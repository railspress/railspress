class DocumentationSyncService
  include ActiveModel::Model
  
  attr_accessor :source_url, :force_update
  
  def initialize(source_url: nil, force_update: false)
    @source_url = source_url || Rails.application.routes.url_helpers.root_url
    @force_update = force_update
  end
  
  # Sync documentation from external source
  def sync_from_source
    return false unless source_url.present?
    
    begin
      # Fetch documentation from source
      response = HTTParty.get("#{source_url}/api/documentation", timeout: 30)
      return false unless response.success?
      
      docs_data = response.parsed_response
      
      # Update theme documentation
      if docs_data['theme_development_docs'].present?
        update_site_setting('theme_development_docs', docs_data['theme_development_docs'])
      end
      
      # Update plugin documentation
      if docs_data['plugin_development_docs'].present?
        update_site_setting('plugin_development_docs', docs_data['plugin_development_docs'])
      end
      
      # Update sync timestamp
      update_site_setting('docs_last_synced_at', Time.current)
      
      Rails.logger.info "Documentation synced successfully from #{source_url}"
      true
      
    rescue => e
      Rails.logger.error "Failed to sync documentation: #{e.message}"
      false
    end
  end
  
  # Check if sync is needed
  def sync_needed?
    return true if force_update
    
    last_sync = get_site_setting('docs_last_synced_at')
    return true if last_sync.nil?
    
    # Sync if older than 24 hours
    last_sync < 24.hours.ago
  end
  
  # Auto-sync if needed
  def auto_sync
    return false unless sync_needed?
    sync_from_source
  end
  
  private
  
  def update_site_setting(key, value)
    SiteSetting.set(key, value, 'text')
  end
  
  def get_site_setting(key)
    SiteSetting.get(key)
  end
end


