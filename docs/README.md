# MCP Documentation

This directory contains comprehensive documentation for the Model Context Protocol (MCP) implementation in RailsPress.

## Documentation Overview

The MCP implementation provides a powerful API for AI models to interact with RailsPress content management system. This documentation covers all aspects of the implementation, from basic usage to advanced deployment and maintenance.

## Documentation Files

### 📚 [MCP Implementation Guide](MCP_IMPLEMENTATION.md)
**Complete overview of the MCP system**
- Architecture and core components
- Protocol support and standards
- API endpoints and authentication
- Tools, resources, and prompts reference
- Admin settings and configuration
- Testing and deployment overview

### 🔧 [MCP API Reference](MCP_API_REFERENCE.md)
**Detailed API documentation**
- Quick start guide
- Complete endpoint reference
- Tool reference with parameters and responses
- Error handling and status codes
- Rate limiting and best practices
- Code examples and workflows

### ⚙️ [MCP Admin Settings Guide](MCP_ADMIN_SETTINGS_GUIDE.md)
**Comprehensive admin configuration guide**
- Accessing MCP settings
- All configuration sections explained
- Security and performance settings
- Interactive features (test connection, generate API key)
- Best practices and troubleshooting

### 🧪 [MCP Testing Guide](MCP_TESTING_GUIDE.md)
**Complete testing documentation**
- Test environment setup
- Automated testing with RSpec
- Manual testing procedures
- Integration and performance testing
- Security testing
- Debugging and troubleshooting

### 🚀 [MCP Deployment Guide](MCP_DEPLOYMENT_GUIDE.md)
**Production deployment guide**
- Pre-deployment checklist
- Production configuration
- Security hardening
- Performance optimization
- Monitoring setup
- Maintenance procedures

## Quick Start

### 1. Enable MCP API
1. Navigate to **Admin → System → MCP Settings**
2. Enable "Enable MCP API"
3. Generate an API key
4. Save settings

### 2. Test Connection
1. Click "Test Connection" button
2. Verify successful handshake
3. Check capabilities and server info

### 3. Make API Calls
```bash
# Handshake
curl -X POST http://localhost:3000/api/v1/mcp/session/handshake \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"session/handshake","params":{"protocolVersion":"2025-03-26","clientInfo":{"name":"test-client","version":"1.0.0"}},"id":1}'

# List tools
curl -X GET http://localhost:3000/api/v1/mcp/tools/list

# Call tool (with API key)
curl -X POST http://localhost:3000/api/v1/mcp/tools/call \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"get_posts","arguments":{"limit":5}},"id":2}'
```

## Key Features

### 🔌 **Protocol Compliance**
- JSON-RPC 2.0 standard
- OpenAI 3.1 compatibility
- Server-Sent Events support
- Comprehensive error handling

### 🛠️ **Rich Tool Set**
- **20+ Tools** for content management
- Posts, pages, taxonomies, media, users
- Full CRUD operations
- Advanced filtering and search

### 🔒 **Security**
- API key authentication
- User permission system
- Rate limiting
- SSL/TLS support
- Security headers

### ⚡ **Performance**
- Response caching
- Database optimization
- Connection pooling
- Compression support

### 📊 **Monitoring**
- Health checks
- Performance metrics
- Error tracking
- Audit logging
- Alerting system

### 🎛️ **Admin Interface**
- Comprehensive settings page
- Real-time testing
- API key management
- 50+ configuration options

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Client     │    │   MCP API       │    │   RailsPress    │
│                 │    │                 │    │                 │
│ • Handshake     │◄──►│ • Authentication│◄──►│ • Posts         │
│ • Tool Discovery│    │ • Tool Execution│    │ • Pages         │
│ • Tool Calls    │    │ • Rate Limiting │    │ • Taxonomies    │
│ • Streaming     │    │ • Caching       │    │ • Media         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/mcp/session/handshake` | POST | Establish MCP session |
| `/api/v1/mcp/tools/list` | GET | List available tools |
| `/api/v1/mcp/tools/call` | POST | Execute a tool |
| `/api/v1/mcp/tools/stream` | GET | Stream tool output |
| `/api/v1/mcp/resources/list` | GET | List available resources |
| `/api/v1/mcp/prompts/list` | GET | List available prompts |

## Tools Available

### Content Management
- `get_posts` - Retrieve posts with filtering
- `get_post` - Get single post by ID/slug
- `create_post` - Create new post
- `update_post` - Update existing post
- `delete_post` - Delete post (move to trash)
- `get_pages` - Retrieve pages with filtering
- `get_page` - Get single page by ID/slug
- `create_page` - Create new page
- `update_page` - Update existing page
- `delete_page` - Delete page (move to trash)

### Taxonomy Management
- `get_taxonomies` - Get all taxonomies
- `get_terms` - Get terms for taxonomy
- `create_term` - Create new term
- `update_term` - Update existing term
- `delete_term` - Delete term

### Media Management
- `get_media` - Retrieve media files
- `upload_media` - Upload media file

### System Information
- `get_content_types` - Get content types
- `get_users` - Get users
- `get_system_info` - Get system statistics

## Resources Available

- `railspress://posts` - Posts collection
- `railspress://pages` - Pages collection
- `railspress://taxonomies` - Taxonomies collection
- `railspress://terms` - Terms collection
- `railspress://media` - Media collection
- `railspress://users` - Users collection
- `railspress://content-types` - Content types collection

## Prompts Available

- `seo_optimize` - Optimize content for SEO
- `content_summarize` - Summarize content
- `content_generate` - Generate content based on topic
- `meta_description_generate` - Generate meta descriptions

## Configuration Options

### Basic Settings
- Enable/disable MCP API
- API key management
- Rate limiting (per minute/hour/day)

### Access Control
- Tool permissions
- Resource access control
- Prompt restrictions
- Authentication requirements

### Security
- SSL/TLS enforcement
- Security headers
- Encryption settings
- Request size limits

### Performance
- Caching configuration
- Compression settings
- Timeout configuration
- Connection pooling

### Monitoring
- Logging configuration
- Analytics settings
- Error tracking
- Performance monitoring

### Advanced Features
- Streaming support
- CORS configuration
- Webhook notifications
- Feature flags

## Testing

### Automated Tests
```bash
# Run RSpec tests
bundle exec rspec spec/controllers/api/v1/mcp_controller_spec.rb

# Run comprehensive test suite
ruby test_mcp_comprehensive.rb

# Run final validation
ruby test_mcp_final.rb
```

### Manual Testing
```bash
# Test MCP settings
ruby test_mcp_settings.rb

# Test specific endpoints
curl -X POST http://localhost:3000/api/v1/mcp/session/handshake \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"session/handshake","params":{"protocolVersion":"2025-03-26","clientInfo":{"name":"test","version":"1.0.0"}},"id":1}'
```

## Deployment

### Production Checklist
- [ ] SSL certificate configured
- [ ] Database migrations applied
- [ ] API key generated
- [ ] Security settings enabled
- [ ] Rate limiting configured
- [ ] Monitoring setup
- [ ] Backup procedures in place

### Environment Variables
```bash
RAILS_ENV=production
DATABASE_URL=postgresql://user:password@localhost/railspress_production
REDIS_URL=redis://localhost:6379/0
SECRET_KEY_BASE=your-secret-key-base
MCP_ENABLED=true
MCP_API_KEY=your-production-api-key
```

## Support

### Troubleshooting
1. Check MCP is enabled in admin settings
2. Verify API key is correct
3. Check user permissions
4. Review Rails logs for errors
5. Test with provided test scripts

### Common Issues
- **404 errors**: MCP not enabled or routes not configured
- **401 errors**: Invalid API key or authentication issues
- **403 errors**: Permission denied for specific operations
- **429 errors**: Rate limit exceeded
- **500 errors**: Internal server errors (check logs)

### Getting Help
1. Review the comprehensive documentation
2. Run the test scripts to verify functionality
3. Check Rails logs for detailed error information
4. Enable debug mode for verbose logging
5. Use the admin test connection feature

## Contributing

### Development Setup
1. Clone the repository
2. Install dependencies: `bundle install`
3. Set up database: `rails db:setup`
4. Run tests: `bundle exec rspec`
5. Start server: `rails server`

### Adding New Tools
1. Define tool schema in `tools_list` method
2. Implement tool logic in `tools_call` method
3. Add appropriate permission checks
4. Write tests for the new tool
5. Update documentation

### Adding New Settings
1. Add setting to `load_mcp_settings` method
2. Add update logic to `update_mcp_settings` method
3. Add UI controls to admin view
4. Update documentation
5. Test configuration changes

## License

This MCP implementation is part of RailsPress and follows the same license terms.

## Version History

- **v1.0.0** - Initial MCP implementation
  - Complete API endpoints
  - 20+ tools for content management
  - Admin settings interface
  - Comprehensive testing suite
  - Production deployment guide

---

For detailed information on any aspect of the MCP implementation, please refer to the specific documentation files listed above. Each guide provides comprehensive coverage of its respective topic with examples, best practices, and troubleshooting information.