require "test_helper"

# TODO: Fix Subscriber controller tests - issues with tenant setup and status enum
class SubscribersControllerTest < ActionDispatch::IntegrationTest
  # Skipping these tests for now due to tenant and status enum issues that need further investigation
  setup do
    @tenant = tenants(:default)
    @subscriber_params = {
      email: "test@example.com",
      name: "Test User"
    }
  end

  test "should create subscriber with valid params" do
    assert_difference("Subscriber.count") do
      post subscribe_path, params: { subscriber: @subscriber_params }
    end

    subscriber = Subscriber.last
    assert_equal "test@example.com", subscriber.email
    assert_equal "Test User", subscriber.name
    assert_equal "pending", subscriber.status
    assert_equal "website", subscriber.source

    assert_redirected_to root_path
    assert_equal "Successfully subscribed! Please check your email to confirm.", flash[:notice]
  end

  test "should create subscriber with custom source" do
    assert_difference("Subscriber.count") do
      post subscribe_path, params: { subscriber: @subscriber_params, source: "newsletter" }
    end

    subscriber = Subscriber.last
    assert_equal "newsletter", subscriber.source
  end

  test "should not create subscriber with invalid email" do
    invalid_params = { email: "invalid", name: "Test User" }
    
    assert_no_difference("Subscriber.count") do
      post subscribe_path, params: { subscriber: invalid_params }
    end

    assert_redirected_to root_path
    assert flash[:alert].present?
  end

  test "should not create subscriber without email" do
    invalid_params = { name: "Test User" }
    
    assert_no_difference("Subscriber.count") do
      post subscribe_path, params: { subscriber: invalid_params }
    end

    assert_redirected_to root_path
    assert flash[:alert].present?
  end

  test "should create subscriber via JSON" do
    assert_difference("Subscriber.count") do
      post subscribe_path, params: { subscriber: @subscriber_params }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal true, json_response["success"]
    assert_equal "Successfully subscribed", json_response["message"]
  end

  test "should not create subscriber with invalid params via JSON" do
    invalid_params = { email: "invalid", name: "Test User" }
    
    assert_no_difference("Subscriber.count") do
      post subscribe_path, params: { subscriber: invalid_params }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal false, json_response["success"]
    assert json_response["errors"].present?
  end

  test "should render unsubscribe page with valid token" do
    subscriber = Subscriber.create!(
      email: "unsubscribe@example.com",
      name: "Unsubscribe Test",
      status: :confirmed,
      unsubscribe_token: SecureRandom.hex(32),
      tenant: @tenant
    )

    get unsubscribe_path(subscriber.unsubscribe_token)
    
    assert_response :success
    subscriber.reload
    assert_equal "unsubscribed", subscriber.status
  end

  test "should redirect with invalid unsubscribe token" do
    get unsubscribe_path("invalid_token")
    
    assert_redirected_to root_path
    assert_equal "Invalid unsubscribe link", flash[:alert]
  end

  test "should render confirm page with valid token" do
    subscriber = Subscriber.create!(
      email: "confirm@example.com",
      name: "Confirm Test",
      status: :pending,
      unsubscribe_token: SecureRandom.hex(32),
      tenant: @tenant
    )

    get confirm_subscription_path(subscriber.unsubscribe_token)
    
    assert_response :success
    subscriber.reload
    assert_equal "confirmed", subscriber.status
  end

  test "should handle already confirmed subscriber" do
    subscriber = Subscriber.create!(
      email: "already_confirmed@example.com",
      name: "Already Confirmed Test",
      status: :confirmed,
      unsubscribe_token: SecureRandom.hex(32),
      tenant: @tenant
    )

    get confirm_subscription_path(subscriber.unsubscribe_token)
    
    assert_response :success
    assert assigns(:already_confirmed)
  end

  test "should redirect with invalid confirmation token" do
    get confirm_subscription_path("invalid_token")
    
    assert_redirected_to root_path
    assert_equal "Invalid confirmation link", flash[:alert]
  end

  test "should set ip_address and user_agent on create" do
    post subscribe_path, params: { subscriber: @subscriber_params }
    
    subscriber = Subscriber.last
    assert_not_nil subscriber.ip_address
    assert_not_nil subscriber.user_agent
  end
end
