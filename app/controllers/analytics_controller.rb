class AnalyticsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:track, :duration]
  skip_before_action :verify_authenticity_token, only: [:track, :duration]
  
  # POST /analytics/track
  def track
    # Extract data from request
    data = JSON.parse(request.body.read) rescue {}
    
    # Track the pageview
    Pageview.track(request, {
      title: data['title'],
      user_id: current_user&.id,
      session_id: data['session_id'] || cookies['_railspress_session_id'],
      consented: data['consented'] || false,
      metadata: {
        screen_width: data['screen_width'],
        screen_height: data['screen_height'],
        viewport_width: data['viewport_width'],
        viewport_height: data['viewport_height'],
        language: data['language'],
        timezone: data['timezone']
      }
    })
    
    # Generate and set session cookie if not exists
    unless cookies['_railspress_session_id']
      cookies['_railspress_session_id'] = {
        value: SecureRandom.hex(16),
        expires: 30.days.from_now,
        httponly: true,
        same_site: :lax
      }
    end
    
    head :ok
  rescue => e
    Rails.logger.error "Analytics tracking error: #{e.message}"
    head :ok  # Always return OK to not break user experience
  end
  
  # POST /analytics/duration
  def duration
    data = JSON.parse(request.body.read) rescue {}
    
    # Find recent pageview for this path and session
    session_id = cookies['_railspress_session_id']
    pageview = Pageview.where(
      path: data['path'],
      session_id: session_id
    ).where('visited_at >= ?', 10.minutes.ago).last
    
    if pageview
      pageview.update(duration: data['duration'])
    end
    
    head :ok
  rescue => e
    Rails.logger.error "Duration tracking error: #{e.message}"
    head :ok
  end
  
  # POST /analytics/reading
  def reading
    data = JSON.parse(request.body.read) rescue {}
    
    # Find recent pageview for this path and session
    session_id = data['session_id'] || cookies['_railspress_session_id']
    pageview = Pageview.where(
      path: data['path'],
      session_id: session_id
    ).where('visited_at >= ?', 10.minutes.ago).last
    
    if pageview
      pageview.update(
        reading_time: data['reading_time'],
        scroll_depth: data['scroll_depth'],
        completion_rate: data['completion_rate'],
        time_on_page: data['reading_time'],
        exit_intent: data['exit_intent'],
        is_reader: data['is_reader'] || false,
        engagement_score: data['engagement_score'] || 0
      )
    end
    
    head :ok
  rescue => e
    Rails.logger.error "Reading tracking error: #{e.message}"
    head :ok
  end

  def api_docs
    render 'analytics_api_documentation', layout: false
  end

  def examples
    render 'examples/analytics_plugin_example', layout: false
  end
end








