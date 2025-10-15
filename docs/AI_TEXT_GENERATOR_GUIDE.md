# AI Text Generator Guide

The AI Text Generator is a Rails partial that provides an easy-to-use interface for generating text content using AI agents. It includes a magic wand button that opens a popup with a textarea, tone selector, and generates content using the OpenAI-compatible API.

## Features

- **Magic Wand Button**: Square button with AI icon that opens the generator popup
- **Tone Selection**: Dropdown with predefined tones (Professional, Casual, Friendly, etc.)
- **Target Element Insertion**: Automatically inserts generated text into specified form fields
- **Multiple Agents**: Support for different AI agents (Creative Writer, Technical Writer, etc.)
- **Responsive Design**: Works on desktop and mobile devices
- **Accessibility**: Full keyboard navigation and screen reader support

## Basic Usage

### 1. Simple Integration

```erb
<!-- Basic usage with a textarea -->
<div class="relative">
  <textarea id="content" placeholder="Start writing..."></textarea>
  
  <%= render 'shared/ai_text_generator', 
      agent_id: 'content_summarizer',
      target_selector: '#content',
      button_class: 'absolute top-3 right-3' %>
</div>
```

### 2. Using Helper Methods

```erb
<!-- For form fields -->
<%= form_with model: @post do |form| %>
  <%= ai_text_field(form, :title, 'Post Title', 
      agent: 'content_summarizer',
      placeholder: 'Enter title...',
      ai_placeholder: 'Generate a title about...') %>
      
  <%= ai_text_area(form, :content, 'Content', 
      agent: 'content_summarizer',
      rows: 8,
      ai_placeholder: 'Write a blog post about...') %>
<% end %>
```

### 3. Using with_ai_generator Helper

```erb
<!-- For existing form fields -->
<%= with_ai_generator(
      form.text_area(:excerpt, class: "form-control"),
      agent_id: 'content_summarizer',
      target_selector: '#post_excerpt',
      button_class: 'absolute top-2 right-2') %>
```

## Parameters

### Required Parameters

- `agent_id`: The AI agent ID to use for generation (e.g., 'content_summarizer', 'creative_writer')
- `target_selector`: CSS selector for the target element where text will be inserted

### Optional Parameters

- `button_text`: Text for the button (default: 'AI')
- `placeholder`: Placeholder text for the prompt textarea
- `button_class`: Additional CSS classes for the button

## Available AI Agents

The system supports different AI agents for different types of content:

- **content_summarizer**: General content creation and summarization
- **creative_writer**: Creative writing, stories, and engaging content
- **technical_writer**: Technical documentation and formal writing

## Tone Options

The tone dropdown includes these options:

- **Balanced** (default): Neutral, well-balanced tone
- **Professional**: Business-appropriate, formal tone
- **Casual**: Conversational, relaxed tone
- **Friendly**: Warm, approachable tone
- **Formal**: Academic, formal tone
- **Creative**: Engaging, imaginative tone
- **Concise**: Brief, to-the-point tone
- **Detailed**: Comprehensive, thorough tone

## Integration Examples

### 1. Post Creation Form

```erb
<%= form_with model: @post, class: "space-y-6" do |form| %>
  <!-- Title with AI generation -->
  <%= ai_text_field(form, :title, 'Post Title', 
      agent: 'content_summarizer',
      placeholder: 'Enter post title...',
      ai_placeholder: 'Generate a catchy title about...') %>
  
  <!-- Content with AI generation -->
  <%= ai_text_area(form, :content, 'Content', 
      agent: 'content_summarizer',
      rows: 10,
      ai_placeholder: 'Write a blog post about...') %>
  
  <!-- Excerpt with AI generation -->
  <%= ai_text_area(form, :excerpt, 'Excerpt', 
      agent: 'content_summarizer',
      rows: 3,
      ai_placeholder: 'Create a compelling excerpt...') %>
<% end %>
```

### 2. Multiple Agents for Different Fields

```erb
<!-- Creative content -->
<%= ai_text_area(form, :story, 'Story', 
    agent: 'creative_writer',
    ai_placeholder: 'Create a story about...') %>

<!-- Technical content -->
<%= ai_text_area(form, :documentation, 'Documentation', 
    agent: 'technical_writer',
    ai_placeholder: 'Write technical documentation about...') %>
```

### 3. Custom Styling

```erb
<div class="relative">
  <textarea id="custom_field" class="custom-textarea"></textarea>
  
  <%= render 'shared/ai_text_generator', 
      agent_id: 'content_summarizer',
      target_selector: '#custom_field',
      button_text: '✨ AI',
      placeholder: 'Describe what you want...',
      button_class: 'absolute top-2 right-2 bg-gradient-to-r from-purple-500 to-pink-500' %>
</div>
```

## JavaScript API

The AI Text Generator uses a Stimulus controller that provides these methods:

### Controller Values

- `agentIdValue`: The AI agent ID to use
- `targetSelectorValue`: CSS selector for the target element
- `popupIdValue`: Unique ID for the popup modal

### Controller Actions

- `openPopup`: Opens the AI generator popup
- `closePopup`: Closes the AI generator popup
- `generateText`: Generates text using the AI agent

### Example: Custom Integration

```javascript
// Custom Stimulus controller
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Access the AI generator controller
    this.aiGenerator = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="ai-text-generator"]'),
      'ai-text-generator'
    )
  }
  
  generateCustomContent() {
    // Trigger AI generation programmatically
    this.aiGenerator.openPopup()
  }
}
```

## Styling and Customization

### CSS Classes

The component uses Tailwind CSS classes and includes these custom CSS classes:

- `.ai-text-generator`: Main container
- `.ai-generator-btn`: The magic wand button
- `.ai-popup`: The popup modal
- `.ai-success-toast`: Success notification
- `.ai-error-toast`: Error notification

### Dark Mode Support

The component automatically adapts to dark mode using CSS media queries:

```css
@media (prefers-color-scheme: dark) {
  .ai-popup > div {
    background-color: #1f2937;
    color: #f9fafb;
  }
}
```

### Responsive Design

The popup is responsive and works on mobile devices:

```css
@media (max-width: 640px) {
  .ai-popup > div {
    margin: 1rem;
    max-width: calc(100vw - 2rem);
  }
}
```

## Error Handling

The component includes comprehensive error handling:

- **Authentication Errors**: Invalid or missing API keys
- **Network Errors**: Connection issues or timeouts
- **API Errors**: Invalid responses or rate limiting
- **Target Element Errors**: Missing or invalid target selectors

Error messages are displayed as toast notifications with detailed information.

## Accessibility

The component is fully accessible:

- **Keyboard Navigation**: Full keyboard support for all interactions
- **Screen Readers**: Proper ARIA labels and semantic HTML
- **Focus Management**: Proper focus handling in the popup
- **High Contrast**: Support for high contrast mode
- **Reduced Motion**: Respects user's motion preferences

## Security

- **API Key Management**: Uses secure meta tag for API key storage
- **CSRF Protection**: Includes CSRF tokens in requests
- **Input Validation**: Validates all user inputs
- **Rate Limiting**: Respects API rate limits

## Browser Support

- **Modern Browsers**: Chrome, Firefox, Safari, Edge (latest versions)
- **Mobile Browsers**: iOS Safari, Chrome Mobile
- **JavaScript Required**: Requires JavaScript for functionality

## Demo Page

Visit `/admin/ai_demo` to see the AI Text Generator in action with various examples and integration patterns.

## Troubleshooting

### Common Issues

1. **Button not appearing**: Check that the CSS file is included
2. **Popup not opening**: Verify Stimulus is loaded and the controller is connected
3. **API errors**: Check that the user has a valid API key
4. **Text not inserting**: Verify the target selector is correct

### Debug Mode

Enable debug mode by adding this to your JavaScript console:

```javascript
// Enable debug logging
localStorage.setItem('ai_text_generator_debug', 'true')
```

## Performance

- **Lazy Loading**: Popup content is only rendered when opened
- **Caching**: API responses are cached for better performance
- **Minimal DOM**: Lightweight implementation with minimal DOM manipulation

## Future Enhancements

- **Streaming Responses**: Support for real-time text generation
- **Custom Prompts**: User-defined prompt templates
- **History**: Save and reuse previous generations
- **Bulk Generation**: Generate content for multiple fields at once
- **Integration**: Direct integration with popular editors (TinyMCE, CKEditor)

