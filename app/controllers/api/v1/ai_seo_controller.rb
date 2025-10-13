class Api::V1::AiSeoController < Api::V1::BaseController
  # POST /api/v1/ai_seo/generate
  def generate
    content_type = params[:content_type] # 'post' or 'page'
    content_id = params[:content_id]
    
    unless content_type.present? && content_id.present?
      return render_error('Missing content_type or content_id', 400)
    end
    
    result = AiSeo.generate_seo(content_type, content_id)
    
    if result[:success]
      render_success(result, 'SEO generated successfully')
    else
      render_error(result[:error] || 'Failed to generate SEO', 422)
    end
  end
  
  # POST /api/v1/ai_seo/analyze
  def analyze
    content_text = params[:content]
    
    unless content_text.present?
      return render_error('Missing content parameter', 400)
    end
    
    plugin = Railspress::PluginSystem.get_plugin('ai_seo')
    unless plugin
      return render_error('AI SEO plugin not active', 503)
    end
    
    begin
      # Create a temporary object for analysis
      temp_object = OpenStruct.new(
        title: params[:title] || 'Untitled',
        content: OpenStruct.new(to_plain_text: content_text)
      )
      
      ai_response = plugin.send(:call_ai_api, content_text, temp_object)
      seo_data = plugin.send(:parse_ai_response, ai_response)
      
      render_success(seo_data, 'Content analyzed successfully')
    rescue => e
      render_error("Analysis failed: #{e.message}", 500)
    end
  end
  
  # GET /api/v1/ai_seo/status
  def status
    plugin = Railspress::PluginSystem.get_plugin('ai_seo')
    
    unless plugin
      return render json: {
        active: false,
        configured: false,
        message: 'AI SEO plugin not active'
      }
    end
    
    render json: {
      active: true,
      configured: plugin.enabled?,
      provider: plugin.get_setting('ai_provider'),
      model: plugin.get_setting('model'),
      auto_generate: plugin.get_setting('auto_generate_on_save'),
      rate_limit: {
        max_per_hour: plugin.get_setting('max_requests_per_hour'),
        current: plugin.send(:get_request_count)
      }
    }
  end
  
  # POST /api/v1/ai_seo/batch_generate
  def batch_generate
    content_type = params[:content_type]
    content_ids = params[:content_ids] # Array of IDs
    
    unless content_type.present? && content_ids.is_a?(Array)
      return render_error('Missing or invalid parameters', 400)
    end
    
    results = []
    content_ids.each do |content_id|
      result = AiSeo.generate_seo(content_type, content_id)
      results << {
        content_id: content_id,
        success: result[:success],
        data: result[:success] ? result : { error: result[:error] }
      }
    end
    
    render_success({
      total: results.count,
      successful: results.count { |r| r[:success] },
      failed: results.count { |r| !r[:success] },
      results: results
    }, 'Batch generation completed')
  end
end






