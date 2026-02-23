# Coding Principles

General coding principles applicable across all languages and frameworks. These encode
project-level preferences about error handling philosophy, defensive coding, deprecation
posture, and code lifecycle management.

Read `standards.yaml` in the project's `.claude/` directory for the `lifecycle` field.
Adjust behavior according to the lifecycle stage.

## Lifecycle Stages

| Stage | Posture |
|-------|---------|
| `development` | Move fast. Delete aggressively. No backwards compatibility. Hard failures everywhere. If something breaks, fix it immediately — don't add a fallback. |
| `staging` | Stabilizing for production. Keep deprecation markers for one release cycle. Backwards compatibility only for external consumers. Internal boundaries still fail hard. |
| `production` | Careful changes. Deprecate before removing. Backwards compatibility for published APIs. Migration paths for data format changes. Internal boundaries can still fail hard. |

## Error Philosophy

### Fail hard at internal boundaries

When code calls other code we fully control (same repo, same team, same deployment), **do not
add defensive fallbacks**. If the internal contract is violated, throw — don't silently degrade.

```typescript
// BAD — defensive fallback hiding a real bug
const name = user?.name || 'Unknown'
const config = getConfig() ?? DEFAULT_CONFIG

// GOOD — fail hard, surface the problem
if (!user) throw new Error(`Expected user but got ${user}`)
const config = getConfig()  // if this returns null, that's a bug — let it crash
```

**Why:** Fallbacks at internal boundaries mask bugs. The caller *should* provide valid data.
If it doesn't, we need to know immediately — not discover it later as a subtle data corruption.

**When fallbacks ARE appropriate:**
- External API responses (we don't control the shape)
- User input (can be anything)
- Third-party library return values (may change across versions)
- Environment variables / config files (may be missing)
- Database query results (data may have been deleted concurrently)
- Cross-service boundaries in distributed systems

### Don't catch errors you can't handle

If a function can't meaningfully recover from an error, don't catch it. Let it propagate
to a level that can (usually the top-level error handler).

```typescript
// BAD — catching just to log and return a default
try {
  const result = await processTask(task)
  return result
} catch (e) {
  console.error('Failed to process task', e)
  return null  // caller now has to handle null — why?
}

// GOOD — let it propagate, handle at the boundary
const result = await processTask(task)
return result
// The route handler / event handler at the top catches and responds appropriately
```

### Error responses should be honest

Return the actual error, not a generic fallback. 500 means "server broke," not "I don't
know what happened so here's a 500."

## Defensive Coding

### Overly defensive code is a code smell

When you find yourself adding null checks, try/catch, fallback values, or optional chaining
for code paths that are *always* called with valid data from within the same codebase —
that's a signal that either:

1. The types are wrong (fix the types to be non-nullable)
2. The caller contract is unclear (document it, or make it type-enforced)
3. You're not trusting code you control (stop — if it's broken, fix it)

### Guard at the boundary, trust inside

Validate data **once** at the system boundary (API handler, event consumer, file parser).
After validation, trust the types throughout the internal call chain. Don't re-validate
at every function call.

```typescript
// BAD — re-validating at every level
function processOrder(order: Order) {
  if (!order.id) throw new Error('Missing order ID')  // already validated upstream
  if (!order.items?.length) throw new Error('No items')  // types guarantee this
  // ...
}

// GOOD — trust the validated type
function processOrder(order: Order) {
  // Order type guarantees id exists and items is non-empty
  // If those invariants are violated, we WANT a crash — it means validation is broken
  // ...
}
```

## Deprecation and Dead Code

### Development lifecycle: aggressive removal

In `development` lifecycle:
- **No deprecation markers.** If code is no longer needed, delete it. Don't comment it out,
  don't add `@deprecated`, don't add `// TODO: remove`. Just delete it.
- **No backwards compatibility.** When changing a data structure, update all consumers
  directly. No migration paths, no dual-format support, no version negotiation.
- **Delete unused code immediately.** Don't leave it "in case we need it later." Git has
  history. If we need it, we can find it.
- **No compatibility shims.** If an interface changes, update all call sites. If a function
  is renamed, update all callers. No re-exports, no aliases, no wrappers.

### What to look for in reviews

| Pattern | Action |
|---------|--------|
| `@deprecated` marker in development-stage project | Remove the deprecated code entirely |
| `// TODO: remove` or `// legacy` comment | Remove the code now |
| Fallback to old format (`if (newFormat) ... else /* old format */`) | Remove old format branch |
| Re-export or alias for renamed symbol | Remove alias, update callers |
| Feature flag for removed feature | Remove the flag and dead branch |
| Commented-out code | Delete it |
| Import that's only used in a commented-out block | Delete both |
| Wrapper function that just forwards to another function | Inline it, delete wrapper |
| Config option that nothing reads | Delete it |
| Error handling for conditions that can't occur | Delete it |

## Code Generation Guidelines

When generating code, prefer:

1. **Explicit over implicit.** Don't hide behavior behind defaults. If a value is required,
   make the type non-optional and let the caller provide it.

2. **Crash over degrade.** At internal boundaries, an unhandled error that crashes is better
   than a silent fallback that produces wrong results.

3. **Delete over deprecate.** In development lifecycle, remove code paths immediately rather
   than marking them for future removal.

4. **Simple over defensive.** Don't add error handling for impossible states. If the types say
   it's a `string`, don't check `if (typeof x === 'string')` — that's the type system's job.

5. **Fix over work around.** If you encounter a bug or design flaw while implementing a feature,
   fix the underlying issue rather than adding a workaround in your code.
