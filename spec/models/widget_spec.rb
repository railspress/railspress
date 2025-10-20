require 'rails_helper'

RSpec.describe Widget, type: :model do
  let(:tenant) { create(:tenant) }
  let(:widget) { build(:widget, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:widget_type) }
    it { should validate_uniqueness_of(:name).scoped_to(:tenant_id) }
  end

  describe 'scopes' do
    let!(:active_widget) { create(:widget, active: true, tenant: tenant) }
    let!(:inactive_widget) { create(:widget, :widget_disabled, tenant: tenant) }

    describe '.active' do
      it 'returns only active widgets' do
        expect(Widget.active).to include(active_widget)
        expect(Widget.active).not_to include(inactive_widget)
      end
    end

    describe '.by_type' do
      it 'returns widgets by type' do
        text_widget = create(:widget, widget_type: 'text', tenant: tenant)
        html_widget = create(:widget, widget_type: 'html', tenant: tenant)
        
        expect(Widget.by_type('text')).to include(text_widget)
        expect(Widget.by_type('text')).not_to include(html_widget)
      end
    end

    describe '.ordered' do
      it 'orders widgets by position' do
        widget1 = create(:widget, position: 2, tenant: tenant)
        widget2 = create(:widget, position: 1, tenant: tenant)
        
        expect(Widget.ordered.first).to eq(widget2)
        expect(Widget.ordered.last).to eq(widget1)
      end
    end
  end

  describe 'instance methods' do
    describe '#render_content' do
      it 'returns HTML content for HTML widgets' do
        widget = build(:widget, widget_type: 'html', content: '<p>Test HTML</p>', tenant: tenant)
        expect(widget.render_content).to eq('<p>Test HTML</p>')
      end
      
      it 'returns escaped content for text widgets' do
        widget = build(:widget, widget_type: 'text', content: '<script>alert("test")</script>', tenant: tenant)
        expect(widget.render_content).to include('&lt;script&gt;')
      end
      
      it 'returns empty string when content is nil' do
        widget = build(:widget, content: nil, tenant: tenant)
        expect(widget.render_content).to eq('')
      end
    end

    describe '#html_widget?' do
      it 'returns true for HTML widgets' do
        widget = build(:widget, widget_type: 'html', tenant: tenant)
        expect(widget.html_widget?).to be true
      end
      
      it 'returns false for non-HTML widgets' do
        widget = build(:widget, widget_type: 'text', tenant: tenant)
        expect(widget.html_widget?).to be false
      end
    end

    describe '#text_widget?' do
      it 'returns true for text widgets' do
        widget = build(:widget, widget_type: 'text', tenant: tenant)
        expect(widget.text_widget?).to be true
      end
      
      it 'returns false for non-text widgets' do
        widget = build(:widget, widget_type: 'html', tenant: tenant)
        expect(widget.text_widget?).to be false
      end
    end
  end

  describe 'callbacks' do
    describe 'after_initialize' do
      it 'sets default values' do
        widget = Widget.new
        expect(widget.active).to be true
        expect(widget.position).to eq(0)
        expect(widget.widget_type).to eq('text')
      end
    end
  end
end
