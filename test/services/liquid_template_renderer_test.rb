require "test_helper"

class LiquidTemplateRendererTest < ActiveSupport::TestCase
  def setup
    @renderer = LiquidTemplateRenderer.new('nordic')
  end

  test "should initialize with nordic theme" do
    assert_equal Rails.root.join('app', 'themes', 'nordic'), @renderer.theme_path
  end

  test "should render simple template" do
    skip "Requires actual template files"
    # This would test actual template rendering
    # result = @renderer.render('index', {})
    # assert_not_nil result
  end

  test "should wrap content in layout" do
    skip "Requires actual template files"
    # Test layout wrapping
  end

  test "should load site data" do
    data = @renderer.send(:load_site_data)
    assert data.is_a?(Hash)
    assert data.key?('name')
  end

  test "should load theme settings" do
    settings = @renderer.send(:load_theme_settings)
    assert settings.is_a?(Hash)
  end

  test "should prepare assigns with base data" do
    assigns = @renderer.send(:prepare_assigns, { 'test' => 'value' })
    
    assert assigns.key?('site')
    assert assigns.key?('theme')
    assert assigns.key?('settings')
    assert_equal 'value', assigns['test']
  end

  test "should handle missing templates gracefully" do
    error = assert_raises(Errno::ENOENT) do
      @renderer.render('nonexistent_template', {})
    end
    assert_match /No such file or directory/, error.message
  end
end

class LiquidFiltersTest < ActiveSupport::TestCase
  include LiquidFilters

  test "asset_url filter should generate correct URL" do
    assert_equal "/themes/nordic/assets/theme.css", asset_url("theme.css")
    assert_equal "/themes/nordic/assets/js/theme.js", asset_url("js/theme.js")
  end

  test "image_url filter should handle different inputs" do
    assert_equal "", image_url(nil)
    assert_equal "/uploads/image.jpg", image_url("image.jpg")
    assert_equal "https://example.com/image.jpg", image_url("https://example.com/image.jpg")
  end

  test "truncate_words filter should truncate text" do
    text = "This is a very long sentence that should be truncated after a certain number of words"
    result = truncate_words(text, 5)
    
    assert_equal "This is a very long...", result
  end

  test "truncate_words filter should not truncate short text" do
    text = "Short text"
    result = truncate_words(text, 10)
    
    assert_equal text, result
  end

  test "strip_html filter should remove HTML tags" do
    html = "<p>Hello <strong>world</strong></p>"
    result = strip_html(html)
    
    assert_equal "Hello world", result
  end

  test "reading_time filter should calculate reading time" do
    text = ("word " * 200).strip  # 200 words
    result = reading_time(text)
    
    assert_equal "1 min read", result
  end

  test "reading_time filter should round up" do
    text = ("word " * 250).strip  # 250 words
    result = reading_time(text)
    
    assert_equal "2 min read", result
  end

  test "date_format filter should format dates" do
    date = Date.new(2025, 10, 12)
    result = date_format(date)
    
    assert_equal "October 12, 2025", result
  end

  test "date_format filter should handle custom formats" do
    date = Date.new(2025, 10, 12)
    result = date_format(date, '%Y-%m-%d')
    
    assert_equal "2025-10-12", result
  end

  test "url_encode filter should encode URLs" do
    text = "hello world"
    result = url_encode(text)
    
    assert_equal "hello+world", result
  end

  test "json filter should convert to JSON" do
    data = { 'key' => 'value' }
    result = json(data)
    
    assert_equal '{"key":"value"}', result
  end
end



