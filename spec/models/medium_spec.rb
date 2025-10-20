require 'rails_helper'

RSpec.describe Medium, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:upload) { create(:upload, user: user, tenant: tenant) }
  let(:medium) { build(:medium, user: user, upload: upload, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:user) }
    it { should belong_to(:upload) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'scopes' do
    let!(:image_upload) { create(:upload, :image_file, user: user, tenant: tenant) }
    let!(:video_upload) { create(:upload, :video_file, user: user, tenant: tenant) }
    let!(:image_medium) { create(:medium, upload: image_upload, user: user, tenant: tenant) }
    let!(:video_medium) { create(:medium, upload: video_upload, user: user, tenant: tenant) }

    describe '.images' do
      it 'returns only image media' do
        expect(Medium.images).to include(image_medium)
        expect(Medium.images).not_to include(video_medium)
      end
    end

    describe '.videos' do
      it 'returns only video media' do
        expect(Medium.videos).to include(video_medium)
        expect(Medium.videos).not_to include(image_medium)
      end
    end

    describe '.recent' do
      it 'orders media by created_at desc' do
        old_medium = create(:medium, created_at: 2.days.ago, user: user, upload: upload, tenant: tenant)
        new_medium = create(:medium, created_at: 1.day.ago, user: user, upload: upload, tenant: tenant)
        
        expect(Medium.recent.first).to eq(new_medium)
        expect(Medium.recent.last).to eq(old_medium)
      end
    end
  end

  describe 'instance methods' do
    describe '#image?' do
      it 'returns true for image upload' do
        image_upload = create(:upload, :image_file, user: user, tenant: tenant)
        medium = build(:medium, upload: image_upload, user: user, tenant: tenant)
        expect(medium.image?).to be true
      end
      
      it 'returns false for non-image upload' do
        video_upload = create(:upload, :video_file, user: user, tenant: tenant)
        medium = build(:medium, upload: video_upload, user: user, tenant: tenant)
        expect(medium.image?).to be false
      end
    end

    describe '#video?' do
      it 'returns true for video upload' do
        video_upload = create(:upload, :video_file, user: user, tenant: tenant)
        medium = build(:medium, upload: video_upload, user: user, tenant: tenant)
        expect(medium.video?).to be true
      end
      
      it 'returns false for non-video upload' do
        image_upload = create(:upload, :image_file, user: user, tenant: tenant)
        medium = build(:medium, upload: image_upload, user: user, tenant: tenant)
        expect(medium.video?).to be false
      end
    end

    describe '#document?' do
      it 'returns true for document upload' do
        doc_upload = create(:upload, :document_file, user: user, tenant: tenant)
        medium = build(:medium, upload: doc_upload, user: user, tenant: tenant)
        expect(medium.document?).to be true
      end
      
      it 'returns false for non-document upload' do
        image_upload = create(:upload, :image_file, user: user, tenant: tenant)
        medium = build(:medium, upload: image_upload, user: user, tenant: tenant)
        expect(medium.document?).to be false
      end
    end

    describe '#file_size' do
      it 'returns file size from upload' do
        upload = create(:upload, file_size: 1024, user: user, tenant: tenant)
        medium = build(:medium, upload: upload, user: user, tenant: tenant)
        expect(medium.file_size).to eq(1024)
      end
      
      it 'returns 0 when upload is nil' do
        medium = build(:medium, upload: nil, user: user, tenant: tenant)
        expect(medium.file_size).to eq(0)
      end
    end

    describe '#content_type' do
      it 'returns content type from upload' do
        upload = create(:upload, content_type: 'image/jpeg', user: user, tenant: tenant)
        medium = build(:medium, upload: upload, user: user, tenant: tenant)
        expect(medium.content_type).to eq('image/jpeg')
      end
    end

    describe '#filename' do
      it 'returns filename from upload' do
        upload = create(:upload, filename: 'test.jpg', user: user, tenant: tenant)
        medium = build(:medium, upload: upload, user: user, tenant: tenant)
        expect(medium.filename).to eq('test.jpg')
      end
    end

    describe '#url' do
      it 'returns URL from upload' do
        upload = create(:upload, file_url: 'https://example.com/file.jpg', user: user, tenant: tenant)
        medium = build(:medium, upload: upload, user: user, tenant: tenant)
        expect(medium.url).to eq('https://example.com/file.jpg')
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'triggers media uploaded hook' do
        medium = build(:medium, user: user, upload: upload, tenant: tenant)
        expect(medium).to receive(:trigger_media_uploaded_hook)
        medium.save!
      end
    end
  end
end
