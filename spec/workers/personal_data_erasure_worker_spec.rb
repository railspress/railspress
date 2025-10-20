require 'rails_helper'

RSpec.describe PersonalDataErasureWorker, type: :worker do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:request) { create(:personal_data_erasure_request, user: user, status: 'pending_confirmation') }
  
  before do
    # Create test data that will be erased
    create(:post, user: user, title: 'Test Post', content: 'Test content')
    create(:page, user: user, title: 'Test Page', content: 'Test page content')
    create(:comment, email: user.email, content: 'Test comment')
    create(:user_consent, user: user, consent_type: 'data_processing', granted: true)
    
    # Create some media for the user
    medium = create(:medium, user: user)
    medium.file.attach(
      io: StringIO.new('test image data'),
      filename: 'test.jpg',
      content_type: 'image/jpeg'
    )
    
    # Create some pageviews
    create(:pageview, user_id: user.id, path: '/test-page')
    create(:pageview, user_id: user.id, path: '/another-page')
  end
  
  describe '#perform' do
    it 'processes erasure request successfully' do
      expect(request.status).to eq('pending_confirmation')
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      request.reload
      expect(request.status).to eq('completed')
      expect(request.completed_at).to be_present
      expect(request.metadata).to include('erasure_completed_at')
    end
    
    it 'updates status to processing during execution' do
      allow(PersonalDataErasureRequest).to receive(:find).with(request.id).and_return(request)
      allow(request).to receive(:update).and_call_original
      
      worker = PersonalDataErasureWorker.new
      worker.perform(request.id)
      
      expect(request).to have_received(:update).with(status: 'processing')
    end
    
    it 'creates backup before erasure' do
      PersonalDataErasureWorker.new.perform(request.id)
      
      request.reload
      backup_path = request.metadata['backup_file_path']
      
      expect(backup_path).to be_present
      expect(File.exist?(backup_path)).to be true
      
      backup_data = JSON.parse(File.read(backup_path))
      expect(backup_data).to include(
        'erasure_request_id' => request.id,
        'user_id' => user.id,
        'user_email' => user.email,
        'erasure_date' => kind_of(String),
        'reason' => request.reason
      )
    end
    
    it 'anonymizes user profile data' do
      original_email = user.email
      original_name = user.name
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      user.reload
      expect(user.email).to eq("deleted_user_#{user.id}@deleted.local")
      expect(user.name).to eq('Deleted User')
      expect(user.bio).to be_nil
      expect(user.website).to be_nil
    end
    
    it 'anonymizes user posts' do
      post = user.posts.first
      original_title = post.title
      original_content = post.content
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      post.reload
      expect(post.title).to eq('[Deleted Post]')
      expect(post.content).to include('deleted due to data erasure request')
      expect(post.slug).to eq("deleted-post-#{post.id}")
    end
    
    it 'anonymizes user pages' do
      page = user.pages.first
      original_title = page.title
      original_content = page.content
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      page.reload
      expect(page.title).to eq('[Deleted Page]')
      expect(page.content).to include('deleted due to data erasure request')
      expect(page.slug).to eq("deleted-page-#{page.id}")
    end
    
    it 'deletes user media files' do
      medium = user.media.first
      medium_id = medium.id
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      expect { medium.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'anonymizes comments by email' do
      comment = Comment.where(email: user.email).first
      original_content = comment.content
      original_author_name = comment.author_name
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      comment.reload
      expect(comment.author_name).to eq('Deleted User')
      expect(comment.author_email).to eq('deleted@deleted.local')
      expect(comment.content).to include('deleted due to data erasure request')
    end
    
    it 'deletes subscriber records' do
      subscriber = create(:subscriber, email: user.email)
      subscriber_id = subscriber.id
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      expect { subscriber.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'deletes API tokens' do
      api_token = create(:api_token, user: user)
      token_id = api_token.id
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      expect { api_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'deletes meta fields' do
      meta_field = create(:meta_field, metable: user)
      field_id = meta_field.id
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      expect { meta_field.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'deletes pageview data' do
      pageview_count = Pageview.where(user_id: user.id).count
      expect(pageview_count).to eq(2)
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      pageview_count_after = Pageview.where(user_id: user.id).count
      expect(pageview_count_after).to eq(0)
    end
    
    it 'deletes consent records' do
      consent = UserConsent.where(user: user).first
      consent_id = consent.id
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      expect { consent.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'deletes OAuth accounts' do
      oauth_account = create(:oauth_account, user: user)
      account_id = oauth_account.id
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      expect { oauth_account.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'deletes AI usage records' do
      ai_usage = create(:ai_usage, user: user)
      usage_id = ai_usage.id
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      expect { ai_usage.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'preserves user account for audit purposes' do
      user_id = user.id
      
      PersonalDataErasureWorker.new.perform(request.id)
      
      expect { User.find(user_id) }.not_to raise_error
    end
  end
  
  describe 'error handling' do
    it 'handles missing request gracefully' do
      expect {
        PersonalDataErasureWorker.new.perform(999999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    it 'updates status to failed on error' do
      allow(PersonalDataErasureRequest).to receive(:find).with(request.id).and_raise(StandardError, 'Test error')
      allow(request).to receive(:update)
      
      expect {
        PersonalDataErasureWorker.new.perform(request.id)
      }.to raise_error(StandardError, 'Test error')
      
      expect(request).to have_received(:update).with(status: 'failed')
    end
    
    it 'logs errors appropriately' do
      allow(PersonalDataErasureRequest).to receive(:find).with(request.id).and_raise(StandardError, 'Test error')
      allow(Rails.logger).to receive(:error)
      
      expect {
        PersonalDataErasureWorker.new.perform(request.id)
      }.to raise_error(StandardError, 'Test error')
      
      expect(Rails.logger).to have_received(:error).with(/Personal data erasure failed for request #{request.id}: Test error/)
    end
  end
  
  describe 'backup creation' do
    it 'creates backup in tmp directory' do
      PersonalDataErasureWorker.new.perform(request.id)
      
      request.reload
      backup_path = request.metadata['backup_file_path']
      
      expect(backup_path).to start_with(Rails.root.join('tmp').to_s)
      expect(backup_path).to include("erasure_backup_#{request.id}")
      expect(backup_path).to end_with('.json')
    end
    
    it 'includes comprehensive backup data' do
      PersonalDataErasureWorker.new.perform(request.id)
      
      request.reload
      backup_path = request.metadata['backup_file_path']
      backup_data = JSON.parse(File.read(backup_path))
      
      expect(backup_data).to include(
        'erasure_request_id' => request.id,
        'user_id' => user.id,
        'user_email' => user.email,
        'erasure_date' => kind_of(String),
        'reason' => request.reason,
        'metadata' => kind_of(Hash),
        'data_categories_erased' => kind_of(Array)
      )
    end
  end
  
  describe 'data categories tracking' do
    it 'tracks erased data categories' do
      PersonalDataErasureWorker.new.perform(request.id)
      
      request.reload
      erased_categories = request.metadata['erased_data_categories']
      
      expect(erased_categories).to include(
        'profile_data',
        'posts',
        'pages',
        'comments',
        'media',
        'analytics',
        'consent_records'
      )
    end
    
    it 'handles user with no data gracefully' do
      user_without_data = create(:user, tenant: tenant)
      request_no_data = create(:personal_data_erasure_request, user: user_without_data, status: 'pending_confirmation')
      
      PersonalDataErasureWorker.new.perform(request_no_data.id)
      
      request_no_data.reload
      erased_categories = request_no_data.metadata['erased_data_categories']
      
      expect(erased_categories).to include('profile_data')
      expect(erased_categories).not_to include('posts', 'pages', 'comments', 'media')
    end
  end
  
  describe 'metadata gathering' do
    it 'gathers accurate metadata before erasure' do
      PersonalDataErasureWorker.new.perform(request.id)
      
      request.reload
      metadata = request.metadata
      
      expect(metadata['user_posts_count']).to eq(1)
      expect(metadata['user_pages_count']).to eq(1)
      expect(metadata['user_comments_count']).to eq(1)
      expect(metadata['user_media_count']).to eq(1)
      expect(metadata['user_pageviews_count']).to eq(2)
      expect(metadata['user_meta_fields_count']).to eq(0)
      expect(metadata['user_consent_records_count']).to eq(1)
    end
  end
  
  describe 'performance' do
    it 'handles large datasets efficiently' do
      # Create a large number of posts and comments
      create_list(:post, 100, user: user)
      create_list(:comment, 100, email: user.email)
      
      start_time = Time.current
      PersonalDataErasureWorker.new.perform(request.id)
      end_time = Time.current
      
      # Should complete within reasonable time (adjust threshold as needed)
      expect(end_time - start_time).to be < 30.seconds
      
      request.reload
      expect(request.status).to eq('completed')
    end
  end
  
  describe 'sidekiq configuration' do
    it 'has correct sidekiq options' do
      expect(PersonalDataErasureWorker.sidekiq_options).to include(
        'retry' => 1,
        'queue' => 'default'
      )
    end
  end
end
