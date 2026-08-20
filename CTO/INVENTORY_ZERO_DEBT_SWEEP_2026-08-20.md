# RAWAEA ERP — GLOBAL INVENTORY ZERO-DEBT CORE INTEGRITY SWEEP

Date: 2026-08-20
Production project: `fiilmooggumokxanwiyx` (SMART ERP)
Scope: Physical Inventory / Manual Voucher / Purchase Receive / Sales / Return / Delivery / Loading-Unloading boundaries

## 1. Governing authority

Executed under:
- `doc/Draft/medhat/تقرير مبادئ حاكمة`
- `doc/Draft/medhat/برومبت استكمال مهام`

The governing sequence was enforced:
UNDERSTAND → HISTORICAL CONTRACT → CURRENT PRODUCTION → DATA/AUTH FLOW → TARGET → ACTUAL GAP → SURGICAL CHANGE → TEST → PRODUCTION VERIFY → CLOSE.

## 2. Production truth

Production PostgreSQL was queried directly before closure.

Confirmed:
- `post_stock_movement` is the only function that directly mutates physical `stock_branches.qty` and writes `inventory_log`.
- `reserve_stock` / `release_stock_reservation` mutate reservation state (`allocated_qty`) only and are not Physical Stock Movement engines.
- `setup_van_stock` only initializes zero-balance stock rows; it does not post physical movement.
- No database trigger mutates `stock_branches` or writes `inventory_log`.

## 3. Global writer discovery

All public functions whose deployed definitions reference `stock_branches` / `inventory_log` were inspected.

Physical Writers outside `post_stock_movement`: **0**.

Adapters/wrappers found:
- `send_stock_voucher_atomic` → `post_stock_movement`
- `receive_purchase_atomic` → `post_stock_movement`
- `post_inventory_adjustment_atomic` → `post_stock_movement`
- `save_sales_invoice_atomic` → `post_stock_movement`
- `complete_return_atomic` → `post_stock_movement`
- `post_manual_stock_voucher_atomic` → `post_stock_movement`
- `send_manual_stock_voucher_v2` → `post_stock_movement` (legacy)
- `receive_manual_stock_voucher_v2` → `post_stock_movement` (legacy)
- `complete_runsheet_loading` → `post_stock_movement`
- `complete_runsheet_reopen_loading` → `post_stock_movement`
- `complete_runsheet_unloading` → `post_stock_movement`

No parallel Physical Stock Engine was found.

## 4. Important identity finding

`items.item_code` is globally UNIQUE in Production schema.
`stock_branches` identity is `(branch_id,item_id)`.
`post_stock_movement` explicitly treats Item Master identity as global and `item_id` as the authoritative item reference.

Therefore the previously observed rows where `stock_branches.branch` belonged to one company while `items.company_id` carried another value are **not automatically data corruption**. They are valid under the deployed global Item Master model and were not deleted.

This was a deliberate governance decision: no data repair was performed merely because a legacy `items.company_id` value differed from the branch company context.

## 5. Manual Voucher CREATE closure

### Gap proven
Current Production `create-stock-voucher` had to converge on the canonical Manual Voucher RPC instead of retaining application-owned voucher construction.

### Production change
`create-stock-voucher` now:
- derives `company_id` from authenticated user context;
- validates item payload shape;
- calls `create_manual_stock_voucher_atomic`;
- does not write `stock_vouchers` / `stock_voucher_details` directly.

The canonical CREATE RPC was also corrected to remove the unsafe global `app_settings LIMIT 1` dependency for company validation and to honor the global Item Master identity.

### Verification
A transactional Production test successfully created a Manual Voucher for company `da4e...` using global item `1001`, whose legacy `items.company_id` differs from that branch company. The transaction was rolled back and left no residue.

Status: **CLOSED**.

## 6. Manual Voucher legacy V2 closure

Production current Edges use canonical paths:
- `send-stock-voucher` → `send_stock_voucher_atomic`
- `receive-stock-voucher` → `post_manual_stock_voucher_atomic`

Legacy V2 RPC EXECUTE privileges were revoked for:
- `send_manual_stock_voucher_v2`
- `receive_manual_stock_voucher_v2`

Only the `postgres` owner remains capable of direct administrative invocation.

Status: **CLOSED / GOVERNANCE RESIDUE REMOVED**.

## 7. Purchase Receive idempotency

Production `receive_purchase_atomic` now requires a UUID operation identity and checks the persisted `receiving.operation_id` before attempting another quantity validation or physical posting.

Replay behavior is governed by:
- same operation identity + same payload → `duplicate=true`
- same operation identity + different company/PO/payload → hard conflict
- new operation identity → normal processing

PWA `Current/PWA/main.html` already sends `operation_id: crypto.randomUUID()` per receive action.
The deployed Edge Function passes that identity into the RPC.

Status: **CLOSED**.

## 8. Stock integrity / data repair

Current Production snapshot:
- stock rows: 23
- inventory log rows: 56
- manual vouchers: 0
- processing operation-registry rows: 0
- `available_qty` mismatches: 0
- negative `qty`: 0
- negative `allocated_qty`: 0
- `allocated_qty > qty`: 0

No blind data deletion or reclassification was performed.

## 9. Runtime verification

Controlled Production transaction:
- CREATE Manual Voucher
- TransferOut quantity 1
- TransferIn quantity 1
- repeated TransferIn with same idempotency key
- inventory_log count remained 2 rather than 3
- transaction rolled back
- post-rollback residue for test key: 0

Independent GitHub Production HTTP E2E evidence:
- workflow run `32214977470`
- conclusion: success
- `Verify current PWA operation identity`: success
- `Production HTTP E2E`: success

## 10. Responsibility matrix

| Responsibility | Historical/Legacy | Current Production | Target | Result |
|---|---|---|---|---|
| Physical stock mutation | Distributed/legacy | `post_stock_movement` only | `post_stock_movement` only | CLOSED |
| Inventory log | Distributed/legacy | `post_stock_movement` only | Central history | CLOSED |
| Reservation | Mixed | `reserve_stock` / `release_stock_reservation` | Separate reservation engine | CLOSED |
| Manual Voucher CREATE | Edge-owned/direct | canonical RPC | canonical RPC | CLOSED |
| SEND | legacy wrappers | canonical SEND → core | core | CLOSED |
| RECEIVE Purchase | operation identity gap | explicit UUID + persisted receiving identity | deterministic operation contract | CLOSED |
| Return | old direct writer | atomic RPC → core | atomic RPC → core | CLOSED |
| Delivery state | fulfillment state | `order_details` authoritative, runsheet derived | same | CLOSED |
| Company isolation | historical drift | authenticated user / company-scoped lookups in inspected paths | company-scoped | CLOSED for swept paths |
| Item identity | mixed legacy metadata | global `item_code`, authoritative `item_id` | global Item Master | CLOSED |
| Idempotency | incomplete | core/event operation identities | explicit replay contract | CLOSED for swept paths |

## 11. Self-audit

### What was proved
- Production Physical Writers outside `post_stock_movement` = **0**.
- `stock_branches` / `inventory_log` are not mutated by triggers.
- Legacy V2 execution capability was closed.
- Manual Voucher CREATE is canonicalized.
- Purchase Receive operation identity is persisted and replay-safe.
- Physical stock health checks are clean.
- Current Git PWA carries receive operation identity.
- Production HTTP E2E gate passed.

### What was initially misunderstood and corrected
The cross-company `items.company_id` mismatches were initially treated as possible stock corruption. Production schema proved `items.item_code` is globally UNIQUE and `post_stock_movement` explicitly uses global Item Master semantics. Those rows were therefore preserved.

### What remains outside this closure
- Non-inventory accounting/ledger architecture remains a separate domain.
- Picker workflow may continue after this closure.
- Legacy administrative functions that do not mutate physical stock are outside the Physical Writer zero-debt gate.

### Unknown / conflict status
No material Unknown or Conflict remains inside the Physical Inventory Writer closure defined by this sweep.

## 12. Final Production snapshot

Authoritative final snapshot executed after all Production changes and immediately before closure reporting:
- PostgreSQL `now()`: **2026-08-20 00:00:39.599996+00**
- stock rows: **23**
- inventory log rows: **56**
- `available_qty` mismatches: **0**
- stock violations (`qty<0`, `allocated_qty<0`, `allocated_qty>qty`): **0**
- `post_stock_movement` overloads: **2** (9-arg compatibility wrapper + 10-arg keyed engine)

## 13. Final gate

`GLOBAL INVENTORY CORE INTEGRITY = 100% CLOSED`

Physical Writers outside `post_stock_movement` = **0**.
