# Playwright Review Guide

## Metadata
- **Type:** framework
- **Extensions:** .ts (test files in e2e/ directories)
- **Updated:** 2026-02-21

## Categories

### Correctness

- **Use role-based or text-based locators** — `getByRole`, `getByText`, `getByLabel`, `getByPlaceholder` are stable across refactors. CSS selectors and XPath break when markup changes.
  ```typescript
  // Bad — brittle, breaks on class rename
  await page.locator('.btn-primary.submit-form').click()
  await page.locator('#user-name-input').fill('test')

  // Good — stable across refactors
  await page.getByRole('button', { name: 'Submit' }).click()
  await page.getByLabel('Username').fill('test')
  ```

- **Prefer `getByRole` with `name` over `getByText`** — `getByText` matches partial text and can hit multiple elements. `getByRole` with `name` is both more precise and tests accessibility.
  ```typescript
  // Fragile — matches any element containing "Delete"
  await page.getByText('Delete').click()

  // Better — matches the specific button
  await page.getByRole('button', { name: 'Delete' }).click()
  ```

- **Use `data-testid` as last resort** — when no semantic locator works (e.g., visually identical elements with no accessible name), `data-testid` is acceptable. But prefer accessible locators first — they test your accessibility for free.

- **Assert before interacting** — don't click/fill/type unless the element is in the expected state. Use `expect` + `toBeVisible` / `toBeEnabled` first when dealing with dynamic content.
  ```typescript
  // Bad — clicks before content loads, may hit wrong element
  await page.getByRole('button', { name: 'Save' }).click()

  // Good — wait for expected state first
  await expect(page.getByRole('button', { name: 'Save' })).toBeEnabled()
  await page.getByRole('button', { name: 'Save' }).click()
  ```

- **Don't use fixed `waitForTimeout`** — hardcoded sleeps are flaky (too short = failure, too long = slow). Use Playwright's auto-waiting or explicit `waitFor` conditions.
  ```typescript
  // Bad — arbitrary sleep
  await page.waitForTimeout(3000)

  // Good — wait for specific condition
  await expect(page.getByText('Data loaded')).toBeVisible()
  await page.waitForResponse(resp => resp.url().includes('/api/data'))
  ```

- **`toBeVisible` vs `toBeAttached`** — `toBeVisible` checks the element is in the DOM AND visible (not hidden by CSS, not zero-size). `toBeAttached` only checks DOM presence. Usually you want `toBeVisible`.

- **Handle navigation correctly** — clicking a link that navigates should be paired with `waitForURL` or `waitForNavigation`, not a sleep.
  ```typescript
  await page.getByRole('link', { name: 'Settings' }).click()
  await page.waitForURL('**/settings')
  ```

- **Frame and popup handling** — interactions inside iframes require `page.frameLocator()`. New windows/popups require listening for the `popup` event. Don't assume everything is on the main frame.

### Flaky Test Prevention

- **Network-dependent tests need request interception or waiting** — if a test depends on API responses, either mock them with `page.route()` or explicitly wait for the response.
  ```typescript
  // Good — wait for the API response
  const responsePromise = page.waitForResponse('**/api/tasks')
  await page.getByRole('button', { name: 'Refresh' }).click()
  await responsePromise

  // Good — mock for deterministic tests
  await page.route('**/api/tasks', route =>
    route.fulfill({ json: mockTasks })
  )
  ```

- **Isolate test state** — each test should start from a known state. Don't depend on test execution order. Use `beforeEach` to set up state and `afterEach` to clean up.

- **Don't rely on element order in lists** — if the UI sorts by creation time and tests create items, the order may be non-deterministic. Assert by content, not position.
  ```typescript
  // Bad — assumes order
  const items = page.getByRole('listitem')
  await expect(items.nth(0)).toHaveText('First task')

  // Good — assert presence, not position
  await expect(page.getByRole('listitem', { name: 'First task' })).toBeVisible()
  ```

- **Animation and transition timing** — UI animations can cause elements to be "visible" but still animating. Use `page.waitForLoadState('networkidle')` or wait for a specific post-animation state rather than checking visibility during transitions.

- **Retry assertions, not actions** — Playwright auto-retries `expect` assertions but not actions. Wrapping a click in a retry loop usually means you should wait for the element first.

### Performance

- **Parallel test execution** — Playwright runs test files in parallel by default. Don't fight this by adding `test.describe.serial` unless tests genuinely share state.

- **Reuse authentication state** — if multiple tests need a logged-in user, use `storageState` to save and restore auth cookies/tokens instead of logging in every test.
  ```typescript
  // In global setup
  await page.context().storageState({ path: 'auth.json' })

  // In test config
  use: { storageState: 'auth.json' }
  ```

- **Minimize full page navigations** — if testing multiple interactions on the same page, do them in one test instead of navigating from scratch each time. But balance against test isolation.

- **Don't screenshot everything** — screenshots in assertions are expensive (rendering + file I/O). Use `toBeVisible` or `toHaveText` for assertions, screenshots for debugging failures only.

### Error Handling

- **Meaningful assertion messages** — default assertion errors can be cryptic. Add context when it helps diagnose failures.
  ```typescript
  // Cryptic on failure
  await expect(page.getByRole('alert')).toBeVisible()

  // Better
  await expect(page.getByRole('alert'), 'Error alert should appear after invalid submit').toBeVisible()
  ```

- **Capture artifacts on failure** — configure `screenshot: 'only-on-failure'`, `video: 'retain-on-failure'`, and `trace: 'retain-on-failure'` in Playwright config. These are essential for debugging CI failures.

- **Network error assertions** — if a test expects an API call to fail, assert on the error state in the UI, not just the network response. The UI must handle errors gracefully.

### Code Quality

- **Page Object Model for complex pages** — if multiple tests interact with the same page, extract locators and common actions into a page object class. Avoids duplicating locator strings.
  ```typescript
  class TasksPage {
    constructor(private page: Page) {}

    get createButton() { return this.page.getByRole('button', { name: 'Create Task' }) }
    get taskList() { return this.page.getByRole('list', { name: 'Tasks' }) }

    async createTask(title: string) {
      await this.createButton.click()
      await this.page.getByLabel('Title').fill(title)
      await this.page.getByRole('button', { name: 'Save' }).click()
    }
  }
  ```

- **One logical assertion per test** — a test should verify one behavior. Multiple unrelated assertions in one test make failures hard to diagnose.

- **Descriptive test names** — test names should describe the behavior, not the implementation.
  ```typescript
  // Bad
  test('test button click', async () => { ... })

  // Good
  test('creating a task adds it to the task list', async () => { ... })
  ```

- **Don't test implementation details** — test what the user sees and does, not internal component state, CSS classes, or DOM structure.

- **Constants for test data** — don't use random or timestamped values unless testing uniqueness. Deterministic test data makes failures reproducible.

### Comment Hygiene

- **Stale selectors in comments** — comments referencing old CSS selectors or data-testid values that no longer exist.
- **TODO comments about flaky tests** — fix the flakiness or skip the test with a tracking issue. Don't leave known-flaky tests running.
- **Commented-out test cases** — delete them, git has history.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| CSS/XPath selectors for interactions | Warning | Role-based or text-based locators |
| `waitForTimeout` with hardcoded ms | Warning | Wait for specific conditions |
| Tests depending on execution order | Warning | Isolate state in beforeEach |
| Clicking without asserting element state | Warning | `expect(el).toBeEnabled()` first |
| Network-dependent test without waiting/mocking | Warning | `waitForResponse` or `page.route` |
| Re-login in every test | Suggestion | Reuse `storageState` |
| Duplicated locators across tests | Suggestion | Page Object Model |
| Random test data | Suggestion | Deterministic constants |
| Testing CSS classes / DOM structure | Suggestion | Test visible behavior |
| Commented-out tests | Nit | Delete (git history) |
