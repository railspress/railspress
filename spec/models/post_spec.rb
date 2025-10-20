require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:post) { build(:post, user: user, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:content_type).optional }
    it { should belong_to(:tenant).optional }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:meta_fields).dependent(:destroy) }
    it { should have_rich_text(:content) }
    it { should have_one_attached(:featured_image_file) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:status) }
    it { should validate_length_of(:password).is_at_least(4).allow_blank }
    
    it 'validates uniqueness of slug' do
      existing_post = Post.create!(
        title: 'Test Post',
        slug: 'test-slug',
        status: :published,
        user: user,
        tenant: tenant,
        published_at: Time.current
      )
      # Skip FriendlyId slug generation for the existing post too
      existing_post.define_singleton_method(:should_generate_new_friendly_id?) { false }
      existing_post.update!(slug: 'test-slug')
      
      duplicate_post = Post.new(
        title: 'Another Post',
        slug: 'test-slug',
        status: :published,
        user: user,
        tenant: tenant,
        published_at: Time.current
      )
      # Skip FriendlyId slug generation for this test
      duplicate_post.define_singleton_method(:should_generate_new_friendly_id?) { false }
      expect(duplicate_post).not_to be_valid
      expect(duplicate_post.errors[:slug]).to include('has already been taken')
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(Post.statuses).to eq({
        'draft' => 0,
        'published' => 1,
        'scheduled' => 2,
        'pending_review' => 3,
        'private_post' => 4,
        'trash' => 5
      })
    end
  end

  describe 'scopes' do
    let!(:published_post) { create(:post, status: :published, published_at: 1.hour.ago, user: user, tenant: tenant) }
    let!(:draft_post) { create(:post, status: :draft, user: user, tenant: tenant) }
    let!(:scheduled_post) { create(:post, status: :scheduled, published_at: 1.hour.from_now, user: user, tenant: tenant) }
    let!(:trashed_post) { create(:post, status: :trash, user: user, tenant: tenant) }

    describe '.visible_to_public' do
      it 'returns only published and scheduled posts' do
        posts = Post.visible_to_public
        expect(posts).to include(published_post)
        expect(posts).not_to include(draft_post)
        expect(posts).not_to include(trashed_post)
      end
    end

    describe '.published' do
      it 'returns only published posts' do
        posts = Post.published
        expect(posts).to include(published_post)
        expect(posts).not_to include(draft_post)
        expect(posts).not_to include(scheduled_post)
      end
    end

    describe '.scheduled' do
      it 'returns only scheduled posts' do
        posts = Post.scheduled
        expect(posts).to include(scheduled_post)
        expect(posts).not_to include(published_post)
        expect(posts).not_to include(draft_post)
      end
    end

    describe '.recent' do
      it 'orders posts by published_at descending' do
        posts = Post.recent
        expect(posts.first).to eq(scheduled_post) # Most recent published_at
      end
    end

    describe '.not_trashed' do
      it 'excludes trashed posts' do
        posts = Post.not_trashed
        expect(posts).to include(published_post, draft_post, scheduled_post)
        expect(posts).not_to include(trashed_post)
      end
    end

    describe '.trashed' do
      it 'returns only trashed posts' do
        posts = Post.trashed
        expect(posts).to include(trashed_post)
        expect(posts).not_to include(published_post)
      end
    end

    describe '.awaiting_review' do
      it 'returns posts pending review' do
        pending_post = create(:post, status: :pending_review, user: user, tenant: tenant)
        posts = Post.awaiting_review
        expect(posts).to include(pending_post)
        expect(posts).not_to include(published_post)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets published_at when status is published' do
        post = build(:post, status: :published, published_at: nil, user: user, tenant: tenant)
        post.valid?
        expect(post.published_at).to be_present
      end
    end

    describe 'after_create' do
      it 'triggers post created hook' do
        expect(Railspress::PluginSystem).to receive(:do_action).with('post_created', instance_of(Post))
        expect(Railspress::WebhookDispatcher).to receive(:dispatch).with('post.created', instance_of(Post))
        create(:post, user: user, tenant: tenant)
      end
    end

    describe 'after_update' do
      it 'triggers post updated hook when status changes' do
        post = create(:post, status: :draft, user: user, tenant: tenant)
        expect(Railspress::PluginSystem).to receive(:do_action).with('post_published', post)
        expect(Railspress::WebhookDispatcher).to receive(:dispatch).with('post.published', post)
        expect(Railspress::PluginSystem).to receive(:do_action).with('post_updated', post)
        expect(Railspress::WebhookDispatcher).to receive(:dispatch).with('post.updated', post)
        post.update!(status: :published)
      end

      it 'triggers post published hook when status changes to published' do
        post = create(:post, status: :draft, user: user, tenant: tenant)
        expect(Railspress::PluginSystem).to receive(:do_action).with('post_published', post)
        expect(Railspress::WebhookDispatcher).to receive(:dispatch).with('post.published', post)
        expect(Railspress::PluginSystem).to receive(:do_action).with('post_updated', post)
        expect(Railspress::WebhookDispatcher).to receive(:dispatch).with('post.updated', post)
        post.update!(status: :published)
      end
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
      it 'returns user name' do
        user.update!(name: 'John Doe')
        expect(post.author_name).to eq('John Doe')
      end

      it 'returns email prefix when no name' do
        user.update!(name: nil, email: 'john@example.com')
        expect(post.author_name).to eq('John')
      end

      it 'returns Anonymous when no user' do
        post_without_user = Post.new(title: 'Test', slug: 'test', status: :draft)
        expect(post_without_user.author_name).to eq('Anonymous')
      end
    end

    describe '#post_type' do
      it 'returns content type' do
        content_type = create(:content_type, ident: 'article', tenant: tenant)
        post.update!(content_type: content_type)
        expect(post.post_type).to eq(content_type)
      end

      it 'returns default type when no content type' do
        expect(post.post_type).to eq(ContentType.default_type)
      end
    end

    describe '#post_type_ident' do
      it 'returns content type ident' do
        content_type = create(:content_type, ident: 'article', tenant: tenant)
        post.update!(content_type: content_type)
        expect(post.post_type_ident).to eq('article')
      end

      it 'returns post when no content type' do
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

      it 'returns false for pending review posts' do
        post.update!(status: :pending_review)
        expect(post.visible_to_public?).to be false
      end

      it 'returns false for private posts' do
        post.update!(status: :private_post)
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
        post.update!(password: 'secret123')
        expect(post.password_protected?).to be true
      end

      it 'returns false when password is blank' do
        post.update!(password: '')
        expect(post.password_protected?).to be false
      end
    end

    describe '#password_matches?' do
      it 'returns true when no password is set' do
        expect(post.password_matches?('anything')).to be true
      end

      it 'returns true when password matches' do
        post.update!(password: 'secret123')
        expect(post.password_matches?('secret123')).to be true
      end

      it 'returns false when password does not match' do
        post.update!(password: 'secret123')
        expect(post.password_matches?('wrong')).to be false
      end
    end

    describe '#check_scheduled_publish' do
      it 'publishes scheduled post when time has passed' do
        post.update!(status: :scheduled, published_at: 1.hour.ago)
        post.check_scheduled_publish
        expect(post.status).to eq('published')
      end

      it 'does not publish scheduled post when time has not passed' do
        post.update!(status: :scheduled, published_at: 1.hour.from_now)
        post.check_scheduled_publish
        expect(post.status).to eq('scheduled')
      end
    end

    describe '#should_generate_new_friendly_id?' do
      it 'returns true when title changes' do
        post.title = 'New Title'
        expect(post.should_generate_new_friendly_id?).to be true
      end

      it 'returns true when slug is blank' do
        post.slug = ''
        expect(post.should_generate_new_friendly_id?).to be true
      end

      it 'returns false when neither title nor slug changes' do
        expect(post.should_generate_new_friendly_id?).to be false
      end
    end
  end

  # describe 'versioning methods' do
  #   let(:post) { create(:post, user: user, tenant: tenant) }

  #   describe '#versions_count' do
  #     it 'returns number of versions' do
  #       post.update!(title: 'Updated Title')
  #       expect(post.versions_count).to eq(2) # Initial + update
  #     end
  #   end

  #   describe '#latest_version' do
  #     it 'returns the most recent version' do
  #       post.update!(title: 'Updated Title')
  #       latest = post.latest_version
  #       expect(latest).to be_present
  #       expect(latest.changeset['title']).to eq([post.title_was, 'Updated Title'])
  #     end
  #   end

  #   describe '#version_at' do
  #     it 'returns version at specific timestamp' do
  #       post.update!(title: 'Updated Title')
  #       version = post.version_at(1.hour.ago)
  #       expect(version).to be_present
  #     end
  #   end

  #   describe '#changes_since' do
  #     it 'returns changes since version' do
  #       post.update!(title: 'Updated Title')
  #       version = post.versions.first
  #       changes = post.changes_since(version)
  #       expect(changes).to have_key('title')
  #     end
  #   end

  #   describe '#version_summary' do
  #     it 'returns summary for version with changes' do
  #       post.update!(title: 'New Title')
  #       version = post.versions.last
  #       summary = post.version_summary(version)
  #       expect(summary).to include('Title changed')
  #     end

  #     it 'returns initial version for first version' do
  #       version = post.versions.first
  #       summary = post.version_summary(version)
  #       expect(summary).to eq('Initial version')
  #     end
  #   end
  # end

  describe 'search methods' do
    let!(:post1) { create(:post, title: 'Ruby on Rails', content: 'Rails is awesome', user: user, tenant: tenant) }
    let!(:post2) { create(:post, title: 'JavaScript', content: 'JS is great', user: user, tenant: tenant) }

    describe '.search_full_text' do
      it 'returns posts matching query' do
        results = Post.search_full_text('Rails')
        expect(results).to include(post1)
        expect(results).not_to include(post2)
      end

      it 'returns empty when query is blank' do
        results = Post.search_full_text('')
        expect(results).to be_empty
      end
    end

    describe '.search' do
      it 'delegates to search_full_text' do
        results = Post.search('Rails')
        expect(results).to include(post1)
      end
    end
  end
end













