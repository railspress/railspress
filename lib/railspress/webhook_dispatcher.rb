# frozen_string_literal: true

module Railspress
  class WebhookDispatcher
    class << self
      # Dispatch a webhook event
      def dispatch(event_type, resource)
        # Find all active webhooks subscribed to this event
        webhooks = Webhook.active.for_event(event_type)
        
        return if webhooks.empty?
        
        # Build payload
        payload = build_payload(event_type, resource)
        
        # Deliver to each webhook
        webhooks.each do |webhook|
          webhook.deliver(event_type, payload)
        end
        
        Rails.logger.info "Dispatched webhook event: #{event_type} to #{webhooks.count} webhook(s)"
      end
      
      private
      
      def build_payload(event_type, resource)
        base_payload = {
          event: event_type,
          timestamp: Time.current.iso8601,
          data: serialize_resource(resource)
        }
        
        # Add site context
        base_payload[:site] = {
          name: SiteSetting.get('site_title', 'RailsPress'),
          url: site_url
        }
        
        base_payload
      end
      
      def serialize_resource(resource)
        case resource
        when Post
          {
            id: resource.id,
            type: 'post',
            title: resource.title,
            slug: resource.slug,
            excerpt: resource.excerpt,
            status: resource.status,
            published_at: resource.published_at&.iso8601,
            url: post_url(resource),
            author: {
              id: resource.user&.id,
              email: resource.user&.email
            },
            categories: resource.categories.map { |c| { id: c.id, name: c.name, slug: c.slug } },
            tags: resource.tags.map { |t| { id: t.id, name: t.name, slug: t.slug } },
            created_at: resource.created_at.iso8601,
            updated_at: resource.updated_at.iso8601
          }
        when Page
          {
            id: resource.id,
            type: 'page',
            title: resource.title,
            slug: resource.slug,
            status: resource.status,
            published_at: resource.published_at&.iso8601,
            url: page_url(resource),
            author: {
              id: resource.user&.id,
              email: resource.user&.email
            },
            created_at: resource.created_at.iso8601,
            updated_at: resource.updated_at.iso8601
          }
        when Comment
          {
            id: resource.id,
            type: 'comment',
            content: resource.content,
            author_name: resource.author_name,
            author_email: resource.author_email,
            status: resource.status,
            commentable_type: resource.commentable_type,
            commentable_id: resource.commentable_id,
            created_at: resource.created_at.iso8601,
            updated_at: resource.updated_at.iso8601
          }
        when User
          {
            id: resource.id,
            type: 'user',
            email: resource.email,
            role: resource.role,
            created_at: resource.created_at.iso8601,
            updated_at: resource.updated_at.iso8601
          }
        when Medium
          {
            id: resource.id,
            type: 'media',
            title: resource.title,
            created_at: resource.created_at.iso8601
          }
        else
          {
            id: resource.try(:id),
            type: resource.class.name.underscore
          }
        end
      end
      
      def site_url
        Rails.application.routes.url_helpers.root_url
      rescue
        'http://localhost:3000'
      end
      
      def post_url(post)
        Rails.application.routes.url_helpers.blog_post_url(post.slug)
      rescue
        "#{site_url}/blog/#{post.slug}"
      end
      
      def page_url(page)
        Rails.application.routes.url_helpers.page_url(page.slug)
      rescue
        "#{site_url}/#{page.slug}"
      end
    end
  end
end






