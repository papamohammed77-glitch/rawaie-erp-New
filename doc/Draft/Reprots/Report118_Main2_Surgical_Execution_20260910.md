# تقرير جراحة Main2 — Report118
## RAWAEA ERP — Owner Source Surgery Preparation

### المرجعية المباشرة
- MASTER التنفيذي: `doc/Draft/Reprots/MASTER — RAWAEA ERP Successor CTO Memory Recovery & Gold-Diamond Execution Directive.md`
- Report117: `doc/Draft/Reprots/Report117_Main2_Surgical_Review_20260910.md`
- المصدر الحالي: `Current/PWA/main2/main2.md`
- SHA المصدر الحالي عند الفحص: `a4a9e8499a65ba182673a964f82671e68372cac8`
- Git HEAD المقروء قبل هذا السجل: `5d84cec48402c03ad7c346d826d18a1d828e92f9`

## تنفيذ الحوكمة
تمت إعادة فتح MASTER كاملًا من البداية حتى `END OF MASTER DIRECTIVE` على دفعات متسلسلة، وتمت إعادة فتح Report117 والمصدر الحالي لـMain2 مباشرة من Git. لم يُعتمد Report117 أو الذاكرة كمصدر حقيقة.

## نتائج المطابقة الحالية
1. `dash-net-profit` في `RW_Dashboard.loadAll()` ما زال يحسب `sales - purchase_orders.total_amount`، وهو العنصر المعيب المحدد في Report117.
2. الدوال `_loadCategoriesIntoSelect`, `_openCategoryModal`, `_deleteCategory`, `_buildCategoryFilterFromDB`, `_renderUploadPreview` تستخدم `companyId` دون declaration محلي مثبت داخل الدالة، وهو تعارض مباشر مع عقد Company Context.
3. `items.item_code` مثبت في Production كـ`UNIQUE` عالمي؛ لذلك لا يجوز اختراع `company_id + item_code` كهوية بديلة.
4. إصلاح Main2 يقع ضمن Owner Source Boundary؛ لذلك لم يتم تعديل `Current/PWA/main2/main2.md` بواسطة المساعد.

## الجراحة المصرح بها
تم تجهيز عناصر استبدال كاملة للدوال الخمس، وفي بداية كل دالة متأثرة تم تثبيت `var companyId = _rwCompanyId();` مع حارس صريح عند غياب السياق.

## التحقق
- Syntax للبدائل الخمسة: PASS باستخدام `node --check` على ملف تحقق مستقل يحتوي البدائل الكاملة.
- Full-file Syntax لـ`main2.md`: لم يُعلن لأن Owner Source Surgery لم تُطبق بعد.
- Browser Runtime بعد الجراحة: غير منفذ بعد.
- Assembly بعد الجراحة: غير منفذ بعد.

## الحالة النهائية للسجل
`MAIN2 = OWNER ACTION REQUIRED`
`SURGERY READY`
`SOURCE NOT MODIFIED BY ASSISTANT`
`PRODUCTION NOT CLOSED`

## Next Authorized Action
استبدال العناصر الخمسة المحددة أدناه حرفيًا داخل `Current/PWA/main2/main2.md`، ثم إعادة فتح المصدر كاملًا وإجراء Syntax/Assembly/Runtime/Production verification.