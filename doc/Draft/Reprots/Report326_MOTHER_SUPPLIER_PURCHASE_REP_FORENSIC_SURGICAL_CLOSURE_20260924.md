# تقرير 326 — التحقيق الجنائي وإغلاق فجوة «مسؤول المشتريات» في النظام الأم
**التاريخ:** 2026-09-24  
**النطاق:** `erp-frontend/companies/company-1/main.html` — `RW_Suppliers.openModal()` فقط  
**Production:** Supabase `fiilmooggumokxanwiyx`  
**الحالة:** Backend CLOSED / Surgical Main Patch READY / Browser UI E2E OWNER-ACTION

---

## 1. أساس الحقيقة الحالي

### Frontend Git
- أحدث Commit للمستودع وقت التحقيق: `897d40c47b27544fb8a5515a7f7dcce528c4563e`.
- Parent: `3520240a57f2124bbcf96c3007f67a9c36890fcb`.
- Commit `3520240…` كان تعديلًا واحدًا فقط في `main.html`: إصلاح عرض كود المورد الجديد.
- Parent ذلك الـcommit: `5206405a07ba6a4317ceb2ef2b93072b24bf3dce`.
- أحدث `main.html` المستخدم في هذا التحقيق: blob `f4e707060a3f0ff68b993bf57616e4e861ac54e6`.
- عدد الأسطر الحالي المثبت: 32068.
- لم يتم تعديل `main.html` بواسطة منفذ هذه الجلسة.

### Production
- `save-supplier` Edge Function الحالية: ACTIVE version 5، `verify_jwt=true`.
- `save_supplier_atomic` هو Writer الحاكم لحفظ Supplier Master.
- `purchase_rep` عمود موجود أصلًا، nullable text.
- البحث الآمن الموجود أصلًا في Production: `public.get_supplier_purchase_reps(text)`.
- صلاحية تنفيذ البحث: authenticated.
- البحث الحالي company-scoped، ويعرض المستخدمين النشطين ذوي الدور `مسئول مشتريات`.
- البحث يدعم الاسم والبريد والهاتف ورقم الموظف.
- لا توجد حاجة لإنشاء Edge Function جديدة.

---

## 2. سبب المشكلة الحقيقي

العنصر الحالي داخل `RW_Suppliers.openModal()` هو:

```
<div class="flex flex-col"><label>مسؤول المشتريات</label><input id="supp-rep" value="${s?.purchase_rep||''}" class="p-2.5 bg-gray-50 border rounded-lg"></div>
```

المشكلة ليست في:
- جدول Suppliers.
- عمود `purchase_rep`.
- `_handleSave()`.
- `save-supplier`.
- `save_supplier_atomic`.
- Accounting.
- Inventory.
- Purchase workflow.

المشكلة هي أن الحقل UI كان input نصيًا بسيطًا بلا بحث أو lookup ذكي.

ولا يجوز أن يحاول `main.html` القراءة المباشرة من `users`، لأن RLS الحالي يسمح قراءة قائمة المستخدمين company-wide لمن يملك صلاحية `users`، بينما مسؤول المشتريات يملك `suppliers` و`purchases` فقط. لذلك الحل الصحيح هو استخدام RPC الموجود أصلًا `get_supplier_purchase_reps()`.

---

## 3. إثبات أن البنية المطلوبة كانت موجودة أصلًا

Production تحتوي:

`public.get_supplier_purchase_reps(p_query text)`

العقد الحالي:
- Authenticated session required.
- Company context من `auth.uid()`.
- Permission `suppliers`.
- Active users only.
- Role = `مسئول مشتريات`.
- البحث متعدد الكلمات في:
  - الاسم.
  - البريد.
  - الهاتف.
  - رقم الموظف.
- الحد الأقصى 25 نتيجة.

النتيجة الحالية من Production لمستخدم:
`buyer1@rawaea.com`

كانت:
- الاسم: `مندوب مشتريات 1`
- البريد: `buyer1@rawaea.com`
- الدور: `مسئول مشتريات`

أما المستخدم:
`vansales@rawaea.com`

فلا يملك صلاحية الوصول إلى هذا البحث، وبالتالي لا يحصل على قائمة مسؤولي المشتريات.

هذه النتيجة تثبت أن البحث يجب أن يمر عبر الـRPC الموجود، وليس عبر جدول `users` مباشرة.

---

## 4. التدخل Production الذي تم أثناء التحقيق

خلال التحقيق تم اختبار تصميم RPC مستقل، ثم ظهر وجود الـcanonical RPC الحالي `get_supplier_purchase_reps`.

تم إلغاء الـRPC التجريبي بالكامل من Production بعد اكتشاف الـcanonical، وأصبح:

`supplier_purchase_rep_search(text)` = غير موجود.

وبذلك لا توجد بنية مكررة في Production.

تم تسجيل migrations التي طُبقت ثم أزيلت في Git حتى لا يصبح Production غير قابل لإعادة البناء:
- `20260924083202_supplier_purchase_rep_search_authenticated_rpc.sql`
- `20260924083232_supplier_purchase_rep_search_scope_fix.sql`
- `20260924083623_remove_duplicate_supplier_rep_search_rpc.sql`

هذه الملفات توثيق للحالة الفعلية التي مرت بها Production وليست جزءًا من العقد النهائي.

---

## 5. الاختبارات Production

### 5.1 Authenticated RPC search

تم الاختبار تحت سياق JWT للمستخدم:
`buyer1@rawaea.com`

**PASS**
- query فارغ يعيد مسؤول المشتريات الحالي.
- query يحتوي على `buyer1` يعيد نفس المستخدم.
- المالك لم يظهر في القائمة بعد تضييق العقد إلى الدور المرتبط بالمشتريات.

### 5.2 Unauthorized search

تم الاختبار تحت سياق:
`vansales@rawaea.com`

**PASS — REJECTED**
لا توجد صلاحية `suppliers` أو `purchases` لهذا المستخدم، وبالتالي لا ينجح استدعاء البحث.

### 5.3 Supplier create/update

تم تشغيل اختبار فعلي داخل PostgreSQL subtransaction مع rollback.

التسلسل:
1. البحث عن مسؤول المشتريات.
2. إنشاء Supplier Master مع `purchase_rep='مندوب مشتريات 1'`.
3. تعديل نفس المورد مع `purchase_rep='' `.
4. التحقق من أن القيمة النهائية أصبحت NULL.
5. قياس سجلات:
   - `stock_branches`
   - `inventory_log`
   - `supplier_ledger`
   - `journal_entries`
6. rollback كامل.

**النتائج:**
- Create = PASS.
- Update = PASS.
- Empty purchase rep = PASS.
- Supplier code generated = PASS.
- `verified_purchase_rep = null`.
- `counts_unchanged = true`.
- الحركة الناتجة محصورة في Supplier Master data.
- لم يتم إنشاء حركة مخزون.
- لم يتم إنشاء قيد يومية.
- لم يتغير رصيد المورد.
- لم يتغير رصيد الفرع.

### 5.4 Final Production snapshot

- Active suppliers = 2.
- Test supplier residue = 0.
- `inventory_log` = 6.
- `stock_branches` = 48.
- `supplier_ledger` = 0.
- `journal_entries` = 8.
- Canonical `get_supplier_purchase_reps` = 1.
- Duplicate `supplier_purchase_rep_search` = 0.

---

## 6. تأثير الحقل على Workflow

### Supplier Master
القيمة تحفظ عبر:

`main.html`
→ `save-supplier`
→ `save_supplier_atomic`
→ `suppliers.purchase_rep`

ولا يحتاج هذا المسار إلى Edge Function جديدة.

### Purchase Workflow
الحقل لا ينفذ شراء ولا استلامًا.

الدور:
- يحدد/يصف مسؤول المشتريات المرتبط بالمورد.
- يستفيد منه البحث في وحدة المشتريات الحالية.
- لا يغيّر `supplier_id` في أوامر الشراء.
- لا يغيّر كمية الشراء.
- لا يغير حالة PO.
- لا يكتب مخزونًا.

### Accounting
لا توجد حركة محاسبية مباشرة من اختيار مسؤول المشتريات.

`save_supplier_atomic` يحتفظ بـ:
`accounts_payable`

ولا ينشئ:
- journal entry.
- supplier ledger transaction.
- cash movement.

الأثر المحاسبي يبدأ لاحقًا من دورة الشراء/الاستلام الموجودة، وليس من حفظ Supplier Master.

### Inventory
لا يوجد أي call إلى:
`post_stock_movement`

عند:
- إنشاء المورد.
- تعديل المورد.
- تغيير مسؤول المشتريات.
- ترك الحقل فارغًا.

---

## 7. التكامل مع النظام الأم

النظام الأم يبقى:
- Control Plane.
- Master Data Plane.
- Navigation Plane.
- Monitoring Plane.

والتطبيقات التشغيلية تبقى كما هي.

لا يوجد نقل لدورة:
- PO.
- Receiving.
- Picking.
- Loading.
- Delivery.
- Return.

إلى Supplier Master.

الحقل مجرد عقد Master Data، بينما دورة المخزون تظل في محركاتها المركزية.

---

## 8. التعديل الجراحي الوحيد المطلوب في main.html

### مكان التعديل

الملف:

`companies/company-1/main.html`

الدالة:

`RW_Suppliers.openModal(code)`

الموضع الحالي المثبت:

**السطر 6934**

ابحث عن هذا العنصر **حرفيًا** واحذفه بالكامل:

```html
<div class="flex flex-col"><label>مسؤول المشتريات</label><input id="supp-rep" value="${s?.purchase_rep||''}" class="p-2.5 bg-gray-50 border rounded-lg"></div>
```

ثم استبدله **فقط** بهذا العنصر:

```html
<div class="flex flex-col relative"><label>مسؤول المشتريات <span class="text-xs text-gray-400">(اختياري)</span></label><input id="supp-rep" value="${s?.purchase_rep||''}" autocomplete="off" list="supp-rep-options" placeholder="ابحث بالاسم أو البريد أو الهاتف..." class="p-2.5 bg-gray-50 border rounded-lg" onfocus="if(!this.dataset.rwRepLoaded){this.dataset.rwRepLoaded='1';this.oninput();}" oninput="(function(el){clearTimeout(el._rwRepTimer);el._rwRepTimer=setTimeout(function(){supabase.rpc('get_supplier_purchase_reps',{p_query:el.value.trim()}).then(function(res){var dl=byId('supp-rep-options');if(!dl)return;dl.innerHTML='';var rows=res.data||[];rows.forEach(function(x){var o=document.createElement('option');o.value=x.name||x.email||'';o.label=[x.email||'',x.phone||'',x.role_name||''].filter(Boolean).join(' — ');dl.appendChild(o);});}).catch(function(err){console.warn('get_supplier_purchase_reps',err);});},250)})(this)"><datalist id="supp-rep-options"></datalist></div>
```

لا تحذف أي سطر آخر في `openModal()`.

لا تعدل:
- `_handleSave()`
- `render()`
- `filterTable()`
- `save-supplier`
- `save_supplier_atomic`

---

## 9. ماذا يقدم التعديل

عند فتح مودال إضافة/تعديل المورد:
- الحقل يبقى اختياريًا.
- التركيز على الحقل يحمّل مسؤولي المشتريات.
- الكتابة تستدعي بحثًا مؤجلًا 250ms.
- البحث يمر عبر RPC مصادق عليه.
- النتائج تظهر Native datalist.
- يظهر الاسم للمستخدم، مع البريد/الهاتف/الدور في وصف النتيجة.
- يمكن مسح الحقل وتركه فارغًا.
- لا توجد قراءة مباشرة لجدول `users`.
- لا توجد بيانات cross-company.
- لا يوجد endpoint جديد.
- لا يوجد Edge Function جديد.
- لا يوجد تغيير في save workflow.

---

## 10. Static validation للتعديل الجراحي

تم تطبيق البديل على نسخة in-memory من **الـblob الحالي** `f4e707060a3f0ff68b993bf57616e4e861ac54e6` فقط بغرض الاختبار.

النتائج:
- Target occurrences = 1.
- Replacement applied = true.
- Inline JS script parse = PASS.
- onfocus handler parse = PASS.
- oninput handler parse = PASS.
- Replacement size = 982 bytes.
- Current source lines = 32068.

لم يتم commit هذا التعديل إلى `erp-frontend` لأن `main.html` Owner-controlled في هذه المهمة.

---

## 11. مراجعة تنافسية للسجل

الوظائف المرجعية في الأنظمة المنافسة تؤكد أن Master Data للمورد لا تقتصر على الاسم والاتصال فقط.

### Odoo 19
يدعم Vendor Pricelists مرتبطة بالمورد والصنف والسعر والحد الأدنى للكمية وLead Time، مع تعدد الموردين للصنف:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/purchase/products/pricelist.html

### Microsoft Dynamics 365 Business Central
Vendor master يتضمن من بين الحقول:
- Purchaser Code.
- Currency Code.
- Payment Terms.
- Vendor Posting Group.
- Shipping conditions.
- Location Code.
- Blocked.
وهذا يوضح أن مسؤول المشتريات جزء واضح من Vendor Master:
https://learn.microsoft.com/en-us/dynamics365/business-central/application/base-application/table/microsoft.purchases.vendor.vendor-templ.

### SAP S/4HANA
يفصل بين General/Central Supplier Data وCompany Code Data وPurchasing Organization Data، ويشمل:
- Order Currency.
- Payment Terms.
- Purchasing Group.
- Planned Delivery Time.
- Shipping Conditions.
- Purchasing Block.
https://help.sap.com/docs/s4hana-best-practices/create-supplier-master-bne-56ccaf9fbaf5bcda
https://help.sap.com/docs/s4hana-best-practices/create-supplier-master-bne-63f3073d55790e5a9d678e741df6bcda/create-supplier-master-data-purchasing-organization-data

### Manager.io
Supplier Master يتضمن:
- Credit limit.
- Currency.
- Address.
- Email.
- Division.
- Control account.
- Starting balance.
https://www2.manager.io/guides/7020

---

## 12. Competitive backlog المقترح دون تنفيذ الآن

لا نضيف هذه الحقول الآن لأن عقد RAWAEA الحالي لم يثبتها بعد:

1. `purchase_rep_user_id` كـFK حقيقي بدل الاعتماد النهائي على النص.
2. Payment Terms.
3. Currency.
4. Credit Limit.
5. Vendor Posting / Reconciliation Account.
6. Tax / Registration identifiers.
7. Bank accounts.
8. Supplier-item price agreements.
9. Lead time.
10. Minimum order value.
11. Purchasing block.
12. Supplier classification / ABC.
13. Supplier contacts متعددة.
14. Attachments/documents.
15. Supplier performance KPIs.
16. Branch/Purchasing Organization assignment عندما يثبت Business Contract ذلك.

القرار الحاكم:
**لا تُضاف أي من هذه الآن.**
يتم فتحها كوحدات Business Contract مستقلة لاحقًا.

---

## 13. سبب اختيار datalist بدل مكتبة جديدة

الاختيار متعمد:
- لا dependency جديدة.
- لا Edge Function.
- لا modal جديد.
- لا state machine جديد.
- لا framework جديد.
- يعمل داخل البنية الحالية.
- يحافظ على input الحالي.
- يبقى متوافقًا مع `_handleSave()`.

هذا يجعل الجراحة محدودة وقابلة للعكس.

---

## 14. ما تم إثباته / ما لم يُثبت

### مثبت
- Production RPC canonical موجود.
- صلاحية RPC company-aware.
- مسؤول المشتريات الحقيقي يظهر في البحث.
- البحث منظم حسب الدور.
- Unauthorized access مرفوض.
- Supplier create PASS.
- Supplier update PASS.
- Empty value PASS.
- لا أثر مخزني مباشر.
- لا أثر محاسبي مباشر.
- لا أثر على Supplier Ledger.
- لا أثر على Stock.
- Static JS parse PASS.
- Target occurrence = 1.
- لا حاجة إلى Edge Function جديدة.
- لا يوجد duplicate RPC نهائي في Production.
- لا يوجد QA supplier residue.

### غير مثبت بعد
- Click-level authenticated browser E2E بعد تطبيق Owner patch على نسخة منشورة من `main.html`.
- Served Artifact hash بعد إدخال patch.

سبب عدم إثبات النقطتين الأخيرتين هو أن `main.html` Owner-controlled ولم يُسمح بتعديله من المنفذ، ولا توجد جلسة Browser authenticated متاحة في أدوات التنفيذ الحالية.

---

## 15. SELF-AUDIT

### What I Proved
تم إثبات سبب المشكلة وبنيتها الحقيقية، وإثبات وجود الـcanonical backend RPC، واختباره، واختبار أثر Supplier Master على المال والمخزون.

### What I Did Not Prove
الاختبار المرئي داخل Browser بعد تطبيق Owner patch.

### What I Fixed
- Production infrastructure اللازمة للبحث لم تُنشأ لأنها كانت موجودة أصلًا.
- أُزيلت البنية التجريبية المكررة.
- تم تجهيز الجراحة UI الدقيقة.

### What I Initially Missed
وجود `get_supplier_purchase_reps` في Production ولم يكن ظاهرًا من التقارير التاريخية.

### What Could Still Be Wrong
قد توجد مشكلة publishing/cache في الـartifact بعد Owner commit، وهي خارج نطاق Production DB.

### Final Confidence
Backend/Data Contract: HIGH  
Surgical Source Patch: HIGH  
Browser UI Runtime: OPEN

### Final Closure Status
**SUPPLIER PURCHASE REP BACKEND + DATA CONTRACT = CLOSED / VERIFIED**

**MOTHER MAIN.HTML UI = READY FOR OWNER SURGICAL APPLY**

**FULL BROWSER E2E = OPEN UNTIL OWNER APPLIES PATCH**

---

## 16. إرشادات للمساعد التالي

ابدأ دائمًا من:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

ثم:
1. لا تعيد فتح `save_supplier_atomic` إلا إذا ظهر تعارض Production جديد.
2. لا تنشئ Edge Function للبحث؛ استخدم `get_supplier_purchase_reps(text)`.
3. لا تعرّض جدول `users` مباشرة لهذا الحقل.
4. طبّق Patch السطر 6934 فقط على blob `f4e707060a3f0ff68b993bf57616e4e861ac54e6`.
5. Parse كامل `main.html`.
6. Verify target occurrence = 1.
7. انشر Owner artifact.
8. نفذ authenticated Browser E2E:
   - افتح Suppliers.
   - Add Supplier.
   - Focus Responsible Buyer.
   - اكتب جزءًا من الاسم.
   - تحقق من ظهور `مندوب مشتريات 1`.
   - اختره.
   - احفظ المورد.
   - افتحه مرة أخرى.
   - امسح الحقل.
   - احفظ.
   - تحقق من NULL.
9. Verify served artifact.
10. Capture fresh Production snapshot.
11. لا تنقل المهمة إلى Business Contract التالي قبل إغلاق هذا العقد مرئيًا.
