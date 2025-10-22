class PlainContentExtractor
  class << self
    def extract(content, editor_type = nil)
      return '' if content.blank?

      case editor_type
      when 'editorjs'
        extract_from_editorjs(content)
      when 'trix', 'ckeditor5'
        extract_from_html(content)
      else
        # Try to detect format
        if looks_like_editorjs?(content)
          extract_from_editorjs(content)
        else
          extract_from_html(content)
        end
      end
    end

    private

    def extract_from_editorjs(json_content)
      return '' if json_content.blank?

      begin
        data = JSON.parse(json_content)
        blocks = data['blocks'] || []
        
        text_parts = blocks.map do |block|
          case block['type']
          when 'paragraph', 'header'
            extract_text_from_block(block)
          when 'list'
            extract_text_from_list_block(block)
          when 'quote'
            extract_text_from_quote_block(block)
          when 'code'
            extract_text_from_code_block(block)
          when 'table'
            extract_text_from_table_block(block)
          else
            # For unknown block types, try to extract any text content
            extract_text_from_block(block)
          end
        end.compact

        # Join with newlines and clean up
        text_parts.join("\n").gsub(/\n{3,}/, "\n\n").strip
      rescue JSON::ParserError => e
        Rails.logger.warn "Failed to parse EditorJS content: #{e.message}"
        # Fallback to HTML extraction
        extract_from_html(json_content)
      end
    end

    def extract_text_from_block(block)
      text = block.dig('data', 'text') || ''
      sanitize_text(text)
    end

    def extract_text_from_list_block(block)
      items = block.dig('data', 'items') || []
      items.map { |item| sanitize_text(item) }.join("\n")
    end

    def extract_text_from_quote_block(block)
      text = block.dig('data', 'text') || ''
      caption = block.dig('data', 'caption') || ''
      
      parts = [sanitize_text(text)]
      parts << sanitize_text(caption) if caption.present?
      parts.join(' - ')
    end

    def extract_text_from_code_block(block)
      code = block.dig('data', 'code') || ''
      sanitize_text(code)
    end

    def extract_text_from_table_block(block)
      content = block.dig('data', 'content') || []
      rows = content.map do |row|
        row.map { |cell| sanitize_text(cell) }.join(' | ')
      end
      rows.join("\n")
    end

    def extract_from_html(html_content)
      return '' if html_content.blank?

      begin
        # Try ActionText first (best for Rails apps)
        if defined?(ActionText::Content)
          ActionText::Content.new(html_content).to_plain_text
        else
          # Fallback to Rails sanitizer
          ActionView::Base.full_sanitizer.sanitize(html_content)
        end
      rescue => e
        Rails.logger.warn "Failed to extract text from HTML: #{e.message}"
        # Last resort: basic HTML tag removal
        html_content.gsub(/<[^>]*>/, '').gsub(/\s+/, ' ').strip
      end
    end

    def looks_like_editorjs?(content)
      return false if content.blank?
      
      # Check if it looks like EditorJS JSON
      content.strip.start_with?('{') && 
      content.include?('"blocks"') && 
      content.include?('"type"')
    end

    def sanitize_text(text)
      return '' if text.blank?
      
      # Remove HTML tags and decode entities
      text = ActionView::Base.full_sanitizer.sanitize(text)
      text = CGI.unescapeHTML(text)
      
      # Normalize whitespace
      text.gsub(/\s+/, ' ').strip
    end
  end
end
