---
slug: lazy-llm-fix-install-script
title: "Fix install.sh to include nvim-note-plugin"
priority: P0
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, bugfix, phase-1]
---

# Fix install.sh to include nvim-note-plugin

## Context
The `STOW_PACKAGES` array in `install.sh` (line 44) does not include `nvim-note-plugin`. This means the NOTE marker feature is never installed when running `./install.sh`. Users must manually stow it.

## Key Files
- `external/lazy-llm/install.sh` — line 44, `STOW_PACKAGES` array

## Acceptance Criteria
- [x] `nvim-note-plugin` is included in the `STOW_PACKAGES` array
- [x] Running `./install.sh` successfully stows the note plugin

## Work Report

**Date:** 2026-03-06

### What was done
- Added `nvim-note-plugin` to the `STOW_PACKAGES` array in `install.sh`

### How it was done
- Single-line edit appending the missing package name to the array

### Decisions made
- Appended at the end of the array to maintain the existing ordering pattern (bins first, then nvim plugins)

### Files changed
- `external/lazy-llm/install.sh` — Added `nvim-note-plugin` to STOW_PACKAGES

### Follow-up
- None
