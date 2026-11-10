# Report695 — تدقيق تكامل المخزن الشامل ومطابقة Picker وفجوات الخادم

**Recorded:** 2026-11-10 (Africa/Cairo)  
**Workstream:** Unified Warehouse / Picker parity / SMART ERP production contract audit  
**Disposition:** Source/DB forensic review and mocked E2E verified; production mutation and deployment deliberately not performed.

## 1. Executive result

تم فحص طلب التنفيذ ومراجعه التشغيلية، ثم فحص المصدر الحالي على GitHub، وتدفقات الوحدات السبع المدمجة، ونسخة Picker المنفصلة، وسجل CI، ولوحة Cloudflare المتاحة، وعقود SMART ERP المنشورة فعليًا. لا توجد حاجة إلى إعادة بناء التطبيق أو استبدال Picker أو إضافة قاعدة/فرع اختبار أو Edge Function جديدة.

التطبيق الحالي بنية تشغيلية أصلية داخل ملف مستقل بأربع مساحات (اليوم، العمليات، الأذونات، حسابي)، ويحتوي الوحدات الأصلية السبع receiver / picker / loader / returns / unloader / counter / vouchers. رابط النظام الأم موجود بالفعل. الاختبارات الآلية الحديثة نجحت، لكنها تعتمد على Supabase mock ولا تثبت تنفيذ عمليات فعلية على مستخدم إنتاج أو ترحيل مخزون/حسابات.

**لا يُعتمد التطبيق إطلاقًا ذهبيًا/ماسيًا بعد:** توجد ثلاثة تعارضات صلاحيات في مسارات التراجع (إلغاء التحضير، إعادة فتح التحضير، إلغاء المرتجعات) تمنع مستخدم المخزن الشامل من تنفيذ وظائف تعرضها له الواجهة؛ كما توجد وظيفة إعادة فتح مرتجع مكتمل تنفذ خصمًا مباشرًا غير متوازن من جدول الرصيد دون قيد عكسي. توجد أيضًا وظيفة إعادة فتح استلام قديمة غير مستخدمة في Receiver الحالي وتنفذ تحديث رصيد مباشرًا. هذه النقاط موثقة أدناه.

## 2. Governance and safety applied

- تمت قراءة الملف المطلوب writing-block-8888-10.md بالكامل: 1,035 سطرًا، blob SHA 928a98e94624e1c0a5bf4b3e97aaff560c33fcd8.
- تمت قراءة CURRENT_STATE.md كاملًا (964 سطرًا، SHA bb9b5e5c4f27238068a522dada9c4cd119322fc7). آخر نقطة موثقة فيه LVE-2026-11-10-694، لكنها أقدم من HEAD الحالي.
- تمت قراءة الدستور التشغيلي الدائم (SHA 3a6b1e220af8509e314e94df76563bbc6f84910d) وMaster CTO Governance (SHA 1a0c81c2984103b5a7f3b40db41607d74051b310)، إضافة إلى تقارير 545 و689–694 ذات الصلة.
- ضوابط §77.2/§77.3 في Master CTO Governance تفرض تقديم التغيير الدقيق والآثار والاختبار/التراجع والحصول على اعتماد المالك قبل تعديل مصدر تشغيلي أو Edge/RPC/ACL أو نشر أو قاعدة بيانات إنتاجية. التفويض العام لا يجيز ترحيل حركة مخزون/حسابات حقيقية ولا تجاوز هذه البوابة.
- لم يتم إنشاء فرع Supabase أو بيئة مدفوعة، ولم تُنشأ بيانات اختبار، ولم يتم استدعاء أي endpoint يغيّر كمية أو حجزًا أو ذممًا أو خزينة أو قيدًا ماليًا. كل فحوص قاعدة البيانات كانت SELECT/قراءة تعريفات فقط.

## 3. Current Git, app and deployment evidence

| Asset | Verified value |
|---|---|
| Operational repository | papamohammed77-glitch/erp-frontend, main |
| Current HEAD | 81bc832cb37f2eca22d6375497e2041f051546db |
| warehouse.html blob | 31c4f1ae903b389269a4b90afdf310784f77f194; 662,494 chars |
| standalone picker.html blob | a94e18f1c7b2de5dad912011bb32999611976b8e; 55,099 chars |
| core.js blob | 2d11b852862c523fc89e6a8b9c510462bb65cc4e |
| E2E workflow | .github/workflows/warehouse_hub_browser_e2e_20261110.yml; blob 8e6ba2f22180edf5980d668cd65d50c707b17002 |
| Supabase project | SMART ERP / fiilmooggumokxanwiyx / eu-west-1 / ACTIVE_HEALTHY |

HEAD 81bc832 is 28 commits ahead of the earlier LVE-694 baseline 172120584039fcdbdd4cda866d26870c9ac34a4c. Recent commits include warehouse branch-receipt/security changes and driver-liability read/write restrictions.

Cloudflare dashboard snapshot exposed Production at commit 3748f4602c54961945c6e1ef74391a27ca3e6004, not current Git HEAD 81bc832. Therefore deployment parity for current HEAD is UNKNOWN/NOT VERIFIED; CI success must not be described as proof of production rollout.

Parent integration was checked directly in current main.html source: warehouse submenu action openWarehouseHub is permission-gated by warehouse and opens warehouse/warehouse.html in a new tab. Parent navigation already exists; Parent main.html was not changed.

## 4. Picker standalone-to-embedded parity

Embedded Picker was extracted from warehouse.html RW_NATIVE_BUNDLES.picker and compared against the inline script in current picker.html using a brace-aware method parser.

- 26 standalone methods and 26 embedded methods were identified.
- All 26 method names are shared; no business method is missing or extra.
- Core picker lifecycle and stock-reservation workflow are preserved. The differences are confined to expected integration/render methods: renderPendingTab, renderRunsheetLists, _buildRunsheetCard, renderSearchDropdown, openRunsheet, renderActiveSession, renderCompletedTab, renderCompletedList, renderAccount.
- Differences are wrapper/mount integration, shared session/client, error display and normalized identity rendering. The embedded module reads currentUser.name with email fallback rather than relying on currentUser.user_metadata.name, resolving the earlier false profile/connectivity display issue.
- Embedded module uses RW_SHARED_SUPABASE and shared RW_Auth; no second Supabase client was detected. No iframe or child-app navigation is used.
- The embedded picker exposes cancel/reopen actions while its module initializer accepts the active role مخزن شامل. The live Edge endpoints for those two actions do not accept that role. This is a server/UI contract mismatch, not a mismatch in picker domain methods.

**Conclusion:** Do not rewrite Picker. Preserve the current native bundle and patch the two authorization gates only after approval.

## 5. E2E evidence and limitations

Latest GitHub Actions run: 42902690529, workflow RAWAEA — Standalone Unified Warehouse E2E, HEAD 81bc832cb37f2eca22d6375497e2041f051546db, conclusion success. Job 130132534409 completed successfully.

PASS markers in job logs included: four-tab contract; no iframe/child navigation; seven native bundles; module CSS scope; shared auth/no duplicate clients; shared core session; Picker role alignment; full native workflows preserved; normalized Picker profile rendering; Loader/Returns/Unloader pending render; three count modes/session save; five manual voucher actions; SupplierReturn specialized contract; voucher back-to-list; branch receipt request and role/source actions; account/logout cleanup; role gates; employee aliases; main-vs-scoped-branch gating.

**Test boundary:** Playwright uses mocked Supabase/auth responses and fake DB mutations. It proves UI wiring and state transitions under the harness. It does not prove real JWT/session authorization, live RLS, live RPC/Edge behavior, stock effects, GL/AP/AR impact or Cloudflare deployment. It does not exercise picking cancel/reopen or completed-return reopen.

## 6. SMART ERP live baseline (read-only)

Active warehouse roles at query time: 25 users with no active warehouse role, 2 أذونات, 1 استلام, 1 تحضير, 1 تحميل, 1 مخزن شامل, 1 مرتجعات.

Current unified-role actor was found active in the same company as main branch BR-01, with role أمين مخزن, active_warehouse_role مخزن شامل, permissions [warehouse], allowed_branch_ids [BR-01]. app_private.user_can_access_warehouse_branch returned true for the user's access to the configured main branch. No test role assignment was performed.

Production row-count baseline:

| Table | Rows |
|---|---:|
| runsheets | 2 |
| run_sheet_details | 12 |
| stock_branches | 58 |
| inventory_log | 78 |
| stock_vouchers / stock_voucher_details | 0 / 0 |
| receiving / receiving_details | 1 / 2 |
| purchase_orders / purchase_order_details | 3 / 5 |
| purchase_invoices / purchase_invoice_details | 5 / 11 |
| inventory_counts / inventory_count_details | 0 / 0 |
| inventory_stock_requests / inventory_stock_request_details | 0 / 0 |
| supplier_ledger | 3 |
| journal_entries | 21 |
| treasury | 4 |
| cash_box | 9 |

Only two production runsheets were returned: RS-1 Delivered and RS-2 Returned, both historical/closed. No open/pending assigned runsheet was available for safe real-account E2E. There is no stock_branches update trigger in the inspected schema; raw qty updates do not automatically create inventory_log entries.

## 7. Operational flow and database impact review

| Workspace / operation | Live route / central contract | Verified impact and status |
|---|---|---|
| Picker start/complete | start-picking v36 / complete-picking v19; shared warehouse-auth + main-branch assertion | Full role supported; uses canonical picking reservation and completion contracts. |
| Picker cancel/reopen | cancel-picking v5 / reopen-picking v9; SQL cancel_runsheet_picking / reopen_runsheet_picking | Backend currently accepts only exact role تحضير (or verified owner); full role is denied despite UI exposing buttons. SQL rechecks company/auth identity, run-sheet state and picker assignment; reservation release and qty_picked reset occur transactionally. |
| Loader start/complete | start-loading v7 / complete-loading v12 | Shared role helper and main branch assertion accept مخزن شامل. Completion moves stock from main branch to vehicle branch through post_stock_movement. |
| Loader reopen | reopen-loading v3 | Current deployed source already uses shared role/main-branch guards and confirms loader_id assignment before atomic reopen. It restores vehicle-to-main movement and reservation through existing RPC. |
| Loader cancel | cancel-loading v5 / cancel_runsheet_loading | Current SQL verifies company/user, Loading state and loader assignment; zeros loaded quantities and returns state to Picked. It does not post a stock movement. Edge wrapper is older and lacks shared branch helper, so consistency hardening is recommended but not the primary defect. |
| Returns start/complete | start-return v6 / complete-return v28 | Shared helper accepts full role and main branch. Completion uses complete_sales_return_credit_note_atomic → complete_return_atomic, which posts SalesReturn stock movement, journal entry, possible customer ledger/refund and driver-liability records, then creates posted credit note. |
| Returns cancel | cancel-return v4 | Validates auth/company/status/handler and refuses completed returns, but requires exact مرتجعات role. Full role is denied. No stock/financial posting occurs on this cancel path. |
| Returns reopen completed | reopen-return v1 | CRITICAL: service-role endpoint directly decrements stock_branches.qty, clamps at zero, then changes runsheet state. It writes no inventory_log movement and does not reverse GL, customer ledger, refund or credit note. Not atomic, no company scoping on the runsheet query, no checking all DB write errors, and no idempotency. Unsafe; must be blocked until a complete, atomic stock + financial reversal contract is designed and approved. Never test this endpoint. |
| Receiving | receiver.html → receive-purchase v18 | Current route verifies effective profile under caller JWT and accepts active استلام or مخزن شامل. Validates accepted/sent qty and reason, requires reusable UUID operation_id, then invokes atomic PO/quick-market receiving RPC. Legacy start/cancel/reopen-receiving v1 are not called by current receiver.html. |
| Legacy reopen receiving | reopen-receiving v1 | Dormant in current Receiver source, but the deployed endpoint remains active. It directly decrements stock_branches.qty for prior received quantity, without inventory_log or corresponding purchase/AP/invoice reversal, and updates PO state. It must be blocked/retired before any client uses it. No current app usage was identified in the inspected Receiver file. |
| Unloading | unloader.html → unload-runsheet v7 | Shared role helper accepts full role; main branch checked; SQL posts VAN-to-main stock movement and clears loaded quantities in a central atomic lifecycle. |
| Inventory count | counter.html → save-inventory-count v5 → inventory_count_engine | Engine validates active user and full role, checks each branch via app_private.user_can_access_warehouse_branch; FINALIZE uses post_stock_movement for differences. No count session was created. |
| Vouchers | vouchers.html → create/send/receive/complete/cancel stock voucher wrappers and central RPCs | Current RPCs validate actor/company/branch scope and state; receive/transfer and DirectReturn paths enforce receiver/custodian contracts. Draft create/save alone does not post stock. |

## 8. SupplierReturn: real supplier, stock and accounting semantics

Live SQL definitions were read, not inferred from the UI:

1. SupplierReturn Draft creation/contract save writes document metadata and evaluated lines; it does not move stock or supplier balances.
2. send_stock_voucher_atomic checks actor, branch scope and assert_supplier_return_contract, then calls the core sender. The core sends a SupplierReturn movement through post_stock_movement from the source branch/vehicle context and transitions Draft → Sent. This is the physical stock-out stage.
3. complete_manual_stock_voucher_atomic validates the actor, SupplierReturn contract and source branch scope, then invokes the accounting core. The core posts supplier ledger debit (reducing payable), debits supplier AP account 211, credits inventory account 124 after discounts, posts purchase-tax reversal lines, writes finance_tax_transactions and marks the voucher Completed.
4. SupplierReturn access is intentionally constrained for مخزن شامل: actor must be eligible and the source draft must be creator-owned and within the user's permitted branch scope. Do not weaken this policy just to make all vouchers globally editable.
5. This flow is distinct from sales-return reopen. It has a dedicated central supplier contract and atomic stock/financial stages. No live SupplierReturn was created or sent in this audit.

## 9. Exact backend gaps requiring a reviewed ChangeSet

### A. Picking cancel/reopen authorization parity

Live reopen-picking v9 and cancel-picking v5 manually check auth, company, permissions and owner status, then reject any active role other than exact تحضير. The UI module initializer permits مخزن شامل. Their SQL RPCs also require service_role and therefore rely critically on these Edge authorization guards.

Proposed minimal patch to each deployed Edge source (no SQL RPC behavior change):

- Import requireWarehouseRole and assertWarehouseMainBranch from ../_shared/warehouse-auth.ts.
- After resolving Authorization, invoke requireWarehouseRole(supabase, authHeader, "تحضير") and assertWarehouseMainBranch(supabase, actor).
- Replace only the exact-role exclusion with a role predicate that allows تحضير and مخزن شامل; retain verified-owner behavior and all current company, assigned-picker, state and RPC checks.
- Keep release_stock_reservation, qty_picked reset and status transitions inside the existing SQL RPCs unchanged.

### B. Returns cancel authorization parity

cancel-return v4 uses a sound same-company/assigned-handler/open-return guard but its role predicate excludes مخزن شامل. Proposed minimal patch: shared requireWarehouseRole(..., "مرتجعات") + assertWarehouseMainBranch, and permit both مرتجعات and مخزن شامل in the existing final role predicate. Preserve status=Returning, return_handler_id=current user and return_end IS NULL checks. No stock or financial behavior should be added.

### C. Completed return reopen — safety blocker

Do not simply add مخزن شامل to this endpoint. The current operation attempts to undo a completed sale return. It needs a single atomic/idempotent reversal that reconciles stock movements and reservations, inventory_log, order_details/run_sheet_details, returned values, driver liability, posted journal/COGS/inventory entries, customer ledger or POS cash refund, credit note status/links and audit trail. A partial raw qty update is not an acceptable substitute.

Minimum immediate containment proposal: fail closed in reopen-return v1 before any DB mutation, with a clear message that completed-return reopen is suspended until an approved reversal contract exists; then remove/disable the visible reopen action in both standalone returns.html and embedded native Returns bundle. Do not claim feature completion until the proper reversal lifecycle is implemented.

### D. Legacy reopen receiving

Current receiver.html does not call legacy reopen-receiving v1; it uses receive-purchase v18. The old endpoint nevertheless remains ACTIVE and performs direct raw stock qty decrement with no corresponding purchase/AP reversal. Proposed containment: disable the old endpoint (fail closed before any DB mutation) unless a separate call-site audit proves another supported client still requires it. Do not alter the current receive-purchase path.

### E. Source control drift for deployed Edge functions

The active reopen-picking/cancel-picking/reopen-return/cancel-return and legacy reopen-receiving sources are available through Supabase live Edge retrieval but their index.ts files are not present in the inspected operational Git tree. Before any deployment, restore the exact live source into the operational repository, review its diff, and establish deployment workflow behavior. Do not edit the live remote source invisibly or deploy an untracked emergency change.

## 10. What was and was not changed

- Created no operational app source change, SQL migration, RPC/ACL change, Edge deployment, RLS policy, role assignment, stock movement, inventory count, voucher, purchase receipt, supplier return, journal entry, cash/treasury movement or customer/supplier balance adjustment.
- No test fixture was inserted; baseline counts remain a read-only point-in-time measurement, not a post-test assertion.
- No Supabase branch or paid test environment was created.
- The report and CURRENT_STATE checkpoint are governance documentation only; they do not change operational application behavior.

## 11. Release gates and next actions

1. Obtain approval for the exact three role/branch guard patches in §9.A/§9.B and the separate fail-closed containment of reopen-return and dormant reopen-receiving in §9.C/§9.D. No broad role relaxation.
2. Restore the exact deployed Edge source into Git, apply the approved surgical source diff, run Deno type/lint/static authorization tests, and verify deployment workflow before release.
3. Add Playwright/contract tests for full-role allow, wrong-role denial, wrong-company denial, out-of-scope branch denial, foreign picker/loader/return assignment denial, completed-return reopen fail-closed, and legacy receiving reopen fail-closed.
4. Deploy only approved changes. Confirm exact Supabase Edge versions and Cloudflare commit; current warehouse.html HEAD deployment is not yet verified.
5. Real authenticated E2E requires an existing assigned open work item or a fully reversible synthetic fixture with a measured baseline and proven cleanup. Current production contains only two closed runsheets, so real picker lifecycle E2E was not run.
6. For any future end-to-end mutation test, compare before/after stock_branches, allocated_qty/reservations, inventory_log, order_details, run_sheet_details, runsheets, stock vouchers, supplier_ledger, journal_entries, treasury/cash_box, driver_liabilities and audit_log, and prove cleanup/compensation before calling it passed.

## 12. Final status

**CONFIRMED:** current native architecture, Parent entry link, 26-method Picker parity, current HEAD, latest mocked CI PASS, live SMART ERP health, role scope for existing unified-role actor, central posting semantics for receiving/loading/unloading/count/vouchers/SupplierReturn.

**BLOCKED:** end-to-end real-authenticated production lifecycle test; Cloudflare parity with current HEAD; unified-role cancel/reopen Picker and cancel Returns parity; unsafe completed-return reopen; legacy reopen-receiving containment; source-control parity for deployed Edge functions.

**No production mutation was performed. Do not mark Warehouse Gold/Diamond or fully released until the blockers above are resolved and real authenticated acceptance evidence is captured.**

---
Operational HEAD: 81bc832cb37f2eca22d6375497e2041f051546db  
Warehouse blob: 31c4f1ae903b389269a4b90afdf310784f77f194  
Picker blob: a94e18f1c7b2de5dad912011bb32999611976b8e  
CI run: 42902690529 (PASS; mocked Supabase)  
SMART ERP project: fiilmooggumokxanwiyx  
Previous checkpoint: LVE-2026-11-10-694