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

## 3. إثبات دعم أكثر من حساب إيراد

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

## 4. النتيجة الجنائية في Mother

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

## 5. الجراحة رقم 2 — نطاق `_newReceipt`

في `main.html` الحالي ابحث حرفيًا عن:

```js
async function _newReceipt() {
```

وبدءًا من هذا السطر احذف **كل كتلة `_newReceipt` والدوال المرتبطة بها**:

```text
_newReceipt
_addReceiptLine
_removeReceiptLine
_recalcReceiptTotal
_saveReceipt
```

ونطاق الحذف ينتهي مباشرة قبل السطر التالي الموجود في الملف:

```js
var _customerPaymentRealtimeChannel = null;
```

في النسخة المرجعية الأخيرة كان هذا النطاق تقريبًا `15443 → 15542`.

### البديل

استخدم **كتلة الاستبدال الكاملة الموجودة في Report226** كما هي، وليس أجزاءً مقتطعة. هذه الكتلة هي الإصدار المصمم للربط مع:

```text
RW_Finance
_companyId()
_cache.accountsFlat
_cache.treasury
finance_revenue_categories
finance_save_revenue
```

وتحتوي على:

- اختيار التاريخ.
- اختيار الفرع.
- اختيار الخزينة.
- اختيار فئة الإيراد.
- حساب إيراد واحد أو عدة حسابات إيراد.
- إضافة وحذف خطوط.
- إعادة حساب الإجمالي.
- Operation ID ثابت للعملية.
- حفظ عبر Revenue RPC.
- رسائل النجاح/الفشل.
- الرجوع إلى شاشة سندات القبض.

**لا تعيد كتابة الدالة يدويًا من الذاكرة؛ انسخ كتلة Report226 كاملة.**

## 6. الجراحة رقم 3 — منع Scope Bug

النسخة الحالية من Revenue UI كانت تعتمد على متغير فروع تم تعريفه داخل `_newReceipt()` ثم استُخدم خارج نطاقه من `_renderRevenues()`.

لا تنقل هذا المتغير إلى Global scope.

داخل `_renderRevenues()` فقط، استخدم جلب الفروع من نفس Company Context وبـ`company_id`، أو استخدم مصدر الفروع الموجود أصلًا في الـcache إذا كان هذا هو المصدر الذي يستخدمه Finance في نفس الملف.

القاعدة: **لا يجوز أن يقرأ `_renderRevenues()` متغيرًا محليًا مملوكًا لـ`_newReceipt()`.**

هذا إصلاح Scope فقط، ولا يغيّر عقد Revenue.

## 7. ما لم يتم تعديله

- لم يتم تعديل `erp-frontend/companies/company-1/main.html` بواسطة المساعد.
- لم يتم إنشاء Revenue Engine جديد.
- لم يتم إنشاء جدول Revenue جديد.
- لم يتم إنشاء Edge Function جديدة.
- لم يتم المساس بتطبيقات Picker/Loader/Driver/POS/Vansales أو دورة Order/Runsheet.
- لم يتم المساس بملفات `Current/PWA/main2`.
- لم يتم تعديل `New-main`.
- لم يتم تعديل `forensic_main_assembly.yml` لأنه مثبت بالفعل على Source of Truth الصحيح.

## 8. الأخطاء/التجارب

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

**الفشل الذي ظهر في المراجعة الأولى:**

محاولة استخدام `branchesForRevenue` خارج نطاقه.

**سبب الفشل:**

Local variable داخل `_newReceipt()` مع استخدام من `_renderRevenues()`.

**التصحيح:**

فصل مصدر الفروع عن Local scope وعدم إنشاء Global state جديد.

## 9. حالة الإغلاق

```text
PRODUCTION REVENUE CORE                 = VERIFIED
MULTI-ACCOUNT REVENUE                  = VERIFIED
TREASURY IMPACT                        = VERIFIED
ACCOUNTING IMPACT                      = VERIFIED
IDEMPOTENCY                             = VERIFIED
VOID / REVERSAL                         = VERIFIED
PRODUCTION DATA CLEAN                  = VERIFIED
FORENSIC ASSEMBLY SOURCE               = VERIFIED
MOTHER PARSING                         = REQUIRES OWNER SURGERY
MOTHER REVENUE E2E                     = OPEN UNTIL OWNER MERGE
```

لا يجوز إعلان `REVENUE GOLD/Diamond CLOSED` قبل تنفيذ جراحة Mother ثم تشغيل E2E من المتصفح وإعادة مطابقة Production بعد العملية.

## 10. تعليمات E2E بعد دمج Mother

التسلسل المطلوب:

1. فتح النظام الأم بعد تنفيذ الجراحة.
2. تسجيل الدخول.
3. فتح سندات القبض.
4. الضغط على **إيراد جديد**.
5. اختيار الفرع.
6. اختيار الخزينة.
7. إضافة حساب إيراد واحد.
8. إضافة حساب إيراد ثانٍ.
9. إدخال مبالغ مختلفة.
10. التأكد من الإجمالي.
11. الحفظ.
12. التحقق أن الشاشة لا تعود بخطأ JavaScript.
13. التحقق أن السند يظهر في قائمة الإيرادات.
14. إعادة تحميل الشاشة.
15. التحقق من بقاء السجل.
16. التحقق من القيد.
17. التحقق من Cash Box.
18. التحقق من Treasury.
19. اختبار Void إن كان الزر ظاهرًا.
20. إعادة مطابقة Production بعد نهاية الاختبار.

## 11. SELF-AUDIT

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
9. فقط بعد إثبات Revenue انتقل للنقطة المفتوحة التالية.
```

## 12. القرار النهائي

**Revenue Production Core = CLOSED / VERIFIED.**

**Revenue Mother UI = OPEN / OWNER SURGERY REQUIRED.**

سبب بقاء النقطة مفتوحة ليس نقص Backend، بل أن النسخة الحالية من Mother تحتاج إصلاح الـSyntax والـScope ثم E2E حقيقي بعد الدمج.

---

**مراجع مباشرة:**

- Report226: `doc/Draft/Reprots/Report226`
- Report227: `doc/Draft/Reprots/Report227_MOTHER_LOGIN_REVENUE_FORENSIC_20260917.md`
- Mother: `erp-frontend/companies/company-1/main.html`
- Assembly Governance: `forensic_main_assembly.yml`
