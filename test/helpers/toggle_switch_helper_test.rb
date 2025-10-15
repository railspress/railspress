require 'test_helper'

class ToggleSwitchHelperTest < ActionView::TestCase
  include ToggleSwitchHelper

  def setup
    @post = posts(:one)
  end

  test "toggle_switch_tag generates correct HTML" do
    html = toggle_switch_tag('test', '1', false, 'Test Label')
    
    assert_includes html, 'toggle-with-label'
    assert_includes html, 'type="checkbox"'
    assert_includes html, 'name="test"'
    assert_includes html, 'value="1"'
    assert_includes html, 'Test Label'
  end

  test "toggle_switch_tag with description generates correct HTML" do
    html = toggle_switch_tag('test', '1', false, 'Test Label', description: 'Test description')
    
    assert_includes html, 'toggle-with-description'
    assert_includes html, 'Test Label'
    assert_includes html, 'Test description'
  end

  test "toggle_switch generates correct HTML" do
    form = ActionView::Helpers::FormBuilder.new(:post, @post, self, {})
    
    html = toggle_switch(form, :active, 'Active Label')
    
    assert_includes html, 'toggle-with-label'
    assert_includes html, 'type="checkbox"'
    assert_includes html, 'name="post[active]"'
    assert_includes html, 'Active Label'
  end

  test "toggle_switch_group generates correct HTML" do
    html = toggle_switch_group do
      "test content"
    end
    
    assert_includes html, 'toggle-group'
    assert_includes html, 'test content'
  end

  test "toggle_switch_group with horizontal direction" do
    html = toggle_switch_group(direction: 'horizontal') do
      "test content"
    end
    
    assert_includes html, 'toggle-group-horizontal'
    assert_includes html, 'test content'
  end

  test "color variants generate correct classes" do
    html = toggle_switch_tag('test', '1', false, 'Test', color: 'success')
    assert_includes html, 'toggle-success'
    
    html = toggle_switch_tag('test', '1', false, 'Test', color: 'warning')
    assert_includes html, 'toggle-warning'
    
    html = toggle_switch_tag('test', '1', false, 'Test', color: 'danger')
    assert_includes html, 'toggle-danger'
  end

  test "size variants generate correct classes" do
    html = toggle_switch_tag('test', '1', false, 'Test', size: 'sm')
    assert_includes html, 'toggle-sm'
    
    html = toggle_switch_tag('test', '1', false, 'Test', size: 'lg')
    assert_includes html, 'toggle-lg'
  end

  test "special state helpers work correctly" do
    html = success_toggle_switch_tag('test', '1', false, 'Test')
    assert_includes html, 'toggle-success'
    
    html = warning_toggle_switch_tag('test', '1', false, 'Test')
    assert_includes html, 'toggle-warning'
    
    html = danger_toggle_switch_tag('test', '1', false, 'Test')
    assert_includes html, 'toggle-danger'
  end
end


