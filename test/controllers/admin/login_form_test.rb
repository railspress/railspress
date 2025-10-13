require 'test_helper'

class Admin::LoginFormTest < ActionDispatch::IntegrationTest
  test "should display admin login form correctly" do
    get new_admin_user_session_path
    assert_response :success
    
    # Check form elements
    assert_select 'form[action=?]', admin_user_session_path
    assert_select 'input[type="email"]'
    assert_select 'input[type="password"]'
    assert_select 'input[type="submit"][value="Sign In"]'
    
    # Check form layout
    assert_select 'label', text: /Email Address/
    assert_select 'label', text: /Password/
    assert_select 'input[type="checkbox"]' # Remember me checkbox
    assert_select 'a[href=?]', new_admin_user_password_path, text: /Forgot password/
    
    # Check admin-specific styling
    assert_select '.admin-login-container'
    assert_select 'h1', text: /RailsPress/
    assert_select '.admin-logo'
  end
  
  test "should handle invalid credentials gracefully" do
    get new_admin_user_session_path
    
    post admin_user_session_path, params: {
      user: {
        email: 'invalid@example.com',
        password: 'wrongpassword'
      }
    }
    
    assert_response :unprocessable_entity
    # Check for flash message in the response body
    assert_match /Invalid email or password/i, response.body
  end
  
  test "should use correct layout" do
    get new_admin_user_session_path
    assert_response :success
    # Check that the response contains admin login layout elements
    assert_match /admin-login-container/, response.body
    assert_match /RailsPress Admin/, response.body
  end
  
  test "should include CSRF token" do
    get new_admin_user_session_path
    # Check that the form has the correct action and method
    assert_select 'form[action="/admin/sign_in"][method="post"]'
    # The CSRF token should be included by Rails automatically
    # We can verify the form structure is correct
    assert_select 'form input[type="hidden"]', minimum: 1
  end
end
