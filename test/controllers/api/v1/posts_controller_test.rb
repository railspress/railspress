require "test_helper"

class Api::V1::PostsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:admin)
    @tenant = @user.tenant
    @post = posts(:hello_world)
  end

  test "should get index" do
    get api_v1_posts_url, headers: auth_headers(@user)
    assert_response :success
    assert_equal "application/json", response.content_type
    
    data = JSON.parse(response.body)
    assert data.key?("posts")
    assert data.key?("meta")
    assert data["posts"].is_a?(Array)
  end

  test "should get index with pagination" do
    get api_v1_posts_url, params: { page: 1, per_page: 5 }, headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data.key?("posts")
    assert data.key?("meta")
    assert data["meta"].key?("pagination")
  end

  test "should get index with filtering" do
    get api_v1_posts_url, params: { status: "published" }, headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    data["posts"].each do |post|
      assert_equal "published", post["status"]
    end
  end

  test "should get index with search" do
    get api_v1_posts_url, params: { search: "hello" }, headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["posts"].any? { |post| post["title"].include?("hello") }
  end

  test "should get show" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    assert_equal "application/json", response.content_type
    
    data = JSON.parse(response.body)
    assert data.key?("post")
    assert_equal @post.id, data["post"]["id"]
    assert_equal @post.title, data["post"]["title"]
  end

  test "should create post" do
    assert_difference("Post.count") do
      post api_v1_posts_url, params: {
        post: {
          title: "New API Post",
          content: "This is a new post created via API",
          status: "published"
        }
      }, headers: auth_headers(@user)
    end
    
    assert_response :created
    assert_equal "application/json", response.content_type
    
    data = JSON.parse(response.body)
    assert data.key?("post")
    assert_equal "New API Post", data["post"]["title"]
    assert_equal "This is a new post created via API", data["post"]["content"]
  end

  test "should not create post without title" do
    assert_no_difference("Post.count") do
      post api_v1_posts_url, params: {
        post: {
          title: "",
          content: "This is a post without title",
          status: "published"
        }
      }, headers: auth_headers(@user)
    end
    
    assert_response :unprocessable_entity
    
    data = JSON.parse(response.body)
    assert data.key?("errors")
    assert data["errors"].key?("title")
  end

  test "should update post" do
    patch api_v1_post_url(@post), params: {
      post: {
        title: "Updated API Post",
        content: "This post has been updated via API"
      }
    }, headers: auth_headers(@user)
    
    assert_response :success
    assert_equal "application/json", response.content_type
    
    data = JSON.parse(response.body)
    assert data.key?("post")
    assert_equal "Updated API Post", data["post"]["title"]
    
    @post.reload
    assert_equal "Updated API Post", @post.title
    assert_equal "This post has been updated via API", @post.content
  end

  test "should not update post with invalid data" do
    patch api_v1_post_url(@post), params: {
      post: {
        title: ""
      }
    }, headers: auth_headers(@user)
    
    assert_response :unprocessable_entity
    
    data = JSON.parse(response.body)
    assert data.key?("errors")
    assert data["errors"].key?("title")
  end

  test "should destroy post" do
    assert_difference("Post.count", -1) do
      delete api_v1_post_url(@post), headers: auth_headers(@user)
    end
    
    assert_response :no_content
  end

  test "should require authentication" do
    get api_v1_posts_url
    assert_response :unauthorized
    
    data = JSON.parse(response.body)
    assert data.key?("error")
    assert_includes data["error"], "authentication"
  end

  test "should require valid API token" do
    get api_v1_posts_url, headers: { "Authorization" => "Bearer invalid-token" }
    assert_response :unauthorized
  end

  test "should handle post with custom fields" do
    # Create custom field
    custom_field = CustomField.create!(
      name: "featured_image",
      field_type: "text",
      tenant: @tenant
    )
    
    # Create post with custom field
    post api_v1_posts_url, params: {
      post: {
        title: "Post with Custom Field",
        content: "This post has a custom field",
        status: "published",
        custom_fields: {
          featured_image: "https://example.com/image.jpg"
        }
      }
    }, headers: auth_headers(@user)
    
    assert_response :created
    
    data = JSON.parse(response.body)
    assert data["post"].key?("custom_fields")
    assert_equal "https://example.com/image.jpg", data["post"]["custom_fields"]["featured_image"]
  end

  test "should handle post with taxonomies" do
    # Create taxonomy and term
    taxonomy = Taxonomy.create!(
      name: "Categories",
      taxonomy_type: "category",
      tenant: @tenant
    )
    
    category = Term.create!(
      name: "Technology",
      slug: "technology",
      taxonomy: taxonomy,
      tenant: @tenant
    )
    
    # Create post with category
    post api_v1_posts_url, params: {
      post: {
        title: "Post with Category",
        content: "This post has a category",
        status: "published",
        taxonomy_ids: [category.id]
      }
    }, headers: auth_headers(@user)
    
    assert_response :created
    
    data = JSON.parse(response.body)
    assert data["post"].key?("taxonomies")
    assert data["post"]["taxonomies"].any? { |t| t["name"] == "Technology" }
  end

  test "should handle post with media" do
    # Create upload and medium
    upload = Upload.create!(
      filename: "test-image.jpg",
      content_type: "image/jpeg",
      file_size: 1024,
      storage_provider: StorageProvider.first,
      tenant: @tenant
    )
    
    medium = Medium.create!(
      title: "Test Image",
      alt_text: "A test image",
      upload: upload,
      user: @user,
      tenant: @tenant
    )
    
    # Create post with featured media
    post api_v1_posts_url, params: {
      post: {
        title: "Post with Media",
        content: "This post has featured media",
        status: "published",
        featured_media_id: medium.id
      }
    }, headers: auth_headers(@user)
    
    assert_response :created
    
    data = JSON.parse(response.body)
    assert data["post"].key?("featured_media")
    assert_equal medium.id, data["post"]["featured_media"]["id"]
  end

  test "should handle post with SEO data" do
    post api_v1_posts_url, params: {
      post: {
        title: "SEO Post",
        content: "This post has SEO data",
        status: "published",
        seo_title: "Custom SEO Title",
        seo_description: "Custom SEO description",
        seo_keywords: "seo, test, rails"
      }
    }, headers: auth_headers(@user)
    
    assert_response :created
    
    data = JSON.parse(response.body)
    assert data["post"].key?("seo_title")
    assert data["post"].key?("seo_description")
    assert data["post"].key?("seo_keywords")
    assert_equal "Custom SEO Title", data["post"]["seo_title"]
  end

  test "should handle bulk operations" do
    # Create multiple posts
    post1 = Post.create!(
      title: "Bulk Post 1",
      content: "Content 1",
      status: "published",
      user: @user,
      tenant: @tenant
    )
    
    post2 = Post.create!(
      title: "Bulk Post 2",
      content: "Content 2",
      status: "draft",
      user: @user,
      tenant: @tenant
    )
    
    # Bulk update
    patch api_v1_posts_url, params: {
      posts: [
        { id: post1.id, status: "draft" },
        { id: post2.id, status: "published" }
      ]
    }, headers: auth_headers(@user)
    
    assert_response :success
    
    post1.reload
    post2.reload
    assert_equal "draft", post1.status
    assert_equal "published", post2.status
  end

  test "should handle post with comments" do
    # Create comment
    comment = Comment.create!(
      content: "Great post!",
      author_name: "John Doe",
      author_email: "john@example.com",
      commentable: @post,
      user: @user,
      status: "approved",
      comment_type: "comment",
      comment_approved: "1",
      tenant: @tenant
    )
    
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("comments")
    assert data["post"]["comments"].any? { |c| c["content"] == "Great post!" }
  end

  test "should handle post with author information" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("author")
    assert_equal @post.user.name, data["post"]["author"]["name"]
    assert_equal @post.user.email, data["post"]["author"]["email"]
  end

  test "should handle post with publication dates" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("created_at")
    assert data["post"].key?("updated_at")
    assert data["post"].key?("published_at")
  end

  test "should handle post with slug" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("slug")
    assert_equal @post.slug, data["post"]["slug"]
  end

  test "should handle post with excerpt" do
    @post.update!(excerpt: "This is a custom excerpt")
    
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("excerpt")
    assert_equal "This is a custom excerpt", data["post"]["excerpt"]
  end

  test "should handle post with word count" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("word_count")
    assert data["post"]["word_count"].is_a?(Integer)
  end

  test "should handle post with reading time" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("reading_time")
    assert data["post"]["reading_time"].is_a?(Integer)
  end

  test "should handle post with view count" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("view_count")
    assert data["post"]["view_count"].is_a?(Integer)
  end

  test "should handle post with like count" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("like_count")
    assert data["post"]["like_count"].is_a?(Integer)
  end

  test "should handle post with share count" do
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("share_count")
    assert data["post"]["share_count"].is_a?(Integer)
  end

  test "should handle post with social media data" do
    @post.update!(
      social_title: "Social Media Title",
      social_description: "Social Media Description",
      social_image: "https://example.com/social-image.jpg"
    )
    
    get api_v1_post_url(@post), headers: auth_headers(@user)
    assert_response :success
    
    data = JSON.parse(response.body)
    assert data["post"].key?("social_title")
    assert data["post"].key?("social_description")
    assert data["post"].key?("social_image")
    assert_equal "Social Media Title", data["post"]["social_title"]
  end

  private

  def auth_headers(user)
    {
      "Authorization" => "Bearer #{user.api_token}",
      "Content-Type" => "application/json"
    }
  end
end


