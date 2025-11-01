# EditorJS to HTML Renderer
# Converts EditorJS JSON blocks to clean HTML for frontend display
class EditorjsRenderer
  class << self
    def render(json_content)
      return '' if json_content.blank?
      
      begin
        data = JSON.parse(json_content)
        return '' unless data.is_a?(Hash) && data['blocks'].is_a?(Array)
        
        html_parts = data['blocks'].map do |block|
          render_block(block)
        end
        
        html_parts.join("\n")
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse EditorJS content: #{e.message}"
        ''
      end
    end
    
    private
    
    def render_block(block)
      return '' unless block.is_a?(Hash)
      
      block_type = block['type']
      block_data = block['data'] || {}
      
      case block_type
      when 'header'
        render_header(block_data)
      when 'paragraph'
        render_paragraph(block_data)
      when 'list'
        render_list(block_data)
      when 'quote'
        render_quote(block_data)
      when 'code'
        render_code(block_data)
      when 'delimiter'
        render_delimiter
      when 'warning'
        render_warning(block_data)
      when 'checklist'
        render_checklist(block_data)
      when 'table'
        render_table(block_data)
      when 'media'
        render_media(block_data)
      when 'uppy'
        render_uppy(block_data)
      else
        # Unknown block type - try to extract any text content
        render_unknown_block(block_data)
      end
    end
    
    def render_header(data)
      level = data['level'] || 2
      text = sanitize_html(data['text'] || '')
      return '' if text.blank?
      
      "<h#{level}>#{text}</h#{level}>"
    end
    
    def render_paragraph(data)
      text = sanitize_html(data['text'] || '')
      return '' if text.blank?
      
      "<p>#{text}</p>"
    end
    
    def render_list(data)
      style = data['style'] || 'unordered'
      items = data['items'] || []
      return '' if items.empty?
      
      tag = style == 'ordered' ? 'ol' : 'ul'
      
      items_html = items.map do |item|
        # Handle both string items and object items (nested lists)
        item_text = if item.is_a?(Hash)
          # Nested list support
          if item['content']
            sanitize_html(item['content'])
          elsif item['items']
            render_list(item)
          else
            ''
          end
        else
          sanitize_html(item.to_s)
        end
        "<li>#{item_text}</li>" unless item_text.blank?
      end.compact
      
      "<#{tag}>#{items_html.join}</#{tag}>"
    end
    
    def render_quote(data)
      text = sanitize_html(data['text'] || '')
      caption = sanitize_html(data['caption'] || '')
      
      html = "<blockquote>"
      html += "<p>#{text}</p>" unless text.blank?
      html += "<cite>#{caption}</cite>" unless caption.blank?
      html += "</blockquote>"
      html
    end
    
    def render_code(data)
      code = escape_html(data['code'] || '')
      return '' if code.blank?
      
      "<pre><code>#{code}</code></pre>"
    end
    
    def render_delimiter
      "<hr>"
    end
    
    def render_warning(data)
      title = sanitize_html(data['title'] || '')
      message = sanitize_html(data['message'] || '')
      
      html = '<div class="warning">'
      html += "<strong>#{title}</strong>" unless title.blank?
      html += "<p>#{message}</p>" unless message.blank?
      html += "</div>"
      html
    end
    
    def render_checklist(data)
      items = data['items'] || []
      return '' if items.empty?
      
      items_html = items.map do |item|
        checked = item.is_a?(Hash) && item['checked'] ? 'checked' : ''
        text = item.is_a?(Hash) ? sanitize_html(item['text'] || '') : sanitize_html(item.to_s)
        next if text.blank?
        
        "<li><input type=\"checkbox\" #{checked} disabled> #{text}</li>"
      end.compact
      
      "<ul class=\"checklist\">#{items_html.join}</ul>"
    end
    
    def render_table(data)
      content = data['content'] || []
      return '' if content.empty?
      
      rows_html = content.map do |row|
        cells_html = row.map { |cell| "<td>#{sanitize_html(cell)}</td>" }
        "<tr>#{cells_html.join}</tr>"
      end
      
      "<table>#{rows_html.join}</table>"
    end
    
    def render_media(data)
      media = data['media'] || {}
      return '' if media.empty?
      
      media_type = media['type'] || media['file_type'] || ''
      url = media['url'] || ''
      alt = sanitize_html(media['alt_text'] || media['title'] || '')
      caption = sanitize_html(media['caption'] || '')
      
      if media_type.start_with?('image/') || url.match?(/\.(jpg|jpeg|png|gif|webp|svg)$/i)
        html = '<figure class="media-block media-image">'
        html += "<img src=\"#{escape_html(url)}\" alt=\"#{alt}\">"
        html += "<figcaption>#{caption}</figcaption>" unless caption.blank?
        html += "</figure>"
        html
      elsif media_type.start_with?('video/')
        html = '<figure class="media-block media-video">'
        html += "<video controls src=\"#{escape_html(url)}\"></video>"
        html += "<figcaption>#{caption}</figcaption>" unless caption.blank?
        html += "</figure>"
        html
      else
        # File/Document
        title = sanitize_html(media['title'] || 'File')
        file_size = media['file_size']
        size_text = file_size ? " (#{format_file_size(file_size)})" : ''
        
        "<div class=\"media-block media-file\"><a href=\"#{escape_html(url)}\" class=\"file-download\">#{title}#{size_text}</a></div>"
      end
    end
    
    def render_uppy(data)
      files = data['files'] || []
      return '' if files.empty?
      
      files_html = files.map do |file|
        if file['type']&.start_with?('image/')
          url = file['url'] || ''
          caption = sanitize_html(file['caption'] || file['name'] || '')
          "<figure><img src=\"#{escape_html(url)}\" alt=\"#{escape_html(caption)}\"><figcaption>#{caption}</figcaption></figure>"
        else
          url = file['url'] || ''
          name = sanitize_html(file['name'] || 'File')
          "<p><a href=\"#{escape_html(url)}\" class=\"file-download\">#{name}</a></p>"
        end
      end
      
      "<div class=\"uploaded-files\">#{files_html.join}</div>"
    end
    
    def render_unknown_block(data)
      # Try to extract any text content from unknown blocks
      text = data['text'] || data['content'] || data['title'] || ''
      sanitize_html(text)
    end
    
    # Sanitize HTML content (allow safe tags)
    def sanitize_html(text)
      return '' if text.blank?
      
      # Use Rails sanitizer but allow common formatting tags
      ActionView::Base.full_sanitizer.sanitize(text.to_s)
    end
    
    # Escape HTML entities
    def escape_html(text)
      return '' if text.blank?
      ERB::Util.html_escape(text.to_s)
    end
    
    # Format file size in human readable format
    def format_file_size(bytes)
      return '' if bytes.nil?
      
      sizes = ['Bytes', 'KB', 'MB', 'GB']
      return '0 Bytes' if bytes == 0
      
      i = Math.log(bytes) / Math.log(1024)
      i = [[i.floor, sizes.length - 1].min, 0].max
      
      "#{(bytes.to_f / (1024 ** i)).round(2)} #{sizes[i]}"
    end
  end
end
