## LVE-2026-11-08-641 — Employee Custody Surgical ChangeSet / Live Revalidation

## OWNER OPERATIONAL CORRECTION — 2026-11-08 (AUTHORITATIVE)

The owner clarified the one and only execution model: deploy/apply directly to SMART ERP Production \`fiilmooggumokxanwiyx\` and operational GitHub \`erp-frontend/main/companies/company-1\`. Do not create Supabase Staging branches/projects, Git execution branches, duplicate app files, or parallel implementation copies. Synthetic QA fixtures may be created directly on Production when clearly tagged, reversible/disposable, and fully cleaned after proof; use BEGIN/ROLLBACK when possible, and for committed E2E fixtures record IDs, baseline snapshots, complete dependent-row/storage cleanup and post-cleanup balance/count reconciliation. Never mutate real business records or leave QA rows/effects behind. This directive supersedes report text that says "Staging only" or "never test Production"; §6.4 was added to the permanent operating constitution. It does not bypass the specific-change review and approval gate for lasting Production changes.

Evidence basis: Report631 §10 documents SQL migration tests in BEGIN/ROLLBACK and RLS tests rolled back; Report632 §10 calls for E2E with removable QA data. Report640's Staging-only recommendation was an assistant-added constraint, not the owner's target operating model.


- Report641: doc/Draft/Reprots/Report641_EMPLOYEE_CUSTODY_SURGICAL_CHANGESET_20261108.md. Live forensic revalidation plus successful SQL/RPC QA inside one SMART ERP Production transaction ending in ROLLBACK; no permanent Production or operational-code write.
- Operational HEAD unchanged: b728c09e1bb4c482effc48a492546b393ff02c1f. Parent main.html blob 59241e741abcbc318fa68d3c10775e40e2688927; Core f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1; Buyer 5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a.
- Live SMART ERP remains ACTIVE_HEALTHY; no Staging branch is to be created under the owner's direct-Production model. Account 127/121 active Asset/Debit, no child GL or posted 127 lines; custody tables empty.
- Confirmed critical defect: finance_save_expense does not require account_type='expense'; asset 127 can enter generic finance_expenses. ChangeSet proposes only a type guard in the existing function, not a new writer.
- Existing buyer_custody_* tables/RPCs remain the single ledger. Existing issue/add/ack/settle RPCs need Treasury-to-branch enforcement, branch scope validation, received_at correction and payload-aware idempotency. Do not create parallel tables or new Edge Functions.
- Current Treasury snapshot: central CASH-01=10,685 EGP (branch_id NULL), BR-01 cashiers=0 EGP each, POS=190 EGP (must not fund employee custody), BR-2 Alexandria has no active Treasury. Phase 1 must only use same-branch Cash Treasury; central exception requires separate policy/permission; branch treasury must be provisioned and funded by real transfer.
- users is current employee identity source; employee_profiles empty. allowed_branch_ids is mixed scalar/array JSONB and current membership counts conflict with Report640; normalize before rollout. Do not expose employee_profiles sensitive HR fields to Finance.
- Employee self-service should use RLS-scoped reads and existing ownership-checking RPCs directly; do not use save-purchase-order GET_CUSTODY for ordinary employees because its current Edge gate is restricted to purchases/finance/finance_manager.
- Report641 documents Parent Finance tab and Buyer UI surgical owner patches. No operational HTML/Core changes have been applied. Six proposed function bodies plus received_at nullability DDL in Appendix A compiled and their SQL/RPC flows passed inside a Production rollback transaction. Tested: Expense-127 rejection, no effect before ACK, Treasury/branch/POS/central guards, Issue/Add idempotency and conflict rejection, employee ACK payments, additional advance, full settlement/return, and Treasury baseline restoration. Browser JWT E2E, PostgREST RLS, UI integration and Cloudflare parity remain unverified.
- No permanent Production DDL/RPC/RLS/ACL/Edge deployment, operational UI/Core change, treasury/journal/cash_box movement, QA row or test record remains from LVE641. The only Production writes were inside a QA transaction and fully rolled back; post-rollback counts are zero and Treasury balances are back at 10,685/0 EGP. No Staging project/branch is to be created.
- Readiness: SQL/RPC QA PASS — FULL ROLLBACK VERIFIED / PERMANENT CHANGE AND OWNER UI WORK OPEN.

---

## LVE-2026-11-07-640 — Employee Custody / Parent Finance / Cross-App Revalidation

- Report640: `doc/Draft/Reprots/Report640_EMPLOYEE_CUSTODY_PARENT_FINANCE_CONSUMER_REVALIDATION_20261107.md`, commit `806d40acdb92f2260dd022a20cd26dbd16949d20`.
- Current operational HEAD remains `b728c09e1bb4c482effc48a492546b393ff02c1f`; Parent blob `59241e741abcbc318fa68d3c10775e40e2688927`; Core `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`; Buyer `5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a`.
- Parent Finance has no Employee Custody tab. Its generic payment modal loads all active COA accounts and calls `finance_save_expense`; the RPC does not enforce Expense account_type, so asset 127 can be posted through a generic finance_expenses document without employee/custody linkage. Never use this as a custody workaround.
- Buyer is the only one of 30 company-1 HTML files found using cash-custody APIs. Van-sales "عهدتي الآن" is vehicle inventory, not cash. Buyer Realtime subscribes to custody tables with a 15-second reconciliation setting; Runtime delivery remains unverified.
- Live `save-purchase-order` v30 is the only current custody API route found in the reviewed app/Edge consumers. Its GET/ACK/Submit gate requires purchases/finance/finance_manager, excluding ordinary sales/delivery employees. Finance issue/review/settlement remains finance/finance_manager-only.
- Production SMART ERP ACTIVE_HEALTHY; 755 migrations, latest `20261104223538`; no Staging branches. COA 127 and 121 active Asset/Debit; no child GL under 127 and no journal lines on 127. Buyer cash/goods custody tables all zero; cash_box has 3 Payment and 5 Receipt rows. Active Expense accounts remain 5/51/52 only; no transport/fuel/tolls Expense leaf.
- Current HR screen and `save-employee` v10 use `users`, not `employee_profiles`. employee_profiles=0 is not itself a blocker. Production users: 31 Active; employee_id empty 31/31; default_branch_id present 3/31; allowed_branch_ids present 9/31. Technical custody identity is users.id, but employee eligibility and branch mapping need explicit rules. employee_profiles contains sensitive HR fields; do not expose it to Finance.
- Custody RLS grants authenticated SELECT only; service_role DML; no anon privileges. Custody RPCs are SECURITY DEFINER, authenticated/service_role EXECUTE, no anon EXECUTE.
- Current issue/add/settle RPCs do not enforce Treasury branch match; Issue allows branch_id NULL. issue_atomic writes received_at before acknowledgement. Issue/Add Advance idempotency returns existing rows without comparing payload. No separate cashier/handover actor, due date, cost center or mission id. Settlement safely blocks employee overspend because Employee Payable is not configured.
- Recommended target: one GL control account 127 plus employee/mission virtual subledger; add Employee Custody destination in Parent payment flow and a dedicated Finance tab; expose "عهدتي النقدية" through a shared authenticated employee component across relevant apps, keeping cash separate from vehicle/inventory custody. Reuse current ledger/RPCs with backward compatibility; no parallel tables or new Edge Function.
- No operational code, Production schema/data, Edge deployment, permissions or business records were changed; no QA data created. Cloudflare, Browser E2E, Runtime Realtime and Staging remain UNVERIFIED.
- Readiness: READY WITH LIMITATIONS. Next: exact owner-reviewed ChangeSet for employee/branch identity, Treasury matching, finance_save_expense account-type guard and Parent Finance custody route; no operational/Production write before explicit approval.

---

## LVE-2026-11-07-639 — Parent Finance / Enterprise Employee Custody Architecture

- Report639: `doc/Draft/Reprots/Report639_EMPLOYEE_CUSTODY_ENTERPRISE_ARCHITECTURE_20261107.md` (commit `fd6d1d41b01399409f90dd49a33fdbb179e0ec5a`).
- Current operational HEAD remains `b728c09e1bb4c482effc48a492546b393ff02c1f`; Parent `main.html` full blob `59241e741abcbc318fa68d3c10775e40e2688927`.
- Parent has RW_Finance. Its generic payments UI calls `finance_save_expense` and must not be used unchanged for employee custody, because it posts expense debits and Treasury cash effects.
- Production COA 127 "عهد الموظفين" exists as active asset/debit; COA 121 "النقدية" exists; COA 127 has no child GL accounts and no journal_lines.
- Buyer custody tables exist with RLS and are currently empty. Their existing lifecycle: finance issues custody + Initial advance; recipient acknowledgement invokes central cash-payment posting Dr127/Cr121; approved operational expense Dr expense/Cr127; actual cash return Dr121/Cr127. These structures are Buyer-specific and not yet a generic service for all company employees.
- Current Production has 31 active users and zero employee_profiles. employee_profiles.employee_id FK points to users.id. Existing custody uses users.id; authoritative employee mapping must be resolved before all-staff rollout.
- Live buyer_custody_issue_atomic checks Treasury company/activity but not its branch_id against custody branch. Treasury master data includes central CASH-01 with null branch_id and branch cashiers/POS; branch matching and explicit centrally authorized exception are required.
- Recommended design: single employee-custody subledger under GL control 127, grouped by employee/branch/mission/custody, shown under 127 in Parent Finance. Avoid one physical GL account per employee by default and do not create a parallel ledger. Keep business-purpose custody separate from salary advance, employee-paid reimbursement, direct expenses and inventory purchases. Use same central posting contract across employee apps, employee-only visibility, role segregation, immutable audit, idempotency and ageing/reconciliation.
- Do not reuse finance_save_expense for custody advances. A draft/approval has no effect; actual acknowledged handover posts Dr127/Cr121; approved expense Dr expense/Cr127; actual returned cash Dr121/Cr127; employee overspend requires separate employee-payable liability/payment or explicit rejection.
- No operating code or Production change occurred in this assessment. Deployment, Browser E2E and Staging remain UNVERIFIED. Next step is a full consumer map of buyer_custody RPC/table users and employee/branch identity contracts, then exact approved ChangeSet.
 
---

# LVE-2026-11-06-638 — PO / Receiver / Audit Integrity Revalidation

- Report638: `doc/Draft/Reprots/Report638_DAILY_PO_RECEIVER_AUDIT_HISTORY_REVALIDATION_20261106.md`; report commit `0c22a78fb117a271ff4dcbb06552f9f16f006bc7`.
- CURRENT_STATE advanced to LVE638 in commit `0de7c7a43896815388131f025646b8fa38c013c2`; previous LVE637 remains below as historical checkpoint.
- Operational repo HEAD unchanged at `b728c09e1bb4c482effc48a492546b393ff02c1f`. Receiver blob `075ddf9e5801c25bd337d65bf883b4bf4b5736c3`; Core blob `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`; Supervisor blob `8d46c3c6d6df487ebd880c29d438bcdd2bd789bf`; Buyer blob `5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a`.
- SMART ERP remains ACTIVE_HEALTHY; 755 migrations, latest `20261104223538`; no Supabase Staging branches. Edge save-purchase-order v30 and receive-purchase v14 remain ACTIVE with LVE637 SHAs.
- Current POs remain QA-SR-PO-20260927 Approved (detail 5/5, no Receiving document) and PO-20260928 Approved (15 ordered, 0 received). No matching Receiving, inventory_log, supplier_ledger or journal_entries records were found for either.
- Clarified purchase_status_history count: 9 total = 5 purchase_invoices + 3 purchase_orders + 1 PurchaseOrder alias. Root cause of duplicate PO creation history is confirmed: purchase_create_po_atomic manually inserts PurchaseOrder/Created while the purchase_orders INSERT trigger also inserts purchase_orders/INSERT for the same PO. Consumer impact is not yet known.
- purchase_status_history remains mutable by authenticated same-company users through ALL RLS policy and INSERT/UPDATE/DELETE grants. Append-only audit contract is not implemented.
- P1 remain: Receiver raw HTML interpolation / DOM-XSS sink; Receiver omits operation_id while receive-purchase v14 generates deterministic fallback; purchase_status_history is mutable. P2 remain: Receiver company-wide PO visibility without branch filter; duplicate creation history; missing formal SEND_PO/ISSUE_PO; Supervisor UTC day boundary and silent query errors.
- Owner self-approval policy remains unresolved. The live PO data includes an Owner-created PO approved by the same Owner; current RPC does not block creator self-approval. Do not infer policy.
- Last 24h logs: 134 save-purchase-order HTTP 200 requests; no receive-purchase invocation. No E2E evidence.
- Cloudflare artifact, authenticated Browser E2E and Staging remain UNVERIFIED. Browser context unavailable. No operational/Production write, code change, deployment or QA data was performed in LVE638.
- Readiness: READY WITH LIMITATIONS. Next: prepare exact approved Receiver/Audit ChangeSet (safe DOM rendering, per-intent operation_id, branch scope, append-only history, deduplicate PO creation history) with Staging-only tests and rollback. No new Edge Function.

---

# LVE-2026-11-05-637 — PO Approval Production Revalidation / Receiver Security

- Report637: `doc/Draft/Reprots/Report637_DAILY_PO_APPROVAL_RECEIVER_SECURITY_REVALIDATION_20261105.md`; final report commit `d5e48f61b05d8fc999300a9b17e62e8ef4db6644`.
- Read-only daily checkpoint at 2026-11-05 22:29 Cairo. Operational HEAD `b728c09e1bb4c482effc48a492546b393ff02c1f`; main owner change commit `684a55240a2f1145134b367204ef0da2c0b696e2`; supervisor `cf07aba424f5ca37cf75ac1804d756448841f4ea`; receiver `b728c09e1bb4c482effc48a492546b393ff02c1f`.
- Production Edge v30/v14 active; approval RPC and receiving gate still present. No operational writes or tests were performed this run.
- New Production events after LVE636: QA-SR-PO-20260927 Draft→Approved at 17:52:32 UTC by Owner; PO-20260928 created at 18:02:42 UTC and approved at 18:05:00 UTC by Purchasing Supervisor. Two POs are Approved; Receiving=0; Receiving Details=0; PO history=3. No matching stock/AP/GL references were found.
- QA-SR-PO-20260927 still records 5/5 received in PO details without a Receiving document; do not clean or reverse automatically.
- P1: Receiver stored DOM-XSS sink (RW_UI.safeHTML is innerHTML only; unescaped PO/supplier/item/profile values are interpolated); Receiver does not send operation_id, core RW_API adds no Idempotency-Key, Edge v14 uses deterministic fallback, and receive_purchase_atomic can return duplicate for a later independent receipt with the same payload; purchase_status_history has authenticated same-company DML through ALL policy + table grants, so audit history is mutable.
- P2: Receiver lists company POs without branch filtering; no SEND_PO/ISSUE_PO; Supervisor dashboard UTC day boundary and silent query errors.
- Owner clarification on 2026-11-05 16:59 UTC: Parent approval requires `purchases`; supervisor app requires `purchases_supervisor`. It does not explicitly settle whether PO creator self-approval is allowed; current RPC does not block it. Keep as unresolved decision, do not infer.
- COA read confirms only expense parent 5, COGS 51, inventory variance 52 in relevant expense accounts; operational transport/fuel leaf remains missing.
- Cloudflare deployment of cf07/b728, deployed artifact, authenticated Browser E2E and Staging remain UNVERIFIED. No commit status checks on b728.
- Readiness: READY WITH LIMITATIONS. Next: exact owner-reviewed Receiver hardening and append-only purchase_status_history ChangeSet; no Production/RLS change without explicit approval. Owner applies operational HTML changes.

---

# HISTORICAL MEMORY BASE — LVE-2026-11-05-632 — Buyer Cash Custody / Operational Expense Hardening

- Report632: [Buyer Cash Custody, Operational Expenses and Quick Market Reservation Hardening](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report632_BUYER_CASH_CUSTODY_OPERATIONAL_EXPENSES_QMP_HARDENING_20261105.md) — commit c52554ebd276369141c935f271009b74f71c3261.
- Production migration buyer_custody_operational_expenses_20261105 version 20261104223538 is applied; operational migration file supabase/migrations/20261104223538_buyer_custody_operational_expenses_20261105.sql. New columns expense_type/category/reference/account_id with checks/FK/indexes; PO expense reviewer remains PO-only.
- New buyer_custody_submit_other_expense_atomic validates caller owns acknowledged open cash custody, currency, allowed category, exact private Storage path/object/MIME/size <=10MB, operation idempotency, and available cash after submitted/approved expenses and open QMP reservations. It creates Submitted OPERATIONAL expense only; no stock/AP/treasury/GL.
- New buyer_custody_review_other_expense_atomic is Finance/Finance Manager-only, forbids self-review, requires valid active company expense leaf, posts one balanced journal DR operational expense / CR custody 127, no extra treasury cash. Reject releases reservation.
- Existing PO submit expense guard includes Quick Market reservations. Custody settlement blocks QMP open invoices, pending expense reviews, unacknowledged advances, and employee payable without a configured payment flow.
- Edge save-purchase-order v29 ACTIVE, verify_jwt true, SHA256 35caa4f2759ba608a7f3bf86640b4773280bc84447872267d6e4d53896743e04; live source synchronized to Git and exact archived Current/CTO/EdgeSnapshots/20261105/save-purchase-order_v29.
- Buyer source commit 21c35a5d02d36c32ecb3304f5cecb6f157911741, blob 5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a; UI shows QMP reservations, separate operational expense modal and review, blocks misleading custody close. JS syntax parse PASS; Tailwind workflow 41927675334 success.
- COA has only expense parent 5, COGS 51, inventory variance 52; no active expense leaf for transport/fuel. Therefore operational expense can be submitted/reserved but Finance approval stays blocked until proper COA accounts are configured. Never use 51/52 or guess codes.
- Supplier cash refund from delegated Buyer SupplierReturn remains open/not implemented; current SupplierReturn trigger clears custodian_user_id, direct Supplier contract, and full AP/GL completion. Need linked single writer, Buyer custody delegation, partial acceptance, cash receipt evidence and Finance disposition between actual cash refund vs credit note. No cash custody was increased by a return.
- Current data unchanged: EGP, buyer_custodies 0, advances 0, expenses 0, goods events 0, purchase invoices 3, QMP invoices 0. No fixtures or business stock/AP/GL/Treasury changes.
- Cloudflare deployment for Buyer source commit unverified; authenticated Buyer E2E not run. Receiver deferred; no main.html/core.js/Receiver/Vouchers edits; no new Edge Function.

# LVE-2026-11-04-631 — Buyer Invoice Evidence / Security / Performance

- Report631: [Buyer Attachment, Security and Performance Hardening](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report631_BUYER_ATTACHMENT_SECURITY_PERFORMANCE_20261104.md), commit `9f4c67dfe28d3dafad74d85b161ea732805438ee`.
- Operational HEAD `b47a56379018e1965e98bb25015d860ba0f70a9f`; Buyer blob `d22d9d914069c820d47ba2dc7e6ead721e1b26d3`; Tailwind CSS commit `10e9a875053743dd9eeb593c973968086572cf14`.
- Buyer Quick Market supplier invoice image/PDF workflow implemented in Buyer source; new drafts require JPEG/PNG/WEBP/PDF <=10MB. Upload path binds company/user/invoice, Edge validates invoice ownership/source/draft status/path/object/MIME/size, registration is idempotent, and invoice detail shows a 5-minute signed URL. Unknown attachment outcome preserves file and draft.
- Edge `save-purchase-order` v28 ACTIVE, verify_jwt true, SHA256 `663b4bab72a4c81ec93b53d3f15a29902fa9984320f11a198209a46ac45646e2`, archived blob `7291a8ca704213a244d740ed7ce8f01920f5dac4`. v28 uses Storage API `info(path)`; v27 superseded.
- Storage bucket `employee-documents` remains private. Finance/Finance Manager/Owner can read only same-company buyer-goods objects tied to Quick Market invoice. Warehouse/Receiver not granted until branch-scoped integration.
- `purchase_attachments` RLS limits PurchaseInvoice metadata to purchaser/creator or Finance/Finance Manager/Owner; Edge GET_DATA scopes non-finance to visible invoices. RLS test rolled back: buyer 0, finance 1, finance_manager 1, owner 1, warehouse 0. Unique path test rolled back: first insert 1, duplicate 0.
- Returns tables are central-writer-only: anon no privileges, authenticated SELECT only, service_role DML; Parent reads via SELECT/RLS and writes via Edge central RPCs.
- Eight migrations applied/recorded: 20261104213909, 20261104214839, 20261104215236, 20261104215443, 20261104215757, 20261104220325, 20261104220515, 20261104220659.
- Added 10 Buyer goods/return indexes and 48 further Buyer/Purchase FK indexes. Performance Advisor: 0 unindexed FK findings in buyer_/purchase_ scope; 244 remain elsewhere.
- Revoked EXECUTE from PUBLIC/anon/authenticated on 16 trigger-only SECURITY DEFINER functions; service_role/postgres retained and all triggers remain attached. Pinned `sales_decision_default_policy()` to search_path pg_catalog. Reviewed 20 authenticated Buyer/Purchase SECURITY DEFINER RPCs; retained because they enforce auth.uid/company/permission/ownership and Edge calls with user JWT.
- Security Advisor remaining: 2 intentional public-store SECURITY DEFINER functions, 123 authenticated SECURITY DEFINER systemwide, 24 RLS-enabled-no-policy INFO, and one leaked-password-protection warning.
- Buyer JS parse check PASS; Tailwind CSS generated. Cloudflare deployment still unverified and authenticated upload/signed URL E2E not run.
- Current production data: EGP, 3 historical purchase invoices, 0 Quick Market invoices, 0 Buyer cash custodies, 0 goods events, 0 returns/details, 0 attachments. No test data remains.
- Remaining: Buyer→Warehouse/partial acceptance waits for Receiver; Buyer→Supplier requires separate physical custody/return accounting design; purchase invoice RLS consumer map; Parent stale SAR UI constants; Cloudflare/E2E; 244 global FK and 123 authenticated SECURITY DEFINER audits; Auth leaked-password protection setting.

# LVE-2026-11-04-630 — Purchase Returns Central Writer Enforced

- Report630: [Purchase Returns Central Writer Hardening](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report630_PURCHASE_RETURNS_CENTRAL_WRITER_HARDENING_20261104.md), report commit `222ad88f4196e754d67bad7024766bb053b117ac`.
- Scanned 34 company-1 HTML/JS files and six Edge functions. Parent main.html reads `purchase_returns` directly via Supabase SELECT but creates/posts via `save-purchase-order` Edge `CREATE_RETURN`/`POST_RETURN`; Buyer reads only. No direct DML consumers found in app sources.
- RPCs `purchase_create_return_atomic` and `purchase_post_return_atomic` are SECURITY DEFINER and EXECUTE only service_role/postgres.
- Applied Production migration `buyer_purchase_returns_central_writer_only_20261104`, version `20261104214839`: anon has no privileges; authenticated SELECT only; service_role retains DML. RLS policies SELECT-only and company-scoped. Verified with ACL, policies, has_table_privilege and a simulated authenticated SELECT transaction.
- Operational migration blob refs: 01 hardening `eff1da92b8045b6f439b3aae67008dab17303042`; returns writer `abbb1aa308c4325b2db7aecc3d49bd530f5218db`.
- Edge v26 archived exact with manifest; v26 remains ACTIVE, verify_jwt true, SHA256 `fb31ac953213d6f30a9e545f1da3b9075ca28638b5032450618769d20f2cb5b4`.
- Buyer LVE629 commit `a35cd59fab199e1614536cd4ce5421179a907608` adds local Quick Market supplier search; earlier commit `240858a` adds unknown-outcome evidence protection and Realtime.
- Parent purchasing UI has stale `currency: 'SAR'` payload constants, but Edge v26 CREATE_QUOTATION/CREATE_INVOICE forces system currency from app_settings (EGP). Parent not edited; stale UI constants remain for separate parent-scoped change.
- Remaining: Quick Market invoice image and purchase_attachments workflow; Storage SELECT for Finance and branch-scoped Warehouse; invoice RLS consumer map; Buyer→Warehouse/Supplier and partial acceptance; Cloudflare deployment parity and authenticated E2E. Receiver deferred. No business data/test fixtures.

# LVE-2026-11-04-629 — Buyer Quick Market Supplier Search / Storage Boundary

- Report629: [Buyer Quick Market Supplier Search and Storage Boundary](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report629_BUYER_QUICK_MARKET_SUPPLIER_SEARCH_STORAGE_BOUNDARY_20261104.md), commit `74ec5ee64c4be4a7a8d180b64654c682cbad3e31`.
- Latest Buyer source commit `a35cd59fab199e1614536cd4ce5421179a907608`, blob `0ac1cd20c5e879405b7d11af7a3349124ea374cf`; only `companies/company-1/purchasing/buyer.html` changed; local supplier search filters active supplier option text by name/code, preserving selection. Data cap remains 500; not server pagination.
- LVE628 Production hardening remains: migration `20261104213909`; `save-purchase-order` v26 ACTIVE SHA256 `fb31ac953213d6f30a9e545f1da3b9075ca28638b5032450618769d20f2cb5b4`; three RPC guards in place; no business data changes.
- Storage access discovery: employee_docs_storage_select permits owner or HR, not Finance/Warehouse; buyer_goods_custody_events SELECT allows custodian, Finance, Finance Manager, Owner, not Warehouse. Avoid broad Storage policy. Need specific least-privilege buyer-goods policy, with branch-scoped Warehouse/Receiver authorization.
- purchase_attachments has storage_path/file metadata; authenticated SELECT only and service_role INSERT. Buyer Quick Market modal and invoice details do not currently upload/render supplier invoice image. Implement only with validated Edge registration, idempotency and signed URLs after defining Storage access.
- Edge GET_DATA filters non-finance purchase invoices to purchaser_user_id/created_by; direct table RLS remains broad and requires consumer map.
- Cloudflare commit deployment unverified; authenticated E2E not run. No test fixtures. Remaining invoice image, storage read policy, RLS/returns consumer maps, Buyer→Warehouse/Supplier and partial acceptance; Receiver deferred; legacy reconciliation.

# LVE-2026-11-04-628 — Buyer Phase 1 Hardening Applied / E2E Open

- Owner explicitly approved the reviewed Buyer Phase 1 changes. Report628: [Buyer Phase 1 Hardening Applied and Verification](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report628_BUYER_PHASE1_HARDENING_APPLIED_AND_VERIFICATION_20261104.md), commit `13ade99f2279c76957ba93147f64089144018578`.
- Production migration `buyer_phase1_hardening_20261104`, version `20261104213909`, applied after full SQL compile in a transaction rolled back before application.
- Three live RPC bodies hardened with signatures/ACL preserved: QMP open reservation blocks cash-custody settlement; goods handover requires company/user/invoice-bound evidence path and existing private Storage object; generic invoice delete blocks invoices with goods-custody events.
- Existing `save-purchase-order` Edge v25 snapshot used as source (not stale Git file); deployed v26 ACTIVE, verify_jwt true, SHA256 `fb31ac953213d6f30a9e545f1da3b9075ca28638b5032450618769d20f2cb5b4`, deployed source matches approved ChangeSet exactly.
- Buyer operational repo commit `240858a071736a416dcf302e8cfc28e453016c3f`, file `companies/company-1/purchasing/buyer.html`, blob `ecce26b3cbc108b4950bf083898fabd7d0e4a7d0`: fixed ambiguous RPC outcome so evidence is not deleted when verification fails; added goods custody events to Realtime and invoice/vehicle refresh targets.
- `buyer_goods_custody_events` already belongs to `supabase_realtime`; RLS enabled. Existing generic private employee-document policies map first two path segments to company/user. No Storage ACL change.
- Post-change data unchanged: app_settings currency EGP; purchase_invoices 3; buyer_custodies 0; goods events 0; Quick Market invoices 0. No test data, stock, treasury, AP or GL mutations.
- Cloudflare Pages automatic deployments enabled; currently available dashboard snapshot is stale and only shows 3717c02, so deployment for 240858a is unverified. No authenticated Buyer session; E2E remains not run.
- Remaining: buyer-only invoice RLS/consumer map; purchase_returns/details direct-DML consumer map; Quick Market invoice image/supplier search; Buyer→Warehouse/Supplier and partial acceptance; Quick Market expense settlement; Cloudflare parity and authenticated E2E. Receiver intentionally deferred. Do not delete/reverse historical Posted invoices or QA-SR without reconciliation.

# LVE-2026-11-04-626 — Buyer Live Forensic Revalidation

- Report626: [Buyer live forensic revalidation and Phase 2 ChangeSet](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report626_BUYER_LIVE_FORENSIC_REVALIDATION_AND_PHASE2_CHANGESET_20261104.md), commit `32c8716a6f23f79865d1a51a711c8da4975b09a5`.
- Live operational HEAD: `bf0833c3c71d7a2dea6167bfac9b5403e8044cf7`; Buyer blob `d9ffb1084a538b7f7baf48391d3048ac5e96bffa`; CSS blob `7eb4ef089a1903e405179f23f921328cad1c06e9`. 19 commits since `e8ab54c` are limited to Buyer/CSS. Receiver, Parent, Core and Vouchers unchanged.
- Buyer Phase 1 Production migrations 01–09 are live. `buyer_goods_custody_events` exists, RLS/append-only; no events or Quick Market invoices exist yet. Edge save-purchase-order v25 and receive-purchase v13.
- Quick Market form lacks supplier invoice image and smart supplier search; invoice date is absent. Goods custody supports supplier→Buyer only; Buyer Realtime does not subscribe to the events table.
- Cash custody settlement ignores outstanding QMP reservations; QMP expense review remains PO/Receiving-only. Generic Edge draft deletion remains callable without purchaser ownership or goods-event guard. Invoice table RLS is company-wide despite Edge GET_DATA filtering.
- SupplierReturn still uses SAR default/fallback, excludes Buyer custodian, permits direct DML on purchase_returns/details, lacks acceptance batches/partial acceptance and cumulative return quantity protection, and has two possible stock/financial writers.
- Historical PINV-1000/1001 are Posted SAR with 5 PurchaseIn movements (50 units), SAR 3,970 supplier-ledger credit and 2 Posted journals; later movements exist. Do not delete directly. QA-SR Draft has inconsistent receipt flags/quantities without a matching Receiving/inventory/AP/journal record.
- Current app_settings currency EGP. Deployment for HEAD bf0833c and authenticated E2E remain unverified. No Production or app write occurred; no test data created.
- Owner sequence remains Buyer first; Receiver is deferred until Buyer acceptance. No new Edge Function; extend existing functions only.
- Exact full change package, impact, acceptance tests and rollback must pass Report614 §14 / charter §6.2 explicit approval before operational or Production writes.

---

# LVE-2026-11-04-621 — Integrated Buyer Goods Custody / Return / Quick Market

- Report621: [Integrated contract gap review and LVE620 reconciliation](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report621_BUYER_INTEGRATED_CONTRACT_GAP_REVIEW_AND_LVE620_RECONCILIATION_20261104.md), latest commit `080c03711154e544c126f5fa41ded2e895a6c11b`.
- CURRENT_STATE is now advanced from stale LVE616 to LVE621; update commit `a9e627e5ff83c7648e7e7f98eba9b59da1269f13`.
- Reconciling basis: Execution Log/Project Memory LVE620; owner decisions Report606; technical/competitive research and change contracts Reports615–620; current operating charter blob `d2afa896514b1cb6abd247d2af7a862251ce0604`.
- Fresh Production read: purchase_invoices=3 (Draft 1 / Posted 2 / no-PO 2); purchase_returns=0; stock_vouchers=0; receiving=0; buyer_custodies=0. `purchase_returns` and details still grant anon/authenticated direct DML with permissive company-only ALL policies. Existing cash-custody review remains PO/AP-specific and must be preserved as a separate branch.
- Current source still shows Buyer `رصيدي` static, Quick Purchase as Draft invoice alias, SupplierReturn without recipient picker, Receiver `po_code` detail query mismatch (actual `po_id`) and parseInt precision defect; no deployed app changes.
- P0: SupplierReturn SAR default/form is incompatible with app_settings EGP; save-contract accepts SAR and financial functions ignore the currency field. Both posting functions need fail-closed currency validation.
- P0: manual SupplierReturn voucher and Parent `purchase_returns` are independent stock/AP/GL writers. Single writer: warehouse voucher dispatch only; linked purchase_return acceptance batch only for accepted AP/GL; linked financial posting cannot post stock.
- P1: purchase return cumulative quantity lock missing; Receiver zero/decimal checks and Quick Market invoice-ID Receiving are missing.
- Competitive evidence in Report621 uses official Dynamics 365 partial return/product receipt, Odoo staged input/quality/stock, and SAP return PO/outbound delivery/goods issue/vendor credit memo flows.
- Schema v1/v3 rejected; v2 still incomplete; created reviewed schema scaffold v4 at `Current/CTO/ChangeSets/20261104/04_buyer_goods_custody_schema_security_REVIEWED_DRAFT_v4.sql`, latest blob `585b7091c3692be519d9455bc27036f5a1c93153`, correction commit `647fec6a9b7d7201cf06941bc016806849ee2cba`. It fixes duplicated acceptance counters, acceptance finance state, multiple event allocations per Receiving line, new Receiving source types/line links, recipient-mode nullability and currency default. It is not executable or approved and has no full RPC/Trigger/Edge bodies.
- Six live Edge snapshots are archived; versions/hash details appear in Report621. No new Edge; five functions are not yet restored to operational Git paths. New auth.uid() operations use profileClient.
- No operational app source, Production schema/data/RPC/Trigger/RLS/ACL, Edge deployment, Cloudflare deployment, test fixture, browser E2E or migration execution. Schema text scan only is not a PostgreSQL compile.
- Governance: preserve Parent main.html lock; no Production/operational write before exact full changeset and explicit owner approval under §77.2.
- Status: forensic/design/change-set preparation continues / implementation NOT STARTED / NOT PRODUCTION READY. Next: finish full RPC/Trigger bodies, six Edge diffs, surgical Buyer/Vouchers/Receiver patches, owner-side Parent patch, private evidence policies, schema-parity JWT/E2E/financial tests and rollback; then submit exact bundle for approval.

---

# LVE-2026-11-04-620 — Existing Edge Function Extension Contract

- Report620: [Existing Edge extension contract](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report620_EXISTING_EDGE_EXTENSION_CONTRACT_20261104.md), commit `4052446b38b35a26b186ab9a861066a205d2a9fd`.
- Confirmed exact current `save-purchase-order` v22 dispatch/permission structure. New Buyer custody operations should use existing Edge only and use `profileClient` for new auth.uid()-dependent RPCs.
- Existing `receive-purchase` v13 can be extended with mutually exclusive PO `po_code`, Quick Market `invoice_id`, and Buyer custody `receiving_id` modes. Preserve current PO payload and RPC unchanged.
- Existing `create-stock-voucher` v12 already forwards `rep_id` → `p_rep_id`; Buyer Delegate can reuse it after SQL Trigger/RPC validation. Existing `send-stock-voucher` v20 and `complete-stock-voucher` v4 can keep request shapes while their SQL RPC behavior is updated.
- No new Edge function. Edge source snapshots are archived and current source parity is no longer a blocker.
- Hardening: `save-purchase-order` v22 `getSystemCurrency()` currently falls back to EGP if setting missing; change to fail closed for missing/invalid `app_settings.currency`.
- No Edge deploy or source write. Status remains contract design / not implemented.

---

# LVE-2026-11-04-619 — Buyer Custody RPC / Single-Writer Posting Contract

- Report619: [Buyer custody RPC and single-writer posting contract](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report619_BUYER_CUSTODY_RPC_SINGLE_WRITER_POSTING_CONTRACT_20261104.md), commit `e3c0fc755815cf5e49c972a1d67607c8cddc9823`.
- Refined schema/security draft v2: [02_buyer_goods_custody_schema_security_DRAFT_v2.sql](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/Current/CTO/ChangeSets/20261104/02_buyer_goods_custody_schema_security_DRAFT_v2.sql), latest commit `2961a45d34349033991b36ad8312a71933d45c61`. V2 removes duplicate return-to-warehouse quantity from stock voucher detail and aligns return/acceptance status constraints. Still NOT executable alone.
- Report619 defines server contracts for: paged Buyer ledger read; Quick Market supplier-to-Buyer handover; Buyer-to-Warehouse Receiving; invoice-ID Quick Market Receiving; SupplierReturn case creation; dispatch; supplier acceptance batches; financial posting for accepted quantity only; currency validation; Quick Market cash-custody settlement.
- Single-writer: Warehouse voucher owns physical stock-out; Buyer custody event ledger owns Buyer balance; supplier acceptance batch owns accepted AP/GL return posting; linked financial posting must not issue stock a second time.
- Existing PO receipt, PO custody settlement, DirectSale/DirectReturn and Transfer must remain behaviorally unchanged. Existing Edge functions only; no new Edge.
- Parent recipient column remains blocked under current `main.html` lock.
- No production/source writes or test fixtures. Status OPEN / NOT IMPLEMENTED / NOT PRODUCTION READY.

---

# LVE-2026-11-04-619 — Schema Review + Receiver Patch Completion + Buyer UX Financial Reconciliation

- Report619: [LVE616_SCHEMA_REVIEW_AND_RECEIVER_PATCH_COMPLETION_20261104.md](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report619_LVE616_SCHEMA_REVIEW_AND_RECEIVER_PATCH_COMPLETION_20261104.md), commit `9b1bd4d374d292f21c13a6da1d6716cbdaa115f5`, blob `f284d8e7e0023c333db0caf45967c65ff86303ce`.
- Reviewed schema scaffold v2: `Current/CTO/ChangeSets/20261104/02_buyer_goods_custody_schema_security_REVIEWED_DRAFT.sql`, latest commit `b203017bfede923382cb833b195d443289ed0838`, blob `9446c4dece9650fb6736e92db1aa340f89ee53dd`. This is schema/security scaffolding only, NOT a deployable migration and NOT executed.
- Canonical Report617: [SupplierReturn Recipient & Currency Surgical Change Set](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report617_SUPPLIER_RETURN_RECIPIENT_CURRENCY_SURGICAL_PATCH_20261104.md), blob `1f2624c5d93adbc8034f1515d6c4791cb2f77564`.
- Report618 UX spec was reconciled and updated (latest blob `53f89aca7f273a5bb6978974dfe22e77c90a16d3`): use `purchase_source='QUICK_MARKET'`; settlement values `EMPLOYEE_CUSTODY`, `SUPPLIER_CREDIT`, `TREASURY_CASH`; employee-custody cash requires invoice-linked accepted Receiving but NO Supplier AP prerequisite and no duplicate supplier payment; operation UUID is fresh per physical event and reused only for exact retry.
- Report619 review found v1 SQL scaffold must not run: unguarded purchase_returns.purchase_invoice_id DROP NOT NULL; destructive replacement of purchase_returns.status check; recipient_mode default applies to non-SupplierReturn vouchers; missing Buyer delegation reference/evidence; duplicate mutable acceptance counters; missing rejection details/sign rules; missing PUBLIC ACL revoke; settlement vocabulary mismatch; no function bodies. Reviewed v2 fixes these schema-contract risks but leaves business RPC/Trigger functions and deployment open.
- Receiver source revalidated: App.purchaseOrders exists; the exact owner-side patch selects PO id, queries details by po_id, uses qty_received to calculate remaining, hides Receive on error/empty, escapes values, validates decimals, uses fresh operation UUID with exact retry reuse.
- Exact edge snapshots remain byte-identical to live Production for all six functions. No function was deployed or modified.
- No operational source write, Production DDL/DML/ACL/RLS/RPC/Trigger/Edge write, test fixture or Cloudflare deployment. Parent main.html remains locked.
- Status: LVE615–619 forensic and source/contract specifications prepared; implementation still NOT APPLIED / NOT PRODUCTION READY. Next coherent step: author full replacement RPC/Trigger/Edge contracts against archived exact source, with one-writer supplier return posting, partial acceptance/tax, cumulative return lock, invoice-ID Quick Market receipt, separate cash settlement branch; then submit exact full change set under §77.2 before operational/Production writes.

---

# LVE-2026-11-04-618 — Buyer Goods Custody / Quick Market UX Specification

- Report618: [Buyer goods custody and Quick Market UX specification](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report618_BUYER_GOODS_CUSTODY_QUICK_MARKET_UX_SPEC_20261104.md), commit `440a32991d8b3a259ab77d7da81d801bfe5e2a34`.
- Exact UX contract: replace static `renderVehicleBalance` with server-backed event-ledger dashboard; separate invoice Draft save from physical Supplier→Buyer handover; Buyer→Warehouse accepted quantities; Buyer→Supplier accepted quantities; default Supplier Direct / Buyer Delegate exception; no mandatory vehicle; hide last cost by default; separate cash custody from goods custody.
- Read model must server-aggregate and paginate; do not calculate balance from 500-row client cache. Realtime must include custody events, acceptance batches, receiving and voucher sources.
- Existing Edge only: extend save-purchase-order v22, receive-purchase v13, create-stock-voucher v12, send-stock-voucher v20, complete-stock-voucher v4; no new Edge Function.
- Existing PO receiving path and current cash-custody PO branch must remain unchanged; add explicit Quick Market invoice-ID branch.
- No Buyer source or Production write was made. Report618 is a specification only; implementation still subject to exact change-set approval and E2E.
- Current status remains OPEN / NOT IMPLEMENTED / NOT PRODUCTION READY.

---

# LVE-2026-11-04-617 — SupplierReturn Recipient & Currency Surgical Patch

- Report617: [SupplierReturn recipient and currency surgical patch](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report617_SUPPLIER_RETURN_RECIPIENT_CURRENCY_SURGICAL_PATCH_20261104.md), latest update commit `a17a89f1e3e2846870773fdbc018597726dfe1e4`.
- New **P0 financial finding CONFIRMED**: Production `app_settings.currency=EGP`; Vouchers UI and `stock_vouchers.return_currency DEFAULT 'SAR'`; `save_supplier_return_contract` accepts/falls back to SAR without checking app_settings; `complete_manual_stock_voucher_atomic_core_20260828` and `purchase_post_return_atomic` have zero references to `return_currency`, so they post the numeric total directly into supplier ledger/GL. No SupplierReturn rows existed in the snapshot.
- Report617 prepares the surgical SupplierReturn recipient UI: add isolated `refs.buyers` (do not contaminate DirectSale/DirectReturn `refs.reps`), default Supplier Direct, Buyer Delegate exception, no vehicle, reuse existing `rep_id` argument to existing `create-stock-voucher` Edge v12, preserve Buyer selection on Draft edit, and show recipient in voucher list/details.
- Currency fix must resolve company currency from `app_settings` server-side in `save_supplier_return_contract`, remove SAR fallback/default, enforce it in Trigger and financial posting paths, and reject client mismatch.
- Report614 and Report615 were updated to mark the currency posting risk as CONFIRMED.
- No operational source or Production write, no test rows, no Edge deployment. Status remains patch preparation only.

---

# LVE-2026-11-04-616 — Receiver Surgical Patch + Buyer Custody Schema Draft

- Report616: [Receiver surgical patch and Buyer custody schema draft](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report616_RECEIVER_SURGICAL_PATCH_AND_BUYER_CUSTODY_SCHEMA_DRAFT_20261104.md), commit `95d8b6322754672ce0b415e5d24689a6a675de1c`.
- SQL draft: [01_buyer_goods_custody_schema_security_DRAFT.sql](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/Current/CTO/ChangeSets/20261104/01_buyer_goods_custody_schema_security_DRAFT.sql), commit `193fe7cfa6946b67903ecdf47e6f3abbadd098d8`.
- Report616 contains exact Receiver source patch for: select PO `id`; query detail rows by `po_id`; calculate remaining quantity using `qty_ordered - qty_received`; hide action on query failure/empty lines; use decimal-safe `Number` and input `step=0.001`.
- SQL draft contains additive schema scaffolding for buyer goods custody events, return acceptance batches, voucher recipient mode/issued quantities, Parent return linkage, invoice source/settlement, invoice-to-Receiving links, custody expense classification, append-only ledger trigger, RLS/least-privilege return table access and Realtime publication.
- Critical: SQL file is explicitly NOT a complete deployable migration. It omits full RPC/Trigger replacements and requires companion source changes, tests, rollback and exact owner approval. It was not executed.
- No operational source edit, Production schema/data write, Edge deployment, or test fixture was made. Status remains NOT IMPLEMENTED / NOT PRODUCTION READY.

---

# LVE-2026-11-04-615 — Buyer / Receiver / Quick Market / Return Security Revalidation

- Report: [Report615_BUYER_RECEIVER_SECURITY_QUICK_MARKET_REVALIDATION_20261104.md](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report615_BUYER_RECEIVER_SECURITY_QUICK_MARKET_REVALIDATION_20261104.md), commit `64e0988cf7bae218c3d1e7766c0ffe45136cff7e`.
- Starting operational HEAD remains `e8ab54c75572e15e71581212479d22be139c8020`; Buyer blob `311f2673a90149df6f56d59a9a187a3379e6981c`; Vouchers blob `85e709d0f41c189c6624a6160965d3b1a41960ba`; Receiver blob `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`.
- Read Report614, full 1,438-line Report614_NEW_P, Report606, Report610, Report613, CURRENT_STATE, Master CTO Governance and permanent operating charter. Owner's previously approved business rules remain binding; no clarification requested.
- CONFIRMED P0 Receiver defect: live `purchase_order_details` has `po_id`, not `po_code`, while Receiver queries by `po_code`. Resolve PO header ID then query details by `po_id`. Receiver also uses `parseInt` for numeric quantities, which truncates fractional units; switch to validated decimal `Number`.
- CONFIRMED P0 security gap: `anon` and `authenticated` have DML grants on `purchase_returns` and `purchase_return_details`; both have permissive PUBLIC ALL RLS policies scoped only to company. Restrict to SELECT for authorized roles; DML only via authorized Edge/RPC.
- CONFIRMED Quick Market gap: `buyer_custody_review_expense_atomic` requires a PO, PO-based Receiving, and supplier-ledger reference by PO code. It cannot settle a no-PO invoice. Preserve the PO path and add a separate invoice-ID Quick Market branch.
- CONFIRMED live `purchase_post_invoice_atomic` allows PO invoices only after completed Receiving; no-PO invoices are rejected with `PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED`. `purchase_create_invoice_atomic` correctly reads EGP from `app_settings`, rejects a client currency mismatch, and permits no-PO Draft invoices.
- Live Production snapshot: 3 purchase invoices / 6 lines; 1 Draft PO / 1 PO line; no Receiving headers/details; 0 SupplierReturn stock vouchers, 0 purchase_returns, 0 Buyer cash custodies, 0 Buyer custody expenses.
- Two historical no-PO invoices are Posted in SAR with matching PurchaseIn movement total 50, supplier ledger and PurchaseInvoice journals. Do not delete/rewrite/repost or retroconvert these posted historical transactions.
- One explicitly QA-labelled Draft PO/invoice pair has line qty 5 and received flags qty_received=5 / received_qty=5 but no Receiving docs, stock movement, supplier ledger, journal, payment allocation, return, expense, voucher or attachment. It has 4 purchase_document_links and 1 status-history row. Isolated QA artefact; recommended cancel/archive preserving links/history, not direct hard delete. No cleanup performed.
- Recovered and archived exact deployed Edge source snapshots (no deploy) under `Current/CTO/EdgeSnapshots/20261104/`: save-purchase-order v22 SHA `a0885a8a...`; receive-purchase v13 `50ab45ae...`; create-stock-voucher v12 `c4ee58c5...`; send-stock-voucher v20 `86412927...`; receive-stock-voucher v22 `62f6e979...`; complete-stock-voucher v4 `8cf68445...`. save-purchase-order v22 tracked source is byte-identical to live source.
- Competitive design references: D365 return PO supports invoice-referenced, partial, unplanned and consignment returns; SAP links return PO/outbound delivery/goods issue/vendor credit memo and inspection; Odoo two-step receiving separates supplier/input custody from available stock. See Report615 citations.
- No operational source or Production write, no DDL/RPC/Trigger/RLS/grant/publication change, no Edge deployment, no QA cleanup, no test rows, no Browser E2E or Cloudflare deploy.
- Status: diagnosis expanded; Buyer goods custody / Quick Market receipt / Parent recipient register still NOT IMPLEMENTED / NOT PRODUCTION READY. Next: exact single-writer SQL/RPC/Trigger and existing Edge/source patch package, including Receiver fix, least-privilege security, Quick Market invoice-ID receipt and currency-from-app_settings. Follow exact-change approval gate in Report614_NEW_P.

---

# LVE-2026-11-04-615 — Integrated Buyer Goods Custody / Supplier Return / Quick Market Change Set

- Report615: [BUYER_INTEGRATED_GOODS_CUSTODY_AND_SUPPLIER_RETURN_CHANGESET_20261104.md](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report615_BUYER_INTEGRATED_GOODS_CUSTODY_AND_SUPPLIER_RETURN_CHANGESET_20261104.md); latest report update commit `b133c9006591123e2c5e3e1f32e272547ad28c06`; blob `c5c2c710231c11a867e6f67f856adce3487c69f2`.
- Continues LVE614. Current operational HEAD observed `e8ab54c75572e15e71581212479d22be139c8020`; current Buyer/Vouchers/Receiver/Parent source fingerprints remain those recorded in LVE614.
- Historical owner decisions recovered from Report606: Supplier is the default recipient; only explicit supplier delegation permits Purchasing Officer custody; supplier balance reduces only for accepted quantities; Quick Market invoice must be receivable in Receiver by invoice number; vehicle is optional; cash purchases, operating expenses, Supplier Credit and actual Supplier Payment are separate.
- Competitor research revalidated from official Odoo, Microsoft Dynamics 365 and SAP documentation: internal/transit company-owned custody differs from external vendor transfer; partial receipt and return line marking are essential; inspection/quality holds and credit-note/receipt evidence separate physical return from financial settlement.
- Additional confirmed defects included in Report615: direct DML privileges for PUBLIC/anon/authenticated on purchase_returns and purchase_return_details; RLS ALL command therefore does not enforce Edge permission checks against direct writes. purchase_create_return_atomic lacks cumulative previous-return quantity guard. Receiver uses purchase_order_details.po_code although actual relation is po_id; parseInt truncates fractional quantities; all-zero receive can create a header; receive-purchase v13 is PO-only and fallback deterministic operation ID can collide across separate physical receipts with identical payload. SupplierReturn uses SAR UI/default while system currency EGP.
- One-writer design: purchase_returns remains the Parent financial return register; each new physical supplier return links to one stock_voucher. send_stock_voucher_atomic is the only branch stock-out writer. Append-only supplier-acceptance events own accepted quantity and Supplier AP/GL once. Delegated Buyer custody is separate from cash buyer_custodies; Buyer quick market has supplier-to-Buyer and Buyer-to-warehouse events.
- Buyer cash expenses use typed categories PURCHASE_CASH/FUEL/TRANSPORT/OTHER with approved COA account mapping. PURCHASE_CASH reconciles accepted Receiving against Employee Custody with no duplicate Supplier AP/Payment; operating expenses debit expense and credit Employee Custody; Supplier Credit remains AP; Treasury cash changes only on documented actual payment.
- Additional exact posting evidence: live receive_purchase_atomic posts PurchaseIn for accepted PO lines, creates Journal DR Inventory 124 / CR Supplier AP 211 and Supplier Ledger credit. The existing cash-custody review subsequently settles that AP with DR Supplier AP / CR Employee Custody, creates a payment row and debits supplier_ledger; this is a Supplier Credit settlement writer, not a generic expense routine. Quick Market EMPLOYEE_CUSTODY_CASH must instead use DR Inventory / CR Employee Custody after accepted receipt, with no AP or supplier ledger duplication. It updates PO qty_received/status but receiving header/details have no invoice FK. Therefore Quick Market EMPLOYEE_CUSTODY_CASH must not use the PO AP posting block; it must post inventory against Employee Custody and avoid Supplier AP/Supplier Ledger duplication. buyer_custody_review_expense_atomic currently settles a PO invoice with Journal DR Supplier AP / CR Employee Custody, creates buyer_custody_payments, marks invoice Paid and debits Supplier Ledger; it is not a generic expense routine. Manual SupplierReturn completion also reverses tax per tax code for the full amount; Parent purchase_post_return_atomic has a separate untaxed simplistic line path. Unified acceptance must reverse tax only on accepted quantity. Supplier refund/credit disposition for cash-paid goods requires a Finance account mapping; none confirmed, so do not debit nonexistent AP or book cash without evidence.
- Exact live Edge versions/hashes and source-parity gaps are listed in Report615. No new Edge Function proposed. Live Edge source files other than save-purchase-order are missing from matching operational Git paths; recover exact source before any future edit.
- Governance: no main.html write; no Production write before the exact full migration/RPC/Trigger/Edge/app change set has been shown and explicitly approved under §77.2; no new Edge function.
- LVE615 work performed: research, forensic source/Production/ACL/Storage/Realtime inspection and integrated change-set design documented in Report615. No operational source write, no SQL/DDL/DML, no ACL/RLS/Trigger/RPC/Edge deployment, no test fixture and no Cloudflare action.
- Current status: ROOT CAUSES CONFIRMED / TARGET DESIGN DOCUMENTED / FULL EXECUTABLE IMPLEMENTATION BUNDLE NOT YET AUTHORED / NOT IMPLEMENTED / NOT PRODUCTION READY. Next exact task: author the full executable additive migration and replacement function bodies, restore all deployed Edge source files into Git byte-for-byte, prepare exact Buyer/Vouchers/Receiver diffs and owner-side Parent patch, plus complete test/rollback suite.

---

# LVE-2026-11-04-614 — Buyer Goods Custody / Supplier Return / Quick Market Receipt

- Review report: [Report614_BUYER_GOODS_CUSTODY_RETURN_RECONCILIATION_20261104.md](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report614_BUYER_GOODS_CUSTODY_RETURN_RECONCILIATION_20261104.md), created at commit `8ee6889e33e671c7996a73e55560e3163a0cfb60`.
- Starting point: LVE613 / Report613. Latest operational repository HEAD observed: `e8ab54c75572e15e71581212479d22be139c8020`; Buyer blob `311f2673a90149df6f56d59a9a187a3379e6981c`; Parent blob `f6ec4ab41dc517f86e17dd3d74a9d5f8add264ca`; Warehouse Vouchers blob `85e709d0f41c189c6624a6160965d3b1a41960ba`; Receiver blob `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`.
- Read current permanent charter `الدستور التشغيلي الدائم.md` blob `d2afa896514b1cb6abd247d2af7a862251ce0604`, latest Master CTO operational protocol and Master CTO Governance §77.2–77.4.
- CONFIRMED: Buyer tab `رصيدي` is a static placeholder, not a live quantity ledger. `quickPurchase()` is only an alias to create a Draft invoice. Buyer Realtime does not subscribe to a goods custody ledger or SupplierReturn voucher stream.
- CONFIRMED: `buyer_custodies` and its dependent tables are cash custody, not goods custody. Production has no separate item-level Buyer custody ledger.
- CONFIRMED: Warehouse `SupplierReturn` UI only selects Branch and Supplier; no Purchasing Officer recipient picker. The deployed Trigger `enforce_stock_voucher_custodian()` clears `custodian_user_id` except DirectSale/DirectReturn; mobile-sales vehicle/rep rules must remain unchanged.
- CONFIRMED: Warehouse manual SupplierReturn sends branch stock out at send; its completion path writes supplier payable reduction and GL for full return amount. It has no Buyer intermediate-custody stage or supplier accepted-quantity model.
- CONFIRMED: Parent purchase-cycle `purchase_returns` is a second independent stock/AP/GL writer through `purchase_post_return_atomic`; there is no unique link between `purchase_returns` and `stock_vouchers`. Risk: duplicate stock and supplier balance reduction if both paths post the same goods.
- CONFIRMED: Quick invoice can be created Draft with PO optional, but the deployed `receive-purchase` v13 contract requires PO code and the current `receiving`/details schema has no invoice/line FK. Quick Market → Buyer custody → Receiver acceptance is not currently supported end to end.
- Current read-only Production counts for `stock_vouchers`, `purchase_returns`, `inventory_log.SupplierReturn`, and `buyer_custodies` were all zero at the review snapshot. No test rows or production data changes were made.
- Additional CONFIRMED finding: Warehouse Vouchers SupplierReturn contract UI hardcodes `currency:'SAR'` in the initial draft and submit payload; Production `app_settings.currency=EGP`, and `stock_vouchers.return_currency` has `DEFAULT 'SAR'`. Actual financial posting/conversion impact remains UNVERIFIED; all relevant return row counts were zero.
- Proposed target: append-only item-level Buyer goods custody ledger separate from cash custody; movements include Warehouse→Buyer, Supplier→Buyer (quick purchase), Buyer→Warehouse accepted, Buyer→Supplier accepted, direct Supplier receipt and compensating corrections. Optional vehicle metadata only.
- Return single-writer proposal: Warehouse voucher owns physical branch stock-out; one linked financial SupplierReturn record owns AP/GL only after supplier acceptance; the linked financial posting must not issue stock again. Final canonical header/link model and accepted-quantity fields still need exact changeset.
- Parent Returns register should display a real recipient: validated Buyer custodian when held, otherwise Supplier for direct receipt. Parent currently reads only `purchase_returns`; current governance §77.3 prohibits editing `main.html`, so that UI patch is blocked unless the governing rule changes or an approved alternative exists.
- No operational HTML, SQL, migration, RPC, Trigger, RLS, Edge Function, data, or deployment change was made. No new Edge Function created. No authenticated Browser E2E or Cloudflare artifact verification. Staging remains schema-non-parity per LVE613.
- Status: forensic root causes confirmed / design proposed / implementation NOT STARTED / Buyer procurement NOT PRODUCTION READY. Next step: prepare the exact additive SQL, RPC/Trigger bodies, existing Edge-source diffs, Buyer/Vouchers/Receiver patches, Parent owner-side patch proposal, test matrix and rollback; then submit that exact set for explicit approval under §77.2 before any operational write.

---

## LVE-2026-11-04-612 — Shared-Core Centralization Application Matrix

- Report: [Report612_CORE_CENTRALIZATION_FORENSIC_APPLICATION_MATRIX_20261104.md](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report612_CORE_CENTRALIZATION_FORENSIC_APPLICATION_MATRIX_20261104.md); report commit `9cc489a7171a3e1675500488767a99d3a07cfcfa`.
- Operational repo `papamohammed77-glitch/erp-frontend` / main / HEAD `68d222b20251049daddc2f159f2b8c80cd6ffb89`; Core blob `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`.
- Complete inventory: 30 HTML files under companies/company-1; 26 load core.js. Three operational entry/app files do not: main.html, warehouse/picker.html, app.html. index.html is static navigation and is exempt.
- main.html independent: 178 direct Supabase table-query references, 75 Auth references, 61 RPC references, 68 functions/v1 references, 11 channel declarations and 39 postgres_changes references. Its internal RW_* modules are distinct from shared Core.
- picker.html owns independent Supabase client/Auth, four raw Edge fetch call sites, Dexie and service-worker code. app.html owns independent client/login/password recovery/session/role routing.
- Buyer is current closest Core-aligned PWA: RW_Auth/API/UI/Realtime; no direct table/RPC/channel/fetch call sites in current Buyer source. This does not imply business/Runtime closure; LVE611 remains open.
- Core's RW_DB is a Dexie/local-store wrapper exposing getDB/syncDown/syncUp/getItems/getCustomers/getBranches, not a comprehensive server repository. RW_API exposes Edge call/callWithRetry only, not an RPC contract. RW_Realtime is adopted by six apps; Parent/Sales Manager/Vouchers have independent channels and Core defaults to INSERT/UPDATE.
- Driver is high-risk hybrid: uses user_metadata for permission derivation, direct users/credit_block_events/service_complaints/driver_liabilities DML and four raw Edge fetches. Review authoritative effective profile, server policies, and single-writer paths; this is not by itself proof of a live exploit.
- Returns has direct run_sheet_details.qty_returned update alongside the Edge return flow; reconcile its authoritative writer before changing.
- Many Core-loaded pages still query Supabase or call RPC directly. See Report612 for the full 30-file matrix and per-app reference counts/patterns.
- Public Storefront/Tracking must use shared public API contracts without employee Auth.
- Target Core: versioned bootstrap/injected page-local client, RW_Auth+verified RW_Context, RW_API+RW_RPC, RW_Data, RW_Realtime, RW_Offline, RW_SW, RW_UI and observability. Keep apps separate; preserve RLS and existing Edge/RPC business writers. Do not add new Edge functions just for wrappers.
- No operational source, Production DB, RPC/RLS/GRANTS/Edge or deployment changes in LVE612.
- Next: exact Core bootstrap/compatibility/API/RPC/Data owner-review package. Never blindly add core.js to main.html/app.html because client/global initialization must be reconciled first. Migrate Picker and Parent incrementally after approval. CURRENT_STATE advanced to LVE612.

---

## LVE-2026-11-04-611 — Buyer / Parent / Core / Receiving Revalidation

- Report: [Report611_BUYER_PARENT_CORE_RECEIVING_RUNTIME_REVALIDATION_20261104.md](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report611_BUYER_PARENT_CORE_RECEIVING_RUNTIME_REVALIDATION_20261104.md); report commit `c2ae71d778a65679afb7d55358606b763901fac7`.
- Operational repo `papamohammed77-glitch/erp-frontend`, branch `main`, HEAD `68d222b20251049daddc2f159f2b8c80cd6ffb89`, three commits ahead of LVE610 HEAD `2b94681bf0ce93ca9ea55066a3f52c0d1add1084`.
- Buyer blob `311f2673a90149df6f56d59a9a187a3379e6981c`; Parent main blob `53b5a9e9d0433a785c3d5471a9c0d68c25497882`; Core blob `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`; Receiver blob `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`.
- Buyer new creator/branch/receipt/currency filters and camera barcode work are in source at current HEAD; browser/camera behavior remains UNVERIFIED.
- Core is used by Buyer/Receiver/Loader, but Parent main, Picker and app.html use direct Supabase/Auth/Realtime paths. The ERP is not fully centralized through Core; centralization is partial/mixed.
- Parent `RW_PurchaseGold.ensurePurchaseRealtime()` subscribes to purchase_invoices but not purchase_orders; Production purchase_orders is in supabase_realtime publication. Parent PO live refresh gap is source-confirmed; runtime event delivery UNVERIFIED.
- Buyer/Parent list retrieval caps remain 500/300 without a complete pagination contract. Parent Purchase Settings edits `purchase_settings.default_currency`, while central PO/Invoice writers use `app_settings.currency`; current values both EGP, but independently editable settings create source-of-truth conflict.
- SMART ERP Production: PostgreSQL 17.6.1.121, 737 migrations. Edge `save-purchase-order` v22 active/JWT and byte-identical to operational Git; `receive-purchase` v13 active/JWT but its source file remains absent from operational Git.
- **CONFIRMED P1:** active `receive_purchase_atomic` can create Receiving header and change PO status for an all-zero receipt: Edge permits zero, RPC skips `received_qty<=0` rows after inserting Receiving, lacks a post-loop positive-total guard, then updates PO and audit log. No Production write probe was run.
- Receiver still uses `po_code` for PO detail lookup while Production detail schema uses `po_id`; uses parseInt; no branch filter in PO list; does not send operation_id. Edge fallback deterministic UUID based on identical payload can collide for distinct physical receipt events.
- Production current sample: PO=1, invoices=3, invoice details=6, receiving headers/details=0. QA PO `QA-SR-PO-20260927` is Draft EGP but qty_received=5; linked QA invoice is Draft SAR, is_received=true, received_date NULL, detail qty/received_qty 5; no Receiving evidence. This is a confirmed metadata inconsistency; actual physical handover remains UNKNOWN. Do not mutate/delete these records without reconciliation and approval.
- Staging `rawaea-staging` has 62 migrations, lacks purchase_invoices, purchase_invoice_details and buyer_custodies; full Buyer E2E unavailable there.
- Cloudflare Pages check on HEAD 68d222b: rawaea-erp Preview deploy success at `https://61aedb51.rawaea-erp.pages.dev`; warehouse-supervisor, rawaea-store and erp-frontend checks failed. Canonical Production artifact parity and authenticated Runtime/E2E remain UNVERIFIED.
- No operational source/Core/Parent/Buyer/Receiver changes, no Production DDL/data/RPC/RLS/Edge changes, no deployment, and no test fixtures were created in LVE611.
- Next: exact owner-review Change Set for zero-receipt guard, per-physical-event idempotency, Receiver po_id/decimal/branch contract and tests. Must follow Master CTO §77.2; wait for explicit approval before source/Production changes. LVE611 state checkpoint recorded in CURRENT_STATE.md; buyer/receiver remains open and not Production Ready.

---

## LVE-2026-11-04-610 — Buyer PO/Invoice UX, Parent Cycle Integration, Creator, Currency & Barcode

- Operational main HEAD 2b94681bf0ce93ca9ea55066a3f52c0d1add1084; Buyer blob 7f82fceb0b2c2470d1f112aefeaa1341de5b71a8; Parent main blob 53b5a9e9d0433a785c3d5471a9c0d68c25497882.
- Buyer and Parent use the same purchase_orders/details and purchase_invoices/details via existing central Edge/RPC writers. No mirrored procurement tables are required.
- Creator is already stored as authenticated actor email in created_by for both PO and Invoice; show it as a column rather than adding a redundant DB field. Parent should retain company/permission-scoped visibility; do not filter to current creator.
- New document currency is server-derived from app_settings.currency; current value EGP. purchase_settings.default_currency is separately editable and can drift; make Parent Purchase Settings currency display read-only from app_settings, do not delete old column or convert historical documents. Existing three invoices in snapshot include one Draft SAR and two Posted SAR; preserve their document currency.
- Parent orders list lacks creator/currency/date/branch and Parent invoices list shows supplier UUID; Parent Realtime subscribes to invoices but not purchase_orders. Buyer PO list uses one session currency for rows; invoice list has no currency column. Edge GET_DATA max 500 / no offset, Parent getData limit 300.
- Buyer has no camera scanner in PO/Invoice inputs. Parent inventory scanner pattern is getUserMedia + BarcodeDetector, rear camera, formats EAN-13/EAN-8/Code128/Code39/UPC-A/UPC-E/QR, 350ms scan loop and cleanup; adapt as Buyer-owned helper, never call RW_Warehouse in isolated PWA.
- Cloudflare Pages check for HEAD 2b94681 succeeded 2026-11-04 11:26:14 UTC; automatic deployment check passed, but served blob/runtime parity remains unverified.
- Report610 doc/Draft/Reprots/Report610_BUYER_PO_INVOICE_PARENT_CYCLE_UX_CURRENCY_BARCODE_FORENSIC_20261104.md, blob e88c15586a9a37025b04924b8b6553aa7fcfa5b2, commit db82d92f45e6b122000453cacdf01382f9035c93.
- No operational Buyer/Parent/Core writes, no SQL/RPC/ACL/Edge/deployment change, no fixtures or authenticated E2E. Staging remains schema-misaligned.
- Exact Change Set 610 is prepared; explicit owner approval required under Master CTO §77.2 before source/Parent/gateway writes. Do not create Edge functions or duplicate tables.

---

## LVE-2026-11-03-609 — Buyer / Receiver Production Reconciliation (2026-11-03 23:30 Cairo)

**Evidence report:** doc/Draft/Reprots/Report609_BUYER_RECEIVER_PRODUCTION_RECONCILIATION_20261103.md  
**Report commit:** 84fb16856c030963766b63cbf8418e00e9e927c7  
**CURRENT_STATE commit:** 5635e8ed98d1b74ffa689ebf88bd9409be8ff210

- Re-read CURRENT_STATE first. At start it was LVE607; Report608 existed but had not been reflected in CURRENT_STATE. LVE609 now reconciles this.
- Operational main HEAD remains 2b94681bf0ce93ca9ea55066a3f52c0d1add1084. Buyer/Receiver/Core blobs: 7f82fceb0b2c2470d1f112aefeaa1341de5b71a8 / 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6 / f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1.
- Production SMART ERP: ACTIVE_HEALTHY, PostgreSQL 17.6.1.121, 737 migrations. save-purchase-order v22 is byte-identical to Git; receive-purchase v13 is active/verify_jwt=true but its exact source is absent from operational Git. Governance snapshot is older; do not deploy it.
- Receiver defects reconfirmed: purchase_order_details lookup uses po_code although Production schema only has po_id; errors are not surfaced; parseInt truncates decimals; UI does not read qty_received/remaining_qty; max is full qty_ordered; zero is allowed; branch list is not filtered; no operation_id is sent.
- receive-purchase v13 derives deterministic operation_id from user/company/PO/payload when the client sends none. This collapses two independent physical receipts with identical payloads. RPC fingerprint includes item_code/received_qty only.
- receive_purchase_atomic v5 is service_role-only and enforces company/user/role/branch, but all-zero non-empty items can still create a completed receiving header and mark PO Partially Received without details or stock/GL/AP. RPC expected/difference is compared with full original PO quantity on each receipt.
- receiving and receiving_details have no purchase_invoice_id / purchase_invoice_detail_id. Quick Market Invoice can be created Draft without PO but cannot be posted without a receipt contract. Cash-vs-credit accounting route remains unapproved; do not reuse PO AP path blindly.
- RLS read-scope mismatch: PO/Invoices are company SELECT, not branch/permission scoped. receiving self-read compares responsible to users.name while RPC stores email; current_user_has_permission does not include role_permissions. receiving tables have broad anon/auth DML GRANTS but only SELECT RLS policies.
- Production data: 1 Draft PO; 3 invoices/6 details; no receiving, attachments, payments or Buyer Custody rows. PINV-1000/1001 are historical Posted no-PO SAR invoices totaling 3,970 with 50 PurchaseIn units, supplier-ledger credits 3,970 and two Posted journals; paid_amount=0. Do not reverse without Finance/Owner review.
- QA-SR PO/Invoice is inconsistent (PO Draft EGP, qty_received=5; invoice Draft SAR, is_received=true, received_date NULL, no receiving). Four document links point to two missing stock_voucher rows; provenance unknown. Do not delete/repair.
- Migration lineage conflict: Production versions 20261102150516/20261102151137 versus operational Git filename prefixes 20261102160000/20261102162000; function bodies match. No db push until reconciled.
- Staging has 62 migrations/70 public tables and lacks invoice/custody tables; not valid for full B E2E.
- Cloudflare Pages check for HEAD 2b94681 failed at 19:16:47Z; parent 5d7b10e succeeded at 18:58:49Z. Served artifact/runtime remain UNVERIFIED.
- Report608's Production rollback test is corroborated by logs: two purchase_create_po_atomic write transactions ended with ROLLBACK; no residual operation/audit/status rows. Report608 records no owner approval; do not repeat Production write tests. LVE609 used read-only Production queries only.
- Next: prepare exact Change Set B approval package, restore exact live v13 source to operational Git only after approval, fix Receiver contract/quantity/idempotency/branch scope, design invoice-linked receiving and cash-vs-credit accounting, reconcile migration lineage, and diagnose Cloudflare failure. No source/Production/deployment changes before explicit owner approval under Master CTO §77.2.

---

## LVE-607 — 2026-11-03 — Buyer Source Update

Operational main HEAD: `2b94681bf0ce93ca9ea55066a3f52c0d1add1084` (parent `5d7b10e4fd0fdf1bb2299c87805f9c86d381cc35`; CSS build only, Buyer blob unchanged); Buyer blob: `7f82fceb0b2c2470d1f112aefeaa1341de5b71a8`. Buyer supplier master is now read-only; no SAVE_SUPPLIER call remains; active-only supplier selection is enforced, without equating is_active to formal approval. The vehicle tab is now «رصيدي» and no longer reads Fleet; no goods custody ledger exists yet. No DB, Edge, Parent, Receiver, or Production changes; B–E and E2E remain open. Report607: `doc/Draft/Reprots/Report607_BUYER_SAFE_SOURCE_EXECUTION_MASTER_SUPPLIER_AND_GOODS_CUSTODY_20261103.md`; checkpoint LVE-607 in CURRENT_STATE.md.

---

## LVE-603 — 2026-11-03 — Buyer Cumulative Return Integrity & Supplier Acceptance

- Revalidated operational Git: erp-frontend/main HEAD 743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c, parent 2ce93c6d80ec4c38353bdf88880d06ae9e0abdde. Buyer blob aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc; Core f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1; Receiver 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6.
- Production schema confirms purchase_create_return_atomic compares each return detail qty only against original purchase_invoice_details.received_qty; it does not subtract earlier returns. A separate operation_id can therefore create another return against the same original received quantity. purchase_post_return_atomic applies SupplierReturn stock movement, debits supplier AP 211, credits inventory 124, inserts supplier_ledger debit, and marks Posted.
- purchase_returns/details have no returned_qty/accepted_qty or cumulative-return trigger. Their current constraints do not enforce aggregate limits. Header triggers are only status history and updated_at.
- Production currently has purchase_returns=0 and purchase_return_details=0; no existing production over-return rows evidenced.
- Direct DML to purchase_returns/details remains granted to authenticated (and anon grants also exist) with RLS ALL scoped by company only. This does not enforce purchasing/finance RBAC. Actual anonymous policy bypass remains unverified.
- Supplier acceptance/partial acceptance is missing from the return schema and posting RPC. Physical supplier acceptance must precede SupplierReturn stock/AP posting; model separately from warehouse release to buyer vehicle and actual supplier handover.
- Prior central controls already applied: invoice table writer boundary 20261103155029; receiver role/branch authorization 20261103155444; custody cash disbursement requires assigned employee acknowledgement 20261103160902. Do not repeat.
- Buyer issueCustody text/toast at lines 870/880 contradict acknowledgement-gated Production behavior; acknowledgeCustody lines 907–910 lacks a clear user confirmation step. Owner patch in Report603 §10; not applied by assistant.
- quickPurchase at line 762 is only an alias to createPurchaseInvoice; Receiver remains PO-only; no separate purchasing vehicle goods custody ledger; expense table lacks PURCHASE/FUEL/TRANSPORT/OTHER types and mapping; settlement has no dedicated cash return proof attachment fields.
- Report603: doc/Draft/Reprots/Report603_BUYER_RETURN_INTEGRITY_DEPLOYMENT_RECHECK_AND_CHANGE_GATE_20261103.md; commit 7e9fe3e7be50e61d6e71145a6b2bffbdd63b3254.
- No Production writes, DDL/ACL changes, source HTML edits, Edge deployments, test fixtures or authenticated E2E were performed. P0-D requires exact owner approval after external consumer review per Master CTO §77.2. P0-R cumulative guard + supplier acceptance requires its own approved design/SQL. Cloudflare snapshot is older than current HEAD; current artifact and runtime remain UNKNOWN/UNVERIFIED.

---

## LVE-602 — 2026-11-03 — Buyer Return ACL & Physical Procurement Workflow

- Operational repo `papamohammed77-glitch/erp-frontend/main` HEAD `743c9b170bf2314a9e4d64fd4d8104f2cc1aee8c`; parent `2ce93c6d80ec4c38353bdf88880d06ae9e0abdde`.
- Current Buyer blob: `aee14e6a4edbccd5fb95dff24f21daf1c6d21fcc`; core.js `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`; Receiver `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`.
- P0 controls already present in Production and current migrations: invoice-table central writer (20261103155029), receive PO role/branch guard (20261103155444; receive-purchase v13), and custody cash movement only after employee acknowledgement (20261103160902). Do not repeat.
- save-purchase-order v22 and receive-purchase v13 are active, JWT-protected; no new Edge Function is needed or authorized.
- Confirmed return-table privilege gap: purchase_returns and purchase_return_details grant client DML to anon/authenticated and retain company-scoped ALL RLS policies. Current 34-file company-1 HTML/JS scan found no direct DML consumer, but external consumers remain unknown.
- purchase_post_return_atomic (service_role only) posts SupplierReturn stock-out, Dr Supplier AP / Cr Inventory, and supplier_ledger debit without an explicit supplier-acceptance event inside the RPC.
- Buyer issueCustody UI at lines 870/880 incorrectly states that cash/GL posted on issue; backend waits for employee acknowledgement. Surgical text and acknowledgement confirmation replacement are prepared in Report602, not yet applied.
- quickPurchase() still aliases createPurchaseInvoice(); Receiver remains PO-only; vehicle tab reads Fleet driver assignment and displays Buyer goods custody ledger as not implemented. No Purchasing Vehicle Goods Custody ledger exists in the inspected schema.
- Production snapshot: invoices 3; returns 0; all buyer custody rows 0; receiving 0; Fleet assignments 0; vehicles 2; inventory_log 76; supplier_ledger 2; journal_entries 19; cash_box 8. App currency EGP.
- No source/Production mutations, no fixtures, no Edge/Cloudflare deploy, and no authenticated E2E this cycle. Cloudflare served-blob parity and runtime remain UNVERIFIED.
- Exact P0-D revocation/SELECT-only policy change is documented in Report602; not applied pending explicit owner approval for the exact change and external consumer review. Market purchase, vehicle custody, supplier return acceptance, and expense categories remain open.
- Report: `doc/Draft/Reprots/Report602_BUYER_CURRENT_SOURCE_PRODUCTION_FORENSIC_AND_CHANGESET_20261103.md` (commit 25b991849fb2d7c9fea28cff0e68962dcf34a50d; blob af43e480f35c72fbc5093a6607c36b4ea16747eb).
- Current state: LVE-602 at top of `CURRENT_STATE.md`, commit bc6dd6a42311a599123314adf1a3d6a4772f5f99; blob 18964899b45250a3bf92bec32d730b6457c1e199.
- Next: check external return-table consumers; present P0-D for exact owner approval; then design Quick Market Purchase + independent goods custody + Supplier Return Acceptance through existing gateways only.

---

## LVE-599 — 2026-11-03 — Procurement Receiving/Invoice/Payment/Return Flow

- purchase_create_invoice_atomic_v2 creates Draft only.
- receive_purchase_atomic (5 args) requires operation_id + payload fingerprint; locks PO/details, validates remaining qty, posts PurchaseIn, increments qty_received/PO status, creates Dr Inventory 124 / Cr Supplier 211 journal and supplier_ledger credit.
- receive-purchase Edge v12 and RPC do not enforce warehouse/receiver permission; carried forward from LVE-590.
- purchase_post_invoice_atomic for PO invoices requires receiving, validates qty against received minus prior invoices, price/tax/total against PO, then marks Posted with stock_posted_by_invoice=false and supplier_liability_posted_by_invoice=false (no duplicate stock/AP).
- Quick invoice without PO is rejected (PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED); owner policy required.
- purchase_post_payment_atomic posts cash payment, allocations, invoice paid status, supplier_ledger debit.
- purchase_post_return_atomic posts SupplierReturn stock-out, Dr Supplier/Cr Inventory, supplier_ledger debit.
- purchase_update_draft_invoice_atomic prevents editing after receiving/payment/posting/downstream references.
- Accounting policy question: GRN currently recognizes supplier liability directly to account 211 and supplier_ledger; decide whether this is intended AP or should use GRNI/GRIR clearing; do not change without accountant/owner.
- No PO/receipt/invoice/payment/return operation, no source/DB/Edge/deployment change.
- Report: doc/Draft/Reprots/Report599_CTO_PROCUREMENT_RECEIVING_INVOICE_PAYMENT_ACCOUNTING_FLOW_20261103.md. Report commit 880865555fa24e89e6548270163b884d2679eccc. CURRENT_STATE commit c26f7fa3ac6514a5643aada4c78f6e98a2d24cb9.
- Next: owner decisions on quick market purchase and GRNI/AP policy, then receiving authorization and isolated E2E.

---

## LVE-598 — 2026-11-03 — POS Invoice Decision Gate

- save-sales-invoice v19 accepts effective pos/van-sales/orders permission; save_sales_invoice_atomic requires operation_id and calls sales_decision_engine_atomic(VALIDATE_ORDER) for Invoiced.
- Successful POS/Van Sales invoice source flow posts POSSale/VanSale stock movement, revenue/COGS journals, cash receipt for cash, customer ledger for credit, driver ledger for Van credit; POS cash requires active shift/terminal/treasury mapping.
- POS UI persists _activeCheckoutOperationId and queues pending updates in IndexedDB; preserves key after failure.
- sales_decision_actor_ok(p_write=true) accepts only direct *, sales_manager, general_manager. sales_decision_engine_atomic uses it for VALIDATE_ORDER, not only policy management.
- Current active POS user has direct pos permission but no *, sales_manager, general_manager; read-only helper evaluation returns false. Edge passes user, DB decision helper denies. Current POS authorization conflict CONFIRMED; runtime invoice failure untested.
- Historical Production has 5 POS orders by cashier between Oct 10–18 with linked decision evaluations ALLOW. Current helper denies; audit log does not record permission changes. Cause UNKNOWN (permission or function change).
- No invoice/stock/cash/journal/ledger mutation; no code/DB/Edge/PR/deployment change.
- Report: doc/Draft/Reprots/Report598_CTO_POS_INVOICE_DECISION_GATE_AND_ACCOUNTING_FLOW_AUDIT_20261103.md. Report commit 52e3771546f5d759e469ca1f67b89869463dad52. CURRENT_STATE commit 6cecc5c01cb53655093866310ed38b716ef5c263.
- Next: split Sales Decision policy management (manager-only) from VALIDATE_ORDER (operational pos/van-sales/orders) while preserving approval rules; owner approval required.

---

## LVE-597 — 2026-11-03 — HR & Fleet Domain Architecture

- Parent main.html calls save-employee v10 and delete-employee v4.
- save-employee validates actor/company/users permission or real Owner, role exists, wildcard restrictions, branch scope, updates Auth + users with audit and rollback.
- delete-employee deactivates/ban Auth, protects owner/self, preserves history.
- hr_command_atomic (SECURITY DEFINER, authenticated/service_role EXECUTE) validates actor identity/company, HR permission or self-service/approver scope, operation_id and hr_command_log payload-hash idempotency. Commands cover profile/org/contracts/schedules/attendance/leave/requests/advances/payroll/documents.
- hr_command_log_enforce_actor_identity enforces actor email/company.
- hr_user_has_permission checks users.permissions + roles.permissions, not role_permissions; no current role_permissions key hr found.
- fleet_command_atomic and fleet_query (SECURITY DEFINER, authenticated/service_role EXECUTE) validate actor/company. fleet_command_atomic requires operation_id and erp_operation_registry payload conflict; 18 commands cover vehicles/drivers/docs/contracts/assignments/odometer/fuel/maintenance/incidents/performance/expenses/Runsheet assignment/status.
- Fleet core permissions include fleet.manage or manager roles; operational commands allow scoped warehouse/delivery/van-sales roles. fleet_query has read permissions/roles.
- Fleet uses direct users.permissions and explicit role names, not full role_permissions union; current General Manager explicitly allowed by role name.
- No HR/Fleet mutation or E2E. No source/DB/Edge/PR/deployment change.
- Report: doc/Draft/Reprots/Report597_CTO_HR_AND_FLEET_DOMAIN_ARCHITECTURE_AUDIT_20261103.md. Report commit c78e430d9cc8cf69ced60a6a28f7e2fa68d8c0fb. CURRENT_STATE commit 93969ab73c593640d8f2fc7ee4cec6d5c45c2bc0.
- Next: reuse HR/Fleet command patterns in Warehouse/Delivery/Finance fixes; no parallel executor or permission engine.

---

## LVE-596 — 2026-11-03 — Public Storefront Checkout & Pricing

- submit-online-order v11 supports Guest Checkout intentionally with verify_jwt=false but requires published storefront_key and maps to company_id.
- submit_online_order_atomic calls resolve_sales_pricing_atomic; authoritative price comes from items.sales_price/commercial rules/promotions, not client cart price.
- Store UI persists operation_id by payload fingerprint in localStorage and sends it in body and Idempotency-Key header.
- Online order is Pending; submit path does not deduct/reserve stock. Availability policy UNKNOWN: checks store_display_qty/max_qty_per_order, not stock_branches.available_qty.
- Public guest path finds existing customer by phone and updates name/area without OTP/phone ownership proof, then uses customer_id in pricing resolver. Customer identity/master-data risk CONFIRMED at source contract; actual misuse UNVERIFIED.
- Edge generates random operation_id if client omits one; retry stability depends on current client behavior. RPC returns existing order for same operation_id without payload-hash conflict detection.
- No order/customer mutation, HTTP tampering test, Browser E2E, source/DB/Edge/PR/deployment change.
- Report: doc/Draft/Reprots/Report596_CTO_ONLINE_STOREFRONT_PUBLIC_CHECKOUT_AND_PRICING_AUDIT_20261103.md. Report commit 2ed1a7c179c57acad821102e1a50ab58d91fcb90. CURRENT_STATE commit 4e4f35b4695065525f1c3d50577946c5d1e5433e.
- Next: owner decisions on guest identity/OTP, customer master update, customer-specific pricing, and available-stock policy.

---

## LVE-595 — 2026-11-03 — CTO Architecture & Operating Map

- Consolidated the architecture from live source and Production: Parent ERP + 27 standalone PWAs + core.js + Supabase central DB/Edge/RPC + Cloudflare frontend hosting.
- Current app repo main HEAD 7a14d51b4d4c225240b215879abf6b77b99888d3. 30 HTML files (index/app/main + 27 PWAs); core.js 1,008 lines/7 modules; main.html 33,358 lines/46 RW_ modules/1,016 functions/48 literal table refs/41 RPC refs/48 Edge refs.
- Production: 186 public tables, 297 public functions, 186 RLS-enabled tables, 247 policies, 304 triggers, 734 migrations, 100 Edge Functions.
- Table/function domain map consolidated in Report595: sales, procurement, inventory, warehouse, delivery, finance, HR, fleet, POS, loyalty, promotions, installments, commissions, assets, budgets, workflows, notifications and audit.
- Critical open findings carried forward: LVE-589 procurement invoice RLS/Receiver/purchase-pos; LVE-590 warehouse/delivery/settlement permissions and vehicle stock; LVE-591 finance authorization; LVE-592 confirm-order/Runsheet permissions; LVE-593 stock voucher/van setup/customer is_owner schema; LVE-594 effective permission and Sales Quotes role mismatch.
- No source, DB, Edge, PR, or deployment mutation.
- Report: doc/Draft/Reprots/Report595_RAWAEA_ERP_CTO_ARCHITECTURE_AND_OPERATING_MAP_20261103.md. Report commit 1fe2b9e2d96c54a6290f2086651aac6d88158a19. CURRENT_STATE commit 4c562181f0573c155faf7bd5c1b178ce9dc436ae.
- Phase 1 advanced but not complete. Remaining: full Edge/RPC consumer/data-effect graph, migration lineage, Staging parity, served Cloudflare artifact, safe E2E. Do not issue completion signal until these are resolved or explicitly bounded by owner.

---

## LVE-594 — 2026-11-03 — Effective Permission Model & User Schema

- public.get_my_effective_profile() SECURITY DEFINER unions users.permissions, roles.permissions, role_permissions.permission_key; isOwner is derived from auth metadata + owner_profile + wildcard. public.users has no is_owner.
- No trigger syncs role permissions into users.permissions; only roles updated_at trigger exists.
- Active System Manager has users.permissions=["*"].
- Active General Manager direct permissions omit finance/orders/pos/purchases/warehouse, but role_permissions adds those keys and get_my_effective_profile includes them.
- rawaea_quote_actor_ok checks direct users.permissions for * or orders; therefore General Manager's effective orders permission is not recognized. Source/DB conflict confirmed; runtime denial untested.
- Sales-return checks return directly (present), sales-target checks general_manager directly (present); do not overgeneralize.
- Correction: save-customer v4/delete-customer v3 select public.users.is_owner, absent in Production; helper returns derived isOwner. Source/schema conflict confirmed; runtime untested.
- No role/user permission data or source/DB changes.
- Report: doc/Draft/Reprots/Report594_CTO_EFFECTIVE_PERMISSION_MODEL_AND_USER_SCHEMA_RECONCILIATION_20261103.md. Report commit 47031788182e8d1be33a29ae6b0c8e1c7e7fb922. CURRENT_STATE commit 2cffe5bdf5a259a717fafd745ffd251e550e187b.
- Next: reconcile direct-permission consumers with get_my_effective_profile, starting with sales quotes and customer actor lookup; no new permission engine or is_owner column.

---

## LVE-593 — 2026-11-03 — Stock Voucher & Van Setup Authorization

- create-stock-voucher v17: legacy 10-arg create_manual_stock_voucher_atomic fallback (when operation_id and rep_id absent) accepts allowed_branch_ids NULL/empty/"*" without distinct stock-voucher permission. Current UI sends operation_id and uses stronger 12-arg overload; fallback remains callable.
- Production has one active role=موظف user with permissions=[] and allowed_branch_ids="*"; that user satisfies the legacy create and send branch-scope condition.
- send-stock-voucher v20/send_stock_voucher_atomic similarly accepts branch wildcard without distinct stock-voucher permission.
- delete_manual_stock_voucher_atomic permits Draft deletion based on active company + branch scope; wildcard user qualifies.
- complete-stock-voucher v4 / complete_manual_stock_voucher_atomic_core_20260828 and cancel-stock-voucher v4 / cancel_manual_stock_voucher_atomic_core_20260828 check active company/state but no effective permission. SupplierReturn completion can post supplier ledger and journal.
- receive-stock-voucher is stronger: Transfer receive requires exact receiver_user_id; DirectReturn receive requires manager or warehouse keeper/active warehouse role and branch scope.
- setup-van-branch v3 verifies target is same-company direct-sales driver but not actor=driver_email and not fleet.manage/van-setup permission. Van Sales UI sends own email, but Edge does not enforce.
- save-inventory-count, inventory_stock_request_engine, bulk-stock-adjustment, save/delete item, save/delete branch have stronger checks in inspected paths.
- Correction to LVE-592: save-customer v4 and delete-customer v3 select public.users.is_owner, but Production public.users has no is_owner column. Source/schema conflict confirmed; runtime not tested. Do not count them as positive permission examples.
- No stock voucher or vehicle setup mutation; no DB/source/Edge/PR/deployment changes.
- Report: doc/Draft/Reprots/Report593_CTO_STOCK_VOUCHER_AND_VAN_SETUP_AUTHORIZATION_AUDIT_20261103.md. Report commit 92896914c6b5eb1a7a2ff190493c307b5e44b8d1. CURRENT_STATE commit 51ebdac02ee5812d5507201d21fcf85b8444f344.
- Next: owner-approved stock voucher and Van Setup authorization changes; secure legacy create, send/delete/complete/cancel, enforce fleet/manage or self-only setup, correct is_owner schema contract. No changes before explicit approval.

---

## LVE-592 — 2026-11-03 — Sales Authorization & Permission Source Contracts

- confirm-order v4: JWT + active company + order status only; no orders/telesales permission. Parent main.html calls it.
- create-runsheet v26 / append-to-runsheet v8: Parent main consumers; Edge/RPC validate company and state but not effective permission (reconfirmed from LVE-590).
- delete-order v10 and update-order v6 enforce sales permissions; update-order combines user, roles and role_permissions.
- save-customer v4/delete-customer v3 check customers permission.
- sales-return-management RPCs check * or return; sales quotes use rawaea_quote_actor_ok (* or orders); sales-target-engine gateway has read/manage/approve tiers; save-sales-invoice and sales-payment-allocation enforce effective permissions.
- Permission implementation divergence: some paths combine role-derived permissions; others check users.permissions only (customer, sales-return, quotes, sales-target). Divergence confirmed; effect for role-only users UNKNOWN pending role data/sync-trigger review.
- Accountant UI retains pending cash voucher payload and operation_id in sessionStorage for retry; preserve this.
- No unauthorized HTTP call or business write. No source/DB/Edge/PR/deployment mutation. PR #10 remains Draft.
- Report: doc/Draft/Reprots/Report592_CTO_SALES_AUTHORIZATION_AND_PERMISSION_CONTRACT_AUDIT_20261103.md. Report commit 4f97a96672958bcd7bbf2d31c4275f3bf5946ca3. CURRENT_STATE commit 6bc6a9a7f9757a450830a7a8c8ff88f61d5b7807.
- Next: owner-approved permission matrix and exact changes for confirm-order, create-runsheet, append-to-runsheet and role-derived permission consistency. Reuse existing effective permission helpers; no parallel engine.

---

## LVE-591 — 2026-11-03 — Finance Authorization & Data Access

- Audited high-impact financial Edge/RPC paths after LVE-590.
- save-journal-entry v8: JWT + active company only; no finance permission; service_role calls post_journal_entry.
- save-payment-voucher v7: JWT + company + branch + treasury only; no finance permission; userClient calls finance_save_expense. Both SECURITY DEFINER overloads of finance_save_expense are executable by authenticated and check company context/period/accounts but not finance permission.
- save-receipt-voucher v8: generic receipt path has no finance permission and calls service_role-only post_cash_receipt_atomic. Van Sales collection path is more restricted because post_van_sales_collection_atomic validates current user's direct-sales role and customer assignment.
- save-transfer-voucher v4: no finance permission; service_role-only post_treasury_transfer_atomic.
- update-driver-ledger v2: no finance/driver-ledger permission; service_role-only post_driver_ledger_entry.
- get-cash-flow v1: JWT only; get_cash_flow callable by authenticated, company scoped through current_user_company_id, no finance permission. Edge service_role context may return empty due missing auth.uid; Runtime not tested.
- post_journal_entry, post_cash_receipt_atomic, post_treasury_transfer_atomic, post_driver_ledger_entry are service_role-only; their Edge wrappers are the effective security boundary.
- Positive patterns: save-sales-invoice v19 and sales-payment-allocation v2 enforce effective permissions.
- Findings CONFIRMED at source/RPC contract level; no HTTP exploit or financial write performed. No DDL/DML/ACL/Edge/deployment/merge.
- Report: doc/Draft/Reprots/Report591_CTO_FINANCE_AUTHORIZATION_AND_DATA_ACCESS_AUDIT_20261103.md. Report commit 28926bbed61c39d39cff3d9e53a49b88ea8508c6. CURRENT_STATE commit c6278354deea37ec4ed5add81b862985490b716e.
- Next priority: owner-approved Finance Authorization Matrix and exact permission changes for manual journals, expenses, generic receipts, treasury transfers, driver ledger, and cash-flow access; keep Van Sales collection separate. Explicit owner approval required.

---

## LVE-590 — 2026-11-03 — Cross-Module Authorization & Inventory Effects

- Starting point LVE-589. Reviewed high-impact Edge/RPC flows beyond Buyer.
- Confirmed server-side permission/assignment gaps at contract level:
  - create-runsheet v26 / create_runsheet_atomic: no effective permission check.
  - append-to-runsheet v8 / append_orders_to_runsheet_atomic: no effective permission check.
  - start-loading v6 / start_runsheet_loading: no warehouse/loader permission or assignment check.
  - complete-loading v11 / complete_runsheet_loading: no loader assignment match or permission check.
  - unload-runsheet v6 / complete_runsheet_unloading: no unloader assignment or warehouse permission check.
  - receive-purchase v12: no effective receiving/purchasing permission check.
  - complete-delivery v4: no deliverer assignment/permission check.
  - complete-order-delivery v14 / complete_order_delivery_atomic: no deliverer assignment or effective delivery permission check.
  - save-daily-settlement v4 / post_daily_settlement_atomic: no driver/settlement permission or assignment check.
- Positive authorization patterns: start-picking v35, complete-picking v18, start-return/complete-return, save-sales-invoice v19, save-purchase-order v22, delivery_supervisor_assign_deliverer_atomic.
- cancel-delivery v5 checks driver_id while driver.html and delivery_supervisor_assign_deliverer_atomic use deliverer_id.
- complete_order_delivery_atomic changes delivered quantities but does not call post_stock_movement; complete_return_atomic posts SalesReturn from NULL to main branch and does not decrement vehicle branch. No compensating triggers were found on orders/order_details/run_sheet_details.
- Production QA fixtures show RS-1 Delivered with 13 loaded/13 delivered while VAN-CHV branch retains 13; RS-2 Returned with 6 loaded/1 delivered/5 returned while VAN-VHL retains 6. inventory_log movement types have no Delivery/VanSale. Treat as QA evidence, not proven real business loss; do not delete.
- Source/DB contract findings CONFIRMED; runtime exploit and E2E UNVERIFIED. No writes or operational changes.
- Report: doc/Draft/Reprots/Report590_CTO_CROSS_MODULE_AUTHORIZATION_AND_INVENTORY_EFFECT_AUDIT_20261103.md. Report commit 17ddb6567736ca14daf57df827bbcaf0af0654e0. CURRENT_STATE commit ea1dd9fd2114457148e0f74c0072a20a280e0150.
- Next priority: owner-review package for Warehouse/Delivery/Settlement authorization and vehicle stock reconciliation, alongside Procurement findings. Explicit owner approval required before any Production change.

---

## LVE-589 — 2026-11-03 — CTO Initialization / Procurement Authorization & Contract Conflicts

- Re-read CURRENT_STATE first; starting LAST VERIFIED EVENT was LVE-588. Read permanent constitution (293 lines), Master CTO Governance (2,665 lines), and reviewed all 114 report files present in range 400–500; numbering duplicates exist and 490/491 files were not present. Report499 is the final daily revalidation in the range; Report500 is a mind map, not Production closure.
- Operational repo current main HEAD 7a14d51b4d4c225240b215879abf6b77b99888d3. PR #10 remains Draft/unmerged, head 209c318f2324d741e61b0dceaf5253f830af8c2e, 3 ahead / 2 behind, only Buyer HTML changed.
- Retrieved full Parent main.html through Git blob API: blob 53b5a9e9d0433a785c3d5471a9c0d68c25497882, 1,800,879 chars / 33,358 lines. Structural scan: 46 RW_ modules, 1,016 functions, 48 literal table references, 41 RPC references, 48 Edge endpoint references. Parent has separate RW_Purchases and RW_PurchaseGold; RW_PurchaseGold replaces RW_Purchases.renderOrders, while legacy purchase-pos remains a separate visible route.
- Current core.js blob f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1, 1,008 lines; modules RW_Auth, RW_DB, RW_API, RW_UI, RW_ImageCache, RW_SW, RW_Realtime.
- Production: 186 public tables, 297 public functions, 186 RLS-enabled tables, 247 public policies, 304 public triggers, 734 migrations, 100 Edge Functions.
- save-purchase-order v22 is ACTIVE/verify_jwt=true and byte-identical to Git source.
- receive-purchase v12 is ACTIVE/verify_jwt=true but checks JWT and company membership without effective warehouse/purchasing permission before calling receive_purchase_atomic through service_role. Backend authorization gap confirmed at source/contract level; no HTTP exploit test performed. Its deploy source is not in operational supabase/functions.
- Receiver source uses purchase_order_details.eq('po_code', code), but Production purchase_order_details has po_id and no po_code. Source/schema conflict confirmed; runtime behavior untested. Receiver uses parseInt on numeric qty_ordered; fractional-unit impact remains unverified.
- Parent legacy purchase-pos route remains reachable and RW_Purchases.savePO sends old orderHeader/itemsList payload without operation, while save-purchase-order v22 requires operation. Source contract conflict confirmed; no runtime E2E.
- purchase_invoices and purchase_invoice_details grant authenticated DML under company-only ALL RLS; current_user_company_id does not check purchases permission. Direct DML bypass of central gateway is confirmed at ACL/RLS level. purchase_attachments has similarly broad company-only policy; private storage lacks a verified buyer-purchase invoice path.
- Buyer and Parent CREATE_INVOICE omit stable operation_id; duplicate Draft on a fresh retry key remains a contract risk, not runtime-tested.
- Supplier AP duplicate trigger is now CLOSED in live Production: one projection trigger remains and stored AP equals supplier_ledger net (3,970; difference zero). Do not reopen without new evidence.
- Production current counts: purchase_invoices=3, details=6, purchase_attachments=0, buyer_custodies=0, advances=0, expenses=0, payments=0, purchase_orders=1, PO_details=1, receiving=0, receiving_details=0. Existing invoice/PO rows are explicit QA/test references; do not delete.
- Staging is ACTIVE_HEALTHY but has no purchase_invoices/details or save-purchase-order/receive-purchase; not Buyer E2E-ready.
- Cloudflare bot comments: rawaea-erp preview for 209c318 reports success; erp-frontend, rawaea-store and warehouse-supervisor project builds report failure. Served HTML/headers/runtime/E2E remain UNVERIFIED.
- Migration lineage: Production ledger versions 20261102150516/20261102151137; operational Git files are timestamped 20261102160000/20261102162000. Function bodies match after formatting normalization, but migration version/name lineage is not one-to-one. No db push.
- No source, DB, Edge, PR, or deployment mutation in LVE-589. Only documentation report/state/memory updates.
- Report: doc/Draft/Reprots/Report589_CTO_INITIALIZATION_AND_LIVE_RECONCILIATION_20261103.md. Report commit 846d960f92851dd39c5248b7d4567ba94bc816fe. CURRENT_STATE commit ae037108f62be375bbf7d200922d18b57f2accc6.
- Next priority: owner-review package for receive-purchase server authorization, Receiver po_id/quantity contract, legacy purchase-pos payload, invoice DML hardening preserving reads, and stable invoice operation_id. Keep PR #10 Draft; no Production write before exact owner approval.

---

## LVE-588 — 2026-11-02 — Buyer Workbench Live Revalidation / Invoice RLS-ACL Conflict

- Revalidated operational repo live: main HEAD 7a14d51; PR #10 branch cto/buyer-field-workbench-lve-587 head 209c318; 3 ahead / 2 behind; PR remains Draft/unmerged. Two main commits after merge base are docs-only. The old 5ae94d7 / 2-ahead handoff is stale.
- Current Buyer blob 100987d; nine tab actions retained, zero cost_price references, one inline script parses, seven source-algorithm search cases pass against 30 active Production items. PO CREATE now sends operation_id from 209c318.
- Buyer CREATE_INVOICE for a new invoice still sends no client operation_id; Edge generates a new UUID per request, so a retry with a new request key can create another Draft. The DB invoice operation_id unique index only deduplicates the same key.
- Existing line editors turn blank price into 0 through Number(el.value); preConfirm does not revalidate each line, and DB accepts zero. This behavior is also present on main, so it is pre-existing, not introduced by PR.
- Owner LVE-585 definition of «فواتيري» remains quick-market purchase register with invoice/item evidence and line specs. Current PR filters creator only; schema has no invoice_type/source marker, and no invoice photo or per-line notes path is implemented.
- Critical Production conflict: purchase_invoices and purchase_invoice_details have permissive ALL company-only RLS policies and authenticated effective SELECT/INSERT/UPDATE/DELETE. current_user_company_id returns company_id for any non-Inactive user, without purchases permission check. This permits direct invoice DML outside the central Edge/RPC workflow and conflicts with owner §77.4. Do not change grants/RLS until full consumer scan and exact owner approval.
- Parent main.html directly reads purchase_invoices and purchase_invoice_details for views/returns, but uses Edge API for invoice create/post; preserve SELECT if future DML hardening is approved.
- Production Edge save-purchase-order v22 remains active and byte-identical to Git; currency EGP. Migration ledger has 734 entries, latest 20261102150516 and 20261102151137; matching SQL source files not located at expected paths.
- Production logs: 11,637 HTTP 200 and two ~160s 504s in 24h, without execution_id/version or matching function error logs; root cause unknown.
- rawaea-staging is active but not Buyer-ready: no save-purchase-order Edge function and no purchase_invoices/details tables. Cloudflare reports rawaea-erp preview build success for 209c318, but served artifact/browser E2E remain unverified.
- No code, DB, RLS/grants, Edge, merge, or deployment writes in this run. PR #10 remains Draft. Next: exact owner-reviewed invoice contract remediation, consumer scan, staging parity, then E2E.
- Report: doc/Draft/Reprots/Report588_BUYER_FIELD_WORKBENCH_DAILY_REVALIDATION_20261102.md

---

## LVE-587 — 2026-11-02 — Buyer field workbench source patch

- Recovered current governance, Buyer commit history and Reports569/570/571/585. Preserved LVE-582/583 invoice tabs/history/detail row handler, Draft edit/delete, currency, auth, gateway, realtime and all nine current tabs.
- Changed only `companies/company-1/purchasing/buyer.html` on feature branch `cto/buyer-field-workbench-lve-587`; current main head remains base `aa8cbffbfa8d42253726381080dcfc24eaea838b`.
- Latest commit `5ae94d769a22b540f852d235694ccf4969862cfc`; file blob `ac8be3839e7c30689e757cb8ae61c2957a8063be`.
- Added mobile horizontal touch navigation; Picker-inspired image product cards; Arabic-normalized search of existing company-scoped items by name/code/barcode; exact barcode priority; empty query yields no list; up to 14 results.
- Removed every `cost_price` reference from Buyer. Purchase price is manual in quick purchase invoice and PO entry; blank price is rejected.
- «فواتيري» filters `created_by` against current authenticated email. Verified invoice creation passes user.email to DB created_by.
- Production item sample: 30 active; 20 barcode, 29 images. All 6 inline scripts parse; zero cost_price refs; search checks pass for one-character, full name, exact barcode and empty query. Existing LVE-583 row details click and Draft guards retained.
- Draft PR #10: https://github.com/papamohammed77-glitch/erp-frontend/pull/10.
- No merge, Production deployment, Cloudflare publish, database/Edge/RPC/RLS/ACL, stock, custody or GL changes. Master CTO §77.2 approval gate remains in force. Current gateway GET_DATA still max 500; server-side pagination/search is not included.
- Next: owner review of exact PR changeset, then browser/deployment verification after authorized merge. Subsequent separate units: invoice private media/specifications, backend catalog search/pagination, Receiver intake, cash custody and purchasing-car movement ledger.

Report: `doc/Draft/Reprots/Report587_BUYER_FIELD_WORKBENCH_EXECUTION_20261102.md`

---

## LVE-586 — 2026-11-02 — Buyer Gold/Diamond Field Product Upgrade

**Status:** Review and product design documented; operational implementation not performed.

- Re-read current operational Buyer source and Picker reference. Buyer source remains the LVE-585 verified blob `73d746571a10b1720bdd31631004abce0ac9afa1`; do not claim broad UI changes are already committed.
- Confirmed `App.data(table)` sends `GET_DATA` with `limit:500`; the app uses client-side cached data. Item quick search only sees the loaded catalog, returns up to 20 matches, and quick-add defaults price to `cost_price||0`. A zero/stale cost must be labeled as unreliable, never presented as a trustworthy market price.
- Reviewed Today, Suppliers, PR, Quotations, Orders, فواتيري, عهدتي, رصيد السيارة and حسابي. Key product gap: current Buyer is largely a set of mobile-compressed data screens, not a cohesive field purchasing journey. Picker patterns to selectively adopt: image-led touch cards, instant search, readable details, visible progress. Preserve Buyer shared core/auth/gateway.
- Report586 defines mobile-first navigation/action center, catalog search, quick market purchase journey, evidence capture, offline draft/sync states, supplier/quotation intelligence, cash reconciliation, purchasing vehicle custody and phased stock/accounting integration. It includes invariants and acceptance tests.
- No operational Buyer/Receiver source, Production schema/data/RLS/Edge function, or deployment was changed in LVE-586.
- Do not redo LVE-583 invoice-row click/escaping or LVE-585 definition correction. Next engineering slice: Phase A field UX foundation plus catalog server-side search contract investigation. Follow project approval gates before Production changes.

Report: `doc/Draft/Reprots/Report586_BUYER_GOLD_DIAMOND_FIELD_PRODUCT_UPGRADE_REVIEW_20261102.md`
Commit: `7d65235207e399fb01c9167a9fc14e42599ae5f1`

---

## LVE-585 — 2026-11-02 — Owner correction: quick purchases, cash custody and purchasing-car stock

**This is the latest verified business definition and supersedes conflicting interpretations in earlier summaries/reports.**

### Owner-defined workflows
- **Buyer vehicle balance:** all physical goods currently in the purchasing officer's car, by item and quantity, regardless of whether loaded from warehouse, bought in the market and handed to the buyer, or issued from warehouse for an operational/customer need. It is not Driver stock, Van Sales stock, a mobile branch, a runsheet, or financial driver settlement.
- **Buyer cash custody:** money physically in the purchasing officer's possession and accountability. Quick purchase expense needs supplier invoice/proof of amount paid plus warehouse receipt. Fuel needs petrol-station receipt. Transport needs ticket/receipt. Other expenses need appropriate evidence. The display is advisory and must separate submitted/pending/approved/rejected/returned cash and the amount still accountable. Expense approval must not automatically be a supplier AP payment.
- **Buyer "فواتيري":** buyer's quick market purchase invoices; include supplier invoice image, item lines, quantities/prices/specifications and item photos; search/filter/detail view like PO/Parent Purchase Invoices. Keep current Draft edit/delete safeguards and barcode lookup.

### LVE-585 current source/Production evidence
- Operational Buyer source blob: 73d746571a10b1720bdd31631004abce0ac9afa1. Its invoice list is generic supplier invoices and lacks the quick-purchase scope and private invoice/item evidence. Existing Draft protections and barcode item lookup are strengths to retain.
- Receiver source blob: 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6; only PO queue/receive by PO code; no invoice-based quick market receipt.
- purchase_invoice_details.notes exists but the current invoice create/update Draft RPCs do not persist per-line notes.
- purchase_invoices.supplier_id is NOT NULL/FK suppliers; status constraint currently Draft/Posted/PartiallyPaid/Paid/Cancelled; no explicit quick-purchase/payment-source marker. No-PO invoices must not all be presumed quick market purchases.
- purchase_post_invoice_atomic still rejects no-PO invoice posting with PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED.
- Current custody expense model has no expense_type and requires PO-linked Draft invoice + supplier + PO receipt docs. Current review RPC posts Dr supplier AP (211), Cr employee custody (127), marks invoice Paid, and reduces supplier ledger. This is not the correct path for quick purchases already paid from the buyer's cash custody.
- purchase_attachments company-only policy and broad authenticated/anon DML grants are not safe for invoice privacy. Private employee-documents bucket has no verified buyer-purchase subpath; public product-images is not appropriate for private invoices.
- Existing stock-voucher core types: Transfer, DirectSale, DirectReturn, SupplierReturn. Custodian trigger requires same-company active direct-sales rep + van-sales for DirectSale/DirectReturn; Transfer vehicle guard requires a same-company delivery driver. Both registered vehicles are Delivery (CHV-2025-01 and VHL-0422). These types/assignments must not be repurposed for buyer custody.
- Existing Branch→Supplier SupplierReturn remains intact.
- Active COA inspected includes 121 Treasury, 124 Inventory, 127 Employee Custody, 211 Suppliers, etc.; exact fuel/transport/other expense account mappings remain UNKNOWN.

### Accountability and control
- Earlier Production buyer/custody/purchase migrations are present, including 20261031233331, 20261031233923, 20261031234921, 20261031235057, 20261101003952, 20261101005616, 20261101005849, 20261101010224, 20261102150516 and 20261102151137. Migration existence does not itself prove exact owner approval. Do not claim approval without its evidence.
- LVE-585 was read-only (source fetches and SELECT queries). No Production rows, DDL, RLS/grants, RPCs, triggers, Edge deployment, app source or Cloudflare deployment were changed.
- Master §77.2 requires an exact source/SQL changeset with impacts, dependencies, failures, tests and rollback followed by explicit owner approval before production-sensitive writes. Operational source remains owner-applied under the project governance.

**Latest report:** doc/Draft/Reprots/Report585_BUYER_QUICK_PURCHASE_CUSTODY_PURCHASING_VEHICLE_CORRECTED_DESIGN_20261102.md  
**Report blob:** 1bf56c28ef76f2ef6987a9e2644271a59fcfc192  
**Report commit:** 7feaa2f5675d95fe527fb32009e5b243db2e9f1c

**Next work:** prepare the exact integrated changeset for Buyer invoice scope/media/specification, secure attachment storage, quick invoice receiving in Receiver, separate purchasing vehicle assignment and central stock movements, and custody expense categories PURCHASE/FUEL/TRANSPORT/OTHER. Preserve PO, existing SupplierReturn, Driver/mobile stock and Parent. Test idempotency, partial receiving, AP isolation, custody balance, tenant/RLS and regressions. No Production write/deploy before exact owner approval.

---

# RAWAEA ERP — PROJECT MEMORY LEDGER 117-02

## 0. PURPOSE
This file is the persistent, governed project-memory ledger derived from the `117-02` current-truth command and the `MASTER - RAWAEA ERP.md` continuity/execution command.
It is not a report and not a replacement for source systems.
Operational recency is governed by `CURRENT_STATE.md` and its `LAST VERIFIED EVENT`.

## 1. SOURCE OF TRUTH HIERARCHY
1. Production runtime and database evidence
2. PostgreSQL schema/functions/triggers/RLS/grants/constraints
3. Active deployed Edge Functions plus runtime evidence
4. Current Git `main`
5. Current application/core/PWA/SW files
6. Git history
7. Historical/original sources
8. Historical execution artifacts
9. Reports/prompts
10. Assistant memory

Historical sources explain intent and prior behavior. They do not prove current runtime state without re-verification.

## 2. CURRENT PROJECT IDENTITY
- Project: RAWAEA ERP
- Operational application-source repository: `papamohammed77-glitch/erp-frontend`, branch `main`; current verified HEAD at LVE-2026-10-31-568: `65799d282acc79359b17a1a13dcd68f62859e1fb`. Parent `companies/company-1/main.html` Blob: `53b5a9e9d0433a785c3d5471a9c0d68c25497882`; shared `companies/company-1/core.js` Blob: `a95ee6b29ff54b4a240ce4b81f9a535aa87686db`; Counter Blob: `32d0dc8ca0edb7cc68660f0fbd6246408117498d`; Loader Blob: `4375d3067f9fe5453b49f580339a1f906040967f`; Warehouse Supervisor Blob: `792f8bbff15a0c724e47b6e6e28f2ffec903b024`; Returns Blob: `16d02fff2d00759451879204abf218202898f9c0`; Driver Blob: `92ae03678b6516345a61d30bb5967046096d8cce`.
- Governance, continuity, and report repository: `papamohammed77-glitch/rawaie-erp-New`, branch `main`. `CURRENT_STATE.md` is the canonical continuity checkpoint; latest event is `LVE-2026-10-31-568` (state commit `12ef7e853533fc0ae6a6878a75fad21f75cec959`). The operational source repository also contains a separate `CURRENT_STATE.md` handoff, updated 2026-10-31 17:20:22Z; it was not modified in this run to avoid a possible uncontrolled Pages deployment. Re-fetch both live heads each run.
- Historical repository: `papamohammed77-glitch/rawaie-erp-review`.
- Production: Supabase `SMART ERP`, ref `fiilmooggumokxanwiyx`, status `ACTIVE_HEALTHY`; live metadata reports PostgreSQL `17.6.1.121` as of LVE-558.
- Staging: Supabase `rawaea-staging`, ref `hfzznsiprnwkpayskzhu`; current live project listing reports `ACTIVE_HEALTHY` as of LVE-558. No staging tests were run in this event.

## 3. MASTER COMMAND ADOPTION
The full `doc/Draft/medhat/MASTER - RAWAEA ERP.md` command was read end-to-end through section 60.
Its operating loop is mandatory:
`CURRENT_STATE -> LAST VERIFIED EVENT -> current reality -> reconcile -> identify target -> resolve critical unknowns -> trace owner/dependencies -> surgical change -> verify -> deploy/runtime verify -> CURRENT_STATE update -> reassess`.
It explicitly rejects historical-stage control, percentage-based control, artificial workflows/executors, duplicate architecture, report-only closure, and invented completion claims.

## 4. HISTORICAL MAIN1 / NEW-MAIN RECONCILIATION NOTES — 2026-08-31
- Previous `CURRENT_STATE.md` states were repeatedly reconciled when Git advanced beyond the recorded checkpoint.
- The last confirmed commit that actually modified `Current/PWA/New-main` is `a4551e0fcfc55fd609f48109407c025b44e20641`.
- Comparing `a4551e0...` to current `e8da572...` shows no later New-main target modification; later commits primarily changed workflows, builders/parsers, prompt/reporting and verification infrastructure.
- A later documentation commit `a2092863...` renamed/normalized the master command file and did not modify Production.

## 5. FRESH PRODUCTION SNAPSHOT — 2026-08-31
Direct SQL verification against Production observed:
- PostgreSQL 17.6
- Public tables: 66
- Public functions: 76
- Public triggers: 20
- Public policies: 110
- Companies: 1
- Users: 24
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log: 3
- Orders: 0
- Runsheets: 0
- Journal entries: 2
- Journal lines: 0
- Customer ledger: 0
- Supplier ledger: 0
- Driver ledger: 0
- Daily settlements: 0
- Treasury: 1
Production status: `ACTIVE_HEALTHY`.

## 6. CURRENT SECURITY / AUTHORIZATION EVIDENCE
Fresh Production privilege/RLS inspection confirmed:
- `orders` broad authenticated `ALL` policy plus broad store/anon insert paths.
- `order_details` broad authenticated `ALL` policy.
- `run_sheet_details` broad authenticated `ALL` policy.
- `daily_settlements` public `ALL` with `true/true`.
- Seven observed externally executable `SECURITY DEFINER` functions include vehicle context/guard functions, `create_vehicle_atomic`, `fn_vehicle_audit_trigger`, and `get_budget_vs_actual`.
- Auth leaked-password protection is disabled according to Security Advisor.
- Performance Advisor reports unindexed FKs, RLS init-plan inefficiencies, multiple permissive policies and unused indexes.
These findings are evidence-backed security/governance blockers, not permission for blind Production mutation.

## 7. STAGING OBSERVATION
Direct staging SQL observed one company. Therefore staging is not a two-company proof environment and cannot by itself prove tenant isolation.

## 8. BUSINESS DOMAIN MEMORY
### Sales
Channels include POS, Telesales, Order Taker, Van Sales and Online Store. Sales orders feed runsheet/fulfillment and may result in delivery, return, settlement and financial/ledger effects.

### Procurement
`Purchase Order -> Receiving -> Physical Stock -> Journal -> Supplier Ledger` through the inspected `receive-purchase -> receive_purchase_atomic` path.

### Warehouse / Fulfillment
`Runsheet -> Picking -> Loading -> Delivery/Return/Unloading`. Picking is reservation-oriented; loading/unloading inspected paths use the central physical-stock engine.

### Inventory
`stock_branches.qty` is physical quantity; `allocated_qty` is reservation state. `post_stock_movement` is the inspected physical movement authority.

### Accounting / Ledgers
`post_journal_entry` is the inspected journal core. Dedicated customer/supplier/driver ledger writers exist. Full writer exclusivity remains open.

## 9. CURRENT ARCHITECTURE MEMORY
- Multi-PWA frontend remains the current operational architecture.
- `Current/PWA/main.html` is protected from replacement.
- `Current/PWA/New-main` is the sole authorized clean-room candidate.
- `main1..main11` are logical modules/contracts, not byte slices.
- Authenticated identity maps through `public.users.auth_id -> users.company_id`.
- `app_private.current_user_company_id()` is the DB tenant resolver.
- Specialized PWAs delegate business writes to Edge/RPC/Core owners.
- Duplicate Physical Stock writers are forbidden.

## 10. HISTORICAL INVENTORY MEMORY
Historical rescue evidence established the Inventory writer boundary around `post_stock_movement(10)`, separated reservation engines, and constrained legacy application execution. This was an Inventory boundary closure, not ERP-wide closure.
Historical Receive contract: cumulative `received_qty`; partial Receive remains Sent; full becomes Received; reject over-remaining; preserve allocation; one history row per physical movement; atomic transaction.

## 11. CURRENT CONSUMER MEMORY
Representative paths:
- Telesales/Main -> `save-sales-invoice` -> `save_sales_invoice_atomic`.
- Purchase receiving -> `receive-purchase` -> `receive_purchase_atomic`.
- Loading -> `complete-loading` -> `complete_runsheet_loading`.
- Voucher UI -> voucher Edge/Core paths.
- New-main -> specialized PWA/Edge/Core owners for operational mutations.
Full all-consumer graph remains unproven.

## 12. DEPENDENCY GRAPH RECONCILIATION
`Current/CTO/20260831_PHASE5_SYSTEM_DEPENDENCY_GRAPH.md` previously claimed `CLOSED` while admitting the full runtime graph was not proven. Under the Master Command this was inconsistent; it was corrected to `PARTIAL / OPEN` in commit `50b40e6b7d8d0f0ddc29dc6681fac8059cc5e110`.

## 13. DEPLOYMENT LINEAGE MEMORY
The complete chain
`Git SHA -> source file -> artifact/package -> Production version -> runtime consumer -> runtime evidence`
remains only partially proven. Deployment existence/version does not establish consumer use or runtime correctness.

## 14. NEW-MAIN / MAIN1 MEMORY — CURRENT
MAIN1 current/original contract evidence is verified. The New-main target at `a4551e0...` contains substantial shell/auth/tenant/navigation/permission/notification/workflow/audit surfaces, but closure is not established.

Verified remaining contract gaps:
- Owner calculation currently permits `owner_profile` existence to make `isOwner=true`; governing contract requires Auth metadata to establish owner semantics and preserves wildcard permissions.
- New-main contains only a lightweight `RW_OwnerLicense` object; full MAIN10 license-management UI/save/email/password contract is not present.
- Notification implementation lacks exact MAIN1 `_clickNotif`, `_renderAndSave`, `_updateBadge`, `markRead` behavior and related-record navigation.
- Audit rendering is simpler than the full MAIN1 `RW_Audit_*` contract set.
- Session reset/fail-closed lifecycle proof is incomplete.
- Workflow rules are not explicitly company-scoped in the current target surface; impact needs contract proof before any Production policy decision.

A previous executor attempt `6b339cc...` modified tooling rather than safely closing the target and was later reverted. Parser/browser-gate commits such as `02da996...`, `9507d0...`, `455e287...`, and `c2c316...` improve execution infrastructure but are not target implementation evidence.

## 15. MAIN1 EXECUTION SAFETY RESULT
The Master Command requires actual target modification plus verification. The available GitHub write path for `Current/PWA/New-main` performs a complete monolithic file replacement. This execution environment did not provide a safe way to reconstruct and submit the full target bytes without risking unrelated content loss. Therefore no unsafe whole-file rewrite was performed.

This is a tooling safety limitation only. It is not a business or architectural blocker and not evidence of completion.

## 16. CURRENT ANOMALY MEMORY
Production anomalies requiring provenance remain:
1. One active/non-inactive `users` row without `auth_id`.
2. Two cancelled `VoidInvoice` journal headers with zero lines.
3. Three `VoidInvoice` inventory-log rows.
No deletion or synthetic repair without provenance, downstream impact and audit analysis.

## 17. INCIDENT / FAILURE MEMORY
Never repeat:
- report == current truth;
- historical PASS == current PASS;
- CI PASS == Production PASS;
- Git source == deployed code without lineage;
- executor change == target implementation;
- deployment existence == consumer proof;
- broad RLS/grants == intended authorization;
- duplicate physical-stock writers;
- destructive repair without provenance;
- byte-slicing logical PWA modules;
- compacting a rich application into a feature-loss candidate;
- patching Production solely to satisfy CI.

## 18. OPEN CLOSURE UNITS
1. Safe actual MAIN1 target modification in `Current/PWA/New-main`.
2. MAIN1 static contract validation after modification.
3. Browser/runtime verification of New-main.
4. Auth/Owner/license lifecycle proof.
5. Notification and audit behavior parity.
6. Full consumer graph and deployment lineage.
7. Two-tenant authorization harness/proof.
8. P0 tenant-isolation remediation plan.
9. Security Advisor remediation + regression suite.
10. Exhaustive journal/ledger/treasury writer matrix.
11. Data provenance for current anomalies.
12. Service Worker runtime proof.
13. Main replacement certification.

## 19. FORBIDDEN ACTIONS
- No blind Production DDL/DML.
- No direct Physical Stock writer outside canonical engines.
- No direct financial mutation from New-main.
- No deletion of unknown legacy artifacts.
- No credential/token use because exposed in historical workflow source.
- No Main replacement before evidence closure.
- No artificial workflow/executor/parallel architecture.

## 20. MEMORY OPERATING LOOP
1. Read `CURRENT_STATE.md` first.
2. Read latest `LAST VERIFIED EVENT`.
3. Verify Git HEAD.
4. Verify relevant Production state.
5. Compare with this ledger.
6. Mark stale/conflict.
7. Resolve critical unknowns.
8. Identify true current target.
9. Prove owner/dependencies/root cause.
10. Implement minimum safe target change.
11. Verify source/runtime/data/audit as applicable.
12. Update `CURRENT_STATE.md` immediately.
13. Record material knowledge here.
14. Reassess target after closure.

## 21. HISTORICAL MEMORY BASELINE — LVE-2026-09-01-004
- Event ID: `LVE-2026-09-01-004`
- Event Type: `MASTER_CONTINUITY_MEMORY_RECONCILIATION_FINAL`
- UTC: `2026-09-01T00:24:00Z` execution window
- Source: full MASTER command 0-60 + current Git history + direct New-main + MAIN1 + MAIN10 inspection + current Production evidence
- Git SHA: `e8da572a5b42a407c4d5f8d7493b9e4fe134f663`
- Production State: `ACTIVE_HEALTHY`
- Action: finalized the project-memory reconciliation after fully reading the Master command; verified the latest New-main target change, separated target implementation from later tooling changes, recorded the remaining MAIN1 gaps, and preserved the no-unsafe-write decision.
- Result: `MEMORY SYNCHRONIZED / MAIN1 OPEN / NO UNSAFE TARGET REWRITE`
- Impact: future CTO continuity starts from the actual latest repository state and will not repeat the reverted executor/false-closure path.
- Next Authorized Action: continue from the proven MAIN1 gaps using a safe full-file target-write path, then run structural, syntax, browser/runtime, authenticated and Production-compatibility verification before closure.

## 22. CURRENT EXECUTION POSITION
- Master continuity command: ACTIVE
- 117-02 memory governance: ACTIVE
- Current State: LVE-2026-10-29-560; source truth is revalidated from live GitHub/Supabase/Cloudflare snapshot, not from this ledger.
- Operational app repo: `erp-frontend/main`, HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`.
- Current target: standalone Returns eligibility. Main `returns.html` still contains the root cause; PR #8 is open/draft/unmerged with the main list eligibility fix. Search patches R8-S1-A/B remain owner-only and un-applied.
- Production: checked at `2026-10-29 19:03:17.860357+00`; `RS-1` Delivered, 5 detail rows, outstanding return quantity 0; `RS-2` Delivered, 7 detail rows, outstanding quantity 5. No current Returning/Returned rows in the inspected sample. No Production mutation occurred.
- Parent: commit `0351897` is in current Main history and corrected the Parent returns-table JS/HTML. Parent SHA is `3a5d2e565a04262081d024f6e514e1372d372e84`; don't repeat historical Parent patches without new evidence.
- Driver: current SHA `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`; no causal Driver defect was found for standalone Returns eligibility. No change required.
- Deployment: Cloudflare snapshot shows Production Main `416de1c` at `b469734c.rawaea-erp.pages.dev` and PR #8 Preview `3ad370c` at `da5fcdde.rawaea-erp.pages.dev`. Byte-identical served artifact and authenticated E2E remain UNKNOWN/UNVERIFIED; referenced failed build logs remain to be read before attributing causes.
- Security / older MAIN1 backlog: OPEN; this event does not close or authorize unrelated historical work.
- Status: RETURNS ROOT CAUSE CONFIRMED / CORE FIX ONLY IN DRAFT PR #8 / OWNER SEARCH PATCH REQUIRED / PRODUCTION READ-ONLY / SERVED ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.

## 23. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-473
- Scope: Loader/Picker runsheet preview parity; owner-only patch to Picker.
- Current Loader SHA: `97b83d68a683df77c1e0557838c24a1b4fb65169`; current Picker SHA: `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Fresh direct Production SQL: items.description and items.image_url exist; run_sheet_details.description is absent; item and runsheet FKs are present; current status count is Picked=2.
- Defect: Picker preview remains abbreviated and uses `.select('*')`; description must be sourced through `items!run_sheet_details_item_id_fkey(description)`. Active Picking session mapping needs the matching one-line nested-description correction.
- Complete surgical owner changeset is Report471 Patches A/A2/B/C/D. Report472 is historical pointer only where it defers to earlier reports; Report471 contains complete replacement blocks.
- No operational source or Production/business data was changed. No synthetic Production data was created or deleted. The memory file itself was restored from the immediately preceding commit after an empty-content write, then this event was appended.
- Status: OWNER PATCH READY / DEPLOYMENT + BROWSER E2E UNVERIFIED / NOT CLOSED.
- Next exact action: re-fetch Picker and verify SHA, apply only missing Report471 patches, deploy using the existing frontend path, verify served HTML and Browser E2E, and confirm inventory/reservations remain unchanged.
- Report: `doc/Draft/Reprots/Report473_PICKER_PREVIEW_PARITY_SESSION_REVALIDATION_20261023.md`.


## 24. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-474
- Target: Loader/Picker runsheet preview parity. Fresh source SHA Loader `97b83d68a683df77c1e0557838c24a1b4fb65169`; Picker `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Loader current refactor commit: `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`. It changes the preview to responsive inline summary/cards and event-bound buttons; therefore Report471 Patch B is visually stale and Report474 Patch B supersedes it.
- Fresh direct Production SQL: items.description/image_url exist; run_sheet_details.description absent; expected item and runsheet FKs exist; current runsheet count status Picked=2 only.
- Confirmed Picker defects: abbreviated preview; no joined description; active session reads nonexistent detail.description; inline onclick interpolates DB values; unsafe image/detail HTML interpolation.
- Owner surgical patches are A/A2/B/C/D in `doc/Draft/Reprots/Report474_PICKER_PREVIEW_PARITY_REBASE_AFTER_LOADER_REFACTOR_20261023.md`. No operational source or Production schema/data changes were made. No test rows were created/deleted.
- Status: OWNER PATCH READY / SOURCE + DB CONTRACT VERIFIED / DEPLOYMENT + BROWSER E2E UNVERIFIED / NOT CLOSED.
- Next: re-fetch Picker, verify SHA, apply only missing patches from Report474, test syntax and Staging E2E; confirm no stock/reservation changes; verify Cloudflare served HTML before closure.

- Report474 self-audit: Picker has no `RW_UI` namespace, so the patch now uses a local `formatPreviewNumber()`; image URL regex literals were corrected and re-fetched. Latest Report474 commit `68d6e9555219d0c41a32145f1fbc74131a410ae7`, blob `c9025663f8ee0bb79bc2e88ae6242be38d00f25c`.



## 25. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-475
- Scope: consolidated CTO re-investigation of Loader/Picker runsheet preview parity; owner-only operational source changes.
- Source repos separated: actual app source is `papamohammed77-glitch/erp-frontend` on `main`; this repository is continuity/governance/reporting. Historical reports are references, not current truth.
- Fresh app source: Loader `companies/company-1/warehouse/loader.html` SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker `companies/company-1/warehouse/picker.html` SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1058 lines). Neither operational file changed.
- Current Loader preview refactor: commit `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`. Picker history reviewed for session recovery, Idempotency-Key/operation id, quantity validation, and insufficient-stock handling; preserve these contracts.
- Production SQL read-only snapshot at 2026-10-23 12:24:37 UTC: PostgreSQL 17.6; items=18, run_sheet_details=12; items.description/image_url exist; run_sheet_details.description absent; item_id FK and runsheet_id FK present; status count Picked=2 only, no Open/Confirmed rows in the queried counts. No DDL, RLS/RPC/Edge, or business-data writes; no test rows created/deleted.
- Confirmed root causes in Picker: abbreviated preview; detail query omits joined item description; active session reads absent detail.description; inline onclick interpolates DB values; unvalidated image src and unescaped item detail HTML.
- New self-contained current owner changeset: `doc/Draft/Reprots/Report475_PICKER_PREVIEW_PARITY_CONSOLIDATED_CTO_EXECUTION_20261023.md`, report commit `53ec7826a121ef5c8767c3fb7f1b4ce7059d0ff2`, report blob `496e18243085101728fba7f15870d72b33927943`. Includes patches A/A2/B/C/D, complete replacements, bounded scope, tests and rollback. Its JS blocks B/C/D were syntax-parsed successfully. Report474 Patch D had ambiguous/broken escaping around inline onerror; do not carry that historic block forward.
- Production and deployment state: source patch not applied; Cloudflare served HTML and browser E2E unverified; current production runsheets do not offer Open/Confirmed test cases. No operational source was edited. Status: ROOT CAUSE VERIFIED / OWNER PATCH READY / NOT DEPLOYED / NOT CLOSED.
- Next exact step: owner re-fetches Picker and checks SHA. If unchanged, apply patches A→A2→B→C→D from Report475 only; test in Staging, validate syntax/UX/auth/company boundaries and unchanged stock/reservations, then compare served Cloudflare HTML and run authenticated browser E2E. Do not edit Loader, main.html, or core.js for this display issue. Do not change Production for this task.


## 26. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-476
- Report475 was amended with Patch E to preserve image-error fallback in the active Picker session after replacing `_img`.
- Final report blob SHA: `130cca676845487a4106c3252ce531e88e430eff`. It contains patches A, A2, B, C, D and E.
- JavaScript parse checks passed for replacement blocks B/C/D/E. No inline `onerror` remains in the new image/detail replacement blocks.
- Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` and Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` remain unchanged. No operational source or Production data was modified.
- Owner patch is not applied or deployed. Cloudflare served HTML and authenticated Browser E2E remain unverified. Continue with Staging verification before closure.


## 27. LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-477
- User required a complete CTO re-execution, full context recovery, and one consolidated owner report rather than references spread across old reports.
- Read current governance (2,606 lines), CURRENT_STATE, and memory; independently refreshed current app source, historical Picker baseline and relevant commits, and Production schema/RLS/Edge inventory.
- Single operative report: `doc/Draft/Reprots/Report477_PICKER_PREVIEW_PARITY_MASTER_CTO_REEXECUTION_20261023.md`, report commit `069f8f4ac53747675af8ae66eb8425007e0c5442`, blob SHA `1707a3dbbcac68728817aa2b67609f982159ece3`. It contains exact defective source elements plus complete patches A/A2/B/C/D/E; Patch B explicitly displays escaped item descriptions and summary totals.
- Current app HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`; Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`; core.js SHA `ff2f581d9900543c16f7cb026e13446520c0329d`. No operational app file was edited.
- Fresh Production read-only snapshot at `2026-10-23T14:26:56.133432Z`: PostgreSQL 17.6; items=18, run_sheet_details=12, runsheets=2; status Picked=2 only; items.description/image_url exist; run_sheet_details.description does not; item and runsheet FKs and company/permission RLS policies verified.
- Current related Edge versions: start-picking v35, complete-picking v18, cancel-picking v5, reopen-picking v9, start-loading v5, complete-loading v11; all ACTIVE, JWT verification enabled. No Production mutation was needed or performed.
- Replacement blocks B/C/D/E in Report477 were syntax-parsed successfully. This does not establish browser/runtime correctness.
- Deployment lineage remains UNKNOWN: Cloudflare Pages is documented and /picker redirects to the current path, but served HTML SHA and authenticated Browser E2E are not established. Owner source changes remain unapplied; task is NOT CLOSED.
- CURRENT_STATE was appended with the Report477 checkpoint in commit `0e06c9ccde376d842c062b5042cc7b11291bd5df`, content SHA `382e6ace2086739719e7dca13f89f8a0fba74736`.
- Next exact action: owner re-fetches Picker and checks SHA; if unchanged, applies only Report477 A→A2→B→C→D→E, runs Staging tests and confirms no stock/reservation/log delta, deploys through the approved frontend path, verifies Cloudflare-served HTML and authenticated Browser E2E, then updates state. Do not touch Loader, main.html, core.js, or Production for this display-only defect.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-478
- Re-read MASTER CTO governance and refreshed CURRENT_STATE and memory before examining operational source. No owner changes are reflected in the current Picker blob.
- App HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`; Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`.
- Fresh SQL at `2026-10-23T14:58:58.392162Z`: PostgreSQL 17.6; items=18, run_sheet_details=12, runsheets=2; status Picked=2 only; items.description/image_url exist; run_sheet_details.description absent; both expected FKs exist.
- Defects remain A/A2/B/C/D/E as documented in Report477. Report477 is still the authoritative full owner patch; Report478 records this session's fresh evidence.
- No operational source, Production schema, Edge/RPC, or business data changed. No synthetic Production data created/deleted.
- Cloudflare served artifact UNKNOWN; owner patch/Staging/Browser E2E UNVERIFIED; task NOT CLOSED.
- Report: `doc/Draft/Reprots/Report478_PICKER_PREVIEW_PARITY_CURRENT_STATE_RECHECK_20261023.md`; report commit `7051d21747913372a125ca5e660eb5d2b1db2c17`.
- Next exact action: owner verifies current Picker SHA, applies only missing Report477 patches A→A2→B→C→D→E, validates in Staging with zero inventory/reservation/log delta, then verifies served Cloudflare artifact and authenticated Browser E2E.

 
## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-481
- Resumed from CURRENT_STATE LVE-480 and independently re-fetched the current operational source and SMART ERP Production; this was read-only verification, not an application change.
- Current app HEAD remains `152e5b1d22aab94d2cf01070778b357df4701aff`; Picker SHA remains `d483bd15b36585b975b63c2ef641481a01d5d084`; Loader SHA remains `97b83d68a683df77c1e0557838c24a1b4fb65169`. Picker still has `.select('*')`, inline `onerror`, and does not contain the Report477 patch. No operational file was edited.
- Fresh read-only SQL at `2026-10-23T15:09:17.918546+00:00`, PostgreSQL 17.6: items=18, run_sheet_details=12, runsheets=2, status Picked=2 only. items.description/image_url exist; run_sheet_details.description does not; expected item/runsheet keys and relevant quantity/status columns exist.
- Current related Edge versions: start-picking v35, complete-picking v18, cancel-picking v5, reopen-picking v9, start-loading v5, complete-loading v11; all ACTIVE with JWT verification enabled. No Production schema/RLS/grant/RPC/Edge/business-data writes were performed or indicated.
- Report480 independently confirms the same Picker defect and identifies Report477 patches A/A2/B/C/D/E as the single operative owner changeset. Required FK relation for description is `items!run_sheet_details_item_id_fkey(description)`; no schema change is needed.
- Cloudflare Pages is documented and `/picker` maps to the Picker file, but served artifact SHA/deployment lineage remains UNKNOWN; Staging and authenticated Browser E2E remain UNVERIFIED.
- Status: ROOT CAUSE RECONFIRMED / OWNER PATCH NOT APPLIED / DEPLOYMENT UNKNOWN / BROWSER E2E UNVERIFIED / NOT CLOSED. No production fixtures were created/deleted.
- Next: re-fetch Picker and verify SHA; apply only missing Report477 patches if unchanged, validate in Staging with zero stock/allocated_qty/inventory_log delta, then verify Cloudflare-served HTML and authenticated Browser E2E. Do not edit Loader, main.html, core.js or Production for this presentation/query-shape defect.

## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-482

- Report481 audits the 50 report files in the Report432–Report480 window (including both Report458 files) and deeply reconciles Reports466–480.
- The current request's target is `erp-frontend/companies/company-1/warehouse/loader.html`, not Picker. Report466 originally targeted Loader; Reports467–480 drifted into a Picker preview-parity patch chain. Report477 is authoritative only for that Picker-specific task and must not be applied to Loader.
- Fresh source identities: operational repo HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`; Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 lines); Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1,058 lines); Core SHA `ff2f581d9900543c16f7cb026e13446520c0329d`.
- Current Loader source already has card/search click handlers invoking `App.openRunsheet(code)`; the method loads runsheet details and renders the Picked preview inside `mainContent`, uses the active session for current user's Loading runsheet, and uses read-only rendering for other states. Therefore no code patch is justified from static source alone; served browser failure must first be reproduced.
- Reporting defects: Report473 incorrectly says Loader and Picker each have 1 line; Reports478–480 repeat unchanged source/state and continue prohibiting Loader edits for a task whose current target is Loader. Picker schema findings can be valid for Picker but are not the current Loader change request.
- No operational HTML/Core or Production change was made. Cloudflare served artifact identity and authenticated browser click behavior remain unverified.
- Exact next step: test the served Loader card and search-result click with an authorized runsheet; capture browser/Console/Network evidence; if failure is reproduced, apply the smallest evidence-backed fix to Loader only, then verify Staging/browser and zero `stock_branches.qty`/`allocated_qty`/`inventory_log` delta from opening details.
- Consolidated report: `doc/Draft/Reprots/Report481_LOADER_RUNSHEET_CLICK_DETAILS_SCOPE_CORRECTION_20261023.md`, commit `73c3f82c5a270bd97c8598eef5e6ac2778cb2e47`. CURRENT_STATE update commit: `0c421866da8d0a161cc9a53e87920a038ac5af91`.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-483

- Corrected the previous misinterpretation: user requested the full Loader-vs-Picker detail experience, not just card click-to-open. Required behaviors are runsheet details in the app, interactive item cards, large-photo item-detail modal, code/unit/qty/description, and parity in the active Loading item's edit modal while preserving its quantity workflow.
- Directly refreshed source: app HEAD 152e5b1d22aab94d2cf01070778b357df4701aff; Loader SHA 97b83d68a683df77c1e0557838c24a1b4fb65169; Picker SHA d483bd15b36585b975b63c2ef641481a01d5d084; Core SHA ff2f581d9900543c16f7cb026e13446520c0329d.
- Current Loader already has click handlers from run-sheet cards/search results and inline Picked preview. Missing parity: item cards in preview aren't clickable; no large item-detail modal; the active Loading editor uses a small image and lacks description/code; run_sheet_details query doesn't join image/description; Loader's list/search/open omit explicit company_id scoping and the open path lacks a guard for a Loading runsheet assigned to someone else.
- Direct Production read-only schema check confirms items.description, items.image_url, and FK run_sheet_details_item_id_fkey (run_sheet_details.item_id → items.id), while run_sheet_details itself has no description/image_url. No schema change or additional function is needed.
- Report482 is the consolidated owner-applied surgical changeset: doc/Draft/Reprots/Report482_LOADER_PICKER_RUNSHEET_ITEM_DETAIL_PARITY_20261023.md, latest commit 0845cb1590774796000196cb15e06cd27d885f15, blob 0a7518f5b90a4a077b2f19da39573640f202cbe3. It contains exact patches A–F.
- All 14 JavaScript snippets in Report482 passed syntax parsing after wrapping partial query/property snippets in their correct syntactic context. This does not constitute full-page parsing, browser tests, or deployment verification.
- No operational source, main.html, core.js, Picker, Supabase schema/RLS/RPC/Edge, or Production business data was changed; no Production test fixtures were created. Cloudflare served artifact, owner application, browser E2E, and zero-stock-delta test remain unverified.
- Next: owner confirms current Loader SHA and applies only Report482 A–F in the stated locations; parse the entire resulting script; test preview detail modal, image fallback, role/company isolation, active Loading editor, back/start flows in staging; verify unchanged stock_branches.qty, allocated_qty, inventory_log; then independently verify the Cloudflare-served file. Do not redirect task to Picker or modify main.html/core.js.
- Status: DIAGNOSIS CORRECTED / OWNER PATCH DOCUMENTED / NOT APPLIED / NOT CLOSED.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-23-484

- Scope: Loader-vs-Picker item-detail parity plus direct verification of loading completion dependencies. This event supersedes the older Loader/Picker checkpoint entries for operational recency; prior history is preserved.
- Read CURRENT_STATE.md first and read MASTER CTO governance SHA `b03feec14a417ca9032d714774f2687b4542a373` (2,606 lines). CURRENT_STATE now has an authoritative top pointer at LVE-484; the stale LVE-481 and LVE-483 headings were relabeled historical without deleting their content.
- Operational app source: `papamohammed77-glitch/erp-frontend`, main HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`. Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`; Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; Core SHA `ff2f581d9900543c16f7cb026e13446520c0329d`. Report482 A–F remains unapplied.
- Report483: `doc/Draft/Reprots/Report483_LOADER_DAILY_REVALIDATION_LOADING_CONTRACT_CONFLICTS_20261023.md`, blob `c2cdb93dee417701f218bec760afd0a31a4739c3`, commit `4da0a37e02e09004b83ef08a9d73683fdf11e8ec`. It documents the daily evidence and adds safe Loader-local thumbnail Patch G; the helper snippet passed V8 syntax parsing only, not full-page or browser testing.
- Read-only Production at 2026-10-23T18:44:22Z: PostgreSQL 17.6; items=18, run_sheet_details=12, runsheets=2, stock_branches=57, inventory_log=28; runsheet status Picked=2 only. items.description/image_url and the item FK exist; run_sheet_details has no description/image_url/notes; order_details.notes exists. Authenticated UPDATE on run_sheet_details is false and no UPDATE policy exists.
- Confirmed loading contract conflict: Loader sends every item, including qty_loaded=0, and includes notes; Production complete-loading v11 rejects any loaded_qty<=0 and drops notes; complete_runsheet_loading also rejects req<=0 and does not persist notes. Actual user occurrence is unverified because no complete-loading invocation appeared in the targeted 24-hour log query and no Loading fixture exists.
- Production complete-loading v11 source differs slightly from Git snapshot `Current/Edge_Functions/complete-loading`; current repo tree has no matching `Current/Edge_Functions/start-loading` file although Production start-loading v5 is active.
- Supabase runtime logs show the published app made unscoped runsheets GETs and a select=* details GET at 2026-10-23 09:14–09:16 UTC, all HTTP 200. This matches current source query shapes but does not establish the served artifact SHA or E2E behavior.
- Deployment artifact/headers/cache and authenticated browser E2E remain UNKNOWN/UNVERIFIED. Direct Cloudflare fetch failed in this environment; no Cloudflare MCP/browser tool was available. Existing staging project `hfzznsiprnwkpayskzhu` is INACTIVE and was not restored.
- No operational app, Production schema/RLS/grants/RPC/Edge, or business data changed; no test fixture was created.
- Status: SOURCE REVALIDATED / REPORT482 NEEDS PATCH G / ZERO-QUANTITY + NOTES CONTRACT CONFLICT CONFIRMED / DEPLOYMENT UNKNOWN / E2E UNVERIFIED / NOT CLOSED.
- Next: do not apply Report482 A–F unchanged; incorporate Patch G and validate the full Loader in active isolated staging. Keep zero-quantity/notes behavior open and do not modify Production Core/Edge until the contract has a safe, tested plan.



## LAST VERIFIED MEMORY EVENT — LVE-2026-10-24-489

- Re-read CURRENT_STATE.md completely to EOF before other project actions; the starting checkpoint was LVE-2026-10-24-488. Re-read the full MASTER CTO governance file, SHA `b03feec14a417ca9032d714774f2687b4542a373`, 2,606 lines.
- Fresh operational source remains `papamohammed77-glitch/erp-frontend` / `main`, HEAD `152e5b1d22aab94d2cf01070778b357df4701aff`; Loader `97b83d68a683df77c1e0557838c24a1b4fb65169`, Picker `d483bd15b36585b975b63c2ef641481a01d5d084`, Core `ff2f581d9900543c16f7cb026e13446520c0329d`. Full current inline JavaScript parse passed for Loader, Picker, and Core; a proposed corrected Loader assembled in memory also passed full inline-script V8 parsing. No operational file was changed.
- Fresh Production snapshot at `2026-10-24 18:41:23.419779+00`: PostgreSQL 17.6, items=18, run_sheet_details=12, runsheets=2, Picked=2 only. RLS scopes runsheets/details to current company. Authenticated has SELECT but no UPDATE grant/policy on run_sheet_details.
- Confirmed contract conflict remains: Loader sends zero-quantity rows and notes; Production complete-loading v11 rejects any `loaded_qty<=0`, drops notes, and RPC `complete_runsheet_loading(uuid,uuid,jsonb,text)` also rejects zero and has no notes handling. Direct UI update to run_sheet_details ignores errors while authenticated UPDATE is denied. No Production schema/RLS/grant/RPC/Edge/business-data mutation was performed.
- Production Edge registry: complete-loading v11 ACTIVE; start-loading v5 ACTIVE. Git snapshot `Current/Edge_Functions/complete-loading` SHA `0dd221173aee7f3aa15d16202f034ae94f4104f3` differs from deployed source in JSON/code normalization; `Current/Edge_Functions/start-loading` is missing (404). Latest recorded migration is `20261021161758`; no later loading-contract repair was found.
- Corrected Report487 patch sequencing: original instruction to apply G first is invalid because its insertion anchor and modal handlers depend on E/F; original B also omitted return of the nested details Promise. Report488 supplies full replacements for A1/A2/B/D plus full image-fallback call-site replacements and specifies the corrected order. It preserves the current read-only behavior for a Loading runsheet assigned to another loader; missing explicit company filters are treated as defense-in-depth because RLS currently enforces tenant scope.
- Report: `doc/Draft/Reprots/Report488_LOADER_DAILY_REVALIDATION_PATCH_ORDER_CORRECTION_20261024.md`; current blob SHA `14f63e0526121e0e5597e12e6186101884d3fe0c`; original creation commit `e706b7545e1048bc863d800aa75ba7d7f5c72b3d`; self-contained patch addendum commit `6f2f5c4eaf1411fb347ea03cfde4cf9777eddbac`.
- CURRENT_STATE was updated append-only to LVE-489; current blob SHA `6d7a78709d86e274506761311daed6f3c82d5ca4`, initial checkpoint update commit `e80fa39f79edb01631e2e8d3e326fc1c0812996a`, latest report-fingerprint refresh commit `f8d3e1c2638668cc9745ce2e5f4f889166d6424a`. Prior checkpoints remain preserved.
- Deployment artifact and headers/cache remain UNKNOWN: Cloudflare Pages URL was inaccessible via web, Browser requires an originating browser context, and no Cloudflare MCP tool was available. Staging `hfzznsiprnwkpayskzhu` is INACTIVE and was not restored. No authenticated browser E2E or stock/reservation/log delta test ran. Targeted logs did not establish a matching Loading invocation; this absence is not proof of non-use.
- Status: SOURCE + PRODUCTION REVALIDATED / OWNER PATCH CORRECTED AND STATIC-PARSED IN MEMORY / LOADING CONTRACT CONFLICT OPEN / DEPLOYMENT UNKNOWN / STAGING + BROWSER E2E UNVERIFIED / NOT CLOSED.
- Next: owner re-fetches Loader and verifies SHA, applies Report488 to Loader only, checks full-file syntax on the saved artifact, then validates item detail/image fallback and zero stock/allocated_qty/inventory_log delta in an authorized active isolated Staging. The zero-quantity/notes/direct-save contract remains a separate blocker; do not claim production-ready loading until resolved.



## LAST VERIFIED MEMORY EVENT — LVE-2026-10-28-534 — Delivery Supervisor → Parent Assignment Display

- **Authority:** `CURRENT_STATE.md` LVE-2026-10-28-534 and Report534 are the current execution record; this ledger remains secondary continuity memory.
- **Operational source:** `papamohammed77-glitch/erp-frontend`, branch `main`; latest observed commit `8843150bdde99d36d477d6bb344a24df61dd2942`; Parent blob `0c1745081e8d17480433ed527d77cac9f5292021`; Supervisor blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Production:** at `2026-10-28T18:57:09.323176Z`, RS-1 and RS-2 remained `Loaded` with `deliverer_id`; `delivery_agents` count remained 0. The live `delivery_logistics_query` body matched the current Git migration body exactly after whitespace normalization; migration version `20261027170454` is present.
- **Security:** relevant RPCs remain SECURITY DEFINER with authenticated/service_role EXECUTE and no anon grant; company/auth/permission checks are present in the inspected definitions. No schema, ACL/RLS, operational source, deployment, or business data was changed in this revalidation.
- **Current diagnosis:** the source renders `d.runsheet_assignments` separately and the live RPC returns that projection; source/Production contract drift is not the current proven defect. Do not repeat the Parent patch, create `delivery_agents` records to mirror assignments, change SQL/ACL, or bump Service Worker without new evidence.
- **Open gate:** exact Cloudflare-served artifact and fresh authenticated Parent DOM/Network/Console evidence remain UNVERIFIED because the available browser connector has no originating browser context and direct page fetch was unavailable.
- **Next:** a normally authenticated published Parent session must capture the `delivery_logistics_query(p_view='agents')` response, confirm RS-1/RS-2 in `runsheet_assignments`, inspect the assignment-table DOM, and capture the first Console error if the payload has rows but the table is absent. Preserve the historical MAIN1/security backlog; this event does not close it.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-29-558

- **Authority:** `CURRENT_STATE.md` LVE-558 and Report558 are the current operational checkpoint; this ledger remains secondary continuity memory.
- **Live source:** `papamohammed77-glitch/erp-frontend`, `main`, HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`. Parent Blob `3a5d2e565a04262081d024f6e514e1372d372e84`; Returns main Blob `36c20e03c94dc734e015610dec1e8208697df32a`; PR #8 branch Blob `9cc013a419f6dac2c656471b72f0e629a622a5b6`, commit `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`, open/draft/unmerged.
- **Returns patch:** R8-S1-A/B applied only in memory after re-fetching the exact PR #8 Blob. Each replacement anchor was unique; the resulting inline JavaScript passed V8 syntax parsing; isolated eligibility fixture excluded RS-1 (pending=0), included RS-2 (pending=5), included same-handler Returning, and excluded another handler. No operational file write occurred.
- **Production:** read-only SQL confirms RS-1 Delivered / 5 detail rows / pending 0; RS-2 Delivered / 7 detail rows / pending 5; no current Returning rows. RLS is enabled for runsheets/details; authenticated SELECT is granted; authenticated UPDATE on run_sheet_details is not granted. Active Edge functions start-return v4 and complete-return v26 were not modified.
- **New CI finding:** Main workflow Blob `7f821b2afdcb8d15f205782218b427d06da03a6e` still contains the obsolete Payroll assertion. Run `40928363996` / job `123639862789` failed on commit `0351897` before Parent JavaScript syntax validation or Playwright. PR #7's workflow-only fix remains draft/unmerged and is based on older commit `626df80fae8101fa6b1fe0ba0b6bc8d4ae69f8ca`; it has not been proven against current Parent source.
- **Deployment/runtime:** GitHub check-runs report `rawaea-erp` success on Main `416de1c` and Preview `3ad370c`; `erp-frontend`, `rawaea-store`, and `warehouse-supervisor` fail. Supabase logs at `2026-10-29T18:17:11Z` show old nested-count requests with HTTP 200, but Origin/Referer are blank. Browser connector could not access tabs without originating context; exact served bytes and authenticated E2E remain UNVERIFIED.
- **Staging metadata correction:** current live Supabase project listing reports `rawaea-staging` ref `hfzznsiprnwkpayskzhu` as `ACTIVE_HEALTHY`, replacing the older LVE-484 `INACTIVE` observation. Staging was not used or changed.
- **Mutation ledger:** no operational source, Production schema/RLS/grants/RPC/Edge functions, business data, stock/accounting, or Cloudflare configuration changed. No test data created.
- **Next:** owner applies R8-S1-A/B to the PR #8 branch after rechecking SHA/boundaries, reruns full inline-script parsing and eligibility checks, and does not merge/close until the CI gate is current, Cloudflare failure logs are understood, the served artifact is identified, and authenticated E2E passes.
- **Status:** ROOT CAUSE CONFIRMED / OWNER PATCH READY / MAIN CI GATE STALE / ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-29-559

- **Authority:** `CURRENT_STATE.md` LVE-559 and Report559 govern the current Returns revalidation; ledger remains secondary.
- **Governance restored:** Read permanent operational constitution, Report545, LVE-558/Report558 and Report557 before investigating. Owner-only operational HTML boundary preserved.
- **Source:** `erp-frontend/main`, HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`; Returns main Blob `36c20e03c94dc734e015610dec1e8208697df32a`. PR #8 remains open/draft/unmerged at `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`, Blob `9cc013a419f6dac2c656471b72f0e629a622a5b6`.
- **Root cause:** main list and search do not filter Delivered runsheets by `qty_loaded - qty_delivered - qty_returned > 0`; the candidate PR fixes the core list/search quantity condition but requires R8-S1-A/B to scope Returning search results to the assigned handler and propagate nested Promise failures.
- **Production:** read-only values RS-1 pending=0, RS-2 pending=5; no current Returning rows in inspected sample. No writes or test data.
- **Deployment:** cloudflare bot recorded successful `rawaea-erp` Preview for commit `3ad370c`; three other project builds reported failure without examined logs. Exact Production artifact and authenticated E2E remain UNVERIFIED.
- **Mutation ledger:** only Report559, CURRENT_STATE, and this ledger updated in governance repository; operational repo, Production, and Cloudflare config untouched.
- **Next:** owner patch R8-S1-A/B on PR branch only, rerun syntax/isolated eligibility tests, inspect relevant build logs, verify exact served artifact and authenticated E2E; do not merge/close early.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-29-560

- **Authority:** `CURRENT_STATE.md` LVE-560 and [Report560_RETURNS_ELIGIBILITY_OWNER_PATCH_DEPLOYMENT_RECHECK_20261029.md](doc/Draft/Reprots/Report560_RETURNS_ELIGIBILITY_OWNER_PATCH_DEPLOYMENT_RECHECK_20261029.md), report commit `8e60085e6e6e184b0b0ff4b5f35864a7301d2fe6`.
- **Governance:** read permanent operational constitution SHA `365a5178810d8da37f55dba64bf422f328a966bd` and Report545 SHA `e153396709ecfcc0552347db84e37c98ad8bcdd6`. Operational HTML ownership rule remains active.
- **Source:** `erp-frontend/main` HEAD `416de1c1d829c48b7c82442242a2a039e3d7e48c`; Returns main Blob `36c20e03c94dc734e015610dec1e8208697df32a`; Parent Blob `3a5d2e565a04262081d024f6e514e1372d372e84`; Driver Blob `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`.
- **Root cause:** current Returns main list loads every `Delivered` runsheet, omits `qty_returned` from detail projection, counts rows by `qty_loaded > qty_delivered`, and never filters `available` by outstanding return quantity. Search lacks both remaining-quantity filter and Returning assignment scope.
- **Candidate:** PR #8 is open/draft/unmerged at commit `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`, Returns Blob `9cc013a419f6dac2c656471b72f0e629a622a5b6`. Core list patch exists on this branch only. Report560 reproduces owner-only R8-S1-A/B: add `return_handler_id` to search select; return nested details Promise and filter Delivered by positive remaining and Returning by current handler.
- **Production read-only:** `2026-10-29 19:03:17.860357+00`, PostgreSQL 17.6; `RS-1` Delivered, 5 detail rows, pending return 0; `RS-2` Delivered, 7 detail rows, pending return 5; no Returning/Returned sample rows. No business data, schema, RLS/ACL, functions, stock, or accounts were changed.
- **Cloudflare:** dashboard shows Production Main `416de1c` at `https://b469734c.rawaea-erp.pages.dev/` and PR #8 Preview `3ad370c` at `https://da5fcdde.rawaea-erp.pages.dev/`. Exact artifact bytes and authenticated Parent → Driver → Returns E2E remain UNVERIFIED.
- **Isolated test:** synthetic in-memory predicate check passed (exclude Delivered pending=0; include pending>0; Returning only when assigned to current user; reject other state/handler). This did not alter source or DB and is not full-file syntax or E2E verification.
- **Mutation ledger:** only Report560, CURRENT_STATE and this ledger changed. No operational HTML, PR branch, Production, or Cloudflare settings changed.
- **Next:** owner re-fetches PR #8 and verifies current Blob SHA/unique anchors before applying R8-S1-A/B on that branch only; run full inline-JavaScript syntax and eligibility tests, investigate actual failed build logs, prove served artifact identity and authenticated E2E before merge/closure.
- **Status:** ROOT CAUSE CONFIRMED / OWNER SEARCH PATCH REQUIRED / PRODUCTION READ-ONLY / ARTIFACT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.


---

## LVE-2026-10-30-562 — Data Entry Master App candidate and Production ACL gate

- Read CURRENT_STATE first, the permanent operational constitution, Report545, Report500, Report560, Report561, and the current operational source. CURRENT_STATE previously had LVE-560 at the top while LVE-561 existed later in the same file; LVE-562 is now promoted to the opening checkpoint, preserving history.
- Operational repository: `papamohammed77-glitch/erp-frontend`, `main`, latest observed HEAD `2e9777a23f44e1b009810c0936513a76e64cc741`. Parent `main.html` Blob `3a5d2e565a04262081d024f6e514e1372d372e84`; shared `core.js` Blob `ff2f581d9900543c16f7cb026e13446520c0329d`.
- Studied Parent `RW_Items` module (approx. lines 4881–6740): list, filters/sort/pagination, 3-panel item form, category modal, product image viewer/upload, movement report, branch matrix, and Excel/CSV stock adjustment. Existing `picker.html` / `loader.html` are integration references, not an officially documented “golden/diamond” registry. Do not invent a formal gold-app list.
- Candidate `/mnt/data/data.html`, SHA-256 `131b6655155ed353d7d1f766a0efc5b2b07de1579c406b60cbc5eb1ca1d9dd05`, 82,081 bytes. Intended canonical path `companies/company-1/warehouse/data.html`; current repo uses lowercase `warehouse/`, and no uppercase `Warehouse/` directory exists. Candidate reuses `core.js`, current manifest/service worker, and existing Edge Functions; no direct browser writes to business tables and no new Edge function/table.
- Static HTML parse and Node inline-JavaScript syntax check PASS; static contract checks PASS. No browser E2E, deployment, operational HTML commit, or Production write occurred.
- CRITICAL CONFIRMED Production ACL exposure: read-only SQL showed anon has `TRUNCATE` on `items`, `categories`, and `branches`; authenticated also has `TRUNCATE` on those tables. RLS is enabled but does not restrict TRUNCATE. The `categories` policy `Allow all for all` applies to `{public}`, command `ALL`, `qual=true`; anon also has category DML privileges. No destructive test or grant/RLS change was made.
- Existing `save-item` v15 contract converts `reorder_point=0` to 5 due `Number(item.reorder_point) || 5`; candidate blocks zero to avoid silent mutation. Category update payload preserves `parent_id`, `image_url`, and `icon`. Bulk adjustment preview rejects nonzero inventory deltas where item cost is not configured and retains the operation fingerprint for safe retries.
- Governance: operational HTML remains owner-applied. Report562 records exact minimal Parent menu/action insertion and all evidence. Do not deploy the candidate until the ACL issue is reviewed and safely remediated with consumer impact and rollback checks.
- Authoritative report: `doc/Draft/Reprots/Report562_DATA_ENTRY_MASTER_APP_OWNER_HANDOFF_20261030.md` (report commit `20392c386cd8b125358875cb5ef8208ef3640bf5`). CURRENT_STATE update commit: `75172e727da21f98f4c89621eb806e290046bc76`.
- Status: `CANDIDATE GENERATED / STATIC PASS / CRITICAL ACL BLOCKER OPEN / OWNER PATCH PENDING / NO PRODUCTION MUTATION / NOT PRODUCTION READY / NOT CLOSED`.


## LAST VERIFIED MEMORY EVENT — LVE-2026-10-30-565

- **Authority:** Governance `CURRENT_STATE.md` LVE-565 and `Report565_RETURNS_LIVE_RECHECK_DEPLOYMENT_AND_DATA_EFFECTS_20261030.md`; this ledger is secondary.
- **Operational source:** `papamohammed77-glitch/erp-frontend`, `main`, HEAD `5745f36cd1e4e3707b84cead4d35aaf8a9882e75`. Returns Blob `16d02fff2d00759451879204abf218202898f9c0`; app router Blob `ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4`.
- **Source status:** Owner commits `671a4cf` and `5745f36` now contain the Delivered pending-quantity filter, matching search filter, Returning assignment restriction, preview quantity logic, UUID identity, image relation/helper, and query error handling. Inline JS parsing PASS. No Browser E2E.
- **PR #8:** still open/draft/unmerged at `3ad370c83f8f3c7880d7ace9ac24eabb5833f9cf`; its branch does not contain the current Main search/image updates. Do not merge or reapply its old patches.
- **Production return event:** RS-2 completed on 2026-10-30 at 17:29:06Z; loaded 6, delivered 1, returned 5. Edge start/complete calls HTTP 200. One Posted credit note 528.00, balanced journal 528.00/528.00, five SalesReturn inventory movements, and 12/12 projection groups match. RS-1 is Delivered but has pending=0; RS-2 is Returned; no active Returning row.
- **Deployment:** last recorded Cloudflare source commit `9e3fe134` is four commits behind current Main. Its Returns blob lacks the new pending filter. Current served artifact, headers, and build lineage remain UNVERIFIED; the successful backend event does not prove which UI build was served.
- **Workflow contract:** authenticated UPDATE on `run_sheet_details` is not granted and no UPDATE RLS policy exists. `saveReturnItem` still attempts that update and ignores the result; drafts are device-local until `complete-return` commits through `complete_sales_return_credit_note_atomic`.
- **Cancellation:** `cancelReturn` does not delete Dexie `localChanges`; later sessions reload them. Whether cancel should preserve or discard is UNKNOWN and requires owner decision.
- **Security:** categories still has public ALL true/true; stock_discrepancies has public SELECT/INSERT true; anon/authenticated TRUNCATE privileges remain on sensitive operational tables. Critical ACL gate remains open; no grants/RLS changes.
- **Mutation ledger:** only Report565, CURRENT_STATE and this memory ledger changed. No operational source, PR, Cloudflare, Production schema/permissions/functions, business data, stock or accounting were changed.
- **Next:** verify Cloudflare Production commit/build lineage and served Returns/core bytes plus headers against Main `5745f36`, then authenticated read-only Browser E2E. Do not merge PR #8.
- **Status:** SOURCE PATCH PRESENT / BACKEND RETURN TRANSACTION CONFIRMED / DEPLOYMENT + UI E2E UNVERIFIED / LOCAL CANCEL-DRAFT INTENT OPEN / CRITICAL ACL BLOCKER OPEN / NOT PRODUCTION READY / NOT CLOSED.

## LAST VERIFIED MEMORY EVENT — LVE-2026-10-31-568 — Parent Realtime Authorization Contract

- **Authority:** Canonical `CURRENT_STATE.md` LVE-568 and Report568. The operational source repository's separate handoff remains Phase 3 Parent channel compatibility; it is newer than the former canonical LVE-567B checkpoint but predates the current operational HEAD.
- **Live source:** `papamohammed77-glitch/erp-frontend`, `main`, HEAD `65799d282acc79359b17a1a13dcd68f62859e1fb`. Parent blob `53b5a9e9d0433a785c3d5471a9c0d68c25497882`; Core blob `a95ee6b29ff54b4a240ce4b81f9a535aa87686db`.
- **Parent Realtime:** 11 direct `.channel()` call sites are present, while the operational handoff records 8. Four current channels are incompatible with Production: Sales Decision and Loyalty are not published and explicitly deny authenticated table access; Customer Payments and Commission are published but service_role-only. Parent does not load core.js, use RW_Realtime/get_my_effective_profile, or provide focus/visibility refresh for these modules.
- **Read APIs:** Sales Decision v1, Loyalty v1, and Customer Payment v2 Edge sources match active Production sources byte-for-byte. Commission v3 is active with JWT verification but has no source file in either GitHub repository.
- **Permission mismatch:** Production get_my_effective_profile merges users.permissions, roles.permissions, and role_permissions. Core uses it; Parent login reads only users.permissions, while session restore uses JWT metadata or defaults to `['*']`. Several Edge/RPC permission checks omit role_permissions. Production has 21 role_permissions rows across 3 roles; at least one active user relies on role_permissions alone for finance, orders, pos, purchases, and warehouse. Actual account behavior was not tested.
- **Production:** Realtime publication has 81 tables. Migrations 20261031153418 and 20261031171715 are applied but absent from the operational `supabase/migrations` directory. Inventory-count tenant policy remains scoped; inventory_counts has zero rows; no active authenticated Counter user exists; active auth-linked users are in one company only.
- **CI/runtime:** Four workflows on current HEAD passed, but no authenticated Parent Realtime E2E ran. Earlier Warehouse Vouchers Browser E2E run 41217489614 failed on commit 8140235 and was not rerun on 65799d2. Cloudflare artifact, browser event delivery, and two-company isolation remain UNVERIFIED.
- **Mutation ledger:** Read-only Production inspection and GitHub reads only. No operational source, Production schema/RLS/grants/publication/Edge deployment, business data, stock, accounting, or Cloudflare configuration changed. Report568, canonical CURRENT_STATE, and this ledger were updated only.
- **Next:** reconcile Parent and Edge Function authorization with the effective-profile contract including role_permissions, and version-control the active Commission v3 source. Then prepare the owner-applied surgical Parent refresh patch using the existing authenticated Edge read APIs; do not weaken RLS or broaden publication.
- **Status:** FOUR DIRECT CHANNEL CONTRACTS INCOMPATIBLE / PERMISSION RESOLVER DIVERGENCE CONFIRMED / COMMISSION SOURCE PROVENANCE GAP / DEPLOYMENT + AUTHENTICATED E2E UNVERIFIED / PHASE 3 OPEN.

## 14. BUYER PURCHASING WORKFLOW — LVE-2026-10-31-569
- Current operational Buyer: companies/company-1/purchasing/buyer.html, blob 6ba510cff5250ba196528b14237ae400e544771a, 137 lines; three tabs only (orders/new/suppliers). Realtime purchase_orders integration exists in source, but authenticated browser E2E and Cloudflare served artifact are unverified.
- Production save-purchase-order v7 (verify_jwt=true, SHA-256 8e8c419c94796d8b802976ff8f3bb9717c039a8701a1523736cb531b2cc6a6cd) matches canonical Current/Edge_Functions/save-purchase-order blob ade8ae3b34b55c00bb8c2e9986e2ec5b72013574 byte-for-byte. That canonical source is not present in operational repo tree. Buyer still sends legacy {orderHeader,itemsList} rather than {operation,payload}.
- Critical open authorization findings: Edge v7 validates JWT/company but does not check business permissions before service_role operations; purchase_get_dashboard(uuid) is SECURITY DEFINER with PUBLIC/anon/authenticated EXECUTE and no auth-bound company check; get_my_effective_profile includes role_permissions but app_private.current_user_has_permission omits them, while suppliers/items RLS relies on that helper.
- Critical PR defects: purchase_submit_request_atomic writes nonexistent changed_by/changed_at columns although purchase_status_history has action/actor_email/created_at and an existing trigger already writes history. purchase_create_request_atomic and purchase_create_invoice_atomic item lookups need company_id guards.
- Existing purchase backend supports PR/RFQ/quotation/PO/invoice/returns/payments/reports. Direct purchase invoice can be created without PO and posted through central stock movement, journal, and supplier ledger. Existing settings: require_inventory_on_invoice=true, require_receiving_before_invoice=false.
- Confirmed missing contracts in current schema/UI: PO expected delivery date/payment terms/send/approval operation; supplier email/A-B-C rating/visits; buyer-specific custody ledger; explicit transfer payment method; OCR operation. PR details lack department_id and received_qty; receipt qty is on PO details. No supplier visit/rating or dedicated buyer custody table found in inspected public schema.
- Production data snapshot during audit: PR 0; PO 1 Draft; invoices 3; quotations 0; payments 0; returns 0; status_history 5.
- Report: doc/Draft/Reprots/Report569_BUYER_PURCHASING_WORKFLOW_FORENSIC_AUDIT_20261031.md.
- No app, Edge, RLS/ACL/RPC, migration, business-data, stock, accounting, or deployment change was made. Continue with backend authorization and contract repair before expanding Buyer UI. Treat Report569 as an audit checkpoint, not task closure.


## LVE-2026-11-01-571 — Buyer Purchasing Integration / Production Contracts

- Buyer file directly modified in papamohammed77-glitch/erp-frontend: companies/company-1/purchasing/buyer.html. Six-tab controller now calls the existing save-purchase-order Edge contract; no direct Supabase table queries in Buyer. Shell, CSS, shared core, main.html and other operational apps were not modified.
- Buyer source blob: 8da37a94b24c86d4bba65fab81273263e6306eae. Latest operational HEAD at verification: c886554765af5b473513ab4d8ca25ce01145ce56.
- save-purchase-order Edge v11 ACTIVE, verify_jwt=true, deployed SHA-256 c5e0dd68dd3bf42cd8271fd3a9672d9a09c512df7036e4553d464e527e9615aa; exact byte match with Git source.
- Nine Production migrations applied and committed under supabase/migrations: company-scoped PR/Invoice/Quotation item lookup; dashboard anon/tenant/permission guard; supplier effective permissions; PR Submitted state and status history fixes; actor attribution; PO status history trigger; Receiver actor; audit_log receive action; wildcard permission alignment.
- Rollback-only SQL tests passed: PR submit/approve/reject/RFQ conversion, RFQ send, quotation create/accept/convert, PO creation, Receiver receipt with +1 stock effect and correct audit actors, direct invoice Draft with no stock/journal effect, supplier RPC, and dashboard anon denial/service-role success.
- All QA test writes rolled back. Final QA residue counts are zero; business entity counts match Report569 baseline.
- Buyer supports Today, Suppliers, PR, PO, Custody placeholder, Account; quick purchase only creates Draft invoice. Supplier visits/ratings/classification/email, custody ledger, PO manual create/send/approval/expected delivery/terms, direct no-PO receiving, OCR/camera and payment method are still open contracts.
- Lists are capped at 500 rows and client-side search; server pagination/search remains open.
- Report: doc/Draft/Reprots/Report571_BUYER_PURCHASING_INTEGRATION_EXECUTION_20261101.md (commit 6c9fc6e48c8009fd551ad31c027e4e5eee8d5c49).
- NOT VERIFIED: Cloudflare served artifact, authenticated browser E2E, multi-user HTTP Edge permission tests, and live PR/RFQ/PO Realtime.
- Next priority: define and implement PO expected-delivery/terms/approval/supplier-dispatch contract without bypassing Receiver or accounting/inventory controls.


## LVE-2026-11-01-572 — Buyer Realtime / Effective Permission / Edge Dispatch Repairs

- Verified operational repo `papamohammed77-glitch/erp-frontend`, branch `main`, HEAD `511efd0cd032183515e5834027abe949d9e55649`.
- Current Buyer blob `996bb04ebe6e3c8b34586e2cef2c52ec01400fbb`; app router `companies/company-1/app.html` blob `2e47a68fe83956e27d569e786a08dcee91af2924`; Buyer shared Core `core.js` remains `a95ee6b29ff54b4a240ce4b81f9a535aa87686db`.
- Buyer now subscribes through existing RW_Realtime to 12 published purchasing/master-data tables; reconcile interval 30s; cache invalidation maps events to Today/Suppliers/PR/PO/Account. The realtime connection indicator is implemented. This is source/configuration confirmation only: actual websocket SUBSCRIBED and event delivery remain UNVERIFIED until authenticated browser E2E.
- Buyer PR approval/rejection actions now appear for Submitted and PendingApproval; label changed to "مرسل للاعتماد".
- SAVE_SUPPLIER Edge preflight no longer invokes the RPC before the call helper/data variables are declared. Execution is after declaration and authorization. Source commit `91c1a20a90cd6372a811d7b8f46095aa2548b3d8`.
- Existing `save-purchase-order` Production is now v12 ACTIVE, verify_jwt=true, SHA256 `4748aede3bd45c6fce4b251408f4ca91a6368e7abeae36a3d87e182e4e723d37`; deployed `index.ts` exact-byte-matches operational Git blob `508aee8b7941ef3d631d4a61ab60e336f1ed8836`. No direct HTTP invocation was available; authenticated SAVE_SUPPLIER runtime remains UNVERIFIED.
- `app.html` now calls `get_my_effective_profile()` and routes on merged `users.permissions`, `roles.permissions`, `role_permissions`, `active_warehouse_role`, `isOwner`; errors fail closed instead of using stale JWT permission metadata. Commit `9016396ab29c88a9014ecff9f602ed94c50c7023`. Parent main.html was deliberately not edited (owner-only handoff).
- Applied six new Production migrations and committed exact SQL files to operational repo:
  1. `20261031230252_buyer_realtime_read_permission_alignment_20261101`
  2. `20261031230550_buyer_purchase_views_use_caller_rls_20261101`
  3. `20261031230557_buyer_purchase_requests_remove_end_user_truncate_20261101`
  4. `20261031230603_buyer_purchase_remove_end_user_truncate_grants_20261101`
  5. `20261031230748_buyer_purchase_reporting_views_revoke_anon_select_20261101`
  6. `20261031231142_buyer_purchase_trigger_functions_pin_search_path_20261101`
- RLS SELECT for suppliers/items/branches/stock_branches is aligned to effective purchase permission while retaining company scope and previous operational grants; no end-user INSERT/UPDATE/DELETE grants were opened.
- Three purchase reporting views now use security_invoker; anonymous SELECT revoked. Supplier-ledger policy includes effective purchases permission within tenant scope. TRUNCATE grants now zero for anon and authenticated across inspected purchase tables/views. Both purchase trigger functions have empty pinned search_path; their 7+7 triggers remain enabled.
- Read-only rollback tests: role_permissions-only purchaser profile includes purchases and can read company rows (supplier balance 4, invoice aging 3, items 30, stock rows 57); direct purchaser likewise sees expected rows; anon supplier/items/branch/stock returns zero/denied. No production business data, stock, or accounting rows were changed.
- Inline JS syntax parse succeeded for Buyer (48,979 chars) and app router (8,181 chars). This is not E2E.
- Missing business contracts remain OPEN: PO expected delivery/payment terms/approval/supplier dispatch; supplier email/A-B-C/rating/visits/GPS/photo/voice; independent Buyer custody and settlement; payment_method in post_payment RPC; supplier invoice number persistence and direct no-PO receiving/OCR; PR department/received remainder; server pagination/search over 500-row cap.
- Cloudflare Pages artifact and authenticated browser E2E remain UNVERIFIED. Browser tab showed login screen; available browser control was read-only. Realtime publication and RLS compatibility are confirmed, not actual websocket event delivery.
- Security Advisor no longer reports SECURITY DEFINER view warning for the three purchase views or mutable search_path for the two purchase trigger functions. System-wide warnings remain (24 RLS-without-policy INFO, 1 mutable search_path outside purchases, 19 anon SECURITY DEFINER, 121 authenticated SECURITY DEFINER, leaked-password protection disabled); do not claim global security closure.
- Detailed Arabic report: `doc/Draft/Reprots/Report572_BUYER_REALTIME_AND_ROUTER_PERMISSION_REPAIR_20261101.md`, latest report commit `53789915a414fcbd3caea851a788653aab55e599`.
- Realtime coverage limit: RW_Realtime subscribes INSERT/UPDATE only. Buyer’s 12 channels do not independently include all detail/history tables (e.g. purchase_request_details, purchase_rfq_details, purchase_quotation_details, purchase_invoice_details, purchase_payment_allocations, purchase_return_details, purchase_status_history). A detail-only change or DELETE is not guaranteed to trigger immediate UI refresh; parent-row change or 30s reconcile may refresh later. Live WebSocket remains UNVERIFIED.
- Status: `PARTIAL REPAIRS CONFIRMED / EDGE v12 BYTE-MATCHED / RLS READ CONTRACTS HARDENED / SOURCE REALTIME WIRED / DEPLOYMENT + WEBSOCKET RUNTIME UNVERIFIED / BUSINESS CONTRACTS OPEN / NOT CLOSED`.



## LVE-2026-11-01-573 — Buyer Custody / Auth / Realtime / Tailwind

**Verified at:** 2026-11-01 Africa/Cairo.  
**Operational repo HEAD:** `papamohammed77-glitch/erp-frontend/main` — `1db1db2927005d12a1531b7518d103c4c7b8140f`.  
**Production Edge:** `save-purchase-order v18 ACTIVE`, `verify_jwt=true`, exact source byte match; deployed SHA-256 `e9fab386b72cc9e3d10b49931324117dea1e2df6828cb50d9e8d010e0923996f`.

### Root cause and repair
- Browser console's `PURCHASE_AUTH_REQUIRED` was traced to `purchase_get_dashboard` checking `current_setting('request.jwt.claim.role', true)`. Under the service-role RPC context that setting was NULL while `auth.role()` returned `service_role` and `auth.uid()` was NULL. The old test misclassified service_role as a normal authenticated user and raised `PURCHASE_AUTH_REQUIRED`.
- The function now uses `auth.role()`; direct service-role dashboard test passes. Authenticated `finance_manager` dashboard test also passes.
- Edge `GET_SUMMARY` now calls the RPC using the caller JWT through `profileClient`, retaining user/company/effective-permission checks rather than using service_role for this read.
- Edge v18 dispatch and role gates include `finance` and `finance_manager` for custody administration and the required Buyer read surfaces.

### Buyer employee custody contract
- Added `buyer_custodies`, `buyer_custody_expenses`, `buyer_custody_settlements` with RLS and company/employee scope.
- Workflow: finance records manual issuance; employee acknowledges receipt; employee submits PDF/image expense documents; finance approves/rejects; settlement waits until all submitted expenses are reviewed and the full unspent cash is manually received/recorded.
- Enforced currency consistency, complete cash reconciliation before closure, and separation of duties (no self-approval or self-settlement).
- New SECURITY DEFINER RPCs are executable by authenticated only; anon execute is false. Direct authenticated INSERT/UPDATE/DELETE on custody tables is false; SELECT is RLS-scoped.
- Storage uses private `employee-documents`; path policies were corrected to qualify `storage.objects.name` (avoiding ambiguity with `users.name`), and an owner-only cleanup policy was added. Finance/finance_manager can read company custody documents.
- Full SQL workflow test (issue 100 SAR → employee document metadata insert → expense 40 SAR → finance approval → cash return 60 SAR → settlement balance 0) passed inside ROLLBACK. Employee and finance document SELECT policy checks both passed. This validates SQL/RLS metadata path, not real browser binary upload/download or Storage API delete.
- Buyer tab now supports employee submission and finance issue/review/settlement. Accountant and Finance Manager screens link to Buyer custody workspace. Parent `main.html` was not modified.

### Realtime and Core
- Buyer now subscribes to 26 tables covering PR/RFQ/quotation/PO, detail rows, invoices/payments/returns, history/attachments/document links/settings, custody, suppliers/items/branches/stock.
- Production query confirms all 26 tables have RLS enabled, authenticated SELECT, a SELECT/ALL policy, and membership in `supabase_realtime`.
- Shared `core.js` blob: `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`; normalizer supports per-table event selection while default remains INSERT/UPDATE.
- Buyer debounce 400ms; reconcile 15s; tab-specific invalidation; MutationObserver drains pending refresh after modal closure.
- DELETE is not subscribed; it is caught by reconciliation, so DELETE is not guaranteed instant. Live authenticated WebSocket delivery/reconnect E2E remains UNVERIFIED.

### Production CSS and source
- Buyer no longer references `cdn.tailwindcss.com`; it links local `buyer.tailwind.css` (blob `25b1b840e0a03c42d3de2593b08baf6af95d0f4b`, 15,038 chars).
- GitHub Actions workflow `.github/workflows/buyer-tailwind-build.yml` compiles CSS; build commit `1fa7a3d73dc73645b1dc88b2ad33c41ecfe37bec`.
- Buyer blob: `ee2fb5676a99a9c17371b3a7f44ab0b2bb320506`.
- Edge source blob: `6d6b6ce45a18e6275f043b6e397da528d2c58124`.
- Accountant blob: `74794dd24277eac92c652061b2540d5cb772425e`.
- Finance Manager blob: `db8a5c4ef7029833ec7777dd4f992f737475e85f`.
- Static JavaScript parse passed for Buyer, Core, Accountant and Finance Manager.
- Eight new migrations are applied and committed under operational `supabase/migrations/`, versions from `20261031233331` through `20261031235057` covering custody, publication, separation of duties, finance-manager permissions, dashboard auth.role, storage path policies, and currency/reconciliation.

### Unverified and open
- Cloudflare Pages served commit/artifact and local CSS delivery remain UNVERIFIED.
- Authenticated browser E2E, real Storage API file upload/download/delete, live WebSocket events and reconnect remain UNVERIFIED.
- Core only emits INSERT/UPDATE; DELETE refresh is periodic (15s), not instant.
- Business contracts still OPEN: PO expected delivery/payment terms/approval/send, supplier email/grade/rating/visits, payment_method in payment RPC, supplier invoice number persistence, direct no-PO receiving/OCR, PR department/received aggregates, and server-side paging/search beyond 500.
- Security Advisor still has system-wide findings outside this task: 24 RLS-enabled/no-policy INFO, 1 mutable search_path outside Buyer, 19 anon SECURITY DEFINER, 121 authenticated SECURITY DEFINER, leaked-password protection warning. Do not claim global security closure.

**Arabic report:** `doc/Draft/Reprots/Report573_BUYER_CUSTODY_AUTH_REALTIME_TAILWIND_20261101.md` (report commit `18577462ab54f7cf3f1dc8f9b4b42161f2730330`).  
**Status:** `PARTIAL REPAIRS CONFIRMED / ROOT CAUSE CONFIRMED / CUSTODY SQL+RLS ROLLBACK-TESTED / EDGE v18 BYTE-MATCHED / 26 TABLES RLS+PUBLICATION VERIFIED / TAILWIND CDN REMOVED FROM SOURCE / CLOUDFLARE+RUNTIME E2E UNVERIFIED / BUSINESS CONTRACTS OPEN / NOT CLOSED`.


---

## LVE-2026-11-01-574 — Buyer Currency / Modal Parity / Custody & PO Accounting

**Verified date:** 2026-11-01 Africa/Cairo.  
**Operational repository HEAD at checkpoint:** 488dfe79f6d9291e649ee0db78d1ffb3af70e91a.

- Production database SMART ERP company currency is EGP. The observed Cloudflare Production dashboard snapshot was still serving commit 1db1db2, whose Buyer source used SAR as a currency fallback. This explains the SAR display as a stale deployed Buyer artifact, not a parent app_settings value. The current Buyer source removes the SAR fallback and refreshes GET_SETTINGS before currency-sensitive supplier, PO, custody issue and account flows. Latest deployment of 488dfe7 remains unverified.
- Buyer source updated in commit 1904b620a62a6e8b07234752caf6d27ad934be0d; blob 6c26444fa80b198d305727b70791f400839a6f75. Inline JavaScript syntax parse PASS (100,666 chars). Supplier modal, purchase invoice draft modal and new PO modal are present; source-level layout/fields reviewed against parent main.html. Parent main.html was not modified.
- Database migration 20261101120225_buyer_currency_po_receipt_and_supplier_balance_reconciliation_20261101 applied to SMART ERP and saved in operational repo under supabase/migrations/20261101120225_buyer_currency_po_receipt_and_supplier_balance_reconciliation_20261101.sql. It enforces app_settings currency on invoice creation, prevents PO-linked invoice posting from duplicating stock and supplier liability already recorded by receiving, revalidates custody invoice/receipt line details at finance approval, and synchronizes suppliers.accounts_payable from supplier_ledger via a restricted app_private trigger.
- Custody workflow includes original cash issue, additional treasury-backed advances, employee acknowledgement per advance, supplier invoice + warehouse receipt documents, finance approval/payment journal and supplier-ledger debit, and exact cash-return settlement. Additional advances increase issued_amount and are not spendable until acknowledged. Authenticated end-to-end execution of this full top-up path and real Storage binary upload/download was not completed because no authenticated employee/finance browser session was available; do not claim it was tested.
- SQL rollback E2E PASS for PO fixture → warehouse receiving → linked invoice posting. PO header/details were inserted directly inside the rollback transaction; authenticated CREATE_PO RPC/UI was not exercised: SAR rejected; EGP accepted; stock quantity changed 1→2 on receiving and remained 2 after invoice posting; supplier accounts_payable and supplier_ledger both changed 0→10 on receiving and remained 10 after invoice posting; one receiving journal remained one (no duplicate posting). Entire transaction rolled back.
- Supplier accounts_payable vs ledger read-only precheck: 4 suppliers, 0 mismatches. Test residue query: 0 E2E PO, invoices, receiving, custody, expenses or Storage objects.
- Custody invoice approval currently requires PO-matching unit price with zero discount/tax until tax/discount accounting mappings are designed. Mismatches are rejected rather than silently posting an unsupported difference.
- Arabic report: doc/Draft/Reprots/Report574_BUYER_CURRENCY_MODAL_PARITY_CUSTODY_PO_ACCOUNTING_20261101.md (commit 6e844f1f7557484178b40b4e3bc82f1478eeb161).
- Current open gates: verify Cloudflare production deployment and live Buyer artifact; authenticated browser E2E for supplier/PO/invoice/custody top-up; real Storage API binary operations; tax/discount PO accounting design. Status remains PARTIAL / NOT CLOSED.


---

## LVE-2026-11-01-575 — Buyer Production Recheck / Migration Lineage / RLS / Supplier AP

**Verified date:** 2026-11-01 Africa/Cairo.
**Operational repo:** papamohammed77-glitch/erp-frontend, main, HEAD 488dfe79f6d9291e649ee0db78d1ffb3af70e91a (unchanged from LVE574).
**Buyer blob:** 6c26444fa80b198d305727b70791f400839a6f75.
**Edge source blob:** 49c85a4a4648bcef6892476d92037ca56745f633.
**Production:** SMART ERP fiilmooggumokxanwiyx; app_settings.currency = EGP.
**Production Edge:** save-purchase-order v21 ACTIVE, verify_jwt=true, deployed SHA-256 dab3eba49dd355080cadaa5bca4aea02056de19c4b6f3ba581f142cccfa0ea8c. The retrieved deployed index.ts matched current Git content exactly (21,007 chars).

### Confirmed current contracts
- Buyer CREATE_INVOICE calls save-purchase-order operation CREATE_INVOICE; Edge calls purchase_create_invoice_atomic_v2; Production wrapper delegates to purchase_create_invoice_atomic, which enforces company system currency from app_settings. Production has currency EGP.
- Buyer manual CREATE_PO calls purchase_create_po_atomic using caller JWT. Production function exists, checks active user/company/effective purchases permission, idempotency, supplier/branch, app currency and status history.
- Production custody add-advance / employee-acknowledgement / expense submit / finance review / settlement RPCs exist and were inspected. Add advance posts treasury accounting and increases issued_amount; employee must separately acknowledge the additional advance before it becomes spendable.
- Custody tables have RLS, authenticated SELECT only and no direct end-user DML/TRUNCATE ACL. purchase_requests, purchase_invoices and purchase_invoice_details have anon/authenticated TRUNCATE denied.
- Read-only supplier check: 4 suppliers, stored AP total 3,970 equals supplier_ledger net total 3,970; zero stored-vs-ledger mismatches.
- buyer_custody_payments currently has zero rows and no orphan/cross-company references in the snapshot.

### New conflicts and security findings — do not patch speculatively
- Migration lineage conflict: Production records custody/auth migrations at versions 20261031233331..20261031235057, while current Git migration directory has corresponding logical files renumbered as 20261101010000..20261101018000. Production also records 20261101003853, 03952, 05159, 05218, 05616, 05849, and 10224, with no same-version/name SQL files in the inspected current migration directory. Production functions purchase_create_po_atomic and buyer_custody_add_advance_atomic were not defined by the inspected current Buyer migrations. Do not run supabase db push or new migrations until every applied version maps to its exact source file/blob/commit or its absence is explained.
- Production policy buyer_custody_payments_scoped_select contains c.company_id = c.company_id, a tautology rather than a correlation to buyer_custody_payments.company_id. Malformed policy predicate is confirmed; actual cross-tenant exposure is unverified because the table is empty and effective RLS context also applies.
- supplier_ledger has two active AFTER INSERT/UPDATE/DELETE triggers writing suppliers.accounts_payable: app_private.sync_supplier_accounts_payable() calculates SUM(credit-debit), and public.sync_supplier_accounts_payable_from_ledger() uses latest ledger balance. Current snapshot reconciles, but trigger order/behavior under ledger corrections or concurrent writes has not been tested. Neither trigger was changed.
- public.suppliers grants TRUNCATE to anon and authenticated despite RLS. Grant is confirmed; HTTP/PostgREST exploitability was not tested. This is distinct from purchase tables whose TRUNCATE grants are already revoked.

### Runtime and non-execution limits
- Cloudflare Pages current served commit/artifact, headers/cache and deployment lineage remain UNKNOWN.
- Authenticated Buyer browser E2E, Console/Network, actual Storage binary upload/download/delete, and Realtime WebSocket events/reconnect remain UNVERIFIED.
- No Production DDL, RLS/grant/trigger change, Edge deployment or business-data write was made during LVE575. All SQL in this pass was SELECT/read-only. Prior LVE574 rollback test is historical evidence and was not repeated.

### Required next step
Migration Lineage Reconciliation first: map each Production-applied migration version to exact SQL path/blob/commit, restore missing SQL from trusted history or document its origin, and explain renumbered migration files without changing Production. No db push. After reconciliation, separately design and test the custody payment RLS correction, choose one authoritative Supplier AP trigger, and revoke excess suppliers TRUNCATE privilege under a reviewed rollback plan.

**Arabic report:** doc/Draft/Reprots/Report575_BUYER_PRODUCTION_RERECHECK_MIGRATION_RLS_AP_20261101.md (latest update commit fff147ac5a22f5b8648f6495559594306f45d42d).
**CURRENT_STATE update:** commit f48fb6d37ce4f9707ecdcbb083704fdd4cef0ffb; new blob d459658f080a5c952dca244b661790c0e3aae804.
**Status:** LVE574 source/DB repairs remain present; Edge v21 source-byte-match confirmed; EGP confirmed; migration lineage conflict blocks safe migration; custody-payment RLS predicate defect confirmed; duplicate supplier AP triggers confirmed; suppliers TRUNCATE grant confirmed; Cloudflare/authenticated runtime UNVERIFIED; NOT CLOSED.

---

## LVE-2026-11-01-578 — Buyer Migration Lineage Reconciled / Supplier AP Trigger Still Dual

**Verified date:** 2026-11-01 Africa/Cairo.  
**Operational repository:** papamohammed77-glitch/erp-frontend, main, HEAD 40bd00c91f8c52260d867f5cf020104c9e71c161 (tree 4b4b36a5ee73868a058f01dde00229c510a91cdc).  
**Buyer blob:** 6c26444fa80b198d305727b70791f400839a6f75.  
**Edge source blob:** 49c85a4a4648bcef6892476d92037ca56745f633.  
**Production:** SMART ERP fiilmooggumokxanwiyx, ACTIVE_HEALTHY, PostgreSQL 17.6.1.121; app_settings.currency = EGP.  
**Edge:** save-purchase-order ACTIVE v21, verify_jwt=true, SHA-256 dab3eba49dd355080cadaa5bca4aea02056de19c4b6f3ba581f142cccfa0ea8c; retrieved deployed source matches Git byte-for-byte (21,007 chars).

### Confirmed changes since LVE575
- Production and Git now match all 33 Buyer migration versions and names in scope 20261031222956 through 20261101144244. There are 0 Buyer applied versions missing from Git and 0 Buyer migration files unapplied.
- Commits inspected: 8030364ebc53d33e02b971f30acda46f8b00c2ef (PO currency guard + custody payment policy); e9cda057f6168e9cf8304c0fc15d4996db8a3ccf (rename to applied version 20261101143644); 6f8b03ec5f79efb8fdb4fc5066f4654e33678ec3 (remove duplicate 20261101150000 file); caea2321c88bbb7640643be20672fe28aa9c502e (TRUNCATE revoke/default ACL); 40bd00c91f8c52260d867f5cf020104c9e71c161 (restore Buyer migration file/version alignment).
- buyer_custody_payments_scoped_select now correlates c.company_id = buyer_custody_payments.company_id. The table is empty, so cross-company row visibility is not functionally exercised.
- anon/authenticated have no TRUNCATE on any of 186 public tables; expanded public default ACL shows no TRUNCATE for these client roles.
- All five Buyer custody tables have RLS and authenticated SELECT only; no direct authenticated DML/TRUNCATE. Custody RPC signatures align with Edge v21 and have anon EXECUTE=false, authenticated EXECUTE=true, SECURITY DEFINER, search_path empty.
- Supplier AP remains numerically reconciled: 4 suppliers, stored AP 3,970, ledger net 3,970, 2 ledger rows, 0 running-balance mismatches.

### Remaining confirmed issue
- Two active triggers still update suppliers.accounts_payable:
  1. supplier_ledger_sync_accounts_payable → app_private.sync_supplier_accounts_payable(), SUM(credit-debit), updates old and new suppliers on supplier_id change, search_path empty.
  2. trg_sync_supplier_accounts_payable → public.sync_supplier_accounts_payable_from_ledger(), latest ledger balance, search_path=public, does not update the old supplier on supplier_id reassignment.
- Both are AFTER INSERT/UPDATE/DELETE. The old function has only its trigger dependency and no other direct function-source reference was found. Migration 20261101120225 creates the new trigger but does not remove the old one.
- Do not remove the legacy trigger in Production until insert/update/delete, supplier_id reassignment and concurrency behavior are tested and a rollback plan is prepared.

### Scope and verification limits
- Production ledger has 730 migration versions; current Git migrations directory has 43 files. The 33 Buyer files match; 10 additional Delivery files are outside this Buyer reconciliation. This does not establish that the full 730-version history is represented in Git. Do not run global db push.
- save-purchase-order v21 logs for 2026-11-01 show 5,563 POST/200, 18 POST/401 and 5,488 OPTIONS/200 in the inspected window; 401 causes are unknown and HTTP 200 does not prove a business transaction.
- Cloudflare Pages served artifact/commit, browser Console/Network, authenticated Buyer E2E, Storage binary operations and Realtime WebSocket behavior remain UNKNOWN/UNVERIFIED.
- No Production DDL, grant/RLS/trigger change, business-data write, Edge deployment or operational source edit was performed during this event. SQL was read-only.
- The previous LVE575 statement that Buyer migration lineage, custody-payment policy and suppliers TRUNCATE were still open is stale against current live evidence; CURRENT_STATE was superseded by LVE578.

**Arabic report:** doc/Draft/Reprots/Report578_BUYER_MIGRATION_LINEAGE_RECONCILIATION_SUPPLIER_AP_TRIGGER_20261101.md.  
**CURRENT_STATE:** updated to LVE-2026-11-01-578 in the governance/report repository.  
**Status:** BUYER MIGRATION SLICE RECONCILED / PAYMENT RLS FIX CONFIRMED / PUBLIC TRUNCATE REVOKED / EDGE v21 BYTE-MATCHED / SUPPLIER AP DATA RECONCILED / DUPLICATE AP TRIGGER OPEN / CLOUDFLARE + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.


---

## LVE-2026-11-02-584 — Buyer Tabs / Procurement Vehicle Custody / Cash Proof

**Verified date:** 2026-11-02 Africa/Cairo.
**Operational repo:** papamohammed77-glitch/erp-frontend, main, latest commit fetched aa8cbffbfa8d42253726381080dcfc24eaea838b.
**Buyer:** companies/company-1/purchasing/buyer.html, blob 73d746571a10b1720bdd31631004abce0ac9afa1.
**Driver:** companies/company-1/delivery/driver.html, blob 92ae03678b6516345a61d30bb5967046096d8cce.
**Edge:** save-purchase-order v22 ACTIVE / verify_jwt=true / byte-for-byte matches Git blob bc038be8c60a3d593f604c7b2ae445e807bacf57; deployed SHA-256 a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb.
**Production:** SMART ERP fiilmooggumokxanwiyx; company currency EGP.

### Buyer tabs — current state
- The four owner-named tabs are already present in Buyer; do not recreate them.
- Invoices: list/detail/search/filter, create Draft, edit/delete Draft only; row click opens detail modal from commit 37d4e95e030bf3085c232655bdec6f059a335ca1. Preserve this work.
- Quotations: create/list/detail/accept/convert-to-PO. Production purchase_quotation_comparison view exists and is security_invoker=true, tenant scoped; Buyer source has zero references, though Edge GET_DATA allow-list permits the view. Current quotation count is zero. View ranks unit_price only; do not label an overall best supplier without total landed cost and terms.
- Custody: issue, employee acknowledgement, top-up, advance acknowledgement, expense documents (supplier invoice + warehouse receipt), finance review and settlement exist. The payment proof gap remains: finance approval currently creates payment/journal, marks invoice Paid and debits supplier_ledger without a separate proof that supplier actually received cash/instrument.
- Vehicle Balance: currently a placeholder. It resolves fleet_vehicle_assignments.driver_user_id, which is delivery driver assignment, not Buyer custodian assignment.

### Vehicle and inventory boundary
- Production counts at recheck: stock_vouchers=0, fleet_vehicle_assignments=0, buyer_custodies=0, purchase_quotations=0, purchase_invoices=3, mobile vehicles=2.
- Vehicle movement snapshot: CHV-2025-01 Loading 15 rows/qty39, Unloading 10 rows/qty26; VHL-0422 DirectReturn 1 row/qty1, Loading 12 rows/qty12, Unloading 6 rows/qty6. These are delivery operations, not procurement goods custody.
- Driver app reads run_sheet_details/orders and qty_loaded/qty_delivered/qty_returned; never reuse its delivery balance as buyer stock.
- fleet_vehicle_assignments has driver_user_id/fleet_driver_id, not buyer_user_id. vehicles has mobile_branch_id. stock_vouchers already has vehicle_id, custodian_user_id, purchase_order_id and purchase_invoice_id; stock voucher Core whitelist currently only supports Transfer, DirectSale, DirectReturn, SupplierReturn.
- Existing Warehouse SupplierReturn Branch→Supplier contract was closed in Reports 342/343. Preserve it; don't rebuild it or post AP credit at the time goods merely leave warehouse for buyer custody.
- Supplier→Buyer/Vehicle→Warehouse and Warehouse→Buyer/Vehicle→Supplier stages are not implemented. Do not add mobile vehicle stock to Buyer view, and don't add it to saleable stock before warehouse acceptance.

### Purchase, supplier, payment, custody contracts
- PO columns expected_delivery_date and payment_terms already exist; approved_by/sent_at columns and Edge SEND_PO/APPROVE_PO do not exist. Edge CREATE_PO exists and creates Draft PO without balance impact.
- purchase_post_invoice_atomic blocks unlinked quick invoice posting until an approved receiving contract exists. PO-linked posting validates receipt/qty/price and avoids duplicate stock/AP postings.
- purchase_payments.payment_method exists with default Cash, but purchase_post_payment_atomic and Edge POST_PAYMENT do not receive p_payment_method; end-to-end selection is incomplete.
- buyer_custody_issue_atomic and buyer_custody_add_advance_atomic post treasury cash immediately, before later employee acknowledgement; reference optional. buyer_custody_settle_atomic posts cash receipt but finance reference optional and no dedicated proof attachment fields are present.
- buyer_custody_review_expense_atomic checks supplier invoice/PO/warehouse receipt but then posts supplier AP debit and marks invoice Paid without separate supplier cash receipt proof. This conflicts with Owner Physical Handover policy (§77.1/77.4).
- suppliers lacks email/rating/grade and no supplier visits/ratings tables were found.
- Prior Report575 issues are resolved against live Production: LVE579 leaves one active Supplier AP trigger; suppliers TRUNCATE denied to anon/authenticated; buyer_custody_payments RLS company predicate corrected.
- Current DB migration registry for the two recent Buyer invoice changes is 20261102150516 / 20261102151137, while Git filenames are 20261102160000 / 20261102162000. Behavior is present in Production; version/file lineage must be reconciled before db push.

### Source recovery / current Edge source gap
- Production has create/send/receive/complete/cancel stock-voucher Edge functions; their current deploy sources are not present in operational supabase/functions directory. Historical snapshots in rawaie-erp-New/Current/Edge_Functions are incomplete/stale and must not be deployed. Recover the actual deployed source into operational Git before extending the existing functions. Do not create new Edge Functions.

### Owner policy and required approval
- Master CTO Governance §77.2 requires exact changeset (source diffs + complete SQL + effects + dependencies + tests + rollback) to be presented and expressly approved before any write/migration/RPC/trigger/RLS/deployment that can affect Production or business balances. General task direction and the procurement policy endorsement under §77.4 do not constitute approval of an exact code/DDL change.
- No operational source, Production row, RPC, migration, RLS/grant/trigger, Edge deployment or Cloudflare deployment was changed during LVE584. SQL was read-only.
- Cloudflare served artifact, authenticated Buyer browser E2E, Storage binary operations and Realtime WebSocket E2E remain UNVERIFIED.

### Required next action
Recover and reconcile the five deployed stock-voucher Edge source files into operational repo. Then prepare one precise Procurement Custody changeset: separate time-bounded Buyer/vehicle assignment, supplier→vehicle custody, warehouse acceptance and discrepancy handling, reverse return transit with supplier receipt, plus evidence gates for cash issue/top-up/supplier payment/settlement and payment_method. Preserve current delivery and direct SupplierReturn flows. No Production deployment until the owner approves the exact presented changeset.

**Arabic report:** doc/Draft/Reprots/Report584_BUYER_TABS_PROCUREMENT_CUSTODY_EVIDENCE_20261102.md (latest commit 725fa11d44468f7375b3163fdd987fdbe5460570; blob afa845159f291cdd33657ec853979c9289de7c86).
**CURRENT_STATE update:** commit e5201bb99fb50edea8a4b119fff7153428c52964; blob b6b28fc439900617de5747afbe2a626a467529bb.
**Status:** tabs present; comparison view not wired; buyer vehicle custody contract missing; supplier cash receipt proof gap confirmed; driver stock is not buyer stock; Edge v22 byte-match; Cloudflare/browser E2E unverified; no Production mutation; not closed.

## LVE621 — Buyer / Receiver / SupplierReturn live revalidation (2026-11-04)

- Current operational HEAD is `erp-frontend/main` = `e8ab54c75572e15e71581212479d22be139c8020`; current source blobs: Buyer `311f2673a90149df6f56d59a9a187a3379e6981c`, Receiver `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`, Vouchers `85e709d0f41c189c6624a6160965d3b1a41960ba`. Cloudflare dashboard lists Production at the same commit; served Buyer byte parity and authenticated E2E remain UNVERIFIED.
- Live app_settings currency is EGP. Existing Posted invoices PINV-1000 and PINV-1001 are SAR and have matching PurchaseIn inventory, supplier-ledger credits and Posted journals; preserve history. QA-SR-INV-20260927 is Draft SAR with is_received=true / received_qty=5 but no matching inventory, supplier-ledger or journal posting; do not auto-post/delete it.
- Receiver's current detail query uses purchase_order_details.po_code, but live schema has po_id and no po_code. UI uses ordered quantity instead of remaining quantity, parseInt truncates fractional quantities, and no all-zero guard exists. Live receive_purchase_atomic skips zero lines but inserts the receiving header before processing, so an all-zero request can create an empty completed header. Edge v13 derives an operation ID from identical payload when caller omits one; a later distinct identical partial receipt can collide with the earlier operation.
- Buyer Quick Purchase is only an alias for createPurchaseInvoice; quick search exposes items.cost_price; Vehicle Balance remains a placeholder with no buyer_goods_custody_events table. Existing cash custody review is PO/receipt-bound and lacks a Quick Market invoice branch.
- SupplierReturn browser/DB defaults and save_supplier_return_contract fallback are SAR despite parent EGP. Contract may use items.cost_price as return-price fallback. enforce_stock_voucher_custodian clears custodian_user_id for non-mobile types, so SupplierReturn Buyer delegation is unsupported. send_stock_voucher moves stock but does not append Buyer custody; complete_manual_stock_voucher_atomic_core_20260828 posts full voucher value to supplier ledger/GL without supplier acceptance quantities. purchase_post_return_atomic is a separate stock+financial writer and is not linked to stock_vouchers; purchase_returns has no stock_voucher_id. Browser roles currently have direct DML grants on purchase_returns and purchase_return_details.
- Production counts: purchase_returns=0, SupplierReturn vouchers=0, buyer_custodies=0, buyer_custody_expenses=0, receiving=0, receiving_details=0, purchase_invoices=3. No test fixtures created.
- The reviewed 710-line `02_buyer_goods_custody_schema_security_REVIEWED_DRAFT.sql` remains a non-deployable scaffold; not executed. Existing Edge Functions are the only intended Edge extension points; do not create a new Edge Function.
- Competitive baseline: Dynamics 365 return PO, partial line receipt and disposition; SAP return PO/outbound delivery/goods issue followed by supplier credit memo; Odoo received-quantity bill control/3-way matching and vendor-return stock valuation; Almarai 2025 published integrated multi-depot/fleet/real-time KPI/forecasting operating model.
- Governing full evidence: `doc/Draft/Reprots/Report621_BUYER_CUSTODY_RECEIVER_LIVE_REVALIDATION_20261104.md` (blob `78cae3f7ef3e48a01adb4e63350c50aa6c281e97`). CURRENT_STATE has LVE621 appended.
- No operational code, schema, RPC, trigger, grants, Edge deployment, business row or test fixture was changed. Exact complete changeset and rollback must be prepared and presented for explicit approval under Report614 §14 before Production implementation.


## LVE622 — Buyer First / Owner Clarified Scope — 2026-11-04

- Owner clarified sequencing: Buyer first; Receiver UI repair is explicitly deferred until Buyer correctly creates PO and no-PO Quick Market invoices. Future Receiver must expose direct supplier-to-warehouse PO receipts and Buyer-created Quick Market invoice receipts to warehouse receiving staff only. Stock moves only on accepted warehouse quantities.
- Buyer may hold goods without a vehicle. Vehicle association is optional metadata, not a business prerequisite or custody-balance key. Cash custody and goods custody are separate ledgers.
- Quick Market: active central supplier only; Draft invoice without PO; hand-entered actual unit prices; EGP from parent app_settings; explicit source/settlement/purchaser metadata; supplier-to-Buyer handover is a separate append-only goods-custody event. Neither Draft invoice nor handover event posts warehouse stock/AP.
- Current Buyer gaps: quickPurchase() aliases createPurchaseInvoice(); cost_price displayed in quick search; vehicle/goods balance is placeholder; cash expense submit/review accepts only PO-linked invoices; invoice list is global by default rather than buyer-owned.
- Current live purchase_post_invoice_atomic rejects no-PO invoices with PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED; preserve the guard until the later Quick Market Receiver path. PO receive_purchase_atomic already posts PurchaseIn and supplier AP from accepted PO receipt; don't create duplicate AP through invoice posting.
- Live SMART ERP has only five buyer cash-custody tables; no deployed buyer_goods_custody_events table. The 710-line reviewed schema scaffold blob 9446c4dece9650fb6736e92db1aa340f89ee53dd remains non-deployable without RPC/trigger/Edge/UI/rollback companions.
- SupplierReturn still requires a single stock dispatch writer and a separate supplier-acceptance writer for AP/GL/tax based on accepted quantity only; current trigger clears SupplierReturn custodian, currency fallback SAR, cost_price valuation fallback and full-value completion posting are defects. purchase_post_return_atomic is a separate writer that must not double-post linked voucher stock.
- Cash advances are posted only after employee acknowledgement. Quick Market needs a custody-expense review branch. amount_due_employee is calculated in current settlement but has no evidenced cash disbursement/payment record; resolve via approved payable mapping or real treasury payment workflow.
- Rechecked test invoices: PINV-1000 Posted SAR 2,640 with 3 PurchaseIn movements / supplier credit / Posted journal; PINV-1001 Posted SAR 1,330 with 2 PurchaseIn movements / supplier credit / Posted journal. Combined 5 movements, 50 units, supplier credit 3,970 SAR and 2 Posted purchase journals. QA-SR-INV-20260927 Draft SAR 375 has is_received=true and received_qty=5 but no inventory/AP/journal matching rows. No deletion or reversal performed.
- Report622: doc/Draft/Reprots/Report622_BUYER_FIRST_OWNER_CLARIFIED_CHANGESET_20261104.md, blob ffccd90c78f37eec3f24140d9267d5312cabed28. CURRENT_STATE LVE622 appended. Operational code, Mother, Core, DB business data/schema/RPC/trigger/ACL and Edge deployments untouched; no test data or branches created.
- Status: owner scope reconciled; Buyer-first ChangeSet design documented; production implementation not yet applied. Next action is the coherent Buyer ChangeSet; Receiver follows only after Buyer acceptance. Keep Report614 §14 approval gate; no new Edge Function.


## LVE623 — Buyer First ChangeSet Revalidation & DDL Cleanup — 2026-11-04

- المالك حسم ترتيب التنفيذ: Buyer أولًا، وReceiver لاحقًا. Receiver لاحقًا يدعم استلام PO مباشرة من المورد واستلام فاتورة Quick Market بلا PO أنشأها Buyer؛ لا زيادة للمخزون إلا بالكمية المقبولة من مسؤول الاستلام المخول. حيازة Buyer لا تشترط مركبة؛ vehicle_id اختياري. مرتجع المورد الذي يسلمه Buyer لا يسوي حساب المورد إلا بإيصال/قبول المورد، مع قبول جزئي.
- Buyer live source لم يتغير: `buyer.html` blob `311f2673a90149df6f56d59a9a187a3379e6981c`، 152,573 حرفًا / 1,181 سطرًا. الفجوات: quickPurchase مجرد alias إلى createPurchaseInvoice، cost_price ظاهر في بحث الأصناف، رصيد عهدة البضاعة placeholder، تسوية المصروف تقبل PO + Receiver مكتملًا فقط، وGET_DATA الحالي يرسل فواتير الشركة كلها للمشتري.
- Edge save-purchase-order لا تزال version 22 وبصمة `a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb`. لا Edge Function جديدة ولا نشر. Repo التطبيقات HEAD `e8ab54c75572e15e71581212479d22be139c8020`، ولم يتغير Buyer أو Receiver أو Mother أو Core.
- إعادة تحقق العهدة النقدية الحالية: الصرف الفعلي من الخزينة لا يحدث إلا بعد إقرار الموظف بالاستلام. إضافة العهدة تزيد issued_amount لكنها لا تصرف قبل الإقرار. تقديم المصروف PO-centric ويتطلب الفاتورة وإذن Receiver المكتمل والمرفقات. مراجعة المالية تطابق PO/الاستلام وتغلق AP بقيد من عهدة الموظف 127. التسوية النهائية تمنع وجود مصروف معلّق/زيادة غير مؤكدة وتستلم كامل النقد المرتجع الفعلي عبر post_cash_receipt_atomic. الحفاظ على الوظائف المركزية؛ Quick Market لا يدخل مراجعة المصروف قبل Receiver. لا يوجد حساب دائن موظفين مخصص؛ لا تعامل amount_due_employee كمدفوع دون حساب معتمد وسند صرف حقيقي.
- ملفات ChangeSet المقترحة محفوظة في `Current/CTO/ChangeSets/20261104/`: 03B/03D/03E/03F/03H SQL؛ 04 و04A فروق Buyer/Edge؛ 04B صلاحيات؛ 04C عزل فواتير الخادم؛ 05 اختبارات قبول؛ 06 و06A تراجع/preflight؛ 07 تنظيف اختبار المخطط. هي مستندات/مسودات وليست تغييرات تشغيلية بعد التنظيف. يجب تنفيذ GET_DATA scope لفواتير المشتري وتفاصيلها على الخادم، وليس مجرد فلترة المتصفح.
- حدث تحقق مهم: منفذ Supabase SQL لم يعامل BEGIN/ROLLBACK المرسلة كمعاملة ذرية واحدة؛ بقي DDL بعد اختبار المخطط. لم يُوصف ذلك بأنه rollback ناجح. تدقيق فوري أثبت صفر أحداث حيازة، صفر فواتير مصنفة، صفر سجلات idempotency، صفر عهد نقدية/مصروفات. نُفذ `07_buyer_phase1_validation_cleanup.sql` ثم تحقق مستقل: جدول buyer_goods_custody_events غير موجود، أعمدة Buyer السبعة غير موجودة، وظائف Buyer التسع غير موجودة، Realtime membership=0، purchase_invoices=3، buyer_custodies=0، buyer_custody_expenses=0، العملة EGP. لا حركة مخزون أو دفتر مورد أو أستاذ عام أو خزينة تغيرت. اختبارات DDL المستقبلية تحتاج منفذًا ثبتت ذريته أو مشروع اختبار منفصل؛ لا تعتمد على BEGIN/ROLLBACK في منفذ SQL هذا.
- فواتير الاختبار الحالية كما هي: PINV-1000 Posted SAR 2,640 وPINV-1001 Posted SAR 1,330 وQA-SR-INV-20260927 Draft SAR 375 مع is_received=true غير المتسق. لم يُحذف/يعكس/يعدل أي صف. التاريخ SAR محفوظ حتى مسار مطابقة/عكس منفصل.
- مستشارو Supabase بعد التنظيف على مستوى المشروع: 24 RLS-enabled/no-policy معلوماتية؛ 1 mutable search_path؛ 18 anon SECURITY DEFINER؛ 128 authenticated SECURITY DEFINER؛ 1 تسرب كلمات مرور معطل. الأداء: 295 FK بلا فهرس، 66 RLS initplan، 56 فهرس غير مستخدم، 18 overlap permissive policies، 7 duplicate indexes. لا blanket revocation ولا تغييرات لجداول غير مرتبطة.
- التقرير العربي: `doc/Draft/Reprots/Report623_BUYER_FIRST_CHANGESET_REVALIDATION_20261104.md` blob `5846a567cd765d08c492412864d9a278451e903f`، 348 سطرًا. يوثق النموذج التجاري، فجوات المصدر، العهدة النقدية، Receiver/SupplierReturn لاحقًا، حادثة DDL والتنظيف، advisor findings، قائمة الحزمة وبوابة النشر.
- الحالة: تشخيص Buyer وتصميم الحزمة واختبار SQL/التنظيف اكتمل؛ لم يطبق Buyer UI/Edge تشغيليًا. لا Edge جديد ولا branch ولا تعديل/نشر app. تبقى بوابة Report614 لاعتماد الحزمة المتطابقة قبل النشر. Receiver بعد قبول Buyer فقط.
- الخطوة التالية: توحيد الفروق النهائية الدقيقة لواجهة Buyer داخل buyer.html والـrouting/server-scope داخل save-purchase-order الموجود، ومقارنة blobs الحالية، ثم عرض ChangeSet واحد كامل واختبارات/تراجع قبل Production. لا تشغل مسودات SQL القديمة مباشرة.


## LVE624 — Buyer Phase 1 executed (2026-11-04)
- تم تطبيق 9 Supabase migrations على SMART ERP: supplier invoice duplicate guard، Buyer source/goods custody schema، PO/QM idempotency hardening، posting guard، handover progress، Realtime، ownership wrappers، ثم إعادة تثبيت غلاف Legacy بعد ربط duplicate guard.
- جدول `buyer_goods_custody_events` live مع RLS، SELECT policy واحدة، append-only trigger، Realtime membership. authenticated SELECT فقط؛ لا DML مباشر. جميع SECURITY DEFINER Buyer RPCs تضبط search_path فارغًا؛ anon EXECUTE=false.
- Edge الحالي `save-purchase-order` ACTIVE v25، SHA-256 `793ba5412a27813aa715da4078971a150d592dd03b53833148b9e99a37b5be62`. العمليات الجديدة تستعمل profileClient/JWT. GET_DATA يحد فواتير وتفاصيل المشتري إلى المالك الحالي، مع توسيع للمالية/مدير المالية/مالك النظام.
- Buyer source الوحيد المعدل: `companies/company-1/purchasing/buyer.html`, blob `9cc971d8c5ae9ce960c9395d53e36d43a30e9c73`, commit `3717c0279b856127d29fb9f912ec502523761da5`. منفصل PO/Quick Market، إخفاء cost_price، حجز عهدة نقدية دون double count، handover موثق إلى عهدة البضاعة مع مركبة اختيارية، رصيد مشتريات من ledger، فواتيري current-user default.
- حالة Production DB: العملة EGP؛ 3 purchase invoices وكلها LEGACY_UNCLASSIFIED؛ 0 PO source و0 Quick Market؛ 0 goods events؛ 0 cash custodies/expenses؛ inventory_log=76؛ supplier_ledger=2؛ journal_entries Posted=17 وCancelled=2؛ purchase_returns=0. لم تُنشأ بيانات اختبار ولم يتغير مخزون أو AP/GL/treasury.
- لا تزال فواتير SAR التاريخية PINV-1000/1001/QA-SR-INV كما هي؛ لا حذف ولا عكس ولا إعادة تصنيف.
- Cloudflare Pages deployment غير مثبت: آخر لقطة لوحة مرئية كانت على commit `e8ab54c` قبل Buyer commit. لا تدّع أن واجهة Buyer live قبل التحقق من deployment جديد. Authenticated Buyer E2E لم ينفذ لعدم وجود جلسة Buyer في المتصفح؛ اختبارات رفض unauthenticated RPC نجحت.
- Receiver.html وSupplierReturn لم يتغيرا؛ لا Edge slug جديد ولا فرع ولا PR ولا Mother/Core/تطبيق آخر.
- تقرير التنفيذ: `doc/Draft/Reprots/Report624_BUYER_PHASE1_PRODUCTION_SCHEMA_EDGE_UI_20261104.md`, SHA `e9cfa3beb19ee1b635473ff25f3283551cc07781`, 189 lines.
- الاستئناف: تحقق/أكمل Cloudflare Pages deployment للـcommit `3717c027`، ثم اختبارات مستخدم Buyer مصادق read-only وSQL transaction rollback؛ لا تترك فاتورة أو append-only handover event تجريبيًا دائمًا. Receiver بعد قبول Buyer فقط.

- تحديث لاحق LVE624: Cloudflare Pages أكد Production deployment للـBuyer commit `3717c0279b856127d29fb9f912ec502523761da5`، Preview URL `https://633d858b.rawaea-erp.pages.dev/`. هذا يلغي ملاحظة "deployment غير مثبت" السابقة؛ يبقى اختبار Buyer المصادق وE2E غير منفذ لعدم وجود جلسة مستخدم مصادق في المتصفح. Report624 الحالي SHA `5b20448251415846bc627ddb59453278fdc77dda`.

- LVE624 security follow-up: applied migration `buyer_phase1_09_effective_permission_only_rpc_guards` from `03L_buyer_effective_permission_only_rpc_hardening.sql`. QMP create now relies only on `current_user_has_effective_permission('purchases')`; Legacy draft ownership override uses canonical `get_my_effective_profile()->>'isOwner'`, not raw `users.permissions @> ["*"]`. Live pg_get_functiondef checks confirm both raw wildcard bypasses are absent. Report624 current SHA: `bc0089d8ae420792156b513a6f8c3c3db9e05592`.

- LVE624 Buyer UI follow-up: ownership-aware edit/delete controls aligned with SQL wrappers. Latest Buyer blob `762de2aa2189b1f6695129a1031475232a70640f`, commit `841b90f564e004311a0a8abcac76056f797e9f71`; inline JS parse still passes. Cloudflare dashboard confirms prior Buyer revision `3717c027` but latest `841b90f` was not yet visible in deployment list at last check; verify Pages before claiming this final UI patch is live. Report624 current blob SHA: `06989864eaf53cb8281f70034e5fab5fe73e94f7`.

- LVE624 final Buyer UI source revision: blob `d9ffb1084a538b7f7baf48391d3048ac5e96bffa`, commit `bf0833c3c71d7a2dea6167bfac9b5403e8044cf7`. Draft deletion now routes to ownership-aware PO/Legacy or Quick Market delete RPC; old unguarded `DELETE_DRAFT_INVOICE` call removed from Buyer. JavaScript parsing passed. Cloudflare still only showed deployed commit `3717c027`; commits `841b90f` and `bf0833c` were not yet visible, so the latest Buyer UI revision remains pending Pages deployment verification. Report624 current SHA: `99405231ce5caf8b1a130c2882b5ab3e8854b262`.


## LVE625 — Buyer Phase 1 security/integration state — 2026-11-04
- Current operational main = bf0833c; Buyer source d9ffb108; CSS 7eb4ef. Buyer UI deletion now uses source-aware wrappers, but the old generic DELETE_DRAFT_INVOICE Edge route remains callable and is not ownership-safe.
- Production migrations 01–09 and save-purchase-order v25 are active. Git Edge source is stale versus deployed v25; restore the exact deployed source before any redeploy.
- P1 open: QMP reservation ignored by cash custody settlement; generic service-role delete route lacks ownership and handover-event guard; invoice RLS remains company-wide despite Edge GET_DATA user scope; direct DML remains on purchase_returns/details; handover RPC does not require/verify evidence and UI may delete evidence on UNKNOWN commit state.
- P2 open: Buyer does not subscribe to buyer_goods_custody_events; CSS cache-first SW version unchanged; Legacy Draft edit may normalize historical SAR to system EGP; event UI does not expose evidence link; 29 Buyer custody FKs unindexed.
- Receiver remains PO-only (purchase_orders subscription, receive-purchase v13); Quick Market warehouse acceptance is not implemented. No Quick Market/custody test rows or business effects exist. Latest confirmed Cloudflare deployment remains 3717c027; bf0833c not deployment-verified; authenticated E2E/Staging unknown.
- Report625: doc/Draft/Reprots/Report625_BUYER_PHASE1_SECURITY_INTEGRATION_REVALIDATION_20261104.md. No operational code/DB/Edge/deployment writes; next step is exact P1 ChangeSet and explicit owner approval.


## LVE627 — Buyer Phase 1 hardening / Edge v25 recovered — 2026-11-04
- Report627: `doc/Draft/Reprots/Report627_BUYER_PHASE1_HARDENING_EDGE_V25_RECOVERY_20261104.md` (commit e95fe0e73160ae9be05047d7dc7eaaa6949e0754).
- Live `save-purchase-order` is ACTIVE v25, SHA256 793ba5412a27813aa715da4078971a150d592dd03b53833148b9e99a37b5be62, 30,017 bytes. Exact snapshot archived in `Current/CTO/EdgeSnapshots/20261104/save-purchase-order_v25/index.ts` (archive commit 8654dea3e0d93008d74f66b9f0a6fe5c695f2bc0; blob 632f207143574a6b26145aa01cc8abc0c283d12b); byte-for-byte match verified. Operational Git Edge file blob bc038be8c60a3d593f604c7b2ae445e807bacf57 (23,077 bytes) is stale; never redeploy it over v25.
- Review drafts: Edge `save-purchase-order_v25_PHASE1_HARDENING_REVIEW_DRAFT.ts` commit 9779f48d373fe543ffe2c31e96d9d6bf118c9c09; SQL `01_buyer_phase1_hardening_REVIEW_DRAFT.sql` latest commit 4682d3f74213b09767e3faec8997220ef35ff1c2; Buyer patch `02_buyer_evidence_unknown_outcome_REVIEW.patch.md` commit 55846d16bce195198408da9767d15c4c966543cc.
- Drafts cover fail-closed currency, generic invoice-delete ownership/source/goods-event guard, QMP reservation guard for custody settlement, required existing private evidence object/path on handover RPC, deletion guard after goods events, and safe unknown-commit file retention.
- Storage bucket employee-documents is private. No buyer-goods-specific policy identified; inspect and draft least-privilege Storage access before any apply. Invoice RLS and purchase_returns direct-DML remain open pending consumer maps.
- No operational or Production write/deploy; no Receiver edit; no QA fixtures. Approval gate remains open under permanent charter §§6.2–6.3.

- Consumer scan addendum: Buyer blob d9ffb108 uses only `DELETE_BUYER_DRAFT_INVOICE` / `DELETE_QUICK_MARKET_DRAFT`; no generic `DELETE_DRAFT_INVOICE` hit returned by GitHub code search. Main.html fetch returned empty content, so do not infer no parent consumer. Generic Edge route retained with proposed owner/source/goods-event checks. Report627 latest commit 3f3de2d2f2bd91e90abe778ad52a09eb9ebf540f.


## LVE633 — PO / Supplier Invoice separation and dispatch gap — 2026-11-05

- Report633: `doc/Draft/Reprots/Report633_BUYER_PO_SUPPLIER_INVOICE_SEPARATION_20261105.md` (commit `b98f737283f826cc6ec21b9e238ff0aebf726b1a`).
- Latest verified operational HEAD at inspection: `7060bbbf6040bae5c4f02145d6c0a638b6131087`; Buyer blob `5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a`; latest Buyer-specific path commit `21c35a5d02d36c32ecb3304f5cecb6f157911741`.
- Live `save-purchase-order` v29 SHA `35caa4f2759ba608a7f3bf86640b4773280bc84447872267d6e4d53896743e04`; `receive-purchase` v13 SHA `50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc`.
- PO and supplier invoice are distinct live entities: `purchase_orders/purchase_order_details` vs `purchase_invoices/purchase_invoice_details`, with optional invoice.purchase_order_id FK. Buyer createPO/Create PO RPC and supplier invoice modal/Create PO Invoice RPC are independent. Rename misleading `+ فاتورة PO` to supplier-invoice wording; preserve all fields and modal capabilities.
- The lifecycle gap is confirmed: PO creation and quotation conversion both produce Draft; no approval/send PO Edge operation or RPC exists; Receiver only displays Sent/Partially Received. Quotation acceptance is not restricted to `purchases_supervisor`; converter accepts Accepted or Submitted. Dedicated role exists, but no active user assignment was found and Buyer gate excludes the permission.
- Receiver has a verified schema mismatch: reads `purchase_order_details.po_code`, but the live table has `po_id`, not po_code. Receiver intentionally not edited in this Buyer-first phase.
- PO receipt currently posts stock and supplier AP/GL from accepted quantity. PO invoice posting after receipt verifies PO/receipt/quantity/price then marks invoice Posted without a second inventory/AP posting. PO invoice modal allows discount/tax but posting currently rejects nonzero values; retain as explicit contract mismatch until separately resolved.
- Production snapshot: purchase_orders=1 (Draft), purchase_quotations=0, purchase_invoices=3 (one Draft), currency EGP. No data or business side effects created.
- No operational source/DB/Edge/Cloudflare changes, no test transactions. Report614 §14 requires exact presented ChangeSet and explicit approval; Report633 is forensic/change design, not applied code.
- Next: prepare/approve the exact current-Edge PO approval/dispatch change set and Buyer labels; keep Receiver correction as its own later patch. Cloudflare deployment and authenticated Buyer E2E remain UNKNOWN/UNVERIFIED.


## LVE634 — PO Supervisor Approval + Warehouse Receiving Gate — 2026-11-05
- Report634: doc/Draft/Reprots/Report634_PO_SUPERVISOR_APPROVAL_AND_RECEIVING_GATE_20261105.md (commit 95cc14f33cec24474ed748af8430386e712fe898).
- The Parent main.html already has Cycle Purchasing → Orders and an existing PO details modal. Surgical UI changes are mapped: Arabic status label in the orders row, conditionally add the supervisor approval button in RW_Purchases.openPO, add a small RW_PurchaseGold.approvePO method routed through the existing api helper, and export that method.
- Production confirmed: purchase_orders RLS grants SELECT but not UPDATE to authenticated; no direct browser UPDATE. save-purchase-order Edge v29 has no APPROVE_PO branch; no purchase_approve_po_atomic RPC exists.
- Proposed backend contract: reuse save-purchase-order (no new Edge), require purchases_supervisor in Edge and again in the new SECURITY DEFINER RPC; validate auth.uid, active company user, actor email, Draft-only status, non-self-approval, lock PO FOR UPDATE. Updating status sets rawaea.purchase_actor; existing trg_purchase_orders_status_history records status transition and approver identity. Avoid duplicate manual history INSERT.
- Current permission recheck: one active user has effective purchases_supervisor. Current Production PO count: one Draft; do not use this real PO as a test.
- To make PO actually receivable, Receiver must include Approved in its status query, fix the existing wrong child lookup purchase_order_details.po_code → po_id = purchase_orders.id, include qty_received and remaining quantity, and preserve fractional quantities. A database-side BEFORE INSERT receiving guard is proposed because the current receive_purchase_atomic does not enforce an approved/eligible PO status itself.
- No operational writes: no changes to main.html/receiver.html, no Edge deployment, no RPC/trigger/migration, no PO state change, no test data and no inventory/accounting/treasury effects. Owner ChangeSet approval gate remains open under Report614 §14.

- LVE634 addendum: Main navigation _hasPermission checks permission for view='purchases'. Current active effective supervisor is 1 and also has purchases plus wildcard, so the existing menu route is accessible; no new nav permission patch is needed for the current assignment. Production routine scan found receive_purchase_atomic is the only INSERT writer into public.receiving, so the proposed isolated receiving trigger in Report634 can fail closed for nonempty po_number: require company_id, require the matching PO, then allow only Approved/Sent/Partially Received.
- Report634 latest amended commit: 14c2f5f7d2ddf73cc99a58e453b31c8da5605bfe (blob 80252af4bccf0854af663d90ff146a733cad9ea3). No operational changes were made.


## LVE635 — Parent PO approval + supervisor app + receiving eligibility — 2026-11-05
- Report635: doc/Draft/Reprots/Report635_PO_APPROVAL_MULTI_CHANNEL_SUPERVISOR_RECEIVING_20261105.md (created commit 4611022b656b839aebc41b0866e938abdf321d5a; verified report blob 4b563c02443456fea9fb3620862418478e05e8cf).
- Revised owner policy supersedes Report634's previous Parent UI permission condition: any user allowed into Parent Purchasing Cycle with effective purchases permission may approve from Parent. The dedicated purchasing/supervisor.html independently requires purchases_supervisor (or owner/wildcard) and should list all company POs for all buyer operators. Server Edge/RPC accepts purchases OR purchases_supervisor.
- Parent main.html already has approval modal/button and approvePO but both UI permission checks incorrectly use purchases_supervisor. save-purchase-order v29 has no APPROVE_PO dispatch, explaining exact unsupported operation 400.
- Latest published Cloudflare Pages Production is commit 4f433c4a014d24d317201936b2473c2335352119; main blob 2ecd4936e5a5f328d56e3cc5f8d6dbcca8487122. Receiver current blob 223dcc9c690510f83922c54fb616f9cfd20a4ed5 includes Approved, po_id detail lookup, qty_received and fractional quantities, but needs detail query error and zero-receipt guards. supervisor current blob d13e3ff72972641fa300fb956d1f5119e2019743 is still read-only, purchases gated, 50-row limited, and missing detail/approval; realtime currentTab is not set.
- Production: one Draft PO, zero Approved; authenticated cannot UPDATE purchase_orders directly. purchase_status_history and status trigger exist; no receiving trigger. receive_purchase_atomic is the only found INSERT writer into receiving and doesn't enforce PO status. Edge save-purchase-order active v29 SHA 35caa4f2759ba608a7f3bf86640b4773280bc84447872267d6e4d53896743e04, receive-purchase active v13 SHA 50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc.
- Report635 defines exact surgical main.html changes; existing Edge v29 dispatch/auth branch; caller-JWT RPC purchase_approve_po_atomic; receiving fail-closed trigger; supervisor list pagination/search/filter/details/approval via RW_API; and Receiver/receive-purchase zero-quantity and query-error guards. No direct table UPDATE, no new Edge.
- No operational writes, Edge deployment, migration, Production data or PO state changes were made. No test fixtures created. LVE635 ChangeSet must be explicitly approved under MASTER CTO GOVERNANCE §77.2 before writes/deploy; after approval CTO executes the changes and QA.

- LVE635 addendum: The existing Production QA PO QA-SR-PO-20260927 (created 2026-09-27) has no linked purchase_status_history row. The status trigger's body does handle purchase_orders and rawaea.purchase_actor, but a rollback-controlled test must prove a fresh Draft→Approved transition creates the history entry. Report635 updated commit f68f88994016b1ff76335f0c992558b9024976e3; blob cebe5ad29b3aa4801e89b1fae61e76f2e25c3d65. Still no production writes.


## LVE636 — PO Approval Production Execution — 2026-11-05 (Supersedes LVE635 “not executed” status)
- Execution report: `doc/Draft/Reprots/Report636_PO_APPROVAL_PRODUCTION_EXECUTION_20261105.md` (commit `3ce25b9b368841b31be0106206cd243d28cc4685`; blob `ea266f085049e033c8b538dedd5647a59473dca2`). CURRENT_STATE LVE636 was appended in commit `5673302a103965cd8affc5deada40954d0dd23b8`.
- Parent main.html was edited by the owner and reviewed by CTO: UI button condition and approvePO guard both use `purchases`; approvePO invokes APPROVE_PO and is exported. It is functionally correct; stale rejection text still says “مشرف المشتريات”. CTO did not alter main.html.
- Production DB writes were executed directly in SMART ERP project `fiilmooggumokxanwiyx`, no repo migration file: created `public.purchase_approve_po_atomic(uuid)`, permission checks effective purchases OR purchases_supervisor, authenticated grant only, Draft-only/idempotent status transition and actor set_config; created `app_private.guard_po_receiving_status()` plus BEFORE INSERT trigger `trg_receiving_require_approved_po` to block PO-linked Receiving until Approved/Sent/Partially Received. Guard direct execution revoked.
- Edge save-purchase-order ACTIVE v30 SHA `838f8c05d5e64f040dc4a346eae52816877d635bab41684d32d77eebeae304e6` handles APPROVE_PO with dual permission and caller-JWT RPC dispatch. Existing receive-purchase ACTIVE v14 SHA `05584598ded76f17ff6e29d4c6fb951d2f347ed7fdd3549ec457d929756a74fb` rejects zero-only receiving; both verify_jwt=true. No new Edge.
- Supervisor frontend main commit `cf07aba424f5ca37cf75ac1804d756448841f4ea`, blob `8d46c3c6d6df487ebd880c29d438bcdd2bd789bf`: gate Owner/*/purchases_supervisor, paginate every company PO, show creator, search/filter, details modal, approve via existing RW_API Edge.
- Receiver frontend main commit `b728c09e1bb4c482effc48a492546b393ff02c1f`, blob `075ddf9e5801c25bd337d65bf883b4bf4b5736c3`: explicit tenant filter, pagination, details error feedback, no zero receipt, quantity upper-bound validation.
- Rollback-only QA passed and cleaned: cashier without purchases denied, purchases-only buyer succeeds, duplicate approval idempotent, exactly one Draft→Approved history event with actor, Draft Receiving blocked, Approved Receiving header allowed. After cleanup Production unchanged: one existing PO Draft, zero receiving, zero PO history. Never change `QA-SR-PO-20260927` in order to test.
- Inline JavaScript syntax for both updated HTML files passed. Live function/trigger ACL verified. No direct receiving API end-to-end or browser interaction was run; no standalone purchases_supervisor-only account was available to test actual role login.
- IMPORTANT DEPLOYMENT STATUS: Cloudflare automatic deployments enabled, but the dashboard content available after commits still showed Production at `684a552`, not `b728c09`. Do not claim Pages is updated until dashboard shows latest commit Success and a live UI verification is done. This is the next handoff checkpoint.
