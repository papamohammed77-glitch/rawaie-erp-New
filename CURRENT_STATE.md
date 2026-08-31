# RAWAEA ERP — CURRENT STATE PACK

> Single operational entry point. This is a state record, not a report. Current Git/Production evidence outranks historical material.

## STATE ID
- State Type: CURRENT PROJECT STATE
- State Status: CURRENT
- Date: 2026-08-31
- Rule: Every real Git/Production/deployment/artifact change must be verified and recorded here before the next authorized action.

# CURRENT GIT STATE
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Branch: `main`
- Last functional artifact commit before this state record: `4ff020857fffb6e7243f299d9fd50c86e116e153`
- Artifact: `Current/PWA/New-main`
- Legacy runtime file: `Current/PWA/main.html` was NOT modified by the reconstruction event.
- Repository subsequently received this state-record commit; it is administrative and does not alter the New-main artifact.

# CURRENT PRODUCTION SNAPSHOT
Verified directly from Production at `2026-08-31T06:30:22.720848+00:00`:

| Entity / invariant | Value |
|---|---:|
| companies | 1 |
| users | 24 |
| branches | 2 |
| items | 17 |
| stock_branches | 20 |
| inventory_log | 3 |
| stock_vouchers | 0 |
| purchase_orders | 0 |
| orders | 0 |
| runsheets | 0 |
| audit_log | 1866 |
| negative physical qty | 0 |
| negative allocated qty | 0 |
| available_qty mismatches | 0 |
| cross-company stock rows | 0 |
| cross-company inventory-log rows | 0 |
| duplicate item_code values | 0 |

Direct Production schema facts:
- `items.item_code` is database-wide UNIQUE.
- `stock_branches(branch_id,item_id)` is UNIQUE.
- `receiving.operation_id` is UNIQUE.
- `post_stock_movement` exists in 9-argument and 10-argument idempotency-aware overloads.
- `reserve_stock` / `release_stock_reservation` exist as reservation capabilities.
- `receive_purchase_atomic` currently requires `p_operation_id uuid` and implements receiving idempotency through `receiving.operation_id`.

# CURRENT ACTIVE EDGE DEPLOYMENTS
Directly verified from the active Production function list during this execution:
- `create-stock-voucher` ACTIVE v9
- `send-stock-voucher` ACTIVE v19
- `receive-stock-voucher` ACTIVE v21
- `receive-purchase` ACTIVE v12
- `save-sales-invoice` ACTIVE v15
- `complete-return` ACTIVE v25
- `complete-order-delivery` ACTIVE v14
- `bulk-stock-adjustment` ACTIVE v6
- `complete-picking` ACTIVE v16
- `start-picking` ACTIVE v33
- `complete-loading` ACTIVE v11
- `unload-runsheet` ACTIVE v6

Current Git `receive-purchase` is aligned with Production v12: it resolves company through `users.auth_id` and supplies a deterministic/requested `operation_id` to `receive_purchase_atomic`.

# CURRENT MAIN.HTML
- Existing runtime file: `Current/PWA/main.html`
- Existing blob SHA before this reconstruction: `e81ae6fe3e0e473b98927ff5cb2d54ba6ef18d8d`
- Status: EXISTING / NOT FINAL
- It was NOT edited during the New-main clean-room event.

# NEW MAIN CLEAN-ROOM ARTIFACT
- Path: `Current/PWA/New-main`
- Creation commit: `4ff020857fffb6e7243f299d9fd50c86e116e153`
- Purpose: independent clean-room candidate, manually authored from current verified contracts.
- Historical `main1..main11` fragments were inspected as current repository evidence, but were NOT concatenated by the historical reconstruction script and `Current/PWA/main.html` was NOT replaced.

Current New-main contract characteristics verified by source inspection:
- Authenticated identity is resolved through `users.auth_id` to `users.company_id`.
- OWNER semantics preserve `isOwner` plus wildcard permission behavior rather than expanding wildcard to an arbitrary list.
- Operational reads are company-scoped where company identity applies.
- Physical stock is read-only in New-main; there is no direct writer for `stock_branches.qty` or `inventory_log`.
- Physical stock authority remains `post_stock_movement` in Backend.
- Reservation authority remains `reserve_stock` / `release_stock_reservation`.
- Business writes are delegated to Edge capabilities such as `save-sales-invoice`.
- Specialized current PWA capabilities are linked rather than reimplemented: Picker, Van Sales, Vouchers, Returns.
- Responsive shell, navigation, dashboard, inventory read view, reporting read view, HR/CRM/settings shells are present.

# REQUIRED PARITY STATUS
`New-main CREATED = VERIFIED`
`Current main.html MODIFIED = NO`
`Structural parity = NOT YET FULLY VERIFIED`
`Functional parity = OPEN`
`Runtime/browser verification = OPEN`
`Production runtime verification of New-main itself = OPEN`
`Final replacement of main.html = NOT AUTHORIZED`

# IMPORTANT CURRENT FINDINGS
1. The repository moved materially after the previous CURRENT_STATE snapshot. Latest Git functional artifact before this state record is `4ff02085…`.
2. Production Edge versions are newer than the stale snapshot previously recorded in CURRENT_STATE; the current list is the authority.
3. Production is currently clean on the verified inventory invariants above.
4. `receive_purchase_atomic` and its Edge consumer now agree on explicit operation identity in both current Git and Production.
5. The historical clean-room automation script in Git is NOT the execution authority for this task because the owner explicitly requires a separate manually-built `Current/PWA/New-main` and forbids using the existing `main.html` as the repair target.

# KNOWN CURRENT CONTRACTS
## Governance
- CURRENT_STATE is the operational entry point.
- LAST VERIFIED EVENT is the only recency marker.
- Historical reports/prompts are context evidence, not current truth.

## Identity
`authenticated user -> users.auth_id -> users.company_id -> company-scoped data`

No unscoped `app_settings LIMIT 1` may determine tenant identity.

## OWNER
`isOwner=true + permissions=["*"] + owner_profile + active license state` semantics must not be simplified away.

## Inventory
`PHYSICAL STOCK MOVEMENT -> post_stock_movement -> stock_branches + inventory_log`
`reserve_stock / release_stock_reservation` are reservation capabilities only.

## Source of truth
`order_details` remains authoritative where the fulfillment contract applies; `run_sheet_details` remains derived/synchronized where its existing trigger contract applies.

# OPEN BLOCKERS
- Full New-main feature parity is not yet proven against every current module/consumer.
- Browser/runtime verification of New-main is not yet available through the present execution environment.
- Main.html replacement remains unauthorized until structural, functional, contract, and runtime gates are proven.
- The current New-main must still be audited for remaining source-level defects before any claim of finality.

# LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-003`
- Event type: `NEW_MAIN_CLEAN_ROOM_ARTIFACT_CREATED_AND_PRODUCTION_BASELINE_REFRESHED`
- UTC: `2026-08-31T06:30:22Z` baseline / Git artifact commit `2026-08-31` preceding state-record commit
- Source: GitHub + Production Supabase
- Git artifact SHA: `4ff020857fffb6e7243f299d9fd50c86e116e153`
- Action: Created `Current/PWA/New-main` without modifying `Current/PWA/main.html`; refreshed direct Production baseline and active Edge deployment state.
- Result: `VERIFIED / CANDIDATE OPEN`
- Evidence: direct GitHub fetch of New-main; direct Production snapshot query; direct active Edge deployment list; direct PostgreSQL function/schema inspection.
- Impact: the requested independent reconstruction now exists as a concrete artifact; final replacement is intentionally not yet authorized because parity/runtime gates remain open.
- Next authorized action: continue verification and surgical correction of New-main only; do not modify Current/PWA/main.html.

# NEXT AUTHORIZED ACTION
ONLY: Continue the clean-room verification of `Current/PWA/New-main` against current Git + Production contracts. Do not return to the historical main.html repair loop.

# CURRENT CLOSURE STATUS
`NEW-MAIN CLEAN-ROOM ARTIFACT = CREATED / VERIFIED`
`NEW-MAIN STRUCTURAL PARITY = OPEN`
`NEW-MAIN FUNCTIONAL PARITY = OPEN`
`NEW-MAIN PRODUCTION RUNTIME = OPEN`
`CURRENT/PWA/main.html REPLACEMENT = NOT AUTHORIZED`
`HISTORICAL RECONSTRUCTION LOOP = CLOSED`
