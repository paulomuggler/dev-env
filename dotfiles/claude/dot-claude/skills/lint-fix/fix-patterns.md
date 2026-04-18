# Fix Patterns Reference

Known-good fix patterns for common lint issues. Consult this BEFORE fixing each issue.

The #1 mistake is removing a type assertion without checking whether the function has a generic
parameter. When `no-unnecessary-type-assertion` flags a cast, the fix is almost never "just remove
the cast" — it's "use the generic parameter instead."

---

## Pattern: Cast after function call → Use generic parameter

**Symptom:** `no-unnecessary-type-assertion` flags `fn() as T`

**Wrong fix:** Remove the cast (leaves variable as `any` or `unknown`)

**Right fix:** Check if the function accepts a generic type parameter. If so, pass it.

```typescript
// BAD — cast after call
const rows = (await client.query(sql)) as UserRow[];
const body = await c.req.json() as Record<string, unknown>;
const data = response.json() as ApiResponse;

// GOOD — use the generic
const rows = await client.query<UserRow[]>(sql);
const body = await c.req.json<Record<string, unknown>>();
const data = response.json<ApiResponse>();
```

**How to check:** Read the function's type signature. Look for `<T>` or `<T extends ...>` in the
parameter list. Common functions with generics:
- Database query methods (mysql2, pg, prisma)
- HTTP response parsers (`.json<T>()`, `.text()`)
- Collection methods (`.reduce<T>()`, `.filter()` with type predicates)
- Framework methods (React's `useState<T>()`, Hono's `c.req.json<T>()`)

---

## Pattern: `as any[]` on query results → Remove or use generic

**Symptom:** `no-unnecessary-type-assertion` flags `as any[]`

**Wrong fix:** Keep the cast (it widens to `any`, losing all type info)

**Right fix:** Remove the cast entirely. The query returns `RowDataPacket[]` which supports
`[column: string]: any` access. Or use a generic if available.

```typescript
// BAD — casting to any[] is ALWAYS wrong, it only loses type info
const results = await query(sql) as any[];

// GOOD — let the return type work
const results = await query(sql);

// BETTER — if query supports generics
const results = await query<SpecificRow[]>(sql);
```

---

## Pattern: `||` with nullable type → `??`

**Symptom:** `prefer-nullish-coalescing` flags `expr || fallback`

**Safe when:** Left operand type includes `null` or `undefined` but NOT `string`, `number`, or
`boolean` as standalone types.

```typescript
// Type is string | null → SAFE (strings are always truthy when non-null... wait, "" is falsy)
// Actually: string | null → CHECK if empty string is valid
// Type is number | null → CHECK if 0 is valid
// Type is SomeObject | null → SAFE (objects are always truthy)
// Type is T | undefined → SAFE for objects, CHECK for primitives

// Safe cases:
const config = savedConfig ?? defaultConfig;     // object | undefined
const handler = customHandler ?? defaultHandler; // function | null

// SKIP — empty string or zero might be valid:
const name = input || 'Anonymous';     // string — "" should probably fall through
const count = rawCount || 1;           // number — 0 might be valid
```

**Decision tree:**
1. Is the left operand an object type? → `??` is safe
2. Is it `string`? → SKIP (unless you can prove `""` should NOT fall through)
3. Is it `number`? → SKIP (unless you can prove `0` should NOT fall through)
4. Is it `boolean`? → SKIP
5. Is it a union with null/undefined? → Apply rules above to the non-null type

**`process.env.*` is ALWAYS a suppress.** Environment variables are `string | undefined`. An unset
var is `undefined`, but a var set to empty (`VAR=""`) is `""`. Using `??` would let empty strings
through, which almost always breaks downstream code (`parseInt("") = NaN`, empty URLs fail, etc.).
Always suppress with: `// eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing -- env vars may be empty strings, || is intentional`

```typescript
// ALWAYS suppress — never change || to ?? for env vars
// eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing -- env vars may be empty strings, || is intentional
const port = parseInt(process.env.PORT || '3000', 10);
// eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing -- env vars may be empty strings, || is intentional
const apiUrl = process.env.API_URL || 'http://localhost:3500';
```

---

## Pattern: `value!` → null guard

**Symptom:** `noNonNullAssertion` flags `value!`

```typescript
// BAD
const item = list.find(x => x.id === id)!;
process(item.name);

// GOOD — early return
const item = list.find(x => x.id === id);
if (!item) return;  // or throw new Error(`Item ${id} not found`)
process(item.name);

// GOOD — nullish coalescing (when a fallback makes sense)
const port = config.port ?? 3000;

// GOOD — optional chaining (when undefined is acceptable downstream)
const name = user?.profile?.displayName;
```

**Exception:** `!` after Map.get() inside a loop over Map.keys() is provably safe, but still
prefer restructuring with `for (const [key, value] of map)`.

---

## Pattern: `any` in function signature → narrow the type

**Symptom:** `noExplicitAny` flags parameter or return type

```typescript
// BAD
function process(data: any) { ... }

// GOOD — if you know the shape
function process(data: ActivationPayload) { ... }

// GOOD — if truly unknown input
function process(data: unknown) {
  if (typeof data !== 'object' || data === null) throw new Error('Expected object');
  // now data is object
}

// GOOD — if generic
function process<T extends Record<string, unknown>>(data: T) { ... }
```

**For event handlers / callbacks:** Look at what the caller passes. The type usually exists
somewhere — an interface, a generic constraint, a parent component's prop type.

---

## Pattern: eslint-disable comment for a rule we don't run → remove

**Symptom:** `no-unnecessary-type-assertion` or auto-fix removes `eslint-disable` comments

Old `// eslint-disable-next-line @typescript-eslint/no-explicit-any` comments are dead if we use
Biome for that rule instead. Remove them. Don't leave blank lines in their place — delete the
line entirely.

---

## Anti-patterns to avoid

1. **Don't add `as unknown as T` to satisfy the linter.** This is a double-cast that hides the
   real problem. Find the proper type.

2. **Don't replace `any` with `any` somewhere else.** If you're moving the `any` instead of
   eliminating it, you haven't fixed anything.

3. **Don't add `// @ts-expect-error` or `// @ts-ignore`.** These suppress the compiler, not the
   linter, and hide real bugs. If you need to suppress, use the linter's own mechanism
   (`eslint-disable-next-line` or `biome-ignore`) with a justification comment.

4. **Don't add unnecessary type guards** just to satisfy `noNonNullAssertion`. If the value is
   guaranteed non-null by the code flow, a guard for an impossible case adds noise. In that case,
   suppress with a justification explaining why `!` is correct here.

5. **Don't widen return types.** If a function returns `string` and a caller casts it to `any`,
   fix the caller, don't change the function to return `any`.
