---
slug: unrelated-task
title: Unrelated task — should NOT be picked by filter
priority: P1
status: pending
created: 2026-03-14
updated: 2026-03-14
depends-on: []
tags: [other]
---

# Unrelated task — should NOT be picked by filter

## Context
This task has a different tag and higher priority. If the filter works correctly, it should NOT be picked during a `--filter tags:filter-test` work loop, even though it's P1.

## Acceptance Criteria
- [ ] This should never run during the filter test
