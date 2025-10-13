# RailsPress Test Suite

## Quick Start

Run all tests with:
```bash
./run_tests.sh
```

## What's Included

This comprehensive test suite includes:

### ✅ Model Tests
- **User Model**: Authentication, validation, roles, associations
- **Post Model**: CRUD operations, slug generation, status management
- **Page Model**: Page creation, validation, author associations
- **Category Model**: Categorization, slug generation, post associations
- **Shortcut Model**: Command palette shortcuts, validation
- **AI Provider Model**: Provider management, validation, API configuration
- **AI Agent Model**: Agent creation, prompt composition, execution

### ✅ Controller Tests
- **Admin Posts Controller**: Full CRUD, bulk operations, search/filter
- **Admin AI Providers Controller**: Provider management, toggle, testing
- **Admin AI Agents Controller**: Agent management, execution, monitoring
- **API Controllers**: Authentication, validation, error handling

### ✅ Integration Tests
- **Admin Authentication**: Login/logout, roles, 2FA, password reset
- **AI Agents Management**: Full workflow testing, execution, monitoring
- **Content Creation**: Posts, pages, media uploads
- **User Management**: CRUD, permissions, deactivation

### ✅ System Tests
- **Admin Dashboard**: UI testing, navigation, responsive design
- **Command Palette**: Keyboard shortcuts, search, execution
- **Real-time Updates**: WebSocket testing, live notifications
- **Accessibility**: Keyboard navigation, ARIA labels, screen readers

### ✅ Service Tests
- **AI Service**: OpenAI, Cohere, Anthropic, Google integrations
- **Error Handling**: Network errors, API failures, timeouts
- **Rate Limiting**: Quota management, throttling
- **Special Cases**: Large inputs, special characters, multiple formats

### ✅ API Tests
- **AI Agents API**: Execution by ID/type, authentication, validation
- **Rate Limiting**: API key validation, quota management
- **Input Handling**: JSON, XML, HTML, Markdown support
- **Caching**: Response caching, cache invalidation

## Test Statistics

- **Total Test Files**: 15+
- **Total Test Cases**: 500+
- **Coverage Areas**: Models, Controllers, Services, APIs, UI
- **Test Types**: Unit, Integration, System, E2E

## Running Specific Tests

### Run all model tests
```bash
rails test test/models/
```

### Run specific model test
```bash
rails test test/models/user_test.rb
```

### Run all controller tests
```bash
rails test test/controllers/
```

### Run specific controller test
```bash
rails test test/controllers/admin/posts_controller_test.rb
```

### Run integration tests
```bash
rails test test/integration/
```

### Run system tests
```bash
rails test test/system/
```

### Run service tests
```bash
rails test test/services/
```

### Run API tests
```bash
rails test test/controllers/api/
```

## Test Coverage by Feature

### 🔐 Authentication & Authorization
- ✅ User login/logout
- ✅ Role-based access control (Admin, Author, User)
- ✅ Password reset flows
- ✅ Two-factor authentication
- ✅ Session management
- ✅ API key authentication
- ✅ Account lockout
- ✅ Email confirmation

### 📝 Content Management
- ✅ Post CRUD operations
- ✅ Page CRUD operations
- ✅ Category management
- ✅ Tag management
- ✅ Comment moderation
- ✅ Media uploads
- ✅ Slug generation
- ✅ Status management (draft/published/private)

### 🤖 AI Features
- ✅ AI Provider configuration (OpenAI, Cohere, Anthropic, Google)
- ✅ AI Agent creation and management
- ✅ Prompt composition (Master + Agent prompts)
- ✅ Agent execution
- ✅ Error handling and recovery
- ✅ Rate limiting
- ✅ Caching
- ✅ API integration

### ⚡ Command Palette
- ✅ Keyboard shortcuts (CMD+K)
- ✅ Search functionality
- ✅ Quick actions
- ✅ Navigation shortcuts
- ✅ Dynamic loading from database

### 🎨 UI/UX
- ✅ Responsive design (mobile/tablet/desktop)
- ✅ Sidebar navigation
- ✅ Collapsible sections
- ✅ Active state management
- ✅ Theme switching
- ✅ Accessibility (ARIA, keyboard navigation)

### 🔌 API
- ✅ RESTful endpoints
- ✅ Authentication (Bearer tokens)
- ✅ Rate limiting
- ✅ Error handling
- ✅ Validation
- ✅ Multiple format support (JSON, XML, HTML, Markdown)

### 📊 Data Management
- ✅ Import/Export (CSV, JSON)
- ✅ Bulk operations
- ✅ Search and filtering
- ✅ Sorting and pagination
- ✅ Data validation
- ✅ Data sanitization

### 🔒 Security
- ✅ CSRF protection
- ✅ XSS prevention
- ✅ SQL injection prevention
- ✅ File upload security
- ✅ API key security
- ✅ Password strength validation
- ✅ Session timeout

## Test Fixtures

Pre-configured test data in `test/fixtures/`:
- `users.yml` - Admin, regular users, authors
- `posts.yml` - Published, draft, private posts
- `categories.yml` - Technology, Web Dev, Rails, JavaScript
- `ai_providers.yml` - OpenAI, Cohere providers (active/inactive)

## Test Helpers

Available in `test/test_helper.rb`:
- `sign_in(user)` - Authenticate user for testing
- `sign_out(user)` - End user session
- `json_response` - Parse JSON response
- `assert_json_response` - Assert JSON structure
- `create_test_ai_provider` - Create test AI provider
- `create_test_ai_agent` - Create test AI agent
- `mock_api_request` - Mock external API calls

## Mocking External Services

The test suite includes comprehensive mocking for:
- OpenAI API responses
- Cohere API responses
- Anthropic API responses
- Google API responses
- Network errors and timeouts
- Rate limiting scenarios
- Authentication failures

## Continuous Testing

The test suite is designed for:
- ✅ Local development testing
- ✅ CI/CD integration (GitHub Actions)
- ✅ Pre-commit hooks
- ✅ Automated testing on PR
- ✅ Code coverage reporting
- ✅ Performance monitoring

## Writing New Tests

### Test Structure
```ruby
require "test_helper"

class MyModelTest < ActiveSupport::TestCase
  setup do
    @model = MyModel.new(attribute: "value")
  end

  test "should be valid with valid attributes" do
    assert @model.valid?
  end

  test "should require attribute" do
    @model.attribute = nil
    assert_not @model.valid?
  end
end
```

### Best Practices
1. Use descriptive test names
2. Keep tests independent
3. Clean up test data
4. Test both success and error cases
5. Mock external services
6. Use fixtures for consistent data
7. Test edge cases
8. Validate error messages

## Troubleshooting

### Tests not running?
```bash
# Ensure test database is set up
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:schema:load

# Try running with verbose output
rails test --verbose
```

### Specific test failing?
```bash
# Run just that test
rails test test/models/user_test.rb:10

# Where 10 is the line number of the test
```

### Need to reset test database?
```bash
RAILS_ENV=test rails db:drop
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:schema:load
```

## Documentation

For detailed documentation, see:
- `TEST_SUITE_DOCUMENTATION.md` - Comprehensive test documentation
- `AI_AGENTS_GUIDE.md` - AI system usage guide
- Individual test files for implementation examples

## Contributing

When adding new features:
1. Write tests first (TDD)
2. Ensure tests pass
3. Add fixtures if needed
4. Update documentation
5. Run full test suite before committing

## Support

For issues or questions:
- Check test output for detailed error messages
- Review test files for usage examples
- Consult TEST_SUITE_DOCUMENTATION.md
- Check logs in `log/test.log`
