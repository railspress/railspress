# MCP Deployment Guide

## Overview

This guide covers deploying the Model Context Protocol (MCP) implementation to production environments. It includes configuration, security considerations, monitoring, and maintenance procedures.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Production Configuration](#production-configuration)
3. [Security Hardening](#security-hardening)
4. [Performance Optimization](#performance-optimization)
5. [Monitoring Setup](#monitoring-setup)
6. [Deployment Strategies](#deployment-strategies)
7. [Maintenance Procedures](#maintenance-procedures)
8. [Troubleshooting](#troubleshooting)

## Pre-Deployment Checklist

### System Requirements

- **Ruby Version**: 3.2.0 or higher
- **Rails Version**: 7.0.0 or higher
- **Database**: PostgreSQL 13+ or MySQL 8+
- **Redis**: 6.0+ (for caching and rate limiting)
- **Memory**: Minimum 2GB RAM
- **Storage**: SSD recommended for database
- **Network**: HTTPS support required

### Application Dependencies

```bash
# Verify all dependencies are installed
bundle install --deployment

# Check for security vulnerabilities
bundle audit

# Run all tests
bundle exec rspec
ruby test_mcp_final.rb
```

### Database Preparation

```bash
# Run migrations
RAILS_ENV=production bundle exec rails db:migrate

# Seed initial data
RAILS_ENV=production bundle exec rails db:seed

# Verify database connectivity
RAILS_ENV=production bundle exec rails runner "puts 'Database connected'"
```

### SSL Certificate

```bash
# Ensure SSL certificate is valid
openssl x509 -in /path/to/certificate.crt -text -noout

# Check certificate expiration
openssl x509 -in /path/to/certificate.crt -noout -dates
```

## Production Configuration

### Environment Variables

Create a `.env.production` file:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost/railspress_production

# Redis
REDIS_URL=redis://localhost:6379/0

# Application
RAILS_ENV=production
SECRET_KEY_BASE=your-secret-key-base
RAILS_MASTER_KEY=your-master-key

# MCP Specific
MCP_ENABLED=true
MCP_API_KEY=your-production-api-key
MCP_RATE_LIMIT_ENABLED=true
MCP_SSL_REQUIRED=true
```

### Rails Configuration

Update `config/environments/production.rb`:

```ruby
# Force SSL
config.force_ssl = true

# Enable caching
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }

# Enable compression
config.middleware.use Rack::Deflater

# Security headers
config.force_ssl = true
config.ssl_options = { redirect: { exclude: -> request { request.path =~ /health/ } } }

# Logging
config.log_level = :info
config.log_formatter = ::Logger::Formatter.new

# Performance
config.eager_load = true
config.cache_classes = true
```

### Nginx Configuration

```nginx
# /etc/nginx/sites-available/railspress
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    # SSL Configuration
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    add_header Content-Security-Policy "default-src 'self'";
    
    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=mcp:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/s;
    
    # MCP API Endpoints
    location /api/v1/mcp/ {
        limit_req zone=mcp burst=20 nodelay;
        
        proxy_pass http://railspress_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # General API endpoints
    location /api/ {
        limit_req zone=api burst=50 nodelay;
        
        proxy_pass http://railspress_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Admin endpoints
    location /admin/ {
        proxy_pass http://railspress_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Backend upstream
upstream railspress_backend {
    server 127.0.0.1:3000;
    keepalive 32;
}
```

### Systemd Service

Create `/etc/systemd/system/railspress.service`:

```ini
[Unit]
Description=RailsPress Application
After=network.target

[Service]
Type=simple
User=railspress
Group=railspress
WorkingDirectory=/opt/railspress
Environment=RAILS_ENV=production
Environment=PORT=3000
ExecStart=/opt/railspress/bin/rails server -b 0.0.0.0 -p 3000
ExecReload=/bin/kill -USR1 $MAINPID
KillMode=mixed
Restart=always
RestartSec=5

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/railspress/tmp
ReadWritePaths=/opt/railspress/log

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```

## Security Hardening

### API Key Management

#### 1. Generate Production API Key
```ruby
# In Rails console
RAILS_ENV=production rails console

# Generate secure API key
api_key = SecureRandom.hex(32)
SiteSetting.set('mcp_api_key', api_key)

# Verify key is stored
puts SiteSetting.get('mcp_api_key')
```

#### 2. API Key Rotation
```ruby
# Rotate API keys regularly
def rotate_api_key
  old_key = SiteSetting.get('mcp_api_key')
  new_key = SecureRandom.hex(32)
  
  # Update setting
  SiteSetting.set('mcp_api_key', new_key)
  
  # Log rotation
  Rails.logger.info "API key rotated at #{Time.current}"
  
  # Notify administrators
  notify_admins_of_key_rotation
end
```

### Security Settings

#### 1. Enable All Security Features
```ruby
# In admin settings or Rails console
security_settings = {
  'mcp_enabled' => true,
  'mcp_require_authentication' => true,
  'mcp_enable_ssl' => true,
  'mcp_enable_security_headers' => true,
  'mcp_enable_encryption' => true,
  'mcp_rate_limit_by_ip' => true,
  'mcp_rate_limit_by_user' => true,
  'mcp_max_request_size' => 1048576, # 1MB
  'mcp_timeout_seconds' => 30,
  'mcp_enable_audit_log' => true,
  'mcp_audit_log_retention_days' => 90
}

security_settings.each do |key, value|
  SiteSetting.set(key, value)
end
```

#### 2. Configure CORS
```ruby
# Only allow specific origins
allowed_origins = [
  'https://your-app.com',
  'https://admin.your-app.com'
]

SiteSetting.set('mcp_cors_origins', allowed_origins.join(','))
SiteSetting.set('mcp_enable_cors', true)
```

#### 3. Rate Limiting
```ruby
# Set appropriate rate limits
rate_limits = {
  'mcp_max_requests_per_minute' => 100,
  'mcp_max_requests_per_hour' => 1000,
  'mcp_max_requests_per_day' => 10000
}

rate_limits.each do |key, value|
  SiteSetting.set(key, value)
end
```

### Firewall Configuration

```bash
# UFW firewall rules
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw deny 3000/tcp   # Block direct access to Rails
sudo ufw enable
```

### Database Security

```sql
-- Create dedicated database user
CREATE USER railspress_mcp WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE railspress_production TO railspress_mcp;
GRANT USAGE ON SCHEMA public TO railspress_mcp;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO railspress_mcp;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO railspress_mcp;
```

## Performance Optimization

### Caching Configuration

#### 1. Redis Caching
```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  namespace: 'railspress:mcp',
  expires_in: 1.hour,
  race_condition_ttl: 5.seconds
}
```

#### 2. MCP-Specific Caching
```ruby
# Enable MCP caching
SiteSetting.set('mcp_enable_caching', true)
SiteSetting.set('mcp_cache_ttl', 300) # 5 minutes
```

### Database Optimization

#### 1. Indexes
```sql
-- Add indexes for MCP queries
CREATE INDEX idx_posts_status_published_at ON posts(status, published_at);
CREATE INDEX idx_pages_status_published_at ON pages(status, published_at);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_site_settings_key ON site_settings(key);
```

#### 2. Connection Pooling
```ruby
# config/database.yml
production:
  adapter: postgresql
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 25 } %>
  timeout: 5000
  checkout_timeout: 5
```

### Application Performance

#### 1. Enable Compression
```ruby
# config/application.rb
config.middleware.use Rack::Deflater
```

#### 2. Optimize Queries
```ruby
# Use includes to prevent N+1 queries
def get_posts_with_associations
  Post.includes(:author, :categories, :tags)
      .where(status: 'published')
      .order(published_at: :desc)
end
```

## Monitoring Setup

### Application Monitoring

#### 1. Health Checks
```ruby
# config/routes.rb
get '/health', to: 'health#show'
get '/health/mcp', to: 'health#mcp'

# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def show
    render json: {
      status: 'ok',
      timestamp: Time.current,
      version: RailsPress::VERSION
    }
  end
  
  def mcp
    mcp_enabled = SiteSetting.get('mcp_enabled', false)
    
    render json: {
      status: mcp_enabled ? 'ok' : 'disabled',
      mcp_enabled: mcp_enabled,
      timestamp: Time.current
    }
  end
end
```

#### 2. Metrics Collection
```ruby
# Enable MCP metrics
SiteSetting.set('mcp_enable_metrics', true)
SiteSetting.set('mcp_metrics_endpoint', '/api/v1/mcp/metrics')
SiteSetting.set('mcp_enable_performance_monitoring', true)
SiteSetting.set('mcp_performance_threshold_ms', 1000)
```

### Log Monitoring

#### 1. Structured Logging
```ruby
# config/initializers/logging.rb
Rails.logger = ActiveSupport::Logger.new(STDOUT)
Rails.logger.formatter = proc do |severity, datetime, progname, msg|
  {
    timestamp: datetime.iso8601,
    level: severity,
    message: msg,
    service: 'railspress-mcp'
  }.to_json + "\n"
end
```

#### 2. Log Aggregation
```yaml
# docker-compose.yml for log aggregation
version: '3.8'
services:
  railspress:
    image: railspress:latest
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  
  logstash:
    image: logstash:7.15.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5044:5044"
```

### Alerting

#### 1. Error Rate Monitoring
```ruby
# Enable error tracking
SiteSetting.set('mcp_enable_error_tracking', true)
SiteSetting.set('mcp_error_tracking_endpoint', 'https://your-error-tracking.com/api/errors')

# Enable alerting
SiteSetting.set('mcp_enable_alerting', true)
SiteSetting.set('mcp_alert_webhook_url', 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK')
SiteSetting.set('mcp_alert_threshold_errors', 10)
SiteSetting.set('mcp_alert_threshold_response_time', 5000)
```

#### 2. Uptime Monitoring
```bash
# Use external monitoring service
# Configure checks for:
# - https://your-domain.com/health
# - https://your-domain.com/health/mcp
# - https://your-domain.com/api/v1/mcp/session/handshake
```

## Deployment Strategies

### Blue-Green Deployment

#### 1. Setup
```bash
# Deploy to green environment
git checkout main
git pull origin main
bundle install --deployment
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails assets:precompile

# Test green environment
curl -f https://green.your-domain.com/health/mcp
```

#### 2. Switch
```bash
# Update load balancer to point to green
# Verify traffic is flowing correctly
# Monitor for errors
```

#### 3. Rollback
```bash
# If issues detected, switch back to blue
# Update load balancer to point to blue
```

### Rolling Deployment

#### 1. Update Application
```bash
# Update code
git pull origin main
bundle install --deployment

# Run migrations
RAILS_ENV=production bundle exec rails db:migrate

# Restart services
sudo systemctl restart railspress
```

#### 2. Verify Deployment
```bash
# Check service status
sudo systemctl status railspress

# Test endpoints
curl -f https://your-domain.com/health/mcp
ruby test_mcp_final.rb
```

### Docker Deployment

#### 1. Dockerfile
```dockerfile
FROM ruby:3.2.0-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    npm

# Set working directory
WORKDIR /app

# Copy Gemfile
COPY Gemfile Gemfile.lock ./
RUN bundle install --deployment

# Copy application
COPY . .

# Precompile assets
RUN RAILS_ENV=production bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start application
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
```

#### 2. Docker Compose
```yaml
version: '3.8'
services:
  railspress:
    build: .
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/railspress_production
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=railspress_production
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:6-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## Maintenance Procedures

### Regular Maintenance

#### 1. Daily Tasks
```bash
#!/bin/bash
# daily_maintenance.sh

# Check service status
systemctl status railspress

# Check disk space
df -h

# Check logs for errors
tail -n 100 /opt/railspress/log/production.log | grep ERROR

# Check MCP health
curl -f https://your-domain.com/health/mcp
```

#### 2. Weekly Tasks
```bash
#!/bin/bash
# weekly_maintenance.sh

# Update system packages
apt update && apt upgrade -y

# Clean old logs
find /opt/railspress/log -name "*.log" -mtime +7 -delete

# Backup database
pg_dump railspress_production > backup_$(date +%Y%m%d).sql

# Check SSL certificate expiration
openssl x509 -in /path/to/certificate.crt -noout -dates
```

#### 3. Monthly Tasks
```bash
#!/bin/bash
# monthly_maintenance.sh

# Rotate API keys
RAILS_ENV=production rails runner "rotate_api_key"

# Clean old audit logs
RAILS_ENV=production rails runner "cleanup_audit_logs"

# Update dependencies
bundle update
bundle audit

# Performance analysis
RAILS_ENV=production rails runner "analyze_performance"
```

### Backup Procedures

#### 1. Database Backup
```bash
#!/bin/bash
# backup_database.sh

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
pg_dump railspress_production > $BACKUP_DIR/railspress_$DATE.sql

# Compress backup
gzip $BACKUP_DIR/railspress_$DATE.sql

# Remove old backups (keep 30 days)
find $BACKUP_DIR -name "railspress_*.sql.gz" -mtime +30 -delete
```

#### 2. Configuration Backup
```bash
#!/bin/bash
# backup_config.sh

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup site settings
RAILS_ENV=production rails runner "
  settings = SiteSetting.where('key LIKE ?', 'mcp_%').pluck(:key, :value)
  File.write('/tmp/mcp_settings.json', settings.to_json)
"

# Compress and store
tar -czf $BACKUP_DIR/mcp_config_$DATE.tar.gz /tmp/mcp_settings.json
rm /tmp/mcp_settings.json
```

### Monitoring and Alerting

#### 1. Health Check Script
```bash
#!/bin/bash
# health_check.sh

# Check MCP API
if ! curl -f -s https://your-domain.com/health/mcp > /dev/null; then
    echo "MCP health check failed"
    # Send alert
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"MCP health check failed"}' \
        https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
    exit 1
fi

# Check database connectivity
if ! RAILS_ENV=production rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
    echo "Database connectivity check failed"
    exit 1
fi

echo "All health checks passed"
```

#### 2. Performance Monitoring
```ruby
# Monitor MCP performance
def monitor_mcp_performance
  # Check response times
  response_times = get_recent_response_times
  
  if response_times.any? { |time| time > 5000 } # 5 seconds
    alert_slow_responses(response_times)
  end
  
  # Check error rates
  error_rate = get_error_rate
  
  if error_rate > 0.05 # 5%
    alert_high_error_rate(error_rate)
  end
end
```

## Troubleshooting

### Common Issues

#### 1. MCP API Not Responding
**Symptoms**: 404 errors, connection timeouts
**Causes**: 
- MCP not enabled
- Routes not configured
- Service not running

**Solutions**:
```bash
# Check if MCP is enabled
RAILS_ENV=production rails runner "puts SiteSetting.get('mcp_enabled')"

# Check service status
systemctl status railspress

# Check logs
tail -f /opt/railspress/log/production.log
```

#### 2. Authentication Failures
**Symptoms**: 401 errors, "Invalid API key"
**Causes**:
- Wrong API key
- User account inactive
- Key not generated

**Solutions**:
```bash
# Check API key
RAILS_ENV=production rails runner "puts SiteSetting.get('mcp_api_key')"

# Generate new key
RAILS_ENV=production rails runner "
  SiteSetting.set('mcp_api_key', SecureRandom.hex(32))
  puts 'New API key generated'
"
```

#### 3. Performance Issues
**Symptoms**: Slow responses, timeouts
**Causes**:
- Database issues
- High load
- Inefficient queries

**Solutions**:
```bash
# Check database performance
RAILS_ENV=production rails runner "
  puts ActiveRecord::Base.connection.execute('SELECT * FROM pg_stat_activity').count
"

# Enable caching
RAILS_ENV=production rails runner "
  SiteSetting.set('mcp_enable_caching', true)
  SiteSetting.set('mcp_cache_ttl', 300)
"
```

#### 4. Rate Limiting Issues
**Symptoms**: 429 errors, "Rate limit exceeded"
**Causes**:
- Limits too restrictive
- High traffic
- Misconfigured limits

**Solutions**:
```bash
# Check current limits
RAILS_ENV=production rails runner "
  puts 'Per minute: ' + SiteSetting.get('mcp_max_requests_per_minute').to_s
  puts 'Per hour: ' + SiteSetting.get('mcp_max_requests_per_hour').to_s
  puts 'Per day: ' + SiteSetting.get('mcp_max_requests_per_day').to_s
"

# Adjust limits if needed
RAILS_ENV=production rails runner "
  SiteSetting.set('mcp_max_requests_per_minute', 200)
  SiteSetting.set('mcp_max_requests_per_hour', 2000)
"
```

### Emergency Procedures

#### 1. Disable MCP API
```bash
# Emergency disable
RAILS_ENV=production rails runner "
  SiteSetting.set('mcp_enabled', false)
  puts 'MCP API disabled'
"
```

#### 2. Rollback Deployment
```bash
# Rollback to previous version
git checkout previous-stable-tag
bundle install --deployment
systemctl restart railspress
```

#### 3. Database Recovery
```bash
# Restore from backup
pg_restore -d railspress_production /opt/backups/railspress_latest.sql
```

### Support and Escalation

#### 1. Log Collection
```bash
# Collect logs for support
tar -czf support_logs_$(date +%Y%m%d).tar.gz \
  /opt/railspress/log \
  /var/log/nginx \
  /var/log/systemd/railspress.service
```

#### 2. System Information
```bash
# Collect system info
echo "System Information" > system_info.txt
uname -a >> system_info.txt
df -h >> system_info.txt
free -h >> system_info.txt
systemctl status railspress >> system_info.txt
```

This deployment guide provides comprehensive procedures for deploying, monitoring, and maintaining the MCP implementation in production environments.


