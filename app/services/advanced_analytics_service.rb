# frozen_string_literal: true

class AdvancedAnalyticsService
  include Rails.application.routes.url_helpers
  
  # Advanced tracking capabilities like GA4/Matomo
  class << self
    # Track user journey and behavior patterns
    def track_user_journey(session_id, user_id = nil, event_data = {})
      return unless analytics_enabled?
      
      journey_data = {
        session_id: session_id,
        user_id: user_id,
        timestamp: Time.current,
        events: [],
        metadata: {}
      }.merge(event_data)
      
      # Store in Redis for real-time analysis
      Redis.current.setex("user_journey:#{session_id}", 30.minutes.to_i, journey_data.to_json)
      
      # Queue for background processing
      AnalyticsProcessingJob.perform_later('user_journey', journey_data)
    end
    
    # Track conversion funnels with attribution
    def track_conversion_funnel(funnel_id, step, session_id, user_id = nil, properties = {})
      return unless analytics_enabled?
      
      funnel_data = {
        funnel_id: funnel_id,
        step: step,
        session_id: session_id,
        user_id: user_id,
        timestamp: Time.current,
        properties: properties,
        attribution: get_attribution_data(session_id)
      }
      
      # Store conversion event
      AnalyticsEvent.track_conversion(
        event_name: "funnel_#{funnel_id}_#{step}",
        session_id: session_id,
        user_id: user_id,
        properties: funnel_data
      )
      
      # Update funnel progress
      update_funnel_progress(funnel_id, step, session_id)
    end
    
    # Track cohort analysis
    def track_user_cohort(user_id, cohort_type, properties = {})
      return unless analytics_enabled? && user_id.present?
      
      cohort_data = {
        user_id: user_id,
        cohort_type: cohort_type,
        timestamp: Time.current,
        properties: properties
      }
      
      # Store cohort membership
      Redis.current.sadd("cohort:#{cohort_type}:#{Date.current.strftime('%Y-%m')}", user_id)
      Redis.current.hset("user_cohort:#{user_id}", cohort_type, cohort_data.to_json)
    end
    
    # Track attribution and multi-touch attribution
    def track_attribution(session_id, touchpoint_type, touchpoint_data = {})
      return unless analytics_enabled?
      
      attribution_data = {
        session_id: session_id,
        touchpoint_type: touchpoint_type,
        timestamp: Time.current,
        data: touchpoint_data
      }
      
      # Store attribution chain
      Redis.current.lpush("attribution:#{session_id}", attribution_data.to_json)
      Redis.current.expire("attribution:#{session_id}", 30.days.to_i)
    end
    
    # Track custom dimensions and metrics
    def track_custom_dimension(session_id, dimension_name, dimension_value)
      return unless analytics_enabled?
      
      dimension_data = {
        session_id: session_id,
        dimension_name: dimension_name,
        dimension_value: dimension_value,
        timestamp: Time.current
      }
      
      # Store custom dimension
      Redis.current.hset("custom_dimensions:#{session_id}", dimension_name, dimension_value)
      Redis.current.expire("custom_dimensions:#{session_id}", 30.days.to_i)
      
      # Track as event
      AnalyticsEvent.track_conversion(
        event_name: 'custom_dimension',
        session_id: session_id,
        properties: dimension_data
      )
    end
    
    # Track advanced e-commerce events (for future WooCommerce-like plugins)
    def track_ecommerce_event(event_type, session_id, user_id = nil, ecommerce_data = {})
      return unless analytics_enabled?
      
      ecommerce_event = {
        event_type: event_type,
        session_id: session_id,
        user_id: user_id,
        timestamp: Time.current,
        ecommerce_data: ecommerce_data
      }
      
      # Track e-commerce event
      AnalyticsEvent.track_conversion(
        event_name: "ecommerce_#{event_type}",
        session_id: session_id,
        user_id: user_id,
        properties: ecommerce_event
      )
    end
    
    # Track content engagement with advanced metrics
    def track_content_engagement(content_id, content_type, engagement_data = {})
      return unless analytics_enabled?
      
      engagement_metrics = {
        content_id: content_id,
        content_type: content_type,
        timestamp: Time.current,
        scroll_depth: engagement_data[:scroll_depth] || 0,
        reading_time: engagement_data[:reading_time] || 0,
        interaction_events: engagement_data[:interactions] || [],
        exit_intent: engagement_data[:exit_intent] || false,
        video_engagement: engagement_data[:video_engagement] || {},
        form_interactions: engagement_data[:form_interactions] || []
      }
      
      # Store engagement data
      Redis.current.hset("content_engagement:#{content_id}", 
                        Time.current.to_i, 
                        engagement_metrics.to_json)
      
      # Update content analytics
      update_content_analytics(content_id, content_type, engagement_metrics)
    end
    
    # Track A/B test performance
    def track_ab_test(test_id, variant, session_id, user_id = nil, conversion_data = {})
      return unless analytics_enabled?
      
      ab_test_data = {
        test_id: test_id,
        variant: variant,
        session_id: session_id,
        user_id: user_id,
        timestamp: Time.current,
        conversion_data: conversion_data
      }
      
      # Store A/B test data
      Redis.current.sadd("ab_test:#{test_id}:variant:#{variant}", session_id)
      Redis.current.hset("ab_test_session:#{session_id}", test_id, variant)
      
      # Track as event
      AnalyticsEvent.track_conversion(
        event_name: "ab_test_#{test_id}",
        session_id: session_id,
        user_id: user_id,
        properties: ab_test_data
      )
    end
    
    # Track user lifetime value and RFM analysis
    def track_user_lifetime_value(user_id, transaction_data = {})
      return unless analytics_enabled? && user_id.present?
      
      ltv_data = {
        user_id: user_id,
        timestamp: Time.current,
        transaction_value: transaction_data[:value] || 0,
        transaction_count: transaction_data[:count] || 1,
        last_transaction: transaction_data[:last_transaction] || Time.current
      }
      
      # Update user LTV
      Redis.current.hincrby("user_ltv:#{user_id}", "total_value", ltv_data[:transaction_value])
      Redis.current.hincrby("user_ltv:#{user_id}", "transaction_count", ltv_data[:transaction_count])
      Redis.current.hset("user_ltv:#{user_id}", "last_transaction", ltv_data[:last_transaction].to_i)
    end
    
    # Track predictive analytics data
    def track_predictive_data(session_id, user_id = nil, predictive_features = {})
      return unless analytics_enabled?
      
      predictive_data = {
        session_id: session_id,
        user_id: user_id,
        timestamp: Time.current,
        features: predictive_features
      }
      
      # Store for ML model training
      Redis.current.lpush("predictive_features:#{user_id || session_id}", predictive_data.to_json)
      Redis.current.expire("predictive_features:#{user_id || session_id}", 90.days.to_i)
    end
    
    # Get comprehensive user profile
    def get_user_profile(user_id)
      return {} unless user_id.present?
      
      profile_data = {
        demographics: get_user_demographics(user_id),
        behavior: get_user_behavior(user_id),
        preferences: get_user_preferences(user_id),
        lifetime_value: get_user_ltv(user_id),
        cohort_data: get_user_cohorts(user_id),
        attribution: get_user_attribution(user_id)
      }
      
      profile_data
    end
    
    # Generate advanced reports
    def generate_advanced_report(report_type, params = {})
      case report_type.to_s
      when 'attribution'
        generate_attribution_report(params)
      when 'cohort'
        generate_cohort_report(params)
      when 'funnel'
        generate_funnel_report(params)
      when 'rfm'
        generate_rfm_report(params)
      when 'predictive'
        generate_predictive_report(params)
      else
        generate_custom_report(report_type, params)
      end
    end
    
    private
    
    def analytics_enabled?
      SiteSetting.get('analytics_enabled', true)
    end
    
    def get_attribution_data(session_id)
      attribution_chain = Redis.current.lrange("attribution:#{session_id}", 0, -1)
      attribution_chain.map { |data| JSON.parse(data) rescue nil }.compact
    end
    
    def update_funnel_progress(funnel_id, step, session_id)
      Redis.current.hset("funnel_progress:#{funnel_id}", session_id, {
        current_step: step,
        timestamp: Time.current
      }.to_json)
    end
    
    def update_content_analytics(content_id, content_type, engagement_data)
      # Update content analytics in background
      ContentAnalyticsUpdateJob.perform_later(content_id, content_type, engagement_data)
    end
    
    def get_user_demographics(user_id)
      pageviews = Pageview.where(user_id: user_id).recent(1.year.ago)
      {
        countries: pageviews.group(:country_name).count,
        devices: pageviews.group(:device).count,
        browsers: pageviews.group(:browser).count,
        operating_systems: pageviews.group(:operating_system).count
      }
    end
    
    def get_user_behavior(user_id)
      pageviews = Pageview.where(user_id: user_id).recent(1.year.ago)
      {
        avg_session_duration: pageviews.average(:time_on_page) || 0,
        avg_pages_per_session: pageviews.group(:session_id).count.values.mean || 0,
        bounce_rate: calculate_user_bounce_rate(user_id),
        return_visitor: pageviews.distinct.count(:session_id) > 1
      }
    end
    
    def get_user_preferences(user_id)
      events = AnalyticsEvent.where(user_id: user_id).recent(1.year.ago)
      {
        preferred_content_types: events.where(event_name: 'content_view').group(:properties).count,
        preferred_times: events.group_by_hour(:created_at).count,
        preferred_devices: events.joins(:pageviews).group('pageviews.device').count
      }
    end
    
    def get_user_ltv(user_id)
      ltv_data = Redis.current.hgetall("user_ltv:#{user_id}")
      {
        total_value: ltv_data['total_value']&.to_f || 0,
        transaction_count: ltv_data['transaction_count']&.to_i || 0,
        last_transaction: ltv_data['last_transaction']&.to_i
      }
    end
    
    def get_user_cohorts(user_id)
      cohort_data = Redis.current.hgetall("user_cohort:#{user_id}")
      cohort_data.transform_values { |data| JSON.parse(data) rescue nil }
    end
    
    def get_user_attribution(user_id)
      # Get attribution data for user's sessions
      user_sessions = Pageview.where(user_id: user_id).distinct.pluck(:session_id)
      user_sessions.map { |session_id| get_attribution_data(session_id) }.flatten
    end
    
    def calculate_user_bounce_rate(user_id)
      user_sessions = Pageview.where(user_id: user_id).group(:session_id)
      single_page_sessions = user_sessions.having('COUNT(*) = 1').count
      total_sessions = user_sessions.count
      
      return 0 if total_sessions.zero?
      (single_page_sessions.to_f / total_sessions * 100).round(2)
    end
    
    def generate_attribution_report(params)
      # Multi-touch attribution analysis
      {
        first_touch: get_first_touch_attribution(params),
        last_touch: get_last_touch_attribution(params),
        linear: get_linear_attribution(params),
        time_decay: get_time_decay_attribution(params)
      }
    end
    
    def generate_cohort_report(params)
      # Cohort analysis by month/week
      cohorts = {}
      (0..12).each do |i|
        period = i.months.ago.strftime('%Y-%m')
        cohorts[period] = get_cohort_data(period, params)
      end
      cohorts
    end
    
    def generate_funnel_report(params)
      # Conversion funnel analysis
      funnel_id = params[:funnel_id]
      steps = Redis.current.hgetall("funnel_progress:#{funnel_id}")
      
      {
        funnel_id: funnel_id,
        steps: steps,
        conversion_rates: calculate_funnel_conversion_rates(funnel_id),
        drop_off_points: identify_drop_off_points(funnel_id)
      }
    end
    
    def generate_rfm_report(params)
      # Recency, Frequency, Monetary analysis
      users = User.joins(:pageviews).distinct
      
      {
        recency: calculate_recency_segments(users),
        frequency: calculate_frequency_segments(users),
        monetary: calculate_monetary_segments(users),
        rfm_matrix: generate_rfm_matrix(users)
      }
    end
    
    def generate_predictive_report(params)
      # Predictive analytics based on ML features
      {
        churn_prediction: predict_user_churn(params),
        lifetime_value_prediction: predict_ltv(params),
        next_purchase_prediction: predict_next_purchase(params),
        content_recommendation: recommend_content(params)
      }
    end
    
    def generate_custom_report(report_type, params)
      # Custom report generation
      {
        report_type: report_type,
        params: params,
        data: generate_custom_data(report_type, params),
        generated_at: Time.current
      }
    end
    
    # Helper methods for report generation
    def get_first_touch_attribution(params)
      # Implementation for first-touch attribution
      {}
    end
    
    def get_last_touch_attribution(params)
      # Implementation for last-touch attribution
      {}
    end
    
    def get_linear_attribution(params)
      # Implementation for linear attribution
      {}
    end
    
    def get_time_decay_attribution(params)
      # Implementation for time-decay attribution
      {}
    end
    
    def get_cohort_data(period, params)
      # Implementation for cohort data
      {}
    end
    
    def calculate_funnel_conversion_rates(funnel_id)
      # Implementation for funnel conversion rates
      {}
    end
    
    def identify_drop_off_points(funnel_id)
      # Implementation for drop-off analysis
      {}
    end
    
    def calculate_recency_segments(users)
      # Implementation for recency segments
      {}
    end
    
    def calculate_frequency_segments(users)
      # Implementation for frequency segments
      {}
    end
    
    def calculate_monetary_segments(users)
      # Implementation for monetary segments
      {}
    end
    
    def generate_rfm_matrix(users)
      # Implementation for RFM matrix
      {}
    end
    
    def predict_user_churn(params)
      # Implementation for churn prediction
      {}
    end
    
    def predict_ltv(params)
      # Implementation for LTV prediction
      {}
    end
    
    def predict_next_purchase(params)
      # Implementation for next purchase prediction
      {}
    end
    
    def recommend_content(params)
      # Implementation for content recommendation
      {}
    end
    
    def generate_custom_data(report_type, params)
      # Implementation for custom data generation
      {}
    end
  end
end
