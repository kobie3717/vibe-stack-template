# Deployment & Security Checklist

**Project:** PROJECT_NAME
**Last Updated:** YYYY-MM-DD

---

## Pre-Deployment Checklist

Run these commands before ANY deployment:

### 1. Full Stack Verification

```bash
# Must pass before deployment
npm run check:full

# Expected output: "FULL STACK CHECK PASSED"
```

### 2. Security Verification

```bash
# Must pass before deployment
npm run check:security

# Expected: 0 failures, warnings are acceptable
```

### 3. Contract Verification

```bash
# Must pass if API contracts changed
npm run contract:check

# Expected: "Contract check passed"
```

### 4. Environment Validation

```bash
# Verify all required env vars are set
npm run validate:env

# Expected: All required variables present
```

---

## Staging Deployment

### Pre-Staging

```bash
# 1. Verify all checks pass
npm run check:full
npm run check:security

# 2. Build production assets
cd backend && npm run build
cd frontend && npm run build

# 3. Run database migrations (if any)
cd backend && npm run db:migrate
```

### Deploy to Staging

```bash
# 1. Pull latest code
git pull origin main

# 2. Install dependencies
npm ci

# 3. Build
npm run build --workspaces

# 4. Restart services
pm2 reload ecosystem.config.cjs

# 5. Verify health
curl https://staging.DOMAIN/health?simple=true
# Expected: OK or DEGRADED
```

### Post-Staging Verification

```bash
# 1. Run smoke tests against staging
PLAYWRIGHT_BASE_URL=https://staging.DOMAIN npx playwright test --project=chromium

# 2. Check logs for errors
pm2 logs --lines 50 --nostream | grep -i error
```

---

## Production Deployment

### Pre-Production Checklist

- [ ] All staging tests passed
- [ ] `check:full` passes locally
- [ ] `check:security` passes with 0 failures
- [ ] Database backup taken
- [ ] Team notified of deployment window

### Deploy to Production

```bash
# 1. Create backup
./scripts/backup-database.sh

# 2. Pull and build
git pull origin main
npm ci
npm run build --workspaces

# 3. Run migrations
cd backend && npm run db:migrate

# 4. Zero-downtime reload
pm2 reload ecosystem.config.cjs --update-env

# 5. Verify health immediately
curl https://DOMAIN/health
# Verify: status is "ok" or "degraded"

# 6. Monitor logs for 5 minutes
pm2 logs --lines 100
```

### Post-Production Verification

```bash
# 1. Health check
curl https://DOMAIN/health

# 2. Verify critical endpoints
curl -s https://DOMAIN/api/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid","password":"invalid"}' | jq .error
# Expected: error response (not 500)

# 3. Check error rate in logs
pm2 logs --lines 200 --nostream | grep -c "error"
# Should be low/zero
```

---

## Rollback Procedure

### Immediate Rollback (< 5 min)

```bash
# 1. Revert to previous commit
git checkout HEAD~1

# 2. Rebuild
npm ci
npm run build --workspaces

# 3. Restart
pm2 reload ecosystem.config.cjs

# 4. Verify
curl https://DOMAIN/health?simple=true
```

### Database Rollback

```bash
# 1. Stop application
pm2 stop all

# 2. Restore database from backup
./scripts/restore-database.sh /path/to/backup.sql

# 3. Checkout previous code version
git checkout <previous-tag>

# 4. Rebuild and restart
npm ci
npm run build --workspaces
pm2 restart all

# 5. Verify
curl https://DOMAIN/health
```

---

## Security Verification Commands

### CORS Configuration

```bash
# Test allowed origin
curl -s -I -X OPTIONS https://DOMAIN/api/auth/login \
  -H "Origin: https://DOMAIN" \
  -H "Access-Control-Request-Method: POST" | grep -i access-control

# Test blocked origin (should NOT have access-control headers)
curl -s -I -X OPTIONS https://DOMAIN/api/auth/login \
  -H "Origin: https://evil.com" \
  -H "Access-Control-Request-Method: POST" | grep -i access-control
```

### Rate Limiting

```bash
# Make 6 rapid login attempts (should be rate limited after 5)
for i in {1..6}; do
  curl -s -X POST https://DOMAIN/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"wrong"}' | jq -r '.error // .success'
done
# Last response should contain "rate" or "too many"
```

### JWT Validation

```bash
# Test invalid token rejection
curl -s https://DOMAIN/api/protected-endpoint \
  -H "Authorization: Bearer invalid-token" | jq .error
# Expected: AUTH_REQUIRED or similar
```

### Webhook HMAC (if applicable)

```bash
# Test invalid signature rejection
curl -s -X POST https://DOMAIN/webhook \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=invalid" \
  -d '{}' -w "\nHTTP: %{http_code}\n"
# Expected: HTTP 401 or 403
```

---

## Monitoring Alerts

### Critical (Page immediately)

- Health endpoint returns `unhealthy`
- Error rate > 5% for 5 minutes
- Response time p99 > 5s

### Warning (Review within 1 hour)

- Health endpoint returns `degraded`
- Error rate > 1% for 15 minutes
- Memory usage > 80%

---

## Emergency Contacts

| Role | Contact |
|------|---------|
| On-call Engineer | [PLACEHOLDER] |
| DevOps Lead | [PLACEHOLDER] |
| Security | [PLACEHOLDER] |

---

## Checklist Sign-off

Before deploying to production, confirm:

- [ ] `npm run check:full` passes
- [ ] `npm run check:security` passes (0 failures)
- [ ] Database backup completed
- [ ] Staging deployment verified
- [ ] Rollback procedure reviewed
- [ ] Team notified

**Deployed by:** _______________
**Date:** _______________
**Commit:** _______________
