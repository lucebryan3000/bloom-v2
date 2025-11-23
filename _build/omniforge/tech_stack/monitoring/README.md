# Monitoring Phase Bootstrap Scripts

This directory contains bootstrap scripts for the **Monitoring & Operations** layer - system health checks, user settings, and feature flag management. These scripts set up:

1. **Health Endpoints** - System status and performance monitoring
2. **Settings UI** - User preferences and configuration management
3. **Feature Flags** - Controlled feature rollout and A/B testing

## Scripts

### health-endpoints.sh

Sets up monitoring and health check endpoints.

**Creates:**
- `src/api/monitoring/health.ts` - GET /api/monitoring/health endpoint
- `src/api/monitoring/metrics.ts` - GET /api/monitoring/metrics endpoint

**Health Endpoint Response:**

```typescript
interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy'
  timestamp: string

  // Dependencies
  database: { status, latency_ms? }
  ai_service: { status, latency_ms? }

  // System metrics
  memory: { used_mb, available_mb, usage_percent }
  uptime: { process_seconds, system_seconds }

  version: string
}
```

**HTTP Status Codes:**
- `200 OK` - System healthy
- `503 Service Unavailable` - System degraded or unhealthy

**Use Cases:**
- Kubernetes liveness probes
- Uptime monitoring services
- Load balancer health checks
- Alerting systems (PagerDuty, Datadog)
- Status pages

**Checks Performed:**

1. **Database Connectivity**
   - Attempts simple query (SELECT 1)
   - Records latency
   - Returns status and timing

2. **AI Service Availability**
   - Checks Anthropic API connectivity
   - Measures response time
   - Monitors API rate limits

3. **Memory Usage**
   - Heap memory utilization
   - Available system memory
   - Usage percentage

4. **Uptime Tracking**
   - Process uptime (since Node.js start)
   - System uptime (since OS boot)

**Example Usage:**

```bash
# Check health
curl http://localhost:3000/api/monitoring/health

# Kubernetes liveness probe
livenessProbe:
  httpGet:
    path: /api/monitoring/health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5
```

---

### Metrics Endpoint Response

```typescript
interface AppMetrics {
  timestamp: string

  // Session metrics
  sessions: {
    total_active: number
    created_today: number
    average_duration_minutes: number
  }

  // Business case metrics
  business_cases: {
    total_created: number
    created_today: number
    average_confidence: number
    awaiting_review: number
    exported: number
  }

  // AI interaction metrics
  ai_interactions: {
    total_messages: number
    messages_today: number
    average_response_time_ms: number
    error_rate_percent: number
  }

  // Export metrics
  exports: {
    total_count: number
    by_format: { pdf, excel, json, markdown }
    today: number
  }

  // Review queue metrics
  review_queue: {
    pending_items: number
    by_severity: { critical, warning, info }
    average_resolution_time_hours: number
  }

  // Performance metrics
  performance: {
    api_response_time_p50_ms: number
    api_response_time_p95_ms: number
    database_query_time_p50_ms: number
    database_query_time_p95_ms: number
    cache_hit_rate_percent: number
  }
}
```

**Implementation Notes:**
- Metrics aggregate data from application logs and database
- Timestamps track measurements for trending
- Percentile metrics (p50, p95) show performance distribution
- Daily metrics reset at midnight UTC

**Reference:** PRD Section 6.13 - Monitoring & Observability

---

### settings-ui.sh

Sets up user settings and preferences management.

**Creates:**
- `src/lib/settings/types.ts` - Settings type definitions and schemas
- `src/lib/settings/manager.ts` - Settings CRUD operations
- `src/api/settings/route.ts` - GET/POST settings API endpoint

**User Settings Structure:**

```typescript
interface UserSettings {
  user_id: string

  // Export preferences
  export_preferences: {
    default_format: 'pdf' | 'excel' | 'json' | 'markdown'
    include_logo: boolean
    include_charts: boolean
    include_appendix: boolean
    page_orientation: 'portrait' | 'landscape'
    footer_text?: string
  }

  // Notifications
  notification_preferences: {
    email_on_business_case_ready: boolean
    email_on_review_needed: boolean
    email_on_export_complete: boolean
    daily_digest: boolean
    digest_time: string  // HH:MM format
  }

  // Display
  display_preferences: {
    theme: 'light' | 'dark' | 'system'
    language: 'en' | 'es' | 'fr' | 'de'
    timezone: string  // e.g., 'America/New_York'
    date_format: 'MM/DD/YYYY' | 'DD/MM/YYYY' | 'YYYY-MM-DD'
    currency: 'USD' | 'EUR' | 'GBP' | 'CAD' | 'AUD'
  }

  // Analysis preferences
  analysis_preferences: {
    confidence_threshold_for_review: number  // 0-1
    confidence_threshold_for_export: number  // 0-1
    default_roi_scenarios: ('conservative' | 'base' | 'aggressive')[]
    enable_contradiction_detection: boolean
    enable_outlier_detection: boolean
  }

  updated_at: Date
}
```

**Key Functions:**

```typescript
// Fetch settings
getUserSettings(userId: string): Promise<UserSettings>

// Update all settings
updateUserSettings(userId: string, updates: Partial<UserSettings>): Promise<UserSettings>

// Update specific category
updateExportPreferences(userId: string, prefs): Promise<UserSettings>
updateNotificationPreferences(userId: string, prefs): Promise<UserSettings>
updateDisplayPreferences(userId: string, prefs): Promise<UserSettings>
updateAnalysisPreferences(userId: string, prefs): Promise<UserSettings>

// Reset to defaults
resetToDefaults(userId: string): Promise<UserSettings>
```

**API Endpoints:**

```
GET /api/settings
  → Returns user settings

POST /api/settings
  Body: { export_preferences: {...}, ... }
  → Updates and returns user settings
```

**Example Usage:**

```typescript
// Get settings
const settings = await fetch('/api/settings').then(r => r.json())

// Update export format
await fetch('/api/settings', {
  method: 'POST',
  body: JSON.stringify({
    export_preferences: {
      default_format: 'excel'
    }
  })
})

// Update analysis threshold
await fetch('/api/settings', {
  method: 'POST',
  body: JSON.stringify({
    analysis_preferences: {
      confidence_threshold_for_export: 0.8
    }
  })
})
```

**Default Settings:**

```typescript
{
  export_preferences: {
    default_format: 'pdf',
    include_logo: true,
    include_charts: true,
    include_appendix: true,
    page_orientation: 'portrait'
  },
  notification_preferences: {
    email_on_business_case_ready: true,
    email_on_review_needed: true,
    email_on_export_complete: false,
    daily_digest: false,
    digest_time: '09:00'
  },
  display_preferences: {
    theme: 'system',
    language: 'en',
    timezone: 'UTC',
    date_format: 'MM/DD/YYYY',
    currency: 'USD'
  },
  analysis_preferences: {
    confidence_threshold_for_review: 0.6,
    confidence_threshold_for_export: 0.75,
    default_roi_scenarios: ['base'],
    enable_contradiction_detection: true,
    enable_outlier_detection: true
  }
}
```

**Integration:**
- Export system reads `export_preferences` for format/layout options
- Confidence engine respects `analysis_preferences` thresholds
- UI uses `display_preferences` for localization and appearance
- Notification system checks `notification_preferences` for routing

**Reference:** PRD Section 6.13 - Settings & User Preferences

---

### feature-flags.sh

Sets up feature flag system for controlled feature rollout.

**Creates:**
- `src/lib/flags/types.ts` - Feature flag types and constants
- `src/lib/flags/manager.ts` - Flag evaluation and management
- `src/api/flags/route.ts` - Feature flag API
- `src/hooks/useFeatureFlag.ts` - React hook for flag evaluation

**Feature Flag Definition:**

```typescript
interface FeatureFlag {
  id: string
  name: string
  description: string
  status: 'disabled' | 'enabled' | 'rollout' | 'experiment'

  // Rollout strategy
  rollout_strategy?: {
    type: 'percentage' | 'user_list' | 'user_segment'
    percentage?: number         // For percentage rollout
    user_ids?: string[]        // For explicit user list
    segment_rules?: Record<string, boolean>  // For segments
  }

  // Explicit targeting
  enabled_for_users: string[]
  disabled_for_users: string[]
  targeting_rules: Array<{
    name: string
    condition: string
    enabled: boolean
  }>

  // Metadata
  owner: string
  created_at: Date
  updated_at: Date
  enabled_at?: Date
  disabled_at?: Date

  // Tracking
  track_usage: boolean
  track_performance: boolean

  // Tags
  tags: string[]  // e.g., ['beta', 'ai', 'core']
}
```

**Built-in Features:**

```typescript
BLOOM_FEATURES = {
  // Core features
  MELISSA_AI: 'melissa-ai',
  ROI_ENGINE: 'roi-engine',
  CONFIDENCE_SCORING: 'confidence-scoring',
  HITL_REVIEW: 'hitl-review-queue',

  // Export features
  EXPORT_PDF: 'export-pdf',
  EXPORT_EXCEL: 'export-excel',
  EXPORT_JSON: 'export-json',
  EXPORT_MARKDOWN: 'export-markdown',

  // Advanced features
  ADVANCED_ROI_MODELING: 'advanced-roi-modeling',
  SCENARIO_ANALYSIS: 'scenario-analysis',
  COLLABORATIVE_REVIEW: 'collaborative-review',
  API_ACCESS: 'api-access',
}
```

**Evaluation Logic:**

```typescript
interface FeatureFlagContext {
  user_id: string
  organization_id?: string
  email?: string
  traits?: Record<string, any>
  custom_properties?: Record<string, any>
}

evaluateFlag(flagId: string, context: FeatureFlagContext): Promise<FeatureFlagResult>
```

**Evaluation Order:**
1. If explicitly disabled for user → disabled
2. If explicitly enabled for user → enabled
3. If flag status = enabled → enabled
4. If flag status = disabled → disabled
5. If flag status = rollout with percentage:
   - Hash user ID deterministically
   - Compare hash % 100 to percentage threshold
   - Result consistent for same user

**Percentage Rollout Logic:**

```typescript
function hashUserId(userId: string): number {
  // Deterministic hash - same user always gets same result
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    const char = userId.charCodeAt(i);
    hash = (hash << 5) - hash + char;
  }
  return Math.abs(hash);
}

// Enable feature for 50% of users
const isEnabled = (hashUserId(userId) % 100) < 50
```

**API Endpoints:**

```
GET /api/flags
  → List all feature flags

GET /api/flags?evaluate=1&flag_id=FEATURE&user_id=USER
  → Evaluate flag for user

POST /api/flags
  Body: { id, name, status, rollout_strategy, ... }
  → Create/update flag (admin only)
```

**React Hook Usage:**

```tsx
import { useFeatureFlag, FeatureFlagGuard } from '@/hooks/useFeatureFlag';

// Hook approach
function MyComponent() {
  const { enabled, loading } = useFeatureFlag('scenario-analysis', userId);

  if (loading) return <Loading />;
  if (!enabled) return <FeatureNotAvailable />;
  return <ScenarioAnalysisUI />;
}

// Guard component approach
<FeatureFlagGuard
  flagId="collaborative-review"
  userId={userId}
  fallback={<UnavailableMessage />}
>
  <CollaborativeReviewUI />
</FeatureFlagGuard>
```

**Use Cases:**

1. **Gradual Rollout**
   - Enable new feature for 10% of users
   - Monitor error rate and performance
   - Increase to 50%, then 100%

2. **A/B Testing**
   - Feature A vs Feature B variants
   - Track metrics for each variant
   - Winner determination

3. **Beta Features**
   - Enable for beta user program
   - Collect feedback before general release
   - Track adoption metrics

4. **Kill Switches**
   - Quickly disable problematic features
   - No deployment needed
   - Immediate effect

5. **Maintenance Windows**
   - Disable features during DB maintenance
   - Route users to alternative flows
   - Re-enable when ready

**Default Features:**

All core features are enabled by default:
- MELISSA_AI (enabled)
- ROI_ENGINE (enabled)
- CONFIDENCE_SCORING (enabled)
- HITL_REVIEW (enabled)
- Export formats (enabled)

Advanced features rollout gradually:
- SCENARIO_ANALYSIS (50% rollout)
- COLLABORATIVE_REVIEW (0% - upcoming)
- API_ACCESS (0% - upcoming)

**Reference:** PRD Section 6.13 - Feature Flags & Experimentation

---

## Monitoring Integration

These three systems work together for complete operational visibility:

```
Health Endpoints
  ↓ (system status)
Metrics Aggregation
  ↓ (performance data)
Settings & Feature Flags
  ↓ (user preferences and features)
Alerting & Dashboards
```

### Health Check Implementation

```typescript
// Kubernetes readiness probe
export async function GET(request: NextRequest) {
  const health = await checkHealth();

  if (health.status === 'healthy') {
    return NextResponse.json(health, { status: 200 });
  }

  return NextResponse.json(health, { status: 503 });
}
```

### Settings Persistence

- In development: Memory store (per-session)
- In production: Database table `user_settings`
  ```sql
  CREATE TABLE user_settings (
    user_id UUID PRIMARY KEY,
    preferences JSONB,
    updated_at TIMESTAMP DEFAULT NOW()
  );
  ```

### Feature Flag Rollout

```bash
# Deploy new feature in 'rollout' status
POST /api/flags
{
  "id": "scenario-analysis",
  "status": "rollout",
  "rollout_strategy": {
    "type": "percentage",
    "percentage": 10
  }
}

# After 24 hours, increase to 50%
# After 1 week, increase to 100%
# When mature, change to 'enabled'
```

## Environment & Configuration

```bash
# Enable monitoring
ENABLE_HEALTH_CHECKS="true"
ENABLE_METRICS="true"
ENABLE_SETTINGS="true"
ENABLE_FEATURE_FLAGS="true"

# Health check sensitivity
HEALTH_CHECK_TIMEOUT_MS="5000"
HEALTH_CHECK_INTERVAL_SECONDS="30"

# Feature flag defaults
FEATURE_FLAG_STORE="memory"  # or 'database'
```

## Dependencies

- **Packages:** `zod` (validation)
- **Database:** Optional (for persistent settings/flags)
- **Auth:** User ID from session

## Testing

```bash
# Test feature flag evaluation
pnpm test src/lib/flags/manager.test.ts

# Test settings management
pnpm test src/lib/settings/manager.test.ts

# Integration tests
pnpm test src/api/__tests__/monitoring.test.ts
```

## Observability Best Practices

1. **Health Checks**
   - Alert if status = unhealthy for 2+ checks
   - Track latency trends
   - Monitor database connection pool

2. **Metrics**
   - Track daily active users
   - Monitor export volume and formats
   - Watch review queue pending count
   - Alert if average_response_time_p95 > 1000ms

3. **Feature Flags**
   - Log flag evaluation decisions
   - Track feature adoption rates
   - Monitor error rates per feature
   - A/B test winner selection criteria

4. **User Settings**
   - Respect user choices (no forced settings)
   - Provide reset to defaults option
   - Validate settings on update
   - Audit settings changes

---

**Last Updated:** Bootstrap System v2.0
**Reference:** Bloom2 PRD Section 6.13 - Monitoring & Observability
