require "test_helper"

class AppearanceHelperTest < ActionView::TestCase
  include AppearanceHelper

  test "color_scheme_colors returns midnight scheme by default" do
    colors = color_scheme_colors('midnight')
    
    assert_equal '#0f0f0f', colors[:bg_primary]
    assert_equal '#141414', colors[:bg_secondary]
    assert_equal '#1a1a1a', colors[:bg_tertiary]
    assert_equal '#2f2f2f', colors[:border_color]
  end

  test "color_scheme_colors returns vallarta scheme" do
    colors = color_scheme_colors('vallarta')
    
    assert_equal '#0a1628', colors[:bg_primary]
    assert_equal '#0f1e3a', colors[:bg_secondary]
    assert_equal '#1a2947', colors[:bg_tertiary]
    assert_equal '#2a3f5f', colors[:border_color]
  end

  test "color_scheme_colors returns amanecer (light) scheme" do
    colors = color_scheme_colors('amanecer')
    
    assert_equal '#ffffff', colors[:bg_primary]
    assert_equal '#f8f9fa', colors[:bg_secondary]
    assert_equal '#f1f3f5', colors[:bg_tertiary]
    assert_equal '#e9ecef', colors[:border_color]
  end

  test "color_scheme_colors returns onyx scheme" do
    colors = color_scheme_colors('onyx')
    
    assert_equal '#000000', colors[:bg_primary]
    assert_equal '#0a0a0a', colors[:bg_secondary]
    assert_equal '#111111', colors[:bg_tertiary]
    assert_equal '#1a1a1a', colors[:border_color]
  end

  test "color_scheme_colors returns slate scheme" do
    colors = color_scheme_colors('slate')
    
    assert_equal '#0f172a', colors[:bg_primary]
    assert_equal '#1e293b', colors[:bg_secondary]
    assert_equal '#334155', colors[:bg_tertiary]
    assert_equal '#475569', colors[:border_color]
  end

  test "color_scheme_colors defaults to midnight for unknown scheme" do
    colors = color_scheme_colors('unknown')
    
    assert_equal '#0f0f0f', colors[:bg_primary]
  end

  test "darken_color darkens hex colors" do
    result = darken_color('#6366f1', 10)
    
    assert_match /^#[0-9a-f]{6}$/i, result
    assert_not_equal '#6366f1', result
    # Darkened color should have lower RGB values
  end

  test "lighten_color lightens hex colors" do
    result = lighten_color('#6366f1', 10)
    
    assert_match /^#[0-9a-f]{6}$/i, result
    assert_not_equal '#6366f1', result
    # Lightened color should have higher RGB values
  end

  test "hex_to_rgba converts hex to rgba" do
    result = hex_to_rgba('#6366f1', 0.5)
    
    assert_equal 'rgba(99, 102, 241, 0.5)', result
  end

  test "hex_to_rgba handles hex without hash" do
    result = hex_to_rgba('6366f1', 1.0)
    
    assert_equal 'rgba(99, 102, 241, 1.0)', result
  end

  test "hex_to_rgba defaults to alpha 1.0" do
    result = hex_to_rgba('#6366f1')
    
    assert_equal 'rgba(99, 102, 241, 1.0)', result
  end

  test "dynamic_appearance_css generates valid CSS" do
    # Mock SiteSetting
    SiteSetting.set('color_scheme', 'midnight', 'string')
    SiteSetting.set('primary_color', '#6366F1', 'string')
    SiteSetting.set('secondary_color', '#8B5CF6', 'string')
    
    css = dynamic_appearance_css
    
    assert_includes css, ':root'
    assert_includes css, '--admin-bg-app'
    assert_includes css, '--admin-primary'
    assert_includes css, '--admin-success'
    assert_includes css, '<style id="dynamic-appearance">'
  end

  test "dynamic_appearance_css includes all color variables" do
    css = dynamic_appearance_css
    
    # Background variables
    assert_includes css, '--admin-bg-app'
    assert_includes css, '--admin-bg-primary'
    assert_includes css, '--admin-bg-secondary'
    assert_includes css, '--admin-bg-tertiary'
    assert_includes css, '--admin-bg-elevated'
    
    # Border variables
    assert_includes css, '--admin-border-subtle'
    assert_includes css, '--admin-border'
    assert_includes css, '--admin-border-strong'
    
    # Text variables
    assert_includes css, '--admin-text-primary'
    assert_includes css, '--admin-text-secondary'
    assert_includes css, '--admin-text-tertiary'
    assert_includes css, '--admin-text-muted'
    
    # Brand variables
    assert_includes css, '--admin-primary'
    assert_includes css, '--admin-secondary'
    
    # Status variables
    assert_includes css, '--admin-success'
    assert_includes css, '--admin-warning'
    assert_includes css, '--admin-error'
    assert_includes css, '--admin-info'
  end

  test "dynamic_appearance_css adjusts for light theme" do
    SiteSetting.set('color_scheme', 'amanecer', 'string')
    
    css = dynamic_appearance_css
    
    # Light theme should have dark text
    assert_includes css, '--text-primary: #1a202c'
  end

  test "dynamic_appearance_css adjusts for dark theme" do
    SiteSetting.set('color_scheme', 'midnight', 'string')
    
    css = dynamic_appearance_css
    
    # Dark theme should have light text
    assert_includes css, '--text-primary: #ffffff'
  end
end


