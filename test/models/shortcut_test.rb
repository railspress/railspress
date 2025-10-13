require "test_helper"

class ShortcutTest < ActiveSupport::TestCase
  def setup
    @shortcut = Shortcut.new(
      title: "Create New Post",
      description: "Quickly create a new post",
      path: "/admin/posts/new",
      icon: "document-add",
      category: "posts"
    )
  end

  test "should be valid with valid attributes" do
    assert @shortcut.valid?
  end

  test "should require title" do
    @shortcut.title = nil
    assert_not @shortcut.valid?
  end

  test "should require path" do
    @shortcut.path = nil
    assert_not @shortcut.valid?
  end

  test "should have default active status" do
    assert @shortcut.active
  end

  test "should scope by category" do
    @shortcut.category = "posts"
    @shortcut.save!
    
    shortcuts = Shortcut.where(category: "posts")
    assert_includes shortcuts, @shortcut
  end

  test "should scope active shortcuts" do
    active_shortcut = Shortcut.create!(
      title: "Active Shortcut",
      path: "/admin/test",
      active: true
    )
    inactive_shortcut = Shortcut.create!(
      title: "Inactive Shortcut",
      path: "/admin/test2",
      active: false
    )
    
    active_shortcuts = Shortcut.where(active: true)
    assert_includes active_shortcuts, active_shortcut
    assert_not_includes active_shortcuts, inactive_shortcut
  end
end

