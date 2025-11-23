# API Reference - Quick Guide

Fast reference for all Appmelia Bloom API endpoints.

## Base URL
```
Development: http://localhost:3000
Production: https://bloom.appmelia.com
```

---

## Sessions API

### Create Session
```http
POST /api/sessions
Content-Type: application/json

{
  "userId": "string",
  "organizationId": "string"
}
```

**Response:**
```json
{
  "sessionId": "sess_abc123",
  "greeting": "Hello! I'm Melissa...",
  "status": "active"
}
```

**Status Codes:**
- `200` - Success
- `400` - Invalid user/organization
- `500` - Server error

---

### Get User Sessions
```http
GET /api/sessions?userId={userId}
```

**Response:**
```json
{
  "sessions": [
    {
      "id": "sess_abc123",
      "status": "completed",
      "startedAt": "2024-01-15T10:00:00Z",
      "completedAt": "2024-01-15T10:15:00Z",
      "roiReport": {
        "totalROI": 372.5,
        "confidenceScore": 87
      }
    }
  ]
}
```

---

### Get Session Details
```http
GET /api/sessions/{sessionId}
```

**Response:**
```json
{
  "id": "sess_abc123",
  "userId": "user_xyz",
  "organizationId": "org_456",
  "status": "active",
  "startedAt": "2024-01-15T10:00:00Z",
  "transcript": [...],
  "responses": [...],
  "metadata": {
    "phase": "metrics",
    "extractedMetrics": {...}
  }
}
```

---

### Update Session Status
```http
PATCH /api/sessions/{sessionId}
Content-Type: application/json

{
  "status": "completed" | "abandoned"
}
```

---

## Melissa Chat API

### Send Message
```http
POST /api/melissa/chat
Content-Type: application/json

{
  "sessionId": "sess_abc123",
  "message": "We process invoices manually"
}
```

**Response (JSON mode):**
```json
{
  "response": "Invoice processing - that's a great area...",
  "phase": "discovery",
  "progress": 25,
  "metrics": {
    "processName": "invoice processing",
    "processType": "financial"
  },
  "confidence": 0.85
}
```

**Response (Streaming mode):**
```
Content-Type: text/event-stream

data: {"token": "Invoice"}
data: {"token": " processing"}
data: {"token": " -"}
data: {"token": " that's"}
...
data: {"done": true, "phase": "discovery"}
```

**Status Codes:**
- `200` - Success
- `404` - Session not found
- `400` - Session not active
- `500` - Processing error

---

### Analyze Session
```http
POST /api/melissa/analyze
Content-Type: application/json

{
  "sessionId": "sess_abc123"
}
```

**Response:**
```json
{
  "completeness": 0.92,
  "dataQuality": 0.85,
  "confidence": 0.87,
  "missingFields": ["errorRate"],
  "recommendations": [
    "Consider asking about error rates for more accurate analysis"
  ]
}
```

---

## ROI Calculation API

### Calculate ROI
```http
POST /api/sessions/{sessionId}/calculate
Content-Type: application/json

{
  "inputs": {
    "weeklyHours": 40,
    "teamSize": 5,
    "hourlyRate": 75,
    "automationPercentage": 60,
    "initialInvestment": 50000,
    "timeline": 3
  },
  "options": {
    "discountRate": 0.10,
    "inflationRate": 0.03
  }
}
```

**Response:**
```json
{
  "roi": 372.5,
  "npv": 186420,
  "irr": 0.942,
  "paybackPeriod": 6.4,
  "tco": 98500,
  "confidenceScore": 87,
  "confidenceBreakdown": {
    "completeness": 95,
    "quality": 90,
    "historical": 80,
    "benchmarks": 85,
    "assumptions": 80
  },
  "sensitivity": {
    "criticalVariables": [
      {
        "name": "automationPercentage",
        "impact": 0.45,
        "optimisticNPV": 248000,
        "pessimisticNPV": 124000
      }
    ]
  }
}
```

**Status Codes:**
- `200` - Success
- `400` - Invalid inputs
- `404` - Session not found
- `500` - Calculation error

---

### Get Sensitivity Analysis
```http
GET /api/sessions/{sessionId}/sensitivity
```

**Response:**
```json
{
  "variables": [
    {
      "name": "automationPercentage",
      "baseValue": 60,
      "impact": 0.45,
      "range": {
        "min": 40,
        "max": 80
      },
      "npvRange": {
        "min": 124000,
        "max": 248000
      }
    }
  ],
  "tornadoDiagram": {
    "svg": "...",
    "data": [...]
  }
}
```

---

## Export API

### Export to PDF
```http
POST /api/sessions/{sessionId}/export
Content-Type: application/json

{
  "format": "pdf",
  "options": {
    "includeCharts": true,
    "includeSensitivity": true,
    "branding": true
  }
}
```

**Response:**
```json
{
  "url": "https://cdn.appmelia.com/exports/report_abc123.pdf",
  "expiresAt": "2024-01-16T10:00:00Z"
}
```

---

### Export to Excel
```http
POST /api/sessions/{sessionId}/export
Content-Type: application/json

{
  "format": "excel",
  "options": {
    "includeRawData": true,
    "includeCharts": true
  }
}
```

---

### Export to JSON
```http
GET /api/sessions/{sessionId}/export?format=json
```

**Response:**
```json
{
  "session": {...},
  "roiReport": {...},
  "calculations": {...},
  "sensitivity": {...},
  "metadata": {...}
}
```

---

## Benchmarks API

### Get Industry Benchmarks
```http
GET /api/benchmarks/{industry}
```

**Response:**
```json
{
  "industry": "technology",
  "benchmarks": [
    {
      "metric": "automation_potential",
      "value": 65,
      "unit": "percentage",
      "source": "Gartner 2023",
      "confidence": 0.85
    },
    {
      "metric": "average_roi",
      "value": 280,
      "unit": "percentage",
      "source": "Industry Survey",
      "confidence": 0.75
    }
  ]
}
```

**Industries Available:**
- `technology`
- `finance`
- `retail`
- `healthcare`
- `manufacturing`
- `services`

---

### Search Benchmarks
```http
GET /api/benchmarks?industry={industry}&metric={metric}
```

---

## Health & Status

### Health Check
```http
GET /api/health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "database": "connected",
  "ai": "ready",
  "uptime": 86400
}
```

---

## Authentication

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "user_xyz",
    "email": "user@example.com",
    "name": "John Doe",
    "organizationId": "org_456"
  }
}
```

---

### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password",
  "name": "John Doe",
  "organizationName": "Acme Corp"
}
```

---

## Error Responses

All errors follow this format:
```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": {...},
  "timestamp": "2024-01-15T10:00:00Z"
}
```

**Common Error Codes:**
- `INVALID_INPUT` - Request validation failed
- `NOT_FOUND` - Resource not found
- `UNAUTHORIZED` - Authentication required
- `FORBIDDEN` - Insufficient permissions
- `RATE_LIMIT` - Too many requests
- `SERVER_ERROR` - Internal server error

---

## Rate Limiting

**Limits:**
- Chat API: 60 requests/minute per user
- Calculation API: 30 requests/minute per user
- Export API: 10 requests/minute per user

**Headers:**
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1642248000
```

---

## Webhooks (Future)

### Session Completed
```http
POST {webhook_url}
Content-Type: application/json

{
  "event": "session.completed",
  "sessionId": "sess_abc123",
  "userId": "user_xyz",
  "roiSummary": {
    "roi": 372.5,
    "confidence": 87
  },
  "timestamp": "2024-01-15T10:15:00Z"
}
```

---

## Testing Endpoints

### Test Data Available
```
GET /api/test/users - Get test users
GET /api/test/sessions - Get test sessions
POST /api/test/reset - Reset test data
```

**Note:** Only available in development mode

---

## File Locations

- Session Routes: `app/api/sessions/`
- Melissa Routes: `app/api/melissa/`
- ROI Routes: `app/api/sessions/{id}/calculate/`
- Export Routes: `app/api/sessions/{id}/export/`
- Benchmark Routes: `app/api/benchmarks/`

---

## Postman Collection

Import the collection:
```bash
curl -o bloom-api.postman_collection.json \
  https://raw.githubusercontent.com/appmelia/bloom/main/postman/collection.json
```

---

## Quick Test

```bash
# Create session
SESSION=$(curl -X POST http://localhost:3000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{"userId":"demo-user","organizationId":"demo-org"}' \
  | jq -r '.sessionId')

# Send message
curl -X POST http://localhost:3000/api/melissa/chat \
  -H "Content-Type: application/json" \
  -d "{\"sessionId\":\"$SESSION\",\"message\":\"Invoice processing\"}"

# Calculate ROI
curl -X POST http://localhost:3000/api/sessions/$SESSION/calculate \
  -H "Content-Type: application/json" \
  -d '{"inputs":{"weeklyHours":40,"teamSize":5,"hourlyRate":75}}'
```
