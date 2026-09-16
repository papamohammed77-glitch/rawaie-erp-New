# Report223 — MOTHER FINANCE COMPLETION / FORENSIC CLOSURE — 2026-09-16

> **تنبيه حاكم في بداية التقرير:** ملف النظام الأم الحالي `papamohammed77-glitch/erp-frontend/companies/company-1/main.html` هو **Source of Truth الوحيد** لهذه المهمة. لا يجوز اعتبار أي تقرير قديم أو fragment تاريخي حالةً حالية. الحقيقة الحالية بُنيت من: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## 1. نقطة البداية الحقيقية

تم استكمال المهمة من `Report222` وليس من الصفر.

الحالة المثبتة في CURRENT GIT:

- Mother HEAD: `0677e474a345a7199838c1379c21787a8078f0eb`
- Parent: `1b1db605b1e72534a8e5a61146e1fd0ee6832ecf`
- Mother blob: `360818482a72011142acd58b9e96005a7f22ee96`
- آخر commit `0677e474…` يعالج `newCheque` و`newBank`، وبخاصة الانتقال من `treasury.name` إلى `treasury.account_name`؛ لذلك لم تتم إعادة إصلاحهما.

`forensic_main_assembly.yml` تمت مراجعته مرة أخرى، وهو يشير صراحةً إلى:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

لا حاجة لتعديل هذا الملف.

## 2. حالة Production المالية الحالية

تمت إعادة مطابقة Production في Supabase `fiilmooggumokxanwiyx`.

الكيانات المالية الأساسية موجودة بالفعل:

- `chart_of_accounts`
- `journal_entries`
- `journal_lines`
- `treasury`
- `cash_box`
- `finance_expense_categories`
- `finance_expenses`
- `finance_expense_lines`
- `finance_cheques`
- `finance_cheque_events`
- `finance_bank_statements`
- `finance_bank_statement_lines`
- `finance_tax_codes`
- `finance_tax_transactions`
- `finance_tax_settlements`
- `fixed_assets`
- `fixed_asset_events`
- `finance_periods`
- `recurring_journal_templates`
- `recurring_journal_lines`
- `finance_recurring_runs`

الحالة الحالية للبيانات:

```text
finance_periods              = 1
finance_expenses             = 0
finance_cheques              = 0
finance_bank_statements      = 0
finance_tax_codes            = 0
fixed_assets                  = 0
recurring_journal_templates   = 0
journal_entries               = 2
```

الـ2 journal entries الموجودان حاليًا كلاهما `Cancelled` ولا يحتويان على خطوط محاسبية فعالة؛ لا توجد بيانات تشغيلية مالية تجريبية جديدة تم إنشاؤها في هذه الجولة.

## 3. العقد المالي المركزي المثبت

Production تحتوي على محرك المحاسبة المركزي `post_journal_entry` ولا توجد حاجة لإنشاء Journal Engine ثانٍ.

كما أن محركات البنوك والشيكات والأصول والضرائب والفترات والمصروفات موجودة بالفعل كـRPCs آمنة ومربوطة بعقد الشركة الحالية، ومنها:

```text
finance_list_expenses
finance_save_expense
finance_list_cheques
finance_save_cheque
finance_transition_cheque
finance_bank_reconciliation_summary
finance_bank_match_candidates
finance_match_bank_line
finance_bank_unmatch_line
finance_include_bank_line
finance_exclude_bank_line
finance_close_bank_statement
finance_save_bank_statement
finance_dispose_asset
finance_period_guard
finance_open_period
finance_close_period
finance_reopen_period
finance_save_recurring
finance_run_recurring
finance_save_tax_code
finance_tax_post
finance_tax_record_manual
finance_tax_report
finance_tax_settle
```

وقد تم التحقق من أن الدوال المالية المقصودة تتحقق من `app_private.current_user_company_id()`، فلا توجد حاجة لإنشاء جدول أو Edge Function بديل لإغلاق الفجوات الثلاث الموجودة في Mother.

## 4. الفجوات الفعلية في CURRENT SOURCE

البحث الجنائي في Mother الحالية أثبت ثلاث فجوات حقيقية فقط ضمن النطاق المطلوب، وليست فجوات افتراضية:

### 4.1 `renderBankReconcile`

الدالة الحالية مجرد قائمة كشوف بنكية وزر إغلاق، ولا تعرض Workspace المطابقة الفعلية، رغم أن Production توفر محركات المطابقة والترشيح والإلغاء والاستبعاد والإدراج والإغلاق.

الـCurrent Source يربط التبويب بهذه الدالة عبر:

```text
RW_Finance._renderBankReconcile
```

والتعريف الحالي ينتهي حرفيًا بـ:

```text
card('مطابقة البنك','fa-building-columns',h); }
```

المرجع السطري المثبت تاريخيًا لهذه المنطقة يقارب `17283` في Mother الحالية، لكن يجب تحديد الدالة بالاسم والحد النهائي أعلاه لا بالرقم وحده، لأن GitHub connector لا يعيد line map موثوقًا لهذا الملف الكبير عند القراءة الجزئية.

### 4.2 `renderExpenses`

الدالة موجودة وليست Stub، ولكنها غير مناسبة لواجهة ERP احترافية لأنها تبدأ بـ:

```javascript
var from=prompt('من تاريخ YYYY-MM-DD',today().slice(0,8)+'01')||today().slice(0,8)+'01';
var to=prompt('إلى تاريخ YYYY-MM-DD',today())||today();
```

وهذه هي حالة `prompt()` الوحيدة التي بقيت في نطاق Finance بعد التحقق من CURRENT SOURCE. لذلك المطلوب ليس Backend جديدًا، بل استبدال واجهة اختيار التاريخ بواجهة داخلية كاملة.

الدالة الحالية تنتهي بـ:

```text
card('المصروفات','fa-money-bill-wave',h); }
```

### 4.3 `goldDispose`

الدالة الحالية تطلب:

```text
UUID حساب المتحصلات
```

يدويًا، بينما Production لديها `chart_of_accounts` و`finance_dispose_asset` مع تحقق Company-scoped للحساب.

الدالة الحالية تنتهي بـ:

```text
await renderAssets();
}
```

ولا يلزم أي تعديل Production؛ المطلوب Frontend contract alignment فقط.

## 5. الجراحات المطلوبة في Mother — لا تنفذها في Production

### الجراحة A — `renderBankReconcile`

**ابحث عن:**

```text
async function renderBankReconcile(){
```

واحذف الدالة كاملة حتى آخر سطر:

```text
card('مطابقة البنك','fa-building-columns',h); }
```

ثم استبدلها بالدالة التالية كاملة:

```javascript
async function renderBankReconcile(){
    var cid=companyId();

    var results=await Promise.all([
        supabase.from('finance_bank_statements')
            .select('id,statement_ref,statement_date,treasury_id,opening_balance,closing_balance,status,currency_code,created_by')
            .eq('company_id',cid)
            .order('statement_date',{ascending:false}),
        supabase.from('treasury')
            .select('id,account_name,current_balance')
            .eq('company_id',cid)
            .eq('is_active',true)
            .order('account_name')
    ]);

    if(results[0].error) throw results[0].error;
    if(results[1].error) throw results[1].error;

    var statements=results[0].data||[];
    var treasuries=results[1].data||[];
    var ids=statements.map(function(s){return s.id;});

    var lineRows=[];
    if(ids.length){
        var lr=await supabase
            .from('finance_bank_statement_lines')
            .select('id,statement_id,txn_date,description,amount,reference,matched,excluded,excluded_reason,matched_cash_box_id,matched_journal_entry_id,matched_at,matched_by,matched_notes')
            .eq('company_id',cid)
            .in('statement_id',ids)
            .order('txn_date',{ascending:true});
        if(lr.error) throw lr.error;
        lineRows=lr.data||[];
    }

    var summaryRows=[];
    if(statements.length){
        summaryRows=await Promise.all(statements.map(async function(s){
            var treasuryId=s.treasury_id;
            try{
                var x=await rpc('finance_bank_reconciliation_summary',{
                    p_company_id:cid,
                    p_treasury_id:treasuryId,
                    p_statement_id:s.id
                });
                return Array.isArray(x)?(x[0]||null):x||null;
            }catch(err){
                return null;
            }
        }));
    }

    var treasuryMap={};
    treasuries.forEach(function(t){treasuryMap[t.id]=t;});

    function userEmail(){return (RW_STATE.user&&RW_STATE.user.email)||'mother';}
    function statementLines(statementId){return lineRows.filter(function(l){return l.statement_id===statementId;});}
    function lineState(l){
        if(l.excluded) return '<span class="px-2 py-1 rounded-lg bg-amber-100 text-amber-800 font-bold">مستبعد</span>';
        if(l.matched) return '<span class="px-2 py-1 rounded-lg bg-emerald-100 text-emerald-800 font-bold">مطابق</span>';
        return '<span class="px-2 py-1 rounded-lg bg-red-100 text-red-800 font-bold">غير مطابق</span>';
    }

    window.RW_FINANCE_BANK={
        match:async function(lineId){
            var candidates=await rpc('finance_bank_match_candidates',{p_company_id:cid,p_line_id:lineId})||[];
            if(!Array.isArray(candidates)) candidates=[candidates];
            if(!candidates.length){
                await Swal.fire({icon:'info',title:'لا توجد مطابقات مرشحة',text:'لم يجد النظام حركة نقدية أو قيدًا مناسبًا لهذه الحركة.'});
                return;
            }

            var html='<div class="space-y-2 text-right">';
            candidates.forEach(function(c,i){
                html+='<label class="flex items-start gap-3 border rounded-xl p-3 cursor-pointer bg-slate-50 hover:bg-white">'+
                    '<input type="radio" name="rw_bank_candidate" value="'+i+'" class="mt-1">'+
                    '<span class="flex-1"><b>'+esc(c.candidate_type==='CASH_BOX'?'حركة خزينة':'قيد محاسبي')+'</b>'+\
                    '<span class="block text-sm text-slate-600">'+esc(c.reference||'')+'</span>'+\
                    '<span class="block text-sm">'+esc(c.description||'')+' — '+money(c.amount||0)+'</span>'+\
                    '<span class="block text-xs text-slate-500">'+esc(c.txn_date||'')+'</span></span></label>';
            });
            html+='</div>';

            var r=await Swal.fire({
                title:'اختيار المطابقة',
                html:html,
                width:800,
                showCancelButton:true,
                confirmButtonText:'تأكيد المطابقة',
                cancelButtonText:'إلغاء',
                preConfirm:function(){
                    var picked=document.querySelector('input[name="rw_bank_candidate"]:checked');
                    if(!picked){Swal.showValidationMessage('اختر حركة أو قيدًا أولًا');return false;}
                    return candidates[Number(picked.value)];
                }
            });
            if(!r.isConfirmed)return;

            var c=r.value;
            await rpc('finance_match_bank_line',{
                p_company_id:cid,
                p_line_id:lineId,
                p_cash_box_id:c.candidate_type==='CASH_BOX'?c.candidate_id:null,
                p_journal_entry_id:c.candidate_type==='JOURNAL'?c.candidate_id:null
            });
            await renderBankReconcile();
        },

        unmatch:async function(lineId){
            var r=await Swal.fire({title:'إلغاء المطابقة؟',text:'سيعود السطر إلى حالة غير مطابق.',icon:'warning',showCancelButton:true,confirmButtonText:'إلغاء المطابقة',cancelButtonText:'إلغاء'});
            if(!r.isConfirmed)return;
            await rpc('finance_bank_unmatch_line',{p_company_id:cid,p_line_id:lineId,p_created_by:userEmail()});
            await renderBankReconcile();
        },

        exclude:async function(lineId){
            var r=await Swal.fire({
                title:'استبعاد حركة بنكية',
                input:'textarea',
                inputPlaceholder:'سبب الاستبعاد إلزامي',
                showCancelButton:true,
                confirmButtonText:'استبعاد',
                cancelButtonText:'إلغاء',
                inputValidator:function(v){return (v||'').trim()?'': 'سبب الاستبعاد مطلوب';}
            });
            if(!r.isConfirmed)return;
            await rpc('finance_exclude_bank_line',{p_company_id:cid,p_line_id:lineId,p_reason:r.value,p_created_by:userEmail()});
            await renderBankReconcile();
        },

        include:async function(lineId){
            await rpc('finance_include_bank_line',{p_company_id:cid,p_line_id:lineId,p_created_by:userEmail()});
            await renderBankReconcile();
        }
    };

    var h='<div class="space-y-5">'+
        '<div class="flex flex-wrap items-center justify-between gap-3">'+
            '<div><div class="text-lg font-black">مطابقة البنك</div><div class="text-sm text-slate-500">مراجعة الكشف، مطابقة الحركات، الاستبعاد، والإغلاق من نفس الشاشة.</div></div>'+
            '<button onclick="RW_Finance._goldNewBankStatement()" class="bg-sky-700 text-white px-4 py-2 rounded-xl font-bold">كشف بنكي جديد</button>'+
        '</div>';

    if(!statements.length){
        h+='<div class="rounded-2xl border border-dashed p-10 text-center text-slate-500">لا توجد كشوف بنكية حتى الآن.</div>';
    }

    statements.forEach(function(s,idx){
        var t=treasuryMap[s.treasury_id];
        var sum=summaryRows[idx]||{};
        var lines=statementLines(s.id);
        var unmatched=Number(sum.unmatched_count??lines.filter(function(l){return !l.matched&&!l.excluded;}).length)||0;
        var matched=Number(sum.matched_count??lines.filter(function(l){return l.matched;}).length)||0;
        var excluded=lines.filter(function(l){return l.excluded;}).length;

        h+='<div class="rounded-2xl border bg-white shadow-sm overflow-hidden">'+
            '<div class="p-4 border-b bg-slate-50 flex flex-wrap items-center justify-between gap-3">'+
                '<div><div class="font-black">'+esc(s.statement_ref)+'</div><div class="text-sm text-slate-500">'+esc(s.statement_date)+' — '+esc(t?t.account_name:'خزينة غير معروفة')+'</div></div>'+\
                '<div class="flex flex-wrap gap-2 text-xs">'+\
                    '<span class="px-3 py-2 rounded-xl bg-emerald-100 text-emerald-800 font-bold">مطابق: '+matched+'</span>'+\
                    '<span class="px-3 py-2 rounded-xl bg-red-100 text-red-800 font-bold">غير مطابق: '+unmatched+'</span>'+\
                    '<span class="px-3 py-2 rounded-xl bg-amber-100 text-amber-800 font-bold">مستبعد: '+excluded+'</span>'+\
                    '<span class="px-3 py-2 rounded-xl bg-slate-200 text-slate-800 font-bold">الحالة: '+esc(s.status)+'</span>'+\
                '</div>'+\
            '</div>'+\
            '<div class="p-4 grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">'+\
                '<div class="rounded-xl bg-blue-50 p-3"><span class="block text-slate-500">افتتاحي</span><b>'+money(s.opening_balance)+'</b></div>'+\
                '<div class="rounded-xl bg-indigo-50 p-3"><span class="block text-slate-500">ختامي كشف البنك</span><b>'+money(s.closing_balance)+'</b></div>'+\
                '<div class="rounded-xl bg-slate-100 p-3"><span class="block text-slate-500">الرصيد الحالي للخزينة</span><b>'+money(t?t.current_balance:0)+'</b></div>'+\
            '</div>';

        if(lines.length){
            h+='<div class="overflow-x-auto"><table class="w-full text-sm"><thead><tr class="bg-slate-100"><th class="p-2 text-right">التاريخ</th><th class="p-2 text-right">الوصف</th><th class="p-2 text-right">المرجع</th><th class="p-2 text-right">المبلغ</th><th class="p-2 text-right">الحالة</th><th class="p-2 text-right">إجراء</th></tr></thead><tbody>';
            lines.forEach(function(l){
                var actions='';
                if(l.excluded){
                    if(s.status!=='RECONCILED') actions+='<button onclick="RW_FINANCE_BANK.include(\''+esc(l.id)+'\')" class="text-emerald-700 font-bold ml-3">إعادة إدراج</button>';
                }else if(l.matched){
                    if(s.status!=='RECONCILED') actions+='<button onclick="RW_FINANCE_BANK.unmatch(\''+esc(l.id)+'\')" class="text-amber-700 font-bold ml-3">إلغاء المطابقة</button>';
                }else{
                    if(s.status!=='RECONCILED'){
                        actions+='<button onclick="RW_FINANCE_BANK.match(\''+esc(l.id)+'\')" class="text-indigo-700 font-bold ml-3">مطابقة</button>';
                        actions+='<button onclick="RW_FINANCE_BANK.exclude(\''+esc(l.id)+'\')" class="text-amber-700 font-bold">استبعاد</button>';
                    }
                }
                h+='<tr class="border-t"><td class="p-2">'+esc(l.txn_date)+'</td><td class="p-2">'+esc(l.description||'')+'</td><td class="p-2">'+esc(l.reference||'')+'</td><td class="p-2 font-black">'+money(l.amount)+'</td><td class="p-2">'+lineState(l)+'</td><td class="p-2">'+actions+'</td></tr>';
            });
            h+='</tbody></table></div>';
        }else{
            h+='<div class="px-4 pb-4 text-sm text-slate-500">لا توجد حركات في هذا الكشف.</div>';
        }

        h+='<div class="p-4 border-t flex flex-wrap justify-end gap-2">'+
            (s.status!=='RECONCILED'?'<button onclick="RW_Finance._goldCloseBank(\''+esc(s.id)+'\')" class="bg-indigo-600 text-white px-4 py-2 rounded-xl font-bold">إغلاق وتسوية الكشف</button>':'<span class="px-4 py-2 rounded-xl bg-emerald-100 text-emerald-800 font-bold">تمت التسوية</span>')+
            '</div></div>';
    });

    h+='</div>';
    card('مطابقة البنك','fa-building-columns',h);
}
```

### الجراحة B — `renderExpenses`

**ابحث عن:**

```text
async function renderExpenses(){
```

واحذف الدالة كاملة حتى السطر:

```text
card('المصروفات','fa-money-bill-wave',h); }
```

واستبدلها كاملة بـ:

```javascript
async function renderExpenses(){
    var cid=companyId();
    var defaultFrom=today().slice(0,8)+'01';
    var defaultTo=today();

    function load(from,to){
        return rpc('finance_list_expenses',{
            p_company_id:cid,
            p_from:from,
            p_to:to
        })||[];
    }

    async function paint(from,to){
        var rows=await load(from,to);
        var h='<div class="space-y-4">'+
            '<div class="grid grid-cols-1 md:grid-cols-4 gap-3 items-end">'+
                '<div><label class="block text-sm font-bold mb-1">من تاريخ</label><input id="fin_exp_from" type="date" value="'+esc(from)+'" class="w-full border rounded-xl p-3"></div>'+\
                '<div><label class="block text-sm font-bold mb-1">إلى تاريخ</label><input id="fin_exp_to" type="date" value="'+esc(to)+'" class="w-full border rounded-xl p-3"></div>'+\
                '<button id="fin_exp_apply" class="bg-slate-800 text-white px-4 py-3 rounded-xl font-bold">تحديث النتائج</button>'+\
                '<button id="fin_exp_new" class="bg-emerald-600 text-white px-4 py-3 rounded-xl font-bold">مصروف جديد</button>'+\
            '</div>'+
            '<div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50">'+\
                '<th class="p-2 border">الكود</th><th class="p-2 border">التاريخ</th><th class="p-2 border">المستفيد</th><th class="p-2 border">التصنيف</th><th class="p-2 border">الإجمالي</th><th class="p-2 border">الضريبة</th><th class="p-2 border">الحالة</th><th class="p-2 border">القيد</th>'+\
            '</tr></thead><tbody>';

        if(!rows.length){
            h+='<tr><td colspan="8" class="p-8 text-center text-slate-500">لا توجد مصروفات ضمن الفترة المحددة.</td></tr>';
        }else{
            rows.forEach(function(x){
                var total=Number(x.total_amount||0);
                var tax=Number(x.tax_amount||0);
                h+='<tr>'+\
                    '<td class="p-2 border">'+esc(x.expense_code)+'</td>'+\
                    '<td class="p-2 border">'+esc(x.expense_date)+'</td>'+\
                    '<td class="p-2 border">'+esc(x.beneficiary_name)+'</td>'+\
                    '<td class="p-2 border">'+esc(x.category_name)+'</td>'+\
                    '<td class="p-2 border text-left font-black">'+money(total+tax)+'</td>'+\
                    '<td class="p-2 border text-left">'+money(tax)+'</td>'+\
                    '<td class="p-2 border">'+esc(x.status||'')+'</td>'+\
                    '<td class="p-2 border">'+esc(x.journal_entry_id||'')+'</td>'+\
                '</tr>';
            });
        }

        h+='</tbody></table></div></div>';
        card('المصروفات','fa-money-bill-wave',h);

        var apply=byId('fin_exp_apply');
        var add=byId('fin_exp_new');
        if(apply){
            apply.onclick=async function(){
                var f=byId('fin_exp_from').value;
                var t=byId('fin_exp_to').value;
                if(!f||!t){await Swal.fire({icon:'warning',title:'الفترة غير مكتملة',text:'حدد تاريخ البداية والنهاية.'});return;}
                if(f>t){await Swal.fire({icon:'warning',title:'الفترة غير صحيحة',text:'تاريخ البداية لا يجوز أن يتجاوز تاريخ النهاية.'});return;}
                await paint(f,t);
            };
        }
        if(add) add.onclick=function(){RW_Finance._goldNewExpense();};
    }

    await paint(defaultFrom,defaultTo);
}
```

### الجراحة C — `goldDispose`

**ابحث عن:**

```text
async function goldDispose(id){
```

واحذف الدالة كاملة حتى:

```text
await renderAssets();
}
```

واستبدلها كاملة بـ:

```javascript
async function goldDispose(id){
    if(typeof Swal==='undefined') return;

    var cid=companyId();
    var ares=await supabase
        .from('chart_of_accounts')
        .select('id,account_code,account_name,account_type')
        .eq('company_id',cid)
        .eq('is_active',true)
        .order('account_code');

    if(ares.error) throw ares.error;

    var accounts=ares.data||[];

    function e(v){
        return String(v==null?'':v)
            .replace(/&/g,'&amp;')
            .replace(/</g,'&lt;')
            .replace(/>/g,'&gt;')
            .replace(/"/g,'&quot;')
            .replace(/'/g,'&#39;');
    }

    var opts='<option value="">بدون متحصلات / استبعاد بدون بيع</option>';
    accounts.forEach(function(a){
        opts+='<option value="'+e(a.id)+'">'+e((a.account_code||'')+' — '+(a.account_name||''))+'</option>';
    });

    var html='<div class="space-y-3 text-right">'+
        '<div class="grid grid-cols-1 md:grid-cols-2 gap-3">'+
            '<div><label class="block text-sm font-bold mb-1">تاريخ الاستبعاد</label><input id="fd_date" type="date" value="'+today()+'" class="w-full border rounded-xl p-3"></div>'+\
            '<div><label class="block text-sm font-bold mb-1">المتحصلات</label><input id="fd_proc" type="number" min="0" step="0.01" value="0" class="w-full border rounded-xl p-3" placeholder="0 عند عدم وجود بيع"></div>'+\
            '<div class="md:col-span-2"><label class="block text-sm font-bold mb-1">حساب المتحصلات</label><select id="fd_acc" class="w-full border rounded-xl p-3">'+opts+'</select><div class="text-xs text-slate-500 mt-1">يُطلب فقط عند وجود متحصلات فعلية.</div></div>'+\
            '<div class="md:col-span-2"><label class="block text-sm font-bold mb-1">المرجع</label><input id="fd_ref" class="w-full border rounded-xl p-3" placeholder="المرجع"></div>'+\
        '</div></div>';

    var r=await Swal.fire({
        title:'استبعاد / بيع أصل',
        html:html,
        width:800,
        showCancelButton:true,
        confirmButtonText:'تنفيذ الاستبعاد',
        cancelButtonText:'إلغاء',
        preConfirm:function(){
            var date=byId('fd_date').value;
            var proceeds=Number(byId('fd_proc').value)||0;
            var accountId=byId('fd_acc').value||null;
            var reference=(byId('fd_ref').value||'').trim();

            if(!date){
                Swal.showValidationMessage('تاريخ الاستبعاد مطلوب');
                return false;
            }
            if(proceeds<0){
                Swal.showValidationMessage('المتحصلات لا يمكن أن تكون سالبة');
                return false;
            }
            if(proceeds>0&&!accountId){
                Swal.showValidationMessage('اختر حساب المتحصلات عند وجود قيمة بيع');
                return false;
            }

            return {
                date:date,
                proceeds:proceeds,
                accountId:accountId,
                reference:reference
            };
        }
    });

    if(!r.isConfirmed)return;

    await rpc('finance_dispose_asset',{
        p_company_id:cid,
        p_asset_id:id,
        p_disposal_date:r.value.date,
        p_proceeds:r.value.proceeds,
        p_proceeds_account_id:r.value.accountId,
        p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',
        p_operation_id:crypto.randomUUID(),
        p_reference:r.value.reference
    });

    await renderAssets();
}
```

## 6. ما لم يُمس عمدًا

لم يتم تعديل:

- `newCheque`
- `newBank`
- `newExpense`
- `goldTaxSettle`
- `goldAddAsset`
- `goldTaxCode`
- `goldOpenPeriod`
- `post_journal_entry`
- `post_cash_payment_atomic`
- `post_cash_receipt_atomic`
- أي Field Operations
- أي Inventory Writer
- أي جدول مالي
- أي Edge Function مالي

السبب: الـCurrent Source وProduction أثبتا أن هذه العناصر ليست سبب الفجوات الثلاث الحالية.

## 7. نتيجة البحث عن Stubs / ناقص / مختصر

تم البحث في CURRENT SOURCE ضمن Finance عن:

```text
قيد التطوير
prompt(
UUID حساب
```

النتيجة:

- `قيد التطوير` = لا نتيجة في Finance الحالية.
- `prompt(` = بقي في `renderExpenses` فقط، وتمت معالجته في الجراحة B.
- `UUID حساب` = بقي في `goldDispose` فقط، وتمت معالجته في الجراحة C.

أما `renderBankReconcile` فليس Stub باسم فارغ، لكنه ثبت وظيفيًا كواجهة ناقصة لأن Backend contract موجود دون استهلاك الواجهة له.

## 8. Production execution decision

لا توجد migration جديدة مطلوبة لهذه الجلسة؛ الـProduction financial foundation المطلوبة للجراحات الثلاث موجودة بالفعل وتم التحقق من عقودها.

لذلك لم يتم إنشاء:

- جدول جديد
- View بديلة
- Edge Function جديدة
- RPC مكرر
- Alias جديد

هذا قرار مقصود لمنع الدين التقني وتعدد مصادر الحقيقة.

## 9. E2E المطلوب بعد أن يطبق المالك جراحات Mother

### Bank Reconcile

```text
Finance → مطابقة البنك
↓
كشوف موجودة / لا توجد كشوف
↓
فتح كشف
↓
ظهور الحركات
↓
مطابقة مرشح CASH_BOX أو JOURNAL
↓
إلغاء المطابقة
↓
استبعاد بسبب موثق
↓
إعادة إدراج
↓
إغلاق الكشف
```

المفترض أن تستخدم كل هذه العمليات RPCs Production الحالية، ولا توجد كتابة مباشرة للـbank reconciliation من الواجهة.

### Expenses

```text
Finance → المصروفات
↓
تواريخ داخل نفس الواجهة
↓
تحديث النتائج
↓
مصروف جديد
```

يجب ألا يظهر `prompt()` في Console أو UI.

### Fixed Assets Disposal

```text
Finance → الأصول
↓
استبعاد / بيع
↓
اختيار حساب متحصلات من قائمة الحسابات
↓
إذا المتحصلات = 0 لا يلزم حساب
↓
إذا المتحصلات > 0 الحساب إلزامي
↓
finance_dispose_asset
```

## 10. أخطاء وتجارب هذه الجلسة

### ما نجح

1. مطابقة CURRENT GIT وParent وMother blob مع الحالة الحديثة.
2. تأكيد أن `forensic_main_assembly.yml` صحيح ولا يحتاج تغييرًا.
3. إعادة فحص Production schema والـFinance RPCs.
4. إثبات أن الـFinance data footprint الحالي محدود ولا توجد حاجة لعملية تنظيف بيانات تشغيلية في هذه النقطة.
5. إثبات أن محركات مطابقة البنك موجودة في Production، وبالتالي الفجوة Frontend contract consumption وليست Backend absence.
6. إثبات أن `newCheque/newBank` تم إصلاحهما فعليًا في commit `0677e474…` وعدم تكرار الجراحة.

### ما لم يكتمل بعد

لم يتم تنفيذ تعديل `main.html` في `erp-frontend` لأن هذه النقطة تقع ضمن مسؤولية المالك حسب قاعدة توزيع المسؤوليات.

لا يوجد authenticated browser E2E بعد دمج الجراحات الثلاث في Mother؛ ولذلك لا يجوز إعلان Finance 100% CLOSED حتى تنفيذ الدمج وإعادة اختبار المتصفح.

## 11. SELF-AUDIT

### PRE-SWEEP

```text
Business Understanding      = CONFIRMED
Architecture Understanding  = CONFIRMED
Database Understanding      = CONFIRMED
Historical Understanding    = CONFIRMED / reports used as context only
Production Understanding    = CONFIRMED
Current Source Understanding= CONFIRMED
Execution Confidence        = HIGH for backend contract / MEDIUM until Mother E2E
```

### ما تم إثباته

```text
Source of Truth              = erp-frontend/companies/company-1/main.html
Latest HEAD                  = 0677e474…
Parent                       = 1b1db605…
Production finance engine    = موجود
Finance tables               = موجودة
Finance tenant guards        = موجودة
Bank reconciliation RPC set  = موجود
Expense RPC set              = موجود
Asset disposal RPC           = موجود
```

### ما لم يُثبت

```text
Browser E2E بعد الدمج        = لم يتم بعد
Console بعد الدمج            = لم يتم بعد
Click-path لكل modal         = لم يتم بعد
Production runtime mutation = لا توجد حاجة لتغيير Backend هنا
```

### الحالة النهائية

```text
Backend Finance foundation  = CLOSED / PROVEN
Mother Finance gaps         = IDENTIFIED / SURGICAL FIXES PREPARED
Mother main.html            = NOT MODIFIED BY ASSISTANT BY DESIGN
Authenticated Browser E2E    = OPEN
Finance Gold/Diamond         = NOT CLOSED YET
```

## 12. الإرشادات التنفيذية للمساعد التالي

ابدأ دائمًا من:

```text
CURRENT GIT
↓
CURRENT SOURCE
↓
CURRENT PRODUCTION
↓
CURRENT DATABASE
↓
CURRENT DEPLOYMENTS
↓
CURRENT COMMIT + PARENT
```

ثم:

```text
حدد الدالة نفسها
↓
حدد Consumer الحقيقي
↓
افتح Production RPC/Schema المقابل
↓
تحقق من Business Contract
↓
قارن Current Source مع Production contract
↓
لا تعيد إصلاح عنصر ثبت إصلاحه بالفعل
↓
أغلق Closure Unit واحدة فقط
↓
طبّق Migration فقط إذا كان Production فعليًا ناقصًا
↓
طبّق Mother surgery عن طريق حذف/استبدال كامل
↓
اختبر syntax
↓
اختبر browser E2E authenticated
↓
طابق Console
↓
طابق DB state
↓
حدّث التقرير وCURRENT_STATE
```

ممنوع البدء من تقرير قديم باعتباره حالة حالية، وممنوع اختراع جدول أو Edge Function فقط لأن الواجهة لا تستعمل Contract موجودًا بالفعل.

## 13. الحكم التنفيذي

المهمة الحالية لم تكشف نقصًا في البنية المالية الخلفية يستلزم إنشاء بنية جديدة. النقص الحقيقي المتبقي في Mother محدد وقابل للإغلاق جراحيًا في ثلاث نقاط:

```text
renderBankReconcile
renderExpenses
goldDispose
```

بعد تطبيق الاستبدالات أعلاه في Mother يجب أن تكون الخطوة التالية الوحيدة هي authenticated browser E2E على Finance، ثم إغلاق أي Console/interaction defect حقيقي يظهر. لا يجوز العودة إلى Inventory أو Field Operations ضمن هذه الجولة.
