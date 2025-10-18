require 'rails_helper'

RSpec.describe 'Posts, Pages, and Users Integration', type: :integration do
  let(:tenant) { create(:tenant) }
  let(:admin_user) { create(:user, :administrator, tenant: tenant) }
  let(:author_user) { create(:user, :author, tenant: tenant) }
  let(:editor_user) { create(:user, :editor, tenant: tenant) }
  let(:subscriber_user) { create(:user, :subscriber, tenant: tenant) }

  describe 'user permissions and content creation' do
    it 'allows administrators to create posts and pages' do
      expect(admin_user.can_create_posts?).to be true
      expect(admin_user.can_create_pages?).to be true
      expect(admin_user.can_upload_media?).to be true
    end

    it 'allows editors to create posts and pages' do
      expect(editor_user.can_create_posts?).to be true
      expect(editor_user.can_create_pages?).to be true
      expect(editor_user.can_upload_media?).to be true
    end

    it 'allows authors to create posts but not pages' do
      expect(author_user.can_create_posts?).to be true
      expect(author_user.can_create_pages?).to be false
      expect(author_user.can_upload_media?).to be true
    end

    it 'restricts subscribers from creating content' do
      expect(subscriber_user.can_create_posts?).to be false
      expect(subscriber_user.can_create_pages?).to be false
      expect(subscriber_user.can_upload_media?).to be false
    end
  end

  describe 'content ownership and management' do
    let(:admin_post) { create(:post, user: admin_user, tenant: tenant) }
    let(:author_post) { create(:post, user: author_user, tenant: tenant) }
    let(:admin_page) { create(:page, user: admin_user, tenant: tenant) }
    let(:editor_page) { create(:page, user: editor_user, tenant: tenant) }

    it 'allows users to own their content' do
      expect(admin_post.user).to eq(admin_user)
      expect(author_post.user).to eq(author_user)
      expect(admin_page.user).to eq(admin_user)
      expect(editor_page.user).to eq(editor_user)
    end

    it 'allows administrators to manage all content' do
      expect(admin_user.can_edit_others_posts?).to be true
      expect(admin_user.can_delete_posts?).to be true
    end

    it 'allows editors to edit others posts but not delete' do
      expect(editor_user.can_edit_others_posts?).to be true
      expect(editor_user.can_delete_posts?).to be false
    end

    it 'restricts authors from editing others content' do
      expect(author_user.can_edit_others_posts?).to be false
      expect(author_user.can_delete_posts?).to be false
    end
  end

  describe 'content status and visibility' do
    let(:published_post) { create(:post, :published, user: author_user, tenant: tenant) }
    let(:draft_post) { create(:post, :draft, user: author_user, tenant: tenant) }
    let(:scheduled_post) { create(:post, :scheduled, user: author_user, tenant: tenant) }
    let(:private_post) { create(:post, :private, user: author_user, tenant: tenant) }
    let(:published_page) { create(:page, :published, user: editor_user, tenant: tenant) }
    let(:draft_page) { create(:page, :draft, user: editor_user, tenant: tenant) }

    it 'shows published content as visible to public' do
      expect(published_post.visible_to_public?).to be true
      expect(published_page.visible_to_public?).to be true
    end

    it 'hides draft content from public' do
      expect(draft_post.visible_to_public?).to be false
      expect(draft_page.visible_to_public?).to be false
    end

    it 'shows scheduled content when published_at has passed' do
      scheduled_post.update!(published_at: 1.hour.ago)
      expect(scheduled_post.visible_to_public?).to be true
    end

    it 'hides scheduled content when published_at is in future' do
      scheduled_post.update!(published_at: 1.hour.from_now)
      expect(scheduled_post.visible_to_public?).to be false
    end

    it 'hides private content from public' do
      expect(private_post.visible_to_public?).to be false
    end
  end

  describe 'content with taxonomies' do
    let(:category_taxonomy) { create(:taxonomy, :category, tenant: tenant) }
    let(:tag_taxonomy) { create(:taxonomy, :post_tag, tenant: tenant) }
    let(:category) { create(:term, taxonomy: category_taxonomy, tenant: tenant) }
    let(:tag) { create(:term, taxonomy: tag_taxonomy, tenant: tenant) }
    let(:post) { create(:post, user: author_user, tenant: tenant) }
    let(:page) { create(:page, user: editor_user, tenant: tenant) }

    it 'allows posts to have categories and tags' do
      post.category = [category]
      post.post_tag = [tag]
      
      expect(post.category).to include(category)
      expect(post.post_tag).to include(tag)
      expect(post.terms).to include(category, tag)
    end

    it 'allows pages to have taxonomies' do
      page.add_term(category, 'category')
      page.add_term(tag, 'post_tag')
      
      expect(page.terms).to include(category, tag)
    end

    it 'maintains taxonomy relationships across content types' do
      post.category = [category]
      page.add_term(category, 'category')
      
      expect(category.posts).to include(post)
      expect(category.objects).to include(post, page)
    end
  end

  describe 'content with custom fields' do
    let(:field_group) { create(:field_group, tenant: tenant) }
    let(:custom_field) { create(:custom_field, field_group: field_group, tenant: tenant) }
    let(:post) { create(:post, user: author_user, tenant: tenant) }
    let(:page) { create(:page, user: editor_user, tenant: tenant) }

    it 'allows posts to have custom fields' do
      post.set_field('test_field', 'test_value')
      expect(post.get_field('test_field')).to eq('test_value')
    end

    it 'allows pages to have custom fields' do
      page.set_field('test_field', 'test_value')
      expect(page.get_field('test_field')).to eq('test_value')
    end

    it 'maintains field isolation between content types' do
      post.set_field('shared_field', 'post_value')
      page.set_field('shared_field', 'page_value')
      
      expect(post.get_field('shared_field')).to eq('post_value')
      expect(page.get_field('shared_field')).to eq('page_value')
    end
  end

  describe 'hierarchical content structure' do
    let(:parent_page) { create(:page, user: editor_user, tenant: tenant) }
    let(:child_page) { create(:page, :with_parent, parent: parent_page, user: editor_user, tenant: tenant) }
    let(:grandchild_page) { create(:page, :with_parent, parent: child_page, user: editor_user, tenant: tenant) }

    it 'supports page hierarchy' do
      expect(child_page.parent).to eq(parent_page)
      expect(parent_page.children).to include(child_page)
      expect(grandchild_page.parent).to eq(child_page)
    end

    it 'generates correct breadcrumbs' do
      breadcrumbs = grandchild_page.breadcrumbs
      expect(breadcrumbs).to eq([parent_page, child_page, grandchild_page])
    end

    it 'deletes children when parent is destroyed' do
      child_id = child_page.id
      grandchild_id = grandchild_page.id
      
      parent_page.destroy
      
      expect(Page.find_by(id: child_id)).to be_nil
      expect(Page.find_by(id: grandchild_id)).to be_nil
    end
  end

  describe 'content with comments' do
    let(:post) { create(:post, user: author_user, tenant: tenant) }
    let(:page) { create(:page, user: editor_user, tenant: tenant) }
    let(:post_comment) { create(:comment, commentable: post, user: subscriber_user, tenant: tenant) }
    let(:page_comment) { create(:comment, commentable: page, user: subscriber_user, tenant: tenant) }

    it 'allows posts to have comments' do
      expect(post.comments).to include(post_comment)
      expect(post_comment.commentable).to eq(post)
    end

    it 'allows pages to have comments' do
      expect(page.comments).to include(page_comment)
      expect(page_comment.commentable).to eq(page)
    end

    it 'deletes comments when content is destroyed' do
      post_comment_id = post_comment.id
      page_comment_id = page_comment.id
      
      post.destroy
      page.destroy
      
      expect(Comment.find_by(id: post_comment_id)).to be_nil
      expect(Comment.find_by(id: page_comment_id)).to be_nil
    end
  end

  describe 'multi-tenancy isolation' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }
    let(:user1) { create(:user, :author, tenant: tenant1) }
    let(:user2) { create(:user, :author, tenant: tenant2) }
    let(:post1) { create(:post, user: user1, tenant: tenant1, slug: 'test-post') }
    let(:post2) { create(:post, user: user2, tenant: tenant2, slug: 'test-post') }
    let(:page1) { create(:page, user: user1, tenant: tenant1, slug: 'test-page') }
    let(:page2) { create(:page, user: user2, tenant: tenant2, slug: 'test-page') }

    it 'isolates posts by tenant' do
      expect(post1.slug).to eq(post2.slug)
      expect(post1.tenant).not_to eq(post2.tenant)
      expect(post1.user.tenant).not_to eq(post2.user.tenant)
    end

    it 'isolates pages by tenant' do
      expect(page1.slug).to eq(page2.slug)
      expect(page1.tenant).not_to eq(page2.tenant)
      expect(page1.user.tenant).not_to eq(page2.user.tenant)
    end

    it 'isolates users by tenant' do
      expect(user1.tenant).not_to eq(user2.tenant)
    end
  end

  describe 'content search and filtering' do
    let(:ruby_post) { create(:post, title: 'Ruby on Rails', user: author_user, tenant: tenant) }
    let(:js_post) { create(:post, title: 'JavaScript Guide', user: author_user, tenant: tenant) }
    let(:about_page) { create(:page, title: 'About Us', user: editor_user, tenant: tenant) }
    let(:contact_page) { create(:page, title: 'Contact Information', user: editor_user, tenant: tenant) }

    it 'searches posts by title and content' do
      results = Post.search('Ruby')
      expect(results).to include(ruby_post)
      expect(results).not_to include(js_post)
    end

    it 'searches pages by title and content' do
      results = Page.search('About')
      expect(results).to include(about_page)
      expect(results).not_to include(contact_page)
    end

    it 'filters content by status' do
      draft_post = create(:post, :draft, user: author_user, tenant: tenant)
      published_posts = Post.published
      
      expect(published_posts).to include(ruby_post, js_post)
      expect(published_posts).not_to include(draft_post)
    end
  end

  describe 'content versioning' do
    let(:post) { create(:post, user: author_user, tenant: tenant) }
    let(:page) { create(:page, user: editor_user, tenant: tenant) }

    it 'tracks post versions' do
      initial_version_count = post.versions.count
      post.update!(title: 'Updated Title')
      expect(post.versions.count).to eq(initial_version_count + 1)
    end

    it 'tracks page versions' do
      initial_version_count = page.versions.count
      page.update!(title: 'Updated Title')
      expect(page.versions.count).to eq(initial_version_count + 1)
    end
  end

  describe 'content with SEO optimization' do
    let(:post) { create(:post, user: author_user, tenant: tenant) }
    let(:page) { create(:page, user: editor_user, tenant: tenant) }

    it 'generates structured data for posts' do
      structured_data = post.structured_data
      expect(structured_data['@type']).to eq('Post')
      expect(structured_data['headline']).to eq(post.title)
    end

    it 'generates structured data for pages' do
      structured_data = page.structured_data
      expect(structured_data['@type']).to eq('Page')
      expect(structured_data['headline']).to eq(page.title)
    end

    it 'provides SEO-friendly URLs' do
      expect(post.seo_default_url).to include(post.slug)
      expect(page.seo_default_url).to include(page.slug)
    end
  end

  describe 'content trash functionality' do
    let(:post) { create(:post, user: author_user, tenant: tenant) }
    let(:page) { create(:page, user: editor_user, tenant: tenant) }

    it 'allows posts to be trashed and restored' do
      post.trash!
      expect(post.trashed?).to be true
      
      post.restore!
      expect(post.trashed?).to be false
    end

    it 'allows pages to be trashed and restored' do
      page.trash!
      expect(page.trashed?).to be true
      
      page.restore!
      expect(page.trashed?).to be false
    end
  end
end
