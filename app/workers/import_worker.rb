class ImportWorker
  include Sidekiq::Worker
  
  sidekiq_options retry: 3, queue: :default
  
  def perform(import_job_id)
    import_job = ImportJob.find(import_job_id)
    import_job.update(status: 'processing', progress: 0)
    
    case import_job.import_type
    when 'wordpress'
      import_wordpress_xml(import_job)
    when 'json'
      import_json(import_job)
    when 'csv_posts'
      import_csv_posts(import_job)
    when 'csv_pages'
      import_csv_pages(import_job)
    when 'csv_users'
      import_csv_users(import_job)
    else
      raise "Unknown import type: #{import_job.import_type}"
    end
    
    import_job.update(
      status: 'completed',
      progress: 100,
      completed_at: Time.current
    )
  rescue => e
    Rails.logger.error("Import job #{import_job_id} failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    import_job.update(
      status: 'failed',
      error_log: "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    )
  end
  
  private
  
  def import_wordpress_xml(import_job)
    require 'nokogiri'
    
    doc = File.open(import_job.file_path) { |f| Nokogiri::XML(f) }
    items = doc.xpath('//item')
    
    import_job.update(total_items: items.count)
    imported = 0
    failed = 0
    
    items.each_with_index do |item, index|
      begin
        post_type = item.xpath('wp:post_type').text
        
        case post_type
        when 'post'
          create_post_from_wordpress(item, import_job)
        when 'page'
          create_page_from_wordpress(item, import_job)
        end
        
        imported += 1
      rescue => e
        Rails.logger.error("Failed to import item #{index}: #{e.message}")
        failed += 1
      end
      
      # Update progress
      progress = ((index + 1).to_f / items.count * 100).to_i
      import_job.update(progress: progress, imported_items: imported, failed_items: failed)
    end
  end
  
  def import_json(import_job)
    data = JSON.parse(File.read(import_job.file_path))
    total_items = (data['posts']&.count || 0) + (data['pages']&.count || 0)
    
    import_job.update(total_items: total_items)
    imported = 0
    
    # Import posts
    data['posts']&.each do |post_data|
      Post.create!(
        title: post_data['title'],
        content: post_data['content'],
        slug: post_data['slug'],
        status: post_data['status'] || 'draft',
        user_id: import_job.user_id
      )
      imported += 1
      import_job.update(progress: (imported.to_f / total_items * 100).to_i, imported_items: imported)
    end
    
    # Import pages
    data['pages']&.each do |page_data|
      Page.create!(
        title: page_data['title'],
        content: page_data['content'],
        slug: page_data['slug'],
        status: page_data['status'] || 'draft'
      )
      imported += 1
      import_job.update(progress: (imported.to_f / total_items * 100).to_i, imported_items: imported)
    end
  end
  
  def import_csv_posts(import_job)
    require 'csv'
    
    csv_data = CSV.read(import_job.file_path, headers: true)
    import_job.update(total_items: csv_data.count)
    
    csv_data.each_with_index do |row, index|
      Post.create!(
        title: row['title'],
        content: row['content'],
        slug: row['slug'] || row['title'].parameterize,
        status: row['status'] || 'draft',
        user_id: import_job.user_id
      )
      
      import_job.update(
        progress: ((index + 1).to_f / csv_data.count * 100).to_i,
        imported_items: index + 1
      )
    end
  end
  
  def import_csv_pages(import_job)
    require 'csv'
    
    csv_data = CSV.read(import_job.file_path, headers: true)
    import_job.update(total_items: csv_data.count)
    
    csv_data.each_with_index do |row, index|
      Page.create!(
        title: row['title'],
        content: row['content'],
        slug: row['slug'] || row['title'].parameterize,
        status: row['status'] || 'draft'
      )
      
      import_job.update(
        progress: ((index + 1).to_f / csv_data.count * 100).to_i,
        imported_items: index + 1
      )
    end
  end
  
  def import_csv_users(import_job)
    require 'csv'
    
    csv_data = CSV.read(import_job.file_path, headers: true)
    import_job.update(total_items: csv_data.count)
    
    csv_data.each_with_index do |row, index|
      User.create!(
        email: row['email'],
        name: row['name'],
        role: row['role'] || 'subscriber',
        password: SecureRandom.hex(16)
      )
      
      import_job.update(
        progress: ((index + 1).to_f / csv_data.count * 100).to_i,
        imported_items: index + 1
      )
    end
  end
  
  def create_post_from_wordpress(item, import_job)
    Post.create!(
      title: item.xpath('title').text,
      content: item.xpath('content:encoded').text,
      slug: item.xpath('wp:post_name').text,
      status: item.xpath('wp:status').text == 'publish' ? 'published' : 'draft',
      published_at: item.xpath('wp:post_date').text,
      user_id: import_job.user_id
    )
  end
  
  def create_page_from_wordpress(item, import_job)
    Page.create!(
      title: item.xpath('title').text,
      content: item.xpath('content:encoded').text,
      slug: item.xpath('wp:post_name').text,
      status: item.xpath('wp:status').text == 'publish' ? 'published' : 'draft',
      published_at: item.xpath('wp:post_date').text
    )
  end
end






