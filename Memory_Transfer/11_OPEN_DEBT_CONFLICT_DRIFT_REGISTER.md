# OPEN DEBT / CONFLICT / DRIFT REGISTER

## CONFlict / drift items

### DRIFT-001 — Public PostgreSQL function count
- Older readiness snapshot 2026-08-21: 42 public functions.
- Direct Production revalidation 2026-08-23: 45 public functions.
- Classification: CONFLICT/DRIFT between snapshots.
- Action: re-baseline function inventory before next major phase.

### DRIFT-002 — Inventory log row count
- 2026-08-20 closure snapshot: 56 rows.
- 2026-08-21 readiness snapshot: 62 rows.
- 2026-08-23 direct Production query: 3 rows.
- Classification: MATERIAL SNAPSHOT DRIFT.
- Action: trace provenance/cleanup/deployment-test effects; do not infer deletion or corruption from counts alone.

### CONFLICT-003 — Current Git vs Production `start-picking`
- Production v14 uses `public.users.id = auth.users.id` and derives `company_id` from that record.
- Current Git main `Current/Edge_Functions/start-picking` uses `public.users.auth_id = auth.users.id`.
- Classification: CURRENT SOURCE / PRODUCTION PARITY CONFLICT.
- Action: reconcile against actual schema contract and update Current to the accepted deployed lineage only after comparison.

### GOVERNANCE-004 — Temporary Edge registry residue
Production registry still includes temporary/canary functions. `ACTIVE` with an inert/410 implementation is not equivalent to deletion. Exact deletion evidence is still required.

### GOVERNANCE-005 — PR #3
PR #3 remains Draft/Open/Unmerged; it is not a Production source of truth and its gate text is historical until re-baselined.

### STALE-006 — Older plan files
`CTO/PLAN-STATUS-CURRENT.md`, older Master Execution logs, and older CTO reconstruction documents contain earlier task positions. They must be treated as historical snapshots when contradicted by newer Production evidence/current closure records.

## OPEN DOMAIN DEBT
- Accounting journal authority and writer convergence.
- Customer/supplier/driver ledger writer mapping and reconciliation.
- Treasury/settlement event graph.
- Full fulfillment state/consumer graph.
- Full critical consumer map and runtime parity.
- Full deployment lineage map.
- ERP-wide data repair/provenance register.
- Required independent-session concurrency proof outside already-proven paths.
- Gold UI parity for vouchers/van sales and remaining critical clients.
- ERP-wide autonomous CTO readiness.

## STATUS RULE
An item remains OPEN until direct evidence proves closure. Historical or target documents may describe intended closure, but do not override current Production truth.
