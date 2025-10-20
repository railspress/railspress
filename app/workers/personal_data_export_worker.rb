class PersonalDataExportWorker
  include Sidekiq::Worker
  
  sidekiq_options retry: 2, queue: :default
  
  def perform(request_id)
    request = PersonalDataExportRequest.find(request_id)
    request.update(status: 'processing')
    
    user = User.find(request.user_id)
    
    # Compile all personal data
    personal_data = {
      request_info: {
        requested_at: request.created_at,
        email: request.email,
        export_date: Time.current
      },
      user_profile: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        bio: user.bio,
        website: user.website,
        created_at: user.created_at,
        updated_at: user.updated_at
      },
      posts: user.posts.map { |p| 
        {
          title: p.title,
          slug: p.slug,
          content: p.content.to_s,
          status: p.status,
          published_at: p.published_at,
          created_at: p.created_at
        }
      },
      comments: Comment.where(author_email: user.email).map { |c|
        {
          content: c.content,
          author_name: c.author_name,
          post_title: c.commentable&.title,
          created_at: c.created_at,
          ip_address: c.ip_address
        }
      },
      subscribers: Subscriber.where(email: user.email).map { |s|
        {
          email: s.email,
          status: s.status,
          subscribed_at: s.confirmed_at,
          lists: s.lists
        }
      },
      pageviews: Pageview.where(user_id: user.id).group(:path).count,
      metadata: {
        total_posts: user.posts.count,
        total_comments: Comment.where(author_email: user.email).count,
        total_pageviews: Pageview.where(user_id: user.id).count
      }
    }
    
    # Write to file
    file_path = Rails.root.join('tmp', "personal_data_#{request.id}.json")
    File.write(file_path, JSON.pretty_generate(personal_data))
    
    request.update(
      status: 'completed',
      file_path: file_path.to_s,
      completed_at: Time.current
    )
    
    # Send notification email (optional)
    # PersonalDataMailer.export_ready(request).deliver_later
    
  rescue => e
    Rails.logger.error("Personal data export #{request_id} failed: #{e.message}")
    request.update(status: 'failed')
  end
end








