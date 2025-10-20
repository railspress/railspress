require 'rails_helper'

RSpec.describe MenuItem, type: :model do
  let(:tenant) { create(:tenant) }
  let(:menu) { create(:menu, tenant: tenant) }
  let(:menu_item) { build(:menu_item, menu: menu, tenant: tenant) }

  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:menu) }
    it { should belong_to(:parent).optional }
    it { should have_many(:children).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:label) }
    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).only_integer }
  end

  describe 'scopes' do
    let!(:root_item) { create(:menu_item, menu: menu, parent: nil, tenant: tenant) }
    let!(:child_item) { create(:menu_item, menu: menu, parent: root_item, tenant: tenant) }

    describe '.root_items' do
      it 'returns items without parent' do
        expect(MenuItem.root_items).to include(root_item)
        expect(MenuItem.root_items).not_to include(child_item)
      end
    end

    describe '.ordered' do
      it 'orders items by position' do
        # Use a fresh menu to avoid interference from other tests
        fresh_menu = create(:menu, tenant: tenant, name: "Test Menu #{Time.current.to_i}")
        
        # Create items with specific positions, bypassing the callback
        item1 = build(:menu_item, menu: fresh_menu, tenant: tenant, position: 2)
        item1.save!(validate: false)
        item2 = build(:menu_item, menu: fresh_menu, tenant: tenant, position: 1)
        item2.save!(validate: false)
        
        # Test ordering for this specific menu
        ordered_items = MenuItem.where(menu: fresh_menu).ordered
        expect(ordered_items.first).to eq(item2)
        expect(ordered_items.last).to eq(item1)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets position automatically' do
        item = build(:menu_item, menu: menu, position: nil, tenant: tenant)
        item.save!
        expect(item.position).to eq(1)
      end
      
      it 'increments position for additional items' do
        create(:menu_item, menu: menu, tenant: tenant)
        item = build(:menu_item, menu: menu, position: nil, tenant: tenant)
        item.save!
        expect(item.position).to eq(2)
      end
    end
  end
end
