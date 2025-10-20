# frozen_string_literal: true

class Api::V1::AnalyticsController < Api::V1::BaseController
  before_action :authenticate_api_user!
  before_action :set_tenant
  
  # GET /api/v1/analytics/posts/:id
  def post_analytics
    post = Post.find(params[:id])
    
    analytics_data = ContentAnalyticsService.post_analytics(
      post.id, 
      period: params[:period]&.to_sym || :month
    )
    
    render json: {
      success: true,
      data: {
        post: {
          id: post.id,
          title: post.title,
          slug: post.slug,
          published_at: post.published_at,
          status: post.status
        },
        analytics: analytics_data,
        period: params[:period] || 'month',
        generated_at: Time.current.iso8601
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Post not found',
      code: 'POST_NOT_FOUND'
    }, status: :not_found
  rescue => e
    Rails.logger.error "Post analytics API error: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch post analytics',
      code: 'ANALYTICS_ERROR'
    }, status: :internal_server_error
  end
  
  # GET /api/v1/analytics/pages/:id
  def page_analytics
    page = Page.find(params[:id])
    
    analytics_data = ContentAnalyticsService.page_analytics(
      page.id,
      period: params[:period]&.to_sym || :month
    )
    
    render json: {
      success: true,
      data: {
        page: {
          id: page.id,
          title: page.title,
          slug: page.slug,
          created_at: page.created_at,
          status: page.status
        },
        analytics: analytics_data,
        period: params[:period] || 'month',
        generated_at: Time.current.iso8601
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Page not found',
      code: 'PAGE_NOT_FOUND'
    }, status: :not_found
  rescue => e
    Rails.logger.error "Page analytics API error: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch page analytics',
      code: 'ANALYTICS_ERROR'
    }, status: :internal_server_error
  end
  
  # GET /api/v1/analytics/posts
  def posts_analytics
    period = params[:period]&.to_sym || :month
    limit = [params[:limit]&.to_i || 10, 100].min
    
    posts_data = ContentAnalyticsService.top_performing_content(
      content_type: 'posts',
      period: period,
      limit: limit
    )
    
    render json: {
      success: true,
      data: {
        posts: posts_data,
        period: period.to_s,
        limit: limit,
        generated_at: Time.current.iso8601
      }
    }
  rescue => e
    Rails.logger.error "Posts analytics API error: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch posts analytics',
      code: 'ANALYTICS_ERROR'
    }, status: :internal_server_error
  end
  
  # GET /api/v1/analytics/pages
  def pages_analytics
    period = params[:period]&.to_sym || :month
    limit = [params[:limit]&.to_i || 10, 100].min
    
    pages_data = ContentAnalyticsService.top_performing_content(
      content_type: 'pages',
      period: period,
      limit: limit
    )
    
    render json: {
      success: true,
      data: {
        pages: pages_data,
        period: period.to_s,
        limit: limit,
        generated_at: Time.current.iso8601
      }
    }
  rescue => e
    Rails.logger.error "Pages analytics API error: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch pages analytics',
      code: 'ANALYTICS_ERROR'
    }, status: :internal_server_error
  end
  
  # GET /api/v1/analytics/overview
  def overview
    period = params[:period]&.to_sym || :month
    
    overview_data = {
      total_pageviews: AnalyticsService.total_pageviews(period: period),
      unique_visitors: AnalyticsService.unique_visitors(period: period),
      top_posts: ContentAnalyticsService.top_performing_content(content_type: 'posts', period: period, limit: 5),
      top_pages: ContentAnalyticsService.top_performing_content(content_type: 'pages', period: period, limit: 5),
      traffic_sources: AnalyticsService.traffic_sources(period: period),
      audience_insights: AnalyticsService.audience_insights(period: period)
    }
    
    render json: {
      success: true,
      data: {
        overview: overview_data,
        period: period.to_s,
        generated_at: Time.current.iso8601
      }
    }
  rescue => e
    Rails.logger.error "Analytics overview API error: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch analytics overview',
      code: 'ANALYTICS_ERROR'
    }, status: :internal_server_error
  end
  
  # GET /api/v1/analytics/realtime
  def realtime
    realtime_data = AnalyticsService.realtime_stats
    
    render json: {
      success: true,
      data: {
        realtime: realtime_data,
        generated_at: Time.current.iso8601
      }
    }
  rescue => e
    Rails.logger.error "Realtime analytics API error: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch realtime analytics',
      code: 'ANALYTICS_ERROR'
    }, status: :internal_server_error
  end
  
  private
  
  def authenticate_api_user!
    # Check for API key authentication
    api_key = request.headers['Authorization']&.gsub(/^Bearer /, '') || params[:api_key]
    
    if api_key.blank?
      render json: {
        success: false,
        error: 'API key required',
        code: 'MISSING_API_KEY'
      }, status: :unauthorized
      return
    end
    
    @current_user = User.find_by(api_key: api_key)
    
    unless @current_user&.administrator?
      render json: {
        success: false,
        error: 'Invalid API key or insufficient permissions',
        code: 'INVALID_API_KEY'
      }, status: :unauthorized
    end
  end
  
  def set_tenant
    ActsAsTenant.current_tenant = @current_user&.tenant
  end
end
