# TypeScript Review Guide

## Metadata
- **Type:** language
- **Extensions:** .ts, .tsx, .js, .jsx, .mjs, .cjs
- **Updated:** 2026-02-20

## Categories

### Security

- **No `eval()` or `Function()` constructor** — dynamic code execution enables injection. Use structured alternatives (maps, switch, parsed ASTs).
  ```typescript
  // Bad
  eval(userInput)
  new Function('return ' + expr)()

  // Good
  const handlers: Record<string, () => void> = { action1: doAction1 }
  handlers[validated]?.()
  ```

- **No string-concatenated SQL/queries** — use parameterized queries or query builders.
  ```typescript
  // Bad
  db.query(`SELECT * FROM users WHERE id = ${id}`)

  // Good
  db.query('SELECT * FROM users WHERE id = ?', [id])
  ```

- **No `innerHTML` or `dangerouslySetInnerHTML` with user data** — use textContent or sanitize first.
  ```typescript
  // Bad
  element.innerHTML = userInput
  <div dangerouslySetInnerHTML={{ __html: userData }} />

  // Good
  element.textContent = userInput
  <div>{userData}</div>  // React auto-escapes
  ```

- **Secrets in source code** — no hardcoded API keys, tokens, passwords, connection strings. Use environment variables.
  ```typescript
  // Bad
  const API_KEY = 'sk-1234567890abcdef'

  // Good
  const API_KEY = process.env.API_KEY
  ```

- **Regex denial of service (ReDoS)** — avoid catastrophic backtracking patterns. Watch for nested quantifiers: `(a+)+`, `(a|a)+`, `(a+)*`.

- **Path traversal** — validate file paths from user input. Reject `..` segments, resolve and check against allowed base directory.
  ```typescript
  // Bad
  const file = fs.readFileSync(`uploads/${userPath}`)

  // Good
  const resolved = path.resolve(UPLOAD_DIR, userPath)
  if (!resolved.startsWith(UPLOAD_DIR)) throw new Error('Path traversal')
  ```

- **Prototype pollution** — don't merge arbitrary user objects into existing objects without filtering `__proto__`, `constructor`, `prototype` keys.

### Correctness

- **Floating-point comparison** — don't use `===` for float equality. Use epsilon comparison or integer math (cents, not dollars).
  ```typescript
  // Bad
  if (0.1 + 0.2 === 0.3) { ... }

  // Good
  if (Math.abs(a - b) < Number.EPSILON) { ... }
  ```

- **Array/object mutation in loops** — modifying an array while iterating over it (splice, push, shift) causes skipped or double-processed elements. Build a new array instead.

- **Missing `await`** — an async function call without `await` runs concurrently and its errors are silently lost. Watch for fire-and-forget patterns.
  ```typescript
  // Bad — error silently lost
  saveToDatabase(data)

  // Good
  await saveToDatabase(data)
  ```

- **Optional chaining with side effects** — `obj?.method()` silently returns `undefined` when `obj` is null. If the call is required for correctness, don't use optional chaining — check explicitly and handle the missing case.

- **Non-exhaustive switch on union types** — switch over string unions or enums without a `default: never` check will silently fall through on new values.
  ```typescript
  // Bad
  switch (status) {
    case 'active': ...
    case 'inactive': ...
    // New status values fall through silently
  }

  // Good
  switch (status) {
    case 'active': ...
    case 'inactive': ...
    default: {
      const _exhaustive: never = status
      throw new Error(`Unhandled status: ${status}`)
    }
  }
  ```

- **Off-by-one in slice/substring** — `slice(0, length)` is exclusive end. `substring` swaps args if start > end (surprising). Verify boundary conditions.

- **`typeof null === 'object'`** — JavaScript's oldest footgun. Check for null explicitly before typeof checks.

- **Promise.all error handling** — one rejection rejects all. Use `Promise.allSettled` when partial results are acceptable.

### Performance

- **N+1 queries in loops** — fetching one record per iteration. Batch into a single query with `IN (...)` or equivalent.
  ```typescript
  // Bad
  for (const id of ids) {
    const user = await db.query('SELECT * FROM users WHERE id = ?', [id])
  }

  // Good
  const users = await db.query('SELECT * FROM users WHERE id IN (?)', [ids])
  ```

- **Unnecessary re-renders (React)** — passing new object/array/function references as props on every render. Use `useMemo`, `useCallback`, or extract constants.
  ```typescript
  // Bad — new object every render
  <Component style={{ color: 'red' }} />

  // Good
  const style = useMemo(() => ({ color: 'red' }), [])
  <Component style={style} />
  ```

- **Blocking the event loop** — synchronous file I/O (`fs.readFileSync`), CPU-heavy computation, or large JSON parse on the main thread. Use async alternatives or workers.

- **Unbounded array growth** — pushing to an array in a loop/event handler without size limits. Will eventually OOM. Add caps or use ring buffers.

- **String concatenation in hot paths** — repeated `+=` on strings creates O(n^2) intermediate strings. Use array join or template literals for batch construction.

- **Unnecessary spread in loops** — `[...acc, item]` in a reduce creates a new array on every iteration (O(n^2)). Push to a mutable array instead.
  ```typescript
  // Bad — O(n^2)
  items.reduce((acc, item) => [...acc, transform(item)], [])

  // Good — O(n)
  items.map(transform)
  // or if reduce is needed:
  items.reduce((acc, item) => { acc.push(transform(item)); return acc }, [])
  ```

### Error Handling

- **Empty catch blocks** — swallowed exceptions hide bugs. At minimum, log the error. Better: rethrow or handle explicitly.
  ```typescript
  // Bad
  try { riskyOp() } catch (e) {}

  // Good
  try { riskyOp() } catch (e) {
    logger.error('riskyOp failed', { error: e })
    throw e
  }
  ```

- **Catch-all without type narrowing** — `catch (e)` gives `unknown`. Narrow before accessing properties.
  ```typescript
  // Bad
  catch (e) { console.log(e.message) }

  // Good
  catch (e) {
    if (e instanceof SpecificError) { ... }
    else { throw e }
  }
  ```

- **Unhandled promise rejections** — async functions in event handlers, callbacks, or `setTimeout` that aren't caught. Add `.catch()` or wrap in try/catch.

- **Error-prone `JSON.parse` without try/catch** — parse of external data should always be wrapped.

- **Fail-open patterns** — catch block that returns a default value when the error should propagate. Especially dangerous in auth/validation code.
  ```typescript
  // Bad — fail-open auth
  function isAuthorized(token: string): boolean {
    try { return verify(token).role === 'admin' }
    catch { return true }  // Fail-open!
  }
  ```

### Code Quality

- **Magic numbers and strings** — unexplained literals in logic. Extract to named constants.
  ```typescript
  // Bad
  if (retries > 3) { ... }
  setTimeout(fn, 86400000)

  // Good
  const MAX_RETRIES = 3
  const ONE_DAY_MS = 24 * 60 * 60 * 1000
  ```

- **Functions over 50 lines** — probably doing too much. Extract logical sections into named helpers.

- **Deep nesting (>3 levels)** — use early returns, guard clauses, or extract functions.
  ```typescript
  // Bad
  if (a) { if (b) { if (c) { doThing() } } }

  // Good
  if (!a) return
  if (!b) return
  if (!c) return
  doThing()
  ```

- **Dead code** — unreachable branches, unused imports, commented-out blocks. Delete it; git has history.

- **Duplicated logic** — same code block appearing 3+ times. Extract to a shared function.

- **`as any` type assertions** — bypasses TypeScript's type system. Use proper typing, generics, or type guards.
  ```typescript
  // Bad
  const data = response as any

  // Good
  const data = response as ApiResponse
  // or
  function isApiResponse(x: unknown): x is ApiResponse { ... }
  ```

- **Overly broad types** — `Record<string, any>`, `object`, `Function`. Use specific interfaces.

### Style

- **Inconsistent naming** — camelCase for variables/functions, PascalCase for types/classes/components, UPPER_SNAKE for constants. No mixed conventions within a file.

- **Inconsistent import style** — pick one pattern (named vs default, path aliases vs relative) and stick with it within a file.

- **Boolean naming** — use `is`, `has`, `should`, `can` prefixes for booleans. Avoid negated names (`isNotValid` — use `isValid` and negate at call site).

- **Ternary abuse** — nested ternaries are unreadable. Use if/else or early returns for complex conditions.
  ```typescript
  // Bad
  const result = a ? b ? c : d : e ? f : g

  // Good
  if (a && b) return c
  if (a) return d
  if (e) return f
  return g
  ```

- **Barrel file pollution** — `index.ts` re-exporting everything. Only re-export the public API. Barrel files that re-export internal implementation details hurt tree-shaking and create circular dependency risks.

### Comment Hygiene

- **Stale comments** — comment describes behavior that no longer matches the code. Delete or update.

- **Resolved TODO/FIXME/HACK** — the issue has been addressed but the comment remains. Delete it.

- **Obvious comments** — `// increment counter` before `counter++`. Remove noise.

- **Commented-out code** — dead code in comments. Delete it; git has history.

- **Misleading comments** — comment says one thing, code does another. This is worse than no comment.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| `eval()` / `new Function()` | Critical | Use structured dispatch (maps, switch) |
| `innerHTML = userInput` | Critical | Use textContent or sanitize |
| String-concatenated SQL | Critical | Parameterized queries |
| Hardcoded secrets | Critical | Environment variables |
| Empty catch block | Warning | Log and rethrow or handle |
| `as any` | Warning | Proper types, generics, type guards |
| N+1 queries in loop | Warning | Batch query |
| Missing `await` on async call | Warning | Add `await` or handle the promise |
| `[...acc, item]` in reduce | Warning | `acc.push(item)` or `.map()` |
| Magic numbers | Warning | Named constants |
| Functions >50 lines | Warning | Extract helpers |
| Nesting >3 levels | Warning | Guard clauses, early returns |
| Dead code / commented-out code | Suggestion | Delete (git has history) |
| Obvious comments | Nit | Remove |
