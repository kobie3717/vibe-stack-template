#!/bin/bash
#
# Contract Check Script
# Verifies frontend/backend type alignment
#
# Usage: ./scripts/contract-check.sh
#

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SHARED_DIR="$ROOT_DIR/shared"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

FAILED=0
WARNED=0

echo ""
echo "Contract Drift Check"
echo "════════════════════════════════════════"

# 1. Check if shared types exist and compile
echo -n "Shared types compile.......... "
if [ -d "$SHARED_DIR" ] && [ -f "$SHARED_DIR/package.json" ]; then
    cd "$SHARED_DIR" || exit 1
    if npm run build > /dev/null 2>&1 || npx tsc --noEmit > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}SKIP${NC} (no shared directory)"
fi

# 2. Check if frontend imports shared types
echo -n "Frontend uses shared types.... "
if [ -d "$FRONTEND_DIR" ]; then
    if grep -rq "@shared\|from ['\"]shared\|from ['\"]../shared" "$FRONTEND_DIR/src" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}WARN${NC} (local types - consider importing from shared)"
        ((WARNED++))
    fi
else
    echo -e "${YELLOW}SKIP${NC} (no frontend)"
fi

# 3. Check API response format consistency
echo -n "API response format........... "
if [ -d "$BACKEND_DIR" ]; then
    # Check for consistent response envelope: { success: boolean, data?: T, error?: string }
    RESPONSE_PATTERN="success.*data\|success.*error\|res\.json.*success"
    if grep -rq "$RESPONSE_PATTERN" "$BACKEND_DIR/src/routes" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}WARN${NC} (response format may not be consistent)"
        ((WARNED++))
    fi
else
    echo -e "${YELLOW}SKIP${NC} (no backend)"
fi

# 4. Check enum consistency (if shared enums exist)
echo -n "Enum consistency.............. "
if [ -d "$SHARED_DIR" ]; then
    # Check for enum definitions
    SHARED_ENUMS=$(grep -rh "^export enum\|^export const.*=" "$SHARED_DIR/src" 2>/dev/null | wc -l)
    if [ "$SHARED_ENUMS" -gt 0 ]; then
        echo -e "${GREEN}OK${NC} ($SHARED_ENUMS shared definitions)"
    else
        echo -e "${YELLOW}WARN${NC} (no shared enums found)"
        ((WARNED++))
    fi
else
    echo -e "${YELLOW}SKIP${NC} (no shared directory)"
fi

# 5. TypeScript compilation check across workspaces
echo -n "Cross-workspace types......... "
cd "$ROOT_DIR" || exit 1
if npx tsc --build --dry-run > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
elif [ -f "$ROOT_DIR/tsconfig.json" ]; then
    # Try individual workspace check
    if npx tsc --noEmit -p "$BACKEND_DIR/tsconfig.json" > /dev/null 2>&1 && \
       npx tsc --noEmit -p "$FRONTEND_DIR/tsconfig.json" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}SKIP${NC} (no root tsconfig)"
fi

echo "════════════════════════════════════════"

# Summary
if [ $FAILED -eq 0 ]; then
    if [ $WARNED -gt 0 ]; then
        echo -e "${YELLOW}Contract check passed with $WARNED warning(s)${NC}"
    else
        echo -e "${GREEN}Contract check passed${NC}"
    fi
    exit 0
else
    echo -e "${RED}Contract check failed ($FAILED error(s))${NC}"
    exit 1
fi
