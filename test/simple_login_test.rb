#!/usr/bin/env ruby

require_relative 'test_helper'

# Simple test to debug login issue
class SimpleLoginTest < ActionDispatch::IntegrationTest
  def test_login_with_existing_user
    # Use the existing admin user from the database
    admin_user = User.find_by(email: 'admin@example.com')
    
    if admin_user
      puts "Found admin user: #{admin_user.email}"
      puts "Password valid: #{admin_user.valid_password?('password')}"
      
      # Try to login
      get new_admin_user_session_path
      assert_response :success
      
      post admin_user_session_path, params: {
        user: {
          email: admin_user.email,
          password: 'password'
        }
      }
      
      if response.redirect?
        puts "Login successful! Redirected to: #{response.redirect_url}"
      else
        puts "Login failed. Status: #{response.status}"
        puts "Flash: #{flash.inspect}"
      end
    else
      puts "No admin user found"
    end
  end
end


