# Hono Review Severity Prescriptions

Review-only overlay for Hono framework patterns. Use alongside `review/typescript.md`.

## Severity Mappings

| Pattern | Severity | Category |
|---------|----------|----------|
| Route handler without try/catch wrapping body | Warning | Error Handling |
| `c.req.json()` result used without validation | Warning | Security |
| `c.req.param()` / `c.req.query()` used without validation | Warning | Security |
| Raw error message exposed in response (`c.json({ error: e.message })`) | Warning | Security |
| Wildcard CORS (`origin: '*'`) in non-dev environment | Warning | Security |
| Route handler >60 lines (extract to service/helper) | Suggestion | Code Quality |
| Missing content-type check before `c.req.json()` | Suggestion | Correctness |
| Status code mismatch (returning 500 for client errors) | Warning | Error Handling |
| Missing 404 for "not found" cases (returning empty 200) | Suggestion | Correctness |
| Inconsistent error response shape across routes | Suggestion | Code Quality |

## Rules

1. Hono route handlers are the primary trust boundary. All request data must be validated.
2. Error responses should never leak internal details (stack traces, SQL errors, file paths).
3. Status codes must match semantics: 400 for bad input, 404 for missing resources, 500 only for genuine server errors.
