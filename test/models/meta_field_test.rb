require "test_helper"

class MetaFieldTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:default)
    @post = posts(:one)
    @page = pages(:one)
    @user = users(:user)
    @ai_agent = ai_agents(:content_summarizer)
  end

  test "should create meta field with valid attributes" do
    meta_field = MetaField.new(
      metable: @post,
      key: "test_key",
      value: "test_value",
      immutable: false
    )
    
    assert meta_field.valid?
    assert meta_field.save
  end

  test "should require key" do
    meta_field = MetaField.new(metable: @post, value: "test_value")
    assert_not meta_field.valid?
    assert_includes meta_field.errors[:key], "can't be blank"
  end

  test "should require metable" do
    meta_field = MetaField.new(key: "test_key", value: "test_value")
    assert_not meta_field.valid?
    assert_includes meta_field.errors[:metable], "must exist"
  end

  test "should validate key uniqueness per metable" do
    MetaField.create!(metable: @post, key: "unique_key", value: "value1")
    
    duplicate = MetaField.new(metable: @post, key: "unique_key", value: "value2")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "must be unique per metable"
  end

  test "should allow same key for different metables" do
    MetaField.create!(metable: @post, key: "shared_key", value: "post_value")
    
    page_meta = MetaField.new(metable: @page, key: "shared_key", value: "page_value")
    assert page_meta.valid?
    assert page_meta.save
  end

  test "should validate immutable inclusion" do
    meta_field = MetaField.new(
      metable: @post,
      key: "test_key",
      value: "test_value",
      immutable: nil
    )
    
    assert_not meta_field.valid?
    assert_includes meta_field.errors[:immutable], "is not included in the list"
  end

  test "should default immutable to false" do
    meta_field = MetaField.create!(
      metable: @post,
      key: "test_key",
      value: "test_value"
    )
    
    assert_equal false, meta_field.immutable
  end

  test "should limit key length" do
    long_key = "a" * 256
    meta_field = MetaField.new(
      metable: @post,
      key: long_key,
      value: "test_value"
    )
    
    assert_not meta_field.valid?
    assert_includes meta_field.errors[:key], "is too long (maximum is 255 characters)"
  end

  test "should scope immutable fields" do
    MetaField.create!(metable: @post, key: "immutable_key", value: "value", immutable: true)
    MetaField.create!(metable: @post, key: "mutable_key", value: "value", immutable: false)
    
    immutable_fields = MetaField.immutable
    mutable_fields = MetaField.mutable
    
    assert_equal 1, immutable_fields.count
    assert_equal 1, mutable_fields.count
    assert_equal "immutable_key", immutable_fields.first.key
    assert_equal "mutable_key", mutable_fields.first.key
  end

  test "should scope by key" do
    MetaField.create!(metable: @post, key: "test_key", value: "value")
    MetaField.create!(metable: @page, key: "other_key", value: "value")
    
    test_fields = MetaField.by_key("test_key")
    assert_equal 1, test_fields.count
    assert_equal "test_key", test_fields.first.key
  end

  test "should get meta field value" do
    MetaField.create!(metable: @post, key: "test_key", value: "test_value")
    
    value = MetaField.get(@post, "test_key")
    assert_equal "test_value", value
  end

  test "should return nil for non-existent key" do
    value = MetaField.get(@post, "non_existent")
    assert_nil value
  end

  test "should set meta field value" do
    meta_field = MetaField.set(@post, "new_key", "new_value")
    
    assert meta_field.persisted?
    assert_equal "new_key", meta_field.key
    assert_equal "new_value", meta_field.value
    assert_equal false, meta_field.immutable
    
    # Verify it's retrievable
    value = MetaField.get(@post, "new_key")
    assert_equal "new_value", value
  end

  test "should set immutable meta field" do
    meta_field = MetaField.set(@post, "immutable_key", "value", immutable: true)
    
    assert meta_field.immutable?
    assert_equal "immutable_key", meta_field.key
    assert_equal "value", meta_field.value
  end

  test "should update existing meta field" do
    MetaField.set(@post, "update_key", "original_value")
    
    meta_field = MetaField.set(@post, "update_key", "updated_value")
    
    assert_equal "updated_value", meta_field.value
    value = MetaField.get(@post, "update_key")
    assert_equal "updated_value", value
  end

  test "should not update immutable field" do
    MetaField.set(@post, "immutable_key", "original_value", immutable: true)
    
    assert_raises(ArgumentError, "Cannot modify immutable meta field: immutable_key") do
      MetaField.set(@post, "immutable_key", "new_value")
    end
  end

  test "should delete meta field" do
    MetaField.set(@post, "delete_key", "value")
    
    meta_field = MetaField.delete(@post, "delete_key")
    
    assert_not_nil meta_field
    assert meta_field.destroyed?
    
    # Verify it's no longer retrievable
    value = MetaField.get(@post, "delete_key")
    assert_nil value
  end

  test "should not delete immutable field" do
    MetaField.set(@post, "immutable_key", "value", immutable: true)
    
    assert_raises(ArgumentError, "Cannot delete immutable meta field: immutable_key") do
      MetaField.delete(@post, "immutable_key")
    end
  end

  test "should bulk get meta fields" do
    MetaField.set(@post, "key1", "value1")
    MetaField.set(@post, "key2", "value2")
    
    values = MetaField.bulk_get(@post, ["key1", "key2", "key3"])
    
    assert_equal ["value1", "value2", nil], values
  end

  test "should bulk set meta fields" do
    MetaField.bulk_set(@post, {
      "bulk_key1" => "bulk_value1",
      "bulk_key2" => "bulk_value2"
    })
    
    value1 = MetaField.get(@post, "bulk_key1")
    value2 = MetaField.get(@post, "bulk_key2")
    
    assert_equal "bulk_value1", value1
    assert_equal "bulk_value2", value2
  end

  test "should get all meta fields for metable" do
    MetaField.set(@post, "key1", "value1", immutable: true)
    MetaField.set(@post, "key2", "value2", immutable: false)
    
    all_meta = MetaField.all_for(@post)
    
    assert_equal 2, all_meta.size
    assert_equal({ value: "value1", immutable: true }, all_meta["key1"])
    assert_equal({ value: "value2", immutable: false }, all_meta["key2"])
  end

  test "should convert to string" do
    meta_field = MetaField.new(value: "test_value")
    assert_equal "test_value", meta_field.to_s
  end

  test "should convert to integer" do
    meta_field = MetaField.new(value: "123")
    assert_equal 123, meta_field.to_i
  end

  test "should convert to float" do
    meta_field = MetaField.new(value: "123.45")
    assert_equal 123.45, meta_field.to_f
  end

  test "should convert to boolean" do
    true_field = MetaField.new(value: "true")
    false_field = MetaField.new(value: "false")
    
    assert_equal true, true_field.to_bool
    assert_equal false, false_field.to_bool
  end

  test "should parse JSON value" do
    meta_field = MetaField.new(value: '{"key": "value"}')
    json_data = meta_field.json_value
    
    assert_equal({ "key" => "value" }, json_data)
  end

  test "should return nil for invalid JSON" do
    meta_field = MetaField.new(value: "invalid json")
    json_data = meta_field.json_value
    
    assert_nil json_data
  end

  test "should invalidate cache on save" do
    meta_field = MetaField.set(@post, "cache_key", "original_value")
    
    # Verify cache is populated (may be nil if cache is not enabled)
    cached_value = Rails.cache.read("meta_field:Post:#{@post.id}:cache_key")
    if cached_value
      assert_equal "original_value", cached_value
    end
    
    # Update the field
    meta_field.update!(value: "updated_value")
    
    # Verify cache is cleared (if it was populated)
    cached_value = Rails.cache.read("meta_field:Post:#{@post.id}:cache_key")
    if Rails.cache.exist?("meta_field:Post:#{@post.id}:cache_key")
      assert_nil cached_value
    end
  end

  test "should invalidate cache on destroy" do
    meta_field = MetaField.set(@post, "cache_key", "value")
    
    # Verify cache is populated (may be nil if cache is not enabled)
    cached_value = Rails.cache.read("meta_field:Post:#{@post.id}:cache_key")
    if cached_value
      assert_equal "value", cached_value
    end
    
    # Destroy the field
    meta_field.destroy
    
    # Verify cache is cleared (if it was populated)
    cached_value = Rails.cache.read("meta_field:Post:#{@post.id}:cache_key")
    if Rails.cache.exist?("meta_field:Post:#{@post.id}:cache_key")
      assert_nil cached_value
    end
  end

  test "should work with all metable types" do
    # Test with Post
    post_meta = MetaField.set(@post, "post_key", "post_value")
    assert_equal "post_value", MetaField.get(@post, "post_key")
    
    # Test with Page
    page_meta = MetaField.set(@page, "page_key", "page_value")
    assert_equal "page_value", MetaField.get(@page, "page_key")
    
    # Test with User
    user_meta = MetaField.set(@user, "user_key", "user_value")
    assert_equal "user_value", MetaField.get(@user, "user_key")
    
    # Test with AiAgent
    agent_meta = MetaField.set(@ai_agent, "agent_key", "agent_value")
    assert_equal "agent_value", MetaField.get(@ai_agent, "agent_key")
  end
end
