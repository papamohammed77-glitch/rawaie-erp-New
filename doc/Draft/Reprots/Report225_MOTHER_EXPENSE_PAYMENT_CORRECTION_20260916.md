# Report225 — تصحيح نهائي لجراحة سند الصرف / المصروفات — 2026-09-16

## التنبيه الحاكم
الهدف هو الوصول إلى تجربة `مصروف جديد` مكتملة وظيفيًا، لا مجرد إصلاح شكلي. Source of Truth الحالي هو `erp-frontend/companies/company-1/main.html`، والحقيقة الحالية تعتمد فقط على CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## التصحيح الذي اكتشفه التحقيق
بعد كتابة Report224 تم إجراء تحقق إضافي على `_cache` في Mother الحالية.

النتيجة المثبتة:

```javascript
var _cache = { loaded: false, accountsTree: [], accountsFlat: [], treasury: [] };
```

ولا توجد `branches` داخل `_cache`.

لذلك فإن الاعتماد على:

```javascript
_cache.branches
```

كان سيعيد قائمة فروع فارغة، رغم أن Production تحتوي فروعًا صحيحة.

تم اعتماد التصحيح التالي: **`_newPayment()` يجلب فروع الشركة مباشرة من `branches` عند فتح شاشة سند الصرف**، مع company scope صريح.

## الجراحة النهائية في Mother

الملف:

```text
companies/company-1/main.html
```

البداية المثبتة:

```text
15836
```

ابحث حرفيًا عن:

```text
function _newPayment() {
```

واحذف من هذا السطر وحتى آخر سطر من الدالة:

```text
    async function _savePayment() {
```

ومحتواها الكامل حتى القوس الذي يغلقها، وقبل بداية:

```text
    function _renderTransfers() {
```

ثم استبدل المجموعة الكاملة بالكتلة التالية.

```javascript
    async function _newPayment() {
        var content = byId('finance-content');
        if (!content) return;

        var cid = _companyId();
        var branchResult = await supabase.from('branches')
            .select('id,branch_code,name')
            .eq('company_id', cid)
            .eq('is_active', true)
            .order('name');
        if (branchResult.error) {
            _showToast(branchResult.error.message || 'فشل تحميل الفروع', 'error');
            return;
        }

        var branches = branchResult.data || [];
        var treasuryOptions = _cache.treasury.map(function(t) {
            return '<option value="' + _esc(t.id) + '">' +
                _esc(t.account_name) + ' (' + _esc(t.account_code) + ')' +
            '</option>';
        }).join('');

        var branchOptions = branches.map(function(b) {
            return '<option value="' + _esc(b.id) + '">' +
                _esc(b.name || b.branch_code) +
            '</option>';
        }).join('');

        var operationId = (window.crypto && crypto.randomUUID) ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random();
        content.dataset.paymentOperationId = operationId;

        var html =
            '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
                '<div class="flex flex-wrap justify-between items-center gap-3 mb-5">' +
                    '<div>' +
                        '<h2 class="text-xl font-black"><i class="fa-solid fa-arrow-up ml-2 text-red-600"></i>مصروف جديد</h2>' +
                        '<div class="text-sm text-gray-500 mt-1">صرف من خزينة محددة إلى حساب واحد أو عدة حسابات.</div>' +
                    '</div>' +
                    '<button type="button" onclick="RW_Finance.renderSubTab(\'payments\')" class="text-gray-500 hover:text-gray-700">' +
                        '<i class="fa-solid fa-xmark text-xl"></i>' +
                    '</button>' +
                '</div>' +
                '<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-5">' +
                    '<div><label class="block text-sm font-bold mb-1">التاريخ</label><input type="date" id="pmt-date" class="border rounded-xl p-3 w-full" value="' + new Date().toISOString().slice(0,10) + '"></div>' +
                    '<div><label class="block text-sm font-bold mb-1">الفرع</label><select id="pmt-branch" class="border rounded-xl p-3 w-full"><option value="">اختر الفرع</option>' + branchOptions + '</select></div>' +
                    '<div><label class="block text-sm font-bold mb-1">الخزينة</label><select id="pmt-cashbox" class="border rounded-xl p-3 w-full"><option value="">اختر الخزينة</option>' + treasuryOptions + '</select></div>' +
                    '<div><label class="block text-sm font-bold mb-1">المستفيد</label><input type="text" id="pmt-beneficiary" class="border rounded-xl p-3 w-full" placeholder="اسم المستفيد / الجهة"></div>' +
                    '<div class="md:col-span-4"><label class="block text-sm font-bold mb-1">المرجع</label><input type="text" id="pmt-reference" class="border rounded-xl p-3 w-full" placeholder="رقم فاتورة، مستند، إيصال..."></div>' +
                '</div>' +
                '<div class="border rounded-2xl overflow-hidden">' +
                    '<div class="bg-slate-50 p-3 flex flex-wrap justify-between items-center gap-2">' +
                        '<div class="font-black">بنود المصروف</div>' +
                        '<button type="button" onclick="RW_Finance._addPaymentLine()" class="text-red-600 font-bold"><i class="fa-solid fa-plus-circle ml-1"></i> إضافة حساب</button>' +
                    '</div>' +
                    '<div class="hidden md:grid grid-cols-12 gap-2 px-3 py-2 text-xs font-bold text-gray-500 border-b"><div class="col-span-5">الحساب</div><div class="col-span-3">البيان</div><div class="col-span-3">المبلغ</div><div class="col-span-1"></div></div>' +
                    '<div id="pmt-lines" class="p-3"></div>' +
                '</div>' +
                '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mt-4">' +
                    '<div class="rounded-xl bg-slate-50 border p-4"><div class="text-xs text-gray-500">عدد الحسابات</div><div id="pmt-count" class="text-xl font-black">0</div></div>' +
                    '<div class="rounded-xl bg-red-50 border border-red-100 p-4"><div class="text-xs text-red-700">إجمالي المصروف</div><div id="pmt-total" class="text-2xl font-black text-red-700">0.00</div></div>' +
                    '<div class="rounded-xl bg-emerald-50 border border-emerald-100 p-4"><div class="text-xs text-emerald-700">حالة الخزينة</div><div id="pmt-balance-status" class="font-black text-emerald-700">اختر الخزينة</div></div>' +
                '</div>' +
                '<div class="mt-4"><label class="block text-sm font-bold mb-1">وصف العملية</label><textarea id="pmt-notes" class="border rounded-xl p-3 w-full" rows="3" placeholder="بيان السند أو الملاحظات"></textarea></div>' +
                '<div class="flex justify-end gap-3 mt-5">' +
                    '<button type="button" onclick="RW_Finance.renderSubTab(\'payments\')" class="px-5 py-2 border rounded-xl">إلغاء</button>' +
                    '<button type="button" onclick="RW_Finance._savePayment()" class="px-6 py-2 bg-red-600 text-white rounded-xl font-black"><i class="fa-solid fa-check ml-1"></i> حفظ وترحيل</button>' +
                '</div>' +
            '</div>';

        safeHTML(content, html);
        _addPaymentLine();
        _recalcPaymentTotal();
    }

    function _addPaymentLine() {
        var accountOptions = _cache.accountsFlat.map(function(a) {
            return '<option value="' + _esc(a.id) + '">' + _esc(a.account_name) + ' (' + _esc(a.account_code) + ')</option>';
        }).join('');
        var html =
            '<div class="pmt-line grid grid-cols-1 md:grid-cols-12 gap-2 mb-3 bg-gray-50 border rounded-xl p-3">' +
                '<div class="md:col-span-5"><label class="md:hidden block text-xs font-bold mb-1">الحساب</label><select class="pmt-line-account border rounded-lg p-2 w-full text-sm"><option value="">اختر الحساب</option>' + accountOptions + '</select></div>' +
                '<div class="md:col-span-3"><label class="md:hidden block text-xs font-bold mb-1">البيان</label><input type="text" class="pmt-line-desc border rounded-lg p-2 w-full text-sm" placeholder="بيان البند"></div>' +
                '<div class="md:col-span-3"><label class="md:hidden block text-xs font-bold mb-1">المبلغ</label><input type="number" step="0.01" min="0.01" class="pmt-line-amount border rounded-lg p-2 w-full text-sm" placeholder="0.00" oninput="RW_Finance._recalcPaymentTotal()"></div>' +
                '<div class="md:col-span-1 flex items-end justify-center"><button type="button" onclick="RW_Finance._removePaymentLine(this)" class="text-red-500 px-2 py-2" title="حذف البند"><i class="fa-solid fa-circle-minus"></i></button></div>' +
            '</div>';
        var host = byId('pmt-lines');
        if (host) host.insertAdjacentHTML('beforeend', html);
        _recalcPaymentTotal();
    }

    function _removePaymentLine(btn) {
        var row = btn && btn.closest ? btn.closest('.pmt-line') : null;
        if (row) row.remove();
        _recalcPaymentTotal();
    }

    function _recalcPaymentTotal() {
        var total = 0, count = 0;
        document.querySelectorAll('.pmt-line').forEach(function(l) {
            var account = l.querySelector('.pmt-line-account');
            var amount = l.querySelector('.pmt-line-amount');
            if (account && account.value) count++;
            total += parseFloat(amount && amount.value || 0) || 0;
        });
        safeText(byId('pmt-total'), _fmtNum(total));
        safeText(byId('pmt-count'), String(count));
        var treasuryId = byId('pmt-cashbox') ? byId('pmt-cashbox').value : '';
        var status = byId('pmt-balance-status');
        if (!status) return;
        if (!treasuryId) { safeText(status, 'اختر الخزينة'); status.className='font-black text-emerald-700'; return; }
        var treasury = null;
        for (var i=0;i<_cache.treasury.length;i++) if (_cache.treasury[i].id===treasuryId) { treasury=_cache.treasury[i]; break; }
        if (!treasury) { safeText(status,'الخزينة غير متاحة'); status.className='font-black text-red-700'; return; }
        var balance=Number(treasury.current_balance||0);
        if(total>balance){ safeText(status,'الرصيد غير كافٍ: '+_fmtNum(balance)); status.className='font-black text-red-700'; }
        else { safeText(status,'متاح: '+_fmtNum(balance)); status.className='font-black text-emerald-700'; }
    }

    async function _savePayment() {
        var host=byId('finance-content'); if(!host) return;
        var branchId=byId('pmt-branch')?byId('pmt-branch').value:'';
        var treasuryId=byId('pmt-cashbox')?byId('pmt-cashbox').value:'';
        var date=byId('pmt-date')?byId('pmt-date').value:'';
        var beneficiary=byId('pmt-beneficiary')?byId('pmt-beneficiary').value.trim():'';
        var reference=byId('pmt-reference')?byId('pmt-reference').value.trim():'';
        var notes=byId('pmt-notes')?byId('pmt-notes').value.trim():'';
        var lines=[];
        document.querySelectorAll('.pmt-line').forEach(function(l){
            var accountId=l.querySelector('.pmt-line-account')?l.querySelector('.pmt-line-account').value:'';
            var description=l.querySelector('.pmt-line-desc')?l.querySelector('.pmt-line-desc').value.trim():'';
            var amount=parseFloat(l.querySelector('.pmt-line-amount')?l.querySelector('.pmt-line-amount').value:0)||0;
            if(accountId&&amount>0) lines.push({accountId:accountId,description:description,amount:amount,taxAmount:0});
        });
        if(!branchId){_showToast('اختر الفرع','warning');return;}
        if(!treasuryId){_showToast('اختر الخزينة','warning');return;}
        if(!date){_showToast('حدد تاريخ السند','warning');return;}
        if(!lines.length){_showToast('أضف حسابًا واحدًا على الأقل','warning');return;}
        var seen={};
        for(var i=0;i<lines.length;i++){
            seen[lines[i].accountId]=(seen[lines[i].accountId]||0)+1;
            if(seen[lines[i].accountId]>1){_showToast('لا تكرر نفس الحساب داخل السند؛ اجمع القيمة في بند واحد.','warning');return;}
        }
        var total=lines.reduce(function(sum,x){return sum+x.amount+x.taxAmount;},0);
        var treasury=null;
        for(var t=0;t<_cache.treasury.length;t++) if(_cache.treasury[t].id===treasuryId){treasury=_cache.treasury[t];break;}
        if(!treasury){_showToast('الخزينة غير موجودة','error');return;}
        if(Number(treasury.current_balance||0)<total){_showToast('رصيد الخزينة غير كافٍ','error');return;}
        var operationId=host.dataset.paymentOperationId||((window.crypto&&crypto.randomUUID)?crypto.randomUUID():String(Date.now())+'-'+Math.random());
        host.dataset.paymentOperationId=operationId;
        _showLoader('جاري حفظ المصروف وترحيله...');
        try{
            var result=await supabase.rpc('finance_save_expense',{
                p_company_id:_companyId(),p_expense_id:null,
                p_expense_code:'EXP-'+operationId.replace(/-/g,'').slice(0,16).toUpperCase(),
                p_expense_date:date,p_beneficiary_name:beneficiary||null,p_category_id:null,
                p_treasury_id:treasuryId,p_description:notes||'سند صرف',p_attachment_url:null,
                p_reference:reference||null,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',
                p_operation_id:operationId,p_branch_id:branchId,p_lines:lines
            });
            if(result.error) throw result.error;
            var data=result.data||{};
            delete host.dataset.paymentOperationId;
            _showToast(data.duplicate?'السند موجود بالفعل ولم يُكرر.':'تم حفظ المصروف وترحيله بنجاح','success');
            await renderSubTab('payments');
        }catch(e){_showToast(e.message||'فشل حفظ سند الصرف','error');}
        finally{_hideLoader();}
    }
```

## 3. توحيد تبويب المصروفات

في `renderExpenses` الحالية غيّر:

```javascript
if(add) add.onclick=function(){RW_Finance._goldNewExpense();};
```

إلى:

```javascript
if(add) add.onclick=function(){RW_Finance._newPayment();};
```

ثم يجب أن يستخدم جدول المصروفات:

```text
finance_list_expenses_v2
```

بدل:

```text
finance_list_expenses
```

حتى يظهر:

```text
الفرع
الخزينة
عدد الحسابات
```

الموجودة الآن في العقد الجديد.

## 4. الحالة Production بعد التصحيح

لا توجد بيانات تجريبية دائمة.

Production ما زالت:

```text
finance_expenses      = 0
finance_expense_lines = 0
```

وتم اختبار عقد multi-line داخل Transaction مع `ROLLBACK`، إضافة إلى اختبار idempotency.

## 5. القرار الخاص بـ`newExpense`

لا يُحذف الآن.

تم إثبات أن consumer التشغيلي المطلوب يمكن توحيده عبر `_newPayment`، ولذلك لا توجد حاجة إلى حذف تاريخي إضافي قبل E2E.

## 6. الحالة النهائية لهذه الوحدة

```text
Production schema              = DEPLOYED
Branch dimension               = DEPLOYED
Multi-account contract         = DEPLOYED
Payment Edge v7                = DEPLOYED
Idempotency                    = VERIFIED transactionally
Mother surgery                 = PREPARED
Branch cache issue             = CORRECTED
Browser E2E                    = OPEN until owner merge
```

## 7. توجيه المساعد التالي

لا يبدأ من Report224 أو Report225 باعتبارهما حقيقة حالية.

ابدأ من:

```text
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ LATEST COMMIT + PARENT
```

ثم افتح الدالة نفسها، وحدد الـConsumer، وافتح RPC/Schema المقابل، ثم نفّذ Closure Unit واحدة، واختبر Production، وبعدها أعطِ المالك جراحة Mother كاملة ذات حدود واضحة.

ولا تعد إصلاح شيء ثبت أنه مغلق.
