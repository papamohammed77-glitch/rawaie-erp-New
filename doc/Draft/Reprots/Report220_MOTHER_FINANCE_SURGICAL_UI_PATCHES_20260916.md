# Report220 — جراحات Mother Finance الدقيقة — 2026-09-16

> **تنبيه حاكم:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html` هو **Source of Truth الوحيد الحالي** للواجهة الأم. يجب قراءته بعناية قبل أي دمج. `Current/PWA/main2` والتقارير والنسخ السابقة للاستدلال التاريخي فقط ولا يجوز استخدامها كمصدر نشر.

## 1. ما تم إثباته

آخر Mother HEAD الحقيقي:

- `3fe3c76674c7cbed8eb10201fee83ca6af2f1b07`
- Parent: `3b5fdce634e44b3a2faa6bbf2dd40db5e88a676a`

الـFinance backend الحالي موجود في Production ولا يحتاج إنشاء جداول بديلة.

تم تنفيذ Production migrations:

```text
20260916162000_finance_contract_integrity_close
20260916163500_finance_expense_cashflow_integrity
20260916165000_finance_asset_tax_bank_contract_final
```

أهم النتائج:

- `finance_period_guard` أصبح يمنع أي ترحيل خارج فترة `OPEN`.
- `finance_open_period` يمنع تداخل الفترات ويمنع تعديل الفترة المغلقة.
- كشف بنكي `RECONCILED` أو يحتوي خطوطًا محمية لا يمكن إعادة كتابته.
- الشيك لا يولد Event `ISSUED` ثانيًا عند التعديل.
- انتقالات الشيكات تمر عبر period guard.
- المصروف النقدي ينشئ Journal + Cash Box Payment + تحديث Treasury داخل نفس العملية.
- `save_fixed_asset` أصبح يتحقق من الحقول والحسابات والتواريخ وIdempotency قبل أي mutation.
- Tax code المستخدم في معاملات سابقة أصبح غير قابل لتغيير العناصر التاريخية الحساسة؛ إنشاء Tax Code جديد هو المسار الصحيح عند تغيير معدل/حسابات الضريبة.

## 2. ما لم أعد تعديله

`newExpense` الحالية أقوى من بقية الـmodals من حيث التحميل Company-scoped للحسابات/التصنيفات/مراكز التكلفة/الضرائب، وتستخدم `finance_save_expense`. لذلك لم تُمس لمجرد التجميل.

## 3. جراحة Mother المطلوبة

### A — Dispatcher

الموضع المثبت: `RW_Finance.renderSubTab`، تقريبًا Console lines `14535–14542` في النسخة التي نتجت عنها ReferenceErrors.

ابحث عن **المقطع كاملًا** التالي واحذفه:

```text
else if (tab === 'journal-list') _renderJournalList();
else if (tab === 'recurring-journals') _renderRecurringJournals();
else if (tab === 'expenses') _renderExpenses();
else if (tab === 'cheques') _renderCheques();
else if (tab === 'bank-reconcile') _renderBankReconcile();
else if (tab === 'tax') _renderTax();
else if (tab === 'assets') _renderAssets();
else if (tab === 'periods') _renderPeriods();
```

وينتهي تحديدًا بالسطر:

```text
else if (tab === 'periods') _renderPeriods();
```

استبدله كاملًا بـ:

```text
else if (tab === 'journal-list') RW_Finance._renderJournalList();
else if (tab === 'recurring-journals') RW_Finance._renderRecurringJournals();
else if (tab === 'expenses') RW_Finance._renderExpenses();
else if (tab === 'cheques') RW_Finance._renderCheques();
else if (tab === 'bank-reconcile') RW_Finance._renderBankReconcile();
else if (tab === 'tax') RW_Finance._renderTax();
else if (tab === 'assets') RW_Finance._renderAssets();
else if (tab === 'periods') RW_Finance._renderPeriods();
```

---

## 4. استبدال `newRecurring`

**ابحث عن العنصر الكامل الذي يبدأ بـ:**

```text
async function newRecurring(){
```

وينتهي تحديدًا عند نهاية الدالة الحالية قبل السطر التالي:

```text
async function runRecurring(){
```

احذف `newRecurring` بالكامل واستبدلها بـ:

```javascript
async function newRecurring(){
    if(typeof Swal==='undefined') return;
    var cid=companyId();
    var res=await Promise.all([
        supabase.from('chart_of_accounts').select('id,account_code,account_name').eq('company_id',cid).eq('is_active',true).order('account_code'),
        supabase.from('cost_centers').select('id,code,name').eq('is_active',true).order('code')
    ]);
    if(res[0].error) throw res[0].error;
    if(res[1].error) throw res[1].error;
    var accounts=res[0].data||[];
    var centers=res[1].data||[];
    if(accounts.length<2) throw new Error('لا يوجد عدد كافٍ من الحسابات النشطة لإنشاء قيد متكرر');
    function ae(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');}
    function accountOptions(){var h='<option value="">اختر الحساب</option>';accounts.forEach(function(a){h+='<option value="'+ae(a.id)+'">'+ae((a.account_code||'')+' — '+(a.account_name||''))+'</option>';});return h;}
    function centerOptions(){var h='<option value="">بدون مركز تكلفة</option>';centers.forEach(function(c){h+='<option value="'+ae(c.id)+'">'+ae((c.code||'')+' — '+(c.name||''))+'</option>';});return h;}
    function rowHtml(){return '<div class="gr-row border rounded-xl p-3 mb-2 bg-slate-50"><div class="grid grid-cols-1 md:grid-cols-5 gap-2"><select class="gr-account border rounded-lg p-2 bg-white">'+accountOptions()+'</select><input class="gr-debit border rounded-lg p-2" type="number" min="0" step="0.01" placeholder="مدين"><input class="gr-credit border rounded-lg p-2" type="number" min="0" step="0.01" placeholder="دائن"><select class="gr-center border rounded-lg p-2 bg-white">'+centerOptions()+'</select><div class="flex gap-2"><input class="gr-note flex-1 border rounded-lg p-2" placeholder="ملاحظة"><button type="button" class="gr-remove px-3 rounded-lg bg-red-100 text-red-700 font-bold">حذف</button></div></div></div>';}
    var html='<div class="space-y-3 text-right">'+
        '<div class="grid grid-cols-1 md:grid-cols-2 gap-3">'+
        '<input id="grc" class="border rounded-xl p-3" placeholder="كود القالب">'+
        '<input id="grn" class="border rounded-xl p-3" placeholder="اسم القالب">'+
        '<select id="grf" class="border rounded-xl p-3"><option value="MONTHLY">شهري</option><option value="DAILY">يومي</option><option value="WEEKLY">أسبوعي</option><option value="QUARTERLY">ربع سنوي</option><option value="YEARLY">سنوي</option></select>'+
        '<input id="grd" type="date" value="'+today()+'" class="border rounded-xl p-3">'+
        '<input id="gre" type="date" class="border rounded-xl p-3" placeholder="تاريخ النهاية الاختياري">'+
        '<input id="grdesc" class="border rounded-xl p-3" placeholder="وصف القيد">'+
        '</div>'+
        '<div class="flex items-center justify-between gap-2"><div class="font-black">بنود القيد</div><button type="button" id="gr_add" class="px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold">إضافة سطر</button></div>'+
        '<div id="gr_lines">'+rowHtml()+rowHtml()+'</div>'+
        '<div class="grid grid-cols-3 gap-3 mt-3"><div class="rounded-xl bg-blue-50 p-3"><span class="text-xs">إجمالي المدين</span><b id="gr_td" class="block text-lg">0</b></div><div class="rounded-xl bg-emerald-50 p-3"><span class="text-xs">إجمالي الدائن</span><b id="gr_tc" class="block text-lg">0</b></div><div class="rounded-xl bg-slate-100 p-3"><span class="text-xs">الفارق</span><b id="gr_diff" class="block text-lg">0</b></div></div></div>';
    var r=await Swal.fire({title:'قيد متكرر جديد',html:html,width:1100,showCancelButton:true,confirmButtonText:'حفظ القالب',cancelButtonText:'إلغاء',didOpen:function(){
        var root=document.getElementById('gr_lines');
        function calc(){var td=0,tc=0;root.querySelectorAll('.gr-row').forEach(function(row){td+=Number(row.querySelector('.gr-debit').value)||0;tc+=Number(row.querySelector('.gr-credit').value)||0;});document.getElementById('gr_td').textContent=td.toFixed(2);document.getElementById('gr_tc').textContent=tc.toFixed(2);document.getElementById('gr_diff').textContent=(td-tc).toFixed(2);}
        document.getElementById('gr_add').addEventListener('click',function(){root.insertAdjacentHTML('beforeend',rowHtml());wire();calc();});
        function wire(){root.querySelectorAll('.gr-remove').forEach(function(b){if(b.dataset.wired)return;b.dataset.wired='1';b.addEventListener('click',function(){if(root.querySelectorAll('.gr-row').length<=2){Swal.showValidationMessage('القيد يحتاج سطرين على الأقل');return;}b.closest('.gr-row').remove();calc();});});root.querySelectorAll('.gr-debit,.gr-credit').forEach(function(i){if(i.dataset.wired)return;i.dataset.wired='1';i.addEventListener('input',calc);});}
        wire();calc();
    },preConfirm:function(){
        var code=(document.getElementById('grc').value||'').trim(),name=(document.getElementById('grn').value||'').trim(),date=document.getElementById('grd').value,end=document.getElementById('gre').value||null,rows=[];
        document.querySelectorAll('#gr_lines .gr-row').forEach(function(row){var aid=row.querySelector('.gr-account').value,debit=Number(row.querySelector('.gr-debit').value)||0,credit=Number(row.querySelector('.gr-credit').value)||0;if(aid||debit||credit)rows.push({account_id:aid,debit:debit,credit:credit,cost_center_id:row.querySelector('.gr-center').value||null,notes:(row.querySelector('.gr-note').value||'').trim()});});
        var td=rows.reduce(function(a,x){return a+x.debit},0),tc=rows.reduce(function(a,x){return a+x.credit},0);
        if(!code||!name||!date){Swal.showValidationMessage('الكود والاسم وتاريخ البداية مطلوبة');return false;}
        if(!rows.length||rows.length<2){Swal.showValidationMessage('أضف بندين على الأقل');return false;}
        if(Math.abs(td-tc)>0.004||td<=0){Swal.showValidationMessage('القيد غير متوازن');return false;}
        return {code:code,name:name,frequency:document.getElementById('grf').value,next:date,end:end,description:(document.getElementById('grdesc').value||'').trim(),lines:rows};
    }});
    if(!r.isConfirmed)return;
    await rpc('finance_save_recurring',{p_company_id:cid,p_template_id:null,p_template_code:r.value.code,p_name:r.value.name,p_frequency:r.value.frequency,p_next_run_date:r.value.next,p_end_date:r.value.end,p_description:r.value.description,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_lines:r.value.lines});
    await renderRecurring();
}
```

---

## 5. استبدال `newCheque`

**ابحث عن:**

```text
async function newCheque(){
```

وينتهي قبل:

```text
async function newBank(){
```

احذف الدالة كاملة واستبدلها بـ:

```javascript
async function newCheque(){
    if(typeof Swal==='undefined') return;
    var cid=companyId();
    var res=await Promise.all([
        supabase.from('treasury').select('id,name,current_balance').eq('company_id',cid).eq('is_active',true).order('name'),
        supabase.from('chart_of_accounts').select('id,account_code,account_name').eq('company_id',cid).eq('is_active',true).order('account_code')
    ]);
    if(res[0].error) throw res[0].error;
    if(res[1].error) throw res[1].error;
    var treasuries=res[0].data||[],accounts=res[1].data||[];
    function e(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');}
    var th='<option value="">بدون خزينة</option>';treasuries.forEach(function(t){th+='<option value="'+e(t.id)+'">'+e((t.name||'خزينة')+' — الرصيد '+Number(t.current_balance||0).toLocaleString())+'</option>';});
    var ah='<option value="">اختر الحساب</option>';accounts.forEach(function(a){ah+='<option value="'+e(a.id)+'">'+e((a.account_code||'')+' — '+(a.account_name||''))+'</option>';});
    var html='<div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-right">'+
        '<input id="gcno" class="border rounded-xl p-3" placeholder="رقم الشيك">'+
        '<select id="gct" class="border rounded-xl p-3"><option value="PAYABLE">شيك صادر / التزام دفع</option><option value="RECEIVABLE">شيك وارد / حق قبض</option></select>'+
        '<input id="gcb" class="border rounded-xl p-3" placeholder="البنك">'+
        '<input id="gca" type="number" min="0.01" step="0.01" class="border rounded-xl p-3" placeholder="المبلغ">'+
        '<input id="gcd" type="date" value="'+today()+'" class="border rounded-xl p-3" placeholder="تاريخ الشيك">'+
        '<input id="gdu" type="date" value="'+today()+'" class="border rounded-xl p-3" placeholder="تاريخ الاستحقاق">'+
        '<input id="gcp" class="border rounded-xl p-3" placeholder="الطرف">'+
        '<select id="gctry" class="border rounded-xl p-3">'+th+'</select>'+
        '<select id="gfrom" class="border rounded-xl p-3">'+ah+'</select>'+
        '<select id="gto" class="border rounded-xl p-3">'+ah+'</select>'+\
        '<textarea id="gcn" class="border rounded-xl p-3 md:col-span-2" placeholder="ملاحظات"></textarea></div>';
    var r=await Swal.fire({title:'شيك جديد',html:html,width:950,showCancelButton:true,confirmButtonText:'حفظ',cancelButtonText:'إلغاء',preConfirm:function(){
        var no=(byId('gcno').value||'').trim(),bank=(byId('gcb').value||'').trim(),amount=Number(byId('gca').value)||0,cd=byId('gcd').value,du=byId('gdu').value;
        if(!no||!bank||amount<=0||!cd||!du){Swal.showValidationMessage('رقم الشيك والبنك والمبلغ والتواريخ مطلوبة');return false;}
        if(du<cd){Swal.showValidationMessage('تاريخ الاستحقاق لا يجوز أن يسبق تاريخ الشيك');return false;}
        return {no:no,type:byId('gct').value,bank:bank,amount:amount,cd:cd,du:du,party:(byId('gcp').value||'').trim(),treasury:byId('gctry').value||null,from:byId('gfrom').value||null,to:byId('gto').value||null,notes:byId('gcn').value||''};
    }});
    if(!r.isConfirmed)return;
    await rpc('finance_save_cheque',{p_company_id:cid,p_id:null,p_cheque_number:r.value.no,p_cheque_type:r.value.type,p_bank_name:r.value.bank,p_amount:r.value.amount,p_cheque_date:r.value.cd,p_due_date:r.value.du,p_party_name:r.value.party,p_from_account_id:r.value.from,p_to_account_id:r.value.to,p_treasury_id:r.value.treasury,p_notes:r.value.notes,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'});
    await renderCheques();
}
```

---

## 6. استبدال `newBank`

**ابحث عن:**

```text
async function newBank(){
```

وينتهي قبل:

```text
async function closeBank(id){
```

احذفها كاملة واستبدلها بـ:

```javascript
async function newBank(){
    if(typeof Swal==='undefined') return;
    var cid=companyId();
    var ts=await supabase.from('treasury').select('id,name,current_balance').eq('company_id',cid).eq('is_active',true).order('name');
    if(ts.error) throw ts.error;
    var treasuries=ts.data||[];
    if(!treasuries.length) throw new Error('لا توجد خزائن فعالة للشركة الحالية');
    function e(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');}
    var th='<option value="">اختر الخزينة</option>';treasuries.forEach(function(t){th+='<option value="'+e(t.id)+'">'+e(t.name||'خزينة')+'</option>';});
    function line(){return '<div class="gb-line grid grid-cols-1 md:grid-cols-4 gap-2 border rounded-xl p-2 bg-slate-50"><input class="gb-date border rounded-lg p-2" type="date" value="'+today()+'"><input class="gb-desc border rounded-lg p-2" placeholder="الوصف"><input class="gb-ref border rounded-lg p-2" placeholder="المرجع"><div class="flex gap-2"><input class="gb-amt flex-1 border rounded-lg p-2" type="number" step="0.01" placeholder="المبلغ"><button type="button" class="gb-remove px-3 rounded-lg bg-red-100 text-red-700 font-bold">حذف</button></div></div>';}
    var html='<div class="space-y-3 text-right">'+
        '<div class="grid grid-cols-1 md:grid-cols-2 gap-3">'+
        '<input id="gbr" class="border rounded-xl p-3" placeholder="مرجع كشف البنك">'+
        '<select id="gbt" class="border rounded-xl p-3">'+th+'</select>'+
        '<input id="gbd" type="date" value="'+today()+'" class="border rounded-xl p-3" placeholder="تاريخ الكشف">'+
        '<input id="gbo" type="number" step="0.01" class="border rounded-xl p-3" placeholder="الرصيد الافتتاحي">'+
        '<input id="gbc" type="number" step="0.01" class="border rounded-xl p-3" placeholder="الرصيد الختامي">'+
        '</div><div class="flex items-center justify-between"><div class="font-black">حركات الكشف</div><button id="gb_add" type="button" class="px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold">إضافة حركة</button></div><div id="gb_lines">'+line()+'</div></div>';
    var r=await Swal.fire({title:'كشف بنكي جديد',html:html,width:1100,showCancelButton:true,confirmButtonText:'حفظ الكشف',cancelButtonText:'إلغاء',didOpen:function(){
        var root=byId('gb_lines');
        byId('gb_add').addEventListener('click',function(){root.insertAdjacentHTML('beforeend',line());wire();});
        function wire(){root.querySelectorAll('.gb-remove').forEach(function(b){if(b.dataset.wired)return;b.dataset.wired='1';b.addEventListener('click',function(){if(root.querySelectorAll('.gb-line').length<=1){Swal.showValidationMessage('يجب إبقاء حركة واحدة على الأقل أو حذفها قبل الحفظ');return;}b.closest('.gb-line').remove();});});}
        wire();
    },preConfirm:function(){
        var ref=(byId('gbr').value||'').trim(),tid=byId('gbt').value||'',date=byId('gbd').value,opening=Number(byId('gbo').value)||0,closing=Number(byId('gbc').value)||0,lines=[];
        document.querySelectorAll('#gb_lines .gb-line').forEach(function(row){var d=row.querySelector('.gb-date').value,a=Number(row.querySelector('.gb-amt').value)||0;if(d&&a!==0)lines.push({txn_date:d,description:(row.querySelector('.gb-desc').value||'').trim(),amount:a,reference:(row.querySelector('.gb-ref').value||'').trim()});});
        if(!ref||!tid||!date){Swal.showValidationMessage('مرجع الكشف والخزينة والتاريخ مطلوبة');return false;}
        return {ref:ref,treasury:tid,date:date,opening:opening,closing:closing,lines:lines};
    }});
    if(!r.isConfirmed)return;
    await rpc('finance_save_bank_statement',{p_company_id:cid,p_treasury_id:r.value.treasury,p_statement_ref:r.value.ref,p_statement_date:r.value.date,p_opening:r.value.opening,p_closing:r.value.closing,p_lines:r.value.lines,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_statement_id:null});
    await renderBankReconcile();
}
```

---

## 7. استبدال `goldTaxCode`

**ابحث عن:**

```text
async function goldTaxCode(){
```

وينتهي قبل السطر التالي الذي يلي الدالة مباشرة، وهو:

```text
}
```

ضمن `RW_Finance_GoldExtension` قبل `return {`.

الأدق: احذف **الدالة الكاملة التي تبدأ بـ `async function goldTaxCode(){` وتنتهي بالسطر `}` الذي يلي `await renderTax();` مباشرة**.

استبدلها بـ:

```javascript
async function goldTaxCode(){
    if(typeof Swal==='undefined') return;
    var cid=companyId();
    var ar=await supabase.from('chart_of_accounts').select('id,account_code,account_name').eq('company_id',cid).eq('is_active',true).order('account_code');
    if(ar.error) throw ar.error;
    var accounts=ar.data||[];
    function e(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');}
    var opt='<option value="">اختر الحساب</option>';accounts.forEach(function(a){opt+='<option value="'+e(a.id)+'">'+e((a.account_code||'')+' — '+(a.account_name||''))+'</option>';});
    var h='<div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-right">'+
        '<input id="tc_code" class="border rounded-xl p-3" placeholder="كود الضريبة">'+
        '<input id="tc_name" class="border rounded-xl p-3" placeholder="اسم الضريبة">'+
        '<input id="tc_rate" type="number" min="0" step="0.01" class="border rounded-xl p-3" placeholder="النسبة %">'+
        '<select id="tc_sales" class="border rounded-xl p-3">'+opt+'</select>'+
        '<select id="tc_purchase" class="border rounded-xl p-3">'+opt+'</select>'+
        '<select id="tc_settle" class="border rounded-xl p-3">'+opt+'</select></div>';
    var r=await Swal.fire({title:'نوع ضريبة جديد',html:h,width:800,showCancelButton:true,confirmButtonText:'حفظ',cancelButtonText:'إلغاء',preConfirm:function(){var code=(byId('tc_code').value||'').trim(),name=(byId('tc_name').value||'').trim(),rate=Number(byId('tc_rate').value);if(!code||!name||!Number.isFinite(rate)||rate<0||!byId('tc_sales').value||!byId('tc_purchase').value||!byId('tc_settle').value){Swal.showValidationMessage('كل بيانات الضريبة والحسابات الثلاثة مطلوبة');return false;}return {code:code,name:name,rate:rate,sales:byId('tc_sales').value,purchase:byId('tc_purchase').value,settle:byId('tc_settle').value};}});
    if(!r.isConfirmed)return;
    await rpc('finance_save_tax_code',{p_company_id:cid,p_id:null,p_code:r.value.code,p_name:r.value.name,p_rate:r.value.rate,p_sales_account_id:r.value.sales,p_purchase_account_id:r.value.purchase,p_settlement_account_id:r.value.settle,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'});
    await renderTax();
}
```

---

## 8. استبدال `goldAddAsset`

**ابحث عن:**

```text
async function goldAddAsset(){
```

وينتهي قبل:

```text
async function goldDepreciate(id){
```

احذف الدالة كاملة واستبدلها بـ:

```javascript
async function goldAddAsset(){
    if(typeof Swal==='undefined') return;
    var cid=companyId();
    var ar=await supabase.from('chart_of_accounts').select('id,account_code,account_name').eq('company_id',cid).eq('is_active',true).order('account_code');
    if(ar.error) throw ar.error;
    var accounts=ar.data||[];
    function e(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');}
    var opt='<option value="">اختر الحساب</option>';accounts.forEach(function(a){opt+='<option value="'+e(a.id)+'">'+e((a.account_code||'')+' — '+(a.account_name||''))+'</option>';});
    var h='<div class="space-y-3 text-right">'+
        '<div class="grid grid-cols-1 md:grid-cols-2 gap-3">'+
        '<input id="fa_code" class="border rounded-xl p-3" placeholder="كود الأصل">'+
        '<input id="fa_name" class="border rounded-xl p-3" placeholder="اسم الأصل">'+
        '<input id="fa_category" class="border rounded-xl p-3" placeholder="التصنيف">'+
        '<input id="fa_cost" type="number" min="0.01" step="0.01" class="border rounded-xl p-3" placeholder="التكلفة">'+
        '<input id="fa_salvage" type="number" min="0" step="0.01" class="border rounded-xl p-3" placeholder="قيمة الخردة">'+
        '<input id="fa_life" type="number" min="1" step="1" class="border rounded-xl p-3" placeholder="العمر بالشهور">'+
        '<input id="fa_date" type="date" value="'+today()+'" class="border rounded-xl p-3">'+
        '<input id="fa_service" type="date" value="'+today()+'" class="border rounded-xl p-3">'+
        '<select id="fa_method" class="border rounded-xl p-3"><option value="STRAIGHT_LINE">خط مستقيم</option><option value="DECLINING_BALANCE">رصيد متناقص</option><option value="NONE">بدون إهلاك</option></select>'+
        '<select id="fa_asset_acc" class="border rounded-xl p-3">'+opt+'</select>'+\
        '<select id="fa_acc_dep" class="border rounded-xl p-3">'+opt+'</select>'+\
        '<select id="fa_dep_exp" class="border rounded-xl p-3">'+opt+'</select>'+\
        '<select id="fa_gl" class="border rounded-xl p-3">'+opt+'</select>'+\
        '</div>'+\
        '<label class="flex items-center gap-2 p-3 rounded-xl bg-amber-50 border"><input id="fa_acquire_now" type="checkbox"> ترحيل اقتناء الأصل الآن إلى الحسابات</label>'+\
        '<select id="fa_funding" class="border rounded-xl p-3">'+opt+'</select>'+\
        '<textarea id="fa_notes" class="border rounded-xl p-3" placeholder="ملاحظات"></textarea></div>';
    var r=await Swal.fire({title:'أصل ثابت جديد',html:h,width:1050,showCancelButton:true,confirmButtonText:'حفظ الأصل',cancelButtonText:'إلغاء',didOpen:function(){byId('fa_funding').disabled=true;byId('fa_acquire_now').addEventListener('change',function(){byId('fa_funding').disabled=!this.checked;});},preConfirm:function(){var code=(byId('fa_code').value||'').trim(),name=(byId('fa_name').value||'').trim(),cost=Number(byId('fa_cost').value)||0,salvage=Number(byId('fa_salvage').value||0),life=Number(byId('fa_life').value)||0,acq=byId('fa_date').value,service=byId('fa_service').value;if(!code||!name||cost<=0||!acq||!service||!byId('fa_asset_acc').value){Swal.showValidationMessage('كود الأصل والاسم والتكلفة والتواريخ وحساب الأصل مطلوبة');return false;}if(service<acq){Swal.showValidationMessage('تاريخ التشغيل لا يسبق تاريخ الاقتناء');return false;}if(salvage<0||salvage>cost){Swal.showValidationMessage('قيمة الخردة غير صالحة');return false;}if(byId('fa_method').value!=='NONE'&&life<=0){Swal.showValidationMessage('العمر بالشهور مطلوب إذا كان الإهلاك فعالًا');return false;}if(byId('fa_acquire_now').checked&&!byId('fa_funding').value){Swal.showValidationMessage('اختر حساب تمويل الاقتناء');return false;}return {asset:{asset_code:code,name:name,category:(byId('fa_category').value||'').trim()||null,acquisition_date:acq,in_service_date:service,cost:cost,salvage_value:salvage,useful_life_months:life,depreciation_method:byId('fa_method').value,asset_account_id:byId('fa_asset_acc').value,accumulated_depreciation_account_id:byId('fa_acc_dep').value||null,depreciation_expense_account_id:byId('fa_dep_exp').value||null,disposal_gain_loss_account_id:byId('fa_gl').value||null,created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',notes:byId('fa_notes').value||''},acquire:byId('fa_acquire_now').checked,funding:byId('fa_funding').value||null};}});
    if(!r.isConfirmed)return;
    var op=crypto.randomUUID();
    var saved=await rpc('save_fixed_asset',{p_company_id:cid,p_operation_id:op,p_asset:r.value.asset});
    if(r.value.acquire){await rpc('finance_asset_acquire',{p_company_id:cid,p_asset_id:saved.asset.id,p_acquisition_date:r.value.asset.acquisition_date,p_funding_account_id:r.value.funding,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_operation_id:crypto.randomUUID()});}
    await renderAssets();
}
```

---

## 9. استبدال `goldOpenPeriod`

**ابحث عن:**

```text
async function goldOpenPeriod(){
```

وينتهي قبل نهاية الدالة مباشرة عند:

```text
}
```

احذف الدالة الكاملة واستبدلها بـ:

```javascript
async function goldOpenPeriod(){
    if(typeof Swal==='undefined') return;
    var cid=companyId();
    var pr=await supabase.from('finance_periods').select('id,period_code,start_date,end_date,status').eq('company_id',cid).order('start_date',{ascending:false});
    if(pr.error) throw pr.error;
    var periods=pr.data||[];
    var y=new Date().getFullYear();
    var h='<div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-right">'+
        '<input id="po_code" class="border rounded-xl p-3" placeholder="كود الفترة">'+
        '<input id="po_year" type="number" value="'+y+'" class="border rounded-xl p-3" placeholder="السنة المالية">'+
        '<input id="po_from" type="date" value="'+y+'-01-01" class="border rounded-xl p-3">'+
        '<input id="po_to" type="date" value="'+y+'-12-31" class="border rounded-xl p-3"></div><div id="po_warning" class="mt-3 text-sm"></div>';
    function overlap(a,b,c,d){return a<=d&&c<=b;}
    var r=await Swal.fire({title:'فتح فترة محاسبية',html:h,width:800,showCancelButton:true,confirmButtonText:'فتح الفترة',cancelButtonText:'إلغاء',didOpen:function(){function check(){var a=byId('po_from').value,b=byId('po_to').value,w=byId('po_warning');if(!a||!b||a>b){w.className='mt-3 text-sm text-red-700 font-bold';w.textContent='نطاق التاريخ غير صالح';return;}var hit=periods.find(function(p){return overlap(a,b,p.start_date,p.end_date);});if(hit){w.className='mt-3 text-sm text-red-700 font-bold';w.textContent='تداخل مع الفترة '+hit.period_code+' ('+hit.start_date+' → '+hit.end_date+')';}else{w.className='mt-3 text-sm text-emerald-700 font-bold';w.textContent='لا يوجد تداخل مع الفترات الحالية';}}['po_from','po_to'].forEach(function(id){byId(id).addEventListener('change',check);});check();},preConfirm:function(){var code=(byId('po_code').value||'').trim(),year=Number(byId('po_year').value),from=byId('po_from').value,to=byId('po_to').value;if(!code||!Number.isInteger(year)||year<2000||year>2200||!from||!to||from>to){Swal.showValidationMessage('بيانات الفترة غير صالحة');return false;}var hit=periods.find(function(p){return overlap(from,to,p.start_date,p.end_date);});if(hit){Swal.showValidationMessage('لا يمكن فتح فترة متداخلة مع '+hit.period_code);return false;}return {code:code,year:year,from:from,to:to};}});
    if(!r.isConfirmed)return;
    await rpc('finance_open_period',{p_company_id:cid,p_period_code:r.value.code,p_fiscal_year:r.value.year,p_start_date:r.value.from,p_end_date:r.value.to,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'});
    await renderPeriods();
}
```

---

## 10. نقطة مهمة جدًا حول `goldTaxSettle`

لم أطلب استبداله الآن؛ الـProduction RPC الحالي لديه:

- Idempotency.
- period guard.
- منع تسوية نفس الفترة مرتين.
- إنشاء Journal Entry مركزي.
- ربط معاملات الضريبة بالتسوية.

لذلك لا نعيد بناءه ما لم يثبت E2E وجود خلل.

---

## 11. نقطة مهمة حول `newExpense`

لا تستبدله الآن.

الدالة الحالية بالفعل تستعمل Company-scoped categories/accounts/cost centers/tax codes/treasury وتستدعي `finance_save_expense`. والإصلاح backend في Production أكمل لها أثر Cash Box + Treasury + Journal في نفس العملية.

اختبارها بعد الدمج يجب أن يثبت:

```text
Expense UI
→ finance_save_expense
→ post_journal_entry
→ finance_expenses + finance_expense_lines
→ finance_tax_transactions عند وجود ضريبة
→ cash_box عند الدفع من Treasury
→ treasury.current_balance
→ audit_log / operation registry
```

---

## 12. ما يجب أن يحدث بعد تطبيق Owner للتعديلات

1. طبّق Dispatcher.
2. طبّق `newRecurring`.
3. طبّق `newCheque`.
4. طبّق `newBank`.
5. طبّق `goldTaxCode`.
6. طبّق `goldAddAsset`.
7. طبّق `goldOpenPeriod`.
8. لا تعدل `newExpense` أو `goldTaxSettle` الآن.
9. انشر Mother الجديد.
10. افتح صفحة Mother كاملة.
11. نفذ Browser E2E لكل تبويب Finance.
12. راقب Console من الصفر، ولا تعيد إصلاح ReferenceErrors القديمة إلا إذا ظهرت من جديد.

## 13. الإغلاق الحالي

```text
Production Finance contracts    = CLOSED / DEPLOYED
Production DB foundation        = PRESENT / VERIFIED
Mother dispatcher fix           = READY / OWNER
Recurring UI                    = SURGICAL REPLACEMENT READY
Cheque UI                       = SURGICAL REPLACEMENT READY
Bank UI                         = SURGICAL REPLACEMENT READY
Tax UI                          = SURGICAL REPLACEMENT READY
Fixed Asset UI                  = SURGICAL REPLACEMENT READY
Period UI                       = SURGICAL REPLACEMENT READY
Expense UI                      = KEEP CURRENT / E2E VERIFY
Full Browser E2E                = PENDING OWNER MERGE
```

## 14. إرشاد بداية الجلسة التالية

ابدأ **بالحقيقة الحالية**:

```text
CURRENT GIT
→ latest HEAD
→ direct parent
→ current main.html
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ browser E2E
```

لا تبدأ من `Report218` أو `Report219` أو هذا التقرير كحالة حالية.
اقرأها للاستدلال فقط.

بعد Owner merge، لا تعِد أي إصلاح مغلق دون إثبات regression.
ولا تعتبر Backend PASS = Browser PASS.

> **تذكير حاكم أخير:** `erp-frontend/companies/company-1/main.html` هو Source of Truth الحالي ويجب قراءته بعناية قبل أي جراحة جديدة.
