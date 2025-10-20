require 'test_helper'

class AdminTaxonomiesJavascriptTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin)
    sign_in @user
    ActsAsTenant.current_tenant = Tenant.first
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "should load Tabulator table on terms page" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Check that Tabulator script is loaded
    assert_select "script", text: /Tabulator/
    assert_select "script", text: /initTermsTable/
    
    # Check table container exists
    assert_select "div[id='terms-table']"
    
    # Check search input exists
    assert_select "input[id='search-terms']"
  end

  test "should handle form submission with JavaScript" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Check form has proper attributes for JavaScript handling
    assert_select "form[data-turbo='true']"
    assert_select "form[action='#{admin_taxonomy_terms_path(taxonomy)}']"
  end

  test "should handle delete confirmations with JavaScript" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Check delete links have proper data attributes
    assert_select "a[data-turbo-method='delete']"
    assert_select "a[data-turbo-confirm]"
  end

  test "should handle responsive design classes" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check responsive grid classes
    assert_select ".grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-3"
    assert_select ".max-w-7xl.mx-auto"
  end

  test "should handle dark theme classes correctly" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check dark theme classes are present
    assert_select ".bg-\\[#1a1a1a\\]"
    assert_select ".text-white"
    assert_select ".border-\\[#2a2a2a\\]"
    assert_select ".text-gray-400"
  end

  test "should handle hover states correctly" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check hover classes
    assert_select ".hover\\:bg-indigo-700"
    assert_select ".hover\\:text-white"
    assert_select ".hover\\:border-\\[#3a3a3a\\]"
  end

  test "should handle focus states correctly" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Check focus classes on form inputs
    assert_select "input.focus\\:outline-none.focus\\:ring-2.focus\\:ring-indigo-500"
    assert_select "textarea.focus\\:outline-none.focus\\:ring-2.focus\\:ring-indigo-500"
    assert_select "select.focus\\:outline-none.focus\\:ring-2.focus\\:ring-indigo-500"
  end

  test "should handle transition animations" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check transition classes
    assert_select ".transition"
    assert_select ".group-hover\\:text-indigo-400"
  end

  test "should handle button states correctly" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check button classes
    assert_select "button.bg-indigo-600.hover\\:bg-indigo-700"
    assert_select "a.bg-indigo-600.hover\\:bg-indigo-700"
  end

  test "should handle form validation styling" do
    get new_admin_taxonomy_path
    assert_response :success
    
    # Check required field indicators
    assert_select "input[required]"
    assert_select "label.text-gray-300"
  end

  test "should handle status badges correctly" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check status badge classes
    assert_select "span.bg-purple-500\\/10.text-purple-400"
    assert_select "span.bg-blue-500\\/10.text-blue-400"
  end

  test "should handle empty state styling" do
    Taxonomy.destroy_all
    get admin_taxonomies_path
    assert_response :success
    
    # Check empty state classes
    assert_select ".bg-\\[#1a1a1a\\].border.border-\\[#2a2a2a\\].rounded-xl.p-12.text-center"
  end

  test "should handle info boxes styling" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check info box classes
    assert_select ".bg-gradient-to-r.from-indigo-500\\/10.to-purple-500\\/10"
    assert_select ".border.border-indigo-500\\/20"
  end

  test "should handle sticky positioning" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Check sticky classes
    assert_select ".sticky.top-20"
  end

  test "should handle overflow handling" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check overflow classes
    assert_select ".overflow-hidden"
  end

  test "should handle text truncation" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check truncation is handled in JavaScript/HTML
    assert_select "p", text: /truncate/
  end

  test "should handle icon styling" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check SVG icons have proper classes
    assert_select "svg.w-5.h-5"
    assert_select "svg.w-8.h-8"
    assert_select "svg.w-4.h-4"
  end

  test "should handle loading states" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check loading/placeholder classes
    assert_select ".placeholder"
  end

  test "should handle accessibility attributes" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check accessibility attributes
    assert_select "input[placeholder]"
    assert_select "button[type='submit']"
    assert_select "form[method='post']"
  end

  test "should handle CSRF tokens in forms" do
    get new_admin_taxonomy_path
    assert_response :success
    
    # Check CSRF token is present
    assert_select "input[name='authenticity_token']"
  end

  test "should handle Turbo Drive compatibility" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check Turbo attributes
    assert_select "meta[name='turbo-visit-control']"
  end

  test "should handle external CDN resources" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check external resources are loaded
    assert_select "link[href*='tabulator']"
    assert_select "link[href*='sweetalert2']"
    assert_select "script[src*='luxon']"
  end

  test "should handle custom CSS variables" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check CSS variables are defined
    assert_select "style", text: /--bg-primary/
    assert_select "style", text: /--text-primary/
  end

  test "should handle SweetAlert2 integration" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check SweetAlert2 is loaded
    assert_select "script[src*='sweetalert2']"
    assert_select "style", text: /swal2-popup/
  end

  test "should handle Luxon datetime formatting" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check Luxon is loaded for Tabulator
    assert_select "script[src*='luxon']"
  end

  test "should handle Tabulator theme customization" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check Tabulator theme is loaded
    assert_select "link[href*='tabulator_midnight']"
  end

  test "should handle responsive breakpoints correctly" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check responsive classes
    assert_select ".md\\:grid-cols-2"
    assert_select ".lg\\:grid-cols-3"
    assert_select ".md\\:grid-cols-4"
  end

  test "should handle form field grouping" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Check form field grouping
    assert_select ".space-y-4"
    assert_select ".space-y-6"
  end

  test "should handle button grouping" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check button grouping
    assert_select ".flex.items-center.space-x-2"
    assert_select ".flex.items-center.justify-between"
  end

  test "should handle card layouts" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check card layout classes
    assert_select ".bg-\\[#1a1a1a\\].border.border-\\[#2a2a2a\\].rounded-xl"
  end

  test "should handle navigation breadcrumbs" do
    taxonomy = taxonomies(:category)
    get admin_taxonomy_terms_path(taxonomy)
    assert_response :success
    
    # Check breadcrumb navigation
    assert_select "a[href='#{admin_taxonomies_path}']", text: /Back to Taxonomies/
  end

  test "should handle action buttons correctly" do
    get admin_taxonomies_path
    assert_response :success
    
    # Check action button classes
    assert_select "a.bg-red-600.hover\\:bg-red-700"
    assert_select "a.border.border-\\[#2a2a2a\\].hover\\:border-\\[#3a3a3a\\]"
  end
end
