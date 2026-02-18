# Getting Started with Vibe Coding 🚀

## What is Vibe Coding?

You describe what you want in plain English. An AI builds it for you. You stay in the driver's seat — steering, reviewing, iterating — while the AI handles the typing. That's it. That's vibe coding.

## Prerequisites

- **Node.js 20+** — check with `node --version`
- **An AI coding tool** — Claude Code, Cursor, Copilot, whatever you like
- That's literally it.

---

## Your First 5 Minutes

### 1. Get the template

```bash
# Use as a GitHub template, or just clone it
git clone https://github.com/your-org/vibe-stack-template my-app
cd my-app
```

### 2. Install everything

```bash
npm install
```

This installs the frontend, backend, and shared packages. One command, done.

### 3. Start the app

```bash
npm run dev
```

This fires up both the backend API and the React frontend. You'll see output from both.

### 4. Open your browser

Go to [http://localhost:5173](http://localhost:5173) (or whatever port Vite tells you).

You should see a working task manager. Add a task. Check it off. Delete it. It works. You didn't write a single line of code yet, and you already have a running app with a real API.

**That's your starting point.** Everything from here is vibes.

---

## Your First Vibe Session

Let's walk through an actual session. You're going to add a priority field to tasks — high, medium, low — with color coding in the UI.

### Step 1: Tell Claude what you want

Open your AI coding tool and say something like:

> "Add a priority field to tasks. It should be high, medium, or low. Default to medium. Show it in the UI with color coding — red for high, yellow for medium, green for low."

That's it. Natural language. No pseudocode needed.

### Step 2: Watch the guardrails work

A well-configured Claude will:

1. **Check SPEC.md** first — understand the current architecture and data model
2. **Write a plan** — "I'll update the shared types, add the field to the backend schema, update the API handlers, then update the React components"
3. **Implement step by step** — shared types → backend → frontend, in order
4. **Run verification** — `npm run check:fast` to make sure nothing's broken

You'll see it updating the `Task` interface in `shared/src/index.ts`, adding the field to the database schema, updating the API endpoints, and adding colored badges to the UI.

### Step 3: When a check fails

It will happen. A type error, a failing test, a lint warning. That's the point.

**The rule is simple: fix it, don't skip it.**

If `npm run check:fast` shows errors, Claude should fix them right there. Not "I'll come back to this later." Not commenting out the test. Fix. It. Now.

This is what separates vibe coding from vibe *hoping*. The guardrails catch mistakes early, before they compound into a mess.

### Step 4: Review and iterate

Look at what Claude built. Try it in the browser. Maybe you want the colors to be different. Maybe you want a priority filter. Just say so:

> "Add a filter dropdown that lets me show only high-priority tasks."

Iterate until it feels right. That's the vibe.

---

## The Guardrails Explained

Vibe coding without guardrails is just generating code and praying. Here's what keeps things solid:

### CLAUDE.md — Your AI's Rulebook

This file tells Claude (or any AI tool) how to behave in your project. Read SPEC.md first. Plan before coding. Run checks after changes. Don't skip tests. It's like onboarding a new developer, except the developer has perfect memory and reads the whole doc every time.

### SPEC.md — The Source of Truth

Your app's architecture, data model, API contracts, design decisions — all in one place. When Claude needs to understand "how does this app work?", SPEC.md is the answer. Keep it updated as your app evolves.

### Scripts — Automated Verification

- `npm run check:fast` — Quick checks: types, lint, format. Run after every change.
- `npm run check:full` — Everything: tests, build, the works. Run before committing.

These scripts are your safety net. They catch type errors, broken imports, style violations, and test failures before they reach production.

### CI — Catches What You Missed

GitHub Actions (or whatever CI you use) runs `check:full` on every push. Even if you forgot to run checks locally, CI has your back. It's the last line of defense.

---

## Making It Yours

The task manager is a demo. Here's how to replace it with your actual app.

### 1. Switch to Project Mode

The template might ship in "template mode" with demo content. Check the README or `PROJECT_KNOBS` config to switch to project mode — this typically removes demo data and adjusts defaults.

### 2. Update PROJECT_KNOBS

`PROJECT_KNOBS` (or your project config) controls things like the app name, database settings, and feature flags. Update these to match your project.

### 3. Replace the Task Manager

Start fresh or evolve it:

- **Fresh start:** Clear out the task-related code and tell Claude "Build me a [your app idea] using the same patterns as the existing code."
- **Evolve it:** If your app is also a CRUD app (and let's be honest, most are), just reshape the task model into whatever you need. "Rename Task to Recipe. Add ingredients as a string array. Add a cookingTime field in minutes."

### 4. Keep the Guardrails

This is important: **don't delete CLAUDE.md, SPEC.md, or the check scripts.** They scale with your project. A side project and a production app both benefit from type checking, linting, and automated tests. The guardrails aren't training wheels — they're seat belts.

Update SPEC.md as your app changes. Update CLAUDE.md if you want different AI behavior. But keep them.

---

## Tips from the Trenches

- **Start small, iterate fast.** Don't ask for "build me a complete e-commerce platform." Ask for "create a product listing page with name, price, and image." Then add features one at a time. Small bites, quick feedback.

- **Read what the AI writes.** Vibe coding isn't "close your eyes and accept all changes." Skim the code. Does it make sense? Is it doing something weird? You don't need to understand every line, but you should understand the shape of what's happening. Your gut is a good debugger.

- **When you're stuck, describe the problem, not the solution.** Instead of "add a useEffect with a setTimeout," say "the notification should disappear after 3 seconds." Let the AI figure out the implementation. You'll often get a better solution than what you had in mind.

- **Commit often.** After each successful feature, commit. `git add -A && git commit -m "add priority field with color coding"`. If the next change goes sideways, you can always roll back to a working state. Cheap insurance.

---

That's it. You've got a working app, a set of guardrails, and a workflow. Now go build something. 🎉
