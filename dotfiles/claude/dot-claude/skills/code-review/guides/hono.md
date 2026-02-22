# Hono Review Guide

## Metadata
- **Type:** framework
- **Extensions:** .ts
- **Updated:** 2026-02-21

## Categories

### Security

- **Validate all request input at the boundary** — path params, query strings, and body payloads are untrusted. Use Zod or Hono's built-in validator middleware before accessing values.
  ```typescript
  // Bad — trusts params directly
  app.get('/users/:id', (c) => {
    const id = c.req.param('id')
    return c.json(await getUser(id))  // id could be anything
  })

  // Good — validate at the handler boundary
  app.get('/users/:id', zValidator('param', z.object({ id: z.string().uuid() })), (c) => {
    const { id } = c.req.valid('param')
    return c.json(await getUser(id))
  })
  ```

- **Don't leak internal errors to clients** — stack traces, SQL errors, and file paths in responses are information disclosure. Use a global error handler that maps to safe responses.
  ```typescript
  // Bad — leaks internals
  app.onError((err, c) => {
    return c.json({ error: err.message, stack: err.stack }, 500)
  })

  // Good — safe error response
  app.onError((err, c) => {
    logger.error('Unhandled error', { error: err, path: c.req.path })
    return c.json({ error: 'Internal server error' }, 500)
  })
  ```

- **Auth middleware must run before route handlers** — middleware execution order is registration order. If auth middleware is registered after a route, that route is unprotected.

- **CORS configuration** — don't use `origin: '*'` in production. Explicitly list allowed origins. Be especially careful with `credentials: true` — it's incompatible with wildcard origins.

- **Don't expose sensitive headers** — avoid passing internal headers (auth tokens, session IDs, internal service identifiers) through to the client in responses.

### Correctness

- **Always return a `Response`** — every route handler must return a response. Falling through without returning causes the client to hang.
  ```typescript
  // Bad — missing return in branch
  app.get('/item/:id', (c) => {
    const item = getItem(c.req.param('id'))
    if (!item) {
      c.status(404)  // missing return!
    }
    return c.json(item)  // returns null with 200
  })

  // Good
  app.get('/item/:id', (c) => {
    const item = getItem(c.req.param('id'))
    if (!item) return c.json({ error: 'Not found' }, 404)
    return c.json(item)
  })
  ```

- **`c.req.json()` and `c.req.text()` consume the body** — calling them twice throws. Read once and store the result.

- **Middleware `next()` must be awaited** — `await next()` ensures downstream handlers complete before upstream middleware runs post-processing (e.g., timing, logging). Without `await`, the middleware returns before the handler finishes.
  ```typescript
  // Bad — timing is wrong
  app.use(async (c, next) => {
    const start = Date.now()
    next()  // not awaited!
    console.log(`${Date.now() - start}ms`)  // always ~0ms
  })

  // Good
  app.use(async (c, next) => {
    const start = Date.now()
    await next()
    console.log(`${Date.now() - start}ms`)
  })
  ```

- **Route registration order matters** — Hono matches routes in registration order. More specific routes must come before catch-alls.
  ```typescript
  // Bad — catch-all shadows specific route
  app.get('/users/*', handleWildcard)
  app.get('/users/me', handleMe)  // never reached

  // Good
  app.get('/users/me', handleMe)
  app.get('/users/*', handleWildcard)
  ```

- **Status code misuse** — returning 200 for errors, 404 for auth failures, or 500 for client errors. Use correct HTTP semantics: 400 for bad input, 401 for unauthenticated, 403 for unauthorized, 404 for not found, 409 for conflicts, 422 for validation failures.

### Performance

- **Don't read full request body for streaming endpoints** — use `c.req.raw.body` (ReadableStream) for large uploads instead of `c.req.json()` which buffers everything.

- **Middleware that runs on every request should be lightweight** — heavy computation (DB queries, crypto, file I/O) in global middleware blocks all routes. Move expensive checks to route-specific middleware.

- **Response streaming** — for large responses, use `c.stream()` or `c.streamText()` instead of building the entire response in memory.

- **JSON serialization overhead** — avoid serializing large objects unnecessarily. If the response is already a JSON string (from cache, another service), use `c.text(jsonString, 200, { 'Content-Type': 'application/json' })` instead of parsing and re-serializing.

### Error Handling

- **Global error handler is required** — without `app.onError()`, unhandled exceptions crash the process. Always register one.

- **Async errors in handlers** — Hono catches errors from async handlers automatically, but only if the handler returns a promise. An unhandled `.catch()` inside the handler won't be caught by `onError`.
  ```typescript
  // Bad — error escapes onError
  app.get('/data', (c) => {
    fetchData().then(data => c.json(data))  // no return, no catch
  })

  // Good
  app.get('/data', async (c) => {
    const data = await fetchData()
    return c.json(data)
  })
  ```

- **404 handler** — register `app.notFound()` to return a consistent response format for unmatched routes instead of Hono's default.

- **Validation errors should return 400, not 500** — if using Zod validation, ensure parse errors are caught and mapped to 400 responses with field-level details, not propagated as unhandled exceptions.

### Code Quality

- **Fat handlers** — route handlers that contain business logic, data access, and response formatting. Extract business logic to service functions; handlers should only parse input, call services, and format output.
  ```typescript
  // Bad — everything in the handler
  app.post('/tasks', async (c) => {
    const body = await c.req.json()
    // 50 lines of validation, DB queries, event publishing...
    return c.json(result)
  })

  // Good — thin handler
  app.post('/tasks', zValidator('json', CreateTaskSchema), async (c) => {
    const input = c.req.valid('json')
    const task = await taskService.create(input)
    return c.json(task, 201)
  })
  ```

- **Inconsistent response shapes** — some endpoints return `{ data: ... }`, others return raw objects, others return `{ error: ... }`. Standardize the envelope.

- **Hardcoded status codes as numbers** — prefer descriptive patterns. At minimum, be consistent (always use numbers or always use named constants).

### Style

- **Route grouping** — group related routes with `app.route('/prefix', subApp)` or at least keep them adjacent in the file. Don't scatter `/users` routes across the file.

- **Middleware composition** — chain related middleware together. Don't register 10 separate `app.use()` calls when they could be composed.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| Unvalidated request input in handler | Critical | Zod validator middleware at boundary |
| Internal errors/stack traces in responses | Critical | Global error handler with safe messages |
| Auth middleware after route registration | Critical | Register auth middleware first |
| Missing `await next()` in middleware | Warning | Always `await next()` |
| Route handler without return | Warning | Return response in all branches |
| Body read twice | Warning | Read once, store result |
| Fat handlers with business logic | Warning | Extract to service layer |
| No global error handler | Warning | Register `app.onError()` |
| Inconsistent response envelope | Suggestion | Standardize shape |
| Scattered route definitions | Nit | Group with `app.route()` |
