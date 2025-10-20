# MCP Admin Settings Guide

## Overview

The MCP Admin Settings page provides comprehensive configuration options for the Model Context Protocol API. Access it through **Admin → System → MCP Settings**.

## Accessing MCP Settings

### Prerequisites
- Administrator role required
- Active user account
- Access to admin panel

### Navigation
1. Log in to RailsPress admin panel
2. Navigate to **System** section in sidebar
3. Click **MCP Settings**

## Configuration Sections

### 1. Basic Settings

#### Enable MCP API
**Purpose**: Master switch for the entire MCP API system
- **Default**: Disabled
- **Impact**: When disabled, all MCP endpoints return 404
- **Recommendation**: Enable only when ready for production use

#### API Key
**Purpose**: Authentication key for API access
- **Format**: 64-character hexadecimal string
- **Generation**: Use "Generate API Key" button for secure generation
- **Storage**: Stored encrypted in database
- **Security**: Never share or log API keys

#### Rate Limiting
Configure request limits to prevent abuse:

**Max Requests/Minute**
- **Default**: 100
- **Range**: 1-1000
- **Purpose**: Prevent burst attacks

**Max Requests/Hour**
- **Default**: 1,000
- **Range**: 10-10,000
- **Purpose**: Control hourly usage

**Max Requests/Day**
- **Default**: 10,000
- **Range**: 100-100,000
- **Purpose**: Daily usage limits

### 2. Access Control

#### Allowed Tools
**Purpose**: Restrict which tools are available to API clients

**Options:**
- **All**: All tools available (default)
- **Posts Only**: Only post-related tools
- **Pages Only**: Only page-related tools
- **Taxonomies Only**: Only taxonomy-related tools
- **Custom**: Specify individual tools

**Security Impact**: Restricting tools reduces attack surface

#### Allowed Resources
**Purpose**: Control which resource collections are accessible

**Options:**
- **All**: All resources available (default)
- **Posts Only**: Only posts collection
- **Pages Only**: Only pages collection
- **Media Only**: Only media collection
- **Custom**: Specify individual resources

#### Allowed Prompts
**Purpose**: Limit which AI prompt templates are available

**Options:**
- **All**: All prompts available (default)
- **SEO Only**: Only SEO-related prompts
- **Content Only**: Only content generation prompts
- **Analytics Only**: Only analytics prompts
- **Custom**: Specify individual prompts

#### Require Authentication
**Purpose**: Force API key authentication for all requests
- **Default**: Enabled
- **Security**: Disable only for testing/development
- **Impact**: Unauthenticated requests return 401

### 3. Rate Limiting

#### Rate Limit by IP
**Purpose**: Apply rate limits based on client IP address
- **Default**: Enabled
- **Use Case**: Prevent single IP from overwhelming API
- **Consideration**: May affect legitimate users behind NAT

#### Rate Limit by User
**Purpose**: Apply rate limits based on authenticated user
- **Default**: Enabled
- **Use Case**: Prevent individual users from exceeding limits
- **Benefit**: More granular control than IP-based limiting

### 4. Logging & Monitoring

#### Log Requests
**Purpose**: Log all incoming API requests
- **Default**: Enabled
- **Data Logged**: Method, path, headers, parameters, timestamp
- **Storage**: Rails logs
- **Privacy**: May contain sensitive data

#### Log Responses
**Purpose**: Log API response data
- **Default**: Disabled
- **Security Risk**: May contain sensitive content
- **Use Case**: Debugging only
- **Recommendation**: Enable only temporarily for debugging

#### Enable Analytics
**Purpose**: Track API usage and performance metrics
- **Default**: Enabled
- **Data Collected**: Request counts, response times, error rates
- **Storage**: Database
- **Retention**: Configurable (see Analytics Retention)

#### Analytics Retention (Days)
**Purpose**: How long to keep analytics data
- **Default**: 30 days
- **Range**: 1-365 days
- **Impact**: Longer retention uses more storage
- **Compliance**: Consider data retention policies

#### Debug Log Level
**Purpose**: Set verbosity of debug logging
- **Options**: Debug, Info, Warn, Error
- **Default**: Info
- **Performance**: Debug level may impact performance
- **Use Case**: Debug level for troubleshooting only

### 5. Advanced Features

#### Enable Streaming
**Purpose**: Enable Server-Sent Events for real-time updates
- **Default**: Enabled
- **Use Case**: Long-running operations, progress updates
- **Browser Support**: Modern browsers required
- **Performance**: May impact server resources

#### Enable CORS
**Purpose**: Enable Cross-Origin Resource Sharing
- **Default**: Disabled
- **Use Case**: Web applications from different domains
- **Security**: Configure CORS Origins carefully
- **Recommendation**: Enable only when needed

#### Enable Caching
**Purpose**: Cache API responses for improved performance
- **Default**: Enabled
- **Benefit**: Reduces database load
- **Consideration**: May serve stale data
- **Cache TTL**: See Cache TTL setting

#### Max Stream Duration (seconds)
**Purpose**: Maximum time for streaming connections
- **Default**: 300 seconds (5 minutes)
- **Range**: 30-3600 seconds
- **Purpose**: Prevent long-running connections
- **Resource Management**: Prevents connection exhaustion

#### Cache TTL (seconds)
**Purpose**: How long to cache responses
- **Default**: 300 seconds (5 minutes)
- **Range**: 60-3600 seconds
- **Balance**: Longer TTL = better performance, more stale data
- **Content Types**: Different content may need different TTLs

#### CORS Origins
**Purpose**: Allowed origins for CORS requests
- **Format**: Comma-separated URLs
- **Example**: `https://app.example.com, https://admin.example.com`
- **Security**: Be specific, avoid wildcards
- **Development**: `http://localhost:3000` for local development

### 6. Security Settings

#### Enable Security Headers
**Purpose**: Add security headers to API responses
- **Default**: Enabled
- **Headers Added**: X-Content-Type-Options, X-Frame-Options, etc.
- **Security**: Helps prevent common attacks
- **Compatibility**: Should not break legitimate clients

#### Enable Encryption
**Purpose**: Encrypt sensitive data in API responses
- **Default**: Enabled
- **Data Encrypted**: API keys, passwords, sensitive content
- **Performance**: Minimal impact
- **Compliance**: May be required for sensitive data

#### Enable SSL
**Purpose**: Require SSL/TLS for API connections
- **Default**: Enabled
- **Security**: Prevents man-in-the-middle attacks
- **Production**: Always enable in production
- **Development**: May disable for local testing

#### Max Request Size (bytes)
**Purpose**: Maximum size of request payloads
- **Default**: 1,048,576 bytes (1 MB)
- **Range**: 1,024-10,485,760 bytes (1 KB-10 MB)
- **Purpose**: Prevent large payload attacks
- **File Uploads**: Consider for media uploads

#### Request Timeout (seconds)
**Purpose**: Maximum time for request processing
- **Default**: 30 seconds
- **Range**: 5-300 seconds
- **Purpose**: Prevent hanging requests
- **Resource Management**: Prevents server overload

### 7. Webhooks

#### Enable Webhooks
**Purpose**: Send webhook notifications for API events
- **Default**: Disabled
- **Events**: Tool calls, errors, rate limit hits
- **Use Case**: Monitoring, logging, integration
- **Reliability**: Consider webhook delivery guarantees

#### Webhook URL
**Purpose**: Target URL for webhook notifications
- **Format**: Full HTTPS URL
- **Example**: `https://monitoring.example.com/webhooks/mcp`
- **Security**: Use HTTPS only
- **Validation**: URL must be accessible

#### Webhook Secret
**Purpose**: Secret for webhook verification
- **Format**: Random string
- **Security**: Use strong, random secret
- **Verification**: Include in webhook signature
- **Storage**: Store securely

### 8. Additional Settings

#### Enable Metrics
**Purpose**: Expose metrics endpoint for monitoring
- **Default**: Enabled
- **Endpoint**: `/api/v1/mcp/metrics`
- **Format**: Prometheus format
- **Use Case**: Monitoring systems integration

#### Enable Health Check
**Purpose**: Provide health check endpoint
- **Default**: Enabled
- **Endpoint**: `/api/v1/mcp/health`
- **Response**: System status
- **Use Case**: Load balancer health checks

#### Enable Versioning
**Purpose**: Support API versioning
- **Default**: Enabled
- **Benefit**: Backward compatibility
- **Implementation**: Version in URL path

#### Supported Versions
**Purpose**: List of supported API versions
- **Default**: `2025-03-26`
- **Format**: Comma-separated version strings
- **Example**: `2025-03-26,2025-04-01`

#### Enable Deprecation Warnings
**Purpose**: Include deprecation warnings in responses
- **Default**: Enabled
- **Benefit**: Helps clients migrate to new versions
- **Headers**: X-Deprecation-Warning

#### Enable Feature Flags
**Purpose**: Enable feature flag system
- **Default**: Disabled
- **Use Case**: Gradual feature rollouts
- **Configuration**: JSON object of flags

#### Feature Flags
**Purpose**: JSON configuration of feature flags
- **Format**: JSON object
- **Example**: `{"new_tool_format": true, "beta_features": false}`
- **Validation**: Must be valid JSON

#### Enable Audit Log
**Purpose**: Log all administrative actions
- **Default**: Enabled
- **Data Logged**: User, action, timestamp, details
- **Compliance**: May be required for audit trails
- **Retention**: See Audit Log Retention

#### Audit Log Retention (Days)
**Purpose**: How long to keep audit logs
- **Default**: 90 days
- **Range**: 30-365 days
- **Compliance**: Consider regulatory requirements
- **Storage**: Longer retention uses more space

#### Enable Rate Limit Headers
**Purpose**: Include rate limit info in response headers
- **Default**: Enabled
- **Headers**: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
- **Benefit**: Helps clients manage rate limits

#### Enable Error Tracking
**Purpose**: Send errors to external tracking service
- **Default**: Enabled
- **Integration**: Sentry, Bugsnag, etc.
- **Privacy**: May contain sensitive data
- **Configuration**: See Error Tracking Endpoint

#### Error Tracking Endpoint
**Purpose**: URL for error tracking service
- **Format**: Full URL
- **Example**: `https://sentry.io/api/123456/store/`
- **Security**: Use HTTPS
- **Authentication**: Include API key if required

#### Enable Performance Monitoring
**Purpose**: Track API performance metrics
- **Default**: Enabled
- **Metrics**: Response times, throughput, error rates
- **Storage**: Database
- **Analysis**: Performance trends and bottlenecks

#### Performance Threshold (ms)
**Purpose**: Threshold for slow request warnings
- **Default**: 1000ms
- **Range**: 100-10000ms
- **Purpose**: Identify performance issues
- **Alerting**: Trigger alerts for slow requests

#### Enable Alerting
**Purpose**: Send alerts for critical events
- **Default**: Disabled
- **Events**: High error rates, slow responses, system issues
- **Integration**: Email, Slack, PagerDuty
- **Configuration**: See Alert Webhook URL

#### Alert Webhook URL
**Purpose**: URL for alert notifications
- **Format**: Full URL
- **Example**: `https://hooks.slack.com/services/...`
- **Security**: Use HTTPS
- **Authentication**: Include webhook secret

#### Alert Threshold - Errors
**Purpose**: Number of errors to trigger alert
- **Default**: 10 errors
- **Range**: 1-100 errors
- **Time Window**: Per minute
- **Purpose**: Early warning of issues

#### Alert Threshold - Response Time
**Purpose**: Response time to trigger alert
- **Default**: 5000ms
- **Range**: 1000-30000ms
- **Purpose**: Performance degradation alerts
- **Time Window**: Average over 5 minutes

#### Enable Backup
**Purpose**: Automatically backup MCP configuration
- **Default**: Disabled
- **Frequency**: See Backup Frequency
- **Storage**: Local or cloud storage
- **Retention**: See Backup Retention

#### Backup Frequency
**Purpose**: How often to backup configuration
- **Options**: Daily, Weekly, Monthly
- **Default**: Daily
- **Purpose**: Data protection
- **Storage**: Consider storage costs

#### Backup Retention (Days)
**Purpose**: How long to keep backup files
- **Default**: 30 days
- **Range**: 7-365 days
- **Purpose**: Recovery options
- **Storage**: Longer retention uses more space

#### Enable OAuth
**Purpose**: Enable OAuth authentication
- **Default**: Disabled
- **Providers**: Google, GitHub, etc.
- **Security**: More secure than API keys
- **Configuration**: See OAuth settings

#### OAuth Provider
**Purpose**: OAuth provider to use
- **Options**: Google, GitHub, Microsoft, Custom
- **Default**: None
- **Configuration**: Provider-specific settings required

#### OAuth Client ID
**Purpose**: OAuth application client ID
- **Format**: Provider-specific
- **Security**: Store securely
- **Registration**: Register with OAuth provider

#### OAuth Client Secret
**Purpose**: OAuth application client secret
- **Format**: Provider-specific
- **Security**: Store encrypted
- **Rotation**: Rotate regularly

#### OAuth Redirect URI
**Purpose**: OAuth callback URL
- **Format**: Full URL
- **Example**: `https://your-domain.com/auth/oauth/callback`
- **Registration**: Must match provider configuration

#### Enable JWT
**Purpose**: Enable JWT token authentication
- **Default**: Disabled
- **Security**: Stateless authentication
- **Expiration**: See JWT Expiration Hours
- **Configuration**: See JWT Secret

#### JWT Secret
**Purpose**: Secret key for JWT signing
- **Format**: Random string
- **Security**: Use strong, random secret
- **Storage**: Store securely
- **Rotation**: Rotate regularly

#### JWT Expiration (Hours)
**Purpose**: JWT token expiration time
- **Default**: 24 hours
- **Range**: 1-168 hours (1 hour to 1 week)
- **Security**: Shorter expiration = more secure
- **User Experience**: Longer expiration = better UX

#### Enable API Versioning
**Purpose**: Support multiple API versions
- **Default**: Enabled
- **Benefit**: Backward compatibility
- **Implementation**: Version in URL or header

#### Default API Version
**Purpose**: Default version for unversioned requests
- **Default**: v1
- **Options**: v1, v2, etc.
- **Compatibility**: Maintains backward compatibility

#### Enable Documentation
**Purpose**: Provide API documentation
- **Default**: Enabled
- **Endpoint**: See Documentation URL
- **Format**: OpenAPI/Swagger
- **Benefit**: Developer experience

#### Documentation URL
**Purpose**: URL for API documentation
- **Default**: `/api/v1/mcp/docs`
- **Format**: Relative or absolute URL
- **Access**: Public or authenticated

#### Enable Sandbox
**Purpose**: Provide sandbox environment
- **Default**: Disabled
- **Use Case**: Testing and development
- **Isolation**: Separate from production data
- **Configuration**: See Sandbox Timeout

#### Sandbox Timeout (seconds)
**Purpose**: Maximum time for sandbox operations
- **Default**: 60 seconds
- **Range**: 30-300 seconds
- **Purpose**: Prevent resource exhaustion
- **Security**: Limit sandbox impact

#### Enable Playground
**Purpose**: Provide interactive API playground
- **Default**: Disabled
- **Use Case**: Testing and exploration
- **Security**: May expose sensitive data
- **Access**: Control access carefully

#### Playground URL
**Purpose**: URL for API playground
- **Default**: `/api/v1/mcp/playground`
- **Format**: Relative or absolute URL
- **Security**: Consider access controls

## Interactive Features

### Test Connection
**Purpose**: Verify MCP API is working correctly
**Location**: Status card at top of settings page
**Function**: Makes test handshake request
**Response**: Shows connection status and server info

**Test Process:**
1. Click "Test Connection" button
2. System makes handshake request to MCP API
3. Displays success/failure with details
4. Shows protocol version and capabilities

**Success Response:**
```
✅ Connection successful!

Protocol Version: 2025-03-26
Capabilities: tools, resources, prompts
Server: railspress-mcp-server v1.0.0
```

**Failure Response:**
```
❌ Connection failed!

Error: [Error details]
```

### Generate API Key
**Purpose**: Create new API key and invalidate current one
**Location**: Status card at top of settings page
**Security**: Current key is immediately invalidated
**Storage**: New key is stored encrypted

**Generation Process:**
1. Click "Generate API Key" button
2. Confirm action in dialog
3. System generates 64-character hex key
4. Displays new key (only shown once)
5. Updates API key field

**Security Notes:**
- Old key is immediately invalidated
- New key is shown only once
- Store key securely
- Rotate keys regularly

## Best Practices

### Security
1. **Enable all security features** in production
2. **Use strong API keys** and rotate regularly
3. **Enable SSL/TLS** for all connections
4. **Configure CORS origins** carefully
5. **Enable audit logging** for compliance
6. **Set appropriate rate limits** to prevent abuse

### Performance
1. **Enable caching** for better performance
2. **Set appropriate cache TTL** based on content type
3. **Monitor performance metrics** regularly
4. **Set performance thresholds** for alerts
5. **Use streaming** for long-running operations

### Monitoring
1. **Enable analytics** to track usage
2. **Set up alerting** for critical events
3. **Monitor error rates** and response times
4. **Use health checks** for load balancers
5. **Enable metrics** for monitoring systems

### Development
1. **Use sandbox mode** for testing
2. **Enable debug logging** for troubleshooting
3. **Disable security features** only in development
4. **Test all configurations** before production
5. **Document custom settings** for team

## Troubleshooting

### Common Issues

#### Settings Not Saving
**Cause**: Permission issues or validation errors
**Solution**: 
- Check user has administrator role
- Verify all required fields are filled
- Check for validation errors

#### API Not Working After Changes
**Cause**: Configuration errors or service restart needed
**Solution**:
- Test connection to verify settings
- Check Rails logs for errors
- Restart Rails server if needed

#### Rate Limits Too Restrictive
**Cause**: Limits set too low for usage patterns
**Solution**:
- Monitor actual usage patterns
- Adjust limits based on needs
- Consider user-specific limits

#### Performance Issues
**Cause**: High load or inefficient configuration
**Solution**:
- Enable performance monitoring
- Check response time metrics
- Optimize cache settings
- Consider scaling resources

### Debug Mode
Enable debug mode for detailed troubleshooting:

1. Go to **Logging & Monitoring** section
2. Enable **Debug Mode**
3. Set **Debug Log Level** to **Debug**
4. Check Rails logs for detailed information
5. Disable debug mode when done

### Configuration Validation
The system validates all configuration settings:

- **Numeric ranges**: Values must be within specified ranges
- **URL formats**: URLs must be valid format
- **JSON validation**: JSON fields must be valid
- **Required fields**: Some fields are required for certain features

### Backup and Recovery
Regular backups of configuration:

1. Enable **Backup** feature
2. Set appropriate **Backup Frequency**
3. Configure **Backup Retention**
4. Test backup restoration process
5. Store backups securely

This comprehensive guide covers all aspects of MCP admin settings configuration and management.


