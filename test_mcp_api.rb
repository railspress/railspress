#!/usr/bin/env ruby
# Test script for MCP endpoints

require 'net/http'
require 'json'
require 'uri'

class McpTester
  def initialize(base_url = 'http://localhost:3000')
    @base_url = base_url
    @session_id = nil
  end
  
  def test_handshake
    puts "Testing handshake..."
    
    request_data = {
      jsonrpc: '2.0',
      method: 'session/handshake',
      params: {
        protocolVersion: '2025-03-26',
        clientInfo: {
          name: 'mcp-tester',
          version: '1.0.0'
        }
      },
      id: 1
    }
    
    response = make_request('POST', '/api/v1/mcp/session/handshake', request_data)
    
    if response['jsonrpc'] == '2.0' && response['result']
      puts "✅ Handshake successful"
      puts "   Server: #{response['result']['serverInfo']['name']} v#{response['result']['serverInfo']['version']}"
      puts "   Capabilities: #{response['result']['capabilities'].join(', ')}"
      @session_id = response['id']
      return true
    else
      puts "❌ Handshake failed: #{response}"
      return false
    end
  end
  
  def test_tools_list
    puts "\nTesting tools list..."
    
    response = make_request('GET', '/api/v1/mcp/tools/list')
    
    if response['jsonrpc'] == '2.0' && response['result']['tools']
      tools = response['result']['tools']
      puts "✅ Tools list retrieved (#{tools.length} tools)"
      
      # Show first few tools
      tools.first(5).each do |tool|
        puts "   - #{tool['name']}: #{tool['description']}"
      end
      
      if tools.length > 5
        puts "   ... and #{tools.length - 5} more tools"
      end
      
      return true
    else
      puts "❌ Tools list failed: #{response}"
      return false
    end
  end
  
  def test_tools_call
    puts "\nTesting tools call..."
    
    # Test get_system_info (no auth required)
    request_data = {
      jsonrpc: '2.0',
      method: 'tools/call',
      params: {
        name: 'get_system_info',
        arguments: {}
      },
      id: 3
    }
    
    response = make_request('POST', '/api/v1/mcp/tools/call', request_data)
    
    if response['jsonrpc'] == '2.0' && response['result']
      system_info = response['result']['content'][0]['data']['system']
      puts "✅ System info retrieved"
      puts "   Name: #{system_info['name']}"
      puts "   Version: #{system_info['version']}"
      puts "   Rails: #{system_info['rails_version']}"
      puts "   Ruby: #{system_info['ruby_version']}"
      puts "   Environment: #{system_info['environment']}"
      puts "   Posts: #{system_info['statistics']['posts_count']}"
      puts "   Pages: #{system_info['statistics']['pages_count']}"
      puts "   Users: #{system_info['statistics']['users_count']}"
      return true
    else
      puts "❌ Tools call failed: #{response}"
      return false
    end
  end
  
  def test_resources_list
    puts "\nTesting resources list..."
    
    response = make_request('GET', '/api/v1/mcp/resources/list')
    
    if response['jsonrpc'] == '2.0' && response['result']['resources']
      resources = response['result']['resources']
      puts "✅ Resources list retrieved (#{resources.length} resources)"
      
      resources.each do |resource|
        puts "   - #{resource['name']}: #{resource['uri']}"
      end
      
      return true
    else
      puts "❌ Resources list failed: #{response}"
      return false
    end
  end
  
  def test_prompts_list
    puts "\nTesting prompts list..."
    
    response = make_request('GET', '/api/v1/mcp/prompts/list')
    
    if response['jsonrpc'] == '2.0' && response['result']['prompts']
      prompts = response['result']['prompts']
      puts "✅ Prompts list retrieved (#{prompts.length} prompts)"
      
      prompts.each do |prompt|
        puts "   - #{prompt['name']}: #{prompt['description']}"
      end
      
      return true
    else
      puts "❌ Prompts list failed: #{response}"
      return false
    end
  end
  
  def test_error_handling
    puts "\nTesting error handling..."
    
    # Test invalid protocol version
    request_data = {
      jsonrpc: '2.0',
      method: 'session/handshake',
      params: {
        protocolVersion: '2024-01-01', # Invalid version
        clientInfo: {
          name: 'test-client',
          version: '1.0.0'
        }
      },
      id: 99
    }
    
    response = make_request('POST', '/api/v1/mcp/session/handshake', request_data)
    
    if response['jsonrpc'] == '2.0' && response['error']
      puts "✅ Error handling works"
      puts "   Error code: #{response['error']['code']}"
      puts "   Error message: #{response['error']['message']}"
      return true
    else
      puts "❌ Error handling failed: #{response}"
      return false
    end
  end
  
  def run_all_tests
    puts "🚀 Starting MCP API Tests"
    puts "=" * 50
    
    tests = [
      :test_handshake,
      :test_tools_list,
      :test_tools_call,
      :test_resources_list,
      :test_prompts_list,
      :test_error_handling
    ]
    
    passed = 0
    total = tests.length
    
    tests.each do |test|
      begin
        if send(test)
          passed += 1
        end
      rescue => e
        puts "❌ #{test} failed with exception: #{e.message}"
      end
    end
    
    puts "\n" + "=" * 50
    puts "📊 Test Results: #{passed}/#{total} tests passed"
    
    if passed == total
      puts "🎉 All tests passed! MCP API is working correctly."
    else
      puts "⚠️  Some tests failed. Check the output above for details."
    end
    
    passed == total
  end
  
  private
  
  def make_request(method, path, data = nil)
    uri = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    
    case method.upcase
    when 'GET'
      request = Net::HTTP::Get.new(uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = data.to_json if data
    end
    
    response = http.request(request)
    
    if response.body && !response.body.empty?
      JSON.parse(response.body)
    else
      { 'error' => 'Empty response', 'code' => response.code }
    end
  rescue => e
    { 'error' => e.message }
  end
end

# Run tests if this script is executed directly
if __FILE__ == $0
  base_url = ARGV[0] || 'http://localhost:3000'
  tester = McpTester.new(base_url)
  success = tester.run_all_tests
  exit(success ? 0 : 1)
end


