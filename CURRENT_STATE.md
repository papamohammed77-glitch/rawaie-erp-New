# CURRENT FORENSIC CHECKPOINT — 2026-10-10 — Report398 POS INTEGRATION CONTRACT AUDIT

> هذا checkpoint أحدث من سجلات Order Taker السابقة لكنه لا يغيّر أو يغلق Closure Unit الخاصة بها. تم فحص Production وGit مباشرة في هذه الدورة. لم يتم تعديل ملفات الواجهة أو قاعدة البيانات.

## Current POS source
- Target: `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`.
- Current Git blob SHA: `6ad4da791b72260b922847246ebce93b552d2bad`, 80,447 chars / 1,115 lines.
- Historical review copy `rawaie-erp-review/PWA/sales/pos.html` and the retrieved historical POS file had the same blob SHA.
- Shared `companies/company-1/core.js` blob: `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81`.
- `main.html`, `pos.html`, and `core.js` were not modified per owner merge rules.

## Fresh Production snapshot — 2026-10-10
- Supabase project: `fiilmooggumokxanwiyx`.
- `save-sales-invoice`: v18 ACTIVE, `verify_jwt=true`, package SHA-256 `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`.
- `complete-return`: v26 ACTIVE, `verify_jwt=true`, package SHA-256 `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d`.
- `public.save_sales_invoice_atomic(jsonb,jsonb,text,text)`: `SECURITY DEFINER`, ACL `postgres/service_role` only.
- The RPC performs invoiced POS/van stock movement through `post_stock_movement`; no new Edge Function or schema was added.
- Live row counts at this inspection: orders=3, order_details=11, runsheets=1, run_sheet_details=5, inventory_log=12, journal_entries=10. No data was deleted; do not delete ORD-1001/1002/1003 without re-proving dependency safety in a new inspection.
- Production logs include successful `save-sales-invoice` v18 HTTP requests on 2026-10-09, but these logs do not establish POS-specific browser E2E.

## Confirmed POS defects
1. `self.syncDown` clears each Dexie table before checking the Supabase response's `error`; a failed/partial fetch can erase good local cache.
2. `self.enterApp` has no catch for initial sync failure.
3. POS does not pass a per-sale `operation_id`. Production Edge's fallback deterministic UUID is derived from user + identical payload + branch, so separate identical sales can collide at the idempotency layer.
4. UI offers cash/card/split, but the current Production RPC determines cash by `paymentType === 'نقدي'` and routes that path through `post_cash_receipt_atomic`. The current contract does not prove correct settlement for card/wallet/split. The documented safe patch fails closed for unsupported methods.
5. POS return UI displays a cash/card return method, but Production `complete-return` v26 does not accept or forward a refund method; it calls `complete_sales_return_credit_note_atomic`. The current UI message must not claim that cash/card was refunded.

## Report / owner merge
- Report: [Report398_POS_INTEGRATION_FORENSIC_REVIEW_20261010.md](doc/Draft/Reprots/Report398_POS_INTEGRATION_FORENSIC_REVIEW_20261010.md)
- Report commit: `98ed12c037fcdeaf3412111369f5e0180e74a434`.
- The report contains complete replacement bodies for `self.syncDown`, `self.enterApp`, and `self.finalizeCheckout`, plus the precise return-method contract mismatch and post-merge test plan.
- No Production mutation was necessary or made in this cycle; current Edge/Core stock contract is centralized. No POS-specific HTTP/browser test was run because the protected frontend patch has not yet been applied and published.
- Closure: `ROOT CAUSE VERIFIED / OWNER PATCH PACKAGE COMMITTED / POS RUNTIME E2E PENDING / NOT CLOSED`.
- Next exact action: owner merges Report398 patches in `companies/company-1/sales/pos.html`, publishes, then runs the authenticated POS test matrix in Report398 section 6. Re-read Production, Git, and served artifact before closing.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-10 — Report397 ORDER TAKER CUSTOMER ID / CODE MISMATCH

> هذا أحدث checkpoint لهذه المشكلة ويقدّم على توصية الواجهة في Report396 فيما يخص الحالة الفعلية الحالية. أُعيدت قراءة Production وGit في هذه الدورة؛ لا تعتمد على هذا النص بدل إعادة القراءة عند بدء الجلسة التالية.

## Production / source resync
- Supabase project: `fiilmooggumokxanwiyx`.
- `update-order`: v6 ACTIVE، `verify_jwt=true`، Production package SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.
- Production RPC `public.update_order_atomic(uuid,text,text,jsonb,jsonb,text,uuid)` يبحث عن العميل باستخدام `customers.customer_code` مع `company_id`، ويحدّث order.customer_id بعد حلّ العميل.
- Live DB integrity check at this inspection: orders=1, customers=3, orphan/cross-company customer links=0. `ORD-1001` currently links to a customer in the same company with canonical customer_code `CUST-158938`; DO NOT delete it without fresh proof it is a safe fixture.
- Unified Logs query returned a backend error; no claim is made about the exact failing request log.
- Current frontend `erp-frontend/companies/company-1/sales/order-taker.html` blob SHA: `e1ab0f35218672cc7134cf18a7a35daaa807a757`.
- Current frontend includes the source attribution fix `hdr.source='order-taker'`, the transactional/error-aware `syncDown`, and the `enterApp` catch. This supersedes Report396's stale statement that these patches remain pending.
- Root cause confirmed in `self._editOrderFromDetail`: it assigns `order.customer_id` UUID to `selCust.customer_code` and queries Dexie by `customer_code = order.customer_id`. `submitOrder` then sends the UUID in `orderHeader.customer_code`, which Production RPC correctly rejects.
- Same UUID/code confusion appears in `self.repeatOrder` lookup. No Edge/RPC/schema change is indicated; repair the consumer contract.

## Current work / exact next action
- Report: [Report397_ORDER_TAKER_EDIT_CUSTOMER_ID_CODE_MISMATCH_20261010.md](doc/Draft/Reprots/Report397_ORDER_TAKER_EDIT_CUSTOMER_ID_CODE_MISMATCH_20261010.md).
- Report commit SHA: f9ec1c773864395a12299efbc2a8fd7dcdeffc8c.
- Owner must apply Report397 Patch D in `erp-frontend/companies/company-1/sales/order-taker.html`, function `self._editOrderFromDetail`, and Patch E in `self.repeatOrder`. Per owner instruction, assistant did not edit the operational frontend file.
- Do not touch `main.html`, `core.js`, or Production RPC for this issue.
- After patch/publish: test edit preserving customer, correct payload customer_code, company isolation, cache miss/failure safe abort, repeat order, no inventory/runsheet side effects; then verify served artifact and restore test baseline.
- Closure: `ROOT CAUSE VERIFIED / SURGICAL PATCHES DOCUMENTED / FRONTEND RUNTIME E2E PENDING / NOT CLOSED`.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-10 — Report396 ORDER TAKER SOURCE ATTRIBUTION / PRODUCTION RESYNC

> هذا أحدث checkpoint لهذه الوحدة. Production أعيدت قراءته قبل وبعد النشر. لا تعتبر التقرير وحده حالة حية؛ أعد فحص Production وGit قبل أي تعديل جديد.

## Production Edge — current verified state
- Project: `fiilmooggumokxanwiyx`.
- `save-sales-invoice`: v18 ACTIVE, `verify_jwt=true`, package `ezbr_sha256=43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308`.
- إصلاح تصنيف المصدر نُشر على Edge Function الموجودة؛ لم تُنشأ Function جديدة.
- Production source `index.ts` = Current Git source نصيًا (6,885 chars).
- Current Git blob: `1864c012f323068ceba5e1f2a0791a2c8bd10dbd`; commit: `b13814da8c0342aeadc16baf6ff45bb12c40decb`.
- `update-order`: v6 ACTIVE, `verify_jwt=true`; لم يتغير.
- RPC ACL: `save_sales_invoice_atomic` و`update_order_atomic` لا تسمحان بـEXECUTE لـanon/authenticated، وتسمحان لـservice_role فقط.

## Production cleanup — re-read, not historical assumption
- أُعيد اكتشاف fixture أعيد إنشاؤها بعد Report395: ORD-1001/ORD-1002/ORD-1003 وRS-1.
- كل الأوردرات Pending ومن `telesales@rawaea.com`، والكميات الميدانية صفر، ولا توجد حركات مخزون أو قيود محاسبية أو اعتماديات تشغيلية مرتبطة حسب الفحوصات المسجلة في Report396.
- حُذف RS-1 ثم الأوردرات الثلاثة مع تفاصيلها؛ audit_log محفوظ.
- Post-cleanup verified: `orders=0`, `order_details=0`, `runsheets=0`, `run_sheet_details=0`; fixture movement/journal counts = 0.

## Current frontend status — owner-side patches only
- Target `erp-frontend/companies/company-1/sales/order-taker.html` blob `6fa258e51284bfc8c35fd66fb709d904024f989f`; **لم يُعدّل**.
- Shared `companies/company-1/core.js` blob `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81`; **لم يُعدّل**.
- `main.html` لم يُعدّل.
- Patches documented in Report396:
  1. Set `hdr.source='order-taker'` only in create branch before `save-sales-invoice`.
  2. Replace `self.syncDown` to check all Supabase errors before clearing Dexie and update local stores transactionally.
  3. Catch `self.enterApp` sync failure, load local branches and show warning.
- Do not alter update flow; edits remain on existing `update-order` → `update_order_atomic` path.
- No new Edge Function, no new schema, no main.html/core.js edits.

## Report / closure
- Report: `doc/Draft/Reprots/Report396_ORDER_TAKER_INTEGRATION_PRODUCTION_SOURCE_ATTRIBUTION_20261010.md`.
- Report commit: `d57efae35b0a526c8e448d5d38f3705eaac94c00`.
- Current closure: `PRODUCTION SOURCE-ATTRIBUTION FIX DEPLOYED / TEST FIXTURES CLEANED / OWNER FRONTEND PATCHES A-B-C PENDING / NOT CLOSED`.
- Not proven: authenticated browser E2E after v18; Cloudflare Pages/Service Worker artifact parity; runtime of owner-side patches before apply/publish.
- Next: owner applies A/B/C in order-taker.html, publishes, then test roles orders-only, orders+telesales, owner wildcard; verify source attribution, no stock movement for Confirmed, edit preserves original source, runsheet linkage, syncDown failure safety, and baseline cleanup.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-10 — Report395 TELESALES CURRENT GIT / PRODUCTION RECONCILIATION

> هذا checkpoint أحدث من Report394. أُعيد فحص Production وGit والسجلات في الجلسة نفسها. لا تُعد تطبيق جراحة RW_Auth أو submitOrder؛ المصدر الحالي يحتويهما بالفعل. لا تدّعِ أن Cloudflare artifact الحالي مطابق قبل إثباته.

## Production re-read — 2026-10-10
- Project: fiilmooggumokxanwiyx.
- save-sales-invoice: v17 ACTIVE, verify_jwt=true, ezbr_sha256=fee635a235a3f8e42db8f72e792bbf2a828fb6a444f082c59bc8e95c4fa9ddb1.
- update-order: v6 ACTIVE, verify_jwt=true, ezbr_sha256=a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3.
- get_my_effective_profile(): SECURITY DEFINER, search_path empty, anon EXECUTE=false, authenticated EXECUTE=true; uses auth.uid() and merges direct/role permissions.
- Production HTTP logs: save-sales-invoice POST 200 at 2026-10-09T22:59:29.693Z and 2026-10-09T23:00:24.844Z. erp_operation_registry recorded successful update_order for ORD-1001. Re-read confirmed Production source equals Current Git source: save-sales-invoice 6,494/6,494 chars (Git blob 9ee86c7ee8ed92c79fe37c209ac3392db63f3f87); update-order 5,528/5,528 chars (Git blob a729c50a1f45fa78c4f5c86504f5c7fdb9ca18b3). These are not proof of the currently served frontend artifact.

## Current frontend Git — actual latest source
- Latest relevant commits in erp-frontend: a626a3e96945915a51822897c6316c0aa32502e2 (core.js auth/profile) and a914f11f089c8c0154d41acc312d7d02b5327cf7 (telesales submitOrder).
- core.js current blob: c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81.
- sales/telesales.html current blob: b6fbd7e94ee957745adcd97e3e61015052645e8c.
- main.html blob: 4f94f9c6ebdde1b59632384628c72767d3bb950d; connector returned empty content; untouched.
- Current telesales submitOrder already routes create to save-sales-invoice, edit to update-order, and resolves customer UUID to canonical customer_code. Current RW_Auth already calls get_my_effective_profile(). Do not replace these again.
- Remaining proven UI defect: syncDown does not check Supabase result.error before clearing Dexie, risking local-cache loss on failed fetch. Report395 supplies exact replacements for syncDown and the enterApp rejection handler.

## Production test-data cleanup — completed and verified
- Removed fixture ORD-1001/ORD-1002/ORD-1003 and RS-1, including their order_details/run_sheet_details and the matching update_order operation-registry row.
- Pre-cleanup evidence: all orders Pending, runsheet Open, picked/loaded/delivered/refused/returned quantities zero, no inventory_log movements, no accounting entries, no payment/delivery/commission/backorder dependencies.
- Post-cleanup verified counts: orders=0, order_details=0, runsheets=0, run_sheet_details=0, matching operation registry row=0.
- audit_log was retained.

## Report and exact next action
- Report: doc/Draft/Reprots/Report395_TELESALES_CURRENT_GIT_PRODUCTION_RECONCILIATION_20261010.md
- Report commit: b55a3a41f873eae2c0b2934b0d33570e3e05121a
- No frontend files, Edge Functions, schema, or production RPCs were changed in this cycle; only the explicitly identified test fixture was cleaned.
- Next: owner applies Report395's two surgical replacements in telesales.html (syncDown and the self.enterApp syncDown handler), without touching main.html; then verify Cloudflare-served artifact/service worker and run authenticated browser E2E for direct/role permissions, create/edit/idempotency, runsheet linkage, company/branch isolation, no stock movement, and baseline restoration.
- Closure: BACKEND VERIFIED / CURRENT GIT SURGERY PARTIALLY PRESENT / SYNCDOWN SURGERY PENDING / NOT CLOSED.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-10 — Report394 TELESALES PRODUCTION RESYNC

> أحدث فحص في هذه الجلسة: Production أُعيدت قراءته مباشرة؛ لا تُعامل تقارير Report392/393 كحالة حية. لم يتم تعديل `main.html` أو `telesales.html` أو `core.js`. لا تزال جراحة الواجهة والنشر واختبارات HTTP/Browser مطلوبة قبل إغلاق التكامل.

## Production re-read — 2026-10-10

- Supabase project: `fiilmooggumokxanwiyx`.
- `save-sales-invoice`: v17 ACTIVE, `verify_jwt=true`, package SHA-256 `fee635a235a3f8e42db8f72e792bbf2a828fb6a444f082c59bc8e95c4fa9ddb1`.
- `update-order`: v6 ACTIVE, `verify_jwt=true`, package SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.
- `public.get_my_effective_profile()`: موجودة؛ `SECURITY DEFINER`, `search_path=''`, `anon EXECUTE=false`, `authenticated EXECUTE=true`. تعتمد `auth.uid()` وتدمج الصلاحيات المباشرة وصلاحيات الدور.
- Baseline الحالي عند الاستعلام: `orders=0`, `order_details=0`, `runsheets=0`, `run_sheet_details=0`.
- لم يحدث تعديل جديد في Production في هذه المراجعة.

## Current frontend artifact identity

- `erp-frontend/companies/company-1/main.html`: blob `4f94f9c6ebdde1b59632384628c72767d3bb950d`; أداة GitHub أعادت محتوى فارغًا، ولم يُعدّل.
- `erp-frontend/companies/company-1/sales/telesales.html`: blob `d839ff043631d365be8eb2832ee98aa4fabcb43c`; لم يُعدّل.
- `erp-frontend/companies/company-1/core.js`: blob `e853c49375ccc8b94757b594057dcd853b4a2fdb`; لم يُعدّل.

## Latest report and next actions

- Report394: [Report394_TELESALES_PRODUCTION_RESYNC_AND_SURGICAL_PATCH_20261010.md](doc/Draft/Reprots/Report394_TELESALES_PRODUCTION_RESYNC_AND_SURGICAL_PATCH_20261010.md), commit `3c4a94cf08c7c15ec4cf903445704bce3875eaab`.
- Replace only the complete `RW_Auth` IIFE in `core.js` using Report393 section 3.
- Replace only `self.submitOrder = function() { ... };` in `telesales.html` using Report392 section 3.
- Do not touch `main.html`; owner applies frontend edits.
- After publish: regression-test every PWA consumer of `RW_Auth`, then authenticated HTTP/Browser E2E for direct and role-derived permissions, create/edit, idempotent retry, no stock movement, runsheet linkage, company/branch isolation, and baseline restoration.
- Closure: `BACKEND VERIFIED / FRONTEND SURGERY PENDING / NOT CLOSED`.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-10 — Report393 TELESALES ROLE-PERMISSION PARITY

> هذا أحدث checkpoint ويقدّم على Report392. لا يُغلق تكامل الواجهة؛ لا يزال المالك مسؤولًا عن تطبيق الجراحة في `erp-frontend/companies/company-1/core.js` و`sales/telesales.html` ثم النشر وHTTP/Browser E2E. لم يتم تعديل `main.html` أو `telesales.html` أو `core.js`.

## Live Production re-read — same session

- Supabase project: `fiilmooggumokxanwiyx`.
- `save-sales-invoice`: v17 ACTIVE, `verify_jwt=true`, package SHA-256 `fee635a235a3f8e42db8f72e792bbf2a828fb6a444f082c59bc8e95c4fa9ddb1`.
- Git Current source `Current/Edge_Functions/save-sales-invoice`: blob SHA `9ee86c7ee8ed92c79fe37c209ac3392db63f3f87`; byte-for-byte equal to deployed v17 source (6,494 bytes). Commit `aabaed938038d3dee934a01b5ee7a943594724a2`.
- The prior Current file was stale (2,228 bytes) compared with Production v16 (5,512 bytes). Recovered v16 from live Production, added role-aware permission merge, then deployed v17.
- `update-order` remains v6 ACTIVE, `verify_jwt=true`, package SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.
- Added authenticated `public.get_my_effective_profile()` via Production migration `20261009220629_telesales_effective_profile_rpc_20261010`; `SECURITY DEFINER`, `search_path=''`, `anon EXECUTE=false`, `authenticated EXECUTE=true`. It returns only the caller profile and merges direct plus role permissions.
- RPC QA using a role-only sales user: profile found, company context present, inherited `orders` permission found, 30 effective permissions; transaction rolled back.
- Post-deploy baseline: `orders=0`, `order_details=0`, `runsheets=0`, `run_sheet_details=0`, sales/runsheet operation registry rows=0.
- Thirteen older QA/Test marker matches remain only in historical `audit_log` records. Do not delete audit history casually; no live sales/runsheet business rows remain.

## Git artifacts and provenance

- Migration source: `supabase/migrations/20261009220629_telesales_effective_profile_rpc_20261010.sql`, commit `694f6a736d7215dd3d3f4c7a5af598c7b05fbc2c`.
- Execution report: `doc/Draft/Reprots/Report393_TELESALES_ROLE_PERMISSION_PARITY_20261010.md`, commit `bbdfb7c909b21114083091058c2f78f1405f87fc`.
- `erp-frontend/companies/company-1/main.html`: blob SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d`; connector returned empty content, so no claim is made about internals and it remains untouched.
- `erp-frontend/companies/company-1/sales/telesales.html`: blob SHA `d839ff043631d365be8eb2832ee98aa4fabcb43c`, unchanged.
- `erp-frontend/companies/company-1/core.js`: blob SHA `e853c49375ccc8b94757b594057dcd853b4a2fdb`, unchanged.

## Exact next action — owner-side surgical change

1. In `companies/company-1/core.js`, replace only the complete `RW_Auth` IIFE before `// الوحدة ٢: RW_DB` with the RPC-backed complete replacement in Report393, section 3. This supersedes the earlier `RW_Auth` replacement in Report392.
2. In `companies/company-1/sales/telesales.html`, replace only `self.submitOrder = function() { ... };` with the complete replacement in Report392, section 3. It routes edits to `update-order`, preserves create via `save-sales-invoice`, and resolves customer UUID to canonical `customer_code`.
3. Do not edit `main.html`. After owner publishes the frontend, run authenticated HTTP/browser E2E: direct-permission and role-derived-permission login, create/edit, duplicate retry, no inventory movement, runsheet linkage, company isolation, and baseline restoration.

## Closure status

`BACKEND PRODUCTION FIX VERIFIED / FRONTEND SURGERY PENDING / HTTP-BROWSER E2E NOT YET PROVEN`.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-09 — Report392 TELESALES INTEGRATION HARDENING

> هذا أحدث checkpoint. يُقدّم على التقارير الأقدم، لكن لا يُغلق تكامل الواجهة؛ تعديلات الواجهة ما زالت تنتظر تطبيق المالك ونشرها واختبارها.

## Production snapshot re-read in this session

- Supabase Production project: `SMART ERP` / `fiilmooggumokxanwiyx`, status `ACTIVE_HEALTHY`.
- Existing Edge Function `update-order`: **v6 ACTIVE**, `verify_jwt=true`, package SHA-256 `a1b06430b9d90777f7d9549286d9c64e7df009c5d15a19917ce6be096a00c8f3`.
- `update-order` now combines direct `public.users.permissions` with same-company `roles.permissions` and `role_permissions.permission_key` before checking `*`, `orders`, or `telesales`.
- Existing PostgreSQL RPC `public.update_order_atomic(uuid,text,text,jsonb,jsonb,text,uuid)` remains `SECURITY DEFINER`; ACL verified as `postgres/service_role` only.
- Applied Production migration `fix_update_order_idempotency_after_order_lock_20261009`; the RPC rechecks the completed operation registry after locking the order row.
- Production row counts at post-QA verification: `orders=0`, `runsheets=0`, `order_details=0`, `run_sheet_details=0`; QA registry and audit residue were both zero.
- SQL transaction QA called the RPC twice with the same `operation_id`, verified second response `duplicate=true` and one detail row, then rolled back. This is not concurrent multi-session testing or HTTP/browser E2E.

## Git/source provenance

- Mother source `erp-frontend/companies/company-1/main.html`: blob SHA `4f94f9c6ebdde1b59632384628c72767d3bb950d`. GitHub connector returned empty content even for line-range fetches. File was not changed; do not infer its internal behavior from this checkpoint.
- Telesales PWA `erp-frontend/companies/company-1/sales/telesales.html`: blob SHA `d839ff043631d365be8eb2832ee98aa4fabcb43c`; unchanged by assistant.
- Shared core `erp-frontend/companies/company-1/core.js`: blob SHA `e853c49375ccc8b94757b594057dcd853b4a2fdb`; unchanged by assistant.
- Canonical current Edge source added at `Current/Edge_Functions/update-order`, blob SHA `a729c50a1f45fa78c4f5c86504f5c7fdb9ca18b3`, commit `c03a39d69ba8fc1cc9da8b7bd53368163d856e24`; this Git blob SHA is distinct from the Production package SHA-256.
- Canonical SQL migration added at `supabase/migrations/20261009210000_fix_update_order_idempotency_after_order_lock_20261009.sql`, commit `54f5bfa7794878aa2771ca083eff8170c1e3851b`.
- Full execution report: [Report392_TELESALES_INTEGRATION_HARDENING_20261009.md](doc/Draft/Reprots/Report392_TELESALES_INTEGRATION_HARDENING_20261009.md), commit `658d6d0daa6ce98ba0a698a3a8dcf3ad465920fc`.

## Exact remaining owner-side frontend surgery

1. In `companies/company-1/sales/telesales.html`, replace the full `self.submitOrder = function() { ... };` block with the corrected replacement in Report392. It routes edits through `update-order`, retains creation through `save-sales-invoice`, and resolves the existing edit flow's customer UUID to canonical `customer_code`.
2. In `companies/company-1/core.js`, replace the complete `RW_Auth` IIFE with Report392's DB-backed replacement only after reviewing/regression-testing all shared-core consumers.
3. Do not modify `main.html` or claim the integration is closed until the owner publishes the frontend and a real authenticated browser/HTTP test proves create/edit/authorization/runsheet linkage and no inventory side effects.

## Current closure status

`BACKEND HARDENED / OWNER FRONTEND SURGERY PENDING / FULL TELESALES INTEGRATION NOT CLOSED`.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-09 — Report391 TELESALES CENTRAL ORDER INTEGRATION

> This block is the latest execution checkpoint. It records verified backend work and explicitly separates owner-side frontend work that remains pending.

## Production snapshot — Supabase SMART ERP / fiilmooggumokxanwiyx

- Project ref: `fiilmooggumokxanwiyx`; status was ACTIVE_HEALTHY at inspection.
- Current frontend sources inspected:
  - `erp-frontend/companies/company-1/sales/telesales.html`, blob SHA `d839ff043631d365be8eb2832ee98aa4fabcb43c`.
  - `erp-frontend/companies/company-1/core.js`, blob SHA `e853c49375ccc8b94757b594057dcd853b4a2fdb`.
- Production Edge `update-order`: v5 ACTIVE, `verify_jwt=true`, package SHA-256 `d70b7ff7596ee71ad3a706388466abec03921cb7d09010fa4ea18371376de283`.
- Existing Edge `save-sales-invoice` remains v16; no new Edge Function was created.
- Production currently has 0 rows in `orders` and 0 in `runsheets` at inspection time; do not claim a real business-order E2E.
- RLS is enabled on `orders`, `order_details`, `runsheets`, and `run_sheet_details`.

## Production changes executed

- Applied migration `telesales_update_order_status_and_duplicate_guard_20261009`: update-order RPC now confirms an edited eligible order and checks duplicate JSON item `code` correctly.
- Applied migration `fix_telesales_update_order_duplicate_guard_alias_20261009`: corrected the SQL alias after the first transactional QA exposed the mismatch.
- Applied migration `fix_telesales_update_order_audit_action_constraint_20261009`: audit uses allowed `action='update'` while preserving `table_name='orders'`, `source_type='telesales'`, and operation identity.
- Canonical source files for all three migrations were added under `supabase/migrations/`:
  - `20261009164325_telesales_update_order_status_and_duplicate_guard_20261009.sql` — commit `6de7c8ffcec48e57e191f21ebaa45abf59bcad2e`.
  - `20261009164549_fix_telesales_update_order_duplicate_guard_alias_20261009.sql` — commit `e74020920dbd56b3822bb0b89d0bf86c1b38b8f2`.
  - `20261009164638_fix_telesales_update_order_audit_action_constraint_20261009.sql` — commit `4e762f36d4c16941e17fa1b1414a5fdcb83efab5`.
- Updated full execution report: `doc/Draft/Reprots/Report391_TELESALES_CENTRAL_INTEGRATION_20261009.md`; latest report commit `e9e762f05d39953beeafe806f0e9de07f314886b`.
- Deployed existing Edge Function `update-order` v5 with DB permission validation (`*`, `orders`, or `telesales`) and company/branch-scope validation before calling `update_order_atomic`.
- Transactional QA exercised update-to-Confirmed, detail persistence, duplicate-item rejection, and no `stock_branches` / `inventory_log` changes, then rolled back. The first QA runs exposed and led to repairs of the SQL alias and audit CHECK mismatch. A post-rollback production count check confirmed `orders=0`, `runsheets=0`, QA order residue `0`, QA audit residue `0`, and QA operation-registry residue `0`. This proves cleanup for this transactional QA only; it is not browser/HTTP E2E evidence. A direct HTTP attempt from this runtime could not resolve the Supabase hostname (DNS/network unavailable), so HTTP behavior remains unverified rather than reported as passed.

## Proven frontend integration defect

- Current `telesales.html` edit flow directly updates `orders`, deletes `order_details`, then reinserts them through separate requests. This bypasses the existing atomic `update-order` Edge / `update_order_atomic` RPC and risks partial persistence.
- Complete surgical replacements are documented in:
  [Report391_TELESALES_CENTRAL_INTEGRATION_20261009.md](doc/Draft/Reprots/Report391_TELESALES_CENTRAL_INTEGRATION_20261009.md)
- Owner must replace the complete `self.submitOrder` block in `telesales.html` to route edits to `update-order`.
- Owner must replace the `RW_Auth` block in shared `core.js` to hydrate permissions from `public.users` by `auth_id`, not Auth `user_metadata`. This shared-core change requires regression testing across dependent PWAs.
- Do not claim full telesales closure until the owner-side files are published and browser/HTTP E2E verifies create/edit/authorization/runsheet linkage.

## Next exact checkpoint

1. Re-read current production function version and SQL definition before any additional backend edits.
2. Apply Report391's full `RW_Auth` replacement and `self.submitOrder` replacement to the owner-managed frontend sources.
3. Run syntax checks, publish the frontend/PWA assets, and verify served artifact identity against Git.
4. Test as a real authenticated telesales account: create, edit, duplicate item rejection, unauthorized user, disallowed branch, retry, and no stock side effect.
5. Link a confirmed order into a runsheet and verify `orders.runsheet_id` and `run_sheet_details`; do not fabricate a production E2E while current production has no orders/runsheets.
6. Only after frontend runtime evidence, close this integration unit.

---

# CURRENT FORENSIC CHECKPOINT — 2026-10-02 — REPORT390 ITEMS / OWNER WILDCARD / IMAGE / COST PRICE

> هذا checkpoint هو آخر حقيقة مُثبتة، ويُقدَّم على أي blocks تاريخية أدناه. لا تُعاد إصلاحات موجودة في Current HEAD.

## Current Git / Mother Source
- Frontend repo: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- HEAD: `768ee12721a85511e38618666c29568f0658615c`
- Parent: `bc4d7a02919dcaf82d11bb599e879281cd550737`
- Mother source: `companies/company-1/main.html`
- Current blob: `2b5b763ada7428f96a05c1144c75f13eec5b1492`
- Current source: 32,349 lines / 1,755,533 chars.

## Production
- Supabase project: `SMART ERP` / `fiilmooggumokxanwiyx`
- Edge Functions count: exactly 100.
- No new function created.
- `save-item`: v14, ACTIVE, verify_jwt=true; DB users permissions authority.
- `save-category`: v5, ACTIVE, verify_jwt=true; metadata-based owner bypass removed; authorization now DB `users.permissions`.
- `delete-item`: v5, ACTIVE, verify_jwt=true; metadata-based owner bypass removed; authorization now DB `users.permissions`.
- Owner DB contract verified: `public.users.permissions=["*"]`, Active, owner_profile license_status=active, auth linkage valid.
- Product-images authenticated INSERT policy is DB-permission scoped; public SELECT remains intentional.

## Open Owner Frontend Surgery
### A — RW_Auth.login()
Current defect: authorization identity is hydrated from `user.user_metadata`.
Exact complete replacement is in Report390 section 3.
Target: block beginning with:
`return RW_SUPABASE_CLIENT.from('users').select('company_id, status')`
inside `RW_Auth.login()`.
After replacement, owner derives from DB wildcard `permissions=["*"]` and `RW_STATE.permissions` comes from DB.

### B — RW_Items.resolveImageUrlAndSave()
Current defect: new-image upload failure falls through to save using the old URL; upload uses `upsert:true`.
Exact complete replacement is in Report390 section 5.
Target helper around lines 5578–5617.
After replacement: upload failure aborts save continuation; `upsert:false`.

### C — RW_Items.openItemPage()
Proven UI capability gap: `cost_price` exists in DB/RPC/Edge and is used elsewhere, but the item form does not expose it.
Exact surgical replacement in Report390 section 6:
- Replace current single sales-price HTML line around line 5519 with the two-line cost + sales price block.

### D — executeSave()
Exact surgical replacement in Report390 section 6:
- Replace current `sales_price:` payload line around line 5631 with `cost_price:` followed by `sales_price:`.
Do not replace the whole function.

## Items Current Truth
- Item CRUD, categories, pricing/inventory controls, opening stock, image preview/viewer, store visibility, marketing, movement, matrix and stock upload all exist.
- Historical `_renderTable()` rowHtml/branch drill-down regression is already fixed in Current HEAD. Do NOT reapply Report153.
- DirectSale/DirectReturn representative column is already in Current HEAD (commit 768ee): `المندوب`, `custodian_name`, `colspan="11"`. Do NOT reapply Report384/388.
- Current navigation/router maps `items -> items`; current permission vocabulary has `items` and `*`, not granular `items.create/update/delete`. Do not invent granular permissions in this closure.

## QA Evidence
- Real Production transaction test was created then rolled back completely.
- Test item code: `ITM-20260928`.
- Create/opening path posted opening stock = 3 to BR-01; allocated = 0; one inventory_log row.
- Same transaction edited name, sales price 25→27, cost price 10→11, show_in_store false→true, category cleared to NULL, image_url changed.
- Journal entries total remained 10 during the item edit.
- After rollback:
  - items=17
  - categories=5
  - inventory_log=12
  - journal_entries=10
  - QA item/category/inventory-log residue=0.
- Static Node syntax check of owner and image surgical blocks: PASS.
- Browser-rendered E2E and served-artifact identity remain OPEN because no browser/deployment artifact inspection tool is available here.

## Security / Advisory Boundary
Current Supabase advisors still report broader existing findings outside this Items closure (RLS-enabled tables without policies, SECURITY DEFINER views/functions, mutable search_path). They were not silently changed because they are separate contracts requiring individual blast-radius analysis.

## Protected / Closed Contracts
- owner wildcard `permissions=["*"]`
- DirectReturn RECEIVE -> InventoryIncrease
- stock movement core / post_stock_movement
- runsheet/picking/loading/delivery/return/unloading workflow
- DirectSale/DirectReturn representative projection already present in Current HEAD
- existing save-item v14 and storage public-read behavior

## Report
- Report390: `doc/Draft/Reprots/Report390_MOTHER_ITEMS_OWNER_WILDCARD_IMAGE_COST_FORENSIC_CLOSURE_20261002.md`
- Report commit: `3410879d59de5c435ba1d3b33042ce09de413cfb`

## Next Exact Resumption Point
1. Verify whether the owner has applied the exact 4 frontend surgical substitutions in Current Mother source.
2. Syntax gate.
3. Publish the updated Mother.
4. Fresh login.
5. Browser E2E:
   - إدارة التراخيص
   - item create/edit
   - cost price round-trip
   - image success and image-upload failure abort
   - store visibility
   - categories CRUD
   - representative column.
6. Compare served artifact with Current Git.
7. Only then move to the next unresolved contract.


# CURRENT FORENSIC CHECKPOINT — 2026-10-01 — Report389

> This block supersedes stale header values below. Reports remain historical evidence; current truth is rebuilt from Current Git + Current Source + Current Production + Current Database + Current Deployment Evidence.

## Current Git / Source of Truth

- Frontend repo: `papamohammed77-glitch/erp-frontend`
- branch: `main`
- HEAD: `768ee12721a85511e38618666c29568f0658615c`
- parent: `bc4d7a02919dcaf82d11bb599e879281cd550737`
- `companies/company-1/main.html` blob: `2b5b763ada7428f96a05c1144c75f13eec5b1492`
- Current inline JS parse gate: PASS.

## Important Reconciliation

The older CURRENT_STATE/Reports 384–388 described a pre-768 state. Commit 768 already contains the DirectSale/DirectReturn `المندوب` column and `colspan=11` changes in `_renderVoucherHistory()`. Do NOT reapply Report388 surgery unless served artifact/runtime proves it is older than Current Git.

## Owner / License Tab

Production owner record is currently proven as:
- `public.users.permissions=["*"]`
- status Active
- auth_id linked correctly to owner_profile
- owner_profile license_status = active
- Auth metadata currently also contains isOwner=true, but metadata is NOT the authority.

Current main defect:
`RW_Auth.login()` hydrates `currentUser.isOwner` and `RW_STATE.permissions` from `user.user_metadata` instead of DB `users.permissions`.

Owner surgical replacement is documented in Report389 section 6:
`return RW_SUPABASE_CLIENT.from('users').select('company_id, status')...`
→ select DB permissions/name, derive `isOwner` from `permissions[*]`, and populate `currentUser.permissions`.

## Items

Current Items module is present and integrated:
- CRUD
- category
- pricing
- inventory controls
- opening stock
- image URL
- show_in_store
- discounts/marketing
- online-store visibility
- movement and branch matrix

Proven current defect:
`RW_Items._handleSaveFromPage() → resolveImageUrlAndSave()`
continues into `executeSave()` after image upload failure by falling back to old image URL.

Owner surgical replacement is documented in Report389 section 9. It aborts on upload failure and changes `upsert:true` to `upsert:false`.

Current Items table renderer is already corrected; do NOT repeat the historical `rowHtml` branch-loop fix from Report153.

## Production Changes Executed

Supabase project: `fiilmooggumokxanwiyx`

### save-item
Existing Edge Function only; NO new function.
- version 13 → version 14
- verify_jwt = true
- authorization now uses DB `users.permissions` only (`items` or `*`)
- category clear now explicitly writes `category_id=null` and `category=null`
- existing company scoping / opening-stock RPC / item code generation preserved.

### product-images Storage
- removed public INSERT policy
- removed duplicate generic authenticated INSERT policies
- created `product_images_authenticated_insert_items`
- upload allowed only for active authenticated users whose DB user or role has `items` or `*`
- public SELECT remains because online-store assets are intentionally public
- no UPDATE policy added; frontend upload now uses `upsert:false`

## QA / E2E Evidence

Transactional QA was run with real Production structures and rolled back.

Create + opening stock:
- create success=true
- opening balance posted=true
- branch qty delta +2
- allocated=0
- inventory_log rows=1
- journal_entries unchanged at 10
- then ROLLBACK

Edit + store visibility:
- opening_balance_posted=false
- inventory_log before/after edit = 0/0
- journal_entries before/after = 10/10
- show_in_store=true became store-eligible
- category_id cleared to null
- image_url persisted
- then ROLLBACK

Cleanup after tests:
- QA items = 0
- QA inventory logs = 0
- QA voucher residue = 0

## Current Production Item Counts

- items = 17
- active + store-visible items = 17
- items with image_url = 16

## Browser / Deployment Boundary

Browser-rendered E2E is still OPEN because this environment has no browser interaction tool for the deployed runtime. Served-artifact identity is also OPEN.

## Next exact checkpoint

1. Apply only Report389 Owner surgical block to current main.html.
2. Apply only Report389 image helper surgical block to current main.html.
3. Syntax check.
4. Publish.
5. Fresh login/session.
6. Verify إدارة التراخيص.
7. Verify item create/edit/image failure/success/store visibility.
8. Verify DirectSale/DirectReturn representative column.
9. Verify served artifact matches Current Git.
10. Do not redo Reports 384–388 unless runtime proves an older artifact.

Full details: `doc/Draft/Reprots/Report389_MOTHER_OWNER_WILDCARD_ITEMS_IMAGE_FORENSIC_SURGICAL_20261001.md`

---

# CURRENT FORENSIC CHECKPOINT — 2026-09-30 — REPORT379 VAN SALES EXECUTION

Authoritative basis: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
Historical reports are guidance only.

## Latest verified frontend reality
- Frontend repository: papamohammed77-glitch/erp-frontend
- Target: companies/company-1/sales/van-sales.html
- Latest frontend HEAD: 1b89202949575eaebed4c5bf5512322129a114fb
- Parent: c67de5a0b601e2cc0690bf40c32d46632140f95e
- Current blob: 568db68e1465578cebf0231c9b1b653065608c52
- Latest commit fixes the malformed loadCustomerPatterns promise tail.

## Current Van Sales open defect
- showRecentCustomers() currently resolves public.users by id = this.currentUser.id.
- Production proves public.users.id differs from auth.users.id for active direct-sales users.
- Exact protected owner surgical patch: `.eq('id', this.currentUser.id)` -> `.eq('auth_id', this.currentUser.id)`.
- Do not modify picker.html, main.html, or warehouse/vouchers.html in this unit.

## Production backend / Inventory Rescue
- setup-van-branch v5 ACTIVE
- save-sales-invoice v15 ACTIVE
- save-receipt-voucher v8 ACTIVE
- save-inventory-count v5 ACTIVE
- save-daily-settlement v4 ACTIVE
- start-picking v14 ACTIVE
- complete-picking v13 ACTIVE
- start-loading v4 ACTIVE
- complete-loading v10 ACTIVE
- reopen-loading v2 ACTIVE
- unload-runsheet v5 ACTIVE
- post_stock_movement is the only direct UPDATE writer detected for public.stock_branches; reserve_stock/release_stock_reservation are reservation writers.
- inventory_log INSERT was detected in post_stock_movement only.

## Experimental data
- Executed historical vouchers IN-1, IN-8, IN-9 remain because they already generated stock/audit history and current integrity guards do not permit safe hard deletion.
- Inspected physical residual is neutralized/zero; known canary users/runsheets/orders/customers are absent.

## Current report
- Report379: doc/Draft/Reprots/Report379_VAN_SALES_FORENSIC_EXECUTION_20260930.md
- Report commit: ac278ad4a2aabde1094d35be45917f52b0ea5c57

---
# CURRENT FORENSIC CHECKPOINT — 2026-09-30 — REPORT378 VAN SALES PARSE FAILURE

Authoritative basis: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
Historical reports are guidance only.

## Latest verified frontend reality
- Frontend repository: papamohammed77-glitch/erp-frontend
- Target: companies/company-1/sales/van-sales.html
- Latest HEAD: c67de5a0b601e2cc0690bf40c32d46632140f95e
- Parent: e5f3e8ed0e2a491a243bce0029aeb2e73cc824dc
- Current blob: 012fba212bc2ecf0d21a8990fca76190c27701f8
- 3295 lines / 151087 chars
- JavaScript full-script parse: FAIL — Unexpected token ')'
- Parent 74b122f9c2721178f27dd8f495cfd61134bb5399 parses successfully.
- e5f3e8e... introduced the malformed loadCustomerPatterns tail; c67 did not repair it.

## Exact root cause
- Function: App.loadCustomerPatterns()
- Approximate defect line: 583
- Defective sequence:
  `    });`
  `        }).catch(function() {});`
- Surgical replacement:
  `    })`
  `        .catch(function() {});`
- Independent V8 parse of the corrected source: PASS.
- App is not defined is a consequence of the parse failure; picker.html is unrelated to this Van Sales syntax root cause.

## Latest Van Sales state
- Current source contains 65 App methods + global resolveCustomer.
- Historical baseline contains 65 App methods + _createVanBranch; _createVanBranch responsibility moved to setup-van-branch.
- repeatOrder and initiateEndOfDay changes are present in c67 and are not the parse root cause.
- Protected frontend files: van-sales.html, main.html, warehouse/vouchers.html. No automatic frontend edit performed.

## Production backend verified
- setup-van-branch v5 ACTIVE
- save-sales-invoice v15 ACTIVE
- save-receipt-voucher v8 ACTIVE
- save-inventory-count v5 ACTIVE
- save-daily-settlement v4 ACTIVE
- post_van_sales_collection_atomic exists
- post_daily_settlement_atomic exists
- get_van_sales_customer_accounts and get_van_sales_customer_account exist
- runsheets schema includes company_id, driver_id, vehicle_id, workflow timestamps, loading_cycle_id.

## Open Van Sales closure order
1. Owner applies Report378 syntax replacement and deployed frontend rebuild/cache refresh.
2. Browser E2E of van-sales.
3. Close remaining open units in existing order:
   repeatOrder
   initiateEndOfDay
   then any remaining direct-scope/consumer units proven open by fresh evidence.
4. Do not reopen closed units without new direct evidence.

## Report
- Report378: doc/Draft/Reprots/Report378_VAN_SALES_FORENSIC_CURRENT_REALITY_20260930.md
- Report commit: 6246f36793126ed7eee2a8a827a248ae6b744a98

---

# CURRENT SESSION — 2026-09-29 — REPORT370 VAN SALES COLLECT PAYMENT FORENSIC CHECKPOINT

> Authoritative evidence for this checkpoint: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. Historical reports are guidance only.

## Current frontend truth
- Frontend repository: papamohammed77-glitch/erp-frontend
- Target: companies/company-1/sales/van-sales.html
- Latest frontend HEAD: cf90684a3b1afd017a97e7b7802e9308d6ae158c
- Parent: 016a219419fbfcf6227135d99eea4813ea94e224
- Current van-sales.html blob: 0e6926a15d3d6ea59ed8e01fa7b1ce5adc140235
- Current source size: 2667 lines / 133773 chars
- Protected: van-sales.html, main.html, warehouse/vouchers.html — not automatically modified.

## Current production truth
- setup-van-branch v5, ACTIVE
- save-sales-invoice v15, ACTIVE
- save-receipt-voucher v8, ACTIVE
- post_van_sales_collection_atomic exists and is atomic/idempotent through erp_operation_registry.

## Current collectPayment finding
- The latest frontend refactor already supplies customerId + operationId to save-receipt-voucher v8.
- The remaining defect is that operationId is generated anew on every confirmation attempt.
- Therefore a committed collection followed by a lost response can be retried as a new operation and bypass the server idempotency registry.
- Exact surgical owner patch is recorded in:
  doc/Draft/Reprots/Report370_VAN_SALES_COLLECT_PAYMENT_FORENSIC_CLOSURE_20260929.md
- Required patch: persist pending operation identity until confirmed success; remove it only after confirmed success.

## Backend conclusion
- No Production DB/Edge change was required for this specific frontend defect.
- post_van_sales_collection_atomic already uses erp_operation_registry keyed by company_id + operation_type + operation_key and posts treasury + customer ledger atomically.
- post_cash_receipt_atomic and post_customer_ledger_entry were verified as atomic financial primitives.

## Existing applied work — do not repeat
- Report368 custody-source corrections are already present in current frontend HEAD.
- showRecentCustomers() live company/source-scoped path is present.
- _loadVehicleStock() live stock/source-scoped path is present.
- enterApp() stops on syncDown failure.
- setup-van-branch v5 uses authenticated user company and primary direct-sales assignment.
- save-sales-invoice v15 uses VanSale through post_stock_movement.

## Open Van Sales closure order
1. collectPayment() — APPLY Report370 exact surgical patch, then syntax + browser E2E + Production retry/ledger verification.
2. loadMyCustomers() — company/source + authoritative customer assignment review.
3. loadCustomerPatterns() — company/source + order_id-bounded details.
4. loadKPIs() — company/source + target-source verification.
5. loadHomeSalesSummary() — company/source.
6. loadMyInvoices() — company/source.
7. showCustomerDetail() — authorization + scope.
8. repeatOrder() — authorization + scope.
9. initiateEndOfDay() — bind to existing settlement contract; not a client-only lock.

## Financial-history caution
- Production driver_ledger contains identifiable QA cleanup/reversal entries and is financial/audit history.
- Do not delete ledger history blindly; handle in a separate forensic reconciliation closure.

## Governance
- No new Edge Function and no new RPC for collectPayment.
- Do not modify main.html or warehouse/vouchers.html.
- Do not declare collectPayment 100% until the exact owner patch is applied and the full verification chain succeeds.

---

# CURRENT SESSION — 2026-09-29 — REPORT369 VAN SALES COLLECT PAYMENT CLOSURE

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. Historical reports are guidance only.

## Verified checkpoint
- Frontend repo latest verified main commit: 016a219419fbfcf6227135d99eea4813ea94e224
- Target: companies/company-1/sales/van-sales.html
- Reports368 custody patches are already present in the current source and must not be repeated.
- Protected: main.html, warehouse/vouchers.html.

## Current verified production
- setup-van-branch v5
- save-sales-invoice v15
- save-receipt-voucher v8
- post_van_sales_collection_atomic exists and executed successfully inside ROLLBACK.

## Current open closure
- App.collectPayment() still sends legacy receipt payload without header.customerId/header.operationId.
- Production save-receipt-voucher v8 requires operationId and routes customer collections to post_van_sales_collection_atomic when customerId is provided.
- Exact surgical replacement is recorded in Report369.

## Required next action
- Owner applies ONLY Report369 replacement to App.collectPayment in van-sales.html.
- Do not modify main.html or vouchers.html.
- Then syntax gate → browser E2E → Production verification.
- Do not open the next Van Sales unit until collectPayment reaches 100% closed.

---

# CURRENT SESSION — 2026-09-29 — REPORT368 VAN SALES CUSTODY RECONCILIATION

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. Historical reports are guidance only.

## Verified checkpoint
- Frontend repo: papamohammed77-glitch/erp-frontend
- Current frontend main HEAD: 751c10723bfa5ed2ce6c3ae12561a179c5ecb56e
- Target: companies/company-1/sales/van-sales.html
- Current van-sales source has the prior showRecentCustomers syntax fix from commit 751c107...; the older CURRENT_STATE reference to 22e2 is stale.
- Protected frontend files remain untouched: main.html, vouchers.html, van-sales.html.

## Production facts verified
- CHV-2025-01 is canonically assigned to vansales@rawaea.com through fleet_vehicle_sales_rep_assignments; VHL-0422 to vansales2@rawaea.com.
- setup-van-branch is currently Production v5 and resolves direct-sales vehicle assignment through fleet_vehicle_sales_rep_assignments.
- save-sales-invoice is currently Production v15 and posts VanSale through the central post_stock_movement path.
- save-receipt-voucher is currently Production v8 and supports post_van_sales_collection_atomic.
- Van stock rows exist canonically in stock_branches. Production currently has 17 rows for each inspected VAN branch, including explicit zero-quantity rows.
- inventory_stock_snapshot confirms stock_value_at_cost is the central inventory valuation field; the current Van Sales UI uses sales_price for commercial display.

## Proven root causes for the custody/value discrepancy
1. loadHomeStockSummary reads local Dexie stock and calculates total value using only the first 5 stock rows.
2. _loadVehicleStock reads local Dexie stock and calculates total value across all rows.
3. Therefore «عهدتي الآن» and «سيارتي» can display different values for the same vehicle stock.
4. enterApp swallows syncDown failures and continues into loadVanBranch, allowing stale/empty cache to be presented as current custody data.
5. _renderVehicleStockHTML renders zero-quantity stock rows, making valid zero rows appear as active custody items.
6. «رصيدي» is a driver_ledger financial liability and is not the same measure as physical stock custody value; it must not be forced to equal stock value.

## Current surgical owner patch
Report: doc/Draft/Reprots/Report368_VAN_SALES_CUSTODY_RECONCILIATION_FORENSIC_20260929.md
- Patch 1: replace enterApp syncDown continuation to stop on sync failure instead of silently continuing.
- Patch 2: replace loadHomeStockSummary to read live stock_branches + company-scoped items and calculate value across all positive stock rows.
- Patch 3: replace _loadVehicleStock to use the same live source and same value basis, while scoping today's sales by company + source='van-sales' and hiding zero-quantity rows from the current-custody display.
- No Production DB/Edge change was required for this specific defect.

## Remaining open Van Sales units
- collectPayment: legacy frontend payload despite Production save-receipt-voucher v8 contract.
- loadMyCustomers / loadCustomerPatterns / loadKPIs / loadHomeSalesSummary / loadMyInvoices: company/source scoping gaps.
- showCustomerDetail / repeatOrder: consumer authorization/scope audit required.
- initiateEndOfDay: client-only lock; settlement contract remains open.
- Browser E2E after owner-applied van-sales source patch: open.

## Session rule
Apply only the exact owner patches in Report368 to van-sales.html. Do not modify main.html or vouchers.html for this closure. Re-run syntax, then Browser E2E, then Production read verification. Do not delete zero stock rows from Production merely because the UI hides them.

---

# CURRENT SESSION — 2026-09-29 — REPORT367 VAN SALES SYNTAX FORENSIC

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Latest verified checkpoint
- Frontend repo: papamohammed77-glitch/erp-frontend
- Current frontend main HEAD: 22e2b851fde0aa136eaf6f55c617d06a4b43ed50
- Parent: 3c03e72f79bc337f89a1b27100795a522d249301
- Target: companies/company-1/sales/van-sales.html
- Root cause: latest commit 22e2 introduced a JavaScript parse failure in App.showRecentCustomers at line 1522 (Unexpected string).
- Parent 3c03 source parses successfully; current HEAD fails full-script V8 parse.
- In-memory replacement of ONLY showRecentCustomers parses successfully.
- Protected frontend files were not modified.
- Exact surgical replacement is recorded in doc/Draft/Reprots/Report367_VAN_SALES_SYNTAX_FAILURE_FORENSIC_20260929.md

## Required owner action
- Replace only showRecentCustomers:function(){...}, in van-sales.html with the exact block in Report367.
- Do not modify main.html or warehouse/vouchers.html.
- After owner patch: syntax gate -> browser E2E -> close VAN-01.

## Current Van Sales open units
- VAN-01 showRecentCustomers: syntax defect introduced by latest refactor; surgical patch ready.
- VAN-02 collectPayment: open surgical patch.
- VAN-03 company/source scoping in sales queries: open surgical patch.
- VAN-04 loadCustomerPatterns order-id-bounded query: open surgical patch.
- EOD settlement/custody reconciliation: open business contract.

---

# CURRENT SESSION — 2026-09-29 — REPORT366 VAN SALES FORENSIC INTEGRATION

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Latest checkpoint
- Report: \`doc/Draft/Reprots/Report366_VAN_SALES_FORENSIC_INTEGRATION_SURGICAL_COMPLETION_20260929.md\`
- Report commit: \`6e8f9938909c244435c5bd845bc472280f95d508\`
- Protected frontend: \`companies/company-1/sales/van-sales.html\` (NOT MODIFIED)
- Protected frontend: \`companies/company-1/warehouse/vouchers.html\` (NOT MODIFIED)
- Mother \`main.html\` (NOT MODIFIED)

## Production changes executed
- \`post_driver_ledger_entry\` hardened to recompute running balance from SUM(debit-credit) with row locking.
- \`post_customer_ledger_entry\` hardened to recompute running balance from SUM(debit-credit) with row locking.
- \`save_sales_invoice_atomic\` item lookups confirmed company-scoped.
- New RPC \`post_van_sales_collection_atomic\` created for atomic Van Sales customer collection.
- Existing \`save-receipt-voucher\` deployed as v8 with Van Sales collection routing to the new RPC.
- First collection test exposed unsupported \`min(uuid)\`; corrected in migration \`20260929191000_fix_van_sales_collection_treasury_uuid_selection\`.
- Collection rollback test subsequently succeeded with no residue.

## Confirmed Production data
- \`vansales@rawaea.com\` and \`vansales2@rawaea.com\` are Active direct-sales representatives.
- Primary vehicle assignments exist for CHV-2025-01 and VHL-0422.
- Both vehicle.driver_id values are NULL; Master Assignment is the canonical direct-sales identity.
- Exactly one active treasury exists for RAWAEA; standard COA 121 cash and 123 AR exist.
- Customer ledger currently has zero snapshot mismatches.
- \`vansales@rawaea.com\` historical driver ledger has net=383 while latest stored snapshot=443; future postings now recompute from mathematical ledger history. Historical rows were preserved.

## Van Sales frontend open units
- \`App.showRecentCustomers()\` at ~1435: dead Dexie \`db.orders\` source; owner surgical patch required.
- \`App.collectPayment()\` at ~951: legacy receipt payload; owner surgical patch required to use customerId + operationId with save-receipt-voucher v8.
- \`loadKPIs()\` ~595: add company/source scoping.
- \`loadHomeSalesSummary()\` ~679: add company/source scoping.
- \`loadCustomerPatterns()\` ~420: add company/source scoping and order-id-bounded details query.
- \`loadMyInvoices()\` ~1026: add company/source scoping.
- \`_loadVehicleStock()\` ~1081: add company/source scoping to sold-today query.
- \`initiateEndOfDay()\` ~1278: client-only lock; requires separate Van Sales settlement contract and must not be incorrectly tied to runsheet until contract is established.
- Browser-rendered E2E after owner-applied protected-file patches remains open.

## Inventory contract
- Physical stock movement remains centralized through \`post_stock_movement\`.
- Van Sale path: save-sales-invoice -> save_sales_invoice_atomic -> post_stock_movement -> mobile branch.
- \`reserve_stock\` remains Reservation-only.
- \`setup_van_stock\` remains Initialization-only.

## Session rule
The next unit starts from the open Van Sales frontend surgical patches above; do not modify protected files automatically.


# CURRENT SESSION — 2026-09-29 — Report365 Van Sales Core Authorization Closure

> Authoritative evidence: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## Latest checkpoint
- Report: `doc/Draft/Reprots/Report365_VAN_SALES_CORE_AUTHORIZATION_CLOSURE_20260929.md`
- Report commit: `d15e10e17166b7416da06a349173b7551009a354`
- Canonical Van Sales source: `companies/company-1/sales/van-sales.html`
- Van Sales blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- Frontend HEAD verified: `3c03e72f79bc337f89a1b27100795a522d249301`
- Frontend parent: `609ab127410004ba9ee3161c8f0deaf630fbfd03`

## Production change executed
- Updated existing `public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text)`.
- VanSale authorization now supports active primary `fleet_vehicle_sales_rep_assignments` for Direct Sales Representatives while preserving `vehicles.driver_id` for delivery-driver fallback.
- Item resolution is now company-scoped.
- Migration source recorded at:
  `supabase/migrations/20260929150000_van_sales_post_stock_movement_assignment_auth.sql`
- Migration Git commit:
  `9e70657af60814c71efb8b93e046e2001b733d0e`
- Production positive test with `vansales2@rawaea.com` + `VHL-0422` succeeded inside rollback transaction.
- Negative mismatched-representative test was rejected.
- QA inventory log residue after rollback: 0.

## Van Sales OPEN items
- `App.showRecentCustomers()`: exact owner surgical patch required; source still uses unwritten Dexie `db.orders`.
- `collectPayment()`: payload incompatible with Production `save-receipt-voucher v7`; separate closure.
- Explicit `source='van-sales'` filters missing in sales/invoice/vehicle-stock queries; separate closure.
- `loadCustomerPatterns()`: broader-than-needed `order_details` query; separate closure.
- `initiateEndOfDay()`: client-only settlement flow; separate closure.
- Production `driver_ledger.balance` snapshot inconsistency for `vansales@rawaea.com`: sum debit-credit = 383 while latest stored balance = 443; requires controlled financial closure.
- Browser E2E against currently deployed frontend artifact remains open.

## Protected files not modified
- `erp-frontend/companies/company-1/sales/van-sales.html`
- `erp-frontend/companies/company-1/warehouse/vouchers.html`
- Mother `main.html`

# CURRENT SESSION — 2026-09-29 — Report361 Voucher Modal Print Forensic Closure

> **Authoritative checkpoint:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> Historical reports are guidance only and do not override current evidence.

## Current Git
- System repo evidence checkpoint (report commit): `bd955967fcb1590f65b43bb085eaa132e0d918d7`
- Parent at evidence checkpoint: `1c862e242a1b3fe23e11f586ecf0703bec35920a`
- `CURRENT_STATE.md` is then updated in a subsequent state commit whose parent is the report commit above.
- Report: `doc/Draft/Reprots/Report361_WAREHOUSE_VOUCHER_MODAL_PRINT_FORENSIC_CLOSURE_20260929.md`
- Report commit: `bd955967fcb1590f65b43bb085eaa132e0d918d7`

## Current Source
- Frontend HEAD: `1214f6bca0d5f851bec2be8bd3d466b4af758efd`
- Frontend parent: `386b003ccd1650444062844394a7ec6ac2f7032f`
- `companies/company-1/warehouse/vouchers.html` blob: `d231a6b1762fdd66a0c57e33a8c43a7200391a13`
- `vouchers.html`: 6625 lines / 215151 chars.
- `Current/PWA/main.html` blob: `27b777528665dcc985809648f006452c861ae36e`
- `companies/company-1/sales/van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- main.html and vouchers.html were NOT modified by this session.

## Closed / Do Not Rework
- Owner wildcard / owner identity
- Main authorization and delegation
- DirectReturn DR-UI-01, DR-UI-02, DR-UI-03A/03B, DR-UI-04
- Transfer source/destination responsibility contract
- SupplierReturn backend
- Existing voucher lifecycle/stock/accounting contracts
- Existing edge/RPC infrastructure

## Current Defect Identified
File: `companies/company-1/warehouse/vouchers.html`
Object: `App`
Function: `printVoucher:function()`
Approximate current source location: line 1664.

Defective element:
`window.open('','_blank','noopener,noreferrer,width=1200,height=900')`

The next guard immediately returns on falsy `w`.

Root cause: the implementation requests `noopener,noreferrer` from `window.open()` while requiring a usable returned window reference. The current Web API behavior permits/defines a `null` return with `noopener`, matching the observed no-response printing failure.

## Required Owner Surgical Patch
The owner must replace ONLY the complete `printVoucher:function(){...},` element immediately before `exportVoucher:function()` with the full replacement in Report361.

No whole-function rewrites beyond this one element.
Do not modify `details()`, `actionFor()`, `renderList()`, `printDraftVoucher()`, `main.html`, or `van-sales.html`.

Required replacement characteristics:
- use `Swal.getHtmlContainer()` when available;
- do not pass `noopener,noreferrer` to `window.open()`;
- use named print context `rawaea-voucher-print`;
- guard duplicate print calls;
- keep existing modal HTML/CSS print output;
- do not invoke any DB mutation.

## Production / Database
Supabase project: `SMART ERP` / `fiilmooggumokxanwiyx` / ACTIVE_HEALTHY / PostgreSQL 17.6.1.121.

Current manual production data remains:
- Completed DirectSale = 1
- Completed SupplierReturn = 4
- Received DirectReturn = 1
- Received Transfer = 1
- Sent DirectSale = 1

Verified integrity:
- IN-1: 5 details / 5 inventory_log / 3 audit / 1 driver ledger.
- IN-9: 1 detail / 2 inventory_log / 4 audit / 1 driver ledger.
- QA-SR-UI-CONTRACT-20260927-01 has stock/audit/journal/supplier-ledger effects and was NOT deleted.

No new Edge Function.
No new RPC.
No migration.
No table/RLS change.
No stock/accounting/treasury mutation was required.

## Testing
- Forensic unit simulation: `PRINT_FORENSIC_UNIT=PASS current=blocked patched=printable`.
- Cause is independently supported by current Web API documentation for `window.open()` and the SweetAlert2 `getHtmlContainer()` API.
- Current frontend HEAD `1214f6...` has no workflow run evidence from the available commit-run lookup endpoint.
- Existing GitHub browser workflow remains available, but current-HEAD authenticated/browser E2E has not been executed through the available connector and therefore remains OPEN.
- Do not mark Browser E2E PASS until an actual browser run built from the patched frontend HEAD succeeds.

## Test Fixtures / Cleanup
Do not delete the existing QA history because it has real stock/audit/financial effects.
No new persistent test fixture was required for this client-only printing defect.

## Next Session Entry Sequence
1. Re-read current Git/source; do not start from Report360.
2. Verify frontend HEAD and vouchers blob.
3. Verify old print element count = 0 and new print element count = 1.
4. Run source syntax gate.
5. Apply/verify the owner surgical patch only.
6. Run browser E2E on Pending: IN-8 and IN-9.
7. Run browser E2E on Completed: IN-1 and QA-SR-UI-CONTRACT-20260927-01.
8. Confirm print window opens and voucher code/content exists.
9. Confirm no DB mutation after print.
10. Mark the browser-print defect CLOSED only on actual browser evidence.
11. Do not reopen any previously closed business contract.
12. Move to the next genuinely OPEN item.

## Continuity Rule
Current Git/source/Production/database/deployment evidence wins over historical reports.

---

# CURRENT SESSION — 2026-09-29 — Report360 Forensic Final

> **Authoritative checkpoint:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> Historical reports are guidance only and do not override current evidence.

## Current Git

- System repo HEAD before this state write: `af7bd6c2f22b308f732ec3503a8ad21163d37d02`
- System repo parent: `817aa8851e9fdd837ad11e994d2ce09c87acef1c`
- Latest report: `doc/Draft/Reprots/Report360_WAREHOUSE_VOUCHERS_DIRECTRETURN_FORENSIC_FINAL_20260929.md`
- Latest report commit: `af7bd6c2f22b308f732ec3503a8ad21163d37d02`

### Frontend current evidence

- Frontend repo HEAD: `386b003ccd1650444062844394a7ec6ac2f7032f`
- Frontend parent: `56fee06ac0145faffbc4f71d3d6031fcd3b46f87`
- `companies/company-1/warehouse/vouchers.html` blob: `9b538a49b9ee520aaa17a097fe881167a9230abf`
- Current vouchers source lines: 6599
- `Current/PWA/main.html` blob: `27b777528665dcc985809648f006452c861ae36e`
- `companies/company-1/sales/van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

## Current forensic conclusion

The latest frontend commit `386b...` partially applied Report359 but left the DirectReturn UI contract incomplete and introduced a new syntax/runtime defect.

### Proven current source defects

1. `pickArr:function(key)` — current DR-UI-01 patch references `v.id` before `v` exists inside the filter callback.
2. `pickSelect:function(key,id)` — current fallback is malformed and causes `SyntaxError: Invalid left-hand side in assignment`.
3. `pickSearch:function(key,q)` — second vehicle display mapping still resolves from `x.driver_id` only (DR-UI-03B missing).
4. `editVoucher:function(code)` — Draft DirectReturn reopening still resolves rep from `vv.driver_id` only (DR-UI-04 missing).

### Proven already correct and MUST NOT be redone

- DR-UI-03A first vehicle search mapping.
- `routeHtml:function()` DirectReturn field is not readonly.
- Current DirectReturn `submit()` assignment-first validation.
- Main authorization / Owner wildcard semantics.
- Main delegation to `vouchers.html`.
- DirectReturn Production backend.
- DirectSale backend.
- Transfer backend.
- SupplierReturn backend/contract.

## Surgical source action

The owner must modify only `companies/company-1/warehouse/vouchers.html` using the exact four replacements in Report360:

- DR-UI-01
- DR-UI-02
- DR-UI-03B
- DR-UI-04

Do not rewrite whole functions.
Do not modify `main.html`.
Do not modify `van-sales.html`.
Do not create new Edge Functions/RPC/tables for this defect.

The four replacements were applied In-Memory to the current source and the resulting inline JavaScript passed a full Syntax Gate.

## Production evidence

Current active Master Assignment proves:

- CHV-2025-01 → `vansales@rawaea.com`; `driver_id=NULL`
- VHL-0422 → `vansales2@rawaea.com`; `driver_id=NULL`

VHL-0422 currently has mobile stock enabled and an available quantity of item `1003`.

Current Production atomic Create/Send test for DirectReturn:

- vehicle: VHL-0422
- rep: `vansales2@rawaea.com`
- destination: BR-01
- item: 1003
- result before rollback: `Sent`, `custodian_user_id = rep2`, movement count = 1
- transaction was rolled back
- no `IN-10` residue remains

A current negative pairing attempt against the wrong rep is still protected by the Production assignment contract; the backend contract itself was already closed in Report359.

## Production infrastructure decision

No Production infrastructure change is required for this source-only defect.

Existing:
- `create_manual_stock_voucher_atomic`
- `create_manual_stock_voucher_atomic_core_12_20260828`
- `update_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `receive-stock-voucher` Edge Function v22
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`

remain the active contract.

## QA history

No historical QA records with stock/audit/financial effects were deleted.

The ephemeral test created in this session was fully rolled back.

Current DirectReturn status counts:
- Draft = 0
- Sent = 0
- Received = 1
- Completed = 0
- IN-10 residue = 0

The existing Received record is historical and is not treated as test residue.

## Deployment

The current frontend HEAD `386b...` has no workflow run evidence returned by the available commit-run lookup endpoint.

The prior Browser E2E run `36483037124` was based on `56fee...`, not the current source.

Therefore Browser E2E remains **OPEN** until a run built from the fixed frontend HEAD completes successfully.

## Next session exact sequence

1. Start from current Git/Source, not Report360.
2. Verify the owner applied DR-UI-01, DR-UI-02, DR-UI-03B, DR-UI-04.
3. Run syntax gate.
4. Run Browser E2E from the new frontend HEAD.
5. Test `vansales2@rawaea.com` → `VHL-0422`.
6. Reopen Draft DirectReturn and verify `custodian_user_id` / Master Assignment.
7. Run Smart Search verification.
8. Run Create → Send → Receive.
9. Run wrong rep/vehicle negative test.
10. Verify stock, audit, custody, and no inappropriate financial/treasury side effect.
11. Only then mark DirectReturn UI CLOSED.
12. Move to the next genuinely open Business Contract.

## Continuity rule

Never re-fix what is proven closed.
If a historical report conflicts with current Git/source/Production/database/deployment evidence, current evidence wins.

---

# CURRENT SESSION — 2026-09-28 — Report359 Forensic Continuation

> **Authoritative checkpoint:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> Reports remain historical guidance only.

## Current Git
- System repo HEAD before this state write: `e5d0a760bc60345458ad6a261a9094072d48133d`
- System repo parent: `57ba850b16826fca0361757d781f3b796d8eb0cf`
- Frontend repo HEAD: `56fee06ac0145faffbc4f71d3d6031fcd3b46f87`
- Frontend parent: `31a255c6bac2e23f8ceb74734e66010039e9938c`
- Current `vouchers.html` blob: `e24eddf27d657a9baa6713b2c26b571c768cb28e`
- Current `main.html` blob: `27b777528665dcc985809648f006452c861ae36e`

## Latest report
`doc/Draft/Reprots/Report359_WAREHOUSE_VOUCHERS_DIRECTRETURN_MASTER_ASSIGNMENT_FORENSIC_CLOSURE_20260928.md`
- Report create commit: `5805225e71305830632aec8bcd117ece04e85874`

## Current forensic finding
The remaining source defect is **not** a Production DB/RPC defect.

Production's authoritative Sales Rep ⇄ Vehicle relationship is:
`fleet_vehicle_sales_rep_assignments`

Production currently proves:
- CHV-2025-01 → `vansales@rawaea.com`; `driver_id = NULL`
- VHL-0422 → `vansales2@rawaea.com`; `driver_id = NULL`

Current `vouchers.html` still contains legacy-first `vehicles.driver_id` usage in four UI locations:
1. `pickArr:function(key)` — DirectReturn vehicle list for direct-sales rep.
2. `pickSelect:function(key,id)` — DirectReturn rep selection fallback path.
3. `pickSearch:function(key,q)` — vehicle/rep resolution in result mapping, two occurrences.
4. `editVoucher:function(code)` — reopening Draft DirectReturn rep from `driver_id`.

## Owner surgical patch set
The owner must apply only the exact replacements in Report359:
- DR-UI-01
- DR-UI-02
- DR-UI-03A
- DR-UI-03B
- DR-UI-04

Do **not** rewrite whole functions.
Do **not** modify `main.html`.
Do **not** modify existing Production RPC/Edge contracts unless new evidence proves a backend defect.

## Closed and must not be reopened
- Main authorization / Owner wildcard semantics
- Main delegation to `vouchers.html`
- Transfer backend
- DirectSale backend
- SupplierReturn backend/contract
- DirectReturn backend
- Report357/Report358 closed items
- Existing assignment-first submit/route logic in `vouchers.html`

## Production verification completed
- DirectReturn Create → Send → Receive: PASS in transaction, rolled back.
- DirectReturn invalid vehicle/rep pairing: correctly rejected by Production RPC.
- Transfer Create → Send: PASS in transaction, rolled back.
- DirectSale Create → Send: PASS in transaction, rolled back; movement=1; custody ledger=true.
- Existing posted QA history was **not deleted** because it already has stock/audit/financial effects.
- No new persistent QA records were left by these tests.

## Deployment evidence
Workflow:
`.github/workflows/warehouse_vouchers_browser_e2e_20260920.yml`

Latest workflow source commit:
`56fee06ac0145faffbc4f71d3d6031fcd3b46f87`

The validator bug was in the test harness, not the app. Its embedded Node validator now parses successfully.

Latest observed workflow run:
- Run ID: `36483037124`
- Head SHA: `56fee06ac0145faffbc4f71d3d6031fcd3b46f87`
- Last observed status during this session: `in_progress`

Do not mark Browser E2E as PASS until completed/success evidence exists.

## Infrastructure decision
No new Edge Function was created.
No new RPC/table was required.
Existing atomic RPC/stock-voucher contract is sufficient for the current defect.
No Production infrastructure change was executed.

## Next-session exact sequence
1. Start from current Git, not from an old report.
2. Check Run `36483037124` or the newest Warehouse Vouchers Browser E2E run.
3. Open current `vouchers.html`.
4. Apply only DR-UI-01 → DR-UI-04 from Report359.
5. Syntax/source validation.
6. Browser E2E.
7. Test `vansales2@rawaea.com` and verify VHL-0422 appears as DirectReturn source vehicle.
8. Reopen a Draft DirectReturn and verify `custodian_user_id` is preserved.
9. Verify Smart Search resolves the rep from Master Assignment.
10. Run DirectReturn Create → Send → Receive.
11. Run negative pairing test.
12. Only after all evidence passes, mark DirectReturn UI contract CLOSED and update this file again.
13. Then move to the next genuinely open Business Contract gap.

## Self-audit rule
Never re-fix what is already proven closed.
If historical reports conflict with current Git/source/Production/database/deployment evidence, the current evidence wins.

---

# CURRENT STATE — 2026-09-28 — Report358 DirectReturn Rep Smart Search / Master Assignment Checkpoint

## AUTHORITATIVE CURRENT REALITY
This section supersedes earlier CURRENT_STATE sections for the DirectReturn representative-search closure unit. Earlier sections remain historical records only.

### CURRENT GIT — SYSTEM
- System HEAD immediately before this final CURRENT_STATE write: a5012fca02fb988fa0194f064cf20d9d20492a3f
- Parent of that execution commit: 04cb7741e84cedf7719515cab33ab967d214808c
- This CURRENT_STATE write is the continuity checkpoint; next session MUST re-read current Git to obtain the new state commit SHA before proceeding.
- Prior state commit: c5d20c5c9cd82afaa587a155b2ebe031d03f43fc
- Report: doc/Draft/Reprots/Report358_WAREHOUSE_VOUCHERS_DIRECTRETURN_REP_SMARTSEARCH_FORENSIC_CLOSURE_20260928.md
- Production migration source recorded at:
  supabase/migrations/20260928221500_vouchers_directreturn_rep_assignment_contract_fix_20260928.sql

### CURRENT GIT — FRONTEND
- Current Frontend HEAD: f28cbe21abe2dfc8d03d02fb0491cc984a273c13
- Parent verified by compare: 8b6b32145aafdb49ae10af8f36aa888e4d25d412
- Latest HEAD commit: Add draft voucher check for current user
- companies/company-1/warehouse/vouchers.html current blob: 60f4b85ecf3dc32e45cc944bbbbd512ac37ea2a2
- vouchers.html current size: 6,340 lines / 208,577 chars
- main.html remains protected and untouched
- van-sales.html remains protected and untouched

### CURRENT SOURCE — PROVEN ROOT CAUSE
Target:
companies/company-1/warehouse/vouchers.html

The DirectReturn representative picker had three coupled Consumer-Layer defects:

1. routeHtml() around line 4268 called:
   p('wsRep','مندوب البيع المباشر',true)
   so the search input was readonly.

2. pickArr() around line 3601 derived branch context from wsFrom. In DirectReturn wsFrom is a Vehicle ID, not a Branch ID. Therefore the generic wsRep path could resolve no branch and return an empty representative list.

3. pickSelect() around line 4116 resolved DirectReturn representative only through vehicle.driver_id and then made wsRepSearch readonly. Current Production vehicles use fleet_vehicle_sales_rep_assignments as the active primary relationship while driver_id is NULL.

A fourth coupled source defect existed in submit():
the DirectReturn validation derived rr from vv.driver_id rather than treating the selected/master-assigned representative as the current contract.

### CURRENT PRODUCTION — PROVEN RELATIONSHIP
Production authoritative relationship:
public.fleet_vehicle_sales_rep_assignments

Current active Primary assignments observed:
- CHV-2025-01 -> vansales@rawaea.com
- VHL-0422 -> vansales2@rawaea.com

For these vehicles Production shows driver_id = NULL.

Existing public.fleet_query('direct_sales_rep_assignments') returns the active Master Assignment rows correctly under an authenticated actor.

### PRODUCTION FIX EXECUTED
No new Edge Function.
No new table.
No new RPC.

Existing functions updated in-place:
- public.create_manual_stock_voucher_atomic_core_12_20260828
- public.update_manual_stock_voucher_atomic

DirectReturn representative validation now uses:
1. active primary fleet_vehicle_sales_rep_assignments
2. legacy vehicles.driver_id fallback

This preserves historical compatibility while aligning the current operation with the Mother system's authoritative Master Assignment.

### PRODUCTION QA — THIS SESSION
Pre-fix forensic fixture:
- An invalid DirectReturn pairing (CHV-2025-01 + vansales2) was accepted by the pre-fix Create contract as IN-9.

Post-fix:
- The same invalid pairing was rejected with:
  المركبة المصدر لا تتبع مندوب البيع المباشر المحدد
- A valid pairing (CHV-2025-01 + vansales@rawaea.com) created IN-10 successfully.
- Authenticated update of the valid Draft was executed inside a transaction and returned success; transaction was rolled back.
- IN-9 and IN-10 were deleted with the existing Draft deletion guard.
- Current transient Draft count after cleanup: 0
- Current DirectReturn voucher count after cleanup: 0

### OWNER FRONTEND PATCH — OPEN / NOT APPLIED BY ASSISTANT
The owner must patch only vouchers.html.

Required surgical elements are stored in Report358:
1. routeHtml() DirectReturn line: remove the literal readonly argument from the wsRep picker.
2. pickArr() wsRep block: add a DirectReturn branch that derives candidate representatives from active vehicle Master Assignment / legacy driver and uses wsTo as the receiving-branch authorization context.
3. pickSelect() DirectReturn wsFrom block: resolve the representative from vehicleRepMap first, driver_id second; keep wsRepSearch editable.
4. pickSelect() wsRep block: for DirectReturn, resolve the representative's current primary vehicle and synchronize wsFrom to it, with receiving-branch authorization.
5. submit() DirectReturn rr element: prefer the selected wsRep / current Master Assignment and reject selected-rep vs vehicle mismatches.

Do not replace whole functions. Use the exact element replacements in Report358.

### PROTECTED / DO NOT REOPEN
- main.html
- van-sales.html
- DirectSale Draft Report357 repair
- Transfer destination/receiver contract
- Transfer source binding
- DirectReturn SEND authorization branch correction
- DirectReturn mobile-branch correction
- SupplierReturn contract
- existing stock writer / idempotency path
- prior Report349–357 closures

### DEPLOYMENT / E2E
- Production database contract: VERIFIED
- Production invalid/valid Create tests: VERIFIED
- Authenticated Update transaction test: VERIFIED
- Frontend source patch: READY only
- Frontend source write by assistant: NOT DONE
- Browser E2E: OPEN
- Served/published artifact identity: OPEN

Browser/served closure MUST NOT be claimed before owner merge + publish + actual interactive DirectReturn test.

### NEXT EXACT RESUMPTION
1. Re-fetch current Frontend HEAD and vouchers blob.
2. Apply only the five surgical elements from Report358.
3. Read vouchers.html completely after merge.
4. Parse all inline JS using a script detector that accepts script-tag attributes.
5. Test DirectReturn picker:
   - focus wsRep
   - type Arabic/name/email fragment
   - receive filtered rows
   - select rep
   - verify mapped vehicle
   - select destination branch
   - verify branch authorization
6. Create Draft and reopen it.
7. Submit through current create-stock-voucher path.
8. Re-check Production Master Assignment and stock-voucher custodian_user_id.
9. Publish and verify served artifact identity.
10. Run authenticated Browser E2E.
11. Only then close this closure unit and move to the next genuinely open Business Contract.

### CLOSURE RULE
Do not re-fix a closed historical unit.
Do not treat a report as current truth.
Use:
CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT EVIDENCE.

# CURRENT STATE — 2026-09-28 — Report357 DIRECTSALE DRAFT MODAL ACTIONS ROOT-CAUSE CHECKPOINT

## AUTHORITATIVE CURRENT REALITY

This section supersedes earlier CURRENT_STATE sections for this specific Warehouse Vouchers closure unit. Older sections remain historical records only.

### Current System Git
- Report357 commit: 5a854bc731dd28e8272b5e93a757116e8a17424b
- Parent: b99dc6f57ea43a3d19a23188da5377cb296745a6
- Report357: doc/Draft/Reprots/Report357_WAREHOUSE_VOUCHERS_DIRECTSALE_DRAFT_MODAL_ACTIONS_FORENSIC_CLOSURE_20260928.md
- The report records the proven root cause and the owner-only surgical source patch.

### Current Frontend Git
- HEAD: 8b6b32145aafdb49ae10af8f36aa888e4d25d412
- Parent: cd125b126cd40527a81f20508139506b8e48031f
- companies/company-1/warehouse/vouchers.html blob: bb0dd32e790fc55161a409e746f2ea778e44ae3b
- vouchers.html: 6327 lines / 208151 chars
- main.html blob: 810e4f5440f5975f55099a124deb42b086a49183 — protected / untouched
- van-sales.html blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e — protected / untouched

### What changed in current HEAD and what did not
- Commit 8b6 already contains Report356's loadList → inventory_voucher_report migration.
- Existing codeJs quoting correction is already present; do not repeat.
- Existing modal topActions already contains Draft Edit/Delete/Send/Print handlers.
- Existing printDraftVoucher() is valid; do not modify.
- The current defect is not in main.html, van-sales.html, details(), cards(), loadList(), or print functions.

### ROOT CAUSE — PROVEN
File: companies/company-1/warehouse/vouchers.html
Function: actionFor:function(v)
Target element: the second generic if(v.status==='Draft') block around line 608.

Current defect:
- Production inventory_voucher_report securely returns an authorized user's Draft in Pending.
- For non-privileged users it deliberately redacts created_by.
- Current pending row therefore has status=Draft and created_by=null.
- actionFor() relied on creator = currentUser.email == voucher.created_by.
- creator becomes false, privileged is false, actionFor returns ''.
- details() therefore does not enter act='draft' and the in-modal Draft toolbar is not rendered.

### Production proof
- Controlled DirectSale Draft fixture was created through the existing create_manual_stock_voucher_atomic path.
- Pending list returned the Draft.
- VOUCHER_AUDIT returned Header + Item detail under the existing employee redaction contract.
- Unrelated employee detail access was blocked centrally with: غير مصرح بالوصول إلى هذا الإذن.
- Therefore the backend authorization contract is working and the UI authorization-decision layer is the defect.

### OWNER SURGICAL SOURCE CHANGE — ONLY OPEN SOURCE ACTION
File:
companies/company-1/warehouse/vouchers.html

Function:
actionFor:function(v)

Around line:
608

Delete exactly this second generic Draft element:
    if(v.status==='Draft'){
        return(
            creator||
            privileged
        )?'draft':'';
    }

    if(v.status==='Sent'){

Replace it completely with:
    if(v.status==='Draft'){
        var draftListedForCurrentUser=
            s.tabName==='pending'&&
            Array.isArray(s.vouchers)&&
            s.vouchers.some(function(row){
                return(
                    row&&
                    row.status==='Draft'&&
                    String(row.voucher_code||'')===
                    String(v.voucher_code||'')
                );
            });

        return(
            creator||
            privileged||
            draftListedForCurrentUser
        )?'draft':'';
    }

    if(v.status==='Sent'){

No Frontend write was made by the assistant.

### Verification
- Current source inline JavaScript parse: PASS.
- In-memory patched source parse: PASS.
- Current source contains the defective target exactly once.
- Patched action simulation returns draft for the authorized Draft present in Pending.
- Unlisted Draft returns no draft action in the same simulation.
- Expected in-modal actions: Edit / Delete / Send / Print.
- codeJs repair remains present and was not repeated.

### Production / Database
No new Production schema change, RPC, Edge Function, or migration is required for this root cause.
Existing inventory_voucher_report and inventory_control contracts remain authoritative.
No new Edge Function was created.

### QA cleanup
Final Manual voucher counts after cleanup:
- Draft = 0
- Sent = 0
- Received = 1
- Completed = 5
- IN-8 detail residue = 0
- IN-8 inventory movement residue = 0
The QA operation identity tombstone remains protected by the existing integrity guard.

### E2E / Deployment
- RPC/database reproduction: PASS.
- Authorization denial test: PASS.
- In-memory UI fix simulation: PASS.
- Authenticated Browser E2E: OPEN / UNVERIFIED.
- Served/published artifact identity: OPEN / UNVERIFIED.
Do not call these Browser/served checks complete until the owner source is merged, published, and tested.

### Separate OPEN hardening
editVoucher() and printDraftVoucher() use direct company-scoped table SELECTs. This is not the root cause of the current missing buttons and is not changed in this session. A separate consumer/RLS audit is required before hardening this path.

### Protected / DO NOT REOPEN
- main.html
- van-sales.html
- closed transfer source/destination contract
- receiver binding
- partial/full receive backend
- DirectReturn contract
- SupplierReturn contract
- existing Edge/RPC path
- prior Report349–356 repairs

### NEXT EXACT RESUMPTION POINT
1. Verify Frontend HEAD and vouchers blob above.
2. Apply only the one owner replacement in actionFor() around line 608.
3. Read vouchers.html completely after merge.
4. Parse complete inline JavaScript.
5. Verify draftListedForCurrentUser appears once.
6. Verify Draft modal renders Edit/Delete/Send/Print.
7. Publish/deploy.
8. Verify served artifact identity.
9. Run authenticated Browser E2E.
10. Re-run Production scope/redaction assertions.
11. Close this unit only after runtime evidence; then move to the next real open Business Contract.
### STATUS
ROOT CAUSE: PROVEN
PRODUCTION CONTRACT: VERIFIED
PRODUCTION CHANGE: NOT REQUIRED
OWNER SOURCE PATCH: OPEN
BROWSER E2E: OPEN
DEPLOYMENT EVIDENCE: OPEN

---

# CURRENT STATE — 2026-09-28 — Report356 VOUCHERS SCOPE/MODAL PRODUCTION CLOSURE CHECKPOINT

## AUTHORITATIVE CURRENT CHECKPOINT
This section supersedes earlier CURRENT_STATE sections for the Warehouse Vouchers closure unit. Historical sections below remain records only.

### Current Git — System
- Pre-state HEAD verified: `21d4171b8f3efbbd5340198eb6a640ac9bbe55c8`
- Pre-state parent verified: `4b62e4b5f730186263daa63a0c7fa3dcbf60f77a`
- Report356 commit: `10ff4e0bc930a409a860b3722849621dcdf1ff72`
- CURRENT_STATE is being updated immediately after Report356.

### Current Git — Frontend
- Frontend HEAD: `cd125b126cd40527a81f20508139506b8e48031f`
- Frontend parent: `85e825de61333f3b7da014580dd7275146818b2a`
- `companies/company-1/warehouse/vouchers.html` blob: `4b99d7f12ab0fb255b523ae29465b7d3a9f56047`
- `vouchers.html`: 6,332 lines / 210,062 chars
- `main.html` blob: `810e4f5440f5975f55099a124deb42b086a49183`
- `van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

### Source Truth — What is CLOSED
- Current `cd125...` already contains the corrected single-quoted `codeJs` construction in `cards()` and `details()`.
- Do NOT repeat the `codeJs` repair.
- Do NOT touch `printVoucher()`; its current print-window implementation is valid and uses `.no-print`.
- Do NOT touch `main.html`.
- Do NOT touch `van-sales.html`.

### Source Truth — ONLY OWNER FRONTEND ACTION
File: `companies/company-1/warehouse/vouchers.html`

1. `loadList:function(scope)` around line 648:
   replace the current direct `supabase.from('stock_vouchers')...` function with the exact Report356 PATCH 1 using existing RPC `inventory_voucher_report` and payload `workflow_scope=pending|completed`.

---

# CURRENT STATE APPEND — 2026-09-30 — EXPERIMENTAL STOCK DATA CLEANUP (REPORT 380)

- This session executed the requested cleanup of experimental stock-voucher records.
- Deleted successfully: IN-1 DirectSale; IN-7 Transfer; IN-8 DirectSale; IN-9 DirectReturn; IN-3 SupplierReturn; IN-4 SupplierReturn.
- Remaining target records: IN-5 SupplierReturn (Completed) and QA-SR-UI-CONTRACT-20260927-01 (Completed).
- The remaining two records are protected from hard deletion by the current Production integrity path for executed/manual vouchers. No triggers were disabled and no replication-role bypass was used.
- Production branch stock totals observed after cleanup: BR-01 71/0; BR-2 10/0; VAN-CHV-2025-01 0/0; VAN-VHL-0422 0/0.
- Latest frontend repository remains papamohammed77-glitch/erp-frontend. Latest known commit is 503fb79da0878f97af46c8adad5bdedb0b3c283f with parent 1b89202949575eaebed4c5bf5512322129a114fb. The latest Van Sales source already contains the showRecentCustomers auth_id fix; no duplicate patch was applied.
- System repo latest commit after this report is 58c64ad0ff2d33e80903000bda07bc4a02f07a65.
- Report: doc/Draft/Reprots/Report380_EXPERIMENTAL_DATA_CLEANUP_20260930.md
- Frontend deployment/browser E2E remains Owner-side verification and was not altered in this cleanup session.

---
# CURRENT STATE APPEND — 2026-09-30 — REPORT 381 / SUPPLIERRETURN CLEANUP + VAN SALES FORENSIC
- Executed Production cleanup of the two remaining experimental Completed SupplierReturn vouchers: IN-5 and QA-SR-UI-CONTRACT-20260927-01.
- Verified afterward: SupplierReturn records 0; targeted voucher records 0; targeted details 0; related inventory_log 0; related journal_entries 0; related finance_tax_transactions 0; related ERP operation registry matches 0.
- Verified 14 audit_log rows remain for the deleted test voucher identities.
- Temporary corrective deletion helper was retired and normal voucher/detail deletion guards were restored. No trigger disabling or replication-role bypass was used.
- Canonical post-cleanup migration record added: supabase/migrations/20260930_supplier_return_cleanup_final_baseline.sql
- Final report added: doc/Draft/Reprots/Report381_SUPPLIER_RETURN_CLEANUP_AND_VAN_SALES_EXECUTION_20260930.md
- Current Van Sales source verified at blob b754208f38a52b67794e9d02003ed8751f3a7c68, 3294 lines.
- Latest frontend commit: 503fb79da0878f97af46c8adad5bdedb0b3c283f; parent 1b89202949575eaebed4c5bf5512322129a114fb.
- Current Van Sales source contains the auth_id correction in showRecentCustomers and company-scoped syncDown. No new frontend defect was proven in this session; no frontend source was changed.
- Production setup-van-branch v5 resolves the authenticated user through public.users.auth_id and company_id, then resolves the vehicle/VAN branch inside that company.
- Production current relevant Edge versions observed in this session include save-sales-invoice v15, save-receipt-voucher v8, save-inventory-count v5, save-daily-settlement v4, start-picking v34, complete-picking v17, start-loading v5, complete-loading v11, reopen-loading v2, unload-runsheet v6, complete-return v26, complete-order-delivery v14, bulk-stock-adjustment v8, send-stock-voucher v7, receive-stock-voucher v5, receive-purchase v9.
- Physical stock UPDATE scan currently identifies post_stock_movement as the physical stock writer; reserve_stock/release_stock_reservation remain reservation writers.
- Van Sales browser-rendered E2E remains Owner-side open.

---
# CURRENT STATE APPEND — 2026-10-01 — REPORT 382 / DIRECTRETURN + REPRESENTATIVE COLUMN FORENSIC CLOSURE

## Current Git baseline used in this session
- System repository: papamohammed77-glitch/rawaie-erp-New
- main HEAD at session start: 8a175b78f09e382e7630efd09c6d97a7385e1876
- Parent: b0cab4f2f63b957c449c537a445e755593712bdb
- Current mother source: Current/PWA/main.html
- Current mother source SHA: 27b777528665dcc985809648f006452c861ae36e
- Mother source was NOT modified by this session; owner-side surgical patch is recorded in Report382.
- Frontend repository: papamohammed77-glitch/erp-frontend
- Current frontend HEAD: 503fb79da0878f97af46c8adad5bdedb0b3c283f
- Frontend parent: 1b89202949575eaebed4c5bf5512322129a114fb
- Current vouchers.html blob: 85e709d0f41c189c6624a6160965d3b1a41960ba

## Report 382 — DirectSale / DirectReturn Representative Projection
- Production/current-source forensic review proved that the authoritative representative identity for DirectSale and DirectReturn is stock_vouchers.custodian_user_id -> public.users.id.
- The embedded voucher table in Current/PWA/main.html currently lacks the representative column and does not resolve custodian_user_id to a representative name.
- The normal parent navigation delegates vouchers to ./vouchers.html; the standalone current vouchers.html already has representative lookup/custody context. The requested main.html change is therefore a compatibility/read-model patch, not a new operational workflow.
- Owner-side main.html patch is exactly four surgical substitutions. No function is to be replaced wholesale. See Report382 for exact search strings and replacements.

## Production defect discovered and fixed during current-state verification
- Current Production exposed a real DirectReturn RECEIVE defect that was not safe to consider closed from historical reports.
- post_manual_stock_voucher_atomic_core_20260828 previously mapped DirectReturn RECEIVE to movement_type='DirectReturn' while setting src=NULL.
- The central post_stock_movement contract requires a real source for movement_type='DirectReturn', and DirectReturn SEND had already removed the quantity from the vehicle mobile stock. A second decrement was therefore both impossible and semantically incorrect.
- Production canonical fix: DirectReturn RECEIVE now maps to movement_type='InventoryIncrease'. This adds the returned quantity to the destination branch without attempting a second vehicle deduction.
- No new Edge Function was created. Existing authenticated Edge/RPC path remains unchanged.
- Canonical migration added:
  supabase/migrations/20261001090000_fix_directreturn_receive_stock_direction_contract.sql
- Migration commit: 6ae450aa42bc2d6cf4bcc30879e96365dbdde4c7

## Production E2E evidence
A transactional rollback test used existing Production master data:
- Company: 00000000-0000-0000-0000-000000000001
- Branch BR-01: a38332b6-6cea-480a-ada1-6eb6ab0590db
- Vehicle CHV-2025-01: 69b08188-60ee-43af-9644-e1626a85bfa0
- Vehicle mobile branch: 2fffcf58-be04-4599-a289-8791362398ff
- Direct-sale representative: 111b0730-a977-4d11-bcd0-2427b178a9e5 / vansales@rawaea.com
- Item 1001: 7cf845d8-34b9-47d1-9b7f-d9f1f597dbf8
- Initial BR-01 stock: 8, allocated 0.

Observed:
- DirectSale CREATE -> Draft with custodian_user_id = representative.
- DirectSale SEND -> Sent; BR-01 8->7; mobile stock 0->1; custody debit 50.
- DirectReturn CREATE -> Draft with same custodian_user_id.
- DirectReturn SEND -> Sent; mobile stock 1->0; branch remains 7.
- DirectReturn RECEIVE -> Received; branch 7->8; mobile remains 0; custody credit 50.
- Repeated RECEIVE with same operation_id returned duplicate=true with no additional movement.
- Inventory log contained the expected three movement records for the two-stage cycle.
- driver_ledger rows 0->2 and balance returned 0 after debit 50 + credit 50.
- General journal remained unchanged: 10 entries and 16 lines before and after the test.
- The test deliberately raised an exception after collecting results so all QA data rolled back. Post-test Production checks showed zero QA voucher rows and BR-01 item 1001 back at qty 8 / allocated 0.

## Browser evidence boundary
- The existing erp-frontend warehouse-vouchers Playwright workflow remains the correct rendered browser gate.
- No workflow dispatch capability was available in this session; therefore browser-rendered E2E is NOT marked as PASS.
- Source-level syntax and representative mapping checks passed for the surgical patch.
- After the owner applies the main.html patch and deploys, rendered browser verification is the remaining owner-side gate.

## Files/areas intentionally not modified
- Current/PWA/main.html
- companies/company-1/warehouse/vouchers.html
- inventory_voucher_report()
- post_stock_movement()
- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher
- navigation/permission contracts
- stock_vouchers schema
- vehicle/representative assignment schema

## Canonical continuity rule
Historical reports are advisory only. The current baseline is:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
Do not re-apply a historical repair merely because a report describes it. Re-verify the current contract first.

## Current source of truth for next session
1. Read this append and Report382.
2. Re-verify post_manual_stock_voucher_atomic_core_20260828 contains DirectReturn -> InventoryIncrease for RECEIVE.
3. Do not touch that RPC again unless current Production contradicts this state.
4. Apply only the four main.html surgical substitutions recorded in Report382.
5. Validate main.html source syntax and representative mapping.
6. Deploy the changed main.html.
7. Run the existing warehouse-vouchers browser E2E workflow.
8. Verify DirectSale and DirectReturn rows display the representative name.
9. Verify non-rep voucher types remain '-'.
10. Verify refresh/reload and empty-state behavior.
11. Do not alter the operational stock workflow in response to a display-only change.

## Report
- doc/Draft/Reprots/Report382_WAREHOUSE_VOUCHERS_DIRECTRETURN_REP_COLUMN_FORENSIC_CLOSURE_20261001.md


---
# CURRENT STATE APPEND — 2026-10-01 — REPORT 383 / MOTHER VOUCHERS REPRESENTATIVE COLUMN

## Current authoritative baseline
- System HEAD before this report: `59fd766167bbdb3b9bd9af3d305da7b0eb52da64`
- Parent: `0be2f6f54e4748e231cc62a6a1943e93257f6a14`
- Mother source: `Current/PWA/main.html`
- Mother source blob: `27b777528665dcc985809648f006452c861ae36e`
- Mother source was NOT modified by the assistant.
- Latest report created: `doc/Draft/Reprots/Report383_WAREHOUSE_VOUCHERS_REPRESENTATIVE_COLUMN_FORENSIC_SURGICAL_PACKAGE_20261001.md`
- Report commit: `aabbb396dacefffc537711c5978594214668e663`

## Proven defect
The embedded Warehouse Vouchers read-model in main.html loaded only `stock_vouchers` and rendered columns through `from` / `to` / `actions`.
It did not project `stock_vouchers.custodian_user_id` to a representative name.
The operational application remains delegated to `./vouchers.html`; this is a mother read-model projection gap, not a new workflow.

## Exact owner surgical patch
Four replacements are required and documented in Report383:
1. `loadVouchers()` around line 2925 — load company-scoped active Direct Sales Representatives and build `window._vouchersRepMap`; project `custodian_user_id` to `_custodian_name`.
2. `loadVouchers()` around line 2924 — add the `المندوب` table header and change loading colspan 8→9.
3. `_applyVouchers()` around line 2930 — change empty-state colspan 8→9.
4. `_applyVouchers()` row projection — insert `_custodian_name` before the actions cell.

Do not replace either function wholesale.

## Source validation
- All four current anchors were found exactly once.
- Patched in-memory source parsed successfully.
- One inline script detected; parse errors = 0.
- Semantic projection test:
  - DirectSale → current Production rep name = PASS.
  - DirectReturn → current Production rep name = PASS.
  - Transfer → `-` = PASS.
  - SupplierReturn → `-` = PASS.
- The real current source blob remains unchanged because main.html is owner-editable only.

## Production verification
- Supabase project `SMART ERP` / `fiilmooggumokxanwiyx` = ACTIVE_HEALTHY.
- `stock_vouchers.custodian_user_id` has FK `stock_vouchers_custodian_user_fk` → `users.id`.
- Current active Direct Sales Representatives were verified in Production.
- Current Master Assignment examples remain:
  - CHV-2025-01 → vansales@rawaea.com
  - VHL-0422 → vansales2@rawaea.com
- `vehicles.driver_id` remains NULL for these current assignments and is not used by the mother projection.
- Current DirectReturn core still contains `WHEN 'DirectReturn' THEN 'InventoryIncrease'`.
- No Production change was required for this display-only capability.

## E2E / deployment boundary
- Existing transactional Production E2E from Report382 remains the latest live proof of DirectSale → DirectReturn → Receive stock/custody/accounting invariants.
- Current Production core was re-read and matches that tested contract.
- A fresh compound production mutation E2E was attempted but execution safety rejected the mutation request before execution; no test data or partial residue was created.
- Browser-rendered E2E for main.html remains OPEN because the owner has not yet applied/published the four source substitutions.

## Do not reopen
- DirectReturn Receive direction fix.
- Master Assignment backend contract.
- Owner wildcard / owner identity.
- Main delegation to `vouchers.html`.
- Existing stock/accounting core.

## Next exact resumption point
1. Owner applies only Report383 PATCH 1→4 to `Current/PWA/main.html`.
2. Run complete inline-JS Syntax Gate.
3. Publish the new mother artifact.
4. Verify served artifact identity.
5. Run rendered Browser E2E.
6. Verify DirectSale and DirectReturn show the representative name from `custodian_user_id`.
7. Verify Transfer and SupplierReturn remain `-`.
8. Verify refresh and empty-state rendering.
9. Do not modify operational voucher workflow in response to this display-only closure.
10. Close the UI projection contract only after rendered production evidence.

## Status
- ROOT CAUSE: PROVEN
- PRODUCTION CONTRACT: VERIFIED
- SOURCE PATCH: READY FOR OWNER
- STATIC SYNTAX: PASS
- SEMANTIC MAPPING: PASS
- PRODUCTION MUTATION E2E THIS CYCLE: NOT EXECUTED (safety gate)
- BROWSER E2E: OPEN
- DEPLOYMENT EVIDENCE: OPEN


---
# CURRENT STATE APPEND — 2026-10-01 — REPORT 384 / CORRECT FRONTEND TARGET + REPRESENTATIVE COLUMN

## Authoritative target correction
- The previously recorded surgical package targeted `rawaie-erp-New/Current/PWA/main.html`.
- The actual owner-requested mother source is `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`.
- Current frontend source blob: `810e4f5440f5975f55099a124deb42b086a49183`.
- Current source size: 1,754,145 chars / 32,316 lines.
- The previous Report382/383 anchors do NOT exist in this actual target because their formatting/path belonged to a different source artifact.

## Proven current defect
- `async function loadVouchers()` begins around line 14858.
- The current voucher list reads `stock_vouchers` but never projects `custodian_user_id`.
- `function _applyVouchers()` begins around line 14884.
- Current table has 8 columns; no representative column.
- Current row projection ends with `to_id` followed directly by actions.
- Current source contains zero occurrences of `custodian_user_id` and zero occurrences of `_vouchersRepMap`.

## Exact owner surgical patch
Report384 defines four exact substitutions against the CURRENT frontend source only:
1. `loadVouchers()` around line 14879 — replace the 3-line `stock_vouchers` load tail with company-scoped voucher loading, distinct `custodian_user_id` extraction, company-scoped `users` lookup, and `_custodian_name` projection.
2. `loadVouchers()` around line 14874 — add `المندوب` header and change loading colspan 8→9.
3. `_applyVouchers()` around line 14902 — change empty-state colspan 8→9.
4. `_applyVouchers()` around line 14910 — add escaped `_custodian_name` before actions.

Do not replace either function wholesale.

## Production evidence
- Supabase project `SMART ERP` / `fiilmooggumokxanwiyx` = ACTIVE_HEALTHY.
- `stock_vouchers.custodian_user_id` is UUID and FK `stock_vouchers_custodian_user_fk` → `public.users.id`.
- Current company has three Active Direct Sales Representatives, each with `permissions=[\"van-sales\"]`.
- RLS includes company-scoped `stock_vouchers` SELECT and direct-rep warehouse read policy.
- Current Production has zero DirectSale/DirectReturn voucher rows after prior QA cleanup. No production fixture was created in this display-only cycle.
- Current DirectReturn RECEIVE core remains `WHEN 'DirectReturn' THEN 'InventoryIncrease'`; no backend change required.

## Historical integration evidence
- `companies/company-1/warehouse/vouchers.html` already had custodian projection in commit `5801db5d15673c49e88ccfc69e84f0a53cd8866d`.
- Therefore the mother correction is a read-model parity fix, not a new workflow or ownership model.

## Validation
- All four current anchors matched exactly once.
- Patched in-memory source: one inline JS script; complete parse PASS.
- Semantic fixture:
  - DirectSale → representative name PASS.
  - DirectReturn → representative name PASS.
  - Transfer → `-` PASS.
  - SupplierReturn → `-` PASS.
- Current source file was not modified by the assistant.
- Production schema/RPC/Edge Functions were not changed.

## E2E / deployment boundary
- Existing Production transactional E2E from Report382 remains the latest verified proof of DirectSale → DirectReturn → Receive stock/custody/accounting invariants.
- Fresh browser-rendered E2E for this corrected target is still OPEN until the owner applies the four patches and publishes the frontend artifact.
- Served artifact identity is OPEN.
- No claim of rendered production PASS has been made.

## Protected / DO NOT REOPEN
- DirectReturn RECEIVE direction fix.
- Owner wildcard / owner identity.
- Main delegation to `vouchers.html`.
- Existing stock/accounting workflow.
- `vouchers.html` historical custodian implementation.

## Next exact resumption point
1. Open `erp-frontend/companies/company-1/main.html`.
2. Apply Report384 PATCH 1→4 only.
3. Run complete inline-JS Syntax Gate.
4. Publish frontend.
5. Verify served blob/artifact identity.
6. Run authenticated Browser E2E.
7. Verify DirectSale and DirectReturn representative names.
8. Verify Transfer/SupplierReturn remain `-`.
9. Verify refresh and empty state.
10. Close only after runtime/deployment evidence.

## Status
- ROOT CAUSE: PROVEN
- CORRECT TARGET SOURCE: PROVEN
- OWNER SURGICAL PATCH: READY
- STATIC SYNTAX: PASS
- SEMANTIC MAPPING: PASS
- PRODUCTION CHANGE: NOT REQUIRED
- BROWSER E2E: OPEN
- DEPLOYMENT EVIDENCE: OPEN

## Report
- `doc/Draft/Reprots/Report384_WAREHOUSE_VOUCHERS_REPRESENTATIVE_COLUMN_CORRECT_TARGET_SURGICAL_FIX_20261001.md`


---

# CURRENT STATE APPEND — 2026-10-01 — REPORT 385 / CURRENT HEAD REPRESENTATIVE COLUMN RECONCILIATION

## Authoritative checkpoint

هذه الإضافة تتجاوز أي assertions أقدم تخص مصدر عمود المندوب في Mother UI عندما تتعارض مع Current Git.

### Current Git — Frontend

- Repository: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- Current HEAD: `d5b8319b81c2236da66c25dcfc32a8f18182f249`
- HEAD parent: `5edf6d448203b8b431086ae762df1b35699366bf`
- Parent of the voucher-column change: `503fb79da0878f97af46c8adad5bdedb0b3c283f`
- Current `companies/company-1/main.html` blob: `4fc2adb99861031cc69decb215daac6f74d58c66`
- Current source: 32,347 lines / 1,755,708 chars

## Current Source truth

The requested representative column is already present in Current Source:

- `loadVouchers()` ≈ line 14858
- table header contains `المندوب`
- loading/empty states use colspan 9
- `custodian_user_id` is collected for DirectSale/DirectReturn
- company-scoped `users` lookup resolves representative names
- `_custodian_name` is projected
- row renders escaped representative name

The four surgical substitutions documented in Report384 are therefore already present in Current Git and must NOT be repeated against the current blob.

## Historical root cause

The original defect existed in the pre-change parent and was removed by commit `5edf6d448203b8b431086ae762df1b35699366bf` with message:

`Update voucher table to include custodian column`

That commit modified only the required voucher-list projection/header/empty-state/row output in `main.html`.

## Current syntax

Full inline JavaScript compilation of Current `main.html` = PASS.

## Current Production

Supabase project `fiilmooggumokxanwiyx`:

- DirectSale vouchers = 0
- DirectReturn vouchers = 0
- Total `stock_vouchers` = 0
- Current active Direct Sales Representatives were verified in `public.users`
- Owner wildcard remains `permissions=["*"]`

## Production infrastructure

No schema, RLS, RPC, Edge Function, stock, custody, or accounting change was required for this read-only defect.

## Database fixture

A read-only SQL fixture was executed against real Production representative records:

- DirectSale → representative name resolved
- DirectReturn → representative name resolved
- Transfer → `-`
- SupplierReturn → `-`

No permanent Production rows were inserted.

## Browser / deployment evidence

GitHub Actions run `36907835220` was triggered by commit `5edf6d...`.

It failed before Playwright because the workflow's unrelated RW_HR payroll assertion failed:

`AssertionError: Canonical RW_HR payroll syntax not present`

Therefore:

- Browser E2E for this voucher UI unit = OPEN
- Served Production artifact identity = OPEN

Do not repair the unrelated HR assertion as part of this voucher unit.

## Protected closed contracts

Do not reopen:

- DirectReturn Receive direction
- Master Assignment
- `custodian_user_id` operational contract
- voucher stock mutation workflow
- accounting/custody workflow
- owner wildcard

## Exact next resumption point

1. Verify served artifact contains blob `4fc2adb99861031cc69decb215daac6f74d58c66`.
2. If local source differs, compare it to Current HEAD before editing.
3. If it is older than Current HEAD, apply only Report385 PATCH 1→4.
4. Run source syntax gate.
5. Publish/deploy.
6. Verify served artifact.
7. Run rendered Browser E2E.
8. Verify DirectSale and DirectReturn representative names.
9. Verify Transfer and SupplierReturn remain `-`.
10. Close this UI unit only after runtime evidence.

## Report

- `doc/Draft/Reprots/Report385_WAREHOUSE_VOUCHERS_REPRESENTATIVE_CURRENT_HEAD_FORENSIC_CLOSURE_20261001.md`
- Report commit: `a61a5259dddbd44f2fd51cba88fecdbb44836ab4`

## Status

- ROOT CAUSE: CLOSED
- CURRENT SOURCE PATCH: PRESENT
- STATIC SYNTAX: PASS
- SEMANTIC MAPPING: PASS
- PRODUCTION CHANGE: NONE REQUIRED
- DATABASE FIXTURE: PASS / NO RESIDUE
- BROWSER E2E: OPEN
- SERVED ARTIFACT: OPEN


---
# CURRENT STATE APPEND — 2026-10-01 — REPORT386 / MOTHER MAIN VOUCHER HEADER CORRUPTION

## Authoritative current baseline
- Frontend repository: papamohammed77-glitch/erp-frontend
- Branch: main
- Current frontend HEAD: e2e9d5cdb559bd014dcc85b12fc9b89610b466d7
- HEAD parent: e373c7ad2d66d72b2919a8f153693da36ab9b7bb
- Current target: companies/company-1/main.html
- Current target blob: 2a4b0bec5a402b1e7490a8e53b3452cc8a7d9209
- Current source size: 1,756,290 chars / 32,348 lines

## Fresh forensic finding
The representative-column implementation from commit 5edf6d448203b8b431086ae762df1b35699366bf is still present in Current Source and must not be reimplemented.

A later commit introduced a new defect:
- Commit: e373c7ad2d66d72b2919a8f153693da36ab9b7bb
- Parent: d5b8319b81c2236da66c25dcfc32a8f18182f249
- File changed: companies/company-1/main.html only
- Defect: line 5 was changed from the valid charset element into a charset element immediately followed by the entire voucher row renderer:
  `<meta charset="UTF-8">return '<tr ... _custodian_name ... </tr>';`
- e2e9d5cdb559bd014dcc85b12fc9b89610b466d7 changed only `_forensic_current_main_extract.md`, so the malformed main.html remains current.

## Exact owner surgery
File: companies/company-1/main.html
Element: line 5
Action: delete the entire corrupted line and replace it with exactly:
```html
  <meta charset="UTF-8">
```

Do NOT reapply Reports 384/385 four-patch representative package when the current file is this HEAD, because the representative header, company-scoped lookup, `custodian_user_id` projection, and escaped row rendering are already present in the current source.

## Source contract verified
- `loadVouchers()` occurs once.
- `_applyVouchers()` occurs once.
- `<th class="p-3">المندوب</th>` is present.
- `custodian_user_id` is present in the voucher projection path.
- `v._custodian_name` is present in the correct row renderer.
- Current source contains two occurrences of the row-renderer prefix only because one is misplaced on line 5 and one is correctly inside `_applyVouchers()`.
- After the owner patch, the misplaced occurrence must be zero while the correct occurrence remains one.

## Production current verification
Supabase project: fiilmooggumokxanwiyx
- total stock_vouchers = 0
- DirectSale vouchers = 0
- DirectReturn vouchers = 0
- active direct-sales representatives = 3
- representative identity contract: stock_vouchers.custodian_user_id -> public.users.id
- read-only fixture projection:
  - DirectSale -> representative name: PASS
  - DirectReturn -> representative name: PASS
  - Transfer -> -: PASS
  - SupplierReturn -> -: PASS
- No persistent QA data created.
- No cleanup mutation required.

## Production changes
None required for Report386.
- No Edge Function
- No RPC
- No table/schema change
- No RLS change
- No stock change
- No custody change
- No accounting change

The existing DirectReturn RECEIVE production contract remains protected and must not be reopened:
`DirectReturn RECEIVE -> InventoryIncrease`.

## Browser / deployment boundary
- Browser-rendered E2E after the owner-side main.html correction is OPEN.
- Served artifact identity is OPEN.
- No Browser PASS may be claimed before publish + served-artifact verification + rendered test.
- Workflow-dispatch capability was not available in this session.

## Owner change package
The sole current owner change is the line-5 header repair documented in:
`doc/Draft/Reprots/Report386_MOTHER_MAIN_VOUCHER_COLUMN_CORRUPTION_FORENSIC_SURGICAL_FIX_20261001.md`

## Protected contracts — do not reopen
- DirectReturn receive direction
- Master Assignment / representative identity
- custodian_user_id operational contract
- voucher stock mutation workflow
- owner wildcard `permissions=["*"]`
- existing operational `warehouse/vouchers.html`
- existing representative-column implementation in `main.html` below the header

## Next exact resumption point
1. Open `companies/company-1/main.html`.
2. Verify Current blob against `2a4b0bec5a402b1e7490a8e53b3452cc8a7d9209`.
3. Find line 5 containing `<meta charset="UTF-8">return '<tr ...`.
4. Delete that corrupted line completely.
5. Replace with `<meta charset="UTF-8">` only.
6. Run full source/inline-JS validation.
7. Verify the representative row renderer remains only inside `_applyVouchers()`.
8. Publish.
9. Verify served artifact.
10. Run rendered Browser E2E for DirectSale / DirectReturn representative display.
11. Close UI unit only after runtime proof.

## Report
- Report386: doc/Draft/Reprots/Report386_MOTHER_MAIN_VOUCHER_COLUMN_CORRUPTION_FORENSIC_SURGICAL_FIX_20261001.md
- Report commit: 06aa932f80594b1a5ae27caa3ff0fae7b04022ae


---
# CURRENT STATE APPEND — 2026-10-01 — REPORT 387 / MOTHER MAIN DIRECTSALE DIRECTRETURN REPRESENTATIVE CURRENT HEAD CLOSURE

## Authoritative checkpoint

هذه الإضافة تتجاوز أي حالة أقدم تتعارض مع Current Git أو Current Source.

### Current Git — Frontend

- Repository: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- Current HEAD: `bc4d7a02919dcaf82d11bb599e879281cd550737`
- HEAD parent: `80b5dc00da7aae08d442acef4beb6857681de481`
- Previous corrupted state commit: `e373c7ad2d66d72b2919a8f153693da36ab9b7bb`
- Current `companies/company-1/main.html` blob: `6cb0ac47e8b3c8459ac5672d6fc3b0ec4bf9eaa3`
- Current `main.html`: 32,348 lines / 1,755,711 chars

## Current Source truth

The requested business capability is already present in Current Source:

- `loadVouchers()` occurs once around line 14859.
- Table header contains `المندوب`.
- Loading/empty states use colspan 9.
- DirectSale and DirectReturn collect `custodian_user_id`.
- Company-scoped `users` lookup resolves representative name.
- `v._custodian_name` is projected only for DirectSale/DirectReturn.
- Row renderer escapes and displays the representative before actions.
- `_applyVouchers()` occurs once around line 14916.

### Static source gate

- Inline scripts: 1
- V8 compilation of the inline script: PASS
- Corrupted meta/row-renderer pattern in head: NOT PRESENT
- `loadVouchers()`: 1
- `_applyVouchers()`: 1

## Git forensic chain

Commit `e373c7ad...` introduced the historical line-5 corruption by attaching the voucher row renderer to the charset meta element.

Commit `80b5dc00...` fixed that corruption exactly, changing the malformed line back to:
`    <meta charset="UTF-8">`

Compare `e2e9d5c... → 80b5dc0...` shows exactly one commit and a one-line main.html repair.

Commit `bc4d7a...` is documentation-only for `_forensic_current_main_extract.md`; it does not alter `main.html`.

Therefore **no owner-side main.html surgery is required on Current HEAD**.

## Historical owner fallback

Only if a local/served copy is proven to contain the old corrupted line, delete that exact corrupted line and replace it with:
```html
  <meta charset="UTF-8">
```

Do not reapply Report384/385 four-patch representative changes or Report386 line-5 repair to Current HEAD.

## Current Production

Supabase project: `SMART ERP / fiilmooggumokxanwiyx`

Verified:
- total `stock_vouchers` = 0
- DirectSale = 0
- DirectReturn = 0
- Active Direct Sales Representatives = 3
- `stock_vouchers.custodian_user_id` is UUID and FK to `public.users.id`
- DirectSale/DirectReturn custodian trigger contract is active.

## Fresh Production transactional E2E

Executed inside `BEGIN ... ROLLBACK` using the real company, BR-01, CHV-2025-01, item 1001, representative `vansales@rawaea.com`, and warehouse actor `vouchers@rawaea.com`.

Results:
- DirectSale CREATE: PASS; custodian and representative projection correct.
- DirectReturn CREATE: PASS; custodian and representative projection correct.
- DirectSale SEND: PASS; branch 8→7, vehicle 0→1, custody debit 50.
- DirectReturn SEND: PASS; vehicle 1→0.
- DirectReturn RECEIVE: PASS; branch 7→8, custody credit 50.
- Duplicate RECEIVE with same operation_id: PASS; duplicate=true and no second movement.
- During transaction: driver_ledger debit 50, credit 50, net 0.
- journal_entries remained 10 and journal_lines remained 16.

After rollback:
- stock_vouchers = 0
- DirectSale = 0
- DirectReturn = 0
- QA operation rows = 0
- QA test inventory residual = 0
- branch item 1001 qty = 8
- vehicle item 1001 qty = 0
- QA driver-ledger net = 0

No test residue remains.

## Test issue resolved

The first E2E attempt used `owner@alrawae.com` as the DirectSale creation actor and was rejected by the existing operational actor contract. This was a test-actor mismatch, not a source defect. The test was rerun with the authorized warehouse voucher actor and passed completely.

## Production changes

For Report387:
- Edge Function: NONE
- New RPC: NONE
- Existing RPC modification: NONE
- Schema change: NONE
- RLS change: NONE
- Data repair: NONE
- Accounting repair: NONE

Existing DirectReturn RECEIVE contract remains protected:
`DirectReturn RECEIVE → InventoryIncrease`.

## Deployment / Browser boundary

The current source is verified, but this session has not established a fresh served-artifact hash or rendered browser E2E against the deployed current `main.html`.

Therefore:
- Browser-rendered E2E = OPEN
- Served artifact identity = OPEN

Do not claim browser/runtime PASS until deployment evidence exists.

## Protected closed contracts — DO NOT REOPEN

- DirectReturn RECEIVE direction
- custodian_user_id operational contract
- Master Assignment / representative identity
- existing voucher stock workflow
- existing custody/accounting workflow
- owner wildcard `permissions=["*"]`
- existing operational `warehouse/vouchers.html`
- current representative implementation in Mother `main.html`

## Next exact resumption point

1. Verify the served/deployed artifact corresponds to Current Git HEAD content/blob.
2. Run authenticated browser-rendered E2E for the voucher table.
3. Filter DirectSale and verify representative display.
4. Filter DirectReturn and verify representative display.
5. Verify Transfer and SupplierReturn display `-`.
6. Verify refresh, empty state, and no lookup loss.
7. Close Browser/Deployment evidence only after runtime proof.
8. Do not modify `main.html` unless Current Source or served artifact proves a real mismatch.

## Report

- Report387: `doc/Draft/Reprots/Report387_MOTHER_MAIN_DIRECTSALE_DIRECTRETURN_REPRESENTATIVE_CURRENT_HEAD_FORENSIC_CLOSURE_20261001.md`
- Report commit: `cf1ec5e4b0ee0f3dd83dc0c19e8a9c91c982eddd`

## Status

- ROOT CAUSE OF HISTORICAL HEADER CORRUPTION: CLOSED
- REQUESTED REPRESENTATIVE COLUMN IN CURRENT SOURCE: CLOSED
- STATIC SYNTAX: PASS
- PRODUCTION CONTRACT: PASS
- PRODUCTION TRANSACTIONAL E2E: PASS
- DATA CLEANUP: PASS
- ACCOUNTING INVARIANCE: PASS
- OWNER SURGERY ON CURRENT HEAD: NONE REQUIRED
- BROWSER E2E: OPEN
- SERVED ARTIFACT: OPEN

---

## Report388 — DirectSale / DirectReturn Representative Column Forensic Closure — 2026-10-01

### Current Truth
- CURRENT Git of Mother: `papamohammed77-glitch/erp-frontend`
- HEAD: `bc4d7a02919dcaf82d11bb599e879281cd550737`
- Parent: `80b5dc00da7aae08d442acef4beb6857681de481`
- Current main.html blob: `6cb0ac47e8b3c8459ac5672d6fc3b0ec4bf9eaa3`
- Historical line-5 corruption remains CLOSED and was not re-applied.

### Root Cause Closed
The separate DirectSale / DirectReturn history table is rendered by `async function _renderVoucherHistory(type)` around line 14432. Its 10-column table omitted the representative, and the previous Production `inventory_voucher_report(LIST)` projection omitted `custodian_user_id` and `custodian_name`. The global `loadVouchers()` table already had the representative column and was not changed.

### Production Change
Existing RPC only:
`direct_voucher_report_representative_projection_20261001`
- Added `custodian_user_id` to LIST projection.
- Added company-scoped `custodian_name` projection for DirectSale / DirectReturn.
- No new Edge Function.
- No schema change.
- No RLS change.
- No workflow or accounting writer change.

### Source Surgery Pending User Application
Three exact replacements are required in `_renderVoucherHistory(type)`:
1. Add `<td class="p-3">'+esc(r.custodian_name||'—')+'</td>` between `to_label` and `created_by`.
2. Change the empty-state `colspan` from 10 to 11.
3. Add `<th>المندوب</th>` between `إلى` and `المنشئ`.
Complete exact replacements are documented in Report388.

### Production E2E
Transactional E2E passed using the authorized warehouse voucher actor, BR-01, vehicle CHV-2025-01, item 1001, representative vansales@rawaea.com:
- DirectSale CREATE/SEND PASS; branch stock 8→7, vehicle stock 0→1, custody debit 50.
- DirectReturn CREATE/SEND/RECEIVE PASS; vehicle stock 1→0, branch stock 7→8, custody credit 50.
- Report RPC returned representative identity/name for both voucher types.
- Driver ledger full-cycle net = 0.
- journal_entries stayed at 10.
- Movement/audit evidence present during transaction.
- All test work rolled back.

### Cleanup Verification
After rollback:
- QA vouchers = 0
- QA details = 0
- QA operation rows = 0
- QA inventory logs = 0
- QA audit rows = 0
- BR-01 item 1001 qty = 8
- Vehicle item 1001 qty = 0
- QA driver-ledger net = 0
- No test residue remains.

### Runtime Boundary
- Production backend contract: CLOSED.
- Source patch: READY / user-side application pending.
- Browser-rendered E2E: OPEN.
- Served artifact identity: OPEN.
Do not claim UI runtime PASS until the 3 source replacements are applied, deployed, and verified in browser.

### Protected Contracts
Do not reopen:
- DirectReturn RECEIVE → InventoryIncrease
- `custodian_user_id` identity contract
- vehicle/representative assignment contract
- existing voucher stock lifecycle
- existing custody/accounting workflow
- owner wildcard `permissions=["*"]`
- existing Global Voucher Table representative projection
- historical line-5 repair.

### Next Exact Resumption Point
1. Verify the 3 Report388 source replacements in Current Git.
2. Run inline-script syntax validation.
3. Deploy.
4. Authenticated browser test DirectSale and DirectReturn.
5. Verify representative column/value, empty state colspan=11, refresh, and filtering.
6. Verify Transfer/SupplierReturn do not invent a representative.
7. Compare served artifact with Current Git.

### Report388 documentation correction — 2026-10-01
- تم تدقيق نص Report388 مرة إضافية مقابل Current Mother `main.html` blob `6cb0ac47e8b3c8459ac5672d6fc3b0ec4bf9eaa3`.
- تم تصحيح الـsource anchors في التقرير لتطابق النص الحالي حرفيًا، بما في ذلك `colspan="10"` → `colspan="11"` والنص الفعلي لحالة الفراغ، ورأس الجدول الكامل بخصائص CSS الحالية.
- آخر Commit لتقرير Report388: `934ea0ea8e6b39900ab698e5d1290dd2be49e5b4`.
- لا يوجد أي تغيير إضافي على `main.html` من جانب المساعد.

# CURRENT FORENSIC CHECKPOINT — 2026-10-08 — REPORT391 TELESALES / MOTHER INTEGRATION

> This checkpoint supersedes older statements about the Telesales production read surface. It does NOT close the full Telesales workflow; it closes and verifies the Production integration foundation.

## Production
- Supabase project: SMART ERP / `fiilmooggumokxanwiyx`.
- Edge Function count remains 100; no new function created.
- `save-sales-invoice`: v16 ACTIVE, verify_jwt=true, deployment SHA `fef1f4111c6ad06c0a38eed6621b3d5d5e066352c46e0f2209099ebd811eaba2`.
- `delete-order`: v10 ACTIVE, verify_jwt=true, deployment SHA `e219c09f35c96e33800c36866ed48e7b65234164117fd58985db151c96728eb6`.
- Telesales DB user: `telesales@rawaea.com`, permissions=["telesales"], allowed branch BR-01.
- Order-Taker DB user: `order-taker@rawaea.com`, permissions=["orders"], allowed branch BR-01.

## Production RLS repaired
Created SELECT policies for the sales-entry capability:
- `branches_select_sales_entry`
- `customers_select_sales_entry`
- `items_select_sales_entry`
- `stock_branches_select_sales_entry`
- `orders_select_sales_entry_own`
- `order_details_select_sales_entry_own`

Authenticated-role verification using the real Telesales auth identity proved:
- branches=1 (BR-01)
- customers=3
- items=17
- stock_branches=17
- own orders=0
- own order details=0

The same read-surface verification passed for Order-Taker.

## Production authorization repair
- save-sales-invoice now requires DB sales permission and enforces source/status rules.
- Telesales canonical source = `telesales`.
- Order-Taker canonical source = `order-taker`.
- Telesales/Order-Taker cannot directly create Invoiced stock-moving sales through this Edge Function.
- Branch assignment is checked against DB `allowed_branch_ids` / `default_branch_id`.
- delete-order now prevents ordinary Telesales/Order-Taker users from deleting another user's order and blocks their direct deletion of executed Invoiced orders.

## Protected
- main.html not modified.
- telesales.html not modified.
- core.js not modified.
- save_sales_invoice_atomic not redesigned.
- post_stock_movement and Inventory workflow not modified.

## Open
- Telesales frontend still needs the exact DB-permission hydration patch.
- Telesales syncDown still needs explicit Supabase error handling before clearing Dexie.
- Explicit source='telesales' should be added to frontend payload for semantic clarity.
- Existing-order edit lacks a canonical backend update contract and must NOT be emulated by direct client UPDATE/DELETE/INSERT writes.
- Browser-rendered E2E and served-artifact identity remain open.
- Owner/license-tab Mother surgery from Report390 remains separate and unverified.

## Report
- `doc/Draft/Reprots/Report391_TELESALES_MOTHER_INTEGRATION_FORENSIC_20261008.md`
- Report commit: `79eb147c0734943b531ea4544e60ecd1fc58b68e`

## Next exact resumption point
1. Apply Patch A and the safe syncDown patch in current Telesales source.
2. Add explicit source=telesales.
3. Do not touch existing-order edit until a canonical update contract is implemented and tested.
4. Run authenticated Telesales E2E.
5. Verify the served artifact and service-worker version.
6. Close the full Telesales business capability only after Runsheet handoff and downstream visibility are verified.

# CURRENT STATE CORRECTION — 2026-10-08 — EXISTING ORDER UPDATE

The existing-order edit contract previously listed as OPEN in the Report391 checkpoint is now VERIFIED.

## Production
- Existing central `public.save_sales_invoice_atomic` was surgically extended; no new RPC/function created.
- It accepts `existing_order_code` in the existing `p_order_header` JSON contract.
- It locks the target order, requires Draft/Confirmed and no Runsheet, enforces ownership/manager privilege, updates header and replaces details atomically.
- It does not invoke stock movement or accounting for the Confirmed/Draft edit path.

## Verification
- Real Production-shaped QA transaction executed with the real Telesales identity, real customer, real item and BR-01.
- Existing QA order changed quantity 1 → 2 and returned successful update state.
- Entire transaction rolled back.
- QA order residue=0; QA detail residue=0.
- Function re-read after modification and confirmed the update contract is installed.

## Updated closure
- Production integration foundation = VERIFIED.
- Existing-order update contract = VERIFIED.
- Remaining full closure requirements are frontend application of the exact surgical patches and authenticated browser E2E through Runsheet/downstream workflow.
- Report391 addendum commit: `d4718232c463f88e8e88f174c01d7674b370539c`.
