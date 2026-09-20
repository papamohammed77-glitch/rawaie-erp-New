# RAWAEA ERP — Delivery & Logistics Management
## Surgical Mother Main Patch — 2026-09-20

> هذا الملف لا يعدّل \`companies/company-1/main.html\` بنفسه.
> التنفيذ على ملف النظام الأم يتم يدويًا من المالك فقط.
> لا يوجد عنصر Delivery & Logistics قديم يتم حذفه؛ التعديل ADD-ONLY فوق البنية الحالية.

## 1) إدراج عنصر القائمة

افتح أحدث \`companies/company-1/main.html\` من:

- Mother HEAD: \`46549e9237f3b946d6bcc18cdab78b9ead57f0c5\`
- main.html blob: \`e428fac9213de08a67a6e40e4c88a9d3c8920232\`

ابحث حرفيًا عن:

~~~js
{ icon: 'fa-truck-moving', label: 'إدارة الأسطول والحركة', submenu: [
    { view: 'fleet-management', label: 'لوحة إدارة الأسطول', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager'] }
] },
~~~

ولا تحذف هذا العنصر.

أضف السطر التالي داخل نفس \`submenu\` بعد عنصر \`fleet-management\` وقبل \`]\`:

~~~js
{ view: 'delivery-logistics-management', label: 'مركز التوصيل واللوجستيات', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager'] }
~~~

ليصبح الجزء:

~~~js
{ icon: 'fa-truck-moving', label: 'إدارة الأسطول والحركة', submenu: [
    { view: 'fleet-management', label: 'لوحة إدارة الأسطول', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager'] },
    { view: 'delivery-logistics-management', label: 'مركز التوصيل واللوجستيات', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager'] }
] },
~~~

## 2) إضافة أيقونة التبويب

ابحث حرفيًا عن:

~~~js
'fleet-management': 'fa-truck-moving',
~~~

أضف بعده:

~~~js
'delivery-logistics-management': 'fa-route',
~~~

## 3) إضافة عنوان التبويب

ابحث حرفيًا عن:

~~~js
'fleet-management':'إدارة الأسطول والحركة',
~~~

أضف بعده:

~~~js
'delivery-logistics-management':'إدارة التوصيل والشحن',
~~~

## 4) إضافة حارس الوصول

داخل \`RW_Views.render(view)\` ابحث عن بداية الحارس الموجود:

~~~js
if (view === 'fleet-management') {
~~~

وابحث عن نهايته مباشرة قبل:

~~~js
var permKey = permissionMap[view];
~~~

أضف قبل \`var permKey\` مباشرة:

~~~js
if (view === 'delivery-logistics-management') {
    var deliveryUser = (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app)
        ? RW_STATE.app.currentUser
        : null;
    var deliveryPerms = (typeof RW_STATE !== 'undefined' && Array.isArray(RW_STATE.permissions))
        ? RW_STATE.permissions
        : [];
    var deliveryAllowed = !!(deliveryUser && (
        deliveryUser.isOwner === true ||
        deliveryPerms.indexOf('*') !== -1 ||
        deliveryPerms.indexOf('fleet.read') !== -1 ||
        deliveryPerms.indexOf('fleet.manage') !== -1 ||
        deliveryPerms.indexOf('general_manager') !== -1 ||
        deliveryPerms.indexOf('warehouse_manager') !== -1 ||
        deliveryPerms.indexOf('delivery_supervisor') !== -1 ||
        deliveryPerms.indexOf('finance_manager') !== -1 ||
        deliveryUser.role === 'مدير عام' ||
        deliveryUser.role === 'مدير مخازن' ||
        deliveryUser.role === 'مشرف توصيل' ||
        deliveryUser.role === 'مدير مالي'
    ));
    if (!deliveryAllowed) {
        safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px">🔒</div><h2>غير مصرح</h2><p>ليس لديك صلاحية الوصول إلى مركز التوصيل واللوجستيات</p></div>');
        return;
    }
}
~~~

## 5) ربط الـRouter

ابحث حرفيًا عن:

~~~js
if (view === 'fleet-management') { RW_FleetManagement.render(); return; }
~~~

أضف بعده مباشرة:

~~~js
if (view === 'delivery-logistics-management') { RW_DeliveryLogistics.render(); return; }
~~~

## 6) إدراج الوحدة المركزية

افتح الملف:

\`Current/PWA/owner-patches/RW_DeliveryLogistics.js\`

SHA الحالي:

\`aae4d353ff703904390064a8e93b7c9568e5b94e\`

انسخ محتوى الملف كاملًا دون حذف أو دمج يدوي.

ثم في أحدث \`main.html\` ابحث حرفيًا عن:

~~~js
// ============================================================
// RW_Views – نظام التوجيه النهائي
// ============================================================
var RW_Views = {
~~~

أدخل محتوى \`RW_DeliveryLogistics.js\` كاملًا مباشرة قبل هذا الـmarker.

لا تحذف \`RW_FleetManagement\`.
لا تحذف \`RW_Views\`.
لا تعدّل \`driver.html\`.
لا تعدّل \`supervisor.html\`.

## 7) ما لا يحتاج تعديلًا

لا تضف Permission جديدة.
لا تعدّل \`permLabels\`.
لا تعدّل \`permissionMap\` إلا إذا كان الـMother الحالي قد أضاف قاعدة صريحة جديدة تجعل الـview غير معروف؛ الـview لديه Access Guard مستقل.
لا تعدّل Fleet module الحالي.
لا تعدّل route/stock/order engines الموجودة.

## 8) سبب اختيار هذا الشكل

هذه الجراحة تضيف Control Plane مركزيًا فوق:
Order → Runsheet → Fleet Capacity/Vehicle → Delivery Route → Delivery Agent → Stop → POD → Collection → Performance

ولا تنشئ دورة مستقلة بديلة، ولا تكتب Physical Stock، ولا تعيد بناء دورة الرانشيت.

## 9) Gate بعد التطبيق

بعد إدخال التعديل:

1. افتح النظام الأم.
2. ادخل بالحساب المخوّل.
3. افتح «إدارة التوصيل والشحن».
4. تحقق من ظهور التبويبات الستة.
5. نفّذ Browser E2E على Runsheet حقيقية/اختبارية مع بيانات GPS.
6. تأكد أن Fleet Assignment ما زال يعمل.
7. تأكد أن تطبيق مندوب التوصيل ما زال يغلق الطلب عبر \`complete-order-delivery\`.
8. تأكد أن المخزون لا يتغير من Delivery Center.

لا تعتبر Browser Gate مغلقة قبل تسجيل النتيجة في \`CURRENT_STATE.md\`.
