# تقرير جراحة Main2 — Report117
## RAWAEA ERP — مراجعة المصدر الحالي ومطابقة Production

### المرجعية
- MASTER التنفيذي الحالي: تم فتحه وقراءته حتى `END OF MASTER DIRECTIVE`.
- Report115: تمت قراءته مباشرة من Git، ويُعامل كسجل تاريخي لا كمصدر حقيقة.
- Report116: تمت مراجعته كآخر سجل تنفيذي متاح، وثبت أنه أقدم من مصدر `main2.md` الحالي في Git.
- المصدر الحالي: `Current/PWA/main2/main2.md` — SHA الحالي المقروء: `a4a9e8499a65ba182673a964f82671e68372cac8`.
- Git HEAD الحالي: `cd19caed9ef639c51c295691ced7c57d13d68e6c`.
- Production snapshot: `2026-09-10 11:50:56.024836+00`.

### Production snapshot
- companies: 1
- branches: 2
- users: 24
- items: 17
- customers: 3
- orders: 0
- purchase_orders: 0
- stock_branches: 20
- inventory_log: 3
- posted journal_entries: 0
- audit_log: 1869

## Finding 1 — RW_Dashboard / صافي الربح
### العنصر المعيب
بطاقة `dash-net-profit` تعرض «صافي الربح»، بينما `RW_Dashboard.loadAll()` يحسبه من:
`totalSales - totalPurchases`
باستخدام `purchase_orders.total_amount`.

### لماذا هو مرفوض
هذه المعادلة ليست صافي ربح محاسبيًا؛ فهي لا تعتمد على القيود المحاسبية المرحلة، ولا تمثل تكلفة المبيعات والمصروفات الفعلية بالشكل المعتمد في Production.

### مصدر الحقيقة البديل
Production تحتوي على RPC موثوق:
`get_profit_loss(p_from_date, p_to_date)`
وهو يقرأ `journal_entries/journal_lines` من الحسابات ذات نوع `revenue` و`expense` ويشتق Company Context من `app_private.current_user_company_id()`.

### الإجراء الجراحي
استبدال كتلة:
`// 2. المشتريات لصافي الربح`
حتى نهاية الـ`catch` الخاصة بها، بكتلة تستدعي `get_profit_loss` ثم تجمع revenue - expense، وتعرض `—` عند فشل الـRPC بدل رقم مضلل.

### Syntax
تم تشغيل `node --check` على كتلة البديل المضمّنة في حارس صياغة مستقل: PASS.

## Finding 2 — RW_Items / Company Context
### العناصر المعيبة
داخل `RW_Items` توجد مراجع إلى `companyId` بلا declaration محلي مثبت في المصدر الحالي، في:
- `_loadCategoriesIntoSelect()`
- `_openCategoryModal()`
- `_deleteCategory()`
- `_buildCategoryFilterFromDB()`
- `_renderUploadPreview()`

### لماذا هي مرفوضة
المتغير غير معرف ضمن هذه الوحدات، ما يخلق ReferenceError إذا لم يوجد global خارجي اتفاقيًا. الاعتماد على global ضمن parent assembly لا يحقق Company Context صريحًا ولا يحمي من drift في السياق.

### البديل الجراحي
في أول كل دالة متأثرة، قبل أول استعمال لـ`companyId`، إضافة:
`var companyId = _rwCompanyId();`
ثم حارس:
`if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }`

### Syntax
تم تشغيل `node --check` على بدائل الدوال والحراس: PASS.

## ما لم يتم تغييره
- لا تعديل على `Current/PWA/main2/main2.md` لأن MASTER يفرض Owner Source Surgery لهذا المسار.
- لا تغيير على Physical Stock Engine.
- لا تغيير على `post_stock_movement`.
- لا تغيير على `stock_branches` أو `inventory_log`.
- لا إعادة تطبيق لأي إصلاح تاريخي لمجرد وجوده في Report116.

## الحالة
`MAIN2 = OWNER ACTION REQUIRED`
`MAIN2 SOURCE = NOT MODIFIED BY ASSISTANT`
`FULL-FILE SYNTAX = NOT PROVEN`
`PRODUCTION INVENTORY CORE = NOT REOPENED`
`PRODUCTION SNAPSHOT = VERIFIED`

## Self-Audit
### What I Proved
- Master الحالي مقروء حتى النهاية.
- Report115 وReport116 أعيد فتحهما، ولم يُعتمد أي منهما كحقيقة حالية.
- مصدر main2 الحالي أُعيد فتحه حتى نهاية الملف.
- Git HEAD وSHA المصدر الحالي تم التحقق منهما مباشرة.
- Production snapshot أُعيد قياسه مباشرة.
- Production `get_profit_loss` تم التحقق من تعريفه الحالي.
- Syntax للبدائل الجراحية المقترحة تم اختباره بـ`node --check`.

### What I Did Not Prove
- Full-file parser success لـ`main2.md` في بيئة الاستخراج الحالية.
- Runtime browser success بعد Owner Source Surgery.
- Main2 assembly بعد الجراحة.

### Next Authorized Action
تنفيذ الاستبدالات الجراحية في `Current/PWA/main2/main2.md` فقط، ثم إعادة قراءة المصدر حتى EOF، ثم Syntax/Assembly/Runtime/Production verification وفق MASTER.
