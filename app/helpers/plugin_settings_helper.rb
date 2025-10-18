module PluginSettingsHelper
  # Render plugin settings form from schema
  def render_plugin_settings_form(plugin, settings_values = {})
    return '' unless plugin.has_settings?
    
    schema = plugin.settings_schema
    
    # Group settings by group if available, otherwise show all together
    grouped_settings = schema.group_by { |setting| setting[:group] || 'General' }
    
    content_tag(:div, class: 'space-y-8') do
      grouped_settings.map do |group_name, group_settings|
        render_settings_group(group_name, group_settings, settings_values, plugin.name)
      end.join.html_safe
    end
  end
  
  # Render a single settings group
  def render_settings_group(group_name, group_settings, settings_values, plugin_name)
    content_tag(:div, class: 'bg-white dark:bg-gray-800 rounded-lg shadow-md p-6') do
      concat content_tag(:h2, group_name, class: 'text-xl font-semibold text-gray-900 dark:text-white mb-2')
      
      concat content_tag(:div, class: 'space-y-6') do
        group_settings.map do |setting|
          render_settings_field(setting, settings_values[setting[:key]], plugin_name)
        end.join.html_safe
      end
    end
  end
  
  # Render a single settings field
  def render_settings_field(field, value, plugin_name)
    value ||= field[:default]
    field_name = "settings[#{field[:key]}]"
    field_id = "#{plugin_name}_#{field[:key]}"
    
    content_tag(:div) do
      case field[:type]
      when 'text', 'email', 'url', 'number'
        render_text_field(field, value, field_name, field_id)
      when 'textarea'
        render_textarea_field(field, value, field_name, field_id)
      when 'checkbox'
        render_checkbox_field(field, value, field_name, field_id)
      when 'select'
        render_select_field(field, value, field_name, field_id)
      when 'radio'
        render_radio_field(field, value, field_name, field_id)
      when 'color'
        render_color_field(field, value, field_name, field_id)
      when 'wysiwyg'
        render_wysiwyg_field(field, value, field_name, field_id)
      when 'code'
        render_code_field(field, value, field_name, field_id)
      else
        render_text_field(field, value, field_name, field_id)
      end
    end
  end
  
  private
  
  def render_text_field(field, value, field_name, field_id)
    concat label_tag(field_id, field[:label], class: 'block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2')
    concat text_field_tag(field_name, value, 
      id: field_id,
      type: field[:type],
      required: field[:required],
      placeholder: field[:placeholder],
      class: 'w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-indigo-500 dark:bg-gray-700 dark:text-white'
    )
    concat content_tag(:p, field[:description], class: 'mt-1 text-sm text-gray-500 dark:text-gray-400') if field[:description]
  end
  
  def render_textarea_field(field, value, field_name, field_id)
    concat label_tag(field_id, field[:label], class: 'block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2')
    concat text_area_tag(field_name, value,
      id: field_id,
      rows: field[:rows] || 4,
      required: field[:required],
      placeholder: field[:placeholder],
      class: 'w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-indigo-500 dark:bg-gray-700 dark:text-white'
    )
    concat content_tag(:p, field[:description], class: 'mt-1 text-sm text-gray-500 dark:text-gray-400') if field[:description]
  end
  
  def render_checkbox_field(field, value, field_name, field_id)
    content_tag(:div, class: 'flex items-start') do
      concat check_box_tag(field_name, '1', value.to_s == '1' || value == true,
        id: field_id,
        class: 'w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500 mt-1'
      )
      concat content_tag(:div, class: 'ml-3') do
        concat label_tag(field_id, field[:label], class: 'text-sm font-medium text-gray-700 dark:text-gray-300')
        concat content_tag(:p, field[:description], class: 'text-sm text-gray-500 dark:text-gray-400') if field[:description]
      end
    end
  end
  
  def render_select_field(field, value, field_name, field_id)
    concat label_tag(field_id, field[:label], class: 'block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2')
    concat select_tag(field_name, options_for_select(field[:options], value),
      id: field_id,
      required: field[:required],
      class: 'w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-indigo-500 dark:bg-gray-700 dark:text-white'
    )
    concat content_tag(:p, field[:description], class: 'mt-1 text-sm text-gray-500 dark:text-gray-400') if field[:description]
  end
  
  def render_radio_field(field, value, field_name, field_id)
    concat label_tag(nil, field[:label], class: 'block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3')
    concat content_tag(:div, class: 'space-y-2') do
      field[:options].map.with_index do |(choice_label, choice_value), index|
        content_tag(:div, class: 'flex items-center') do
          concat radio_button_tag(field_name, choice_value, value == choice_value,
            id: "#{field_id}_#{index}",
            class: 'w-4 h-4 text-indigo-600 border-gray-300 focus:ring-indigo-500'
          )
          concat label_tag("#{field_id}_#{index}", choice_label, class: 'ml-2 text-sm text-gray-700 dark:text-gray-300')
        end
      end.join.html_safe
    end
    concat content_tag(:p, field[:description], class: 'mt-2 text-sm text-gray-500 dark:text-gray-400') if field[:description]
  end
  
  def render_color_field(field, value, field_name, field_id)
    concat label_tag(field_id, field[:label], class: 'block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2')
    concat content_tag(:div, class: 'flex items-center gap-3') do
      concat color_field_tag(field_name, value || '#000000',
        id: field_id,
        class: 'h-10 w-20 rounded border border-gray-300'
      )
      concat text_field_tag("#{field_name}_text", value || '#000000',
        class: 'flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-indigo-500 dark:bg-gray-700 dark:text-white font-mono text-sm',
        onchange: "document.getElementById('#{field_id}').value = this.value"
      )
    end
    concat content_tag(:p, field[:description], class: 'mt-1 text-sm text-gray-500 dark:text-gray-400') if field[:description]
  end
  
  def render_wysiwyg_field(field, value, field_name, field_id)
    concat label_tag(field_id, field[:label], class: 'block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2')
    concat text_area_tag(field_name, value,
      id: field_id,
      rows: 8,
      class: 'w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-indigo-500 dark:bg-gray-700 dark:text-white',
      data: { controller: 'trix' }
    )
    concat content_tag(:p, field[:description], class: 'mt-1 text-sm text-gray-500 dark:text-gray-400') if field[:description]
  end
  
  def render_code_field(field, value, field_name, field_id)
    concat label_tag(field_id, field[:label], class: 'block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2')
    concat text_area_tag(field_name, value,
      id: field_id,
      rows: 12,
      class: 'w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-indigo-500 dark:bg-gray-900 dark:text-green-400 font-mono text-sm',
      spellcheck: 'false'
    )
    concat content_tag(:p, field[:description], class: 'mt-1 text-sm text-gray-500 dark:text-gray-400') if field[:description]
  end
end








