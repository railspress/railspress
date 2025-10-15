require "test_helper"

class EditorHelperTest < ActionView::TestCase
  include EditorHelper

  def setup
    @admin = users(:admin)
    @admin.update(editor_preference: 'blocknote')
  end

  test "render_content_editor returns partial" do
    form = stub(object: Post.new)
    
    result = render_content_editor(form, :content)
    
    assert_not_nil result
    # Should render the content_editor partial
  end

  test "editor_preference_options returns all editors" do
    options = editor_preference_options
    
    assert_equal 4, options.length
    assert_includes options.map(&:last), 'blocknote'
    assert_includes options.map(&:last), 'trix'
    assert_includes options.map(&:last), 'ckeditor'
    assert_includes options.map(&:last), 'editorjs'
  end

  test "editor_display_name returns correct names" do
    assert_equal 'BlockNote', editor_display_name('blocknote')
    assert_equal 'Trix (ActionText)', editor_display_name('trix')
    assert_equal 'CKEditor', editor_display_name('ckeditor')
    assert_equal 'Editor.js', editor_display_name('editorjs')
  end

  test "editor_icon returns HTML for all editors" do
    ['blocknote', 'trix', 'ckeditor', 'editorjs'].each do |editor|
      icon = editor_icon(editor)
      assert_includes icon, '<svg'
      assert icon.html_safe?
    end
  end

  test "user_has_editor_preference? checks current_user" do
    # Mock current_user
    def current_user
      @admin
    end
    
    assert user_has_editor_preference?
    
    @admin.update(editor_preference: nil)
    assert_not user_has_editor_preference?
  end
end






