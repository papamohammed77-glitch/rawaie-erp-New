# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-11 — MAIN1 FORENSIC RE-CHECK R3

### GOVERNING TARGET — NON-NEGOTIABLE
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع ولا يُتعامل معه كإضافات شكلية.

الحوكمة الحاكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

### SOURCE-OF-TRUTH GOVERNANCE
- Production الحالية هي حقيقة التنفيذ.
- Git هو المصدر القانوني القابل لإعادة الإنتاج، وليس بديلًا عن Production.
- التقارير التاريخية أدلة جنائية وليست حقيقة حالية.
- Source of Truth التحريري للملف الأم: `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` مرجع تاريخي immutable.
- `Current/PWA/New-main` مرحلة تاريخية/هدف تجميع فقط، وليس مصدر مراجعة حالي.
- Main1 مسؤول عن Shell/Control Plane، وواجهات الوحدات موزعة على Main2–Main11.
- لا Assembly قبل اكتمال ومراجعة الأجزاء الـ11.

## CURRENT GIT TRUTH — FRESH R3
- Main1 current SHA: `8275750c05c353dec9ed825ca4aff7a4f6d05fab`.
- Main1 source: `Current/PWA/main2/main1.md`.
- تم تجاوز حدود EOF القديمة المسجلة في R2؛ القراءة الحالية أثبتت وجود محتوى بعد الحد 1049، ثم الوصول إلى EOF فعلي في نطاق لاحق.
- تقارير R2 الخاصة بـMain1 تحمل SHA/وصفًا أقدم من المصدر الحالي، وتبقى محفوظة كأدلة تاريخية.
- تقرير الجلسة الجديدة: `doc/Draft/Reprots/MAIN1_REFORENSIC_20260911_R3.md`.

## FRESH PRODUCTION SNAPSHOT — 2026-09-11 R3
تم التحقق مباشرة من Production في UTC `2026-09-11 07:27:23.265014`.
- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- orders = 0
- purchase_orders = 0
- stock_branches = 20
- inventory_log = 3
- audit_log = 1869

Additional current facts:
- `workflow_rules` has 3 active rules.
- `workflow_log` = 0 rows.
- `items.item_code` is globally UNIQUE in the current schema.
- `users.auth_id` is UNIQUE.
- `audit_log` has no `company_id` column.

## MAIN1 FORENSIC RE-CHECK — RESULTS

### Already correct in current Main1 — DO NOT REAPPLY
- Finance actions use `perm: ['finance', 'finance_manager']`.
- HR uses `perm: 'hr'`.
- CRM uses `perm: 'customers'`.
- `isAllowed(item)` supports permission arrays with OR semantics.
- Owner + wildcard semantics remain preserved.
- Audit table XSS repair is already present using DOM + `textContent`.
- Audit details XSS repair is already present using DOM + `textContent` and literal `<pre>` content.
- Notification panel XSS repair is already present using DOM + `textContent`.

إذًا إصلاحات MAIN1-E/F/G الواردة في R2 لا تعاد.

### MAIN1-WF — OPEN / REAL FUNCTIONAL GAP
Exact element:
`function evaluate(tableName, event, recordId, recordData) {`
في `RW_Workflow`، عند حوالي السطر 351.

Current behavior proven directly:
- يطابق قواعد الـWorkflow.
- يبني action records بحالة `pending` فقط.
- لا ينفذ الـActions.
- يسجل `workflow_log.status = 'success'` رغم عدم تنفيذها.
- يبتلع أخطاء حفظ السجل.

Production workflow rules proven:
1. `UpdateStockAndJournalOnPOReceive` → `update_inventory`, `create_journal_entry`.
2. `CreateJournalOnOrderDeliver` → `create_journal_entry`.
3. `CreateStockVoucherOnOrderConfirm` → `create_stock_voucher`.

لا يوجد حتى الآن Executor/Dispatcher كامل ومثبت لهذه الـActions يمكن ربط `evaluate()` به دون تخمين؛ لذلك لم يُخترع replacement.

### EXACT NEXT WORK
لا تحذف ولا تستبدل `evaluate()` الآن.
ابحث في Main2–Main11 وProduction عن:
`update_inventory`
`create_journal_entry`
`create_stock_voucher`

ثم أثبت:
- موقع الـExecutor.
- Payload/parameters.
- Authorization/Tenant scope.
- Transaction boundary.
- Retry/Idempotency.
- Failure contract.
- انتقال المسؤوليات إلى downstream components.

بعد إثبات العقد فقط يتم إعداد replacement كامل للدالة.

## SYNTAX VALIDATION STATUS
- Structural reread + EOF boundary verification: DONE.
- Full JavaScript parser/browser syntax PASS: NOT PROVEN في هذه الجلسة.
- لا يُعلن syntax PASS دون تنفيذ parser فعلي على المصدر النهائي.

## ASSEMBLY CONFIG STATUS
تم البحث عن `forensic_main_assembly.yml` في الجذر و`doc/` و`doc/Draft/Reprots/` ولم يثبت وجوده.
لا يتم إنشاء أو تعديل مسار بهذا الاسم بالتخمين.

## PRODUCTION / DATA MUTATION
- لا تعديل مباشر على `Current/PWA/main2/main1.md` لأن نطاقه من اختصاص المالك.
- لا تعديل على Main2–Main11.
- لا تعديل على `Original/PWA/main`.
- لا Mutation لبيانات Main1 business data في Production خلال R3.

## CLOSURE STATUS
- Governance reread: `CLOSED`
- Main1 forensic reread: `CLOSED`
- Fresh Production synchronization: `CLOSED FOR THIS CHECKPOINT`
- Historical reconciliation of R2: `DONE / R2 SUPERSEDED BY CURRENT SOURCE`
- Main1 E/F/G: `ALREADY PRESENT / NO REPEAT SURGERY`
- Main1-WF: `OPEN — EXECUTOR CONTRACT DISCOVERY`
- Main1 functional closure: `OPEN`
- Main1 Gold/Diamond: `OPEN`
- Global Gold/Diamond: `OPEN`
- Assembly: `DEFERRED`

## FINAL SELF-AUDIT
### What was proven
- Current Main1 source is not the stale R2 SHA.
- Production snapshot was refreshed directly before judgment.
- Current source already contains E/F/G repairs described as open in R2.
- Workflow false-success remains a real functional gap.
- No safe Workflow Executor contract has been proven yet.
- No Main1 Production data mutation was justified.

### What was not proven
- Full syntax parser PASS.
- Workflow Executor/Dispatcher contract.
- Main2–Main11 functional completeness.
- Final integrated assembly.
- Browser/PWA end-to-end runtime.

## NEXT EXACT RESUMPTION POINT
`MAIN1-WF — EXECUTOR CONTRACT DISCOVERY`

Source element:
`Current/PWA/main2/main1.md :: function evaluate(tableName, event, recordId, recordData) {`

Evidence terms:
`update_inventory`
`create_journal_entry`
`create_stock_voucher`
