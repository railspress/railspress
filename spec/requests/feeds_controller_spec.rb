require 'rails_helper'

RSpec.describe FeedsController, type: :request do
  let(:user) { create(:user) }
  let(:category_taxonomy) { create(:taxonomy, :category) }
  let(:tag_taxonomy) { create(:taxonomy, :post_tag) }
  let(:category) { create(:term, :category, taxonomy: category_taxonomy) }
  let(:tag) { create(:term, :tag, taxonomy: tag_taxonomy) }
  
  before do
    # Create site settings
    create(:site_setting, :site_title)
    create(:site_setting, :site_description)
    
    # Create taxonomies
    category_taxonomy
    tag_taxonomy
  end

  describe 'GET /feed' do
    context 'with published posts' do
      let!(:published_post) do
        create(:post, :with_categories, :with_tags, user: user, published_at: 1.hour.ago)
      end
      let!(:draft_post) { create(:post, :draft, user: user) }
      let!(:scheduled_post) { create(:post, :scheduled, user: user) }

      it 'returns RSS feed with only published posts' do
        get '/feed'
        
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/rss+xml')
        expect(response.body).to include(published_post.title)
        expect(response.body).not_to include(draft_post.title)
        expect(response.body).not_to include(scheduled_post.title)
      end

      it 'includes proper RSS structure' do
        get '/feed'
        
        expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(response.body).to include('<rss version="2.0"')
        expect(response.body).to include('xmlns:atom="http://www.w3.org/2005/Atom"')
        expect(response.body).to include('xmlns:dc="http://purl.org/dc/elements/1.1/"')
        expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
        expect(response.body).to include('<channel>')
        expect(response.body).to include('</channel>')
        expect(response.body).to include('</rss>')
      end

      it 'includes post details in RSS format' do
        get '/feed'
        
        expect(response.body).to include("<title>#{published_post.title}</title>")
        expect(response.body).to include("<link>http://localhost:3000/blog/#{published_post.slug}</link>")
        expect(response.body).to include("<guid isPermaLink=\"true\">http://localhost:3000/blog/#{published_post.slug}</guid>")
        expect(response.body).to include("<dc:creator>#{published_post.user.name}</dc:creator>")
        expect(response.body).to include("<author>#{published_post.user.email} (#{published_post.user.name})</author>")
      end

      it 'includes categories and tags' do
        get '/feed'
        
        expect(response.body).to include('<category domain="http://localhost:3000/category/uncategorized">Uncategorized</category>')
        # Tags should also be included as categories
        expect(response.body).to match(/<category domain="http:\/\/localhost:3000\/tag\/[^"]+">[^<]+<\/category>/)
      end

      it 'includes full content in content:encoded' do
        get '/feed'
        
        expect(response.body).to include('<content:encoded>')
        expect(response.body).to include('<![CDATA[')
        expect(response.body).to include(published_post.content.to_s)
        expect(response.body).to include(']]>')
        expect(response.body).to include('</content:encoded>')
      end

      it 'sets proper cache headers' do
        get '/feed'
        
        expect(response.headers['Cache-Control']).to include('max-age=3600')
        expect(response.headers['Cache-Control']).to include('public')
      end
    end

    context 'with no posts' do
      it 'returns empty RSS feed' do
        get '/feed'
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<channel>')
        expect(response.body).to include('</channel>')
        expect(response.body).not_to include('<item>')
      end
    end
  end

  describe 'GET /feed.xml' do
    let!(:published_post) { create(:post, :with_categories, :with_tags, user: user) }

    it 'returns XML feed with same content as RSS' do
      get '/feed.xml'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/xml')
      expect(response.body).to include(published_post.title)
    end

    it 'includes proper XML structure' do
      get '/feed.xml'
      
      expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(response.body).to include('<rss version="2.0"')
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end

    it 'is valid XML' do
      get '/feed.xml'
      
      expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
    end
  end

  describe 'GET /feed.rss' do
    let!(:published_post) { create(:post, :with_categories, :with_tags, user: user) }

    it 'returns RSS feed' do
      get '/feed.rss'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
      expect(response.body).to include(published_post.title)
    end

    it 'is valid XML' do
      get '/feed.rss'
      
      expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
    end
  end

  describe 'GET /feed.atom' do
    let!(:published_post) { create(:post, :with_categories, :with_tags, user: user) }

    it 'returns Atom feed' do
      get '/feed.atom'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/atom+xml')
      expect(response.body).to include(published_post.title)
    end

    it 'includes proper Atom structure' do
      get '/feed.atom'
      
      expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(response.body).to include('<feed xmlns="http://www.w3.org/2005/Atom">')
      expect(response.body).to include('<entry>')
      expect(response.body).to include('</entry>')
      expect(response.body).to include('</feed>')
    end

    it 'includes post details in Atom format' do
      get '/feed.atom'
      
      expect(response.body).to include("<title>#{published_post.title}</title>")
      expect(response.body).to include("<link href=\"http://localhost:3000/blog/#{published_post.slug}\" rel=\"alternate\"/>")
      expect(response.body).to include("<id>http://localhost:3000/blog/#{published_post.slug}</id>")
      expect(response.body).to include("<author>")
      expect(response.body).to include("<name>#{published_post.user.name}</name>")
      expect(response.body).to include("<email>#{published_post.user.email}</email>")
      expect(response.body).to include("</author>")
    end

    it 'includes categories as Atom categories' do
      get '/feed.atom'
      
      expect(response.body).to include('<category term="uncategorized" label="Uncategorized"/>')
      # Tags should also be included as categories
      expect(response.body).to match(/<category term="[^"]+" label="[^"]+"\/>/)
    end

    it 'is valid XML' do
      get '/feed.atom'
      
      expect { Nokogiri::XML(response.body) { |config| config.strict } }.not_to raise_error
    end
  end

  describe 'GET /feed/posts' do
    let!(:published_post) { create(:post, :with_categories, :with_tags, user: user) }

    it 'returns RSS feed for posts' do
      get '/feed/posts'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
      expect(response.body).to include(published_post.title)
    end
  end

  describe 'GET /feed/comments' do
    let!(:post) { create(:post, user: user) }
    let!(:approved_comment) { create(:comment, commentable: post, status: 'approved') }
    let!(:pending_comment) { create(:comment, commentable: post, status: 'pending') }

    it 'returns RSS feed with only approved comments' do
      get '/feed/comments'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
      expect(response.body).to include(approved_comment.content)
      expect(response.body).not_to include(pending_comment.content)
    end
  end

  describe 'GET /feed/category/:slug' do
    let!(:category_post) { create(:post, :with_categories, user: user) }
    let!(:other_post) { create(:post, user: user) }

    it 'returns RSS feed for specific category' do
      get "/feed/category/#{category.slug}"
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
      expect(response.body).to include("Category: #{category.name}")
    end
  end

  describe 'GET /feed/tag/:slug' do
    let!(:tagged_post) { create(:post, :with_tags, user: user) }
    let!(:other_post) { create(:post, user: user) }

    it 'returns RSS feed for specific tag' do
      get "/feed/tag/#{tag.slug}"
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
      expect(response.body).to include("Tag: #{tag.name}")
    end
  end

  describe 'GET /feed/author/:id' do
    let!(:author_post) { create(:post, user: user) }
    let(:other_user) { create(:user) }
    let!(:other_post) { create(:post, user: other_user) }

    it 'returns RSS feed for specific author' do
      get "/feed/author/#{user.id}"
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
      expect(response.body).to include("Author: #{user.name}")
      expect(response.body).to include(author_post.title)
      expect(response.body).not_to include(other_post.title)
    end
  end

  describe 'GET /feed/pages' do
    let!(:published_page) { create(:page, status: :published) }
    let!(:draft_page) { create(:page, status: :draft) }

    it 'returns RSS feed with only published pages' do
      get '/feed/pages'
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/rss+xml')
      expect(response.body).to include(published_page.title)
      expect(response.body).not_to include(draft_page.title)
    end
  end

  describe 'XML namespace validation' do
    let!(:published_post) { create(:post, :with_categories, :with_tags, user: user) }

    it 'RSS feed has all required namespaces' do
      get '/feed.rss'
      
      expect(response.body).to include('xmlns:atom="http://www.w3.org/2005/Atom"')
      expect(response.body).to include('xmlns:dc="http://purl.org/dc/elements/1.1/"')
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end

    it 'XML feed has all required namespaces' do
      get '/feed.xml'
      
      expect(response.body).to include('xmlns:atom="http://www.w3.org/2005/Atom"')
      expect(response.body).to include('xmlns:dc="http://purl.org/dc/elements/1.1/"')
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end

    it 'content:encoded element is properly namespaced' do
      get '/feed.xml'
      
      expect(response.body).to include('<content:encoded>')
      expect(response.body).to include('</content:encoded>')
    end
  end

  describe 'feed limits' do
    before do
      # Create more than 50 posts to test the limit
      55.times do |i|
        create(:post, user: user, title: "Post #{i}", published_at: i.hours.ago)
      end
    end

    it 'limits posts to 50 in main feed' do
      get '/feed'
      
      expect(response.body.scan('<item>').count).to eq(50)
    end

    it 'limits posts to 50 in category feed' do
      get "/feed/category/#{category.slug}"
      
      expect(response.body.scan('<item>').count).to be <= 50
    end

    it 'limits posts to 50 in tag feed' do
      get "/feed/tag/#{tag.slug}"
      
      expect(response.body.scan('<item>').count).to be <= 50
    end

    it 'limits posts to 50 in author feed' do
      get "/feed/author/#{user.id}"
      
      expect(response.body.scan('<item>').count).to eq(50)
    end
  end

  describe 'feed ordering' do
    let!(:old_post) { create(:post, user: user, published_at: 3.days.ago) }
    let!(:new_post) { create(:post, user: user, published_at: 1.day.ago) }
    let!(:middle_post) { create(:post, user: user, published_at: 2.days.ago) }

    it 'orders posts by published_at desc' do
      get '/feed'
      
      new_index = response.body.index(new_post.title)
      middle_index = response.body.index(middle_post.title)
      old_index = response.body.index(old_post.title)
      
      expect(new_index).to be < middle_index
      expect(middle_index).to be < old_index
    end
  end
end
