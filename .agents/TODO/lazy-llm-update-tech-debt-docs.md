---
slug: lazy-llm-update-tech-debt-docs
title: "Update TECH_DEBT.md and TODO.md to reflect current state"
priority: P3
status: pending
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, docs, phase-4]
---

# Update TECH_DEBT.md and TODO.md to reflect current state

## Context
TECH_DEBT.md still lists pane ID migration (Issue #1) with all implementation items unchecked, but the code already uses pane IDs. Several completed items in TODO.md are marked done but the document could better reflect the current state and new priorities from this review.

## Key Files
- `external/lazy-llm/docs/TECH_DEBT.md`
- `external/lazy-llm/docs/TODO.md`

## Acceptance Criteria
- [ ] TECH_DEBT.md Issue #1 (pane reference resilience) marked as done with implementation notes
- [ ] New issues from this review added to TECH_DEBT.md
- [ ] TODO.md P1 items updated to reflect current priorities
- [ ] Completed items in TODO.md cross-referenced with actual status
