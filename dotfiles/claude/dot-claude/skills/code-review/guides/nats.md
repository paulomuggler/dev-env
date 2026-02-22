# NATS Review Guide

## Metadata
- **Type:** infrastructure
- **Extensions:** .ts (NATS client code)
- **Updated:** 2026-02-21

## Categories

### Security

- **Authentication** — production NATS servers should require authentication (token, user/pass, or NKey). Don't rely on network isolation alone. Even in development, unauthenticated NATS servers exposed on `0.0.0.0` are a risk.

- **Authorization and subject permissions** — NATS supports per-user publish/subscribe permissions on subjects. Don't give every service full access to every subject. Scope permissions to what each service actually needs.

- **Don't put secrets in message payloads without encryption** — NATS messages are plaintext in transit by default. Use TLS for transport encryption. For sensitive payloads, consider application-level encryption.

- **Subject injection** — if subject names are constructed from user input, validate the input. NATS subjects use `.` as a separator and `*`/`>` as wildcards — unsanitized input can subscribe to unintended subjects.
  ```typescript
  // Bad — user input in subject
  nc.publish(`tasks.${userInput}.status`, data)

  // Good — validate input
  if (!/^[a-zA-Z0-9_-]+$/.test(projectId)) throw new Error('Invalid project ID')
  nc.publish(`tasks.${projectId}.status`, data)
  ```

### Correctness

- **Message acknowledgment in JetStream** — always acknowledge messages after successful processing. Failing to ack causes redelivery, which can cause duplicate processing. Ack AFTER the work is done, not before.
  ```typescript
  // Bad — ack before processing (message lost if processing fails)
  msg.ack()
  await processMessage(msg.data)

  // Good — ack after success
  try {
    await processMessage(msg.data)
    msg.ack()
  } catch (err) {
    msg.nak()  // or msg.term() if unrecoverable
  }
  ```

- **`ack()` vs `nak()` vs `term()`** — understand the semantics:
  - `ack()` — processed successfully, remove from stream
  - `nak()` — processing failed, redeliver after delay
  - `term()` — processing failed permanently, don't redeliver
  - `inProgress()` — extend the ack wait deadline, still processing

  Using `ack()` on failure silently drops messages. Using `nak()` on unrecoverable errors causes infinite redelivery.

- **Consumer configuration — durable vs ephemeral** — durable consumers survive restarts and maintain their position. Ephemeral consumers are lost on disconnect. Use durable consumers for anything that must not miss messages.
  ```typescript
  // Durable — survives restarts
  const consumer = await js.consumers.get(stream, 'my-durable-consumer')

  // Ephemeral — lost on disconnect (OK for live dashboards, bad for task queues)
  const consumer = await js.consumers.get(stream)
  ```

- **Subject naming conventions** — use hierarchical dot-separated subjects (`project.{id}.task.created`). Don't use flat names (`projectTaskCreated`) — you lose the ability to use wildcard subscriptions.
  ```typescript
  // Bad — flat, no wildcard capability
  nc.publish('projectTaskCreated', data)

  // Good — hierarchical, can subscribe to project.*.task.*
  nc.publish(`project.${projectId}.task.created`, data)
  ```

- **Message ordering** — NATS JetStream preserves per-subject ordering, but only within a single subject. If you need ordering across related messages, put them on the same subject. Consumers with `max_ack_pending > 1` can receive out of order — use `max_ack_pending: 1` for strict ordering.

- **Payload serialization** — NATS transports bytes. Always serialize (JSON, protobuf) and deserialize explicitly. Don't assume the payload is a string.
  ```typescript
  // Publishing
  nc.publish(subject, JSON.stringify(payload))

  // Consuming
  const data = JSON.parse(new TextDecoder().decode(msg.data))
  ```

- **Stream retention policies** — `limits` (max age/count/bytes), `interest` (deleted when all consumers ack), `workqueue` (deleted after one consumer acks). Choose based on use case:
  - Event log → `limits` with appropriate max age
  - Task queue → `workqueue`
  - Pub/sub with persistence → `interest`

### Performance

- **Batch publishing** — if publishing many messages in sequence, the NATS client may buffer them. Flush periodically or after a batch to ensure delivery.
  ```typescript
  for (const event of events) {
    nc.publish(subject, JSON.stringify(event))
  }
  await nc.flush()
  ```

- **Subscriber backpressure** — a slow consumer holds up message delivery. Use `max_ack_pending` to control concurrency, and process messages asynchronously if the handler is slow.

- **Payload size** — NATS default max message size is 1MB. Large payloads (files, images) should use object store or external storage with a reference in the message. Don't increase `max_payload` without good reason.

- **Connection reuse** — don't create a new NATS connection per request. Create one connection at startup and reuse it. Connection establishment has overhead (TLS handshake, auth).

- **Unnecessary stream reads** — don't poll JetStream for new messages. Use push-based consumers or `consume()` / `fetch()` iterators which use server-side push.

### Error Handling

- **Connection error and reconnect** — NATS clients auto-reconnect by default, but your code must handle the reconnection period. Buffer or fail gracefully during disconnection.
  ```typescript
  nc.on('disconnect', () => logger.warn('NATS disconnected'))
  nc.on('reconnect', () => logger.info('NATS reconnected'))
  nc.on('error', (err) => logger.error('NATS error', { error: err }))
  ```

- **Subscription errors** — subscribe callbacks that throw don't crash the process, but the message is effectively lost. Always try/catch inside subscription handlers.
  ```typescript
  // Bad — error crashes nothing but message is lost
  sub.callback = (err, msg) => {
    const data = JSON.parse(msg.data)  // throws on invalid JSON
    processData(data)
  }

  // Good
  sub.callback = (err, msg) => {
    try {
      const data = JSON.parse(new TextDecoder().decode(msg.data))
      processData(data)
    } catch (e) {
      logger.error('Failed to process message', { error: e, subject: msg.subject })
      msg.term()  // don't redeliver malformed messages
    }
  }
  ```

- **Drain on shutdown** — call `nc.drain()` before process exit to flush pending messages and cleanly unsubscribe. Don't just close the connection.
  ```typescript
  process.on('SIGTERM', async () => {
    await nc.drain()
    process.exit(0)
  })
  ```

- **Dead letter handling** — messages that fail processing after max redelivery attempts need a dead letter strategy. Don't let them cycle forever. Use `max_deliver` on the consumer config and monitor for advisory messages.

### Code Quality

- **Hardcoded subject strings** — define subjects as constants or build them from typed templates. Typos in subject strings cause silent message loss.
  ```typescript
  // Bad — typo goes unnoticed
  nc.publish('taks.created', data)

  // Good
  const SUBJECTS = {
    taskCreated: (projectId: string) => `project.${projectId}.task.created`,
  } as const
  nc.publish(SUBJECTS.taskCreated(projectId), data)
  ```

- **Missing type safety on payloads** — define TypeScript interfaces for message payloads and validate on consumption.

- **Tight coupling to NATS in business logic** — business logic should publish/consume through an abstraction (event bus interface), not call NATS directly. This enables testing and swapping transports.

### Comment Hygiene

- **Stale subject names in comments** — subject naming evolves. Comments referencing old subject patterns mislead.
- **TODO comments about consumer configuration** — configure correctly now, don't leave it for later.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| Ack before processing | Critical | Ack after successful processing |
| `ack()` on unrecoverable failure | Critical | Use `term()` for permanent failures |
| Subject injection from user input | Critical | Validate input pattern |
| No error handling in subscription callbacks | Warning | Try/catch with logging |
| Ephemeral consumer for critical messages | Warning | Use durable consumers |
| New connection per request | Warning | Reuse connection |
| No drain on shutdown | Warning | `nc.drain()` on SIGTERM |
| Hardcoded subject strings without constants | Warning | Centralize subject definitions |
| Large payloads in messages (>100KB) | Warning | Use object store or external storage |
| No dead letter strategy | Suggestion | Configure max_deliver, monitor advisories |
| Missing payload validation on consume | Suggestion | Schema validation (Zod) |
| Flat subject naming | Nit | Use hierarchical dot-separated subjects |
