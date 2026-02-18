<div align="center">

# 🏗️ Vibe Stack Template

[![License: MIT](https://img.shields.io/github/license/kobie3717/vibe-stack-template)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/kobie3717/vibe-stack-template)](https://github.com/kobie3717/vibe-stack-template/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/kobie3717/vibe-stack-template)](https://github.com/kobie3717/vibe-stack-template/commits/main)

### Stop shipping broken code with AI. This template catches it before you do.

*A production-ready project template with built-in verification, security enforcement, and deployment discipline — designed for AI-assisted development.*

</div>

---

## Why This Exists

AI coding tools (Claude, Cursor, Copilot) let you ship fast. **Too fast.** They'll happily generate code that:

- Passes no tests (because there aren't any)
- Breaks the build (but CI was set to skip missing files)
- Ships secrets (because nobody ran a scan)
- Drifts from the spec (because the spec wasn't enforced)

This template adds **guardrails** so your AI copilot stays on the road. It gives you:

- **Protocols** that keep AI agents disciplined (CLAUDE.md)
- **Verification scripts** that catch problems locally before CI
- **A mode gate** that prevents "false green" builds
- **Security scanning** baked into the workflow, not bolted on

## Built With Battle Scars

This isn't a theoretical template. It was extracted from running a real production SaaS where an AI agent handles autonomous development. Every protocol, every check, every "never do this" rule exists because **something went wrong** and we built the guardrail after.

The protocols (P1–P12) aren't aspirational — they're scar tissue turned into automation.

---

## What's Included

| File | Purpose |
|------|---------|
| **CLAUDE.md** | AI assistant protocols for autonomous development |
| **SPEC.md** | Product specification as source of truth |
| **Verification Scripts** | Stack, security, contract, and environment checks |
| **CI/CD Pipeline** | GitHub Actions with security scanning and mode-aware enforcement |
| **Deployment Checklist** | Pre-deploy, staging, production, rollback procedures |

## Template Mode vs Project Mode

This template uses an explicit mode gate to ensure CI behavior is appropriate:

| Mode | TEMPLATE_MODE file | CI Behavior |
|------|-------------------|-------------|
| **Template Mode** | `true` (default) | Lightweight validation: file existence, config parsing, secret scanning |
| **Project Mode** | `false` | Full checks: lint, typecheck, build, tests, E2E, security — **fails if files are missing** |

This prevents "false green" builds where CI passes by skipping checks.

---

## Quick Start

### 1. Create from Template

Click **"Use this template"** on GitHub, or:

```bash
git clone https://github.com/YOUR_USERNAME/vibe-stack-template.git my-project
cd my-project
rm -rf .git && git init
```

### 2. Switch to Project Mode

```bash
echo "false" > TEMPLATE_MODE
```

> ⚠️ **This is critical.** In project mode, CI will fail loudly if required files are missing. No more hiding broken builds.

### 3. Configure PROJECT_KNOBS

Open `CLAUDE.md` and update:

```bash
PROJECT_NAME=my-project
BACKEND_PORT=4000
FRONTEND_PORT=5173
API_BASE_URL=http://localhost:4000/api
DOMAIN=myproject.com
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
REDIS_URL=redis://localhost:6379
```

Also update `package.json`, `SPEC.md`, and `DEPLOYMENT_SECURITY_CHECKLIST.md` with your project details.

### 4. Install & Verify

```bash
npm install
cp backend/.env.example backend/.env
npm run check:template   # Validate template structure
npm run check:quick      # Fast health check (once you have code)
```

---

## Verification Commands

| Command | Time | When to Use |
|---------|------|-------------|
| `npm run check:template` | ~5s | Before pushing template changes |
| `npm run check:quick` | ~5s | After config changes |
| `npm run check:fast` | ~90s | After code changes |
| `npm run check:full` | ~3-5min | Before merge/release |
| `npm run check:security` | ~30s | Before deployment |
| `npm run contract:check` | ~15s | After API changes |
| `npm run validate:env` | ~5s | After env changes |
| `npm run prerelease` | ~5min | Before production deploy |

### System Status Levels

| Status | Meaning |
|--------|---------|
| **PARTIALLY ACTIVE** | `check:quick` passes — basic health verified |
| **ACTIVE** | `check:fast` passes — code quality verified |
| **RELEASE-READY** | `check:full` + `check:security` + `contract:check` all pass |

---

## CI Pipeline

### Template Mode (`TEMPLATE_MODE=true`)
Runs a single **Template Validation** job: file existence, YAML syntax, gitleaks secret scan, hardcoded secret patterns.

### Project Mode (`TEMPLATE_MODE=false`)
Full pipeline:
1. **detect-mode** → reads TEMPLATE_MODE
2. **secrets-scan** → blocks if secrets detected
3. **security-validation** → CORS, rate limiting, auth checks
4. **stack-check** → contract and type alignment
5. **backend** → lint, typecheck, test, build
6. **frontend** → lint, typecheck, build
7. **e2e** → end-to-end tests (main branch only)

**No conditional skipping.** Missing files = loud failure.

---

## Project Structure

```
├── TEMPLATE_MODE               # 'true' or 'false' — CI mode gate
├── CLAUDE.md                   # AI assistant protocols (P1–P12)
├── SPEC.md                     # Product specification (source of truth)
├── DEPLOYMENT_SECURITY_CHECKLIST.md
├── .gitleaks.toml              # Secret scanning config
├── .github/workflows/ci.yml   # Mode-aware CI pipeline
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

---

## Customization Checklist

- [ ] `TEMPLATE_MODE` → set to `false`
- [ ] `CLAUDE.md` → update PROJECT_KNOBS
- [ ] `package.json` → name, description
- [ ] `SPEC.md` → your product spec, API contracts, invariants
- [ ] `backend/` → your backend implementation
- [ ] `frontend/` → your frontend implementation
- [ ] `shared/` → shared TypeScript types
- [ ] `DEPLOYMENT_SECURITY_CHECKLIST.md` → domain, contacts

---

## The Golden Rule

> **If code and SPEC.md disagree, the code is BROKEN.**

SPEC.md is the source of truth. Update it first, then implement.

## Why No Conditional Skipping?

Previous versions used `if: hashFiles('backend/tsconfig.json') != ''` to skip checks when files were missing. This created a dangerous pattern: someone deletes package.json → CI skips the build → CI passes (false green) → broken state gets merged.

The fix: **Template Mode** validates structure only. **Project Mode** requires all files and fails loudly. No hiding, no skipping, no false greens.

---

## License

MIT
