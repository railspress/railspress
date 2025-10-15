require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:default)
    @post = posts(:one)
    @comment_params = {
      content: "This is a test comment",
      author_name: "John Doe",
      author_email: "john@example.com"
    }
  end

  test "should create comment for post with minimal params" do
    assert_difference("Comment.count") do
      post "/comments", params: { post_id: @post.slug, comment: @comment_params }
    end

    comment = Comment.last
    assert_equal @post, comment.commentable
    assert_equal "This is a test comment", comment.content
    assert_equal "John Doe", comment.author_name
    assert_equal "john@example.com", comment.author_email
    assert_equal "pending", comment.status
    assert_equal "comment", comment.comment_type
    assert_equal "0", comment.comment_approved
    assert_equal "127.0.0.1", comment.author_ip
    assert_equal "Unknown", comment.author_agent
    assert_nil comment.user

    assert_redirected_to root_path
  end

  test "should not create comment without content" do
    invalid_params = { author_name: "John Doe", author_email: "john@example.com" }
    
    assert_no_difference("Comment.count") do
      post "/comments", params: { post_id: @post.slug, comment: invalid_params }
    end

    assert_redirected_to root_path
  end

  test "should not create comment without author name" do
    invalid_params = { content: "Test comment", author_email: "john@example.com" }
    
    assert_no_difference("Comment.count") do
      post "/comments", params: { post_id: @post.slug, comment: invalid_params }
    end

    assert_redirected_to root_path
  end

  test "should not create comment with invalid email" do
    invalid_params = { content: "Test comment", author_name: "John Doe", author_email: "invalid" }
    
    assert_no_difference("Comment.count") do
      post "/comments", params: { post_id: @post.slug, comment: invalid_params }
    end

    assert_redirected_to root_path
  end
end
