# frozen_string_literal: true

require 'net/http'
require 'json'

module Railspress
  class UpdateChecker
    GITHUB_REPO = ENV['RAILSPRESS_GITHUB_REPO'] || 'username/railspress'
    GITHUB_API_URL = "https://api.github.com/repos/#{GITHUB_REPO}/releases/latest"
    CURRENT_VERSION = '1.0.0'
    
    class << self
      def check_for_updates
        return cached_result if cached_result && cache_valid?
        
        begin
          latest_version = fetch_latest_version
          update_available = version_greater?(latest_version, CURRENT_VERSION)
          
          result = {
            current_version: CURRENT_VERSION,
            latest_version: latest_version,
            update_available: update_available,
            checked_at: Time.current,
            release_url: "https://github.com/#{GITHUB_REPO}/releases/latest"
          }
          
          cache_result(result)
          result
        rescue => e
          Rails.logger.error("Update check failed: #{e.message}")
          {
            current_version: CURRENT_VERSION,
            latest_version: nil,
            update_available: false,
            error: e.message,
            checked_at: Time.current
          }
        end
      end
      
      def fetch_latest_version
        uri = URI(GITHUB_API_URL)
        
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = 'application/vnd.github.v3+json'
        request['User-Agent'] = 'RailsPress'
        
        # Add GitHub token if available
        if ENV['GITHUB_TOKEN']
          request['Authorization'] = "token #{ENV['GITHUB_TOKEN']}"
        end
        
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
        
        if response.code == '200'
          data = JSON.parse(response.body)
          data['tag_name'].gsub(/^v/, '') # Remove 'v' prefix if present
        else
          raise "GitHub API returned #{response.code}: #{response.body}"
        end
      end
      
      def version_greater?(version1, version2)
        v1_parts = version1.split('.').map(&:to_i)
        v2_parts = version2.split('.').map(&:to_i)
        
        [v1_parts.length, v2_parts.length].max.times do |i|
          v1 = v1_parts[i] || 0
          v2 = v2_parts[i] || 0
          
          return true if v1 > v2
          return false if v1 < v2
        end
        
        false
      end
      
      def fetch_release_notes
        uri = URI(GITHUB_API_URL)
        
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = 'application/vnd.github.v3+json'
        request['User-Agent'] = 'RailsPress'
        
        if ENV['GITHUB_TOKEN']
          request['Authorization'] = "token #{ENV['GITHUB_TOKEN']}"
        end
        
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
        
        if response.code == '200'
          data = JSON.parse(response.body)
          {
            version: data['tag_name'],
            name: data['name'],
            body: data['body'],
            html_url: data['html_url'],
            published_at: data['published_at']
          }
        else
          nil
        end
      end
      
      private
      
      def cache_key
        'railspress:update_check'
      end
      
      def cached_result
        Rails.cache.read(cache_key)
      end
      
      def cache_result(result)
        # Cache for 6 hours
        Rails.cache.write(cache_key, result, expires_in: 6.hours)
      end
      
      def cache_valid?
        cached = cached_result
        return false unless cached
        
        cached[:checked_at] && cached[:checked_at] > 6.hours.ago
      end
    end
  end
end






