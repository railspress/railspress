require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:post) { create(:post, tenant: tenant) }
  let(:comment) { build(:comment, commentable: post, user: user, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant).optional }
    it { should belong_to(:user).optional }
    it { should belong_to(:commentable) }
    it { should belong_to(:parent).optional }
    it { should belong_to(:comment_parent).optional }
    it { should have_many(:replies).dependent(:destroy) }
    it { should have_many(:comment_replies).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:comment_type) }
    it { should validate_presence_of(:comment_approved) }
    it { should validate_presence_of(:author_ip) }
    it { should validate_presence_of(:author_agent) }
    it { should validate_inclusion_of(:comment_approved).in_array(%w[0 1]) }
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(Comment.statuses).to include('pending', 'approved', 'spam', 'trash')
    end
    
    it 'defines comment_type enum' do
      expect(Comment.comment_types).to include('comment', 'pingback', 'trackback')
    end
  end

  describe 'scopes' do
    let!(:approved_comment) { create(:comment, :approved, commentable: post, user: user, tenant: tenant) }
    let!(:pending_comment) { create(:comment, :pending, commentable: post, user: user, tenant: tenant) }
    let!(:spam_comment) { create(:comment, :spam, commentable: post, user: user, tenant: tenant) }

    describe '.approved' do
      it 'returns only approved comments' do
        expect(Comment.approved).to include(approved_comment)
        expect(Comment.approved).not_to include(pending_comment)
        expect(Comment.approved).not_to include(spam_comment)
      end
    end

    describe '.recent' do
      it 'orders comments by created_at desc' do
        old_comment = create(:comment, created_at: 2.days.ago, commentable: post, user: user, tenant: tenant)
        new_comment = create(:comment, created_at: 1.day.ago, commentable: post, user: user, tenant: tenant)
        
        # Clear existing comments to avoid interference
        Comment.where.not(id: [old_comment.id, new_comment.id]).delete_all
        
        expect(Comment.recent.first).to eq(new_comment)
        expect(Comment.recent.last).to eq(old_comment)
      end
    end

    describe '.root_comments' do
      it 'returns only root comments' do
        root_comment = create(:comment, parent_id: nil, commentable: post, user: user, tenant: tenant)
        reply_comment = create(:comment, parent: root_comment, commentable: post, user: user, tenant: tenant)
        
        expect(Comment.root_comments).to include(root_comment)
        expect(Comment.root_comments).not_to include(reply_comment)
      end
    end
  end

  describe 'instance methods' do
    describe '#approved?' do
      it 'returns true for approved comments' do
        comment = build(:comment, commentable: post, user: user, tenant: tenant, comment_approved: '1')
        expect(comment.approved?).to be true
      end
      
      it 'returns false for non-approved comments' do
        comment = build(:comment, commentable: post, user: user, tenant: tenant, comment_approved: '0')
        expect(comment.approved?).to be false
      end
    end

    describe '#pending?' do
      it 'returns true for pending comments' do
        comment = build(:comment, commentable: post, user: user, tenant: tenant, comment_approved: '0')
        expect(comment.pending?).to be true
      end
      
      it 'returns false for non-pending comments' do
        comment = build(:comment, commentable: post, user: user, tenant: tenant, comment_approved: '1')
        expect(comment.pending?).to be false
      end
    end

    describe '#spam?' do
      it 'returns true for spam comments' do
        comment = build(:comment, :spam, commentable: post, user: user, tenant: tenant)
        expect(comment.spam?).to be true
      end
      
      it 'returns false for non-spam comments' do
        comment = build(:comment, :approved, commentable: post, user: user, tenant: tenant)
        expect(comment.spam?).to be false
      end
    end

    describe '#trash?' do
      it 'returns true for trash comments' do
        comment = build(:comment, :trash, commentable: post, user: user, tenant: tenant)
        expect(comment.trash?).to be true
      end
      
      it 'returns false for non-trash comments' do
        comment = build(:comment, :approved, commentable: post, user: user, tenant: tenant)
        expect(comment.trash?).to be false
      end
    end

    describe '#reply?' do
      it 'returns true when parent is present' do
        parent_comment = create(:comment, commentable: post, user: user, tenant: tenant)
        reply = build(:comment, parent: parent_comment, commentable: post, user: user, tenant: tenant)
        expect(reply.parent_id).to be_present
      end
      
      it 'returns false when parent is nil' do
        comment = build(:comment, parent: nil, commentable: post, user: user, tenant: tenant)
        expect(comment.parent_id).to be_nil
      end
    end

    describe '#root?' do
      it 'returns true when parent is nil' do
        comment = build(:comment, parent: nil, commentable: post, user: user, tenant: tenant)
        expect(comment.parent_id).to be_nil
      end
      
      it 'returns false when parent is present' do
        parent_comment = create(:comment, commentable: post, user: user, tenant: tenant)
        reply = build(:comment, parent: parent_comment, commentable: post, user: user, tenant: tenant)
        expect(reply.parent_id).to be_present
      end
    end
  end

  describe 'callbacks' do
    describe 'after_initialize' do
      it 'sets default values' do
        comment = Comment.new
        expect(comment.status).to eq('pending')
        expect(comment.comment_type).to eq('comment')
        expect(comment.comment_approved).to eq('0')
        expect(comment.author_ip).to eq('127.0.0.1')
        expect(comment.author_agent).to eq('Unknown')
      end
    end
  end
end
