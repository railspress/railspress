require "test_helper"

class PageTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @page = Page.new(
      title: "Test Page",
      content: "This is test content",
      slug: "test-page",
      status: "published",
      author: @user
    )
  end

  test "should be valid with valid attributes" do
    assert @page.valid?
  end

  test "should require title" do
    @page.title = nil
    assert_not @page.valid?
  end

  test "should require content" do
    @page.content = nil
    assert_not @page.valid?
  end

  test "should require author" do
    @page.author = nil
    assert_not @page.valid?
  end

  test "should generate slug from title" do
    @page.title = "My Amazing Page"
    @page.save!
    assert_equal "my-amazing-page", @page.slug
  end

  test "should have valid statuses" do
    valid_statuses = %w[draft published private]
    valid_statuses.each do |status|
      @page.status = status
      assert @page.valid?
    end
  end
end


