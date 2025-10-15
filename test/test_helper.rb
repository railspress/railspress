ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  def sign_in(user)
    if defined?(Devise)
      # For Devise authentication
      post user_session_path, params: {
        user: {
          email: user.email,
          password: user.password || 'password'
        }
      }
    else
      # For custom authentication or session-based auth
      session[:user_id] = user.id
    end
  end
  
  def sign_out(user)
    if defined?(Devise)
      delete destroy_user_session_path
    else
      session[:user_id] = nil
    end
  end
  
  def setup_tenant
    @tenant = Tenant.first || Tenant.create!(
      name: 'Test Tenant',
      subdomain: 'test'
    )
  end
  
  def setup_user(role: 'admin')
    @user = User.first || User.create!(
      email: 'test@example.com',
      password: 'password',
      role: role
    )
  end
end