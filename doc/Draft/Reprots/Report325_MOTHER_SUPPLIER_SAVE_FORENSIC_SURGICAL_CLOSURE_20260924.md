# Report325 — تحقيق جنائي وإغلاق إصلاح الموردين في النظام الأم — 2026-09-24

## 1. نطاق التنفيذ
النطاق الوحيد في هذه الدورة:
- النظام الأم Mother: `erp-frontend/companies/company-1/main.html`
- تبويب الموردين `RW_Suppliers`
- زر/مودال `إضافة مورد جديد`
- خطأ Console:
  `POST /functions/v1/save-supplier 400`
- توليد كود المورد تلقائيًا
- التكامل مع صلاحيات النظام، الموردين، الشراء، المخزون، الحسابات، سجل التدقيق.

قيد الملكية:
- لم يتم تعديل `main.html` بواسطة المساعد.
- تم تنفيذ جميع إصلاحات Supabase/Production المتاحة مباشرة.
- تم إعداد Owner Surgical Patch دقيق لمالك المصدر.

---

## 2. قاعدة الحقيقة التي حُكمت بها الدورة
تمت إعادة قراءة:
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` حتى EOF.
- `CURRENT_STATE.md` حتى EOF.
- أحدث تقرير تنفيذي ذي صلة: Report324.
- Report322/323 عند الحاجة لفهم آخر تغييرات Mother.
- Current Source وProduction والـDeployments.
- سجل commits وparent commits.

المبدأ التنفيذي المعتمد:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

التقارير السابقة استخدمت كقرائن فقط، ولم تُعامل كحالة حالية.

---

## 3. Current Git — وقت بداية الإصلاح

### System Repository
- قبل إصلاح هذه الوحدة: `61b8097de250d9f504fe68fa2b5efc699f01fe74`
- Parent: `b0b2503a3f714d6c42c492b0a1ec4761fa8658be`

### Mother Frontend
Repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`5206405a07ba6a4317ceb2ef2b93072b24bf3dce`

Parent:
`45e40a1d703f802fe4198a790408ef44012d5cc0`

Current `main.html` blob:
`d76e6849b8d1c5a341b325eb9736bc76ffd7b18f`

آخر commit على main.html:
`45e40a1d703f802fe4198a790408ef44012d5cc0`

هذا الـcommit غيّر أجزاء Purchase فقط، ولم يغيّر `RW_Suppliers`.

---

## 4. Current Source — الموردون

الموضع الحالي المثبت:

`RW_Suppliers` يبدأ عند السطر 6871.

الدالة:
`openModal(code)`

تبدأ عند:
**السطر 6917**

العنصر المعيب في الواجهة:
**السطر 6926**

النص الحالي:
`value="${s?.supplier_code||'جديد'}"`

وهذا يعني أن المورد الجديد لا يحصل على Preview فعلي للكود التالي.

مسار الحفظ:
- السطر 6967: `supabase.auth.getSession()`
- السطر 6969: POST إلى `save-supplier`
- السطر 6972: يرسل `supplier_code: null` عند الإنشاء.

هذا السلوك الأخير صحيح معماريًا بعد الإصلاح، لأن Production أصبحت تولد الكود authoritative داخل RPC ولا تعتمد على Preview الواجهة.

---

## 5. Root Cause — سبب 400 المثبت

Production `save-supplier` Version 4 كانت تحتوي في `actor()`:

`select("id,company_id,status,is_owner,permissions")`

بينما `public.users` الحالية لا تحتوي عمود:
`is_owner`

Schema الحالي لـ`public.users` يثبت وجود:
- company_id
- status
- permissions
- auth_id
- role_id
- وغيرها

ولا يوجد:
`is_owner`

إذًا الطلب كان يفشل قبل تنفيذ INSERT للمورد، لذلك ظهر:
`HTTP 400`

وهذا هو السبب الجذري الحقيقي للخطأ، وليس:
- Supabase connectivity
- supplier payload
- supplier_code
- modal
- search
- database insert constraint.

---

## 6. Owner Semantics التي يجب الحفاظ عليها

Production الحالية تثبت أن Owner semantics ليست عمودًا داخل `users`.

التحقق الحالي:
- `auth.users.raw_user_meta_data.isOwner = true`
- `users.permissions` تحتوي `*`
- وجود سجل مطابق في `owner_profile`

والـ`app_private.current_user_has_permission()` الحالية تطبق هذا العقد.

لم يتم اختراع عمود `is_owner` جديد.

---

## 7. Production Repair المنفذ

لم يتم إنشاء Edge Function جديدة.

تم تحديث Edge Function القائمة:
`save-supplier`

من:
**Version 4**

إلى:
**Version 5**

وحالتها:
- ACTIVE
- verify_jwt = true

Version 5 أصبحت:
1. تتحقق من Authorization.
2. تستخرج المستخدم الحقيقي من Auth.
3. تجلب `users` عبر `auth_id`.
4. لا تعتمد على عمود غير موجود.
5. تستدعي RPC مركزيًا.
6. تعيد نتيجة RPC للمستخدم.

---

## 8. RPC مركزي جديد

تم إنشاء Production RPC:

`public.save_supplier_atomic`

Signature:
`(uuid, uuid, text, jsonb, boolean, text)`

المسؤوليات:
- التحقق من Auth User.
- التحقق من Company context.
- التحقق من Active status.
- التحقق من Owner/permissions.
- CREATE Supplier.
- UPDATE Supplier.
- توليد Supplier Code.
- حماية الترقيم من race condition.
- الحفاظ على `accounts_payable` كمعلومة مالية لا تُعدل من Master Data.

---

## 9. Supplier Code — التصميم الصحيح

قبل الإصلاح:
- modal يعرض `جديد`.
- Edge Version 4 كان يولد الكود بنفسه بطريقة غير ذرية.

بعد الإصلاح:
Production RPC تحسب:
`SUPP-${MAX_NUM+1}`

مع:
`pg_advisory_xact_lock('rawaea:supplier-code:<company>')`

وبالتالي:
- الكود authoritative في DB.
- لا يوجد duplicate بسبب concurrent create.
- unique constraint الحالية `(company_id,supplier_code)` تبقى حارسًا نهائيًا.

Current Production:
- suppliers = 0
- max supplier_code = NULL

إذًا Preview الصحيح للمورد الجديد الآن:
**SUPP-1001**

والإنشاء الفعلي في Production سيولد نفس الكود.

---

## 10. لماذا لم نجعل UI هو مصدر الكود

واجهة Mother يجب أن تعرض Preview فقط.

المصدر الحقيقي للكود هو Production RPC.

لأن:
- مستخدمين قد يفتحان المودال في نفس اللحظة.
- كلاهما قد يرى نفس Preview.
- الرقم النهائي يجب أن يحدده transaction مركزي واحد.

لذلك:
UI Preview ≠ authoritative identity.

Production DB = authoritative identity.

---

## 11. Data / Financial Safety

Master Supplier CREATE لا ينفذ:
- stock movement
- stock_branches mutation
- inventory_log movement
- supplier_ledger posting
- journal posting

ويتم إنشاء سجل التدقيق عبر:
`trg_audit_suppliers`
→ `fn_audit_trigger()`

أما `accounts_payable`:
- عند CREATE = 0
- عند UPDATE يتم الحفاظ على الرصيد السابق.
- لا يمكن تعديل الرصيد المالي من بيانات المورد الأساسية.

وهذا يحافظ على فصل:
Supplier Master
عن
Supplier Financial Transactions.

---

## 12. Production E2E — Supplier Master

تم تنفيذ Transaction اختبارية كاملة ثم ROLLBACK.

الاختبار شمل:
- CREATE Supplier.
- توليد كود أول.
- CREATE Supplier ثانٍ.
- توليد الكود التالي.
- UPDATE Supplier.
- محاولة تغيير `accounts_payable` من الـMaster Data.
- التحقق من بقاء الرصيد المالي الحقيقي.
- التحقق من عدم حدوث حركة مخزون أو قيد محاسبي مستقل.

نتيجة الاختبار:
- transaction اكتملت بدون SQL failure.
- داخل الاختبار ظهر سجلان مؤقتان للموردين.
- بعد ROLLBACK عاد Production إلى الحالة السابقة.

---

## 13. Authorization E2E

تم اختبار مستخدم غير مالك وغير حاصل على `suppliers`:

`vansales@rawaea.com`

والنتيجة:
رفض العملية:

`لا تملك صلاحية تنفيذ هذه العملية`

الرفض حدث داخل:
`save_supplier_atomic`

وليس مجرد اعتماد على UI.

---

## 14. Purchase Integration E2E

لإثبات أن Supplier Master ليس جزيرة منفصلة، تم تنفيذ Transaction اختبارية متكاملة:

Supplier CREATE
→ Purchase Invoice CREATE
→ Purchase Invoice POST
→ Physical Stock Movement
→ Supplier Ledger
→ Journal

مع:
- Supplier جديد مؤقت.
- Item = `1001`
- Branch = `BR-01`
- Qty = 3
- Unit Price = 100
- Supplier Invoice Reference = `QA-SUPP-INV-20260924`
- Operation ID = `QA-SUPPLIER-PURCHASE-20260924`

ثم تم:
- تنفيذ POST.
- تنفيذ POST مرة ثانية.
- التحقق من عدم إنشاء حركة ثانية.
- التحقق من `inventory_log`.
- إنهاء الاختبار بـROLLBACK.

الـtransaction نفذت بدون SQL failure، والنتيجة النهائية القابلة للقياس:
`movement_count = 1`

بعد ROLLBACK:
- suppliers = 0
- purchase_invoices = 0
- purchase_orders = 0
- inventory_log = 6
- stock_branches = 48
- supplier_ledger = 0
- journal_entries = 8

إذًا لم تُلوث بيانات Production.

---

## 15. Current Production Snapshot بعد الاختبار

- suppliers = 0
- max_supplier_code = NULL
- purchase_invoices = 0
- purchase_orders = 0
- inventory_log = 6
- stock_branches = 48
- supplier_ledger = 0
- journal_entries = 8

Production لم تُترك ببيانات QA دائمة.

---

## 16. Audit

Current `suppliers` triggers:
`trg_audit_suppliers`

على:
- INSERT
- UPDATE
- DELETE

وتستدعي:
`fn_audit_trigger()`

المسار محفوظ ولم يُعاد بناؤه.

لم يتم تعطيل Audit Guard.

---

## 17. No Table Expansion

لم يثبت في التحقيق وجود نقص Schema يجب أن نضيف بسببه جدولًا جديدًا الآن.

لذلك:
**No new table**

**No new column**

**No new Edge Function**

التغيير Production كان:
- Existing Edge Function updated.
- Existing database architecture extended بـRPC authoritative.

---

## 18. Competitive Gap Review — Supplier Master

### Odoo
Odoo 19 يوثق Vendor Pricelists كبيانات تربط المورد بالمنتج، ما يوضح أهمية فصل شروط شراء المورد عن مجرد بيانات الاتصال.

المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/purchase/products/pricelist.html

### Microsoft Dynamics 365 Business Central
Vendor data تشمل حقولًا مثل:
- Vendor Posting Group
- Currency Code
- Payment Terms Code
- telephone
وذلك بجانب الحسابات والإعدادات المالية ذات الصلة.

المصادر:
https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/table/microsoft.purchases.vendor.vendor-templ/
https://learn.microsoft.com/en-us/dynamics365/business-central/finance-payment-terms

### SAP
Supplier Master / Business Partner يحتفظ ببيانات:
- الاسم والعنوان والاتصال
- بيانات البنك
- البيانات الضريبية
- Billing preferences
- Payment Terms
- Incoterms
- Purchasing Organization
- Supplier ABC Classification

المصادر:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/cb9131e59ba34741923bd19ef4cb1f90/3ca4b04268604fb5b657854b2477cba1.html
https://help.sap.com/docs/SAP_Cloud_Platform_Master_Data_for_Business_Partners/baa3bb2e1c3e45b7a55bcc326922471a/1514eeea5025457fb4950455e86990ba.html

### Daftra
Daftra توثق في Supplier Master حقولًا مثل:
- اسم النشاط
- ممثل الشركة
- الهاتف والموبايل
- العنوان
- الدولة
- السجل التجاري
- VAT Number
- عناوين إضافية
- جهات اتصال متعددة
- Supplier Number auto sequence
- Currency
- Opening Balance
- Opening Balance Date
- Email
- Notes

المصدر:
https://docs.daftra.com/en/tutorial/adding-a-new-supplier/

كما أن Daftra تدعم Custom Fields مرتبطة بكيانات أخرى، بما فيها supplier-related forms.

المصدر:
https://docs.daftra.com/en/user_manual/suppliers-custom-fields/

### Manager.io
Manager يوثق:
- Name
- Code
- Credit Limit
- Currency
- Address
- Email
- Division
- Control Account
- Starting Balance

كما يتيح Custom Fields للموردين.

المصادر:
https://www2.manager.io/guides/7020
https://www2.manager.io/guides/9470
https://www2.manager.io/manager.pdf

---

## 19. Competitive Backlog — لا يُنفذ الآن

الحقول التي تستحق Contract Study مستقبلية:
1. Email
2. Commercial Registration
3. VAT / Tax ID
4. Currency
5. Credit Limit
6. Payment Terms in days
7. Default Due-Date Rule
8. Bank Account(s)
9. Supplier Category / ABC
10. Purchasing Group
11. Default AP Control Account
12. Multiple Contacts
13. Supplier-specific Item Pricing / Pricelist
14. Attachments / Supplier Documents
15. Purchasing Block / Operational Status Reason
16. Default Purchasing Scope / Branches
17. Supplier Performance KPI

هذه ليست أعطالًا في هذه الدورة، ولا يجوز إضافتها عشوائيًا قبل تثبيت Business Contract وSchema ownership.

---

## 20. Owner Surgical Patch — Mother main.html

### الملف
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

### Current SHA
`d76e6849b8d1c5a341b325eb9736bc76ffd7b18f`

### العنصر المعيب
`RW_Suppliers.openModal(code)`

### السطر
**6926**

### ابحث عن هذا النص حرفيًا واحذفه:
`<div class="flex flex-col"><label>كود المورد</label><input id="supp-code" value="${s?.supplier_code||'جديد'}" readonly class="p-2.5 bg-gray-100 border rounded-lg"></div>`

### واستبدله حرفيًا بهذا العنصر:
`<div class="flex flex-col"><label>كود المورد</label><input id="supp-code" value="${s?.supplier_code || ('SUPP-' + (data.reduce(function(max, x) { var m = String(x?.supplier_code || '').trim().match(/^SUPP-(\\d+)$/i); return m ? Math.max(max, Number(m[1])) : max; }, 1000) + 1))}" readonly class="p-2.5 bg-gray-100 border rounded-lg"></div>`

### وظيفة الجراحة
- تعديل Preview فقط.
- Edit يحتفظ بكوده الحالي.
- New يعرض آخر رقم + 1.
- الكود النهائي لا يعتمد على الواجهة؛ Production RPC هي المصدر النهائي.
- لا تعديل لـ`_handleSave`.
- لا تعديل لـ`openModal` بالكامل.
- لا تعديل لأجزاء الحساب أو المخزون.
- لا إعادة كتابة `RW_Suppliers`.

---

## 21. العناصر التي ثبت عدم الحاجة لتعديلها

لا تعدّل:
- `RW_Suppliers._handleSave`
- `RW_Suppliers.render()`
- `RW_Suppliers.renderTable()`
- `RW_Audit_log`
- `main.html` بالكامل
- `purchase_create_invoice_atomic_v2`
- `purchase_post_invoice_atomic`
- `stock_branches`
- `inventory_log`
- `supplier_ledger`
- `journal_entries`

لأن هذه الأجزاء ليست سبب العطل الحالي.

---

## 22. Static Source Verification

تم تطبيق Owner Patch في الذاكرة فقط على Current \`main.html\` blob دون الكتابة إلى المستودع، ثم تم فحص الناتج باستخدام JavaScript parser داخل بيئة التنفيذ.

النتيجة:
- exact defective element occurrences = 1
- exact replacement occurrences = 1
- inline script blocks = 6
- parse = PASS
- main.html repository remained untouched.

## 23. Browser E2E Status

Production DB/RPC E2E:
**VERIFIED**

Production authorization:
**VERIFIED**

Production deployment:
**VERIFIED**

Current Source surgical target:
**VERIFIED**

Authenticated Browser E2E على الـpublished artifact:
**OPEN / UNVERIFIED**

السبب:
لا توجد في هذه الدورة أداة Browser-authenticated تسمح بتسجيل دخول حقيقي وتشغيل المودال على artifact المنشور.

لذلك لم يتم تحويل:
- DB E2E
- RPC E2E
- source verification

إلى ادعاء Browser E2E.

---

## 24. Production/Git Alignment

Production:
- save-supplier Version 5

Git canonical:
- `Current/Edge_Functions/save-supplier`
- migration:
  `supabase/migrations/20260924_save_supplier_atomic_fix.sql`

System repo current HEAD بعد مزامنة Production:
`2bfdf840a4fb5b0644c22e788bd889323b294066`

Parent:
`2398a518c19f41422f1b80d5352ec243adc034d1`

Parent of save-supplier source commit:
`61b8097de250d9f504fe68fa2b5efc699f01fe74`

---

## 25. Closure Matrix

| Boundary | Status |
|---|---|
| Historical context | VERIFIED |
| Current Git | VERIFIED |
| Current Mother Source | VERIFIED |
| Current Production Edge | VERIFIED |
| Current DB schema | VERIFIED |
| Root Cause | PROVEN |
| Existing Edge reused | YES |
| New Edge Function | NO |
| RPC authority | VERIFIED |
| Supplier code generation | VERIFIED |
| Concurrency guard | IMPLEMENTED |
| Owner semantics | VERIFIED |
| Authorization | VERIFIED |
| Supplier master audit | VERIFIED |
| Purchase integration | E2E VERIFIED |
| Inventory integration | E2E VERIFIED |
| Accounting integration | E2E VERIFIED |
| Data residue | NONE |
| Main.html assistant write | NO |
| Owner surgical patch | READY |
| Published artifact identity | OPEN |
| Authenticated Browser E2E | OPEN |

### الحالة
**SUPPLIER SAVE / CODE GENERATION PRODUCTION CORE = PRODUCTION VERIFIED**

**MOTHER UI CLOSURE = PARTIALLY CLOSED**

والسبب الوحيد المتبقي لإغلاق الواجهة هو تطبيق Owner Surgical Patch ثم نشره وتشغيل Browser E2E.

---

## 26. تعليمات الاستكمال للمساعد التالي

لا تبدأ من الصفر.

ابدأ بالترتيب:
1. تحقق من System HEAD `2bfdf840a4fb5b0644c22e788bd889323b294066`.
2. تحقق من save-supplier Version 5 في Production.
3. تحقق من RPC `save_supplier_atomic`.
4. تحقق من Mother HEAD `5206405a07ba6a4317ceb2ef2b93072b24bf3dce`.
5. تحقق من main.html blob `d76e6849b8d1c5a341b325eb9736bc76ffd7b18f`.
6. لا تعِد إصلاح `save-supplier`.
7. لا تعِد فحص/إصلاح Purchase backend إلا مع evidence contradictory.
8. طبّق فقط عنصر السطر 6926 في Owner Surgical Patch.
9. Parse كامل `main.html`.
10. Publish.
11. Verify served artifact identity.
12. Login جديد.
13. Mother → الموردين.
14. مورد جديد.
15. تحقق من Preview = `SUPP-1001`.
16. Save.
17. تحقق من Network 200.
18. تحقق من supplier row.
19. تحقق من Audit.
20. Edit supplier.
21. تحقق من عدم تعديل `accounts_payable` من Master Data.
22. تحقق من refresh.
23. التقط Production snapshot في نفس لحظة التقرير.
24. حدّث `CURRENT_STATE.md`.

---

## 27. Final Self-Audit

### What was proved
- سبب 400 الحقيقي.
- عدم وجود `is_owner` في `users`.
- Production Version 5.
- RPC authoritative.
- Supplier code sequential logic.
- Concurrency lock.
- Authorization rejection.
- Purchase/Stock/Accounting integration transaction.
- Rollback cleanliness.
- Main.html exact defect location.

### What was fixed
- Production `save-supplier`.
- Production supplier-save authority.
- Production code generation.
- Production/Git alignment.

### What was NOT modified
- `main.html`
- Purchase engine
- Inventory engine
- Accounting engine
- Supplier audit trigger
- Tables

### What remains
- Owner applies one-line surgical UI patch.
- Published artifact verification.
- Authenticated Browser E2E.

### Initial missed point during this cycle
The first diagnosis considered UI code preview and backend failure as one issue. The forensic split proved أن:
1. HTTP 400 = backend schema drift.
2. "جديد" in modal = separate UI completion gap.

They therefore require two different layers of repair.

### Final classification
**Production backend supplier capability: CLOSED / VERIFIED**

**Mother supplier UI: PARTIALLY CLOSED pending owner patch + Browser E2E**

# END OF REPORT325
