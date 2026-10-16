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
