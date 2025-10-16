require "test_helper"

class BuilderThemeTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.first || Tenant.create!(name: "Test Tenant", domain: "test.com")
    @user = User.first || User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      tenant: @tenant
    )
    @builder_theme = BuilderTheme.new(
      name: "Test Builder Theme",
      description: "A test builder theme",
      user: @user,
      tenant: @tenant
    )
  end

  test "should be valid with valid attributes" do
    assert @builder_theme.valid?
  end

  test "should require name" do
    @builder_theme.name = nil
    assert_not @builder_theme.valid?
    assert_includes @builder_theme.errors[:name], "can't be blank"
  end

  test "should require user" do
    @builder_theme.user = nil
    assert_not @builder_theme.valid?
    assert_includes @builder_theme.errors[:user], "must exist"
  end

  test "should require tenant" do
    @builder_theme.tenant = nil
    assert_not @builder_theme.valid?
    assert_includes @builder_theme.errors[:tenant], "must exist"
  end

  test "should belong to user" do
    assert_respond_to @builder_theme, :user
  end

  test "should belong to tenant" do
    assert_respond_to @builder_theme, :tenant
  end

  test "should have many builder theme files" do
    assert_respond_to @builder_theme, :builder_theme_files
  end

  test "should have many builder theme sections" do
    assert_respond_to @builder_theme, :builder_theme_sections
  end

  test "should have many builder theme snapshots" do
    assert_respond_to @builder_theme, :builder_theme_snapshots
  end

  test "should serialize settings as JSON" do
    @builder_theme.settings = { color: "blue", font: "Arial" }
    @builder_theme.save!
    
    @builder_theme.reload
    assert_equal "blue", @builder_theme.settings["color"]
    assert_equal "Arial", @builder_theme.settings["font"]
  end

  test "should have active scope" do
    @builder_theme.active = true
    @builder_theme.save!
    
    assert_includes BuilderTheme.active, @builder_theme
  end

  test "should have published scope" do
    @builder_theme.published = true
    @builder_theme.save!
    
    assert_includes BuilderTheme.published, @builder_theme
  end

  test "should generate slug from name" do
    @builder_theme.name = "My Test Theme"
    @builder_theme.save!
    
    assert_equal "my-test-theme", @builder_theme.slug
  end

  test "should have version tracking" do
    assert_respond_to @builder_theme, :version
    @builder_theme.version = "1.0.0"
    assert_equal "1.0.0", @builder_theme.version
  end

  test "should track creation and modification dates" do
    @builder_theme.save!
    
    assert_not_nil @builder_theme.created_at
    assert_not_nil @builder_theme.updated_at
  end
end



