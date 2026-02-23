# Coding Standards

Centralized coding and review standards for all projects. Managed via stow
from the dev-env repo, symlinked to `~/.claude/coding-standards/`.

## Structure

```
coding-standards/
├── languages/         # Language patterns, conventions, anti-patterns
│   ├── typescript.md  # Used during both code generation and review
│   ├── python.md
│   └── shell.md
├── frameworks/        # Framework-specific patterns and conventions
│   ├── hono.md
│   ├── react.md
│   └── ...
└── review/            # Review-only severity/category prescriptions
    ├── typescript.md   # "Flag pattern X as Warning/Correctness"
    └── hono.md
```

## Per-Project Manifest

Each project has `.claude/standards.yaml`:

```yaml
languages: [typescript]
frameworks: [hono, react, nats]
```

This scopes which standards are relevant. Agents read the manifest to know
which files to consult, but use their discretion on which to actually load
for a given task.

## Agent Behavior

- **Code generation:** Read applicable `languages/` and `frameworks/` files
  before writing code in those languages/frameworks.
- **Code review:** Read the above plus `review/` overlays for severity guidance.
- **Source tracking:** Record which files were consulted in work reports or
  the analysis task's `## Sources Consulted` section.
- **Creating new guides:** When introducing a new framework or language, agents
  should create the guide file here and update the project's `standards.yaml`.

## Adding Standards

1. Create `languages/{name}.md` or `frameworks/{name}.md`
2. Follow the existing format: Metadata header, then categories with patterns
3. For review overlays: create `review/{name}.md` with severity mappings
4. Commit in the dev-env repo — stow propagates automatically
