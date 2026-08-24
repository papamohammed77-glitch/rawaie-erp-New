# Operations Agent Runtime Contract

This is the execution boundary between the 5-minute GitHub scheduler and the external CTO agent runtime.

## Required GitHub Actions secrets

- `AGENT_RUNTIME_URL` — HTTPS endpoint that accepts `POST` operations tasks.
- `AGENT_RUNTIME_TOKEN` — bearer token for that endpoint.

## Request

```json
{
  "type": "operations_task",
  "task": {
    "message_id": "OPS-...",
    "task_id": "OPS-...",
    "owner": "Medhat|Khalid|Hytham",
    "status": "NEW",
    "created_at": "...",
    "source_file": "doc/Draft/Operations_Team/...",
    "source_commit": "...",
    "reply_file": null,
    "dispatch_attempts": 0
  }
}
```

The runtime is expected to acknowledge an accepted task with any 2xx response. It must then execute the mission outside GitHub Actions and write the required execution report back to `doc/Draft/Operations_Team/` using the team protocol.

## Non-negotiable semantics

- A scheduler poll is not an execution claim.
- A task is dispatched once per `task_id`; source-file/commit identity prevents duplicate dispatches.
- CLOSED and SUPERSEDED tasks are never re-dispatched.
- A failed/unconfigured runtime leaves the task in `WAITING_FOR_EXECUTION`.
- The control ledger is the source of truth for task state, owner, timestamps, source commit, and dispatch result.

## Runtime responsibility

The external agent runtime must provide the actual agent invocation. GitHub Actions is the control-plane scheduler and durable queue/ledger, not the AI agent itself.
