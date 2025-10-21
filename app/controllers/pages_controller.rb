class PagesController < ApplicationController
  include LiquidRenderable
  include Themeable
  
  def show
    path = params[:path]
    page = Page.friendly.find(path.split('/').last)
    
    # Check if visible (handles all statuses)
    unless page.visible_to_public? || can_view_page?(page)
      raise ActiveRecord::RecordNotFound
    end
    
    # Auto-publish scheduled pages
    page.check_scheduled_publish
    
    # Check password protection
    if page.password_protected? && !password_verified?(page)
      return render_liquid('password_protected', { 'page' => page })
    end
    
    comments = page.comments.approved.root_comments.order(created_at: :desc)
    
    # Determine template (check for specialized template like page.about)
    # Use page slug to determine if there's a specialized template
    custom_template_path = Rails.root.join('app', 'themes', current_theme_name, 'templates', "page.#{page.slug}.json")
    template_name = File.exist?(custom_template_path) ? "page.#{page.slug}" : 'page'
    
    render_liquid(template_name, {
      'page' => {
        'title' => page.title,
        'content' => page.content.to_s,
        'description' => page.respond_to?(:excerpt) ? page.excerpt : page.content.to_s.truncate(200),
        'featured_image' => page.respond_to?(:featured_image_url) ? page.featured_image_url : nil,
        'slug' => page.slug,
        'author' => page.user,
        'published_at' => page.published_at,
        'updated_at' => page.updated_at
      },
      'comments' => comments,
      'template' => 'page'
    })
  rescue ActiveRecord::RecordNotFound
    render_liquid_error(404)
  end
  
  # POST /pages/:path/verify_password
  def verify_password
    path = params[:path]
    @page = Page.friendly.find(path.split('/').last)
    
    if @page.password_matches?(params[:password])
      # Store verified page ID in session
      session[:verified_pages] ||= []
      session[:verified_pages] << @page.id unless session[:verified_pages].include?(@page.id)
      
      redirect_to page_path(@page.slug), notice: 'Password verified successfully.'
    else
      redirect_to page_path(@page.slug), alert: 'Incorrect password. Please try again.'
    end
  end
  
  private
  
  def can_view_page?(page)
    return false unless user_signed_in?
    
    # Admins and editors can view everything
    return true if current_user.administrator? || current_user.editor?
    
    # Authors can view their own pages
    return true if page.user_id == current_user.id
    
    # Private pages visible to any logged-in user
    return true if page.private_page_status?
    
    false
  end
  
  def password_verified?(page)
    return true unless page.password_protected?
    return true if can_view_page?(page)  # Admins/editors/authors bypass password
    
    session[:verified_pages]&.include?(page.id)
  end
end
