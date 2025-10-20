#!/usr/bin/env ruby

# Test script for GDPR implementation
puts "🧪 Testing GDPR Implementation"
puts "=" * 50

begin
  # Load Rails environment
  require_relative 'config/environment'
  
  puts "✅ Rails environment loaded successfully"
  
  # Test 1: Check if GDPR models exist
  puts "\n📋 Testing Models:"
  
  if defined?(PersonalDataExportRequest)
    puts "✅ PersonalDataExportRequest model exists"
  else
    puts "❌ PersonalDataExportRequest model missing"
  end
  
  if defined?(PersonalDataErasureRequest)
    puts "✅ PersonalDataErasureRequest model exists"
  else
    puts "❌ PersonalDataErasureRequest model missing"
  end
  
  if defined?(UserConsent)
    puts "✅ UserConsent model exists"
  else
    puts "❌ UserConsent model missing"
  end
  
  # Test 2: Check if GDPR service exists
  puts "\n🔧 Testing Services:"
  
  if defined?(GdprService)
    puts "✅ GdprService exists"
    
    # Test service methods
    methods = [
      :create_export_request,
      :create_erasure_request,
      :confirm_erasure_request,
      :generate_portability_data,
      :get_user_gdpr_status,
      :record_user_consent,
      :withdraw_user_consent,
      :get_audit_log
    ]
    
    methods.each do |method|
      if GdprService.respond_to?(method)
        puts "  ✅ #{method} method exists"
      else
        puts "  ❌ #{method} method missing"
      end
    end
  else
    puts "❌ GdprService missing"
  end
  
  # Test 3: Check if controllers exist
  puts "\n🎮 Testing Controllers:"
  
  controller_path = Rails.root.join('app', 'controllers', 'api', 'v1', 'gdpr_controller.rb')
  if File.exist?(controller_path)
    puts "✅ GDPR API controller exists"
  else
    puts "❌ GDPR API controller missing"
  end
  
  # Test 4: Check if GraphQL types exist
  puts "\n🔍 Testing GraphQL Types:"
  
  gdpr_type_path = Rails.root.join('app', 'graphql', 'types', 'gdpr_type.rb')
  if File.exist?(gdpr_type_path)
    puts "✅ GDPR GraphQL types exist"
  else
    puts "❌ GDPR GraphQL types missing"
  end
  
  gdpr_mutations_path = Rails.root.join('app', 'graphql', 'mutations', 'gdpr_mutations.rb')
  if File.exist?(gdpr_mutations_path)
    puts "✅ GDPR GraphQL mutations exist"
  else
    puts "❌ GDPR GraphQL mutations missing"
  end
  
  # Test 5: Check if routes exist
  puts "\n🛣️  Testing Routes:"
  
  # Check if GDPR routes are defined
  routes = Rails.application.routes.routes
  gdpr_routes = routes.select { |route| route.path.spec.to_s.include?('gdpr') }
  
  if gdpr_routes.any?
    puts "✅ GDPR routes found:"
    gdpr_routes.each do |route|
      puts "  - #{route.verb} #{route.path.spec}"
    end
  else
    puts "❌ No GDPR routes found"
  end
  
  # Test 6: Check if workers exist
  puts "\n⚙️  Testing Workers:"
  
  worker_path = Rails.root.join('app', 'workers', 'personal_data_erasure_worker.rb')
  if File.exist?(worker_path)
    puts "✅ PersonalDataErasureWorker exists"
  else
    puts "❌ PersonalDataErasureWorker missing"
  end
  
  # Test 7: Check if documentation exists
  puts "\n📚 Testing Documentation:"
  
  doc_path = Rails.root.join('docs', 'api', 'GDPR_COMPLIANCE_API.md')
  if File.exist?(doc_path)
    puts "✅ GDPR API documentation exists"
  else
    puts "❌ GDPR API documentation missing"
  end
  
  puts "\n🎉 GDPR Implementation Test Complete!"
  puts "=" * 50
  
  # Summary
  total_checks = 0
  passed_checks = 0
  
  # Count checks (simplified)
  checks = [
    defined?(PersonalDataExportRequest),
    defined?(PersonalDataErasureRequest), 
    defined?(UserConsent),
    defined?(GdprService),
    File.exist?(controller_path),
    File.exist?(gdpr_type_path),
    File.exist?(gdpr_mutations_path),
    gdpr_routes.any?,
    File.exist?(worker_path),
    File.exist?(doc_path)
  ]
  
  total_checks = checks.length
  passed_checks = checks.count(true)
  
  puts "📊 Results: #{passed_checks}/#{total_checks} checks passed"
  
  if passed_checks == total_checks
    puts "🎯 All GDPR compliance features implemented successfully!"
  else
    puts "⚠️  Some GDPR features may need attention"
  end
  
rescue => e
  puts "❌ Error during testing: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end
