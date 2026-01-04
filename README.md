# Vibe Stack Template

A production-ready project template with built-in verification, security enforcement, and deployment discipline.

## What This Template Provides

- **CLAUDE.md** - AI assistant protocols for autonomous development
- **SPEC.md** - Product specification as source of truth
- **Verification Scripts** - Stack, security, contract, and environment checks
- **CI/CD Pipeline** - GitHub Actions with security scanning
- **Deployment Checklist** - Pre-deploy, staging, production, rollback procedures

## Quick Start

### 1. Create from Template

Click **"Use this template"** on GitHub, or clone manually:

```bash
git clone https://github.com/YOUR_USERNAME/vibe-stack-template.git my-project
cd my-project
rm -rf .git && git init
```

### 2. Replace PROJECT_KNOBS

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

### 3. Install Dependencies

```bash
npm install
```

### 4. Setup Environment

```bash
cp backend/.env.example backend/.env
# Edit backend/.env with your values
```

### 5. Verify Setup

```bash
npm run check:quick   # Fast health check
```

## Available Commands

| Command | Description | When to Use |
|---------|-------------|-------------|
| `npm run check:quick` | Health checks only (~5s) | After config changes |
| `npm run check:fast` | Lint + typecheck + build (~90s) | After code changes |
| `npm run check:full` | Full check + tests + E2E (~3-5min) | Before merge/release |
| `npm run check:security` | Security validation | Before deployment |
| `npm run contract:check` | Frontend/backend alignment | After API changes |
| `npm run validate:env` | Environment variables | After env changes |
| `npm run prerelease` | All checks combined | Before production deploy |

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
├── CLAUDE.md                    # AI assistant protocols
├── SPEC.md                      # Product specification
├── DEPLOYMENT_SECURITY_CHECKLIST.md
├── .gitleaks.toml               # Secret scanning config
├── .github/
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI
├── scripts/
│   ├── stack-check.sh           # Unified verification
│   ├── security-check.sh        # Security validation
│   ├── contract-check.sh        # Type alignment
│   └── validate-env.sh          # Environment validation
├── backend/                     # Express API (customize)
├── frontend/                    # React + Vite (customize)
└── shared/                      # Shared types (optional)
```

## Customization Checklist

After cloning, update these files:

- [ ] `CLAUDE.md` → PROJECT_KNOBS section
- [ ] `package.json` → name, description
- [ ] `SPEC.md` → project description, features, API contracts
- [ ] `backend/` → Your backend implementation
- [ ] `frontend/` → Your frontend implementation
- [ ] `shared/` → Shared TypeScript types
- [ ] `DEPLOYMENT_SECURITY_CHECKLIST.md` → Domain, emergency contacts

## What Each Check Does

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

## CI Pipeline

The GitHub Actions workflow runs on every PR and push:

1. **secrets-scan** - Blocks if secrets detected
2. **security-validation** - Static security checks
3. **stack-check** - Type alignment verification
4. **backend** - Lint, typecheck, test, build
5. **frontend** - Lint, typecheck, build
6. **e2e** - End-to-end tests (main branch only)

## The Golden Rule

> If code and SPEC.md disagree, **the code is BROKEN**.

SPEC.md is the source of truth. Update it first, then implement.

## License

MIT
