# RAWAEA ERP — MAIN1 FORENSIC RE-CHECK R3
## 2026-09-11

> **المبدأ الحاكم المتكرر:** هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يُتعامل معه كإضافات شكلية. والمنهج الحاكم: الدراسة أولًا، إعادة بناء العقد التاريخي، تتبع السلوك الحالي، تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

## 1. نطاق الجلسة
- تم إيقاف مسار Inventory السابق والتركيز على إعادة الفحص الجنائي لـ Main1.
- تم الرجوع إلى MASTER Governance، وOWNER_CHANGESETS R2، وCTO_EXECUTION_LOG R2، وCURRENT_STATE، ثم التحقق من المصدر الحالي مباشرة.
- `Current/PWA/main2/main1.md` هو Source of Truth التحريري للـMain1، ولا يجوز للمساعد تعديله مباشرة؛ التنفيذ التحريري في هذا الملف من اختصاص المالك.
- `Original/PWA/main/*` مرجع تاريخي فقط.
- `Current/PWA/New-main` ليس مصدرًا للمراجعة الحالية.

## 2. الحالة الحالية المثبتة
- Main1 الحالي في Git هو:
  `Current/PWA/main2/main1.md`
- Current SHA المثبت مباشرة: `8275750c05c353dec9ed825ca4aff7a4f6d05fab`.
- تم تجاوز حدود EOF القديمة المسجلة في R2؛ القراءة الحالية أثبتت وجود محتوى بعد الحد 1049، ثم أصبحت القراءة فارغة في النطاق اللاحق. لذلك EOF القديم في R2 غير صالح كمرجع للحالة الحالية.
- Main1 ما زال Shell/Control Plane، ويحتوي على bootstrap لـSupabase وRW_STATE وAuthentication وPermissions وAudit وWorkflow وNotifications وNavigation، بينما `RW_Views` تبقى مسؤولية الملفات الأخرى.

## 3. Production snapshot — لحظة التحقق
تمت إعادة قراءة Production مباشرة في UTC:
`2026-09-11 07:27:23.265014`

النتائج:
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

هذه الأرقام هي Snapshot هذه الجلسة وتتفوق على أي Snapshot أقدم في التقارير.

## 4. ما هو موجود بالفعل ولا يجب إعادة تطبيقه
تم إثبات أن الإصلاحات التالية موجودة بالفعل في Main1 الحالي:
- Finance permissions السبعة باستخدام `perm: ['finance', 'finance_manager']`.
- HR menu باستخدام `perm: 'hr'`.
- CRM menu باستخدام `perm: 'customers'`.
- `isAllowed(item)` يدعم permission arrays بمنطق OR.
- Owner + wildcard semantics محفوظة.
- `RW_Audit_renderTable(data)` أصبحت DOM-based وتستخدم `textContent` للقيم الديناميكية.
- `RW_Audit_showDetails(logId)` تستخدم DOM/textContent وPre literal text للـJSON.
- `RW_Notification.showPanel()` تعرض title/body باستخدام `textContent` بدل إدخال بيانات قاعدة البيانات مباشرة كـHTML.

وبالتالي فإن MAIN1-E/F/G الواردة في R2 كـSURGERY READY ليست أعمالًا جديدة في المصدر الحالي؛ لا تعاد.

## 5. MAIN1-WF — الفجوة المؤكدة الوحيدة في هذه المراجعة
العنصر الدقيق:
`function evaluate(tableName, event, recordId, recordData) {`
داخل `RW_Workflow`، ويبدأ حاليًا عند حوالي السطر 351.

السلوك الحالي المثبت:
- يطابق rule مع table/event/condition.
- يبني `executed` بقيم `status: 'pending'` فقط.
- لا ينفذ أي Action من `rule.actions`.
- يسجل `workflow_log.status = 'success'` رغم عدم تنفيذ Action.
- يبتلع أخطاء حفظ سجل Workflow.

Production يحتوي حاليًا على 3 قواعد Workflow فعالة مع أنواع Actions:
1. `UpdateStockAndJournalOnPOReceive` → `update_inventory`, `create_journal_entry`
2. `CreateJournalOnOrderDeliver` → `create_journal_entry`
3. `CreateStockVoucherOnOrderConfirm` → `create_stock_voucher`

و`workflow_log` = 0 حاليًا؛ لذلك لا توجد بيانات تاريخية زائفة تحتاج إلى إصلاح.

## 6. قرار الحوكمة — لا تخمين
تم البحث عن عقد Executor/Dispatcher لهذه الـActions في Production وفي مصادر Main2–Main11 المتاحة، ولم يثبت حتى الآن Executor كامل يمكن ربط `evaluate()` به بأمان.

لذلك:
- لا يتم حذف `evaluate()` الآن.
- لا يتم اختراع Executor.
- لا يتم اختراع payload أو auth/tenant contract أو transaction boundary أو retry semantics.

هذه نقطة Evidence Discovery مفتوحة، وليست إذنًا ببناء Workflow Engine تخميني.

## 7. Syntax validation
تمت إعادة قراءة Main1 الحالي حتى نهايته والتحقق من حدود EOF الحالية من GitHub.
لكن لم يتوفر في هذه الجلسة تنفيذ parser/browser كامل على الملف النهائي المستقل.

لذلك لا يوجد ادعاء `syntax PASS`.
المثبت فقط: Structural reread + boundary/EOF verification.

## 8. forensic_main_assembly.yml
تم البحث عن `forensic_main_assembly.yml` في الجذر و`doc/` و`doc/Draft/Reprots/` والبحث النصي المتاح، ولم يثبت وجود الملف.

لذلك لا يتم إنشاء أو تعديل ملف بهذا الاسم بالتخمين.
المسار الصحيح يجب إثباته من المصدر قبل أي تغيير.

## 9. التعديلات المنفذة في هذه الجلسة
- لا تعديل مباشر على `Current/PWA/main2/main1.md`.
- لا تعديل مباشر على `Current/PWA/main2/main2..main11`.
- لا تغيير على `Original/PWA/main`.
- لا تغيير في بيانات Main1 business data في Production.
- تم إجراء تحقق Production فقط دون mutation ضمن هذه المراجعة.
- تم إنشاء هذا التقرير كوثيقة R3 جديدة.

## 10. أخطاء/نتائج المراجعة
### نتائج/مشكلات مؤكدة
- CURRENT_STATE السابق يحمل SHA قديمًا لـMain1 ولا يمثل المصدر الحالي.
- OWNER_CHANGESETS R2 وCTO_EXECUTION_LOG R2 يحملان وصفًا قديمًا لـE/F/G رغم أن المصدر الحالي يحتوي الإصلاحات بالفعل.
- Main1-WF ما زال False-Success stub.
- `audit_log` في Production لا يحتوي `company_id`; لم يتم تغييره لأن عقد multi-company الصحيح لهذا الجدول لم يُثبت بعد.

### ما لم يحدث
- لم يتم حذف دالة Workflow.
- لم يتم اختراع Workflow executor.
- لم تتم إعادة تطبيق إصلاحات تاريخية موجودة بالفعل.
- لم يتم تنفيذ Assembly.
- لم يتم إعلان Main1 مغلقًا وظيفيًا.

## 11. التعليمات الدقيقة للمالك — Main1
**لا تلمس E/F/G؛ فهي موجودة بالفعل في الملف الحالي.**

ابحث عن:
```javascript
function evaluate(tableName, event, recordId, recordData) {
```
داخل `RW_Workflow`، عند حوالي السطر 351.

**لا تحذفه ولا تستبدله الآن.**

المطلوب التالي فقط هو إثبات Executor الحقيقي عن طريق البحث في:
- `Current/PWA/main2/main2.md`
- `Current/PWA/main2/main3.md`
- `Current/PWA/main2/main4.md`
- `Current/PWA/main2/main5.md`
- `Current/PWA/main2/main6.md`
- `Current/PWA/main2/main7.md`
- `Current/PWA/main2/main8.md`
- `Current/PWA/main2/main9.md`
- `Current/PWA/main2/main10.md`
- `Current/PWA/main2/main11.md`

عن الكلمات الدقيقة:
`update_inventory`
`create_journal_entry`
`create_stock_voucher`

وبالتوازي يتم إثبات Production RPC/Edge Executor لهذه الأنواع، مع payload والـauthorization والـtransaction boundary والـidempotency والـfailure contract.

بعد إثبات ذلك فقط يتم إعطاء استبدال كامل لدالة `evaluate()`.

## 12. NEXT EXACT CHECKPOINT
`MAIN1-WF — EXECUTOR CONTRACT DISCOVERY`

الحالة:
- Main1 forensic re-check = CLOSED
- Main1 functional closure = OPEN
- Gold/Diamond global closure = OPEN
- Assembly = DEFERRED
- Production Main1 mutation = NONE

## 13. SELF-AUDIT
### What was proven
- Governance basis was re-read.
- Current Main1 source was checked directly.
- Current Main1 SHA differs from the stale R2 SHA.
- Current Production snapshot was refreshed immediately before judgment.
- Finance/CRM/HR and E/F/G findings were reconciled against the current source.
- Workflow false-success remains proven.

### What was not proven
- Real Workflow Executor contract.
- Full parser/browser syntax PASS.
- Functional completeness of Main2–Main11.
- Final integrated assembly.
- End-to-end Production runtime of the assembled application.

### Final closure status
`MAIN1 FORENSIC RE-CHECK = CLOSED`
`MAIN1 FUNCTIONAL = OPEN`
`GLOBAL GOLD/DIAMOND = OPEN`
