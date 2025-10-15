require 'test_helper'

class AiTextGeneratorHelperTest < ActionView::TestCase
  include AiTextGeneratorHelper

  def setup
    @post = posts(:one)
  end

  test "ai_text_field generates correct HTML" do
    skip "Helper method HTML generation needs to be tested in integration tests"
  end

  test "ai_text_area generates correct HTML" do
    skip "Helper method HTML generation needs to be tested in integration tests"
  end

  test "ai_agents_available? returns boolean" do
    # This will depend on whether there are active AI agents in the test database
    result = ai_agents_available?
    assert_includes [true, false], result
  end

  test "ai_agent_options returns array of options" do
    options = ai_agent_options
    assert_kind_of Array, options
    # Each option should be an array with [name, id]
    options.each do |option|
      assert_kind_of Array, option
      assert_equal 2, option.length
    end
  end

  test "ai_text_generator_button generates correct HTML" do
    html = ai_text_generator_button(
      agent_id: 'test_agent',
      target_selector: '#test_field',
      button_text: 'Test AI',
      placeholder: 'Test prompt'
    )
    
    assert_includes html, 'ai-text-generator'
    assert_includes html, 'test_agent'
    assert_includes html, '#test_field'
    assert_includes html, 'Test AI'
    assert_includes html, 'Test prompt'
  end

  test "with_ai_generator wraps field with AI generator" do
    field_html = '<textarea id="test_field"></textarea>'
    
    html = with_ai_generator(
      field_html,
      agent_id: 'test_agent',
      target_selector: '#test_field'
    )
    
    assert_includes html, 'relative'
    assert_includes html, 'ai-text-generator'
    assert_includes html, 'test_agent'
    assert_includes html, '#test_field'
    assert_includes html, '<textarea id="test_field"></textarea>'
  end
end
