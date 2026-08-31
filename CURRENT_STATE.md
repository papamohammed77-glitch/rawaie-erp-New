# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- CURRENT_STATE is the operational checkpoint.
- LAST VERIFIED EVENT is authoritative for recency.
- Historical reports/prompts are evidence only; Production and Git are current truth.
- Existing `Current/PWA/main.html` is NOT a repair target in this task.

## CURRENT GIT
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Branch: `main`
- Current HEAD: `f07344284d6d46ee9ffc468b0addb4af663e9446`
- Current HEAD purpose: trigger isolated New-main clean-room execution.
- Latest New-main artifact commit before trigger: `4ff020857fffb6e7243f299d9fd50c86e116e153`.
- `Current/PWA/New-main` blob SHA: `5f4783697bfc7b524024c54be286a213a74a4252`.

## PRODUCTION BASELINE — DIRECTLY VERIFIED
- Project: `fiilmooggumokxanwiyx`
- Last direct invariant baseline captured: 2026-08-31 UTC during this execution.
- companies: 1
- users: 24
- branches: 2
- items: 17
- stock_branches: 20
- inventory_log: 3
- stock_vouchers: 0
- purchase_orders: 0
- orders: 0
- runsheets: 0
- audit_log: 1866
- negative physical qty: 0
- negative allocated qty: 0
- available_qty mismatches: 0
- cross-company stock rows: 0
- cross-company inventory-log rows: 0
- duplicate item_code values: 0

## PRODUCTION CONTRACTS VERIFIED
- `items.item_code` UNIQUE globally.
- `stock_branches(branch_id,item_id)` UNIQUE.
- `receiving.operation_id` UNIQUE.
- `post_stock_movement` is the Physical Stock authority.
- `reserve_stock` / `release_stock_reservation` are reservation authority only.
- `receive_purchase_atomic` currently takes explicit `p_operation_id uuid` and uses receiving.operation_id for idempotency.
- Active Edge versions verified: create-stock-voucher v9; send-stock-voucher v19; receive-stock-voucher v21; receive-purchase v12; save-sales-invoice v15; complete-return v25; complete-order-delivery v14; bulk-stock-adjustment v6; complete-picking v16; start-picking v33; complete-loading v11; unload-runsheet v6.

## NEW-MAIN TASK
Target: `Current/PWA/New-main`.
Forbidden target: `Current/PWA/main.html`.

### Executed
1. Read governance prompt `تقرير +برومبت 117-02`.
2. Read and refreshed CURRENT_STATE against current Git/Production evidence.
3. Read `FINAL_MAIN_HTML_RECONSTRUCTION_COMMAND.md`.
4. Created isolated `Current/PWA/New-main` candidate.
5. Added an isolated clean-room builder and CI gate that can assemble the current `main1..main11` fragments into New-main only, with a main.html byte-identity guard.
6. Triggered the isolated execution through Git history.

### Verified
- `Current/PWA/main.html` was not modified by the direct artifact creation event.
- New-main currently exists as a concrete Git artifact, blob SHA `5f4783697bfc7b524024c54be286a213a74a4252`.
- The current repository contains the execution tool and isolated workflow.
- Production inventory invariants remain clean in the latest direct snapshot.

### NOT YET PROVEN
- The isolated GitHub Actions run that performs full `main1..main11` assembly has not produced a verifiable persisted execution commit in the accessible Git evidence.
- Therefore full structural parity of New-main against all 11 fragments is not claimed.
- Browser smoke for the full reconstructed artifact is not claimed.
- Production runtime verification of New-main is not claimed.
- Replacement of `Current/PWA/main.html` is not authorized and was not performed.

## LAST VERIFIED EVENT
- Event ID: `LVE-2026-08-31-004`
- Event type: `NEW_MAIN_CLEAN_ROOM_TRIGGERED_WITH_VERIFICATION_BOUNDARY`
- Git UTC: 2026-08-31T06:35:07Z
- Git commit: `f07344284d6d46ee9ffc468b0addb4af663e9446`
- Source: direct GitHub + direct Production Supabase
- Action: triggered the isolated clean-room reconstruction path for `Current/PWA/New-main`; left `Current/PWA/main.html` outside the target.
- Result: `CANDIDATE EXISTS / FULL RECONSTRUCTION NOT YET PROVEN`
- Why no false PASS: no accessible Git evidence of a successful `[new-main-clean-room-persist]` commit or runtime result.
- Next authorized action: verify/obtain the actual clean-room execution result, then audit New-main structurally and functionally. Do not modify `Current/PWA/main.html`.

## CLOSURE
`NEW-MAIN ARTIFACT = EXISTS`
`FULL RECONSTRUCTION = OPEN`
`STRUCTURAL PARITY = OPEN`
`FUNCTIONAL PARITY = OPEN`
`BROWSER RUNTIME = OPEN`
`PRODUCTION RUNTIME = OPEN`
`main.html REPLACEMENT = NOT AUTHORIZED`
