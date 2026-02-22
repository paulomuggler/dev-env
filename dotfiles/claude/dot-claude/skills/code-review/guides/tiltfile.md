# Tiltfile Review Guide

## Metadata
- **Type:** infrastructure
- **Extensions:** Tiltfile
- **Updated:** 2026-02-21

## Categories

### Correctness

- **`live_update` sync paths must match container paths** — if the container WORKDIR is `/app` and you sync `./src` to `/app/src`, verify the Dockerfile's COPY matches. Mismatched paths cause synced files to land in the wrong location.
  ```python
  # Bad — container expects code at /opt/app, sync goes to /app
  docker_build('myimage', '.', live_update=[
      sync('./src', '/app/src'),
  ])

  # Good — matches Dockerfile WORKDIR
  docker_build('myimage', '.', live_update=[
      sync('./src', '/opt/app/src'),
  ])
  ```

- **`fall_back_on` vs `run` in live_update** — `fall_back_on` triggers a full rebuild when matched files change. `run` executes a command in the container. If you need to reinstall dependencies when `package.json` changes, use `fall_back_on`, not `run('pnpm install')` (which may fail in containers without build tools).
  ```python
  live_update=[
      fall_back_on(['package.json', 'pnpm-lock.yaml']),
      sync('./src', '/app/src'),
  ]
  ```

- **Resource dependencies must form a DAG** — circular `resource_deps` cause Tilt to hang. If A depends on B and B depends on A, neither starts.

- **`docker_compose` resource names come from service names** — the resource name in Tilt is the compose service name. `dc_resource('api')` must match `services: api:` in docker-compose.yml exactly.

- **Ignoring files that trigger unnecessary rebuilds** — without `docker_build(..., ignore=[...])` or `.dockerignore`, changing test files, docs, or configs triggers a full image rebuild.
  ```python
  docker_build('myimage', '.',
      ignore=['./tests', './docs', './*.md', './e2e'],
      live_update=[...],
  )
  ```

- **`only` vs `ignore`** — `only` is a whitelist (only these files are in the build context), `ignore` is a blacklist. Using both is confusing — pick one. `only` is safer for keeping build contexts small.

### Performance

- **Unnecessary full rebuilds** — if `live_update` isn't configured or the sync paths are wrong, every source change triggers a full Docker build. This is the #1 cause of slow Tilt feedback loops.

- **Build context size** — `docker_build` sends the entire context directory to the Docker daemon. Large contexts (node_modules, .git) slow every build. Use `ignore` or `only` to trim.

- **Syncing `node_modules`** — never sync `node_modules` via `live_update`. It's huge and changes frequently during builds. Mount it as a volume or install inside the container.

- **Separate build resources from runtime resources** — if a build step (TypeScript compilation) takes a long time, make it a separate Tilt resource so it doesn't block the runtime resource from starting.

- **`resource_deps` over-constraining startup** — only declare dependencies that are actually needed for startup. Unnecessary deps serialize startup and slow the whole dev stack.

### Code Quality

- **Repeated `docker_build` / `live_update` patterns** — if multiple services have identical build/sync configurations, extract into a helper function.
  ```python
  # Good — DRY
  def ts_service(name, context, port=None):
      docker_build('myregistry/' + name, context,
          live_update=[
              fall_back_on([context + '/package.json']),
              sync(context + '/src', '/app/src'),
          ])

  ts_service('api', './apps/api')
  ts_service('worker', './apps/worker')
  ```

- **Magic strings** — port numbers, image names, and paths repeated across the Tiltfile without named constants.

- **Dead resources** — `dc_resource` or `docker_build` calls for services that no longer exist in docker-compose or the codebase.

- **Overly complex Starlark** — Tiltfiles should be simple and declarative. If you need complex control flow, it may indicate the Docker/Compose setup needs restructuring.

### Resource Organization

- **Labels for grouping** — use `labels` to organize resources in the Tilt UI by concern (infra, api, frontend, etc.).
  ```python
  dc_resource('db', labels=['infra'])
  dc_resource('api', labels=['api'])
  dc_resource('ui', labels=['apps'])
  ```

- **Resource ordering in the file** — organize top-down: infrastructure first, then shared services, then apps. Matches the startup dependency order.

- **Links for convenience** — add `links` to resources that expose web UIs so developers can click through from the Tilt dashboard.
  ```python
  dc_resource('ui', labels=['apps'], links=['https://taskmill.localhost'])
  ```

### Comment Hygiene

- **Stale port numbers in comments** — ports change in docker-compose but comments in Tiltfile don't get updated.
- **Commented-out resources** — delete them, git has history.
- **TODO comments about build optimization** — either do it or track it properly.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| `live_update` sync path doesn't match container | Warning | Verify against Dockerfile WORKDIR |
| Circular `resource_deps` | Warning | Break the cycle, restructure dependencies |
| No `fall_back_on` for dependency files | Warning | Fall back on lockfile/package.json changes |
| Missing `ignore` on docker_build | Warning | Ignore tests, docs, non-source files |
| Syncing `node_modules` via live_update | Warning | Volume mount or container install |
| Repeated build patterns without helpers | Suggestion | Extract to Starlark function |
| No labels on resources | Suggestion | Add labels for Tilt UI organization |
| Dead resources referencing removed services | Suggestion | Delete stale definitions |
| Commented-out resources | Nit | Delete (git history) |
