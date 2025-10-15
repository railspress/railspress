require "test_helper"

class TenantTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.new(
      name: "Test Tenant",
      domain: "test.example.com",
      subdomain: "test",
      active: true
    )
  end

  test "should be valid with valid attributes" do
    assert @tenant.valid?
  end

  test "should require name" do
    @tenant.name = nil
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:name], "can't be blank"
  end

  test "should require domain" do
    @tenant.domain = nil
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:domain], "can't be blank"
  end

  test "should require subdomain" do
    @tenant.subdomain = nil
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:subdomain], "can't be blank"
  end

  test "should validate subdomain format" do
    @tenant.subdomain = "invalid-subdomain!"
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:subdomain], "is invalid"
  end

  test "should validate subdomain uniqueness" do
    @tenant.save!
    
    duplicate_tenant = Tenant.new(
      name: "Another Tenant",
      domain: "another.example.com",
      subdomain: @tenant.subdomain
    )
    
    assert_not duplicate_tenant.valid?
    assert_includes duplicate_tenant.errors[:subdomain], "has already been taken"
  end

  test "should validate domain format" do
    @tenant.domain = "invalid-domain"
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:domain], "is invalid"
  end

  test "should have many users" do
    assert_respond_to @tenant, :users
  end

  test "should have many posts" do
    assert_respond_to @tenant, :posts
  end

  test "should have many pages" do
    assert_respond_to @tenant, :pages
  end

  test "should have many comments" do
    assert_respond_to @tenant, :comments
  end

  test "should have many media" do
    assert_respond_to @tenant, :media
  end

  test "should have many uploads" do
    assert_respond_to @tenant, :uploads
  end

  test "should have many storage_providers" do
    assert_respond_to @tenant, :storage_providers
  end

  test "should have many upload_securities" do
    assert_respond_to @tenant, :upload_securities
  end

  test "should have many site_settings" do
    assert_respond_to @tenant, :site_settings
  end

  test "should scope active tenants" do
    @tenant.active = true
    @tenant.save!
    
    active_tenant = Tenant.active.first
    assert_equal @tenant, active_tenant
  end

  test "should find tenant by domain" do
    @tenant.domain = "example.com"
    @tenant.save!
    
    found_tenant = Tenant.find_by_domain("example.com")
    assert_equal @tenant, found_tenant
  end

  test "should find tenant by subdomain" do
    @tenant.subdomain = "mysite"
    @tenant.save!
    
    found_tenant = Tenant.find_by_subdomain("mysite")
    assert_equal @tenant, found_tenant
  end

  test "should generate slug from name" do
    @tenant.name = "My Awesome Site"
    @tenant.save!
    
    assert_equal "my-awesome-site", @tenant.slug
  end

  test "should have default settings" do
    @tenant.save!
    assert_respond_to @tenant, :settings
    assert @tenant.settings.is_a?(Hash)
  end

  test "should update settings" do
    @tenant.save!
    
    new_settings = { theme: "dark", language: "en" }
    @tenant.update!(settings: new_settings)
    
    assert_equal new_settings, @tenant.settings
  end

  test "should have plan attribute" do
    @tenant.plan = "pro"
    @tenant.save!
    
    assert_equal "pro", @tenant.plan
  end

  test "should validate plan" do
    @tenant.plan = "invalid_plan"
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:plan], "is not included in the list"
  end

  test "should have default plan" do
    @tenant.save!
    assert_equal "free", @tenant.plan
  end

  test "should check if tenant is on free plan" do
    @tenant.plan = "free"
    assert @tenant.free_plan?
    
    @tenant.plan = "pro"
    assert_not @tenant.free_plan?
  end

  test "should check if tenant is on pro plan" do
    @tenant.plan = "pro"
    assert @tenant.pro_plan?
    
    @tenant.plan = "free"
    assert_not @tenant.pro_plan?
  end

  test "should check if tenant is on enterprise plan" do
    @tenant.plan = "enterprise"
    assert @tenant.enterprise_plan?
    
    @tenant.plan = "free"
    assert_not @tenant.enterprise_plan?
  end

  test "should have storage quota based on plan" do
    @tenant.plan = "free"
    assert_equal 1.gigabyte, @tenant.storage_quota
    
    @tenant.plan = "pro"
    assert_equal 100.gigabytes, @tenant.storage_quota
    
    @tenant.plan = "enterprise"
    assert_equal 1.terabyte, @tenant.storage_quota
  end

  test "should check if tenant has exceeded storage quota" do
    @tenant.plan = "free"
    @tenant.save!
    
    # Mock storage usage
    @tenant.stubs(:storage_used).returns(500.megabytes)
    assert_not @tenant.storage_exceeded?
    
    @tenant.stubs(:storage_used).returns(2.gigabytes)
    assert @tenant.storage_exceeded?
  end

  test "should have user limit based on plan" do
    @tenant.plan = "free"
    assert_equal 1, @tenant.user_limit
    
    @tenant.plan = "pro"
    assert_equal 10, @tenant.user_limit
    
    @tenant.plan = "enterprise"
    assert_nil @tenant.user_limit # Unlimited
  end

  test "should check if tenant has reached user limit" do
    @tenant.plan = "free"
    @tenant.save!
    
    assert_not @tenant.user_limit_reached?
    
    # Create a user to reach the limit
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      tenant: @tenant
    )
    
    assert @tenant.user_limit_reached?
  end
end


