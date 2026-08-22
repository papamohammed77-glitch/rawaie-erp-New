# RAWAEA ERP — Parallel Execution Plan
## Khalid + Hytham | 2026-08-22

### Governing Rule
Production is the current runtime truth. Git is the canonical change record. Historical reports are evidence/navigation only. No Owner Decision is to be fabricated.

### Global Mission
Move RAWAEA ERP from forensic qualification into controlled Production-grade closure while preserving the Inventory rescue as a regression foundation, not as the only project objective.

---

# TRACK A — KHALID
## Role: Continuity / Architecture / Governance / Financial Security

### A1 — Accounting Contract Authority
- Freeze and document the proven financial contract boundaries.
- Resolve only evidence-backed contract gaps that do not require Owner policy decisions.
- Maintain a decision register for: Treasury→COA mapping, VoidInvoice semantics, payment/receipt account semantics, settlement recognition, driver-ledger ownership, dates, reversal policy.

### A2 — Treasury / COA Contract
- Inventory current Production treasury identities and COA identities.
- Do not map by code unless the target UUID identity is proven.
- Produce a canonical mapping contract or explicitly mark Owner Decision where required.

### A3 — Consumer Matrix
For every financial writer:
- PWA consumer
- Edge Function
- RPC/Core dependency
- expected auth/company context
- operation identity
- failure/retry behavior
- current Production version
- Git source
- target replacement path

### A4 — Financial Security Closure
- Keep Staging direct-write boundary active as the safety reference.
- After consumer coverage is proven, apply the equivalent Production capability boundary.
- Verify RLS policy semantics after the write-capability change.

### A5 — Deployment Lineage
- Maintain Writer → Git artifact → deployed Edge version → DB function dependency → PWA consumer lineage.
- No artifact is considered closed without Production runtime evidence.

### Khalid Exit Gate
- Accounting contract documented
- Treasury/COA dependency closed or explicitly Owner-gated
- Consumer Matrix complete
- Security rollout proven
- Deployment lineage proven

---

# TRACK B — HYTHAM
## Role: Core Engines / Writer Convergence / Runtime

### B1 — Canonical Accounting Core
- `post_journal_entry` is the authoritative journal posting boundary.
- Preserve balanced-posting, company, account identity, operation-id, audit and idempotency invariants already proven.

### B2 — Atomic Receipt Core
- Build the replacement path for `save-receipt-voucher` only after account semantics are proven.
- Atomicity covers voucher/treasury/journal/driver effects.
- Operation identity must be explicit and retry-safe.

### B3 — Atomic Payment Core
- Same closure pattern as receipt.
- No direct journal DML in the Edge wrapper after migration.

### B4 — Daily Settlement Core
- Make settlement one transactional business event.
- Keep operational settlement state, liability settlement, journal posting and runsheet closure consistent.
- Do not invent accounting mapping for driver liability accounts.

### B5 — Driver Ledger Core
- Convert direct `driver_ledger` writes into an owned core capability.
- Define whether it is an accounting projection or an operational ledger before replacing consumers.

### B6 — Writer Convergence
Priority order:
1. save-receipt-voucher
2. save-payment-voucher
3. update-driver-ledger
4. save-daily-settlement
5. save-sales-invoice
6. receive-purchase
7. complete-return

Each writer is a closure unit:
FOUND → CONTRACT → SURGICAL CHANGE → STAGING/transactional proof → PRODUCTION DEPLOY → RUNTIME VERIFY → CLOSE

### B7 — Financial Concurrency
- Independent-session retry and conflict tests after all canonical cores are stable.

### Hytham Exit Gate
- All required writers converge on canonical cores
- No direct journal/ledger writer remains outside the owning core
- Runtime E2E verified
- Concurrency verified
- Data reconciliation completed

---

# PARALLELIZATION RULE
Khalid may advance independently on contract/security/consumer evidence while Hytham implements only evidence-backed cores. A task is parallel-safe only when it does not depend on an unresolved Owner Decision.

# INVENTORY RULE
Inventory remains frozen as a regression foundation. No unrelated Inventory redesign is to be introduced during Accounting/Ledger closure. Any Production change to Inventory reopens the relevant regression gate.

# FINAL GLOBAL GATE
GLOBAL ZERO-DEBT = CLOSED only when:
- all financial writers are discovered;
- all required writers are converged;
- no parallel financial engine remains;
- tenant and account identity are enforced;
- Current Git and Production versions align;
- Production runtime evidence exists;
- remaining Owner Decisions are explicitly recorded, not guessed;
- data repair/reconciliation is complete.
