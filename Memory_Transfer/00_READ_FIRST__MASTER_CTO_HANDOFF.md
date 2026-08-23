# RAWAEA ERP — MASTER CTO HANDOFF

## HANDOFF SNAPSHOT
- Snapshot UTC: **2026-08-23 03:41:38.004558 UTC**
- Production project: `fiilmooggumokxanwiyx` / SMART ERP
- PostgreSQL database: `postgres`
- Current Git branch: `main`
- Git HEAD at snapshot start: `579722996367998327fda7340408f1ad32ce955f`
- Current migration head: `20260822182733 fix_post_journal_entry_schema_drift_20260822`

## TRUTH HIERARCHY
1. Current Production runtime / PostgreSQL / deployed Edge / RPC / RLS / grants / data / logs.
2. Current Git `main`.
3. Current CTO / Evidence records.
4. Historical / Original / Git history.
5. Historical prompts and reports.

A historical CLOSED state never overrides a newer Production contradiction.

## CURRENT VERIFIED POSITION
- Public PostgreSQL functions: **45**.
- Public tables: **62**.
- RLS-enabled public tables: **62**.
- RLS policies: **102**.
- Public triggers: **38**.
- Companies: 3; users: 26; branches: 5; items: 50.
- `stock_branches`: 26.
- `inventory_log`: **3**.
- `stock_vouchers`: 0; `stock_voucher_details`: 0.
- `orders`: 0; `order_details`: 0.
- `runsheets`: 0; `run_sheet_details`: 0.
- `purchase_orders`: 0; `purchase_order_details`: 0.
- `journal_entries`: 2; `journal_lines`: 0.
- `audit_log`: 1781.
- customer/supplier/driver ledgers: 0 rows each.

## INVENTORY CORE
The current direct SQL sweep finds only one function performing the Physical Stock contract:

`post_stock_movement(10 args)`
→ `stock_branches` physical qty
→ `inventory_log`.

`reserve_stock` / `release_stock_reservation` mutate `allocated_qty` only.
`setup_van_stock` is an initialization capability.
No public trigger directly writes Physical Stock or `inventory_log`.

**Current inventory conclusion:** Physical Writer Centralization = VERIFIED for the currently deployed Production surface.

## CURRENT EDGE REALITY
Critical deployed versions now include:
- `start-picking` v33 ACTIVE.
- `complete-picking` v16 ACTIVE.
- `complete-loading` v11 ACTIVE.
- `complete-return` v24 ACTIVE.
- `create-stock-voucher` v8 ACTIVE.
- `send-stock-voucher` v19 ACTIVE.
- `receive-stock-voucher` v21 ACTIVE.
- `complete-stock-voucher` v4 ACTIVE.
- `cancel-stock-voucher` v4 ACTIVE.
- `receive-purchase` v12 ACTIVE.
- `save-sales-invoice` v15 ACTIVE.
- `save-journal-entry` v8 ACTIVE.
- `save-receipt-voucher` v5 ACTIVE.
- `save-payment-voucher` v3 ACTIVE.
- `save-daily-settlement` v3 ACTIVE.
- `update-driver-ledger` v1 ACTIVE.
- `complete-order-delivery` v13 ACTIVE.

The registry still contains temporary/canary/runtime-harness functions. Several were observed returning HTTP 410 while remaining registered ACTIVE. `ACTIVE + 410` is not equivalent to deletion and remains governance debt.

## START-PICKING PARITY — CORRECTED
The older Memory Transfer package recorded Production `start-picking` v14 as using `public.users.id = auth.users.id`. That statement is obsolete.

Current Production `start-picking` v33 and current Git `Current/Edge_Functions/start-picking` both resolve the authenticated user through:

`auth.users.id → public.users.auth_id → public.users.id → company_id`.

The previous parity conflict is therefore **RESOLVED by newer evidence** and must not be inherited by the successor CTO.

## ACCOUNTING / FINANCIAL STATE
Accounting is active but not centrally converged. Current financial writers include journal/ledger effects from domain RPCs and dedicated Edge capabilities such as receipt, payment, daily settlement and driver ledger paths.

Current `save-journal-entry` v8 + `post_journal_entry` are strong core contracts, but Journal Writer Convergence is not globally closed. Treasury→COA identity remains an explicit contract boundary; do not invent a mapping.

## CURRENT OPEN DOMAINS
- Accounting writer convergence.
- Ledger writer authority and reconciliation.
- Treasury / Daily Settlement contract graph.
- Full fulfillment state/consumer graph.
- Full critical Consumer Matrix.
- Deployment lineage (Git SHA → deployed Edge version → runtime consumer).
- ERP-wide data repair/provenance registry.
- Independent-session concurrency proof for remaining high-risk transitions.
- Browser/client runtime proof.
- Temporary Edge/canary registry retirement.
- Global Zero-Debt outside the verified Physical Stock writer boundary.

## FIRST 10 CHECKS FOR THE SUCCESSOR CTO
1. `select now(), version();`
2. Recount critical tables and compare with this snapshot.
3. List deployed Edge Functions and versions.
4. Re-read critical deployed RPC definitions.
5. Rescan Physical Stock writers.
6. Rescan reservation writers separately.
7. Read the current source for the active Closure Unit.
8. Read the Historical/Original source for the same unit.
9. Read every current consumer of the unit.
10. Compare the new snapshot with this handoff and register drift before acting.

## OPERATING RULE
UNDERSTAND → RECONSTRUCT → TRACE → RECONCILE → PATCH ONE CLOSURE UNIT → TEST → DEPLOY → PRODUCTION VERIFY → CLOSE.

**Memory is context. Production is truth.**