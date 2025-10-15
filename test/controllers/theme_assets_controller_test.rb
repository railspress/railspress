require "test_helper"

class ThemeAssetsControllerTest < ActionDispatch::IntegrationTest
  test "should serve CSS assets" do
    get "/themes/nordic/assets/theme.css"
    
    assert_response :success
    assert_equal "text/css", response.content_type
  end

  test "should serve JavaScript assets" do
    get "/themes/nordic/assets/theme.js"
    
    assert_response :success
    assert_equal "text/javascript", response.content_type
  end

  test "should return 404 for non-existent assets" do
    get "/themes/nordic/assets/nonexistent.css"
    
    assert_response :not_found
  end

  test "should return 404 for invalid theme names" do
    get "/themes/../../etc/passwd"
    
    assert_response :not_found
  end

  test "should prevent path traversal attacks" do
    get "/themes/nordic/assets/../../../config/database.yml"
    
    assert_response :forbidden
  end

  test "should set cache headers" do
    get "/themes/nordic/assets/theme.css"
    
    assert_not_nil response.headers['Cache-Control']
    assert_match /public/, response.headers['Cache-Control']
  end

  test "should handle nested asset paths" do
    get "/themes/nordic/assets/css/components/header.css"
    
    # Should either succeed or return 404, but not error
    assert_includes [200, 404], response.status
  end

  test "should determine correct MIME types" do
    assets = {
      'theme.css' => 'text/css',
      'theme.js' => 'text/javascript',
      'logo.png' => 'image/png',
      'font.woff2' => 'font/woff2'
    }
    
    assets.each do |filename, expected_type|
      skip "File #{filename} not present" unless File.exist?(Rails.root.join('app/themes/nordic/assets', filename))
      
      get "/themes/nordic/assets/#{filename}"
      assert_equal expected_type, response.content_type
    end
  end
end





