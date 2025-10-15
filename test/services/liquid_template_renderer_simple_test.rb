require "test_helper"

class LiquidTemplateRendererSimpleTest < ActiveSupport::TestCase
  def setup
    @renderer = LiquidTemplateRenderer.new("default", "post", {})
  end

  test "should initialize with theme name and template type" do
    assert_equal "default", @renderer.instance_variable_get(:@theme_name)
    assert_equal "post", @renderer.instance_variable_get(:@template_type)
    assert_equal({}, @renderer.instance_variable_get(:@template_data))
  end

  test "should have render method" do
    assert_respond_to @renderer, :render
  end

  test "should have render_section method" do
    assert_respond_to @renderer, :render_section
  end

  test "should have private methods" do
    # Test that private methods exist by checking if they respond to the method
    assert @renderer.respond_to?(:load_template_structure, true)
    assert @renderer.respond_to?(:render_layout, true)
    assert @renderer.respond_to?(:render_sections, true)
    assert @renderer.respond_to?(:load_theme_settings, true)
    assert @renderer.respond_to?(:load_page_data, true)
    assert @renderer.respond_to?(:default_layout, true)
  end

  test "should handle render with missing theme files gracefully" do
    # Test that render doesn't crash when theme files don't exist
    result = @renderer.render
    assert_not_nil result
    assert result.is_a?(String)
  end

  test "should handle render_section with missing section files gracefully" do
    # Test that render_section doesn't crash when section files don't exist
    result = @renderer.render_section("nonexistent", {})
    assert_equal "", result
  end

  test "should have theme_path set correctly" do
    expected_path = Rails.root.join('app', 'themes', 'default')
    assert_equal expected_path, @renderer.instance_variable_get(:@theme_path)
  end

  test "should initialize with different parameters" do
    renderer2 = LiquidTemplateRenderer.new("custom_theme", "page", { "custom" => "data" })
    
    assert_equal "custom_theme", renderer2.instance_variable_get(:@theme_name)
    assert_equal "page", renderer2.instance_variable_get(:@template_type)
    assert_equal({ "custom" => "data" }, renderer2.instance_variable_get(:@template_data))
  end

  test "should handle template_data parameter" do
    template_data = { "sections" => { "header" => { "type" => "header" } } }
    renderer = LiquidTemplateRenderer.new("default", "index", template_data)
    
    assert_equal template_data, renderer.instance_variable_get(:@template_data)
  end
end


