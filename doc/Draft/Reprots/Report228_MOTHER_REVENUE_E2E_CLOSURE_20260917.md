# Report228 — إغلاق عقد الإيرادات في Production وتجهيز الجراحة النهائية للنظام الأم

**التاريخ:** 2026-09-17  
**النطاق:** Revenue / Receipts — النظام الأم + Production  
**Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

## 1. قاعدة الحالة

تم إيقاف أي اعتماد على التقارير باعتبارها حالة حالية. استُخدمت التقارير السابقة فقط لاسترجاع التاريخ وتحديد أماكن البحث، ثم تمت المطابقة المباشرة مع:

- CURRENT GIT
- CURRENT SOURCE
- CURRENT PRODUCTION
- CURRENT DATABASE
- CURRENT DEPLOYMENT EVIDENCE

الحالة الوظيفية الحالية للنظام الأم موجودة في Commit:

`8fff8f4f05ba0c0d95a985a742b58a5890028fdb`

والـHEAD الحالي للمستودع هو:

`d7bf7ed138fa95b8dfdb88cc407827340954aa43`

والـHEAD الأخير ليس تغييرًا وظيفيًا في `main.html`؛ بل حفظًا لـforensic extract، لذلك يبقى الـparent المذكور هو نقطة آخر تغيير وظيفي في Mother.

ملف `forensic_main_assembly.yml` تم التحقق منه مباشرة، وهو صحيح ولا يحتاج تعديلًا:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

## 2. حقيقة Revenue في Production

ثبت مباشرة أن Production تحتوي بالفعل على البنية الكاملة:

- `finance_revenue_categories`
- `finance_revenues`
- `finance_revenue_lines`
- `finance_save_revenue`
- `finance_list_revenues_v2`
- `finance_void_revenue`

ولا توجد حاجة لإنشاء جدول أو محرك جديد أو Edge Function جديدة للإيرادات.

الدالة `finance_save_revenue` هي المحرك المحاسبي المركزي وتفرض Company Context، Branch، Treasury، Revenue Account validation، Period Guard، Operation ID، ثم تنشئ السجلات المحاسبية وسجل الإيراد وسجل الخزينة.

## 3. صلاحية الاستدعاء من النظام الأم

تم التحقق مباشرة من `information_schema.routine_privileges` في Production.

الدوال الثلاث:

```text
finance_list_revenues_v2
finance_save_revenue
finance_void_revenue
```

ممنوحة لـ:

```text
authenticated
postgres
service_role
```

وبالتالي يستطيع النظام الأم المستند إلى جلسة المستخدم authenticated استدعاء الـRPCs مباشرة، ولا توجد حاجة لإدخال Edge Function وسيطة لمجرد تنفيذ Revenue.

## 4. إثبات دعم أكثر من حساب إيراد

تم إجراء E2E Transactionally في Production باختبار تجريبي داخل Transaction واحدة ثم Rollback كامل:

```text
Revenue line 1 = 10
Revenue line 2 = 20
Total          = 30
```

النتيجة:

```text
POST               = SUCCESS
Revenue header     = 1
Revenue lines      = 2
Journal entry      = created
Cash-box movement  = created
Treasury           = +30
Retry same op_id   = duplicate=true
Void               = SUCCESS
Rollback           = COMPLETE
```

بعد الـRollback تم التحقق من عدم بقاء أي سجل اختبار في:

```text
finance_revenues = 0
finance_revenue_lines = 0
```

كما بقي رصيد الخزينة الأصلي كما هو.

**النتيجة:** Production Revenue Core مغلق وظيفيًا من جهة Database/Accounting/Treasury/Idempotency.

## 5. النتيجة الجنائية في Mother

آخر Mother الوظيفية تحتوي على Revenue UI وReceipt UI جديد، ولكن التنفيذ السابق أدخل عيب Parsing حقيقي في `_newReceipt()`.

العنصر المعيب موجود في `_newReceipt()` قرب السطر `15526` في النسخة المرجعية الأخيرة، وعدد المواضع **اثنان**.

### الجراحة رقم 1 — إصلاح الـescaping

ابحث حرفيًا داخل `_newReceipt()` عن السطر:

```js
'onclick="RW_Finance.renderSubTab(\\'receipts\\')" ' +
```

هذا السطر موجود في موضعين داخل `_newReceipt()`.

احذف كل موضع منه كاملًا واستبدله حرفيًا بـ:

```js
'onclick="RW_Finance.renderSubTab(\'receipts\')" ' +
```

لا تعدّل أي جزء آخر من هذا السطر.

## 6. الجراحة رقم 2 — استبدال `_renderRevenues()` بالكامل

في `main.html` الحالي ابحث حرفيًا عن:

```js
function _renderRevenues() {
```

احذف **الدالة كاملة فقط** حتى القوس الأخير الذي يغلق `_renderRevenues()`.

في النسخة المرجعية الحالية، البديل الكامل المثبت في Report227 هو القسم `8. Mother Surgical Instructions`، ويجب نسخه كاملًا كما هو، وليس إعادة كتابته من الذاكرة.

البديل يحقق:

- شركة محددة من `_companyId()`.
- استدعاء `finance_list_revenues_v2` من نفس سياق الشركة.
- فلاتر تاريخ بداية/نهاية.
- عدد العمليات.
- إجمالي الإيرادات المرحلة.
- إجمالي العمليات.
- عدد المعكوس.
- جدول الإيرادات.
- زر `إيراد جديد`.
- زر `سندات القبض`.
- ربط مباشر بـ`_newReceipt` و`renderSubTab('receipts')`.

الـNode parser أثبت PASS لهذا الاستبدال، والنسخة لا تحتوي مرجعًا إلى `branchesForRevenue` خارج نطاقه.

## 7. الجراحة رقم 3 — Scope Bug

العيب الثاني داخل Mother هو:

```js
var branchesForRevenue = [];
```

داخل `_newReceipt()` فقط، ثم وجود اعتماد على نفس الاسم من `_renderRevenues()` خارج نطاقه.

**لا تنشئ Global variable جديدًا.**

اعتماد `_renderRevenues()` يكون على مصدر فروع مستقل داخل الدالة نفسها أو cache الشركة الحالي المستخدم في Finance.

القاعدة النهائية:

```text
_newReceipt scope ≠ _renderRevenues scope
```

## 8. ما لم يتم تعديله

- لم يتم تعديل `erp-frontend/companies/company-1/main.html` بواسطة المساعد.
- لم يتم إنشاء Revenue Engine جديد.
- لم يتم إنشاء جدول Revenue جديد.
- لم يتم إنشاء Edge Function جديدة للإيرادات.
- لم يتم المساس بتطبيقات Picker/Loader/Driver/POS/Vansales أو دورة Order/Runsheet.
- لم يتم المساس بملفات `Current/PWA/main2`.
- لم يتم تعديل `New-main`.
- لم يتم تعديل `forensic_main_assembly.yml` لأنه مثبت بالفعل على Source of Truth الصحيح.

## 9. الأخطاء/التجارب

### خطأ Parsing السابق

الخطأ المثبت:

```text
main:15526 Uncaught SyntaxError: Invalid or unexpected token
```

سببه escaping خاطئ داخل string JavaScript في `_newReceipt()`.

### اختبار Production

تم اختبار Revenue Save + Retry + Void داخل Transaction مع Rollback.

**نجح:**

- تعدد الحسابات.
- القيد المحاسبي.
- حركة الخزينة.
- Cash Box.
- Idempotency.
- Void.
- عدم ترك بيانات بعد Rollback.

### إثبات الصلاحيات

تم التحقق أن `finance_save_revenue`, `finance_list_revenues_v2`, `finance_void_revenue` قابلة للتنفيذ من دور `authenticated` في Production.

**الفشل الذي ظهر في المراجعة:**

محاولة استخدام `branchesForRevenue` خارج نطاقه.

**سبب الفشل:**

Local variable داخل `_newReceipt()` مع استخدام من `_renderRevenues()`.

**التصحيح:**

فصل مصدر الفروع عن Local scope وعدم إنشاء Global state جديد.

## 10. حالة الإغلاق

```text
PRODUCTION REVENUE CORE                 = VERIFIED
MULTI-ACCOUNT REVENUE                  = VERIFIED
TREASURY IMPACT                        = VERIFIED
ACCOUNTING IMPACT                      = VERIFIED
IDEMPOTENCY                             = VERIFIED
VOID / REVERSAL                         = VERIFIED
AUTHENTICATED RPC ACCESS               = VERIFIED
PRODUCTION DATA CLEAN                  = VERIFIED
FORENSIC ASSEMBLY SOURCE               = VERIFIED
MOTHER PARSING                         = REQUIRES OWNER SURGERY
MOTHER REVENUE E2E                     = OPEN UNTIL OWNER MERGE
```

لا يجوز إعلان `REVENUE GOLD/Diamond CLOSED` قبل تنفيذ جراحة Mother ثم تشغيل E2E من المتصفح وإعادة مطابقة Production بعد العملية.

## 11. تعليمات E2E بعد دمج Mother

التسلسل المطلوب:

1. فتح النظام الأم بعد تنفيذ الجراحة.
2. تسجيل الدخول.
3. فتح Finance.
4. فتح الإيرادات.
5. الضغط على **إيراد جديد**.
6. اختيار الفرع.
7. اختيار الخزينة.
8. إضافة حساب إيراد واحد.
9. إضافة حساب إيراد ثانٍ.
10. إدخال مبالغ مختلفة.
11. التأكد من الإجمالي.
12. الحفظ.
13. التحقق أن الشاشة لا تعود بخطأ JavaScript.
14. التحقق أن السند يظهر في قائمة الإيرادات.
15. إعادة تحميل الشاشة.
16. التحقق من بقاء السجل.
17. التحقق من القيد.
18. التحقق من Cash Box.
19. التحقق من Treasury.
20. اختبار Void إن كان الزر ظاهرًا.
21. إعادة مطابقة Production بعد نهاية الاختبار.

## 12. SELF-AUDIT

### ما تم إثباته

- Source of Truth الحالي.
- آخر Git functional parent.
- صحة `forensic_main_assembly.yml`.
- وجود Revenue Core في Production.
- دعم أكثر من Revenue Account.
- تأثير الإيراد على Accounting/Treasury/Cash Box.
- Idempotency.
- Void.
- عدم بقاء بيانات الاختبار.
- سبب Syntax Error.
- سبب Scope Error.
- صلاحية RPCs للدور authenticated.

### ما لم يتم إثباته بعد

- نجاح المتصفح بعد أن يدمج المالك جراحة Mother.
- نجاح كل تفاعلات Revenue UI في E2E الحقيقي بعد الدمج.
- عدم وجود خطأ JavaScript آخر مخفي خلف Syntax Error السابق.

### ما تم إصلاحه في Production

لا يوجد تغيير جديد مطلوب لمحرك Revenue في هذه الجلسة؛ Production Core الموجود كان صحيحًا وتم إثباته. تم تجنب إعادة تعديل شيء ثبت أنه يعمل بالفعل.

### ما يجب أن يفعله المساعد التالي أولًا

ابدأ من:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT
```

ثم:

```text
1. اقرأ HEAD والـparent.
2. اقرأ Mother الحالية، وليس main2.
3. طابق دوال Revenue الحالية مع Production RPCs.
4. افحص Console/Network.
5. إن كان Revenue يعمل، لا تعِد إصلاحه.
6. إن كان الخطأ بعد جراحة المالك، حدد الدالة/السطر حرفيًا.
7. لا تعدل Production ما لم يثبت Defect جديد.
8. بعد كل E2E أعد مطابقة Production قبل أي نسبة أو إغلاق.
9. أغلق Revenue فقط بعد owner merge + browser E2E + DB verification.
10. انتقل للنقطة المفتوحة التالية فقط بعد الإغلاق.
```

---

**مراجع مباشرة:**

- Report226: `doc/Draft/Reprots/Report226`
- Report227: `doc/Draft/Reprots/Report227_MOTHER_LOGIN_REVENUE_FORENSIC_20260917.md`
- Mother: `erp-frontend/companies/company-1/main.html`
- Assembly Governance: `forensic_main_assembly.yml`
