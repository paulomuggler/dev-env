# TypeScript Architecture Guide

## Metadata
- **Languages:** TypeScript, JavaScript
- **Extensions:** .ts, .tsx, .js, .jsx, .mjs, .cjs
- **Updated:** 2026-02-20

## Module System

### Import Resolution

TypeScript resolves imports through a specific chain: path aliases (`@/`, `~/`), relative paths, `node_modules`, then `baseUrl`. Understanding this chain is essential for detecting circular dependencies and layering violations.

- **Path aliases** — defined in `tsconfig.json` `paths`. Resolve them to actual file paths before building the import graph. Aliases that map to multiple locations (e.g., `@shared/*` mapping to both `packages/shared/src/*` and `packages/shared/dist/*`) can mask circular dependencies.
- **Index file resolution** — `import from './utils'` resolves to `./utils/index.ts`. This creates implicit dependencies on barrel files that may re-export more than needed.
- **Dual extensions** — `.js` in import specifiers often maps to `.ts` source files (ESM convention). Resolve to the actual source when building the import graph.

### Barrel Files (index.ts)

Barrel files are a common modularization pattern in TypeScript but introduce specific architectural risks:

**Appropriate use:**
- Package entry points (`packages/*/src/index.ts`) — defines the public API
- Feature folder entry points — re-exports only the public interface of a feature

**Anti-patterns:**
- **Deep barrel chains** — `index.ts` re-exporting from another `index.ts` that re-exports from another. Creates invisible dependency chains and makes dead export detection harder.
- **Re-exporting everything** — `export * from './internal'` exposes implementation details. Prefer named re-exports for explicit API surface control.
- **Barrel files causing circular dependencies** — when A imports from B's barrel, which re-exports from C, which imports from A. The barrel makes the cycle non-obvious.

### Tree-Shaking Implications

- **Side-effect imports** (`import './setup'`) prevent tree-shaking and are invisible in the export map. Flag files imported only for side effects.
- **`sideEffects: false`** in `package.json` enables aggressive tree-shaking but can break modules with genuine side effects (CSS imports, polyfills, module-level initialization).
- **Dynamic imports** (`import()`) create code-split boundaries. Files only reachable through dynamic imports are separate chunks and may have different initialization timing.

## Type System Patterns

### Type-Only vs Runtime Dependencies

TypeScript `import type` and `type` exports are erased at compile time. This distinction is critical for circular dependency analysis:

- **Type-only cycles are benign** — `import type { User } from './user'` creates no runtime dependency. The import graph should distinguish `type` imports from value imports.
- **Mixed imports mask cycles** — `import { User, createUser } from './user'` imports both a type and a value. Even if only `User` is used as a type, the runtime import exists. Use `import type` explicitly when only types are needed.
- **`isolatedModules` enforcement** — when enabled, re-exports must distinguish types: `export type { Foo }` vs `export { Foo }`. This is architecturally helpful — it makes the type/value boundary explicit.

### Structural Typing and Interface Segregation

TypeScript's structural typing means interface segregation works differently than in nominal type systems:

- **Over-broad interfaces** — a function accepting `User` when it only needs `{ id: string; name: string }` creates unnecessary coupling to the full `User` type. This shows up as high fan-in on type definition files.
- **Utility types as coupling** — `Partial<User>`, `Pick<User, 'id'>` still couple to `User`. For cross-module boundaries, define standalone interfaces.
- **Type-only files** — files that export only types (no runtime code) are natural module boundary definitions. Their fan-in indicates how many modules depend on the contract.

### Discriminated Unions

Discriminated unions are TypeScript's primary pattern for modeling state. Architectural concerns:

- **Scattered switch statements** — if the same union is switched on in many files, those files are tightly coupled to the union's shape. Adding a variant means updating all switch sites. Consider the visitor pattern or a dispatch map for high fan-out unions.
- **Union types in wrong layer** — domain unions defined in the UI layer (or vice versa) are a layering violation.

## Dependency Management

### Workspace Patterns (pnpm/npm/yarn)

Monorepo workspace conventions affect architectural analysis:

- **Package boundaries** — each `package.json` in a workspace defines a module boundary. Imports across package boundaries should go through the package's entry point, not reach into `src/` directly.
- **Peer dependencies** — indicate "this package works alongside X but doesn't own X." Peer dep mismatches across workspace packages indicate version conflicts.
- **Internal packages** — workspace packages that are only consumed internally. These should have `"private": true` and can have looser API surface rules.

### Circular Package Dependencies

Circular dependencies between workspace packages are more severe than within-package cycles:

- They break incremental builds (TypeScript `references`, `tsc --build`)
- They prevent independent deployment
- They indicate the package boundary is wrong — consider merging or extracting a shared package

## Common Anti-Patterns

| Pattern | Category | Severity | Description |
|---------|----------|----------|-------------|
| Barrel re-export chain | API Surface | Warning | `index.ts` → `index.ts` → `index.ts` re-export depth >2 |
| God module | God Files | Warning | >500 lines, >15 exports, or >20 imports |
| Utility dumping ground | Coupling | Warning | A `utils/` or `helpers/` directory with unrelated functions that's imported everywhere |
| Cross-package internal import | Layering | Warning | Importing from `packages/x/src/internal/` instead of `packages/x` entry point |
| Type import without `import type` | Circular Deps | Suggestion | Value import used only for types — masks the true dependency graph |
| Side-effect-only module | Dead Code | Suggestion | File imported with `import './x'` — invisible in export analysis |
| Shared type file with runtime code | Coupling | Warning | `types.ts` that also exports functions/constants — forces runtime dependency for type consumers |
| Enum in shared types | Coupling | Warning | Enums are runtime objects in TS. Shared enum files create runtime coupling. Prefer `as const` objects or union types. |
| Default export overuse | API Surface | Suggestion | Default exports prevent tree-shaking, make refactoring harder (inconsistent import names), and don't play well with barrel files |
| Re-exporting third-party types | API Surface | Suggestion | `export { SomeType } from 'third-party'` creates coupling between consumers and a specific third-party package |

## Modularization Idioms

### Feature-Based vs Layer-Based

TypeScript projects typically organize as one of:

**Feature-based** (preferred for applications):
```
src/
  auth/
    auth.service.ts
    auth.routes.ts
    auth.types.ts
  users/
    users.service.ts
    users.routes.ts
    users.types.ts
  shared/
    db.ts
    logger.ts
```

**Layer-based** (common in smaller projects):
```
src/
  services/
    auth.ts
    users.ts
  routes/
    auth.ts
    users.ts
  types/
    auth.ts
    users.ts
```

Mixing these patterns within the same project is an inconsistency finding. Feature-based scales better — related code is co-located and feature folders can be extracted into packages.

### Dependency Direction

In a well-layered TypeScript application:

```
Routes/Controllers → Services → Repositories/Data
         ↓                ↓              ↓
      Types/Interfaces (shared, type-only)
```

Violations to detect:
- Services importing from routes (business logic depending on transport)
- Repositories importing from services (data layer depending on business logic)
- Any layer importing from a higher layer
- Framework-specific code (Express req/res, React hooks) in service/domain layer
