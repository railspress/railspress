class AdminChatService
  def initialize(agent_slug:, user: nil, session_uuid: nil)
    @agent = AiAgent.find_by!(slug: agent_slug)
    @user = user
    @session = find_or_create_session(session_uuid)
  end
  
  def stream_chat(message:, conversation_history: [], show_greeting: false, settings: {}, content: {}, attachments: [], user_info: {})
    # If this is a new session and greeting is requested, stream it first
    if show_greeting && @session.event_count == 0 && @agent.greeting.present?
      @agent.greeting.chars.each do |char|
        yield char if block_given?
        sleep 0.01 # Simulate streaming
      end
      
      greeting_result = stream_greeting
      yield "\n\n" if block_given? # Add spacing after greeting
      
      # Return early if no message provided (greeting only)
      return greeting_result if message.blank?
    end
    
    # Return nil if no message provided (shouldn't happen but safety check)
    return { response_event_id: nil, session_uuid: @session.uuid } if message.blank?
    
    # Log user intent with user info if provided
    intent_payload = { text: message, channel: "web" }
    intent_payload[:user_info] = user_info if user_info.present?
    
    intent_event = @session.log(
      event_type: "intent",
      subtype: "user_text",
      payload: intent_payload
    )

    full_response = ""
    
    # Log action (plan to generate response)
    action_event = @session.log(
      event_type: "action",
      subtype: "generate_response",
      payload: { model_version: @agent.ai_provider.model_identifier }
    )

    # Build context hash for the agent
    context = { 
      conversation_history: conversation_history,
      settings: settings
    }
    
    # Add content if present
    if content.present? && content['content'].present?
      context[:content] = content['content']
    end
    
    # Add attachments if present
    if attachments.present? && attachments.any?
      context[:attachments] = attachments
      
      # Log attachment event
      @session.log(
        event_type: "action",
        subtype: "attach_files",
        summary: "Attached #{attachments.length} file(s)",
        payload: {
          file_count: attachments.length,
          files: attachments.map { |f| { name: f['name'], type: f['type'], size: f['size'] } }
        }
      )
    end
    
    # Add HTML formatting rule to the message
    formatted_message = message + "\n\nReturn only valid HTML. Valid tags: <h1>, <h2>, <h3>, <p>, <ul>, <ol>, <li>, <strong>, <em>, <a>, <blockquote>, <code>, <pre>, <img>. Do NOT wrap HTML in markdown code blocks. Return raw HTML directly. Do NOT return a full HTML document (e.g., no <html>, <head>, <body> tags). Return only the content within the body."
    
    @agent.execute_streaming(formatted_message, context, @user) do |chunk|
      full_response += chunk if chunk
      yield chunk if block_given?
    end

    # Log response
    response_event = @session.log(
      event_type: "response",
      subtype: "text",
      summary: full_response.truncate(200),
      payload: {
        text: full_response,
        model_version: @agent.ai_provider.model_identifier,
        provenance: { action_id: action_event.id },
        tokens: { in: estimate_tokens(message), out: estimate_tokens(full_response) }
      },
      target_event: intent_event
    )

    { response_event_id: response_event.id, session_uuid: @session.uuid }
  rescue => e
    @session.log(
      event_type: "observation",
      subtype: "error",
      summary: e.message,
      payload: { error_class: e.class.name, backtrace: e.backtrace.first(5) }
    )
    raise
  end

  def stream_greeting
    return unless @agent.greeting.present?
    
    # Log greeting as a response event
    greeting_event = @session.log(
      event_type: "response",
      subtype: "greeting",
      summary: @agent.greeting.truncate(200),
      payload: {
        text: @agent.greeting,
        is_greeting: true
      }
    )
    
    { response_event_id: greeting_event.id, session_uuid: @session.uuid }
  end

  def log_feedback(event_id:, feedback_type:, category: nil, reason_text: nil)
    target_event = @session.agent_events.find(event_id)
    
    @session.log(
      event_type: "feedback",
      subtype: feedback_type, # like, unlike, copy, insert
      payload: {
        feedback_type: feedback_type,
        category: category,
        reason_text: reason_text,
        user_consent_for_training: true
      },
      target_event: target_event
    )
  end
  
  def agent_info
    {
      name: @agent.name,
      description: @agent.description,
      slug: @agent.slug,
      greeting: @agent.greeting
    }
  end

  def get_session_info
    return nil unless @session
    
    {
      session_uuid: @session.uuid,
      conversation_history: @session.conversation_history,
      agent_info: {
        name: @agent.name,
        description: @agent.description,
        slug: @agent.slug
      }
    }
  end

  def close_session!
    return unless @session
    
    # Log intent to close conversation
    @session.log(
      event_type: "intent",
      subtype: "close_conversation",
      payload: { reason: "User started new chat" }
    )
    
    # Close the session
    @session.close!(summary: "Conversation closed - user started new chat")
  end

  private

  def find_or_create_session(session_uuid)
    if session_uuid
      @agent.agent_sessions.find_by(uuid: session_uuid) || @agent.create_session(user: @user)
    else
      @agent.create_session(user: @user)
    end
  end

  def estimate_tokens(text)
    (text.to_s.length / 4.0).ceil
  end
end

