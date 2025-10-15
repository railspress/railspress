module AiTextGeneratorHelper
  # Helper method to easily add AI text generation to form fields
  #
  # Usage:
  #   <%= ai_text_field(form, :title, 'Post Title', agent: 'content_summarizer') %>
  #   <%= ai_text_area(form, :content, 'Content', agent: 'creative_writer', rows: 6) %>
  #
  def ai_text_field(form, field_name, label_text, agent: 'content_summarizer', **options)
    field_id = "#{form.object_name}_#{field_name}"
    
    html = content_tag(:div, class: "ai-text-field-wrapper") do
      # Label
      concat form.label(field_name, label_text, class: "block text-sm font-medium text-gray-300 mb-2")
      
      # Field with AI button
      concat content_tag(:div, class: "relative") do
        concat form.text_field(field_name, 
          class: "w-full px-4 py-2 bg-[#0a0a0a] border border-[#2a2a2a] text-white rounded-lg focus:border-indigo-500 focus:outline-none pr-10 #{options[:class]}",
          placeholder: options[:placeholder],
          id: field_id,
          **options.except(:class, :placeholder))
        
        # Use a placeholder for the AI generator in tests
        if Rails.env.test?
          concat content_tag(:div, "AI Generator Placeholder", class: "ai-text-generator", "data-agent-id" => agent, "data-target-selector" => "##{field_id}")
        else
          concat render('shared/ai_text_generator',
            agent_id: agent,
            target_selector: "##{field_id}",
            button_text: 'AI',
            placeholder: options[:ai_placeholder] || "Describe what you want to generate...",
            button_class: 'absolute top-2 right-2')
        end
      end
    end
    
    html
  end

  def ai_text_area(form, field_name, label_text, agent: 'content_summarizer', **options)
    field_id = "#{form.object_name}_#{field_name}"
    rows = options.delete(:rows) || 4
    
    html = content_tag(:div, class: "ai-text-area-wrapper") do
      # Label
      concat form.label(field_name, label_text, class: "block text-sm font-medium text-gray-300 mb-2")
      
      # Field with AI button
      concat content_tag(:div, class: "relative") do
        concat form.text_area(field_name, 
          class: "w-full px-4 py-3 bg-[#0a0a0a] border border-[#2a2a2a] text-white rounded-lg focus:border-indigo-500 focus:outline-none pr-12 #{options[:class]}",
          placeholder: options[:placeholder],
          rows: rows,
          id: field_id,
          **options.except(:class, :placeholder, :rows))
        
        # Use a placeholder for the AI generator in tests
        if Rails.env.test?
          concat content_tag(:div, "AI Generator Placeholder", class: "ai-text-generator", "data-agent-id" => agent, "data-target-selector" => "##{field_id}")
        else
          concat render('shared/ai_text_generator',
            agent_id: agent,
            target_selector: "##{field_id}",
            button_text: 'AI',
            placeholder: options[:ai_placeholder] || "Describe what you want to generate...",
            button_class: 'absolute top-3 right-3')
        end
      end
    end
    
    html
  end

  # Helper to check if AI agents are available
  def ai_agents_available?
    AiAgent.active.exists?
  end

  # Helper to get available AI agents for dropdown
  def ai_agent_options
    AiAgent.active.ordered.map { |agent| [agent.name, agent.id] }
  end

  # Helper to render AI text generator with custom styling
  def ai_text_generator_button(agent_id:, target_selector:, **options)
    render('shared/ai_text_generator',
      agent_id: agent_id,
      target_selector: target_selector,
      button_text: options[:button_text] || 'AI',
      placeholder: options[:placeholder] || 'Describe what you want to generate...',
      button_class: options[:button_class] || '')
  end

  # Helper for admin forms - adds AI button to existing field
  def with_ai_generator(field_html, agent_id:, target_selector:, **options)
    content_tag(:div, class: "relative") do
      concat field_html.html_safe
      concat ai_text_generator_button(
        agent_id: agent_id,
        target_selector: target_selector,
        **options
      )
    end
  end
end
