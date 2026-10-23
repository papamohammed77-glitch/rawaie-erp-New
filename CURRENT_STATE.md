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


## Current checkpoint — 2026-10-13 — Report421 POS Application Forensic Integration

- Scope: `erp-frontend/companies/company-1/sales/pos.html` and its current Supabase Production contracts. No edits were made to `main.html` or the operational POS file; no Production data/schema/ACL changes were made.
- Current POS source read in full: blob SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`, 91,752 characters / 1,564 lines.
- Historical POS baseline read: `rawaie-erp-review/PWA/sales/pos.html`, blob SHA `6ad4da791b72260b922847246ebce93b552d2bad`, 80,447 characters / 1,115 lines. Current version preserves the POS architecture while adding company-scoped RPC bootstrap/invoice reads, strict checkout validation, operation_id handling, and stricter return behavior.
- Fresh Production Edge evidence: `save-sales-invoice v18`, `verify_jwt=true`, `ezbr_sha256=43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`; `complete-return v26`, `verify_jwt=true`, `ezbr_sha256=801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`.
- Production ACL checked: `save_sales_invoice_atomic`, `complete_sales_return_credit_note_atomic`, and `post_stock_movement` are not executable by anon/authenticated and are executable by service_role. POS read RPCs are executable by authenticated and enforce auth.uid()/POS permission/company context. No unsafe direct-RPC grant was added.
- Current Production orders distribution observed read-only: `order-taker/Pending=4`, `pos/Invoiced=2`, `pos/Partially Returned=1`, `telesales/Pending=2`. No test sale/return was inserted.
- Verified gaps in current POS source: (1) `_setupUser` makes a redundant, unscoped `app_settings` query despite company-scoped `get_pos_bootstrap_data()` returning currency; (2) payment UI shows card/split but checkout intentionally rejects all non-cash methods because no complete settlement contract is proven; (3) return modal says no cash refund while the production return contract supports cash POS refunds only after validating the original cash receipt; (4) no `pending_updates.add/put/bulkAdd` writer exists in the current POS file, so offline sales are not implemented even though stale-cache UI opens offline.
- Proposal URL `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعددد` could not be retrieved through GitHub Contents API (404); extension and alternate directory variants were also tried. Its content is not claimed as reviewed.
- Report: [Report421_POS_APP_FORENSIC_INTEGRATION_20261013.md](doc/Draft/Reprots/Report421_POS_APP_FORENSIC_INTEGRATION_20261013.md), latest report update commit `e4f471110b0c4960b5502470547b05172bdfb55f` (initial report commit `6288a6001969229167744d74385dfae0753ab94a`).
- Surgical owner patches are documented in Report421: remove unscoped settings read; align POS return modal text with cash-only return contract; disable card/split options until settlement contract exists; correct return button wording. The assistant did not edit the operational file.
- Closure status: `SOURCE + PRODUCTION CONTRACTS AUDITED / OWNER PATCH READY / OFFLINE SALES AND NON-CASH SETTLEMENT OPEN / PRODUCTION UI E2E NOT PROVEN / NOT 100% CLOSED`.
- Next exact steps: owner applies only the Report421 surgical POS changes against SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`, deploys the operational app, and performs the specified authenticated browser tests. For full capability completion, implement a durable offline-sale pending-sync contract and an atomic card/wallet/split settlement contract before enabling those features. Do not grant authenticated direct execution of the service-role core RPCs without a separately audited authenticated wrapper.


## Current checkpoint — 2026-10-13 — Report422 POS Surgical Review and Production Reconciliation

- Scope: POS only, `erp-frontend/companies/company-1/sales/pos.html`; no `main.html` or operational POS file edits made by the assistant, per task constraints.
- Current POS source re-fetched: blob SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`, 91,752 characters / 1,564 lines. Historical baseline: `rawaie-erp-review/PWA/sales/pos.html`, SHA `6ad4da791b72260b922847246ebce93b552d2bad`.
- Fresh Production SQL at `2026-10-12 22:39:53.699289+00`: `get_pos_bootstrap_data()`, `get_pos_branches()`, `get_pos_invoice_data(text,text)` executable by authenticated and service_role, not anon. `save_sales_invoice_atomic` and `complete_sales_return_credit_note_atomic` executable only by service_role among checked roles. Current 11-argument `post_stock_movement` executable only by service_role; 10-argument legacy overload is not executable by anon/authenticated/service_role.
- Production Edge remains `save-sales-invoice v18`, `verify_jwt=true`, sha `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`; `complete-return v26`, `verify_jwt=true`, sha `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`.
- Current Production orders observed read-only: `order-taker/Pending=4`, `pos/Invoiced=2`, `pos/Partially Returned=1`, `telesales/Pending=2`. No test sales/returns created.
- Proposal `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعددد` could not be retrieved through GitHub Contents API (404); GitHub search returned no result for its supplied name/keywords. The proposal content remains UNVERIFIED and must not be represented as reviewed.
- Report422: [Report422_POS_SURGICAL_REVIEW_AND_PRODUCTION_RECONCILIATION_20261013.md](doc/Draft/Reprots/Report422_POS_SURGICAL_REVIEW_AND_PRODUCTION_RECONCILIATION_20261013.md), commit `69460eacfc2645735722dd4b75a8933b6a53e67d`.
- Four exact owner patches are documented in Report422: (1) remove redundant unscoped `app_settings` read from `self._setupUser`; (2) correct misleading POS return warning; (3) disable card/split options until a complete settlement contract exists; (4) relabel return action to indicate cash-only POS returns.
- No Production changes were appropriate: current RPC ACL boundary is consistent with Edge→service_role→Core. No Edge Function added. No Production data/schema/ACL changes.
- Open: owner applies patches to the operational POS file and deploys; authenticated browser E2E still unproven; offline-sales queue writer and non-cash settlement remain real capabilities not implemented; proposal content not assessed.
- Closure: `SOURCE + PRODUCTION CONTRACTS RECONCILED / OWNER PATCHES READY / PROPOSAL UNVERIFIED / PRODUCTION BROWSER E2E OPEN / NOT 100% CLOSED`.
- Next exact step: recover a valid URL/commit for the proposal, read it fully, then owner applies only Report422's four patches against the current source SHA, deploys, and performs the documented authenticated E2E without synthetic Production transactions.


**Checkpoint precedence:** Report421 and Report422 entries above are historical snapshots; their proposal-unavailable and return-core ACL claims are superseded by the live findings and repairs recorded in Report423 below.

## Current checkpoint — 2026-10-13 — Report423 POS Production ACL Repair

- Scope: POS only; operational `erp-frontend/companies/company-1/sales/pos.html` and related Production sale/return contracts. Assistant did not edit `main.html` or the operational POS file.
- Fresh current POS source SHA remains `0160f7cf9c4f194d954d2c7498d91fc639a5f419` (91,752 chars / 1,564 lines). Historical POS baseline SHA `6ad4da791b72260b922847246ebce93b552d2bad`.
- Live Supabase Edge: `save-sales-invoice v18`, `verify_jwt=true`, hash `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`; `complete-return v26`, `verify_jwt=true`, hash `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`.
- Important correction to Report422: a fresh Production SQL query found `authenticated_execute=true` on `public.complete_sales_return_credit_note_atomic(uuid,text,text,boolean,text,jsonb,text)`, contrary to Report422's old assertion. The SECURITY DEFINER wrapper accepts caller-supplied company/user arguments and must remain behind the authenticated Edge/service_role boundary.
- Production ACL was repaired directly: `REVOKE ALL ... FROM PUBLIC, anon, authenticated; GRANT EXECUTE ... TO service_role`. Post-change live verification at `2026-10-12 22:46:18.477992+00 UTC`: anon=false, authenticated=false, service_role=true; inner `complete_return_atomic` service_role=true.
- Canonical migration record committed: `supabase/migrations/20261013014600_revoke_authenticated_pos_return_core.sql`, commit `d62b773a548f849c78ef22d9e866364c4de4afa0`.
- Report423: [Report423_POS_PRODUCTION_ACL_REPAIR_AND_SURGICAL_CLOSEOUT_20261013.md](doc/Draft/Reprots/Report423_POS_PRODUCTION_ACL_REPAIR_AND_SURGICAL_CLOSEOUT_20261013.md), commit `b17106d05f2908900f29d016ab3569cbb2a44ee1`.
- Four owner-only POS patches remain unapplied: remove unscoped `app_settings` read from `_setupUser`; correct misleading cash-return warning; disable card/split payment controls until settlement contract exists; relabel return action as cash-only. Exact full replacements are in Report423.
- Proposal recovered at corrected path `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعدد`, commit `a456097f3326af2b18941992b903c3365c89aa10`, blob `d8badc619764e41b77b12a98e80a2b68c99b99cc`; full 10,965-character file reviewed. Proposal’s shift/X-Z/cash-control goals are accepted in principle, but its draft SQL is invalid (duplicate `company_id`) and misses key constraints, RLS, idempotency, concurrency and safe treasury/void contracts. See Report423 section 4.
- No Production sale/return fixtures were created. Browser E2E, served artifact parity, and clean fixture restoration are unproven. Supabase log query failed with backend error; no conclusion was drawn from it.
- Fresh Production schema check: `cash_box`, `treasury`, `sales_payment_receipts`, `audit_log`, `orders` exist; `shifts`, `cash_movements`, `cash_count_details`, `pos_terminals`, `orders.shift_id`, and shift RPCs were not found. Shift Management is a real capability gap; do not create the proposal schema verbatim or force sales to require a shift before coordinated UI/Edge support is deployed.
- Report423 was corrected after recovering the proposal and now links the P0 ADR: latest report commit `4f7434433a6f88953ce17c0cfa8477cc7c05579b`.
- Formal ADR created: [ADR_POS_SHIFT_MANAGEMENT_P0_20261013.md](doc/Draft/Reprots/ADR_POS_SHIFT_MANAGEMENT_P0_20261013.md), commit `3d361239ed49e6426e41a5f0a268ffb0a48757af`. It defines a safe, company-scoped shift model, RLS/ACL, atomic/idempotent RPC contracts, financial source-of-truth rules, and staged rollout. No shift tables were created in Production yet, because the current POS and existing sale Edge must be coordinated before enforcing `shift_id`.
- Current closure: `PRODUCTION RETURN-CORE ACL FIXED + VERIFIED / OWNER UI PATCHES READY / PROPOSAL REVIEWED; UNSAFE DDL REJECTED / SHIFT MANAGEMENT OPEN / BROWSER E2E OPEN / POS NOT 100% CLOSED`.
- Next exact step: owner applies Report423's four surgical POS changes to the current source SHA, deploys the operational POS app, then runs isolated authenticated cash sale/return E2E and direct-RPC-denial verification. Do not change `main.html`; do not enable non-cash settlement or claim offline sales complete without their full contracts.


## Current checkpoint — 2026-10-13 — Report424 POS Current Source + Production Reconciliation

- Scope: cashier/POS only. No changes made to `erp-frontend/companies/company-1/sales/pos.html` or `main.html`; no new Edge Function and no Production business test rows created.
- Current POS was freshly fetched in full: `erp-frontend/companies/company-1/sales/pos.html`, blob SHA `54dce2c9ad1e08e154965beb92d9d494607e42c9`, 92,037 characters / 1,575 lines. The same blob was returned when fetching the file at commit `f662358147c170be4a7119e8a8001d995f2706ff` (“Enhance POS button labels and descriptions”, 2026-10-13 02:05 +03).
- Historical baseline: `rawaie-erp-review/PWA/sales/pos.html`, SHA `6ad4da791b72260b922847246ebce93b552d2bad`.
- Four prior UI patches are already present in current Git: remove unscoped `app_settings` query from `_setupUser`; disable card/split buttons; correct cash-return modal copy; relabel return button to cash-only. Do not reapply them.
- Fresh Production Edge: `save-sales-invoice v18`, `verify_jwt=true`, hash `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`; `complete-return v26`, `verify_jwt=true`, hash `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`.
- Fresh Production ACL at `2026-10-12 23:12:07.767309+00 UTC`: POS read RPCs authenticated/service_role only; `save_sales_invoice_atomic`, `complete_sales_return_credit_note_atomic`, and current 10-argument `post_stock_movement` service_role only; legacy 9-argument `post_stock_movement` has no EXECUTE for anon/authenticated/service_role. The prior return-core ACL repair remains verified.
- Read-only Production order sample at `2026-10-12 23:12:40.470287+00 UTC`: order-taker/Pending/cash=4; pos/Invoiced/cash=2; pos/Partially Returned/cash=1; telesales/Pending/cash=2. No rows changed.
- Confirmed open gaps: Production has no `shifts`, `cash_movements`, `cash_count_details`, `pos_terminals`, or `orders.shift_id`; current POS has no shift identifier. Current POS opens with cached data offline but has no `pending_updates.add/put/bulkAdd` writer; `finalizeCheckout` sends directly to `save-sales-invoice`, so durable offline checkout is not implemented. Do not claim Offline-First checkout complete.
- Served-artifact parity and authenticated browser E2E remain unverified. No synthetic sale/return was created to fill this gap.
- Report424: [Report424_POS_CURRENT_SOURCE_PRODUCTION_RECONCILIATION_20261013.md](doc/Draft/Reprots/Report424_POS_CURRENT_SOURCE_PRODUCTION_RECONCILIATION_20261013.md), commit `8af724ee4eabc72f790d159275bdb84a7a855471`.
- Closure: `CURRENT SOURCE + PRODUCTION ACL VERIFIED / FOUR UI FIXES PRESENT IN GIT / SHIFT MANAGEMENT OPEN / OFFLINE CHECKOUT OPEN / SERVED ARTIFACT + BROWSER E2E UNVERIFIED / NOT 100% CLOSED`.
- Next: do not reapply the four UI fixes. Implement Shift Management from ADR `ADR_POS_SHIFT_MANAGEMENT_P0_20261013.md` with company-scoped schema/RLS/ACL and authenticated idempotent RPCs, then coordinate owner-applied POS and existing sale Edge changes without creating a new Edge Function or breaking current sales. Separately implement durable offline queue semantics and test retry/concurrency. Before closure, prove served artifact identity and authenticated browser E2E.


### Report424 final live recheck — 2026-10-13

- After the report was committed, Production was re-queried at `2026-10-12 23:14:19.134919+00`. The current idempotent `post_stock_movement` and the sale/return core functions remain service_role-only; the legacy movement overload remains non-executable by anon/authenticated/service_role.
- Edge Functions re-fetched after publication: `save-sales-invoice v18`, `complete-return v26`; both still `verify_jwt=true` and hashes match Report424.
- Report424's final post-publication resynchronization is recorded in section 9. Latest report commit: `1a117f9ea3829971e24775c6c0760e7ee075a6e1`.


## Current checkpoint — 2026-10-13 — Report425 POS Shift Management Production Core

- **Scope:** POS shift open/X-report/close/Z-report and shift linkage to existing cash records. No edits to `erp-frontend/companies/company-1/sales/pos.html` or `companies/company-1/main.html`; no new Edge Function; no synthetic sale/return rows were committed.
- **Production resync:** Supabase project `fiilmooggumokxanwiyx`. Final live resync: `2026-10-12 23:34:07.605759+00 UTC`; four shift tables, two linkage columns, two triggers, RPC ACLs and zero test residue reverified.
- **Current POS source:** `erp-frontend/companies/company-1/sales/pos.html`, blob SHA `54dce2c9ad1e08e154965beb92d9d494607e42c9`, 92,037 characters / 1,575 lines. Historical baseline `rawaie-erp-review/PWA/sales/pos.html`, SHA `6ad4da791b72260b922847246ebce93b552d2bad`. Operational file remains unchanged.
- **Historical docs:** proposal `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعدد`, blob `d8badc619764e41b77b12a98e80a2b68c99b99cc`; ADR `doc/Draft/Reprots/ADR_POS_SHIFT_MANAGEMENT_P0_20261013.md`, blob `3158bd3e3e69be32265641d6fbabc15490f98158`.
- **Production pre-change fact:** no shift/terminal/cash-count/event tables, no `orders.shift_id`, no `cash_box.shift_id`. Existing company has one active treasury `CASH-01`; current `save_sales_invoice_atomic` requires exactly one active treasury. `treasury` has no `branch_id`; do not claim separate branch treasuries or create more active treasuries without a coordinated core refactor.
- **Production migrations applied and present in schema_migrations:**
  - `20261012232615 / 20261012233000_pos_shift_management_core`
  - `20261012232738 / 20261012234000_pos_shift_authenticated_acl`
  - `20261012232948 / 20261012235000_pos_shift_linkage_hardening`
  - `20261012233250 / 20261012235500_pos_shift_z_report_snapshot`
- **Migration sources in GitHub:**
  - `supabase/migrations/20261012233000_pos_shift_management_core.sql`, final blob SHA `ae63a38f66e82df8b355d382920885b057be4e55`, final file-update commit `bf4ea7f5f249994c69d43d8c4b63d5b6452522cb`.
  - `supabase/migrations/20261012234000_pos_shift_authenticated_acl.sql`, commit `9491c9cff615d00f8553348749a78e8942081109`.
  - `supabase/migrations/20261012235000_pos_shift_linkage_hardening.sql`, commit `8129e3e72f7f22328fe07d68f7dfbff74b317fd7`.
  - `supabase/migrations/20261012235500_pos_shift_z_report_snapshot.sql`, commit `63f1e1849fc3b6a370d3cc9fe66ea38563b724a0`.
- **Production DB additions:** `pos_terminals`, `pos_shifts`, `pos_shift_cash_counts`, `pos_shift_events`; nullable `orders.shift_id` and `cash_box.shift_id`; triggers bind POS order/cash-box events to a matching open shift when present. Legacy POS writes remain compatible temporarily: a POS order without an open shift is not yet rejected at the DB layer because the owner has not deployed the UI gate.
- **RPCs:** `pos_open_shift`, `pos_get_shift_summary`, `pos_close_shift`; internal `pos_shift_expected_cash`. Verified ACL: anon=false, authenticated=true, service_role=false for the three user-facing RPCs; helper EXECUTE false for all app roles. Tables have RLS and no direct grants to anon/authenticated/service_role.
- **Tests:** transactional DB smoke with cashier JWT claims verified opening, duplicate open retry, expected cash 100.00, denomination sum, close difference 0, Z-report fields (`cash_sales`, `cash_refunds`, `sale_count`, `closed_by_user_id`), duplicate close retry, and rejection of cashier access to unauthorized branch. Transaction rolled back; final test residue counts were zero for test terminal/shift/events.
- **Edge:** Production `save-sales-invoice v18` (`verify_jwt=true`, hash `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`) and `complete-return v26` (`verify_jwt=true`, hash `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`) were re-fetched during this cycle; no Edge version was deployed by this task.
- **Report:** `doc/Draft/Reprots/Report425_POS_SHIFT_MANAGEMENT_PRODUCTION_CORE_20261013.md`, latest commit `b34663c2b7cef865ffb707013717ee5320a2a451`.
- **Closure:** `PRODUCTION DB CORE DEPLOYED / TRANSACTION TESTS PASS / OWNER POS SURGICAL PATCH REQUIRED / HTTP E2E OPEN / NOT 100% CLOSED`.
- **Next exact step:** first re-read current Production schema, migration history, RPC ACL and Edge versions. Then owner applies Report425 Patch 1–7 against POS SHA `54dce2c9ad1e08e154965beb92d9d494607e42c9`, deploys, and runs isolated authenticated browser E2E. Only after UI + existing sale Edge are coordinated may the database cutover reject shiftless POS sales. Paid In/Out, Void, supervisor approval, offline checkout, and branch-specific treasury remain open; do not create a duplicate cash ledger or enable multiple treasuries while the current sale core requires exactly one.


## Current checkpoint — 2026-10-16 — Report425 POS Shift / Treasury Forensic Resync

- Scope: only `erp-frontend/companies/company-1/sales/pos.html` plus read-only Production verification. Assistant did not modify `main.html` or the operational POS app and did not create Production sales/returns/shifts.
- Current POS source was re-fetched directly: blob SHA `1c5ee4b674e11bc22a141ade3743687fcf4d0ec0`, 106,570 characters / 1,847 lines. It already contains a shift open/close modal, denomination counting, and pre-checkout shift/branch guards; do not re-add those features.
- Fresh Production confirmed `pos_terminals`, `pos_shifts`, `pos_shift_cash_counts`, `pos_shift_events`, `orders.shift_id`, `cash_box.shift_id`, and order/cash-box shift-assignment triggers. The four POS shift migrations are recorded in `supabase_migrations.schema_migrations`.
- Live ACL: `pos_open_shift`, `pos_get_shift_summary`, `pos_close_shift` are executable by authenticated, not anon; helper/trigger functions are not directly executable. Direct table SELECT/INSERT/UPDATE grants are absent for anon/authenticated; shift tables have RLS enabled and no direct policies.
- Production currently has zero rows in `pos_shifts`; observed company `00000000-0000-0000-0000-000000000001` has one active treasury. No test fixture was created; no authenticated browser session was available for E2E.
- Verified gaps: no standalone `خزينتي` tab or periodic refresh in current POS source; no cashier-to-accountant handover acknowledgement contract; no server-enforced supervisor-code approval for POS return; multi-treasury UI selector absent; served artifact/browser E2E and offline checkout remain unverified.
- Surgical owner patch (nav entry, `treasury` view route, renderer polling `pos_get_shift_summary` every 5 seconds) is in [Report425](doc/Draft/Reprots/Report425_POS_SHIFT_UI_AND_CASHIER_CONTROL_REVIEW_20261016.md). This is near-live polling, not a true Realtime subscription.
- No Production DDL/ACL changes were made because the core shift schema/RPC already exists, there are no current shifts to exercise, and handover/supervisor approval require coordinated UI + secure backend contracts rather than an untested partial production mutation.
- Closure: `SHIFT CORE PRESENT / KHAZINATI SURGICAL PATCH READY / CASH HANDOVER OPEN / SUPERVISOR RETURN APPROVAL OPEN / HTTP E2E UNVERIFIED / NOT CLOSED`.
- Next exact action: owner applies Report425 patches against POS SHA `1c5ee4b674e11bc22a141ade3743687fcf4d0ec0`; then implement the handover contract and secure one-time supervisor approval enforced in the existing return Edge/Core path, followed by authenticated Production E2E and baseline verification. Do not recreate existing shift tables or reapply Report421–424 fixes.


## Current checkpoint — 2026-10-16 — Report426 POS Branch/Cash Contract Repair

- **Scope:** `erp-frontend/companies/company-1/sales/pos.html` plus Production `save-sales-invoice`. Assistant did not modify `main.html` or the operational POS HTML.
- **Fresh current POS source:** blob SHA `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d`, 111,290 characters / 1,904 lines. Latest relevant frontend commit checked: `6f30e2d78aa824ed92a5b3a0607edc8cb68ea9dc` (treasury view). Historical POS baseline remains `rawaie-erp-review/PWA/sales/pos.html`, SHA `6ad4da791b72260b922847246ebce93b552d2bad`.
- **Live cashier assignment:** `cashier@rawaea.com` is active, company `00000000-0000-0000-0000-000000000001`, permission `pos`, `default_branch_id=NULL`, `allowed_branch_ids="BR-01"`. `BR-01` is active. For this profile, the only provable branch is BR-01.
- **Production defect fixed:** prior `save-sales-invoice v18` checked company membership but omitted POS from the branch-allow-list condition and trusted client-supplied POS customer/payment fields.
- **Production repair:** existing `save-sales-invoice` deployed as **v19 ACTIVE**, `verify_jwt=true`, Production `ezbr_sha256=bdbe8fdeed5e3b7344241c07193d52cbec46bf8f58bf8d1ab443ee885065fd1f`. It rejects inactive branches; non-owner POS requests must match `default_branch_id`, or exactly one allowed branch when no default exists; POS requests are forced to generic cash customer, cash payment, zero delivery fees, and no customer contact/shipping fields.
- **Git source parity:** `Current/Edge_Functions/save-sales-invoice` blob SHA `2a90d34d1c7d3ae63a51e1cf3f2bb43ee6bdc5bc`; commit `622ab42fbc96307f76fb074ae699f95a0c4de4c8`. Production v19 was re-fetched and its `index.ts` matched the Git Current source exactly.
- **Core ACL:** `save_sales_invoice_atomic(jsonb,jsonb,text,text)` remains non-executable by `anon/authenticated`, executable by `service_role`. No new Edge Function and no DB DDL/ACL change were made.
- **Data baseline:** Production `orders=9`, `pos_shifts=0`, `pos_terminals=0`, `pos_shift_events=0`; no synthetic sale/return/shift was created.
- **Owner-only POS patches:** exact replacements A–F (fixed customer control, disabled branch control until profile resolution, branch locking from `defaultBranchId` / one allowed branch, static cash customer, fixed checkout header) are in [Report426](doc/Draft/Reprots/Report426_POS_BRANCH_CASH_CONTRACT_REPAIR_20261016.md). Do not edit `main.html`; do not reapply prior POS fixes without comparing current source.
- **Competitive benchmark:** Report426 records the current features and gaps against official Oracle Xstore, Microsoft Dynamics 365 Commerce, and Odoo POS docs. Cash handover, server-enforced supervisor return approval, durable offline checkout, paid-in/out/transfer, void reversal, non-cash settlement, and multi-treasury remain OPEN; do not claim they are implemented.
- **Closure:** `PRODUCTION EDGE v19 DEPLOYED + GIT SOURCE-SYNCED / POS UI PATCH READY FOR OWNER / AUTHENTICATED HTTP E2E UNVERIFIED / NOT 100% CLOSED`.
- **Next exact step:** owner applies Report426 Patches A–F only if POS source SHA is still `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d`, deploys the POS app, then runs authenticated E2E in an isolated test company or approved staging. Re-sync Production Edge and source first. Do not create test financial transactions in the live customer dataset.


## Current checkpoint — 2026-10-16 — Report427 Parent Orders Click/Details Forensic Check

- Scope: `erp-frontend/companies/company-1/main.html`, `RW_Orders`; owner-only source file. Assistant did not modify `main.html`, any operational app, Production schema, ACL, RPC, or business data.
- Fresh source: blob SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`, 1,762,271 characters / 32,437 lines, fetched by blob SHA and inspected around row click, detail loader, export, refresh loop, and error handling.
- Current source proves row click at line 10513 calls `RW_Orders._showDetails(order_code)`; `_showDetails` exists at line 10693, is exported at line 11077, and assigned to `window.RW_Orders` at line 11083. It performs company-scoped order lookup, then loads `order_details` by `order.id`; its catch logs `Order details error`.
- Fresh Production SQL at `2026-10-16 18:37:12 UTC`: 10 orders for company `00000000-0000-0000-0000-000000000001`.
- Fresh Supabase logs for the previous 24 hours: 247 requests to `/rest/v1/orders` and 237 to `/rest/v1/order_details`; all requests in the aggregation returned HTTP 200. This does not prove the exact click succeeded, but does not support a general DB/ACL outage.
- Console `ERR_CONNECTION_CLOSED` cannot be tied to the order-detail click from the supplied trace. The current source's periodic refresh invokes `_refreshData()` every 30 seconds; the initial load also fails to check `ordRes.error` explicitly, but neither is proven to cause the click issue. No speculative patch was made.
- Report427: [Report427_PARENT_ORDERS_CLICK_DETAIL_FORENSIC_20261016.md](doc/Draft/Reprots/Report427_PARENT_ORDERS_CLICK_DETAIL_FORENSIC_20261016.md), commit `c6ac3e679106cdee4706607e3e8682394e01c9bc`.
- Closure: `CURRENT SOURCE EVENT WIRING VERIFIED / PRODUCTION READS HEALTHY IN OBSERVED LOGS / EXACT BROWSER CLICK FAILURE UNREPRODUCED / NO UNSUPPORTED PRODUCTION OR SOURCE PATCH / OPEN`.
- Next exact step: owner reproduces one click with DevTools Network Preserve log and records the two requests: company-scoped `orders` lookup by `order_code`, then `order_details` lookup by `order_id`. If no request occurs, compare served Cloudflare Pages artifact with current Git SHA and patch only the event/served-artifact defect. If a request fails, repair the layer proven by its HTTP status/body. If both return 200 but modal does not appear, inspect SweetAlert/loader DOM on the served artifact. Do not change Production ACL/schema or create synthetic business orders without evidence.


## Current checkpoint — 2026-10-16 — Report425 Parent Orders Click Failure

- Scope: `erp-frontend/companies/company-1/main.html`, module `RW_Orders`; owner applies parent UI changes. Assistant did not modify `main.html`, any operational app, or Production schema/data.
- Current parent file blob SHA observed from GitHub: `a192704e07d984fdbecd00ce40a73e95fa806a7e`. The connector returned empty content for the large file even when line ranges were requested, so exact current source lines/body for the click handler and timer are not yet verified.
- Owner-provided Console stack shows the orders module's `render` path is invoked from `setInterval` at `main:10323`, with another `render` frame at `main:30347`. This is evidence of timed rendering, not proof by itself that the table DOM is replaced on each tick.
- Fresh Production read-only SQL at `2026-10-16 18:47:17 UTC`: `public.orders` exists and has 10 rows for company `00000000-0000-0000-0000-000000000001`.
- Fresh Supabase logs over the observed window show 3–7 GET requests per minute for `/rest/v1/orders`, all sampled responses HTTP 200; sampled average origin times were about 150–763 ms. The user's earlier `ERR_CONNECTION_CLOSED` is not reproduced by these later requests and does not establish a persistent DB/ACL defect.
- Tailwind CDN warning and favicon 404 are unrelated to the click failure based on current evidence.
- Report425: [Report425_PARENT_ORDERS_CLICK_FAILURE_FORENSIC_20261016.md](doc/Draft/Reprots/Report425_PARENT_ORDERS_CLICK_FAILURE_FORENSIC_20261016.md). Contains a non-mutating Console monitor and the proposed surgical direction.
- No Production SQL/RPC/ACL change is justified. Current likely cause is timer-triggered full render/DOM churn, but the precise root cause remains UNVERIFIED until current source body and browser mutation evidence are obtained.
- Next exact step: owner pastes the Report425 monitor in the served browser, clicks one order, and records whether the clicked row becomes detached and whether the details handler fires. Then retrieve the current `RW_Orders.render`/timer and details-click source block; only then issue a complete exact surgical replacement. Do not patch line numbers from stale reports.
- Closure: `PRODUCTION ORDERS READ VERIFIED / UI TIMER PATH OBSERVED IN OWNER CONSOLE / EXACT SOURCE BLOCK + BROWSER E2E OPEN / NOT CLOSED`.


## Current checkpoint — 2026-10-16 — Report428 Parent Orders Click Monitor Findings

- Scope: parent system `erp-frontend/companies/company-1/main.html`, module `RW_Orders`. No edits to `main.html`, operational apps, Production schema/ACL/RPC, or business data.
- Current parent source blob SHA: `a192704e07d984fdbecd00ce40a73e95fa806a7e`.
- New owner-provided browser trace: click target was a TD within an order row; row remained connected and identical at microtask and 500ms checks. A request matching `/rest/v1/orders` for `ORD-1002` returned HTTP 200. Subsequent visible list requests also returned HTTP 200. MutationObserver recorded later DOM mutations near some refreshes.
- The monitor only wrapped `/rest/v1/orders`; it did not track `/rest/v1/order_details` or modal visibility. Therefore it does not prove the details request occurred or that the modal rendered. The initial `ERR_CONNECTION_CLOSED` was not reproduced by the later visible requests.
- Current finding: no persistent `orders` API/DB failure proven; polling/DOM refresh correlation exists, but polling is not yet proven to cause the click failure. No speculative patch or Production change is justified.
- Report428: [Report428_PARENT_ORDERS_CLICK_MONITOR_FINDINGS_20261016.md](doc/Draft/Reprots/Report428_PARENT_ORDERS_CLICK_MONITOR_FINDINGS_20261016.md), report commit `152fd22d1acca014ab860a1440e30b870b47b144`.
- Closure: `ORDERS REQUESTS OBSERVED HTTP 200 / ROW NOT DETACHED IN FIRST 500MS / ORDER_DETAILS + MODAL RESULT UNVERIFIED / NO UNSUPPORTED PATCH / OPEN`.
- Next exact step: reproduce one click with Network Preserve log; record the `orders?order_code=eq.ORD-1002` and `order_details?order_id=eq.<id>` requests, status/body, Console errors, and modal visibility. Then patch only the proven failing source element. Do not alter Production ACL/schema or polling interval without direct evidence.


## Current checkpoint — 2026-10-16 — Report429 Parent Orders Details Modal Close Race

- Scope: owner-maintained `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`, `RW_Orders._showDetails(code)`. The assistant did not edit `main.html`, any operational app, or Production schema/data/ACL.
- Current source was fetched as a complete Git blob: SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`, 1,762,271 characters / 32,437 lines. Relevant current lines: `showLoader` 1218; `hideLoader` 1219; `_showDetails(code)` 10693; details `Swal.fire` 10786; `.finally(hideLoader)` 10809.
- Root cause proven in source: `hideLoader()` calls `Swal.close()`. The details callback calls `Swal.fire({...})` but does not return its Promise. The request chain therefore completes immediately and the outer `.finally(hideLoader)` closes the details modal as soon as it is opened.
- Historical comparison: `rawaie-erp-review/PWA/main.html`, blob SHA `e81ae6fe3e0e473b98927ff5cb2d54ba6ef18d8d`; the historical `_showDetails` closed the loader before opening the details modal and had no finalizer that closed the newly opened modal.
- Fresh Production SQL at `2026-10-16 19:12:41.863949 UTC`: `ORD-1002` exists for company `00000000-0000-0000-0000-000000000001`, id `4a2288df-b580-4736-bbac-7367f4edcc30`, status `Pending`, source `order-taker`, with 3 `order_details` rows. Recent Supabase logs show HTTP 200 on observed `order_details` requests, but no claim is made that any individual log row is the exact failed click.
- Latest relevant parent commit checked: `27e6687b2101a9efb91c6fb65a1ae218096679e7`; its diff changes only formatting of the `sourceLabel` object, not the modal lifecycle.
- Exact owner-only patch is in [Report429_PARENT_ORDERS_DETAILS_MODAL_CLOSE_RACE_20261016.md](doc/Draft/Reprots/Report429_PARENT_ORDERS_DETAILS_MODAL_CLOSE_RACE_20261016.md), report commit `42fd9a24e8dd2868bff3f6bc6fcddedfb2971231`: change only the details modal call from `Swal.fire({` to `return Swal.fire({`, preserving the full modal configuration and existing `.finally(hideLoader)`. Returning the modal Promise makes the chain wait until dismissal before the finalizer runs.
- No Production change is indicated. No test data was created. The parent source remains owner-maintained.
- Closure: `ROOT CAUSE PROVEN / OWNER PATCH READY / PRODUCTION DATA PRESENT / DEPLOYMENT + BROWSER E2E OPEN`.
- Next exact step: owner confirms current SHA, applies the one-line `return` change at the exact call in `RW_Orders._showDetails(code)`, deploys the parent system, then verifies `ORD-1002` modal stays visible, lists all three details, closes normally, and emits no `Order details error` or JavaScript error. Only then record runtime closure; do not modify Production DB/RLS/RPC or reapply prior polling patches.


## Current checkpoint — 2026-10-16 — Report430 Fresh Production Resync / Parent Orders Details Modal

- Scope remains only `erp-frontend/companies/company-1/main.html`, module `RW_Orders._showDetails(code)`. The owner applies changes to `main.html`; assistant did not edit it, any operational app, or Production schema/data/ACL.
- Fresh current source was fetched as a Git blob and inspected directly: SHA `a192704e07d984fdbecd00ce40a73e95fa806a7e`, 1,762,271 characters / 32,437 lines. The actual current `_showDetails(code)` calls `Swal.fire({...})` without returning its Promise, and the outer chain ends in `.finally(function() { hideLoader(); })`. `hideLoader()` invokes `Swal.close()`; this proves the finalizer can close the just-opened details modal immediately.
- Historical baseline rechecked from `rawaie-erp-review/PWA/main.html`, SHA `e81ae6fe3e0e473b98927ff5cb2d54ba6ef18d8d`: it closes the loading modal before opening the details modal and does not use the same post-modal finalizer sequence.
- Fresh read-only Production SQL at `2026-10-16 19:20:28.412986+00 UTC`: `ORD-1002` exists for company `00000000-0000-0000-0000-000000000001`, status `Pending`, source `order-taker`, with 3 `order_details` rows. Recent Supabase logs show successful HTTP 200 `order_details` reads, but do not prove the exact click's modal result.
- Exact owner-only fix: in `RW_Orders._showDetails(code)`, replace the existing complete `Swal.fire({ title: 'تفاصيل الأوردر: ' + esc(code), ... });` details-modal call with the identical complete call prefixed by `return`. Do not change or remove `.finally(function() { hideLoader(); })`. Full replacement and verification procedure are in [Report430](doc/Draft/Reprots/Report430_PARENT_ORDERS_DETAILS_MODAL_FRESH_PRODUCTION_RESYNC_20261016.md), report commit `00cc0899fcd234948d00bc140e8a8cc52f276474`.
- No Production RPC/Edge/schema/ACL change is justified. No test data was created. Current parent source SHA remains `a192704e07d984fdbecd00ce40a73e95fa806a7e`; deployed Pages artifact parity remains unverified.
- Closure: `ROOT CAUSE PROVEN IN CURRENT SOURCE / OWNER SURGICAL PATCH READY / PRODUCTION ORDER+DETAILS VERIFIED / DEPLOYMENT + BROWSER E2E OPEN`.
- Next exact step: owner verifies the SHA, applies only the `return Swal.fire(...)` replacement from Report430, deploys the parent system, and verifies `ORD-1002` modal remains visible with three details and closes normally. Do not alter Production DB or recreate business records for this UI defect.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-16 — Report431 Treasury/Bank Branch Linkage

## Scope and ownership
- Scope: Mother system `RW_Finance` → `الخزائن والبنوك` only.
- Owner edits/deploys `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`; assistant did not modify `main.html` or operational apps.
- Current parent commit checked: `3f226d5047b998ae14a9684222354924e1a43d31`; parent `6f30e2d78aa824ed92a5b3a0607edc8cb68ea9dc`; current `main.html` blob SHA `55d23d13e6d421d23e3a7ce57b758b5a03c4ace0`. Re-verify SHA before applying line-based instructions.

## Fresh Production facts — 2026-10-16 19:38–19:42 UTC
- Supabase project: `fiilmooggumokxanwiyx`.
- `public.treasury` originally had no `branch_id`; current production schema now has nullable `branch_id`.
- Production logs showed authenticated `POST /rest/v1/treasury` → HTTP 403 at 19:33:23 UTC; Postgres logged `permission denied for table treasury`. Authenticated role had SELECT only and no INSERT/UPDATE/DELETE table grants.
- No broad table-level write grants were added. Authenticated direct INSERT/UPDATE/DELETE remain false.
- Production had four active company branches, one treasury, and one POS shift linked to the existing treasury and main branch. The existing treasury balance and shift were not modified by the test.
- Production migrations applied:
  - `20261016194118_treasury_branch_linkage_and_metadata_rpc_20261016`
  - `20261016194152_treasury_delete_company_scoped_rpc_20261016`
- New functions: `finance_list_treasury_branches(uuid)`, `finance_save_treasury(uuid,uuid,text,text,numeric,uuid)`, `finance_delete_treasury(uuid,uuid)`. EXECUTE is granted to authenticated/service_role and revoked from PUBLIC/anon.
- A simulated authenticated company user successfully exercised branch-list, create, update, and delete RPCs. Final verification: `branch_id_column_exists=true`, save/delete authenticated EXECUTE true, `fixture_residue=0`, existing treasury count remains `1`.
- Git migration provenance:
  - `supabase/migrations/20261016194118_treasury_branch_linkage_and_metadata_rpc_20261016.sql`, commit `729767eb043b7313593102576340dc8ecf4cb5b1`.
  - `supabase/migrations/20261016194152_treasury_delete_company_scoped_rpc_20261016.sql`, commit `fc2e223b4733f0e7f0856929738dc110fce56f85`.
- Report: [Report431_TREASURY_BRANCH_LINKAGE_AND_PRODUCTION_SAVE_REPAIR_20261016.md](doc/Draft/Reprots/Report431_TREASURY_BRANCH_LINKAGE_AND_PRODUCTION_SAVE_REPAIR_20261016.md), commit `ef1497f9517a6d3fa024318f188d4c8ce00b0474`.

## Required owner patch
- Replace only `_openTreasuryDialog()` (around line 18081) and `_editTreasury(code)` (around line 18114) using the complete replacements in Report431.
- New modal branch selection uses `finance_list_treasury_branches`; create/edit uses `finance_save_treasury`; deletion uses `finance_delete_treasury`. This avoids direct table writes and keeps table-level write privileges closed.
- Do not change balance posting logic, other Finance modules, POS apps, or `main.html` through the assistant.
- Branch selection is optional for company-wide treasury/bank accounts. Existing balance values remain protected on edit. Server rejects a branch assignment that conflicts with existing POS-shift branch history.

## Closure status
`PRODUCTION SCHEMA/RPCS VERIFIED / AUTHENTICATED RPC SMOKE TEST PASSED / TEST RESIDUE ZERO / GIT MIGRATIONS RECORDED / OWNER UI PATCH + DEPLOYMENT + BROWSER E2E OPEN`.

## Next exact resumption point
Owner verifies blob SHA `55d23d13e6d421d23e3a7ce57b758b5a03c4ace0`, replaces only the two functions in Report431, deploys the parent UI, verifies create/edit/reload persistence with a zero-balance temporary treasury assigned to the main branch, then deletes that test treasury and proves no residue. Do not change the existing production treasury or create a test POS shift.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-16 — Report432 Treasury QR Owner Change Set

## Scope and source synchronization
- Scope: Mother system `RW_Finance → الخزائن والبنوك`; owner applies changes to `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`. Assistant did not edit `main.html` or the operational POS app.
- Fresh parent repository commit list checked at 2026-10-16: latest commit `4bd8958bd4d087346c56c871b29b749b9b1c1384` (forensic HR extract); preceding treasury UI commit `cba8e7fc7762c08735e678d09eb0080eb9538129`.
- Current `main.html` blob SHA at commit `cba8e7fc7762c08735e678d09eb0080eb9538129`: `9d02dcc1129e00c033082384562177ce1aa5b80a`, 32,569 lines. The branch-aware create/edit patch from Report431 is present in this source. Do not replace it with the older direct-table-write implementation.
- QRCode.js is already loaded dynamically in another Mother-system workflow from `qrcodejs@1.0.0`; no new dependency or Edge Function is needed for QR display.

## Fresh Production synchronization
- Supabase project `fiilmooggumokxanwiyx`; live database read timestamp `2026-10-16 20:32:39.750235+00 UTC`.
- Production table counts at observation: `treasury=1`, `pos_terminals=1`, `pos_shifts=1`, `cash_box=6`.
- Live treasury RPC ACL rechecked: `finance_list_treasury_branches(uuid)`, `finance_save_treasury(uuid,uuid,text,text,numeric,uuid)`, `finance_delete_treasury(uuid,uuid)` are executable by `authenticated` and `service_role`, not by `anon`.
- Direct `authenticated` table grants on `public.treasury` remain SELECT-only; no direct write grant was added.
- No Production schema, ACL, or business-data changes were made for QR. Existing `treasury.id` UUID and `company_id` are sufficient for a stable versioned QR payload; creating a QR does not require a new DB column.
- No fixture/test data was created in Production.

## Report432 result
- Report: [Report432_TREASURY_QR_CODE_SURGICAL_CHANGE_20261016.md](doc/Draft/Reprots/Report432_TREASURY_QR_CODE_SURGICAL_CHANGE_20261016.md), commit `8717d317b8dab39681b1775510a5a6ffefe6eb17`.
- Owner changes A–E: replace `_buildTreasuryTable(data)` to add per-row QR action; insert `_showTreasuryQR(code, fallbackItem)`; after successful RPC creation display QR automatically; widen create modal from 720 to 820; export the QR method on `RW_Finance`.
- QR payload is versioned JSON containing `type=rawaea_treasury`, `version=1`, `company_id`, and `treasury_id`. It is an identifier, not an access credential. Future POS binding must validate the signed-in user's company and permissions on the server; it must not trust company_id supplied in QR.
- No claim is made that scanning currently auto-binds a POS terminal. That consumer/runtime contract remains separate and must be verified before claiming end-to-end binding.

## Closure status
`PRODUCTION CONTRACTS RESYNCED / QR OWNER CHANGESET COMMITTED / PRODUCTION UNCHANGED / OWNER APPLY + DEPLOY + BROWSER E2E OPEN`.

## Next exact resumption point
Owner verifies `main.html` blob SHA `9d02dcc1129e00c033082384562177ce1aa5b80a`, applies only Report432 Changes A–E, deploys the parent system, tests create → QR display → reload → QR consistency → edit without balance mutation → clean deletion of the isolated zero-balance fixture, and proves no residue. Then separately trace the current POS consumer and implement authenticated treasury binding before claiming QR scanning auto-links a cashier.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-17 — Report433 Treasury Modal / QR

- Scope: owner-maintained papamohammed77-glitch/erp-frontend/companies/company-1/main.html, RW_Finance / الخزائن والبنوك. Assistant did not edit/deploy main.html or POS files.
- Current main.html blob SHA returned by GitHub: 10ea1297782b58f8d56b5a9409f41b01b3dac03f. Git confirms QR feature commit da0f3fcddf264a77573a34a565feb8bcb653f449 and modal width 920 commit 282d0d21d23b1b76dff9a4bcf60f350f1d58de8a; latest source-extract metadata commit 80914df7ca75c754815ba22871e3aeae66d5cfe4.
- Fresh Production SQL at 2026-10-16 21:09:58.733033+00 UTC: treasury=1, pos_terminals=1, pos_shifts=1, cash_box=6. Production RPC definitions and ACL rechecked for finance_list_treasury_branches, finance_save_treasury, finance_delete_treasury: authenticated/service_role EXECUTE, anon denied, company context checked. No Production change or test fixture made.
- Proven UI defect from committed diff: _showTreasuryQR catches its own errors and returns no status, while _openTreasuryDialog always emits a QR-success toast. A failed QR may therefore produce false success. A failed script element may also poison retries.
- Report433: [Report433_TREASURY_MODAL_QR_RETRY_HARDENING_20261017.md](doc/Draft/Reprots/Report433_TREASURY_MODAL_QR_RETRY_HARDENING_20261017.md), commit 33fa3dddca45de5f33a40f8ed80e679cc40df160. It provides owner-only changes: responsive modal width capped at 1120px, correct save-vs-QR feedback, and a complete retry-safe _showTreasuryQR replacement. Do not duplicate the QR feature already in Git.
- Not proven: Cloudflare served artifact parity, browser E2E, or QR scan-to-POS terminal binding. QR payload is an identifier, not authorization.
- Closure: CURRENT GIT QR FEATURE VERIFIED / PRODUCTION CONTRACT VERIFIED / OWNER PATCH + DEPLOYMENT + BROWSER E2E OPEN.
- Next exact step: owner confirms current SHA, applies only Report433 Changes A–C, deploys parent UI, verifies create, QR/retry, reload stability, responsive layout, and no financial/test residue. Trace and test authenticated POS binding separately before claiming scan-to-bind works.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-17 — Report434 POS Fixed Terminal / Treasury Binding

## Scope
Only POS-to-parent treasury integration. The assistant did not edit `erp-frontend/companies/company-1/main.html` or `erp-frontend/companies/company-1/sales/pos.html`. Owner applies the PWA patch.

## Fresh Git/source facts
- Current POS file: `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`, SHA `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d`, 111,290 characters / 1,904 lines.
- Current POS source still calls `pos_open_shift` with `p_treasury_id: null`, and its `_getShiftTerminalCode()` uses localStorage to identify a browser/device.
- Current parent `main.html` source contains `RW_Finance._showTreasuryQR`, whose QR payload is `type=rawaea_treasury, version=1, company_id, treasury_id`. POS has no current QR consumer. No parent source was changed.
- Report434: [Report434_POS_FIXED_TERMINAL_TREASURY_INTEGRATION_20261017.md](doc/Draft/Reprots/Report434_POS_FIXED_TERMINAL_TREASURY_INTEGRATION_20261017.md), commit `ddb05415953d26db80275b68b6743993b53e6faf`.

## Fresh Production facts — 2026-10-16 22:02 UTC
- Project: `fiilmooggumokxanwiyx`.
- Three active treasuries were found; the old implicit treasury choice is not sufficient for a newly initialized terminal.
- `pos_terminals` now has nullable `treasury_id` with FK to `treasury(id)`. Existing terminal's binding is backfilled from its consistent shift history to `الخزينة الرئيسية`; the existing open shift was not changed.
- Current Production baseline after rollback tests: `pos_terminals=1`, `pos_shifts=1`, `pos_shift_events=1`, `cash_box=6`, test terminal residue (0).
- `pos_bind_terminal_treasury(uuid,text,uuid,text)` is active, `anon EXECUTE=false`, `authenticated EXECUTE=true`; it requires Owner / general manager / cash manager and validates company, allowed branch and active treasury. The function refuses to rebind a terminal with shift history to a different treasury.
- `pos_open_shift(uuid,text,numeric,uuid,uuid,text)` remains `anon EXECUTE=false`, `authenticated EXECUTE=true`; it uses the terminal's fixed treasury and rejects mismatches.
- Production migrations applied:
  - `pos_terminal_treasury_binding_20261016` — Git migration `supabase/migrations/20261016220000_pos_terminal_treasury_binding.sql`, commit `a7906e063da2db614eddd876668258454a0976d6`.
  - `pos_terminal_manager_binding_guard_20261016` — Git migration `supabase/migrations/20261016221000_pos_terminal_manager_binding_guard.sql`, commit `0bdb2bfa9573d3532cec63d5bd9b1d4fb696efff`.
  - `pos_terminal_bind_idempotency_fix_20261016` — Git migration `supabase/migrations/20261016222000_pos_terminal_bind_idempotency_fix.sql`, commit `81e0826260c99a0f6ba9971907767d25a682c28c`.
- SQL verification passed: idempotent retry of the current open shift returned the same `shift_id`; a different treasury for the bound terminal was rejected with `SHIFT_TERMINAL_TREASURY_MISMATCH`; a normal POS cashier was denied terminal binding with `POS_TERMINAL_CONFIGURATION_PERMISSION_REQUIRED`. Test transaction rolled back; no test data remains.
- No Edge Function was added. No sales, refund, cash-box or accounting transaction was created or modified.

## Owner-only surgical patch
- Report434 contains the complete exact POS patches: add the QR binding button to `#posShiftOpenPanel`; insert `POS.bindTerminalTreasuryQR` after `_getShiftTerminalCode`; replace `self.startShift` error handling.
- Do not change `main.html` for the POS binding consumer. The existing parent QR generator is the producer; POS is the missing consumer.
- Report426's earlier owner-only patches A–F for fixed cash customer and branch assignment are still not present in the current POS source at the observed SHA; compare and apply only what remains necessary. Do not reapply blindly if the SHA changes.
- Report433's parent QR retry/success-feedback patch remains an owner-side UI item; no claim that the parent QR flow is served/deployed was made.

## Closure status
`PRODUCTION DB/RPC REPAIR APPLIED + SQL VERIFIED / POS PATCH READY / BROWSER E2E + SERVED ARTIFACT PARITY OPEN / NOT 100% CLOSED`.

## Next exact resumption point
Owner verifies POS SHA `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d`, applies Report434 Patches A–C and the still-required parts of Report426, then deploys POS and tests: authorized Owner binds a new terminal via treasury QR; cashier signs in and opens a shift against that fixed treasury; same cashier signs into a second device with a different terminal binding; mismatched treasury is rejected; sale/refund cash-box rows retain the correct shift/treasury; then verify the actual served artifact. Do not create synthetic permanent Production sales or change the existing open shift.


## Final update — Report434 branch-scope hardening — 2026-10-16 22:05 UTC
- Added migration `pos_terminal_bind_branch_scope_fix_20261016`; Git file `supabase/migrations/20261016223000_pos_terminal_bind_branch_scope_fix.sql`, commit `0e18d089b1570c913a54139b1588e7090e905c8a`.
- `pos_bind_terminal_treasury` no longer relies on `get_pos_branches()` for branch authorization; it checks company, active branch, owner state, `default_branch_id`, and `allowed_branch_ids` directly.
- Post-migration live query at `2026-10-16 22:05:16 UTC`: `anon EXECUTE=false` and `authenticated EXECUTE=true` for both terminal binding and shift open; baseline remains `terminals=1, shifts=1, events=1, cash_box=6, E2E residue=0`.
- The previous successful permission-denial test predates this branch-only correction; an attempted rerun was blocked by the tool safety layer. The final read-only Production catalog/ACL/baseline query succeeded. No transaction or business data changed in the blocked attempt.
- Report434 remains `PRODUCTION DB/RPC REPAIR APPLIED + SQL VERIFIED / POS PATCH READY / BROWSER E2E + SERVED ARTIFACT PARITY OPEN / NOT 100% CLOSED`.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-18 — Report435 POS Terminal/Treasury Sale Routing

## Scope
Only POS cashier/device/treasury session contract. No changes to main.html or operational POS HTML. Production SQL/Core was repaired directly; the owner must apply the source-only changes documented in Report435.

## Current source evidence
- POS: papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html
- Current blob SHA: f6bc60f7067922d2603c4f849d2fb477407a7e83
- Size: 119,763 characters / 2,103 lines.
- Current source includes QR-to-terminal treasury binding added in commit e8f6e4000f2edb49944b25365f575dc62a580d30. Do not re-add that feature.
- Current shared core.js SHA: c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81.
- POS still needs owner changes: shift/terminal match in loadShiftState; include shift_id + device_id in invoice header; branch allow-list UI enforcement; disable misleading customer selector; local-only signout and short auto-logout.

## Fresh Production facts — 2026-10-18 16:02–16:12 UTC
- Active treasuries: 3; pos_terminals=1; pos_shifts=1; pos_shift_events=2; cash_box=6; POS orders=4.
- Existing terminal remains bound to BR-01 and treasury “الخزينة الرئيسية”. Existing shift is closed. Historical cash difference -135.00 was preserved.
- Root cause: save_sales_invoice_atomic still required exactly one active treasury for a cash POS sale; with 3 active treasuries it contradicted the terminal-fixed treasury contract.
- Production migration applied: pos_terminal_treasury_sale_routing_20261018, version 20261018160955.
- Canonical Git migration: supabase/migrations/20261018161000_pos_terminal_treasury_sale_routing.sql; blob SHA bb2a923cd07483d8fa114c43e9e5f859e56268e6; commit c1402a7671a69886ce909aabb3db64bfb599ab97.
- Core now routes POS cash receipts through the open shift’s treasury, validates terminal/treasury/company/branch consistency, and persists optional shift_id/device_id on orders. The non-POS single-active-treasury rule remains unchanged.
- ACL after migration: save_sales_invoice_atomic is not executable by anon/authenticated and is executable by service_role; trigger function has no direct app-role execute grant.
- Existing Edge save-sales-invoice remains v19 ACTIVE, verify_jwt=true; no Edge Function was added.

## SQL E2E and baseline
- A transaction-isolated POS sale with a temporary shift succeeded and its cash_box receipt used the shift’s bound treasury. The transaction was rolled back.
- A transaction-isolated request using an unbound terminal code was rejected with POS_TERMINAL_NOT_BOUND_TO_BRANCH_TREASURY; the subtransaction rolled back.
- Post-test baseline: pos_terminals=1, pos_shifts=1, pos_shift_events=2, cash_box=6, active_treasuries=3, test_orders=0. No test residue remains.
- No Browser/HTTP E2E or Cloudflare served-artifact parity is claimed.

## Report
- Report435: doc/Draft/Reprots/Report435_POS_TERMINAL_SESSION_AND_TREASURY_CLOSURE_20261018.md
- Commit: d863dd1600661ceaf9f90e1055bdb4b91b3158d2
- Report includes exact owner-only surgical changes to POS and core.js. Do not edit main.html and do not replace either file wholesale.

## Closure
PRODUCTION CORE REPAIRED / TRANSACTIONAL SQL E2E PASS / BASELINE RESTORED / OWNER SOURCE PATCHES OPEN / BROWSER E2E OPEN / NOT 100% CLOSED.

## Next exact resumption point
Owner applies Report435 Patches A–F against the exact current POS/core SHA, deploys the POS PWA, and verifies:
1. An open shift is usable only on the terminal whose terminal_code, terminal_id, and treasury_id match.
2. POS sends shift_id and device_id; Production writes the cash receipt to that terminal’s treasury.
3. Only the cashier’s permitted branch is available.
4. POS checkout/receipt consistently uses the generic cash customer.
5. Logging out or automatic lock affects the current device session only, not other devices.
6. Browser/HTTP E2E, served-artifact parity, and zero test residue are proven before claiming full closure.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-18 — Report436 POS Device Binding / Local Session Scope

## Scope
POS device-to-treasury binding and local sign-out scope only. No edits were made to operational pos.html, shared core.js, or main.html. No Production schema/data change was made in this cycle because live evidence shows the shift RPC correctly rejects a device code that does not resolve to the bound terminal.

## Fresh Git evidence
- Current POS source: papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html, blob SHA 962dc6474a9c2692c1072631bd9d09d359d7d982, 2,278 lines.
- Latest relevant POS source commit: e4876b012f9a00ce785b2d8c899e740102c842e7 (2026-10-18 16:36:40 UTC). It contains the device-shift mismatch guard, allowed-branch filter, and disabled generic-customer selector.
- Current shared core.js SHA: c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81. Both signOut calls still omit scope and need the owner-only surgical patch described in Report436.
- Report435’s POS patches A–E are already present in the current POS source: terminal/shift matching, shift-other-terminal guards, shift_id/device_id on invoice payload, branch allow-list, and generic cash customer. Do not reapply them.
- Report436: doc/Draft/Reprots/Report436_POS_DEVICE_BINDING_AND_LOCAL_SESSION_SURGICAL_CLOSEOUT_20261018.md, commit cb4fddc691debe206e64f8eb9510e1a7d45af2db.

## Fresh Production evidence — 2026-10-18
- pos_terminals=1, pos_shifts=1, pos_shift_events=2, pos_shift_cash_counts=8, cash_box=6, treasury=3, orders=10.
- Existing terminal: ID 6c7e8574-4146-4f45-8633-dd3335d95796, code POS-f79a1587-378c-422d-9bd3-e7231e8864f4, branch BR-01, treasury ID 0a9d9357-b5f3-4dfa-886f-7c73de4f274e (CASH-01 / الخزينة الرئيسية), active.
- Authenticated user on the failing request is cashier@rawaea.com, active, company 00000000-0000-0000-0000-000000000001, permission pos, allowed branch BR-01.
- Production log at 2026-10-18T16:39:09.353Z shows pos_open_shift raised SHIFT_TREASURY_SELECTION_REQUIRED. The live function only raises this when it cannot resolve a terminal with a fixed treasury and the fallback sees multiple active treasuries. The request payload does not expose p_terminal_code, so inspect Local Storage on the failing browser and compare rawaea_pos_terminal_code to pos_terminals.terminal_code; do not infer the exact local value.
- No pos_bind_terminal_treasury call appeared in the selected 16:38–16:41 UTC log window. The same-device QR binding workflow exists in current POS source. The proper action is to bind/verify that device using an authorized parent-system QR workflow, not to weaken the RPC or pick a treasury arbitrarily.
- Migration pos_terminal_treasury_sale_routing_20261018 version 20261018160955 is present. save_sales_invoice_atomic remains service_role-only; no Edge Function was added. No Production change was made in this cycle.
- Latest counts differ from older Report435 snapshot; treat the fresh counts above as current. No synthetic production sale or new test data was created by this cycle.

## Exact next actions
1. Owner: in companies/company-1/core.js at SHA c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81, replace the signOut() line inside doLogin’s hydrateProfile error branch and the signOut() line inside doLogout with signOut({ scope: 'local' }); complete replacements and exact search anchors are in Report436.
2. On the device that failed to open a shift, use an authorized parent account to display the target treasury QR, then scan it from that same POS device. If it still fails, read its Local Storage value rawaea_pos_terminal_code and compare it with the live pos_terminals.terminal_code before any further change.
3. Verify on Production: the current terminal code resolves to the intended active terminal and fixed treasury; pos_open_shift opens the shift; POS sends matching shift_id/device_id on checkout; sale receipt lands in that terminal treasury. Do not create permanent test sales in the live customer dataset.
4. After owner source change and same-device verification, update this checkpoint with the new source SHA and runtime evidence. No 100% closure claim until browser/HTTP E2E and served-artifact parity are proven.

## Closure
PRODUCTION SALE ROUTING MIGRATION VERIFIED / SHIFT OPEN FAILURE DIAGNOSED TO TERMINAL RESOLUTION FALLBACK / CURRENT POS PATCHES A–E ALREADY PRESENT / CORE.JS LOCAL SIGN-OUT PATCH READY / BROWSER E2E OPEN / NOT 100% CLOSED.


# CURRENT FORENSIC CHECKPOINT — 2026-10-18 — Report437 POS Auto Device Treasury / No QR

## Scope
POS shift-opening treasury setup only. Production RPC repaired directly; no changes were made to `main.html`, POS HTML, or `core.js`. The owner-only surgical UI patches and official Square/Shopify benchmark are in `doc/Draft/Reprots/Report437_POS_AUTO_DEVICE_TREASURY_NO_QR_20261018.md` (latest report commit `0ad51b91f63d59a1c15bfbca5e86ec883b9cd60f`).

## Fresh Production state after repair
- Supabase project: `fiilmooggumokxanwiyx`.
- Migration `pos_terminal_auto_treasury_on_shift_open_20261018` recorded as version `20261018182808`.
- Git migration artifact: `supabase/migrations/20261018182808_pos_terminal_auto_treasury_on_shift_open.sql`, commit `92e648365d8b65463ceba2909860d706718a0bf8`.
- Production function: `public.pos_open_shift(uuid,text,numeric,uuid,uuid,text)`; source contains the deterministic device-treasury provisioning path.
- ACL verified: `anon EXECUTE=false`, `authenticated EXECUTE=true`, `service_role EXECUTE=true`.
- Baseline after transaction-isolated test: `pos_terminals=1`, `pos_shifts=1`, `pos_shift_events=2`, `pos_shift_cash_counts=8`, `cash_box=6`, `treasury=3`, `POS orders=4`.
- E2E fixture residue: `0` test terminals, `0` test treasuries; the SQL test transaction was rolled back.

## Verified behavior
- An authenticated POS user may open a shift without scanning a treasury QR.
- For an unregistered terminal code, the RPC creates a company/branch-scoped `Cash` treasury and terminal binding atomically; deterministic code plus an advisory transaction lock prevents duplicate treasury creation for the same device.
- Existing terminal treasury bindings are preserved. The historical terminal and its prior shift/cash records were not reassigned.
- Repeating the same `operation_id` returns the same shift/terminal/treasury as a duplicate.
- An unauthorized branch is rejected before device/treasury provisioning.
- The existing `pos_assign_order_shift` and `save_sales_invoice_atomic` contracts remain the downstream guard/routing path; no Edge Function was added.

## Owner-only remaining change
Current POS HTML blob SHA remains `962dc6474a9c2692c1072631bd9d09d359d7d982`. Apply Report437 Patch A to replace the mandatory treasury-QR UI block with the automatic device-treasury explanation, and Patch B to remove the obsolete QR-required error text. Do not modify `main.html` or replace the POS file.

## Open verification
- Browser/HTTP E2E against the actual Cloudflare-served POS artifact: OPEN / UNVERIFIED.
- Served-artifact parity against Git: OPEN / UNVERIFIED.
- The owner-side POS patch has not been applied by this session.
- Do not claim 100% closure until the owner patch is deployed and the real cashier browser flow is verified.

## Exact next steps
1. Owner applies Report437 Patches A and B to the exact POS source SHA; preserve all other functionality.
2. Deploy the POS app through the existing frontend deployment route.
3. Test on a browser with a fresh terminal code: cashier login → choose authorized branch → start shift without QR → confirm a device-specific treasury is created once → repeat/retry without duplicates.
4. Complete a real cash sale and verify `orders.shift_id/device_id` and `cash_box.treasury_id/shift_id` match the active shift and terminal.
5. Verify logout on device A does not revoke device B; the separate `core.js` local-sign-out patch from Report436 remains owner-side and is not marked applied here.
6. Confirm baseline/test residue and inspect the served artifact before closure.


# CURRENT FORENSIC CHECKPOINT — 2026-10-18 — Report438 POS No-QR Shift UI Binding

## Scope
Only the POS no-QR shift-open handoff. Do not edit `main.html`, `pos.html`, or `core.js` directly. The owner applies the surgical source changes.

## Fresh source and Production reconciliation
- Current POS: `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`, blob SHA `962dc6474a9c2692c1072631bd9d09d359d7d982`, 2,278 lines.
- Latest relevant source commit: `e4876b012f9a00ce785b2d8c899e740102c842e7`.
- Report437 already repaired Production `public.pos_open_shift` and recorded migration `20261018182808`; this cycle did not repeat or mutate that repair.
- Fresh live Production check confirms `pos_open_shift(uuid,text,numeric,uuid,uuid,text)` contains deterministic automatic device-treasury provisioning, does not contain the old `SHIFT_TREASURY_SELECTION_REQUIRED` error path, and grants execute to authenticated but not anon.
- The RPC returns `terminal_id` and `treasury_id`; current POS `self.startShift` does not persist those IDs before calling `loadShiftState`. The latter intentionally rejects an open shift when local terminal/treasury IDs are missing or mismatch. This is a newly identified client handoff defect after the Report437 backend change.
- Production has one closed shift with one linked order, two linked cash_box rows, two events, and eight denomination-count rows; close difference is `-135.00`. Preserve these records because they have linked business/financial evidence; do not delete them as presumed test data.
- No Production schema/data/ACL change was needed or performed in this cycle.

## Report438
- `doc/Draft/Reprots/Report438_POS_NO_QR_SHIFT_OPEN_LOCAL_BINDING_FIX_20261018.md`
- Commit: `151db5cfab78f771ea22464d11029d6739b84f40`
- Patch C is the only new source patch in Report438: after successful `pos_open_shift`, persist returned `terminal_id` and `treasury_id` in localStorage before `loadShiftState`.
- Report437 Patches A/B remain required: replace QR-required UI instructions and obsolete QR-required error wording. Do not repeat the Production migration or replace the POS file.

## Closure
`PRODUCTION NO-QR RPC VERIFIED / OWNER PATCHES A–C PENDING / BROWSER E2E OPEN / NOT 100% CLOSED`.

## Next exact steps
1. Owner applies Report437 Patch A and Patch B plus Report438 Patch C against POS SHA `962dc6474a9c2692c1072631bd9d09d359d7d982`.
2. Deploy through the existing frontend route.
3. Browser test: cashier login → authorized branch → open shift without QR → verify no “other terminal” false-positive and confirm the active shift is visible.
4. Retry the same flow after reload; confirm the terminal/treasury IDs remain aligned and the existing terminal/treasury binding is not changed.
5. Run one isolated cash sale only in a designated test company/environment; verify order.shift_id/device_id and cash_box.shift_id/treasury_id against the active shift. Do not create a permanent test sale in the live customer dataset.
6. Verify served-artifact parity and baseline/test residue before claiming closure.


## Report421 — POS shift summary permission investigation (2026-10-18)
- Report: `doc/Draft/Reprots/Report421_POS_SHIFT_SUMMARY_PERMISSION_FORENSIC_20261018.md`
- Commit: `92e0f52943c9c9c382e8e09ef502519b76afabe3`
- Fresh Production ACL: `public.pos_get_shift_summary(uuid)` exists; `authenticated EXECUTE=true`, `anon EXECUTE=false`. The function is SECURITY DEFINER and checks `auth.uid()`, company scope, active user profile, and POS permission.
- Fresh Production logs at 2026-10-18 19:33:40–19:33:55 UTC still show PostgREST `permission denied for function pos_get_shift_summary`.
- No Production ACL/schema/data change made: authenticated already has EXECUTE, and granting anon would weaken financial-data access. The actual JWT role for failed requests is not yet proven.
- Current source SHAs inspected: POS `b09320129dd04a833d1304a76fee0768ab7c52a3`; shared `core.js` `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81`. Neither file was changed.
- Status: `PRODUCTION ACL VERIFIED / LIVE ERROR CONFIRMED / JWT ROLE ROOT CAUSE UNVERIFIED / OWNER SOURCE PATCH AND AUTHENTICATED HTTP E2E OPEN`.
- Next exact step: owner applies a surgical session-presence guard in `POS.loadShiftState` so no RPC is sent without a valid Supabase session, preserving all existing response/error handling; then test with a real authenticated POS session and verify logs. Do not grant EXECUTE to `anon` and do not create a new Edge Function.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-18 — Report439 POS Session Guard / Production Reconciliation

- Scope: POS only — `erp-frontend/companies/company-1/sales/pos.html`, its directly related shared auth behavior in `companies/company-1/core.js`, and Supabase Production project `fiilmooggumokxanwiyx`. No edits to `main.html`, `pos.html`, or `core.js` were made by the assistant.
- Fresh current source identities:
  - POS `b09320129dd04a833d1304a76fee0768ab7c52a3`, 2,292 lines.
  - shared `core.js` `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81`, 773 lines.
- Production ACL rechecked: `pos_get_shift_summary(uuid)` = authenticated EXECUTE true / anon false; `pos_open_shift(uuid,text,numeric,uuid,uuid,text)` = authenticated true / anon false; `save_sales_invoice_atomic(jsonb,jsonb,text,text)` = authenticated false / anon false (service-role path only). No ACL change is warranted.
- Production logs in the examined window show repeated `POST 401 /rest/v1/rpc/pos_get_shift_summary` and `permission denied for function pos_get_shift_summary` through 2026-10-18 19:46:45 UTC. The actual JWT role is not exposed by these records. A transaction-isolated SQL call with role `authenticated` and claims for the existing POS user returned `success=true, active_shift=false`; transaction rolled back. This is not HTTP/browser E2E.
- Fresh read-only baseline at 2026-10-18 19:48:07 UTC: terminals=2, shifts=2 (both closed), shift_events=4, shift_cash_counts=16, cash_box=8, treasuries=4, POS orders=5, open_shifts=0. One auto-created POS treasury is linked to a terminal, closed shift, POS order, and cash_box rows; preserve it. Preserve historical shift/order/cash records, including the historical -135.00 close difference. Older POS orders with null shift/device fields were not rewritten.
- The live `pos_open_shift` auto-treasury migration and `save_sales_invoice_atomic` terminal/shift treasury routing migration are present in Git and Production. Current POS source already includes no-QR messaging, persists returned terminal/treasury IDs before reloading shift state, requires an open verified shift, sends `shift_id/device_id`, restricts branch, uses generic cash customer, and blocks unsupported non-cash settlement. Do not reapply historical patches blindly.
- Defect confirmed in current source: `loadShiftState` calls `pos_get_shift_summary` without checking `supabase.auth.getSession()` and matching the live session user against `currentUser.auth_id`. Report439 provides the exact one-line replacement wrapping the existing RPC with a session guard. It also documents the still-open shared `core.js` `signOut({scope:'local'})` surgical replacements.
- Report: [Report439_POS_PRODUCTION_SESSION_GUARD_AND_CLOSEOUT_20261018.md](doc/Draft/Reprots/Report439_POS_PRODUCTION_SESSION_GUARD_AND_CLOSEOUT_20261018.md), commit `ed1ec394c04db679875830a1135a4e1b50fa65b2`.
- No Production schema/ACL/business-data changes were applied. No permanent test sale was created. The current automatic treasury was not misclassified or deleted as test residue.
- Closure: `PRODUCTION CORE/ACL VERIFIED / SQL AUTHENTICATED-SIMULATION PASS / OWNER POS + CORE PATCHES READY / HTTP E2E + SERVED ARTIFACT PARITY OPEN / NOT 100% CLOSED`.
- Exact next step: owner applies the Report439 surgical changes to the current POS/core files after confirming their SHAs, deploys through the existing frontend route, then tests a valid cashier session, missing/expired session, wrong-user session, local logout on two devices, open shift, cash sale, cash return, and matching `orders.shift_id/device_id` ↔ `pos_shifts.terminal_id/treasury_id` ↔ `cash_box.shift_id/treasury_id`. Recheck Production logs and served Cloudflare artifact before closure.

# CURRENT FORENSIC CHECKPOINT — 2026-10-18 — Report440 Online Store Public Catalog / Order Submission

## Scope
Standalone public store only: papamohammed77-glitch/erp-frontend/companies/company-1/store/index.html. Do not edit that operational HTML or main.html through the assistant; owner applies the surgical changes in Report440. Supabase Production changes were executed directly.

## Fresh current-source and historical evidence
- Current store HTML SHA: 2d227aa2bbd44df38071313fc0fb848127678f72, 503 lines. Historical rawaie-erp-review/PWA/store/index.html SHA matches; last 10 store-file commits were on 2026-07-21.
- Current Edge source: Current/Edge_Functions/submit-online-order, Git blob SHA 02dcec1fb0826482a946c597cbb972f11480b4f2; commit 63185a9d3950a4c420181d5143d315fbd377824f.
- Production submit-online-order v11 ACTIVE, verify_jwt=false, ezbr_sha256 172eff4fccc8bf43f920e9ab8c83dd39aa988a68c9e5b3170ce320138ff31315. v11 preserves valid authenticated parent-system user context and supports guest checkout only through a published storefront.
- Report440: doc/Draft/Reprots/Report440_ONLINE_STORE_FORENSIC_REPAIR_20261018.md, commit b1b3b48595d48c1bef069749f5f0270d43c42bf8.

## Proven defects and repairs
- Current store directly queried app_settings/items from an anon browser; RLS policies do not permit anon row reads. Public table grants do not bypass RLS.
- items has no qty column, while store UI read item.qty. New public RPC returns qty from main-branch stock_branches.available_qty (fallback qty-allocated_qty).
- Added app_settings.storefront_key/storefront_enabled; current store key is company-1 and is enabled for company 00000000-0000-0000-0000-000000000001.
- Added public.get_public_store_catalog(text), restricted SECURITY DEFINER, safe public fields only; anon/authenticated EXECUTE is granted on this read-only catalog RPC. Direct table reads remain RLS-governed.
- Repaired public.submit_online_order_atomic validation loop to read p_cart_items before pricing and scope item lookup by p_company_id.
- Hidden QA-SR-ITEM-20260927 from public storefront by setting show_in_store=false; the inventory/test record was preserved, not deleted.
- Canonical migration files and Production migration history align:
  - supabase/migrations/20261018203420_public_storefront_catalog_and_public_order_contract.sql (version 20261018203420)
  - supabase/migrations/20261018203424_online_order_core_validation_scope_fix.sql (version 20261018203424)

## Verification
- get_public_store_catalog under SQL role anon returned store settings + 16 public products and no cost_price.
- QA-SR-ITEM-20260927 no longer appears in catalog.
- Transaction-isolated submit_online_order_atomic test: first create succeeded, same operation_id retry returned duplicate=true; outer transaction rolled back.
- Transaction-isolated duplicate-item test rejected repeated item_code; outer transaction rolled back.
- No persistent test order was created; baseline orders count before test was 11.
- Actual HTTP POST/browser E2E could not be run from this environment: outbound DNS/network failed. Do not claim HTTP E2E or served-artifact parity.

## Required owner changes
Apply only Report440 Patches A–D to the store HTML at the exact SHA above:
1. Replace Store.init with error-visible initialization.
2. Replace Store.loadSettings to call get_public_store_catalog('company-1') and populate settings/products.
3. Replace Store.syncProducts to use the RPC payload and update Dexie cache, not query items directly.
4. Replace Store.submitOrder to send storefront_key + persisted operation_id and retain the same idempotency key across retry of identical payload.
Do not replace the whole file and do not edit main.html.

## Open work — do not mark store closed
- Owner patches A–D are not yet applied to the operational store file.
- HTTP/browser E2E and Cloudflare served-artifact parity are OPEN.
- Coupon functionality remains unimplemented end-to-end: coupons table currently has zero rows, lacks company_id, and the order core currently does not apply coupon_code. Do not represent coupon discounts as server-authoritative.
- Displayed discount/price can differ from resolve_sales_pricing_atomic final pricing; a scoped public quote RPC and confirm-before-create flow remain OPEN.
- Stock availability is displayed from main branch but the current cart does not enforce available_qty; do not change the established no-reservation-before-runsheet business contract without an explicit cross-module design.
- Regression test the authenticated RW_OnlineStore consumer in main.html against Edge v11. main.html was not modified.

## Exact next step
Owner applies Report440 Patches A–D to store/index.html only, deploys the existing frontend artifact, then verifies: public catalog loads, no QA fixture appears, guest checkout creates one Pending online_store order, retry returns the same order for the same operation_id, invalid/duplicate item payload is rejected, and the authenticated parent RW_OnlineStore path still resolves company from the real user JWT. Recheck Production logs, baseline data, and Cloudflare served artifact before closure.

## Closure
PRODUCTION BACKEND FOUNDATION REPAIRED / OWNER SOURCE PATCH PENDING / HTTP E2E OPEN / COUPON + PRICE QUOTE OPEN / NOT CLOSED.

## Report440 addendum — final catalog tenant-scope hardening
- Added and applied canonical migration supabase/migrations/20261018204024_public_store_catalog_branch_company_scope.sql; Production migration version 20261018204024, name public_store_catalog_branch_company_scope.
- The public catalog stock join now joins public.branches and requires b.company_id=v_settings.company_id before reading stock_branches, preventing a corrupted cross-company main_branch_id from exposing another company's stock quantities.
- Fresh Production verification: branch_company_scope=true; get_public_store_catalog('company-1') still returns 16 products. No business rows were created.
- Report440 updated with this final verification; latest report commit 82bd47ca1e4799f4074df88c252fdd292135ea38.


## Current checkpoint — 2026-10-19 — Report441 Storage RLS HR helper ACL repair

- Scope: Production error `permission denied for function hr_user_has_permission` during the system-settings/logo-upload workflow. No changes to `erp-frontend/companies/company-1/main.html` or `erp-frontend/companies/company-1/store/index.html`; no new Edge Function; no business data changed.
- Fresh Production facts: `public.hr_user_has_permission(uuid,text)` was executable only by `postgres/service_role`; four Storage policies for employee documents directly invoked it. `app_private.current_user_has_permission(text)` is executable by authenticated and evaluates the current user via `auth.uid()`.
- Production repair applied as migration version `20261018212304`, name `fix_storage_employee_policy_hr_acl_leakage`: updated only `employee_docs_storage_select/insert/update/delete` to use `app_private.current_user_has_permission('hr')`, preserving active-user, company, and employee ownership predicates. The public HR function remains non-executable by `anon/authenticated`.
- Post-change DB verification: zero Storage policies directly reference `public.hr_user_has_permission`; authenticated can execute the private current-user helper; anon cannot; public HR helper remains unavailable to authenticated/anon. Existing `app_settings` policies and triggers were inspected and left unchanged.
- Source migration: `supabase/migrations/20261018212304_fix_storage_employee_policy_hr_acl_leakage.sql`, commit `3016d4db7d1ee2fad7f33061163d5e8f0775fe22`.
- Report: `doc/Draft/Reprots/Report441_STORAGE_RLS_HR_PERMISSION_ACL_FIX_20261019.md`, commit `c0a927dbaeaf0b00b25a407bdcddd5a85265df0c`.
- Important limitation: Supabase Logs query failed at the backend, and no real browser/HTTP logo upload was executed. Do not mark the user-visible workflow fully closed until owner tests upload + save + reload in browser and confirms 2xx. If 400 persists after the HR permission error disappears, inspect the full Storage response body before changing permissions further.
- Next exact step: owner performs the six-step HTTP/browser verification in Report441. Do not edit `main.html` or `store/index.html`; do not grant EXECUTE on `public.hr_user_has_permission` to authenticated/anon.
- Closure: `PRODUCTION POLICY ACL REPAIR APPLIED / DATABASE VERIFIED / HTTP E2E OPEN`.


## Current checkpoint — 2026-10-19 — Report442 Online Store Display Quantity

- Scope: owner-applied surgical UI changes only in `erp-frontend/companies/company-1/main.html` and `erp-frontend/companies/company-1/store/index.html`. The assistant did not edit either operational UI file.
- Fresh source identities:
  - Parent `main.html`: blob SHA `3f9c6727154b72a742b881ecb3050fc2c9d76305`, 32,747 lines. The item marketing modal has no `store_display_qty` input and the save payload omits it.
  - Standalone `store/index.html`: blob SHA `d8b3f963e81f64b20e6b70494995fc0ddd2ae3f2`, 523 lines. Its product badge incorrectly uses physical `item.qty` to show “تبقت ... فقط”; cart controls do not cap additions by display quota.
- Fresh Production evidence:
  - `items.store_display_qty numeric` exists.
  - `save-item v15` accepts the field, maps blank to NULL, validates non-negative numeric values, and writes it.
  - `create_item_with_opening_stock(uuid,jsonb,uuid,numeric,text)` persists the field on creation.
  - `get_public_store_catalog(text)` returns `store_display_qty`, `store_sold_qty`, and `store_remaining_qty`; remaining is capped at zero and NULL when no display limit is set.
  - `submit_online_order_atomic(..., uuid)` enforces the quota transactionally and locks requested item rows; direct EXECUTE is denied to anon/authenticated and granted to service_role.
  - Current company baseline: 17 items, 0 with a display limit, 16 active items shown in store. No data was modified and no persistent fixtures were created.
- No Production schema/ACL/Edge change is required for this UI task. Do not create a new Edge Function.
- Exact owner changes, current line numbers, replacements, and post-deploy test plan are in `doc/Draft/Reprots/Report442_ONLINE_STORE_DISPLAY_QUANTITY_SURGICAL_PATCH_20261019.md`, report commit `ab7d551da6a8703e0d97a66f6456d245cac2b7ec`.
- Required patches: (A) add optional display-quantity input in the item marketing modal; (B) pass blank as NULL and numeric values in the save payload; (C) base the storefront badge only on `store_remaining_qty` when `store_display_qty` is set; (D) enforce the display limit in cart controls; (E) refresh the public catalog after successful checkout.
- Status: `PRODUCTION BACKEND CONTRACT VERIFIED / OWNER SOURCE PATCHES READY / DEPLOYMENT + HTTP/BROWSER E2E OPEN / NOT CLOSED`.
- Next exact step: owner applies Report442 patches only after confirming both current SHAs, deploys existing frontend files, then tests blank/unlimited, quota=5, partial orders, exhaustion, cancellation restoration, item create/edit persistence, and the authenticated parent `RW_OnlineStore` consumer. Recheck live Production logs, served-artifact parity, and test-residue cleanup before closure.


## Current checkpoint — 2026-10-19 — Report443 Parent Orders Source + Operations Filters

- Scope: owner-applied surgical changes only in `erp-frontend/companies/company-1/main.html`, module `RW_Orders`. The assistant did not edit `main.html`, `store/index.html`, or Production.
- Current main source: blob SHA `e8c163e1856bc9cd0ca88eff6c2a2fed1b091b36`, 32,749 lines. Current frontend HEAD `16511abe1af392c0e9cb55bc9bd204d23f46e0e3`; parent `3109c5d38fd151c8f3e349add15875cf21713bf9`.
- Forensic finding: commit `16511abe1af392c0e9cb55bc9bd204d23f46e0e3` changed `main.html` as well as the store. Line 5543 has a duplicated fragment after the badge-text string statement. Remove only that trailing fragment using Report443 PATCH 0 before the other edits.
- Current RW_Orders filters at lines 10232–10243 include date range, customer, status, area and runsheet; source filter and operations-only toggle are absent. Current eligibility contract is: normalized source in `telesales/tele-sales/order-taker/online-store`, status `Confirmed/Pending`, and no `runsheet_id`.
- Fresh Production snapshot at `2026-10-19 14:26:33+00`: 12 orders, source counts `online_store=1`, `order-taker=4`, `pos=5`, `telesales=2`. `create-runsheet` v26 and `append-to-runsheet` v8 have `verify_jwt=true`; their atomic RPC contracts enforce the same source/status/branch-link eligibility. Both core RPCs deny EXECUTE to anon/authenticated and allow service_role.
- Store source: `companies/company-1/store/index.html`, blob SHA `4af4e2f2f7727f84bdad5afb91932d5f7efe2a3e`, 576 lines. It posts to Production `submit-online-order` v11, which writes source `online_store`. No backend or store change is needed for the parent filters.
- Report443 contains the full owner-applied surgical patches: [Report443_PARENT_ORDERS_SOURCE_AND_OPERATIONS_FILTERS_20261019.md](doc/Draft/Reprots/Report443_PARENT_ORDERS_SOURCE_AND_OPERATIONS_FILTERS_20261019.md), latest report commit `0678556497fa25df8287b3e444ad056be0cec96d` (initial report commit `08e224ecc9e1349e50064b6e3cec6e420c24b852`).
- No Production database/schema/RPC/ACL/Edge changes were performed; no test orders were created.
- Status: `CURRENT SOURCE + PRODUCTION CONTRACT VERIFIED / OWNER PATCHES READY / DEPLOYMENT + BROWSER E2E OPEN`.
- Exact next step: owner applies Report443 PATCH 0 first (single-line cleanup), then PATCH 1–8 against the exact current main.html SHA, deploys the parent UI, and runs the report's tests for source filtering, operations eligibility, reset, Realtime, sorting, details, and runsheet creation/append. Do not edit the operational store file or change the Production eligibility contract for this UI task.


# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report444 Main Syntax + Store Production Resync

## Scope
Current parent system `erp-frontend/companies/company-1/main.html`, `RW_Orders` syntax failure, with read-only Production reconciliation for the standalone online store. The assistant did not edit `main.html` or `store/index.html`, and did not modify Production.

## Fresh Git evidence
- Current `main.html` blob SHA: `ad5360b7eeb8dcbeaefdd54760dccd4111b0fdd6`.
- Latest commit: `159b3113a14a1f8a23be759b7085fe7ae148ce21`; parent: `ae287de38618d3de46ccbb93470a84b53434b535`.
- Root cause: commit `159b3113...` inserted `_toggleOperationsOnly: _toggleOperationsOnly,` inside `RW_Orders._refreshData()` rather than inside its returned API object. This causes the current `Unexpected token '}'` parsing error near line 11141.
- Required owner patch is documented completely in [Report444](doc/Draft/Reprots/Report444_MAIN_RW_ORDERS_TOGGLE_SYNTAX_AND_STORE_PRODUCTION_RESYNC_20261019.md): remove the misplaced line and add the property immediately after `_showWithoutRS: _showWithoutRS,` inside `return { ... }`. Do not rewrite the function or change the approved checkbox source contract.
- Current store source SHA: `4af4e2f2f7727f84bdad5afb91932d5f7efe2a3e`. The current file contains the Report442 display-quota card/cart logic and refreshes the catalog after checkout.
- Open store integration gap: current `bodyPayload` does not send a stable `operation_id` or explicit `storefront_key`; Production Edge creates a fresh UUID if no idempotency value is supplied. Retry idempotency across separate client attempts is therefore unproven. Do not silently mark store integration fully closed.

## Fresh Production evidence — project `fiilmooggumokxanwiyx`
- Checked at `2026-10-19 15:50 UTC`.
- `submit-online-order`: v11 ACTIVE, `verify_jwt=false`, `ezbr_sha256=172eff4fccc8bf43f920e9ab8c83dd39aa988a68c9e5b3170ce320138ff31315`.
- `get_public_store_catalog(text)` is a limited public catalog RPC; anon/authenticated can execute this read-only RPC.
- `submit_online_order_atomic(..., p_operation_id uuid)` remains service_role-only; anon/authenticated execution is false.
- Current item snapshot: 17 items, 1 item with display quota, 16 active store items.
- No Production DDL/ACL/Edge changes, no persistent fixtures, and no business rows were created or deleted. SQL logs query failed at backend; do not infer absence of runtime errors from that failure.

## Exact resumption point
1. Owner applies Report444's two-line relocation to current `main.html`; do not touch the rest of the module.
2. Run syntax validation, load the parent system, and verify the operations-only button and existing checkbox eligibility.
3. Reconcile the served Cloudflare artifact and perform browser E2E before closing the UI issue.
4. Address store retry idempotency in a separate surgical patch to `store/index.html`; persist/reuse one operation UUID for the identical checkout payload and pass the published storefront key, then test retry and duplicate prevention without leaving test orders.
5. Do not claim Production/browser closure until the relevant runtime evidence exists.

## Closure
`ROOT CAUSE VERIFIED / OWNER PATCH REQUIRED / PRODUCTION CONTRACT VERIFIED READ-ONLY / STORE RETRY IDEMPOTENCY OPEN / BROWSER E2E OPEN / NOT CLOSED`.


# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report445 Store Idempotency + Parent Orders Resync

- Scope: current online store consumer and parent RW_Orders source/filter behavior. No operational HTML files were modified; no Production schema, ACL, Edge, RPC, or business data was changed.
- Current parent `main.html` blob SHA: `1b38c60ff38d439d429474b17ff54b5b169c07b4`. Commit `1a60b404e1d3c9e2769036618bebf3c66947d1f1` corrected the misplaced `_toggleOperationsOnly` export by moving it from `_refreshData()` into the RW_Orders return object. The source filter and operations-only logic added by `159b3113a14a1f8a23be759b7085fe7ae148ce21` are present in the commit diff. Browser/runtime and served-artifact parity remain unverified.
- One unrelated malformed duplicate fragment remains in the marketing badge-text line introduced by commit `16511abe1af392c0e9cb55bc9bd204d23f46e0e3`; Report445 supplies the one-line owner replacement. Do not rewrite the marketing modal.
- Current store `companies/company-1/store/index.html` SHA: `4af4e2f2f7727f84bdad5afb91932d5f7efe2a3e`, 576 lines. `loadSettings` still calls `get_public_store_catalog` with `p_storefront_key: null`; `submitOrder` sends neither `storefront_key` nor a stable `operation_id`.
- Fresh Production read at `2026-10-19 16:13 UTC`: storefront key `company-1` is enabled for company `00000000-0000-0000-0000-000000000001`; `submit-online-order` v11 ACTIVE, `verify_jwt=false`, hash `172eff4fccc8bf43f920e9ab8c83dd39aa988a68c9e5b3170ce320138ff31315`. Edge generates a fresh UUID when no operation ID is provided. Core `submit_online_order_atomic(..., p_operation_id uuid)` is service_role-only; anon/authenticated direct execute is denied. No backend change is needed for this client defect.
- Production order snapshot: 12 total; `pos=5`, `telesales=2`, `order-taker=4`, `online_store=1`. No test orders were created/deleted. No records were deleted as “test” without provenance.
- Report445: `doc/Draft/Reprots/Report445_STORE_IDEMPOTENCY_AND_PARENT_ORDERS_FORENSIC_RESYNC_20261019.md`. It includes exact surgical changes: (A) remove the duplicated badge-text fragment from main.html; (B) use explicit `company-1` key for catalog lookup; (C) persist/reuse a SHA-256 fingerprint-bound operation UUID, pass storefront key/idempotency header to the existing Edge, and clear the pending key only when the current success flow clears the cart.
- Exact next step: owner applies only Report445 changes after confirming current SHAs; then run syntax validation, parent filter browser tests, isolated retry/duplicate E2E, and served-artifact parity checks. Do not create Production fixtures. Closure remains `OWNER PATCHES READY / PRODUCTION CONTRACT VERIFIED READ-ONLY / BROWSER + HTTP E2E OPEN / NOT CLOSED`.


# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report446 Parent Operations Filter Includes Linked Runsheets

- Scope: owner-applied surgical UI patch only in `erp-frontend/companies/company-1/main.html`, module `RW_Orders`. Assistant did not modify `main.html`, `store/index.html`, Production schema, RPC, ACL, Edge Functions, or business data.
- Current main source was freshly fetched as a full Git blob: SHA `1b38c60ff38d439d429474b17ff54b5b169c07b4`, 32,820 lines. Last source commit known in the checked chain: `1a60b404e1d3c9e2769036618bebf3c66947d1f1`.
- Re-read historical Reports443–445 and compared them against the current source. Current code has the operations button, source filter, and corrected `_toggleOperationsOnly` export. The current defect is semantic: `_applyFilters()` applies `_isRunsheetEligible`, which excludes any order with `runsheet_id` and therefore wrongly hides operational orders already linked to runsheets.
- Fresh Production SQL at `2026-10-19 16:27:10.683668+00 UTC`: 12 total orders; 7 from requested operational sources; 6 linked to runsheets and 1 unlinked. Breakdown: `online_store/Pending=1` unlinked; `order-taker/Pending=4` all linked; `telesales/Pending=2` all linked.
- No Production backend repair is warranted: the orders exist and the defect is in the parent UI predicate. Do not alter RPC eligibility or checkbox rules.
- Exact owner patch: [Report446_PARENT_ORDERS_OPERATIONS_FILTER_INCLUDE_LINKED_RUNSHEETS_20261019.md](doc/Draft/Reprots/Report446_PARENT_ORDERS_OPERATIONS_FILTER_INCLUDE_LINKED_RUNSHEETS_20261019.md), commit `21b067a162a26b7cd3cbdf4d7bb94ad2e9953003`. Replace `_isRunsheetEligible(order)` with source-only `_isOperationsOrder(order)`, and change the single `_applyFilters()` predicate to use it. Keep checkbox `runsheetEligible` logic unchanged.
- Status: `ROOT CAUSE VERIFIED / OWNER PATCH READY / PRODUCTION UNCHANGED / BROWSER E2E OPEN`.
- Next step: owner applies only Report446 PATCH A–B against the exact current main SHA, runs full JavaScript syntax validation, then verifies the button shows the 7 current operational orders (including all 6 linked orders) while checkbox eligibility remains restricted. Verify the deployed Cloudflare artifact and browser behavior before closing. Do not create synthetic Production orders.


## Current checkpoint — 2026-10-19 — Report447 Public Store Order Tracking

- Scope: public storefront order tracking contract and owner-only surgical patch to `erp-frontend/companies/company-1/store/track.html`. Do not edit `main.html`, `store/index.html`, or `store/track.html` on behalf of the owner.
- Current `track.html` source SHA: `bca9cddc3977bd4beb164acb811a0c82138a2d70` (213 lines). Current `store/index.html` source SHA observed: `75cca148ade533a3e6d7c73469c7a989c8016644`.
- Historical check: commit `6f9bff32d4f6a036b199500ae8746a89abf2b48d` (2026-07-08) centralized Supabase client loading through `core.js` but did not repair the direct table query in tracking.
- Production facts: `orders` and `order_details` both have RLS enabled; current SELECT policies are for authenticated users, not public anonymous tracking. `order_details` has `order_id` and does not have `order_code`. The previous page queried both tables directly and ignored returned Supabase errors.
- Production Edge `submit-online-order` v11 uses `submit_online_order_atomic`; public store requests are scoped by published `storefront_key`, and online orders use source `online_store`.
- Production migration applied: version `20261019163902`, name `create_public_store_order_tracking_rpc`. New RPC: `public.get_public_store_order_tracking(text,text,text)`; resolves exactly one enabled storefront company, restricts lookup to that company and `source='online_store'`, verifies the provided customer phone, returns only the tracking projection and order items, and never returns the phone. ACL: `anon=true`, `authenticated=true`, `service_role=false` for EXECUTE.
- SQL verification: invalid store key and nonexistent order both return `success=false`; existing online-store order verified in SQL without disclosing customer PII, returning `success=true`, a valid items array (3 lines), and `phone_exposed=false`. No Production business rows were inserted, updated, or deleted.
- Canonical migration file: `supabase/migrations/20261019163902_create_public_store_order_tracking_rpc.sql`, commit `80c90254678bda8773bb3a0d1b1d754ff5100314`.
- Report: [Report447_STORE_ORDER_TRACKING_FORENSIC_REPAIR_20261019.md](doc/Draft/Reprots/Report447_STORE_ORDER_TRACKING_FORENSIC_REPAIR_20261019.md), latest report commit `097965d877105dc05f5a7d2112037fe7b94dfd3a` (initial commit `c1f97446925b875df67e7bf094dee20adbe1ccab`). The report contains exact owner patches for adding the phone field, using the RPC, status progress, HTML escaping, and Enter-key handling.
- Logs query returned a backend error; no operational conclusion was drawn from logs.
- Status: `PRODUCTION RPC DEPLOYED + SQL VERIFIED / OWNER UI PATCH REQUIRED / BROWSER E2E OPEN / NO TEST RESIDUE`.
- Next step: owner applies Report447 patches A–F only to `track.html` against SHA `bca9cddc3977bd4beb164acb811a0c82138a2d70`, deploys the operational app, then performs all tests in section 5 of Report447. Verify served artifact parity and browser Network/Console before claiming end-to-end closure. Do not add a new Edge Function and do not create synthetic Production orders.


# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report448 Store Tracking Single-Identifier Lookup

## Scope
Only public online-store order tracking. No edits to main.html, store/index.html, or operational track.html were made by the assistant. Production RPC was updated because live evidence confirmed the existing contract required both fields.

## Fresh source and history
- Current operational page: erp-frontend/companies/company-1/store/track.html, blob SHA b798587e8deccfdd875d70d1eecc0416731f91ad, 245 lines.
- Latest page commit: 92d7a307f502f9601889acb9d5fccb3c94d4b38c (2026-10-19 19:59 +03).
- Historical baseline: rawaie-erp-review/PWA/store/track.html, blob SHA bca9cddc3977bd4beb164acb811a0c82138a2d70.
- Report447 is historical and superseded for the new single-identifier requirement by Report448 below. Its RPC/UI design required both order code and phone, which did not satisfy the owner's latest requirement.
- The current UI already uses get_public_store_order_tracking and escapes HTML, but Tracker.lookup still rejects a request unless both orderCode and customerPhone are present. The UI remains owner-managed; do not edit it directly.

## Live Production change
- Supabase project: fiilmooggumokxanwiyx.
- Migration version: 20261019170525; name store_order_tracking_single_identifier_lookup_20261019.
- Canonical source: supabase/migrations/20261019170525_store_order_tracking_single_identifier_lookup_20261019.sql, commit bdcf317c24b29ceacc28f6aa5ec35660dfc6ccee.
- Updated existing RPC only: public.get_public_store_order_tracking(text,text,text). No new Edge Function was created.
- Contract: order-code-only returns order code/date/status only; phone-only returns up to 10 recent order code/date/status summaries; both matching values return the previous full permitted projection and items. Single-input responses do not return customer name, area, amount, or items.
- Company resolution still requires exactly one enabled storefront mapping; all reads are scoped to that company and source='online_store'. Phone input must normalize to at least 7 digits.
- Live SQL E2E using an existing Production online-store order passed for code-only, phone-only, and matching code+phone. Invalid code, no inputs, and invalid storefront were rejected. Checks confirmed no customer name, amount, or items are returned for either single-input mode.
- Live ACL after change: anon EXECUTE=true, authenticated EXECUTE=true, service_role EXECUTE=false. Function remains SECURITY DEFINER with a narrow projection and company/source constraints.
- No business data was inserted, updated, or deleted. No test residue was created.

## Owner-only surgical patch and closure
- Report: doc/Draft/Reprots/Report448_STORE_TRACKING_SINGLE_IDENTIFIER_LOOKUP_20261019.md, commit 654c67b11e42ae4bdfb275b972c5d1a7776669c7.
- Report448 contains exact changes for current track.html SHA b798587e8deccfdd875d70d1eecc0416731f91ad: update helper text; replace Tracker.lookup; add Tracker.showOrderList; add lookupMode to showStatus and conditionally hide customer/area/amount for single-input lookup.
- The owner must apply only those surgical changes to track.html, deploy the operational app, and verify the served Cloudflare artifact.
- Browser E2E, served artifact parity, and actual customer-device behavior remain UNVERIFIED until the owner patch is deployed and tested. Do not claim end-to-end closure based only on SQL.
- Next exact step: owner applies Report448 patches A-D against the exact SHA above, then tests order-code-only, phone-only, matching code+phone, invalid phone/code, empty inputs, Enter-key handling, HTML escaping, Network calls, and Console. Verify only one RPC is called and no direct orders/order_details reads occur.

## Closure
PRODUCTION RPC DEPLOYED + LIVE SQL VERIFIED / OWNER UI PATCH READY / BROWSER E2E OPEN / NO TEST RESIDUE.


# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report449 Picker Integration

- Scope: `erp-frontend/companies/company-1/warehouse/picker.html` integration audit only. Assistant did not modify `main.html`, the operational picker file, Production SQL, ACL, Edge Functions, or business data.
- Current picker source read in full: 925 lines, blob SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`. Historical baseline read: `rawaie-erp-review/PWA/warehouse/picker.html`, SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`. Latest matching picker commit found: `703342f4fadb046388bcdeb826b4911167c96b67` (2026-08-17), which introduced company scoping and `users.auth_id` lookup; preserve this hardening.
- Fresh Production Edge: `start-picking v34` (`verify_jwt=true`, hash `706840bfe745f2e12b4584ff99dc9d7d6c08a5ef5f35f5afb0a57a684aaa1adf`); `complete-picking v17` (`verify_jwt=true`, hash `eb631b8f3ed33b51847bad5cdf7868eaeada70221cf001ea2bd4c53bc768f1df`); `cancel-picking v4` (`verify_jwt=true`, hash `e8013e0e06dd38503e3bc9c44a62c8b689212b145a9bbb44f45f48d99cdc5c66`); `reopen-picking v8` (`verify_jwt=true`, hash `b095383e169f2c2736a7c71d7505fc10fc9893d428a948199d7ffc420ecfa9e9`).
- Confirmed defect: current `App.editPickedItem(index)`, line 643, attempts a direct `UPDATE run_sheet_details.qty_picked` and silently ignores the result. Production RLS grants authenticated users SELECT only on `run_sheet_details`, and the table grants contain no authenticated UPDATE. The table is a derived projection maintained by `trg_sync_run_sheet_details` / `sync_run_sheet_details()` from `order_details`. Remove only that direct update line; do not grant UPDATE or replace it with direct `order_details` writes.
- Two additional source-confirmed read-error gaps: `renderPendingTab()` ignores resolved PostgREST errors in both Promise results, and `openRunsheet()` ignores errors from the runsheet and details reads. Exact guards are in Report449.
- Core contract verified live: `complete_runsheet_picking(..., p_operation_id uuid DEFAULT NULL)` validates the runsheet/company, calls `reserve_stock`, updates `order_details.qty_picked`, and sets status `Picked`; the trigger refreshes the derived `run_sheet_details` projection. No physical stock movement is expected during picking.
- Production logs showed a successful authenticated GET of `run_sheet_details` from `https://rawaea-erp.pages.dev/` at `2026-10-19T17:14:26Z`; this does not prove served HTML byte parity or a successful/failing PATCH. Production snapshot contained 2 `Open` runsheets; none were mutated and no test data was created/deleted.
- No Production change was warranted. No HTTP E2E was run because the only observed open runsheets may be live work and no isolated fixture was proven. Staging/served artifact parity remains open.
- Report: [Report449_PICKER_FORENSIC_INTEGRATION_AND_SURGICAL_FIX_20261019.md](doc/Draft/Reprots/Report449_PICKER_FORENSIC_INTEGRATION_AND_SURGICAL_FIX_20261019.md), commit `f8056c80acd2231015c926a69565e1205fd3a29d`.
- Owner next step: apply only Report449 patches A–C to current picker SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`, then run syntax validation and isolated E2E. Do not modify `main.html`; do not grant direct UPDATE on `run_sheet_details`; verify Cloudflare served artifact before closure.
- Status: `ROOT CAUSE VERIFIED / OWNER SURGICAL PATCHES READY / PRODUCTION UNCHANGED / HTTP E2E + SERVED PARITY OPEN / NOT CLOSED`.


# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report450 Picker Server Authorization + Draft Persistence

## Scope
Only picker integration and its direct server-side security contract. The operational file `erp-frontend/companies/company-1/warehouse/picker.html` and `main.html` were not edited by the assistant. No new Edge Function was created. No Production business rows were changed.

## Fresh source and history
- Operational picker re-read in full: 925 lines, blob SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`.
- Historical picker baseline in both review PWA and New/Original: blob SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`.
- Latest picker-specific commit located: `703342f4fadb046388bcdeb826b4911167c96b67` (2026-08-17). More recent repo commits checked were unrelated to picker.
- The previous Report449 owner patches remain applicable: exact PostgREST error guards in `renderPendingTab()` and `openRunsheet()`, and removal of the direct `run_sheet_details.qty_picked` update. Do not repeat or broaden those changes.

## Production authorization fix — executed and re-read
The four existing Production Edge Functions now enforce the database permission model server-side in addition to JWT authentication:
- direct `public.users.permissions` must contain `warehouse`, or
- the assigned `public.roles.permissions` must contain `warehouse`, or
- verified owner exception requires auth metadata `isOwner=true`, direct user permission `*`, and a matching `owner_profile` row.
- Non-owner users must have `active_warehouse_role='تحضير'`.
- User/company/status and role/owner lookup errors fail closed.
- Core RPC grants remain restricted from `anon/authenticated`; Edge → service_role → core boundary is preserved.

| Function | Production version | verify_jwt | Production ezbr_sha256 |
|---|---:|---|---|
| `start-picking` | 35 | true | `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a` |
| `complete-picking` | 18 | true | `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537` |
| `cancel-picking` | 5 | true | `218052d71120eeab9f83aff045a14e24173dd15f3dafdb4e91978e7dd7bbda01` |
| `reopen-picking` | 9 | true | `ca69477e935cb78b7f9cebe13940e589c58adcf891ee16e26cc15354c735b3ae` |

The deployed objects were fetched again after deployment and contain the authorization check. Supabase unified-log query failed with a backend error; do not claim log-based runtime E2E.

## Current source provenance synchronized
The four `rawaie-erp-New/Current/Edge_Functions/` files now match the deployed Production function source:
- `start-picking`: blob `14188f5d60d70cc4ec214cd27145398979e06403`, commit `0fd979e756b0994e333fb57405da6a1cee938673`.
- `complete-picking`: blob `be06ac006adc146df46adc893e18105d95c0e9a3`, commit `8f7ca687750e88c265da0b06c625552ee04abef5`.
- `cancel-picking`: blob `69005b8c8b73baad5d54a9af9e155d45b621014f`, commit `80ff793ccdc120cdaa90a622ed29789167520fa9`.
- `reopen-picking`: blob `fe7d6f77f1f34ba141f47d6af6e33ac5e8443ac2`, commit `5a8aea2f545e33adbc541fa0f414cef68c01c340`.
- Historical/Original files remain untouched.

## New source-proven picker findings
- Line 643 attempts a direct UPDATE to `run_sheet_details.qty_picked` and ignores the response. Production has authenticated SELECT but no authenticated UPDATE on this table.
- `sync_run_sheet_details()` is triggered by writes to `order_details` and rebuilds `run_sheet_details` as a derived projection. The PWA must not be granted direct UPDATE and must not write directly to `order_details`.
- Dexie declares a `session` store keyed by `runsheet_code`, but the current PWA never writes a session to it; it only clears the store on cancel/complete. Draft quantities held in memory can therefore be lost on refresh before completion.
- Report450 contains exact surgical owner patches: remove the ignored write; persist/restore a device-local draft using the existing Dexie store with runsheet id + picker_start session identity; and preserve the Report449 read-error guards.

## Report and closure
- Report450: `doc/Draft/Reprots/Report450_PICKER_SERVER_AUTHORIZATION_AND_DRAFT_PERSISTENCE_20261019.md`, commit `3a1a46f0a6abf941fee0f9809d141e2dc3bed3fa`.
- No authenticated HTTP E2E was run; no existing Open runsheet was used as a test fixture. Served Cloudflare HTML parity remains unverified.
- Status: `PRODUCTION AUTHORIZATION HARDENED / CURRENT EDGE SOURCE SYNCED / OWNER PICKER PATCHES PENDING / HTTP E2E + SERVED PARITY OPEN / NOT CLOSED`.

## Exact resumption point
1. Owner applies Report449's existing read-error patches plus Report450 patches A–C to picker blob `c7ad267d852d415b680aed7716833eea9bcffdf6`; do not edit `main.html`.
2. Re-fetch the picker source after changes and recalculate line numbers before any further edit.
3. Run syntax validation, served-artifact parity checks, and isolated authenticated E2E with authorized and denied accounts.
4. Verify complete picking updates `order_details`, the derived trigger updates `run_sheet_details`, reservation is correct, no physical movement is logged by picking, and cancel/reopen lifecycle remains valid.
5. Verify no fixture/test residue remains before claiming closure.


# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report451 Picker Production Resync + Idempotent Completion

## Fresh same-session verification
- Scope: `erp-frontend/companies/company-1/warehouse/picker.html`; no edits to `main.html` or the operational HTML by the assistant.
- Current picker source re-fetched in full: SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`, 925 lines. No newer picker-specific commit found; latest matching commit remains `703342f4fadb046388bcdeb826b4911167c96b67`.
- Original baseline: `rawaie-erp-New/Original/PWA/warehouse/picker.html`, SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`, 623 lines.
- Production SQL was checked at `2026-10-19 18:16:17.823361+00 UTC`.
- Production Edge objects re-fetched: `start-picking v35`, `complete-picking v18`, `cancel-picking v5`, `reopen-picking v9`; all `verify_jwt=true`. Their `index.ts` content matches the corresponding `rawaie-erp-New/Current/Edge_Functions/` files exactly. Git blob SHAs and Production `ezbr_sha256` values remain distinct identifiers.
- Production confirms `run_sheet_details` has no authenticated UPDATE grant/policy and is a projection rebuilt by `sync_run_sheet_details()` from `order_details`. Do not grant UI UPDATE and do not write to `order_details` from the PWA.
- The live Core `complete_runsheet_picking(..., p_operation_id uuid)` supports idempotent replay when the caller sends an operation ID. Current Picker still sends only `runsheet_code` and `items`; this consumer omission is newly recorded in Report451.
- Production log query returned a backend error; Cloudflare page retrieval was inaccessible through the available web fetch. Do not infer runtime success or served parity.
- No Production business data, schema, ACL, triggers, Edge functions, or current operational HTML were changed.

## Report451
- Report: `doc/Draft/Reprots/Report451_PICKER_PRODUCTION_RESYNC_IDEMPOTENT_COMPLETION_20261019.md`
- Commit: `9d43d981cce914235c078126c558e15a8a961dfc`
- Report451 freshly reconciles Report449/450 against current Production and confirms the earlier patches remain pending owner application.
- New Patch E: send and persist a stable UUID `operation_id` / `Idempotency-Key` for `complete-picking`, restore it with the same local draft session, and reset it only when the picked payload changes. This is a consumer-only surgical patch; no new Edge Function or Production schema/ACL change is needed.
- Legacy 4-argument `complete_runsheet_picking` overload exists but is not executable by `anon/authenticated/service_role`; the current Edge calls the 5-argument overload. No direct SQL caller to the old overload was found in the routine-source scan. Do not drop it as part of this Picker change without a separate full dependency/lineage proof.

## Exact resumption point
1. Owner applies Report449 patches A–C and Report450 patches A–C against picker SHA `c7ad267d852d415b680aed7716833eea9bcffdf6`, without editing `main.html`.
2. Apply Report451 Patch E1–E4 to complete the existing idempotency contract. Preserve the Dexie draft save/restore from Report450.
3. Re-fetch the file after edits; calculate the new SHA and line numbers. Run full JavaScript syntax validation.
4. Verify Cloudflare served HTML parity, then run authenticated isolated E2E for allowed/denied users, draft recovery, normal completion, same-operation retry, payload-changed new operation, cancel, reopen, reservation, and no physical movement.
5. Verify Production baseline/test residue before closure. Do not use an Open business runsheet as a fixture.

## Closure
`PRODUCTION EDGE/CURRENT CONTENT PARITY VERIFIED / OWNER PICKER PATCHES PENDING / IDEMPOTENT CONSUMER PATCH DOCUMENTED / SERVED PARITY + AUTHENTICATED HTTP E2E UNVERIFIED / NOT CLOSED`.


# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report452 Picker Consolidated Owner Patch Set

## Scope
Only erp-frontend/companies/company-1/warehouse/picker.html integration with the runsheet picking lifecycle. The assistant did not edit the operational Picker HTML or main.html. No Production schema, ACL, Edge Function, or business data was changed in this cycle.

## Fresh current evidence — 2026-10-19
- Current Picker source SHA: c7ad267d852d415b680aed7716833eea9bcffdf6, 925 lines. It still contains the direct run_sheet_details.qty_picked UPDATE and does not yet use db.session.put/get or send operation_id.
- Historical Original Picker SHA: 7626ba320021a607854bf219f4bacd81fc3d1d92, 623 lines. Preserve current company scoping and public.users.auth_id identity mapping introduced by the relevant historical commit.
- Production Edge re-read: start-picking v35, complete-picking v18, cancel-picking v5, reopen-picking v9; all verify_jwt=true.
- Production Edge source matches the corresponding rawaie-erp-New/Current/Edge_Functions/ source exactly. Git blob SHA and ezbr_sha256 are separate identifiers.
- SQL checked at 2026-10-19 19:21 UTC: five-argument complete_runsheet_picking(..., p_operation_id uuid) is executable by service_role only; four-argument overload is not executable by anon/authenticated/service_role. reserve_stock is protected from anon/authenticated.
- run_sheet_details and order_details have RLS enabled; authenticated SELECT=true and UPDATE=false. trg_sync_run_sheet_details runs on order_details INSERT/UPDATE/DELETE and maintains the derived projection.
- Supabase logs show OPTIONS 200 and GET 200 for run_sheet_details from https://rawaea-erp.pages.dev/ at 2026-10-19T17:14:26Z. This is read evidence only, not a completion E2E or proof of Cloudflare served-byte parity.
- No Production business data or fixture was created, deleted, or changed. Existing open runsheets were not used as test data.

## Consolidated owner changes
Report452 consolidates Report449 patches A-C, Report450 local Dexie draft persistence, and Report451 operation-idempotency E1-E4 into a single ordered surgical set:
1. Remove the direct update to run_sheet_details.
2. Add resolved-error guards in renderPendingTab() and openRunsheet().
3. Save/restore the local draft only when runsheet_id and server picker_start identity match.
4. Clear operation_id when quantity/notes payload changes and persist the changed draft.
5. Generate a UUID once per completion payload, persist it before HTTP, send it in body and Idempotency-Key, and restore it with the same draft session.

## Report
- doc/Draft/Reprots/Report452_PICKER_449_451_CONSOLIDATED_SURGICAL_INTEGRATION_20261019.md
- Report452 commit: bb688eb34316c9a9189c694e58e8c28228fc90eb
- No Production deployment or data change was required by the verified evidence.

## Closure status
PRODUCTION CORE/EDGE VERIFIED / OWNER PATCH SET CONSOLIDATED / OPERATIONAL HTML UNCHANGED / SERVED PARITY + HTTP E2E OPEN / NOT CLOSED.

## Exact resumption point
1. Re-fetch erp-frontend/companies/company-1/warehouse/picker.html and confirm its SHA before applying Report452.
2. Owner applies the six consolidated patches only; do not edit main.html and do not grant authenticated UPDATE on run_sheet_details.
3. Re-fetch the file, inspect the resulting diff, run full JavaScript syntax validation, and verify no direct projection UPDATE remains.
4. Deploy through the existing deployment path, then prove Cloudflare served artifact parity.
5. Run authenticated, isolated E2E for draft recovery, normal completion, same-operation retry, changed-payload new operation, cancel/reopen, company/role isolation, projection synchronization, and no physical stock movement during picking.
6. Restore and verify the test baseline before declaring closure.

# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report453 Picker Live Resync

## Scope
Only `erp-frontend/companies/company-1/warehouse/picker.html` integration with the picking lifecycle. `main.html` and the operational Picker file remain owner-controlled and were not edited by the assistant. No Production schema, ACL, Edge Function, or business data was changed in this cycle.

## Fresh current-source evidence
- Picker current blob SHA: `3f3fab73c30dd2861e43747e6cc774d86739244b`; 51,413 characters / 966 lines.
- Latest matching commit inspected: `b903c403c8bebf7f98307d22f9c7ca286c72382e` — “Improve error handling and session management in picker”.
- The latest commit has already applied the earlier Report449 changes: no direct `run_sheet_details` UPDATE remains; `renderPendingTab()` checks both resolved query errors; `openRunsheet()` checks runsheet and detail-read errors.
- The current source partially implements Report450 draft persistence: it restores a saved Dexie session when `runsheet_id` and server `picker_start` match, and writes the session when opening the active runsheet. It still does **not** persist every quantity/notes edit.
- The current Picker does **not** mention `operation_id` or `Idempotency-Key`; the completion consumer still sends only `runsheet_code` and `items`.
- Static current-source scan: direct projection updates=0; pending/runsheet/details read guards=present; `db.session.get`=1; `db.session.put`=1; idempotency mentions=0.

## Fresh Production resync
- Checked at `2026-10-19 19:59:21.177102+00 UTC`: 2 runsheets, 12 run-sheet detail rows, 57 stock-branch rows. Current runsheets `RS-1` and `RS-2` are both Open with no picker assigned and zero picked quantities; treated as real business data, not test fixtures.
- Production Edge and `rawaie-erp-New/Current/Edge_Functions` content were compared directly. Exact content parity: `start-picking v35`, `complete-picking v18`, `cancel-picking v5`, `reopen-picking v9`; all `verify_jwt=true`. Production deployment hashes are recorded separately from Git blob SHAs in Report453.
- Live SQL reconfirmed that the five-argument `complete_runsheet_picking(..., p_operation_id uuid)` is the current service_role-only completion contract; `run_sheet_details` is a derived projection with authenticated SELECT but no UPDATE; `trg_sync_run_sheet_details` rebuilds it from `order_details`.
- No new Production change is warranted. No production fixture was created or business data modified. Served Cloudflare HTML parity and authenticated HTTP/browser E2E remain unverified.

## Exact remaining owner patches
Report453: [Report453_PICKER_LIVE_RESYNC_AND_REMAINING_SURGICAL_PATCH_20261019.md](doc/Draft/Reprots/Report453_PICKER_LIVE_RESYNC_AND_REMAINING_SURGICAL_PATCH_20261019.md), commit `0ef311dd9586a23fa450c36ee2597ef167ddc419`.

1. Apply **PATCH 453-A** only: in `App.editPickedItem(index)`, save each edited local session to Dexie and reset the existing `operation_id` only when quantity/notes payload changes.
2. Apply **PATCH 453-B** only: in `App.completePicking()`, generate/persist a stable UUID before HTTP, and send it as both `operation_id` and `Idempotency-Key`.
3. Do not reapply Report449 read guards or projection-write removal; they are already present in current source.
4. Do not edit `main.html`, grant UPDATE on `run_sheet_details`, or write directly to `order_details` from the PWA.
5. After owner application, refetch current HTML and inspect its new SHA/diff; run JS syntax validation; verify local draft recovery, normal completion, same-operation retry, changed-payload new operation, cancel/reopen, company/role isolation, trigger projection sync, reservation correctness, no physical stock movement during picking, served-artifact parity, and zero test residue. Use an isolated fixture only; do not mutate `RS-1`/`RS-2`.

## Closure
`CURRENT SOURCE RESYNCED / PRODUCTION EDGE-CORE VERIFIED / TWO OWNER PATCHES REQUIRED / SERVED PARITY + AUTHENTICATED HTTP E2E OPEN / NOT CLOSED`.



# CURRENT FORENSIC CHECKPOINT — 2026-10-19 — Report454 Picker Syntax Error

## Scope
Only the syntax blocker in `erp-frontend/companies/company-1/warehouse/picker.html`. The assistant did not edit `main.html` or the operational Picker HTML; owner applies the surgical source patch.

## Fresh evidence
- Current Picker blob SHA: `f87c539e32074ae0e586e3ccd7ff2add68cffe1f`.
- Latest Picker commit: `0c1ea67bc81ee5e001af69d0366de90ede8795f7`; parent: `b903c403c8bebf7f98307d22f9c7ca286c72382e`.
- The parent commit introduced a multiline string inside single quotes in `App.renderPendingTab()`, in the newly added resolved-query-error branch. That is the direct cause of the parser failure; `App is not defined` is downstream because the inline script never parses.
- The earlier parent baseline `09f62423b7ad7f455a97467d1f9885dce000afa8` had no such branch.
- Live Supabase Edge checked: `start-picking v35`, `complete-picking v18`, `start-loading v5`, `complete-loading v11`; all observed with `verify_jwt=true`. Relevant completion/reservation core functions remain service-role-only as observed. No database or Edge change is needed for this JavaScript syntax defect.
- No source HTML, Production data, SQL, ACL, or Edge deployment was changed. No test fixtures were created.

## Exact resumption point
1. Open [Report454](doc/Draft/Reprots/Report454_PICKER_SYNTAX_ERROR_ROOT_CAUSE_AND_SURGICAL_PATCH_20261019.md).
2. In `App.renderPendingTab()`, replace only the malformed error branch with the valid `safeHTML(..., '<div ...>...</div>')` replacement in Report454.
3. Run a syntax check on the inline JavaScript, deploy via the existing owner-controlled path, and reload with cache disabled.
4. Verify that `Uncaught SyntaxError` and downstream `App is not defined` disappear; verify login button handlers and both normal/error runsheet-load paths.
5. Re-fetch the deployed source and record the new blob SHA and browser evidence. Do not change `main.html` or Production schema/RPC/ACL for this UI parse error.

## Closure status
`ROOT CAUSE PROVEN / SURGICAL PATCH DOCUMENTED / OWNER APPLICATION + SERVED RUNTIME VERIFICATION OPEN / NOT CLOSED`.

## Current checkpoint — 2026-10-20 — Report422 Picker Product Image Preview

- **Scope:** only `erp-frontend/companies/company-1/warehouse/picker.html`; owner applies the UI edits. No edit was made to `picker.html` or `main.html` by the assistant.
- **Current source:** GitHub blob SHA `b85e81ef1303e6abbb086fa35acdf84bf9638075`, 1,003 lines. Last matching recent commit found: `15da299daa62262a7a365f58ca5ed118f905c2a7` (2026-10-19, “Refactor error handling in picker.html”). The source was read around `App.showItemDetail()` and `App.editPickedItem()`.
- **Root cause:** preview image uses `h-48 object-cover` in `showItemDetail` and a small `w-20 h-20 object-cover` image in `editPickedItem`; modal width is 380px in the first path. The list thumbnail `App._img()` is intentionally small and must not be changed.
- **Owner surgical change report:** [Report422_PICKER_PRODUCT_IMAGE_PREVIEW_SURGICAL_CHANGE_20261020.md](doc/Draft/Reprots/Report422_PICKER_PRODUCT_IMAGE_PREVIEW_SURGICAL_CHANGE_20261020.md), commit `d7a4dc36acce0e1afec4822472a1d06ccc517357`.
- **Proposed patch:** enlarge the preview to 320px high and the picking-entry image to 288px high, use `object-contain` to avoid cropping packaging, and make both modal widths responsive up to 560px. Keep all picking quantity, notes, session persistence, and operation-id behavior unchanged.
- **Production/Supabase:** no DB, RPC, Edge Function, ACL, or data change was indicated or performed; this is a presentation-only defect. No fixture or synthetic business data was created.
- **Verification status:** source diagnosis and exact replacement text documented. Owner must apply the two image-line replacements and modal width adjustments, then test square/portrait/landscape images, missing/broken image fallback, save/reopen quantity and notes, and 360px mobile layout. No browser E2E or deployed Production parity is claimed.
- **Closure:** `SURGICAL PATCH READY / OWNER APPLY + BROWSER VERIFICATION OPEN`.


## Current checkpoint — 2026-10-20 — Report455 Picker editPickedItem Syntax Error

- Scope: only `erp-frontend/companies/company-1/warehouse/picker.html`. The owner applies the source edit; do not edit `main.html` or the operational HTML through the assistant.
- Fresh current source blob: `12e74e484702598b28a2234734fa7dc92db4101e`, 1,004 lines / 52,798 characters.
- Latest commit: `f99c9bca6a0caeeb933880c1de80185db27d1a0d` (2026-10-20 14:07 UTC), parent `15da299daa62262a7a365f58ca5ed118f905c2a7`. Parent blob `b85e81ef1303e6abbb086fa35acdf84bf9638075` had a valid `title` property.
- Root cause: current `App.editPickedItem(index)`, lines 682–683, leaves `title:` without a value and places `width:` where the title value should be. This causes a parser error; `App is not defined` is downstream.
- Exact owner patch and tests: [Report455_PICKER_EDIT_ITEM_SYNTAX_FIX_20261020.md](doc/Draft/Reprots/Report455_PICKER_EDIT_ITEM_SYNTAX_FIX_20261020.md), report commit `5e3e570e17c09dad16b73ad885e1a48bcc62b2d6`.
- Production was inspected: `start-picking v35`, `verify_jwt=true`, hash `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a`. Its identity lookup uses `users.auth_id = auth.users.id`; no Supabase/DB/ACL/Edge change is indicated for this frontend syntax defect.
- No operational HTML, `main.html`, database, or Production data was modified; no fixtures were created.
- Closure: `ROOT CAUSE PROVEN / OWNER PATCH DOCUMENTED / OWNER APPLICATION + SYNTAX CHECK + SERVED HTML + BROWSER E2E OPEN / NOT CLOSED`.
- Next exact step: owner replaces only the malformed two-line `title/width` fragment in `App.editPickedItem(index)` with the Report455 replacement. Then refetch the source, run syntax validation, deploy through the existing owner-controlled path, and verify the served artifact/browser. Do not reapply Report454's older unrelated syntax fix.


## Current checkpoint — 2026-10-20 — Report456 Picker Over-Quantity Validation

- **Scope:** only `erp-frontend/companies/company-1/warehouse/picker.html`; owner applies the UI patch. Do not edit `main.html` or the operational app directly.
- **Fresh source:** blob SHA `13f0b5337749e5796774028989f92ffe95e5667b`, 1,004 lines / 52,782 characters. Latest commit checked: `88fde32d59c96ed1158d8ecdf49071de2d11b008` (“Fix Swal.fire title order in picker.html”), whose diff fixes the malformed title/width property only. The previously reported syntax defect is no longer present in current Git; do not reapply Report455.
- **Existing image patch:** Report422's larger `object-contain` images and responsive width are present in the fresh current source; do not reapply.
- **Root cause now found:** `App.editPickedItem(index)`, current lines 687–689, uses `Math.min(parseInt(...), it.qty_ordered)`, silently converting any oversized quantity to the requested maximum. The HTML `max` attribute alone does not prevent manual entry in the embedded input.
- **Historical comparison:** `rawaie-erp-review/PWA/warehouse/picker.html`, blob SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`, contains the same clamp pattern; the defect is historical/persistent rather than introduced by the latest title fix.
- **Live Production:** `complete-picking` v18, `verify_jwt=true`, `ezbr_sha256=14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`. Current Edge calls `complete_runsheet_picking(..., p_operation_id)`.
- **Database contract:** `public.complete_runsheet_picking(uuid,text,text,jsonb,uuid)` is SECURITY DEFINER with `search_path=public`; privileges checked: anon=false, authenticated=false, service_role=true. Its definition rejects `rec.picked_qty > total_qty` before reservation and order-detail updates. Thus no Production DB/Edge/ACL change is needed for this UI warning defect. A legacy 4-argument overload exists, but was not changed because it is not the current Edge call and has not been proven causal here.
- **Owner change package:** [Report456_PICKER_OVERQUANTITY_VALIDATION_20261020.md](doc/Draft/Reprots/Report456_PICKER_OVERQUANTITY_VALIDATION_20261020.md), commit `8bdeb90ebecc6f27100830dade686e8504a1db80`. It replaces only the `preConfirm` callback with explicit validation and an Arabic warning; no application source was edited by the assistant.
- **No test data:** no fixtures or business rows were created/deleted; this front-end validation defect does not require production data changes.
- **Closure status:** `ROOT CAUSE PROVEN / PRODUCTION RPC GUARD VERIFIED / OWNER PATCH READY / OWNER APPLICATION + SERVED ARTIFACT + BROWSER E2E OPEN`. Do not claim full closure until owner applies the patch and browser tests pass.
- **Next exact step:** owner replaces only the `preConfirm` block specified in Report456 against current source SHA `13f0b5337749e5796774028989f92ffe95e5667b`; then refetch source, validate syntax, deploy through the existing owner-controlled path, and test exact/under/over/negative/fractional values in the served browser. Confirm correct completion through the existing Edge/RPC contract without creating synthetic Production orders.


---

## Current checkpoint — 2026-10-20 — Report423 Picker Over-Quantity Validation

- **Scope:** only `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html`. The owner remains responsible for applying any operational-app edits. No change was made to `picker.html` or `main.html` by the assistant.
- **Fresh Current Git:** `picker.html` blob SHA `55d84b1a95a425597520b007af999315be7bcae6`.
- **Latest relevant commit:** `67748842e6030c81ab8a2046b197f256d53a9c75`, “Improve quantity input validation in picker.html”, 2026-10-20. Its diff removes the silent clamp `Math.max(0, Math.min(parseInt(...), it.qty_ordered))` and validates the numeric input in `App.editPickedItem(index).preConfirm`; invalid/over-order quantities show `Swal.showValidationMessage` and return `false`.
- **Finding:** the core defect (silently accepting an over-quantity by clamping it to the ordered quantity) is fixed in Current Git. Do not reapply or replace the function.
- **UX distinction:** over-quantity is rejected before save inside the quantity modal; shortage is a valid lower quantity and prompts for a reason after save. Forcing the same post-save flow on over-quantity would be incorrect. Exact visual equivalence has not been implemented or browser-tested; if the owner still requires literal visual matching, treat it as a separate presentation-only change while retaining the pre-save rejection.
- **Production:** Supabase was inspected read-only; no schema, RPC, ACL, Edge Function, or business data was changed. The live `complete-picking` Edge Function was observed at v18 with `verify_jwt=true`; that does not prove which HTML artifact is served.
- **Test status:** static source logic inspected; hosted HTML deployment and browser E2E remain UNVERIFIED. Required owner test: requested qty 5 / enter 6 → rejection, modal stays open, no local qty mutation; enter 5 → save; enter 3 → existing shortage prompt; empty/decimal/negative → reject; verify no test residue.
- **Report:** [Report423_PICKER_OVERQUANTITY_VALIDATION_FORENSIC_REVIEW_20261020.md](doc/Draft/Reprots/Report423_PICKER_OVERQUANTITY_VALIDATION_FORENSIC_REVIEW_20261020.md), commit `2547d2aab3b0ff739da89291d5dbad1067c9897c`.
- **Closure status:** `CURRENT SOURCE FIX VERIFIED / NO ADDITIONAL SOURCE CHANGE / PRODUCTION HTML + BROWSER E2E UNVERIFIED`.
- **Next exact step:** owner confirms that commit `67748842e6030c81ab8a2046b197f256d53a9c75` is deployed to the hosted picker, performs the listed browser tests, and records runtime evidence. Do not touch `main.html` or create a backend change for this UI-only issue.


---

## Current checkpoint — 2026-10-20 — Report457 Picker Over-Quantity Alert Parity

- **Scope:** only owner-applied UI changes in `erp-frontend/companies/company-1/warehouse/picker.html`, function `App.editPickedItem(index)`. Assistant did not edit/deploy `picker.html` or `main.html`.
- **Fresh current source:** blob SHA `55d84b1a95a425597520b007af999315be7bcae6`, 1,030 lines. Latest relevant frontend commit `67748842e6030c81ab8a2046b197f256d53a9c75` removed silent clamping and added explicit numeric validation. Preserve that correction.
- **Fresh Production:** `complete-picking` is ACTIVE v18, `verify_jwt=true`, `ezbr_sha256=14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`. It calls `complete_runsheet_picking(..., p_operation_id)`. Live `public.complete_runsheet_picking(uuid,text,text,jsonb,uuid)` rejects `picked_qty > total_qty` before reservation and order-detail updates; ACL remains anon=false, authenticated=false, service_role=true.
- **Root cause:** current UI rejects over-quantity inside `preConfirm` with an inline validation message, while shortage opens a separate SweetAlert2 question modal after saving. The current request is to make the excess warning visually/interaction-wise similar to the shortage warning without permitting the invalid quantity to persist.
- **Report457:** [Report457_PICKER_OVERQUANTITY_ALERT_PARITY_20261020.md](doc/Draft/Reprots/Report457_PICKER_OVERQUANTITY_ALERT_PARITY_20261020.md), commit `a900d64f3ab6c2ab7d880a5387665123ed857d23`. It specifies two surgical owner changes: preserve integer/non-negative validation but remove the inline max rejection from `preConfirm`; insert a pre-persistence overage guard in the confirmed branch that shows a standalone question modal and returns before mutating session state, resetting `operation_id`, or writing IndexedDB. “Correct” reopens the editor; “Cancel” preserves the prior value.
- **Production changes:** none required or applied. Do not relax the RPC guard or alter stock/business data for this presentation issue.
- **Verification:** source and Production contract reviewed. The proposed patch is not applied/deployed; browser E2E, Cloudflare-served artifact parity, and post-deploy draft/idempotency checks remain UNVERIFIED. No test data was created.
- **Closure:** `ROOT CAUSE VERIFIED / OWNER SURGICAL PATCH READY / PRODUCTION UNCHANGED / BROWSER E2E + SERVED ARTIFACT PARITY OPEN`.
- **Next exact step:** owner verifies picker SHA `55d84b1a95a425597520b007af999315be7bcae6`, applies only Report457 patches A and B, deploys through the existing frontend route, tests over/exact/under/empty/fractional/negative quantities, confirms over-quantity never changes local session or `operation_id`, then records the served artifact identity and browser results. Do not edit `main.html`, add an Edge Function, or change the Production quantity contract.


---

## Current checkpoint — 2026-10-20 — Report458 Parent Picking Table Integration

- **Scope:** owner-applied surgical UI change in `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`, Picking section only. Assistant did not edit `main.html` or `warehouse/picker.html`; no Production, database, Edge, RPC, or business-data writes were made.
- **Fresh current source:** `main.html` was fetched through Git blob; SHA `1b38c60ff38d439d429474b17ff54b5b169c07b4`, 1,777,471 characters / 32,820 lines. The Picking functions are around lines 15304–15347 in that exact blob. The source currently queries runsheets in Open/Confirmed but hardcodes the displayed state to Picked, lacks picker identity/timestamps/notes in the table, and its detail query already uses `run_sheet_details.qty_picked`.
- **Fresh Production:** project `fiilmooggumokxanwiyx` ACTIVE_HEALTHY. `start-picking` v35 and `complete-picking` v18 are ACTIVE with `verify_jwt=true`. Production columns `runsheets.picker_id/picker_start/picker_end`, `users.name/email`, `order_details.reason_picking`, and `run_sheet_details.qty_picked` exist.
- **Production data cross-check:** current RS-1 is Picked, joined to `picker@rawaea.com`, has picker_start and picker_end, and sums to qty_picked=13 in both `order_details` and `run_sheet_details`. RS-2 is Open with qty_picked=0. Audit log records the RS-1 Picking → Picked transition on 2026-10-20. This disproves a current database-wide zero for RS-1 but does not prove which HTML blob is served to the browser.
- **Historical records reviewed:** current state and Reports451/454/457. These concern the operational Picker and Production picking contract; their owner-boundary rule is preserved. No relevant Production defect was proven, so no RPC/Edge change was made.
- **Report458:** `doc/Draft/Reprots/Report458_PICKING_PARENT_TABLE_FORENSIC_SURGICAL_PATCH_20261020.md`, commit `1e835c9704e88e624995ec657799489c0684e9f8`. It contains exact owner patches for table headers, company-scoped enrichment of picker name/timestamps/reason_picking, correct dynamic status display, and explicit detail-query error handling.
- **Test data:** no fixtures were created or deleted. Production rows use generic-looking RS-1/RS-2 codes and a zero UUID company id, but without independent proof that they are disposable fixtures, destructive cleanup was intentionally not performed.
- **Closure status:** `CURRENT SOURCE + DATABASE FACTS VERIFIED / OWNER PATCH READY / PRODUCTION UNCHANGED / SERVED HTML + BROWSER E2E NOT VERIFIED`.
- **Next exact step:** owner applies Report458 against main.html SHA `1b38c60ff38d439d429474b17ff54b5b169c07b4`, deploys through the existing frontend route, hard-reloads the served parent, tests all four statuses, picker name/times, reason aggregation, company isolation, and RS-1 details quantity. If the served details still show zero, capture the actual Network response and served asset identity before changing Core. Do not edit the operational Picker or change Production stock/picking functions without new evidence.


---

## Current checkpoint — 2026-10-21 — Report459 Parent Picking RLS Identity RPC

- **Scope:** parent Picking table integration only. The owner still applies the HTML patch; the assistant did not edit `erp-frontend/companies/company-1/main.html` or `warehouse/picker.html`.
- **Current parent source:** latest commit `bce36e7942e3d13da4a81e31738bd1a7b0e6dd4b`, parent `ed7c4bc65fee776802e6461bef72d6a8a59c808c`; GitHub connector reports current main blob `abe90901dfcf01f7055fe83db27183ce78390367`. The latest commit diff contains the Report458 parent-table changes. Full body/line-range retrieval of this oversized HTML file was unavailable in this cycle; do not claim full-file read or use old Report458 line numbers.
- **Fresh Production facts (2026-10-21 ~14:30 UTC):** RS-1 is `Picked`; `picker_id=34758d59-21db-4f28-9028-f2dd8125f69b`, picker is `picker@rawaea.com` / `مسؤول مخازن (تحضير احتياطي)`; picker_start and picker_end are populated; both `order_details.qty_picked` and `run_sheet_details.qty_picked` sum to 13. RS-2 is `Open` and both sums are 0. Current DB does not reproduce the reported zero for RS-1.
- **Confirmed defect:** current parent patch queries `public.users` directly to resolve picker names. Production `users_select_company` requires `users` permission to read other users; warehouse-only callers do not qualify. The query may return no picker row without a PostgREST error. Do not broaden users-table RLS or grant broad directory access.
- **Production repair:** migration `supabase/migrations/20261021143458_picking_display_users_read_rpc.sql`, Git commit `42cb8bd275b92521928c892a793d1c5072824b14`, adds `public.get_picking_display_users(uuid[])`. It checks auth, current company, warehouse/runsheets permission, limits IDs to 500, and returns only matching picker identities linked to a runsheet in the current company. Execute ACL checked: anon=false, authenticated=true. Runtime claim-context test returned the expected picker name; cross-company test returned 0 rows. No Edge Function or business data changed.
- **Owner-only HTML patch:** in `loadPicking()`, replace the direct `supabase.from('users')...` lookup block with `supabase.rpc('get_picking_display_users',{p_picker_ids: pickerIds})`. Exact complete replacement is in [Report459_PARENT_PICKING_RLS_IDENTITY_RPC_AND_LIVE_PRODUCTION_REPAIR_20261021.md](doc/Draft/Reprots/Report459_PARENT_PICKING_RLS_IDENTITY_RPC_AND_LIVE_PRODUCTION_REPAIR_20261021.md), commit `8fca644136991548f55001087577d90bf1ce434b`.
- **Do not change:** `complete_runsheet_picking`, `sync_run_sheet_details`, inventory quantities, reservations, `run_sheet_details.qty_picked`, or operational Picker source absent new evidence. Current RS-1 projection rows are present and total 13.
- **Open verification:** owner applies the surgical HTML change and deploys; then validate source syntax, served HTML identity, picker name/timestamps/reason aggregation, RS-1 details quantities, RS-2 zero-before-picking, and company isolation in browser. If RS-1 still displays zero, capture the actual Network response and served asset before any Core change. Browser E2E and served-artifact parity are not yet proven.
- **Closure:** `PRODUCTION IDENTITY RPC VERIFIED / OWNER HTML PATCH REQUIRED / SERVED HTML + BROWSER E2E OPEN / NOT CLOSED`.
- **Next exact task:** apply only Report459's replacement block against the current `main.html` source after re-fetching its current SHA, deploy through the owner-controlled path, and record actual browser/Network evidence.


## Current checkpoint — 2026-10-21 — Report460 Parent Picking Current-Source Resync

- Scope: parent Picking integration only in `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`. Assistant did not edit `main.html`, `warehouse/picker.html`, Production SQL, ACL, Edge Functions, or business data.
- Fresh GitHub fetch reports current `main.html` blob SHA `60c83c51be5aa24993a01fe5e148c4bd247ccca6`, but the connector returned an empty body, including for line-range requests. Do not claim a full-body read or reuse prior line numbers.
- Live Supabase Edge inventory confirms `start-picking v35` and `complete-picking v18` are ACTIVE with `verify_jwt=true`. This does not establish current SQL function/ACL state.
- A fresh read-only SQL check was attempted but rejected by the tool safety layer. Current SQL RPC/ACL/data verification is therefore UNVERIFIED in this session. Report459's successful RPC tests and migration application remain historical evidence only until live SQL can be queried again.
- Canonical migration is present in Git: `supabase/migrations/20261021143458_picking_display_users_read_rpc.sql`. No new migration or Production mutation was performed.
- Report460: `doc/Draft/Reprots/Report460_PARENT_PICKING_CURRENT_SOURCE_RESYNC_20261021.md`, commit `c36574120c9faa29293b4d8ececfc2b5fa7dfc95`. It documents the exact owner-only replacement from direct `public.users` lookup to `supabase.rpc('get_picking_display_users', {p_picker_ids: pickerIds})`, plus a checklist to verify Report458's columns, notes, status rendering and details behavior without reapplying already-present patches.
- Do not reapply Report458/459 patches blindly. Owner must re-fetch current source, match the exact block, apply only if still present, deploy, then verify served HTML and browser behavior.
- No production test data was created or deleted. Rows cannot be deleted as fixtures without current evidence of their ownership and disposable status.
- Closure: `CURRENT SOURCE SHA OBSERVED / SOURCE BODY UNAVAILABLE / EDGE INVENTORY OBSERVED / LIVE SQL + SERVED HTML + BROWSER E2E UNVERIFIED / NOT CLOSED`.
- Next step: regain read-only SQL access; verify `get_picking_display_users(uuid[])` definition and ACL plus current runsheet/quantity/note data. In parallel, owner checks current `main.html` SHA and applies only the matching surgical replacement if absent, deploys, and captures served artifact + Network evidence. Do not change stock/picking core based only on a UI symptom.


## Current checkpoint — 2026-10-21 — Report461 Picking Note Persistence Repair

**This checkpoint supersedes the Report460 statements that live SQL was unverified and that `complete_runsheet_picking` should remain untouched.** Those statements were accurate for Report460's tool context but are superseded by fresh Production inspection and a proven defect in this cycle.

- Scope: picker-note persistence in the canonical Production Core function, plus current parent Picking source verification. The assistant did not modify `erp-frontend/companies/company-1/main.html` or `warehouse/picker.html`.
- Current parent source was successfully retrieved via Git blob: `erp-frontend/companies/company-1/main.html`, blob SHA `60c83c51be5aa24993a01fe5e148c4bd247ccca6`. Latest file commit `8da2acbd450a0debd49f3c721881007683d873ca` (2026-10-21 14:42:39 UTC; parent `166914a29e5bce2173c030fc827e07e191d0779a`). Source already includes the table columns, status filtering, note aggregation, and `get_picking_display_users(uuid[])` RPC call; do not reapply Reports458/459 broadly.
- Operational Picker source SHA: `ffe18d4483ee074230e32b1c96f60507e5876a4b`. Current Production Edge: `start-picking v35` and `complete-picking v18`, ACTIVE, `verify_jwt=true`.
- Fresh live SQL: `RS-1` status Picked, `order_details.qty_picked=13`, `run_sheet_details.qty_picked=13`; `RS-2` status Open, picked total 0. Projection detail rows match the source rows. This does not prove what the currently served browser HTML displays.
- Proven defect: canonical five-argument `public.complete_runsheet_picking(uuid,text,text,jsonb,uuid)` wrote `reason_picking` only when `assign_qty < ordered_qty`. A full-quantity item with a non-empty picker note was saved with `reason_picking=NULL`, so the parent UI could not display it.
- Production repair applied: migration `supabase/migrations/20261021145600_preserve_picking_notes_when_fully_picked.sql`, repository commit `4cba5b3832b775030e609a098be5a55056e0d727`. Production apply returned success. The canonical five-argument function now preserves shortage-note behavior and, when the aggregate picked quantity equals the ordered quantity, stores a non-empty note once on the first deterministic order line. Quantity distribution, stock reservation, status transition, operation_id/idempotency contract, and ACL were preserved.
- Production live verification: the five-argument overload has `anon=false`, `authenticated=false`, `service_role=true`; the legacy four-argument overload remains non-executable by anon/authenticated/service_role. Live function definition contains the new note logic.
- Regression test before repair reproduced full-quantity note loss. Post-repair transaction test PASS: full-quantity note `QA_FULL_QTY_NOTE_ROLLBACK` persisted; shortage note `QA_SHORTAGE_NOTE_ROLLBACK` remained on the underfilled detail row only. Both tests used explicit transaction rollback.
- Baseline restoration verified after test: `RS-2` remains Open, `picker_id=NULL`, picked quantity 0; test notes residue 0; operation registry residue 0; stock for item 1001 restored to 6.0000. No durable business fixture was created.
- Report461: `doc/Draft/Reprots/Report461_PICKING_NOTE_PERSISTENCE_PRODUCTION_REPAIR_20261021.md`, commit `300d2904575059ec8d7349a54dde8e1925682f77`.
- Remaining owner-only surgical patch: in `_showPickingDetails(code)` at current source lines 15475–15482, add explicit checks for `rsRes.error`, missing runsheet, and `itemsRes.error`; exact complete replacement is in Report461. This makes failures visible but does not assert it is the proven cause of a zero quantity.
- Unverified: served HTML parity, browser E2E, and the exact Network response from the session that showed zero. If RS-1 still shows zero after the owner patch and deployment, capture the served HTML identity and `run_sheet_details` Network response before any further Core edits.
- No production data changes remain from testing. No Edge Function was added or redeployed. No stock or reservation behavior was modified.
- Closure: `PRODUCTION NOTE-PERSISTENCE CORE FIX VERIFIED / OWNER DETAILS-ERROR PATCH REQUIRED / SERVED HTML + BROWSER E2E UNVERIFIED — NOT FULLY CLOSED`.
- Next exact step: owner applies only Report461's details-query error-handling replacement if it still matches the current source SHA, deploys the parent UI, then captures authenticated browser evidence for RS-1 (expected picked total 13), RS-2 (expected 0 while Open), picker identity/timestamps, notes, and company isolation. Do not reapply table columns or the identity RPC patch.


# CURRENT FORENSIC CHECKPOINT — 2026-10-21 — Report462 Picking Parent / Production Stock Reconciliation

- **Scope:** parent Picking table/details plus the current `complete-picking` HTTP 400. Owner-controlled files `erp-frontend/companies/company-1/main.html` and `warehouse/picker.html` were not modified. No Production schema/RPC/Edge/ACL/business data was changed.
- **Fresh current parent source:** `main.html` blob SHA `bb10422217fc57a9a42c2bf65a55e9470a19537c`, 33,000 lines, retrieved via Git blob. Relevant code was read at lines 15301–15512.
- **Current UI finding:** required columns (picker, start/end timestamps, aggregated picking notes) are already present in Git. Picker identity uses `get_picking_display_users(uuid[])`; notes are aggregated from `order_details.reason_picking`. Do not reapply Report458/459 table/identity patches.
- **Fresh Production facts:** `complete-picking` v18 ACTIVE, `verify_jwt=true`, deployment hash `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`. RS-1 is Picked and has picked totals 13 in both `order_details` and `run_sheet_details`. RS-2 is still Picking and has zero picked quantities in both sources. The projection trigger `trg_sync_run_sheet_details` rebuilds the aggregate from `order_details`.
- **Current HTTP error root cause:** PostgreSQL log at `2026-10-21 15:21:25 UTC` records `insufficient available stock for reservation`. In RS-2, item `1008` (مصاصة 2ج) has qty=1, allocated_qty=1, available=0; the available unit is already reserved for RS-1. This rejection is correct. Do not bypass `reserve_stock` or alter allocations manually. Set picked qty 0 with a shortage note in RS-2, or enter real additional stock through the canonical stock movement flow before retrying.
- **No changes required in Production** based on the verified evidence. If browser still shows zero for RS-1, capture the actual `run_sheet_details` Network response and served HTML identity before changing source; current DB does not reproduce the reported zero for RS-1.
- **Reports:** authoritative report for this cycle: `doc/Draft/Reprots/Report462_PICKING_PARENT_PRODUCTION_STOCK_FORENSIC_20261021.md`, commit `79d94034e83a4bd21008cc1f6669f7221d70d8ca`. A separately named supplemental report was also created during this cycle: `Report458_PICKING_PARENT_UI_AND_PRODUCTION_STOCK_FORENSIC_20261021.md`, commit `2c882c4bf4b3c482dc510e9e49c20b28fab31fa5`; it does not replace the existing historical Report458 and should not be treated as a separate closure unit.
- **Unverified:** Cloudflare-served HTML parity and browser E2E. No fixtures were created or deleted.
- **Closure:** `CURRENT GIT + PRODUCTION DATA/CORE VERIFIED / NO CODE CHANGE JUSTIFIED / SERVED HTML + BROWSER E2E OPEN`.
- **Next exact step:** resolve RS-2 item 1008 by recording actual shortage (picked=0 + note) or by posting legitimate stock receipt if physical stock exists; retry completion. If RS-1 details still show zero in the browser, capture Network response + served artifact SHA and continue from that evidence. Do not reapply existing parent patches.


---

## Current checkpoint — 2026-10-21 — Report463 Parent Picking Live Resync

- Scope: parent Picking table/details in `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`; assistant did not edit `main.html` or operational `warehouse/picker.html`, and did not mutate Production business data/schema/RPC/Edge in this cycle.
- Current source blob SHA: `bb10422217fc57a9a42c2bf65a55e9470a19537c`, 1,782,052 characters / 33,000 lines; current Picking block reviewed at lines 15282–15512. Latest file commit observed: `aafc769abd2a4d5539e6183990eaf6b9b989566b` (2026-10-21 15:12:22 UTC), comment-only change.
- The requested picker identity, start/end timestamps and aggregated picking-note columns already exist in current Git. `loadPicking()` calls `get_picking_display_users(uuid[])` and aggregates `order_details.reason_picking`. `_showPickingDetails(code)` already handles errors/missing runsheet and reads `run_sheet_details.qty_picked`; do not reapply Report458/459/461 broadly.
- Live SQL at 2026-10-21 15:38:41 UTC: RS-1 is Picked; `order_details` and `run_sheet_details` both total qty_picked=13. RS-2 is still Picking and both sources total 0. The projection trigger `trg_sync_run_sheet_details` sums `order_details.qty_picked` into `run_sheet_details.qty_picked`.
- PostgreSQL logs show `insufficient available stock for reservation` in `complete_runsheet_picking(uuid,text,text,jsonb,uuid)` at 15:21 and 15:33 UTC. Item 1008 (`مصاصه 2ج`) has main-branch qty=1, allocated=1, available=0; RS-1 holds the one reserved unit while RS-2 asks for another. This rejection is correct. Do not bypass `reserve_stock` or adjust allocations manually; record the real shortage or post genuine receipt through the canonical stock-movement flow.
- No new UI/Production defect is proven by current evidence. If RS-1 still shows zero in the browser, capture the exact `run_sheet_details` Network response and served HTML identity before further changes. Served-artifact parity and browser E2E remain UNVERIFIED.
- Report463: `doc/Draft/Reprots/Report463_PARENT_PICKING_LIVE_RESYNC_AND_QUANTITY_DIAGNOSIS_20261021.md`.
- Closure: `CURRENT GIT + LIVE PRODUCTION QUANTITIES + STOCK-REJECTION ROOT CAUSE VERIFIED / NO NEW SURGICAL CHANGE JUSTIFIED / SERVED HTML + BROWSER E2E OPEN`.
- Next step: do not reapply Report458/459/461 changes. Resolve RS-2 only according to actual physical stock/shortage; if RS-1 UI still misreports quantities, capture Network response and served HTML identity.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-21 — Report464 Picking Production Recheck

- **Scope:** parent Picking display/quantity concern and current `complete-picking` HTTP 400. Owner-controlled `erp-frontend/companies/company-1/main.html` and `warehouse/picker.html` were not modified. No Production schema/RPC/Edge/business-data writes were performed.
- **Fresh Production read:** at `2026-10-21 15:52:37.687084+00 UTC`, RS-1 = `Picked`, 11 detail lines, ordered 14, picked 13, loaded 0; RS-2 = `Picking`, 9 detail lines, ordered 9, picked 0, loaded 0. The zero is currently RS-2, which has not completed; this does not reproduce a zero for RS-1.
- **Stock root cause remains current:** item `1008` in main branch `BR-01` has qty=1, allocated=1, available=0. RS-1 already holds the available unit. Production logs show `insufficient available stock for reservation` inside `reserve_stock` called by `complete_runsheet_picking`; the HTTP 400 is a correct business guard, not a reason to bypass reservation.
- **Current Production Edge:** `complete-picking` v18 ACTIVE, `verify_jwt=true`, deployment SHA `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`.
- **Core sync:** `trg_sync_run_sheet_details` fires after INSERT/UPDATE/DELETE on `order_details`; `sync_run_sheet_details()` aggregates `sum(qty_picked)` into `run_sheet_details`. No mismatch in current evidence justifies a trigger or RPC repair.
- **Source:** current `main.html` blob SHA `bb10422217fc57a9a42c2bf65a55e9470a19537c`. Existing forensic checkpoints report that picker identity, start/end times, aggregated notes, and details query are already implemented. The large-file connector returned metadata/SHA but not full body in this execution, so no claim of fresh full-file reread or served parity is made.
- **Report464:** `doc/Draft/Reprots/Report464_PARENT_PICKING_FRESH_PRODUCTION_RESYNC_20261021.md`, commit `1bacf5ae76467348e323f6fcf8b7f2ee6c6c2597`.
- **No code patch justified now:** if RS-1 still shows zero in browser, capture the exact authenticated Network response for `run_sheet_details` plus the served HTML identity before editing. Do not reapply Report458/459/461 patches. For RS-2, record actual shortage (picked=0 + note) or receive genuine physical stock through the canonical stock-movement flow, then retry.
- **Closure:** `CURRENT PRODUCTION DATA + STOCK REJECTION ROOT CAUSE VERIFIED / NO NEW CODE CHANGE JUSTIFIED / SERVED HTML PARITY + BROWSER E2E UNVERIFIED`.


---

## Current checkpoint — 2026-10-21 — Report465 Picker Reservation Shortage

- Scope: `erp-frontend/companies/company-1/warehouse/picker.html` / `complete-picking` HTTP 400. The operational app and `main.html` were not edited by the assistant.
- Fresh Production Edge: `complete-picking` ACTIVE v18, `verify_jwt=true`, deployment hash `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`.
- Current picker source blob SHA: `ffe18d4483ee074230e32b1c96f60507e5876a4b`.
- Root cause verified from live Production: `RS-1` is `Picked` and holds the one available unit of item `1008` (مصاصة 2ج); `RS-2` is still `Picking` and requests another unit. Main branch stock is `qty=1, allocated_qty=1, available_qty=0`. The rejection is correct; do not bypass `reserve_stock`, alter allocations manually, or fake stock.
- Production migration `picking_reservation_diagnostic_contract_20261021` applied. `reserve_stock` now reports item code, requested quantity, and available quantity when rejecting an insufficient reservation. This changes diagnostics only, not stock behavior.
- Isolated SQL negative test passed: request for item 1008 quantity 1 at available 0 returned the expected detailed diagnostic. Post-test stock remained `qty=1, allocated_qty=1, available_qty=0`; no business data changed.
- Artifacts: migration `supabase/migrations/20261021_picking_reservation_diagnostic_contract.sql`; report `doc/Draft/Reprots/Report465_PICKER_RESERVATION_SHORTAGE_FORENSIC_20261021.md`.
- Owner-only surgical UI change is specified in Report465: replace only the final catch handler inside `App.completePicking` so a reservation shortage opens a persistent, actionable dialog rather than a short toast. Do not edit `main.html` or the operational app through the assistant.
- Closure: `ROOT CAUSE + PRODUCTION DIAGNOSTIC VERIFIED / STOCK INTEGRITY PRESERVED / OWNER UI PATCH + BROWSER E2E OPEN`. Do not claim 100% closure. Resolve RS-2 according to physical reality: record actual shortage (picked quantity 0 plus reason) or receive real stock through the canonical stock-movement flow.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-21 — Report466 Loader Preview Inline

- **Scope:** owner-controlled `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/loader.html`. Assistant did not edit the operational app or `main.html`.
- **Current source:** `loader.html` SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`, 266 lines. `App._showPreviewModal` is at lines 162–174. Root cause: it calls `Swal.fire(...)` to show the runsheet preview as a separate modal, whereas Picker renders its runsheet details into `mainContent`.
- **Shared core:** `core.js` SHA `ff2f581d9900543c16f7cb026e13446520c0329d`; Loader uses `RW_Auth`, `RW_UI`, `RW_API`, and `RW_ImageCache`. Current `openRunsheet` loads the runsheet and details; starting and completing loading go through existing `start-loading` and `complete-loading` Edge Functions.
- **Fresh Production Edge:** `start-loading` ACTIVE v5, `verify_jwt=true`; `complete-loading` ACTIVE v11, `verify_jwt=true`, `ezbr_sha256=c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`. Production RPC `complete_runsheet_loading(uuid,uuid,jsonb,text)` routes physical movement through `post_stock_movement`.
- **Production schema/RLS:** `run_sheet_details` has only a SELECT policy for authenticated users and no authenticated UPDATE table grant. The current Loader `editLoadedItem` attempts a direct update of `run_sheet_details.qty_loaded` and ignores the response; this does not have a valid authorized write contract. Also, Loader UI allows zero loaded quantity for an item, while Production `complete-loading v11` rejects any `loaded_qty <= 0` and the core rejects `req <= 0`. The Edge currently drops per-item `notes` before invoking the core. These are real adjacent loading-lifecycle defects, not part of the modal rendering fix.
- **Runtime evidence:** Supabase logs show real authenticated GET requests from `https://rawaea-erp.pages.dev/` to `runsheets` on 2026-10-21 around 16:52 UTC. This confirms live application API use, but does not prove that the HTML served by Cloudflare Pages is byte-identical to the current Git blob.
- **Owner patch report:** [Report466_LOADER_RUNSHEET_PREVIEW_INLINE_SURGICAL_CHANGE_20261021.md](doc/Draft/Reprots/Report466_LOADER_RUNSHEET_PREVIEW_INLINE_SURGICAL_CHANGE_20261021.md), report commit `51ae2bc38ff3211d471aaf56ddab01fcbfab6e3d`. It contains the complete replacement for `App._showPreviewModal` only, the exact locator and application steps, and post-deployment tests. The operational app was not edited by the assistant.
- **Production changes:** none; a modal-only change does not require a DB migration, RPC, or Edge deployment. No production test data or inventory quantities were changed.
- **Closure:** `ROOT CAUSE PROVEN / OWNER PATCH READY / HTML DEPLOYMENT + BROWSER E2E OPEN / LOADING DRAFT-WRITE + ZERO-QUANTITY + REASON PROPAGATION CONTRACTS OPEN`.
- **Next exact step:** owner replaces only `App._showPreviewModal` in `loader.html` using Report466, deploys the app, and tests Picked → inline preview → Back → Start Loading in the served browser. Do not claim UI closure before the browser test. Then close the three documented loading-lifecycle defects with a separate authenticated RPC/core repair and a safe, isolated test plan; do not grant broad direct UPDATE on `run_sheet_details` and do not bypass `post_stock_movement`.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report467 Picker Runsheet Preview Parity

- **Scope:** owner-controlled `erp-frontend/companies/company-1/warehouse/picker.html`; no changes to `main.html`, no direct edits to operational HTML, and no Production/Supabase mutations.
- **Fresh source:** Loader blob SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker blob SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines); shared `core.js` SHA `ff2f581d9900543c16f7cb026e13446520c0329d`.
- **Historical reconciliation:** Loader baseline SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`; Picker baseline SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`. Report466's original Loader SHA was stale by this cycle; latest Loader preview refactor commit is `152e5b1d22aab94d2cf01070778b357df4701aff`.
- **Current diagnosis:** Loader has a richer inline preview with summary cards and detailed item cards. Picker's `App.openRunsheet(code)` non-active branch (around current lines 570–581) still renders a short heading/basic item list and omits the total requested quantity and always-visible item description. Database values are interpolated into HTML in the preview; the linked `showItemDetail` modal also inserts item fields without escaping.
- **Production resync at 2026-10-23 11:18:26 UTC:** current RLS policies for `runsheets` and `run_sheet_details` constrain reads to the current company and permitted roles. Existing `start-loading v5` and `complete-loading v11` are ACTIVE with `verify_jwt=true`. Recent authenticated runsheet-list requests from `rawaea-erp.pages.dev` returned HTTP 200. These logs do not prove served HTML blob parity. No schema, ACL, Edge, or business data changed.
- **Owner patch:** Report467 `doc/Draft/Reprots/Report467_PICKER_RUNSHEET_PREVIEW_PARITY_SURGICAL_CHANGE_20261023.md`, commit `89b2b37fba4bf5aa6a3cbdabfceb3f130318ef93`. It contains exact replacement blocks for the Picker preview branch and `App.showItemDetail`, with item quantities/descriptions, safe text escaping, back/start handlers, and tests. The owner must apply these blocks to current SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; re-fetch and relocate exact blocks if SHA changes.
- **No Production change required:** display-only work does not justify an Edge Function, RPC, schema, RLS, grant, or stock mutation. The existing `start-picking` and central reservation lifecycle remain untouched.
- **Closure:** `SOURCE + PRODUCTION READ CONTRACTS RECONCILED / OWNER SURGICAL PATCH READY / DEPLOYMENT + SERVED HTML PARITY + BROWSER E2E OPEN`.
- **Next step:** owner applies Report467's two surgical replacements, deploys Picker, then verifies Open/Confirmed preview, total requested quantity, descriptions, detail modal escaping, Back, Start Picking, company isolation, mobile layout, and unchanged inventory baseline. Do not claim UI closure before browser evidence.


---

## CURRENT FORENSIC RECHECK — 2026-10-23 — Picker Preview Patch Revalidated

- Scope remains owner-applied UI-only change in `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html`. Do not edit `main.html` or the operational HTML through the assistant.
- Re-fetched current source: Loader `companies/company-1/warehouse/loader.html` SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines). Picker still contains the short preview block at lines 570–581 and the unescaped `App.showItemDetail` at lines 590–594; Report467's locators still match these exact source contents.
- Fresh Production check at `2026-10-23 11:21:23.239957+00 UTC`: `start-loading` ACTIVE v5, `verify_jwt=true`, `ezbr_sha256=afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7`; `complete-loading` ACTIVE v11, `verify_jwt=true`, `ezbr_sha256=c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`. Both authenticate the JWT, resolve `public.users` through `auth_id = auth.users.id`, then call the existing service-role core RPC.
- Production RLS rechecked: `runsheets` SELECT is company-scoped and permission-gated; `run_sheet_details` SELECT requires a parent runsheet in the current company and a runsheets/warehouse/reports permission. No schema, ACL, Edge, stock, or business-data changes were required or made.
- Revalidated finding: Picker preview lacks a total requested-quantity summary and always-visible item description; preview and detail modal interpolate database text without escaping. Report467 already contains the two complete owner-only replacements; no duplicate report or code patch is needed.
- Exact owner instructions remain in [Report467_PICKER_RUNSHEET_PREVIEW_PARITY_SURGICAL_CHANGE_20261023.md](doc/Draft/Reprots/Report467_PICKER_RUNSHEET_PREVIEW_PARITY_SURGICAL_CHANGE_20261023.md). Apply only its two replacements after re-fetching the file and confirming the SHA; do not replace the entire `openRunsheet` function.
- No browser/Cloudflare served-artifact parity or post-patch E2E was run. Closure remains OPEN until the owner applies, deploys, and verifies the patch. Do not call the task closed based on source inspection alone.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report468 Picker Preview Schema-Corrected Revalidation

- **Scope:** owner-applied surgical UI patch for `erp-frontend/companies/company-1/warehouse/picker.html` to bring the non-active runsheet preview closer to Loader's current inline preview. No edits were made to `main.html`, `loader.html`, or the operational `picker.html`; no Production mutations were performed.
- **Current source re-fetched:** Loader blob SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 lines; Picker blob SHA `d483bd15b36585b975b63c2ef641481a01d5d084`, 1058 lines; shared core SHA `ff2f581d9900543c16f7cb026e13446520c0329d`.
- **Git changes checked:** Loader preview refactor commit `152e5b1d22aab94d2cf01070778b357df4701aff`; latest Picker commit in search results `eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7`. The GitHub commit connector did not expose parent SHAs in its normalized response; do not invent a parent. The loader path is present at current default ref despite an earlier rename commit.
- **Important correction to Report467:** Production schema shows `run_sheet_details` has no `description` column. The actual source is `items.description`, and the real FK is `run_sheet_details_item_id_fkey` (`run_sheet_details.item_id → items.id`). Report468 corrects the query to select `items!run_sheet_details_item_id_fkey(description)` and reads the nested relation. It also supplies safe image URL handling in `App._img` and escaped values in `App.showItemDetail`.
- **Fresh Production check:** at `2026-10-23 11:25:19–11:25:56 UTC`, the project `fiilmooggumokxanwiyx` was `ACTIVE_HEALTHY`; current RLS for `runsheets` and `run_sheet_details` remains company/permission-scoped. `start-loading` ACTIVE v5, `verify_jwt=true`, deployment hash `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7`; `complete-loading` ACTIVE v11, `verify_jwt=true`, hash `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`.
- **No Production schema/ACL/RPC/Edge/data changes:** this remains a display-only change; preview must not reserve or move stock. Existing `start-picking` remains the only start-picking path.
- **Owner report:** [Report468_PICKER_PREVIEW_PARITY_SCHEMA_CORRECTED_20261023.md](doc/Draft/Reprots/Report468_PICKER_PREVIEW_PARITY_SCHEMA_CORRECTED_20261023.md), latest report correction commit `3e9b628d9e8d88c4dcfa7939d1d3cb3a15f122d3` (report initially added in `2485bf02ef8c5449af5e6dc8fa871935278cdb40`).
- **Current status:** `SOURCE + LIVE DB RELATIONSHIP + READ POLICIES VERIFIED / OWNER SURGICAL PATCH READY / SERVED HTML PARITY + BROWSER E2E OPEN`.
- **Next exact step:** owner applies only the four changes in Report468 to the current Picker blob SHA: (1) nested description relation in the details query; (2) inline preview block replacement; (3) `App._img` safe URL replacement; (4) `App.showItemDetail` escaping replacement. Re-fetch Picker first and relocate the exact selectors if its SHA changed. Then deploy and verify Open/Confirmed preview, descriptions, XSS-like text, back/start actions, active-session restoration, company isolation, mobile layout, and unchanged stock/allocations. Do not modify Loader or main.html, and do not call this closed before browser/runtime evidence.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report469 Picker Preview Final Revalidation

- **Scope:** current Loader-vs-Picker preview integration only. No edits to `erp-frontend/companies/company-1/main.html`, `loader.html`, or operational `picker.html`.
- **Fresh source re-read:** Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines); shared `core.js` SHA `ff2f581d9900543c16f7cb026e13446520c0329d`.
- **Existing report revalidated:** Report468 blob `57066e3d602549afe2655e7988c92f5bad5ab862` has the correct database relationship and safe preview patch. A further small UI correction was identified: if a same-user `Picked` runsheet is opened, the suggested status label would incorrectly display `مفتوح`. Report469 supplies the exact two-line correction without rewriting the full patch.
- **Production database rechecked:** `run_sheet_details_item_id_fkey` is `FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT`; `items.description` exists and `run_sheet_details.description` does not. Current `runsheets` SELECT policy is company/permission-scoped; `run_sheet_details` SELECT policy requires a parent runsheet in the current company and a valid warehouse/runsheet/reports permission.
- **Production Edge rechecked:** `start-picking v35`, `start-loading v5`, `complete-loading v11`, all ACTIVE with `verify_jwt=true`. No Production schema, ACL, RPC, Edge Function, inventory, or business-data change is justified for this display-only change; none was performed.
- **Git history:** Picker commit `eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7` is titled `Update picker.html` and dated `2026-10-21T16:43:32Z`. The available normalized commit response did not expose its parent SHA; no parent SHA is claimed.
- **Report469:** `doc/Draft/Reprots/Report469_PICKER_PREVIEW_PARITY_FINAL_REVALIDATION_20261023.md`, commit `5928939ee43895e6160058c2106e058bb8b95253`.
- **Status:** `SOURCE + LIVE DB RELATIONSHIP + RLS + EDGE VERSIONS VERIFIED / OWNER PATCH READY / OPERATIONAL HTML UNCHANGED / SERVED HTML PARITY + BROWSER E2E OPEN`.
- **Exact next step:** owner applies the four changes from Report468, with Report469's status-label/subtitle correction included, to the current Picker SHA after re-fetching it. Deploy through the existing path; test Open, Confirmed, and same-user Picked views, description relation, escaped content, images, Back/Start actions, company isolation, mobile layout, and unchanged stock/reservations. Do not modify `main.html` or `loader.html`; do not claim closure before served-artifact parity and browser E2E evidence.


# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report470 Picker Preview Parity

## Scope
Only the owner-applied surgical parity patch for `erp-frontend/companies/company-1/warehouse/picker.html`. Do not edit `main.html`, `loader.html`, or the operational Picker file through the assistant. No Production schema/RPC/Edge/data change is required for this UI-only scope.

## Fresh source and Git
- Current Loader: `companies/company-1/warehouse/loader.html`, blob SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`.
- Current Picker: `companies/company-1/warehouse/picker.html`, blob SHA `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Loader preview inline refactor: commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`.
- Picker source still contains the short inline preview branch; Report468’s proposed patch is not present in the current Picker blob.
- Final revalidation report: `doc/Draft/Reprots/Report470_PICKER_PREVIEW_PARITY_FRESH_REVALIDATION_20261023.md`, commit `5a644a4c497bdd2b24ebfd33cfb4c01133fa14a9`. It consolidates Report468’s full replacement set with Report469’s two status-label corrections.

## Fresh Production evidence — 2026-10-23
- Supabase project `fiilmooggumokxanwiyx`.
- Edge Functions: `start-picking v35`, `start-loading v5`, `complete-loading v11`; all ACTIVE and `verify_jwt=true`.
- Schema: `run_sheet_details.item_id` references `items.id` through `run_sheet_details_item_id_fkey`; `items.description` and `items.image_url` exist; `run_sheet_details.description` does not exist.
- RLS policies on `runsheets`, `run_sheet_details`, and `items` enforce company/permission context.
- Read-only status count at inspection: 2 runsheets in status `Picked`. No rows were inserted/updated/deleted, and no inventory/reservation was changed.

## Exact owner patch
1. In `App.openRunsheet(code)`, change the details select to `select('*, items!run_sheet_details_item_id_fkey(description)')`.
2. Replace only the non-active preview block in `App.openRunsheet(code)` using the complete replacement block in Report468.
3. Before applying that block, use Report469/Report470’s corrected label: `Picked → مكتمل التحضير`; do not label every non-Confirmed state as `مفتوح`. Change the subtitle to distinguish `canStart` from read-only details.
4. Replace `App._img(code)` and `App.showItemDetail(...)` only if their current bodies still match the unescaped versions targeted in Report468.
5. Owner deploys and verifies. Do not touch `main.html`, `loader.html`, `core.js`, Production schema, RPC, or Edge for this presentation-only change.

## Verification status
- Source/schema diagnosis: VERIFIED.
- Patch applied by owner: UNVERIFIED.
- Cloudflare served HTML parity: UNVERIFIED.
- Browser E2E: UNVERIFIED.
- Closure: `OWNER PATCH READY / PRODUCTION UI E2E OPEN / NOT CLOSED`.

## Next exact step
Owner applies the Report470 patch to the matching current Picker SHA, deploys the existing frontend artifact, and tests Open/Confirmed/Picked read-only preview, item description/image escaping, back navigation, allowed start action, and unchanged stock/reservations. Re-fetch source SHA and served HTML after deployment before claiming closure.


---

## CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report471 Loader/Picker Preview Live Revalidation

- **Scope:** Loader-vs-Picker runsheet preview only. Owner remains responsible for merging operational HTML. No edit to `main.html`, `loader.html`, or `picker.html` was made by the assistant.
- **Fresh Git source:** `erp-frontend/companies/company-1/warehouse/loader.html` SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); `picker.html` SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines). Current Loader preview function starts at line 162; Picker `App.openRunsheet(code)` starts at line 467, details query at line 516, abbreviated preview block at lines 570–580, `App._img` at line 585, and `App.showItemDetail` at line 590.
- **Current Git history:** Loader refactor commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`; latest checked Picker commit `eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7`, parent `fbcd4c7e1845236455f026eb3f7ae0ccfa8ba407`.
- **Fresh Production DB:** checked at `2026-10-23 11:52:46.223005+00`. `items.description` and `items.image_url` exist; `run_sheet_details.description` does not. FK `run_sheet_details_item_id_fkey` links `run_sheet_details.item_id → items.id`; FK `run_sheet_details_runsheet_id_fkey` links details to runsheets. Live RLS policies constrain reads of `runsheets`/ `items` by current company and permissions; `run_sheet_details` requires a parent runsheet in the current company and runsheets/warehouse/reports permission.
- **Fresh Production Edge inventory:** `start-picking` ACTIVE v35, `verify_jwt=true`, hash `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a`; `complete-picking` ACTIVE v18, `verify_jwt=true`, hash `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`; `start-loading` ACTIVE v5, `verify_jwt=true`, hash `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7`; `complete-loading` ACTIVE v11, `verify_jwt=true`, hash `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`.
- **Current defect:** Picker still uses `.select('*')` for `run_sheet_details`, has no `pickerPreviewTotalQty`, and its abbreviated preview omits total requested quantity and a permanently visible description. Existing current code interpolates item data into HTML/inline handler strings without complete escaping.
- **Canonical owner patch:** [Report471](doc/Draft/Reprots/Report471_LOADER_PICKER_PREVIEW_PARITY_LIVE_REVALIDATION_20261023.md), with complete replacement blocks in [Report470](doc/Draft/Reprots/Report470_PICKER_PREVIEW_PARITY_FRESH_REVALIDATION_20261023.md) and [Report468](doc/Draft/Reprots/Report468_PICKER_PREVIEW_PARITY_SCHEMA_CORRECTED_20261023.md). Patch A uses `items!run_sheet_details_item_id_fkey(description)`; Patch B replaces only the abbreviated preview block; Patch C/D harden `App._img` and `App.showItemDetail`. Preserve Report469/470's `Picked → مكتمل التحضير` label and hide Start for Picked.
- **Production/source mutation:** none. No test business data, inventory, reservation, schema, RLS, RPC, or Edge changes were made; the issue is presentation-only and current read contracts already support the required fields.
- **Verification:** current source and Production schema/RLS/Edge identities are verified. Patch is **not present** in current Picker SHA. Cloudflare served-HTML parity and browser E2E after owner merge remain **UNVERIFIED**.
- **Closure:** `OWNER SURGICAL PATCH READY / SERVED HTML PARITY + BROWSER E2E OPEN / NOT CLOSED`.
- **Next exact step:** owner re-fetches Picker and checks SHA; if unchanged, applies only Patches A–D from Report470/468 with Report469 corrections; deploys the frontend; then verifies served HTML, Open/Confirmed/Picked previews, escaping, empty state, back/start actions, active-session restore, company isolation, mobile layout, and unchanged stock/reservations. Do not alter Loader or main.html for this gap.


---

## CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report472 Fresh Loader/Picker + Production Recheck

- **Scope:** Loader-versus-Picker runsheet preview parity only. Owner applies changes to operational HTML; assistant must not edit main.html, loader.html, or picker.html.
- **Fresh Git source:** Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines). Both match the blobs recorded in Report471.
- **Fresh Production SQL:** `2026-10-23 12:02:10.368502+00 UTC`. `items.description` and `items.image_url` exist; `run_sheet_details.description` does not. FK `run_sheet_details_item_id_fkey` links `run_sheet_details.item_id → items.id`; `run_sheet_details_runsheet_id_fkey` links details to `runsheets.id`.
- **Fresh Production Edge inventory:** `start-picking` ACTIVE v35/JWT true/hash `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a`; `complete-picking` ACTIVE v18/JWT true/hash `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537`; `start-loading` ACTIVE v5/JWT true/hash `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7`; `complete-loading` ACTIVE v11/JWT true/hash `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`.
- **Confirmed current defect:** Picker still uses `.select('*')` for `run_sheet_details`, has no `pickerPreviewTotalQty`, and retains abbreviated preview/unsafe HTML interpolation. Loader preview is richer and contains a read-only total/value summary.
- **Owner surgical patch:** Report472 at `doc/Draft/Reprots/Report472_PICKER_LOADER_PARITY_FRESH_PRODUCTION_RECHECK_20261023.md`, commit `f652e8b5fe58e16642a7c8660ca49e3b09031183`. Apply Patch A (FK relationship select), Patch B (full preview block from Report470 with Report469 state-label correction), Patch C (`App._img`), and Patch D (`App.showItemDetail`) only if current SHA is unchanged and each patch is not already present.
- **Production mutation:** none. No schema/RLS/RPC/Edge/data changes; none are justified for this presentation-only gap. No synthetic Production fixture was created.
- **Verification status:** Git source + DB schema/FK + live Edge inventory verified. Owner application, Cloudflare served-artifact parity, and Browser E2E remain UNVERIFIED. Do not call this CLOSED.
- **Next exact step:** Owner re-fetches Picker and checks SHA; if unchanged, applies Patches A–D from Reports470/468 with Report469 correction, deploys through the approved frontend path, then verifies served HTML and Browser E2E including Open/Confirmed/Picked states, description, XSS/URL handling, company isolation, active Dexie session, back/start actions, mobile layout, and unchanged stock/reservations.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report471 Self-Contained Owner Changeset Correction

## Scope and ownership
- Scope remains the Loader/Picker runsheet preview parity change only.
- The assistant did not edit the operational files picker.html, loader.html, main.html, or core.js.
- Report471 was corrected to include every complete replacement block directly, instead of requiring the owner to assemble code from earlier reports.
- Corrected Report471 commit: 39dad87375731ca634f9b0e6a1953f0c761b2e26; blob SHA cc0f4ae8d989d029e0a0286e2a3930441028d8c5.

## Current source snapshot
- Loader: erp-frontend/companies/company-1/warehouse/loader.html, SHA 97b83d68a683df77c1e0557838c24a1b4fb65169, 332 lines.
- Picker: erp-frontend/companies/company-1/warehouse/picker.html, SHA d483bd15b36585b975b63c2ef641481a01d5d084, 1058 lines.
- Shared core: erp-frontend/companies/company-1/core.js, SHA ff2f581d9900543c16f7cb026e13446520c0329d.
- Loader refactor: commit 152e5b1d22aab94d2cf01070778b357df4701aff, parent e69c9af4b56d99ba29a4fa74282f78438b9f7010.
- Picker latest file commit checked: eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7, parent fbcd4c7e1845236455f026eb3f7ae0ccfa8ba407.
- Fresh source still does not contain the owner preview patch.

## Fresh Production verification
- Read-only SQL verification at 2026-10-23 11:56:09.253978 UTC: items.description and items.image_url exist; run_sheet_details.description does not.
- FK run_sheet_details_item_id_fkey: run_sheet_details.item_id → items.id.
- FK run_sheet_details_runsheet_id_fkey: run_sheet_details.runsheet_id → runsheets.id.
- Current read policies scope runsheets/items to company and permissions; run_sheet_details requires a matching parent runsheet in the current company and one of the established runsheets/warehouse/reports permissions.
- Current status count: two Picked runsheets for the observed company, zero Open or Confirmed runsheets in this count. No test/business rows were inserted, updated, or deleted.
- Edge Functions rechecked: start-picking v35 SHA fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a; complete-picking v18 SHA 14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537; start-loading v5 SHA afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7; complete-loading v11 SHA c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286. All ACTIVE and verify_jwt=true.

## Exact owner patch package
Report471 now includes the complete independent owner patch:
1. Patch A: query items!run_sheet_details_item_id_fkey(description).
2. Patch A2: use the nested item description in the existing active-Picking session mapping; this removes the old reference to the nonexistent detail-table column.
3. Patch B: replace only the abbreviated non-active preview rendering block, preserve active-session recovery and the surrounding Promise closure, show total requested quantity and description, and map statuses accurately.
4. Patch C: replace App._img(code) only; permit HTTP(S) and single-root-relative paths but reject //host and unsupported protocols.
5. Patch D: replace App.showItemDetail(...) only; escape all text and validate the image URL.

Authoritative report:
doc/Draft/Reprots/Report471_LOADER_PICKER_PREVIEW_PARITY_LIVE_REVALIDATION_20261023.md.

## Verification and closure
- Verified: source SHAs, relevant Git parents, schema/foreign keys, RLS read policies, current Edge versions, and current runsheet status counts.
- Not verified: owner patch applied, served HTML parity, or browser E2E after patch.
- Production changes: none justified; no schema/RLS/RPC/Edge/business-data changes made.
- Closure: SELF-CONTAINED OWNER PATCH READY / SOURCE + DB CONTRACT VERIFIED / SERVED HTML PARITY + BROWSER E2E OPEN / NOT CLOSED.
- Next exact step: owner re-fetches Picker and checks SHA. If unchanged, apply only Report471 Patches A, A2, B, C, D; publish using the existing frontend path; verify Open/Confirmed in an approved test environment and Picked read-only behavior; prove images/text are safe and stock/allocations remain unchanged. Do not edit Loader or main.html for this finding.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report473 Picker Preview Parity Revalidation

- **Closure unit:** Picker runsheet preview parity with Loader; owner-only source changes.
- **Current source re-fetch:** Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (1 lines); Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1 lines). Neither operational file was modified by the assistant.
- **Fresh Production SQL:** project `fiilmooggumokxanwiyx`; `items.description` and `items.image_url` exist; `run_sheet_details.description` does not; both expected foreign keys exist; current runsheet status count is `Picked: 2` and no other statuses are present in this count.
- **Confirmed defect:** Picker preview still uses `.select('*')` and its abbreviated preview; description must be read via `items!run_sheet_details_item_id_fkey(description)`. The active-session mapping also needs the single-line nested-description correction.
- **Authoritative complete owner patch:** Report471, Patches A/A2/B/C/D. Report472 is a historical pointer and should not override the complete corrected blocks in Report471.
- **Production:** no DDL, RLS, RPC, Edge, or data changes; none justified. No synthetic data created and no records deleted.
- **UNKNOWN:** Cloudflare served HTML parity with Git.
- **UNVERIFIED:** owner patch, deployment, Browser E2E, and Open/Confirmed browser states.
- **LAST VERIFIED EVENT:** `LVE-2026-10-23-473`, SQL/source revalidation and continuity update; report commit `f39bca5e66fa82f3cc1caec81e3a099cad25c421`.
- **Next exact action:** owner re-fetches Picker and checks SHA; if unchanged, applies only Report471 Patches A/A2/B/C/D, deploys through the existing frontend path, then verifies served HTML and browser E2E. Do not edit Loader, main.html, or core.js. Do not change Production for this presentation-only gap.

- **Documentation recovery note:** a continuity-ledger write briefly produced an empty file; the prior committed ledger was restored, the new event appended, and the restored content verified. Final memory blob SHA `36306ca568ef4cfdbf0e30ae3361c8ee3a2b71f7`. No operational/Production data changed.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report474 Loader Refactor Rebase

- **Target:** picker.html runsheet preview parity with loader.html; owner-only operational source patch.
- **Fresh source:** Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines).
- **New historical fact:** Loader commit `152e5b1d22aab94d2cf01070778b357df4701aff` (“Refactor preview modal HTML generation”), parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`, replaced the old modal with the current inline responsive summary/cards/event-wired preview. Report471's Patch B is now stale visually and is superseded by Report474 Patch B.
- **Production SQL read-only:** items.description and items.image_url exist; run_sheet_details.description does not; both item and runsheet foreign keys exist; current status count `Picked: 2` only.
- **Defects confirmed in Picker:** abbreviated preview; details query omits joined item description; active session reads missing detail.description; inline click-handler string construction; unsafe image/detail HTML interpolation.
- **Owner patch:** Report474 A/A2/B/C/D. Patch B reuses Loader's responsive summary/cards and preview metrics but keeps Picker semantics and start action gated to Open/Confirmed; it does not mutate stock/reservations. Patch B supersedes Report471 B only; A/A2/C/D remain applicable after SHA recheck.
- **No Production schema, RLS, RPC, Edge, or business-data changes.** No test records created or deleted. Do not touch Loader, main.html, or core.js.
- **UNKNOWN:** Cloudflare served artifact parity. **UNVERIFIED:** owner merge, deploy, browser E2E, Open/Confirmed behavior.
- **LAST VERIFIED EVENT:** `LVE-2026-10-23-474`; Report474 creation commit `9a657c589224ead26326667cafefe514e8073ef8` (later report addendum commit recorded in GitHub response).
- **Next exact action:** owner re-fetches Picker, checks SHA; if unchanged applies A/A2/B/C/D from Report474, then validates syntax, preview states, image/text safety, and no inventory/allocation mutation in Staging; deploy and verify served HTML + Browser E2E before closure.

- **Report474 correction verified:** Patch B uses local `formatPreviewNumber()` (Picker has no `RW_UI` namespace); image URL regex literals in Patch D were normalized and re-read after update. Latest Report474 update commit `68d6e9555219d0c41a32145f1fbc74131a410ae7`, blob `c9025663f8ee0bb79bc2e88ae6242be38d00f25c`.



---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report475 Consolidated Picker Preview CTO Re-investigation

- **Closure unit:** Picker runsheet preview parity with Loader; operational source changes remain owner-only.
- **Source authority:** actual app source is `papamohammed77-glitch/erp-frontend` main; this repository stores reports/state. Historical reports are not executable truth.
- **Fresh current source:** Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines). Neither app file was edited. Latest Loader preview refactor is commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`.
- **Production SQL read-only snapshot:** 2026-10-23 12:24:37 UTC; PostgreSQL 17.6; items=18; run_sheet_details=12; items.description and items.image_url exist; run_sheet_details.description is absent; item_id and runsheet_id FKs exist; current runsheet status aggregate is Picked=2 only, no Open/Confirmed in result.
- **Defects confirmed:** abbreviated Picker preview; details query omits joined description; active session reads nonexistent detail.description; inline onclick interpolates DB values; unsafe image/detail HTML interpolation.
- **Consolidated current owner changeset:** `doc/Draft/Reprots/Report475_PICKER_PREVIEW_PARITY_CONSOLIDATED_CTO_EXECUTION_20261023.md`, commit `53ec7826a121ef5c8767c3fb7f1b4ce7059d0ff2`, blob `496e18243085101728fba7f15870d72b33927943`. Self-contained patches A/A2/B/C/D, current selectors, complete replacements, architectural boundaries, validation plan and rollback. Patch B/C/D syntax parsing passed. Report474's previous Patch D inline-onerror escaping must not be reused.
- **No Production or operational changes:** no source edits, Schema/RLS/RPC/Edge changes, business-data writes, or test rows created/deleted.
- **Unknown/unverified:** Cloudflare served HTML parity, owner patch, deployment, authenticated browser E2E. Source patch not applied; task remains NOT CLOSED.
- **Next exact action:** owner re-fetches Picker, verifies the base SHA, applies Report475 patches A→A2→B→C→D only if unchanged, tests syntax and scenarios in Staging, confirms no stock/reservation changes, then checks Cloudflare-served HTML and authenticated browser E2E. Do not modify Loader, main.html, core.js, or Production for this display issue.



---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report475 Image-Fallback Recheck (LVE-476)

- Report475 was amended after review found that `App._img(code)` is also used in `App.renderActiveSession()`. Removing inline `onerror` without wiring active-session image-error handling would regress the old thumbnail fallback.
- Patch E added to Report475: bind image error handling in `renderActiveSession()` and handle already-failed loads. Patch B now also handles images whose error completed before its listener was attached.
- Final Report475 blob SHA: `130cca676845487a4106c3252ce531e88e430eff`; patches A/A2/B/C/D/E are included.
- JavaScript parse checks passed for replacement blocks B/C/D/E. The new C/D replacements contain no inline `onerror` handler.
- Current operational SHAs remain unchanged: Loader `97b83d68a683df77c1e0557838c24a1b4fb65169`; Picker `d483bd15b36585b975b63c2ef641481a01d5d084`. Operational source was not edited.
- Production remains read-only. No schema, RLS/RPC/Edge or business-data writes; no fixtures created/deleted.
- NOT CLOSED: owner patch not applied; Cloudflare served HTML and authenticated Browser E2E unverified.
- Next: re-fetch Picker SHA, apply A→A2→B→C→D→E only if unchanged; test Staging including active session/image fallback, preview states, authorization/company isolation, unchanged stock/reservations; then verify Cloudflare HTML and authenticated Browser E2E.


---

# CURRENT FORENSIC CHECKPOINT — 2026-10-23 — Report476 Fresh Production Revalidation

- **Scope:** Picker runsheet preview parity with current Loader. Operational app edits remain owner-only.
- **Fresh source re-fetch:** Loader `companies/company-1/warehouse/loader.html` SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker `companies/company-1/warehouse/picker.html` SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines). Current files were not modified.
- **Historical baseline:** review PWA and New/Original Picker both SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`. Loader preview refactor commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`.
- **Fresh Production SQL:** checked 2026-10-23 14:17:01–14:18:09 UTC; PostgreSQL 17.6; items=18; run_sheet_details=12; status aggregate `Picked: 2` only. `items.description` and `items.image_url` exist; `run_sheet_details.description` does not. FK `run_sheet_details_item_id_fkey` and same-company read policies were verified. No `Open/Confirmed` fixture was present in the returned status aggregate.
- **Confirmed defects:** Picker preview is abbreviated; details query omits the joined item description; active-session mapping reads a nonexistent detail column; DB values are interpolated into inline handlers; image/detail HTML lacks complete escaping/URL validation.
- **Authoritative surgical set:** Report475, blob SHA `130cca676845487a4106c3252ce531e88e430eff`, patches A/A2/B/C/D/E. Do not use superseded Report471/472/474 Patch B or the older inline-`onerror` Patch D.
- **New fresh verification report:** [Report476_PICKER_PREVIEW_PARITY_FRESH_PRODUCTION_REVALIDATION_20261023.md](doc/Draft/Reprots/Report476_PICKER_PREVIEW_PARITY_FRESH_PRODUCTION_REVALIDATION_20261023.md), commit `fd8fc30e0d9c24dae9c8d7a159afb68ebf9965cf`.
- **Production:** read-only only. No schema/RLS/grants/RPC/Edge/business data changes; none are justified for this display/query-shape defect. No test fixtures created or deleted.
- **UNKNOWN/UNVERIFIED:** Cloudflare-served HTML parity, owner patch application, Staging tests, authenticated browser E2E.
- **Closure:** `SOURCE + PRODUCTION CONTRACT REVALIDATED / OWNER PATCH REQUIRED / NOT CLOSED`.
- **Next exact action:** owner re-fetches Picker and checks SHA. If unchanged, apply Report475 patches A→A2→B→C→D→E only; validate full script syntax; test preview state gates, description relation, escaping, images, Dexie active session, company isolation, and zero stock/reservation/log delta in Staging; deploy through the existing frontend path; verify Cloudflare served artifact and authenticated Browser E2E. Do not edit Loader, main.html, core.js, or Production for this presentation-only defect.
