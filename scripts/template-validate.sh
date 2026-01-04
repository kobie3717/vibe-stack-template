#!/usr/bin/env bash
# template-validate.sh - Validates template repository structure
# Run: bash scripts/template-validate.sh
#
# Exit codes:
#   0 = All validations passed
#   1 = Validation failed

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

ERRORS=0
WARNINGS=0

log_pass() { echo -e "${GREEN}✓${NC} $1"; }
log_fail() { echo -e "${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; WARNINGS=$((WARNINGS + 1)); }
log_info() { echo -e "  $1"; }

echo "═══════════════════════════════════════════════════════════════"
echo "Template Validation"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────────────────────
# 1. Required Files Check
# ─────────────────────────────────────────────────────────────────────
echo "── Required Files ──"

REQUIRED_FILES=(
  "CLAUDE.md"
  "SPEC.md"
  "README.md"
  "TEMPLATE_MODE"
  ".gitignore"
  ".gitleaks.toml"
  ".github/workflows/ci.yml"
  "scripts/stack-check.sh"
  "scripts/contract-check.sh"
  "scripts/validate-env.sh"
  "scripts/template-validate.sh"
  "backend/.env.example"
  "frontend/.env.example"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$file" ]]; then
    log_pass "$file exists"
  else
    log_fail "$file is MISSING"
  fi
done

echo ""

# ─────────────────────────────────────────────────────────────────────
# 2. Script Executability Check
# ─────────────────────────────────────────────────────────────────────
echo "── Script Permissions ──"

SCRIPTS=(
  "scripts/stack-check.sh"
  "scripts/contract-check.sh"
  "scripts/validate-env.sh"
  "scripts/template-validate.sh"
)

for script in "${SCRIPTS[@]}"; do
  if [[ -f "$script" ]]; then
    if [[ -x "$script" ]]; then
      log_pass "$script is executable"
    else
      log_warn "$script exists but is not executable (chmod +x recommended)"
    fi
  fi
done

echo ""

# ─────────────────────────────────────────────────────────────────────
# 3. Configuration Parsing Check
# ─────────────────────────────────────────────────────────────────────
echo "── Configuration Parsing ──"

# Check .gitleaks.toml
if [[ -f ".gitleaks.toml" ]]; then
  if command -v gitleaks &> /dev/null; then
    if gitleaks detect --config .gitleaks.toml --source . --no-git --exit-code 0 &> /dev/null; then
      log_pass ".gitleaks.toml parses correctly"
    else
      log_fail ".gitleaks.toml has syntax errors"
    fi
  else
    # Fallback: basic TOML syntax check
    if grep -q '^\[' .gitleaks.toml && ! grep -qE '^\s*\[.*\].*\[' .gitleaks.toml; then
      log_pass ".gitleaks.toml basic syntax OK (gitleaks not installed for full check)"
    else
      log_warn ".gitleaks.toml syntax could not be fully validated (install gitleaks)"
    fi
  fi
else
  log_fail ".gitleaks.toml not found"
fi

# Check ci.yml YAML syntax
if [[ -f ".github/workflows/ci.yml" ]]; then
  if command -v python3 &> /dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" 2>/dev/null; then
      log_pass ".github/workflows/ci.yml parses as valid YAML"
    else
      log_fail ".github/workflows/ci.yml has YAML syntax errors"
    fi
  elif command -v node &> /dev/null; then
    # Node.js fallback using js-yaml if available
    if node -e "require('js-yaml').load(require('fs').readFileSync('.github/workflows/ci.yml'))" 2>/dev/null; then
      log_pass ".github/workflows/ci.yml parses as valid YAML"
    else
      log_warn ".github/workflows/ci.yml syntax could not be validated (install PyYAML)"
    fi
  else
    log_warn "No YAML parser available - skipping ci.yml validation"
  fi
else
  log_fail ".github/workflows/ci.yml not found"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────
# 4. No Hardcoded Secrets Check
# ─────────────────────────────────────────────────────────────────────
echo "── Secret Patterns Check ──"

# Patterns that suggest real secrets (not placeholders)
SECRET_PATTERNS=(
  'sk-[a-zA-Z0-9]{20,}'           # OpenAI-style keys
  'ghp_[a-zA-Z0-9]{36}'           # GitHub PAT
  'gho_[a-zA-Z0-9]{36}'           # GitHub OAuth
  'AKIA[0-9A-Z]{16}'              # AWS Access Key
  'xox[baprs]-[0-9a-zA-Z-]{10,}'  # Slack tokens
  'eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*'  # JWT (real, not example)
)

FOUND_SECRETS=0
for pattern in "${SECRET_PATTERNS[@]}"; do
  # Search in code files, excluding node_modules, .git, etc.
  if grep -rE "$pattern" --include="*.ts" --include="*.js" --include="*.json" --include="*.env*" \
     --exclude-dir=node_modules --exclude-dir=.git --exclude="package-lock.json" . 2>/dev/null | \
     grep -v "example\|test\|placeholder\|your.*here\|YOUR.*HERE" | head -1 | grep -q .; then
    log_fail "Potential secret pattern found: $pattern"
    FOUND_SECRETS=$((FOUND_SECRETS + 1))
  fi
done

if [[ $FOUND_SECRETS -eq 0 ]]; then
  log_pass "No hardcoded secret patterns detected"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────
# 5. TEMPLATE_MODE Value Check
# ─────────────────────────────────────────────────────────────────────
echo "── Template Mode Check ──"

if [[ -f "TEMPLATE_MODE" ]]; then
  MODE_VALUE=$(cat TEMPLATE_MODE | tr -d '[:space:]')
  if [[ "$MODE_VALUE" == "true" ]]; then
    log_pass "TEMPLATE_MODE is set to 'true' (template mode active)"
  elif [[ "$MODE_VALUE" == "false" ]]; then
    log_warn "TEMPLATE_MODE is set to 'false' (project mode) - full CI checks will run"
  else
    log_fail "TEMPLATE_MODE has invalid value: '$MODE_VALUE' (expected 'true' or 'false')"
  fi
else
  log_fail "TEMPLATE_MODE file is missing"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────
# 6. Directory Structure Check
# ─────────────────────────────────────────────────────────────────────
echo "── Directory Structure ──"

REQUIRED_DIRS=(
  "backend"
  "frontend"
  "scripts"
  ".github/workflows"
)

for dir in "${REQUIRED_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    log_pass "$dir/ directory exists"
  else
    log_fail "$dir/ directory is MISSING"
  fi
done

# Check for shared/ (optional but recommended)
if [[ -d "shared" ]]; then
  log_pass "shared/ directory exists (optional)"
else
  log_info "shared/ directory not present (optional)"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}TEMPLATE VALIDATION PASSED${NC}"
  if [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}$WARNINGS warning(s) - review recommended${NC}"
  fi
  echo "═══════════════════════════════════════════════════════════════"
  exit 0
else
  echo -e "${RED}TEMPLATE VALIDATION FAILED${NC}"
  echo -e "${RED}$ERRORS error(s), $WARNINGS warning(s)${NC}"
  echo "═══════════════════════════════════════════════════════════════"
  exit 1
fi
