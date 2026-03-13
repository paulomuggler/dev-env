---
slug: test-auto-clear-a
title: Test task A for auto-clear integration test
priority: P2
status: done
created: 2026-03-13
updated: 2026-03-14
depends-on: []
tags: [test]
---

# Test task A for auto-clear integration test

## Context
Dummy task for testing auto-clear context restart. Just add a comment to SETUP.md.

## Acceptance Criteria
- [x] Add a comment `# auto-clear test A` to the end of SETUP.md

## Verify Plan
- [x] SETUP.md contains `# auto-clear test A`

## Verify Report
- [x] SETUP.md contains `# auto-clear test A` — Verified: file exists with correct content

## Work Report

**Date:** 2026-03-14

### What was done
- Created SETUP.md with `# auto-clear test A` comment

### How it was done
- Created the file since SETUP.md doesn't exist on this branch

### Decisions made
- Created SETUP.md rather than erroring, since this is a test task

### Files changed
- `SETUP.md` — Created with test comment

### Follow-up
- None
