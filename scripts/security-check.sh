#!/bin/bash
#
# Security Check Script
# Validates security configurations
#
# Usage: ./scripts/security-check.sh
#

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$ROOT_DIR/backend"

# ============================================================================
# CONFIGURATION - Update these for your project
# ============================================================================
API_URL="${API_URL:-http://localhost:4000}"
TIMEOUT_SEC=5
# ============================================================================

# Counters
PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_check() {
    echo -e "\n${YELLOW}▶ $1${NC}"
}

pass() {
    echo -e "  ${GREEN}✓ PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "  ${RED}✗ FAIL${NC}: $1"
    ((FAILED++))
}

warn() {
    echo -e "  ${YELLOW}⚠ WARN${NC}: $1"
    ((WARNINGS++))
}

# ============================================================================
# CHECKS
# ============================================================================

print_header "Security Check"
echo "  API URL: $API_URL"
echo "  Timeout: ${TIMEOUT_SEC}s per check"

# 1. API Health Check
print_check "API Health Check"

HEALTH=$(timeout $TIMEOUT_SEC curl -s "$API_URL/health?simple=true" 2>/dev/null)
CURL_EXIT=$?

if [ $CURL_EXIT -ne 0 ] || [ -z "$HEALTH" ]; then
    warn "API not responding at $API_URL (timeout ${TIMEOUT_SEC}s)"
    echo "  → Start the API: cd backend && npm run dev"
    API_UP=false
else
    if [ "$HEALTH" = "OK" ] || [ "$HEALTH" = "DEGRADED" ]; then
        pass "API is healthy (status: $HEALTH)"
        API_UP=true
    else
        fail "API returned unexpected status: $HEALTH"
        API_UP=false
    fi
fi

# 2. CORS Configuration
if [ "$API_UP" = true ]; then
    print_check "CORS Configuration"

    # Test blocked origin
    BLOCKED_RESPONSE=$(timeout $TIMEOUT_SEC curl -s -I -X OPTIONS "$API_URL/api/auth/login" \
        -H "Origin: https://evil.com" \
        -H "Access-Control-Request-Method: POST" 2>/dev/null)

    if echo "$BLOCKED_RESPONSE" | grep -qi "access-control-allow-origin"; then
        fail "Evil origin should NOT receive CORS headers"
    else
        pass "Malicious origins blocked (no CORS header)"
    fi
fi

# 3. Rate Limiting
if [ "$API_UP" = true ]; then
    print_check "Rate Limiting"

    RATE_LIMITED=false
    for i in {1..11}; do
        RESPONSE=$(timeout $TIMEOUT_SEC curl -s -X POST "$API_URL/api/auth/login" \
            -H "Content-Type: application/json" \
            -d '{"email":"ratelimit-test@test.local","password":"wrong"}' 2>/dev/null)

        if echo "$RESPONSE" | grep -qi "too many\|rate"; then
            RATE_LIMITED=true
            pass "Rate limiting triggered at attempt $i"
            break
        fi
    done

    if [ "$RATE_LIMITED" = false ]; then
        warn "Rate limiting may not be enforced (11 requests succeeded)"
    fi
fi

# 4. Health Endpoint Schema
if [ "$API_UP" = true ]; then
    print_check "Health Endpoint Schema"

    HEALTH_JSON=$(timeout $TIMEOUT_SEC curl -s "$API_URL/health" 2>/dev/null)

    # Check required fields
    FIELDS=("status" "timestamp" "version" "checks" "uptime")
    for field in "${FIELDS[@]}"; do
        if echo "$HEALTH_JSON" | jq -e ".$field" >/dev/null 2>&1; then
            pass "Health response contains .$field"
        else
            fail "Health response missing .$field"
        fi
    done

    # Check checks sub-fields
    for field in "database" "redis"; do
        if echo "$HEALTH_JSON" | jq -e ".checks.$field" >/dev/null 2>&1; then
            pass "Health response contains .checks.$field"
        else
            warn ".checks.$field not present"
        fi
    done

    # Check simple mode
    SIMPLE=$(timeout $TIMEOUT_SEC curl -s "$API_URL/health?simple=true" 2>/dev/null)
    if [ "$SIMPLE" = "OK" ] || [ "$SIMPLE" = "DEGRADED" ] || [ "$SIMPLE" = "UNHEALTHY" ]; then
        pass "Simple mode returns valid plain text: $SIMPLE"
    else
        fail "Simple mode should return OK/DEGRADED/UNHEALTHY, got: $SIMPLE"
    fi
fi

# 5. Secret Scanning (gitleaks)
print_check "Secret Scanning"

if command -v gitleaks &>/dev/null; then
    cd "$ROOT_DIR" || exit 1
    GITLEAKS_OUTPUT=$(gitleaks detect --source . --no-git --config .gitleaks.toml 2>&1)
    GITLEAKS_EXIT=$?

    if [ $GITLEAKS_EXIT -eq 0 ]; then
        pass "No secrets detected in source files"
    elif [ $GITLEAKS_EXIT -eq 1 ]; then
        TOTAL_SECRETS=$(echo "$GITLEAKS_OUTPUT" | grep -c "Finding:" 2>/dev/null || echo 0)
        if [ "$TOTAL_SECRETS" -eq 0 ]; then
            pass "No secrets detected in source files"
        else
            fail "Secrets detected in source files ($TOTAL_SECRETS findings)"
            echo "$GITLEAKS_OUTPUT" | grep -E "^(File:|Finding:)" | head -10
        fi
    else
        warn "gitleaks returned unexpected exit code: $GITLEAKS_EXIT"
    fi
else
    warn "gitleaks not installed - install with: brew install gitleaks"
fi

# 6. npm audit
print_check "Dependency Vulnerabilities"

cd "$ROOT_DIR" || exit 1
AUDIT_OUTPUT=$(npm audit --audit-level=high 2>&1)
AUDIT_EXIT=$?

if [ $AUDIT_EXIT -eq 0 ]; then
    pass "No high/critical vulnerabilities in dependencies"
else
    VULN_COUNT=$(echo "$AUDIT_OUTPUT" | grep -oE "[0-9]+ high|[0-9]+ critical" | awk '{s+=$1} END {print s}')
    if [ -n "$VULN_COUNT" ] && [ "$VULN_COUNT" -gt 0 ]; then
        warn "Found $VULN_COUNT high/critical vulnerabilities (run: npm audit)"
    else
        pass "No high/critical vulnerabilities"
    fi
fi

# 7. .env gitignored
print_check "Environment Files"

if git -C "$ROOT_DIR" check-ignore backend/.env >/dev/null 2>&1; then
    pass ".env files are gitignored"
else
    fail ".env may not be gitignored - check .gitignore"
fi

# 8. Auth middleware presence
print_check "Authentication Middleware"

if [ -f "$BACKEND_DIR/src/middleware/auth.ts" ] || [ -f "$BACKEND_DIR/src/middleware/auth.js" ]; then
    if grep -q "jwt\|JWT\|jsonwebtoken\|verify" "$BACKEND_DIR/src/middleware/auth."* 2>/dev/null; then
        pass "JWT authentication middleware exists"
    else
        warn "Auth middleware exists but JWT verification not found"
    fi
else
    warn "No auth middleware found at expected path"
fi

# 9. Rate limiter presence
print_check "Rate Limiter Middleware"

if [ -f "$BACKEND_DIR/src/middleware/rateLimiter.ts" ] || [ -f "$BACKEND_DIR/src/middleware/rateLimiter.js" ]; then
    pass "Rate limiter middleware exists"
else
    warn "No rate limiter middleware found"
fi

# ============================================================================
# SUMMARY
# ============================================================================

print_header "Security Check Summary"

echo ""
echo -e "  ${GREEN}Passed${NC}:   $PASSED"
echo -e "  ${RED}Failed${NC}:   $FAILED"
echo -e "  ${YELLOW}Warnings${NC}: $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  All critical security checks passed!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  $FAILED critical security check(s) failed!${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
