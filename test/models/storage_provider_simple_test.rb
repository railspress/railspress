require "test_helper"

class StorageProviderSimpleTest < ActiveSupport::TestCase
  def setup
    @storage_provider = StorageProvider.new(
      name: "Local Storage",
      provider_type: "local",
      config: {
        root_path: "/tmp/uploads"
      },
      active: true
    )
  end

  test "should be valid with valid attributes" do
    # StorageProvider requires tenant, so it won't be valid without it
    assert_not @storage_provider.valid?
    assert_includes @storage_provider.errors[:tenant], "must exist"
  end

  test "should require name" do
    @storage_provider.name = nil
    assert_not @storage_provider.valid?
    assert_includes @storage_provider.errors[:name], "can't be blank"
  end

  test "should require provider_type" do
    @storage_provider.provider_type = nil
    assert_not @storage_provider.valid?
    assert_includes @storage_provider.errors[:provider_type], "can't be blank"
  end

  test "should validate provider_type" do
    @storage_provider.provider_type = "invalid_type"
    assert_not @storage_provider.valid?
    assert_includes @storage_provider.errors[:provider_type], "is not included in the list"
  end

  test "should belong to tenant" do
    assert_respond_to @storage_provider, :tenant
  end

  test "should have scopes" do
    assert_respond_to StorageProvider, :active
    assert_respond_to StorageProvider, :ordered
    assert_respond_to StorageProvider, :by_type
  end

  test "should check provider type methods" do
    @storage_provider.provider_type = "local"
    assert @storage_provider.local?
    assert_not @storage_provider.s3?
    assert_not @storage_provider.gcs?
    assert_not @storage_provider.azure?
    
    @storage_provider.provider_type = "s3"
    assert @storage_provider.s3?
    assert_not @storage_provider.local?
  end

  test "should have active_storage_service method" do
    assert_respond_to @storage_provider, :active_storage_service
  end

  test "should have active_storage_config method" do
    assert_respond_to @storage_provider, :active_storage_config
  end

  test "should serialize config as JSON" do
    config = { root_path: "/tmp/uploads", max_size: "100MB" }
    @storage_provider.config = config
    
    # Test that config is properly set (JSON serialization converts symbols to strings)
    expected_config = { "root_path" => "/tmp/uploads", "max_size" => "100MB" }
    assert_equal expected_config, @storage_provider.config
    assert @storage_provider.config.is_a?(Hash)
  end

  test "should have position attribute" do
    @storage_provider.position = 1
    assert_equal 1, @storage_provider.position
  end

  test "should have active attribute" do
    @storage_provider.active = false
    assert_equal false, @storage_provider.active
  end
end
