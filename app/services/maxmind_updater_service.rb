class MaxmindUpdaterService
  include Singleton

  MAXMIND_BASE_URL = 'https://download.maxmind.com/app/geoip_download'
  DATABASE_DIR = Rails.root.join('db', 'maxmind')
  
  DATABASES = {
    'country' => {
      edition_id: 'GeoLite2-Country',
      filename: 'GeoLite2-Country.mmdb'
    },
    'city' => {
      edition_id: 'GeoLite2-City',
      filename: 'GeoLite2-City.mmdb'
    }
  }.freeze

  def initialize
    ensure_database_directory
  end

  def update_database(type = 'country')
    return { success: false, message: 'MaxMind license key not configured' } unless license_key_configured?
    return { success: false, message: 'Invalid database type' } unless DATABASES.key?(type)
    
    database_info = DATABASES[type]
    download_url = build_download_url(database_info[:edition_id])
    target_path = DATABASE_DIR.join(database_info[:filename])
    temp_path = target_path.to_s + '.tmp'
    
    begin
      Rails.logger.info "Starting MaxMind #{type} database update..."
      
      # Download the database
      response = download_database(download_url)
      return { success: false, message: "Download failed: #{response[:error]}" } unless response[:success]
      
      # Write to temporary file
      File.write(temp_path, response[:data])
      
      # Verify the downloaded file
      unless valid_mmdb_file?(temp_path)
        File.delete(temp_path) if File.exist?(temp_path)
        return { success: false, message: 'Downloaded file is not a valid MMDB database' }
      end
      
      # Backup existing database if it exists
      if File.exist?(target_path)
        backup_path = target_path.to_s + ".backup.#{Time.current.to_i}"
        File.rename(target_path, backup_path)
      end
      
      # Move temp file to final location
      File.rename(temp_path, target_path)
      
      # Clean up backup if everything is successful
      if File.exist?(backup_path)
        File.delete(backup_path)
      end
      
      # Update last update timestamp
      update_last_update_timestamp(type)
      
      Rails.logger.info "MaxMind #{type} database updated successfully"
      { success: true, message: "#{type.capitalize} database updated successfully", path: target_path }
      
    rescue => e
      Rails.logger.error "MaxMind database update failed: #{e.message}"
      
      # Clean up temp file
      File.delete(temp_path) if File.exist?(temp_path)
      
      { success: false, message: "Update failed: #{e.message}" }
    end
  end

  def update_all_databases
    results = {}
    
    DATABASES.keys.each do |type|
      results[type] = update_database(type)
    end
    
    results
  end

  def check_database_age(type = 'country')
    return { error: 'Invalid database type' } unless DATABASES.key?(type)
    
    database_info = DATABASES[type]
    target_path = DATABASE_DIR.join(database_info[:filename])
    
    if File.exist?(target_path)
      stat = File.stat(target_path)
      age_days = (Time.current - stat.mtime) / 1.day
      
      {
        exists: true,
        age_days: age_days.round(1),
        last_modified: stat.mtime,
        size: stat.size,
        needs_update: age_days > 30 # MaxMind recommends updating monthly
      }
    else
      {
        exists: false,
        needs_update: true
      }
    end
  end

  def schedule_auto_update
    return { success: false, message: 'Auto-update not enabled' } unless auto_update_enabled?
    
    # Check if databases need updating
    needs_update = false
    DATABASES.keys.each do |type|
      age_info = check_database_age(type)
      if age_info[:needs_update]
        needs_update = true
        break
      end
    end
    
    return { success: true, message: 'Databases are up to date' } unless needs_update
    
    # Update databases in background
    Thread.new do
      begin
        update_all_databases
        Rails.logger.info "Scheduled MaxMind database update completed"
      rescue => e
        Rails.logger.error "Scheduled MaxMind database update failed: #{e.message}"
      end
    end
    
    { success: true, message: 'Auto-update scheduled' }
  end

  def test_connection
    return { success: false, message: 'MaxMind license key not configured' } unless license_key_configured?
    
    begin
      # Test download with a small request
      test_url = build_download_url('GeoLite2-Country', suffix: '.tar.gz')
      response = HTTP.timeout(10).get(test_url)
      
      if response.status == 200
        { success: true, message: 'Connection to MaxMind successful' }
      else
        { success: false, message: "HTTP #{response.status}: #{response.reason}" }
      end
    rescue => e
      { success: false, message: "Connection failed: #{e.message}" }
    end
  end

  def database_info
    info = {}
    
    DATABASES.each do |type, config|
      target_path = DATABASE_DIR.join(config[:filename])
      
      if File.exist?(target_path)
        stat = File.stat(target_path)
        info[type] = {
          exists: true,
          path: target_path,
          size: stat.size,
          last_modified: stat.mtime,
          age_days: ((Time.current - stat.mtime) / 1.day).round(1),
          needs_update: (Time.current - stat.mtime) > 30.days
        }
      else
        info[type] = {
          exists: false,
          needs_update: true
        }
      end
    end
    
    info
  end

  private

  def ensure_database_directory
    FileUtils.mkdir_p(DATABASE_DIR) unless Dir.exist?(DATABASE_DIR)
  end

  def license_key_configured?
    SiteSetting.get('maxmind_license_key', '').present?
  end

  def auto_update_enabled?
    SiteSetting.get('maxmind_auto_update', false)
  end

  def build_download_url(edition_id, suffix = '.mmdb')
    license_key = SiteSetting.get('maxmind_license_key', '')
    "#{MAXMIND_BASE_URL}?edition_id=#{edition_id}&license_key=#{license_key}&suffix=#{suffix}"
  end

  def download_database(url)
    begin
      response = HTTP.timeout(30).get(url)
      
      if response.status == 200
        { success: true, data: response.body.to_s }
      else
        { success: false, error: "HTTP #{response.status}: #{response.reason}" }
      end
    rescue => e
      { success: false, error: e.message }
    end
  end

  def valid_mmdb_file?(file_path)
    begin
      # Try to open the file with MaxMindDB to verify it's valid
      db = MaxMindDB.new(file_path)
      # If we can create the object without error, it's likely valid
      true
    rescue => e
      Rails.logger.error "Invalid MMDB file: #{e.message}"
      false
    end
  end

  def update_last_update_timestamp(type)
    SiteSetting.set("maxmind_#{type}_last_update", Time.current.iso8601)
  end
  
  # Scheduling methods for automatic updates
  def schedule_auto_update(frequency = 'weekly')
    # Schedule automatic updates using Sidekiq-Cron
    cron_schedule = case frequency
                   when 'daily'
                     '0 2 * * *' # Daily at 2 AM
                   when 'weekly'
                     '0 2 * * 1' # Weekly on Monday at 2 AM
                   when 'monthly'
                     '0 2 1 * *' # Monthly on 1st at 2 AM
                   else
                     '0 2 * * 1' # Default to weekly
                   end
    
    # Remove existing job if it exists
    Sidekiq::Cron::Job.destroy('MaxMind Database Update')
    
    # Create new scheduled job
    Sidekiq::Cron::Job.create(
      name: 'MaxMind Database Update',
      cron: cron_schedule,
      class: 'MaxmindUpdateJob',
      args: ['full'],
      description: "Automatic MaxMind database update (#{frequency})"
    )
    
    # Store the schedule preference
    SiteSetting.set('maxmind_update_frequency', frequency)
    SiteSetting.set('maxmind_auto_update_enabled', true)
    
    Rails.logger.info "MaxMind automatic update scheduled: #{frequency} (#{cron_schedule})"
  end
  
  def disable_auto_update
    # Remove the scheduled job
    Sidekiq::Cron::Job.destroy('MaxMind Database Update')
    
    # Update settings
    SiteSetting.set('maxmind_auto_update_enabled', false)
    
    Rails.logger.info "MaxMind automatic update disabled"
  end
  
  def get_update_schedule_info
    job = Sidekiq::Cron::Job.find('MaxMind Database Update')
    
    if job
      {
        enabled: true,
        frequency: SiteSetting.get('maxmind_update_frequency', 'weekly'),
        next_run: job.next_time,
        last_run: get_last_update_time,
        cron_schedule: job.cron
      }
    else
      {
        enabled: false,
        frequency: nil,
        next_run: nil,
        last_run: get_last_update_time,
        cron_schedule: nil
      }
    end
  end
  
  def get_last_update_time
    last_update = SiteSetting.get('maxmind_last_update')
    last_update ? Time.parse(last_update) : nil
  end
  
  def check_and_update_if_needed
    # Check if databases need updating and update if necessary
    needs_update = false
    
    DATABASES.keys.each do |type|
      age_info = check_database_age(type)
      if age_info[:needs_update]
        needs_update = true
        break
      end
    end
    
    if needs_update
      Rails.logger.info "MaxMind databases need updating, starting automatic update"
      MaxmindUpdateJob.perform_later('full')
    else
      Rails.logger.info "MaxMind databases are up to date"
    end
  end
end
