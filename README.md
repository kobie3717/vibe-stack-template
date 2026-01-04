# Vibe Stack Template

A production-ready project template with built-in verification, security enforcement, and deployment discipline.

## What This Template Provides

- **CLAUDE.md** - AI assistant protocols for autonomous development
- **SPEC.md** - Product specification as source of truth
- **Verification Scripts** - Stack, security, contract, and environment checks
- **CI/CD Pipeline** - GitHub Actions with security scanning and mode-aware enforcement
- **Deployment Checklist** - Pre-deploy, staging, production, rollback procedures

## Template Mode vs Project Mode

This template uses an explicit mode gate to ensure CI behavior is appropriate:

| Mode | TEMPLATE_MODE file | CI Behavior |
|------|-------------------|-------------|
| **Template Mode** | `true` (default) | Runs lightweight validation: file existence, config parsing, secret scanning |
| **Project Mode** | `false` | Runs full checks: lint, typecheck, build, tests, E2E, security - **fails if files are missing** |

This prevents "false green" builds where CI passes by skipping checks.

## Quick Start

### 1. Create from Template

Click **"Use this template"** on GitHub, or clone manually:

```bash
git clone https://github.com/YOUR_USERNAME/vibe-stack-template.git my-project
cd my-project
rm -rf .git && git init
```

### 2. Switch to Project Mode

**This is critical!** Edit the `TEMPLATE_MODE` file:

```bash
# Change 'true' to 'false'
echo "false" > TEMPLATE_MODE
```

Once you do this:
- CI will run full checks (lint, typecheck, build, tests)
- CI will **fail** if backend/frontend are missing required files (package.json, tsconfig.json)
- You cannot hide broken builds by deleting files

### 3. Replace PROJECT_KNOBS

Open `CLAUDE.md` and update the PROJECT_KNOBS section:

```bash
PROJECT_NAME=my-project
BACKEND_PORT=4000
FRONTEND_PORT=5173
API_BASE_URL=http://localhost:4000/api
DOMAIN=myproject.com
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
REDIS_URL=redis://localhost:6379
```

Also update:
- `package.json` → name and description
- `SPEC.md` → project description and features
- `DEPLOYMENT_SECURITY_CHECKLIST.md` → domain references

### 4. Install Dependencies

```bash
npm install
```

### 5. Setup Environment

```bash
cp backend/.env.example backend/.env
# Edit backend/.env with your values
```

### 6. Verify Setup

```bash
npm run check:template   # Validate template structure
npm run check:quick      # Fast health check (once you have code)
```

## Available Commands

| Command | Description | When to Use |
|---------|-------------|-------------|
| `npm run check:template` | Validate template structure | Before pushing template changes |
| `npm run check:quick` | Health checks only (~5s) | After config changes |
| `npm run check:fast` | Lint + typecheck + build (~90s) | After code changes |
| `npm run check:full` | Full check + tests + E2E (~3-5min) | Before merge/release |
| `npm run check:security` | Security validation | Before deployment |
| `npm run contract:check` | Frontend/backend alignment | After API changes |
| `npm run validate:env` | Environment variables | After env changes |
| `npm run prerelease` | All checks combined | Before production deploy |

## CI Pipeline Behavior

### When TEMPLATE_MODE=true

The CI runs a single job: **Template Validation**

- Checks all required files exist (CLAUDE.md, SPEC.md, scripts, etc.)
- Validates YAML syntax of ci.yml
- Validates .gitleaks.toml config
- Runs gitleaks secret scan
- Checks for hardcoded secret patterns

**Backend/Frontend jobs do NOT run.** This is intentional - they are placeholders.

### When TEMPLATE_MODE=false

The CI runs full pipeline:

1. **detect-mode** - Reads TEMPLATE_MODE, sets job conditions
2. **secrets-scan** - Blocks if secrets detected (gitleaks)
3. **security-validation** - CORS, rate limiting, auth checks (**fails if missing**)
4. **stack-check** - Contract and type alignment
5. **backend** - Lint, typecheck, test, build (**fails if package.json/tsconfig.json missing**)
6. **frontend** - Lint, typecheck, build (**fails if package.json/tsconfig.json missing**)
7. **e2e** - End-to-end tests (main branch only)

**No conditional skipping.** If files are missing, CI fails with clear error messages.

## System Status Definitions

| Status | Meaning |
|--------|---------|
| **PARTIALLY ACTIVE** | `check:quick` passes - basic health verified |
| **ACTIVE** | `check:fast` passes - code quality verified |
| **RELEASE-READY** | `check:full` + `check:security` + `contract:check` all pass |

## Before Deploying to Production

Run this single command:

```bash
npm run prerelease
```

This runs:
1. Full stack check (lint, typecheck, build, tests, E2E)
2. Security check (secrets, CORS, rate limiting, npm audit)
3. Contract check (frontend/backend type alignment)

**Only deploy if all checks pass.**

## Project Structure

```
├── TEMPLATE_MODE               # 'true' or 'false' - CI mode gate
├── CLAUDE.md                   # AI assistant protocols
├── SPEC.md                     # Product specification
├── DEPLOYMENT_SECURITY_CHECKLIST.md
├── .gitleaks.toml              # Secret scanning config
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI (mode-aware)
├── scripts/
│   ├── template-validate.sh    # Template structure validation
│   ├── stack-check.sh          # Unified verification
│   ├── security-check.sh       # Security validation
│   ├── contract-check.sh       # Type alignment
│   └── validate-env.sh         # Environment validation
├── backend/                    # Express API (customize)
├── frontend/                   # React + Vite (customize)
└── shared/                     # Shared types (optional)
```

## Customization Checklist

After cloning, update these files:

- [ ] `TEMPLATE_MODE` → Change `true` to `false`
- [ ] `CLAUDE.md` → PROJECT_KNOBS section
- [ ] `package.json` → name, description
- [ ] `SPEC.md` → project description, features, API contracts
- [ ] `backend/` → Your backend implementation
- [ ] `frontend/` → Your frontend implementation
- [ ] `shared/` → Shared TypeScript types
- [ ] `DEPLOYMENT_SECURITY_CHECKLIST.md` → Domain, emergency contacts

## What Each Check Does

### `check:template`
- Validates required template files exist
- Validates script permissions
- Validates config file syntax (.gitleaks.toml, ci.yml)
- Checks for hardcoded secret patterns
- Reports TEMPLATE_MODE value

### `check:quick`
- Pings `/health` endpoint
- Verifies database connectivity
- Verifies Redis connectivity (if configured)

### `check:fast`
- TypeScript compilation (both workspaces)
- ESLint (if configured)
- Production build (both workspaces)
- Health checks

### `check:full`
- Everything in `check:fast`
- Unit tests
- E2E tests (Playwright, chromium only)

### `check:security`
- gitleaks secret scanning
- npm audit (high/critical)
- CORS configuration check
- Rate limiting verification
- Health endpoint schema validation
- Auth middleware presence

### `contract:check`
- Shared types compile
- Frontend imports shared types
- API response format consistency
- Cross-workspace TypeScript

## The Golden Rule

> If code and SPEC.md disagree, **the code is BROKEN**.

SPEC.md is the source of truth. Update it first, then implement.

## Why No Conditional Skipping?

Previous versions of this template used `if: hashFiles('backend/tsconfig.json') != ''` to skip checks when files were missing. This created a dangerous pattern:

1. Someone deletes package.json accidentally
2. CI skips the build step
3. CI passes (false green)
4. Broken state gets merged

The new approach:
- In **Template Mode**: CI only validates template structure
- In **Project Mode**: CI requires all files and fails loudly if missing

This is a **10/10 enforcement** approach. No hiding, no skipping, no false greens.

## License

MIT
