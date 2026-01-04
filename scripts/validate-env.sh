#!/bin/bash
#
# Environment Variable Validation Script
# Validates required environment variables are present
#
# Usage:
#   ./scripts/validate-env.sh           # Validate actual .env files
#   ./scripts/validate-env.sh --template # Validate .env.example exists (for CI)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

TEMPLATE_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --template)
            TEMPLATE_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [--template]"
            echo ""
            echo "Options:"
            echo "  --template    Validate .env.example files exist (for CI)"
            echo "  --help, -h    Show this help message"
            echo ""
            echo "Without flags: Validates actual .env files have all required vars"
            exit 0
            ;;
    esac
done

echo ""
echo "Environment Variable Validation"
echo "════════════════════════════════════════"

FAILED=0

# ============================================================================
# CONFIGURATION - Update these for your project
# ============================================================================

# Required backend variables (will fail if missing)
BACKEND_REQUIRED=(
    "DATABASE_URL"
    "JWT_SECRET"
    "PORT"
)

# Recommended backend variables (will warn if missing)
BACKEND_RECOMMENDED=(
    "NODE_ENV"
    "REDIS_URL"
)

# Required frontend variables
FRONTEND_REQUIRED=(
    "VITE_API_URL"
)

# ============================================================================

if [ "$TEMPLATE_MODE" = true ]; then
    # CI mode: just check .env.example exists
    echo -e "\n${YELLOW}Template mode: checking .env.example files${NC}\n"

    if [ -f "$BACKEND_DIR/.env.example" ]; then
        echo -e "  ${GREEN}✓${NC} backend/.env.example exists"
    else
        echo -e "  ${RED}✗${NC} backend/.env.example missing"
        ((FAILED++))
    fi

    if [ -f "$FRONTEND_DIR/.env.example" ]; then
        echo -e "  ${GREEN}✓${NC} frontend/.env.example exists"
    else
        echo -e "  ${YELLOW}○${NC} frontend/.env.example missing (optional)"
    fi
else
    # Normal mode: validate actual .env files

    # Backend validation
    echo -e "\n${YELLOW}Backend (.env)${NC}\n"

    if [ -f "$BACKEND_DIR/.env" ]; then
        # Source the env file to check variables
        set -a
        source "$BACKEND_DIR/.env" 2>/dev/null || true
        set +a

        for var in "${BACKEND_REQUIRED[@]}"; do
            if [ -n "${!var}" ]; then
                # Mask sensitive values
                VALUE="${!var}"
                if [[ "$var" == *"SECRET"* ]] || [[ "$var" == *"PASSWORD"* ]] || [[ "$var" == *"KEY"* ]]; then
                    VALUE="***masked***"
                elif [ ${#VALUE} -gt 30 ]; then
                    VALUE="${VALUE:0:20}..."
                fi
                echo -e "  ${GREEN}✓${NC} $var = $VALUE"
            else
                echo -e "  ${RED}✗${NC} $var (required, missing!)"
                ((FAILED++))
            fi
        done

        for var in "${BACKEND_RECOMMENDED[@]}"; do
            if [ -n "${!var}" ]; then
                VALUE="${!var}"
                if [ ${#VALUE} -gt 30 ]; then
                    VALUE="${VALUE:0:20}..."
                fi
                echo -e "  ${GREEN}✓${NC} $var = $VALUE"
            else
                echo -e "  ${YELLOW}○${NC} $var (recommended, not set)"
            fi
        done
    else
        echo -e "  ${RED}✗${NC} backend/.env not found"
        echo -e "     Copy from: cp backend/.env.example backend/.env"
        ((FAILED++))
    fi

    # Frontend validation
    echo -e "\n${YELLOW}Frontend (.env)${NC}\n"

    if [ -f "$FRONTEND_DIR/.env" ] || [ -f "$FRONTEND_DIR/.env.local" ]; then
        ENV_FILE="$FRONTEND_DIR/.env"
        [ -f "$FRONTEND_DIR/.env.local" ] && ENV_FILE="$FRONTEND_DIR/.env.local"

        set -a
        source "$ENV_FILE" 2>/dev/null || true
        set +a

        for var in "${FRONTEND_REQUIRED[@]}"; do
            if [ -n "${!var}" ]; then
                VALUE="${!var}"
                if [ ${#VALUE} -gt 40 ]; then
                    VALUE="${VALUE:0:30}..."
                fi
                echo -e "  ${GREEN}✓${NC} $var = $VALUE"
            else
                echo -e "  ${RED}✗${NC} $var (required, missing!)"
                ((FAILED++))
            fi
        done
    else
        echo -e "  ${YELLOW}○${NC} No frontend .env (may use defaults)"
    fi

    # JWT Secret length check
    echo -e "\n${YELLOW}Security Checks${NC}\n"

    if [ -n "$JWT_SECRET" ] && [ ${#JWT_SECRET} -ge 32 ]; then
        echo -e "  ${GREEN}✓${NC} JWT_SECRET is at least 32 characters"
    elif [ -n "$JWT_SECRET" ]; then
        echo -e "  ${RED}✗${NC} JWT_SECRET is too short (need 32+ chars, have ${#JWT_SECRET})"
        ((FAILED++))
    fi
fi

echo ""
echo "════════════════════════════════════════"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Environment validation passed${NC}"
    exit 0
else
    echo -e "${RED}Environment validation failed ($FAILED error(s))${NC}"
    exit 1
fi
