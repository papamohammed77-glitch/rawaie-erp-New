# RAWAEA ERP — MAIN1 FORENSIC RE-CHECK R5
## 2026-09-11

> **المبدأ الحاكم المتكرر:** هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يُتعامل معه كإضافات شكلية. والمنهج الحاكم: الدراسة أولًا، إعادة بناء العقد التاريخي، تتبع السلوك الحالي، تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

## 1. نطاق الجلسة
تم إيقاف مسار المهمة السابقة والتركيز على `Current/PWA/main2/main1.md` فقط، مع استخدام بقية Main2 كمصادر تكامل عند الحاجة. لم يتم تعديل أي ملف من `Current/PWA/main2/main1..main11.md` بواسطة المساعد، وفق توزيع المسؤوليات المعتمد.

مصادر الاستعادة التي تمت مراجعتها:
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `doc/Draft/Reprots/MAIN1_FORENSIC_RECHECK_20260911_R4.md`
- `doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R2.md`
- `CURRENT_STATE.md`
- المصدر الفعلي الحالي لـ `Current/PWA/main2/main1.md`
- Production Supabase الحالية

التقارير السابقة عوملت كأدلة جنائية لا كحقيقة حالية، وتمت مطابقة الادعاءات المهمة مع Git وProduction مباشرة.

## 2. Source of Truth
المسار المعتمد حاليًا:
`Current/PWA/main2/main1.md ... main11.md`

`Original/PWA/main/*` = مرجع تاريخي فقط.

`Current/PWA/New-main` = مرحلة متوقفة وليست مصدرًا حاليًا.

لم يتم تنفيذ Assembly، ولم يتم إنشاء `forensic_main_assembly.yml` بالتخمين. وجود الملف ومساره يحتاجان إثباتًا من المصدر قبل إنشائه.

## 3. Git Current Reality
`Current/PWA/main2/main1.md` ما زال على SHA:
`8275750c05c353dec9ed825ca4aff7a4f6d05fab`

الملف ينتهي فعليًا عند:
```javascript
window.RW_Navigation = RW_Navigation;
```

تمت إعادة قراءة المحتوى من المصدر والـblob الحالي، مع التحقق من حدود EOF وعدم وجود محتوى بعد النهاية المثبتة.

تم إنشاء سجل تغييرات المالك R5 فقط، دون تعديل Main1 نفسه:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R5.md`

Commit الخاص بسجل R5:
`32fa734a63e48ac6866fd5be6edcf8da10c238eb`

## 4. Fresh Production Snapshot
تمت مزامنة Production مباشرة في هذه الجلسة عند:
`2026-09-11 09:39:47.550805 UTC`

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

لم يتم إجراء mutation على بيانات Production الخاصة بالـbusiness flow في هذه الجلسة.

## 5. Main1 — ما ثبت أنه صحيح بالفعل
الإصلاحات التالية موجودة بالفعل في Main1 الحالي، ولذلك تم منع إعادة تطبيقها:
- Finance menu permissions = `['finance','finance_manager']`.
- HR = `hr`.
- CRM = `customers`.
- `isAllowed()` يدعم permission arrays بمنطق OR.
- Owner semantics وwildcard لم يتم كسرها.
- Audit table/detail dynamic values تستخدم DOM و`textContent` بالفعل.
- بيانات `RW_Data` الأساسية مقيدة بـcompany في المصدر الحالي.

هذه العناصر لا تُلمس في R5.

## 6. Main1 — العيوب الجديدة المثبتة مباشرة

### MAIN1-N1 — Password visibility function missing
العنصر الموجود في HTML يستدعي حرفيًا:
```html
onclick="window.togglePasswordVisibility('rw-password', this)"
```

بحث المصدر الحالي عن تعريف `togglePasswordVisibility` لم يثبت وجوده. النتيجة: الزر الحالي يستدعي دالة غير معرفة.

**الحالة:** Change Request آمن.

**Owner action موجود في R5:** إضافة `window.togglePasswordVisibility` كاملة فوق:
```javascript
const byId = id => document.getElementById(id);
```

البديل كامل وموجود في `OWNER_CHANGESETS_20260911_MAIN1_R5.md`.

### MAIN1-N2 — Notification listeners are lost
داخل `RW_Notification` الدالة الحالية `showPanel()` تبني عناصر DOM وتربط listeners صحيحة، ثم تمرر:
```javascript
html: root.outerHTML
```
إلى SweetAlert.

`outerHTML` يحول العقد إلى HTML جديد ويفقد listeners التي تم ربطها على `markAll` وصفوف الإشعارات.

**الحالة:** Change Request آمن.

**Owner action موجود في R5:** استبدال `showPanel()` كاملة، مع الإبقاء على DOM construction و`textContent`، وتمرير:
```javascript
html: root
```
بدل `root.outerHTML`.

الاستبدال الكامل موجود في `OWNER_CHANGESETS_20260911_MAIN1_R5.md`.

### MAIN1-N3 — Forgot Password decorative/inert control
العنصر الحالي:
```html
<a href="#" class="rw-forgot">نسيت كلمة المرور؟</a>
```
لا يحتوي على handler فعلي في Main1.

**الحالة:** Change Request آمن.

**Owner action موجود في R5:** تحويله إلى button معرف بـ`rw-forgot-password`، ثم إضافة handler باستخدام `RW_SUPABASE_CLIENT.auth.resetPasswordForEmail()` فوق آخر سطر:
```javascript
window.RW_Navigation = RW_Navigation;
```

البديل الكامل موجود في `OWNER_CHANGESETS_20260911_MAIN1_R5.md`.

## 7. Main1 — عناصر لم يتم تعديلها عمدًا

### MAIN1-N4 — Quick Search
العنصر:
```html
<input type="text" class="rw-header-search-input" placeholder="بحث سريع...">
```
لم يثبت داخل Main1 وحده عقد البحث الكامل، ولا مكان التنفيذ النهائي بين Main2–Main11.

**القرار:** لا نضيف handler تخمينيًا؛ لأن ذلك قد ينشئ Search implementation موازية أو duplicate routing.

### MAIN1-WF — Workflow false-success
الدالة:
```javascript
function evaluate(tableName, event, recordId, recordData) {
```
ما زالت:
- تطابق rules.
- تبني actions بحالة `pending`.
- لا تنفذ الـactions.
- تسجل `workflow_log.status = 'success'`.
- تبتلع فشل الكتابة.

Production الحالية تحتوي 3 rules فعالة:
- `UpdateStockAndJournalOnPOReceive`
- `CreateJournalOnOrderDeliver`
- `CreateStockVoucherOnOrderConfirm`

تم فحص Production الحالية ولم يثبت Executor/Dispatcher كامل بعقد parameters + authorization + retry + transaction يمكن الاعتماد عليه بأمان.

**القرار:** لا replacement تخميني. نقطة الاستكمال التالية هي `MAIN1-WF — EXECUTOR CONTRACT DISCOVERY` بعد استنفاد Current Main2–Main11 + Production + historical callers/callees.

## 8. Historical / Functional Completion Findings
الهدف Gold/Diamond لا يتحقق بمجرد اكتمال Shell. الفحص الحالي يدعم وجود نقص وظيفي خارج Main1، ومنه:
- Main7 يحتوي عمليات Receiving/Vouchers/Inventory Count/Settlement وتوجد ملاحظة State Contract بين `RW_STATE.app.companyId` و`RW_STATE.app.company.id` تحتاج إثباتًا موحدًا قبل الدمج.
- Main8 يعرض Finance tabs لكن وجود UI لا يثبت اكتمال capability المحاسبية end-to-end.
- Main9 يحتوي reporting capabilities مع gates تمنع بعض الادعاءات غير المثبتة.
- Main11 يحتوي نقصًا صريحًا سابق الإثبات في HR documents `(قيد التطوير)`.

هذه ليست موافقة على إغلاق أي من هذه الوحدات؛ بل إثبات أن Main1 ليس نقطة الاختناق الوحيدة.

## 9. Syntax / Structural Validation
- إعادة القراءة والـEOF لـMain1: **PROVEN**.
- سلامة حدود النص وعدم وجود محتوى بعد EOF: **PROVEN**.
- Full browser/parser execution لـMain1 مستقلًا: **NOT PROVEN** في هذه الجلسة لأن محتوى HTML الكبير لم يُشغّل داخل Browser runtime فعلي.
- لذلك لا يوجد ادعاء `Syntax 100% PASS`.

## 10. نتائج التحقق من Supabase المتعلقة بالحالة
تم التأكد من:
- `workflow_rules` يحتوي تعريف القواعد الثلاث الحالية.
- `workflow_log` لا يحتوي أي تنفيذ حالي (`0`).
- `notifications` و`notification_templates` لا تحتويان `company_id` في الـschema الحالي، لذلك لا تم اختراع tenant column/contract جديد في Main1.
- `audit_log` يعتمد على trigger `trg_audit_stock_vouchers` في `stock_vouchers` لمسار audit المرتبط بالإذن.

## 11. تغييرات هذه الجلسة
### Source
تم إنشاء:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R5.md`

لم يتم تعديل:
- `Current/PWA/main2/main1.md`
- `Current/PWA/main2/main2.md ... main11.md`
- `Original/PWA/main/*`

### Production
لم يتم تنفيذ business-data mutation في هذه الجلسة.
تم إجراء read-only verification وfresh snapshot فقط.

### Documentation
هذا التقرير هو:
`doc/Draft/Reprots/MAIN1_FORENSIC_RECHECK_20260911_R5.md`

## 12. ما تم وما لم يتم
### تم
- Governance re-read.
- R4 re-check.
- CURRENT_STATE re-check.
- Main1 source direct re-read + EOF verification.
- Production snapshot جديد.
- اكتشاف وإثبات N1/N2/N3.
- إبقاء N4 وWF مفتوحين بلا تخمين.
- إنشاء Owner Change Set R5 كامل ومحدد.

### لم يتم
- تعديل Main1 بواسطة المساعد.
- Assembly.
- دمج الأجزاء الـ11.
- parser/browser E2E كامل.
- Workflow executor closure.
- إعلان Main1 Functional Gold/Diamond.
- إعلان Global Gold/Diamond.

## 13. OWNER EXACT ACTION — R5
نفّذ فقط التعليمات في:
`doc/Draft/Reprots/OWNER_CHANGESETS_20260911_MAIN1_R5.md`

وتحديدًا:
1. `MAIN1-N1` إضافة `window.togglePasswordVisibility` فوق `const byId...`.
2. `MAIN1-N2` استبدال `showPanel()` كاملة حتى قبل `function markAllRead()`.
3. `MAIN1-N3` استبدال Anchor الخاص بـForgot Password وإضافة handler فوق آخر سطر `window.RW_Navigation = RW_Navigation;`.

لا تعدل:
- `RW_Audit_renderTable()`.
- `RW_Audit_showDetails()`.
- Finance permissions.
- HR permission.
- CRM permission.
- `isAllowed()`.
- Workflow `evaluate()`.

بعد تنفيذ R5 يجب إعادة القراءة من أول حرف إلى EOF ثم اختبار الوظائف المذكورة في R5. لا تعتبر Main1 functional closed قبل ذلك.

## 14. Final Self-Audit
### What was proven
- الهدف الحاكم Gold/Diamond تم تأكيده مرة أخرى ولم يتحول إلى UI-only target.
- Main1 current SHA = `8275750c05c353dec9ed825ca4aff7a4f6d05fab`.
- Fresh Production snapshot = `2026-09-11 09:39:47.550805 UTC`.
- N1 missing password visibility function مثبت.
- N2 notification listeners loss بسبب `outerHTML` مثبت.
- N3 forgot-password control inert مثبت.
- Workflow false-success مثبت.
- Executor contract ما زال غير مثبت.
- Owner R5 changeset مكتوب ومحدد.

### What was not proven
- Full parser/browser PASS.
- Workflow executor contract.
- اكتمال Main2–Main11 وظيفيًا بالكامل.
- Assembly النهائي.
- Browser/PWA E2E.
- Global Gold/Diamond closure.

## 15. FINAL STATUS
`GOVERNANCE = CLOSED FOR THIS SESSION`
`MAIN1 FORENSIC RE-CHECK R5 = CLOSED`
`MAIN1 SOURCE SURGERY = OWNER ACTION REQUIRED`
`MAIN1 FUNCTIONAL = OPEN`
`MAIN1-WF = OPEN — EXECUTOR CONTRACT DISCOVERY`
`GLOBAL FUNCTIONAL COMPLETION = OPEN`
`GLOBAL GOLD/DIAMOND = OPEN`
`ASSEMBLY = DEFERRED`

## 16. ANSWER TO THE REQUIRED FINAL QUESTIONS
### هل تحقق الهدف الأصلي: استكمال ملفات النظام الأم وظيفيًا؟
**لا، ليس بعد.** الأدلة الحالية لا تسمح بإعلان اكتمال النظام الأم وظيفيًا بالكامل.

### هل مازالت هناك أي تبويب أو وظيفة ناقصة أو هيكلية فقط أو `(قيد التطوير)`؟
**نعم.** Main1 لديه N1/N2/N3 التي تحتاج تنفيذ المالك، وWorkflow executor غير مغلق، وMain11 يحمل `(قيد التطوير)` مثبتًا في HR documents، كما أن اكتمال Main2–Main11 end-to-end لم يثبت بعد.

### متى يكتمل؟
لا يوجد تاريخ يمكن إثباته دون تخمين. معيار الإكمال واضح: إغلاق كل owner surgeries، إثبات وإغلاق Workflow executor، استكمال القدرات الوظيفية لكل Main2–Main11، parser/browser PASS، Assembly صحيح من `Current/PWA/main2`, ثم Production E2E verification. حتى ذلك الحين الحالة الصحيحة هي `OPEN` وليست `100% CLOSED`.

## 17. NEXT EXACT RESUMPTION POINT
`MAIN1 OWNER MERGE VERIFICATION` ثم:
`MAIN1-WF — EXECUTOR CONTRACT DISCOVERY`

ولا يوجد أي سبب للعودة إلى `Current/PWA/New-main` أو `Current/PWA/main/*` كمصادر تطويرية.
