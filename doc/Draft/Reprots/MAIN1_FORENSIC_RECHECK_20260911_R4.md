# RAWAEA ERP — MAIN1 FORENSIC RE-CHECK R4
## 2026-09-11

> **المبدأ الحاكم المتكرر:** هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يُتعامل معه كإضافات شكلية. والمنهج الحاكم: الدراسة أولًا، إعادة بناء العقد التاريخي، تتبع السلوك الحالي، تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

## 1. نطاق التنفيذ
- أُوقف مسار المهمة السابقة، وأصبح نطاق هذه الجلسة هو إعادة الفحص الجنائي لـ `Current/PWA/main2/main1.md` مع التحقق من بقية أجزاء Main2 كمصادر تكامل.
- تم الرجوع إلى Governance OS، وOWNER_CHANGESETS_20260911_MAIN1_R2، وCTO_EXECUTION_LOG_20260911_MAIN1_R2، وCURRENT_STATE، ثم الرجوع إلى المصدر الفعلي في Git وProduction.
- Source of Truth التحريري للملف الأم: `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` مرجع تاريخي فقط، و`Current/PWA/New-main` ليس مصدر المراجعة الحالي.
- لم يُنفذ Assembly، ولم يتم تعديل أي من ملفات `main1..main11` مباشرة من المساعد.

## 2. Main1 الحالي — حقيقة Git
- الملف: `Current/PWA/main2/main1.md`
- SHA الحالي المثبت مباشرة: `8275750c05c353dec9ed825ca4aff7a4f6d05fab`
- القراءة الحالية أثبتت أن المصدر الحالي يتجاوز حدود EOF القديمة المسجلة في R2، وينتهي فعليًا عند:
  `window.RW_Navigation = RW_Navigation;`
- إصلاحات E/F/G الواردة في تقرير R2 موجودة بالفعل في المصدر الحالي، لذلك لم تتم إعادة تطبيقها.

## 3. Production snapshot — لحظة الحكم
تمت مزامنة Production مباشرة قبل إصدار هذا التقرير، الساعة:
`2026-09-11 08:10:13.866449 UTC`

النتيجة:
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

## 4. Main1 — النتيجة الجنائية
### 4.1 الإصلاحات الموجودة بالفعل
- Finance actions تستخدم `perm: ['finance', 'finance_manager']`.
- HR يستخدم `perm: 'hr'`.
- CRM يستخدم `perm: 'customers'`.
- `isAllowed(item)` يدعم permission arrays بمنطق OR.
- Owner + wildcard semantics لم تُكسر.
- Audit table يستخدم DOM و`textContent` للقيم الديناميكية.
- Audit details يستخدم DOM و`textContent` مع `<pre>` literal.
- Notification panel يستخدم DOM و`textContent`.

### 4.2 الفجوة المفتوحة
العنصر الدقيق:
`function evaluate(tableName, event, recordId, recordData) {}`
داخل `RW_Workflow`، عند حوالي السطر 351.

السلوك المثبت مباشرة:
1. يطابق rule مع table/event/condition.
2. يبني action records بحالة `pending` فقط.
3. لا ينفذ أي Action.
4. يسجل `workflow_log.status = 'success'` رغم عدم تنفيذ Action.
5. يبتلع فشل تسجيل Workflow.

Production يحتوي على 3 قواعد فعالة:
- `UpdateStockAndJournalOnPOReceive` → `update_inventory`, `create_journal_entry`
- `CreateJournalOnOrderDeliver` → `create_journal_entry`
- `CreateStockVoucherOnOrderConfirm` → `create_stock_voucher`

التحقق من Production لم يثبت أي PostgreSQL function تحتوي هذه الأسماء التنفيذية داخل `prosrc`، ولم يثبت Dispatcher/Executor كاملًا يمكن ربطه بالدالة بأمان.

## 5. قرار المالك — لا تعديل Main1 الآن
لا تحذف ولا تستبدل:
```javascript
function evaluate(tableName, event, recordId, recordData) {
```
ولا يتم إعطاء Replacement تخميني.

سبب القرار: عقد الـExecutor غير مثبت من المصدر الفعلي. إنشاء Executor أو payload أو retry/idempotency أو transaction boundary دون إثبات سيخالف مبدأ الحوكمة.

**لا يوجد Change Request آمن للمالك على Main1 في هذه اللحظة.**

## 6. مراجعة تكامل الأجزاء الأخرى — نتائج مؤكدة
المراجعة المباشرة للأجزاء أظهرت أن Main1 ليس المشكلة الوحيدة، وأن الهدف Gold/Diamond لم يتحقق بعد.

### Main7
يحتوي على عمليات Receiving/Vouchers/Inventory Count/Settlement ويستخدم `RW_STATE.app.companyId` في أجزاء تشغيلية، بينما Main1 الحالي يعتمد أيضًا على `RW_STATE.app.company.id` في مصادر أخرى. هذه نقطة تكامل تحتاج إثباتًا موحدًا قبل توحيد الـState Contract.

### Main8 — Finance
التبويبات الثمانية موجودة (Treasury, Accounts, Journal, Receipts, Payments, Transfers, Reports, Budgets)، لكنها ليست دليلًا وحده على اكتمال Business Capability بالكامل. يلزم إغلاق الوظائف المحاسبية والتكاملات end-to-end قبل إعلان Gold/Diamond.

### Main9 — Reports
يحتوي Dashboard وDetailed/Comprehensive reporting، مع `Capability Gate` صريح يمنع بعض التوصيات غير المثبتة بمصدر Production سلطوي. هذا يمنع اعتبار بعض القدرات مكتملة لمجرد وجود UI.

### Main10 — Owner/License
توجد إدارة الترخيص وتغيير البريد وكلمة المرور، مع اعتماد Company-scoped settings في القراءة.

### Main11 — HR/CRM
يوجد نقص صريح مثبت في واجهة HR: بطاقات رفع "صورة الهوية" و"عقد العمل" تعرض النص `(قيد التطوير)`. هذه ليست شبهة؛ إنها حالة نقص مؤكدة في المصدر الحالي.

## 7. Assembly path
تم اختبار وجود:
- `forensic_main_assembly.yml`
- `doc/forensic_main_assembly.yml`
- `doc/Draft/Reprots/forensic_main_assembly.yml`

ولم يُثبت وجود الملف في أي من هذه المواقع. لذلك لم يتم إنشاؤه أو اختراع مساره.

## 8. Syntax validation
- Structural reread + EOF boundary verification لـMain1: DONE.
- Full JavaScript parser/browser syntax PASS على الملف النهائي المستقل: NOT PROVEN في هذه الجلسة.
- لا يُسمح بإعلان `syntax PASS` دون parser فعلي.

## 9. الأخطاء/العوائق التي ظهرت
- تقارير R2 تحمل SHA ووصفًا أقدم من المصدر الحالي.
- CURRENT_STATE السابق كان يحمل checkpoint أقدم.
- القراءة الكاملة البرمجية للأجزاء الكبيرة في GitHub تُعرض أحيانًا بشكل مقتطع من أداة القراءة، لذلك لا يمكن تحويل القراءة الجزئية إلى ادعاء "Full file EOF verified" لكل Main2–Main11.
- لا يوجد Executor Production مثبت لقواعد Workflow الثلاث.

## 10. ما تم وما لم يتم
### تم
- مزامنة Production جديدة قبل الحكم.
- إعادة فحص Main1 الحالي مباشرة.
- إعادة مطابقة نتائج E/F/G مع المصدر الحالي ومنع تكرار الإصلاح.
- فحص قواعد Workflow الحالية مباشرة في Production.
- فحص موضع `forensic_main_assembly.yml` دون إنشاء مسار تخميني.
- فحص مباشر لعدة أجزاء من Main2–Main11 لاكتشاف الفجوات الوظيفية الواضحة.

### لم يتم
- تعديل `Current/PWA/main2/main1.md`.
- تعديل `main2..main11`.
- Assembly.
- إعلان Main1 Functional Gold/Diamond.
- إعلان Global Gold/Diamond.
- Full parser/browser PASS.

## 11. نتيجة مطابقة الهدف الأصلي
**هل تحقق هدف استكمال ملفات النظام الأم وظيفيًا بالكامل؟**
لا. الأدلة الحالية لا تسمح بهذا الإعلان.

السبب ليس نقص واجهات فقط؛ توجد قدرات غير مكتملة مثبتة، منها Workflow executor غير مثبت، وHR document upload ما زال `(قيد التطوير)`، كما لم يثبت تكامل الأجزاء الـ11 كاملًا بعد.

**هل ما زالت هناك تبويبات أو وظائف ناقصة أو هيكلية أو `(قيد التطوير)`؟**
نعم. المثال المثبت مباشرة في `main11` هو قسم مستندات الموظف الذي يحتوي `(قيد التطوير)`. كذلك وجود UI لا يساوي اكتمال capability؛ لذلك يلزم إغلاق كل capability end-to-end قبل إعلان Gold/Diamond.

**متى يكتمل؟**
لا يوجد تاريخ ثابت يمكن إثباته الآن دون اختلاق تقدير. معيار الإغلاق هو اكتمال الـ11 أجزاء وظيفيًا، إثبات عقود الـExecutors، parser PASS، Assembly صحيح، ثم E2E Production verification.

## 12. NEXT EXACT RESUMPTION POINT
`MAIN1-WF — EXECUTOR CONTRACT DISCOVERY`

وللمالك على Main1:
لا حذف، ولا استبدال للدالة `evaluate()` في هذه المرحلة.

## 13. FINAL SELF-AUDIT
### What was proven
- Production snapshot حديث ومباشر.
- Main1 current SHA مثبت.
- E/F/G موجودة بالفعل.
- Workflow false-success مثبت مباشرة في Main1.
- قواعد Workflow الثلاث مثبتة في Production.
- لا يوجد PostgreSQL Executor مثبت للأسماء `update_inventory/create_journal_entry/create_stock_voucher`.
- Main11 يحتوي نقصًا صريحًا `(قيد التطوير)`.
- `forensic_main_assembly.yml` غير مثبت وجوده في المواقع المفحوصة.

### What was not proven
- Full parser PASS.
- Executor contract الكامل.
- اكتمال Main2–Main11 وظيفيًا بالكامل.
- Assembly النهائي.
- Browser/PWA E2E.

### FINAL STATUS
`MAIN1 FORENSIC = CLOSED`
`MAIN1 FUNCTIONAL = OPEN`
`GLOBAL GOLD/DIAMOND = OPEN`
`ASSEMBLY = DEFERRED`

## 14. GOVERNANCE REMINDER
الدراسة تسبق التعديل. لا قيمة لنسبة أو تقرير دون Production snapshot حديث مطابق للحظة الحكم. لا يُبنى أي إصلاح على الظن أو التخمين، ولا يتم اعتبار Commit أو Staging PASS أو وجود UI دليلًا على Production Functional Closure.
