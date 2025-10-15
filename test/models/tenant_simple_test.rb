require "test_helper"

class TenantSimpleTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.new(
      name: "Test Tenant",
      domain: "test.example.com",
      subdomain: "test"
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

  test "should require theme" do
    @tenant.theme = nil
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:theme], "can't be blank"
  end

  test "should validate storage_type" do
    @tenant.storage_type = "invalid_type"
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:storage_type], "invalid_type is not a valid storage type"
  end

  test "should require domain or subdomain" do
    @tenant.domain = nil
    @tenant.subdomain = nil
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:base], "Must have either a domain or subdomain"
  end

  test "should have many associations" do
    assert_respond_to @tenant, :posts
    assert_respond_to @tenant, :pages
    assert_respond_to @tenant, :media
    assert_respond_to @tenant, :comments
    assert_respond_to @tenant, :taxonomies
    assert_respond_to @tenant, :terms
    assert_respond_to @tenant, :menus
    assert_respond_to @tenant, :widgets
    assert_respond_to @tenant, :themes
    assert_respond_to @tenant, :site_settings
    assert_respond_to @tenant, :users
    assert_respond_to @tenant, :email_logs
  end

  test "should have scopes" do
    assert_respond_to Tenant, :active
    assert_respond_to Tenant, :by_domain
    assert_respond_to Tenant, :by_subdomain
  end

  test "should have class methods" do
    assert_respond_to Tenant, :current
    assert_respond_to Tenant, :find_by_request
  end

  test "should have instance methods" do
    assert_respond_to @tenant, :activate!
    assert_respond_to @tenant, :deactivate!
    assert_respond_to @tenant, :full_url
    assert_respond_to @tenant, :locale_list
    assert_respond_to @tenant, :using_s3?
    assert_respond_to @tenant, :using_local_storage?
    assert_respond_to @tenant, :storage_configured?
    assert_respond_to @tenant, :storage_service
    assert_respond_to @tenant, :get_setting
    assert_respond_to @tenant, :set_setting
  end

  test "should have default theme" do
    @tenant.save!
    assert_equal "default", @tenant.theme
  end

  test "should have default locales" do
    @tenant.save!
    assert_equal "en", @tenant.locales
  end

  test "should have default storage_type" do
    @tenant.save!
    assert_equal "local", @tenant.storage_type
  end

  test "should have default active status" do
    @tenant.save!
    assert_equal true, @tenant.active
  end

  test "should have default settings" do
    @tenant.save!
    assert @tenant.settings.is_a?(Hash)
  end

  test "should generate full_url with domain" do
    @tenant.domain = "example.com"
    @tenant.subdomain = nil
    assert_equal "https://example.com", @tenant.full_url
  end

  test "should generate full_url with subdomain" do
    @tenant.domain = nil
    @tenant.subdomain = "mysite"
    # This will depend on ENV['APP_DOMAIN'] or default to 'railspress.app'
    assert @tenant.full_url.include?("mysite")
  end

  test "should handle locale_list" do
    @tenant.locales = "en,es,fr"
    assert_equal ["en", "es", "fr"], @tenant.locale_list
    
    @tenant.locale_list = ["de", "it"]
    assert_equal "de,it", @tenant.locales
  end

  test "should check storage type methods" do
    @tenant.storage_type = "local"
    assert @tenant.using_local_storage?
    assert_not @tenant.using_s3?
    
    @tenant.storage_type = "s3"
    assert @tenant.using_s3?
    assert_not @tenant.using_local_storage?
  end

  test "should check storage configuration" do
    @tenant.storage_type = "local"
    assert @tenant.storage_configured?
    
    @tenant.storage_type = "s3"
    @tenant.storage_bucket = "my-bucket"
    @tenant.storage_region = "us-east-1"
    @tenant.storage_access_key = "access_key"
    @tenant.storage_secret_key = "secret_key"
    assert @tenant.storage_configured?
  end

  test "should return storage service" do
    @tenant.storage_type = "local"
    assert_equal :local, @tenant.storage_service
    
    @tenant.storage_type = "s3"
    assert_equal :amazon, @tenant.storage_service
  end

  test "should handle settings" do
    @tenant.save!
    
    # Test setting a value
    @tenant.set_setting("custom_key", "custom_value")
    assert_equal "custom_value", @tenant.get_setting("custom_key")
    
    # Test default value
    assert_equal "default_value", @tenant.get_setting("nonexistent_key", "default_value")
  end

  test "should handle active status" do
    @tenant.save!
    assert @tenant.active?
    
    @tenant.deactivate!
    assert_not @tenant.active?
    
    @tenant.activate!
    assert @tenant.active?
  end
end
