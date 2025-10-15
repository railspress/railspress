require "test_helper"

class StorageProviderTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.first
    @storage_provider = StorageProvider.new(
      name: "Local Storage",
      provider_type: "local",
      config: {
        root_path: "/tmp/uploads"
      },
      active: true,
      tenant: @tenant
    )
  end

  test "should be valid with valid attributes" do
    assert @storage_provider.valid?
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

  test "should require tenant" do
    @storage_provider.tenant = nil
    assert_not @storage_provider.valid?
    assert_includes @storage_provider.errors[:tenant], "must exist"
  end

  test "should validate provider_type" do
    @storage_provider.provider_type = "invalid_type"
    assert_not @storage_provider.valid?
    assert_includes @storage_provider.errors[:provider_type], "is not included in the list"
  end

  test "should belong to tenant" do
    assert_respond_to @storage_provider, :tenant
  end

  test "should have many uploads" do
    assert_respond_to @storage_provider, :uploads
  end

  test "should scope active providers" do
    @storage_provider.active = true
    @storage_provider.save!
    
    active_provider = StorageProvider.active.first
    assert_equal @storage_provider, active_provider
  end

  test "should scope by provider type" do
    @storage_provider.provider_type = "local"
    @storage_provider.save!
    
    local_providers = StorageProvider.by_type("local")
    assert_includes local_providers, @storage_provider
  end

  test "should have default config" do
    @storage_provider.save!
    assert_not_nil @storage_provider.config
    assert @storage_provider.config.is_a?(Hash)
  end

  test "should configure ActiveStorage for local provider" do
    @storage_provider.provider_type = "local"
    @storage_provider.config = { root_path: "/tmp/uploads" }
    @storage_provider.save!
    
    # This would typically be called in the model
    assert_respond_to @storage_provider, :configure_active_storage
  end

  test "should configure ActiveStorage for S3 provider" do
    @storage_provider.provider_type = "s3"
    @storage_provider.config = {
      bucket: "my-bucket",
      region: "us-east-1",
      access_key_id: "access_key",
      secret_access_key: "secret_key"
    }
    @storage_provider.save!
    
    assert_respond_to @storage_provider, :configure_active_storage
  end

  test "should validate S3 configuration" do
    @storage_provider.provider_type = "s3"
    @storage_provider.config = { bucket: "my-bucket" }
    
    # Should fail without required S3 config
    assert_not @storage_provider.valid?
  end

  test "should validate GCS configuration" do
    @storage_provider.provider_type = "gcs"
    @storage_provider.config = { bucket: "my-bucket" }
    
    # Should fail without required GCS config
    assert_not @storage_provider.valid?
  end

  test "should validate Azure configuration" do
    @storage_provider.provider_type = "azure"
    @storage_provider.config = { container: "my-container" }
    
    # Should fail without required Azure config
    assert_not @storage_provider.valid?
  end

  test "should return display name" do
    @storage_provider.name = "My Local Storage"
    @storage_provider.save!
    
    assert_equal "My Local Storage", @storage_provider.display_name
  end

  test "should return provider type display name" do
    @storage_provider.provider_type = "s3"
    assert_equal "Amazon S3", @storage_provider.provider_type_display
    
    @storage_provider.provider_type = "local"
    assert_equal "Local Filesystem", @storage_provider.provider_type_display
  end

  test "should check if provider is local" do
    @storage_provider.provider_type = "local"
    assert @storage_provider.local?
    
    @storage_provider.provider_type = "s3"
    assert_not @storage_provider.local?
  end

  test "should check if provider is cloud" do
    @storage_provider.provider_type = "s3"
    assert @storage_provider.cloud?
    
    @storage_provider.provider_type = "local"
    assert_not @storage_provider.cloud?
  end

  test "should serialize configuration as JSON" do
    config = { root_path: "/tmp/uploads", max_size: "100MB" }
    @storage_provider.config = config
    @storage_provider.save!
    
    @storage_provider.reload
    assert_equal config, @storage_provider.config
  end

  test "should handle configuration updates" do
    @storage_provider.save!
    
    new_config = { root_path: "/new/path" }
    @storage_provider.update!(config: new_config)
    
    assert_equal new_config, @storage_provider.config
  end
end
