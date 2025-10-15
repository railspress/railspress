module ToggleSwitchHelper
  # Helper method to create a toggle switch with label
  #
  # Usage:
  #   <%= toggle_switch(form, :active, 'Enable Feature', description: 'Turn this feature on or off') %>
  #   <%= toggle_switch_tag('setting', '1', false, 'Enable Setting', class: 'toggle-success') %>
  #
  def toggle_switch(form, field_name, label_text, **options)
    description = options.delete(:description)
    size = options.delete(:size) || 'default'
    color = options.delete(:color) || 'default'
    
    wrapper_class = "toggle-with-#{description ? 'description' : 'label'}"
    wrapper_class += " toggle-#{size}" if size != 'default'
    wrapper_class += " toggle-#{color}" if color != 'default'
    wrapper_class += " #{options.delete(:wrapper_class)}" if options[:wrapper_class]
    
    content_tag(:div, class: wrapper_class) do
      concat form.check_box(field_name, options)
      
      content_tag(:div, class: 'toggle-content') do
        concat content_tag(:label, label_text, for: "#{form.object_name}_#{field_name}")
        concat content_tag(:p, description) if description.present?
      end
    end
  end

  def toggle_switch_tag(name, value, checked, label_text, **options)
    description = options.delete(:description)
    size = options.delete(:size) || 'default'
    color = options.delete(:color) || 'default'
    
    wrapper_class = "toggle-with-#{description ? 'description' : 'label'}"
    wrapper_class += " toggle-#{size}" if size != 'default'
    wrapper_class += " toggle-#{color}" if color != 'default'
    wrapper_class += " #{options.delete(:wrapper_class)}" if options[:wrapper_class]
    
    checkbox_id = options.delete(:id) || "#{name}_#{value}".gsub(/[\[\]]/, '_').gsub(/_+/, '_').chomp('_')
    
    content_tag(:div, class: wrapper_class) do
      concat check_box_tag(name, value, checked, options.merge(id: checkbox_id))
      
      content_tag(:div, class: 'toggle-content') do
        concat content_tag(:label, label_text, for: checkbox_id)
        concat content_tag(:p, description) if description.present?
      end
    end
  end

  # Helper to create a toggle switch group
  def toggle_switch_group(**options)
    direction = options.delete(:direction) || 'vertical'
    group_class = direction == 'horizontal' ? 'toggle-group-horizontal' : 'toggle-group'
    group_class += " #{options[:class]}" if options[:class]
    
    content_tag(:div, class: group_class, **options.except(:class)) do
      yield if block_given?
    end
  end

  # Helper for simple toggle switches without labels
  def simple_toggle_switch(form, field_name, **options)
    form.check_box(field_name, options)
  end

  def simple_toggle_switch_tag(name, value, checked, **options)
    check_box_tag(name, value, checked, options)
  end

  # Helper to create toggle switches with different colors
  def success_toggle_switch(form, field_name, label_text, **options)
    toggle_switch(form, field_name, label_text, color: 'success', **options)
  end

  def warning_toggle_switch(form, field_name, label_text, **options)
    toggle_switch(form, field_name, label_text, color: 'warning', **options)
  end

  def danger_toggle_switch(form, field_name, label_text, **options)
    toggle_switch(form, field_name, label_text, color: 'danger', **options)
  end

  # Helper for different sizes
  def small_toggle_switch(form, field_name, label_text, **options)
    toggle_switch(form, field_name, label_text, size: 'sm', **options)
  end

  def large_toggle_switch(form, field_name, label_text, **options)
    toggle_switch(form, field_name, label_text, size: 'lg', **options)
  end

  def small_toggle_switch_tag(name, value, checked, label_text, **options)
    toggle_switch_tag(name, value, checked, label_text, size: 'sm', **options)
  end

  def large_toggle_switch_tag(name, value, checked, label_text, **options)
    toggle_switch_tag(name, value, checked, label_text, size: 'lg', **options)
  end

  # Helper for loading state
  def loading_toggle_switch(form, field_name, label_text, **options)
    toggle_switch(form, field_name, label_text, wrapper_class: 'toggle-loading', **options)
  end

  # Helper for error state
  def error_toggle_switch(form, field_name, label_text, **options)
    toggle_switch(form, field_name, label_text, wrapper_class: 'toggle-error', **options)
  end

  # Helper for success state
  def success_state_toggle_switch(form, field_name, label_text, **options)
    toggle_switch(form, field_name, label_text, wrapper_class: 'toggle-success', **options)
  end
end
