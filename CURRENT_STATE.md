# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-11 — MAIN1 FORENSIC RE-CHECK R4

### GOVERNING TARGET — NON-NEGOTIABLE
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع ولا يُتعامل معه كإضافات شكلية.

الحوكمة الحاكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

### SOURCE-OF-TRUTH GOVERNANCE
- Production الحالية هي حقيقة التنفيذ.
- Git هو المصدر القانوني القابل لإعادة الإنتاج، وليس بديلًا عن Production.
- التقارير التاريخية أدلة جنائية وليست حقيقة حالية.
- Source of Truth التحريري للملف الأم: `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` مرجع تاريخي immutable.
- `Current/PWA/New-main` مرحلة تاريخية فقط، وليس مصدر مراجعة حالي.
- Main1 مسؤول عن Shell/Control Plane، والواجهات الوظيفية موزعة على Main2–Main11.
- لا Assembly قبل اكتمال ومراجعة الأجزاء الـ11.

## CURRENT GIT TRUTH — FRESH R4
- Main1 current SHA: `8275750c05c353dec9ed825ca4aff7a4f6d05fab`.
- Main1 source: `Current/PWA/main2/main1.md`.
- لا يوجد تعديل جديد على Main1 في هذه الجلسة.
- تقرير هذه الجلسة: `doc/Draft/Reprots/MAIN1_FORENSIC_RECHECK_20260911_R4.md`.
- تم التحقق أن `forensic_main_assembly.yml` غير مثبت وجوده في المواقع المفحوصة، ولم يتم إنشاؤه بالتخمين.

## FRESH PRODUCTION SNAPSHOT — 2026-09-11 R4
تم التحقق مباشرة من Production في UTC `2026-09-11 08:10:13.866449`.
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
- active workflow_rules = 3
- workflow_log = 0

## MAIN1 FORENSIC RE-CHECK

### Already correct — DO NOT REAPPLY
- Finance actions use `perm: ['finance', 'finance_manager']`.
- HR uses `perm: 'hr'`.
- CRM uses `perm: 'customers'`.
- `isAllowed(item)` supports permission arrays with OR semantics.
- Owner + wildcard semantics preserved.
- Audit table/detail and Notification panel dynamic output are already protected through DOM/textContent in current source.

### MAIN1-WF — OPEN
Exact element:
`function evaluate(tableName, event, recordId, recordData) {}`
inside `RW_Workflow`, around line 351.

Current proven behavior:
- matches workflow rules;
- creates `status: 'pending'` action records;
- does not execute actions;
- nevertheless records `workflow_log.status = 'success'`;
- swallows workflow-log insertion errors.

Current Production active rules:
1. `UpdateStockAndJournalOnPOReceive` → `update_inventory`, `create_journal_entry`.
2. `CreateJournalOnOrderDeliver` → `create_journal_entry`.
3. `CreateStockVoucherOnOrderConfirm` → `create_stock_voucher`.

Production PostgreSQL source search did not prove a dispatcher/executor for these action names. Therefore no replacement was invented.

### EXACT OWNER ACTION — NONE FOR NOW
لا تحذف ولا تستبدل دالة `evaluate()` الآن. لا يوجد Replacement آمن قبل إثبات Executor contract.

## MAIN2–MAIN11 FORENSIC CROSS-CHECK
تمت مراجعة مباشرة لأجزاء متعددة من Main2–Main11 لتحديد نقاط التكامل والفجوات، مع عدم تحويل القراءة المقتطعة من أداة النقل إلى ادعاء Full EOF.

- `main2`: يعرض Item/Stock center وتبويبات الأصناف/الحركة/المصفوفة وتحديث الأرصدة؛ يعتمد على `RW_Data.loadItems()` وبيانات المخزون حسب الفروع.
- `main3`: العملاء والموردون؛ المسارات المعروضة تستخدم `RW_Data` وEdge Functions مع Company scoping في نقاط رئيسية.
- `main4`: POS/TeleSales؛ حساب Available Stock مبني على `qty - allocated` من cache، والحفظ يستخدم Edge Function.
- `main5`: Orders؛ Company-scoped reads وRealtime للمبيعات، مع الحاجة لاستكمال تحقق end-to-end بعد Assembly.
- `main6`: Online Store؛ يعتمد على بيانات المنتجات و`submit-online-order`، ولا يوجد ما يثبت اكتمال capability التجارية end-to-end من الملف وحده.
- `main7`: Receiving/Vouchers/Inventory Count/Settlement؛ يوجد تكرار في الوصول إلى Company ID عبر `RW_STATE.app.companyId` بدل العقد الأكثر وضوحًا في Main1 (`RW_STATE.app.company.id`)، وهي نقطة تكامل يجب توحيدها لاحقًا بعد إثبات الـruntime contract.
- `main8`: Finance؛ ثمانية تبويبات مع CRUD/عرض وتقارير أولية، لكن وجود UI لا يساوي اكتمال capability المحاسبية.
- `main9`: Reports؛ Dashboard/Detailed/Comprehensive موجودة، وبعض التوصيات محجوبة خلف `Capability Gate` لأن مصدر Production السلطوي غير مثبت لها.
- `main10`: Owner/License management موجود.
- `main11`: HR/CRM؛ نقص وظيفي صريح مثبت في HR لأن مستندات الموظف تعرض `(قيد التطوير)` للهوية وعقد العمل.

## SYNTAX VALIDATION
- Main1 structural reread + EOF boundary verification: DONE.
- Full JavaScript parser/browser syntax PASS: NOT PROVEN.
- Main2–Main11 full parser/E2E PASS: NOT PROVEN.
- لذلك لا يوجد ادعاء Syntax 100% ولا Functional 100%.

## PRODUCTION / DATA MUTATION
- لم يتم تعديل `Current/PWA/main2/main1.md` أو أي main2–main11.
- لم يتم تعديل `Original/PWA/main`.
- لا mutation لبيانات Main1 business data في جلسة R4.
- تم تنفيذ verification فقط على Production لهذه الجلسة.

## CLOSURE STATUS
- Governance reread: `CLOSED`
- Main1 forensic reread: `CLOSED`
- Fresh Production synchronization: `CLOSED FOR THIS CHECKPOINT`
- Historical reconciliation R2/R3 vs current source: `DONE`
- Main1 E/F/G: `ALREADY PRESENT`
- Main1-WF: `OPEN — EXECUTOR CONTRACT DISCOVERY`
- Main1 functional closure: `OPEN`
- Main1 Gold/Diamond: `OPEN`
- Global Gold/Diamond: `OPEN`
- Assembly: `DEFERRED`

## FINAL SELF-AUDIT
### What was proven
- Main1 الحالي هو `Current/PWA/main2/main1.md` وSHA الحالي `8275750c05c353dec9ed825ca4aff7a4f6d05fab`.
- Production snapshot تم تحديثه مباشرة عند `2026-09-11 08:10:13.866449 UTC`.
- E/F/G موجودة بالفعل ولا يجوز إعادة تطبيقها.
- Workflow false-success ما زال عيبًا وظيفيًا مثبتًا.
- Production لديها 3 Workflow rules فعالة، ولم يثبت Executor لهذه الـActions.
- Main11 يحتوي `(قيد التطوير)` بشكل صريح في HR documents.
- لم يثبت وجود `forensic_main_assembly.yml` في المواقع المفحوصة.

### What was not proven
- Full parser/browser syntax PASS.
- Workflow Executor/Dispatcher contract.
- Functional completeness لكل Main2–Main11.
- Final integrated assembly.
- Browser/PWA end-to-end Production runtime.

## NEXT EXACT RESUMPTION POINT
`MAIN1-WF — EXECUTOR CONTRACT DISCOVERY`

لا يتم تعديل `evaluate()` قبل إثبات عقد الـExecutor من Git + Production.

## GOVERNANCE RULE
لا قيمة لأي نسبة أو تقرير قبل مطابقة Production الحالية في نفس لحظة التقرير. لا تعديل يبنى على الظن أو التخمين. وجود واجهة أو Commit أو Staging PASS لا يساوي Functional Production Closure.
