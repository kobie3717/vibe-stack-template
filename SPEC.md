# SPEC.md

Product Specification — Version 1.0

**Last Updated:** YYYY-MM-DD

---

## Golden Rule

If code and SPEC.md disagree, **the code is BROKEN**.

This document is the source of truth for product behavior.

> **📝 This is a blank canvas.** All sections below are intentionally left as placeholders for you to fill in with your project's specifics. The structure shows you what to document — replace the TODOs with your actual specs.

---

## 1. Project Overview

### 1.1 Description

<!-- TODO: Replace with your project description -->
[PROJECT_NAME] is a [brief description of what it does].

### 1.2 Target Users

- Primary: [describe primary users]
- Secondary: [describe secondary users]

### 1.3 Key Features

1. [Feature 1]
2. [Feature 2]
3. [Feature 3]

---

## 2. Architecture

### 2.1 Stack

| Component | Technology |
|-----------|------------|
| Frontend | React + Vite |
| Backend | Node.js + Express |
| Database | PostgreSQL |
| Cache | Redis |
| Auth | JWT |

### 2.2 Service Map

```
[Client] → [Frontend:FRONTEND_PORT] → [Backend:BACKEND_PORT] → [Database]
                                                            → [Redis]
```

---

## 3. API Contracts

### 3.1 Response Envelope

All API responses follow this format:

```typescript
// Success
{
  success: true,
  data: T
}

// Error
{
  success: false,
  error: string,
  code?: string  // Machine-readable error code
}
```

### 3.2 Error Codes

| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `AUTH_REQUIRED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

### 3.3 Endpoints

<!-- TODO: Document your API endpoints -->

#### Authentication

```
POST /api/auth/login
  Body: { email: string, password: string }
  Response: { user: User, token: string }
  Errors: AUTH_REQUIRED, VALIDATION_ERROR

POST /api/auth/register
  Body: { email: string, password: string, name: string }
  Response: { user: User, token: string }
  Errors: VALIDATION_ERROR

POST /api/auth/logout
  Headers: Authorization: Bearer <token>
  Response: { success: true }
```

---

## 4. Health Check

### 4.1 Schema

The `/health` endpoint returns:

```typescript
{
  status: 'ok' | 'degraded' | 'unhealthy',
  timestamp: string,  // ISO 8601
  version: string,    // Package version
  checks: {
    database: { status: 'ok' | 'error', latencyMs?: number, error?: string },
    redis: { status: 'ok' | 'error', latencyMs?: number, error?: string }
  },
  uptime: number  // Seconds
}
```

### 4.2 Status Logic

| Condition | Status | HTTP Code |
|-----------|--------|-----------|
| All checks pass | `ok` | 200 |
| Database OK, Redis fails | `degraded` | 200 |
| Database fails | `unhealthy` | 503 |

### 4.3 Simple Mode

`GET /health?simple=true` returns plain text:
- `OK`
- `DEGRADED`
- `UNHEALTHY`

---

## 5. Invariants

Rules that must ALWAYS hold true. Violating these is a critical bug.

### INV-1: [Name]
<!-- TODO: Define your invariants -->
[Description of what must always be true]

### INV-2: [Name]
[Description of what must always be true]

---

## 6. State Machines

<!-- TODO: Define state machines for your entities -->

### 6.1 [Entity] States

```
DRAFT → ACTIVE → COMPLETED
          ↓
       CANCELLED
```

| Transition | Allowed From | Condition |
|------------|--------------|-----------|
| activate | DRAFT | [conditions] |
| complete | ACTIVE | [conditions] |
| cancel | ACTIVE | [conditions] |

---

## 7. Security Requirements

### 7.1 Authentication

- JWT tokens with 7-day expiry
- Passwords hashed with bcrypt (cost factor 12)
- HTTP-only cookies for token storage

### 7.2 Rate Limiting

| Endpoint | Limit |
|----------|-------|
| `/api/auth/login` | 5 per 15 minutes per IP |
| `/api/*` | 100 per minute per user |

### 7.3 CORS

Allowed origins:
- Production: `https://DOMAIN`
- Development: `http://localhost:FRONTEND_PORT`

---

## 8. Testing Requirements

### 8.1 Minimum Coverage

| Type | Target |
|------|--------|
| Unit tests | 70% |
| Integration tests | Critical paths |
| E2E tests | Happy paths |

### 8.2 Required Test Scenarios

- [ ] User registration and login
- [ ] [Your critical flow 1]
- [ ] [Your critical flow 2]

---

## 9. Deployment

### 9.1 Environment Variables

Required in production:

```bash
NODE_ENV=production
DATABASE_URL=<required>
JWT_SECRET=<required, min 32 chars>
REDIS_URL=<required>
```

### 9.2 Health Checks

Load balancer should poll:
- `GET /health?simple=true`
- Healthy: response is `OK` or `DEGRADED`
- Unhealthy: response is `UNHEALTHY` or timeout

---

## Changelog

### v1.0 (YYYY-MM-DD)
- Initial specification
