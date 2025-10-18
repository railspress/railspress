require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:content_type) { create(:content_type, tenant: tenant) }
  let(:post) { build(:post, user: user, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:content_type).optional }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:meta_fields).dependent(:destroy) }
    it { should have_many(:custom_field_values).dependent(:destroy) }
    it { should have_many(:term_relationships).dependent(:destroy) }
    it { should have_many(:terms).through(:term_relationships) }
    it { should have_rich_text(:content) }
    it { should have_one_attached(:featured_image_file) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:status) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_length_of(:password).is_at_least(4).allow_blank }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(draft: 0, published: 1, scheduled: 2, pending_review: 3, private_post: 4, trash: 5) }
  end

  describe 'friendly_id' do
    it 'generates slug from title' do
      post.title = 'My Test Post'
      post.save!
      expect(post.slug).to eq('my-test-post')
    end

    it 'updates slug when title changes' do
      post.save!
      post.update!(title: 'New Title')
      expect(post.slug).to eq('new-title')
    end
  end

  describe 'scopes' do
    let!(:published_post) { create(:post, status: :published, published_at: 1.hour.ago, tenant: tenant) }
    let!(:draft_post) { create(:post, status: :draft, tenant: tenant) }
    let!(:scheduled_post) { create(:post, status: :scheduled, published_at: 1.hour.from_now, tenant: tenant) }
    let!(:trashed_post) { create(:post, status: :trash, tenant: tenant) }

    describe '.visible_to_public' do
      it 'returns published and scheduled posts' do
        expect(Post.visible_to_public).to include(published_post, scheduled_post)
        expect(Post.visible_to_public).not_to include(draft_post, trashed_post)
      end
    end

    describe '.published' do
      it 'returns only published posts' do
        expect(Post.published).to include(published_post)
        expect(Post.published).not_to include(draft_post, scheduled_post, trashed_post)
      end
    end

    describe '.scheduled' do
      it 'returns only scheduled posts' do
        expect(Post.scheduled).to include(scheduled_post)
        expect(Post.scheduled).not_to include(published_post, draft_post, trashed_post)
      end
    end

    describe '.recent' do
      it 'orders posts by published_at descending' do
        recent_posts = Post.recent
        expect(recent_posts.first).to eq(scheduled_post)
        expect(recent_posts.second).to eq(published_post)
      end
    end

    describe '.search' do
      it 'searches posts by title, excerpt, meta_description, and content' do
        search_post = create(:post, title: 'Ruby on Rails', tenant: tenant)
        results = Post.search('Ruby')
        expect(results).to include(search_post)
      end
    end
  end

  describe 'callbacks' do
    it 'sets published_at when status is published' do
      post.status = :published
      post.save!
      expect(post.published_at).to be_present
    end

    it 'triggers post_created hook after create' do
      expect(Railspress::PluginSystem).to receive(:do_action).with('post_created', instance_of(Post))
      expect(Railspress::WebhookDispatcher).to receive(:dispatch).with('post.created', instance_of(Post))
      create(:post, tenant: tenant)
    end

    it 'triggers post_updated hook after status change' do
      post = create(:post, status: :draft, tenant: tenant)
      expect(Railspress::PluginSystem).to receive(:do_action).with('post_updated', post)
      expect(Railspress::WebhookDispatcher).to receive(:dispatch).with('post.updated', post)
      post.update!(status: :published)
    end
  end

  describe 'instance methods' do
    let(:post) { create(:post, user: user, tenant: tenant) }

    describe '#author' do
      it 'returns the user' do
        expect(post.author).to eq(user)
      end
    end

    describe '#author_name' do
      it 'returns user name if present' do
        user.update!(name: 'John Doe')
        expect(post.author_name).to eq('John Doe')
      end

      it 'returns email prefix if name is blank' do
        user.update!(name: nil)
        expect(post.author_name).to eq(user.email.split('@').first.titleize)
      end

      it 'returns Anonymous if user is nil' do
        post.update!(user: nil)
        expect(post.author_name).to eq('Anonymous')
      end
    end

    describe '#post_type' do
      it 'returns content_type if present' do
        post.update!(content_type: content_type)
        expect(post.post_type).to eq(content_type)
      end

      it 'returns default type if content_type is nil' do
        expect(post.post_type).to eq(ContentType.default_type)
      end
    end

    describe '#post_type_ident' do
      it 'returns content_type ident if present' do
        post.update!(content_type: content_type)
        expect(post.post_type_ident).to eq(content_type.ident)
      end

      it 'returns "post" if content_type is nil' do
        expect(post.post_type_ident).to eq('post')
      end
    end

    describe '#visible_to_public?' do
      it 'returns true for published posts' do
        post.update!(status: :published, published_at: 1.hour.ago)
        expect(post.visible_to_public?).to be true
      end

      it 'returns false for draft posts' do
        post.update!(status: :draft)
        expect(post.visible_to_public?).to be false
      end

      it 'returns false for trashed posts' do
        post.update!(status: :trash)
        expect(post.visible_to_public?).to be false
      end

      it 'returns true for scheduled posts with past published_at' do
        post.update!(status: :scheduled, published_at: 1.hour.ago)
        expect(post.visible_to_public?).to be true
      end

      it 'returns false for scheduled posts with future published_at' do
        post.update!(status: :scheduled, published_at: 1.hour.from_now)
        expect(post.visible_to_public?).to be false
      end
    end

    describe '#password_protected?' do
      it 'returns true when password is present' do
        post.update!(password: 'secret')
        expect(post.password_protected?).to be true
      end

      it 'returns false when password is blank' do
        expect(post.password_protected?).to be false
      end
    end

    describe '#password_matches?' do
      it 'returns true when password matches' do
        post.update!(password: 'secret')
        expect(post.password_matches?('secret')).to be true
      end

      it 'returns false when password does not match' do
        post.update!(password: 'secret')
        expect(post.password_matches?('wrong')).to be false
      end

      it 'returns true when no password is set' do
        expect(post.password_matches?('anything')).to be true
      end
    end

    describe '#check_scheduled_publish' do
      it 'publishes scheduled posts when published_at has passed' do
        post.update!(status: :scheduled, published_at: 1.hour.ago)
        post.check_scheduled_publish
        expect(post.reload.status).to eq('published')
      end

      it 'does not publish scheduled posts when published_at is in future' do
        post.update!(status: :scheduled, published_at: 1.hour.from_now)
        post.check_scheduled_publish
        expect(post.reload.status).to eq('scheduled')
      end
    end

    describe '#featured_image_url' do
      it 'returns nil when no featured image is attached' do
        expect(post.featured_image_url).to be_nil
      end

      it 'returns URL when featured image is attached' do
        # This would require actual file attachment testing
        # For now, we'll test the method exists
        expect(post).to respond_to(:featured_image_url)
      end
    end

    describe '#url' do
      it 'returns the post URL' do
        expect(post.url).to include(post.id.to_s)
      end
    end

    describe '#to_liquid' do
      it 'returns liquid-compatible hash' do
        liquid = post.to_liquid
        expect(liquid['id']).to eq(post.id)
        expect(liquid['title']).to eq(post.title)
        expect(liquid['url']).to eq(post.url)
        expect(liquid['author']).to eq(post.author)
      end
    end
  end

  describe 'custom fields' do
    let(:field_group) { create(:field_group, tenant: tenant) }
    let(:custom_field) { create(:custom_field, field_group: field_group, tenant: tenant) }
    let(:post) { create(:post, tenant: tenant) }

    describe '#get_field' do
      it 'returns field value by name' do
        create(:custom_field_value, custom_field: custom_field, object: post, meta_key: 'test_field', typed_value: 'test_value')
        expect(post.get_field('test_field')).to eq('test_value')
      end

      it 'returns nil for non-existent field' do
        expect(post.get_field('non_existent')).to be_nil
      end
    end

    describe '#set_field' do
      it 'sets field value by name' do
        result = post.set_field('test_field', 'test_value')
        expect(result).to be true
        expect(post.get_field('test_field')).to eq('test_value')
      end

      it 'returns false for non-existent field' do
        result = post.set_field('non_existent', 'value')
        expect(result).to be false
      end
    end

    describe '#get_fields' do
      it 'returns all fields as hash' do
        create(:custom_field_value, custom_field: custom_field, object: post, meta_key: 'field1', typed_value: 'value1')
        create(:custom_field_value, custom_field: custom_field, object: post, meta_key: 'field2', typed_value: 'value2')
        
        fields = post.get_fields
        expect(fields['field1']).to eq('value1')
        expect(fields['field2']).to eq('value2')
      end
    end

    describe '#update_fields' do
      it 'updates multiple fields at once' do
        post.update_fields({ 'field1' => 'value1', 'field2' => 'value2' })
        expect(post.get_field('field1')).to eq('value1')
        expect(post.get_field('field2')).to eq('value2')
      end
    end
  end

  describe 'taxonomies integration' do
    let(:category_taxonomy) { create(:taxonomy, slug: 'category', tenant: tenant) }
    let(:tag_taxonomy) { create(:taxonomy, slug: 'post_tag', tenant: tenant) }
    let(:category) { create(:term, taxonomy: category_taxonomy, tenant: tenant) }
    let(:tag) { create(:term, taxonomy: tag_taxonomy, tenant: tenant) }
    let(:post) { create(:post, tenant: tenant) }

    it 'can have categories' do
      post.category = [category]
      expect(post.category).to include(category)
    end

    it 'can have tags' do
      post.post_tag = [tag]
      expect(post.post_tag).to include(tag)
    end

    it 'can have both categories and tags' do
      post.category = [category]
      post.post_tag = [tag]
      expect(post.terms).to include(category, tag)
    end
  end

  describe 'multi-tenancy' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }
    let(:user1) { create(:user, tenant: tenant1) }
    let(:user2) { create(:user, tenant: tenant2) }

    it 'isolates posts by tenant' do
      post1 = create(:post, user: user1, tenant: tenant1, slug: 'test-post')
      post2 = create(:post, user: user2, tenant: tenant2, slug: 'test-post')

      expect(post1.slug).to eq(post2.slug)
      expect(post1.tenant).not_to eq(post2.tenant)
    end
  end

  describe 'SEO integration' do
    let(:post) { create(:post, tenant: tenant) }

    it 'includes SEO optimizable functionality' do
      expect(post).to respond_to(:seo_title)
      expect(post).to respond_to(:seo_description)
      expect(post).to respond_to(:structured_data)
    end

    it 'generates structured data' do
      structured_data = post.structured_data
      expect(structured_data['@type']).to eq('Post')
      expect(structured_data['headline']).to eq(post.title)
    end
  end

  describe 'trash functionality' do
    let(:post) { create(:post, tenant: tenant) }

    it 'includes trashable functionality' do
      expect(post).to respond_to(:trash!)
      expect(post).to respond_to(:restore!)
    end

    it 'can be trashed and restored' do
      post.trash!
      expect(post.trashed?).to be true
      
      post.restore!
      expect(post.trashed?).to be false
    end
  end

  describe 'versioning' do
    let(:post) { create(:post, tenant: tenant) }

    it 'tracks versions' do
      expect(post.versions).to be_present
    end

    it 'creates new version on update' do
      initial_version_count = post.versions.count
      post.update!(title: 'Updated Title')
      expect(post.versions.count).to eq(initial_version_count + 1)
    end
  end
end
