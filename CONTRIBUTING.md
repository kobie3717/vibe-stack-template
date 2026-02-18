# Contributing

Thanks for your interest in the Vibe Stack Template!

## Using the Template

1. Click **"Use this template"** on GitHub to create your own repo
2. Set `TEMPLATE_MODE` to `false`
3. Update `CLAUDE.md` PROJECT_KNOBS with your project values
4. Build your project on top of the template structure

This is a starting point, not a framework. Fork it, change it, make it yours.

## Reporting Issues

- **Bug reports:** Open an issue with the steps to reproduce, expected behavior, and actual behavior
- **Feature requests:** Open an issue describing the use case and why it would help
- **Questions:** Use GitHub Discussions if available, or open an issue tagged `question`

## Code Style

- TypeScript for backend and frontend
- ESLint for linting (configure per your project needs)
- Prettier for formatting (recommended)
- Meaningful commit messages — describe *what* and *why*, not just *what file*

## The Verification Workflow

Before submitting a PR, run the appropriate checks:

```bash
# Template structure changes
npm run check:template

# Code changes
npm run check:fast

# Before merge
npm run check:full

# Security-sensitive changes
npm run check:security
```

All CI checks must pass. We don't merge with failing checks, and we don't weaken checks to make them pass (see Protocol P5 in CLAUDE.md).

## Pull Requests

1. Fork the repo and create a feature branch
2. Make your changes
3. Run verification (`npm run check:fast` minimum)
4. Open a PR with a clear description of what changed and why
5. Respond to review feedback

## Philosophy

- **SPEC.md is the source of truth.** If code and spec disagree, the code is wrong.
- **No false greens.** CI must fail loudly when things are broken.
- **Guardrails over speed.** Ship fast, but not broken.
