require 'test_helper'

class AiUsageTest < ActiveSupport::TestCase
  setup do
    @ai_agent = ai_agents(:content_summarizer)
    @user = users(:admin)
  end

  test "should be valid" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    assert usage.valid?
  end

  test "should require ai_agent" do
    usage = AiUsage.new(
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:ai_agent], "must exist"
  end

  test "should require user" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:user], "must exist"
  end

  test "should require prompt" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:prompt], "can't be blank"
  end

  test "should require tokens_used" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:tokens_used], "can't be blank"
  end

  test "should require cost" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      response_time: 1.5,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:cost], "can't be blank"
  end

  test "should require response_time" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:response_time], "can't be blank"
  end

  test "should require success" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: nil
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:success], "is not included in the list"
  end

  test "should validate tokens_used is greater than 0" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 0,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:tokens_used], "must be greater than 0"
  end

  test "should validate cost is greater than or equal to 0" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: -0.001,
      response_time: 1.5,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:cost], "must be greater than or equal to 0"
  end

  test "should validate response_time is greater than 0" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 0,
      success: true
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:response_time], "must be greater than 0"
  end

  test "should validate success is boolean" do
    usage = AiUsage.new(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: nil
    )
    
    assert_not usage.valid?
    assert_includes usage.errors[:success], "is not included in the list"
  end

  test "should belong to ai_agent" do
    usage = AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    assert_equal @ai_agent, usage.ai_agent
  end

  test "should belong to user" do
    usage = AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    assert_equal @user, usage.user
  end

  test "should scope successful usages" do
    successful_usage = AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    failed_usage = AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: nil,
      tokens_used: 50,
      cost: 0.0,
      response_time: 1.0,
      success: false,
      error_message: "Test error"
    )
    
    successful_usages = AiUsage.successful
    
    assert_includes successful_usages, successful_usage
    assert_not_includes successful_usages, failed_usage
  end

  test "should scope failed usages" do
    successful_usage = AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: "Test response",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    failed_usage = AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt",
      response: nil,
      tokens_used: 50,
      cost: 0.0,
      response_time: 1.0,
      success: false,
      error_message: "Test error"
    )
    
    failed_usages = AiUsage.failed
    
    assert_includes failed_usages, failed_usage
    assert_not_includes failed_usages, successful_usage
  end

  test "should scope usages by agent" do
    other_agent = ai_agents(:post_writer)
    
    usage1 = AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 1",
      response: "Test response 1",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true
    )
    
    usage2 = AiUsage.create!(
      ai_agent: other_agent,
      user: @user,
      prompt: "Test prompt 2",
      response: "Test response 2",
      tokens_used: 150,
      cost: 0.002,
      response_time: 2.0,
      success: true
    )
    
    agent_usages = AiUsage.by_agent(@ai_agent)
    
    assert_includes agent_usages, usage1
    assert_not_includes agent_usages, usage2
  end

  test "should calculate total tokens for period" do
    # Create usages with different dates
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 1",
      response: "Test response 1",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true,
      created_at: 1.day.ago
    )
    
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 2",
      response: "Test response 2",
      tokens_used: 150,
      cost: 0.002,
      response_time: 2.0,
      success: true,
      created_at: 2.days.ago
    )
    
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 3",
      response: "Test response 3",
      tokens_used: 200,
      cost: 0.003,
      response_time: 2.5,
      success: true,
      created_at: 1.week.ago
    )
    
    start_date = 3.days.ago
    end_date = 1.day.ago
    
    total_tokens = AiUsage.total_tokens_for_period(start_date, end_date)
    
    assert_equal 250, total_tokens # 100 + 150
  end

  test "should calculate total cost for period" do
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 1",
      response: "Test response 1",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true,
      created_at: 1.day.ago
    )
    
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 2",
      response: "Test response 2",
      tokens_used: 150,
      cost: 0.002,
      response_time: 2.0,
      success: true,
      created_at: 2.days.ago
    )
    
    start_date = 3.days.ago
    end_date = 1.day.ago
    
    total_cost = AiUsage.total_cost_for_period(start_date, end_date)
    
    assert_equal 0.003, total_cost
  end

  test "should calculate average response time for period" do
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 1",
      response: "Test response 1",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true,
      created_at: 1.day.ago
    )
    
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 2",
      response: "Test response 2",
      tokens_used: 150,
      cost: 0.002,
      response_time: 2.0,
      success: true,
      created_at: 2.days.ago
    )
    
    start_date = 3.days.ago
    end_date = 1.day.ago
    
    avg_response_time = AiUsage.average_response_time_for_period(start_date, end_date)
    
    assert_equal 1.75, avg_response_time
  end

  test "should calculate success rate for period" do
    # Create successful usage
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 1",
      response: "Test response 1",
      tokens_used: 100,
      cost: 0.001,
      response_time: 1.5,
      success: true,
      created_at: 1.day.ago
    )
    
    # Create failed usage
    AiUsage.create!(
      ai_agent: @ai_agent,
      user: @user,
      prompt: "Test prompt 2",
      response: nil,
      tokens_used: 50,
      cost: 0.0,
      response_time: 1.0,
      success: false,
      error_message: "Test error",
      created_at: 2.days.ago
    )
    
    start_date = 3.days.ago
    end_date = 1.day.ago
    
    success_rate = AiUsage.success_rate_for_period(start_date, end_date)
    
    assert_equal 50.0, success_rate # 1 successful out of 2 total
  end
end
