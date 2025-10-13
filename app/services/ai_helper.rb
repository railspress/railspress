class AiHelper
  class << self
    # Execute an AI agent by type
    def execute_agent(agent_type, user_input = "", context = {})
      agent = AiAgent.active.find_by(agent_type: agent_type)
      return { success: false, error: "No active agent found for type: #{agent_type}" } unless agent
      
      begin
        result = agent.execute(user_input, context)
        { success: true, result: result, agent: agent }
      rescue => e
        { success: false, error: e.message }
      end
    end
    
    # Generate content using the Post Writer agent
    def generate_post_content(topic, tone = "professional", additional_context = {})
      context = {
        tone: tone,
        target_audience: additional_context[:target_audience] || "general audience",
        word_count: additional_context[:word_count] || "800-1200",
        keywords: additional_context[:keywords] || ""
      }.merge(additional_context)
      
      execute_agent('post_writer', topic, context)
    end
    
    # Summarize content using the Content Summarizer agent
    def summarize_content(content, summary_length = "medium")
      context = {
        content: content,
        length: summary_length
      }
      
      execute_agent('content_summarizer', content, context)
    end
    
    # Analyze comments using the Comments Analyzer agent
    def analyze_comments(comments)
      context = {
        comments: comments
      }
      
      execute_agent('comments_analyzer', comments, context)
    end
    
    # Analyze SEO using the SEO Analyzer agent
    def analyze_seo(content, target_keywords = [])
      context = {
        content: content,
        target_keywords: target_keywords.join(', '),
        url: content[:url] if content.is_a?(Hash),
        title: content[:title] if content.is_a?(Hash)
      }
      
      execute_agent('seo_analyzer', content.is_a?(Hash) ? content[:content] || content[:text] : content, context)
    end
    
    # Get available agent types
    def available_agents
      AiAgent.active.pluck(:agent_type).uniq
    end
    
    # Check if an agent type is available
    def agent_available?(agent_type)
      AiAgent.active.exists?(agent_type: agent_type)
    end
    
    # Get agent info
    def agent_info(agent_type)
      agent = AiAgent.active.find_by(agent_type: agent_type)
      return nil unless agent
      
      {
        id: agent.id,
        name: agent.name,
        description: agent.description,
        provider: agent.ai_provider.name,
        model: agent.ai_provider.model_identifier
      }
    end
  end
end


