---
slug: pin-and-control-plugin-versions
title: Pin versions and make updates deliberate (nvim plugins + dev-env tools)
priority: P2
status: pending
created: 2026-05-28
updated: 2026-05-28
depends-on: []
tags: [maintenance, reliability, nvim]
---

# Pin versions and make updates deliberate (nvim plugins + dev-env tools)

## Context
On 2026-05-28, installing one new nvim plugin (glow.nvim) was done via `:Lazy! sync`,
which doesn't just install missing plugins — it **updates and re-locks every plugin**.
That silently bumped ~38 plugins (blink.cmp, LazyVim core, treesitter, snacks, …) and
broke command-line mode (error on every `:`, surfaced through noice). Recovery was only
possible because each plugin is its own git repo with a reflog; the pre-update commits
were restored and `lazy-lock.json` rewritten to match.

The root issue: updates are uncontrolled. `lazy-lock.json` is the pin mechanism but it
isn't treated as a tracked, reviewed artifact, and there's no convention separating
"install new" from "update everything". The same lack of discipline applies to dev-env's
tool installs (`install-scripts/*.sh`), most of which pull latest from package managers.

## Goal
Make version state explicit and updates intentional, so a routine install can never
cascade into an unintended fleet-wide update again.

## Acceptance Criteria
- [ ] Decide where `lazy-lock.json` lives as a tracked artifact (lazy-llm repo and/or
      dev-env dotfiles) so plugin versions are version-controlled and reviewable
- [ ] Document the safe install workflow: use `:Lazy install` (or restart + lazy
      auto-install) for new plugins; never `:Lazy sync`/`update` as a side effect of adding one
- [ ] Define a deliberate update cadence/process: run updates intentionally, review the
      `lazy-lock.json` diff, smoke-test (esp. cmdline/noice/blink.cmp), commit as its own change
- [ ] Establish a rollback recipe (reflog-based restore + lock rewrite) as documented procedure
- [ ] Survey dev-env `install-scripts/*.sh` and decide a version-pinning policy for tools
      where stability matters (vs. tools fine to track latest)
- [ ] Capture the policy in the appropriate doc (CLAUDE.md / SETUP.md / lazy-llm README)

## Notes
- Incident backup of the broken lock: `~/.config/nvim/lazy-lock.json.broken-20260528`
- This Arch box runs Omarchy's LazyVim; lazy-llm links plugin specs in as stow packages
  (`nvim-*-plugin/`), separate from the `dotfiles/nvim` stow package.
