# RailsPress Test Suite Documentation

## Overview

The RailsPress test suite provides comprehensive testing coverage for all major components of the application. The test suite includes unit tests, integration tests, system tests, and API tests.

## Test Structure

### Test Categories

1. **Model Tests** (`test/models/`)
   - User model validation and behavior
   - Post model functionality and associations
   - AI Provider and Agent model testing
   - Category, Tag, Comment, and other content models

2. **Controller Tests** (`test/controllers/`)
   - Admin panel controllers (Posts, Users, AI Agents, etc.)
   - API controllers for external integrations
   - Authentication and authorization testing

3. **Integration Tests** (`test/integration/`)
   - Full workflow testing (authentication flows, content creation)
   - AI Agents management workflows
   - User management and settings flows

4. **System Tests** (`test/system/`)
   - End-to-end browser testing
   - Dashboard functionality
   - Responsive design testing
   - Command palette and UI interactions

5. **Service Tests** (`test/services/`)
   - AI Service integration testing
   - External API mocking and testing
   - Background job testing

6. **Helper Tests** (`test/helpers/`)
   - View helper functionality
   - AI helper methods
   - Utility function testing

## Running Tests

### Quick Start
```bash
./run_tests.sh
```

### Individual Test Categories
```bash
# Model tests only
rails test test/models/

# Controller tests only
rails test test/controllers/

# Integration tests only
rails test test/integration/

# System tests only
rails test test/system/

# Service tests only
rails test test/services/
```

### Specific Test Files
```bash
# Test specific model
rails test test/models/user_test.rb

# Test specific controller
rails test test/controllers/admin/posts_controller_test.rb

# Test specific integration
rails test test/integration/admin_authentication_test.rb
```

## Test Coverage

### Model Tests Coverage

#### User Model (`user_test.rb`)
- ✅ Email validation and uniqueness
- ✅ Password requirements and confirmation
- ✅ Role-based access control
- ✅ Association testing (posts, pages, comments)
- ✅ Scoping methods (administrators, active users)
- ✅ Authentication methods
- ✅ Avatar attachment handling

#### Post Model (`post_test.rb`)
- ✅ Title and content validation
- ✅ Author association
- ✅ Status validation (draft, published, private)
- ✅ Slug generation and uniqueness
- ✅ Tag and category associations
- ✅ Comment associations
- ✅ Scoping methods (published, drafts, by category, by tag)
- ✅ View count tracking
- ✅ Featured image attachment
- ✅ Excerpt generation
- ✅ Reading time calculation

#### AI Provider Model (`ai_provider_test.rb`)
- ✅ Name and provider type validation
- ✅ API key requirements
- ✅ Model identifier validation
- ✅ Parameter validation (max_tokens, temperature)
- ✅ Provider type validation (OpenAI, Cohere, Anthropic, Google)
- ✅ Association with AI agents
- ✅ Scoping methods (active, by type, ordered)
- ✅ Default value setting
- ✅ Deletion protection for providers with agents

#### AI Agent Model (`ai_agent_test.rb`)
- ✅ Name and agent type validation
- ✅ Unique constraints
- ✅ Provider association
- ✅ Prompt composition (full_prompt method)
- ✅ Agent type validation
- ✅ Scoping methods (active, by type, ordered)
- ✅ Execution method testing
- ✅ Text field handling

### Controller Tests Coverage

#### Admin Posts Controller (`admin/posts_controller_test.rb`)
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Authentication and authorization
- ✅ Form validation and error handling
- ✅ Bulk operations
- ✅ Search and filtering
- ✅ File upload handling
- ✅ Slug generation and conflicts
- ✅ AJAX request handling
- ✅ Pagination and sorting

#### Admin AI Providers Controller (`admin/ai_providers_controller_test.rb`)
- ✅ Provider management (CRUD)
- ✅ Toggle active status
- ✅ Bulk operations
- ✅ API key masking in views
- ✅ Provider testing functionality
- ✅ Import/export functionality
- ✅ Validation testing
- ✅ Error handling

### Integration Tests Coverage

#### Admin Authentication (`admin_authentication_test.rb`)
- ✅ Login/logout flows
- ✅ Role-based access control
- ✅ Session management
- ✅ Password reset flows
- ✅ Account lockout handling
- ✅ Two-factor authentication
- ✅ Session timeout
- ✅ API authentication

#### AI Agents Management (`ai_agents_management_test.rb`)
- ✅ Agent creation and management
- ✅ Provider-agent relationships
- ✅ Agent testing and execution
- ✅ Error handling and recovery
- ✅ Bulk operations
- ✅ Search and filtering
- ✅ Import/export
- ✅ Monitoring and metrics

### System Tests Coverage

#### Admin Dashboard (`admin_dashboard_test.rb`)
- ✅ Dashboard loading and statistics
- ✅ Navigation functionality
- ✅ Responsive design testing
- ✅ Command palette functionality
- ✅ Real-time updates
- ✅ Error handling
- ✅ Accessibility testing
- ✅ Performance monitoring
- ✅ Theme switching
- ✅ Notifications

### Service Tests Coverage

#### AI Service (`ai_service_test.rb`)
- ✅ OpenAI API integration
- ✅ Cohere API integration
- ✅ Anthropic API integration
- ✅ Google API integration
- ✅ Error handling (API errors, network errors, timeouts)
- ✅ Rate limiting handling
- ✅ Quota exceeded handling
- ✅ Invalid response handling
- ✅ Special character handling
- ✅ Custom API URL support

### API Tests Coverage

#### AI Agents API (`api/v1/ai_agents_controller_test.rb`)
- ✅ Agent execution by ID
- ✅ Agent execution by type
- ✅ Authentication and authorization
- ✅ Error handling
- ✅ Input validation
- ✅ Rate limiting
- ✅ Large input handling
- ✅ Special character handling
- ✅ Multiple format support (JSON, XML, HTML, Markdown)
- ✅ Streaming responses
- ✅ Callback URL support
- ✅ Execution logging and metrics
- ✅ Caching

## Test Fixtures

### User Fixtures (`users.yml`)
- Admin user with full permissions
- Regular user with limited permissions
- Inactive user for testing deactivation
- Author user for content creation

### Post Fixtures (`posts.yml`)
- Published posts
- Draft posts
- Private posts
- Posts with different authors and categories

### Category Fixtures (`categories.yml`)
- Technology category
- Web Development category
- Rails category
- JavaScript category

### AI Provider Fixtures (`ai_providers.yml`)
- OpenAI provider
- Cohere provider
- Active and inactive providers
- Different model configurations

## Test Helpers

### Authentication Helpers
- `sign_in(user)` - Sign in a user for testing
- `sign_out(user)` - Sign out current user
- `json_response` - Parse JSON response body
- `assert_json_response` - Assert JSON response structure
- `assert_error_response` - Assert error response format
- `assert_success_response` - Assert success response format

### AI Testing Helpers
- `create_test_ai_provider` - Create test AI provider
- `create_test_ai_agent` - Create test AI agent
- `mock_ai_service_response` - Mock AI service responses
- `mock_api_request` - Mock external API requests

### File Testing Helpers
- `create_test_file` - Create temporary test files
- `with_timeout` - Add timeout to test operations

## Mocking and Stubbing

### External API Mocking
- OpenAI API responses
- Cohere API responses
- Anthropic API responses
- Google API responses

### Error Simulation
- Network timeouts
- API rate limiting
- Authentication failures
- Invalid responses

## Performance Testing

### Load Testing
- Multiple concurrent requests
- Large data sets
- Memory usage monitoring
- Response time tracking

### Stress Testing
- High-volume operations
- Resource exhaustion scenarios
- Error recovery testing

## Security Testing

### Authentication Testing
- Password strength validation
- Session management
- API key security
- Role-based access control

### Input Validation Testing
- SQL injection prevention
- XSS protection
- CSRF protection
- File upload security

## Continuous Integration

### GitHub Actions
- Automated test running
- Code coverage reporting
- Performance monitoring
- Security scanning

### Test Environment
- Isolated test database
- Mock external services
- Consistent test data
- Parallel test execution

## Best Practices

### Test Organization
- Group related tests
- Use descriptive test names
- Keep tests independent
- Clean up after tests

### Test Data Management
- Use fixtures for consistent data
- Create test data as needed
- Clean up test data
- Avoid hardcoded values

### Error Testing
- Test all error conditions
- Verify error messages
- Test error recovery
- Monitor error rates

### Performance Testing
- Test with realistic data volumes
- Monitor response times
- Test concurrent operations
- Validate resource usage

## Troubleshooting

### Common Issues
- Database connection problems
- Fixture loading errors
- Mock service failures
- Timeout issues

### Debugging Tips
- Use `puts` for debugging output
- Check test logs
- Verify fixture data
- Test individual components

### Performance Issues
- Run tests in parallel
- Use database transactions
- Optimize test data
- Monitor memory usage

## Contributing

### Adding New Tests
1. Follow existing test patterns
2. Use descriptive test names
3. Include error cases
4. Add appropriate fixtures
5. Update documentation

### Test Maintenance
- Keep tests up to date
- Remove obsolete tests
- Refactor duplicate code
- Improve test coverage

### Code Review
- Verify test quality
- Check test coverage
- Validate test data
- Ensure test isolation

