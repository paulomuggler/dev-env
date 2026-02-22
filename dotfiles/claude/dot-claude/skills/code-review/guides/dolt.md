# Dolt Review Guide

## Metadata
- **Type:** infrastructure
- **Extensions:** .sql, .ts (database access code)
- **Updated:** 2026-02-21

## Categories

### Security

- **Parameterized queries only** — Dolt is MySQL-compatible, so all SQL injection risks apply. Never interpolate user input into query strings.
  ```typescript
  // Bad
  await db.query(`SELECT * FROM tasks WHERE id = '${taskId}'`)

  // Good
  await db.query('SELECT * FROM tasks WHERE id = ?', [taskId])
  ```

- **Don't expose Dolt system tables to clients** — `dolt_log`, `dolt_diff`, `dolt_status`, and other system tables expose internal history. Filter them from any user-facing query or API.

- **Database credentials** — never hardcode connection strings. Use environment variables. The `mysql2` driver accepts individual params (`host`, `user`, `password`, `database`) — prefer these over connection string URLs to avoid URL-encoding issues with special characters in passwords.

- **Principle of least privilege** — application database users should have only the permissions they need (SELECT, INSERT, UPDATE, DELETE on application tables). Don't use the root account for application queries.

### Correctness

- **CLI vs SQL server — critical gotcha** — `docker exec taskmill-dolt dolt sql` writes to a file-based database, not the running SQL server. Changes made via CLI are invisible to the server and vice versa. Always use the SQL server (`mysql -h localhost -P 3306`) or the `mysql2` driver.

- **Transaction isolation** — Dolt defaults to `READ COMMITTED` isolation. If your code reads a value, makes a decision, then writes, another transaction can change the value in between. Use `SERIALIZABLE` for read-modify-write patterns, or use `SELECT ... FOR UPDATE`.
  ```typescript
  // Bad — TOCTOU race condition
  const task = await db.query('SELECT status FROM tasks WHERE id = ?', [id])
  if (task.status === 'pending') {
    await db.query('UPDATE tasks SET status = ? WHERE id = ?', ['running', id])
  }

  // Good — atomic check-and-update
  await db.query(
    'UPDATE tasks SET status = ? WHERE id = ? AND status = ?',
    ['running', id, 'pending']
  )
  ```

- **Dolt branch semantics** — Dolt branches work like git branches. The server runs on a single branch (usually `main`). Writing to other branches requires `CALL dolt_checkout('branch')` within a session. This is session-scoped — it doesn't affect other connections. Don't assume all connections see the same branch.

- **Auto-commit vs explicit transactions** — Dolt auto-commits each statement by default. For multi-statement operations that must be atomic, use explicit `BEGIN`/`COMMIT`. A crash between two auto-committed statements leaves data half-updated.

- **`DOLT_COMMIT` is not `COMMIT`** — `CALL dolt_commit(...)` creates a Dolt version history entry (like `git commit`). `COMMIT` ends a SQL transaction. They serve completely different purposes. You can commit a SQL transaction without creating a Dolt commit, and vice versa.

- **NULL handling** — MySQL (and Dolt) treats NULL differently than empty string or zero. `WHERE col = NULL` never matches — use `WHERE col IS NULL`. `NULL` in arithmetic produces `NULL`. Be explicit about nullable columns in schema and application code.

### Performance

- **`SELECT *` on wide tables** — only select the columns you need. Dolt's storage engine benefits from column pruning more than traditional MySQL because of its content-addressed storage.

- **Missing indexes** — queries that filter or join on columns without indexes cause full table scans. Check `EXPLAIN` output for table scans on tables with >1000 rows.

- **N+1 query patterns** — same as any database. Batch reads with `IN (...)` clauses.

- **Dolt versioning overhead** — every `CALL dolt_commit()` creates a snapshot. Committing after every single row change is expensive. Batch related changes, then commit once.
  ```typescript
  // Bad — commit per row
  for (const task of tasks) {
    await db.query('UPDATE tasks SET status = ? WHERE id = ?', [status, task.id])
    await db.query("CALL dolt_commit('-Am', 'Update task')")
  }

  // Good — batch then commit
  for (const task of tasks) {
    await db.query('UPDATE tasks SET status = ? WHERE id = ?', [status, task.id])
  }
  await db.query("CALL dolt_commit('-Am', 'Batch update tasks')")
  ```

- **Large diffs** — `dolt_diff()` on tables with many changed rows is expensive. Use it for auditing, not hot-path queries.

- **Connection pooling** — create a pool, don't open a new connection per query. `mysql2/promise` pool handles this. Set `connectionLimit` appropriate to the workload.

### Schema & Migrations

- **Migration files must be idempotent** — use `CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`. Dolt supports MySQL 8 DDL syntax.

- **Foreign key constraints** — Dolt supports them but they add overhead. Use them for data integrity on core domain tables. Don't skip them to save migration complexity.

- **Column types** — Dolt supports standard MySQL types. Prefer `VARCHAR(N)` over `TEXT` for bounded strings (enables indexing). Use `JSON` type for semi-structured data, not serialized strings in `TEXT`.

- **Migration ordering** — migration files should be numbered sequentially and never reordered after deployment. Name them descriptively (`003_add_tools_table.sql`, not `003_changes.sql`).

- **Default values** — always provide `DEFAULT` for non-nullable columns that get added to existing tables. Otherwise the ALTER fails if the table has rows.

### Error Handling

- **Connection errors** — MySQL connections drop due to idle timeouts, network issues, or server restarts. Use connection pool `waitForConnections` and retry logic. Don't treat a connection error as a permanent failure.

- **Deadlock retry** — Dolt (like MySQL) can deadlock on concurrent transactions. Catch error code `ER_LOCK_DEADLOCK` (1213) and retry the transaction.

- **Duplicate key handling** — use `INSERT ... ON DUPLICATE KEY UPDATE` or catch error code 1062 explicitly. Don't let duplicate key errors bubble as 500s.

- **Query timeout** — set `connectTimeout` and statement-level timeouts for long-running queries. A hung query blocks the connection pool.

### Code Quality

- **Raw SQL strings scattered across handlers** — centralize queries in repository modules. Handlers should call repository methods, not construct SQL.

- **Type-unsafe query results** — `mysql2` returns `RowDataPacket[]` which is untyped. Define result types and use type assertions on the specific repository method, not at the call site.
  ```typescript
  // Bad — untyped result used everywhere
  const [rows] = await db.query('SELECT * FROM tasks')
  const task = rows[0] as any

  // Good — typed in repository
  interface Task { id: string; title: string; status: string }
  async function getTask(id: string): Promise<Task | null> {
    const [rows] = await db.query<Task[]>('SELECT * FROM tasks WHERE id = ?', [id])
    return rows[0] ?? null
  }
  ```

- **Magic column names** — string literals like `'status'`, `'pending'` scattered across queries. Define column names and enum values as constants.

### Comment Hygiene

- **Migration comments describing "why"** — migrations should have a comment at the top explaining the purpose, not just `-- Add column`. The schema change is visible; the reason is not.
- **Stale schema comments** — comments in migration files referencing columns or tables that have since been renamed or dropped.
- **TODO comments about index optimization** — either add the index or track it as a task.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| String-interpolated SQL | Critical | Parameterized queries |
| Using Dolt CLI instead of SQL server | Critical | Always use mysql client/driver |
| Missing transaction for multi-statement atomic ops | Warning | Explicit BEGIN/COMMIT |
| `dolt_commit()` per row | Warning | Batch changes, commit once |
| No connection pooling | Warning | Use mysql2 pool |
| SELECT * on wide tables | Warning | Select specific columns |
| Missing indexes on filtered columns | Warning | Add indexes, check EXPLAIN |
| Raw SQL in handlers (not repositories) | Warning | Centralize in repository layer |
| Non-idempotent migrations | Warning | IF NOT EXISTS / IF EXISTS |
| Untyped query results at call sites | Suggestion | Type in repository methods |
| No deadlock retry logic | Suggestion | Catch 1213, retry transaction |
