class CspReportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :set_current_tenant
  
  def create
    if Rails.env.development?
      Rails.logger.warn "CSP Violation: #{csp_report_params.inspect}"
    end
    
    # In production, you might want to store these or send to monitoring service
    # CspViolation.create(report: csp_report_params) if Rails.env.production?
    
    head :no_content
  end
  
  private
  
  def csp_report_params
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    {}
  end
end






