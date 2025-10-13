class ExportWorker
  include Sidekiq::Worker
  
  sidekiq_options retry: 3, queue: :default
  
  def perform(export_job_id)
    export_job = ExportJob.find(export_job_id)
    export_job.update(status: 'processing', progress: 0)
    
    case export_job.export_type
    when 'wordpress'
      export_wordpress_xml(export_job)
    when 'json'
      export_json(export_job)
    when 'csv'
      export_csv(export_job)
    when 'sql'
      export_sql(export_job)
    else
      raise "Unknown export type: #{export_job.export_type}"
    end
    
    export_job.update(
      status: 'completed',
      progress: 100
    )
  rescue => e
    Rails.logger.error("Export job #{export_job_id} failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    export_job.update(status: 'failed')
  end
  
  private
  
  def export_json(export_job)
    options = export_job.metadata
    data = {}
    total_items = 0
    exported = 0
    
    if options['include_posts']
      posts = Post.kept
      posts = posts.published_status if !options['include_drafts']
      data['posts'] = posts.map { |p| post_to_json(p) }
      total_items += posts.count
    end
    
    if options['include_pages']
      pages = Page.kept
      pages = pages.published_status if !options['include_drafts']
      data['pages'] = pages.map { |p| page_to_json(p) }
      total_items += pages.count
    end
    
    if options['include_users']
      data['users'] = User.all.map { |u| user_to_json(u) }
      total_items += User.count
    end
    
    if options['include_settings']
      data['settings'] = {
        general: Settings.general,
        writing: Settings.writing,
        reading: Settings.reading
      }
    end
    
    export_job.update(total_items: total_items)
    
    # Write to file
    file_path = Rails.root.join('tmp', "export_#{export_job.id}.json")
    File.write(file_path, options['prettify_json'] ? JSON.pretty_generate(data) : data.to_json)
    
    export_job.update(
      file_path: file_path.to_s,
      file_name: "railspress_export_#{Date.today}.json",
      content_type: 'application/json',
      exported_items: total_items
    )
  end
  
  def export_wordpress_xml(export_job)
    # Generate WordPress WXR format
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.rss('version' => '2.0', 
              'xmlns:excerpt' => 'http://wordpress.org/export/1.2/excerpt/',
              'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
              'xmlns:wp' => 'http://wordpress.org/export/1.2/') do
        xml.channel do
          xml.title Settings.site_title
          xml.link request.base_url
          
          posts = Post.kept
          posts.each do |post|
            xml.item do
              xml.title post.title
              xml.link "#{request.base_url}/blog/#{post.slug}"
              xml['content'].encoded { xml.cdata post.content.to_s }
              xml['wp'].post_name post.slug
              xml['wp'].status post.published_status? ? 'publish' : 'draft'
              xml['wp'].post_type 'post'
              xml['wp'].post_date post.created_at.strftime('%Y-%m-%d %H:%M:%S')
            end
          end
        end
      end
    end
    
    file_path = Rails.root.join('tmp', "export_#{export_job.id}.xml")
    File.write(file_path, builder.to_xml)
    
    export_job.update(
      file_path: file_path.to_s,
      file_name: "wordpress_export_#{Date.today}.xml",
      content_type: 'application/xml',
      exported_items: Post.kept.count
    )
  end
  
  def post_to_json(post)
    {
      id: post.id,
      title: post.title,
      slug: post.slug,
      content: post.content.to_s,
      excerpt: post.excerpt,
      status: post.status,
      published_at: post.published_at,
      author: post.user&.email,
      categories: post.terms.joins(:taxonomy).where(taxonomies: { slug: 'category' }).pluck(:name),
      tags: post.terms.joins(:taxonomy).where(taxonomies: { slug: 'tag' }).pluck(:name)
    }
  end
  
  def page_to_json(page)
    {
      id: page.id,
      title: page.title,
      slug: page.slug,
      content: page.content.to_s,
      status: page.status,
      published_at: page.published_at
    }
  end
  
  def user_to_json(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      created_at: user.created_at
    }
  end
end



