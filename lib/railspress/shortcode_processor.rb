module Railspress
  class ShortcodeProcessor
    class << self
      attr_accessor :shortcodes

      def initialize_processor
        @shortcodes = {}
        register_default_shortcodes
      end

      # Register a shortcode
      def register(name, &block)
        @shortcodes ||= {}
        @shortcodes[name.to_s] = block
        Rails.logger.info "Shortcode registered: #{name}"
      end

      # Process content containing shortcodes
      def process(content, context = {})
        return content if content.blank?
        
        # Pattern matches [shortcode attr="value"] or [shortcode]content[/shortcode]
        content.gsub(/\[(\w+)([^\]]*)\](?:([^\[]*)\[\/\1\])?/) do
          shortcode_name = $1
          attributes_str = $2
          inner_content = $3
          
          if @shortcodes.key?(shortcode_name)
            attrs = parse_attributes(attributes_str)
            execute_shortcode(shortcode_name, attrs, inner_content, context)
          else
            # Return original if shortcode not found
            $&
          end
        end
      end

      # Execute a specific shortcode
      def execute_shortcode(name, attributes, content, context)
        shortcode = @shortcodes[name]
        return '' unless shortcode
        
        begin
          if shortcode.arity == 3
            shortcode.call(attributes, content, context)
          elsif shortcode.arity == 2
            shortcode.call(attributes, content)
          else
            shortcode.call(attributes)
          end
        rescue => e
          Rails.logger.error "Error executing shortcode #{name}: #{e.message}"
          "[Error in #{name} shortcode]"
        end
      end

      # Parse shortcode attributes
      def parse_attributes(attr_string)
        return {} if attr_string.blank?
        
        attrs = {}
        attr_string.scan(/(\w+)=["']([^"']+)["']|(\w+)=(\S+)/) do |match|
          key = match[0] || match[2]
          value = match[1] || match[3]
          attrs[key.to_sym] = value
        end
        attrs
      end

      # Check if shortcode exists
      def exists?(name)
        @shortcodes.key?(name.to_s)
      end

      # Get all registered shortcodes
      def all
        @shortcodes.keys
      end

      # Remove a shortcode
      def unregister(name)
        @shortcodes.delete(name.to_s)
      end

      private

      # Register default shortcodes
      def register_default_shortcodes
        # Gallery shortcode
        register('gallery') do |attrs, content|
          ids = attrs[:ids]&.split(',')&.map(&:to_i) || []
          columns = attrs[:columns]&.to_i || 3
          size = attrs[:size] || 'medium'
          
          if ids.any?
            media = Medium.where(id: ids)
            render_gallery(media, columns, size)
          else
            ''
          end
        end

        # Button shortcode
        register('button') do |attrs, content|
          url = attrs[:url] || '#'
          style = attrs[:style] || 'primary'
          size = attrs[:size] || 'medium'
          target = attrs[:target] || '_self'
          
          render_button(content || 'Click Here', url, style, size, target)
        end

        # YouTube shortcode
        register('youtube') do |attrs|
          video_id = attrs[:id]
          width = attrs[:width] || '560'
          height = attrs[:height] || '315'
          
          render_youtube(video_id, width, height)
        end

        # Recent Posts shortcode
        register('recent_posts') do |attrs|
          count = attrs[:count]&.to_i || 5
          category = attrs[:category]
          
          posts = Post.published.recent
          posts = posts.by_category(category) if category
          posts = posts.limit(count)
          
          render_recent_posts(posts)
        end

        # Contact Form shortcode
        register('contact_form') do |attrs|
          form_id = attrs[:id] || 'contact'
          email = attrs[:email] || SiteSetting.get('admin_email', 'admin@example.com')
          
          render_contact_form(form_id, email)
        end

        # Columns shortcode
        register('columns') do |attrs, content|
          count = attrs[:count]&.to_i || 2
          render_columns(content, count)
        end

        # Alert/Notice shortcode
        register('alert') do |attrs, content|
          type = attrs[:type] || 'info'
          render_alert(content, type)
        end

        # Code shortcode
        register('code') do |attrs, content|
          language = attrs[:lang] || 'plaintext'
          render_code(content, language)
        end
      end

      # Rendering helpers
      def render_gallery(media, columns, size)
        return '' if media.empty?
        
        html = '<div class="shortcode-gallery grid grid-cols-' + columns.to_s + ' gap-4 my-6">'
        media.each do |item|
          if item.file.attached?
            html += '<div class="gallery-item">'
            html += '<img src="' + Rails.application.routes.url_helpers.url_for(item.file) + '" alt="' + (item.alt_text || item.title) + '" class="w-full h-auto rounded-lg">'
            html += '</div>'
          end
        end
        html += '</div>'
        html
      end

      def render_button(text, url, style, size, target)
        color_classes = {
          'primary' => 'bg-blue-600 hover:bg-blue-700 text-white',
          'secondary' => 'bg-gray-600 hover:bg-gray-700 text-white',
          'success' => 'bg-green-600 hover:bg-green-700 text-white',
          'danger' => 'bg-red-600 hover:bg-red-700 text-white'
        }
        
        size_classes = {
          'small' => 'px-3 py-1 text-sm',
          'medium' => 'px-6 py-2',
          'large' => 'px-8 py-3 text-lg'
        }
        
        classes = "inline-block #{color_classes[style]} #{size_classes[size]} rounded-lg transition font-medium"
        
        "<a href=\"#{url}\" target=\"#{target}\" class=\"#{classes}\">#{text}</a>"
      end

      def render_youtube(video_id, width, height)
        return '' unless video_id
        
        "<div class=\"video-container my-6\" style=\"position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;\">
          <iframe src=\"https://www.youtube.com/embed/#{video_id}\" 
                  width=\"#{width}\" 
                  height=\"#{height}\" 
                  style=\"position: absolute; top: 0; left: 0; width: 100%; height: 100%;\"
                  frameborder=\"0\" 
                  allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture\" 
                  allowfullscreen>
          </iframe>
        </div>"
      end

      def render_recent_posts(posts)
        return '' if posts.empty?
        
        html = '<div class="shortcode-recent-posts my-6 space-y-3">'
        posts.each do |post|
          html += '<div class="recent-post">'
          html += '<h4 class="font-semibold"><a href="/blog/' + post.slug + '" class="text-blue-600 hover:text-blue-800">' + post.title + '</a></h4>'
          html += '<p class="text-sm text-gray-500">' + post.published_at.strftime('%B %d, %Y') + '</p>'
          html += '</div>'
        end
        html += '</div>'
        html
      end

      def render_contact_form(form_id, email)
        "<div class=\"shortcode-contact-form my-6 p-6 bg-gray-50 rounded-lg\">
          <form action=\"/contact\" method=\"post\" class=\"space-y-4\">
            <div>
              <label class=\"block text-sm font-medium mb-1\">Name</label>
              <input type=\"text\" name=\"name\" required class=\"w-full px-4 py-2 border rounded-lg\">
            </div>
            <div>
              <label class=\"block text-sm font-medium mb-1\">Email</label>
              <input type=\"email\" name=\"email\" required class=\"w-full px-4 py-2 border rounded-lg\">
            </div>
            <div>
              <label class=\"block text-sm font-medium mb-1\">Message</label>
              <textarea name=\"message\" rows=\"4\" required class=\"w-full px-4 py-2 border rounded-lg\"></textarea>
            </div>
            <button type=\"submit\" class=\"px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700\">Send Message</button>
          </form>
        </div>"
      end

      def render_columns(content, count)
        "<div class=\"shortcode-columns grid grid-cols-#{count} gap-6 my-6\">
          #{content}
        </div>"
      end

      def render_alert(content, type)
        colors = {
          'info' => 'bg-blue-50 border-blue-500 text-blue-800',
          'success' => 'bg-green-50 border-green-500 text-green-800',
          'warning' => 'bg-yellow-50 border-yellow-500 text-yellow-800',
          'danger' => 'bg-red-50 border-red-500 text-red-800'
        }
        
        "<div class=\"shortcode-alert #{colors[type]} border-l-4 p-4 my-6 rounded\">
          #{content}
        </div>"
      end

      def render_code(content, language)
        "<pre class=\"shortcode-code my-6 bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto\"><code class=\"language-#{language}\">#{content}</code></pre>"
      end
    end
  end
end








