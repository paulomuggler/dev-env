# Enrichment pass for `/todo create`

Run this procedure inline (in the main create flow — not as a spawned subagent) for each task being created or substantively scope-changed. Output is a list of discovered references to attach to the task's `## Read first` section, after user confirmation.

This is best-effort. Any class of lookup (shell, web, memory) that fails should be skipped silently — never block task creation on a tool failure.

---

## A. Extract keywords

Tokenize the candidate task's title and body. Drop English stopwords and tokens shorter than 4 characters. Bucket the survivors into three classes — the same keyword may end up in multiple buckets:

- **identifiers** — `lowercase-hyphen`, `snake_case`, `camelCase`, `PascalCase` tokens of length ≥ 4. Used for memory grep, doc grep, commit grep.
- **packages** — `@scope/name` literal occurrences, and bare `kebab-case` tokens that look like npm package names (no spaces, no slashes, lowercase). Used for `pnpm view` + web search.
- **product names** — single capitalized tokens (`Mastra`, `Dolt`, `Kiln`, `Traefik`, `Tiptap`, `Hono`, `NATS`, etc.). Used for vendor docs web search.

Cap each class at 8 unique keywords (highest-frequency wins) so downstream grep/web volume stays bounded.

---

## B. Memory hits (Bash + Read)

Derive the project memory dir:

```bash
MEM_DIR="$HOME/.claude/projects/$(pwd | sed 's|/|-|g')/memory"
```

For each `*.md` file in `$MEM_DIR` (excluding `MEMORY.md`):

1. `rg -l -i -F '<keyword>' "$MEM_DIR" --glob '!MEMORY.md'` per identifier-class keyword.
2. For each hit, read the file's frontmatter `description:` line to use as the suggestion's context blurb.

Emit suggestions as:

```
~/.claude/projects/<encoded-cwd>/memory/<slug>.md — <description>
```

If the memory dir doesn't exist (new project), skip this class.

---

## C. Doc grep (Bash)

Grep project documentation:

```bash
rg -l -i --max-depth 2 -F '<keyword>' docs/ CLAUDE.md 2>/dev/null
```

Run once per identifier-class keyword. Collect unique absolute file paths.

For each hit, capture the first matching line (`rg -n -m 1 -i -F '<keyword>' <path>`) to use as the context blurb (truncate to ~80 chars).

Emit suggestions as:

```
<absolute-path> — <first matching line, truncated>
```

If `docs/` doesn't exist, fall back to `rg -l -i -F '<keyword>' --max-depth 1 .` for top-level markdown only.

---

## D. Package + vendor docs (Bash + WebSearch + WebFetch)

> This section implements the create-time half of the [External Information Discipline](./SKILL.md#external-information-discipline) rule — surfacing authoritative vendor docs as `## Read first` references before the task file is written, so the work-phase planner doesn't have to argue from absence or intuition. The rule itself is broader (it also covers execute-phase lookups); this is just the automated create-time piece.

For each package-class token:

1. `pnpm view <pkg> homepage 2>/dev/null` — if it returns a URL, that's the suggestion. Done.
2. If `pnpm view` fails or returns nothing, **only then** fall back to web:
   - `WebSearch` query: `<token> docs site`.
   - Pick the top vendor result (skip Stack Overflow, GitHub issue trackers — prefer `<vendor>.{ai,com,io,dev}/docs/...`).
   - `WebFetch` the URL to confirm it loads and contains the package/product name on the page.
   - Emit the URL as the suggestion.

For each product-name token:

1. Skip `pnpm view` (product names aren't npm packages).
2. `WebSearch '<ProductName> documentation'`.
3. Take the top vendor result; `WebFetch` to confirm.
4. Emit URL.

**Budget:** cap web lookups at **3 total per task** (across packages + products) to keep create-time latency tolerable. Skip the rest, log the skip in the summary so the user knows.

**Skip web calls entirely** if no package- or product-class tokens were extracted.

---

## E. Recent commits (Bash)

```bash
git log --oneline -n 30 --format='%h %s' 2>/dev/null
```

Grep the resulting output lines case-insensitively against the identifier-class keywords. Collect matching lines.

Emit suggestions as:

```
commit <short-hash> — <subject line>
```

Cap at 5 commit suggestions (newest first) so the list stays scannable.

If not in a git repo (`git log` fails), skip this class.

---

## F. Present to user (AskUserQuestion)

Build the option list in this priority order — this also defines tie-breaking when capping at 12:

1. memory hits (B)
2. doc grep matches (C)
3. recent commits (E)
4. package / vendor docs (D)

Cap the option list at **12 entries** per task. Overflow (anything past 12) goes into the question's preamble text as a `(N more suggestions truncated)` notice so the user knows there were more — they can manually add any of them after the task file is written.

Call `AskUserQuestion` with `multiSelect: true`. Each option's `label` is the path/URL/commit line (kept short — abbreviate long paths to `~/...` or basename if needed); each option's `description` is the matched context blurb (≤ 60 chars).

If **zero** references were discovered across all classes, **skip the prompt entirely** and report `(no enrichment suggestions found)` in the create summary instead. Do not ask an empty question.

---

## G. Write into task file

Selected items become bullets in the task file's `## Read first` section, preserved in the same priority order from step F. Format per the task template:

```markdown
## Read first
- `path/to/file` — why
- https://... — why
- commit `abc1234` — why
```

Commit hashes are recorded **only** in the `## Read first` bullet — do **not** populate the frontmatter `commits` field with them. That field is reserved for code commits authored by the executor during phase 2.

If the user rejected every option, omit the `## Read first` section entirely. Don't leave an empty heading.

---

## Failure modes (summary)

- `rg` / `pnpm` / `git log` failures → skip the affected class, continue.
- `WebSearch` / `WebFetch` failures → skip that lookup (do not retry), continue with the next token.
- `AskUserQuestion` timeout or user cancellation → treat as "user rejected all"; write the task file without a `## Read first` section.
- Empty memory dir / no `docs/` / not in a git repo → skip the affected class, continue.

The create flow must complete even if every enrichment class fails. A task with no `## Read first` section is acceptable; a task that never gets written is not.
