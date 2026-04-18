# Docker Review Guide

## Metadata
- **Type:** infrastructure
- **Extensions:** Dockerfile*, docker-compose*.yml, docker-compose*.yaml
- **Updated:** 2026-02-21

## Categories

### Security

- **Don't run as root** — containers should use a non-root user. Add `USER` directive after installing dependencies.
  ```dockerfile
  # Bad — runs as root (default)
  COPY . .
  CMD ["node", "server.js"]

  # Good
  RUN addgroup --system app && adduser --system --ingroup app app
  USER app
  COPY --chown=app:app . .
  CMD ["node", "server.js"]
  ```

- **No secrets in build args or ENV** — `ARG` and `ENV` values are visible in image history (`docker history`). Use runtime secrets, mounted files, or Docker BuildKit secrets.
  ```dockerfile
  # Bad — secret in build layer
  ARG DATABASE_PASSWORD
  ENV DB_PASS=$DATABASE_PASSWORD

  # Good — pass at runtime
  # docker run -e DB_PASS=secret ...
  # or use --secret flag with BuildKit
  ```

- **Pin base image versions** — `FROM node:latest` is unpredictable. Pin to specific version tags (`node:22-slim`). Even better, use digest pinning for reproducible builds.
  ```dockerfile
  # Bad
  FROM node:latest

  # Good
  FROM node:22-slim
  ```

- **Don't install unnecessary packages** — every package increases attack surface. No `curl`, `wget`, `vim`, `ssh` in production images unless actually needed at runtime. Use multi-stage builds to separate build-time and runtime dependencies.

- **Don't COPY `.env` or credentials files** — these should be mounted at runtime or injected via environment variables. Add them to `.dockerignore`.

- **Scan for known vulnerabilities** — base images may contain CVEs. Use `docker scout` or Trivy in CI.

### Correctness

- **COPY before RUN that depends on it** — Docker layers execute top-down. Ensure files are copied before commands that need them.

- **`COPY . .` copies everything not in `.dockerignore`** — verify `.dockerignore` excludes `node_modules`, `.git`, `.env`, `dist`, test files, and other build artifacts. Missing `.dockerignore` bloats images and may leak secrets.

- **WORKDIR must exist** — `WORKDIR /app` creates the directory, but if you need specific ownership, create it explicitly first.

- **CMD vs ENTRYPOINT** — `CMD` is overridable, `ENTRYPOINT` is not (without `--entrypoint`). Use `ENTRYPOINT` for the main process and `CMD` for default arguments.
  ```dockerfile
  # Good — entrypoint is fixed, args are overridable
  ENTRYPOINT ["node"]
  CMD ["server.js"]
  ```

- **Signal handling** — use exec form (`["node", "server.js"]`), not shell form (`node server.js`). Shell form wraps in `/bin/sh` which doesn't forward signals (SIGTERM), causing ungraceful shutdowns and 10-second Docker kill delays.

- **Multi-stage build artifact paths** — when copying from a build stage, verify the source path exists. A typo silently copies nothing.
  ```dockerfile
  # Verify this path matches the build output
  COPY --from=build /app/dist ./dist
  ```

### Performance

- **Layer ordering for cache efficiency** — put rarely-changing layers first (base image, system deps), then dependency install (package.json/lockfile), then source code last. This maximizes cache hits.
  ```dockerfile
  # Good — dependencies cached unless lockfile changes
  COPY package.json pnpm-lock.yaml ./
  RUN pnpm install --frozen-lockfile
  COPY src/ ./src/
  RUN pnpm build
  ```

- **Use slim/alpine base images** — `node:22-slim` (~50MB) vs `node:22` (~350MB). Only use full images when native compilation requires build tools.

- **Multi-stage builds** — separate build-time tools (TypeScript compiler, dev dependencies) from the runtime image. Final stage should only contain production artifacts.
  ```dockerfile
  FROM node:22-slim AS build
  COPY . .
  RUN pnpm install && pnpm build

  FROM node:22-slim
  COPY --from=build /app/dist ./dist
  COPY --from=build /app/node_modules ./node_modules
  CMD ["node", "dist/index.js"]
  ```

- **Minimize layer count** — combine related `RUN` commands with `&&`. Each `RUN` creates a layer.
  ```dockerfile
  # Bad — 3 layers
  RUN apt-get update
  RUN apt-get install -y curl
  RUN apt-get clean

  # Good — 1 layer, cleans up in same layer
  RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
  ```

- **Don't install dev dependencies in production images** — use `--production` or `--frozen-lockfile` with appropriate filters. For pnpm workspaces, use `--filter` to install only what's needed.

- **`.dockerignore` for build context size** — a large build context (node_modules, .git) slows every build even if COPY doesn't use it. The entire context is sent to the daemon.

### Docker Compose

- **`depends_on` only controls startup order, not readiness** — the dependent service starts after the dependency's container starts, not after it's ready. Use health checks with `condition: service_healthy`.
  ```yaml
  services:
    api:
      depends_on:
        db:
          condition: service_healthy
    db:
      healthcheck:
        test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
        interval: 5s
        timeout: 3s
        retries: 5
  ```

- **Named volumes vs bind mounts** — named volumes persist across `docker compose down` and are managed by Docker. Bind mounts (`.:/app`) mirror host files. Don't confuse them — losing a named volume loses data.

- **Environment variable precedence** — `.env` file < `environment:` in compose < shell environment. This ordering can cause confusion when values don't match expectations.

- **Port mapping conflicts** — `ports: "3306:3306"` always use quotes around ports with colons in YAML (otherwise YAML interprets as sexagesimal). Check for host port conflicts across services.

- **Restart policies** — `restart: unless-stopped` for persistent services, `restart: "no"` or `restart: on-failure` for one-shot tasks. Don't use `restart: always` on services that are expected to exit.

- **Volume mount permissions** — files created in containers may have root ownership on the host. Use `user:` directive or match container UID to host UID.

- **Network isolation** — services that don't need to communicate shouldn't be on the same network. Use named networks to segment.

- **Hardcoded container names** — `container_name:` prevents scaling and causes conflicts on shared hosts. Only use for infra services that need stable DNS names.

### Comment Hygiene

- **Stale port mappings** — comments listing ports that don't match the actual `EXPOSE` or `ports:` configuration.
- **TODO comments about build optimization** — if the optimization is straightforward, just do it.
- **Commented-out services** in docker-compose — delete them, git has history.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| Running as root | Critical | Add USER directive |
| Secrets in ARG/ENV | Critical | Runtime injection or BuildKit secrets |
| Missing `.dockerignore` | Warning | Create with node_modules, .git, .env |
| Shell form CMD/ENTRYPOINT | Warning | Exec form for signal handling |
| `depends_on` without health check | Warning | Add healthcheck + condition |
| Dev dependencies in production image | Warning | Multi-stage build or production install |
| `COPY . .` without reviewing .dockerignore | Warning | Audit what gets copied |
| Unpinned base image (`latest`) | Warning | Pin to specific version |
| Large base image when slim works | Suggestion | Use `-slim` or `-alpine` variants |
| Layer ordering defeats cache | Suggestion | Dependencies before source code |
| Commented-out services in compose | Nit | Delete (git history) |
