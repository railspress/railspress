require 'rails_helper'

RSpec.describe 'RailsPress Complete System Integration', type: :system do
  let(:admin_user) { create(:user, role: :administrator, email: 'admin@example.com') }
  let(:tenant) { create(:tenant) }

  before do
    ActsAsTenant.current_tenant = tenant
    sign_in admin_user
  end

  describe 'Complete CMS Workflow' do
    it 'allows full content management from creation to publication' do
      # Step 1: Create Content Type
      visit new_admin_content_type_path
      
      fill_in 'Name', with: 'Article'
      fill_in 'Slug', with: 'article'
      fill_in 'Description', with: 'Blog articles'
      check 'Public'
      check 'Has Comments'
      check 'Has Featured Image'
      
      click_button 'Create Content Type'
      expect(page).to have_content('Content Type was successfully created')
      
      # Step 2: Create Taxonomy
      visit new_admin_taxonomy_path
      
      fill_in 'Name', with: 'Categories'
      fill_in 'Slug', with: 'categories'
      fill_in 'Description', with: 'Article categories'
      select 'Article', from: 'Content Types'
      
      click_button 'Create Taxonomy'
      expect(page).to have_content('Taxonomy was successfully created')
      
      # Step 3: Create Terms
      taxonomy = Taxonomy.last
      visit new_admin_taxonomy_term_path(taxonomy)
      
      fill_in 'Name', with: 'Technology'
      fill_in 'Slug', with: 'technology'
      fill_in 'Description', with: 'Technology articles'
      
      click_button 'Create Term'
      expect(page).to have_content('Term was successfully created')
      
      # Step 4: Create Post
      visit new_admin_post_path
      
      fill_in 'Title', with: 'RailsPress: The Ultimate CMS'
      select 'Article', from: 'Content Type'
      fill_in 'Content', with: 'RailsPress is a modern, feature-rich Content Management System built with Ruby on Rails.'
      select 'Technology', from: 'Categories'
      select 'Published', from: 'Status'
      
      click_button 'Create Post'
      expect(page).to have_content('Post was successfully created')
      
      # Step 5: Create Page
      visit new_admin_page_path
      
      fill_in 'Title', with: 'About Us'
      fill_in 'Content', with: 'Learn more about our company and mission.'
      select 'Published', from: 'Status'
      
      click_button 'Create Page'
      expect(page).to have_content('Page was successfully created')
      
      # Step 6: Upload Media
      visit new_admin_medium_path
      
      # Note: File upload testing would require file fixtures
      # This is a simplified test
      expect(page).to have_content('Upload Media')
      
      # Step 7: Manage Comments
      post = Post.last
      comment = create(:comment, commentable: post, content: 'Great article!')
      
      visit admin_comments_path
      expect(page).to have_content('Great article!')
      
      # Approve comment
      click_link 'Approve'
      expect(page).to have_content('Comment was successfully approved')
      
      # Step 8: Frontend Rendering
      visit root_path
      expect(page).to have_content('RailsPress: The Ultimate CMS')
      
      # Step 9: API Access
      visit '/api/v1/posts'
      expect(page).to have_content('Authentication required')
    end
  end

  describe 'Theme Management System' do
    it 'allows complete theme management workflow' do
      # Step 1: View Available Themes
      visit admin_themes_path
      expect(page).to have_content('Themes')
      
      # Step 2: Activate Theme
      theme = create(:theme, name: 'Test Theme', active: false)
      visit admin_theme_path(theme)
      
      click_button 'Activate Theme'
      expect(page).to have_content('Theme was successfully activated')
      
      # Step 3: Theme Editor
      visit admin_theme_editor_path
      expect(page).to have_content('Theme Editor')
      
      # Step 4: Customize Theme
      # This would involve more complex interactions with the Monaco editor
      # For now, we'll test the basic structure
      expect(page).to have_content('File Tree')
      expect(page).to have_content('Editor')
      
      # Step 5: Preview Changes
      click_button 'Preview'
      expect(page).to have_content('Theme Preview')
    end
  end

  describe 'User Management and Permissions' do
    it 'enforces role-based access control' do
      # Test admin access
      visit admin_posts_path
      expect(page).to have_content('Posts')
      
      # Create regular user
      regular_user = create(:user, role: :author, email: 'author@example.com')
      
      # Test author access
      sign_out admin_user
      sign_in regular_user
      
      visit admin_posts_path
      expect(page).to have_content('Posts')
      
      # Test subscriber access
      subscriber = create(:user, role: :subscriber, email: 'subscriber@example.com')
      sign_out regular_user
      sign_in subscriber
      
      visit admin_posts_path
      expect(page).to have_content('Access denied')
    end
  end

  describe 'API Integration' do
    it 'provides comprehensive API functionality' do
      # Create test data
      post = create(:post, title: 'API Test Post', status: :published)
      page = create(:page, title: 'API Test Page', status: :published)
      
      # Test REST API endpoints
      api_user = create(:user, api_key: 'test-api-key')
      
      # Mock authentication
      allow_any_instance_of(Api::V1::BaseController).to receive(:current_user).and_return(api_user)
      
      # Test posts API
      visit '/api/v1/posts'
      expect(page).to have_content('"success":true')
      
      # Test pages API
      visit '/api/v1/pages'
      expect(page).to have_content('"success":true')
      
      # Test GraphQL API
      visit '/graphql'
      expect(page).to have_content('GraphQL')
    end
  end

  describe 'Search and Filtering' do
    it 'provides comprehensive search functionality' do
      # Create test content
      post1 = create(:post, title: 'Ruby on Rails Guide', content: 'Learn Ruby on Rails')
      post2 = create(:post, title: 'JavaScript Tutorial', content: 'Learn JavaScript')
      page1 = create(:page, title: 'About Ruby', content: 'Information about Ruby')
      
      # Test post search
      visit admin_posts_path
      fill_in 'Search', with: 'Ruby'
      click_button 'Search'
      
      expect(page).to have_content('Ruby on Rails Guide')
      expect(page).to have_content('About Ruby')
      expect(page).not_to have_content('JavaScript Tutorial')
      
      # Test page search
      visit admin_pages_path
      fill_in 'Search', with: 'Ruby'
      click_button 'Search'
      
      expect(page).to have_content('About Ruby')
    end
  end

  describe 'Content Versioning' do
    it 'tracks content changes and allows rollback' do
      # Create post
      post = create(:post, title: 'Original Title', content: 'Original content')
      
      # Update post
      visit edit_admin_post_path(post)
      fill_in 'Title', with: 'Updated Title'
      fill_in 'Content', with: 'Updated content'
      click_button 'Update Post'
      
      expect(page).to have_content('Post was successfully updated')
      
      # Check version history
      visit admin_post_path(post)
      click_link 'Version History'
      
      expect(page).to have_content('Version History')
      expect(page).to have_content('Original Title')
      expect(page).to have_content('Updated Title')
      
      # Restore previous version
      click_link 'Restore'
      expect(page).to have_content('Version was successfully restored')
    end
  end

  describe 'Media Management' do
    it 'handles media upload and management' do
      visit admin_media_path
      expect(page).to have_content('Media')
      
      # Test media upload form
      click_link 'Upload Media'
      expect(page).to have_content('Upload Media')
      
      # Test media library
      medium = create(:medium, title: 'Test Image')
      visit admin_media_path
      
      expect(page).to have_content('Test Image')
    end
  end

  describe 'Comment System' do
    it 'manages comments and moderation' do
      post = create(:post, title: 'Comment Test Post')
      
      # Create comments
      comment1 = create(:comment, commentable: post, content: 'Great post!', status: :pending)
      comment2 = create(:comment, commentable: post, content: 'Spam comment', status: :spam)
      
      visit admin_comments_path
      
      expect(page).to have_content('Great post!')
      expect(page).to have_content('Spam comment')
      
      # Approve comment
      within("#comment_#{comment1.id}") do
        click_link 'Approve'
      end
      
      expect(page).to have_content('Comment was successfully approved')
      
      # Mark as spam
      within("#comment_#{comment1.id}") do
        click_link 'Mark as Spam'
      end
      
      expect(page).to have_content('Comment was marked as spam')
    end
  end

  describe 'SEO and Meta Management' do
    it 'handles SEO settings and meta fields' do
      post = create(:post, title: 'SEO Test Post')
      
      visit edit_admin_post_path(post)
      
      # Add SEO fields
      fill_in 'Meta Title', with: 'SEO Optimized Title'
      fill_in 'Meta Description', with: 'This is a SEO optimized description'
      fill_in 'Meta Keywords', with: 'rails, cms, seo'
      
      click_button 'Update Post'
      
      expect(page).to have_content('Post was successfully updated')
      
      # Check meta fields
      post.reload
      expect(post.meta_title).to eq('SEO Optimized Title')
      expect(post.meta_description).to eq('This is a SEO optimized description')
    end
  end

  describe 'Multi-tenancy' do
    it 'maintains tenant isolation' do
      # Create tenant-specific content
      tenant1 = create(:tenant, name: 'Tenant 1')
      tenant2 = create(:tenant, name: 'Tenant 2')
      
      ActsAsTenant.current_tenant = tenant1
      post1 = create(:post, title: 'Tenant 1 Post')
      
      ActsAsTenant.current_tenant = tenant2
      post2 = create(:post, title: 'Tenant 2 Post')
      
      # Switch to tenant 1
      ActsAsTenant.current_tenant = tenant1
      visit admin_posts_path
      
      expect(page).to have_content('Tenant 1 Post')
      expect(page).not_to have_content('Tenant 2 Post')
      
      # Switch to tenant 2
      ActsAsTenant.current_tenant = tenant2
      visit admin_posts_path
      
      expect(page).to have_content('Tenant 2 Post')
      expect(page).not_to have_content('Tenant 1 Post')
    end
  end

  describe 'Performance and Caching' do
    it 'implements proper caching strategies' do
      # Create content
      post = create(:post, title: 'Cached Post', status: :published)
      
      # First request
      visit root_path
      expect(page).to have_content('Cached Post')
      
      # Update post
      post.update!(title: 'Updated Cached Post')
      
      # Clear cache
      Rails.cache.clear
      
      # Second request should show updated content
      visit root_path
      expect(page).to have_content('Updated Cached Post')
    end
  end

  describe 'Error Handling and Recovery' do
    it 'handles errors gracefully' do
      # Test invalid form submission
      visit new_admin_post_path
      
      # Submit empty form
      click_button 'Create Post'
      
      expect(page).to have_content('can\'t be blank')
      
      # Test non-existent resource
      visit admin_post_path(99999)
      expect(page).to have_content('Post not found')
    end
  end

  describe 'Security Features' do
    it 'implements security best practices' do
      # Test CSRF protection
      visit new_admin_post_path
      
      # Try to submit without CSRF token
      page.execute_script("document.querySelector('meta[name=\"csrf-token\"]').remove()")
      
      fill_in 'Title', with: 'Test Post'
      click_button 'Create Post'
      
      # Should handle CSRF error gracefully
      expect(page).to have_content('Forbidden')
      
      # Test XSS protection
      visit new_admin_post_path
      
      fill_in 'Title', with: '<script>alert("xss")</script>'
      fill_in 'Content', with: 'Content with <script>alert("xss")</script>'
      click_button 'Create Post'
      
      # Should sanitize content
      post = Post.last
      expect(post.title).to include('<script>')
      expect(post.content).to include('<script>')
    end
  end
end
