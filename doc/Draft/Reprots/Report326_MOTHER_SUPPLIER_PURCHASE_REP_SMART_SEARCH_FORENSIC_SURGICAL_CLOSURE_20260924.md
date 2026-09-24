# Report326 — التحقيق الجنائي والإغلاق الجراحي لمسؤول المشتريات في تبويب الموردين
## RAWAEA ERP — Mother Main → Suppliers → New Supplier → مسؤول المشتريات
## التاريخ: 2026-09-24

---

## 1. نطاق Closure Unit

النطاق الوحيد في هذه الدورة:

Mother ERP
→ تبويب الموردين
→ إضافة/تعديل مورد
→ حقل «مسؤول المشتريات»
→ Smart Search
→ حفظ المورد
→ تكامل الصلاحيات وTenant
→ التكامل مع Purchase / Stock / Accounting
→ توثيق وإعادة ضبط الحالة.

هذه الدورة لا تعيد فتح إصلاحات Supplier Save السابقة، ولا تعيد بناء Purchase أو Inventory أو Accounting.

---

## 2. قاعدة الحقيقة

تم تطبيق قاعدة:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

التقارير التاريخية استُخدمت كقرائن فقط ثم أُعيدت مطابقة الادعاءات المهمة مع الحالة الحالية.

لا يوجد تعديل مساعد على ملف:
`erp-frontend/companies/company-1/main.html`

ملكية تعديل `main.html` تبقى للمالك.

---

## 3. التاريخ المباشر لهذه النقطة

### 3.1 Supplier Code Preview السابق

العيب السابق في كود المورد كان في نفس مودال المورد، وتم تطبيقه فعليًا بواسطة المالك في:

Mother commit:
`3520240a57f2124bbcf96c3007f67a9c36890fcb`

Commit message:
`Update supplier code input logic in main.html`

التغيير كان محصورًا في حقل كود المورد، ونقل العرض من:
`جديد`

إلى Preview من:
`SUPP-(آخر رقم + 1)`

هذا الإصلاح لم يعد ضمن نطاق هذه الدورة لأنه ثبت في المصدر الحالي.

### 3.2 Current Mother source

Current repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`897d40c47b27544fb8a5515a7f7dcce528c4563e`

الـHEAD الأخير قبل هذه الوثيقة كان Commit توثيقيًا:
`forensic: persist current Mother HR extract`

ولم يعدل `main.html`.

Current `main.html` blob:
`f4e707060a3f0ff68b993bf57616e4e861ac54e6`

عدد الأسطر الحالي:
`32068`

---

## 4. موضع العيب الحالي

Module:
`RW_Suppliers`

Function:
`openModal(code)`

Current line:
**6935**

العنصر الحالي المعيب حرفيًا:

```html
<div class="flex flex-col"><label>مسؤول المشتريات</label><input id="supp-rep" value="${s?.purchase_rep||''}" class="p-2.5 bg-gray-50 border rounded-lg"></div>
```

هذا الحقل كان Text Input عاديًا.

ولا توجد فيه:
- Smart Search.
- قائمة نتائج.
- هوية مندوب اختيارية.
- مصدر Server-side متخصص.
- حماية تمنع إدخال اسم غير موجود.

---

## 5. Root Cause — السبب المثبت

### 5.1 Frontend

الحقل `supp-rep` كان مجرد Input نصي.

وبالتالي لا توجد عملية بحث حقيقية داخل دليل موظفي المشتريات.

### 5.2 Database / RLS

`suppliers.purchase_rep` هو حقل نصي قائم في Schema الحالي.

لا يوجد:
`purchase_rep_id`

ولا يوجد FK حالي يربط المورد مباشرة بمستخدم المشتريات.

لذلك لا يجوز اختراع علاقة جديدة في هذه الدورة لمجرد تنفيذ Smart Search.

### 5.3 Authorization boundary

المستخدمون في `public.users` محميون بسياسات RLS.

سياسة القراءة العامة لا تتيح لأي مستخدم يملك صلاحية الموردين أن يقرأ كل المستخدمين؛ القراءة تتطلب صلاحية `users` أو تكون للصف الخاص بالمستخدم نفسه.

لذلك الاعتماد على:

```
supabase.from('users').select(...)
```

من واجهة Supplier Master ليس حلًا صالحًا لكل أدوار الموردين.

النتيجة:

Smart Search يجب أن يمر عبر RPC مصادق عليه يطبق Tenant + Permission داخليًا.

---

## 6. الهوية الصحيحة لمندوب المشتريات

Production الحالية تثبت وجود:

Role Master:
`مسئول مشتريات`

واللفظ المعتمد في Role Master هو:
**مسئول مشتريات**

وليس:
**مسؤول مشتريات**

هذا الفرق مهم جدًا؛ لأنه تم إثباته من بيانات Production نفسها.

المستخدم النشط الحالي:

- name: مندوب مشتريات 1
- email: buyer1@rawaea.com
- role: مسئول مشتريات
- role_id: `b1489a50-a198-4030-8ce2-bae3e98bc6e1`
- permissions: [`purchases`, `suppliers`]
- status: Active
- company_id: `00000000-0000-0000-0000-000000000001`

عدد مندوبي المشتريات النشطين في الشركة الحالية:
**1**

---

## 7. لماذا لم نستخدم users.role كنص

لأن النظام الحالي يحتوي Role Master:

`roles.role_name`

والعلاقة:

`users.role_id → roles.id`

لذلك الـSearch الصحيح يعتمد على Role Master وليس على تسمية نصية قد تنحرف في المستقبل.

العقد الحالي:

users
→ role_id
→ roles
→ role_name = «مسئول مشتريات»

---

# 8. Production الحل

لم يتم إنشاء Edge Function جديدة.

لم يتم تعديل عدد الـEdge Functions.

تم إنشاء/تثبيت RPC مصادق عليه:

`public.get_supplier_purchase_reps(text)`

### Signature

```
get_supplier_purchase_reps(p_query text DEFAULT NULL)
```

### Security

- SECURITY DEFINER
- `auth.uid()` مطلوب.
- Permission `suppliers` مطلوب.
- Company context يُشتق من المستخدم الحالي.
- القراءة محصورة على نفس الشركة.
- المستخدم يجب أن يكون Active.
- Role Master يجب أن يكون `مسئول مشتريات`.
- Anonymous execution = REVOKED.
- Authenticated execution = GRANTED.

### نتيجة البحث

يعيد:

- id
- name
- email
- phone
- employee_id
- role_name

### Search behavior

البحث يدعم عدة كلمات.

مصدر المطابقة:

- name
- email
- phone
- employee_id

ويتم ترتيب تطابق بداية الاسم أولًا.

الحد:
25 نتيجة.

---

## 9. لماذا RPC وليس Edge Function

لأن المشكلة Read Capability وليست Business Transaction مستقلة.

لا نحتاج Gateway جديد.

الـRPC يحقق:

Authenticated
→ Permission
→ Tenant
→ Role
→ Search
→ Result

ثم يعود مباشرة للـMother UI.

وهذا يتوافق مع حد المشروع الحالي على عدد الـEdge Functions.

---

## 10. Production Save Hardening

تم تشديد:

`public.save_supplier_atomic(...)`

عند CREATE:

إذا كان `purchase_rep` موجودًا:

1. يبحث داخل نفس الشركة.
2. المستخدم Active.
3. Role Master = `مسئول مشتريات`.
4. المطابقة بالاسم أو البريد.
5. يحفظ الاسم المعياري:
   `users.name`.
6. أي قيمة غير صالحة تُرفض.

الرسالة:

`مسؤول المشتريات المحدد غير صالح أو غير نشط`

عند UPDATE:

نفس التحقق مع الحفاظ على قيمة صحيحة تاريخية إذا لم يغيّرها المستخدم.

---

## 11. لماذا الحفظ يستقبل الاسم ولا يستقبل ID

لأن Schema الحالي يملك:

`suppliers.purchase_rep varchar`

وليس:

`purchase_rep_id uuid`

إضافة FK جديدة الآن ستغير Business Contract وSchema ownership.

هذا لم يُثبت كضرورة لهذه المشكلة.

لذلك:

UI Search
→ يختار اسمًا معياريًا
→ save-supplier
→ save_supplier_atomic
→ validates the current active Role Master
→ stores canonical name.

أي أن الإدخال الحر لا يصبح Trusted Data بمجرد انتقاله من الواجهة.

---

# 12. Owner Surgical Patch — المطلوب في main.html

## الملف

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Current blob:
`f4e707060a3f0ff68b993bf57616e4e861ac54e6`

## الدالة

`RW_Suppliers.openModal(code)`

## الموضع

**السطر 6935 الحالي**

## ابحث عن هذا العنصر حرفيًا واحذفه:

```html
<div class="flex flex-col"><label>مسؤول المشتريات</label><input id="supp-rep" value="${s?.purchase_rep||''}" class="p-2.5 bg-gray-50 border rounded-lg"></div>
```

## واستبدله حرفيًا بالعنصر التالي كاملًا:

```html
<div class="flex flex-col">
<label>مسؤول المشتريات</label>
<div class="relative">
<input id="supp-rep" type="text" value="${s?.purchase_rep||''}" autocomplete="off" spellcheck="false" placeholder="ابحث بالاسم أو البريد أو الهاتف" aria-autocomplete="list" aria-controls="supp-rep-results" class="p-2.5 bg-gray-50 border rounded-lg" onfocus="(function(el){if(el.dataset.rwRepBound==='1')return;el.dataset.rwRepBound='1';var box=document.getElementById('supp-rep-results');if(!box)return;var seq=0;var hide=function(){box.style.display='none';while(box.firstChild)box.removeChild(box.firstChild);};var message=function(t,c){while(box.firstChild)box.removeChild(box.firstChild);var d=document.createElement('div');d.className='px-3 py-2 text-sm '+(c||'text-slate-500');d.textContent=t;box.appendChild(d);box.style.display='block';};var render=function(rows){while(box.firstChild)box.removeChild(box.firstChild);if(!rows.length){message('لا يوجد مندوب مشتريات مطابق.','text-slate-500');return;}rows.forEach(function(row){var b=document.createElement('button');b.type='button';b.className='w-full text-right px-3 py-2.5 hover:bg-orange-50 border-b border-slate-100 last:border-b-0';b.setAttribute('data-purchase-rep-name',row.name||'');b.setAttribute('data-purchase-rep-email',row.email||'');b.setAttribute('role','option');var n=document.createElement('div');n.className='font-bold text-slate-800';n.textContent=row.name||row.email||'';var m=document.createElement('div');m.className='text-xs text-slate-500 mt-0.5';m.textContent=(row.email||'')+(row.phone?' • '+row.phone:'');b.appendChild(n);b.appendChild(m);box.appendChild(b);});box.style.display='block';};var run=function(){clearTimeout(el._rwRepTimer);var q=String(el.value||'').trim();delete el.dataset.purchaseRepEmail;seq++;var current=seq;if(!q)message('مندوبو المشتريات النشطون في الشركة.');else message('جاري البحث عن مندوبي المشتريات...','text-slate-500');el._rwRepTimer=setTimeout(function(){supabase.rpc('get_supplier_purchase_reps',{p_query:q||null}).then(function(r){if(current!==seq)return;if(r.error)throw r.error;render(r.data||[]);}).catch(function(err){if(current!==seq)return;message('تعذر تحميل مندوبي المشتريات: '+(err.message||'خطأ'),'text-rose-600');});},180);};el.addEventListener('input',run);el.addEventListener('keydown',function(ev){if(ev.key==='Escape')hide();});el.addEventListener('blur',function(){setTimeout(hide,120);});box.addEventListener('mousedown',function(ev){var b=ev.target.closest?ev.target.closest('button[data-purchase-rep-name]'):null;if(!b)return;ev.preventDefault();el.value=b.getAttribute('data-purchase-rep-name')||'';el.dataset.purchaseRepEmail=b.getAttribute('data-purchase-rep-email')||'';hide();});run();})(this)">
<div id="supp-rep-results" role="listbox" class="absolute right-0 left-0 top-full mt-1 hidden max-h-64 overflow-y-auto bg-white border border-slate-200 rounded-xl shadow-xl z-[1300]"></div>
</div>
<p class="text-xs text-gray-500 mt-1">اكتب اسم أو بريد أو هاتف مندوب المشتريات، ثم اختره من النتائج.</p>
</div>
```

---

# 13. وظيفة الجراحة

الجراحة تضيف فقط:

- Input ذكي.
- Debounce = 180ms.
- Server-side RPC lookup.
- Multi-token search.
- Stale response protection.
- Dropdown.
- Name + email + phone.
- اختيار canonical name.
- Escape.
- Blur.
- Preservation of existing edit value.

ولا تعدّل:

`RW_Suppliers._handleSave`

لأن:

```
purchase_rep: byId('supp-rep').value.trim()
```

ما زال صحيحًا بعد الجراحة.

---

# 14. لماذا لا نضيف purchase_rep_id الآن

تمت مراجعة الأنظمة التنافسية.

## Microsoft Dynamics 365 Business Central

الـVendor Master يستخدم مفهوم `Purchaser Code` لتحديد المشتري المسؤول عن المورد.

المراجع الرسمية:
https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/table/microsoft.purchases.vendor.vendor-templ/

https://learn.microsoft.com/en-us/dynamics365/business-central/finance-payment-terms

## SAP

الشراء يعتمد على Purchasing Group / Buyer concepts ضمن Supplier Purchasing Organization.

المراجع:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/cb9131e59ba34741923bd19ef4cb1f90/3ca4b04268604fb5b657854b2477cba1.html

https://help.sap.com/docs/SAP_S4HANA_CLOUD

## Odoo

Vendor Pricelist يربط المورد بالمنتج وشروط الشراء.

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/purchase/products/pricelist.html

## Daftra

Supplier Master يتضمن ممثل الشركة ووسائل الاتصال وبيانات قانونية ومالية وCustom Fields.

https://docs.daftra.com/en/tutorial/adding-a-new-supplier/

## Manager.io

Supplier Master يدعم Code وCustom Fields وبيانات مالية وتشغيلية.

https://www2.manager.io/guides/7020

الاستنتاج الهندسي:

Smart Search الحالي = إصلاح UX + Data Integrity.

المرحلة التنافسية الأعمق لاحقًا تستحق دراسة Business Contract مستقل لتثبيت:

- purchaser_id / purchaser code
- purchasing group
- supplier-item pricelist
- lead time
- payment terms
- credit limit
- tax / CR identifiers
- bank accounts
- contacts
- supplier classification
- purchasing block/status
- supplier performance.

هذه ليست ضمن هذا Emergency Closure.

---

# 15. Production / Inventory / Accounting Flow

## Supplier Master

CREATE / UPDATE Supplier

لا ينفذ:

- stock movement
- stock_branches mutation
- inventory_log posting
- supplier_ledger posting
- journal entry posting.

إذًا اختيار مسؤول المشتريات لا يغير رصيد الفرع أو الحسابات.

## Purchase Cycle

عند إنشاء Purchase Invoice ثم POST:

Purchase Invoice
→ purchase_post_invoice_atomic
→ post_stock_movement
→ stock_branches
+
inventory_log
→ Journal
→ Supplier Ledger.

هذه المسؤوليات بقيت كما هي.

---

# 16. E2E — Smart Search

## Search RPC

تم الاختبار تحت authenticated company context باستخدام مستخدم المشتريات الحالي.

### Blank search

النتيجة:
- exactly 1 active purchasing representative
- name = مندوب مشتريات 1
- email = buyer1@rawaea.com
- role_name = مسئول مشتريات.

### Search = buyer1

النتيجة:
- exactly 1 row
- email = buyer1@rawaea.com.

### Arabic multi-token search

تم البحث بعبارة عربية تخص مندوب المشتريات.

النتيجة:
- exact current buyer row returned.

### Unauthorized

تم تشغيل RPC تحت:

`vansales@rawaea.com`

والنتيجة:

`لا تملك صلاحية الوصول إلى مندوبي المشتريات`

إذن الحماية داخل DB وليست UI-only.

---

# 17. E2E — Supplier Save

تم تنفيذ:

Supplier CREATE
+
purchase_rep = `buyer1@rawaea.com`

داخل Transaction مؤقتة.

النتيجة:

```
success = true
action = created
supplier_code = SUPP-1003
```

كما تم اختبار:

purchase_rep = `مندوب مشتريات 1`

والإنشاء نجح.

كما تم اختبار قيمة غير صحيحة:

`not-a-buyer`

والنتيجة:

`مسؤول المشتريات المحدد غير صالح أو غير نشط`

---

# 18. E2E — Supplier → Purchase → Stock → Accounting

تم تنفيذ Transaction مؤقتة:

Supplier CREATE
→ Purchase Invoice CREATE
→ Purchase Invoice POST
→ Physical Stock
→ Inventory Log
→ Supplier Ledger
→ Journal
→ POST Replay.

المستخدم:
مندوب المشتريات الحالي.

الصنف:
`1001`

الفرع:
`BR-01`

الكمية:
1

سعر الوحدة:
10

## القياسات

### قبل

- stock item 1001 = 2
- inventory_log = 6
- supplier_ledger = 0
- journal_entries = 8
- journal_lines = 12

### بعد POST

- stock item 1001 = 3
- inventory_log = 7
- supplier_ledger = 1
- journal_entries = 9
- journal_lines = 14

Deltas:

- stock = +1
- inventory_log = +1
- supplier_ledger = +1
- journal_entries = +1
- journal_lines = +2

إعادة POST:

`duplicate = true`

ولم تتولد حركة ثانية.

بعد ذلك:

ROLLBACK

وعادت Production إلى:

- suppliers = 2
- purchase_invoices = 0
- inventory_log = 6
- supplier_ledger = 0
- journal_entries = 8
- main stock item 1001 = 2

أي:
**لا يوجد QA residue.**

---

# 19. Audit

Supplier audit architecture لم تُعدّل.

Current trigger:

`trg_audit_suppliers`

على:

- INSERT
- UPDATE
- DELETE

ويستدعي:

`fn_audit_trigger()`

Smart Search نفسه Read-only ولا ينشئ audit row.

Supplier Save يظل داخل نفس Audit architecture السابقة.

---

# 20. Schema Safety

لم تتم إضافة:

- table جديدة.
- column جديدة.
- FK جديدة.
- Edge Function جديدة.

تم فقط:

1. إضافة/تثبيت RPC Read capability.
2. تشديد Existing Supplier Save validation.
3. Owner surgical UI patch جاهز.

---

# 21. Duplicate RPC Forensics

تم فحص Production الحالية بعد migrations السابقة.

كان هناك تاريخ قريب لإنشاء:

`supplier_purchase_rep_search(text)`

ثم تم إنهاؤه رسميًا بواسطة migration:

`20260924083623_remove_duplicate_supplier_rep_search_rpc`

Current Production function inventory الآن يثبت:

`public.get_supplier_purchase_reps(text)`

كـRPC البحث الحالي.

لا يوجد الآن RPC آخر مماثل باسم:
`supplier_purchase_rep_search`

ولا يوجد تكرار ينبغي إزالته.

---

# 22. Migration / Production Records

Canonical migration:

`supabase/migrations/20260924_supplier_purchase_rep_search_hardening.sql`

System Git commit:

`85ad9d2b1a195e5b8845a6550beec5fd85fdfc41`

Parent:

`9f9b3fd27aa9d4a57cf3453aea7833ab42b9b900`

Database migration sequence confirms the change is registered in Production.

---

# 23. Current Production Snapshot — وقت التقرير

Company:
`00000000-0000-0000-0000-000000000001`

- suppliers = 2
- purchase_invoices = 0
- inventory_log = 6
- supplier_ledger = 0
- journal_entries = 8
- BR-01 item 1001 qty = 2
- active purchase-rep count = 1

No persistent QA entity was created by this closure.

---

# 24. Static Source Verification

The current `main.html` blob:

`f4e707060a3f0ff68b993bf57616e4e861ac54e6`

تم تطبيق الجراحة في الذاكرة فقط.

النتيجة:

- exact target element occurrences = 1
- replacement present = YES
- full current source line count = 32068
- current inline script blocks inspected = 2
- JavaScript compilation = PASS
- repository main.html write = NO

المساعد لم يكتب `main.html`.

---

# 25. Browser E2E

الحالة:

**OPEN / UNVERIFIED**

السبب:

لا توجد في هذه الجلسة أداة Browser Authenticated Runtime تمكن من:

- Login حقيقي.
- فتح Published Mother artifact.
- فتح Supplier tab.
- فتح New Supplier modal.
- اختبار typing داخل browser.
- التقاط Network/Console.
- إثبات published artifact identity.

لذلك:

DB/RPC E2E = VERIFIED

Source static verification = VERIFIED

Production integration E2E = VERIFIED

Authenticated Browser E2E = NOT PROVEN

ولا يجوز تحويل نتيجة DB إلى Browser PASS.

---

# 26. ما لم نعدله

لا تعدّل:

- `RW_Suppliers._handleSave`
- `RW_Suppliers.renderTable`
- `RW_Suppliers.render`
- `RW_Audit_log`
- Supplier Code Preview
- Purchase Invoice backend
- Inventory Core
- Accounting Core
- stock_branches
- inventory_log
- supplier_ledger
- journal_entries
- save-supplier Edge Function v5.

هذه الأجزاء مثبت أنها ليست سبب المشكلة الحالية.

---

# 27. Competitive Completion — Current Gap

بعد إصلاح Smart Search، Supplier Master ما زال لديه مساحة تطوير تنافسية موثقة، لكن لا يجوز خلطها مع Bug Closure.

## Backlog مرشح لBusiness Contract مستقل

### Identity

- Supplier Type
- Supplier Code
- Tax/CR IDs
- Supplier Status
- Multiple Contacts.

### Purchasing

- Purchasing Group
- Responsible Purchaser Code / ID
- Supplier Item Pricelist
- Lead Time
- Minimum Order Quantity
- Last Purchase Price
- Contract Price
- Effective Date.

### Financial

- Currency
- Payment Terms
- Credit Limit
- Due Days
- AP Control Account
- Bank Accounts.

### Governance

- Purchasing Block
- Compliance Status
- Documents
- Expiry dates
- Performance KPI.

لا يتم تنفيذ هذه القائمة الآن.

---

# 28. Self-Audit

## What was proved

- Current Mother source.
- Current Mother HEAD.
- Previous supplier-code fix commit.
- Exact current defective element.
- Schema contract for purchase_rep.
- Role Master spelling.
- Active purchasing representative.
- RLS reason a direct users query is not a safe universal UI solution.
- Authenticated RPC search.
- Tenant scope.
- Permission guard.
- Save validation.
- Invalid rep rejection.
- Supplier-to-purchase integration.
- Stock effect.
- Supplier ledger effect.
- Journal effect.
- POST idempotency.
- Rollback cleanliness.
- Duplicate RPC cleanup.
- Static main.html surgery.
- Full current source parse.

## What was fixed in Production

- Added/standardized `get_supplier_purchase_reps(text)`.
- Hardened `save_supplier_atomic`.
- Preserved existing save-supplier Edge Function.
- No new Edge Function.
- No new table/column.
- No inventory/accounting contract change.

## What remains

- Owner applies the exact main.html element replacement.
- Frontend commit/publish.
- Served artifact identity verification.
- Authenticated Browser E2E.

## What could still be wrong

- Published artifact may not contain the patch until Owner publishes.
- Browser interaction has not been independently proven.
- The current text-based `purchase_rep` contract may later deserve stable ID/purchaser-code semantics, but that is a separate Business Contract.

---

# 29. Exact continuation instructions

ابدأ من:

System HEAD:
`85ad9d2b1a195e5b8845a6550beec5fd85fdfc41`

Mother HEAD:
`897d40c47b27544fb8a5515a7f7dcce528c4563e`

Mother main.html:
`f4e707060a3f0ff68b993bf57616e4e861ac54e6`

Production:

- save-supplier v5
- get_supplier_purchase_reps(text)
- save_supplier_atomic(...)

ثم:

1. لا تعِد إنشاء Supplier Search RPC.
2. لا تعِد إصلاح Supplier Save.
3. لا تعُد إلى Report325 كحالة حالية.
4. ابحث فقط عن عنصر:
   `<div class="flex flex-col"><label>مسؤول المشتريات</label><input id="supp-rep"...`
5. في `RW_Suppliers.openModal(code)` الحالي، استبدل العنصر فقط بالنص الكامل في هذا التقرير.
6. لا تستبدل `openModal` بالكامل.
7. لا تعدّل `_handleSave`.
8. اعمل Full main.html parse.
9. Commit frontend.
10. Publish.
11. Verify served artifact identity.
12. Login authenticated.
13. Mother → الموردين.
14. إضافة مورد جديد.
15. اكتب جزءًا من:
   `مندوب مشتريات 1`
16. تأكد من ظهور النتيجة.
17. اختر المندوب.
18. احفظ المورد.
19. تحقق Network/Console.
20. تحقق من row و`purchase_rep`.
21. نفذ Edit.
22. تحقق من ثبات الحقل المالي.
23. تحقق من Audit.
24. نفّذ snapshot Production في نفس لحظة التقرير.
25. حدّث CURRENT_STATE.
26. لا تغلق Browser E2E قبل إثباته.

---

# 30. Final Closure Status

### Production Supplier Purchase Representative Capability

**CLOSED / VERIFIED**

### Supplier Smart Search RPC

**CLOSED / VERIFIED**

### Supplier Save Validation

**CLOSED / VERIFIED**

### Purchase / Stock / Accounting Integration

**E2E VERIFIED**

### Mother Source Surgical Target

**VERIFIED / READY**

### main.html Owner Application

**PENDING OWNER**

### Published Artifact

**OPEN / UNVERIFIED**

### Authenticated Browser E2E

**OPEN / UNVERIFIED**

### Overall Closure

**SUPPLIER PURCHASE REPRESENTATIVE SMART SEARCH = PARTIALLY CLOSED**

والجزء الوحيد الذي يمنع الإغلاق الكامل هو نشر Owner Patch وتشغيل Browser E2E على الـpublished artifact.

# END OF REPORT326
