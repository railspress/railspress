require 'test_helper'

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false
  def setup
    # Use existing admin user or create one
    @admin_user = User.find_by(email: 'admin@example.com')
    if @admin_user
      puts "Using existing admin user: #{@admin_user.email}"
    else
      @admin_user = User.create!(
        email: 'admin@example.com',
        password: 'password',
        password_confirmation: 'password',
        role: 'administrator',
        name: 'Admin User'
      )
      puts "Created new admin user: #{@admin_user.email}"
    end
    
    # Create non-admin user for testing
    @non_admin_user = User.find_by(email: 'user@example.com') || User.create!(
      email: 'user@example.com',
      password: 'password',
      password_confirmation: 'password',
      role: 'subscriber',
      name: 'Regular User'
    )
    
    # Verify users exist
    puts "Setup: Admin user exists: #{@admin_user.persisted?}"
    puts "Setup: Non-admin user exists: #{@non_admin_user.persisted?}"
  end

  test "should get new admin login page" do
    get new_admin_user_session_path
    assert_response :success
    assert_select 'form[action=?]', admin_user_session_path
    assert_select 'input[type="email"]'
    assert_select 'input[type="password"]'
    assert_select 'input[type="submit"][value="Sign In"]'
  end

  test "should successfully login with valid admin credentials" do
    # Debug: check if user exists and password is valid
    puts "User exists: #{User.exists?(@admin_user.id)}"
    puts "User email: #{@admin_user.email}"
    puts "User role: #{@admin_user.role}"
    puts "Password valid: #{@admin_user.valid_password?('password')}"
    
    # Try to find user by email directly
    found_user = User.find_by(email: @admin_user.email)
    puts "Found user: #{found_user&.email}"
    puts "Found user password valid: #{found_user&.valid_password?('password')}" if found_user
    
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    # Then post with the CSRF token
    post admin_user_session_path, params: {
      user: {
        email: @admin_user.email,
        password: 'password'
      }
    }
    
    # Debug: print response if not redirect
    unless response.redirect?
      puts "Response status: #{response.status}"
      puts "Flash messages: #{flash.inspect}"
    end
    
    assert_redirected_to admin_root_path
    assert_equal @admin_user.id, session['warden.user.user.key'][0][0]
  end

  test "should reject login with invalid password" do
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: @admin_user.email,
        password: 'wrongpassword'
      }
    }
    
    assert_response :unprocessable_entity
    assert_select '.alert', text: /Invalid email or password/
  end

  test "should reject login with non-existent email" do
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: 'nonexistent@example.com',
        password: 'password'
      }
    }
    
    assert_response :unprocessable_entity
    assert_select '.alert', text: /Invalid email or password/
  end

  test "should reject non-admin users from accessing admin login" do
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: @non_admin_user.email,
        password: 'password'
      }
    }
    
    assert_redirected_to new_admin_user_session_path
    assert_equal 'You do not have permission to access the admin area.', flash[:alert]
  end

  test "should redirect to admin dashboard after successful login" do
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: @admin_user.email,
        password: 'password'
      }
    }
    
    assert_redirected_to admin_root_path
  end

  test "should redirect to admin login after logout" do
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    # First login
    post admin_user_session_path, params: {
      user: {
        email: @admin_user.email,
        password: 'password'
      }
    }
    
    # Then logout
    delete admin_user_session_path
    assert_redirected_to new_admin_user_session_path
  end

  test "should use admin_login layout" do
    get new_admin_user_session_path
    assert_response :success
    assert_template 'admin/sessions/new'
    assert_template layout: 'admin_login'
  end

  test "should include remember me checkbox" do
    get new_admin_user_session_path
    assert_select 'input[name="user[remember_me]"]'
  end

  test "should include forgot password link" do
    get new_admin_user_session_path
    assert_select 'a[href=?]', new_admin_user_password_path, text: /Forgot password/
  end

  test "should display flash messages correctly" do
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    # Test alert message
    post admin_user_session_path, params: {
      user: {
        email: 'wrong@example.com',
        password: 'wrong'
      }
    }
    
    assert_response :unprocessable_entity
    assert_select '.alert', text: /Invalid email or password/
  end

  test "should handle empty credentials" do
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: '',
        password: ''
      }
    }
    
    assert_response :unprocessable_entity
    assert_select '.alert', text: /Invalid email or password/
  end

  test "should allow author role to access admin" do
    author_user = User.create!(
      email: 'author@example.com',
      password: 'password',
      password_confirmation: 'password',
      role: 'author',
      name: 'Author User'
    )
    
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: author_user.email,
        password: 'password'
      }
    }
    
    assert_redirected_to admin_root_path
  end

  test "should allow editor role to access admin" do
    editor_user = User.create!(
      email: 'editor@example.com',
      password: 'password',
      password_confirmation: 'password',
      role: 'editor',
      name: 'Editor User'
    )
    
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: editor_user.email,
        password: 'password'
      }
    }
    
    assert_redirected_to admin_root_path
  end

  test "should reject subscriber role from accessing admin" do
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: @non_admin_user.email,
        password: 'password'
      }
    }
    
    assert_redirected_to new_admin_user_session_path
    assert_equal 'You do not have permission to access the admin area.', flash[:alert]
  end

  test "should reject contributor role from accessing admin" do
    contributor_user = User.create!(
      email: 'contributor@example.com',
      password: 'password',
      password_confirmation: 'password',
      role: 'contributor',
      name: 'Contributor User'
    )
    
    # First get the login page to get the CSRF token
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: contributor_user.email,
        password: 'password'
      }
    }
    
    assert_redirected_to new_admin_user_session_path
    assert_equal 'You do not have permission to access the admin area.', flash[:alert]
  end
end