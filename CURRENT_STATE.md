# CURRENT FORENSIC CHECKPOINT — 2026-10-11 — Report416 Parent Orders Production Resync

## Current scope
Only the parent system's sales-orders table: `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`, module `RW_Orders`. Owner applies parent UI changes. Assistant must not edit `main.html` or the operational app. Production/Supabase changes are assistant-owned only when fresh evidence proves a defect.

## Latest execution record
- Report: [Report416_PARENT_ORDERS_CURRENT_SOURCE_AND_PRODUCTION_RECHECK_20261011.md](doc/Draft/Reprots/Report416_PARENT_ORDERS_CURRENT_SOURCE_AND_PRODUCTION_RECHECK_20261011.md).
- Report commit: `726ffd2c3bc2ae01e70e20badb0b44f0a664a8dc` (file blob SHA; use report link for content).
- Previous evidence: [Report415](doc/Draft/Reprots/Report415_PARENT_ORDERS_FRESH_PRODUCTION_AND_SURGICAL_PATCH_20261011.md), [Report414](doc/Draft/Reprots/Report414_PARENT_ORDERS_LIVE_RESYNC_AND_RLS_AUDIT_20261011.md), [Report413](doc/Draft/Reprots/Report413_PARENT_ORDERS_RETURN_RUNSHEET_SOURCE_INTEGRATION_20261011.md), [Report408](doc/Draft/Reprots/Report408_POS_RETURN_STATE_DETAILS_AND_OWNER_CHANGESET_20261011.md).
- Master governance: [MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS](doc/Draft/Reprots/MASTER%20CTO%20GOVERNANCE%20%26%20CONTINUOUS%20EXECUTION%20OS%20%E2%80%94%20RAWAEA%20ERP.md).

## Fresh Production facts — 2026-10-11 16:24 UTC
- `ORD-1006`: source=`pos`, created_by=`cashier@rawaea.com`, created_at=`2026-10-11 07:31:00.768458+00`, status=`Partially Returned`, current/original totals=`135.00/185.00`, `runsheet_id=NULL`.
- Two detail rows: item `1001` qty 1 / returned 1 / reason `مرتجع نقطة بيع`; item `1003` qty 1 / returned 0. Remaining quantity=1 and remaining detail-line count=1. No business rows changed.
- Production RPCs `create_runsheet_atomic` and `append_orders_to_runsheet_atomic` reject sources outside normalized `telesales/tele-sales/order-taker/online-store`; `pos` and blank/unknown sources are rejected. ACL: anon=false, authenticated=false, service_role=true. No new Production SQL/Edge change justified.
- RLS `users_select_company` permits cross-user lookup only to users with `users` permission (plus self row). UI must fall back to `created_by`; do not broaden RLS to display names.
- Supabase has no development branches. No Production fixture created and no production data mutated.

## Current source/provenance constraint
- Live parent file fetch returns SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d` but empty content, including ranged reads. Exact live line numbers and source parity are therefore **UNVERIFIED**.
- Historical snapshot `rawaie-erp-New/Current/PWA/main.html`, blob `27b777528665dcc985809648f006452c861ae36e`, has 5,410 lines. The line map in Report416 (2332–2454) is only a search aid for that snapshot, never proof of current live line numbers.
- Do not blindly replace live functions from the historical snapshot. Compare actual live function bodies first.

## Owner surgical patch
Inside `RW_Orders`, compare the live code against Report413 §3-A–F:
1. `var ordersData = [];` — add source eligibility helpers once.
2. `async function loadData()` — count only lines where qty remains after returns; safely fall back to `created_by`.
3. `async function refreshRealtimeChannel()` — refresh header plus derived details for the current company.
4. `id="check-all"` — select only `.order-checkbox:not(:disabled)`.
5. Table headers/render — show creation time, source and creator; disable selection for POS/unknown source; adjust colspan for 11 columns.
6. `_validateSelected(selected)` — validate company, eligible source, status and existing runsheet link.
7. `_showDetails`, `_printOrder`, `_buildPrintWindow` — compare Report408/Report415; show original/returned/remaining quantities and consistent final/original totals. Print must be tested separately.
- Snapshot line references: helpers 2332; loadData 2334; realtime 2352; check-all 2394; date header 2396; customer header 2397; render 2428; validation 2443; details 2450; print 2452/2454. These are NOT verified live-file line numbers.
- The backend source guard is already deployed; do not change it again without new evidence.

## Closure status
`PRODUCTION CORE VERIFIED / OWNER UI PATCH SPECIFIED / LIVE SOURCE TEXT UNREADABLE THROUGH CONNECTOR / FRONTEND DEPLOYMENT + AUTHENTICATED BROWSER E2E + PRINT OPEN / NOT CLOSED`.

## Next exact resumption point
Owner opens the live `main.html`, matches actual `RW_Orders` function signatures, merges only matching blocks from Report413 and Report408/415, publishes, records the served artifact SHA, then tests authenticated table/details/print/Realtime and eligible-vs-ineligible runsheet selection. Use an isolated fixture only if a Staging environment becomes available; restore baseline and prove no residue. Preserve earlier detailed checkpoints in Git history.
