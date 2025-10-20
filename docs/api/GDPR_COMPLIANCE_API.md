# GDPR Compliance API

RailsPress provides comprehensive GDPR compliance endpoints for both REST API and GraphQL to help you automate data protection compliance.

## Overview

The GDPR API implements the following GDPR articles:

- **Article 7** - Conditions for consent
- **Article 17** - Right to erasure ("right to be forgotten")
- **Article 20** - Right to data portability
- **Article 25** - Data protection by design and by default

## REST API Endpoints

### Authentication

All GDPR endpoints require authentication. Include your API token in the Authorization header:

```
Authorization: Bearer YOUR_API_TOKEN
```

### Data Export (Article 20 - Right to Data Portability)

#### Request Data Export

```http
GET /api/v1/gdpr/data-export/:user_id
```

Creates a personal data export request for the specified user.

**Parameters:**
- `user_id` (path) - ID of the user whose data to export

**Response:**
```json
{
  "success": true,
  "message": "Personal data export request created successfully",
  "data": {
    "request_id": 123,
    "token": "abc123...",
    "status": "pending",
    "requested_at": "2024-01-15T10:30:00Z",
    "estimated_completion": "2024-01-15T10:35:00Z",
    "download_url": "/api/v1/gdpr/data-export/download/abc123..."
  }
}
```

#### Download Exported Data

```http
GET /api/v1/gdpr/data-export/download/:token
```

Downloads the exported personal data file.

**Parameters:**
- `token` (path) - Export request token

**Response:**
- Returns the exported data as a JSON file download

### Data Erasure (Article 17 - Right to Erasure)

#### Request Data Erasure

```http
POST /api/v1/gdpr/data-erasure/:user_id
```

Creates a personal data erasure request.

**Parameters:**
- `user_id` (path) - ID of the user whose data to erase
- `reason` (body) - Optional reason for data erasure

**Request Body:**
```json
{
  "reason": "User requested data deletion"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Data erasure request created successfully",
  "data": {
    "request_id": 456,
    "token": "def456...",
    "status": "pending_confirmation",
    "requested_at": "2024-01-15T10:30:00Z",
    "reason": "User requested data deletion",
    "confirmation_url": "/api/v1/gdpr/data-erasure/confirm/def456...",
    "metadata": {
      "user_posts_count": 5,
      "user_comments_count": 12,
      "user_media_count": 3
    }
  }
}
```

#### Confirm Data Erasure

```http
POST /api/v1/gdpr/data-erasure/confirm/:token
```

Confirms and processes a data erasure request.

**Parameters:**
- `token` (path) - Erasure request token

**Response:**
```json
{
  "success": true,
  "message": "Data erasure confirmed and queued for processing",
  "data": {
    "request_id": 456,
    "status": "processing",
    "confirmed_at": "2024-01-15T10:35:00Z",
    "estimated_completion": "2024-01-15T10:45:00Z"
  }
}
```

### Data Portability (Article 20)

#### Get Data Portability Information

```http
GET /api/v1/gdpr/data-portability/:user_id
```

Returns comprehensive data portability information for a user.

**Parameters:**
- `user_id` (path) - ID of the user

**Response:**
```json
{
  "success": true,
  "message": "Data portability information retrieved successfully",
  "data": {
    "user_profile": {
      "id": 123,
      "email": "user@example.com",
      "name": "John Doe",
      "role": "author",
      "created_at": "2024-01-01T00:00:00Z"
    },
    "posts": [...],
    "pages": [...],
    "comments": [...],
    "media": [...],
    "subscribers": [...],
    "api_tokens": [...],
    "meta_fields": [...],
    "analytics_data": {...},
    "consent_records": [...],
    "gdpr_requests": {...},
    "metadata": {
      "total_posts": 5,
      "export_date": "2024-01-15T10:30:00Z"
    }
  }
}
```

### Consent Management (Article 7)

#### Record User Consent

```http
POST /api/v1/gdpr/consent/:user_id
```

Records user consent for data processing.

**Parameters:**
- `user_id` (path) - ID of the user
- `consent_type` (body) - Type of consent
- `consent_data` (body) - Consent information

**Request Body:**
```json
{
  "consent_type": "marketing",
  "consent_data": {
    "granted": true,
    "consent_text": "I agree to receive marketing emails",
    "ip_address": "192.168.1.1",
    "user_agent": "Mozilla/5.0..."
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Consent recorded successfully",
  "data": {
    "id": 789,
    "consent_type": "marketing",
    "granted": true,
    "consent_text": "I agree to receive marketing emails",
    "granted_at": "2024-01-15T10:30:00Z"
  }
}
```

#### Withdraw User Consent

```http
DELETE /api/v1/gdpr/consent/:user_id?consent_type=marketing
```

Withdraws user consent for a specific consent type.

**Parameters:**
- `user_id` (path) - ID of the user
- `consent_type` (query) - Type of consent to withdraw

**Response:**
```json
{
  "success": true,
  "message": "Consent withdrawn successfully"
}
```

### GDPR Status and Requests

#### Get GDPR Status

```http
GET /api/v1/gdpr/status/:user_id
```

Returns GDPR compliance status for a user.

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": 123,
    "email": "user@example.com",
    "compliance_status": {
      "data_processing_consent": "granted",
      "marketing_consent": "withdrawn",
      "analytics_consent": "granted",
      "cookie_consent": "not_recorded"
    },
    "data_retention": {
      "account_created": "2024-01-01T00:00:00Z",
      "last_activity": "2024-01-15T09:00:00Z",
      "data_age_days": 14
    },
    "pending_requests": {
      "export_requests": 0,
      "erasure_requests": 1
    },
    "data_categories": {
      "profile_data": true,
      "content_data": true,
      "communication_data": true,
      "analytics_data": false,
      "media_data": true,
      "subscription_data": false
    },
    "legal_basis": {
      "consent": true,
      "withhold_consent": false,
      "legitimate_interest": true
    }
  }
}
```

#### List GDPR Requests

```http
GET /api/v1/gdpr/requests
```

Lists all GDPR requests for the current user (or all requests for admins).

**Response:**
```json
{
  "success": true,
  "data": {
    "export_requests": [
      {
        "id": 123,
        "user_email": "user@example.com",
        "status": "completed",
        "requested_at": "2024-01-15T10:30:00Z",
        "completed_at": "2024-01-15T10:35:00Z",
        "download_url": "/api/v1/gdpr/data-export/download/abc123..."
      }
    ],
    "erasure_requests": [
      {
        "id": 456,
        "user_email": "user@example.com",
        "status": "processing",
        "reason": "User requested data deletion",
        "requested_at": "2024-01-15T10:30:00Z",
        "confirmed_at": "2024-01-15T10:35:00Z"
      }
    ]
  }
}
```

#### Get Audit Log (Admin Only)

```http
GET /api/v1/gdpr/audit-log?page=1&per_page=50
```

Returns GDPR audit log entries.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "action": "data_export_requested",
      "user_email": "user@example.com",
      "timestamp": "2024-01-15T10:30:00Z",
      "details": {
        "status": "completed",
        "completed_at": "2024-01-15T10:35:00Z"
      }
    }
  ]
}
```

## GraphQL API

### Queries

#### Get GDPR Status

```graphql
query GetGdprStatus($userId: ID!) {
  gdprStatus(userId: $userId) {
    userId
    email
    complianceStatus {
      dataProcessingConsent
      marketingConsent
      analyticsConsent
      cookieConsent
    }
    dataRetention {
      accountCreated
      lastActivity
      dataAgeDays
    }
    pendingRequests {
      exportRequests
      erasureRequests
    }
    dataCategories {
      profileData
      contentData
      communicationData
      analyticsData
      mediaData
      subscriptionData
    }
    legalBasis {
      consent
      withholdConsent
      legitimateInterest
    }
    exportRequests {
      id
      email
      status
      requestedAt
      completedAt
      downloadUrl
    }
    erasureRequests {
      id
      email
      status
      reason
      requestedAt
      confirmedAt
      completedAt
    }
    consentRecords {
      id
      consentType
      granted
      consentText
      grantedAt
      withdrawnAt
    }
  }
}
```

#### Get Data Portability

```graphql
query GetDataPortability($userId: ID!) {
  gdprDataPortability(userId: $userId) {
    userProfile
    posts
    pages
    comments
    media
    subscribers
    apiTokens
    metaFields
    analyticsData
    consentRecords
    gdprRequests
    metadata
  }
}
```

#### Get Audit Log

```graphql
query GetAuditLog($page: Int, $perPage: Int) {
  gdprAuditLog(page: $page, perPage: $perPage) {
    id
    action
    userEmail
    timestamp
    details
  }
}
```

### Mutations

#### Request Data Export

```graphql
mutation RequestDataExport($userId: ID!) {
  requestDataExport(userId: $userId) {
    success
    message
    exportRequest {
      id
      email
      status
      token
      requestedAt
      downloadUrl
    }
    errors
  }
}
```

#### Request Data Erasure

```graphql
mutation RequestDataErasure($userId: ID!, $reason: String) {
  requestDataErasure(userId: $userId, reason: $reason) {
    success
    message
    erasureRequest {
      id
      email
      status
      reason
      requestedAt
      confirmationUrl
      metadata
    }
    errors
  }
}
```

#### Confirm Data Erasure

```graphql
mutation ConfirmDataErasure($token: String!) {
  confirmDataErasure(token: $token) {
    success
    message
    erasureRequest {
      id
      status
      confirmedAt
    }
    errors
  }
}
```

#### Record Consent

```graphql
mutation RecordConsent($userId: ID!, $consentType: String!, $consentData: JSON!) {
  recordConsent(userId: $userId, consentType: $consentType, consentData: $consentData) {
    success
    message
    consentRecord {
      id
      consentType
      granted
      consentText
      grantedAt
    }
    errors
  }
}
```

#### Withdraw Consent

```graphql
mutation WithdrawConsent($userId: ID!, $consentType: String!) {
  withdrawConsent(userId: $userId, consentType: $consentType) {
    success
    message
    consentRecord {
      id
      consentType
      granted
      withdrawnAt
    }
    errors
  }
}
```

## Consent Types

The following consent types are supported:

- `data_processing` - General data processing consent
- `marketing` - Marketing communications consent
- `analytics` - Analytics tracking consent
- `cookies` - Cookie usage consent
- `newsletter` - Newsletter subscription consent
- `third_party_sharing` - Third-party data sharing consent

## Error Handling

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "errors": ["Detailed error message"]
}
```

Common HTTP status codes:

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Unprocessable Entity
- `500` - Internal Server Error

## Rate Limiting

GDPR endpoints are subject to rate limiting:
- 100 requests per hour per user for export/erasure requests
- 1000 requests per hour for status and consent endpoints

## Security Considerations

1. **Authentication Required**: All endpoints require valid API authentication
2. **User Isolation**: Users can only access their own data unless they're administrators
3. **Admin Protection**: Administrator accounts cannot be erased
4. **Audit Trail**: All GDPR actions are logged for compliance
5. **Secure Tokens**: Export and erasure tokens are cryptographically secure
6. **Data Minimization**: Only necessary data is included in exports

## Implementation Examples

### JavaScript/Fetch

```javascript
// Request data export
const exportResponse = await fetch('/api/v1/gdpr/data-export/123', {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer YOUR_API_TOKEN',
    'Content-Type': 'application/json'
  }
});

const exportData = await exportResponse.json();
console.log('Export request created:', exportData.data.token);

// Record consent
const consentResponse = await fetch('/api/v1/gdpr/consent/123', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_API_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    consent_type: 'marketing',
    consent_data: {
      granted: true,
      consent_text: 'I agree to receive marketing emails',
      ip_address: '192.168.1.1',
      user_agent: navigator.userAgent
    }
  })
});
```

### cURL

```bash
# Request data export
curl -X GET \
  'https://your-site.com/api/v1/gdpr/data-export/123' \
  -H 'Authorization: Bearer YOUR_API_TOKEN'

# Record consent
curl -X POST \
  'https://your-site.com/api/v1/gdpr/consent/123' \
  -H 'Authorization: Bearer YOUR_API_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "consent_type": "marketing",
    "consent_data": {
      "granted": true,
      "consent_text": "I agree to receive marketing emails",
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0..."
    }
  }'
```

## Compliance Features

### Data Export
- Complete user data in structured JSON format
- Includes all personal data categories
- Machine-readable format for easy processing
- Secure token-based download system

### Data Erasure
- Two-step confirmation process
- Comprehensive data anonymization
- Audit trail preservation
- Admin account protection

### Consent Management
- Granular consent types
- Timestamp tracking
- IP address and user agent logging
- Easy withdrawal process

### Audit Trail
- Complete action logging
- User identification
- Timestamp tracking
- Action details preservation

This GDPR API ensures your RailsPress installation is fully compliant with European data protection regulations while providing the flexibility to automate compliance processes.
