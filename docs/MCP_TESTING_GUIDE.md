# MCP Testing Guide

## Overview

This guide covers comprehensive testing strategies for the Model Context Protocol (MCP) implementation in RailsPress. It includes automated tests, manual testing procedures, and debugging techniques.

## Table of Contents

1. [Test Environment Setup](#test-environment-setup)
2. [Automated Testing](#automated-testing)
3. [Manual Testing](#manual-testing)
4. [Integration Testing](#integration-testing)
5. [Performance Testing](#performance-testing)
6. [Security Testing](#security-testing)
7. [Debugging](#debugging)
8. [Test Data Management](#test-data-management)

## Test Environment Setup

### Prerequisites

- RailsPress application running
- Test database configured
- Admin user with administrator role
- API key generated

### Environment Configuration

```bash
# Set test environment
export RAILS_ENV=test

# Run database migrations
bundle exec rails db:migrate

# Seed test data
bundle exec rails db:seed
```

### Test User Setup

```ruby
# Create test admin user
admin_user = User.create!(
  email: 'admin@example.com',
  password: 'password',
  role: 'administrator',
  name: 'Test Admin'
)

# Generate API key
admin_user.generate_api_key!
```

## Automated Testing

### RSpec Test Suite

The main test suite is located in `spec/controllers/api/v1/mcp_controller_spec.rb`.

#### Running Tests

```bash
# Run all MCP tests
bundle exec rspec spec/controllers/api/v1/mcp_controller_spec.rb

# Run specific test
bundle exec rspec spec/controllers/api/v1/mcp_controller_spec.rb:25

# Run with coverage
COVERAGE=true bundle exec rspec spec/controllers/api/v1/mcp_controller_spec.rb
```

#### Test Categories

**1. Handshake Tests**
- Valid handshake requests
- Invalid protocol versions
- Malformed JSON-RPC requests
- Empty request bodies

**2. Tools List Tests**
- Successful tool listing
- Tool schema validation
- Response format validation

**3. Tool Call Tests**
- Successful tool execution
- Authentication requirements
- Permission checks
- Invalid tool names
- Parameter validation

**4. Resources Tests**
- Resource listing
- Resource schema validation

**5. Prompts Tests**
- Prompt listing
- Prompt argument validation

**6. Authentication Tests**
- Missing API key
- Invalid API key
- Inactive user accounts
- Permission-based access control

**7. Error Handling Tests**
- JSON parsing errors
- Tool execution errors
- Permission denied errors
- Rate limiting errors

### Test Examples

#### Handshake Test
```ruby
describe 'POST #handshake' do
  context 'with valid handshake request' do
    let(:valid_request) do
      {
        jsonrpc: '2.0',
        method: 'session/handshake',
        params: {
          protocolVersion: '2025-03-26',
          clientInfo: {
            name: 'test-client',
            version: '1.0.0'
          }
        },
        id: 1
      }
    end

    it 'returns successful handshake response' do
      post :handshake, params: valid_request, as: :json
      
      expect(response).to have_http_status(:ok)
      response_data = JSON.parse(response.body)
      expect(response_data['jsonrpc']).to eq('2.0')
      expect(response_data['result']['protocolVersion']).to eq('2025-03-26')
      expect(response_data['result']['capabilities']).to include('tools', 'resources', 'prompts')
    end
  end
end
```

#### Tool Call Test
```ruby
describe 'POST #tools_call' do
  context 'with valid API key' do
    let(:valid_request) do
      {
        jsonrpc: '2.0',
        method: 'tools/call',
        params: {
          name: 'get_posts',
          arguments: { limit: 5 }
        },
        id: 2
      }
    end

    it 'calls the tool successfully' do
      post :tools_call, params: valid_request, as: :json
      
      expect(response).to have_http_status(:ok)
      response_data = JSON.parse(response.body)
      expect(response_data['jsonrpc']).to eq('2.0')
      expect(response_data['result']).to have_key('content')
    end
  end
end
```

## Manual Testing

### Test Scripts

#### Comprehensive MCP Test
```bash
# Run comprehensive test suite
ruby test_mcp_comprehensive.rb
```

**Test Coverage:**
- Handshake protocol negotiation
- Tools discovery and listing
- Resource and prompt listing
- Tool execution with various parameters
- Error handling scenarios

#### MCP Settings Test
```bash
# Test admin settings endpoints
ruby test_mcp_settings.rb
```

**Test Coverage:**
- Settings page accessibility
- Test connection endpoint
- Generate API key endpoint
- Authentication requirements

#### Final Validation Test
```bash
# Run final comprehensive validation
ruby test_mcp_final.rb
```

**Test Coverage:**
- Complete API functionality
- Admin integration
- Settings configuration
- End-to-end workflow

### Manual Testing Procedures

#### 1. API Endpoint Testing

**Handshake Test:**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/session/handshake \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "session/handshake",
    "params": {
      "protocolVersion": "2025-03-26",
      "clientInfo": {"name": "test-client", "version": "1.0.0"}
    },
    "id": 1
  }'
```

**Expected Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "protocolVersion": "2025-03-26",
    "capabilities": ["tools", "resources", "prompts"],
    "serverInfo": {
      "name": "railspress-mcp-server",
      "version": "1.0.0"
    }
  },
  "id": 1
}
```

**Tools List Test:**
```bash
curl -X GET http://localhost:3000/api/v1/mcp/tools/list \
  -H "Accept: application/json"
```

**Tool Call Test:**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_posts",
      "arguments": {"limit": 5}
    },
    "id": 2
  }'
```

#### 2. Authentication Testing

**Missing API Key:**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "get_posts"}, "id": 1}'
```

**Expected Response:**
```json
{
  "success": false,
  "error": "API key required",
  "code": "MISSING_API_KEY"
}
```

**Invalid API Key:**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer invalid-key" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "get_posts"}, "id": 1}'
```

**Expected Response:**
```json
{
  "success": false,
  "error": "Invalid API key",
  "code": "INVALID_API_KEY"
}
```

#### 3. Permission Testing

**Test with Different User Roles:**
- Administrator: Full access
- Editor: Limited access
- Author: Basic access
- Subscriber: No access

**Permission Test Script:**
```ruby
# Test different user permissions
users = {
  admin: User.find_by(role: 'administrator'),
  editor: User.find_by(role: 'editor'),
  author: User.find_by(role: 'author')
}

users.each do |role, user|
  puts "Testing #{role} permissions..."
  # Test tool access based on role
end
```

## Integration Testing

### End-to-End Workflows

#### 1. Complete Content Management Workflow

**Step 1: Handshake**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/session/handshake \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "session/handshake", "params": {"protocolVersion": "2025-03-26", "clientInfo": {"name": "workflow-test"}}, "id": 1}'
```

**Step 2: List Available Tools**
```bash
curl -X GET http://localhost:3000/api/v1/mcp/tools/list
```

**Step 3: Create a Post**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "create_post",
      "arguments": {
        "title": "Test Post",
        "content": "This is a test post created via MCP API",
        "status": "draft"
      }
    },
    "id": 2
  }'
```

**Step 4: Retrieve the Post**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_post",
      "arguments": {"id": 1}
    },
    "id": 3
  }'
```

**Step 5: Update the Post**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "update_post",
      "arguments": {
        "id": 1,
        "title": "Updated Test Post",
        "status": "published"
      }
    },
    "id": 4
  }'
```

#### 2. Taxonomy Management Workflow

**Step 1: Get Taxonomies**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_taxonomies",
      "arguments": {}
    },
    "id": 1
  }'
```

**Step 2: Create a Category**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "create_term",
      "arguments": {
        "name": "Technology",
        "taxonomy": "category",
        "description": "Technology related posts"
      }
    },
    "id": 2
  }'
```

**Step 3: Get Terms for Category**
```bash
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_terms",
      "arguments": {
        "taxonomy": "category"
      }
    },
    "id": 3
  }'
```

### Admin Integration Testing

#### 1. Settings Page Access
```bash
# Test settings page redirects to login
curl -X GET http://localhost:3000/admin/settings/mcp
# Expected: 302 redirect to login
```

#### 2. Test Connection Feature
```bash
# Test connection endpoint (requires authentication)
curl -X POST http://localhost:3000/admin/settings/mcp/test_connection \
  -H "Content-Type: application/json"
# Expected: 422 or 302 (requires authentication)
```

#### 3. Generate API Key Feature
```bash
# Test API key generation (requires authentication)
curl -X POST http://localhost:3000/admin/settings/mcp/generate_api_key \
  -H "Content-Type: application/json"
# Expected: 422 or 302 (requires authentication)
```

## Performance Testing

### Load Testing

#### 1. Concurrent Request Testing
```ruby
# Test concurrent handshake requests
require 'concurrent'

def test_concurrent_handshakes(count = 10)
  futures = (1..count).map do |i|
    Concurrent::Future.execute do
      make_handshake_request(i)
    end
  end
  
  results = futures.map(&:value)
  puts "Completed #{results.count(&:success?)}/#{count} handshakes"
end
```

#### 2. Rate Limiting Testing
```ruby
# Test rate limiting
def test_rate_limiting
  api_key = get_test_api_key
  
  # Make requests exceeding rate limit
  (1..150).each do |i|
    response = make_tool_call_request(api_key)
    if response.code == '429'
      puts "Rate limit hit at request #{i}"
      break
    end
  end
end
```

#### 3. Response Time Testing
```ruby
# Test response times
def test_response_times
  times = []
  
  100.times do
    start_time = Time.now
    make_handshake_request
    end_time = Time.now
    times << (end_time - start_time) * 1000 # Convert to milliseconds
  end
  
  puts "Average response time: #{times.sum / times.count}ms"
  puts "95th percentile: #{times.sort[times.count * 0.95]}ms"
end
```

### Memory Usage Testing

```ruby
# Test memory usage
def test_memory_usage
  initial_memory = get_memory_usage
  
  # Make many requests
  1000.times do
    make_handshake_request
  end
  
  final_memory = get_memory_usage
  memory_increase = final_memory - initial_memory
  
  puts "Memory increase: #{memory_increase}MB"
end
```

## Security Testing

### Authentication Testing

#### 1. API Key Validation
```ruby
# Test various API key scenarios
def test_api_key_validation
  test_cases = [
    { key: nil, expected: 'MISSING_API_KEY' },
    { key: '', expected: 'MISSING_API_KEY' },
    { key: 'invalid-key', expected: 'INVALID_API_KEY' },
    { key: 'short', expected: 'INVALID_API_KEY' },
    { key: 'a' * 100, expected: 'INVALID_API_KEY' }
  ]
  
  test_cases.each do |test_case|
    response = make_request_with_key(test_case[:key])
    assert_error_code(response, test_case[:expected])
  end
end
```

#### 2. User Permission Testing
```ruby
# Test user permissions
def test_user_permissions
  users = create_test_users
  
  users.each do |user|
    api_key = user.api_key
    
    # Test tool access based on role
    tools_to_test = get_tools_for_role(user.role)
    
    tools_to_test.each do |tool|
      response = make_tool_call(api_key, tool)
      assert_success_or_permission_denied(response)
    end
  end
end
```

### Input Validation Testing

#### 1. SQL Injection Testing
```ruby
# Test for SQL injection vulnerabilities
def test_sql_injection
  malicious_inputs = [
    "'; DROP TABLE posts; --",
    "1' OR '1'='1",
    "1; DELETE FROM users; --"
  ]
  
  malicious_inputs.each do |input|
    response = make_tool_call_with_param('search', input)
    assert_no_sql_error(response)
  end
end
```

#### 2. XSS Testing
```ruby
# Test for XSS vulnerabilities
def test_xss_protection
  xss_payloads = [
    "<script>alert('xss')</script>",
    "javascript:alert('xss')",
    "<img src=x onerror=alert('xss')>"
  ]
  
  xss_payloads.each do |payload|
    response = make_tool_call_with_param('title', payload)
    assert_no_xss_in_response(response)
  end
end
```

### Rate Limiting Security Testing

```ruby
# Test rate limiting security
def test_rate_limiting_security
  # Test IP-based rate limiting
  test_ip_rate_limiting
  
  # Test user-based rate limiting
  test_user_rate_limiting
  
  # Test rate limit bypass attempts
  test_rate_limit_bypass
end

def test_ip_rate_limiting
  # Make requests from same IP
  # Should hit rate limit
end

def test_user_rate_limiting
  # Make requests with same API key
  # Should hit rate limit
end

def test_rate_limit_bypass
  # Test various bypass attempts
  # Should not be able to bypass
end
```

## Debugging

### Log Analysis

#### 1. Enable Debug Logging
```ruby
# In admin settings
SiteSetting.set('mcp_enable_debug_mode', true)
SiteSetting.set('mcp_debug_log_level', 'debug')
```

#### 2. Monitor Logs
```bash
# Monitor Rails logs
tail -f log/development.log | grep MCP

# Monitor specific endpoints
tail -f log/development.log | grep "mcp/tools/call"
```

#### 3. Log Analysis Script
```ruby
# Analyze MCP logs
def analyze_mcp_logs
  log_file = 'log/development.log'
  
  File.readlines(log_file).each do |line|
    if line.include?('MCP')
      puts line
    end
  end
end
```

### Error Investigation

#### 1. Common Error Patterns
```ruby
# Check for common error patterns
def check_error_patterns
  errors = {
    authentication: 0,
    permission: 0,
    validation: 0,
    internal: 0
  }
  
  # Analyze logs for error patterns
  # Count different error types
end
```

#### 2. Performance Bottlenecks
```ruby
# Identify performance bottlenecks
def identify_bottlenecks
  slow_requests = []
  
  # Analyze response times
  # Identify slow endpoints
  # Check database queries
end
```

### Interactive Debugging

#### 1. Rails Console Debugging
```ruby
# Debug in Rails console
rails console

# Test MCP controller directly
controller = Api::V1::McpController.new
controller.handshake

# Check site settings
SiteSetting.get('mcp_enabled')
SiteSetting.get('mcp_api_key')
```

#### 2. Request Replay
```ruby
# Replay failed requests
def replay_request(request_data)
  controller = Api::V1::McpController.new
  controller.request = create_mock_request(request_data)
  controller.response = ActionDispatch::Response.new
  
  begin
    controller.handshake
    puts "Request succeeded"
  rescue => e
    puts "Request failed: #{e.message}"
    puts e.backtrace
  end
end
```

## Test Data Management

### Test Data Setup

#### 1. Factory Definitions
```ruby
# spec/factories/mcp_test_data.rb
FactoryBot.define do
  factory :mcp_test_user do
    email { "mcp-test-#{SecureRandom.hex(4)}@example.com" }
    password { "password" }
    role { "administrator" }
    name { "MCP Test User" }
    
    after(:create) do |user|
      user.generate_api_key!
    end
  end
  
  factory :mcp_test_post do
    title { "MCP Test Post #{SecureRandom.hex(4)}" }
    content { "This is a test post for MCP testing" }
    status { "published" }
    association :author, factory: :mcp_test_user
  end
end
```

#### 2. Test Data Cleanup
```ruby
# Clean up test data
def cleanup_test_data
  # Remove test users
  User.where("email LIKE ?", "mcp-test-%").destroy_all
  
  # Remove test posts
  Post.where("title LIKE ?", "MCP Test Post%").destroy_all
  
  # Reset site settings
  SiteSetting.where("key LIKE ?", "mcp_%").destroy_all
end
```

### Test Environment Isolation

#### 1. Database Isolation
```ruby
# Use transactions for test isolation
RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
```

#### 2. API Key Management
```ruby
# Manage test API keys
class McpTestHelper
  def self.create_test_api_key
    user = FactoryBot.create(:mcp_test_user)
    user.api_key
  end
  
  def self.cleanup_test_api_keys
    User.where("email LIKE ?", "mcp-test-%").destroy_all
  end
end
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/mcp-tests.yml
name: MCP Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.2.0
        
    - name: Install dependencies
      run: |
        bundle install
        
    - name: Set up test database
      run: |
        bundle exec rails db:create
        bundle exec rails db:migrate
        bundle exec rails db:seed
        
    - name: Run MCP tests
      run: |
        bundle exec rspec spec/controllers/api/v1/mcp_controller_spec.rb
        
    - name: Run manual tests
      run: |
        ruby test_mcp_comprehensive.rb
        ruby test_mcp_final.rb
```

### Test Reporting

#### 1. Coverage Reports
```ruby
# Generate coverage reports
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/test/'
  
  add_group 'MCP', 'app/controllers/api/v1/mcp_controller.rb'
  add_group 'MCP Admin', 'app/controllers/admin/mcp_settings_controller.rb'
end
```

#### 2. Test Results
```ruby
# Generate test results
def generate_test_report
  results = {
    total_tests: 0,
    passed_tests: 0,
    failed_tests: 0,
    coverage: 0
  }
  
  # Run tests and collect results
  # Generate HTML report
end
```

This comprehensive testing guide provides all the tools and procedures needed to thoroughly test the MCP implementation, ensuring reliability, security, and performance.


