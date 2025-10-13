# AI Agents System Guide

RailsPress includes a comprehensive AI Agents system that allows you to integrate various AI providers and create custom agents for content generation, analysis, and optimization.

## Overview

The AI system consists of:
- **AI Providers**: Configure different AI services (OpenAI, Cohere, Anthropic, Google)
- **AI Agents**: Custom agents with specific prompts and behaviors
- **API Endpoints**: RESTful API for calling agents
- **UI Integration**: Reusable popup for content generation
- **Helper Services**: Easy-to-use Ruby classes for AI operations

## Setup

### 1. Configure AI Providers

Navigate to **AI Agents > Providers** in the admin panel to set up your AI providers:

1. **OpenAI GPT-4o**
   - API Key: Your OpenAI API key
   - Model: `gpt-4o`
   - Max Tokens: 4000
   - Temperature: 0.7

2. **Cohere Command R+**
   - API Key: Your Cohere API key
   - Model: `command-r-plus`
   - Max Tokens: 4000
   - Temperature: 0.7

3. **Anthropic Claude 3.5 Sonnet**
   - API Key: Your Anthropic API key
   - Model: `claude-3-5-sonnet-20241022`
   - Max Tokens: 4000
   - Temperature: 0.7

4. **Google Gemini 1.5 Pro**
   - API Key: Your Google API key
   - Model: `gemini-1.5-pro`
   - Max Tokens: 4000
   - Temperature: 0.7

### 2. Default Agents

The system comes with 4 pre-configured agents:

1. **Content Summarizer**
   - Summarizes long content into concise summaries
   - Reduces content by 70-80% while preserving key information

2. **Post Writer**
   - Creates engaging, SEO-friendly blog posts
   - Supports different tones and styles
   - Includes keyword optimization

3. **Comments Analyzer**
   - Analyzes comment sentiment and themes
   - Identifies engagement patterns
   - Provides actionable insights

4. **SEO Analyzer**
   - Analyzes content for SEO opportunities
   - Provides keyword and structure recommendations
   - Suggests improvements for search visibility

## Usage

### Using the AI Popup in Admin UI

The AI Assistant button is automatically added to content editors in:
- Post creation/editing forms
- Page creation/editing forms

**To use:**
1. Click the "AI Assistant" button next to any content editor
2. Select the desired AI agent
3. Enter your input/prompt
4. Configure options (tone, word count, keywords)
5. Click "Generate Content"
6. Review and insert the generated content

### Using AI Agents in Code

#### Basic Usage with AiHelper

```ruby
# Generate a blog post
result = AiHelper.generate_post_content(
  "How to use AI in content marketing",
  tone: "professional",
  additional_context: {
    target_audience: "marketers",
    word_count: "1000-1500",
    keywords: "AI, content marketing, automation"
  }
)

if result[:success]
  puts result[:result]
else
  puts "Error: #{result[:error]}"
end

# Summarize content
result = AiHelper.summarize_content(long_content, "medium")

# Analyze SEO
result = AiHelper.analyze_seo(content, ["keyword1", "keyword2"])
```

#### Direct Agent Usage

```ruby
# Find and execute an agent directly
agent = AiAgent.active.find_by(agent_type: 'post_writer')
result = agent.execute("Write about sustainable energy", {
  tone: "informative",
  target_audience: "general public"
})
```

### API Usage

#### Execute Agent by Type

```bash
POST /api/v1/ai_agents/execute/post_writer
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "user_input": "Write about sustainable energy",
  "context": {
    "tone": "professional",
    "word_count": "800-1200",
    "keywords": "sustainable, energy, green"
  }
}
```

#### Execute Specific Agent

```bash
POST /api/v1/ai_agents/execute
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN

{
  "agent_id": 1,
  "user_input": "Summarize this content",
  "context": {
    "content": "Your long content here..."
  }
}
```

### Adding AI to Custom Forms

To add AI assistance to any form:

```erb
<!-- In your form -->
<div>
  <%= ai_content_editor_label(form, :content, "Your Content") if ai_agents_available? %>
  <%= form.text_area :content %>
</div>

<!-- At the end of your form -->
<%= ai_popup_modal if ai_agents_available? %>
```

Or use individual helpers:

```erb
<!-- Just the button -->
<%= ai_assistant_button %>

<!-- Just the modal -->
<%= ai_popup_modal %>
```

## Creating Custom Agents

### 1. Create a New Agent

Navigate to **AI Agents > Agents** and click "Add Agent":

- **Name**: Descriptive name for your agent
- **Description**: What the agent does
- **Agent Type**: Choose from predefined types or create custom ones
- **Provider**: Select which AI provider to use
- **Prompt**: Main instructions for the AI
- **Content**: Content guidelines
- **Guidelines**: Additional guidelines
- **Rules**: Specific rules to follow
- **Tasks**: Step-by-step tasks
- **Master Prompt**: High-level instructions (optional)

### 2. Agent Type Configuration

The system supports these agent types:
- `content_summarizer`
- `post_writer`
- `comments_analyzer`
- `seo_analyzer`

To add custom types, update the `AGENT_TYPES` constant in the `AiAgent` model.

### 3. Prompt Engineering

The agent combines multiple prompt components in this order:
1. Master Prompt (highest priority)
2. Agent Prompt
3. Content Guidelines
4. Guidelines
5. Rules
6. Tasks
7. User Input
8. Context

Example prompt structure:
```
You are an expert content strategist and writer with expertise in digital marketing and SEO optimization.

You are a professional content writer specializing in engaging, SEO-optimized blog posts. Create compelling content that resonates with readers.

Content Guidelines:
Write in the specified tone and style. Include relevant keywords naturally. Structure content with clear headings and subheadings.

Guidelines:
Use active voice when possible. Include engaging introductions and strong conclusions. Add relevant examples and case studies.

Rules:
Ensure all content is original and plagiarism-free. Maintain consistent tone throughout. Include a clear call-to-action.

Tasks:
1. Analyze the topic and requirements
2. Research key points and supporting evidence
3. Create an engaging introduction
4. Develop main content with clear structure
5. Write a compelling conclusion
6. Optimize for SEO

User Input: Write about sustainable energy

Context:
tone: professional
target_audience: general public
word_count: 800-1200
keywords: sustainable, energy, green
```

## Best Practices

### 1. Provider Management
- Keep API keys secure and rotate them regularly
- Monitor usage and costs
- Use different providers for different use cases
- Set appropriate temperature and token limits

### 2. Agent Design
- Write clear, specific prompts
- Test agents thoroughly before deploying
- Use master prompts for high-level instructions
- Keep guidelines focused and actionable

### 3. Error Handling
- Always check for errors in API responses
- Provide fallbacks for failed requests
- Log errors for debugging
- Inform users of issues gracefully

### 4. Performance
- Cache frequently used results
- Use appropriate token limits
- Batch requests when possible
- Monitor response times

## Troubleshooting

### Common Issues

1. **"No active agent found"**
   - Ensure at least one agent is marked as active
   - Check that the agent type matches the request

2. **API key errors**
   - Verify API keys are correct and valid
   - Check provider status and billing

3. **Content not generating**
   - Check agent prompts and configuration
   - Verify input format and context
   - Test with simpler inputs first

4. **Poor quality results**
   - Refine agent prompts
   - Adjust temperature settings
   - Provide more specific context

### Debugging

Enable logging in your Rails application:

```ruby
# In config/environments/development.rb
config.log_level = :debug
```

Check the Rails logs for detailed error messages and API responses.

## Security Considerations

1. **API Key Protection**
   - Store API keys securely
   - Use environment variables
   - Rotate keys regularly

2. **Input Validation**
   - Sanitize user inputs
   - Limit input length
   - Validate agent types

3. **Rate Limiting**
   - Implement rate limiting for API endpoints
   - Monitor usage patterns
   - Set appropriate limits

4. **Content Filtering**
   - Review generated content
   - Implement content filters
   - Monitor for inappropriate outputs

## Future Enhancements

Planned features:
- Agent templates and presets
- Usage analytics and reporting
- Batch processing capabilities
- Integration with more AI providers
- Custom model fine-tuning
- Workflow automation

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review the Rails logs
3. Test with the built-in agent testing feature
4. Contact support with detailed error information

