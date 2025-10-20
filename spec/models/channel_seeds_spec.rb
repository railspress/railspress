require 'rails_helper'

RSpec.describe 'Channel Seeds', type: :model do
  describe 'Default Channels' do
    before do
      # Load the seeds
      load Rails.root.join('db', 'seeds.rb')
    end

    it 'creates the Web channel' do
      web_channel = Channel.find_by(slug: 'web')
      expect(web_channel).to be_present
      expect(web_channel.name).to eq('Web')
      expect(web_channel.domain).to be_nil
      expect(web_channel.locale).to eq('en')
      expect(web_channel.metadata).to eq({})
      expect(web_channel.settings).to eq({})
    end

    it 'creates the Mobile channel' do
      mobile_channel = Channel.find_by(slug: 'mobile')
      expect(mobile_channel).to be_present
      expect(mobile_channel.name).to eq('Mobile')
      expect(mobile_channel.domain).to be_nil
      expect(mobile_channel.locale).to eq('en')
      expect(mobile_channel.metadata).to eq({})
      expect(mobile_channel.settings).to eq({})
    end

    it 'creates the Newsletter channel' do
      newsletter_channel = Channel.find_by(slug: 'newsletter')
      expect(newsletter_channel).to be_present
      expect(newsletter_channel.name).to eq('Newsletter')
      expect(newsletter_channel.domain).to be_nil
      expect(newsletter_channel.locale).to eq('en')
      expect(newsletter_channel.metadata).to eq({})
      expect(newsletter_channel.settings).to eq({})
    end

    it 'creates the Smart TV channel' do
      smarttv_channel = Channel.find_by(slug: 'smarttv')
      expect(smarttv_channel).to be_present
      expect(smarttv_channel.name).to eq('Smart TV')
      expect(smarttv_channel.domain).to be_nil
      expect(smarttv_channel.locale).to eq('en')
      expect(smarttv_channel.metadata).to eq({})
      expect(smarttv_channel.settings).to eq({})
    end

    it 'creates channels with unique slugs' do
      channels = Channel.where(slug: ['web', 'mobile', 'newsletter', 'smarttv'])
      expect(channels.count).to eq(4)
      expect(channels.map(&:slug).uniq.count).to eq(4)
    end

    it 'does not create duplicate channels on multiple seed runs' do
      initial_count = Channel.count
      
      # Run seeds again
      load Rails.root.join('db', 'seeds.rb')
      
      expect(Channel.count).to eq(initial_count)
    end

    it 'creates channels with proper timestamps' do
      web_channel = Channel.find_by(slug: 'web')
      expect(web_channel.created_at).to be_present
      expect(web_channel.updated_at).to be_present
    end
  end

  describe 'Channel Factory' do
    it 'creates valid channels with factory' do
      channel = create(:channel)
      expect(channel).to be_valid
      expect(channel.name).to be_present
      expect(channel.slug).to be_present
      expect(channel.locale).to eq('en')
    end

    it 'creates web channel with factory trait' do
      web_channel = create(:channel, :web)
      expect(web_channel.name).to eq('Web')
      expect(web_channel.slug).to eq('web')
    end

    it 'creates mobile channel with factory trait' do
      mobile_channel = create(:channel, :mobile)
      expect(mobile_channel.name).to eq('Mobile')
      expect(mobile_channel.slug).to eq('mobile')
    end

    it 'creates newsletter channel with factory trait' do
      newsletter_channel = create(:channel, :newsletter)
      expect(newsletter_channel.name).to eq('Newsletter')
      expect(newsletter_channel.slug).to eq('newsletter')
    end

    it 'creates smarttv channel with factory trait' do
      smarttv_channel = create(:channel, :smarttv)
      expect(smarttv_channel.name).to eq('Smart TV')
      expect(smarttv_channel.slug).to eq('smarttv')
    end
  end

  describe 'Channel Associations' do
    let(:web_channel) { create(:channel, :web) }
    let(:post) { create(:post) }
    let(:page) { create(:page) }
    let(:medium) { create(:medium) }

    it 'associates posts with channels' do
      post.channels << web_channel
      expect(post.channels).to include(web_channel)
      expect(web_channel.posts).to include(post)
    end

    it 'associates pages with channels' do
      page.channels << web_channel
      expect(page.channels).to include(web_channel)
      expect(web_channel.pages).to include(page)
    end

    it 'associates media with channels' do
      medium.channels << web_channel
      expect(medium.channels).to include(web_channel)
      expect(web_channel.media).to include(medium)
    end

    it 'allows multiple channels per content' do
      mobile_channel = create(:channel, :mobile)
      
      post.channels << [web_channel, mobile_channel]
      
      expect(post.channels).to include(web_channel, mobile_channel)
      expect(web_channel.posts).to include(post)
      expect(mobile_channel.posts).to include(post)
    end

    it 'allows multiple content per channel' do
      post2 = create(:post)
      
      web_channel.posts << [post, post2]
      
      expect(web_channel.posts).to include(post, post2)
      expect(post.channels).to include(web_channel)
      expect(post2.channels).to include(web_channel)
    end
  end

  describe 'Channel Override Seeds' do
    let(:web_channel) { create(:channel, :web) }
    let(:mobile_channel) { create(:channel, :mobile) }
    let(:post) { create(:post) }

    it 'creates override with factory' do
      override = create(:channel_override, channel: web_channel, resource: post)
      expect(override).to be_valid
      expect(override.channel).to eq(web_channel)
      expect(override.resource).to eq(post)
      expect(override.kind).to eq('override')
      expect(override.enabled).to be true
    end

    it 'creates exclusion with factory trait' do
      exclusion = create(:channel_override, :exclusion, channel: web_channel, resource: post)
      expect(exclusion.kind).to eq('exclude')
      expect(exclusion.should_exclude_resource?).to be true
    end

    it 'creates disabled override with factory trait' do
      disabled_override = create(:channel_override, :disabled, channel: web_channel, resource: post)
      expect(disabled_override.enabled).to be false
    end

    it 'creates override with complex data' do
      complex_override = create(:channel_override,
        channel: web_channel,
        resource: post,
        path: 'metadata.author',
        data: { name: 'Channel Author', email: 'author@channel.com' }
      )
      
      expect(complex_override.path).to eq('metadata.author')
      expect(complex_override.data).to eq({ name: 'Channel Author', email: 'author@channel.com' })
    end
  end

  describe 'Channel Validation' do
    it 'validates presence of name' do
      channel = build(:channel, name: '')
      expect(channel).not_to be_valid
      expect(channel.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of slug' do
      channel = build(:channel, slug: '')
      expect(channel).not_to be_valid
      expect(channel.errors[:slug]).to include("can't be blank")
    end

    it 'validates uniqueness of slug' do
      create(:channel, slug: 'test-slug')
      duplicate_channel = build(:channel, slug: 'test-slug')
      expect(duplicate_channel).not_to be_valid
      expect(duplicate_channel.errors[:slug]).to include('has already been taken')
    end

    it 'validates locale format' do
      invalid_channel = build(:channel, locale: 'invalid-locale')
      expect(invalid_channel).not_to be_valid
      expect(invalid_channel.errors[:locale]).to include('is invalid')
    end

    it 'accepts valid locales' do
      valid_locales = ['en', 'es', 'fr', 'de', 'pt-BR']
      valid_locales.each do |locale|
        channel = build(:channel, locale: locale)
        expect(channel).to be_valid, "Locale #{locale} should be valid"
      end
    end
  end

  describe 'Channel Override Validation' do
    let(:web_channel) { create(:channel, :web) }
    let(:post) { create(:post) }

    it 'validates presence of resource_type' do
      override = build(:channel_override, channel: web_channel, resource_type: '')
      expect(override).not_to be_valid
      expect(override.errors[:resource_type]).to include("can't be blank")
    end

    it 'validates presence of kind' do
      override = build(:channel_override, channel: web_channel, kind: '')
      expect(override).not_to be_valid
      expect(override.errors[:kind]).to include("can't be blank")
    end

    it 'validates inclusion of kind' do
      override = build(:channel_override, channel: web_channel, kind: 'invalid')
      expect(override).not_to be_valid
      expect(override.errors[:kind]).to include('is not included in the list')
    end

    it 'validates presence of path' do
      override = build(:channel_override, channel: web_channel, path: '')
      expect(override).not_to be_valid
      expect(override.errors[:path]).to include("can't be blank")
    end

    it 'validates presence of resource_id for specific overrides' do
      override = build(:channel_override, channel: web_channel, resource_id: nil)
      expect(override).not_to be_valid
      expect(override.errors[:resource_id]).to include("can't be blank")
    end
  end
end

