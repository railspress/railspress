module Admin::AiHelper
  # Render an AI Assistant button that opens the AI popup
  def ai_assistant_button(options = {})
    options[:class] ||= "flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition text-sm"
    options[:text] ||= "AI Assistant"
    
    content_tag :button, type: "button", onclick: "openAiPopup()", class: options[:class] do
      content_tag(:svg, class: "w-4 h-4", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, "", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z")
      end +
      content_tag(:span, options[:text])
    end
  end
  
  # Render the AI popup modal (call this once per page)
  def ai_popup_modal
    render 'shared/ai_popup'
  end
  
  # Render an AI button with content editor label
  def ai_content_editor_label(form, field, label_text = nil)
    label_text ||= field.to_s.humanize
    
    content_tag :div, class: "flex items-center justify-between mb-2" do
      form.label(field, label_text, class: "block text-sm font-medium text-gray-300") +
      ai_assistant_button
    end
  end
  
  # Check if AI agents are available
  def ai_agents_available?
    AiAgent.active.any?
  end
  
  # Get available agent types
  def available_ai_agents
    AiAgent.active.pluck(:agent_type, :name).map { |type, name| [type, name] }
  end
end



