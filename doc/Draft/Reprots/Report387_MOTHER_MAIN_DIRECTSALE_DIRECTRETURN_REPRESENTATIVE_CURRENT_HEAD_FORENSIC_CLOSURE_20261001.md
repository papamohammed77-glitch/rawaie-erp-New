# تقرير 387 — الإغلاق الجنائي لعرض مندوب DirectSale / DirectReturn في النظام الأم
## RAWAEA ERP — Current Head Reconciliation — 2026-10-01

## 1. نقطة الاستئناف

تم الاستئناف من آخر نقطة مثبتة في:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS
- CURRENT_STATE.md
- Reports 382 → 386

تم اعتبار التقارير مصادر تاريخية فقط، ثم تم إعادة إثبات الحالة من:
**CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE**

الهدف التنفيذي:
إغلاق عرض عمود **المندوب** في جدول الأذونات المخزنية للـ **DirectSale** و **DirectReturn**، مع عدم إعادة فتح أي عقد تشغيلي أو مخزني أو محاسبي مغلق.

---

## 2. CURRENT GIT — الحقيقة الحالية

المستودع:
`papamohammed77-glitch/erp-frontend`

Branch:
`main`

أحدث Commit مثبت:
`bc4d7a02919dcaf82d11bb599e879281cd550737`

الرسالة:
`forensic: persist current Mother HR extract`

الـParent المباشر:
`80b5dc00da7aae08d442acef4beb6857681de481`

والـCompare بين:
`e2e9d5cdb559bd014dcc85b12fc9b89610b466d7`
→
`80b5dc00da7aae08d442acef4beb6857681de481`

أثبت أن 80b هو Commit واحد فقط فوق e2e9، وملف `main.html` تغيّر فيه بمقدار:
- additions = 1
- deletions = 1

أما Compare:
`80b5dc00da7aae08d442acef4beb6857681de481`
→
`bc4d7a02919dcaf82d11bb599e879281cd550737`

فأثبت أن bc4 غيّر فقط:
`_forensic_current_main_extract.md`

ولم يغيّر `main.html`.

### Current main.html

المسار:
`companies/company-1/main.html`

Current blob:
`6cb0ac47e8b3c8459ac5672d6fc3b0ec4bf9eaa3`

الحجم الحالي:
`1,755,711` حرفًا

عدد الأسطر:
`32,348`

---

## 3. مراجعة Report386 مقابل Current Source

Report386 سجّل عيبًا حقيقيًا في ذلك الوقت:
كان السطر 5 يحتوي على:

`<meta charset="UTF-8">return '<tr ... _custodian_name ... </tr>';`

لكن هذا العيب **لم يعد موجودًا** في Current Source.

Commit:
`80b5dc00da7aae08d442acef4beb6857681de481`

أصلح العيب تحديدًا، واستعاد:
`    <meta charset="UTF-8">`

إذن:
**لا توجد حاليًا جراحة Owner مطلوبة لإصلاح line 5.**

إعادة تطبيق Report386 على Current HEAD ستكون Regression/No-op غير مقبول.

---

## 4. Current Source — اختبار جنائي كامل للملف

تم جلب الـblob الفعلي للملف الحالي مباشرة من GitHub.

تم فحص:
- عدد الدوال المستهدفة.
- رأس الجدول.
- lookup للمندوب.
- إسقاط `custodian_user_id`.
- rendering.
- سلامة `meta charset`.
- inline JavaScript compilation.

### النتائج

`loadVouchers()`
= 1 occurrence

`_applyVouchers()`
= 1 occurrence

Header:
`<th class="p-3">المندوب</th>`
= موجود

`colspan="9"`
= موجود

Representative lookup:
`.in('id', custodianIds)`
= موجود

Projection:
`v._custodian_name = isDirectVehicleVoucher && v.custodian_user_id ...`
= موجود

Escaped render:
`esc(v._custodian_name||'-')`
= موجود

Corrupted meta pattern:
`<meta charset="UTF-8">return '<tr...`
= غير موجود

### Static Syntax Gate

عدد inline scripts:
`1`

V8 `new Function(...)` compilation:
**PASS**

---

## 5. موضع Business Capability المطلوب

### loadVouchers()

الموضع الحالي:
حوالي الأسطر `14859 → 14914`

الجدول يحتوي فعليًا:

`رقم الإذن | النوع | التاريخ | الحالة | المرجع | من | إلى | المندوب | إجراءات`

### Representative lookup

المنطق الحالي:

`stock_vouchers.custodian_user_id`
→
`public.users.id`
→
`public.users.name / email`

والـlookup مقيّد بـ:
`company_id`

### Projection

يتم بناء:
`v._custodian_name`

فقط لـ:
- DirectSale
- DirectReturn

وأي نوع آخر يحصل على:
`-`

### Row renderer

الموضع الحالي:
حوالي السطر `14942`

يضيف اسم المندوب قبل عمود الإجراءات، مع escaping.

---

## 6. هل يوجد عنصر معيب حاليًا يجب حذفه؟

**لا.**

وهذا هو القرار الجنائي الصحيح وفق Current Source.

العنصر الذي كان معيبًا تاريخيًا هو **السطر 5** الذي أفسده commit `e373c7ad2d66d72b2919a8f153693da36ab9b77`.

وقد تم إصلاحه بالفعل في commit `80b5dc00da7aae08d442acef4beb6857681de481`.

### العنصر التاريخي المعيب — للاحتياط فقط

ابحث في النسخة المحلية/المنشورة القديمة فقط عن هذا السطر الكامل:

```html
  <meta charset="UTF-8">return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3">' + (v._custodian_name||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
```

احذفه بالكامل فقط إذا كان موجودًا في نسختك المحلية/المنشورة.

البديل الكامل:

```html
  <meta charset="UTF-8">
```

**لا تنفذ هذا الاستبدال على Current Git الحالي لأنه منفذ بالفعل.**

---

## 7. Production — الحالة الحالية

Supabase:
`SMART ERP`

Project Ref:
`fiilmooggumokxanwiyx`

الحالة التشغيلية المرتبطة بهذه النقطة:
- total `stock_vouchers` = 0
- DirectSale = 0
- DirectReturn = 0
- active direct-sales representatives = 3
- `stock_voucher_details` = 0

العقد البنيوي:
`stock_vouchers.custodian_user_id`
هو UUID مرتبط بـ:
`public.users.id`

والـtrigger الإنتاجي:
`enforce_stock_voucher_custodian`
يثبت أن DirectSale/DirectReturn يحتفظان بهوية المندوب كـcustodian، مع:
- نفس الشركة.
- مستخدم Active.
- role = `مندوب بيع مباشر`.
- permission = `van-sales`.

---

## 8. Production Workflow — لم يتم تغييره

المسار الحالي المثبت:

### DirectSale
`Branch`
→
`Vehicle mobile branch`

ويُسجل:
`custodian_user_id`
ويولد أثر عهدة المندوب عند الإرسال.

### DirectReturn
`Vehicle mobile branch`
→
`Branch`

مرحلة SEND تستخدم:
`InventoryDecrease`

مرحلة RECEIVE تستخدم:
`InventoryIncrease`

وهذا العقد محمي من إعادة الفتح.

---

## 9. Production E2E حديث — تنفيذ واختبار

تم تنفيذ اختبار transactional في Production باستخدام:
- فرع BR-01
- مركبة CHV-2025-01
- الصنف 1001
- مندوب مبيعات بيع مباشر
- منفذ تشغيل مخزني `vouchers@rawaea.com`

كل الاختبار نفذ داخل:
`BEGIN ... ROLLBACK`

### CREATE

DirectSale:
- Draft
- custodian صحيح
- representative projection صحيح

DirectReturn:
- Draft
- custodian صحيح
- representative projection صحيح

**PASS**

### SEND DirectSale

- status = Sent
- movement_count = 1
- custody_value = 50
- custody_ledger = true

المخزون:
- الفرع 8 → 7
- السيارة 0 → 1

**PASS**

### SEND DirectReturn

- status = Sent
- movement_count = 1

المخزون:
- الفرع = 7
- السيارة 1 → 0

**PASS**

### RECEIVE DirectReturn

- status = Received
- custody_credit = 50
- custody_ledger = true
- نفس custodian

المخزون:
- الفرع 7 → 8
- السيارة = 0

**PASS**

### Duplicate RECEIVE

تمت إعادة نفس العملية بنفس:
`operation_id = QA-REP-DR-RECV-20261001-C`

النتيجة:
`duplicate = true`

ولم تُضف حركة ثانية.

**PASS**

---

## 10. التأثير على العهدة والحسابات

أثناء الاختبار:
- driver_ledger rows = 2
- debit = 50
- credit = 50
- net = 0

وهذا يثبت أن:
DirectSale custody debit
تمت موازنته مع:
DirectReturn custody credit

دورة الاختبار لم تغيّر:
`journal_entries`
ولا:
`journal_lines`

snapshot:
- journal_entries = 10
- journal_lines = 16

وهو متوافق مع أن الحركة الداخلية/العهدية ليست إيرادًا محاسبيًا عامًا بحد ذاتها في هذا العقد.

---

## 11. تنظيف Production بعد الاختبار

بعد ROLLBACK تم التحقق مباشرة:

- total stock_vouchers = 0
- DirectSale = 0
- DirectReturn = 0
- QA operation rows = 0
- QA direct-return inventory-log rows = 0
- main branch item 1001 qty = 8
- mobile vehicle item 1001 qty = 0
- QA driver-ledger net = 0

**لا توجد بقايا بيانات اختبار.**

---

## 12. فشل الاختبار الأول وكيف تم حسمه

المحاولة الأولى استخدمت:
`owner@alrawae.com`
كمنفذ لإنشاء DirectSale.

الـcore الحالي رفض العملية لأن عقد الإنشاء يتطلب:
- مندوب بيع مباشر، أو
- مخزني بصلاحية `أذونات`

هذا كان **خطأ في اختيار Actor للاختبار** وليس عيبًا في الكود.

تم تصحيح Actor إلى:
`vouchers@rawaea.com`

وأُعيد الاختبار كاملًا ونجح.

لا يوجد أثر Production من المحاولة الأولى.

---

## 13. لماذا لا توجد Production Change لهذه المهمة

الخلل المطلوب في هذه الدورة هو Read-Model/UI parity.

Current Production already contains:
- custodian contract
- representative validation
- DirectSale workflow
- DirectReturn workflow
- custody ledger
- central stock movement

لذلك:
- Edge Function جديدة = لا
- RPC جديد = لا
- RPC تعديل = لا
- Schema change = لا
- RLS change = لا
- stock repair = لا
- accounting repair = لا

أي تعديل Backend هنا سيكون خارج السبب الجذري.

---

## 14. التكامل مع التطبيق التشغيلي

التطبيق التشغيلي:
`companies/company-1/warehouse/vouchers.html`

يحمل بدوره عقد custodian/representative.

إذن Mother `main.html` في هذه النقطة هو:
**Read Projection / Control-Plane surface**

وليس بديلًا عن executor workflow.

هذه الجراحة لا تغيّر:
- delegated application
- RPC execution
- stock movement
- custody
- accounting

---

## 15. الحقول ذات القيمة المستقبلية

لا توجد حاجة لإضافتها الآن.

حقول يمكن أن ترفع القيمة الرقابية لاحقًا في تقرير مركزي:
- المندوب
- السيارة
- الفرع المصدر
- فرع الاستلام
- منشئ الإذن
- مرسل الإذن
- مستلم الإذن
- وقت الإنشاء
- وقت الإرسال
- وقت الاستلام
- operation_id
- قيمة العهدة
- سبب المرتجع
- حالة الاستثناء/العكس

لكن هذه **ليست جزءًا من الإصلاح الحالي**.

---

## 16. مقارنة وظيفية مع الأنظمة المنافسة

الهدف من عمود المندوب ليس تجميليًا.

قيمته الوظيفية هي ربط:
`Document`
→
`Custodian`
→
`Vehicle`
→
`Stock Movement`
→
`Audit / Liability`

وهو يتفق مع الاتجاه العام في أنظمة ERP الناضجة إلى تتبع فاعل العملية وسياق الموقع والحركة، مع بقاء RAWAEA محافظًا على سلسلة العمليات الميدانية الخاصة به بدل تحويلها إلى شاشة CRUD بسيطة.

لا توجد حاجة لإضافة ميزات تسويقية غير مرتبطة بالنقطة الحالية لكي نعلن إغلاقها.

---

## 17. SELF AUDIT

### WHAT I PROVED
- Current Git HEAD = `bc4d7a02919dcaf82d11bb599e879281cd550737`
- Parent = `80b5dc00da7aae08d442acef4beb6857681de481`
- Current main blob = `6cb0ac47e8b3c8459ac5672d6fc3b0ec4bf9eaa3`
- Current header is valid.
- Representative column is present.
- DirectSale/DirectReturn custodian projection is present.
- Current inline JS compiles.
- Production custodian contract is valid.
- Production E2E stock/custody/duplicate behavior passed.
- Production rollback left zero QA residue.

### WHAT I FIXED
لا يوجد إصلاح جديد في هذه الدورة.

العيب التاريخي الذي كان يمنع القراءة والوصول إلى الملف تم إصلاحه بالفعل بواسطة:
`80b5dc00da7aae08d442acef4beb6857681de481`

### WHAT I DEPLOYED
لا شيء جديد.

### WHAT I VERIFIED
- Current source
- Current Git chain
- Current Production schema
- Current Production RPC contract
- transactional E2E
- rollback cleanup
- static syntax
- representative projection

### WHAT FAILED
Actor الاختبار الأول فقط.

### HOW IT WAS RESOLVED
تغيير test actor إلى الحساب التشغيلي المخول، ثم إعادة الاختبار كاملًا بنجاح.

### WHAT REMAINS
Browser-rendered E2E بعد النشر الفعلي.

Served artifact identity غير مثبت من runtime في هذه الجلسة.

### WHAT COULD STILL BE WRONG
إذا كانت النسخة التي يراها المستخدم مختلفة عن Current Git، فالمشكلة قد تكون deployment/cache drift، لا source defect.

---

## 18. مستوى الإغلاق

### Business capability
**CLOSED IN CURRENT SOURCE**

### Source
**PASS**

### Database contract
**PASS**

### Production transactional E2E
**PASS**

### Data cleanup
**PASS**

### Accounting invariance
**PASS**

### Owner surgery
**NONE REQUIRED ON CURRENT HEAD**

### Browser rendered production
**OPEN**

### Served artifact identity
**OPEN**

لا يتم إعلان الإغلاق النهائي المرئي للمستخدم قبل إثبات الـserved artifact وBrowser runtime.

---

## 19. NEXT EXACT RESUMPTION POINT

ابدأ من هذه الحقيقة فقط:

`erp-frontend/main` HEAD = `bc4d7a02919dcaf82d11bb599e879281cd550737`

ولا تعيد:
- Report384 PATCH 1→4
- Report385 PATCH 1→4
- Report386 line-5 repair

إلا إذا أثبت الفحص أن النسخة المحلية/المنشورة أقدم من Current Git.

الخطوة التالية الوحيدة:

1. إثبات أن النسخة المنشورة تحمل Current main blob/المحتوى المقابل.
2. تنفيذ Browser E2E على جدول الأذونات.
3. اختيار DirectSale والتحقق من اسم المندوب.
4. اختيار DirectReturn والتحقق من اسم المندوب.
5. التحقق من Transfer/SupplierReturn = `-`.
6. التحقق من refresh وعدم سقوط lookup.
7. إغلاق الوحدة نهائيًا فقط بعد Runtime evidence.

---

## 20. تعليمات الحقيقة للمساعد التالي

لا تبدأ من التقارير.

ابدأ:
`CURRENT GIT`
↓
`CURRENT SOURCE`
↓
`CURRENT PRODUCTION`
↓
`CURRENT DATABASE`
↓
`CURRENT DEPLOYMENT EVIDENCE`

ثم استخدم Reports فقط لتفسير التاريخ.

في هذه القضية تحديدًا:
**الـCurrent Source سليم ولا توجد Owner Change مطلوبة الآن.**

إذا ظهرت نسخة منشورة مختلفة، عالج Deployment Drift أولًا، ولا تعيد كتابة `main.html` بلا دليل.

# END OF REPORT 387
