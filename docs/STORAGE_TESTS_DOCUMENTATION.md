# RailsPress Storage System Tests

This document describes the comprehensive test suite for the RailsPress storage settings and upload system integration.

## Overview

The storage system tests cover all aspects of the storage configuration, file upload validation, and integration between different components of the system.

## Test Structure

### 1. StorageConfigurationService Tests (`spec/services/storage_configuration_service_spec.rb`)

Tests the core service that manages storage configuration and settings.

**Coverage:**
- ✅ Service initialization and settings loading
- ✅ Storage type configuration (local/S3)
- ✅ Local storage path management
- ✅ CDN configuration and URL generation
- ✅ File validation against storage settings
- ✅ S3 configuration generation
- ✅ ActiveStorage configuration
- ✅ Storage.yml file updates

**Key Test Cases:**
- Settings loading from SiteSetting and tenant configuration
- File size and type validation
- CDN URL generation
- Storage service name resolution
- Configuration file updates

### 2. UploadSecurity Integration Tests (`spec/models/upload_security_spec.rb`)

Tests the integration between UploadSecurity and storage settings.

**Coverage:**
- ✅ Model associations and validations
- ✅ Default value setting
- ✅ File validation with storage settings integration
- ✅ Suspicious file detection
- ✅ Global settings updates
- ✅ Multi-tenant support

**Key Test Cases:**
- File validation using storage settings as primary source
- Fallback to upload security settings
- More restrictive limit enforcement
- File type validation from storage settings
- MIME type checking

### 3. Upload Model Tests (`spec/models/upload_spec.rb`)

Tests the Upload model and its integration with storage configuration.

**Coverage:**
- ✅ Model associations and validations
- ✅ File type detection methods
- ✅ File information methods
- ✅ CDN URL generation
- ✅ Quarantine functionality
- ✅ Storage configuration callbacks
- ✅ Multi-tenancy support

**Key Test Cases:**
- File type detection (image/video/document)
- CDN URL generation based on settings
- Storage configuration on upload creation
- Quarantine and approval workflows

### 4. Settings Controller Tests (`spec/controllers/admin/settings_controller_spec.rb`)

Tests the admin settings controller for storage configuration.

**Coverage:**
- ✅ Storage settings page loading
- ✅ Settings update functionality
- ✅ Tenant configuration updates
- ✅ Storage configuration application
- ✅ Error handling
- ✅ Authorization and authentication

**Key Test Cases:**
- Settings page rendering with current values
- Settings persistence and validation
- S3 and local storage configuration
- Error handling for configuration failures
- Admin-only access control

### 5. Integration Tests (`spec/requests/storage_settings_integration_spec.rb`)

End-to-end tests for the complete storage system workflow.

**Coverage:**
- ✅ Complete storage settings flow
- ✅ Upload process with storage validation
- ✅ CDN integration
- ✅ Multi-tenant isolation
- ✅ Error handling scenarios
- ✅ Authorization checks

**Key Test Cases:**
- Full storage settings configuration workflow
- File upload with storage settings validation
- CDN URL generation in uploads
- Multi-tenant storage isolation
- Error handling and recovery

## Test Data and Factories

### UploadSecurity Factory (`spec/factories/upload_securities.rb`)

Provides test data for upload security configurations:

- **Default**: Standard security settings
- **With Virus Scanning**: Enabled virus scanning
- **Without Quarantine**: Disabled quarantine
- **Auto Approve**: Auto-approval enabled
- **Restrictive**: Very strict file limits
- **Permissive**: Very lenient file limits

### Upload Factory (`spec/factories/uploads.rb`)

Provides test data for upload objects:

- **Default**: Basic text file upload
- **With Image**: Image file upload
- **With Video**: Video file upload
- **With Document**: PDF document upload
- **Quarantined**: Quarantined upload
- **Large File**: Large file upload
- **Approved/Rejected**: Approval status variants

## Running the Tests

### Individual Test Suites

```bash
# Run specific test files
bundle exec rspec spec/services/storage_configuration_service_spec.rb
bundle exec rspec spec/models/upload_security_spec.rb
bundle exec rspec spec/models/upload_spec.rb
bundle exec rspec spec/controllers/admin/settings_controller_spec.rb
bundle exec rspec spec/requests/storage_settings_integration_spec.rb
```

### All Storage Tests

```bash
# Run the test runner script
./run_storage_tests.sh
```

### Specific Test Patterns

```bash
# Run tests matching a pattern
bundle exec rspec spec/ -t storage
bundle exec rspec spec/ -t upload
bundle exec rspec spec/ -t settings
```

## Test Coverage Areas

### Storage Configuration
- ✅ Local storage path configuration
- ✅ S3 storage configuration
- ✅ CDN setup and URL generation
- ✅ File size and type limits
- ✅ Auto-optimization settings

### File Validation
- ✅ File size validation against storage settings
- ✅ File type validation against allowed types
- ✅ MIME type checking
- ✅ Suspicious file detection
- ✅ Quarantine functionality

### Upload Process
- ✅ File upload with validation
- ✅ Storage configuration application
- ✅ CDN URL generation
- ✅ Multi-tenant isolation
- ✅ Error handling and recovery

### Settings Management
- ✅ Settings persistence
- ✅ Real-time configuration updates
- ✅ Tenant-specific settings
- ✅ Admin authorization
- ✅ Error handling

## Test Environment Setup

### Prerequisites
- Ruby on Rails application
- RSpec testing framework
- FactoryBot for test data
- Database with proper migrations
- ActiveStorage configured

### Database Setup
```bash
# Run migrations for test environment
RAILS_ENV=test bundle exec rails db:migrate

# Load test fixtures if needed
RAILS_ENV=test bundle exec rails db:fixtures:load
```

### Test Data
The tests use FactoryBot to generate test data dynamically. No additional fixtures are required.

## Troubleshooting

### Common Issues

1. **Factory Not Found**
   - Ensure all factory files are in `spec/factories/`
   - Check factory names match the model names

2. **Database Errors**
   - Run migrations: `RAILS_ENV=test bundle exec rails db:migrate`
   - Reset test database: `RAILS_ENV=test bundle exec rails db:reset`

3. **ActiveStorage Errors**
   - Ensure ActiveStorage is properly configured
   - Check storage.yml configuration

4. **Multi-tenant Issues**
   - Verify ActsAsTenant is properly configured
   - Check tenant creation in tests

### Debug Mode

Run tests with verbose output:
```bash
bundle exec rspec spec/services/storage_configuration_service_spec.rb --format documentation --backtrace
```

## Continuous Integration

These tests are designed to run in CI/CD environments:

- All tests are isolated and don't depend on external services
- No real file uploads are performed (mocked)
- Database is properly cleaned between tests
- No side effects on the host system

## Performance Considerations

- Tests use in-memory file attachments where possible
- Database transactions are used for cleanup
- Minimal file I/O operations
- Efficient factory usage

## Future Enhancements

Potential areas for additional testing:

- Real S3 integration tests (with test buckets)
- Performance testing with large files
- Concurrent upload testing
- Storage quota management
- Backup and recovery testing

## Contributing

When adding new storage features:

1. Add corresponding tests to the appropriate spec file
2. Update factory definitions if needed
3. Ensure all tests pass
4. Update this documentation
5. Run the full test suite before committing

## Support

For issues with the storage system tests:

1. Check the test output for specific error messages
2. Verify all dependencies are installed
3. Ensure database is properly set up
4. Check factory definitions
5. Review the test documentation

The storage system tests provide comprehensive coverage of all storage-related functionality and ensure the system works correctly across all scenarios.
