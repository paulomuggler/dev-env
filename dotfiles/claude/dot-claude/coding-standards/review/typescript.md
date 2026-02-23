# TypeScript Review Severity Prescriptions

Review-only overlay. Prescribes severity and category for common TypeScript patterns.
Analysis subagents MUST use these classifications when reporting findings — do not
reclassify patterns listed here.

## Severity Mappings

| Pattern | Severity | Category |
|---------|----------|----------|
| `response.json() as T` without runtime validation | Warning | Security |
| `req.json() as T` without runtime validation | Warning | Security |
| Any `as T` cast on external data (API, DB, file, user input) | Warning | Security |
| `eval()` or `new Function()` | Critical | Security |
| String-concatenated SQL | Critical | Security |
| Hardcoded secrets (API keys, tokens, passwords) | Critical | Security |
| `\|\|` on nullable types where `??` is intended | Warning | Correctness |
| Truthy check (`if (value)`) excluding valid falsy values (0, "") | Warning | Correctness |
| Missing `await` on async call | Warning | Correctness |
| Floating promise (created but never awaited/caught) | Warning | Correctness |
| Non-exhaustive switch on union type (no `default: never`) | Warning | Correctness |
| Non-null assertion `!` without nearby truthiness check | Warning | Correctness |
| Empty catch block (swallowed error) | Warning | Error Handling |
| `catch (e)` without type narrowing, accessing `e.message` | Warning | Error Handling |
| Missing try/catch on route handler body | Warning | Error Handling |
| Event handler without `ack()` in finally | Warning | Error Handling |
| Unhandled promise rejection in callback/setTimeout | Warning | Error Handling |
| N+1 query in loop | Warning | Performance |
| `[...acc, item]` in reduce (O(n^2)) | Warning | Performance |
| `as any` type assertion | Warning | Code Quality |
| `@ts-ignore` without justification comment | Warning | Code Quality |
| Functions >80 lines | Suggestion | Code Quality |
| Functions >50 lines | Nit | Code Quality |
| Nesting >3 levels deep | Suggestion | Code Quality |
| Dead code (unreachable branches, unused imports) | Suggestion | Code Quality |
| Duplicated logic (3+ identical blocks) | Suggestion | Code Quality |
| Magic numbers/strings without named constant | Suggestion | Code Quality |
| Stale/misleading comments | Nit | Comment Hygiene |
| Obvious comments (`// increment counter`) | Nit | Comment Hygiene |
| Commented-out code | Nit | Comment Hygiene |

## Rules

1. **Do not promote Suggestion to Warning** unless the pattern appears in the table above as Warning.
2. **Do not downgrade Warning to Suggestion** for patterns in the table — use the prescribed severity.
3. If a pattern is not in this table, use your best judgment but err toward lower severity.
4. The `languages/typescript.md` guide has detailed examples for each pattern — reference it for context on what constitutes the pattern, but use THIS file for severity.
