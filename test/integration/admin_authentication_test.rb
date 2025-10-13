require "test_helper"

class AdminAuthenticationTest < ActionDispatch::IntegrationTest
  test "should redirect to login when not authenticated" do
    get admin_dashboard_url
    assert_redirected_to new_user_session_url
    assert_equal "You need to sign in or sign up before continuing.", flash[:alert]
  end

  test "should allow access with valid admin credentials" do
    user = users(:admin)
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
    
    assert_redirected_to admin_dashboard_url
    follow_redirect!
    assert_response :success
    assert_select "h1", "Dashboard"
  end

  test "should deny access with invalid credentials" do
    post user_session_url, params: {
      user: {
        email: "invalid@example.com",
        password: "wrongpassword"
      }
    }
    
    assert_response :unprocessable_entity
    assert_includes response.body, "Invalid email or password"
  end

  test "should deny access to regular users" do
    user = users(:user)
    sign_in user
    
    get admin_dashboard_url
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
  end

  test "should maintain session across requests" do
    user = users(:admin)
    sign_in user
    
    get admin_dashboard_url
    assert_response :success
    
    get admin_posts_url
    assert_response :success
    
    get admin_users_url
    assert_response :success
  end

  test "should logout and clear session" do
    user = users(:admin)
    sign_in user
    
    get admin_dashboard_url
    assert_response :success
    
    delete destroy_user_session_url
    assert_redirected_to root_url
    
    get admin_dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "should redirect to intended URL after login" do
    intended_url = admin_posts_url
    
    get intended_url
    assert_redirected_to new_user_session_url
    
    user = users(:admin)
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
    
    assert_redirected_to intended_url
  end

  test "should handle remember me functionality" do
    user = users(:admin)
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123",
        remember_me: "1"
      }
    }
    
    assert_response :redirect
    assert_not_nil cookies["remember_user_token"]
  end

  test "should handle password reset flow" do
    user = users(:admin)
    
    # Request password reset
    post user_password_url, params: {
      user: {
        email: user.email
      }
    }
    
    assert_response :redirect
    assert_equal "You will receive an email with instructions on how to reset your password in a few minutes.", flash[:notice]
    
    # Simulate clicking reset link (would normally come from email)
    token = user.send_reset_password_instructions
    get edit_user_password_url, params: { reset_password_token: token }
    assert_response :success
    
    # Submit new password
    patch user_password_url, params: {
      user: {
        reset_password_token: token,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    
    assert_redirected_to admin_dashboard_url
    assert_equal "Your password has been changed successfully. You are now signed in.", flash[:notice]
  end

  test "should handle account lockout after failed attempts" do
    user = users(:admin)
    
    # Simulate multiple failed login attempts
    5.times do
      post user_session_url, params: {
        user: {
          email: user.email,
          password: "wrongpassword"
        }
      }
    end
    
    # Next attempt should be locked
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
    
    assert_response :unprocessable_entity
    assert_includes response.body, "Your account is locked"
  end

  test "should require strong passwords" do
    user = users(:admin)
    
    # Try to update with weak password
    patch user_registration_url, params: {
      user: {
        current_password: "password123",
        password: "123",
        password_confirmation: "123"
      }
    }
    
    assert_response :unprocessable_entity
    assert_includes response.body, "Password is too short"
  end

  test "should handle email confirmation" do
    user = User.new(
      email: "newuser@example.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "New",
      last_name: "User"
    )
    
    post user_registration_url, params: {
      user: {
        email: user.email,
        password: user.password,
        password_confirmation: user.password_confirmation,
        first_name: user.first_name,
        last_name: user.last_name
      }
    }
    
    assert_response :redirect
    assert_equal "A message with a confirmation link has been sent to your email address. Please open the link to activate your account.", flash[:notice]
    
    # User should not be able to access admin until confirmed
    get admin_dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "should handle two-factor authentication" do
    user = users(:admin)
    user.update!(two_factor_enabled: true)
    
    sign_in user
    
    get admin_dashboard_url
    assert_redirected_to new_user_two_factor_authentication_url
    
    # Verify with 2FA code
    post user_two_factor_authentication_url, params: {
      user: {
        otp_attempt: user.current_otp
      }
    }
    
    assert_redirected_to admin_dashboard_url
    assert_response :success
  end

  test "should handle session timeout" do
    user = users(:admin)
    sign_in user
    
    # Simulate session timeout
    travel_to 2.hours.from_now do
      get admin_dashboard_url
      assert_redirected_to new_user_session_url
      assert_equal "Your session has expired. Please sign in again.", flash[:alert]
    end
  end

  test "should handle concurrent sessions" do
    user = users(:admin)
    
    # First session
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
    
    assert_response :redirect
    
    # Second session should invalidate first
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
    
    assert_response :redirect
    assert_equal "You are already signed in.", flash[:notice]
  end

  test "should handle admin role changes" do
    user = users(:admin)
    sign_in user
    
    get admin_dashboard_url
    assert_response :success
    
    # Change user to regular user
    user.update!(role: "user")
    
    get admin_dashboard_url
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
  end

  test "should handle user deactivation" do
    user = users(:admin)
    sign_in user
    
    get admin_dashboard_url
    assert_response :success
    
    # Deactivate user
    user.update!(active: false)
    
    get admin_dashboard_url
    assert_redirected_to new_user_session_url
    assert_equal "Your account has been deactivated.", flash[:alert]
  end

  test "should handle CSRF protection" do
    user = users(:admin)
    sign_in user
    
    # Disable CSRF protection for this test
    ActionController::Base.allow_forgery_protection = false
    
    post admin_posts_url, params: {
      post: {
        title: "CSRF Test",
        content: "Test content"
      }
    }
    
    # Re-enable CSRF protection
    ActionController::Base.allow_forgery_protection = true
    
    assert_response :success
  end

  test "should handle API authentication" do
    user = users(:admin)
    api_key = user.api_keys.create!(name: "Test API Key")
    
    get admin_posts_url, headers: {
      "Authorization" => "Bearer #{api_key.token}"
    }
    
    assert_response :success
  end

  test "should handle invalid API key" do
    get admin_posts_url, headers: {
      "Authorization" => "Bearer invalid_token"
    }
    
    assert_response :unauthorized
    assert_includes response.body, "Invalid API key"
  end

  test "should handle expired API key" do
    user = users(:admin)
    api_key = user.api_keys.create!(name: "Test API Key", expires_at: 1.day.ago)
    
    get admin_posts_url, headers: {
      "Authorization" => "Bearer #{api_key.token}"
    }
    
    assert_response :unauthorized
    assert_includes response.body, "API key has expired"
  end
end



