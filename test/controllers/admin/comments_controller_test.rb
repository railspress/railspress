require "test_helper"

class Admin::CommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:admin)
    @tenant = @user.tenant
    @post = posts(:hello_world)
    @comment = Comment.create!(
      content: "This is a test comment",
      author_name: "Test Author",
      author_email: "test@example.com",
      commentable: @post,
      user: @user,
      status: "approved",
      comment_type: "comment",
      comment_approved: "1",
      author_ip: "127.0.0.1",
      author_agent: "Mozilla/5.0 (Test Browser)",
      tenant: @tenant
    )
  end

  test "should get index" do
    sign_in @user
    get admin_comments_url
    assert_response :success
    assert_select "h1", text: /Comments/
  end

  test "should get show" do
    sign_in @user
    get admin_comment_url(@comment)
    assert_response :success
    assert_select "h1", text: /Comment/
  end

  test "should get edit" do
    sign_in @user
    get edit_admin_comment_url(@comment)
    assert_response :success
    assert_select "form"
  end

  test "should update comment" do
    sign_in @user
    
    patch admin_comment_url(@comment), params: {
      comment: {
        content: "Updated comment content",
        status: "approved"
      }
    }
    
    assert_redirected_to admin_comment_url(@comment)
    assert_equal "Comment updated successfully.", flash[:notice]
    
    @comment.reload
    assert_equal "Updated comment content", @comment.content
    assert_equal "approved", @comment.status
  end

  test "should not update comment with invalid data" do
    sign_in @user
    
    patch admin_comment_url(@comment), params: {
      comment: {
        content: "",
        status: "invalid_status"
      }
    }
    
    assert_response :unprocessable_entity
  end

  test "should approve comment" do
    @comment.update!(status: "pending")
    sign_in @user
    
    post approve_admin_comment_url(@comment)
    
    assert_redirected_to admin_comments_url
    assert_equal "Comment approved.", flash[:notice]
    
    @comment.reload
    assert_equal "approved", @comment.status
  end

  test "should unapprove comment" do
    @comment.update!(status: "approved")
    sign_in @user
    
    post unapprove_admin_comment_url(@comment)
    
    assert_redirected_to admin_comments_url
    assert_equal "Comment unapproved.", flash[:notice]
    
    @comment.reload
    assert_equal "pending", @comment.status
  end

  test "should mark comment as spam" do
    @comment.update!(status: "approved")
    sign_in @user
    
    post spam_admin_comment_url(@comment)
    
    assert_redirected_to admin_comments_url
    assert_equal "Comment marked as spam.", flash[:notice]
    
    @comment.reload
    assert_equal "spam", @comment.status
  end

  test "should not spam comment" do
    @comment.update!(status: "spam")
    sign_in @user
    
    post not_spam_admin_comment_url(@comment)
    
    assert_redirected_to admin_comments_url
    assert_equal "Comment marked as not spam.", flash[:notice]
    
    @comment.reload
    assert_equal "pending", @comment.status
  end

  test "should trash comment" do
    sign_in @user
    
    assert_no_difference("Comment.count") do
      post trash_admin_comment_url(@comment)
    end
    
    assert_redirected_to admin_comments_url
    assert_equal "Comment moved to trash.", flash[:notice]
    
    @comment.reload
    assert @comment.trashed?
  end

  test "should restore comment" do
    sign_in @user
    @comment.trash!(@user)
    
    assert_no_difference("Comment.count") do
      post restore_admin_comment_url(@comment)
    end
    
    assert_redirected_to admin_comment_url(@comment)
    assert_equal "Comment restored from trash.", flash[:notice]
    
    @comment.reload
    assert_not @comment.trashed?
  end

  test "should destroy comment permanently" do
    sign_in @user
    
    assert_difference("Comment.count", -1) do
      delete admin_comment_url(@comment)
    end
    
    assert_redirected_to admin_comments_url
    assert_equal "Comment permanently deleted.", flash[:notice]
  end

  test "should bulk action approve comments" do
    # Create another comment
    comment2 = Comment.create!(
      content: "Another test comment",
      author_name: "Test Author 2",
      author_email: "test2@example.com",
      commentable: @post,
      user: @user,
      status: "pending",
      comment_type: "comment",
      comment_approved: "0",
      tenant: @tenant
    )
    
    sign_in @user
    
    post bulk_action_admin_comments_url, params: {
      bulk_action: "approve",
      comment_ids: [@comment.id, comment2.id]
    }
    
    assert_redirected_to admin_comments_url
    assert_equal "2 comments approved.", flash[:notice]
    
    @comment.reload
    comment2.reload
    assert_equal "approved", @comment.status
    assert_equal "approved", comment2.status
  end

  test "should bulk action trash comments" do
    # Create another comment
    comment2 = Comment.create!(
      content: "Another test comment",
      author_name: "Test Author 2",
      author_email: "test2@example.com",
      commentable: @post,
      user: @user,
      status: "approved",
      comment_type: "comment",
      comment_approved: "1",
      tenant: @tenant
    )
    
    sign_in @user
    
    post bulk_action_admin_comments_url, params: {
      bulk_action: "trash",
      comment_ids: [@comment.id, comment2.id]
    }
    
    assert_redirected_to admin_comments_url
    assert_equal "2 comments moved to trash.", flash[:notice]
    
    @comment.reload
    comment2.reload
    assert @comment.trashed?
    assert comment2.trashed?
  end

  test "should bulk action mark as spam" do
    sign_in @user
    
    post bulk_action_admin_comments_url, params: {
      bulk_action: "spam",
      comment_ids: [@comment.id]
    }
    
    assert_redirected_to admin_comments_url
    assert_equal "1 comment marked as spam.", flash[:notice]
    
    @comment.reload
    assert_equal "spam", @comment.status
  end

  test "should filter comments by status" do
    sign_in @user
    
    # Create comments with different statuses
    pending_comment = Comment.create!(
      content: "Pending comment",
      author_name: "Pending Author",
      author_email: "pending@example.com",
      commentable: @post,
      user: @user,
      status: "pending",
      comment_type: "comment",
      comment_approved: "0",
      tenant: @tenant
    )
    
    spam_comment = Comment.create!(
      content: "Spam comment",
      author_name: "Spam Author",
      author_email: "spam@example.com",
      commentable: @post,
      user: @user,
      status: "spam",
      comment_type: "comment",
      comment_approved: "spam",
      tenant: @tenant
    )
    
    get admin_comments_url, params: { status: "pending" }
    assert_response :success
    
    # Should only show pending comments
    assert_select ".comment-item", count: 1
  end

  test "should filter comments by type" do
    sign_in @user
    
    # Create a pingback
    pingback = Comment.create!(
      content: "Pingback content",
      author_name: "Pingback Author",
      author_email: "pingback@example.com",
      commentable: @post,
      user: @user,
      status: "approved",
      comment_type: "pingback",
      comment_approved: "1",
      tenant: @tenant
    )
    
    get admin_comments_url, params: { type: "pingback" }
    assert_response :success
    
    # Should only show pingback comments
    assert_select ".comment-item", count: 1
  end

  test "should search comments" do
    sign_in @user
    
    get admin_comments_url, params: { search: "test" }
    assert_response :success
    
    # Should show comments matching search term
    assert_select ".comment-item"
  end

  test "should require authentication" do
    get admin_comments_url
    assert_redirected_to new_user_session_url
  end

  test "should require admin role" do
    # Create a non-admin user
    subscriber = User.create!(
      name: "Subscriber",
      email: "subscriber@example.com",
      password: "password123",
      role: "subscriber",
      tenant: @tenant
    )
    
    sign_in subscriber
    get admin_comments_url
    assert_redirected_to root_url
  end

  test "should handle comment reply" do
    sign_in @user
    
    post reply_admin_comment_url(@comment), params: {
      comment: {
        content: "This is a reply",
        author_name: "Reply Author",
        author_email: "reply@example.com",
        comment_parent_id: @comment.id
      }
    }
    
    assert_redirected_to admin_comments_url
    assert_equal "Reply posted successfully.", flash[:notice]
    
    reply = Comment.last
    assert_equal @comment.id, reply.comment_parent_id
    assert_equal "This is a reply", reply.content
  end

  test "should not create reply with invalid data" do
    sign_in @user
    
    assert_no_difference("Comment.count") do
      post reply_admin_comment_url(@comment), params: {
        comment: {
          content: "",
          author_name: "Reply Author",
          author_email: "reply@example.com",
          comment_parent_id: @comment.id
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  test "should handle comment moderation actions" do
    sign_in @user
    
    # Test multiple moderation actions
    post approve_admin_comment_url(@comment)
    @comment.reload
    assert_equal "approved", @comment.status
    
    post spam_admin_comment_url(@comment)
    @comment.reload
    assert_equal "spam", @comment.status
    
    post not_spam_admin_comment_url(@comment)
    @comment.reload
    assert_equal "pending", @comment.status
  end
end

