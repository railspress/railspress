require 'rails_helper'

RSpec.describe Menu, type: :model do
  let(:tenant) { create(:tenant) }
  let(:menu) { build(:menu, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should have_many(:menu_items).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:location) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'scopes' do
    let!(:header_menu) { create(:menu, location: 'header', tenant: tenant) }
    let!(:footer_menu) { create(:menu, :menu_footer, tenant: tenant) }

    describe '.by_location' do
      it 'returns menus by location' do
        expect(Menu.by_location('header')).to include(header_menu)
        expect(Menu.by_location('header')).not_to include(footer_menu)
      end
    end
  end

  describe 'instance methods' do
    describe '#root_items' do
      it 'returns menu items without parent' do
        root_item = create(:menu_item, menu: menu, parent: nil, tenant: tenant)
        child_item = create(:menu_item, menu: menu, parent: root_item, tenant: tenant)
        
        expect(menu.root_items).to include(root_item)
        expect(menu.root_items).not_to include(child_item)
      end
    end
  end
end
