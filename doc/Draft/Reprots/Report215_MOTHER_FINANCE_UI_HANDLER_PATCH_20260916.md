# Report 215 — جراحة handlers المتبقية في Mother Finance

**النطاق:** `erp-frontend/companies/company-1/main.html` فقط.  
**تنبيه:** لا يعدّل المساعد الملف؛ المالك ينفذ الجراحة.

## الموضع

في الكتلة التي تبدأ بـ:
`var RW_Finance_GoldExtension = (function () {`

وتنتهي قبل:
`window.RW_Finance = RW_Finance;`

ابحث عن السطر الأخير الكامل الذي يبدأ بـ:
`return {journalList:`

احذف **جملة return كاملة حتى آخر `};` في نفس الدالة**، ثم أضف قبلها handlers التالية:

```js
async function goldAddAsset(){
    var h='<div class="grid grid-cols-2 gap-2"><input id="fa_code" class="swal2-input" placeholder="كود الأصل"><input id="fa_name" class="swal2-input" placeholder="اسم الأصل"><input id="fa_cost" type="number" class="swal2-input" placeholder="التكلفة"><input id="fa_salvage" type="number" class="swal2-input" placeholder="قيمة الخردة"><input id="fa_life" type="number" class="swal2-input" placeholder="العمر بالشهور"><input id="fa_date" type="date" value="'+today()+'" class="swal2-input"><input id="fa_service" type="date" value="'+today()+'" class="swal2-input"><select id="fa_method" class="swal2-select"><option value="STRAIGHT_LINE">خط مستقيم</option><option value="DECLINING_BALANCE">رصيد متناقص</option><option value="NONE">بدون إهلاك</option></select><input id="fa_asset_acc" class="swal2-input" placeholder="UUID حساب الأصل"><input id="fa_acc_dep" class="swal2-input" placeholder="UUID مجمع الإهلاك"><input id="fa_dep_exp" class="swal2-input" placeholder="UUID مصروف الإهلاك"><input id="fa_gl" class="swal2-input" placeholder="UUID ربح/خسارة الاستبعاد"><textarea id="fa_notes" class="swal2-textarea" placeholder="ملاحظات"></textarea></div>';
    var r=await Swal.fire({title:'أصل ثابت جديد',html:h,width:800,showCancelButton:true,confirmButtonText:'حفظ'}); if(!r.isConfirmed)return;
    await rpc('save_fixed_asset',{p_company_id:companyId(),p_operation_id:crypto.randomUUID(),p_asset:{asset_code:byId('fa_code').value.trim(),name:byId('fa_name').value.trim(),category:'General',acquisition_date:byId('fa_date').value,in_service_date:byId('fa_service').value,cost:Number(byId('fa_cost').value),salvage_value:Number(byId('fa_salvage').value||0),useful_life_months:Number(byId('fa_life').value),depreciation_method:byId('fa_method').value,asset_account_id:byId('fa_asset_acc').value.trim(),accumulated_depreciation_account_id:byId('fa_acc_dep').value.trim(),depreciation_expense_account_id:byId('fa_dep_exp').value.trim(),disposal_gain_loss_account_id:byId('fa_gl').value.trim(),created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',notes:byId('fa_notes').value}});
    await renderAssets();
}

async function goldDepreciate(id){
    if(typeof Swal!=='undefined'){var c=await Swal.fire({title:'تنفيذ إهلاك؟',text:'سيتم تسجيل الإهلاك كقيد محاسبي.',showCancelButton:true,confirmButtonText:'تنفيذ'});if(!c.isConfirmed)return;}
    await rpc('post_fixed_asset_depreciation',{p_company_id:companyId(),p_asset_id:id,p_operation_id:crypto.randomUUID(),p_event_date:today(),p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'}); await renderAssets();
}

async function goldDispose(id){
    var h='<input id="fd_date" type="date" value="'+today()+'" class="swal2-input"><input id="fd_proc" type="number" class="swal2-input" placeholder="متحصلات البيع"><input id="fd_acc" class="swal2-input" placeholder="UUID حساب المتحصلات"><input id="fd_ref" class="swal2-input" placeholder="المرجع">';
    var r=await Swal.fire({title:'استبعاد/بيع أصل',html:h,showCancelButton:true,confirmButtonText:'تنفيذ'});if(!r.isConfirmed)return;
    await rpc('finance_dispose_asset',{p_company_id:companyId(),p_asset_id:id,p_disposal_date:byId('fd_date').value,p_proceeds:Number(byId('fd_proc').value||0),p_proceeds_account_id:byId('fd_acc').value.trim(),p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_operation_id:crypto.randomUUID(),p_reference:byId('fd_ref').value.trim()}); await renderAssets();
}

async function goldTaxCode(){
    var h='<input id="tc_code" class="swal2-input" placeholder="الكود"><input id="tc_name" class="swal2-input" placeholder="الاسم"><input id="tc_rate" type="number" class="swal2-input" placeholder="النسبة"><input id="tc_sales" class="swal2-input" placeholder="UUID حساب ضريبة المخرجات"><input id="tc_purchase" class="swal2-input" placeholder="UUID حساب ضريبة المدخلات"><input id="tc_settle" class="swal2-input" placeholder="UUID حساب التسوية">';
    var r=await Swal.fire({title:'نوع ضريبة جديد',html:h,showCancelButton:true,confirmButtonText:'حفظ'});if(!r.isConfirmed)return;
    await rpc('finance_save_tax_code',{p_company_id:companyId(),p_id:null,p_code:byId('tc_code').value.trim(),p_name:byId('tc_name').value.trim(),p_rate:Number(byId('tc_rate').value),p_sales_account_id:byId('tc_sales').value.trim(),p_purchase_account_id:byId('tc_purchase').value.trim(),p_settlement_account_id:byId('tc_settle').value.trim(),p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'}); await renderTax();
}

async function goldTaxSettle(){
    var h='<input id="ts_from" type="date" value="'+today().slice(0,8)+'01" class="swal2-input"><input id="ts_to" type="date" value="'+today()+'" class="swal2-input"><input id="ts_code" class="swal2-input" placeholder="كود التسوية">';
    var r=await Swal.fire({title:'تسوية ضريبية',html:h,showCancelButton:true,confirmButtonText:'تنفيذ'});if(!r.isConfirmed)return;
    await rpc('finance_tax_settle',{p_company_id:companyId(),p_from:byId('ts_from').value,p_to:byId('ts_to').value,p_settlement_code:byId('ts_code').value.trim(),p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_operation_id:crypto.randomUUID()}); await renderTax();
}

async function goldOpenPeriod(){
    var h='<input id="po_code" class="swal2-input" placeholder="كود الفترة"><input id="po_year" type="number" value="'+new Date().getFullYear()+'" class="swal2-input"><input id="po_from" type="date" value="'+today().slice(0,4)+'-01-01" class="swal2-input"><input id="po_to" type="date" value="'+today().slice(0,4)+'-12-31" class="swal2-input">';
    var r=await Swal.fire({title:'فتح فترة محاسبية',html:h,showCancelButton:true,confirmButtonText:'حفظ'});if(!r.isConfirmed)return;
    await rpc('finance_open_period',{p_company_id:companyId(),p_period_code:byId('po_code').value.trim(),p_fiscal_year:Number(byId('po_year').value),p_start_date:byId('po_from').value,p_end_date:byId('po_to').value,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'}); await renderPeriods();
}

async function goldChequeTransition(id,status){
    var options = status==='ISSUED'?['DELIVERED','DEPOSITED','CANCELLED']:status==='DELIVERED'?['DEPOSITED','CANCELLED','BOUNCED']:status==='DEPOSITED'?['CLEARED','BOUNCED']:[];
    if(!options.length)throw new Error('لا توجد انتقالات مسموحة لهذه الحالة');
    var r=await Swal.fire({title:'تغيير حالة الشيك',input:'select',inputOptions:Object.fromEntries(options.map(function(x){return [x,x]})),inputPlaceholder:'اختر الحالة',showCancelButton:true,confirmButtonText:'تنفيذ'});if(!r.isConfirmed)return;
    await rpc('finance_transition_cheque',{p_company_id:companyId(),p_cheque_id:id,p_to_status:r.value,p_event_date:today(),p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_reference:'',p_notes:'Mother Finance'}); await renderCheques();
}

return {
    journalList:journalList,
    renderAssets:renderAssets,
    renderTax:renderTax,
    renderPeriods:renderPeriods,
    renderBankReconcile:renderBankReconcile,
    renderRecurring:renderRecurring,
    renderExpenses:renderExpenses,
    renderCheques:renderCheques,
    journalDetail:journalDetail,
    reverse:reverse,
    newRecurring:newRecurring,
    runRecurring:runRecurring,
    newCheque:newCheque,
    newBank:newBank,
    closeBank:closeBank,
    closePeriod:closePeriod,
    reopenPeriod:reopenPeriod,
    goldAddAsset:goldAddAsset,
    goldDepreciate:goldDepreciate,
    goldDispose:goldDispose,
    goldTaxCode:goldTaxCode,
    goldTaxSettle:goldTaxSettle,
    goldOpenPeriod:goldOpenPeriod,
    goldChequeTransition:goldChequeTransition
};
```

ثم **لا تحذف** assignments الموجودة بعد `window.RW_Finance = RW_Finance;`؛ أضف بعدها مباشرة:

```js
RW_Finance._goldAddAsset = RW_Finance_GoldExtension.goldAddAsset;
RW_Finance._goldDepreciate = RW_Finance_GoldExtension.goldDepreciate;
RW_Finance._goldDispose = RW_Finance_GoldExtension.goldDispose;
RW_Finance._goldTaxCode = RW_Finance_GoldExtension.goldTaxCode;
RW_Finance._goldTaxSettle = RW_Finance_GoldExtension.goldTaxSettle;
RW_Finance._goldOpenPeriod = RW_Finance_GoldExtension.goldOpenPeriod;
RW_Finance._goldChequeTransition = RW_Finance_GoldExtension.goldChequeTransition;
```

## 2. ملاحظة مهمة

هذا patch يستكمل handlers المفقودة ويحوّل الأزرار من `undefined` إلى RPC calls حقيقية. حقول UUID الخاصة بالحسابات مقصودة كحل جراحي أولي، وليست UI المثالي النهائي؛ يمكن تحسينها لاحقًا إلى account selectors بعد إغلاق E2E الأساسي، دون تغيير backend contract.
