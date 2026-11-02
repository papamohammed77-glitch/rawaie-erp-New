# RAWAEA ERP — إعادة بناء نموذج الصلاحيات الفعلي ومطابقته مع بيانات المستخدمين

**Checkpoint:** LVE-2026-11-03-594  
**التاريخ:** 2026-11-03  
**الحالة:** EFFECTIVE PERMISSION MODEL CONFIRMED / ROLE-ONLY ACCESS CONFLICT CONFIRMED / USER SCHEMA CONFLICT CONFIRMED  
**نقطة البداية:** LVE-593.

---

## 1. الهدف

حسم UNKNOWN المسجل في LVE-592 حول الفرق بين:
- users.permissions
- roles.permissions
- role_permissions.permission_key
- الصلاحيات الفعلية التي تعرضها الواجهة عبر get_my_effective_profile.

تم فحص الدالة الفعلية، مخطط الجداول، Triggers، بيانات الأدوار والمستخدمين النشطين، ثم مطابقة ذلك مع RPCs/Edge التي تعتمد على direct permissions فقط.

---

## 2. مصدر الصلاحيات الفعلي — CONFIRMED

Production public.get_my_effective_profile() هي SECURITY DEFINER وتعيد:
- هوية المستخدم والشركة والحالة والدور.
- permissions ناتجة عن UNION بين:
  1. users.permissions
  2. roles.permissions
  3. role_permissions.permission_key
- isOwner مشتق من auth.users.raw_user_meta_data->>'isOwner' مع شرط users.permissions يحتوي * ووجود owner_profile مرتبط بـauth.uid().

إذًا:
- الصلاحية الفعلية في النظام ليست users.permissions وحدها.
- لا يجوز أن يبني Edge/RPC مستقل قرار الصلاحية من users.permissions فقط إذا كانت الواجهة أو المسارات المركزية تعتمد get_my_effective_profile.
- لا يوجد عمود is_owner في public.users؛ isOwner قيمة محسوبة داخل get_my_effective_profile.

### 2.1 Triggers

تم فحص Triggers على public.users وpublic.roles وpublic.role_permissions:
- لا يوجد trigger ينسخ roles.permissions أو role_permissions إلى users.permissions.
- الموجود فقط trigger تحديث updated_at على roles.

إذًا role-derived permissions ليست مجرد نسخة تلقائية داخل users.permissions؛ إنها تُجمع وقت الاستعلام عبر get_my_effective_profile.

---

## 3. بيانات الأدوار النشطة — CONFIRMED

- معظم المستخدمين النشطين لديهم role_id، وبياناتهم المباشرة تتوافق غالبًا مع role permissions.
- مستخدم مدير النظام لديه users.permissions=["*"]، لذلك direct wildcard يمرر أغلب checks.
- مستخدم مدير عام لديه direct permissions تشمل general_manager وreturn وcustomers وitems وbranches وغيرها، لكن لا تشمل:
  - finance
  - orders
  - pos
  - purchases
  - warehouse
- هذه المفاتيح موجودة في role_permissions المرتبطة بدور مدير عام.
- get_my_effective_profile يدمج هذه المفاتيح ويعرضها كصلاحيات فعالة.

هذا فرق فعلي في Production data، وليس مجرد احتمال نظري.

---

## 4. أثر التعارض — CONFLICT مثبت

### 4.1 Sales Quotes

- sales-quotes Edge v2 يمرر هوية المستخدم إلى RPC.
- RPC helper rawaea_quote_actor_ok يفحص users.permissions فقط ويقبل * أو orders.
- مستخدم مدير عام الحالي يملك orders عبر role_permissions، لكنه لا يملك orders داخل users.permissions.
- لذلك helper سيرفضه رغم أن get_my_effective_profile يعرض orders كصلاحية فعالة.
- إذا كانت واجهة Parent تعرض Sales Quotes للمستخدم بناءً على effective permissions، فهناك تعارض UI/RPC.

Source/DB permission conflict CONFIRMED؛ نتيجة تجربة Runtime للمستخدم المحدد لم تُنفذ، لذلك الرفض الفعلي UNVERIFIED.

### 4.2 مسارات أخرى

- sales-return-management RPCs تفحص return مباشرة؛ المستخدم مدير عام يملك return مباشرة، فلا يثبت هذا الفحص وحده تعارضًا له.
- sales-target-engine_gateway يفحص general_manager مباشرة؛ المستخدم يملك general_manager مباشرة، لذلك لا يثبت هذا المسار تعارضًا له.
- save-customer/delete-customer يستخدمان direct customers، والمستخدم يملك customers مباشرة، لكن هناك تعارضًا آخر في is_owner schema يمنع اعتبارهما مسارين سليمين.

لا تعمم نتيجة Sales Quotes على كل الخدمات؛ يلزم فحص كل direct-permission consumer بحسب المفاتيح التي يطلبها.

---

## 5. تصحيح is_owner — CONFIRMED SOURCE/DB CONFLICT

- save-customer v4 وdelete-customer v3 يطلبان is_owner من public.users.
- Production public.users لا يحتوي is_owner.
- get_my_effective_profile يعيد isOwner بصيغة محسوبة من auth metadata وowner_profile.
- لا يجوز إصلاح ذلك بإضافة عمود is_owner إلى users دون قرار معماري؛ يجب أولًا توحيد Edge مع مصدر الحقيقة الحالي isOwner أو helper الحالي.

الاستعلام عن عمود غير موجود سيمنع actor lookup قبل الوصول إلى permission check؛ Runtime لم يُختبر.

---

## 6. المعمارية الصحيحة التي يجب الحفاظ عليها

1. get_my_effective_profile هو مصدر الصلاحيات الفعالة الحالي.
2. لا تنشئ جدولًا أو helper موازيًا لإعادة تعريف الصلاحيات.
3. Edge الذي يستخدم service_role يجب أن يستدعي helper موثوقًا بهوية المستخدم النهائية أو يجلب effective profile من مسار محمي.
4. RPC SECURITY DEFINER يجب أن يفرض permission check داخليًا إذا كان قابلًا للاستدعاء من authenticated أو إذا كان Edge wrapper هو حد الحماية.
5. لا تعتبر allowed_branch_ids نطاقًا جغرافيًا بديلًا عن permission؛ branch scope وpermission شرطان منفصلان.
6. Owner status لا يؤخذ من users.is_owner لأنه غير موجود؛ المصدر الحالي هو get_my_effective_profile.isOwner.
7. اختبارات القبول يجب أن تشمل:
   - صلاحية مباشرة في users.permissions.
   - صلاحية موروثة من roles.permissions.
   - صلاحية مضافة عبر role_permissions.
   - مستخدم لا يملك الصلاحية.
   - Owner profile الحقيقي.
   - مستخدم له branch scope دون permission.

---

## 7. ما تم وما لم يتم

**تم:**
- فحص مخطط users/roles/role_permissions.
- فحص Triggers على الجداول الثلاثة.
- قراءة get_my_effective_profile definition.
- مقارنة role permissions مع direct permissions للمستخدمين النشطين.
- إثبات أن مدير عام الحالي يملك orders/finance/pos/purchases/warehouse من role_permissions دون وجودها في users.permissions.
- قراءة rawaea_quote_actor_ok ومطابقة شرطه مع بيانات المستخدم.
- تصحيح نتيجة save-customer/delete-customer السابقة بشأن is_owner.

**لم يتم:**
- لم يتم تسجيل دخول أو اختبار واجهة Sales Quotes بحساب مدير عام.
- لم يتم تغيير users.permissions أو role_permissions أو roles.permissions.
- لم يتم تعديل Edge/RPC أو إضافة عمود is_owner.
- لم يتم تنفيذ أي DML أو نشر.

---

## 8. الحكم

**مصدر الصلاحيات الفعلي هو get_my_effective_profile الذي يدمج ثلاث طبقات. توجد RPCs/Edge قديمة تعتمد users.permissions فقط، وبيانات مدير عام الحالية تثبت أن ذلك قد يرفض صلاحية orders الموروثة. كما أن Edge customer endpoints تعتمد عمود is_owner غير الموجود في Production users schema.**

الحالة: PERMISSION MODEL CONFIRMED / SALES QUOTE ROLE-ONLY CONFLICT CONFIRMED / CUSTOMER is_owner CONTRACT CONFLICT CONFIRMED / RUNTIME UNVERIFIED / NOT CLOSED.
