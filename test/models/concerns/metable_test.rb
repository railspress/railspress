require "test_helper"

class MetableTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:default)
    @post = posts(:one)
  end

  test "should get meta field" do
    MetaField.set(@post, "test_key", "test_value")
    
    value = @post.get_meta("test_key")
    assert_equal "test_value", value
  end

  test "should set meta field" do
    meta_field = @post.set_meta("new_key", "new_value")
    
    assert meta_field.persisted?
    assert_equal "new_key", meta_field.key
    assert_equal "new_value", meta_field.value
  end

  test "should delete meta field" do
    MetaField.set(@post, "delete_key", "value")
    
    meta_field = @post.delete_meta("delete_key")
    assert meta_field.destroyed?
    
    assert_nil @post.get_meta("delete_key")
  end

  test "should bulk get meta fields" do
    MetaField.set(@post, "key1", "value1")
    MetaField.set(@post, "key2", "value2")
    
    values = @post.bulk_get_meta(["key1", "key2", "key3"])
    assert_equal ["value1", "value2", nil], values
  end

  test "should bulk set meta fields" do
    @post.bulk_set_meta({
      "bulk_key1" => "bulk_value1",
      "bulk_key2" => "bulk_value2"
    })
    
    assert_equal "bulk_value1", @post.get_meta("bulk_key1")
    assert_equal "bulk_value2", @post.get_meta("bulk_key2")
  end

  test "should get all meta fields" do
    MetaField.set(@post, "key1", "value1", immutable: true)
    MetaField.set(@post, "key2", "value2", immutable: false)
    
    all_meta = @post.all_meta
    
    assert_equal 2, all_meta.size
    assert_equal({ value: "value1", immutable: true }, all_meta["key1"])
    assert_equal({ value: "value2", immutable: false }, all_meta["key2"])
  end

  test "should check if meta field exists" do
    assert_not @post.has_meta?("non_existent")
    
    MetaField.set(@post, "existing_key", "value")
    assert @post.has_meta?("existing_key")
  end

  test "should get meta keys" do
    MetaField.set(@post, "key1", "value1")
    MetaField.set(@post, "key2", "value2", immutable: true)
    
    keys = @post.meta_keys
    assert_includes keys, "key1"
    assert_includes keys, "key2"
  end

  test "should get immutable meta keys" do
    MetaField.set(@post, "mutable_key", "value", immutable: false)
    MetaField.set(@post, "immutable_key", "value", immutable: true)
    
    immutable_keys = @post.immutable_meta_keys
    mutable_keys = @post.mutable_meta_keys
    
    assert_equal ["immutable_key"], immutable_keys
    assert_equal ["mutable_key"], mutable_keys
  end

  test "should get meta as string with default" do
    # Test with existing value
    MetaField.set(@post, "string_key", "actual_value")
    assert_equal "actual_value", @post.get_meta_as_string("string_key", "default")
    
    # Test with non-existent key
    assert_equal "default", @post.get_meta_as_string("non_existent", "default")
    
    # Test with blank value
    MetaField.set(@post, "blank_key", "")
    assert_equal "default", @post.get_meta_as_string("blank_key", "default")
  end

  test "should get meta as integer with default" do
    # Test with valid integer
    MetaField.set(@post, "int_key", "123")
    assert_equal 123, @post.get_meta_as_integer("int_key", 0)
    
    # Test with non-existent key
    assert_equal 0, @post.get_meta_as_integer("non_existent", 0)
    
    # Test with invalid integer
    MetaField.set(@post, "invalid_int", "abc")
    assert_equal 0, @post.get_meta_as_integer("invalid_int", 0)
  end

  test "should get meta as float with default" do
    # Test with valid float
    MetaField.set(@post, "float_key", "123.45")
    assert_equal 123.45, @post.get_meta_as_float("float_key", 0.0)
    
    # Test with non-existent key
    assert_equal 0.0, @post.get_meta_as_float("non_existent", 0.0)
    
    # Test with invalid float
    MetaField.set(@post, "invalid_float", "abc")
    assert_equal 0.0, @post.get_meta_as_float("invalid_float", 0.0)
  end

  test "should get meta as boolean with default" do
    # Test with true values
    MetaField.set(@post, "true_key", "true")
    assert_equal true, @post.get_meta_as_boolean("true_key", false)
    
    MetaField.set(@post, "one_key", "1")
    assert_equal true, @post.get_meta_as_boolean("one_key", false)
    
    MetaField.set(@post, "yes_key", "yes")
    assert_equal true, @post.get_meta_as_boolean("yes_key", false)
    
    MetaField.set(@post, "on_key", "on")
    assert_equal true, @post.get_meta_as_boolean("on_key", false)
    
    # Test with false values
    MetaField.set(@post, "false_key", "false")
    assert_equal false, @post.get_meta_as_boolean("false_key", true)
    
    MetaField.set(@post, "zero_key", "0")
    assert_equal false, @post.get_meta_as_boolean("zero_key", true)
    
    MetaField.set(@post, "no_key", "no")
    assert_equal false, @post.get_meta_as_boolean("no_key", true)
    
    MetaField.set(@post, "off_key", "off")
    assert_equal false, @post.get_meta_as_boolean("off_key", true)
    
    # Test with non-existent key
    assert_equal false, @post.get_meta_as_boolean("non_existent", false)
    
    # Test with invalid boolean
    MetaField.set(@post, "invalid_bool", "maybe")
    assert_equal false, @post.get_meta_as_boolean("invalid_bool", false)
  end

  test "should get meta as JSON with default" do
    # Test with valid JSON
    json_data = { "key" => "value", "number" => 123 }
    MetaField.set(@post, "json_key", json_data.to_json)
    assert_equal json_data, @post.get_meta_as_json("json_key", {})
    
    # Test with non-existent key
    assert_equal({}, @post.get_meta_as_json("non_existent", {}))
    
    # Test with invalid JSON
    MetaField.set(@post, "invalid_json", "invalid json")
    assert_equal({}, @post.get_meta_as_json("invalid_json", {}))
  end

  test "should set meta JSON" do
    json_data = { "key" => "value", "number" => 123 }
    @post.set_meta_json("json_key", json_data)
    
    retrieved_data = @post.get_meta_as_json("json_key", {})
    assert_equal json_data, retrieved_data
  end

  test "should clear all mutable meta fields" do
    MetaField.set(@post, "mutable_key1", "value1", immutable: false)
    MetaField.set(@post, "mutable_key2", "value2", immutable: false)
    MetaField.set(@post, "immutable_key", "value3", immutable: true)
    
    @post.clear_all_meta!
    
    assert_nil @post.get_meta("mutable_key1")
    assert_nil @post.get_meta("mutable_key2")
    assert_equal "value3", @post.get_meta("immutable_key")  # Should remain
  end

  test "should handle plugin meta fields" do
    # Set plugin meta fields
    @post.set_plugin_meta("test_plugin", "setting1", "value1")
    @post.set_plugin_meta("test_plugin", "setting2", "value2")
    @post.set_plugin_meta("other_plugin", "setting", "value")
    
    # Get plugin meta field
    assert_equal "value1", @post.get_plugin_meta("test_plugin", "setting1")
    
    # Bulk get plugin meta fields
    plugin_data = @post.bulk_get_plugin_meta("test_plugin", ["setting1", "setting2"])
    assert_equal({ "setting1" => "value1", "setting2" => "value2" }, plugin_data)
    
    # Get all plugin meta fields
    all_plugin_data = @post.get_all_plugin_meta("test_plugin")
    assert_equal({ "setting1" => "value1", "setting2" => "value2" }, all_plugin_data)
    
    # Delete plugin meta field
    @post.delete_plugin_meta("test_plugin", "setting1")
    assert_nil @post.get_plugin_meta("test_plugin", "setting1")
    
    # Delete all plugin meta fields
    @post.delete_all_plugin_meta("test_plugin")
    assert_empty @post.get_all_plugin_meta("test_plugin")
    
    # Verify other plugin data is unaffected
    assert_equal "value", @post.get_plugin_meta("other_plugin", "setting")
  end

  test "should handle plugin meta fields with immutable flag" do
    @post.set_plugin_meta("test_plugin", "immutable_setting", "value", immutable: true)
    
    # Should be able to retrieve
    assert_equal "value", @post.get_plugin_meta("test_plugin", "immutable_setting")
    
    # Should not be able to modify
    assert_raises(ArgumentError) do
      @post.set_plugin_meta("test_plugin", "immutable_setting", "new_value")
    end
    
    # Should not be able to delete
    assert_raises(ArgumentError) do
      @post.delete_plugin_meta("test_plugin", "immutable_setting")
    end
  end

  test "should work with different metable types" do
    # Test with Page
    page = pages(:one)
    page.set_plugin_meta("test_plugin", "page_setting", "page_value")
    assert_equal "page_value", page.get_plugin_meta("test_plugin", "page_setting")
    
    # Test with User
    user = users(:user)
    user.set_plugin_meta("test_plugin", "user_setting", "user_value")
    assert_equal "user_value", user.get_plugin_meta("test_plugin", "user_setting")
    
    # Test with AiAgent
    agent = ai_agents(:content_summarizer)
    agent.set_plugin_meta("test_plugin", "agent_setting", "agent_value")
    assert_equal "agent_value", agent.get_plugin_meta("test_plugin", "agent_setting")
  end
end
