# Report73 — المراجعة الجنائية الجراحية لـ main4

التاريخ: 2026-09-07
المستودع: `papamohammed77-glitch/rawaie-erp-New`
الفرع: `main`
Production: `SMART ERP / fiilmooggumokxanwiyx`

## 1. الهدف

استكمال العمل من آخر حالة موثقة بعد Report72، دون إعادة فتح main3 ودون إعادة البدء من الصفر، وفحص `Current/PWA/main2/main4.md` كاملًا من أوله إلى آخر `})();`، ثم مطابقة العقود مع Git وProduction الحالية.

لم يتم تعديل `main4.md` بواسطة المساعد. هذا التقرير يوثق الفحص والتعليمات الجراحية التي سينفذها المستخدم يدويًا.

## 2. Last Verified State

قبل هذه الجلسة كان آخر State Commit المثبت:

```text
6e4a333e5938d1fb02d71da260f41056ddc2a44d
Update CURRENT_STATE after main3 Report72 verification
UTC 2026-09-07 04:30:29
```

كما أن main3 ظل عند:

```text
commit = e5a340b0a2c3de8a38a2d09375753afe1538230b
blob   = 479060e3d4bea5e2203c87f822b1dbc0e2f7d456
```

## 3. المصادر التي تمت مراجعتها

- `doc/Draft/medhat/MASTER - RAWAEA ERP.md` كاملًا.
- `CURRENT_STATE.md` كاملًا.
- `doc/Draft/Reprots/Report72_Main3_PostPatch_Forensic_Verification_20260907.md` كاملًا.
- `Current/PWA/main2/main3.md` كاملًا من Git الحالي.
- `Current/PWA/main2/main4.md` كاملًا من البداية حتى نهاية الملف.
- Production PostgreSQL الحالية للـ`companies`, `app_settings`, `users`, `roles`, `customers`, `branches`, `items`, `stock_branches`.
- Production RLS للكيانات المرتبطة.
- Production Edge Functions الحالية ذات العلاقة، وعلى رأسها `save-sales-invoice`, `save-role`, `delete-role`, `seed-roles`.

## 4. Production Reality — 2026-09-07

الحالة الحالية المثبتة مباشرة:

```text
companies = 1
app_settings = 1
users = 24
roles = 20
customers = 3
branches = 2
items = 17
```

الإعداد الحالي:

```text
company_id = 00000000-0000-0000-0000-000000000001
company_name = الروائع
currency = SAR
main_branch_id موجود فعليًا
```

الفروع الحالية:

```text
BR-01 = الفرع الرئيسي
BR-2  = فرع إسكندرية
```

Schema facts:

```text
items.item_code = UNIQUE عالميًا
roles.company_id = موجود
branches.company_id = موجود
app_settings.company_id = موجود
app_settings.main_branch_id = موجود
stock_branches.company_id = غير موجود؛ السياق يستنتج من branch_id -> branches.company_id
```

RLS الحالي:

```text
app_settings = company-scoped
branches = company-scoped
customers = company-scoped
stock_branches SELECT = company-aware through branch
roles = policy واسعة Allow all for all (true/true) وما زالت Closure مستقلة
```

## 5. main4 Logical Modules

الملف يحتوي ثلاث وحدات منطقية:

```text
RW_POS
RW_Roles
RW_TeleSales
```

تمت قراءة الملف كله حتى نهاية `RW_TeleSales` وبعدها `})();` النهائي.

## 6. Findings — RW_POS

### F1 — app_settings lookup غير مقيد بالشركة

الموجود حاليًا:

```javascript
var settingsRes = await supabase.from('app_settings').select('*').limit(1).single();
```

هذا يعتمد على global lookup، وهو مخالف لعقد Tenant الحالي.

### F2 — POS يستخدم branchId بينما Production Edge Contract يستخدم branchCode

الموجود:

```javascript
body: JSON.stringify({
    orderHeader: orderHeader,
    itemsList: itemsList,
    branchId: 'MAIN'
})
```

والـProduction Edge الحالية تبني `p_branch_code` من `body.branchCode`.

كما أن Production branch code الفعلي للفرع الرئيسي هو `BR-01`، وليس `MAIN`.

هذا Defect حقيقي، وليس تجميليًا.

### F3 — العملة Hard-coded إلى EGP

Production الحالية تقول `currency = SAR`، بينما main4 يعرض `EGP` في POS.

يجب تحويل العرض إلى currency القادمة من `app_settings` الحالية، مع fallback فقط عند غياب القيمة نفسها وليس عند فشل القراءة.

## 7. Findings — RW_Roles

الـwrites الحالية تمر عبر Edge Functions.

`save-role` الحالي company-aware في Production.

لكن القراءات المحلية في main4 غير scoped:

```javascript
supabase.from('roles').select('*')
```

وتوجد هذه القراءة بعد:

```text
initial render
successful save
successful delete
successful seed
```

يجب جعل جميع هذه القراءات company-scoped.

أما `delete-role` في Production فهو ما زال بدون predicate على company_id؛ وهذا Backend Closure مستقل، ولا يجب حلّه بإخفاء المشكلة داخل main4.

## 8. Findings — RW_TeleSales

### F4 — app_settings غير scoped

يوجد lookup عالمي للإعدادات أثناء render ويوجد lookup عالمي آخر داخل `_saveOrder`.

### F5 — branches غير scoped

الموجود:

```javascript
supabase.from('branches').select('id, branch_code, name')
```

يجب قصره على `_rwCompanyId()`.

### F6 — stock_branches غير مقيد بنطاق الفروع الحالية

الـtable لا يحمل company_id، وبالتالي الحل الصحيح هو:

```text
company_id
→ branches
→ branch IDs
→ stock_branches WHERE branch_id IN (...)
```

وليس اختراع company_id في stock_branches.

### F7 — عند عدم اختيار فرع يتم جمع المتاح من كل الفروع

`_getAvailable()` الحالي يجمع الرصيد المتاح لجميع الفروع عندما لا يكون هناك فرع مختار.

لكن الطلب نفسه يُحفظ لاحقًا بفرع واحد.

هذا يجعل مصدر الرصيد مختلفًا عن مصدر الفرع الفعلي للطلب.

الإصلاح الجراحي: لا تحسب أي Available عند عدم اختيار الفرع؛ أطلب من المستخدم اختيار الفرع أولًا.

### F8 — `_saveOrder` لديه fallback صامت بعد فشل قراءة الإعدادات

عند فشل `app_settings`، الكود الحالي يستمر بقيم محلية ويصفر الضريبة.

هذا يمكن أن يجعل نفس الأوردر يُحسب بطريقتين حسب نجاح قراءة الإعدادات.

الإصلاح: فشل تحميل الإعدادات = توقف العملية برسالة واضحة.

### F9 — العملة Hard-coded إلى EGP

وجدت EGP في:

- customer debt display
- customer form
- item search prices
- cart prices
- minimum invoice message

يجب ربطها بالعملة الحالية.

## 9. ماذا لم أغير

```text
main3.md                 = لم يُفتح
main4.md                 = لم يُعدل
roles RLS                = لم يُعدل
save-role backend        = لم يُعدل
 delete-role backend     = لم يُعدل
delete-employee          = لم يُفتح بعد
11-part assembly         = لم يبدأ
browser E2E               = لم يُعلن
```

## 10. سبب عدم إعلان main4 Closed

لأن المستخدم طلب صراحة أن ينفذ التعديل بنفسه.

لذلك حالة هذه الجلسة هي:

```text
main4 forensic review = COMPLETE
main4 source patch = NOT YET APPLIED
main4 verification = PENDING USER PATCH
main4 closure = OPEN
```

## 11. التجارب والتحقق

تم تنفيذ تحقق Production Read-only لعقود:

```text
company identity
app_settings
branches
roles
customers
items
stock_branches
RLS
active Edge contracts
```

لم يتم إنشاء بيانات دائمة للاختبار في Production ضمن مراجعة main4، ولم يتم الادعاء بوجود Browser Runtime PASS.

## 12. الخطوة التالية المعتمدة

بعد أن يطبق المستخدم جميع التعديلات الجراحية على `main4.md`:

```text
READ main4 TO EOF AGAIN
→ verify every requested replacement
→ compare against Production contracts again
→ record the new main4 blob/commit
→ only then proceed to fresh reconciliation
→ open delete-employee as a separate Closure Unit
```

## 13. Final Self-Audit

### WHAT I PROVED

- MASTER قرئ كاملًا.
- CURRENT_STATE قرئ كاملًا.
- Report72 قرئ كاملًا.
- main3 قرئ كاملًا ولم يظهر سبب لإعادة فتحه.
- main4 قرئ كاملًا حتى النهاية.
- Production الحالية تم فحصها مباشرة.
- branch code الحقيقي للفرع الرئيسي هو `BR-01`.
- currency الحالية هي `SAR`.
- `roles.company_id` موجود.
- `items.item_code` unique عالميًا.
- main4 يحتوي على نقاط company-scope غير مكتملة.
- main4 POS لا يطابق عقد `save-sales-invoice` الحالي في اسم الحقل والفرع.
- main4 TeleSales يحتوي fallback صامتًا عند فشل settings.

### WHAT I DID NOT PROVE

- Browser E2E بعد تطبيق التعديلات اليدوية.
- Runtime PASS لـmain4.
- Final 11-part assembly.
- Full PWA equivalence.
- delete-employee closure.
- roles RLS closure.

### FINAL STATUS

```text
MAIN3 = SOURCE VERIFIED / DO NOT REOPEN
MAIN4 = FORENSICALLY REVIEWED / SURGICAL PATCH SPEC READY / OPEN
DELETE-EMPLOYEE = NEXT INDEPENDENT CLOSURE AFTER FRESH RECONCILIATION
PROJECT = OPEN
```
