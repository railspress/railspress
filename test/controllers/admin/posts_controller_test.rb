require "test_helper"

class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @post = posts(:one)
    sign_in @user
  end

  test "should get index" do
    get admin_posts_url
    assert_response :success
    assert_select "h1", "Posts"
  end

  test "should get new" do
    get new_admin_post_url
    assert_response :success
    assert_select "h1", "New Post"
  end

  test "should create post" do
    assert_difference("Post.count") do
      post admin_posts_url, params: { 
        post: { 
          title: "Test Post", 
          content: "Test content",
          status: "published",
          category_id: categories(:one).id
        } 
      }
    end

    assert_redirected_to admin_post_url(Post.last)
    assert_equal "Post was successfully created.", flash[:notice]
  end

  test "should not create post with invalid data" do
    assert_no_difference("Post.count") do
      post admin_posts_url, params: { 
        post: { 
          title: "", 
          content: "",
          status: "invalid_status"
        } 
      }
    end

    assert_response :unprocessable_entity
    assert_template :new
  end

  test "should show post" do
    get admin_post_url(@post)
    assert_response :success
    assert_select "h1", @post.title
  end

  test "should get edit" do
    get edit_admin_post_url(@post)
    assert_response :success
    assert_select "h1", "Edit Post"
  end

  test "should update post" do
    patch admin_post_url(@post), params: { 
      post: { 
        title: "Updated Title",
        content: "Updated content"
      } 
    }
    
    assert_redirected_to admin_post_url(@post)
    assert_equal "Post was successfully updated.", flash[:notice]
    
    @post.reload
    assert_equal "Updated Title", @post.title
    assert_equal "Updated content", @post.content
  end

  test "should not update post with invalid data" do
    patch admin_post_url(@post), params: { 
      post: { 
        title: "",
        content: ""
      } 
    }
    
    assert_response :unprocessable_entity
    assert_template :edit
  end

  test "should destroy post" do
    assert_difference("Post.count", -1) do
      delete admin_post_url(@post)
    end

    assert_redirected_to admin_posts_url
    assert_equal "Post was successfully deleted.", flash[:notice]
  end

  test "should require authentication" do
    sign_out @user
    
    get admin_posts_url
    assert_redirected_to new_user_session_url
  end

  test "should require admin role for non-admin users" do
    regular_user = users(:user)
    sign_in regular_user
    
    get admin_posts_url
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
  end

  test "should filter posts by status" do
    published_post = posts(:published)
    draft_post = posts(:draft)
    
    get admin_posts_url, params: { status: "published" }
    assert_response :success
    assert_select ".post-row", count: 1
    assert_select ".post-title", published_post.title
  end

  test "should filter posts by category" do
    category = categories(:one)
    post_in_category = posts(:one)
    
    get admin_posts_url, params: { category_id: category.id }
    assert_response :success
    assert_select ".post-row", count: 1
    assert_select ".post-title", post_in_category.title
  end

  test "should search posts by title" do
    search_term = @post.title.split.first
    
    get admin_posts_url, params: { search: search_term }
    assert_response :success
    assert_select ".post-row", count: 1
    assert_select ".post-title", @post.title
  end

  test "should search posts by content" do
    search_term = @post.content.split.first
    
    get admin_posts_url, params: { search: search_term }
    assert_response :success
    assert_select ".post-row", count: 1
    assert_select ".post-title", @post.title
  end

  test "should handle bulk actions" do
    post_ids = [posts(:one).id, posts(:two).id]
    
    post admin_bulk_action_posts_url, params: {
      bulk_action: "publish",
      post_ids: post_ids
    }
    
    assert_redirected_to admin_posts_url
    assert_equal "Posts were successfully updated.", flash[:notice]
    
    posts(:one).reload
    posts(:two).reload
    assert_equal "published", posts(:one).status
    assert_equal "published", posts(:two).status
  end

  test "should handle bulk delete" do
    post_ids = [posts(:one).id, posts(:two).id]
    
    assert_difference("Post.count", -2) do
      post admin_bulk_action_posts_url, params: {
        bulk_action: "delete",
        post_ids: post_ids
      }
    end
    
    assert_redirected_to admin_posts_url
    assert_equal "Posts were successfully deleted.", flash[:notice]
  end

  test "should preview post" do
    get preview_admin_post_url(@post)
    assert_response :success
    assert_select "h1", @post.title
  end

  test "should duplicate post" do
    assert_difference("Post.count") do
      post duplicate_admin_post_url(@post)
    end
    
    assert_redirected_to admin_posts_url
    assert_equal "Post was successfully duplicated.", flash[:notice]
    
    duplicated_post = Post.last
    assert_equal "#{@post.title} (Copy)", duplicated_post.title
    assert_equal @post.content, duplicated_post.content
    assert_equal "draft", duplicated_post.status
  end

  test "should export posts" do
    get export_admin_posts_url, params: { format: :csv }
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_includes response.body, @post.title
  end

  test "should import posts" do
    csv_content = "title,content,status\nImported Post,Imported content,published"
    
    post import_admin_posts_url, params: {
      file: fixture_file_upload("posts.csv", "text/csv")
    }
    
    assert_redirected_to admin_posts_url
    assert_equal "Posts were successfully imported.", flash[:notice]
  end

  test "should handle ajax requests" do
    get admin_posts_url, xhr: true
    assert_response :success
    assert_equal "text/javascript", response.content_type
  end

  test "should handle pagination" do
    # Create multiple posts to test pagination
    15.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content #{i}",
        author: @user,
        status: "published"
      )
    end
    
    get admin_posts_url, params: { page: 2 }
    assert_response :success
  end

  test "should handle sorting" do
    get admin_posts_url, params: { sort: "title", direction: "asc" }
    assert_response :success
  end

  test "should handle invalid sort parameters" do
    get admin_posts_url, params: { sort: "invalid_column", direction: "invalid_direction" }
    assert_response :success
  end

  test "should set author automatically on create" do
    post admin_posts_url, params: { 
      post: { 
        title: "Test Post", 
        content: "Test content",
        status: "published"
      } 
    }
    
    created_post = Post.last
    assert_equal @user, created_post.author
  end

  test "should not allow changing author unless admin" do
    other_user = users(:user)
    
    patch admin_post_url(@post), params: { 
      post: { 
        author_id: other_user.id
      } 
    }
    
    @post.reload
    assert_not_equal other_user, @post.author
  end

  test "should handle featured image upload" do
    post admin_posts_url, params: { 
      post: { 
        title: "Test Post", 
        content: "Test content",
        status: "published",
        featured_image: fixture_file_upload("test_image.jpg", "image/jpeg")
      } 
    }
    
    created_post = Post.last
    assert created_post.featured_image.attached?
  end

  test "should validate featured image format" do
    post admin_posts_url, params: { 
      post: { 
        title: "Test Post", 
        content: "Test content",
        status: "published",
        featured_image: fixture_file_upload("test_document.pdf", "application/pdf")
      } 
    }
    
    assert_response :unprocessable_entity
    assert_includes response.body, "must be an image"
  end

  test "should handle slug generation" do
    post admin_posts_url, params: { 
      post: { 
        title: "My Amazing Post Title", 
        content: "Test content",
        status: "published"
      } 
    }
    
    created_post = Post.last
    assert_equal "my-amazing-post-title", created_post.slug
  end

  test "should handle custom slug" do
    post admin_posts_url, params: { 
      post: { 
        title: "Test Post", 
        content: "Test content",
        status: "published",
        slug: "custom-slug"
      } 
    }
    
    created_post = Post.last
    assert_equal "custom-slug", created_post.slug
  end

  test "should handle slug conflicts" do
    existing_post = posts(:one)
    
    post admin_posts_url, params: { 
      post: { 
        title: existing_post.title, 
        content: "Test content",
        status: "published"
      } 
    }
    
    created_post = Post.last
    assert_not_equal existing_post.slug, created_post.slug
    assert created_post.slug.ends_with?("-2")
  end
end



