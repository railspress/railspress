require "test_helper"

class ContentTypeTest < ActiveSupport::TestCase
  test "should create content type with valid attributes" do
    content_type = ContentType.new(
      ident: "portfolio",
      label: "Portfolio",
      singular: "Portfolio Item",
      plural: "Portfolio Items"
    )
    assert content_type.valid?
    assert content_type.save
  end
  
  test "should require ident" do
    content_type = ContentType.new(label: "Test")
    assert_not content_type.valid?
    assert_includes content_type.errors[:ident], "can't be blank"
  end
  
  test "should require unique ident" do
    ContentType.create!(ident: "test", label: "Test", singular: "Test", plural: "Tests")
    content_type = ContentType.new(ident: "test", label: "Test", singular: "Test", plural: "Tests")
    assert_not content_type.valid?
    assert_includes content_type.errors[:ident], "has already been taken"
  end
  
  test "should normalize ident to lowercase with hyphens" do
    content_type = ContentType.create!(
      ident: "Test Content Type!",
      label: "Test",
      singular: "Test",
      plural: "Tests"
    )
    assert_equal "test-content-type-", content_type.ident
  end
  
  test "should find by ident" do
    content_type = ContentType.create!(ident: "test", label: "Test", singular: "Test", plural: "Tests")
    found = ContentType.find_by_ident("test")
    assert_equal content_type.id, found.id
  end
  
  test "should support features" do
    content_type = ContentType.create!(
      ident: "test",
      label: "Test",
      singular: "Test",
      plural: "Tests",
      supports: ["title", "editor"]
    )
    assert content_type.supports?("title")
    assert content_type.supports?("editor")
    assert_not content_type.supports?("thumbnail")
  end
  
  test "should have default active scope" do
    ContentType.create!(ident: "active", label: "Active", singular: "Active", plural: "Actives", active: true)
    ContentType.create!(ident: "inactive", label: "Inactive", singular: "Inactive", plural: "Inactives", active: false)
    
    assert_equal 1, ContentType.active.count
  end
  
  test "should set default values" do
    content_type = ContentType.create!(ident: "test", label: "Test")
    assert_equal "Test", content_type.singular
    assert_equal "Tests", content_type.plural
    assert_equal true, content_type.active
    assert_equal true, content_type.public
  end
end

