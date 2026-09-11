# تقرير 123 — المراجعة الجنائية وإعادة فحص Main4
## RAWAEA ERP — Main4 Forensic Recheck / Gold-Diamond Functional Gate

> **الهدف الحاكم — إعادة التأكيد حرفيًا:** هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.
>
> وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

---

## 1. نطاق الجلسة

تم إيقاف أي مسار سابق، وتركّزت هذه الجلسة حصريًا على:

`Current/PWA/main2/main4.md`

مع مراجعة:

- الحوكمة الرئيسية.
- Report122 كأساس زمني فقط.
- CURRENT_STATE.md.
- Current Main4 من البداية حتى EOF.
- Original Main4 كمرجع تاريخي.
- `forensic_main_assembly.yml`.
- كامل مجموعة `Current/PWA/main2/main1.md ... main11.md` من حيث الوجود والمسارات والـSHA الحالية.
- Production Supabase للقدرات التي يعتمد عليها Main4، وبالأخص Roles وPOS/TeleSales dependencies.

لم يتم تعديل:

- `Current/PWA/main2/main4.md`.
- أي ملف من Main1–Main11.
- `Original/PWA/main4.md`.
- `Current/PWA/New-main`.
- أي Assembly نهائي.

هذا الالتزام مطابق لحدود الملكية: تعديلات Main4 المصدرية ينفذها المالك يدويًا، بينما تعديلات Production ينفذها CTO مباشرة.

---

## 2. إعادة بناء السياق التاريخي

### Report122
تمت قراءة Report122 من البداية حتى نهايته الفعلية. التقرير السابق نفسه أكد أن Main3 ظل Owner-boundary وأن التقارير السابقة أدلة لا تُعامل كحقيقة حالية.

### Production
لم تُعتمد أي نتيجة من التقارير السابقة دون مطابقة Production الحالية.

### Original Main4
تم فتح `Original/PWA/main/main4.md` فقط لفهم الأصل التاريخي. لم تتم استعادة الكود الأصلي لمجرد اختلافه عن Current، لأن Current يحمل تطورات لاحقة مرتبطة بـcompany scope وتكامل POS/Roles/TeleSales.

---

## 3. Main4 — القراءة الكاملة وEOF

المصدر المعتمد:

`Current/PWA/main2/main4.md`

Current blob SHA:

`e89d29e4164c68784c109292f27d4d77df240557`

الحجم المبلغ عنه في GitHub:

`64,146 bytes`

تمت القراءة المتسلسلة من بداية الملف حتى حدود EOF. القراءة النهائية بعد السطر 1360 أعادت محتوى فارغًا، بينما آخر المحتوى الحقيقي كان نهاية:

`window.RW_TeleSales = RW_TeleSales;`

وبذلك تم إثبات حد الإغلاق للملف.

### الوحدات الرئيسية المثبتة

1. `RW_POS` — نقطة البيع.
2. `RW_Roles` — إدارة أدوار المستخدمين.
3. `RW_TeleSales` — التلي سيلز.

لم يُثبت وجود `(قيد التطوير)` داخل Main4 بالبحث النصي المباشر. هذا لا يساوي Gold/Diamond completion.

---

## 4. Main4 — POS Contract

تم إثبات أن POS يجمع:

`orderHeader.operation_id = crypto.randomUUID()`

ويستخدم:

`save-sales-invoice`

على Edge Function.

Production `save_sales_invoice_atomic` الحالية تعتمد على `operation_id` كجزء من idempotency/order identity، وبالتالي لا يجب استبدال هذا السلوك بمفتاح ثابت أو hash تخميني.

كما أن POS يمر عبر:

`save-sales-invoice`

ثم Production Physical Stock Engine، وليس عبر كتابة مباشرة من Main4 إلى `stock_branches`.

### نتيجة الحوكمة
لا يوجد سبب مثبت لإعادة بناء lifecycle الخاص بـPOS داخل Main4، ولذلك لم يتم العبث به.

---

## 5. Main4 — TeleSales Contract

TeleSales هو Order flow وليس Invoice flow.

هذا مهم لأن المشروع يعتمد على الفصل بين:

- إنشاء الطلب.
- الربط بالرانشيت.
- التحضير.
- التحميل.
- التسليم.
- المرتجع.

لذلك لم يتم إدخال أي Physical Stock mutation إلى `_saveOrder` لمجرد “إكمال” الوظيفة.

تم إثبات أن Main4 يجمع العملاء والأصناف والفروع ضمن سياق الشركة الحالي، لكن عقد `allowed_branch_ids` على مستوى المستخدم داخل TeleSales لم يثبت بما يكفي لإضافة فلترة جديدة في هذه الجلسة دون مخاطرة بخرق contract تاريخي.

**القرار:** لا يتم اختراع branch filter جديد الآن.

---

## 6. Main4 — Roles: Production Reality

قبل الإصلاح، Production كانت تحتوي سياسة RLS:

`Allow all for all`

على جدول `roles`، وهي كانت تسمح بـALL دون company/permission enforcement.

كما أن Production `save-role` كانت لا تفرض permission gate بالشكل الكافي، و`delete-role` كانت لا تتحقق من company scope قبل الحذف، و`seed-roles` كانت تحمل company ID ثابتًا.

هذه عيوب Production مثبتة مباشرة من الحالية، وليست استنتاجات من شكل الواجهة.

---

## 7. ما تم إصلاحه فعليًا في Production

### 7.1 save-role
تم نشر:

`save-role` — Version 7 — ACTIVE — JWT required

الإصلاحات:

- اشتقاق company context من المستخدم المصادق عليه عبر `users.auth_id`.
- التعامل مع المستخدم Inactive/غير الصحيح.
- اشتراط permission `roles` أو wildcard `*`.
- company-scoped role update.
- عدم السماح برفع `is_system` من payload عند إنشاء دور جديد.
- الحفاظ على حالة `is_system` للدور القائم بدل تحويلها صراحة من الـUI.
- إزالة تكرار permissions.

Production deployment SHA:

`d979e3d6097ff11592811f462d12c5b7437a3ca9e0fb6d932b0a2b7a761adbd9`

### 7.2 delete-role
تم نشر:

`delete-role` — Version 3 — ACTIVE — JWT required

الإصلاحات:

- company context من المستخدم المصادق عليه.
- permission gate `roles` أو `*`.
- company-scoped lookup/delete.
- منع حذف `is_system = true`.
- منع حذف الدور المستخدم حاليًا من أي مستخدم داخل الشركة.
- تنظيف `role_permissions` للدور المحدد فقط.

Production deployment SHA:

`99b689791bd47cf806249fbb163f544ae2f62cf3e86a2f3f2d9ae55de7964b5e`

### 7.3 seed-roles
تم نشر:

`seed-roles` — Version 4 — ACTIVE — JWT required

الإصلاحات:

- إزالة company ID الثابت.
- اشتقاق الشركة من المستخدم الحالي.
- permission gate.
- فحص الأدوار الموجودة داخل الشركة الحالية فقط.
- إنشاء الأدوار الافتراضية مع permissions داخل `roles.permissions` مباشرة بما يتوافق مع الـschema الحالي.

Production deployment SHA:

`ffd7f56bc87d0874ca939bfed77f80d4fdcdc3cc5c27207116ce5858e3587953`

### 7.4 Roles RLS
تم تطبيق migration Production باسم:

`lock_roles_rls_to_company_and_permission`

تم حذف:

`Allow all for all`

وتم إنشاء سياسات منفصلة لـ:

- SELECT.
- INSERT.
- UPDATE.
- DELETE.

وجميعها تشترط:

`company_id = app_private.current_user_company_id()`

و:

`app_private.current_user_has_permission('roles')`

### 7.5 Production verification
بعد التنفيذ تم الاستعلام مباشرة عن `pg_policies`، وثبت وجود السياسات الأربع الجديدة.
كما ثبت بقاء:

- `مدير النظام` = system role.
- `مدير عام` = system role.

لم يتم حذف أي بيانات أعمال أثناء هذه الـclosure.

---

## 8. Main4 Owner Source Surgeries — محددة حرفيًا

> هذه العمليات تخص `Current/PWA/main2/main4.md` ولذلك **المستخدم/المالك** هو الذي ينفذها. لم يتم تعديل الملف بواسطة المساعد.

### MAIN4-N1 — POS session guard

**الموضع:** السطر 364.

ابحث عن السطر الكامل:

```javascript
        var token = sessionRes.data.session && sessionRes.data.session.access_token;
```

**أضف مباشرة بعده هذا المقطع كاملًا:**

```javascript
        if (!token) {
            hideLoader();
            showToast('انتهت الجلسة', 'error');
            return;
        }
```

لا تحذف سطر `token` الأصلي.

---

### MAIN4-N2 — حماية زر حذف الدور النظامي

**الموضع:** السطر 539 داخل `RW_Roles.openModal`.

ابحث عن السطر الكامل:

```javascript
        (isEdit ? '<button type="button" id="btn-delete-role" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fas fa-trash-alt ml-1"></i> حذف</button>' : '') +
```

**احذف السطر كاملًا** واستبدله بهذا السطر الكامل:

```javascript
        (isEdit && !role.is_system ? '<button type="button" id="btn-delete-role" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fas fa-trash-alt ml-1"></i> حذف الدور</button>' : (isEdit && role.is_system ? '<span class="px-4 py-2.5 bg-slate-100 text-slate-500 rounded-xl font-bold mr-auto"><i class="fas fa-lock ml-1"></i> دور نظامي</span>' : '')) +
```

النتيجة المقصودة: الدور النظامي لا يظهر له زر حذف أصلًا.

---

### MAIN4-N3 — منع تعديل الرصيد الافتتاحي من نموذج عميل TeleSales

**الموضع:** السطر 929.

ابحث عن السطر الكامل:

```javascript
    '<div class="flex flex-col"><label>الرصيد الحالي (' + currency + ')</label><input id="cust-debt" type="number" value="0" class="p-2.5 bg-gray-50 border rounded-lg"></div>' +
```

**احذف السطر كاملًا** واستبدله بـ:

```javascript
    '<div class="flex flex-col"><label>الرصيد الحالي (' + currency + ')</label><input id="cust-debt" type="number" value="0" readonly disabled class="p-2.5 bg-gray-100 border rounded-lg text-gray-600 cursor-not-allowed"><p class="text-xs text-gray-500 mt-1">الرصيد المالي يُعرض للقراءة فقط ويُدار من المسار المالي الرسمي.</p></div>' +
```

---

### MAIN4-N4 — إبقاء payload متوافقًا ومنع قيمة مالية قادمة من الحقل

**الموضع:** السطر 953.

ابحث عن السطر الكامل:

```javascript
              debt: parseFloat(document.getElementById('cust-debt').value)||0,
```

**احذف السطر كاملًا** واستبدله بـ:

```javascript
              debt: 0,
```

هذا يحافظ على مفتاح `debt` داخل payload للتوافق، لكن يمنع واجهة TeleSales من تمرير opening balance مالي من هذا النموذج.

---

## 9. لماذا لم يتم تعديل أشياء أخرى في Main4

### Roles permissions
الـschema الحالي يجعل `roles.permissions` JSONB، والـproduction data الحالية تحتوي arrays فعلية. لم يتم اختراع normalization آخر.

### Owner semantics
لم يتم تغيير `permissions = ['*']` للمالك، ولم يتم استبدال wildcard بقائمة صريحة.

### POS operation identity
لم يتم تغيير `crypto.randomUUID()`، لأنه متوافق مع عقد idempotency الحالي.

### TeleSales stock behavior
لم يتم إدخال أي stock mutation جديدة.

### TeleSales branch filtering
لم يتم افتراض أن `allowed_branch_ids` يجب أن يحكم هذه الشاشة دون contract مثبت من التاريخ والتطبيقات المرتبطة.

---

## 10. المطابقة مع Main1–Main11

تمت مراجعة دليل `Current/PWA/main2` مباشرة، وثبت وجود الأجزاء الـ11 في المسارات canonical:

`Current/PWA/main2/main1.md`
إلى
`Current/PWA/main2/main11.md`

كما أن `forensic_main_assembly.yml` الحالي يشير صراحة إلى `Current/PWA/main2` ويمنع:

- `Current/PWA/main`
- `Current/PWA/New-main`

ولا توجد حاجة لتغيير مسار assembly في هذه الجلسة.

لم يتم تنفيذ Assembly.

ملاحظة: هذه المطابقة هنا هي مطابقة canonical path/tree/manifest، وليست ادعاء بأن الأجزاء الـ11 كلها أعيدت قراءتها كاملة في هذه الجلسة؛ ذلك يبقى مرحلة منفصلة عند بوابة Assembly النهائية.

---

## 11. Syntax / Validation Gate

### Static source check
تمت قراءة Main4 حتى EOF، وتم فحص إغلاق الـIIFEs الأساسية:

- `window.RW_POS = RW_POS;`
- `window.RW_Roles = RW_Roles;`
- `window.RW_TeleSales = RW_TeleSales;`

ولم يظهر نقص واضح في الإغلاق البنيوي في المصدر الحالي.

### CI
الـworkflow الموجود في:

`.github/workflows/validate-main2-fragments.yml`

يطبق `node --check` على Main1–Main11.

لكن لا يوجد Run حديث موثوق مكشوف في GitHub connector لهذا checkpoint، ولذلك:

`CI PASS = NOT PROVEN`

ولم يتم تحويل static source review إلى ادعاء CI verification.

### Local syntax attempt
محاولة جلب raw GitHub من runtime المحلي لفحص Node مباشرة فشلت بسبب عدم توفر DNS/network الخارجي في بيئة التنفيذ. هذا failure بيئي وليس syntax failure.

---

## 12. التجارب والنتائج

### نجح

- قراءة Main4 حتى EOF.
- إثبات Main4 current SHA.
- إثبات assembly source-of-truth.
- Production `save-role` v7 ACTIVE.
- Production `delete-role` v3 ACTIVE.
- Production `seed-roles` v4 ACTIVE.
- Production roles RLS policies الأربع مثبتة بعد migration.
- system roles لم تختفِ من Production.

### لم يُدّعَ نجاحه

- Browser E2E بعد Owner surgeries.
- CI `node --check` بعد هذا checkpoint.
- Gold/Diamond completion الكامل لـMain4.
- Gold/Diamond completion الكامل لكل Main1–Main11.

---

## 13. الأخطاء التي ظهرت وأسبابها

### Production error — Roles authorization
المشكلة الأصلية كانت غياب enforcement الكافي على Roles، مع RLS مفتوح وسياسات وEdge functions تسمحان بأفعال إدارية دون tenant/permission boundary قوي.

**Root cause:** تطور طبقات الإدارة بمرور الوقت دون أن تتحول الحدود الأمنية إلى عقد موحد في كل طبقات المسار.

**الإصلاح:** توحيد Actor/Company/Permission checks داخل Edge layer وإغلاق RLS على نفس العقد.

### Validation limitation
القيود البيئية منعت تشغيل GitHub raw محليًا، ولم يظهر CI Run يمكن اعتماده.

**القرار:** لا توجد نتيجة Syntax CI مُختلقة.

---

## 14. Gold/Diamond Functional Assessment

Main4 ليس مجرد شاشة ناقصة، لكنه أيضًا ليس Gold/Diamond مغلقًا.

الملف الحالي يملك أساسًا وظيفيًا حقيقيًا في:

- POS.
- Roles.
- TeleSales.

لكن هدف المشروع أوسع من CRUD. لذلك يبقى الباب مفتوحًا لاستكمال business depth المثبت بالعقود الفعلية، خاصة:

- customer financial context.
- stronger operational views.
- richer sales/credit workflows.
- branch-aware execution عند إثبات contract.
- التكامل بين الإدارة المركزية والتطبيقات الميدانية.

هذه ليست دعوة لإضافة وظائف عامة من خارج المشروع؛ كل نقطة يجب فتحها عندما يتوفر contractها التاريخي والـProduction evidence.

---

## 15. FINAL SELF-AUDIT

### What I Proved

- Main4 canonical path.
- Main4 current blob SHA.
- Main4 EOF boundary.
- Main4 functional units POS/Roles/TeleSales.
- POS operation identity contract موجود.
- TeleSales ليس Physical Stock writer.
- Roles Production security defects كانت حقيقية ومثبتة.
- Roles security fixes تم نشرها فعلًا.
- Roles RLS policies الأربع موجودة بعد الإصلاح.
- Assembly manifest صحيح.

### What I Did Not Prove

- Browser E2E.
- CI PASS.
- TeleSales allowed-branch contract الكامل.
- Gold/Diamond functional completeness للـMain4.
- Gold/Diamond completeness للمشروع كله.

### What I Fixed

- Production save-role security.
- Production delete-role security.
- Production seed-role tenant correctness.
- Production roles RLS isolation/permission enforcement.

### What I Initially Missed During Exploration

ظهر أثناء الفحص أن Role security ليست مجرد Edge Function concern؛ وجود RLS policy `Allow all for all` جعل اصلاح الـEdge وحده غير كافٍ، لذلك تم إغلاق طبقة database أيضًا.

### What Could Still Be Wrong

أي contract ميداني خاص بـTeleSales branch assignment لم يثبت حتى الآن من المصادر التاريخية والتطبيقات المرتبطة؛ لذلك لم يتم اختراعه.

### Final Confidence

`HIGH` في Production Roles security closure.

`HIGH` في Main4 structural/EOF reconstruction.

`MEDIUM` في Gold/Diamond functional completeness لأن أجزاء الأعمال الأعمق ما زالت مفتوحة.

### Final Closure Status

`MAIN4 FORENSIC RECHECK = COMPLETED`

`MAIN4 PRODUCTION SECURITY CLOSURE = COMPLETED`

`MAIN4 OWNER SOURCE SURGERY = REQUIRED`

`MAIN4 GOLD/DIAMOND FUNCTIONAL COMPLETION = NOT YET CLOSED`

`FINAL ASSEMBLY = DEFERRED`

---

## 16. Session Handoff

ابدأ بعد تنفيذ المالك:

`MAIN4-N1 → MAIN4-N2 → MAIN4-N3 → MAIN4-N4`

ثم:

1. إعادة قراءة `Current/PWA/main2/main4.md` كاملة حتى EOF.
2. تشغيل syntax validation عبر workflow Main1–Main11.
3. إعادة مطابقة Production مع Main4 الحالي.
4. فتح أول functional gap لم يُغلق بعد، دون إعادة فتح ما ثبتت صحته.
5. لا تبدأ Assembly قبل إغلاق جميع Owner surgeries وفتح/مراجعة كل الأجزاء حسب بوابة المشروع.
