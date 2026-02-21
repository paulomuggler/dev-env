# React Review Guide

## Metadata
- **Type:** framework
- **Extensions:** .tsx, .jsx
- **Updated:** 2026-02-21

## Categories

### Security

- **No `dangerouslySetInnerHTML` with unsanitized data** — XSS vector. If absolutely needed, sanitize with DOMPurify or similar. Prefer rendering structured data through JSX.
  ```tsx
  // Bad
  <div dangerouslySetInnerHTML={{ __html: userContent }} />

  // Good
  <div>{userContent}</div>
  // or if HTML is needed:
  <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
  ```

- **No `javascript:` URLs in href** — React warns but doesn't block. Validate URL protocols.
  ```tsx
  // Bad
  <a href={userProvidedUrl}>Click</a>

  // Good
  const safeUrl = url.startsWith('http://') || url.startsWith('https://') ? url : '#'
  <a href={safeUrl}>Click</a>
  ```

- **Don't spread arbitrary props onto DOM elements** — `{...props}` on native elements can inject event handlers (`onClick`, `onError`) or dangerous attributes.
  ```tsx
  // Bad — user-controlled props reach the DOM
  <div {...userProps} />

  // Good — pick only known-safe props
  <div className={userProps.className} id={userProps.id} />
  ```

### Correctness

- **Rules of Hooks** — hooks must be called at the top level of a component or custom hook. Never inside conditions, loops, or nested functions.
  ```tsx
  // Bad
  if (isEnabled) {
    const [value, setValue] = useState(0)
  }

  // Good
  const [value, setValue] = useState(0)
  // use `isEnabled` in the render logic, not around the hook
  ```

- **Missing dependency in useEffect/useMemo/useCallback** — stale closures cause bugs. Include all referenced variables in the dependency array, or restructure to avoid the dependency.
  ```tsx
  // Bad — stale `count`
  useEffect(() => {
    const id = setInterval(() => setCount(count + 1), 1000)
    return () => clearInterval(id)
  }, []) // missing `count`

  // Good
  useEffect(() => {
    const id = setInterval(() => setCount(c => c + 1), 1000)
    return () => clearInterval(id)
  }, [])
  ```

- **Stale closure in event handlers** — event handlers defined in render capture the closure at render time. Use refs or functional updates for current values.

- **Missing cleanup in useEffect** — subscriptions, timers, event listeners, and abort controllers must be cleaned up in the return function.
  ```tsx
  // Bad — memory leak
  useEffect(() => {
    const ws = new WebSocket(url)
    ws.onmessage = handleMessage
  }, [url])

  // Good
  useEffect(() => {
    const ws = new WebSocket(url)
    ws.onmessage = handleMessage
    return () => ws.close()
  }, [url])
  ```

- **State updates on unmounted components** — async operations that resolve after unmount. Use abort controllers or check mounted state.
  ```tsx
  useEffect(() => {
    const controller = new AbortController()
    fetch(url, { signal: controller.signal }).then(setData).catch(() => {})
    return () => controller.abort()
  }, [url])
  ```

- **Key prop misuse** — using array index as key when list items can be reordered, added, or removed causes incorrect rendering. Use stable, unique IDs.
  ```tsx
  // Bad — index key with mutable list
  items.map((item, i) => <Item key={i} {...item} />)

  // Good
  items.map(item => <Item key={item.id} {...item} />)
  ```

- **Direct state mutation** — mutating state objects/arrays instead of creating new references. React won't re-render.
  ```tsx
  // Bad
  state.items.push(newItem)
  setState(state)

  // Good
  setState(prev => ({ ...prev, items: [...prev.items, newItem] }))
  ```

- **setState in render** — calling setState during render causes infinite re-render loops. State updates belong in effects or event handlers.

### Performance

- **Unnecessary re-renders from inline objects/functions** — new references on every render defeat React.memo and cause child re-renders.
  ```tsx
  // Bad — new object every render
  <Child style={{ marginTop: 10 }} onClick={() => handleClick(id)} />

  // Good
  const style = useMemo(() => ({ marginTop: 10 }), [])
  const handleItemClick = useCallback(() => handleClick(id), [id])
  <Child style={style} onClick={handleItemClick} />
  ```

- **Heavy computation in render** — expensive calculations should be memoized with `useMemo`, not recomputed on every render.

- **Missing React.memo on pure components** — leaf components that receive the same props frequently should be memoized. But don't over-memoize — only where profiling shows benefit.

- **Large context value without memoization** — context value that creates new object references on every render re-renders all consumers.
  ```tsx
  // Bad — all consumers re-render on any parent render
  <MyContext.Provider value={{ data, actions }}>

  // Good
  const value = useMemo(() => ({ data, actions }), [data, actions])
  <MyContext.Provider value={value}>
  ```

- **Expensive list rendering without virtualization** — rendering 1000+ items in a list. Use `react-window`, `react-virtuoso`, or `@tanstack/react-virtual`.

- **Fetching in useEffect without caching** — use React Query, SWR, or similar for data fetching. Raw useEffect + fetch leads to waterfalls, duplicate requests, and missing loading/error states.

### Error Handling

- **Missing error boundaries** — unhandled errors in React components crash the entire app. Wrap sections with error boundaries. Class components with `componentDidCatch` or libraries like `react-error-boundary`.

- **Unhandled async errors in useEffect** — async operations in effects that don't catch errors crash silently. Always add `.catch()` or try/catch.
  ```tsx
  // Bad
  useEffect(() => {
    fetchData().then(setData)
  }, [])

  // Good
  useEffect(() => {
    fetchData().then(setData).catch(err => setError(err))
  }, [])
  ```

- **Missing loading and error states** — components that fetch data must handle loading, error, and empty states. Not just the happy path.

### Code Quality

- **Component doing too much** — a component that handles data fetching, business logic, and rendering. Split into container/presenter or use custom hooks.

- **Prop drilling more than 2 levels** — pass context or use composition instead.

- **Boolean prop explosion** — components with many boolean flags (`isLoading`, `isError`, `isDisabled`, `isExpanded`). Consider a state machine or discriminated union.
  ```tsx
  // Bad
  type Props = { isLoading: boolean; isError: boolean; data: Data | null }

  // Good
  type Props =
    | { status: 'loading' }
    | { status: 'error'; error: Error }
    | { status: 'success'; data: Data }
  ```

- **Unused state** — state variables that are set but never read, or state that could be derived from props/other state.

- **Derived state that should be computed** — state that mirrors or derives from props. Compute it during render instead.
  ```tsx
  // Bad — state mirrors props
  const [fullName, setFullName] = useState(`${first} ${last}`)
  useEffect(() => setFullName(`${first} ${last}`), [first, last])

  // Good — derive in render
  const fullName = `${first} ${last}`
  ```

### Style

- **Component naming** — PascalCase for components, camelCase for hooks (prefixed with `use`). Files should match their default/primary export name.

- **Hook extraction** — logic involving multiple `useState` + `useEffect` for the same concern should be extracted into a custom hook.

- **Conditional rendering clarity** — prefer early returns for invalid/loading states over deeply nested ternaries in JSX.
  ```tsx
  // Bad
  return (
    <div>
      {isLoading ? <Spinner /> : error ? <Error /> : data ? <Content data={data} /> : <Empty />}
    </div>
  )

  // Good
  if (isLoading) return <Spinner />
  if (error) return <Error error={error} />
  if (!data) return <Empty />
  return <Content data={data} />
  ```

- **Fragment abuse** — don't wrap in `<></>` when the parent already accepts children or when there's a single child.

### Component Libraries

This codebase uses several headless/primitive UI libraries. Review rules for using them correctly:

**General principle: use the library, don't fight it.**
- Prefer library primitives over custom implementations. If Radix has a Dialog, don't build one from scratch with divs and portals.
- Don't override accessibility defaults. Libraries like Radix ship with correct ARIA roles, focus management, and keyboard navigation. Removing or breaking these is a regression.
- Wrap library components in your own thin components for consistent styling — but don't add behavior the library already handles.

**Radix UI** (`@radix-ui/react-dialog`, `react-dropdown-menu`, `react-select`, `react-switch`, `react-tooltip`, `react-slot`):
- **Always use the `Portal` part for overlays** — Dialog.Portal, DropdownMenu.Portal, Tooltip.Portal. Without it, z-index and overflow clipping cause rendering bugs.
- **Don't suppress `onOpenChange`** — Radix manages open/close state internally. Fighting it (e.g., preventing close on overlay click without using the `modal` prop) causes focus trap and accessibility issues.
- **Use `Slot` for polymorphic components** — `asChild` pattern composes better than wrapper divs. Prefer `<Button asChild><Link /></Button>` over nesting.
- **Don't put interactive elements inside Tooltip triggers** — Tooltips are for non-interactive supplementary info. Use Popover for interactive content.
  ```tsx
  // Bad — button inside tooltip trigger
  <Tooltip.Trigger>
    <button onClick={doAction}>
      <InfoIcon />
    </button>
  </Tooltip.Trigger>

  // Good — tooltip on a non-interactive element, action is separate
  <Tooltip.Trigger asChild>
    <span><InfoIcon /></span>
  </Tooltip.Trigger>
  ```

**React Flow** (`@xyflow/react`):
- **Never mutate nodes/edges arrays directly** — React Flow relies on reference equality. Always create new arrays via `setNodes(nds => nds.map(...))`.
- **Use `useReactFlow()` inside `ReactFlowProvider`** — calling the hook outside the provider throws. Ensure the provider wraps any component using flow APIs.
- **Custom nodes must be memoized** — pass `nodeTypes` as a stable reference (module-level or useMemo). Defining nodeTypes inline causes remounts on every render.
- **Use `useNodesState` / `useEdgesState`** for managed state, or controlled mode with explicit `onNodesChange`/`onEdgesChange` handlers. Don't mix both.

**dnd-kit** (`@dnd-kit/core`, `@dnd-kit/sortable`):
- **Always provide a unique `id`** to draggable/sortable items. Using array indices breaks after reorder.
- **Use `useSortable` for sortable lists**, not raw `useDraggable` + `useDroppable` — it handles the coordination.
- **Don't forget `DndContext` sensors** — without sensors, drag only works with mouse. Add keyboard and pointer sensors for accessibility.

**CodeMirror 6** (`@uiw/react-codemirror`):
- **Don't create extensions inline** — extension arrays should be stable references (useMemo or module-level). Inline arrays cause the editor to fully reconfigure on every render.
- **Use `onChange` callback, not controlled `value` for frequent updates** — setting `value` on every keystroke causes cursor jumps and performance issues.

**cmdk** (command palette):
- **Filter function must be stable** — inline filter functions cause the list to re-render on every keystroke. Memoize or define at module level.
- **Use `Command.Empty`** for the no-results state — don't conditionally render the list.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| `dangerouslySetInnerHTML` with user data | Critical | Sanitize with DOMPurify or use JSX |
| Hook inside condition/loop | Critical | Move to top level of component |
| Missing useEffect cleanup (subscriptions/timers) | Warning | Return cleanup function |
| Missing dependency array entries | Warning | Add dependencies or restructure |
| State update on unmounted component | Warning | Use abort controller |
| Index as key on mutable lists | Warning | Use stable unique IDs |
| Direct state mutation | Warning | Create new references |
| Inline objects/functions as props (hot paths) | Warning | useMemo/useCallback |
| Context value not memoized | Warning | useMemo on provider value |
| Derived state instead of computed value | Suggestion | Compute in render |
| Prop drilling >2 levels | Suggestion | Context or composition |
| Nested ternaries in JSX | Nit | Early returns |
