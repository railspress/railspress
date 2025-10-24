class Admin::AiChatController < Admin::BaseController
  include ActionController::Live
  
  skip_before_action :verify_authenticity_token, only: [:stream, :upload_attachment]
  
  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'
    
    agent_slug = params[:agent_slug]
    message = params[:message]
    history = JSON.parse(params[:conversation_history] || '[]')
    session_uuid = params[:session_uuid]
    show_greeting = params[:show_greeting] == 'true'
    settings = JSON.parse(params[:settings] || '{}')
    content = JSON.parse(params[:content] || '{}')
    attachments = JSON.parse(params[:attachments] || '[]')
    user_info = JSON.parse(params[:user_info] || '{}')
    
    service = AdminChatService.new(
      agent_slug: agent_slug,
      user: current_user,
      session_uuid: session_uuid
    )
    
    begin
      # Send agent info as first event (only on initial connection)
      if show_greeting || message.blank?
        agent_info = service.agent_info
        response.stream.write("data: #{JSON.generate({agent_info: agent_info, done: false})}\n\n")
      end
      
      result = service.stream_chat(
        message: message,
        conversation_history: history,
        show_greeting: show_greeting,
        settings: settings,
        content: content,
        attachments: attachments,
        user_info: user_info
      ) do |chunk|
        if chunk
          response.stream.write("data: #{JSON.generate({chunk: chunk, done: false})}\n\n")
        end
      end
      
      # Send completion signal with session info
      response.stream.write("data: #{JSON.generate({chunk: '', done: true, session_uuid: result[:session_uuid], event_id: result[:response_event_id]})}\n\n")
    rescue => e
      response.stream.write("data: #{JSON.generate({error: e.message})}\n\n")
    ensure
      response.stream.close
    end
  end

  def feedback
    service = AdminChatService.new(
      agent_slug: params[:agent_slug],
      user: current_user,
      session_uuid: params[:session_uuid]
    )

    service.log_feedback(
      event_id: params[:event_id],
      feedback_type: params[:feedback_type], # like, unlike, copy, insert
      category: params[:category],
      reason_text: params[:reason_text]
    )

    render json: { success: true }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
  
  def agent_info
    service = AdminChatService.new(agent_slug: params[:agent_slug])
    render json: service.agent_info
  end

  def session
    service = AdminChatService.new(
      agent_slug: params[:agent_slug],
      user: current_user,
      session_uuid: params[:session_uuid]
    )

    session_data = service.get_session_info
    
    render json: session_data
  rescue => e
    render json: { error: e.message }, status: :not_found
  end

  def close_session
    service = AdminChatService.new(
      agent_slug: params[:agent_slug],
      user: current_user,
      session_uuid: params[:session_uuid]
    )

    service.close_session!
    
    render json: { success: true }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
  
  def upload_attachment
    file = params[:file]
    agent_slug = params[:agent_slug]
    
    unless file
      render json: { error: 'No file provided' }, status: :bad_request
      return
    end
    
    # Validate file size (5MB max)
    if file.size > 5.megabytes
      render json: { error: 'File too large. Maximum size is 5MB.' }, status: :bad_request
      return
    end
    
    # Validate file type
    allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif', 'application/pdf', 'text/plain', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
    unless allowed_types.include?(file.content_type)
      render json: { error: 'File type not allowed' }, status: :bad_request
      return
    end
    
    # Find active storage provider
    storage_provider = StorageProvider.find_by(active: true) || StorageProvider.first
    
    # Get agent name for tags
    agent_name = 'Unknown Agent'
    if agent_slug.present?
      agent = AiAgent.find_by(slug: agent_slug)
      agent_name = agent.name if agent
    end
    
    # Create upload record and attach file
    upload = Upload.create!(
      title: file.original_filename,
      user: current_user,
      tenant: current_tenant,
      storage_provider: storage_provider,
      temporary: true,
      expires_at: 1.hour.from_now,
      public: true,
      source: "#{agent_slug}_session",
      tags: "#{agent_name} Uploads"
    ) do |u|
      u.file.attach(file)
    end
    
    # Return file data
    render json: {
      id: upload.id,
      name: file.original_filename,
      type: file.content_type,
      url: upload.url,
      size: file.size
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

