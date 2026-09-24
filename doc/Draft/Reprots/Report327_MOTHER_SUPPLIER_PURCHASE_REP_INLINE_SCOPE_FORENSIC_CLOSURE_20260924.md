# تقرير 327 — الإغلاق الجنائي لخطأ نطاق Supabase في بحث مسؤول المشتريات
**التاريخ:** 2026-09-24
**النطاق:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
**القدرة:** Mother ERP → الموردين → إضافة/تعديل مورد → مسؤول المشتريات
**Production Project:** `fiilmooggumokxanwiyx`

---

## 1. نقطة الاستكمال المثبتة

### Current Git
- آخر Frontend HEAD: `47ff966a23e89b19666485ac239455ec9a06a79d`
- Parent: `3bd5ab664608e7a7632ce978d7b50c3181508516`
- أحدث `companies/company-1/main.html` blob: `2b14edfaaa2dc1c64af386a187b795aca9e239a9`
- حجم الملف الحالي من blob: 1,741,262 bytes
- عدد الأسطر المقروءة من المصدر: 32,075

### Historical transition
الـcommit:
`3bd5ab664608e7a7632ce978d7b50c3181508516`
أضاف بالفعل واجهة البحث الذكي داخل `RW_Suppliers.openModal(code)`.

الـcommit:
`47ff966a23e89b19666485ac239455ec9a06a79d`
لم يعدل `main.html`، وإنما حدّث `_forensic_current_main_extract.md`.

وبذلك فإن Report326 أصبح مرجعًا تاريخيًا، بينما `2b14edf...` هو source truth الحالي.

---

## 2. العنصر المعيب الحالي

### الملف
`companies/company-1/main.html`

### الدالة
`RW_Suppliers.openModal(code)`

### الموضع الحالي
السطر **6938**

### العنصر
العنصر الذي يحتوي:
`id="supp-rep"`

عدد مرات ظهوره في الملف = **1**

---

## 3. Root Cause المثبت

المصدر الحالي ينشئ عميل Supabase داخل IIFE:

`var supabase = RW_SUPABASE_CLIENT;`

وهذا المتغير **محلي داخل الـIIFE**.

في المقابل:
- `window.supabase` هو namespace الخاص بمكتبة Supabase UMD.
- `window.RW_SUPABASE_CLIENT` هو العميل الفعلي الذي تم تعريضه صراحة على `window`.

واجهة المورد استخدمت داخل `onfocus`:

`supabase.rpc('get_supplier_purchase_reps', ...)`

والـinline event handler لا يحمل الـlexical scope الخاص بالـIIFE؛ لذلك حل الاسم `supabase` يتم على المستوى العالمي، وليس إلى `var supabase` المحلي.

النتيجة المثبتة هي:

`supabase.rpc is not a function`

وهذا يطابق تمامًا Console error المبلغ عنه:
`Uncaught TypeError: supabase.rpc is not a function`

---

## 4. Production verification

### Canonical RPC
`public.get_supplier_purchase_reps(p_query text)`

الحالة الحالية:
- SECURITY DEFINER
- authenticated EXECUTE = true
- anon EXECUTE = false
- auth.uid required
- company derived from authenticated user
- supplier permission required
- active users only
- role = `مسئول مشتريات`
- search: name/email/phone/employee_id
- limit 25

اختبار Production الحالي:
- `buyer1@rawaea.com`
- الاسم: `مندوب مشتريات 1`
- الدور: `مسئول مشتريات`
- permissions: `purchases`, `suppliers`

### Supplier writer
`public.save_supplier_atomic(...)`

الحالة:
- هو Writer الحاكم لـSupplier Master
- يتحقق من same-company active purchaser
- يخزن canonical purchaser name
- لا ينفذ حركة مخزون
- لا ينشئ journal entry
- لا يكتب supplier ledger

### Edge Function
`save-supplier`
- Version 5
- ACTIVE
- verify_jwt = true
- لا توجد حاجة إلى Edge Function جديدة

---

## 5. Current Production snapshot

آخر snapshot مثبت أثناء التحقيق:

- suppliers = 2
- inventory_log = 6
- stock_branches = 48
- supplier_ledger = 0
- journal_entries = 8

لا يوجد QA Supplier residue.

هذه الأرقام لم تتغير نتيجة إصلاح الـUI لأن `main.html` لم يُعدل ولم يُنشر.

---

## 6. Production / Database action

**لا يوجد Production patch مطلوب لهذه المشكلة.**

لم يتم:
- إنشاء RPC جديد
- إنشاء Edge Function
- تعديل جدول
- تعديل عمود
- تعديل Supplier writer
- تعديل Purchase workflow
- تعديل Inventory
- تعديل Accounting

العقد الخلفي الصحيح موجود بالفعل.

---

## 7. Static surgical verification

تم أخذ الـblob الحالي مباشرة من Git وفحص العنصر المطلوب.

### قبل التصحيح
- `id="supp-rep"` = 1
- `supabase.rpc('get_supplier_purchase_reps'...` داخل العنصر = 1
- `window.RW_SUPABASE_CLIENT.rpc(...)` = 0

### بعد التصحيح in-memory
- `id="supp-rep"` = 1
- `supabase.rpc(...)` المحلي = 0
- `window.RW_SUPABASE_CLIENT.rpc(...)` = 1
- onfocus handler parse = PASS
- الإغلاق/الـHTML structure داخل العنصر محفوظ
- لا توجد دوال إضافية
- لا يوجد تغيير في `_handleSave()`

---

## 8. Exact Owner Surgical Change

### احذف فقط العنصر الحالي الذي يحتوي على:
`id="supp-rep"`

داخل:
`RW_Suppliers.openModal(code)`

### ثم استبدله بالعنصر المصحح في هذا التقرير.

**التغيير البرمجي الوحيد داخل العنصر هو:**

`supabase.rpc(...)`

إلى:

`window.RW_SUPABASE_CLIENT.rpc(...)`

ولا يوجد أي تغيير آخر في الـworkflow.

---

## 9. Full replacement element

```html
<div class="flex flex-col">
		<label>مسؤول المشتريات</label>
		<div class="relative">
		<input id="supp-rep" type="text" value="${s?.purchase_rep||''}" autocomplete="off" spellcheck="false" placeholder="ابحث بالاسم أو البريد أو الهاتف" aria-autocomplete="list" aria-controls="supp-rep-results" class="p-2.5 bg-gray-50 border rounded-lg" onfocus="(function(el){if(el.dataset.rwRepBound==='1')return;el.dataset.rwRepBound='1';var box=document.getElementById('supp-rep-results');if(!box)return;var seq=0;var hide=function(){box.style.display='none';while(box.firstChild)box.removeChild(box.firstChild);};var message=function(t,c){while(box.firstChild)box.removeChild(box.firstChild);var d=document.createElement('div');d.className='px-3 py-2 text-sm '+(c||'text-slate-500');d.textContent=t;box.appendChild(d);box.style.display='block';};var render=function(rows){while(box.firstChild)box.removeChild(box.firstChild);if(!rows.length){message('لا يوجد مندوب مشتريات مطابق.','text-slate-500');return;}rows.forEach(function(row){var b=document.createElement('button');b.type='button';b.className='w-full text-right px-3 py-2.5 hover:bg-orange-50 border-b border-slate-100 last:border-b-0';b.setAttribute('data-purchase-rep-name',row.name||'');b.setAttribute('data-purchase-rep-email',row.email||'');b.setAttribute('role','option');var n=document.createElement('div');n.className='font-bold text-slate-800';n.textContent=row.name||row.email||'';var m=document.createElement('div');m.className='text-xs text-slate-500 mt-0.5';m.textContent=(row.email||'')+(row.phone?' • '+row.phone:'');b.appendChild(n);b.appendChild(m);box.appendChild(b);});box.style.display='block';};var run=function(){clearTimeout(el._rwRepTimer);var q=String(el.value||'').trim();delete el.dataset.purchaseRepEmail;seq++;var current=seq;if(!q)message('مندوبو المشتريات النشطون في الشركة.');else message('جاري البحث عن مندوبي المشتريات...','text-slate-500');el._rwRepTimer=setTimeout(function(){window.RW_SUPABASE_CLIENT.rpc('get_supplier_purchase_reps',{p_query:q||null}).then(function(r){if(current!==seq)return;if(r.error)throw r.error;render(r.data||[]);}).catch(function(err){if(current!==seq)return;message('تعذر تحميل مندوبي المشتريات: '+(err.message||'خطأ'),'text-rose-600');});},180);};el.addEventListener('input',run);el.addEventListener('keydown',function(ev){if(ev.key==='Escape')hide();});el.addEventListener('blur',function(){setTimeout(hide,120);});box.addEventListener('mousedown',function(ev){var b=ev.target.closest?ev.target.closest('button[data-purchase-rep-name]'):null;if(!b)return;ev.preventDefault();el.value=b.getAttribute('data-purchase-rep-name')||'';el.dataset.purchaseRepEmail=b.getAttribute('data-purchase-rep-email')||'';hide();});run();})(this)">
		<div id="supp-rep-results" role="listbox" class="absolute right-0 left-0 top-full mt-1 hidden max-h-64 overflow-y-auto bg-white border border-slate-200 rounded-xl shadow-xl z-[1300]"></div>
		</div>
		<p class="text-xs text-gray-500 mt-1">اكتب اسم أو بريد أو هاتف مندوب المشتريات، ثم اختره من النتائج.</p>
		</div>
```

---

## 10. What remains intentionally OPEN

لا يجوز تسجيل UI closure كـ100% قبل:

1. Owner applies the exact element above.
2. Full `main.html` parse.
3. Owner commit.
4. Publish.
5. Served artifact identity verification.
6. Authenticated Browser E2E:
   - Open Suppliers.
   - Add Supplier.
   - Focus Responsible Buyer.
   - Search `مندوب مشتريات 1` أو `buyer1`.
   - Select result.
   - Save.
   - Reopen supplier.
   - Verify purchaser.
   - Clear field.
   - Save.
   - Verify NULL.
   - Verify no Console error.
7. Fresh Production snapshot.

لا توجد Browser automation capability متاحة للمنفذ في هذه الدورة؛ لذلك لا يتم تحويل static/runtime DB evidence إلى Browser E2E PASS.

---

## 11. SELF-AUDIT

### What I Proved
- Current source blob identified.
- Current parent commit identified.
- Exact defective element identified once.
- Root cause is inline-handler scope resolution.
- Production RPC exists and is correct.
- Production Supplier writer remains correct.
- No Production schema/Edge change is needed.
- Exact one-element correction parses successfully in-memory.
- Existing business workflow remains untouched.

### What I Did Not Prove
- Click-level authenticated browser E2E after Owner publish.
- Served artifact identity after Owner publish.

### What I Fixed
لا يوجد Production mutation في هذه الدورة.
تم إعداد Owner surgical fix دقيق فقط.

### What I Initially Missed / What Changed Since Report326
Report326 كان مبنيًا على blob أقدم `f4e707...` وكان يوصي باستدعاء `supabase.rpc` داخل inline handler.
المصدر الحالي أصبح `2b14edf...` بعد commit `3bd5ab...`، وأظهر أن هذا الاستدعاء المحلي غير صالح في inline scope.

### Final Status
**ROOT CAUSE = PROVEN**

**PRODUCTION BACKEND CONTRACT = CLOSED / VERIFIED**

**MAIN.HTML SURGICAL PATCH = READY / OWNER ACTION**

**BROWSER E2E = OPEN / UNVERIFIED**

**OVERALL SUPPLIER PURCHASE REPRESENTATIVE UI = PARTIALLY CLOSED**

---

## 12. تعليمات الاستكمال للمساعد التالي

ابدأ من:

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

1. تحقق من Frontend HEAD `47ff966...`.
2. تحقق من parent `3bd5ab...`.
3. تحقق من main.html blob `2b14edf...`.
4. لا تعيد إصلاح Production RPC أو Supplier writer إلا إذا ظهر تعارض حالي جديد.
5. طبّق فقط عنصر `#supp-rep` أعلاه في `RW_Suppliers.openModal(code)`.
6. لا تعدل `_handleSave()`.
7. نفذ full parse.
8. نفذ Owner commit/publish.
9. Verify served artifact.
10. Run authenticated Browser E2E.
11. Capture fresh Production snapshot.
12. حدّث CURRENT_STATE.
13. لا تغلق العقد إلا بعد Browser proof.
