---
name: assess
description: |
  Structured multi-pass system assessment with dimensional analysis. Use when the user wants
  to evaluate, critique, or assess a software system's architecture, UX, problem-fit,
  observability, robustness, or operational qualities. Triggers: "assess", "system assessment",
  "critique this system", "evaluate", "design review", "assess-system".
user-invocable: true
disable-model-invocation: false
arguments: $ARGUMENTS
---

# /assess — System Assessment Skill

Structured multi-pass system assessment with dimensional analysis. Produces grounded,
evidence-backed reports with finding IDs, severity rankings, and actionable recommendations.

Each assessment pass runs as a self-contained TODO task that fills an entire context window
(~180k tokens). This maximizes depth per pass while maintaining cross-pass coherence through
a shared methodology document and finding ID system.

**Integration:** Uses `.agents/TODO/` for task tracking. Creates tasks that execute through
the standard `/todo work` protocol or via `/todo start`.

---

## Path Resolution

When this SKILL.md is loaded, note the absolute path it was read from. Derive:

- **Skill dir** (`{skill}`): the directory containing this file
- **Methodology template**: `{skill}/references/methodology-template.md`

Resolve to absolute paths before use.

## Execution Rules

1. **Each pass runs as a TODO task** — created in `.agents/TODO/` of the target project. Each task
   is self-contained with full system context, methodology reference, and pass-specific instructions.
2. **Strict linear dependency chain** — each task `depends-on` the previous one.
3. **METHODOLOGY.md** — written to the reports directory before task creation. All tasks reference it.
4. **The skill creates the plan, agents execute it** — the skill generates TODO tasks and outputs
   next steps. Actual assessment execution happens when tasks are picked up.
5. **Assessment never modifies source code** — output is reports only.
6. **Reports directory** — all output goes to `{reports-dir}/` within the target project.

## Flags

| Flag | Default | Effect |
|------|---------|--------|
| `--phases` | `both` | Which phases: `1` (self-contained), `2` (comparative), `both` |
| `--passes` | `3` | Passes per phase (2-4). 3 is the sweet spot. |
| `--dimensions` | `ARCH,UX,FIT,OBS,ROB,OPS` | Override assessment dimensions (comma-separated) |
| `--playwright` | `true` | Capture UI screenshots in Phase 1 Pass 1 |
| `--ecosystem-reports` | `.agents/reports/ecosystem-reports/` | Path to ecosystem research reports (Phase 2) |
| `--reports-dir` | `.agents/reports/system-critique/` | Output directory for all reports |
| `--name` | *(auto-detected)* | Project name for report headers |

## Routing

| Input | Route |
|-------|-------|
| *(empty or no path argument)* | **assess** — Discover system, create tasks |
| `status` | **status** — Show assessment progress |

---

## Route: assess (default)

### Step 1: Parse args and flags [orchestrator]

Parse `$ARGUMENTS` for flags. Apply defaults for any unspecified flags.

Validate:
- `--phases` is one of: `1`, `2`, `both`
- `--passes` is 2-4
- `--dimensions` are valid codes (2-4 uppercase letters each)
- If `--phases` includes `2`, `--ecosystem-reports` path must exist with `.md` files

### Step 2: Discover system context [orchestrator]

Build a **system context block** by reading project files. This block is embedded verbatim
in every task body so agents understand the target system without rediscovery.

**Read these files** (skip any that don't exist):
- `CLAUDE.md` — project purpose, structure, conventions
- `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` — dependencies, scripts, name
- `docker-compose.yml` / `Tiltfile` — infrastructure
- `tsconfig.json` / `biome.json` / `.eslintrc.*` — tooling
- Top-level directory listing

**Produce a system context block** (300-500 words):

```markdown
## System Under Assessment

**{name}** is {one-sentence purpose}.

**Stack:**
- {language/runtime}, {framework} ({port})
- {frontend} ({port})
- {database}
- {infrastructure}
- {dev tooling}

**Core entity hierarchy:**
{key entities and relationships}

**Source layout:**
- `{dir}/` — {description}
- `{dir}/` — {description}
```

Store this block — it goes into every task body.

### Step 3: Discover source files [orchestrator]

Build a **file inventory** for Phase 1 Pass 1. Organize by layer/concern:

```
Server/Backend:
  - Entry + routes: {paths}
  - Engine/core: {paths}
  - DB layer: {paths}
  - Migrations: {paths}

Frontend/UI:
  - Routes: {paths}
  - Components: {paths}
  - Lib/hooks: {paths}

Shared:
  - Types/schemas: {paths}

Config:
  - {paths}
```

Skip: `node_modules/`, `dist/`, `.git/`, build output, generated files, lock files, binaries.

This inventory goes into Phase 1 Pass 1 only. Subsequent passes use prior reports to decide
what to read.

### Step 4: Create reports directory [orchestrator]

```bash
mkdir -p {reports-dir}
mkdir -p {reports-dir}/screenshots  # only if --playwright is true
```

### Step 5: Write METHODOLOGY.md [orchestrator]

Read `{skill}/references/methodology-template.md`. Customize for the target system:

1. **Dimensions table** — if `--dimensions` overrides defaults, update the table. For non-default
   dimension codes, provide a name and evaluation description for each.

2. **Playwright targets** — if `--playwright`, derive 5-8 target screens from the system context
   (home/dashboard, list views, detail views, config, results, comparison). If `--playwright`
   is false, remove the entire Playwright section.

3. **Report paths** — update example paths to use `{reports-dir}`.

4. **Phase 2 section** — if `--phases` is `1`, remove the comparative lens section. If it includes
   `2`, list the actual ecosystem report paths discovered at `{ecosystem-reports}`.

Write the customized methodology to `{reports-dir}/METHODOLOGY.md`.

### Step 6: Create Phase 1 tasks [orchestrator]

Create TODO tasks for Phase 1. Write each task as a markdown file to `.agents/TODO/`.

**Task frontmatter pattern:**
```yaml
slug: system-critique-p1-pass{N}
title: "Assessment: Phase 1 Pass {N} — {focus description}"
priority: P1
status: backlog
created: {today}
updated: {today}
depends-on: [{previous task slug, or [] for Pass 1}]
tags: [assessment]
```

**Dependency chain:** Pass 1 → Pass 2 → ... → Pass N → Synthesis

**Pass focus mapping:**

| Pass | Focus | Title Suffix |
|------|-------|-------------|
| 1 | BREADTH | Initial familiarization & broad assessment |
| 2 | DEPTH | Deep investigation |
| 3 | NUANCE | Systemic patterns & cross-dimension interactions |
| 4+ | EXPERT | Edge cases, failure scenarios & stress testing |

Generate one task per pass plus a synthesis task (`system-critique-p1-synthesis`).

---

#### Task Body: Phase 1 Pass 1 (Breadth)

```markdown
# Phase 1 Pass 1 — Initial Familiarization & Broad Assessment

{system context block from Step 2}

## Task

1. **Read the methodology** at `{reports-dir}/METHODOLOGY.md` — defines dimensions,
   finding IDs, report templates.

2. **Systematically read the codebase** (breadth-first, all layers):
   {file inventory from Step 3, with specific file paths organized by layer}

3. {IF --playwright}**Use Playwright to capture the UI** (5-8 screenshots):
   - First check if dev server is running ({ports from system context}).
     Start with `{dev command}` if needed.
   - Navigate to `{dev URL}` and capture key screens:
     {screenshot targets from METHODOLOGY.md}
   - Save screenshots to `{reports-dir}/screenshots/` with descriptive filenames.
   - Note UI state observations (empty states, loaded data, layout) in the assessment.{END IF}

4. **Trace the end-to-end flow** through both code {IF --playwright}and UI{END IF}:
   {2-4 questions about the primary user workflow, derived from system context.
    e.g., "How does a user create X, configure Y, run Z, and view results?"}

5. **Assess each dimension** ({dimensions list}) with specific findings, evidence,
   and code references (`file:line`).

6. **Produce two reports:**
   - `{reports-dir}/p1-pass1-assessment.md`
   - `{reports-dir}/p1-pass1-critique.md`

   Follow the templates in METHODOLOGY.md. Use finding IDs like `P1.1.{DIM}.01`.

## Pass Focus: BREADTH

Cast a wide net. Goal: complete picture of the system across all dimensions.
Don't go too deep into any one area — that's for Pass 2. But read enough code
to form grounded opinions backed by specific file:line references, not surface
impressions.

## Important Notes

- Be honest and critical. This is a design review, not a validation exercise.
- Ground findings in specific code references and UI observations.
- The "Questions for Further Investigation" section in the critique report is
  especially important — it guides Pass 2.
{IF --playwright}- Playwright screenshots are token-expensive. Be targeted: capture,
  note observations, move on.{END IF}
{IF has UI}- If the database has no data (empty lists), note that as a UX finding
  and assess the UI structure even without data.{END IF}
```

---

#### Task Body: Phase 1 Pass 2+ (Depth / Nuance / Expert)

```markdown
# Phase 1 Pass {N} — {Focus Title}

{system context block — abbreviated version for passes 2+, since the agent
 will read the full context from prior reports and METHODOLOGY.md}

## Task

1. **Read the methodology** at `{reports-dir}/METHODOLOGY.md`

2. **Read all prior Phase 1 reports** ({2*(N-1)} files):
   {list each prior assessment and critique report path}

3. **Focus on "Questions for Further Investigation"** from the most recent critique.

4. {Pass-specific instructions:
   - DEPTH: Deep-dive into flagged areas. Follow code paths. Examine error handling.
     Trace data flows. Analyze edge cases in detail.
   - NUANCE: Focus on interactions between dimensions. Look for systemic patterns.
     Challenge previous findings with fresh evidence. Find what was missed.
   - EXPERT: Stress-test assumptions. Consider failure scenarios. Examine performance
     characteristics. Look for subtle correctness issues.}

5. **Re-assess dimensions** where prior passes were uncertain or where new evidence
   warrants revision.

6. **Produce two reports:**
   - `{reports-dir}/p1-pass{N}-assessment.md`
   - `{reports-dir}/p1-pass{N}-critique.md`

   Use finding IDs like `P1.{N}.{DIM}.01`. Reference prior finding IDs when
   confirming, revising, or challenging earlier findings.

## Pass Focus: {FOCUS}

{Focus-specific guidance from the pass focus mapping.}
```

---

#### Task Body: Phase 1 Synthesis

```markdown
# Phase 1 Synthesis — Final Assessment

{abbreviated system context}

## Task

1. **Read the methodology** at `{reports-dir}/METHODOLOGY.md` — especially the
   synthesis report template.

2. **Read ALL Phase 1 reports** ({2 * passes} files):
   {list every assessment and critique report path}

3. **Consolidate findings:**
   - Deduplicate findings that describe the same issue from different angles
   - Merge related findings into coherent themes
   - Resolve contradictions between passes (later passes have more context, but
     earlier passes may have caught things that later passes over-corrected on)
   - Track which findings were confirmed across multiple passes vs. single-pass only

4. **Rate each dimension** on a 1-5 scale:
   - 1: Fundamentally broken — blocks use
   - 2: Weak — significant issues that degrade value
   - 3: Adequate — works but with notable friction or gaps
   - 4: Strong — well-designed with minor issues
   - 5: Excellent — exemplary implementation

5. **Prioritize recommendations** into three tiers:
   - **Immediate:** Must fix before production use
   - **Short-term:** Should address in the next development cycle
   - **Medium-term:** Worth doing but can wait

6. **Produce the synthesis report:** `{reports-dir}/p1-synthesis.md`

## Important Notes

- This is the authoritative output of Phase 1. Concise, well-organized, actionable.
- New synthesis-only findings use `P1.S.{DIM}.{##}`.
- The synthesis must work as a **standalone document** — someone who hasn't read
  the individual pass reports should understand the full picture.
- Be ruthlessly honest in the scorecard.
- "Strengths" matters as much as "Weaknesses" — it tells us what to protect.
- "Open Questions" captures things that need user input or empirical testing.
```

---

### Step 7: Create Phase 2 tasks [orchestrator]

**Skip if `--phases` is `1`.**

#### Prerequisites check

List `.md` files at `{ecosystem-reports}`. If none found, warn:

> Phase 2 requires ecosystem research reports at `{ecosystem-reports}`.
> Prepare these first (platform comparisons, landscape analysis, feature gap analysis),
> then re-run with `--phases 2`.

Skip Phase 2 task creation if no reports found.

#### Discover ecosystem reports

Read the first ~50 lines of each `.md` file at `{ecosystem-reports}` to build a
description block:

```markdown
## Ecosystem Research

- `{path}` — {brief description of contents}
- `{path}` — {brief description}
```

This block is embedded in every Phase 2 task.

#### Task creation

Same frontmatter pattern as Phase 1 with slugs `system-critique-p2-pass{N}` and
`system-critique-p2-synthesis`. Phase 2 Pass 1 depends on `system-critique-p1-synthesis`.

---

#### Task Body: Phase 2 Pass 1 (Breadth)

```markdown
# Phase 2 Pass 1 — Ecosystem Comparison: Broad Survey

{abbreviated system context}

## Context

Phase 1 (self-contained assessment) is complete. Phase 2 evaluates the system
through the lens of the existing ecosystem — comparing capabilities, identifying
gaps, and evaluating adoption opportunities.

{ecosystem reports block}

## Task

1. **Read the methodology** at `{reports-dir}/METHODOLOGY.md`

2. **Read the Phase 1 synthesis:** `{reports-dir}/p1-synthesis.md`

3. **Read all ecosystem research reports** (listed above).

4. **For each dimension** ({dimensions}), evaluate:
   - How does the system compare to best-in-class in the ecosystem?
   - What specific capabilities do ecosystem tools offer that we lack?
   - What capabilities do we have that the ecosystem lacks? (unique advantages)
   - Which Phase 1 weaknesses could be addressed by ecosystem-inspired improvements?
   - Which ecosystem ideas are most relevant to our stated purpose?

5. **Assess adoption feasibility** for the most promising ideas:
   - Implementation complexity (how much code changes?)
   - Architectural compatibility (does it fit our existing design?)
   - Maintenance burden (does it add ongoing complexity?)
   - Problem-fit (does it actually solve a problem we have?)

6. **Read relevant source code** to understand how adopted ideas would integrate.

7. **Produce two reports:**
   - `{reports-dir}/p2-pass1-assessment.md`
   - `{reports-dir}/p2-pass1-critique.md`

   Use finding IDs like `P2.1.{DIM}.01`. Reference Phase 1 finding IDs when
   connecting ecosystem capabilities to Phase 1 weaknesses.

## Pass Focus: BREADTH

Survey the full landscape comparison across all dimensions. Map ecosystem
capabilities to assessment dimensions. Identify the most promising adoption
candidates. Don't go deep on implementation details — that's for Pass 2.

## Important Notes

- Be practical. "Could adopt" ≠ "should adopt." Weigh cost vs. benefit.
- Distinguish "better than us" from "better for us." A platform might be superior
  in ways that don't matter for our use case.
- Cross-reference Phase 1 findings: weakness + ecosystem solution = high signal.
```

---

#### Task Body: Phase 2 Pass 2+ (Depth / Nuance / Expert)

```markdown
# Phase 2 Pass {N} — {Focus Title}

{abbreviated system context}

{ecosystem reports block}

## Task

1. **Read the methodology** at `{reports-dir}/METHODOLOGY.md`

2. **Read prior Phase 2 reports + Phase 1 synthesis:**
   {list all prior P2 report paths + p1-synthesis.md}

3. **Focus on "Questions for Further Investigation"** from the most recent P2 critique.

4. {Pass-specific instructions:
   - DEPTH: Deep-dive into source code to understand integration paths. Design
     implementation strategies for top adoption candidates. Identify prerequisites
     and dependencies. Assess what existing code would need to change.
   - NUANCE: Focus on tradeoffs. Which ideas should we NOT adopt, and why? Assess
     production readiness. Challenge previous adoption recommendations. Resolve
     open questions with concrete decisions.
   - EXPERT: Stress-test the adoption strategy. Consider maintenance burden at scale.
     Look for ideas dismissed too quickly or adopted too eagerly.}

5. **Produce two reports:**
   - `{reports-dir}/p2-pass{N}-assessment.md`
   - `{reports-dir}/p2-pass{N}-critique.md`

   Use finding IDs like `P2.{N}.{DIM}.01`.

## Pass Focus: {FOCUS}

{Focus-specific guidance.}
```

---

#### Task Body: Phase 2 Synthesis

```markdown
# Phase 2 Synthesis — Final Comparative Assessment

{abbreviated system context}

## Task

1. **Read the methodology** at `{reports-dir}/METHODOLOGY.md` — especially the
   synthesis template.

2. **Read the Phase 1 synthesis:** `{reports-dir}/p1-synthesis.md`

3. **Read ALL Phase 2 reports** ({2 * passes} files):
   {list every P2 assessment and critique report path}

4. **Produce an integrated assessment:**
   - Revised dimension ratings reflecting both self-assessment and ecosystem comparison
   - Adoption roadmap with phased implementation (what to adopt, in what order,
     with what prerequisites)
   - Production readiness assessment — is this system ready for its stated purpose?
   - What to preserve (unique advantages) vs. what to change (ecosystem-informed)

5. **Produce the synthesis report:** `{reports-dir}/p2-synthesis.md`

## Important Notes

- This is the authoritative output of the full assessment (Phase 1 + Phase 2).
- New synthesis-only findings use `P2.S.{DIM}.{##}`.
- The adoption roadmap must be concrete and phased — not a wish list.
- Be clear about what the system should NOT adopt and why.
- Answer the production readiness question directly.
```

---

### Step 8: Commit [orchestrator]

Two separate commits:

```bash
# 1. Methodology
git add {reports-dir}/METHODOLOGY.md
git commit -m "[assessment] Write methodology for {name} system assessment"

# 2. Tasks
git add .agents/TODO/system-critique-*.md
git commit -m "[todo] Create {N} assessment tasks for {name} ({phases description})"
```

### Step 9: Run /todo lint [orchestrator]

Run the lint procedure to regenerate INDEX.md with the new tasks.

### Step 10: Output summary [orchestrator]

```
Assessment Plan Created
───────────────────────
System: {name}
Dimensions: {dimensions}
Phases: {phases}  Passes per phase: {passes}
Reports: {reports-dir}

Tasks created:
  Phase 1:
    ○ system-critique-p1-pass1 — Breadth
    ○ system-critique-p1-pass2 — Depth
    ○ system-critique-p1-pass3 — Nuance
    ○ system-critique-p1-synthesis — Consolidation
  {IF phase 2:}
  Phase 2:
    ○ system-critique-p2-pass1 — Ecosystem breadth
    ○ system-critique-p2-pass2 — Ecosystem depth
    ○ system-critique-p2-pass3 — Integration strategy
    ○ system-critique-p2-synthesis — Final assessment

Starting work loop...
```

### Step 11: Auto-start work loop [orchestrator]

Invoke the TODO skill to immediately begin executing assessment tasks:

```
/todo work loop --filter tags:assessment --auto-clear
```

This:
- **`loop`** — executes tasks continuously until no eligible assessment tasks remain
- **`--filter tags:assessment`** — restricts picking to tasks tagged `assessment`, preventing
  the loop from picking up unrelated project tasks. The filter is persisted in `.work-state`
  so it survives context clears.
- **`--auto-clear`** — restarts Claude between tasks for a fresh context window. Each assessment
  pass fills ~180k tokens of context, so a clean slate between passes is essential.

The TODO skill's pick logic will select `system-critique-p1-pass1` first (it has no
dependencies and is the highest-priority eligible task). After each pass completes, the
dependency chain unlocks the next pass automatically.

---

## Route: status

Query assessment progress by checking task files:

```bash
ls .agents/TODO/system-critique-*.md .agents/TODO/done/system-critique-*.md 2>/dev/null
```

Read frontmatter of each task to get status. Display:

```
Assessment Progress
───────────────────
Phase 1:
  ✓ Pass 1 — done
  ✓ Pass 2 — done
  → Pass 3 — in-progress
  ○ Synthesis — backlog

Phase 2:
  ○ Pass 1 — backlog (blocked by P1 Synthesis)
  ○ Pass 2 — backlog
  ○ Pass 3 — backlog
  ○ Synthesis — backlog

Reports: {reports-dir}/
  ✓ METHODOLOGY.md
  ✓ p1-pass1-assessment.md, p1-pass1-critique.md
  ✓ p1-pass2-assessment.md, p1-pass2-critique.md
  ○ p1-pass3 (pending)
  ...
```

---

## Customization Guide

### Custom Dimensions

Override `--dimensions` with custom codes. Each custom dimension needs a name and
evaluation description, which the orchestrator adds to METHODOLOGY.md.

**Examples:**
- Security-focused: `--dimensions ARCH,ROB,SEC,OPS` (add SEC for security posture)
- Performance-critical: `--dimensions ARCH,PERF,ROB,OPS` (add PERF)
- API/library: `--dimensions ARCH,API,FIT,OPS` (replace UX with API ergonomics)

### Non-Web Systems

Set `--playwright false` for CLI tools, libraries, or backend-only systems. The UX
dimension naturally adapts to focus on API ergonomics, documentation, CLI experience,
or SDK usability.

### Phase 2 Prerequisites

Phase 2 requires ecosystem research reports — platform profiles, feature comparisons,
landscape analysis. The skill does NOT generate these; it assumes they exist at
`--ecosystem-reports`. Prepare them before running Phase 2.

### Adjusting Pass Count

- **2 passes:** Breadth + Depth + Synthesis. For small systems or time-constrained reviews.
- **3 passes:** Breadth + Depth + Nuance + Synthesis. Sweet spot for most systems.
- **4 passes:** Adds Expert pass. For complex systems or unresolved questions after 3 passes.

---

## Git Discipline

- **Assessment never modifies source code** — output is reports only
- Commit methodology separately from pass reports
- Commit task files with `[todo]` prefix
- Commit reports after each pass: `[assessment] Phase {N} Pass {M}: {brief summary}`
- Stage specific files, never `git add -A`
