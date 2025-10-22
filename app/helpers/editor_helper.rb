module EditorHelper
  # Main method to render the content editor based on user preference
  def render_content_editor(form, field_name, content: nil, options: {})
    # Get content from form object if not provided
    content = form.object.send(field_name) if content.nil? && form.object.respond_to?(field_name)
    
    # Get user's preferred editor or default to editorjs
    editor_type = current_user&.editor_preference || 'editorjs'
    placeholder = options[:placeholder] || 'Start writing...'
    
    # Render the reusable content editor partial
    render partial: 'shared/content_editor', locals: {
      form: form,
      content: content,
      field_name: field_name,
      placeholder: placeholder,
      editor_type: editor_type
    }
  end
  
  # Editor preference options for settings
  def editor_preference_options
    [
      ['Editor.js - JSON-based Editor (Default)', 'editorjs'],
      ['Trix - ActionText Rich Text', 'trix'],
      ['CKEditor - Classic WYSIWYG', 'ckeditor5']
    ]
  end
  
  # Get display name for editor type
  def editor_display_name(editor_type)
    case editor_type
    when 'trix'
      'Trix (ActionText)'
    when 'ckeditor'
      'CKEditor'
    when 'editorjs'
      'Editor.js'
    else
      editor_type.titleize
    end
  end
  
  # Check if user has a specific editor preference set
  def user_has_editor_preference?
    current_user&.editor_preference.present?
  end
  
  # Get editor icon for UI
  def editor_icon(editor_type)
    case editor_type
    when 'trix'
      '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
      </svg>'.html_safe
    when 'ckeditor'
      '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
      </svg>'.html_safe
    when 'editorjs'
      '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
      </svg>'.html_safe
    else
      '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
      </svg>'.html_safe
    end
  end
end
