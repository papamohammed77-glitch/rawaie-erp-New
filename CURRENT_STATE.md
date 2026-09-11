# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-11 — MAIN3 FORENSIC RECHECK

### GOVERNING TARGET — NON-NEGOTIABLE
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع ولا يُتعامل معه كإضافات شكلية.

الحوكمة الحاكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

## SOURCE-OF-TRUTH GOVERNANCE
- Production الحالية هي حقيقة التنفيذ.
- Git هو المصدر القانوني القابل لإعادة الإنتاج، وليس بديلًا عن Production.
- التقارير التاريخية أدلة جنائية وليست حقيقة حالية.
- Source of Truth التحريري للملف الأم: `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` مرجع تاريخي immutable.
- `Current/PWA/New-main` مرحلة تاريخية فقط، وليس مصدر مراجعة حالي.
- Main1 مسؤول عن Shell/Control Plane، والواجهات الوظيفية موزعة على Main2–Main11.
- لا Assembly قبل اكتمال ومراجعة الأجزاء الـ11.

## LATEST DOCUMENTATION / EXECUTION
- Report121: `doc/Draft/Reprots/Report121_Main2_Forensic_Recheck_20260911.md`.
- Report122: `doc/Draft/Reprots/Report122_Main3_Forensic_Recheck_20260911.md`.
- Main3 source: `Current/PWA/main2/main3.md`.
- Main3 current blob SHA: `479060e3d4bea5e2203c87f822b1dbc0e2f7d456`.
- Main3 was re-read to EOF; no Main3 source mutation was performed by the assistant.
- `Original/PWA/main/main3.md` used only for historical comparison.

## ASSEMBLY SOURCE GOVERNANCE
- `forensic_main_assembly.yml` now exists at repository root and explicitly points to `Current/PWA/main2` with Main1–Main11 fragments.
- Forbidden assembly sources remain `Current/PWA/main` and `Current/PWA/New-main`.
- Final assembly remains deferred.

## MAIN1 STATUS — OPEN OWNER WORK
Previously proven Main1 owner items remain open until manually applied and reverified:
- `MAIN1-N1` — add `window.togglePasswordVisibility` before the `byId` helper.
- `MAIN1-N2` — fix `RW_Notification.showPanel()` to preserve DOM listeners by passing the constructed node rather than its outerHTML.
- `MAIN1-N3` — replace forgot-password anchor with actionable reset handler.
- `MAIN1-N4` — Quick Search remains discovery-only; no safe implementation invented.
- `MAIN1-WF` — workflow executor/dispatcher contract not proven; no speculative executor implemented.

## MAIN3 — FORENSIC RESULT
Main3 contains:
- `RW_Customers`.
- `RW_Suppliers`.
- `RW_Branches`.
- `RW_Settings`.
- `RW_Users`.

Main3 is syntactically structured and contains no `(قيد التطوير)` marker found during current read, but remains CRUD-heavy and therefore is not yet Gold/Diamond functionally complete.

### MAIN3 OWNER SURGERY — REQUIRED
1. `MAIN3-N1` at current line 870:
   `allowed_branch_ids: selectedBranches.join(','),`
   Replace with:
   `allowed_branch_ids: selectedBranches,`

2. `MAIN3-N2` around current line 336:
   Replace the branch button label `حذف` with `تعطيل الفرع` because Production preserves branch history by deactivation.

3. `MAIN3-N3` at current line 64:
   Replace editable customer debt input with readonly/disabled display; do not invent a new opening-balance accounting contract.

4. `MAIN3-N4` at current line 209:
   Replace editable supplier payable input with readonly/disabled display; do not invent a new opening-balance accounting contract.

These are Owner changes; the assistant must not directly rewrite `Current/PWA/main2/main3.md`.

## PRODUCTION CAPABILITIES UPDATED
The following Edge Functions were directly updated and verified as ACTIVE:
- `save-customer` v4 — authenticated company/permission gate.
- `delete-customer` v3 — company scoped; deactivates when history exists.
- `save-supplier` v4 — authenticated company/permission gate.
- `delete-supplier` v3 — company scoped; deactivates when history exists.
- `save-branch` v4 — authenticated company/permission gate.
- `delete-branch` v3 — company scoped; prevents disabling the configured main branch.
- `save-employee` v8 — authenticated company/permission gate; JSONB-compatible branch scope and Owner protection.
- `delete-employee` v3 — company scoped; deactivation, Owner/self protection.
- `save-settings` v13 — unchanged in this checkpoint.

Inventory writer centralization work from earlier checkpoints remains in force; no order/runsheet/picking/loading/delivery/return writer was changed in this Main3 session.

## SCHEMA / DATA FACTS
- `items.item_code` has global UNIQUE constraint and is therefore a valid global item identity key in the current schema.
- `stock_branches` is unique on `(branch_id,item_id)`.
- `stock_vouchers` is unique on `(company_id,voucher_code)`.
- `users.allowed_branch_ids` is JSONB; Owner wildcard semantics `['*']` must remain intact.
- `customer_assignments` is protected by RLS using company/customer relation and `customers` permission.
- Branch/customer/supplier records have downstream operational and financial references; hard delete must not be used when history exists.

## PRODUCTION DATA INTEGRITY NOTES
The previously discovered cross-company `stock_branches` rows were not blindly deleted. Their meaning was not treated as proven corruption because current item identity is globally unique and the historical/fixture distinction must be preserved until source provenance is established.

## VALIDATION TOOLING
`.github/workflows/validate-main2-fragments.yml` was corrected to validate all Main1–Main11 files using `node --check` and explicit existence checks.
A reliable post-commit CI run proving the new workflow was not exposed through the available GitHub connector; therefore CI PASS is not claimed as fact.

## GOLD/DIAMOND FUNCTIONAL GATE
The project-level target remains functional completion, not visual completion.

Main3 future completion must add evidence-backed business depth such as:
- customer statement/history/credit context;
- supplier statement/history/aging;
- branch operational snapshot;
- complete user/permission/assignment management;
- settings behavior tied to real current contracts.

No speculative schema, accounting rule, workflow engine, or inventory lifecycle was invented.

## FINAL CHECKPOINT FOR NEXT SESSION
Start at `Current/PWA/main2/main3.md` after applying `MAIN3-N1..N4`.
Then re-read Main3 completely, run syntax validation through the corrected 1–11 validator, and continue only with the next unclosed functional gap.
Do not start final assembly yet.
