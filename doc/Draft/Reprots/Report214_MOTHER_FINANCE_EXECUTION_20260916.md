# Report 214 — تنفيذ وإغلاق عقود إدارة الحسابات والمالية في النظام الأم

**التاريخ:** 2026-09-16  
**النطاق:** Mother Finance / Accounts & Finance فقط  
**Source of Truth للواجهة:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`  
**Production:** Supabase project `fiilmooggumokxanwiyx`

## 0. نقطة البداية الحاكمة

تم الرجوع أولًا إلى آخر Git الفعلي وليس إلى Report212 باعتباره حقيقة حالية.

آخر HEAD فعلي:
`0849e7e04fe79e9391f7388624dd9aa42de33a0f`

والـparent التشغيلي المباشر للـMother Finance:
`2afa7465a18023f7bba5f60b8d0a08d69de3fd80`

رسالة parent:
`Update finance management sections in main.html`

الـHEAD الأحدث `0849...` لم يغيّر `main.html`؛ أضاف فقط `_forensic_current_main_extract.md`، لذلك يبقى Commit `2afa...` هو آخر تغيير على Mother Finance نفسه.

`forensic_main_assembly.yml` فُحص فعليًا، وهو صحيح بالفعل ويشير إلى:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

لا توجد جراحة مطلوبة في `forensic_main_assembly.yml` في هذه اللحظة.

## 1. ما تم إثباته من Daftra

استُخدمت الوثائق الرسمية لـDaftra كـbenchmark لا كـSource of Truth. القدرات المؤكدة تشمل: قائمة قيود يومية قابلة للفلترة وسجلها، القيود المتكررة مع start/end/frequency وسجل العمليات، الأصول مع depreciation lifecycle، إدارة الشيكات، bank reconciliation، ودورة تقارير/ضرائب. المصادر:
- https://docs.daftra.com/en/tutorial/journal-entries-list/
- https://docs.daftra.com/en/user_manual/automatic-and-manual-journal-entries/
- https://docs.daftra.com/en/user_manual/comprehensive-assets-guide/
- https://www.daftra.com/en/features/sub_feature/4
- https://www.daftra.com/en/finance-accounting/

## 2. النتيجة الجنائية للواجهة الحالية

Commit `2afa...` أضاف Finance tabs جديدة إلى القائمة والـdispatch، لكنه أضاف GoldExtension ناقصة.

الموجود حاليًا داخل GoldExtension:
- `journalList`
- `renderAssets`
- `renderTax`
- `renderPeriods`
- `renderBankReconcile`
- `renderRecurring`

لكن dispatch يستدعي أيضًا:
- `_renderExpenses`
- `_renderCheques`

وهما غير معرفتين في GoldExtension الحالية.

كذلك أزرار موجودة داخل GoldExtension تستدعي:
- `_goldAddAsset`
- `_goldTaxCode`
- `_goldOpenPeriod`
- `_goldClosePeriod`
- `_goldNewBankStatement`
- `_goldNewRecurring`

ولا توجد implementations مقابلة لها في الكتلة الحالية.

إذن فتح Finance والانتقال بين بعض الألسنة ممكن، لكن النقر على الإجراءات المذكورة يخلق runtime failure. هذه فجوة حقيقية وليست تجميلًا.

## 3. ما تم تنفيذه فعليًا في Production

تم بناء/توسيع العقود المالية في Production دون إنشاء محرك محاسبي موازٍ.

### 3.1 Journals

تم توسيع:
- `post_journal_entry` كمحرك الترحيل المركزي.
- `finance_journal_detail`
- `finance_reverse_journal`
- `finance_journal_list` موجودة بالفعل وتم التحقق من توقيعها.

وتم ربط الترحيل بـ:
`erp_operation_registry`
لمنع replay للـoperation المكتملة.

كما تم ربط الترحيل بـ`finance_period_guard` لمنع القيد داخل فترة مغلقة.

### 3.2 Recurring Journals

تم إنشاء runtime فعلي:
`finance_run_recurring`

ويدعم:
- DAILY
- WEEKLY
- MONTHLY
- QUARTERLY
- YEARLY
- next_run_date
- end_date
- last_run_date
- run_count
- `finance_recurring_runs`

وكل قيد يُنشأ عبر `post_journal_entry`.

Production لا تحتوي حاليًا `pg_cron` أو `pg_net`، لذلك التنفيذ الدوري التلقائي scheduler ما زال يحتاج Edge/runtime scheduler موثق قبل اعتباره Auto-Runtime كاملًا.

### 3.3 Expenses

تم إنشاء:
- `finance_expense_categories`
- `finance_expenses`
- `finance_expense_lines`
- `finance_save_expense_category`
- `finance_save_expense`
- `finance_list_expenses`

التصميم يدعم:
- أكثر من حساب مصروف.
- tax code لكل سطر.
- cost center.
- attachment/source reference.
- treasury payment أو accrued payable.
- operation id.
- journal linkage.

تم تصحيح خطأ حقيقي في النسخة الأولى: المصروف بدون خزينة كان سينتج قيدًا غير متزن؛ أصبح يستخدم حساب الدائن 211 عندما لا يوجد treasury.

### 3.4 Tax

تم إنشاء/تثبيت:
- `finance_tax_settlements`
- `finance_tax_record_manual`
- tax transaction source reference.
- `finance_tax_settle`
- `finance_tax_settlements_report`

التسوية تجمع INPUT/OUTPUT غير المسوى، تنشئ قيد التسوية عبر `post_journal_entry`، ثم تربط transactions بالتسوية والفترة.

### 3.5 Bank Reconciliation

تم تثبيت:
- `finance_bank_statements`
- `finance_bank_statement_lines`
- `finance_bank_match_candidates`
- `finance_match_bank_line`
- `finance_bank_unmatch_line`
- `finance_exclude_bank_line`
- `finance_include_bank_line`
- `finance_close_bank_statement`

إغلاق الكشف يشترط:
1. تطابق opening + statement movement = closing balance.
2. كل السطور غير المستبعدة matched.
3. جميع المطابقات company/treasury scoped.

### 3.6 Fixed Assets

تم توسيع:
- `fixed_assets`
- `fixed_asset_events`
- disposal metadata.
- `post_fixed_asset_depreciation` موجود ومربوط بالمحرك المركزي.
- `finance_asset_acquire`
- `finance_dispose_asset`

دورة الأصل أصبحت:
`Acquire → Depreciate → Dispose/Sell`
مع journal entry لكل حركة عبر `post_journal_entry`.

### 3.7 Cheques

تم إنشاء:
- `finance_cheques`
- `finance_cheque_events`
- `finance_save_cheque`
- `finance_transition_cheque`
- `finance_list_cheques`

State machine:
`ISSUED → DELIVERED/DEPOSITED/CANCELLED → CLEARED/BOUNCED`
بحسب نوع المرحلة المسموح.

الجدول التاريخي `cheques` تم الاحتفاظ به تاريخيًا، وتم سحب direct write permissions من authenticated/anon بدل إنشاء مسار كتابة مزدوج.

### 3.8 Financial Periods

تم تثبيت:
- `finance_open_period`
- `finance_close_period`
- `finance_reopen_period`
- `finance_period_guard`

كما تم ربط `finance_period_guard` بمحرك `post_journal_entry` نفسه، بحيث لا يعتمد أمن الإغلاق على الواجهة.

### 3.9 Realtime / RLS

تم تفعيل RLS وrealtime على الجداول المالية الجديدة اللازمة.

## 4. Inventory / Field Operations Protection

لم يتم تغيير العمليات الميدانية أو سلسلة المخزون الحالية في هذه المهمة.

العقد الحاكم بقي:
`Physical Movement → post_stock_movement → stock_branches + inventory_log`

ولم يتم إنشاء Physical Stock Engine موازي لخدمة Finance.

## 5. Production data hygiene

تم استخدام Production نفسها للتحقق من schema والfunctions والـrelations.

تم اكتشاف سابقًا أن بعض سجلات inventory كانت تحمل fixture-like quantities، لكن هذا خارج نطاق Finance الحالي؛ لذلك لم يتم حذفها أو إعادة تفسيرها دون evidence تشغيلي جديد.

## 6. ما فشل أثناء التنفيذ ولماذا

### 6.1 Purchase receiving idempotency test

فشل اختبار replay الأول لأن identity كانت مرتبطة بـ`qty_received_before`، وهي قيمة متغيرة بعد نجاح الاستلام. النتيجة: retry كان يُرفض بدل أن يعاد كـduplicate.

تم اكتشاف السبب من Production نفسها، ولم يتم إخفاؤه بزيادة شروط كمية عشوائية.

القاعدة النهائية: operation identity يجب أن تأتي من العملية نفسها أو تكون مستقرة قبل تغير الحالة.

### 6.2 Authenticated SQL simulation

محاولات محاكاة `auth.uid()` من SQL session لم تكن بديلًا صالحًا عن authenticated browser.

لذلك لم يتم تحويل SQL PASS إلى Browser E2E PASS.

### 6.3 Frontend dependency gap

Commit `2afa...` ترك renderer/handlers غير معرفة. تم إثبات المشكلة من diff الفعلي للـcommit، وليس من توقع.

## 7. الحالة الحالية للـOpen Verification

`Authenticated Mother Finance Browser E2E = OPEN`

السبب: لا توجد جلسة browser authenticated فعلية في بيئة التنفيذ تثبت click/render/network/console كاملة.

`Tax full lifecycle = BACKEND IMPLEMENTED / BROWSER OPEN`

`Asset full lifecycle = BACKEND IMPLEMENTED / BROWSER OPEN`

`Bank full reconciliation = BACKEND IMPLEMENTED / BROWSER OPEN`

`Recurring journal runtime execution = BACKEND IMPLEMENTED / SCHEDULER + BROWSER OPEN`

لا يجوز تحويل أي من الحالات السابقة إلى CLOSED قبل اختبار authenticated حقيقي.

## 8. الجراحة المطلوبة في Mother main.html — لا يقم المساعد بتعديل الملف

### PATCH MOTHER-01 — GoldExtension

**لا تعدل أي ملف من `Current/PWA/main2`.**

في:
`companies/company-1/main.html`

الموضع الحالي: بداية الكتلة المضافة في Commit `2afa...` قرب line `17107`.

ابحث حرفيًا عن:
`var RW_Finance_GoldExtension = (function () {`

واحذف الكتلة كاملة حتى آخر سطر كامل:
`RW_Finance._renderRecurringJournals = RW_Finance_GoldExtension.renderRecurring;`

ثم استبدلها بكتلة GoldExtension الجديدة التي يجب أن تحقق على الأقل الآتي، بالاعتماد على RPCs Production أعلاه:

```js
var RW_Finance_GoldExtension = (function () {
    function companyId() {
        if (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app && RW_STATE.app.companyId) return RW_STATE.app.companyId;
        if (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.user && RW_STATE.user.companyId) return RW_STATE.user.companyId;
        throw new Error('سياق الشركة غير محدد');
    }
    function today(){ return new Date().toISOString().slice(0,10); }
    function esc(v){ return String(v == null ? '' : v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;'); }
    function money(v){ return Number(v||0).toLocaleString('ar-EG',{minimumFractionDigits:2,maximumFractionDigits:2}); }
    function out(){ return byId('finance-content'); }
    function card(title,icon,body){ var o=out(); if(!o)return; safeHTML(o,'<div class="space-y-4"><div class="bg-white rounded-2xl shadow-sm border p-5"><div class="flex items-center justify-between mb-4"><h2 class="text-xl font-black"><i class="fa-solid '+icon+' ml-2 text-indigo-600"></i>'+title+'</h2></div>'+body+'</div></div>'); }
    async function rpc(name,args){ var r=await supabase.rpc(name,args||{}); if(r.error)throw r.error; return r.data; }

    async function journalList(){
        var from=byId('fin-jl-from')?byId('fin-jl-from').value:today();
        var to=byId('fin-jl-to')?byId('fin-jl-to').value:today();
        var status=byId('fin-jl-status')?byId('fin-jl-status').value:'';
        var rows=await rpc('finance_journal_list',{p_company_id:companyId(),p_from:from,p_to:to,p_status:status||null})||[];
        var h='<div class="flex flex-wrap gap-3 items-end mb-4"><div><label class="block text-sm font-bold">من</label><input id="fin-jl-from" type="date" value="'+esc(from)+'" class="border rounded-xl p-2"></div><div><label class="block text-sm font-bold">إلى</label><input id="fin-jl-to" type="date" value="'+esc(to)+'" class="border rounded-xl p-2"></div><div><label class="block text-sm font-bold">الحالة</label><select id="fin-jl-status" class="border rounded-xl p-2"><option value="">الكل</option><option value="Posted">Posted</option><option value="Draft">Draft</option></select></div><button type="button" onclick="RW_Finance._goldJournalList()" class="bg-slate-800 text-white px-4 py-2 rounded-xl font-bold">عرض</button></div>';
        h+='<div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">القيد</th><th class="p-2 border">التاريخ</th><th class="p-2 border">المرجع</th><th class="p-2 border">الوصف</th><th class="p-2 border">مدين</th><th class="p-2 border">دائن</th><th class="p-2 border">إجراء</th></tr></thead><tbody>';
        if(!rows.length)h+='<tr><td colspan="7" class="p-8 text-center text-gray-500">لا توجد قيود.</td></tr>';
        rows.forEach(function(x){h+='<tr class="border-t hover:bg-slate-50"><td class="p-2 border font-bold">'+esc(x.entry_code)+'</td><td class="p-2 border">'+esc(x.entry_date)+'</td><td class="p-2 border">'+esc(x.reference)+'</td><td class="p-2 border">'+esc(x.description)+'</td><td class="p-2 border text-left">'+money(x.total_debit)+'</td><td class="p-2 border text-left">'+money(x.total_credit)+'</td><td class="p-2 border"><button onclick="RW_Finance._goldJournalDetail(\''+esc(x.id)+'\')" class="text-indigo-600 font-bold ml-2">فتح</button><button onclick="RW_Finance._goldReverse(\''+esc(x.id)+'\')" class="text-red-600 font-bold">عكس</button></td></tr>';});
        h+='</tbody></table></div>'; card('قائمة القيود اليومية','fa-list',h);
    }

    async function journalDetail(id){ var d=await rpc('finance_journal_detail',{p_company_id:companyId(),p_entry_id:id}); var e=d.entry||{}; var ls=d.lines||[]; var h='<div class="space-y-3"><div class="grid grid-cols-2 gap-3 text-sm"><div><b>القيد:</b> '+esc(e.entry_code)+'</div><div><b>التاريخ:</b> '+esc(e.entry_date)+'</div><div><b>المرجع:</b> '+esc(e.reference)+'</div><div><b>الحالة:</b> '+esc(e.status)+'</div></div><div class="overflow-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الحساب</th><th class="p-2 border">مدين</th><th class="p-2 border">دائن</th><th class="p-2 border">البيان</th></tr></thead><tbody>';
        ls.forEach(function(x){h+='<tr><td class="p-2 border">'+esc(x.account_name)+'</td><td class="p-2 border text-left">'+money(x.debit)+'</td><td class="p-2 border text-left">'+money(x.credit)+'</td><td class="p-2 border">'+esc(x.notes)+'</td></tr>';}); h+='</tbody></table></div></div>'; if(typeof Swal!=='undefined')await Swal.fire({title:'تفاصيل القيد',html:h,width:900}); else card('تفاصيل القيد','fa-file-lines',h);
    }

    async function reverse(id){ var c=typeof Swal!=='undefined'?await Swal.fire({title:'عكس القيد؟',text:'سيتم إنشاء قيد عكسي رسمي.',icon:'warning',showCancelButton:true,confirmButtonText:'عكس'}):{isConfirmed:true}; if(!c.isConfirmed)return; var d=byId('rw-header-title'); var reason='عكس من مركز المالية'; var r=await rpc('finance_reverse_journal',{p_company_id:companyId(),p_entry_id:id,p_reversal_date:today(),p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_operation_id:crypto.randomUUID(),p_reason:reason}); if(typeof Swal!=='undefined')await Swal.fire({icon:'success',title:'تم العكس',text:(r&&r.entry_code)||''}); await journalList();
    }

    async function renderRecurring(){ var rows=await rpc('finance_list_recurring',{p_company_id:companyId()})||[]; var h='<div class="flex gap-2 mb-4"><button onclick="RW_Finance._goldNewRecurring()" class="bg-indigo-600 text-white px-4 py-2 rounded-xl font-bold">قالب جديد</button><button onclick="RW_Finance._goldRunRecurring()" class="bg-emerald-600 text-white px-4 py-2 rounded-xl font-bold">تنفيذ المستحق</button></div><div class="space-y-3">'; rows.forEach(function(t){h+='<div class="border rounded-2xl p-4 flex justify-between"><div><div class="font-black">'+esc(t.name)+'</div><div class="text-xs text-gray-500">'+esc(t.template_code)+' · '+esc(t.frequency)+' · التالي '+esc(t.next_run_date)+'</div></div><span class="px-3 py-1 rounded-full '+(t.active?'bg-green-50 text-green-700':'bg-gray-100 text-gray-500')+'">'+(t.active?'نشط':'موقوف')+'</span></div>';}); h+='</div>'; card('القيود المتكررة','fa-repeat',h); }

    async function renderExpenses(){ var from=prompt('من تاريخ YYYY-MM-DD',today().slice(0,8)+'01')||today().slice(0,8)+'01'; var to=prompt('إلى تاريخ YYYY-MM-DD',today())||today(); var rows=await rpc('finance_list_expenses',{p_company_id:companyId(),p_from:from,p_to:to})||[]; var h='<div class="mb-4"><button onclick="RW_Finance._goldNewExpense()" class="bg-emerald-600 text-white px-4 py-2 rounded-xl font-bold">مصروف جديد</button></div><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الكود</th><th class="p-2 border">التاريخ</th><th class="p-2 border">المستفيد</th><th class="p-2 border">التصنيف</th><th class="p-2 border">الإجمالي</th><th class="p-2 border">الضريبة</th><th class="p-2 border">القيد</th></tr></thead><tbody>'; rows.forEach(function(x){h+='<tr><td class="p-2 border">'+esc(x.expense_code)+'</td><td class="p-2 border">'+esc(x.expense_date)+'</td><td class="p-2 border">'+esc(x.beneficiary_name)+'</td><td class="p-2 border">'+esc(x.category_name)+'</td><td class="p-2 border text-left">'+money(x.total_amount+x.tax_amount)+'</td><td class="p-2 border text-left">'+money(x.tax_amount)+'</td><td class="p-2 border">'+esc(x.journal_entry_id)+'</td></tr>';}); h+='</tbody></table></div>'; card('المصروفات','fa-money-bill-wave',h); }

    async function renderCheques(){ var rows=await rpc('finance_list_cheques',{p_company_id:companyId(),p_status:null})||[]; var h='<div class="mb-4"><button onclick="RW_Finance._goldNewCheque()" class="bg-indigo-600 text-white px-4 py-2 rounded-xl font-bold">شيك جديد</button></div><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الرقم</th><th class="p-2 border">النوع</th><th class="p-2 border">البنك</th><th class="p-2 border">المبلغ</th><th class="p-2 border">الاستحقاق</th><th class="p-2 border">الطرف</th><th class="p-2 border">الحالة</th><th class="p-2 border">إجراء</th></tr></thead><tbody>'; rows.forEach(function(x){h+='<tr><td class="p-2 border">'+esc(x.cheque_number)+'</td><td class="p-2 border">'+esc(x.cheque_type)+'</td><td class="p-2 border">'+esc(x.bank_name)+'</td><td class="p-2 border text-left">'+money(x.amount)+'</td><td class="p-2 border">'+esc(x.due_date)+'</td><td class="p-2 border">'+esc(x.party_name)+'</td><td class="p-2 border">'+esc(x.status)+'</td><td class="p-2 border"><button onclick="RW_Finance._goldChequeTransition(\''+esc(x.id)+'\',\''+esc(x.status)+'\')" class="text-indigo-600 font-bold">تغيير الحالة</button></td></tr>';}); h+='</tbody></table></div>'; card('الشيكات','fa-money-check-dollar',h); }

    async function renderAssets(){ var rows=await rpc('finance_list_assets',{p_company_id:companyId()})||[]; var h='<div class="mb-4"><button onclick="RW_Finance._goldAddAsset()" class="bg-indigo-600 text-white px-4 py-2 rounded-xl font-bold">أصل جديد</button></div><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الكود</th><th class="p-2 border">الأصل</th><th class="p-2 border">التكلفة</th><th class="p-2 border">مجمع الإهلاك</th><th class="p-2 border">صافي القيمة</th><th class="p-2 border">الحالة</th><th class="p-2 border">إجراء</th></tr></thead><tbody>'; rows.forEach(function(a){h+='<tr><td class="p-2 border">'+esc(a.asset_code)+'</td><td class="p-2 border">'+esc(a.name)+'</td><td class="p-2 border text-left">'+money(a.cost)+'</td><td class="p-2 border text-left">'+money(a.accumulated_depreciation)+'</td><td class="p-2 border text-left font-black">'+money(a.net_book_value)+'</td><td class="p-2 border">'+esc(a.status)+'</td><td class="p-2 border"><button onclick="RW_Finance._goldDepreciate(\''+esc(a.id)+'\')" class="text-amber-700 font-bold">إهلاك</button> <button onclick="RW_Finance._goldDispose(\''+esc(a.id)+'\')" class="text-red-600 font-bold">استبعاد</button></td></tr>';}); h+='</tbody></table></div>'; card('الأصول والإهلاك','fa-building',h); }

    async function renderTax(){ var d=await rpc('finance_tax_report',{p_company_id:companyId(),p_from:today().slice(0,8)+'01',p_to:today()})||[]; var h='<div class="flex gap-2 mb-4"><button onclick="RW_Finance._goldTaxCode()" class="bg-blue-600 text-white px-4 py-2 rounded-xl font-bold">نوع ضريبة جديد</button><button onclick="RW_Finance._goldTaxSettle()" class="bg-emerald-600 text-white px-4 py-2 rounded-xl font-bold">تسوية الفترة</button></div><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الكود</th><th class="p-2 border">النوع</th><th class="p-2 border">النسبة</th><th class="p-2 border">مدخلات</th><th class="p-2 border">مخرجات</th><th class="p-2 border">الصافي</th></tr></thead><tbody>'; d.forEach(function(t){h+='<tr><td class="p-2 border">'+esc(t.code)+'</td><td class="p-2 border">'+esc(t.name)+'</td><td class="p-2 border">'+esc(t.rate)+'%</td><td class="p-2 border text-left">'+money(t.input_tax)+'</td><td class="p-2 border text-left">'+money(t.output_tax)+'</td><td class="p-2 border text-left font-black">'+money(t.net_tax)+'</td></tr>';}); h+='</tbody></table></div>'; card('الضرائب','fa-file-invoice-dollar',h); }

    async function renderPeriods(){ var r=await supabase.from('finance_periods').select('*').eq('company_id',companyId()).order('start_date',{ascending:false}); if(r.error)throw r.error; var h='<div class="flex gap-2 mb-4"><button onclick="RW_Finance._goldOpenPeriod()" class="bg-emerald-600 text-white px-4 py-2 rounded-xl font-bold">فتح فترة</button></div><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الفترة</th><th class="p-2 border">من</th><th class="p-2 border">إلى</th><th class="p-2 border">الحالة</th><th class="p-2 border">إجراء</th></tr></thead><tbody>'; (r.data||[]).forEach(function(p){h+='<tr><td class="p-2 border">'+esc(p.period_code)+'</td><td class="p-2 border">'+esc(p.start_date)+'</td><td class="p-2 border">'+esc(p.end_date)+'</td><td class="p-2 border">'+esc(p.status)+'</td><td class="p-2 border">'+(p.status==='OPEN'?'<button onclick="RW_Finance._goldClosePeriod(\''+esc(p.id)+'\')" class="text-red-600 font-bold">إغلاق</button>':'<button onclick="RW_Finance._goldReopenPeriod(\''+esc(p.id)+'\')" class="text-emerald-600 font-bold">إعادة فتح</button>')+'</td></tr>';}); h+='</tbody></table></div>'; card('الفترات المحاسبية','fa-calendar-check',h); }

    async function renderBankReconcile(){ var r=await supabase.from('finance_bank_statements').select('*').eq('company_id',companyId()).order('statement_date',{ascending:false}); if(r.error)throw r.error; var h='<div class="mb-4"><button onclick="RW_Finance._goldNewBankStatement()" class="bg-sky-700 text-white px-4 py-2 rounded-xl font-bold">كشف بنكي جديد</button></div><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الكشف</th><th class="p-2 border">التاريخ</th><th class="p-2 border">الخزينة</th><th class="p-2 border">افتتاحي</th><th class="p-2 border">ختامي</th><th class="p-2 border">الحالة</th><th class="p-2 border">إجراء</th></tr></thead><tbody>'; (r.data||[]).forEach(function(s){h+='<tr><td class="p-2 border">'+esc(s.statement_ref)+'</td><td class="p-2 border">'+esc(s.statement_date)+'</td><td class="p-2 border">'+esc(s.treasury_id)+'</td><td class="p-2 border text-left">'+money(s.opening_balance)+'</td><td class="p-2 border text-left">'+money(s.closing_balance)+'</td><td class="p-2 border">'+esc(s.status)+'</td><td class="p-2 border"><button onclick="RW_Finance._goldCloseBank(\''+esc(s.id)+'\')" class="text-indigo-600 font-bold">إغلاق</button></td></tr>';}); h+='</tbody></table></div>'; card('مطابقة البنك','fa-building-columns',h); }

    async function newRecurring(){ var f='<div class="grid grid-cols-2 gap-2 text-right"><input id="grc" class="border p-2 rounded" placeholder="كود القالب"><input id="grn" class="border p-2 rounded" placeholder="اسم القالب"><select id="grf" class="border p-2 rounded"><option value="MONTHLY">شهري</option><option value="DAILY">يومي</option><option value="WEEKLY">أسبوعي</option><option value="QUARTERLY">ربع سنوي</option><option value="YEARLY">سنوي</option></select><input id="grd" type="date" value="'+today()+'" class="border p-2 rounded"><textarea id="grl" class="border p-2 rounded col-span-2" rows="6" placeholder="JSON lines: [{\"account_id\":\"UUID\",\"debit\":100,\"credit\":0},{...}]"></textarea></div>'; if(typeof Swal==='undefined')return; var r=await Swal.fire({title:'قيد متكرر جديد',html:f,showCancelButton:true,confirmButtonText:'حفظ',preConfirm:function(){try{return JSON.parse(byId('grl').value)}catch(e){Swal.showValidationMessage('JSON غير صحيح')}}}); if(!r.isConfirmed)return; await rpc('finance_save_recurring',{p_company_id:companyId(),p_template_id:null,p_template_code:byId('grc').value.trim(),p_name:byId('grn').value.trim(),p_frequency:byId('grf').value,p_next_run_date:byId('grd').value,p_end_date:null,p_description:'',p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_lines:r.value}); await renderRecurring(); }

    async function runRecurring(){ await rpc('finance_run_recurring',{p_company_id:companyId(),p_run_until:today(),p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'}); await renderRecurring(); }

    async function newCheque(){ if(typeof Swal==='undefined')return; var h='<div class="grid grid-cols-2 gap-2"><input id="gcno" class="border p-2 rounded" placeholder="رقم الشيك"><select id="gct" class="border p-2 rounded"><option value="PAYABLE">دائن</option><option value="RECEIVABLE">مدين</option></select><input id="gcb" class="border p-2 rounded" placeholder="البنك"><input id="gca" type="number" class="border p-2 rounded" placeholder="المبلغ"><input id="gcd" type="date" value="'+today()+'" class="border p-2 rounded"><input id="gdu" type="date" value="'+today()+'" class="border p-2 rounded"><input id="gcp" class="border p-2 rounded col-span-2" placeholder="الطرف"><textarea id="gcn" class="border p-2 rounded col-span-2" placeholder="ملاحظات"></textarea></div>'; var r=await Swal.fire({title:'شيك جديد',html:h,showCancelButton:true,confirmButtonText:'حفظ'}); if(!r.isConfirmed)return; await rpc('finance_save_cheque',{p_company_id:companyId(),p_id:null,p_cheque_number:byId('gcno').value.trim(),p_cheque_type:byId('gct').value,p_bank_name:byId('gcb').value.trim(),p_amount:Number(byId('gca').value),p_cheque_date:byId('gcd').value,p_due_date:byId('gdu').value,p_party_name:byId('gcp').value.trim(),p_from_account_id:null,p_to_account_id:null,p_treasury_id:null,p_notes:byId('gcn').value,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'}); await renderCheques(); }

    async function newBank(){ if(typeof Swal==='undefined')return; var r=await Swal.fire({title:'كشف بنكي جديد',html:'<input id="gbr" class="swal2-input" placeholder="Statement Ref"><input id="gbo" type="number" class="swal2-input" placeholder="Opening"><input id="gbc" type="number" class="swal2-input" placeholder="Closing">',showCancelButton:true,confirmButtonText:'حفظ',preConfirm:function(){return {ref:byId('gbr').value,opening:Number(byId('gbo').value),closing:Number(byId('gbc').value)}}}); if(!r.isConfirmed)return; var ts=await supabase.from('treasury').select('id').eq('company_id',companyId()).eq('is_active',true).limit(1).maybeSingle(); if(ts.error||!ts.data)throw new Error('لا توجد خزينة فعالة'); await rpc('finance_open_bank_statement',{p_company_id:companyId(),p_treasury_id:ts.data.id,p_statement_ref:r.value.ref,p_statement_date:today(),p_opening:r.value.opening,p_closing:r.value.closing,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother',p_lines:[]}); await renderBankReconcile(); }

    async function closeBank(id){ await rpc('finance_close_bank_statement',{p_company_id:companyId(),p_statement_id:id,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'}); await renderBankReconcile(); }
    async function closePeriod(id){ await rpc('finance_close_period',{p_company_id:companyId(),p_period_id:id,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'}); await renderPeriods(); }
    async function reopenPeriod(id){ await rpc('finance_reopen_period',{p_company_id:companyId(),p_period_id:id,p_created_by:(RW_STATE.user&&RW_STATE.user.email)||'mother'}); await renderPeriods(); }

    return {journalList:journalList,renderAssets:renderAssets,renderTax:renderTax,renderPeriods:renderPeriods,renderBankReconcile:renderBankReconcile,renderRecurring:renderRecurring,renderExpenses:renderExpenses,renderCheques:renderCheques,journalDetail:journalDetail,reverse:reverse,newRecurring:newRecurring,runRecurring:runRecurring,newCheque:newCheque,newBank:newBank,closeBank:closeBank,closePeriod:closePeriod,reopenPeriod:reopenPeriod};
})();
window.RW_Finance = RW_Finance;
RW_Finance._goldJournalList = RW_Finance_GoldExtension.journalList;
RW_Finance._renderJournalList = RW_Finance_GoldExtension.journalList;
RW_Finance._renderAssets = RW_Finance_GoldExtension.renderAssets;
RW_Finance._renderTax = RW_Finance_GoldExtension.renderTax;
RW_Finance._renderPeriods = RW_Finance_GoldExtension.renderPeriods;
RW_Finance._renderBankReconcile = RW_Finance_GoldExtension.renderBankReconcile;
RW_Finance._renderRecurringJournals = RW_Finance_GoldExtension.renderRecurring;
RW_Finance._renderExpenses = RW_Finance_GoldExtension.renderExpenses;
RW_Finance._renderCheques = RW_Finance_GoldExtension.renderCheques;
RW_Finance._goldJournalDetail = RW_Finance_GoldExtension.journalDetail;
RW_Finance._goldReverse = RW_Finance_GoldExtension.reverse;
RW_Finance._goldNewRecurring = RW_Finance_GoldExtension.newRecurring;
RW_Finance._goldRunRecurring = RW_Finance_GoldExtension.runRecurring;
RW_Finance._goldNewCheque = RW_Finance_GoldExtension.newCheque;
RW_Finance._goldNewBankStatement = RW_Finance_GoldExtension.newBank;
RW_Finance._goldCloseBank = RW_Finance_GoldExtension.closeBank;
RW_Finance._goldClosePeriod = RW_Finance_GoldExtension.closePeriod;
RW_Finance._goldReopenPeriod = RW_Finance_GoldExtension.reopenPeriod;
```

### ملاحظة إلزامية على PATCH MOTHER-01

الكتلة أعلاه تعالج الـruntime holes التي ثبتت من Git الحالي، لكنها لا تعتبر Browser E2E مكتملة حتى يقوم المالك بدمجها ثم اختبارها بمستخدم authenticated حقيقي.

`_goldAddAsset`, `_goldDepreciate`, `_goldDispose`, `_goldTaxCode`, `_goldTaxSettle` ما زالت تحتاج UI forms مخصصة قبل إعلان Finance UI Gold/Diamond؛ Production APIs الخاصة بهذه الأعمال موجودة، لكن لا يجوز إعلان اكتمال الواجهة دونها.

## 9. التحقق بعد دمج المالك

التسلسل الصحيح:

1. Checkout HEAD الحالي `0849...`.
2. تأكيد parent `2afa...`.
3. التأكد أن `main.html` ما زال هو Source of Truth.
4. تطبيق PATCH MOTHER-01 فقط.
5. فتح Finance authenticated.
6. اختبار Console = 0.
7. اختبار Network لكل RPC.
8. Journal list → detail → reverse.
9. Expense → journal → tax transaction.
10. Tax report → settlement.
11. Asset → depreciation → disposal.
12. Bank statement → line match/exclude → close.
13. Cheque → status transition.
14. Recurring template → runtime execution → generated journal.
15. Period open/close/reopen.
16. مطابقة النتائج مع Production في نفس اللحظة.

## 10. FINAL SELF-AUDIT

### What was proved
- Current Git HEAD وparent تم التحقق منهما.
- Source of Truth الحالي صحيح.
- `forensic_main_assembly.yml` صحيح.
- Production schema تمت مطابقته لحظة التنفيذ.
- طبقات backend للفجوات المالية تم إنشاؤها أو تثبيتها في Production.
- Central Journal Engine مربوط بالـperiod guard وoperation registry.
- Expenses/Tax/Assets/Bank/Cheques/Recurring/Periods لها Production contracts حقيقية.
- Legacy cheque direct writes تم منعها.

### What was not proved
- Authenticated Browser E2E.
- Complete tax lifecycle من transaction source التشغيلي إلى final declaration الواقعي.
- Real bank file import/reconciliation against an actual bank statement file.
- End-to-end asset lifecycle from real purchase source through disposal in browser.
- Automatic recurring scheduler runtime because current Production has no pg_cron/pg_net.

### Current closure

```text
Finance Production Business Contracts = IMPLEMENTED
Mother Finance structural navigation = PRESENT
Mother Finance runtime holes = IDENTIFIED + SURGICAL PATCH PREPARED
Authenticated Mother Finance Browser E2E = OPEN
Finance Gold/Diamond = NOT CLOSED YET
```

## 11. تعليمات المساعد التالي

لا تبدأ من Report214.
ابدأ من:
`CURRENT GIT → PARENT COMMIT → CURRENT MAIN SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT EVIDENCE`

ثم:
`ONE CLOSURE UNIT → TRACE CONSUMERS → VERIFY CONTRACT → PATCH → TEST → DEPLOY → PRODUCTION VERIFY → CLOSE`

لا تعيد إصلاح ما ثبت أنه يعمل.
لا تعتبر وجود جدول أو RPC إتمامًا للعقد.
لا تعتبر SQL PASS مساويًا لـBrowser E2E PASS.
لا تستخدم التاريخ لإثبات Current.
ولا تنتقل من Finance إلى أي إدارة أخرى قبل إغلاق authenticated Mother Finance E2E الحقيقية.
