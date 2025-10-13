require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "John",
      last_name: "Doe"
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    @user.save!
    duplicate_user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should require valid email format" do
    @user.email = "invalid_email"
    assert_not @user.valid?
    assert_includes @user.errors[:email], "is invalid"
  end

  test "should require password" do
    @user.password = nil
    @user.password_confirmation = nil
    assert_not @user.valid?
    assert_includes @user.errors[:password], "can't be blank"
  end

  test "should require password confirmation to match" do
    @user.password_confirmation = "different_password"
    assert_not @user.valid?
    assert_includes @user.errors[:password_confirmation], "doesn't match Password"
  end

  test "should require minimum password length" do
    @user.password = "123"
    @user.password_confirmation = "123"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "should have default role" do
    assert_equal "user", @user.role
  end

  test "should be able to set administrator role" do
    @user.role = "administrator"
    assert @user.valid?
    assert @user.administrator?
  end

  test "should have full name method" do
    assert_equal "John Doe", @user.full_name
  end

  test "should handle missing first or last name" do
    @user.first_name = nil
    assert_equal "Doe", @user.full_name
    
    @user.last_name = nil
    @user.first_name = "John"
    assert_equal "John", @user.full_name
  end

  test "should have posts association" do
    @user.save!
    post = @user.posts.create!(title: "Test Post", content: "Test content", status: "published")
    assert_includes @user.posts, post
  end

  test "should have pages association" do
    @user.save!
    page = @user.pages.create!(title: "Test Page", content: "Test content", status: "published")
    assert_includes @user.pages, page
  end

  test "should have comments association" do
    @user.save!
    comment = @user.comments.create!(content: "Test comment", status: "approved")
    assert_includes @user.comments, comment
  end

  test "should scope administrators" do
    admin = User.create!(email: "admin@example.com", password: "password123", password_confirmation: "password123", role: "administrator")
    user = User.create!(email: "user@example.com", password: "password123", password_confirmation: "password123", role: "user")
    
    administrators = User.administrators
    assert_includes administrators, admin
    assert_not_includes administrators, user
  end

  test "should scope active users" do
    active_user = User.create!(email: "active@example.com", password: "password123", password_confirmation: "password123")
    inactive_user = User.create!(email: "inactive@example.com", password: "password123", password_confirmation: "password123", active: false)
    
    active_users = User.active
    assert_includes active_users, active_user
    assert_not_includes active_users, inactive_user
  end

  test "should authenticate with correct password" do
    @user.save!
    assert @user.authenticate("password123")
  end

  test "should not authenticate with incorrect password" do
    @user.save!
    assert_not @user.authenticate("wrong_password")
  end

  test "should have avatar attachment" do
    assert_respond_to @user, :avatar
  end

  test "should handle avatar upload" do
    @user.save!
    # This would require file upload testing in a real scenario
    assert_respond_to @user, :avatar_attached?
  end
end




