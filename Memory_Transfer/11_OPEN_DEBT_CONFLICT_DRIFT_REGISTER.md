# OPEN DEBT / CONFLICT / DRIFT REGISTER

## DRIFT-001 — PostgreSQL public function count
- 2026-08-21 baseline: 42.
- 2026-08-23 03:41:38 UTC direct Production: 45.
- Classification: MATERIAL SNAPSHOT DRIFT.
- Action: current function inventory is authoritative; trace additions by migration/deployment before retiring anything.

## DRIFT-002 — inventory_log count
- 2026-08-20 snapshot: 56.
- 2026-08-21 snapshot: 62.
- 2026-08-23 direct Production: 3.
- Classification: MATERIAL DATA SNAPSHOT DRIFT.
- Rule: do not infer deletion/corruption without provenance.

## RESOLVED-003 — start-picking identity parity
- Older handoff claimed Production v14 used `public.users.id = auth.users.id`.
- Current Production v33 uses `.eq('auth_id', user.id)`.
- Current Git `Current/Edge_Functions/start-picking` also uses `.eq('auth_id', user.id)`.
- Classification: RESOLVED by newer evidence.
- The old statement remains historical only.

## GOVERNANCE-004 — Temporary Edge registry residue
Production registry contains temporary/canary/harness functions. Several were observed returning HTTP 410 while remaining ACTIVE.
- Classification: OPEN GOVERNANCE DEBT.
- Action: explicit deletion/retirement evidence required.

## GOVERNANCE-005 — PR #3
PR #3 remains Draft/Open/Unmerged and is not a Production source of truth.

## OPEN-006 — Accounting writer convergence
Multiple current domain and Edge functions can create financial effects. Central journal Core exists but global authority is not closed.

## OPEN-007 — Ledger authority/reconciliation
Customer/Supplier/Driver ledger writers are distributed; no single universal ledger posting authority has been proven.

## OPEN-008 — Treasury↔COA contract
Treasury identity such as `CASH-01` does not have a proven universal mapping to journal `account_id` UUID. No mapping invented.

## OPEN-009 — Financial security Production rollout
Staging direct-write restrictions were proven in prior work. Production rollout remains gated by consumer/runtime proof.

## OPEN-010 — Consumer Matrix
Not every current PWA/Edge consumer has a verified Git SHA → deployed version → runtime contract mapping.

## OPEN-011 — Deployment Lineage
Current Edge registry versions are known, but complete per-function Git source SHA/deployment lineage is not fully indexed.

## OPEN-012 — Browser Runtime
Critical PWA browser/service-worker E2E remains unproven from the current execution environment.

## OPEN-013 — Concurrency
Independent-session concurrency proof is incomplete outside already-tested transactional paths.

## OPEN-014 — Data provenance registry
Historical inventory-log and other cleanup deltas require full provenance chain before any claim of corruption/cleanup correctness.

## OPEN-015 — Supplier↔Branch master contract
Live schema does not prove a permanent `suppliers.branch_id` contract. Do not invent one.

## OPEN-016 — Fulfillment lifecycle graph
Complete state-machine interactions across order → runsheet → loading → delivery → return → unload → settlement remain partially mapped.

## STATUS RULE
Nothing becomes CLOSED because a report says so. Closure requires current evidence appropriate to the contract: Production, Git parity, runtime, security and responsibility preservation as applicable.