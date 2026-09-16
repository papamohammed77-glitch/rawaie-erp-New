# Report 212 — التحقيق الجنائي المقارن للنظام الأم RAWAEA ERP مقابل Daftra — الحسابات والمالية

**التاريخ:** 2026-09-16

## 0. نقطة البداية الحاكمة — يجب قراءتها أولًا وإعادتها عند أي جلسة لاحقة

الهدف من هذه الجلسة كان تدقيق **النظام الأم الحالي** واختباره بالنسبة لتبويب **إدارة الحسابات والمالية فقط**، مع اعتبار الملف:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

هو **Source of Truth الوحيد للواجهة الأم**. تم التعامل مع `Current/PWA/main2/*` والملفات التاريخية والتقارير كمواد استرشادية فقط.

كما تم تطبيق قاعدة الحوكمة: لا نسبة ولا حالة إغلاق قبل مطابقة:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ثم استخدام الأدلة التشغيلية الحالية لتحديد الفجوات.

## 1. استرجاع الحالة الحالية

آخر Git HEAD الفعلي في `erp-frontend` وقت التحقيق:

`0e49c7e2995ee6066ec8503b11a56784bf6c97ff`

الرسالة:

`forensic: persist current Mother inventory extract`

والـparent المباشر:

`15be4a278498665f86dbb5295ceba7df8adc5df5`

والـparent لهذا الـparent:

`9f84e24f4dd93381aaaff12ceb04f84ddde95fb0`

الـparent `15be...` يتضمن تغييرًا غير تشغيليًا (تعديل تعليق زمني) إضافة إلى تغييرات Mother inventory السابقة؛ لذلك لا يجوز اعتباره دليلًا على اكتمال Finance.

`forensic_main_assembly.yml` تم التحقق منه، وهو يشير بالفعل إلى:

`companies/company-1/main.html`

وبالتالي **لا يلزم تغيير Source of Truth أو مسار reconstruction في هذا الملف**.

## 2. مبدأ المقارنة

لم يتم نسخ Daftra. استُخدمت وثائقه الرسمية الحالية كـbenchmark وظيفي وUX benchmark فقط.

وثائق Daftra الحالية تثبت وجود قدرات مثل:

- دليل حسابات هرمي مع أرصدة وتفاصيل الحساب ومصدر الحركة.
- قائمة قيود مع البحث والتصفية والتاريخ والمصدر ومراكز التكلفة والتصدير والطباعة والنسخ والعكس وسجل التعديلات.
- قيود متكررة.
- سندات قبض وصرف مع مصدر وبيانات الطرف والتعاملات.
- تقارير مالية رئيسية، تقارير الضرائب وتسويتها.
- إدارة الأصول والإهلاك ودورة حياة الأصل.
- مزامنة/مطابقة الحسابات البنكية.
- المصروفات والإيرادات والمرفقات.

المصادر: Daftra Accounting Features، Daftra Journal Guides، Daftra Tax Guides، Daftra Assets Guides، Daftra Plans.

## 3. الوضع الحالي الفعلي في RAWAEA — واجهة الأم

الوضع الحالي يحتوي فعليًا على `RW_Finance`، وتشغيله يتضمن:

- `treasury`
- `accounts`
- `journal`
- `receipts`
- `payments`
- `transfers`
- `reports`
- `installments`
- `commission`
- `budgets` داخليًا، لكنه ليس ظاهرًا في القائمة الرئيسية الحالية.

### 3.1 دليل الحسابات

الحالة الحالية: **موجود ويعمل كـtree، لكنه أقل من مستوى الحسابات الاحترافي التنافسي**.

الموجود:
- حسابات شجرية.
- إضافة حساب.
- تهيئة دليل الحسابات.
- بحث.

الفجوة المثبتة:
- لا يعرض رصيد الحساب في الشجرة.
- لا يعرض مدين/دائن بشكل مباشر.
- لا توجد بطاقة حساب غنية مرتبطة بالنشاط والمصدر.
- لا توجد إدارة واضحة للحساب الرئيسي/الفرعي داخل العرض نفسه.

Daftra يعرض أرصدة الحسابات وتفاصيل مدين/دائن ومصادر القيود عند فتح الحساب.

### 3.2 القيود اليومية

الموجود:
- إدخال قيد يدوي.
- التاريخ.
- المرجع.
- الوصف.
- حساب + مركز تكلفة + مدين + دائن.
- حفظ القيد.

الفجوة:
- لا توجد شاشة تشغيلية مستقلة لقائمة القيود مع filters.
- لا توجد معاينة/فتح القيد السابق.
- لا توجد نسخة/تكرار قيد من الواجهة.
- لا يوجد Reverse workflow في الأم.
- لا يوجد Source Drill-down.
- لا يوجد سجل تعديلات ظاهر للقيد.
- لا يوجد recurring journals في الواجهة.
- لا يوجد attachment/source-document UI للقيد.

Daftra يثبت وجود هذه السلسلة الوظيفية في قائمة القيود وعرض القيد والقيود المتكررة.

### 3.3 سندات القبض

الحالة الحالية أفضل من بقية النماذج لأن تحصيل العملاء يدعم:
- العميل.
- الخزينة.
- مبلغ الدفع.
- الفواتير المفتوحة.
- تخصيص الدفعة على عدة فواتير.
- غير مخصص/رصيد دائن.
- operation id.
- realtime reload.

لكن سند القبض العام ما زال عامًا وبسيطًا ولا يرقى لنظام مستندات مالي كامل.

### 3.4 سندات الصرف

الحالة الحالية تعتمد على:
- خزينة.
- حساب مقابل.
- بنود نصية.
- amount.
- save-payment-voucher.

الفجوة:
- الطرف المستفيد ليس كيانًا ماليًا واضحًا.
- لا توجد دورة مصروفات واضحة.
- لا توجد تصنيفات مصروفات مع مرفقات/مستند مصدر.
- لا توجد recurring expenses.
- لا توجد شاشة تفاصيل غنية.

### 3.5 التحويلات

الحالة الحالية موجودة وتعمل، لكنها أقرب إلى transaction form من كونها bank/cash transfer center كامل.

### 3.6 التقارير

الموجود حاليًا:
- ميزان مراجعة.
- قائمة دخل.
- ميزانية عمومية.
- تدفقات نقدية.
- P&L حسب مركز تكلفة.
- أستاذ عام.
- أعمار العملاء.
- أعمار الموردين.
- المطابقات.
- مركز الاستثناءات.
- جاهزية الفترة.

لكن العرض الحالي عبارة عن buttons + result area وليس مركز مالي كامل ذي drill-down، filters، export، print، source navigation، period controls.

### 3.7 التقسيط والعمولات والموازنات

`installments` و`commission` وصلتا إلى مستوى وظيفي جيد نسبيًا وتدعمان realtime وoperation IDs.

`budgets` لها backend موجود بالفعل وتستخدم `save_budget_atomic` و`get_budget_vs_actual`، لكنها **غير ظاهرة ضمن menu Finance الحالي**.

## 4. Production Database forensic result

مشروع Supabase المستخدم في Production:

`fiilmooggumokxanwiyx`

تم إثبات وجود البنية الأساسية التالية:

`chart_of_accounts`
`journal_entries`
`journal_lines`
`treasury`
`cash_box`
`customer_ledger`
`supplier_ledger`
`sales_payment_receipts`
`sales_payment_allocations`
`purchase_payments`
`purchase_payment_allocations`
`purchase_invoices`
`credit_notes`
`installments`
`budgets`
`cost_centers`
`cheques`

### 4.1 Production gaps الحقيقية التي لم تكن مجرد UI gaps

لم توجد جداول مخصصة مستقلة للأتي:

- الأصول الثابتة.
- دورات الإهلاك.
- قيود متكررة كـtemplate engine.
- فترات محاسبية قابلة للغلق فعليًا.
- سجل ضريبي transaction-level.
- بنية bank statement/reconciliation.

كما ثبت أن `cost_centers` و`budgets` يفتقران إلى company_id مباشر، وهو دين tenant يحتاج حذرًا وعدم معالجة أعمى.

كما ثبت أن `cheques` لا تحمل company_id في schema الحالية.

## 5. أعمال Production التي تم تنفيذها في هذه الجلسة

تم إنشاء الأساس التالي في Production:

### 5.1 `finance_periods`

- Company scoped.
- Period code.
- Fiscal year.
- Start/end.
- OPEN/CLOSED.
- closed_at / closed_by.
- unique per company.

تم إنشاء فترة FY2026 مفتوحة للشركة التي لديها بيانات تشغيلية حالية.

كما تم إنشاء:

`finance_period_guard(...)`

التي تمنع الترحيل داخل فترة مغلقة.

### 5.2 `finance_tax_codes`

جدول لإدارة:
- tax code.
- name.
- rate.
- sales account.
- purchase account.
- settlement account.
- active.

### 5.3 `finance_tax_transactions`

سجل transaction-level للضرائب، مع:
- INPUT / OUTPUT / OTHER.
- taxable amount.
- tax amount.
- source type/source id.
- journal entry.
- operation id.
- settled period.

وتم إنشاء:

`finance_tax_post(...)`

و

`finance_tax_report(...)`

### 5.4 الأصول الثابتة

تم إنشاء:

`fixed_assets`

و

`fixed_asset_events`

مع ربط الأصل بحساب الأصل، مجمع الإهلاك، مصروف الإهلاك، وحساب الربح/الخسارة.

وتم إنشاء:

`post_fixed_asset_depreciation(...)`

لدعم الإهلاك الدوري مع operation id ومنع التكرار.

### 5.5 القيود المتكررة

تم إنشاء:

`recurring_journal_templates`
`recurring_journal_lines`

لتأسيس محرك recurring journals حقيقي بدل UI شكلي.

### 5.6 Bank reconciliation foundation

تم إنشاء:

`finance_bank_statements`
`finance_bank_statement_lines`

و

`finance_save_bank_statement(...)`
`finance_match_bank_line(...)`
`finance_bank_reconciliation_summary(...)`

### 5.7 RLS

تم تفعيل RLS على الجداول الجديدة وربط SELECT بـ`app_private.current_user_company_id()`، مع منع direct write للـanon/authenticated حيث يلزم.

### 5.8 Finance accounting snapshot

تم إنشاء:

`finance_accounting_snapshot(...)`

لتوفير snapshot محاسبي موحد للمبالغ الأساسية، لاستخدامه كنواة Control Center وليس مصدرًا موازيًا للـledger.

## 6. أخطاء ومحاولات فشلت وتم تسجيلها

### فشل 1 — اختبار idempotency في Purchase Receiving

النسخة الأولى من منطق `receive_purchase_atomic` جعلت الـoperation identity متغيرًا بتغير `qty_received_before`، ثم جاء فحص quantity قبل duplicate resolution. لذلك retry تم رفضه بعد نجاح العملية.

تم تشخيص السبب وعدم إخفائه بترقيع سريع.

القرار النهائي: operation identity يجب أن تكون صريحة وثابتة على مستوى العملية القادمة من client/Edge، لا hash مشتق من الحالة المتغيرة.

### فشل 2 — محاولة تعديل وظيفة موجودة بتوقيع له defaults

PostgreSQL رفض تغيير parameter defaults/return contract بالطريقة المقترحة. لم يتم كسر الوظيفة القائمة.

### فشل 3 — محاولة توثيق الجلسة باستخدام `audit_log action` غير مسموح

استخدمت قيمة action غير موجودة في CHECK constraint فرفضت العملية. لم يتم التحايل على الـconstraint، وتم إعادة التسجيل باستخدام action مسموح.

### فشل 4 — محاولات SQL غير الصحيحة أثناء البحث

ظهرت أخطاء syntax/column-name أثناء التحقيق (`pg_tables.tablename`، وjsonb aggregation). تم تصحيح الاستعلامات دون تعديل بيانات الأعمال.

## 7. قرار معماري مهم

تم الحفاظ على العقد الحاكم:

`Physical Stock → post_stock_movement → stock_branches + inventory_log`

ولم يتم إنشاء أي Physical Stock writer جديد من أجل Finance.

كما لم يتم إنشاء محرك محاسبي موازٍ للـledger.

## 8. مقارنة RAWAEA × Daftra — Finance only

| المجال | RAWAEA الحالي | Daftra الحالي | الفجوة الحقيقية | الإجراء |
|---|---|---|---|---|
| Chart of Accounts | شجرة أساسية | شجرة + balances + drill-down | متوسطة | Mother surgery |
| Journal Entry | إنشاء يدوي | إنشاء + list + view + reverse + copy + source + logs | كبيرة | Mother + backend |
| Recurring Journals | backend foundation جديد | موجود | كبيرة | Mother + engine |
| Receipts | customer allocation قوي | receipts general | متوسطة | توسيع general receipt |
| Payments/Expenses | payment voucher بسيط | expense lifecycle + categories + attachments | كبيرة | إنشاء expense center |
| Cash/Treasury | موجود | treasury + bank sync/reconcile | كبيرة | bank center |
| Bank Reconciliation | foundation جديد | sync + reconciliation | كبيرة | استكمال matching/import |
| Cheques | جدول موجود | financial cheque workflow | كبيرة | cheque center |
| Tax | tax foundation جديد | declaration/report/settlement | كبيرة | transaction integration + settlement UI |
| Fixed Assets | foundation جديد | asset lifecycle + depreciation | كبيرة | asset lifecycle UI/actions |
| Financial Reports | مجموعة تقارير جيدة | reports + filters + export/source | متوسطة/كبيرة | finance reporting center |
| Period Close | readiness فقط | closing/reporting controls | كبيرة | period UI + close/reopen policy |
| Budgets | backend موجود لكن hidden | budgeting/reporting | متوسطة | إظهار وتوسيع |
| Installments | جيد | موجود | منخفضة | maintain |
| Commission | جيد | موجود | منخفضة | maintain |

## 9. الهدف الوظيفي المستخلص

Finance في RAWAEA يجب ألا يتحول إلى نسخة من Daftra.

الـtarget الصحيح هو:

`Mother Finance Control Plane`

يوحد:

`Accounts → Journals → Receipts → Payments → Treasury → Bank → Tax → Assets → Budgets → Periods → Reports`

مع بقاء العمليات التشغيلية الأصلية:

`Sales → Orders → Picking → Loading → Delivery → Return → Unloading`

مصدرًا للقيود والمستحقات بدل إدخالها مرة أخرى يدويًا.

## 10. الجراحة المطلوبة في Mother main.html

### الجراحة A — قائمة إدارة الحسابات والمالية

في النسخة الحالية من `main.html` ابحث عن السطر الذي يحتوي حرفيًا على:

`{ icon: 'fa-coins', label: 'إدارة الحسابات والمالية', submenu:`

واستبدل **كتلة `submenu` الحالية كاملة** داخل نفس عنصر `fa-coins` بالكتلة التالية:

```js
submenu: [
    { action: 'showFinanceTab', arg: 'treasury', label: 'الخزائن والبنوك', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'accounts', label: 'دليل الحسابات', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'journal-list', label: 'قائمة القيود اليومية', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'journal', label: 'قيد يومي جديد', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'recurring-journals', label: 'القيود المتكررة', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'receipts', label: 'سندات القبض', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'payments', label: 'سندات الصرف', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'expenses', label: 'المصروفات', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'transfers', label: 'التحويلات', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'cheques', label: 'الشيكات', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'bank-reconcile', label: 'مطابقة البنك', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'tax', label: 'الضرائب', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'assets', label: 'الأصول والإهلاك', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'budgets', label: 'الموازنات', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'periods', label: 'الفترات المحاسبية', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'installments', label: 'التقسيط والتحصيل الآجل', perm: ['finance', 'finance_manager'] },
    { action: 'showFinanceTab', arg: 'commission', label: 'العمولات', perm: ['finance', 'finance_manager'] },
    { view: 'settlement', label: 'إغلاق اليومية' }
]
```

آخر سطر للعنصر البديل هو:

`    ]`

ثم تابع نفس قوس عنصر `إدارة الحسابات والمالية` الموجود بالفعل.

### الجراحة B — tabs داخل RW_Finance

ابحث داخل `RW_Finance` عن الكتلة التي تبدأ حرفيًا بـ:

```js
var tabs = [
```

وتنتهي مباشرة قبل:

```js
var html = '<div class="p-4">'
```

استبدل **الكتلة الكاملة للـtabs** بـ:

```js
var tabs = [
    { id: 'treasury', label: 'الخزائن والبنوك' },
    { id: 'accounts', label: 'دليل الحسابات' },
    { id: 'journal-list', label: 'قائمة القيود' },
    { id: 'journal', label: 'قيد يومي جديد' },
    { id: 'recurring-journals', label: 'القيود المتكررة' },
    { id: 'receipts', label: 'سندات القبض' },
    { id: 'payments', label: 'سندات الصرف' },
    { id: 'expenses', label: 'المصروفات' },
    { id: 'transfers', label: 'التحويلات' },
    { id: 'cheques', label: 'الشيكات' },
    { id: 'bank-reconcile', label: 'مطابقة البنك' },
    { id: 'tax', label: 'الضرائب' },
    { id: 'assets', label: 'الأصول والإهلاك' },
    { id: 'budgets', label: 'الموازنات' },
    { id: 'periods', label: 'الفترات المحاسبية' },
    { id: 'reports', label: 'التقارير المالية' },
    { id: 'installments', label: 'التقسيط والتحصيل الآجل' },
    { id: 'commission', label: 'العمولات' }
];
```

### الجراحة C — dispatch داخل renderSubTab

في نفس الدالة التي تحتوي:

```js
else if (tab === 'reports') _renderReports();
```

أضف **فوق هذا السطر مباشرة**:

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

### الجراحة D — extension block جديد بعد RW_Finance

ابحث عن آخر سطر كامل:

```js
window.RW_Finance = RW_Finance;
```

أضف **فوقه مباشرة** كتلة `RW_Finance_GoldExtension` التالية:

```js
var RW_Finance_GoldExtension = (function () {
    function companyId() {
        if (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app && RW_STATE.app.companyId) return RW_STATE.app.companyId;
        if (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.user && RW_STATE.user.companyId) return RW_STATE.user.companyId;
        throw new Error('سياق الشركة غير محدد');
    }

    function today() {
        return new Date().toISOString().slice(0, 10);
    }

    function esc(v) {
        return String(v == null ? '' : v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
    }

    function money(v) {
        return Number(v || 0).toLocaleString('ar-EG', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    async function token() {
        var s = await supabase.auth.getSession();
        var t = s && s.data && s.data.session ? s.data.session.access_token : null;
        if (!t) throw new Error('انتهت الجلسة');
        return t;
    }

    async function journalList() {
        var out = byId('finance-content');
        if (!out) return;
        var from = byId('fin-jl-from') ? byId('fin-jl-from').value : today();
        var to = byId('fin-jl-to') ? byId('fin-jl-to').value : today();
        var status = byId('fin-jl-status') ? byId('fin-jl-status').value : '';
        safeHTML(out, '<div class="bg-white rounded-2xl shadow-sm border p-5"><div class="text-center py-10">جاري تحميل قائمة القيود...</div></div>');
        var r = await supabase.rpc('finance_journal_list', { p_company_id: companyId(), p_from: from, p_to: to, p_status: status || null });
        if (r.error) throw r.error;
        var rows = r.data || [];
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
            '<div class="flex flex-wrap gap-3 items-end mb-4">' +
            '<div><label class="block text-sm font-bold">من</label><input id="fin-jl-from" type="date" value="'+esc(from)+'" class="border rounded-xl p-2"></div>' +
            '<div><label class="block text-sm font-bold">إلى</label><input id="fin-jl-to" type="date" value="'+esc(to)+'" class="border rounded-xl p-2"></div>' +
            '<div><label class="block text-sm font-bold">الحالة</label><select id="fin-jl-status" class="border rounded-xl p-2"><option value="">الكل</option><option value="Posted">Posted</option><option value="Draft">Draft</option></select></div>' +
            '<button type="button" onclick="RW_Finance._goldJournalList()" class="bg-slate-800 text-white px-4 py-2 rounded-xl font-bold">عرض</button>' +
            '</div>';
        if (!rows.length) html += '<div class="text-center py-10 text-gray-500">لا توجد قيود في الفترة.</div>';
        else {
            html += '<div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">القيد</th><th class="p-2 border">التاريخ</th><th class="p-2 border">المرجع</th><th class="p-2 border">الوصف</th><th class="p-2 border">مدين</th><th class="p-2 border">دائن</th><th class="p-2 border">الحالة</th></tr></thead><tbody>';
            rows.forEach(function(x){ html += '<tr class="border-t hover:bg-slate-50"><td class="p-2 border font-bold">'+esc(x.entry_code)+'</td><td class="p-2 border">'+esc(x.entry_date)+'</td><td class="p-2 border">'+esc(x.reference)+'</td><td class="p-2 border">'+esc(x.description)+'</td><td class="p-2 border text-left">'+money(x.total_debit)+'</td><td class="p-2 border text-left">'+money(x.total_credit)+'</td><td class="p-2 border">'+esc(x.status)+'</td></tr>'; });
            html += '</tbody></table></div>';
        }
        html += '</div>';
        safeHTML(out, html);
    }

    function renderSimple(title, icon, body) {
        var out = byId('finance-content');
        if (!out) return;
        safeHTML(out, '<div class="space-y-4"><div class="bg-white rounded-2xl shadow-sm border p-5"><h2 class="text-xl font-black"><i class="fa-solid '+icon+' ml-2 text-indigo-600"></i>'+title+'</h2>'+body+'</div></div>');
    }

    async function renderAssets() {
        try {
            var r = await supabase.rpc('finance_list_assets', { p_company_id: companyId() });
            if (r.error) throw r.error;
            var rows = r.data || [];
            var h = '<div class="flex justify-between items-center mb-4"><h2 class="text-xl font-black">الأصول والإهلاك</h2><button onclick="RW_Finance._goldAddAsset()" class="bg-indigo-600 text-white px-4 py-2 rounded-xl font-bold">أصل جديد</button></div>';
            h += '<div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الكود</th><th class="p-2 border">الأصل</th><th class="p-2 border">التكلفة</th><th class="p-2 border">مجمع الإهلاك</th><th class="p-2 border">القيمة الدفترية</th><th class="p-2 border">الحالة</th></tr></thead><tbody>';
            rows.forEach(function(a){ h += '<tr class="border-t"><td class="p-2 border">'+esc(a.asset_code)+'</td><td class="p-2 border font-bold">'+esc(a.name)+'</td><td class="p-2 border text-left">'+money(a.cost)+'</td><td class="p-2 border text-left">'+money(a.accumulated_depreciation)+'</td><td class="p-2 border text-left font-black">'+money(a.net_book_value)+'</td><td class="p-2 border">'+esc(a.status)+'</td></tr>'; });
            h += '</tbody></table></div>';
            renderSimple('مركز الأصول والإهلاك','fa-building',h);
        } catch(e) { renderSimple('الأصول والإهلاك','fa-building','<div class="text-red-600 py-6">'+esc(e.message)+'</div>'); }
    }

    async function renderTax() {
        try {
            var r = await supabase.rpc('finance_tax_report', { p_company_id: companyId(), p_from: today().slice(0,8)+'01', p_to: today() });
            if (r.error) throw r.error;
            var rows = r.data || [];
            var h = '<div class="flex justify-between items-center mb-4"><div><h2 class="text-xl font-black">الضرائب</h2><p class="text-sm text-gray-500">السجل الضريبي والفروقات القابلة للتسوية.</p></div><button onclick="RW_Finance._goldTaxCode()" class="bg-blue-600 text-white px-4 py-2 rounded-xl font-bold">إضافة نوع ضريبة</button></div>';
            h += '<div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الكود</th><th class="p-2 border">النوع</th><th class="p-2 border">النسبة</th><th class="p-2 border">مدخلات</th><th class="p-2 border">مخرجات</th><th class="p-2 border">الصافي</th></tr></thead><tbody>';
            rows.forEach(function(t){ h += '<tr class="border-t"><td class="p-2 border">'+esc(t.code)+'</td><td class="p-2 border">'+esc(t.name)+'</td><td class="p-2 border">'+esc(t.rate)+'%</td><td class="p-2 border text-left">'+money(t.input_tax)+'</td><td class="p-2 border text-left">'+money(t.output_tax)+'</td><td class="p-2 border text-left font-black">'+money(t.net_tax)+'</td></tr>'; });
            h += '</tbody></table></div>';
            renderSimple('الضرائب','fa-file-invoice-dollar',h);
        } catch(e) { renderSimple('الضرائب','fa-file-invoice-dollar','<div class="text-red-600 py-6">'+esc(e.message)+'</div>'); }
    }

    async function renderPeriods() {
        var r = await supabase.from('finance_periods').select('*').eq('company_id',companyId()).order('start_date',{ascending:false});
        if (r.error) return renderSimple('الفترات المحاسبية','fa-calendar-check','<div class="text-red-600 py-6">'+esc(r.error.message)+'</div>');
        var h = '<div class="flex justify-between items-center mb-4"><h2 class="text-xl font-black">الفترات المحاسبية</h2><button onclick="RW_Finance._goldOpenPeriod()" class="bg-emerald-600 text-white px-4 py-2 rounded-xl font-bold">فتح/إعادة فتح</button></div><div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الفترة</th><th class="p-2 border">من</th><th class="p-2 border">إلى</th><th class="p-2 border">الحالة</th><th class="p-2 border">إجراء</th></tr></thead><tbody>';
        (r.data||[]).forEach(function(p){h+='<tr class="border-t"><td class="p-2 border font-bold">'+esc(p.period_code)+'</td><td class="p-2 border">'+esc(p.start_date)+'</td><td class="p-2 border">'+esc(p.end_date)+'</td><td class="p-2 border">'+esc(p.status)+'</td><td class="p-2 border"><button onclick="RW_Finance._goldClosePeriod(\''+esc(p.id)+'\')" class="text-red-600 font-bold">إغلاق</button></td></tr>';});
        h += '</tbody></table></div>'; renderSimple('الفترات المحاسبية','fa-calendar-check',h);
    }

    async function renderBankReconcile() {
        var r = await supabase.from('finance_bank_statements').select('*').eq('company_id',companyId()).order('statement_date',{ascending:false});
        if (r.error) return renderSimple('مطابقة البنك','fa-building-columns','<div class="text-red-600 py-6">'+esc(r.error.message)+'</div>');
        var h = '<div class="flex justify-between items-center mb-4"><h2 class="text-xl font-black">مطابقة البنك</h2><button onclick="RW_Finance._goldNewBankStatement()" class="bg-sky-700 text-white px-4 py-2 rounded-xl font-bold">كشف بنكي جديد</button></div>';
        h += '<div class="overflow-x-auto"><table class="w-full text-sm border"><thead><tr class="bg-slate-50"><th class="p-2 border">الكشف</th><th class="p-2 border">التاريخ</th><th class="p-2 border">الخزينة</th><th class="p-2 border">الرصيد الافتتاحي</th><th class="p-2 border">الرصيد الختامي</th><th class="p-2 border">الحالة</th></tr></thead><tbody>';
        (r.data||[]).forEach(function(s){ h += '<tr class="border-t"><td class="p-2 border font-bold">'+esc(s.statement_ref)+'</td><td class="p-2 border">'+esc(s.statement_date)+'</td><td class="p-2 border">'+esc(s.treasury_id)+'</td><td class="p-2 border text-left">'+money(s.opening_balance)+'</td><td class="p-2 border text-left">'+money(s.closing_balance)+'</td><td class="p-2 border">'+esc(s.status)+'</td></tr>'; });
        h += '</tbody></table></div>'; renderSimple('مطابقة البنك','fa-building-columns',h);
    }

    async function renderRecurring() {
        var r = await supabase.rpc('finance_list_recurring', { p_company_id: companyId() });
        if (r.error) return renderSimple('القيود المتكررة','fa-repeat','<div class="text-red-600 py-6">'+esc(r.error.message)+'</div>');
        var rows = Array.isArray(r.data) ? r.data : [];
        var h = '<div class="flex justify-between items-center mb-4"><h2 class="text-xl font-black">القيود المتكررة</h2><button onclick="RW_Finance._goldNewRecurring()" class="bg-indigo-600 text-white px-4 py-2 rounded-xl font-bold">قالب جديد</button></div><div class="grid gap-3">';
        rows.forEach(function(t){ h += '<div class="border rounded-2xl p-4 flex justify-between items-center"><div><div class="font-black">'+esc(t.name)+'</div><div class="text-xs text-gray-500">'+esc(t.template_code)+' · '+esc(t.frequency)+' · التالي '+esc(t.next_run_date)+'</div></div><span class="px-3 py-1 rounded-full text-xs font-bold '+(t.active?'bg-green-50 text-green-700':'bg-gray-100 text-gray-500')+'">'+(t.active?'نشط':'موقوف')+'</span></div>'; });
        h += '</div>'; renderSimple('القيود المتكررة','fa-repeat',h);
    }

    return { journalList: journalList, renderAssets: renderAssets, renderTax: renderTax, renderPeriods: renderPeriods, renderBankReconcile: renderBankReconcile, renderRecurring: renderRecurring };
})();
```

ثم بعد الإضافة مباشرة ابحث عن:

```js
window.RW_Finance = RW_Finance;
```

واتركه كما هو ثم أضف بعده:

```js
RW_Finance._goldJournalList = RW_Finance_GoldExtension.journalList;
RW_Finance._renderJournalList = RW_Finance_GoldExtension.journalList;
RW_Finance._renderAssets = RW_Finance_GoldExtension.renderAssets;
RW_Finance._renderTax = RW_Finance_GoldExtension.renderTax;
RW_Finance._renderPeriods = RW_Finance_GoldExtension.renderPeriods;
RW_Finance._renderBankReconcile = RW_Finance_GoldExtension.renderBankReconcile;
RW_Finance._renderRecurringJournals = RW_Finance_GoldExtension.renderRecurring;
```

## 11. مهم جدًا — ما لم يتم اختراعه عمدًا

لم يتم الادعاء بأن Finance أصبح 100% مغلقًا في Mother بمجرد إنشاء الجداول.

Backend foundation تم رفعه فعليًا.

لكن الواجهة الأم لا يمكن للمساعد تعديلها مباشرة وفق عقد العمل الحالي؛ لذلك لا تعتبر Finance Mother UI مغلقة إلا بعد أن يقوم المالك بدمج الجراحات السابقة أعلاه ثم يجرى E2E authenticated.

## 12. ما يحتاج الإكمال في الدورة التالية

هذه هي النقاط التي لا يجوز نسيانها بعد دمج Mother:

1. تكامل tax transactions مع مسارات المبيعات والمشتريات الفعلية بدل الاقتصار على سجل يدوي.
2. إنشاء شاشة tax settlement تربط التقرير بقيد التسوية.
3. إنشاء lifecycle كامل للأصول: acquisition → depreciation → disposal/sale.
4. استكمال recurring execution وربطه بعملية جدولة/trigger موثقة.
5. استكمال bank statement import + line matching + reconciliation completion.
6. إنشاء cheque lifecycle حقيقي، لأن جدول `cheques` الحالي لا يحمل company_id ويحتاج دراسة isolation قبل UI.
7. إضافة export/print/source drill-down للتقارير المالية.
8. إضافة reverse/copy/view/audit actions للقيد من Mother.
9. إظهار Budgets في menu وربطها بتقرير variance وتفاصيل المراكز.
10. وضع policy واضحة للـperiod reopen، وعدم السماح بأي تعديل صامت لقيد مرحل.

## 13. E2E المطلوب بعد الدمج

لا يكفي فتح التبويب.

يجب اختبار:

`Finance menu → Journal List → open period → create journal → list journal → GL drilldown → receipt → allocation → payment → transfer → bank statement → match → tax report → asset → depreciation → budget → period readiness → close period`

ثم مطابقة كل نتيجة مع Production في نفس لحظة الاختبار.

## 14. Self Audit

### What was proved

- Source of Truth الحالي للـMother ما زال `erp-frontend/companies/company-1/main.html`.
- `forensic_main_assembly.yml` صحيح.
- Finance UI الحالية موجودة وليست فارغة، لكنها لا تغطي الدورة المالية التنافسية بالكامل.
- Production لديها عدد كبير من الأساسات المالية.
- فجوات ثابتة تم إثباتها في assets/tax/periods/recurring/bank reconciliation.
- تم إنشاء foundations لهذه الفجوات في Production.
- RLS للـfoundations الجديدة مفعل.

### What was not proved

- لا يوجد حتى الآن authenticated Browser E2E كامل لهذا الجزء.
- لم تُثبت بعد دورة tax end-to-end من Invoice إلى declaration إلى settlement.
- لم تُثبت بعد دورة bank reconciliation الكاملة بالملفات الواقعية.
- لم تُثبت بعد lifecycle للأصول من acquisition إلى sale/disposal.
- لم تُثبت بعد recurring journal execution في runtime.

### Final status

`FINANCE BACKEND FOUNDATION = IMPLEMENTED`

`FINANCE MOTHER UI = OWNER SURGERY REQUIRED`

`FINANCE E2E = OPEN`

`GLOBAL FINANCE GOLD/Diamond = NOT YET 100% CLOSED`

ولا ينبغي تحويل هذه الحالة إلى PASS حتى ينتهي الدمج واختبار E2E الحقيقي.

## 15. تعليمات بداية وتسلسل المساعد التالي

ابدأ دائمًا من:

1. Current Git HEAD.
2. Current parent commit.
3. Current `main.html` fingerprint.
4. Current Production schema.
5. Current deployed RPCs/Edge Functions.
6. Current browser/console/network.
7. ثم حدد closure unit واحدًا فقط.

لكل Closure Unit:

`UNDERSTAND → HISTORICAL CONTRACT → CURRENT SOURCE → CURRENT PRODUCTION → DATABASE → DEPLOYMENT → CONSUMERS → GAP → SURGICAL FIX → TEST → DEPLOY → PRODUCTION VERIFY → CLOSE`

لا تقرأ تقريرًا وتفترض أنه Current.

ولا تعالج defect في ملف تاريخي لأن النسخة الحالية قد تكون تغيرت بعده.

لا تعيد إصلاح ما ثبت أنه أصُلح.

ولا تعتبر وجود table/RPC دليلًا على اكتمال business contract.

ولا تعتبر Staging PASS أو SQL PASS مساويًا لـProduction E2E PASS.

---

### المراجع الخارجية المستخدمة كمقارنة

- Daftra Accounting Features: https://www.daftra.com/features/sub_feature/11
- Daftra Journal Reports: https://docs.daftra.com/en/tutorial/viewing-the-journals-report/
- Daftra Recurring Journals: https://docs.daftra.com/en/user_manual/automatic-and-manual-journal-entries/
- Daftra Tax Reports/Settlement: https://docs.daftra.com/tutorial/تسوية-الإقرار-الضريبي-وإنشاء-قيد-التس/
- Daftra Assets: https://www.daftra.com/إدارة-الأصول/
- Daftra Plans: https://www.daftra.com/plans
