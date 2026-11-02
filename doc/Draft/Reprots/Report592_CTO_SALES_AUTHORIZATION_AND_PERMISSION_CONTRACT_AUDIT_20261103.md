# RAWAEA ERP — مراجعة تفويض المبيعات وعقود الصلاحيات بين Edge وRPC والواجهة

**Checkpoint:** LVE-2026-11-03-592  
**التاريخ:** 2026-11-03  
**الحالة:** SALES AUTHORIZATION & PERMISSION-SOURCE INCONSISTENCIES / READ-ONLY / NOT CLOSED  
**نقطة البداية:** LVE-591.

---

## 1. النطاق

تم تتبع مسارات تأكيد الطلبات وإنشاء/إلحاق Runsheet وإدارة الطلبات والعملاء وعروض الأسعار والمرتجعات وأهداف المبيعات، مع ربطها بمستهلكي Parent main.html وPWAs.

الهدف هو تمييز:
- Edge يفرض الصلاحية بنفسه.
- Edge يمرر إلى RPC يفرض الصلاحية.
- Edge/RPC لا يفرضان الصلاحية.
- اختلاف طريقة احتساب effective permissions بين المسارات.

---

## 2. نتائج CONFIRMED

### 2.1 confirm-order — فجوة تفويض

- Edge: confirm-order v4، verify_jwt=true.
- يتحقق من JWT، ووجود المستخدم النشط، والشركة، وأن الطلب Draft/Pending وغير مرتبط بـRunsheet.
- ينفذ UPDATE مباشرًا على orders لتغيير order_status إلى Confirmed.
- لا يتحقق من orders أو telesales أو sales permission.
- يستخدم service_role client.
- Parent main.html يستدعي endpoint في مسار تأكيد الطلب، بما في ذلك confirm order من الشاشة الرئيسية والـmodal.

**النتيجة:** أي مستخدم نشط في الشركة يستطيع من حيث Edge contract طلب تأكيد أي Order Draft/Pending غير مرتبط برانشيت، حتى لو لم يكن مخولًا لتأكيد الطلب. لم يُنفذ HTTP request؛ الأثر Runtime UNVERIFIED.

### 2.2 create-runsheet / append-to-runsheet

- create-runsheet v26 وappend-to-runsheet v8 مستهلكان من Parent main.html.
- Edge يتحقق من JWT والمستخدم والشركة والحالة، لكنه لا يفرض effective permission.
- create_runsheet_atomic وappend_orders_to_runsheet_atomic يتحققان من الشركة والطلبات والرانشيت والحالة والتكرار، لكن لا يفرضان صلاحية المستخدم التشغيلية.
- توجد أقفال/ضوابط ذرية للتسلسل والتكرار، لكنها لا تعوض التفويض.

هذه النتائج تؤكد LVE-590 وتوضح أن مسار إنشاء/تعديل Runsheet يحتاج authorization server-side قبل أن يكون آمنًا.

### 2.3 مسارات الطلبات التي تحتوي فحصًا أفضل

- delete-order v10:
  - يحدد owner/general_manager/sales_manager/sales_supervisor للعمليات المميزة.
  - يسمح بمسار sales entry للـDraft وفق orders أو telesales.
- update-order v6:
  - يبني effective permissions من user.permissions وroles.permissions وrole_permissions.
  - يشترط orders أو telesales قبل تعديل الطلب.
- save-sales-invoice v19:
  - يفحص صلاحية المصدر بحسب العملية.
- sales-payment-allocation v2:
  - يفحص finance أو finance_manager.
- sales-return-management v2:
  - Edge لا يفحص الصلاحية مباشرة، لكن RPCs list_sales_return_management وsave_sales_return_review تتحقق من أن actor داخل الشركة ونشط ويملك * أو return.
- sales-quotes v2:
  - Edge يثبت هوية المستخدم والشركة.
  - RPC helper rawaea_quote_actor_ok يفرض * أو orders قبل إنشاء/تعديل/إدارة العرض.
- sales-target-engine v2:
  - sales_target_engine_gateway يفرق بين read/manage/approve:
    - read: sales_manager/sales_supervisor/general_manager/reports أو *.
    - manage: sales_manager/sales_supervisor/general_manager أو *.
    - approve/post/reverse: sales_manager/general_manager أو *.
- save-customer v4 وdelete-customer v3:
  - actor helper يفرض customers أو * قبل إنشاء/تعديل/تعطيل/حذف العميل.

هذه المسارات تثبت أن ضوابط الصلاحيات موجودة بالفعل في النظام؛ المشكلة هي عدم توحيد تطبيقها.

---

## 3. تعارض مصدر الصلاحية — CONFLICT

تم رصد نمطين مختلفين لاحتساب الصلاحيات:

### النمط A — Effective permissions

تجمع بعض المسارات:
- users.permissions
- roles.permissions
- role_permissions.permission_key

أمثلة: update-order وsave-sales-invoice، كما يستخدم save-purchase-order ملف المستخدم الفعال.

### النمط B — Direct user.permissions فقط

مسارات أخرى تتحقق من users.permissions دون دمج role permissions:
- save-customer / delete-customer.
- sales-return-management RPCs.
- rawaea_quote_actor_ok المستخدم في Sales Quotes.
- sales_target_engine_gateway.

**التعارض:** واجهة app.html وcore.js تعتمد على صلاحيات المستخدم الفعالة، بينما بعض Edge/RPC تعتمد على الصلاحيات المباشرة فقط. إذا كان المستخدم يحصل على customers أو return أو orders أو sales-target permission من role_id/roles.permissions/role_permissions دون نسخها إلى users.permissions، فقد تظهر له الشاشة ثم يرفضه الخادم، أو تختلف صلاحياته من مسار لآخر.

لا يوجد في هذه الجولة إثبات أن جميع role permissions تُنسخ تلقائيًا إلى users.permissions؛ لذلك:
- اختلاف implementation: CONFIRMED.
- أثره على كل مستخدم فعلي: UNKNOWN حتى مراجعة بيانات roles/role_permissions وtrigger/sync contract.

---

## 4. Parent consumer map

في Parent main.html الحالي:
- confirm-order يُستدعى في مساري تأكيد الطلب من الواجهة والـmodal.
- create-runsheet وappend-to-runsheet يُستدعيان من إدارة الرانشيت.
- save-journal-entry يُستدعى من مسار المالية.
- save-transfer-voucher يُستدعى من مسار التحويل بين الخزائن.

إذن فجوات LVE-590/LVE-591 ليست endpoints يتيمة فقط؛ هناك مستهلكات حية في النظام الأم.

في تطبيق Accountant:
- sendCash يستخدم save-receipt-voucher أو save-payment-voucher.
- يحتفظ بالعملية المعلقة في sessionStorage ويعيد المحاولة بنفس payload وoperation_id.
- هذا نمط idempotency جيد يجب الحفاظ عليه.
- لكن حفظ operation_id لا يعوض غياب finance permission في الخادم.

في Van Sales:
- save-receipt-voucher يُستخدم لتحصيل Van Sales.
- RPC الخاص بـVan Sales يتحقق من أن driver_email يعود لمندوب بيع مباشر وأن العميل مخصص له.
- لا تخلط هذا المسار مع سند القبض العام؛ فالسند العام يحتاج finance permission بينما تحصيل المندوب له role/customer assignment contract مستقل.

---

## 5. مصفوفة الصلاحيات الحالية

| العملية | الحماية الحالية | الحكم |
|---|---|---|
| Confirm Order | JWT + active user + company + status فقط | فجوة permission |
| Create Runsheet | JWT + company + RPC validations | فجوة permission |
| Append Runsheet | JWT + company + RPC validations | فجوة permission |
| Update Order | effective orders/telesales | أفضل |
| Delete Order | owner/manager/supervisor + draft permission | أفضل |
| Save Customer | direct customers permission | direct-role only |
| Delete Customer | direct customers permission | direct-role only |
| Sales Invoice | effective source permission | أفضل |
| Sales Return Review | RPC return permission | أفضل |
| Sales Quotes | RPC orders permission | أفضل |
| Sales Targets | RPC read/manage/approve roles | أفضل |
| Sales Payment Allocation | finance/finance_manager | أفضل |
| Manual Journal | لا finance permission في Edge | فجوة مالية LVE-591 |
| Treasury Transfer | لا finance permission في Edge | فجوة مالية LVE-591 |

---

## 6. ما لم يتم

- لم يتم استدعاء confirm-order أو create-runsheet أو append-to-runsheet من مستخدم غير مخول.
- لم يتم اختبار مستخدم يرث permission عبر role دون وجودها مباشرة في users.permissions.
- لم يتم تعديل صلاحيات أو Edge أو RPC أو بيانات.
- لم يتم دمج PR #10 أو نشر أي شيء.
- لم يتم اعتماد نموذج الصلاحيات النهائي من المالك.

---

## 7. ما يجب فعله قبل الإغلاق

1. اعتماد مصدر موحد لتعريف effective permissions، مع عدم إنشاء Permission Engine موازٍ.
2. إعادة استخدام helper موثوق موجود بالفعل مثل get_my_effective_profile أو نمط effective permissions المعتمد في save-sales-invoice/update-order.
3. إضافة checks في confirm-order وcreate-runsheet وappend-to-runsheet وفق صلاحيات المالك الفعلية.
4. توحيد role-derived permissions في save-customer وsales-return-management وsales-quotes وsales-target-engine، أو توثيق أن هذه العمليات تعتمد عمدًا على direct permissions فقط.
5. اختبارات سلبية لمستخدم Active داخل الشركة بلا permission، واختبارات إيجابية لمستخدم يملك permission مباشرة أو عبر role.
6. الحفاظ على operation_id في Accountant/Van Sales، وعدم توليد مفتاح جديد عند retry لنفس العملية.

لا تنفيذ قبل exact owner approval وفق Master §77.2.

---

## 8. الحكم

**توجد بوابات صلاحيات قوية في أجزاء من Sales، لكن Confirm Order وRunsheet creation/append ما زالت تعتمد على الهوية والشركة دون permission server-side. كما أن طريقة احتساب الصلاحيات ليست موحدة بين direct user permissions وrole-derived effective permissions.**

الحالة: SOURCE/RPC CONTRACT FINDINGS CONFIRMED / ROLE-INHERITANCE IMPACT UNKNOWN / RUNTIME UNVERIFIED / NOT CLOSED.  
لم يحدث أي تغيير تشغيلي أو مالي في LVE-592.
