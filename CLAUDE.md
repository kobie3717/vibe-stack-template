# CLAUDE.md

Guidance for Claude Code when working with this repository.

---

## Source of Truth

| Document | Purpose |
|----------|---------|
| **SPEC.md** | Product behavior, invariants, API contracts |
| **CLAUDE.md** | Engineering protocols, verification commands, incident handling |

**Golden Rule:** If code and SPEC.md disagree, the code is BROKEN.

---

## PROJECT_KNOBS

**Replace these values when cloning the template:**

```bash
PROJECT_NAME=my-project          # Used in package.json, logs, PM2
BACKEND_PORT=4000                # Express/API server port
FRONTEND_PORT=5173               # Vite/React dev server port
API_BASE_URL=http://localhost:4000/api
DOMAIN=example.com               # Production domain
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
REDIS_URL=redis://localhost:6379
```

---

## Canonical Verification

Run from repo root:

```bash
npm run check:quick    # Health checks only (~5s)
npm run check:fast     # Lint + typecheck + build + health (~90s)
npm run check:full     # Fast + tests + UI smoke (~3-5min)
npm run check:security # Security validation
npm run contract:check # Verify frontend/backend alignment
npm run validate:env   # Validate environment variables
```

---

## System Status Levels

| Status | Requirement | When to use |
|--------|-------------|-------------|
| **PARTIALLY ACTIVE** | `check:quick` passes | After config-only or doc-only changes |
| **ACTIVE** | `check:fast` passes | After any code change (default) |
| **RELEASE-READY** | `check:full` AND `contract:check` AND `check:security` pass | Before merge to main |

---

## Protocols (Mandatory)

### P1: Autonomous Full-Stack Fixes
Fix backend if frontend requires it. Fix frontend if backend breaks it. Never ask permission for cross-stack fixes.

### P2: Batch Changes, Single Verification
Plan first. Implement all related changes together. Run the appropriate check ONCE after the batch, not after each file.

### P3: Contract-First
When modifying API endpoints, DB schema, or shared types: update SPEC.md FIRST, then implement. Always run `contract:check` after contract changes.

### P4: Self-Healing (2 attempts before escalating)
If a command fails: Attempt 1 (analyze + fix) → Attempt 2 (alternative) → If still failing, output INCIDENT REPORT.

### P5: Never Weaken Checks
Never add `|| true`, delete tests, or skip checks to make them pass. Fix the code instead.

### P6: Verification Honesty
Never claim a check passed without running it. If skipped, say "I did not run the full check."

### P7: Fact Hygiene
Before stating repo facts (file counts, ports, paths), verify by scanning. If unverified, label as "UNVERIFIED".

### P8: Safe Failure Simulation
When testing failure scenarios:
- **NEVER sabotage repository files** (delete code, corrupt configs)
- **DO simulate failures by**: stopping external dependencies, setting env vars, using test endpoints
- After simulating failure, **always restore** the system

### P9: Plan Before Every Change
Even small changes get a written plan. Before touching code, state: "What am I changing and why?" This applies to one-line fixes too. Plans prevent drift and make reviews possible. Write it down — even if it's two sentences.

### P10: Test Immediately
Run relevant tests after every change, not "later." If no tests exist for the area you're changing, write them first (TDD). A change without a test run is an unverified change, and unverified changes are broken until proven otherwise.

### P11: Proactive Scanning
After completing work, scan for collateral damage before declaring victory:
- Unused imports
- Type errors in adjacent files
- Regressions in related features
- Console warnings or errors

Don't wait for CI to tell you what you should have caught locally.

### P12: Memory Discipline
After discovering gotchas, workarounds, or lessons learned: **document them immediately.** Mental notes don't survive sessions. If you learned something the hard way, write it down so the next session (or the next developer) doesn't repeat the mistake.

---

## Structured Handover (after every task)

```
A) What changed (plain English)
B) Check result: PASSED / FAILED / SKIPPED (with reason)
C) System status: PARTIALLY ACTIVE / ACTIVE / RELEASE-READY
D) Next step suggestion
```

---

## Incident Report Format (after 2 failed fix attempts)

```
═══════════════════════════════════════════════════════════════════
INCIDENT REPORT: [Brief description]
═══════════════════════════════════════════════════════════════════

EXACT FAILING COMMAND:
$ [full command as executed]

KEY ERROR LINES:
[3-5 most relevant error lines]

WHAT CHANGED:
- [Files/configs modified since last working state]

LIKELY ROOT CAUSE:
[Specific analysis]

SMALLEST NEXT FIX:
[Single smallest change that might resolve]
═══════════════════════════════════════════════════════════════════
```

---

## Quick Reference

| Port | Service | Default |
|------|---------|---------|
| BACKEND_PORT | Backend API | 4000 |
| FRONTEND_PORT | Frontend (Vite) | 5173 |
| 5432 | PostgreSQL | - |
| 6379 | Redis | - |

| Path | Purpose |
|------|---------|
| `backend/` | Express API |
| `frontend/` | React + Vite |
| `shared/` | Shared types/contracts |
| `scripts/` | Verification scripts |
| `SPEC.md` | Product specification |

---

## What NOT to Duplicate Here

The following are defined in SPEC.md — do not restate:
- State machines
- API response envelope and error codes
- Invariants
- Parsing rules
