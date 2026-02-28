# TypeScript Review Guide

## Metadata
- **Type:** language
- **Extensions:** .ts, .tsx, .js, .jsx, .mjs, .cjs
- **Updated:** 2026-02-21

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

- **Unchecked type assertions at trust boundaries** — `as T` on external data (API responses, user input, file reads) bypasses validation entirely. Use runtime validation (Zod, etc.) at system boundaries.
  ```typescript
  // Bad — trusts the network blindly
  const data = await res.json() as UserProfile

  // Good
  const data = UserProfileSchema.parse(await res.json())
  ```

### Correctness

- **Non-null assertion `!` overuse** — `value!` tells the compiler "trust me, this isn't null" but provides no runtime guarantee. Prefer narrowing, fallbacks, or explicit error handling.
  ```typescript
  // Bad — crashes at runtime if null
  const name = user!.name
  const el = document.getElementById('root')!

  // Good
  const el = document.getElementById('root')
  if (!el) throw new Error('Missing root element')
  ```

- **Type assertions masking real mismatches** — `as T` silences the compiler but doesn't transform data. If the shapes don't actually match, you get runtime errors far from the assertion site.
  ```typescript
  // Bad — silences a real mismatch
  const config = rawData as AppConfig

  // Good — narrow or validate
  function isAppConfig(x: unknown): x is AppConfig {
    return typeof x === 'object' && x !== null && 'port' in x
  }
  ```

- **Truthy checks that exclude valid falsy values** — `if (value)` excludes `0`, `""`, `false`, and `NaN`. When these are valid domain values, check explicitly.
  ```typescript
  // Bad — filters out 0 and ""
  if (count) { process(count) }
  if (name) { greet(name) }

  // Good
  if (count !== undefined) { process(count) }
  if (name !== null && name !== undefined) { greet(name) }
  ```

- **Loose equality (`==`)** — type coercion causes surprises (`0 == ""`, `null == undefined`, `"" == false`). Always use `===` and `!==`.

- **Missing `await`** — an async function call without `await` runs concurrently and its errors are silently lost.
  ```typescript
  // Bad — error silently lost
  saveToDatabase(data)

  // Good
  await saveToDatabase(data)
  ```

- **Floating promises** — a promise created but never awaited, returned, or caught. Common in callbacks, event handlers, and `forEach`.
  ```typescript
  // Bad — promise floats, error lost
  items.forEach(async item => {
    await processItem(item)
  })

  // Good
  await Promise.all(items.map(item => processItem(item)))
  ```

- **`async void` functions** — errors thrown inside `async void` can't be caught by the caller. Only use for event handlers where the framework expects `void`; otherwise always return `Promise`.
  ```typescript
  // Bad — uncatchable
  const cleanup = async (): Promise<void> => { /* ... */ }
  setTimeout(async () => { await cleanup() }, 1000) // error lost

  // Good
  setTimeout(() => { cleanup().catch(logger.error) }, 1000)
  ```

- **Sequential await where parallel is possible** — awaiting independent operations serially wastes time.
  ```typescript
  // Bad — sequential, ~2x slower
  const users = await fetchUsers()
  const posts = await fetchPosts()

  // Good — parallel
  const [users, posts] = await Promise.all([fetchUsers(), fetchPosts()])
  ```

- **Non-exhaustive switch on union types** — switch over string unions or enums without a `default: never` check silently falls through on new values.
  ```typescript
  // Bad
  switch (status) {
    case 'active': ...
    case 'inactive': ...
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

- **Array/object mutation in loops** — modifying an array while iterating (splice, push, shift) causes skipped or double-processed elements. Build a new array instead.

- **Optional chaining with side effects** — `obj?.method()` silently returns `undefined` when `obj` is null. If the call is required for correctness, don't use optional chaining — check explicitly and handle the missing case.

- **Off-by-one in slice/substring** — `slice(0, length)` is exclusive end. `substring` swaps args if start > end (surprising). Verify boundary conditions.

- **`typeof null === 'object'`** — check for null explicitly before typeof checks.

- **Promise.all error handling** — one rejection rejects all. Use `Promise.allSettled` when partial results are acceptable.

- **Floating-point comparison** — don't use `===` for float equality. Use epsilon comparison or integer math (cents, not dollars).

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

- **Creating objects/closures in hot loops** — allocating closures, objects, or arrays inside tight loops puts GC pressure on hot paths. Hoist allocations out of the loop when the shape is static.

### Error Handling

- **Empty catch blocks** — swallowed exceptions hide bugs. At minimum, log the error. Better: rethrow or handle explicitly. If intentionally swallowing (e.g., fire-and-forget cleanup), add a comment explaining why.
  Enforced by: `noEmptyBlockStatements` (Biome)
  ```typescript
  // Bad
  try { riskyOp() } catch (e) {}
  cleanup().catch(() => {})

  // Good
  try { riskyOp() } catch (e) {
    logger.error('riskyOp failed', { error: e })
    throw e
  }
  cleanup().catch(() => { /* best-effort cleanup, failure is non-critical */ })
  ```

- **Error messages without context** — `throw new Error('Failed')` tells you nothing. `new Error()` without any message is even worse. Include what failed and relevant identifiers.
  Enforced by: `useErrorMessage` (Biome)
  ```typescript
  // Bad
  throw new Error()
  throw new Error('Not found')

  // Good
  throw new Error(`User ${userId} not found in project ${projectId}`)
  ```

- **Throw only Error objects** — throwing strings, numbers, or plain objects loses stack traces and breaks `instanceof` checks in catch blocks.
  Enforced by: `useThrowOnlyError` (Biome)
  ```typescript
  // Bad
  throw 'something went wrong'
  throw { code: 404 }

  // Good
  throw new Error('something went wrong')
  throw new HttpError(404, 'Not found')
  ```

- **Preserve error cause when wrapping** — when catching and re-throwing with a new message, use the `cause` option to preserve the original stack trace. Without it, the original error's location is lost.
  No linter rule — requires manual discipline.
  ```typescript
  // Bad — original stack trace lost
  catch (e) {
    throw new Error('Task processing failed')
  }

  // Good — full chain preserved
  catch (e) {
    throw new Error(`Task ${taskId} processing failed`, { cause: e })
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

- **`as any` type assertions** — bypasses TypeScript's type system entirely. Use proper typing, generics, or type guards.
  ```typescript
  // Bad
  const data = response as any

  // Good
  const data = response as ApiResponse
  // or
  function isApiResponse(x: unknown): x is ApiResponse { ... }
  ```

- **`@ts-ignore` / `@ts-expect-error` without justification** — suppresses compiler errors. If genuinely needed (e.g., library type bugs), add a comment explaining why and link the upstream issue.

- **Overly broad types** — `Record<string, any>`, `object`, `Function`, `{}`. Use specific interfaces. `unknown` is better than `any` when the shape is genuinely unknown.

- **Overusing `Partial<T>`** — makes every field optional when only some should be. Define the actual optionality.
  ```typescript
  // Bad — everything optional, caller can omit required fields
  function updateUser(id: string, data: Partial<User>) { ... }

  // Good — explicit about what's optional
  type UserUpdate = Pick<User, 'name'> & Partial<Pick<User, 'email' | 'avatar'>>
  ```

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

- **`undefined` vs `null` inconsistency** — pick one convention for "no value" within a codebase. TypeScript's optional properties use `undefined`; DOM and JSON use `null`. Don't mix arbitrarily within application code.

### Resource Management

- **Unclosed file handles and connections** — `fs.open`, database connections, HTTP connections must be closed in finally blocks or use disposable patterns.
  ```typescript
  // Bad — leaked on error
  const conn = await pool.getConnection()
  const result = await conn.query(sql)
  conn.release()

  // Good
  const conn = await pool.getConnection()
  try {
    return await conn.query(sql)
  } finally {
    conn.release()
  }
  ```

- **Event listener leaks** — adding listeners without corresponding removal. In long-lived processes, this is a memory leak.
  ```typescript
  // Bad — never removed
  emitter.on('data', handler)

  // Good — track and remove
  emitter.on('data', handler)
  // later:
  emitter.off('data', handler)
  ```

- **Missing AbortController for cancellable operations** — long-running fetches, streams, or timers that should be cancellable but aren't.

- **Timers without cleanup** — `setInterval` and `setTimeout` in contexts where the owner can be destroyed (components, connections). Always store the ID and clear on teardown.

### Comment Hygiene

- **Stale comments** — comment describes behavior that no longer matches the code. Delete or update.

- **Resolved TODO/FIXME/HACK** — the issue has been addressed but the comment remains. Delete it.

- **Obvious comments** — `// increment counter` before `counter++`. Remove noise.

- **Commented-out code** — dead code in comments. Delete it; git has history.

- **Misleading comments** — comment says one thing, code does another. This is worse than no comment.

## Anti-Patterns

| Pattern | Severity | Fix | Enforced by |
|---------|----------|-----|-------------|
| `eval()` / `new Function()` | Critical | Use structured dispatch (maps, switch) | `noGlobalEval` |
| String-concatenated SQL | Critical | Parameterized queries | — |
| Hardcoded secrets | Critical | Environment variables | — |
| `as T` at trust boundaries without validation | Critical | Runtime validation (Zod, etc.) | — |
| Empty catch block | Warning | Log and rethrow, or comment if intentional | `noEmptyBlockStatements` |
| `new Error()` without message | Warning | Add descriptive message with context | `useErrorMessage` |
| `throw "string"` (non-Error) | Warning | Throw `Error` or subclass | `useThrowOnlyError` |
| Re-throw without `{ cause }` | Warning | `new Error(msg, { cause: e })` | — |
| `as any` | Warning | Proper types, generics, type guards | `noExplicitAny` |
| `@ts-ignore` without justification | Warning | Fix the type error or document why | — |
| Non-null assertion `!` overuse | Warning | Null checks, narrowing, fallbacks | `noNonNullAssertion` |
| N+1 queries in loop | Warning | Batch query | — |
| Missing `await` / floating promises | Warning | Add `await`, return, or `.catch()` | — |
| `async void` (outside event handlers) | Warning | Return `Promise`, add `.catch()` at call site | — |
| `[...acc, item]` in reduce | Warning | `acc.push(item)` or `.map()` | — |
| Truthy check on number/string | Warning | Explicit null/undefined check | — |
| Magic numbers | Warning | Named constants | — |
| Functions >50 lines | Warning | Extract helpers | `noExcessiveCognitiveComplexity` |
| Nesting >3 levels | Warning | Guard clauses, early returns | `noExcessiveCognitiveComplexity` |
| Unclosed resources in error paths | Warning | try/finally or disposable pattern | — |
| Sequential await (independent ops) | Suggestion | `Promise.all` | — |
| `Partial<T>` when specific optionality needed | Suggestion | `Pick` + `Partial<Pick<...>>` | — |
| Dead code / commented-out code | Suggestion | Delete (git has history) | `noUnusedVariables` |
| Obvious comments | Nit | Remove | — |
