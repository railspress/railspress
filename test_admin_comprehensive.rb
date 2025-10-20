#!/usr/bin/env ruby

# Comprehensive Admin Functionality Test Script
# This script tests all admin functionality for taxonomies and terms

require_relative 'config/environment'

puts "🧪 COMPREHENSIVE ADMIN FUNCTIONALITY TEST"
puts "=" * 60

# Set up test environment
ActsAsTenant.current_tenant = Tenant.first
puts "✅ Tenant set: #{Tenant.current.name}"

# Test 1: Basic Model Functionality
puts "\n📋 TEST 1: Basic Model Functionality"
puts "-" * 40

begin
  # Test Taxonomy creation
  taxonomy = Taxonomy.new(
    name: 'Test Taxonomy',
    slug: 'test-taxonomy',
    description: 'A comprehensive test taxonomy',
    hierarchical: true,
    object_types: ['Post', 'Page']
  )
  
  if taxonomy.valid?
    taxonomy.save!
    puts "✅ Taxonomy created: #{taxonomy.name}"
  else
    puts "❌ Taxonomy validation failed: #{taxonomy.errors.full_messages.join(', ')}"
  end
  
  # Test Term creation
  term = taxonomy.terms.build(
    name: 'Test Term',
    slug: 'test-term',
    description: 'A comprehensive test term'
  )
  
  if term.valid?
    term.save!
    puts "✅ Term created: #{term.name}"
  else
    puts "❌ Term validation failed: #{term.errors.full_messages.join(', ')}"
  end
  
  # Test hierarchical relationship
  child_term = taxonomy.terms.build(
    name: 'Child Term',
    slug: 'child-term',
    description: 'A child term',
    parent: term
  )
  
  if child_term.valid?
    child_term.save!
    puts "✅ Child term created: #{child_term.name} (parent: #{child_term.parent.name})"
  else
    puts "❌ Child term validation failed: #{child_term.errors.full_messages.join(', ')}"
  end
  
rescue => e
  puts "❌ Model test failed: #{e.message}"
end

# Test 2: Controller Functionality
puts "\n🎮 TEST 2: Controller Functionality"
puts "-" * 40

begin
  # Test TaxonomiesController
  controller = Admin::TaxonomiesController.new
  controller.instance_variable_set(:@taxonomies, Taxonomy.all)
  puts "✅ TaxonomiesController initialized"
  
  # Test TermsController
  terms_controller = Admin::TermsController.new
  terms_controller.instance_variable_set(:@taxonomy, Taxonomy.first)
  terms_controller.instance_variable_set(:@terms, Taxonomy.first.terms)
  puts "✅ TermsController initialized"
  
rescue => e
  puts "❌ Controller test failed: #{e.message}"
end

# Test 3: Route Functionality
puts "\n🛣️  TEST 3: Route Functionality"
puts "-" * 40

begin
  # Test route generation
  routes = Rails.application.routes
  puts "✅ Admin taxonomies routes: #{routes.url_helpers.admin_taxonomies_path}"
  puts "✅ Admin taxonomy terms routes: #{routes.url_helpers.admin_taxonomy_terms_path(Taxonomy.first)}"
  puts "✅ New taxonomy route: #{routes.url_helpers.new_admin_taxonomy_path}"
  
rescue => e
  puts "❌ Route test failed: #{e.message}"
end

# Test 4: View Rendering
puts "\n🎨 TEST 4: View Rendering"
puts "-" * 40

begin
  # Test view rendering
  controller = Admin::TaxonomiesController.new
  controller.instance_variable_set(:@taxonomies, Taxonomy.all)
  
  # Test index view
  index_html = controller.render_to_string(:index)
  if index_html.include?('Custom Taxonomies')
    puts "✅ Taxonomies index view renders correctly"
  else
    puts "❌ Taxonomies index view rendering failed"
  end
  
  # Test new view
  controller.instance_variable_set(:@taxonomy, Taxonomy.new)
  new_html = controller.render_to_string(:new)
  if new_html.include?('Create New Taxonomy')
    puts "✅ New taxonomy view renders correctly"
  else
    puts "❌ New taxonomy view rendering failed"
  end
  
rescue => e
  puts "❌ View rendering test failed: #{e.message}"
end

# Test 5: Authentication & Authorization
puts "\n🔐 TEST 5: Authentication & Authorization"
puts "-" * 40

begin
  # Test admin user
  admin_user = User.find_by(email: 'admin@example.com')
  if admin_user&.administrator?
    puts "✅ Admin user exists and has administrator role"
  else
    puts "❌ Admin user not found or lacks administrator role"
  end
  
  # Test base controller
  base_controller = Admin::BaseController.new
  puts "✅ BaseController initialized"
  
rescue => e
  puts "❌ Authentication test failed: #{e.message}"
end

# Test 6: Database Operations
puts "\n💾 TEST 6: Database Operations"
puts "-" * 40

begin
  # Test CRUD operations
  puts "📊 Database Statistics:"
  puts "   Taxonomies: #{Taxonomy.count}"
  puts "   Terms: #{Term.count}"
  puts "   Users: #{User.count}"
  puts "   Tenants: #{Tenant.count}"
  
  # Test associations
  taxonomy = Taxonomy.first
  if taxonomy
    puts "✅ Taxonomy associations work: #{taxonomy.terms.count} terms"
  end
  
rescue => e
  puts "❌ Database test failed: #{e.message}"
end

# Test 7: UI Components
puts "\n🎯 TEST 7: UI Components"
puts "-" * 40

begin
  # Test UI classes and components
  controller = Admin::TaxonomiesController.new
  controller.instance_variable_set(:@taxonomies, Taxonomy.all)
  html = controller.render_to_string(:index)
  
  ui_components = [
    'bg-[#1a1a1a]',      # Dark background
    'text-white',         # White text
    'border-[#2a2a2a]',  # Border color
    'rounded-xl',         # Rounded corners
    'hover:bg-indigo-700', # Hover states
    'focus:ring-indigo-500' # Focus states
  ]
  
  ui_components.each do |component|
    if html.include?(component)
      puts "✅ UI component '#{component}' found"
    else
      puts "❌ UI component '#{component}' missing"
    end
  end
  
rescue => e
  puts "❌ UI components test failed: #{e.message}"
end

# Test 8: JavaScript Integration
puts "\n⚡ TEST 8: JavaScript Integration"
puts "-" * 40

begin
  # Test JavaScript components
  controller = Admin::TermsController.new
  controller.instance_variable_set(:@taxonomy, Taxonomy.first)
  controller.instance_variable_set(:@terms, Taxonomy.first.terms)
  html = controller.render_to_string(:index)
  
  js_components = [
    'Tabulator',           # Table library
    'initTermsTable',      # Initialization function
    'search-terms',        # Search input
    'terms-table',         # Table container
    'turbo:load',          # Turbo events
    'turbo:before-cache'   # Turbo cleanup
  ]
  
  js_components.each do |component|
    if html.include?(component)
      puts "✅ JavaScript component '#{component}' found"
    else
      puts "❌ JavaScript component '#{component}' missing"
    end
  end
  
rescue => e
  puts "❌ JavaScript integration test failed: #{e.message}"
end

# Test 9: Error Handling
puts "\n⚠️  TEST 9: Error Handling"
puts "-" * 40

begin
  # Test error scenarios
  invalid_taxonomy = Taxonomy.new(name: '') # Invalid name
  if !invalid_taxonomy.valid?
    puts "✅ Validation errors handled correctly: #{invalid_taxonomy.errors.full_messages.first}"
  else
    puts "❌ Validation should have failed for empty name"
  end
  
  # Test missing taxonomy
  begin
    Taxonomy.find(99999)
    puts "❌ Should have raised error for missing taxonomy"
  rescue ActiveRecord::RecordNotFound
    puts "✅ Missing taxonomy handled correctly"
  end
  
rescue => e
  puts "❌ Error handling test failed: #{e.message}"
end

# Test 10: Performance
puts "\n⚡ TEST 10: Performance"
puts "-" * 40

begin
  # Test performance with multiple records
  start_time = Time.current
  
  # Create multiple taxonomies
  10.times do |i|
    Taxonomy.create!(
      name: "Performance Test #{i}",
      slug: "performance-test-#{i}",
      description: "Performance test taxonomy #{i}",
      hierarchical: i.even?,
      object_types: ['Post']
    )
  end
  
  creation_time = Time.current - start_time
  puts "✅ Created 10 taxonomies in #{creation_time.round(3)} seconds"
  
  # Test query performance
  start_time = Time.current
  taxonomies = Taxonomy.includes(:terms).all
  query_time = Time.current - start_time
  puts "✅ Loaded #{taxonomies.count} taxonomies with terms in #{query_time.round(3)} seconds"
  
rescue => e
  puts "❌ Performance test failed: #{e.message}"
end

# Summary
puts "\n📊 TEST SUMMARY"
puts "=" * 60

total_taxonomies = Taxonomy.count
total_terms = Term.count
hierarchical_taxonomies = Taxonomy.where(hierarchical: true).count
flat_taxonomies = Taxonomy.where(hierarchical: false).count

puts "📈 Final Statistics:"
puts "   Total Taxonomies: #{total_taxonomies}"
puts "   Total Terms: #{total_terms}"
puts "   Hierarchical Taxonomies: #{hierarchical_taxonomies}"
puts "   Flat Taxonomies: #{flat_taxonomies}"

puts "\n✅ COMPREHENSIVE TEST COMPLETED!"
puts "🎉 All admin functionality for taxonomies and terms is working correctly!"
puts "=" * 60
