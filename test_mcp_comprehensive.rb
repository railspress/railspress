#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class McpTester
  def initialize(base_url = 'http://localhost:3000')
    @base_url = base_url
    @session_id = nil
  end

  def test_handshake
    puts "🔌 Testing MCP Handshake..."
    
    uri = URI("#{@base_url}/api/v1/mcp/session/handshake")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    
    payload = {
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
    
    request.body = payload.to_json
    
    response = http.request(request)
    
    puts "Status: #{response.code}"
    puts "Response: #{response.body}"
    
    if response.code == '200'
      data = JSON.parse(response.body)
      if data['result'] && data['result']['capabilities']
        puts "✅ Handshake successful!"
        puts "Capabilities: #{data['result']['capabilities'].join(', ')}"
        return true
      else
        puts "❌ Handshake failed - invalid response format"
        return false
      end
    else
      puts "❌ Handshake failed - HTTP #{response.code}"
      return false
    end
  end

  def test_tools_list
    puts "\n🛠️  Testing Tools List..."
    
    uri = URI("#{@base_url}/api/v1/mcp/tools/list")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    
    response = http.request(request)
    
    puts "Status: #{response.code}"
    puts "Response: #{response.body}"
    
    if response.code == '200'
      data = JSON.parse(response.body)
      if data['result'] && data['result']['tools']
        puts "✅ Tools list successful!"
        puts "Available tools: #{data['result']['tools'].length}"
        data['result']['tools'].each do |tool|
          puts "  - #{tool['name']}: #{tool['description']}"
        end
        return true
      else
        puts "❌ Tools list failed - invalid response format"
        return false
      end
    else
      puts "❌ Tools list failed - HTTP #{response.code}"
      return false
    end
  end

  def test_tools_call
    puts "\n⚡ Testing Tools Call..."
    
    uri = URI("#{@base_url}/api/v1/mcp/tools/call")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Authorization'] = 'Bearer test-api-key' # We'll need a real API key
    
    payload = {
      jsonrpc: '2.0',
      method: 'tools/call',
      params: {
        name: 'get_posts',
        arguments: {
          limit: 5
        }
      },
      id: 2
    }
    
    request.body = payload.to_json
    
    response = http.request(request)
    
    puts "Status: #{response.code}"
    puts "Response: #{response.body}"
    
    if response.code == '200'
      data = JSON.parse(response.body)
      if data['result']
        puts "✅ Tools call successful!"
        return true
      else
        puts "❌ Tools call failed - invalid response format"
        return false
      end
    else
      puts "❌ Tools call failed - HTTP #{response.code}"
      return false
    end
  end

  def test_resources_list
    puts "\n📚 Testing Resources List..."
    
    uri = URI("#{@base_url}/api/v1/mcp/resources/list")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    
    response = http.request(request)
    
    puts "Status: #{response.code}"
    puts "Response: #{response.body}"
    
    if response.code == '200'
      puts "✅ Resources list successful!"
      return true
    else
      puts "❌ Resources list failed - HTTP #{response.code}"
      return false
    end
  end

  def test_prompts_list
    puts "\n💬 Testing Prompts List..."
    
    uri = URI("#{@base_url}/api/v1/mcp/prompts/list")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    
    response = http.request(request)
    
    puts "Status: #{response.code}"
    puts "Response: #{response.body}"
    
    if response.code == '200'
      puts "✅ Prompts list successful!"
      return true
    else
      puts "❌ Prompts list failed - HTTP #{response.code}"
      return false
    end
  end

  def run_all_tests
    puts "🚀 Starting Comprehensive MCP API Tests\n"
    
    results = []
    results << test_handshake
    results << test_tools_list
    results << test_resources_list
    results << test_prompts_list
    # Skip tools_call for now since it requires authentication
    
    puts "\n📊 Test Results Summary:"
    puts "Handshake: #{results[0] ? '✅ PASS' : '❌ FAIL'}"
    puts "Tools List: #{results[1] ? '✅ PASS' : '❌ FAIL'}"
    puts "Resources List: #{results[2] ? '✅ PASS' : '❌ FAIL'}"
    puts "Prompts List: #{results[3] ? '✅ PASS' : '❌ FAIL'}"
    
    passed = results.count(true)
    total = results.length
    
    puts "\n🎯 Overall: #{passed}/#{total} tests passed"
    
    if passed == total
      puts "🎉 All tests passed! MCP API is working correctly."
    else
      puts "⚠️  Some tests failed. Check the output above for details."
    end
    
    return passed == total
  end
end

# Run the tests
if __FILE__ == $0
  tester = McpTester.new
  success = tester.run_all_tests
  exit(success ? 0 : 1)
end


