# System Assessment Methodology

## Overview

A structured multi-pass assessment process for evaluating software systems. Each pass increases in depth and nuance, building on findings from previous passes. Two phases: Phase 1 (self-contained system assessment) and Phase 2 (comparative ecosystem assessment).

## Assessment Dimensions

| Code | Dimension | What to Evaluate |
|------|-----------|-----------------|
| ARCH | Architecture/Design | Separation of concerns, data model adequacy, extensibility points, code organization, dependency management, abstraction quality |
| UX | UX/Workflow | End-to-end user flow friction, discoverability, information density, feedback loops, error states, progressive disclosure |
| FIT | Problem-Fit | Does the system solve the right problems for its stated purpose? Are there capability gaps or misaligned abstractions? |
| OBS | Observability | Can you understand what happened in a run and why? Debugging support, logging, state visibility, audit trail |
| ROB | Robustness | Error handling, edge cases, failure modes, recovery paths, data integrity, input validation |
| OPS | Operational | Deployment complexity, configuration management, maintenance burden, upgrade path, documentation adequacy |

## Finding ID Scheme

Pattern: `P{phase}.{pass}.{DIM}.{##}`

- Phase: 1 (self-contained assessment) or 2 (comparative ecosystem assessment)
- Pass: 1, 2, 3, or S (synthesis)
- DIM: dimension code from the table above
- ##: sequential number within dimension per pass

Examples:
- `P1.1.ARCH.01` — Phase 1, Pass 1, Architecture finding #1
- `P2.3.UX.04` — Phase 2, Pass 3, UX finding #4
- `P1.S.FIT.01` — Phase 1, Synthesis, new Problem-Fit finding #1

## Report Templates

### Assessment Report (`p{phase}-pass{N}-assessment.md`)

```markdown
# Phase {phase} Pass {N} — Assessment Report

**Date:** {date}
**Pass focus:** {breadth | depth | nuance | expert}
**Files examined:** {count}
**Playwright screenshots:** {count, Pass 1 only if applicable}

## Executive Summary

{2-3 paragraphs summarizing key findings across all dimensions}

## Dimension Assessments

### {CODE} — {Dimension Name}

**Status:** {Strong | Adequate | Weak | Mixed}

{Narrative assessment with specific code references and finding IDs}

#### Findings
- **P{X}.{Y}.{CODE}.01** — {finding title}: {description with evidence}
- **P{X}.{Y}.{CODE}.02** — ...

{Repeat for each dimension}

## Cross-Cutting Themes

{Patterns that span multiple dimensions}

## Summary Table

| Dimension | Status | Finding Count | Key Issue |
|-----------|--------|--------------|-----------|
| ... | ... | ... | ... |
```

### Critique Report (`p{phase}-pass{N}-critique.md`)

```markdown
# Phase {phase} Pass {N} — Critique Report

**Date:** {date}

## Executive Summary

{2-3 paragraphs summarizing the most important issues and opportunities}

## Severity-Ranked Issues

### Critical
{Issues that would block production use or cause data loss/corruption}

- **{ID}** [{DIM}] — {title}
  - **Description:** ...
  - **Evidence:** {code reference, screenshot, behavior observation}
  - **Impact:** ...
  - **Suggested Remedy:** ...

### Major
{Issues that significantly degrade usability or reliability}

### Minor
{Issues that are annoying but workable}

### Observations
{Things that aren't wrong but are worth noting}

## Opportunities

{Things not broken but could be significantly better}

| ID | Dimension | Opportunity | Potential Impact |
|----|-----------|-------------|-----------------|
| ... | ... | ... | ... |

## Questions for Further Investigation

{Specific questions to pursue in the next pass}

1. ...
2. ...
```

### Synthesis Report (`p{phase}-synthesis.md`)

```markdown
# Phase {phase} — Synthesis Report

**Date:** {date}
**Passes incorporated:** {pass list}

## Executive Summary

{Authoritative 3-5 paragraph summary of the full assessment}

## System Scorecard

| Dimension | Rating (1-5) | Trend Across Passes | Summary |
|-----------|-------------|--------------------|---------|
| ... | ... | ... | ... |
| **Overall** | ... | | ... |

## Consolidated Finding Registry

{All findings from all passes, deduplicated and cross-referenced}

### Critical & Major Findings

| ID | Dim | Title | First Found | Confirmed In | Status |
|----|-----|-------|------------|-------------|--------|
| ... | ... | ... | Pass 1 | Pass 2, 3 | ... |

### Minor Findings & Observations
{Summary table}

## Prioritized Recommendations

### Immediate (before production use)
1. ...

### Short-term (next development cycle)
1. ...

### Medium-term (future iterations)
1. ...

## Strengths
{What the system does well — things to preserve and build on}

## Weaknesses
{Systemic issues that need addressing}

## Open Questions
{Unresolved questions that need user input or further investigation}
```

## Pass Focus Guidelines

| Pass | Focus | Depth | Approach |
|------|-------|-------|----------|
| Pass 1 | **Breadth** | Surface to medium | Read all major files. Trace e2e flows. Capture UI screenshots (if applicable). Identify all dimensions. Cast a wide net. |
| Pass 2 | **Depth** | Medium to deep | Focus on areas flagged in Pass 1. Read deeper into specific code paths. Analyze data model implications. Follow dependency chains. |
| Pass 3 | **Nuance** | Deep to expert | Focus on interactions between dimensions. Look for systemic patterns. Consider edge cases. Challenge previous findings. Find what you missed. |
| Pass 4 | **Expert** | Expert | Stress-test assumptions. Consider failure scenarios. Examine performance characteristics. Look for subtle correctness issues. |
| Synthesis | **Integration** | Complete | Consolidate all findings. Resolve contradictions. Prioritize. Produce authoritative assessment. |

## Playwright Guidance (Phase 1, Pass 1 only)

Capture 5-8 screenshots of key UI states. Save to `{reports-dir}/screenshots/`.

Target screens should cover the primary user workflows:
1. Home / dashboard / entry point
2. List views (main entities)
3. Detail views (entity with full context)
4. Configuration / settings screens
5. Input / creation flows
6. Output / results views
7. Comparison / analysis views
8. Error / empty states

Reference screenshots by filename in assessment reports. Keep screenshots targeted —
each one should capture a specific UI state relevant to assessment.

## Phase 2: Comparative Lens

Phase 2 uses the same dimensions and report templates, but evaluates through the lens of
ecosystem comparison. For each dimension, additionally assess:

- How does the system compare to best-in-class in the ecosystem?
- What capabilities do ecosystem tools offer that we lack?
- What capabilities do we have that the ecosystem lacks?
- Which ecosystem ideas are most relevant to our stated purpose?
- What is the adoption feasibility (implementation cost vs. benefit)?

Ecosystem research reports are provided as input to Phase 2 tasks.
