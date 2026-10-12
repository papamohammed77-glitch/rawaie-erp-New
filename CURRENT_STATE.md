# CURRENT FORENSIC CHECKPOINT — 2026-10-13 — Report418 Parent Orders Fresh Resync

## Current scope
Only the parent system's sales-orders table: `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`, module `RW_Orders`. Owner applies parent UI changes. Assistant must not edit `main.html` or the operational app. Production/Supabase changes are assistant-owned only when fresh evidence proves a defect.

## Fresh current-source evidence — 2026-10-13
- Current parent source: `erp-frontend/companies/company-1/main.html`, blob SHA `92bec4b0b006c7a280ba48e0ab4279e44282687a`, 1,762,278 characters / 32,436 lines. This supersedes Report417's prior blob SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d`; never reuse old line numbers.
- Report418: [Report418_PARENT_ORDERS_FRESH_RESYNC_AND_DIRECT_SALES_LABEL_20261013.md](doc/Draft/Reprots/Report418_PARENT_ORDERS_FRESH_RESYNC_AND_DIRECT_SALES_LABEL_20261013.md), commit `5a849f0f7edc0025f4583cf3aa89b2b8ad491556`.
- Report417 is historical evidence only. Its main A–H fixes are already present in the current parent source: 11-column table; source/creator/created-at columns; disabled checkboxes for ineligible sources; return-aware item counts; return-aware details/print; refresh of derived counts on confirmation and Realtime.
- Remaining exact owner patch only: in `RW_Orders._renderTable(data)`, current lines 10503–10509, add `'van-sales': 'بيع مباشر'` to the `sourceLabel` object. Full replacement is in Report418. Do not reapply the broader Report417 changes.
- Current source normalizes underscores to hyphens, so `online_store` maps to `online-store` and `van_sales` maps to `van-sales`.
- Fresh Production SQL at `2026-10-12 21:05:52.666893+00 UTC`: 6 orders total, 3 `pos`, 3 `order-taker`, and currently 0 `online-store`, 0 `telesales`, 0 `van-sales`. No Production test orders were created and no business data was changed.
- Production Edge: `create-runsheet` v26 (`verify_jwt=true)); `append-to-runsheet` v8 (`verify_jwt=true)). Production RPCs `create_runsheet_atomic(uuid,text[],text)` and `append_orders_to_runsheet_atomic(uuid,text,text[],text)` allow normalized `telesales/tele-sales/order-taker/online-store` only; `anon/authenticated EXECUTE=false`, `service_role EXECUTE=true`. Do not broaden this contract for display-label changes.
- Historical store source at commit `b2cd78da3af2ed7ff5f61b5fdea5c3d8a523f907` invokes `submit-online-order`; Production `submit_online_order_atomic` writes source `online_store`, which the current normalization already accepts.
- Recent repository commit checked: `fd94f0357f9525b1f85f36fa981a78afa99a00fe` only adds `_forensic_current_main_extract.md`; it is not the parent source patch. No claim is made that the current source blob is deployed.

## Closure status
`CURRENT GIT SOURCE VERIFIED / PRODUCTION CORE VERIFIED / ONE OWNER SOURCE-LABEL PATCH REQUIRED / SERVED ARTIFACT + BROWSER E2E NOT PROVEN`.

## Next exact resumption point
Owner: apply only the complete `sourceLabel` object replacement in Report418 against current SHA `92bec4b0b006c7a280ba48e0ab4279e44282687a`, then deploy and test source labels and eligibility in the served browser. Do not change `main.html` through the assistant, do not change Production RPC/ACL for this label-only defect, and do not create synthetic production orders.

## Current checkpoint — 2026-10-13 — Report419 Parent Orders Source Label
- Scope remains only `erp-frontend/companies/company-1/main.html`, module `RW_Orders`; owner applies parent UI changes. Assistant must not edit `main.html` or operational apps.
- Fresh Production SQL at `2026-10-12 21:27:14.559315+00 UTC`: `orders` has `pos=3`, `order-taker=3`; no other source values in the current sample.
- Production RPC ACL rechecked: `create_runsheet_atomic` and `append_orders_to_runsheet_atomic` are not executable by `anon/authenticated` and are executable by `service_role`. Their current definitions allow only normalized `telesales/tele-sales/order-taker/online-store`; direct-sale sources remain rejected.
- Current parent source SHA reported by GitHub: `92bec4b0b006c7a280ba48e0ab4279e44282687a`. The large-file fetch returned metadata/SHA but not the file body in this cycle; do not claim a fresh full-body read. Report418's exact `sourceLabel` patch targets this same SHA and must be matched against the opened source before owner application.
- Exact remaining owner patch: in `RW_Orders._renderTable(data)`, add `'van-sales': 'بيع مباشر'` to the `sourceLabel` object. Full replacement and validation steps are in [Report419](doc/Draft/Reprots/Report419_PARENT_ORDERS_VAN_SALES_SOURCE_LABEL_SURGICAL_CHANGE_20261013.md).
- No Production schema, RPC, ACL, Edge Function, or business data changes were required or performed. No Production test orders were created.
- Status: `PRODUCTION CONTRACT VERIFIED / OWNER SURGICAL PATCH READY / SOURCE BODY RECHECK + DEPLOYMENT + BROWSER E2E OPEN`.
- Next exact step: owner applies only the `sourceLabel` replacement against SHA `92bec4b0b006c7a280ba48e0ab4279e44282687a`, deploys the parent UI, and verifies source labels and checkbox eligibility in browser. Do not reapply broader Report417 fixes.

## Current checkpoint — 2026-10-13 — Report420 Parent Orders Source/Creator Filters

- **Scope remains only** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`, module `RW_Orders`. The owner applies parent UI changes; assistant did not edit `main.html` or an operational app.
- **Fresh current-source retrieval:** GitHub blob SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`; content fetched through the GitHub blob connector (about 1,762,271 characters). The latest direct `main.html` commit checked is `27e6687b2101a9efb91c6fb65a1ae218096679e7` (2026-10-12 21:39:56 UTC), which only reformats the `sourceLabel` object. Current source already contains `'van-sales': 'بيع مباشر'`; do not reapply Report418/419's label change.
- **Current parent UI finding:** filter grid at lines 10230–10241 contains date-from, date-to, customer, status, area, and runsheet only. `_applyFilters()` does not filter by `orders.source` or `orders.created_by`; `_resetFilters()` resets only six controls. The table already displays source and creator columns.
- **Fresh Production SQL:** project `fiilmooggumokxanwiyx`, checked at `2026-10-12 21:55:19.579432+00 UTC`. `public.orders` has `source` and `created_by` columns. Current sample: 9 orders, 3 distinct source values, 3 distinct creator values, no null/blank source or creator. Source counts: `order-taker=4`, `pos=3`, `telesales=2`. Read-only only; no Production data/schema changes.
- **Owner patch prepared:** [Report420_PARENT_ORDERS_SOURCE_CREATOR_FILTERS_SURGICAL_CHANGE_20261013.md](doc/Draft/Reprots/Report420_PARENT_ORDERS_SOURCE_CREATOR_FILTERS_SURGICAL_CHANGE_20261013.md), commit `4e7a96360514a671ac21be0749498c789ef99d76`. It specifies: replace filter-grid block to add source/creator selects; insert safe option-population helper; replace `_applyFilters()`; replace `_resetFilters()`; call option population after initial load and after `_refreshData()`.
- **No Production RPC/Edge/schema change is indicated** for this UI-only filtering task. Do not create synthetic Production orders.
- **Closure status:** `CURRENT SOURCE VERIFIED / PRODUCTION FIELDS + COUNTS VERIFIED / OWNER SURGICAL CHANGESET READY / DEPLOYMENT + BROWSER E2E OPEN`.
- **Next exact step:** owner applies Report420's exact edits to `main.html`, deploys the parent UI, then verifies source/creator filters, combined filters, reset, realtime refresh, sort, runsheet selection and the existing source eligibility guard in the served browser. Only then update this checkpoint with runtime evidence.
