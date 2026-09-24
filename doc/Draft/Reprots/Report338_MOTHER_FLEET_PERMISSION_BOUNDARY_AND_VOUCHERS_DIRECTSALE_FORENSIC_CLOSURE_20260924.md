# تقرير 338 — الإغلاق الجنائي لحدود النظام الأم وتطبيق الأذونات المخزنية
## التاريخ
2026-09-24

## حالة التقرير
**تنفيذ فعلي + تحقق Production + تحقق مصدر Git + إصلاح تطبيقي منفصل + تعليمات جراحية Owner-only لـ main.html**

---

# 1. قاعدة الحقيقة التي بُني عليها هذا التقرير

تم تجاهل التقارير السابقة كحالة حالية، واستخدامها كأدلة تاريخية فقط.

الحالة الحالية المعتمدة في هذه الجلسة بُنيت من:

- CURRENT GIT
- CURRENT SOURCE
- CURRENT PRODUCTION
- CURRENT DATABASE
- CURRENT DEPLOYMENT / runtime evidence

المبدأ الحاكم المستعاد من:
`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

هو:

`UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH/CONTROL FLOW → COMPARE TARGET → IDENTIFY ACTUAL GAP → SURGICAL FIX → VERIFY`

ولا يجوز تحويل نجاح التقرير التاريخي إلى حقيقة Production جديدة دون إعادة المطابقة.

---

# 2. آخر Git قبل هذه الجلسة

## Mother repository

Repository:

`papamohammed77-glitch/erp-frontend`

آخر commit حالي:

`9257912dddb3b432a7d6979f41c68e25570ce3f5`

الرسالة:

`forensic: persist current Mother HR extract`

والـcommit السابق مباشرة:

`f32f970ad395ad163f770d3cdf56f9015198e3a6`

الرسالة:

`Update main.html`

والـparent لـ`f32f970` هو:

`7ca0aa1324fe1d925a752f559e990e92e29a384b`

## النتيجة الجنائية المهمة

ثبت أن PATCH-337 الذي كان Report337 يطلب من الـOwner تنفيذه **تم تطبيقه بالفعل على Mother main.html** في commit:

`f32f970ad395ad163f770d3cdf56f9015198e3a6`

والـmain.html الحالي في هذا المسار أصبح:

`617e6d9ac123e1112dc37bea0097b59b0d0509cb`

إذن:

**ممنوع إعادة تطبيق PATCH-337.**

---

# 3. Production الحالية

Supabase project:

`fiilmooggumokxanwiyx`

الـControl Plane الحالي:

- `fleet_query`
- `fleet_command_atomic`

الأمر:

`VEHICLE_OPERATION_BIND`

## Production facts

- الشركات: 1
- الفروع: 4
- المركبات: 2
- الرانشيتات: 0
- الأذونات المخزنية: 2
- inventory_log: 25
- journal_entries: 10
- journal_lines: 16

## التوزيع الحالي للمستخدمين

### Mother / إدارة عليا

- owner@alrawae.com — مدير النظام — *
- general.manager@rawaea.com — مدير عام
- warehouse.manager@rawaea.com — مدير مخازن
- finance-manager@rawaea.com — مدير مالي
- driver.supervisor@rawaea.com — مشرف توصيل

### التنفيذ الميداني المنفصل

- warehouse.supervisor@rawaea.com — مشرف مخازن
- vouchers@rawaea.com — مخزني / أذونات
- picker@rawaea.com — مخزني / تحضير
- loader@rawaea.com — مخزني / تحميل
- receiver@rawaea.com — مخزني / استلام
- returns@rawaea.com — مخزني / مرتجعات
- vansales@rawaea.com — مندوب بيع مباشر
- van-sales2@rawaea.com — مندوب بيع مباشر
- driver@rawaea.com وأقرانه — مندوبي توصيل

---

# 4. النتيجة الجنائية الرئيسية

## ما تم إصلاحه سابقًا

Report337 أصلح مشكلة Production صحيحة: capability الخاصة بـ `VEHICLE_OPERATION_BIND` يجب أن تكون متاحة للمستهلك التشغيلي الذي يحتاجها، دون فتح كل أوامر Fleet.

هذا الإصلاح في Production Control Plane **صحيح ولم يتم التراجع عنه**.

## الخلل الذي ظهر بعد تطبيق PATCH-337 على Mother

PATCH-337 وسّع في main.html:

- Fleet navigation
- canRead()
- canBindVehicleOperation()

ليسمح لصلاحيات تنفيذية مثل:

- warehouse
- warehouse_supervisor
- vouchers
- transfer
- direct-sale
- van-sales
- delivery
- vehicle-count

بالدخول إلى Mother Fleet Management.

هذا يتعارض مع العقد الذي تم تأكيده في هذه الجلسة:

**الموظفون التنفيذيون لا يدخلون النظام الأم ولا ينفذون عملياتهم داخله.**

التطبيقات المنفصلة هي واجهات التشغيل الميداني.

إذن:

**Production capability = صحيحة**

ولكن:

**Mother UI authorization = غير متوافق مع العقد الحالي**

---

# 5. القرار المعماري الصحيح

لا نعكس تعديل Production.

لا نغلق `VEHICLE_OPERATION_BIND` في Production.

لا ننشئ Edge Function جديدة.

الفصل الصحيح:

```text
Operational Apps
      ↓
Canonical Production RPC
      ↓
Authoritative Data
      ↓
Mother Read / Control
```

والـMother لا يصبح بوابة تنفيذ بديلة للتطبيقات التشغيلية.

---

# 6. Mother main.html — الحالة الفعلية

الـmain.html الحالي 32335 سطرًا.

ثبت أنه يحتوي PATCH-337 فعليًا.

## العناصر الصحيحة التي تبقى

- command() special-case الخاص بـ VEHICLE_OPERATION_BIND
- فصل زر الربط عن أزرار master data
- openVehicleOperationLinkForm() يستخدم capability منفصلة
- vehicle_operation_candidates
- voucher_id
- direct_sales_rep_id
- operation_id
- direct_sales reporting
- عدم إنشاء سجل حركة موازي

لا يعاد بناؤها.

---

# 7. التعديل الجراحي المطلوب من الـOwner في main.html

**Mother main.html لم يتم تعديله في هذه الجلسة.**

## PATCH-338-01 — Fleet navigation

ابحث بالتحديد عن السطر الحالي داخل قائمة:

`إدارة الأسطول والحركة`

وعن عنصر:

`لوحة إدارة الأسطول`

النص الحالي:

```js
{ view: 'fleet-management', label: 'لوحة إدارة الأسطول', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager','warehouse','warehouse_supervisor','warehouse_manager','vouchers','transfer','direct-sale','van-sales','delivery','vehicle-count'] },
```

احذفه واستبدله فقط بـ:

```js
{ view: 'fleet-management', label: 'لوحة إدارة الأسطول', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager'] },
```

---

## PATCH-338-02 — canBindVehicleOperation()

ابحث بالتحديد عن:

`function canBindVehicleOperation()`

وحدد الدالة الحالية كاملة.

احذف هذه الدالة فقط واستبدلها بـ:

```js
function canBindVehicleOperation() {
  var u = currentUser();
  if (!u) return false;
  if (u.isOwner === true) return true;
  var p = Array.isArray(RW_STATE.permissions) ? RW_STATE.permissions : [];
  return p.indexOf('*') !== -1 ||
    p.indexOf('fleet.manage') !== -1 ||
    p.indexOf('general_manager') !== -1 ||
    p.indexOf('warehouse_manager') !== -1 ||
    p.indexOf('delivery_supervisor') !== -1 ||
    p.indexOf('finance_manager') !== -1 ||
    u.role === 'مدير عام' ||
    u.role === 'مدير مخازن' ||
    u.role === 'مشرف توصيل' ||
    u.role === 'مدير مالي';
}
```

---

## PATCH-338-03 — canRead()

ابحث داخل:

`function canRead()`

عن كتلة `return` الحالية التي تحتوي على الصلاحيات التشغيلية.

احذف كتلة `return` الحالية فقط واستبدلها بـ:

```js
return p.indexOf('*') !== -1 ||
  p.indexOf('fleet.manage') !== -1 ||
  p.indexOf('fleet.read') !== -1 ||
  p.indexOf('reports') !== -1 ||
  p.indexOf('general_manager') !== -1 ||
  p.indexOf('warehouse_manager') !== -1 ||
  p.indexOf('delivery_supervisor') !== -1 ||
  p.indexOf('finance_manager') !== -1 ||
  u.role === 'مدير عام' ||
  u.role === 'مدير مخازن' ||
  u.role === 'مشرف توصيل' ||
  u.role === 'مدير مالي';
```

**لا تحذف canRead().**

---

# 8. ما لا يعدل في main.html

لا تعدل:

- command()
- VEHICLE_OPERATION_BIND special case
- فصل زر الربط عن master-data buttons
- openVehicleOperationLinkForm()
- vehicle_operation_candidates
- direct_sales reporting
- voucher_id
- direct_sales_rep_id
- operation_id

هذه أجزاء ثبتت صحتها.

---

# 9. التحقيق في vouchers.html

المصدر:

`Current/PWA/vouchers.html`

النسخة الحالية كانت تحتوي على ثلاثة تعارضات:

1. اختيار مركبة DirectSale كان مقيدًا بـ `vehicle.driver_id === direct_sales_rep`.
2. submit() كان يرفض DirectSale إذا اختلف سائق المركبة عن مندوب البيع.
3. الواجهة كانت تحصل على rep لكنها لا ترسله إلى create endpoint.

هذا يتعارض مباشرة مع العقد المثبت سابقًا:

`Vehicle ≠ Driver ≠ Direct Sales Rep ≠ Custodian`

---

# 10. الإصلاح الفعلي المنفذ في vouchers.html

تم تعديل المصدر في Git.

Commit:

`cb6f0b500ea4dbae43e87214ac59da2c278b0597`

التغييرات الجراحية:

- المركبة في DirectSale أصبحت مستقلة عن driver_id.
- إزالة مقارنة driver/rep من validation.
- إرسال rep_id إلى existing create endpoint.
- إنشاء operation_id محلي لكل محاولة إنشاء.
- الاحتفاظ بنفس operation_id عند فشل الاستجابة لإعادة المحاولة.
- تصفير operation identity بعد النجاح.

لا يوجد Edge Function جديد.

---

# 11. Production E2E — Mother Fleet Binding

تم تنفيذ اختبار transaction حقيقي داخل Production.

Actor:

`finance-manager@rawaea.com`

Vehicle:

`CHV-2025-01`

Item:

`1001 — جو كيك 5ج`

النتيجة:

`VEHICLE_OPERATION_BIND = success`

Replay بنفس operation_id:

`duplicate = true`

الأثر:

- stock qty delta = 0
- allocated_qty delta = 0
- inventory_log delta = 0
- journal_entries delta = 0
- journal_lines delta = 0

إذن:

**BIND relationship operation وليست stock/accounting movement.**

---

# 12. Production E2E — vouchers DirectSale

Actor:

`vouchers@rawaea.com`

Direct Sales Rep:

`van-sales2`

Vehicle:

`CHV-2025-01`

Item:

`1001`

تم تنفيذ:

`CREATE → SEND → REPLAY`

## CREATE

`success=true`

`rep_id` تم حفظه.

## SEND

`success=true`

`status=Sent`

`movement_count=1`

`custodian_user_id` تم حفظه.

## Stock

فرع BR-01:

`-1`

مخزن المركبة:

`+1`

## Inventory Log

`+1`

## Accounting

`journal_entries = 0`

`journal_lines = 0`

## Replay

`duplicate=true`

ثم تم rollback كامل للاختبار.

---

# 13. QA residue

بعد الاختبارات:

- QA vouchers = 0
- QA stock-voucher operations = 0
- QA inventory_log = 0

يوجد سجل audit تاريخي واحد من 2026-08-16 متعلق بـ QA قديم:

`QA-RCV-HTTP-20260816-040337422`

وهو ليس ناتج هذه الجلسة، لذلك لم يتم حذفه.

---

# 14. Purchase Receiving

لا يوجد في هذا closure سبب لإعادة تعديل Purchase Receiving.

العقد الحالي:

`receive_purchase_atomic`

يحدد فرع الاستلام من:

`COALESCE(po.branch_id, main_branch)`

ثم يستخدم:

`post_stock_movement`

للوصول إلى رصيد الفرع.

لا تعاد معالجة هذا الجزء في الجلسة التالية ما لم يظهر Production evidence جديد.

---

# 15. التأثير المحاسبي

## Vehicle Operation Bind

لا ينشئ:

- Revenue
- COGS
- Inventory Journal
- Cash
- Receivable

## DirectSale SEND

المثبت حاليًا:

- Physical stock movement = نعم
- inventory_log = نعم
- custody/driver ledger = نعم
- journal_entries = 0
- journal_lines = 0

ولا يوجد ما يبرر تغييره داخل هذا closure.

---

# 16. التكامل المعتمد

التدفق النهائي:

```text
vouchers.html
      ↓
DirectSale voucher
      ↓
vehicle = to_id
sales rep = custodian_user_id
      ↓
fleet_command_atomic
      ↓
VEHICLE_OPERATION_BIND
      ↓
Fleet reporting
```

والـMother:

```text
Mother
  ↓
Read / Control / Audit
  ↓
Authoritative Production Data
```

وليست واجهة تشغيل بديلة للمخزني أو مندوب البيع أو مندوب التوصيل.

---

# 17. المقارنة الوظيفية مع الأنظمة المنافسة

## Odoo

Odoo 19 Fleet Services يدعم تسجيل الخدمات والصيانة وربط السائق بالمركبة وقراءة العداد.

المصدر الرسمي:
https://www.odoo.com/documentation/19.0/applications/hr/fleet/service.html

## Dynamics 365

Transportation Management يدعم النقل الوارد والصادر وبناء الأحمال وإدارة النقل الخاص بالشركة والحلول الخارجية.

المصدر الرسمي:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/transportation-management-overview

## SAP

SAP Transportation Management يمثل المركبة كمورد للنقل مع capacity وavailability وخصائص تشغيلية متعددة.

المصدر الرسمي:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/bad5555bf8d042069b1ed7927e6e59e7.html

## Daftra

Daftra يتيح ملف الرحلة والإيرادات والمصروفات وتكاليف الصيانة والنتيجة المالية للرحلة.

المصدر:
https://www.daftra.com/en/transportation/

## backlog تنافسي مستقبلي

لا يعاد فتحه ضمن هذا closure:

- trip cost
- cost/km
- fuel economics
- maintenance allocation
- capacity utilization
- planned vs actual
- vehicle availability
- asset lifecycle / depreciation
- route profitability
- vehicle-operation-document 360

---

# 18. Self Audit

## What I Proved

- current Mother HEAD/source
- PATCH-337 was actually applied
- current Mother main blob
- current Production fleet control plane
- current Production authorization
- current user role distribution
- BIND has no stock/GL movement
- BIND replay is idempotent
- vouchers CREATE persists rep identity
- DirectSale SEND changes source and vehicle stock correctly
- DirectSale SEND creates custody ledger effect
- DirectSale SEND creates no journal entry/line
- current vouchers source no longer contains vehicle-driver equality for DirectSale
- current vouchers source sends rep_id
- current vouchers source sends operation_id
- no QA residue from this session

## What I Did Not Prove

- authenticated Browser E2E against the published Mother artifact
- Cloudflare published artifact after latest Mother commit
- visual regression after Owner applies PATCH-338

## Remaining status

Browser:

**OPEN / UNVERIFIED**

لا يجوز تحويل DB/RPC/source PASS إلى Browser PASS.

---

# 19. Continuity instruction للمساعد التالي

ابدأ من:

`CURRENT_STATE.md`

ثم:

`CURRENT System HEAD + parent`

ثم:

`CURRENT Mother HEAD + parent`

ثم:

`CURRENT main.html blob`

ثم:

`CURRENT vouchers.html blob`

ثم:

`CURRENT Production fleet_query`

ثم:

`CURRENT Production fleet_command_atomic`

ثم:

`CURRENT Edge deployments`

ثم:

`Published/browser evidence`

ولا تبدأ من Report338 كحالة حالية.

إذا كان PATCH-338 مطبقًا بالفعل:

- لا تعيده.
- افحص المصدر الحالي.
- اختبر Mother access.
- اختبر Fleet candidate read.
- اختبر BIND.
- اختبر أنه لا يغيّر stock أو GL.

إذا لم يكن مطبقًا:

نفذ فقط:

`PATCH-338-01`
`PATCH-338-02`
`PATCH-338-03`

ثم افحص النتيجة.

ولا تعيد:

- PATCH-334
- PATCH-336
- PATCH-337

ولا تنشئ Edge Function جديدة.

---

# 20. الحالة النهائية

```text
PRODUCTION VEHICLE_OPERATION_BIND
= CLOSED

DirectSale identity separation
= CLOSED

vouchers.html DirectSale source fix
= CLOSED

Mother main.html
= OWNER PATCH-338 REQUIRED

Browser E2E
= OPEN / UNVERIFIED
```

**End of Report338**
