require "test_helper"

class Admin::AiProvidersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @ai_provider = ai_providers(:one)
    sign_in @user
  end

  test "should get index" do
    get admin_ai_providers_url
    assert_response :success
    assert_select "h1", "AI Providers"
  end

  test "should get new" do
    get new_admin_ai_provider_url
    assert_response :success
    assert_select "h1", "New AI Provider"
  end

  test "should create ai_provider" do
    assert_difference("AiProvider.count") do
      post admin_ai_providers_url, params: { 
        ai_provider: { 
          name: "Test Provider",
          provider_type: "openai",
          api_key: "sk-test-key-123456789",
          model_identifier: "gpt-4",
          max_tokens: 4000,
          temperature: 0.7,
          active: true
        } 
      }
    end

    assert_redirected_to admin_ai_provider_url(AiProvider.last)
    assert_equal "AI Provider was successfully created.", flash[:notice]
  end

  test "should not create ai_provider with invalid data" do
    assert_no_difference("AiProvider.count") do
      post admin_ai_providers_url, params: { 
        ai_provider: { 
          name: "",
          provider_type: "invalid_type",
          api_key: "",
          model_identifier: ""
        } 
      }
    end

    assert_response :unprocessable_entity
    assert_template :new
  end

  test "should show ai_provider" do
    get admin_ai_provider_url(@ai_provider)
    assert_response :success
    assert_select "h1", @ai_provider.name
  end

  test "should get edit" do
    get edit_admin_ai_provider_url(@ai_provider)
    assert_response :success
    assert_select "h1", "Edit AI Provider"
  end

  test "should update ai_provider" do
    patch admin_ai_provider_url(@ai_provider), params: { 
      ai_provider: { 
        name: "Updated Provider",
        max_tokens: 8000,
        temperature: 0.5
      } 
    }
    
    assert_redirected_to admin_ai_provider_url(@ai_provider)
    assert_equal "AI Provider was successfully updated.", flash[:notice]
    
    @ai_provider.reload
    assert_equal "Updated Provider", @ai_provider.name
    assert_equal 8000, @ai_provider.max_tokens
    assert_equal 0.5, @ai_provider.temperature
  end

  test "should not update ai_provider with invalid data" do
    patch admin_ai_provider_url(@ai_provider), params: { 
      ai_provider: { 
        name: "",
        provider_type: "invalid_type",
        max_tokens: -1,
        temperature: 2.5
      } 
    }
    
    assert_response :unprocessable_entity
    assert_template :edit
  end

  test "should destroy ai_provider" do
    assert_difference("AiProvider.count", -1) do
      delete admin_ai_provider_url(@ai_provider)
    end

    assert_redirected_to admin_ai_providers_url
    assert_equal "AI Provider was successfully deleted.", flash[:notice]
  end

  test "should not destroy ai_provider with active agents" do
    # Create an agent for this provider
    @ai_provider.ai_agents.create!(
      name: "Test Agent",
      agent_type: "content_summarizer",
      prompt: "Test prompt"
    )
    
    assert_no_difference("AiProvider.count") do
      delete admin_ai_provider_url(@ai_provider)
    end

    assert_redirected_to admin_ai_providers_url
    assert_equal "Cannot delete provider with active agents.", flash[:alert]
  end

  test "should toggle ai_provider active status" do
    patch toggle_admin_ai_provider_url(@ai_provider)
    
    assert_redirected_to admin_ai_providers_url
    
    @ai_provider.reload
    assert_not @ai_provider.active
    
    patch toggle_admin_ai_provider_url(@ai_provider)
    @ai_provider.reload
    assert @ai_provider.active
  end

  test "should require authentication" do
    sign_out @user
    
    get admin_ai_providers_url
    assert_redirected_to new_user_session_url
  end

  test "should require admin role for non-admin users" do
    regular_user = users(:user)
    sign_in regular_user
    
    get admin_ai_providers_url
    assert_redirected_to root_url
    assert_equal "Access denied.", flash[:alert]
  end

  test "should filter providers by type" do
    openai_provider = ai_providers(:openai)
    cohere_provider = ai_providers(:cohere)
    
    get admin_ai_providers_url, params: { provider_type: "openai" }
    assert_response :success
    assert_select ".provider-row", count: 1
    assert_select ".provider-name", openai_provider.name
  end

  test "should filter providers by active status" do
    active_provider = ai_providers(:active)
    inactive_provider = ai_providers(:inactive)
    
    get admin_ai_providers_url, params: { active: "true" }
    assert_response :success
    assert_select ".provider-row", count: 1
    assert_select ".provider-name", active_provider.name
  end

  test "should search providers by name" do
    search_term = @ai_provider.name.split.first
    
    get admin_ai_providers_url, params: { search: search_term }
    assert_response :success
    assert_select ".provider-row", count: 1
    assert_select ".provider-name", @ai_provider.name
  end

  test "should handle bulk actions" do
    provider_ids = [ai_providers(:one).id, ai_providers(:two).id]
    
    post admin_bulk_action_ai_providers_url, params: {
      bulk_action: "activate",
      provider_ids: provider_ids
    }
    
    assert_redirected_to admin_ai_providers_url
    assert_equal "Providers were successfully updated.", flash[:notice]
    
    ai_providers(:one).reload
    ai_providers(:two).reload
    assert ai_providers(:one).active
    assert ai_providers(:two).active
  end

  test "should handle bulk deactivate" do
    provider_ids = [ai_providers(:one).id, ai_providers(:two).id]
    
    post admin_bulk_action_ai_providers_url, params: {
      bulk_action: "deactivate",
      provider_ids: provider_ids
    }
    
    assert_redirected_to admin_ai_providers_url
    assert_equal "Providers were successfully updated.", flash[:notice]
    
    ai_providers(:one).reload
    ai_providers(:two).reload
    assert_not ai_providers(:one).active
    assert_not ai_providers(:two).active
  end

  test "should test provider connection" do
    post test_admin_ai_provider_url(@ai_provider)
    
    assert_response :success
    assert_equal "application/json", response.content_type
    
    response_data = JSON.parse(response.body)
    assert_includes ["success", "error"], response_data["status"]
  end

  test "should export providers" do
    get export_admin_ai_providers_url, params: { format: :csv }
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_includes response.body, @ai_provider.name
  end

  test "should import providers" do
    csv_content = "name,provider_type,api_key,model_identifier\nImported Provider,openai,sk-imported,gpt-4"
    
    post import_admin_ai_providers_url, params: {
      file: fixture_file_upload("ai_providers.csv", "text/csv")
    }
    
    assert_redirected_to admin_ai_providers_url
    assert_equal "Providers were successfully imported.", flash[:notice]
  end

  test "should handle ajax requests" do
    get admin_ai_providers_url, xhr: true
    assert_response :success
    assert_equal "text/javascript", response.content_type
  end

  test "should handle pagination" do
    # Create multiple providers to test pagination
    15.times do |i|
      AiProvider.create!(
        name: "Provider #{i}",
        provider_type: "openai",
        api_key: "sk-key-#{i}",
        model_identifier: "gpt-4"
      )
    end
    
    get admin_ai_providers_url, params: { page: 2 }
    assert_response :success
  end

  test "should handle sorting" do
    get admin_ai_providers_url, params: { sort: "name", direction: "asc" }
    assert_response :success
  end

  test "should handle invalid sort parameters" do
    get admin_ai_providers_url, params: { sort: "invalid_column", direction: "invalid_direction" }
    assert_response :success
  end

  test "should validate provider types" do
    valid_types = %w[openai cohere anthropic google]
    
    valid_types.each do |type|
      post admin_ai_providers_url, params: { 
        ai_provider: { 
          name: "Test #{type}",
          provider_type: type,
          api_key: "test-key",
          model_identifier: "test-model"
        } 
      }
      
      assert_response :redirect
      assert_equal "AI Provider was successfully created.", flash[:notice]
    end
  end

  test "should reject invalid provider types" do
    post admin_ai_providers_url, params: { 
      ai_provider: { 
        name: "Invalid Provider",
        provider_type: "invalid_type",
        api_key: "test-key",
        model_identifier: "test-model"
      } 
    }
    
    assert_response :unprocessable_entity
    assert_includes response.body, "Provider type is not included in the list"
  end

  test "should validate max_tokens range" do
    post admin_ai_providers_url, params: { 
      ai_provider: { 
        name: "Test Provider",
        provider_type: "openai",
        api_key: "test-key",
        model_identifier: "gpt-4",
        max_tokens: -1
      } 
    }
    
    assert_response :unprocessable_entity
    assert_includes response.body, "Max tokens must be greater than 0"
  end

  test "should validate temperature range" do
    post admin_ai_providers_url, params: { 
      ai_provider: { 
        name: "Test Provider",
        provider_type: "openai",
        api_key: "test-key",
        model_identifier: "gpt-4",
        temperature: 2.5
      } 
    }
    
    assert_response :unprocessable_entity
    assert_includes response.body, "Temperature must be between 0 and 2"
  end

  test "should handle api_url validation" do
    post admin_ai_providers_url, params: { 
      ai_provider: { 
        name: "Test Provider",
        provider_type: "openai",
        api_key: "test-key",
        model_identifier: "gpt-4",
        api_url: "invalid-url"
      } 
    }
    
    assert_response :unprocessable_entity
    assert_includes response.body, "Api url must be a valid URL"
  end

  test "should allow nil api_url" do
    post admin_ai_providers_url, params: { 
      ai_provider: { 
        name: "Test Provider",
        provider_type: "openai",
        api_key: "test-key",
        model_identifier: "gpt-4",
        api_url: nil
      } 
    }
    
    assert_response :redirect
    assert_equal "AI Provider was successfully created.", flash[:notice]
  end

  test "should mask api_key in views" do
    get admin_ai_provider_url(@ai_provider)
    assert_response :success
    
    # API key should be masked in the view
    assert_not_includes response.body, @ai_provider.api_key
    assert_includes response.body, "sk-****"
  end

  test "should show associated agents count" do
    # Create agents for this provider
    3.times do |i|
      @ai_provider.ai_agents.create!(
        name: "Agent #{i}",
        agent_type: "content_summarizer",
        prompt: "Test prompt"
      )
    end
    
    get admin_ai_provider_url(@ai_provider)
    assert_response :success
    assert_includes response.body, "3 agents"
  end

  test "should handle provider position changes" do
    patch admin_ai_provider_url(@ai_provider), params: { 
      ai_provider: { 
        position: 5
      } 
    }
    
    assert_redirected_to admin_ai_provider_url(@ai_provider)
    @ai_provider.reload
    assert_equal 5, @ai_provider.position
  end
end


