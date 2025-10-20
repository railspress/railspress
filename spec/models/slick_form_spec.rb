require 'rails_helper'

RSpec.describe SlickForm, type: :model do
  let(:tenant) { create(:tenant) }
  let(:slick_form) { build(:slick_form, tenant_id: tenant.id) }

  describe 'associations' do
    it { should have_many(:slick_form_submissions).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:active).in_array([true, false]) }
    
    it 'validates uniqueness of name scoped to tenant' do
      create(:slick_form, name: 'test-form', tenant_id: tenant.id)
      duplicate_form = build(:slick_form, name: 'test-form', tenant_id: tenant.id)
      expect(duplicate_form).not_to be_valid
      expect(duplicate_form.errors[:name]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    let!(:active_form) { create(:slick_form, active: true, tenant_id: tenant.id, name: 'active-form') }
    let!(:inactive_form) { create(:slick_form, active: false, tenant_id: tenant.id, name: 'inactive-form') }
    let!(:other_tenant_form) { create(:slick_form, tenant_id: create(:tenant).id, name: 'other-form') }

    describe '.active' do
      it 'returns only active forms' do
        expect(SlickForm.active).to include(active_form)
        expect(SlickForm.active).not_to include(inactive_form)
      end
    end

    describe '.inactive' do
      it 'returns only inactive forms' do
        expect(SlickForm.inactive).to include(inactive_form)
        expect(SlickForm.inactive).not_to include(active_form)
      end
    end

    describe '.by_tenant' do
      it 'returns forms for specific tenant' do
        forms = SlickForm.by_tenant(tenant.id)
        expect(forms).to include(active_form, inactive_form)
        expect(forms).not_to include(other_tenant_form)
      end
    end

    describe '.accessible_by' do
      it 'returns forms accessible by tenant' do
        forms = SlickForm.accessible_by(tenant)
        expect(forms).to include(active_form, inactive_form)
        expect(forms).not_to include(other_tenant_form)
      end

      it 'returns all forms when no tenant provided' do
        forms = SlickForm.accessible_by(nil)
        expect(forms).to include(active_form, inactive_form, other_tenant_form)
      end
    end

    describe '.recent' do
      it 'orders forms by creation date descending' do
        forms = SlickForm.recent
        expect(forms.first).to eq(other_tenant_form) # Created last
        expect(forms.last).to eq(active_form) # Created first
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save' do
      it 'sets default values' do
        form = SlickForm.new(name: 'test', title: 'Test Form', tenant_id: tenant.id)
        form.save!
        
        expect(form.fields).to eq([])
        expect(form.settings).to eq({})
        expect(form.submissions_count).to eq(0)
      end
    end
  end

  describe 'instance methods' do
    let(:form) { create(:slick_form, tenant_id: tenant.id, fields: [{ 'type' => 'text', 'name' => 'email' }], submissions_count: 5) }

    describe '#field_count' do
      it 'returns number of fields' do
        expect(form.field_count).to eq(1)
      end

      it 'returns 0 when fields is nil' do
        form.update!(fields: nil)
        expect(form.field_count).to eq(0)
      end
    end

    describe '#has_submissions?' do
      it 'returns true when submissions exist' do
        expect(form.has_submissions?).to be true
      end

      it 'returns false when no submissions' do
        form.update!(submissions_count: 0)
        expect(form.has_submissions?).to be false
      end
    end

    describe '#conversion_rate' do
      it 'returns 0 when no views' do
        expect(form.conversion_rate).to eq(0.0)
      end
    end

    describe '#duplicate!' do
      it 'creates a duplicate form' do
        duplicated = form.duplicate!
        
        expect(duplicated.name).to eq("#{form.name} (Copy)")
        expect(duplicated.title).to eq("#{form.title} (Copy)")
        expect(duplicated.submissions_count).to eq(0)
        expect(duplicated.id).not_to eq(form.id)
      end
    end

    describe '#public_url' do
      it 'returns public URL' do
        expect(form.public_url).to eq("/plugins/slick_forms/form/#{form.id}")
      end
    end

    describe '#embed_url' do
      it 'returns embed URL' do
        expect(form.embed_url).to eq("/plugins/slick_forms/form/#{form.id}/embed")
      end
    end

    describe '#submission_url' do
      it 'returns submission URL' do
        expect(form.submission_url).to eq("/plugins/slick_forms/submit/#{form.id}")
      end
    end
  end
end
