# Image Optimization API Documentation

## Overview

The RailsPress Image Optimization API provides comprehensive endpoints for managing image optimization, analytics, and bulk operations. The API supports both REST and GraphQL interfaces.

## Base URL

```
REST API: /api/v1/image_optimization
GraphQL: /graphql
```

## Authentication

All API endpoints require authentication. Include your API token in the request headers:

```
Authorization: Bearer YOUR_API_TOKEN
```

## REST API Endpoints

### 1. Analytics Overview

**GET** `/api/v1/image_optimization/analytics`

Returns comprehensive optimization statistics.

**Response:**
```json
{
  "success": true,
  "data": {
    "overview": {
      "total_optimizations": 1250,
      "successful_optimizations": 1180,
      "failed_optimizations": 45,
      "skipped_optimizations": 25,
      "total_bytes_saved": 52428800,
      "total_size_saved_mb": 50.0,
      "average_size_reduction": 35.5,
      "average_processing_time": 1.2,
      "today_optimizations": 15,
      "this_week_optimizations": 85,
      "this_month_optimizations": 320
    },
    "recent_optimizations": [...],
    "compression_level_stats": {
      "lossy": 850,
      "ultra": 280,
      "lossless": 50
    },
    "optimization_type_stats": {
      "upload": 1000,
      "bulk": 200,
      "manual": 30,
      "regenerate": 20
    }
  }
}
```

### 2. Detailed Report

**GET** `/api/v1/image_optimization/report`

Returns detailed optimization report with optional date filtering.

**Parameters:**
- `start_date` (optional): Start date (YYYY-MM-DD)
- `end_date` (optional): End date (YYYY-MM-DD)

**Response:**
```json
{
  "success": true,
  "data": {
    "report": {
      "total_optimizations": 500,
      "successful_optimizations": 475,
      "failed_optimizations": 15,
      "skipped_optimizations": 10,
      "total_bytes_saved": 20971520,
      "total_size_saved_mb": 20.0,
      "average_size_reduction": 32.5,
      "average_processing_time": 1.1,
      "compression_level_breakdown": {...},
      "optimization_type_breakdown": {...},
      "daily_optimizations": {...},
      "top_users": [...],
      "top_tenants": [...]
    },
    "date_range": {
      "start_date": "2024-01-01",
      "end_date": "2024-01-31"
    }
  }
}
```

### 3. Failed Optimizations

**GET** `/api/v1/image_optimization/failed`

Returns list of failed optimizations with pagination.

**Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "failed_optimizations": [
      {
        "id": 123,
        "filename": "corrupted-image.jpg",
        "content_type": "image/jpeg",
        "original_size": 2048000,
        "optimized_size": 2048000,
        "bytes_saved": 0,
        "size_reduction_percentage": 0.0,
        "compression_level": "lossy",
        "status": "failed",
        "error_message": "Invalid image format",
        "user": {
          "id": 1,
          "email": "user@example.com"
        },
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_count": 45
    }
  }
}
```

### 4. Top Savings

**GET** `/api/v1/image_optimization/top_savings`

Returns images with the highest optimization savings.

**Parameters:**
- `limit` (optional): Number of results (default: 50)

**Response:**
```json
{
  "success": true,
  "data": {
    "top_savings": [
      {
        "id": 456,
        "filename": "large-banner.jpg",
        "original_size": 5242880,
        "optimized_size": 2097152,
        "bytes_saved": 3145728,
        "size_reduction_percentage": 60.0,
        "size_reduction_mb": 3.0,
        "compression_level": "ultra",
        "processing_time": 2.5,
        "user": {
          "id": 2,
          "email": "admin@example.com"
        }
      }
    ]
  }
}
```

### 5. User Statistics

**GET** `/api/v1/image_optimization/user_stats`

Returns optimization statistics by user.

**Response:**
```json
{
  "success": true,
  "data": {
    "user_stats": {
      "1": 150,
      "2": 200,
      "3": 75
    },
    "top_users": [
      ["2", 200],
      ["1", 150],
      ["3", 75]
    ]
  }
}
```

### 6. Compression Levels

**GET** `/api/v1/image_optimization/compression_levels`

Returns available compression levels and their usage statistics.

**Response:**
```json
{
  "success": true,
  "data": {
    "available_levels": {
      "lossless": {
        "name": "Lossless",
        "description": "Maximum quality, minimal compression",
        "quality": 95,
        "compression_level": 1,
        "lossy": false,
        "expected_savings": "5-15%",
        "recommended_for": "Professional photography, high-quality images"
      },
      "lossy": {
        "name": "Lossy",
        "description": "Balanced quality and compression",
        "quality": 85,
        "compression_level": 6,
        "lossy": true,
        "expected_savings": "25-40%",
        "recommended_for": "General web images, blog posts"
      },
      "ultra": {
        "name": "Ultra",
        "description": "Maximum compression, slight quality loss",
        "quality": 75,
        "compression_level": 9,
        "lossy": true,
        "expected_savings": "40-60%",
        "recommended_for": "High-traffic sites, mobile optimization"
      }
    },
    "usage_stats": {
      "lossy": 850,
      "ultra": 280,
      "lossless": 50
    }
  }
}
```

### 7. Performance Metrics

**GET** `/api/v1/image_optimization/performance`

Returns detailed performance metrics.

**Response:**
```json
{
  "success": true,
  "data": {
    "average_processing_time": 1.2,
    "average_size_reduction": 35.5,
    "total_processing_time": 1500.0,
    "total_bytes_saved": 52428800,
    "total_size_saved_mb": 50.0
  }
}
```

### 8. Bulk Optimization

**POST** `/api/v1/image_optimization/bulk_optimize`

Starts bulk optimization of unoptimized images.

**Response:**
```json
{
  "success": true,
  "message": "Queued 25 images for optimization",
  "data": {
    "queued_count": 25
  }
}
```

### 9. Regenerate Variants

**POST** `/api/v1/image_optimization/regenerate_variants`

Regenerates variants for a specific image.

**Parameters:**
- `medium_id`: ID of the medium to regenerate variants for

**Response:**
```json
{
  "success": true,
  "message": "Queued variant regeneration for medium 123",
  "data": {
    "medium_id": 123
  }
}
```

### 10. Clear Logs

**DELETE** `/api/v1/image_optimization/clear_logs`

Clears all optimization logs (requires confirmation).

**Parameters:**
- `confirm`: Must be "yes" to confirm

**Response:**
```json
{
  "success": true,
  "message": "All optimization logs have been cleared"
}
```

### 11. Export Data

**GET** `/api/v1/image_optimization/export`

Exports optimization data as CSV.

**Parameters:**
- `start_date` (optional): Start date (YYYY-MM-DD)
- `end_date` (optional): End date (YYYY-MM-DD)

**Response:** CSV file download

## GraphQL API

### Queries

#### Get Optimization Analytics

```graphql
query {
  imageOptimizationAnalytics {
    totalOptimizations
    successfulOptimizations
    failedOptimizations
    skippedOptimizations
    totalBytesSaved
    totalSizeSavedMb
    averageSizeReduction
    averageProcessingTime
    todayOptimizations
    thisWeekOptimizations
    thisMonthOptimizations
  }
}
```

#### Get Optimization Logs

```graphql
query {
  imageOptimizationLogs(limit: 20, status: "success") {
    id
    filename
    originalSize
    optimizedSize
    bytesSaved
    sizeReductionPercentage
    compressionLevel
    compressionLevelName
    processingTime
    processingTimeFormatted
    status
    optimizationType
    user {
      id
      email
    }
    medium {
      id
      title
    }
    createdAt
  }
}
```

#### Get Failed Optimizations

```graphql
query {
  failedImageOptimizations(limit: 10) {
    id
    filename
    errorMessage
    status
    user {
      email
    }
    createdAt
  }
}
```

#### Get Top Savings

```graphql
query {
  topImageSavings(limit: 5) {
    id
    filename
    originalSize
    optimizedSize
    bytesSaved
    sizeReductionPercentage
    sizeReductionMb
    compressionLevel
    processingTime
    user {
      email
    }
  }
}
```

#### Get Compression Levels

```graphql
query {
  compressionLevels {
    name
    description
    quality
    compressionLevel
    lossy
    expectedSavings
    recommendedFor
  }
}
```

#### Get Optimization Report

```graphql
query {
  imageOptimizationReport(startDate: "2024-01-01", endDate: "2024-01-31") {
    totalOptimizations
    successfulOptimizations
    failedOptimizations
    skippedOptimizations
    totalBytesSaved
    totalSizeSavedMb
    averageSizeReduction
    averageProcessingTime
    compressionLevelBreakdown
    optimizationTypeBreakdown
    dailyOptimizations
    topUsers
    topTenants
  }
}
```

### Mutations

#### Bulk Optimize Images

```graphql
mutation {
  bulkOptimizeImages
}
```

#### Regenerate Image Variants

```graphql
mutation {
  regenerateImageVariants(mediumId: "123")
}
```

#### Clear Optimization Logs

```graphql
mutation {
  clearOptimizationLogs(confirm: true)
}
```

## Error Handling

All API endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "errors": {
    "field": ["Specific error message"]
  }
}
```

Common HTTP status codes:
- `200`: Success
- `400`: Bad Request (invalid parameters)
- `401`: Unauthorized (missing or invalid token)
- `403`: Forbidden (insufficient permissions)
- `404`: Not Found
- `500`: Internal Server Error

## Rate Limiting

API requests are rate limited to prevent abuse:
- **Authenticated users**: 1000 requests per hour
- **Unauthenticated requests**: 100 requests per hour

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Examples

### JavaScript/Fetch

```javascript
// Get analytics
const response = await fetch('/api/v1/image_optimization/analytics', {
  headers: {
    'Authorization': 'Bearer YOUR_API_TOKEN',
    'Content-Type': 'application/json'
  }
});
const data = await response.json();
console.log(data.data.overview);

// Start bulk optimization
const bulkResponse = await fetch('/api/v1/image_optimization/bulk_optimize', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_API_TOKEN',
    'Content-Type': 'application/json'
  }
});
const bulkData = await bulkResponse.json();
console.log(bulkData.message);
```

### cURL

```bash
# Get analytics
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type: application/json" \
     https://your-domain.com/api/v1/image_optimization/analytics

# Start bulk optimization
curl -X POST \
     -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type: application/json" \
     https://your-domain.com/api/v1/image_optimization/bulk_optimize
```

### GraphQL Client

```javascript
import { request } from 'graphql-request';

const query = `
  query {
    imageOptimizationAnalytics {
      totalOptimizations
      successfulOptimizations
      totalBytesSaved
      averageSizeReduction
    }
  }
`;

const data = await request('/graphql', query);
console.log(data.imageOptimizationAnalytics);
```

## Webhooks

The system supports webhooks for optimization events:

### Available Events

- `optimization.started`: When optimization begins
- `optimization.completed`: When optimization finishes successfully
- `optimization.failed`: When optimization fails
- `bulk_optimization.started`: When bulk optimization begins
- `bulk_optimization.completed`: When bulk optimization finishes

### Webhook Payload

```json
{
  "event": "optimization.completed",
  "data": {
    "medium_id": 123,
    "upload_id": 456,
    "user_id": 1,
    "filename": "image.jpg",
    "original_size": 2048000,
    "optimized_size": 1536000,
    "bytes_saved": 512000,
    "size_reduction_percentage": 25.0,
    "compression_level": "lossy",
    "processing_time": 1.2,
    "variants_generated": ["webp", "avif"],
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

## SDKs and Libraries

### JavaScript/Node.js

```bash
npm install @railspress/image-optimization-sdk
```

```javascript
import { ImageOptimizationClient } from '@railspress/image-optimization-sdk';

const client = new ImageOptimizationClient({
  apiKey: 'YOUR_API_KEY',
  baseUrl: 'https://your-domain.com/api/v1'
});

// Get analytics
const analytics = await client.getAnalytics();

// Start bulk optimization
const result = await client.bulkOptimize();
```

### Python

```bash
pip install railspress-image-optimization
```

```python
from railspress_image_optimization import ImageOptimizationClient

client = ImageOptimizationClient(
    api_key='YOUR_API_KEY',
    base_url='https://your-domain.com/api/v1'
)

# Get analytics
analytics = client.get_analytics()

# Start bulk optimization
result = client.bulk_optimize()
```

## Support

For API support and questions:
- **Documentation**: https://docs.railspress.com/api/image-optimization
- **Support Email**: api-support@railspress.com
- **GitHub Issues**: https://github.com/railspress/railspress/issues
