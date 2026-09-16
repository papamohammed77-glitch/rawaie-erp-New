# Report 216 — التحقيق الجنائي وتنفيذ إغلاق Mother Finance / Accounts & Finance

**التاريخ:** 2026-09-16  
**النطاق:** Mother Finance / Accounts & Finance / E2E Console investigation  
**Production:** Supabase project `fiilmooggumokxanwiyx`  
**Frontend Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

> **النقطة الحاكمة في بداية التقرير:** ملف النظام الأم المنشور `erp-frontend/companies/company-1/main.html` هو **مصدر الحقيقة الحالي الوحيد للواجهة**. تمت قراءته/فحصه كالمصدر الجاري اختباره، ولم يتم تعديل أي ملف من `Current/PWA/main2` أو أي نسخة تاريخية لبناء القرار. هذه القاعدة يجب قراءتها بعناية لأنها تمنع إعادة إصلاح ما تم إصلاحه تاريخيًا أو بناء قرار على نسخة قديمة.

---

## 1. قاعدة التحقيق

تم التعامل مع التقارير السابقة (`Report214`, `Report215`) كـhistorical guidance فقط، وليس كحالة حالية. الحالة الحالية التي بُني عليها التحقيق هي:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

تمت مراجعة آخر Git الفعلي، والـparent المباشر، ونسخة `main.html` الحالية، ثم مطابقة ذلك مع Production PostgreSQL ووجود الـRPCs والـRLS/ACL.

### آخر Git مثبت

- Latest HEAD: `2af93b03a0bc5c46e2126d329154c6d176f0d098`
- HEAD message: `forensic: persist current Mother inventory extract`
- Previous parent relevant to Finance: `68bbd6e1ed8f17e05d1c11fc1ce33e147f46282d`
- Parent message: `Add functions for asset management and tax handling`

الـparent يثبت أن الإضافات المالية/الأصول/الضرائب تم إدخالها فعليًا في `main.html`، وليس أن Finance مجرد قائمة UI شكلية.

---

## 2. النتيجة الجنائية لخطأ Console

### الخطأ المرصود

```text
main:14542 Uncaught ReferenceError: _renderPeriods is not defined
main:14539 Uncaught ReferenceError: _renderBankReconcile is not defined
main:14538 Uncaught ReferenceError: _renderCheques is not defined
main:14536 Uncaught ReferenceError: _renderRecurringJournals is not defined
main:14537 Uncaught ReferenceError: _renderExpenses is not defined
main:14541 Uncaught ReferenceError: _renderAssets is not defined
main:14535 Uncaught ReferenceError: _renderJournalList is not defined
main:14540 Uncaught ReferenceError: _renderTax is not defined
```

### ما تم إثباته من `main.html` الحالي

الـdispatcher يحتوي بالفعل على استدعاءات bare identifiers:

```js
else if (tab === 'journal-list') _renderJournalList();
else if (tab === 'recurring-journals') _renderRecurringJournals();
else if (tab === 'expenses') _renderExpenses();
else if (tab === 'cheques') _renderCheques();
else if (tab === 'bank-reconcile') _renderBankReconcile();
else if (tab === 'tax') _renderTax();
else if (tab === 'assets') _renderAssets();
else if (tab === 'periods') _renderPeriods();
```

وفي الوقت نفسه يحتوي الملف نفسه على ربط فعلي للدوال داخل كائن `RW_Finance`:

```js
RW_Finance._renderJournalList = RW_Finance_GoldExtension.journalList;
RW_Finance._renderAssets = RW_Finance_GoldExtension.renderAssets;
RW_Finance._renderTax = RW_Finance_GoldExtension.renderTax;
RW_Finance._renderPeriods = RW_Finance_GoldExtension.renderPeriods;
RW_Finance._renderBankReconcile = RW_Finance_GoldExtension.renderBankReconcile;
RW_Finance._renderRecurringJournals = RW_Finance_GoldExtension.renderRecurring;
RW_Finance._renderExpenses = RW_Finance_GoldExtension.renderExpenses;
RW_Finance._renderCheques = RW_Finance_GoldExtension.renderCheques;
```

إذن **الدوال ليست مفقودة من GoldExtension**. سبب الـReferenceError هو اختلاف مستوى الاسم:

`RW_Finance._renderX` موجود  
بينما  
`_renderX` كمتغير/دالة global غير موجود.

هذا يفسر بدقة لماذا ظهرت ReferenceError رغم وجود renderer implementations داخل الملف.

### الدوال الفعلية نفسها موجودة

تم العثور في المصدر الحالي على implementations حقيقية لـ:

- `renderExpenses()` → `finance_list_expenses`
- `renderCheques()` → `finance_list_cheques`
- `renderAssets()` → `finance_list_assets`
- `renderTax()` → `finance_tax_report`
- `renderPeriods()` → `finance_periods`

وبقية renderers المالية تربط similarly بالـRPC layer.

**الاستنتاج:** مشكلة Console الحالية هي **Dispatcher Binding defect** وليست Missing Backend Finance engine.

---

## 3. الجراحة المطلوبة في Mother `main.html`

> **مهم:** لم يتم تعديل `erp-frontend/main.html`. هذه الجراحة تخص المالك فقط.

### الجراحة A — إصلاح Dispatcher

**الموضع المثبت من Console:** الأسطر `14535–14542` في النسخة التي صدر منها الخطأ.

**ابحث عن هذه الأسطر الثمانية حرفيًا واحذفها كاملة:**

```js
else if (tab === 'journal-list') _renderJournalList();
else if (tab === 'recurring-journals') _renderRecurringJournals();
else if (tab === 'expenses') _renderExpenses();
else if (tab === 'cheques') _renderCheques();
else if (tab === 'bank-reconcile') _renderBankReconcile();
else if (tab === 'tax') _renderTax();
else if (tab === 'assets') _renderAssets();
else if (tab === 'periods') _renderPeriods();
```

**واستبدلها كاملة بهذا العنصر:**

```js
else if (tab === 'journal-list') RW_Finance._renderJournalList();
else if (tab === 'recurring-journals') RW_Finance._renderRecurringJournals();
else if (tab === 'expenses') RW_Finance._renderExpenses();
else if (tab === 'cheques') RW_Finance._renderCheques();
else if (tab === 'bank-reconcile') RW_Finance._renderBankReconcile();
else if (tab === 'tax') RW_Finance._renderTax();
else if (tab === 'assets') RW_Finance._renderAssets();
else if (tab === 'periods') RW_Finance._renderPeriods();
```

هذا هو الإصلاح المباشر لخطأ Console الحالي؛ لا تحذف أي renderer implementation.

---

## 4. فجوة ثانية مثبتة بعد إصلاح Dispatcher

بعد فحص renderers الحالية تم إثبات أن `renderExpenses()` يعرض زرًا يستدعي:

```js
RW_Finance._goldNewExpense()
```

لكن لا يوجد في المصدر الحالي assignment مماثل لـ`_goldNewExpense`، ولا implementation `newExpense` مثبتة في GoldExtension الحالية.

هذه ليست Console error الحالية لأن الوصول إلى expenses كان يتوقف أولًا عند `_renderExpenses`، لكنها **next runtime failure متوقعة ومثبتة من source** بعد إصلاح dispatcher.

### الجراحة B — إضافة `newExpense`

**داخل `RW_Finance_GoldExtension`**:

ابحث عن السطر الكامل الذي يبدأ بـ:

```js
async function renderExpenses(){
```

وأضف **فوقه مباشرة** الدالة التالية كاملة:

```js
async function newExpense(){
    var cid=companyId();
    if(!cid) throw new Error('سياق الشركة غير متوفر');

    var results=await Promise.all([
        supabase.from('finance_expense_categories').select('id,code,name').eq('company_id',cid).eq('is_active',true).order('code'),
        supabase.from('treasury').select('id,account_code,account_name').eq('company_id',cid).eq('is_active',true).order('account_code'),
        supabase.from('chart_of_accounts').select('id,account_code,account_name').eq('company_id',cid).eq('is_active',true).order('account_code'),
        supabase.from('cost_centers').select('id,code,name').eq('is_active',true).order('code'),
        supabase.from('finance_tax_codes').select('id,code,name,rate').eq('company_id',cid).eq('is_active',true).order('code')
    ]);

    for(var rr=0;rr<results.length;rr++) if(results[rr].error) throw results[rr].error;

    var categories=results[0].data||[];
    var treasuries=results[1].data||[];
    var accounts=results[2].data||[];
    var centers=results[3].data||[];
    var taxes=results[4].data||[];

    var categoryOptions='<option value="">بدون تصنيف</option>';
    categories.forEach(function(x){ categoryOptions+='<option value="'+esc(x.id)+'">'+esc(x.code)+' — '+esc(x.name)+'</option>'; });

    var treasuryOptions='<option value="">مصروف آجل / على الموردين</option>';
    treasuries.forEach(function(x){ treasuryOptions+='<option value="'+esc(x.id)+'">'+esc(x.account_code)+' — '+esc(x.account_name)+'</option>'; });

    var accountOptions='<option value="">اختر حساب المصروف</option>';
    accounts.forEach(function(x){ accountOptions+='<option value="'+esc(x.id)+'">'+esc(x.account_code)+' — '+esc(x.account_name)+'</option>'; });

    var centerOptions='<option value="">بدون مركز تكلفة</option>';
    centers.forEach(function(x){ centerOptions+='<option value="'+esc(x.id)+'">'+esc(x.code)+' — '+esc(x.name)+'</option>'; });

    var taxOptions='<option value="">بدون ضريبة</option>';
    taxes.forEach(function(x){ taxOptions+='<option value="'+esc(x.id)+'" data-rate="'+esc(x.rate)+'">'+esc(x.code)+' — '+esc(x.name)+' ('+esc(x.rate)+'%)</option>'; });

    var html=''+
      '<div class="grid grid-cols-2 gap-3 text-right">'+
        '<input id="fx_code" class="swal2-input" placeholder="كود المصروف — اختياري" style="margin:0">'+
        '<input id="fx_date" type="date" value="'+today()+'" class="swal2-input" style="margin:0">'+
        '<input id="fx_beneficiary" class="swal2-input" placeholder="المستفيد" style="margin:0">'+
        '<select id="fx_category" class="swal2-select" style="margin:0">'+categoryOptions+'</select>'+
        '<select id="fx_treasury" class="swal2-select col-span-2" style="margin:0">'+treasuryOptions+'</select>'+
        '<select id="fx_account" class="swal2-select" style="margin:0">'+accountOptions+'</select>'+
        '<select id="fx_center" class="swal2-select" style="margin:0">'+centerOptions+'</select>'+
        '<input id="fx_amount" type="number" min="0.01" step="0.01" class="swal2-input" placeholder="قيمة المصروف قبل الضريبة" style="margin:0">'+
        '<select id="fx_tax" class="swal2-select" style="margin:0">'+taxOptions+'</select>'+
        '<input id="fx_tax_amount" type="number" min="0" step="0.01" value="0" class="swal2-input" placeholder="قيمة الضريبة" style="margin:0">'+
        '<input id="fx_reference" class="swal2-input col-span-2" placeholder="المرجع" style="margin:0">'+
        '<textarea id="fx_description" class="swal2-textarea col-span-2" placeholder="وصف المصروف" style="margin:0"></textarea>'+
      '</div>';

    var r=await Swal.fire({
        title:'مصروف جديد',
        html:html,
        width:900,
        showCancelButton:true,
        confirmButtonText:'تسجيل وترحيل',
        cancelButtonText:'إلغاء',
        focusConfirm:false,
        didOpen:function(){
            var taxEl=byId('fx_tax');
            var amountEl=byId('fx_amount');
            var taxAmountEl=byId('fx_tax_amount');
            function recalc(){
                var opt=taxEl&&taxEl.options[taxEl.selectedIndex];
                var rate=opt?Number(opt.getAttribute('data-rate')||0):0;
                var amount=Number(amountEl&&amountEl.value||0);
                if(rate>0) taxAmountEl.value=(amount*rate/100).toFixed(2);
                else taxAmountEl.value='0';
            }
            if(taxEl) taxEl.addEventListener('change',recalc);
            if(amountEl) amountEl.addEventListener('input',recalc);
        },
        preConfirm:function(){
            var code=(byId('fx_code').value||'').trim()||('EXP-'+crypto.randomUUID().slice(0,8).toUpperCase());
            var amount=Number(byId('fx_amount').value||0);
            var taxAmount=Number(byId('fx_tax_amount').value||0);
            var accountId=(byId('fx_account').value||'').trim();
            if(!amount||amount<=0){ Swal.showValidationMessage('قيمة المصروف يجب أن تكون أكبر من صفر'); return false; }
            if(!accountId){ Swal.showValidationMessage('اختر حساب المصروف'); return false; }
            if(taxAmount<0){ Swal.showValidationMessage('قيمة الضريبة غير صالحة'); return false; }
            return {
                expense_code:code,
                expense_date:byId('fx_date').value||today(),
                beneficiary_name:(byId('fx_beneficiary').value||'').trim(),
                category_id:(byId('fx_category').value||'').trim()||null,
                treasury_id:(byId('fx_treasury').value||'').trim()||null,
                description:(byId('fx_description').value||'').trim(),
                reference:(byId('fx_reference').value||'').trim(),
                account_id:accountId,
                cost_center_id:(byId('fx_center').value||'').trim()||null,
                tax_code_id:(byId('fx_tax').value||'').trim()||null,
                amount:amount,
                tax_amount:taxAmount
            };
        }
    });

    if(!r.isConfirmed||!r.value) return;

    await rpc('finance_save_expense',{
        p_company_id:cid,
        p_expense_id:null,
        p_expense_code:r.value.expense_code,
        p_expense_date:r.value.expense_date,
        p_beneficiary_name:r.value.beneficiary_name,
        p_category_id:r.value.category_id,
        p_treasury_id:r.value.treasury_id,
        p_description:r.value.description,
        p_attachment_url:null,
        p_reference:r.value.reference,
        p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',
        p_operation_id:crypto.randomUUID(),
        p_lines:[{
            account_id:r.value.account_id,
            cost_center_id:r.value.cost_center_id,
            tax_code_id:r.value.tax_code_id,
            description:r.value.description,
            amount:r.value.amount,
            tax_amount:r.value.tax_amount
        }]
    });

    await renderExpenses();
}
```

### تعديل Return Object

ابحث عن السطر الكامل:

```js
newCheque:newCheque,
```

وأضف **فوقه مباشرة**:

```js
newExpense:newExpense,
```

فيصبح موضعه:

```js
newExpense:newExpense,
newCheque:newCheque,
```

### تعديل Assignment

ابحث عن السطر الكامل:

```js
RW_Finance._goldNewBankStatement = RW_Finance_GoldExtension.newBank;
```

وأضف **بعده مباشرة**:

```js
RW_Finance._goldNewExpense = RW_Finance_GoldExtension.newExpense;
```

بهذا يصبح زر `مصروف جديد` مرتبطًا بـRPC حقيقي، مع account/category/treasury/cost center/tax selections بدل UUID text fields.

---

## 5. Production Database — الحالة الحالية

تمت إعادة فحص Production بدل الاعتماد على Report214.

الجداول المالية التشغيلية موجودة بالفعل:

- `finance_tax_codes`
- `finance_tax_settlements`
- `finance_tax_transactions`
- `finance_bank_statements`
- `finance_bank_statement_lines`
- `finance_cheques`
- `finance_cheque_events`
- `finance_expenses`
- `finance_expense_lines`
- `finance_expense_categories`
- `finance_periods`
- `recurring_journal_templates`
- `recurring_journal_lines`
- `finance_recurring_runs`
- `fixed_assets`
- `fixed_asset_events`

ولا توجد حاجة في هذه النقطة إلى إنشاء جداول موازية أو إعادة بناء Finance من الصفر.

### RPC layer المثبتة

Production تحتوي فعليًا على contracts للـ:

- journal list/detail/reversal/posting
- recurring journal save/run/list
- expenses save/list/category
- cheque save/list/transition
- bank statement save/open/match/unmatch/exclude/include/close
- tax code/report/post/manual record/settlement
- fixed asset save/acquire/depreciate/dispose/list
- accounting period open/close/reopen/current/guard

وبالتالي **الـbackend base ليس missing** في المشكلة الحالية.

---

## 6. Production Security Correction — تم تنفيذها فعليًا

فحص `routine_privileges` أثبت أن عدة Finance `SECURITY DEFINER` RPCs كانت تمنح `EXECUTE` إلى `PUBLIC` و`anon` رغم أن business contract يعتمد على authenticated company context.

تم تنفيذ migration في Production باسم:

`finance_rpc_execute_acl_hardening`

الإجراء:

- `REVOKE EXECUTE` من `PUBLIC, anon` على Finance mutation RPCs.
- `GRANT EXECUTE` إلى `authenticated, service_role`.
- لم يتم تغيير business logic ولا signatures.
- لم يتم إغلاق service-role execution المستخدمة في Edge Functions.

### Production verification بعد التعديل

تمت إعادة الاستعلام عن privileges، وأثبتت النتيجة أن RPCs المستهدفة أصبحت مرخصة لـ:

- `authenticated`
- `service_role`
- `postgres`

ولا يظهر `PUBLIC/anon` لهذه الـmutation contracts المستهدفة.

هذه جراحة أمنية مستقلة عن خطأ Console، لكنها لازمة لإغلاق Finance control-plane بشكل صحيح.

---

## 7. RLS / Data isolation

تم التحقق من `pg_tables.rowsecurity`، والنتيجة الحالية:

كل الجداول المالية التشغيلية الجديدة المذكورة أعلاه تحمل `rowsecurity = true`.

هذا متسق مع company-scoped security layer الموجودة في Finance RPCs عبر `app_private.current_user_company_id()`.

---

## 8. ما لم يتم تغييره ولماذا

لم يتم إنشاء جداول جديدة للضرائب/البنك/الأصول/المصروفات/الشيكات/الفترات لأن Production تحتوي بالفعل على البنية اللازمة.

لم يتم إنشاء Edge Function جديدة لمجرد وجود Console error؛ الـfrontend يستدعي RPCs مباشرة والـRPC layer موجودة بالفعل، وبالتالي إضافة Edge router جديد في هذه اللحظة كان duplication architecture وليس إصلاحًا.

لم يتم تعديل:

- `erp-frontend/companies/company-1/main.html`
- `Current/PWA/main2/*`
- التطبيقات التشغيلية المنفصلة الخاصة بالمخزون/التوصيل/الرانشيت
- Physical Stock engine

---

## 9. Inventory / Field Operations safety

لم يتم لمس سلسلة العمليات الميدانية في هذه الجلسة.

العقد المحمي ما زال:

`Physical Movement → post_stock_movement → stock_branches + inventory_log`

ولم تتم إضافة أي Physical Stock writer إلى Finance.

---

## 10. Test Matrix

### T1 — Source forensic

**PASS**

ثبت وجود render implementations وربطها داخل `RW_Finance`.

### T2 — Console root-cause

**PASS**

تم إثبات أن الـdispatcher يستدعي bare globals بينما الموجود فعليًا object properties.

### T3 — Finance DB inventory

**PASS**

الجداول التشغيلية والـRPC contracts المطلوبة موجودة في Production.

### T4 — RLS presence

**PASS**

Finance operational tables الحالية مفعّل عليها RLS.

### T5 — Production Finance EXECUTE ACL

**PASS بعد migration**

Public/anon execution removed from targeted mutation contracts.

### T6 — Authenticated Browser E2E

**OPEN**

لا توجد في بيئة هذه الجلسة قناة browser authenticated حقيقية تثبت click → render → network → console end-to-end.

لذلك لم يتم تحويل هذه النقطة إلى CLOSED ادعاءً.

---

## 11. أخطاء/محاولات فاشلة أثناء التحقيق

### 11.1 محاولة الوصول البرمجي المباشر إلى GitHub من container

فشلت بسبب غياب DNS/network في container.

هذا لم يؤثر على Source of Truth؛ تم الاعتماد على GitHub connector نفسه في جلب source/commit evidence.

### 11.2 قراءة خطية مباشرة للـblob الكبير

بعض طلبات line-range لملف `main.html` الكبير لم تُرجع نطاقًا صالحًا عبر connector، لكن هذا لم يُستخدم ذريعة للتخمين.

تم استبدال الطريق بـcontent search داخل المصدر الجاري نفسه، وتم إثبات كل من:

- dispatcher calls
- actual render implementations
- actual RW_Finance assignments

وبذلك أمكن تحديد الـroot cause بدقة.

---

## 12. الحالة النهائية الصحيحة الآن

### Frontend

`Mother Finance Dispatcher ReferenceError = ROOT CAUSE IDENTIFIED`

`Mother Finance renderer implementations = PRESENT`

`Current surgical edit required = YES`

`Assistant changed Mother main.html = NO`

### Production

`Finance backend tables = PRESENT`

`Finance RPC contracts = PRESENT`

`Finance RLS = ENABLED`

`Finance mutation ACL hardening = DEPLOYED`

### E2E

`Authenticated Mother Finance Browser E2E = OPEN`

ولا يجوز تغييرها إلى CLOSED حتى ينجح اختبار المتصفح بعد دمج جراحة A+B.

---

## 13. قرار الإغلاق لهذه النقطة

**لا تعتبر Finance E2E مغلقة الآن.**

السبب الوحيد المفتوح هو browser-side verification، وليس نقصًا مثبتًا في backend core.

التسلسل الصحيح:

1. تنفيذ جراحة A في Mother `main.html`.
2. تنفيذ جراحة B في Mother `main.html`.
3. إعادة تحميل الملف في المتصفح.
4. فتح `الإدارة المالية`.
5. فتح كل subtab:
   - قائمة القيود
   - القيود المتكررة
   - المصروفات
   - الشيكات
   - مطابقة البنك
   - الضرائب
   - الأصول والإهلاك
   - الفترات المحاسبية
6. فحص Console.
7. فحص Network لكل RPC.
8. تجربة create/list/action لكل tab الذي يملك mutation.
9. مقارنة النتيجة فورًا مع Production في نفس اللحظة.
10. فقط عند نجاح ذلك تصبح Finance E2E CLOSED.

---

## 14. معيار Gold/Diamond المستخدم في هذه الجلسة

الوظيفة لا تُعتبر مكتملة لمجرد وجود:

- tab
- card
- button
- table

بل يجب أن يكون المسار:

`UI → validated handler → authenticated company context → canonical RPC → transaction/business rule → journal/ledger/state → audit/realtime → UI refresh`

وهو النمط الموجود الآن في backend Finance، مع بقاء جراحة dispatcher وبعض action handlers على Mother UI.

---

# FINAL SELF-AUDIT

## What I Proved

1. Current Git HEAD مختلف عن التاريخ الموجود في بعض التقارير القديمة.
2. Parent `68bb...` يثبت أصل الإضافات المالية والأصول والضرائب.
3. Current `main.html` يحتوي renderer implementations المالية.
4. Current `main.html` يحتوي `RW_Finance._render...` assignments.
5. Console يفشل لأن dispatcher يستدعي bare identifiers غير معرفة.
6. `renderExpenses` يمتلك زرًا يعتمد على `_goldNewExpense` غير المربوط، وهي فجوة runtime ثانية حقيقية.
7. Production تحتوي Finance schema والـRPC contracts المطلوبة بالفعل.
8. Production Finance tables عليها RLS.
9. تم إصلاح EXECUTE ACL لعدد من Finance mutation RPCs مباشرة في Production.

## What I Did Not Prove

1. لم أثبت authenticated browser E2E حتى النهاية لعدم وجود browser session authenticated في هذه البيئة.
2. لم أثبت scheduler automatic recurring runtime؛ ما زال هذا closure مستقلًا.

## What I Fixed

1. Production Finance RPC ACL hardening.
2. لا يوجد تعديل على Mother frontend لأن هذه مسؤولية المالك.

## What I Initially Missed

كان التركيز الأول سهلًا على تفسير ReferenceError باعتبار الدوال missing. التحقيق أثبت أن الدوال موجودة، لكن namespace binding هو الذي يفشل. هذه نقطة مهمة لمنع إعادة إنشاء الدوال الموجودة أصلًا.

## What Could Still Be Wrong

1. أي typo في الدمج اليدوي لجراحة A أو B.
2. أي consumer مالي آخر لا يستخدم `RW_Finance.*`.
3. أي UI action غير مثبت بعد في Browser E2E.

## Final Confidence

**High for root cause.**  
**High for backend infrastructure presence.**  
**Not 100% for browser E2E until authenticated runtime proof.**

## Final Closure Status

`MOTHER FINANCE CONSOLE ROOT CAUSE = IDENTIFIED`

`PRODUCTION FINANCE ACL HARDENING = CLOSED`

`MOTHER FINANCE E2E = OPEN — WAITING FOR OWNER SURGICAL MERGE + AUTHENTICATED BROWSER VERIFICATION`

---

# إرشادات إلى المساعد التالي — كيف يبدأ ولا يضيع الوقت

1. **ابدأ دائمًا من `erp-frontend/companies/company-1/main.html` الحالي ومن HEAD الحالي، ثم افحص parent المباشر.** لا تبدأ من `Current/PWA/main2` إلا لفهم تاريخ mutation محدد.
2. **قبل القول إن دالة missing ابحث عن ثلاثة أشياء:** implementation، exported property، call site. كثير من أخطاء Mother تكون namespace/binding وليست missing logic.
3. **قبل أي Production migration نفذ schema + function + privilege + RLS evidence في اللحظة نفسها.** لا تعتمد على Report214/215 في هذه النقطة.
4. **لا تعيد إنشاء Finance tables أو RPCs التي أثبت Production أنها موجودة.** ابحث عن bridge/consumer defect أولًا.
5. **كل Browser error يجب تحويله إلى chain:** exact call site → actual symbol owner → backend RPC → DB table → security context → runtime result.
6. **كل تعديل في Mother main.html يقدمه المساعد كحذف/استبدال كامل مع anchor واضح وسطر معروف إن توفر؛ المالك هو الذي يدمج الملف.**
7. **كل تعديل Production ينفذه المساعد مباشرة، ثم يعيد الاستعلام بعد التنفيذ من نفس Production.**
8. **لا تعلن CLOSED من static source.** CLOSED يتطلب browser + Console + Network + Production same-moment verification.
9. إذا ظهرت مشكلة جديدة بعد إصلاح Dispatcher، **لا تعدّل ما تم إثباته إلا إذا كان هناك دليل جديد يفرض ذلك**؛ انتقل إلى أول open runtime failure جديد.
10. عند كل جلسة حدّث هذا `CURRENT_STATE.md` وأضف تقريرًا جديدًا في `doc/Draft/Reprots` دون حذف أي تقرير تاريخي.

**القاعدة الأخيرة:** لا تلاحق الأسماء التي ظهرت في التقارير؛ لاحق السلوك الذي يثبته `CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT`. كود قديم لكنه موجود في current source هو current behavior إلى أن يثبت العكس.