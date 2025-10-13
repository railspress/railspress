# frozen_string_literal: true

require 'loofah'

module Railspress
  class HtmlSanitizer
    # Allow safe HTML tags and attributes for content editors
    ALLOWED_TAGS = %w[
      p br strong em b i u s strike del ins mark small sub sup
      h1 h2 h3 h4 h5 h6
      ul ol li dl dt dd
      blockquote q code pre kbd samp var
      a img
      table thead tbody tfoot tr th td caption colgroup col
      div span section article aside header footer nav main
      figure figcaption
      hr
      abbr cite dfn time
    ].freeze

    ALLOWED_ATTRIBUTES = {
      'a' => %w[href title rel target],
      'img' => %w[src alt title width height],
      'div' => %w[class id],
      'span' => %w[class id],
      'p' => %w[class id],
      'h1' => %w[id],
      'h2' => %w[id],
      'h3' => %w[id],
      'h4' => %w[id],
      'h5' => %w[id],
      'h6' => %w[id],
      'section' => %w[class id],
      'article' => %w[class id],
      'table' => %w[class],
      'tr' => %w[class],
      'td' => %w[class colspan rowspan],
      'th' => %w[class colspan rowspan],
      'code' => %w[class],
      'pre' => %w[class],
      'blockquote' => %w[cite]
    }.freeze

    ALLOWED_PROTOCOLS = %w[http https mailto].freeze

    class << self
      # Sanitize HTML content for posts/pages
      def sanitize_content(html)
        return '' if html.blank?

        scrubber = ContentScrubber.new
        Loofah.fragment(html).scrub!(scrubber).to_s
      end

      # Sanitize HTML from GrapesJS (template editor)
      def sanitize_template(html)
        return '' if html.blank?

        scrubber = TemplateScrubber.new
        Loofah.fragment(html).scrub!(scrubber).to_s
      end

      # Strip all HTML tags, leaving only text
      def strip_tags(html)
        return '' if html.blank?

        Loofah.fragment(html).text(encode_special_chars: false)
      end

      # Sanitize for safe display in admin (allows more tags)
      def sanitize_admin(html)
        return '' if html.blank?

        scrubber = AdminScrubber.new
        Loofah.fragment(html).scrub!(scrubber).to_s
      end

      # Check if HTML contains any disallowed content
      def contains_unsafe_content?(html)
        return false if html.blank?

        # Check for script tags
        return true if html.match?(/<script[\s>]/i)

        # Check for event handlers
        return true if html.match?(/on\w+\s*=/i)

        # Check for javascript: protocol
        return true if html.match?(/javascript:/i)

        # Check for data: protocol (except images)
        return true if html.match?(/data:(?!image)/i)

        false
      end
    end

    # Scrubber for content (posts/pages)
    class ContentScrubber < Loofah::Scrubber
      def initialize
        @direction = :top_down
      end

      def scrub(node)
        return CONTINUE if node.text?

        # Remove comments
        return STOP if node.comment?

        # Check if tag is allowed
        unless ALLOWED_TAGS.include?(node.name)
          node.before(node.children)
          return STOP
        end

        # Remove dangerous attributes
        node.attributes.each do |name, _attr|
          # Skip if attribute is allowed for this tag
          next if ALLOWED_ATTRIBUTES[node.name]&.include?(name)

          # Remove attribute
          node.remove_attribute(name)
        end

        # Sanitize href/src attributes
        sanitize_url_attributes(node)

        CONTINUE
      end

      private

      def sanitize_url_attributes(node)
        %w[href src].each do |attr|
          next unless node[attr]

          url = node[attr].strip

          # Remove javascript: and data: protocols
          if url.match?(/^(javascript|data):/i)
            node.remove_attribute(attr)
            next
          end

          # Ensure protocol is allowed
          if url.match?(/^(\w+):/) && !ALLOWED_PROTOCOLS.any? { |p| url.start_with?("#{p}:") }
            node.remove_attribute(attr)
          end
        end
      end
    end

    # Scrubber for templates (GrapesJS)
    class TemplateScrubber < ContentScrubber
      # Additional allowed tags for templates
      TEMPLATE_TAGS = (ALLOWED_TAGS + %w[
        style
      ]).freeze

      # Additional allowed attributes for templates
      TEMPLATE_ATTRIBUTES = ALLOWED_ATTRIBUTES.merge(
        'style' => %w[type],
        'div' => %w[class id data-gjs-type],
        'section' => %w[class id data-gjs-type]
      ).freeze

      def scrub(node)
        return CONTINUE if node.text?
        return STOP if node.comment?

        # Allow more tags for templates
        unless TEMPLATE_TAGS.include?(node.name)
          node.before(node.children)
          return STOP
        end

        # Remove dangerous attributes but keep template-specific ones
        node.attributes.each do |name, _attr|
          next if TEMPLATE_ATTRIBUTES[node.name]&.include?(name)
          node.remove_attribute(name)
        end

        # For style tags, sanitize content
        if node.name == 'style'
          sanitize_css(node)
        end

        sanitize_url_attributes(node)

        CONTINUE
      end

      private

      def sanitize_css(node)
        # Remove any @import or expression() from CSS
        css = node.content
        css.gsub!(/@import/i, '')
        css.gsub!(/expression\s*\(/i, '')
        css.gsub!(/javascript:/i, '')
        node.content = css
      end
    end

    # Scrubber for admin interface (most permissive)
    class AdminScrubber < TemplateScrubber
      # Admin can see more but still no scripts
      ADMIN_TAGS = (TEMPLATE_TAGS + %w[
        video audio source track
        iframe embed object
        canvas svg
        details summary
      ]).freeze

      def scrub(node)
        return CONTINUE if node.text?
        return STOP if node.comment?

        # Block script tags always
        if node.name == 'script'
          return STOP
        end

        # Allow admin tags
        unless ADMIN_TAGS.include?(node.name)
          node.before(node.children)
          return STOP
        end

        # Remove event handler attributes
        node.attributes.each do |name, _attr|
          if name.match?(/^on/i)
            node.remove_attribute(name)
          end
        end

        CONTINUE
      end
    end
  end
end




