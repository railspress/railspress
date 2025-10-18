require 'rails_helper'

RSpec.describe Page, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:page) { build(:page, user: user, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:parent).class_name('Page').optional }
    it { should belong_to(:page_template).optional }
    it { should have_many(:children).class_name('Page').dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:meta_fields).dependent(:destroy) }
    it { should have_many(:custom_field_values).dependent(:destroy) }
    it { should have_many(:term_relationships).dependent(:destroy) }
    it { should have_many(:terms).through(:term_relationships) }
    it { should have_rich_text(:content) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:status) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_length_of(:password).is_at_least(4).allow_blank }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(draft: 0, published: 1, scheduled: 2, pending_review: 3, private_page: 4, trash: 5) }
  end

  describe 'friendly_id' do
    it 'generates slug from title' do
      page.title = 'My Test Page'
      page.save!
      expect(page.slug).to eq('my-test-page')
    end

    it 'updates slug when title changes' do
      page.save!
      page.update!(title: 'New Title')
      expect(page.slug).to eq('new-title')
    end
  end

  describe 'scopes' do
    let!(:published_page) { create(:page, status: :published, published_at: 1.hour.ago, tenant: tenant) }
    let!(:draft_page) { create(:page, status: :draft, tenant: tenant) }
    let!(:scheduled_page) { create(:page, status: :scheduled, published_at: 1.hour.from_now, tenant: tenant) }
    let!(:trashed_page) { create(:page, status: :trash, tenant: tenant) }

    describe '.visible_to_public' do
      it 'returns published and scheduled pages' do
        expect(Page.visible_to_public).to include(published_page, scheduled_page)
        expect(Page.visible_to_public).not_to include(draft_page, trashed_page)
      end
    end

    describe '.published' do
      it 'returns only published pages' do
        expect(Page.published).to include(published_page)
        expect(Page.published).not_to include(draft_page, scheduled_page, trashed_page)
      end
    end

    describe '.root_pages' do
      let!(:parent_page) { create(:page, parent: nil, tenant: tenant) }
      let!(:child_page) { create(:page, parent: parent_page, tenant: tenant) }

      it 'returns only pages without parent' do
        expect(Page.root_pages).to include(parent_page)
        expect(Page.root_pages).not_to include(child_page)
      end
    end

    describe '.ordered' do
      let!(:page1) { create(:page, order: 2, title: 'B Page', tenant: tenant) }
      let!(:page2) { create(:page, order: 1, title: 'A Page', tenant: tenant) }
      let!(:page3) { create(:page, order: 1, title: 'C Page', tenant: tenant) }

      it 'orders by order then title' do
        ordered = Page.ordered
        expect(ordered).to eq([page2, page3, page1])
      end
    end

    describe '.search' do
      it 'searches pages by title, meta_description, and content' do
        search_page = create(:page, title: 'About Us', tenant: tenant)
        results = Page.search('About')
        expect(results).to include(search_page)
      end
    end
  end

  describe 'callbacks' do
    it 'sets published_at when status is published' do
      page.status = :published
      page.save!
      expect(page.published_at).to be_present
    end

    it 'triggers page_created hook after create' do
      expect(Railspress::PluginSystem).to receive(:do_action).with('page_created', instance_of(Page))
      create(:page, tenant: tenant)
    end

    it 'triggers page_updated hook after status change' do
      page = create(:page, status: :draft, tenant: tenant)
      expect(Railspress::PluginSystem).to receive(:do_action).with('page_updated', page)
      page.update!(status: :published)
    end
  end

  describe 'instance methods' do
    let(:page) { create(:page, user: user, tenant: tenant) }

    describe '#visible_to_public?' do
      it 'returns true for published pages' do
        page.update!(status: :published, published_at: 1.hour.ago)
        expect(page.visible_to_public?).to be true
      end

      it 'returns false for draft pages' do
        page.update!(status: :draft)
        expect(page.visible_to_public?).to be false
      end

      it 'returns false for trashed pages' do
        page.update!(status: :trash)
        expect(page.visible_to_public?).to be false
      end

      it 'returns true for scheduled pages with past published_at' do
        page.update!(status: :scheduled, published_at: 1.hour.ago)
        expect(page.visible_to_public?).to be true
      end

      it 'returns false for scheduled pages with future published_at' do
        page.update!(status: :scheduled, published_at: 1.hour.from_now)
        expect(page.visible_to_public?).to be false
      end
    end

    describe '#password_protected?' do
      it 'returns true when password is present' do
        page.update!(password: 'secret')
        expect(page.password_protected?).to be true
      end

      it 'returns false when password is blank' do
        expect(page.password_protected?).to be false
      end
    end

    describe '#password_matches?' do
      it 'returns true when password matches' do
        page.update!(password: 'secret')
        expect(page.password_matches?('secret')).to be true
      end

      it 'returns false when password does not match' do
        page.update!(password: 'secret')
        expect(page.password_matches?('wrong')).to be false
      end

      it 'returns true when no password is set' do
        expect(page.password_matches?('anything')).to be true
      end
    end

    describe '#check_scheduled_publish' do
      it 'publishes scheduled pages when published_at has passed' do
        page.update!(status: :scheduled, published_at: 1.hour.ago)
        page.check_scheduled_publish
        expect(page.reload.status).to eq('published')
      end

      it 'does not publish scheduled pages when published_at is in future' do
        page.update!(status: :scheduled, published_at: 1.hour.from_now)
        page.check_scheduled_publish
        expect(page.reload.status).to eq('scheduled')
      end
    end

    describe '#breadcrumbs' do
      let(:grandparent) { create(:page, parent: nil, tenant: tenant) }
      let(:parent) { create(:page, parent: grandparent, tenant: tenant) }
      let(:child) { create(:page, parent: parent, tenant: tenant) }

      it 'returns array of pages from root to current' do
        breadcrumbs = child.breadcrumbs
        expect(breadcrumbs).to eq([grandparent, parent, child])
      end

      it 'returns single page for root page' do
        breadcrumbs = grandparent.breadcrumbs
        expect(breadcrumbs).to eq([grandparent])
      end
    end

    describe '#template' do
      let(:page_template) { create(:page_template, tenant: tenant) }

      it 'returns page_template if present' do
        page.update!(page_template: page_template)
        expect(page.template).to eq(page_template)
      end

      it 'returns default template if page_template is nil' do
        expect(page.template).to eq(page.default_template)
      end
    end

    describe '#render_with_template' do
      it 'renders content with template' do
        expect(page).to respond_to(:render_with_template)
      end
    end
  end

  describe 'hierarchical structure' do
    let(:parent_page) { create(:page, tenant: tenant) }
    let(:child_page) { create(:page, parent: parent_page, tenant: tenant) }

    it 'supports parent-child relationships' do
      expect(child_page.parent).to eq(parent_page)
      expect(parent_page.children).to include(child_page)
    end

    it 'deletes children when parent is destroyed' do
      child_id = child_page.id
      parent_page.destroy
      expect(Page.find_by(id: child_id)).to be_nil
    end
  end

  describe 'custom fields' do
    let(:field_group) { create(:field_group, tenant: tenant) }
    let(:custom_field) { create(:custom_field, field_group: field_group, tenant: tenant) }
    let(:page) { create(:page, tenant: tenant) }

    describe '#get_field' do
      it 'returns field value by name' do
        create(:custom_field_value, custom_field: custom_field, object: page, meta_key: 'test_field', typed_value: 'test_value')
        expect(page.get_field('test_field')).to eq('test_value')
      end

      it 'returns nil for non-existent field' do
        expect(page.get_field('non_existent')).to be_nil
      end
    end

    describe '#set_field' do
      it 'sets field value by name' do
        result = page.set_field('test_field', 'test_value')
        expect(result).to be true
        expect(page.get_field('test_field')).to eq('test_value')
      end

      it 'returns false for non-existent field' do
        result = page.set_field('non_existent', 'value')
        expect(result).to be false
      end
    end

    describe '#get_fields' do
      it 'returns all fields as hash' do
        create(:custom_field_value, custom_field: custom_field, object: page, meta_key: 'field1', typed_value: 'value1')
        create(:custom_field_value, custom_field: custom_field, object: page, meta_key: 'field2', typed_value: 'value2')
        
        fields = page.get_fields
        expect(fields['field1']).to eq('value1')
        expect(fields['field2']).to eq('value2')
      end
    end

    describe '#update_fields' do
      it 'updates multiple fields at once' do
        page.update_fields({ 'field1' => 'value1', 'field2' => 'value2' })
        expect(page.get_field('field1')).to eq('value1')
        expect(page.get_field('field2')).to eq('value2')
      end
    end
  end

  describe 'taxonomies integration' do
    let(:category_taxonomy) { create(:taxonomy, slug: 'category', tenant: tenant) }
    let(:tag_taxonomy) { create(:taxonomy, slug: 'post_tag', tenant: tenant) }
    let(:category) { create(:term, taxonomy: category_taxonomy, tenant: tenant) }
    let(:tag) { create(:term, taxonomy: tag_taxonomy, tenant: tenant) }
    let(:page) { create(:page, tenant: tenant) }

    it 'can have taxonomies' do
      page.add_term(category, 'category')
      expect(page.terms).to include(category)
    end

    it 'can have multiple taxonomies' do
      page.add_term(category, 'category')
      page.add_term(tag, 'post_tag')
      expect(page.terms).to include(category, tag)
    end
  end

  describe 'multi-tenancy' do
    let(:tenant1) { create(:tenant) }
    let(:tenant2) { create(:tenant) }
    let(:user1) { create(:user, tenant: tenant1) }
    let(:user2) { create(:user, tenant: tenant2) }

    it 'isolates pages by tenant' do
      page1 = create(:page, user: user1, tenant: tenant1, slug: 'test-page')
      page2 = create(:page, user: user2, tenant: tenant2, slug: 'test-page')

      expect(page1.slug).to eq(page2.slug)
      expect(page1.tenant).not_to eq(page2.tenant)
    end
  end

  describe 'SEO integration' do
    let(:page) { create(:page, tenant: tenant) }

    it 'includes SEO optimizable functionality' do
      expect(page).to respond_to(:seo_title)
      expect(page).to respond_to(:seo_description)
      expect(page).to respond_to(:structured_data)
    end

    it 'generates structured data' do
      structured_data = page.structured_data
      expect(structured_data['@type']).to eq('Page')
      expect(structured_data['headline']).to eq(page.title)
    end
  end

  describe 'trash functionality' do
    let(:page) { create(:page, tenant: tenant) }

    it 'includes trashable functionality' do
      expect(page).to respond_to(:trash!)
      expect(page).to respond_to(:restore!)
    end

    it 'can be trashed and restored' do
      page.trash!
      expect(page.trashed?).to be true
      
      page.restore!
      expect(page.trashed?).to be false
    end
  end

  describe 'versioning' do
    let(:page) { create(:page, tenant: tenant) }

    it 'tracks versions' do
      expect(page.versions).to be_present
    end

    it 'creates new version on update' do
      initial_version_count = page.versions.count
      page.update!(title: 'Updated Title')
      expect(page.versions.count).to eq(initial_version_count + 1)
    end
  end

  describe 'comments' do
    let(:page) { create(:page, tenant: tenant) }
    let(:comment) { create(:comment, commentable: page, tenant: tenant) }

    it 'can have comments' do
      expect(page.comments).to include(comment)
    end

    it 'deletes comments when page is destroyed' do
      comment_id = comment.id
      page.destroy
      expect(Comment.find_by(id: comment_id)).to be_nil
    end
  end
end
