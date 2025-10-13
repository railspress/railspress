# FluentFormsIntegrationJob
# Handles third-party integrations (Slack, Mailchimp, Webhooks, etc.)

class FluentFormsIntegrationJob < ApplicationJob
  queue_as :default
  
  def perform(submission_id)
    @submission = fetch_submission(submission_id)
    return unless @submission
    
    @form = fetch_form(@submission[:form_id])
    return unless @form
    
    @plugin = FluentFormsPro.new
    
    # Process all enabled integrations
    process_slack_integration if slack_enabled?
    process_mailchimp_integration if mailchimp_enabled?
    process_webhook_integration if webhook_enabled?
    process_zapier_integration if zapier_enabled?
    
    log_integration(submission_id, 'Integrations processed successfully')
    
  rescue => e
    Rails.logger.error "[Fluent Forms] Integration error: #{e.message}"
    log_integration(submission_id, "Integration failed: #{e.message}")
  end
  
  private
  
  def fetch_submission(submission_id)
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM ff_submissions WHERE id = ? LIMIT 1",
      submission_id
    ).first
    
    return nil unless result
    
    {
      id: result[0],
      form_id: result[1],
      serial_number: result[2],
      response_data: JSON.parse(result[3] || '{}'),
      created_at: result[14]
    }
  end
  
  def fetch_form(form_id)
    result = ActiveRecord::Base.connection.execute(
      "SELECT * FROM ff_forms WHERE id = ? LIMIT 1",
      form_id
    ).first
    
    return nil unless result
    
    {
      id: result[0],
      title: result[1],
      settings: JSON.parse(result[3] || '{}')
    }
  end
  
  # Slack Integration
  def slack_enabled?
    webhook_url = @plugin.get_setting('slack_webhook_url')
    integrations = @form[:settings][:integrations] || {}
    webhook_url.present? && integrations.dig(:slack, :enabled)
  end
  
  def process_slack_integration
    webhook_url = @plugin.get_setting('slack_webhook_url')
    
    message = format_slack_message
    
    uri = URI(webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = message.to_json
    
    response = http.request(request)
    
    if response.code.to_i == 200
      Rails.logger.info "[Fluent Forms] Slack notification sent for submission #{@submission[:id]}"
    else
      Rails.logger.error "[Fluent Forms] Slack notification failed: #{response.body}"
    end
  end
  
  def format_slack_message
    fields = @submission[:response_data].map do |key, value|
      {
        title: key.titleize,
        value: value,
        short: value.to_s.length < 40
      }
    end
    
    {
      text: "New form submission: #{@form[:title]}",
      attachments: [
        {
          color: '#36a64f',
          fields: fields,
          footer: 'Fluent Forms Pro',
          ts: Time.current.to_i
        }
      ]
    }
  end
  
  # Mailchimp Integration
  def mailchimp_enabled?
    api_key = @plugin.get_setting('mailchimp_api_key')
    integrations = @form[:settings][:integrations] || {}
    api_key.present? && integrations.dig(:mailchimp, :enabled)
  end
  
  def process_mailchimp_integration
    api_key = @plugin.get_setting('mailchimp_api_key')
    list_id = @form[:settings].dig(:integrations, :mailchimp, :list_id)
    
    return unless list_id.present?
    
    email = find_email_in_submission
    return unless email.present?
    
    # Extract datacenter from API key
    datacenter = api_key.split('-').last
    
    uri = URI("https://#{datacenter}.api.mailchimp.com/3.0/lists/#{list_id}/members")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.basic_auth('apikey', api_key)
    request.body = {
      email_address: email,
      status: 'subscribed',
      merge_fields: extract_merge_fields
    }.to_json
    
    response = http.request(request)
    
    if response.code.to_i.between?(200, 299)
      Rails.logger.info "[Fluent Forms] Mailchimp subscriber added for submission #{@submission[:id]}"
    else
      Rails.logger.error "[Fluent Forms] Mailchimp failed: #{response.body}"
    end
  rescue => e
    Rails.logger.error "[Fluent Forms] Mailchimp error: #{e.message}"
  end
  
  def extract_merge_fields
    fields = {}
    
    # Map common fields
    if @submission[:response_data]['name'].present?
      name_parts = @submission[:response_data]['name'].split(' ', 2)
      fields['FNAME'] = name_parts[0]
      fields['LNAME'] = name_parts[1] if name_parts[1]
    end
    
    fields['FNAME'] = @submission[:response_data]['first_name'] if @submission[:response_data]['first_name']
    fields['LNAME'] = @submission[:response_data]['last_name'] if @submission[:response_data]['last_name']
    fields['PHONE'] = @submission[:response_data]['phone'] if @submission[:response_data]['phone']
    
    fields
  end
  
  # Webhook Integration
  def webhook_enabled?
    webhooks = @form[:settings].dig(:integrations, :webhooks) || []
    webhooks.any? { |w| w[:enabled] }
  end
  
  def process_webhook_integration
    webhooks = @form[:settings].dig(:integrations, :webhooks) || []
    
    webhooks.each do |webhook|
      next unless webhook[:enabled] && webhook[:url].present?
      
      send_webhook(webhook)
    end
  end
  
  def send_webhook(webhook)
    uri = URI(webhook[:url])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = {
      form_id: @form[:id],
      form_title: @form[:title],
      submission_id: @submission[:id],
      serial_number: @submission[:serial_number],
      data: @submission[:response_data],
      created_at: @submission[:created_at]
    }.to_json
    
    response = http.request(request)
    
    if response.code.to_i.between?(200, 299)
      Rails.logger.info "[Fluent Forms] Webhook sent to #{webhook[:url]}"
    else
      Rails.logger.error "[Fluent Forms] Webhook failed: #{response.code} - #{response.body}"
    end
  rescue => e
    Rails.logger.error "[Fluent Forms] Webhook error: #{e.message}"
  end
  
  # Zapier Integration
  def zapier_enabled?
    @plugin.setting_enabled?('zapier_enabled')
  end
  
  def process_zapier_integration
    zapier_webhook = @form[:settings].dig(:integrations, :zapier, :webhook_url)
    return unless zapier_webhook.present?
    
    send_webhook({ url: zapier_webhook, enabled: true })
  end
  
  # Helper methods
  def find_email_in_submission
    @submission[:response_data].values.find { |v| v.to_s.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i) }
  end
  
  def log_integration(submission_id, message)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO ff_logs (submission_id, form_id, log_type, title, description, created_at) 
       VALUES (?, ?, ?, ?, ?, ?)",
      submission_id,
      @submission[:form_id],
      'integration',
      'Third-party Integration',
      message,
      Time.current
    )
  rescue => e
    Rails.logger.error "[Fluent Forms] Log error: #{e.message}"
  end
end

