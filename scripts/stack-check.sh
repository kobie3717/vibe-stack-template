#!/bin/bash
#
# Stack Check Script
# Unified verification for the entire stack
#
# Usage:
#   ./scripts/stack-check.sh --quick   # Health checks only (~5s)
#   ./scripts/stack-check.sh --fast    # Lint + typecheck + build + health (~90s)
#   ./scripts/stack-check.sh --full    # Fast + tests + UI smoke (~3-5min)
#

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

# ============================================================================
# CONFIGURATION - Update these for your project
# ============================================================================
BACKEND_PORT="${BACKEND_PORT:-4000}"
FRONTEND_PORT="${FRONTEND_PORT:-5173}"
API_URL="http://localhost:$BACKEND_PORT"
# ============================================================================

# Mode
MODE="${1:---fast}"
MODE="${MODE#--}"

# Counters
PASSED=0
FAILED=0
SKIPPED=0
START_TIME=$(date +%s)

# Functions
section() {
    echo ""
    echo -e "${BLUE}[$1]${NC} $2"
    echo "────────────────────────────────────────────────────────────────────"
}

check() {
    if [ $2 -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $1"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${NC} $1"
        ((FAILED++))
    fi
}

skip() {
    echo -e "  ${YELLOW}○${NC} $1 (skipped)"
    ((SKIPPED++))
}

# ============================================================================
# HEADER
# ============================================================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            Stack Check ($MODE mode)                               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# BACKEND CHECKS
# ============================================================================
section "1/5" "Backend Checks"

if [ -d "$BACKEND_DIR" ]; then
    cd "$BACKEND_DIR" || exit 1

    # TypeScript
    if [ "$MODE" != "quick" ]; then
        echo -e "  ${YELLOW}→${NC} Running TypeScript check..."
        npx tsc --noEmit > /dev/null 2>&1
        check "TypeScript compiles" $?
    else
        skip "TypeScript"
    fi

    # ESLint
    if [ "$MODE" != "quick" ]; then
        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.cjs" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
            echo -e "  ${YELLOW}→${NC} Running ESLint..."
            npm run lint > /dev/null 2>&1
            check "ESLint passes" $?
        else
            skip "ESLint (no config)"
        fi
    fi

    # Build
    if [ "$MODE" != "quick" ]; then
        echo -e "  ${YELLOW}→${NC} Building backend..."
        npm run build > /dev/null 2>&1
        check "Backend builds" $?
    fi

    # Unit tests (full mode only)
    if [ "$MODE" == "full" ]; then
        echo -e "  ${YELLOW}→${NC} Running unit tests..."
        npm test -- --forceExit --testPathIgnorePatterns integration > /dev/null 2>&1
        check "Unit tests pass" $?
    fi
else
    skip "Backend (directory not found)"
fi

# ============================================================================
# FRONTEND CHECKS
# ============================================================================
section "2/5" "Frontend Checks"

if [ -d "$FRONTEND_DIR" ]; then
    cd "$FRONTEND_DIR" || exit 1

    # TypeScript
    if [ "$MODE" != "quick" ]; then
        echo -e "  ${YELLOW}→${NC} Running TypeScript check..."
        npx tsc --noEmit > /dev/null 2>&1
        check "TypeScript compiles" $?
    else
        skip "TypeScript"
    fi

    # ESLint
    if [ "$MODE" != "quick" ]; then
        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.cjs" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
            echo -e "  ${YELLOW}→${NC} Running ESLint..."
            npm run lint > /dev/null 2>&1
            check "ESLint passes" $?
        else
            skip "ESLint (no config)"
        fi
    fi

    # Build
    if [ "$MODE" != "quick" ]; then
        echo -e "  ${YELLOW}→${NC} Building frontend..."
        npm run build > /dev/null 2>&1
        check "Frontend builds" $?
    fi
else
    skip "Frontend (directory not found)"
fi

# ============================================================================
# HEALTH CHECKS
# ============================================================================
section "3/5" "Health Checks"
cd "$ROOT_DIR" || exit 1

echo ""
echo "Health Check Results"
echo "════════════════════════════════════════"

# Backend API
echo -n "Backend API........... "
HEALTH_RESPONSE=$(timeout 5 curl -s "$API_URL/health" 2>/dev/null)
if [ -n "$HEALTH_RESPONSE" ]; then
    STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.status' 2>/dev/null)
    if [ "$STATUS" = "ok" ] || [ "$STATUS" = "degraded" ]; then
        echo -e "${GREEN}$STATUS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAIL${NC} (status: $STATUS)"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}SKIP${NC} (not running)"
    ((SKIPPED++))
fi

# Database (from health response)
echo -n "Database.............. "
if [ -n "$HEALTH_RESPONSE" ]; then
    DB_STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.checks.database.status' 2>/dev/null)
    if [ "$DB_STATUS" = "ok" ]; then
        echo -e "${GREEN}OK${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}SKIP${NC}"
    ((SKIPPED++))
fi

# Redis (from health response)
echo -n "Redis................. "
if [ -n "$HEALTH_RESPONSE" ]; then
    REDIS_STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.checks.redis.status' 2>/dev/null)
    if [ "$REDIS_STATUS" = "ok" ]; then
        echo -e "${GREEN}OK${NC}"
        ((PASSED++))
    elif [ "$REDIS_STATUS" = "null" ]; then
        echo -e "${YELLOW}SKIP${NC} (not configured)"
        ((SKIPPED++))
    else
        echo -e "${YELLOW}WARN${NC} (degraded)"
        ((PASSED++))  # Degraded is acceptable
    fi
else
    echo -e "${YELLOW}SKIP${NC}"
    ((SKIPPED++))
fi

# Frontend dist
echo -n "Frontend.............. "
if [ -d "$FRONTEND_DIR/dist" ]; then
    echo -e "${GREEN}OK${NC} (dist exists)"
    ((PASSED++))
else
    echo -e "${YELLOW}SKIP${NC} (not built)"
    ((SKIPPED++))
fi

echo "════════════════════════════════════════"

# ============================================================================
# DATABASE CONNECTIVITY
# ============================================================================
section "4/5" "Database Check"

if [ -f "$SCRIPT_DIR/health-check/db-check.js" ]; then
    node "$SCRIPT_DIR/health-check/db-check.js" > /dev/null 2>&1
    check "Database connectivity" $?
else
    # Fallback: use health endpoint
    if [ -n "$HEALTH_RESPONSE" ]; then
        DB_STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.checks.database.status' 2>/dev/null)
        if [ "$DB_STATUS" = "ok" ]; then
            check "Database connectivity" 0
        else
            check "Database connectivity" 1
        fi
    else
        skip "Database check (no script or health endpoint)"
    fi
fi

# ============================================================================
# UI SMOKE TESTS (full mode only)
# ============================================================================
section "5/5" "UI Smoke Tests"

if [ "$MODE" == "full" ]; then
    cd "$FRONTEND_DIR" || exit 1

    if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
        echo -e "  ${YELLOW}→${NC} Running Playwright tests (chromium only)..."
        npx playwright test --project=chromium --reporter=list > /dev/null 2>&1
        check "Playwright tests pass" $?
    else
        skip "UI tests (no Playwright config)"
    fi
else
    skip "UI tests (full mode only)"
fi

# ============================================================================
# SUMMARY
# ============================================================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                           SUMMARY                                ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Duration:  ${DURATION}s"
echo -e "  Passed:    ${GREEN}$PASSED${NC}"
echo -e "  Failed:    ${RED}$FAILED${NC}"
echo -e "  Skipped:   ${YELLOW}$SKIPPED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✓ STACK CHECK PASSED                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                  ✗ STACK CHECK FAILED                            ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
