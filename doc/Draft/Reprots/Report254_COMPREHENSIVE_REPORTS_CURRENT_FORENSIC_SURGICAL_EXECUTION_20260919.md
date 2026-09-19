
# RAWAEA ERP — Report 254
# تبويب التقارير الشاملة — CURRENT FORENSIC / SURGICAL EXECUTION
## 2026-09-19

## 1. النطاق
تبويب التقارير الشاملة فقط. لم يتم تعديل main.html في مستودع النظام الأم بواسطة CTO.

## 2. هرم الحقيقة
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

التقارير السابقة استُخدمت كأدلة تاريخية لا كحالة حالية.

## 3. الحالة المثبتة قبل التنفيذ
System Repository:
papamohammed77-glitch/rawaie-erp-New

HEAD:
682082358b555369e1e113cad755d69e14172e5e

Parent:
0b05af82690f74e0c2603415c2fee9139a0f8fb1

Mother Repository:
papamohammed77-glitch/erp-frontend

HEAD:
f45b5511fe3965d012c9f94e09f0dd2102c55140

Parent:
adeda04609723e221249e51621cc674b05dfc5ce

main.html blob:
94a30d3d7fda02967b6a1f3b112ea2ced6d77ac9

Current main.html:
1,500,659 bytes

Full inline script:
1,480,964 characters

Full inline V8 parser:
PASS

## 4. القراءة التاريخية
تم فتح والتحقق من Report238 وReport239 وReport240 وReport241 بالكامل.

النقاط المغلقة التي لم يُعاد فتحها:
- module-local _companyId
- parser repair
- _exportReportCsv
- script raw-text termination
- inventory turnover Production contract
- inventory movement Production rewire
- low stock Production rewire
- Finance GL/Tax contracts
- HR reporting contract
- 38 report IDs / implementations

لا يوجد Current Evidence يبرر إعادة هذه الإصلاحات.

## 5. Current Report Architecture
Current RW_Reports_Comprehensive:
- 38 report IDs
- 6 business domains الرئيسية
- direct table reads لبعض التقارير التشغيلية
- specialized Production RPCs للتقارير التحليلية الحساسة
- HR عبر hr_query

Current detail functions:
- _showCustomerLedgerDetail
- _showItemMovementDetail
- _showRunsheetDetail
- _showSettlementDetail

هذه الوظائف كانت تستخدم Swal.fire.

## 6. Forensic Finding — Production Reporting Authorization
قبل الجراحة كان:
inventory_movement_report:
authenticated EXECUTE = FALSE

inventory_replenishment_report:
authenticated EXECUTE = FALSE

بينما Mother يستدعيهما مباشرة من جلسة authenticated.

هذا كان عيب Runtime/Authorization حقيقي، وليس مجرد اختلاف شكلي.

كما أن الدوال كانت تعتمد على p_company_id وp_user_email المرسلين من caller دون ربط صريح كامل بهوية جلسة authenticated.

## 7. Production Surgical Repair — DONE
تم تطبيق Production migration:

20260919_comprehensive_reports_inventory_rpc_security_close

Canonical file:
supabase/migrations/20260919_comprehensive_reports_inventory_rpc_security_close.sql

النتيجة:
- authenticated EXECUTE = TRUE
- anon EXECUTE = FALSE
- PUBLIC EXECUTE = FALSE
- service_role = TRUE
- company context مربوط بـ app_private.current_user_company_id()
- reports permission إلزامي
- p_user_email يجب أن يطابق مستخدم الجلسة عند authenticated

## 8. Production Verification
Owner JWT:
auth.uid =
0a6089e6-0c33-4cf9-9aa0-31fc42774b89

owner company:
00000000-0000-0000-0000-000000000001

results:
- inventory_movement_report = success
- inventory_replenishment_report = success
- comprehensive_inventory_turnover_report = success
- trial balance = success
- P&L = success
- balance sheet = success
- cash flow = success
- GL activity = success
- period readiness = success
- reconciliation = success
- exception center = success
- customer aging = success
- supplier aging = success
- tax report = success
- tax settlements = success
- HR attendance = success
- HR payroll = success

Current transactional data is sparse; empty result sets are not classified as failures.

Unauthorized smoke:
picker@rawaea.com without reports permission
= REPORTS_PERMISSION_REQUIRED

## 9. Competitive Benchmark
Odoo 19:
global filters, graph/pivot reporting, drill-down, multi-page dashboard navigation, access to underlying records/views.

Microsoft Dynamics 365 Business Central:
analysis mode, filter pane, columns/row groups/values, multiple analysis views, saved views, export.

SAP:
Analytical List Page, KPI header, visual/page filters, contextual actions, drill-down and analytical/transactional navigation.

Daftra:
warehouse/product/type/category filters, opening stock, summary/detail, source/reference, stock after movement, CSV/Excel/PDF/Print.

Manager:
custom reports with filtering/order/grouping, transaction history, user/action filtering.

## 10. RAWAEA Competitive Interpretation
لا نريد تقليد الأنظمة المنافسة في Business Logic.

الـCenter الصحيح للروائع هو:
RW_Reports_Comprehensive
↓
Production Reporting Contracts
↓
Authoritative operational data

وليس:
UI calculations
↓
duplicate business logic

ولا:
one giant Production reporting function

## 11. Current UI Gap
الفجوة المثبتة داخل Current Source هي أن Drill-Down ما زال Modal.

ذلك يمنع تجربة Page-level analysis شبيهة بالنمط المثبت لدى الأنظمة التنافسية.

المعالجة الجراحية:
Modal → In-Page Drill-Down

مع الحفاظ على:
- نفس report IDs
- نفس public function names
- نفس data contracts
- نفس operational apps
- نفس accounting/inventory engines
- نفس export/print entry points

## 12. OWNER SURGICAL PATCH 01 — Modal → Page

ابحث داخل main.html عن:

// ==================== دوال التفاصيل (Drill-Down) ====================

ثم ابحث عن:

async function _showCustomerLedgerDetail(customerId, customerName) {

واحذف البلوك الكامل الذي يبدأ بهذا السطر وينتهي عند آخر قوس في:

async function _showSettlementDetail(settlementCode) {

ولا تحذف:

// ==================== توليد التقرير (مع Drill-Down) ===

استبدل البلوك كاملًا بالنص التالي:

~~~~javascript

function _renderReportDrilldownPage(title, subtitle, bodyHtml) {
    var resultDiv = byId('report-result');

    if (!resultDiv) {
        return;
    }

    safeHTML(
        resultDiv,
        '<div class="bg-white rounded-2xl border shadow-sm overflow-hidden">' +
        '<div class="px-5 py-4 bg-gradient-to-l from-slate-900 via-indigo-900 to-indigo-700 text-white">' +
        '<div class="flex flex-wrap items-center justify-between gap-3">' +
        '<div>' +
        '<div class="text-xs font-bold text-white/70 mb-1">التقارير الشاملة / Drill-Down</div>' +
        '<h3 class="text-xl md:text-2xl font-black">' +
        _esc(title || 'تفاصيل التقرير') +
        '</h3>' +
        '<div class="text-xs md:text-sm text-white/75 mt-1">' +
        _esc(subtitle || '') +
        '</div>' +
        '</div>' +
        '<button id="rw-report-drilldown-back" type="button" ' +
        'class="px-4 py-2 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 font-black text-sm transition">' +
        '<i class="fa-solid fa-arrow-right ml-1"></i>' +
        'عودة إلى التقرير' +
        '</button>' +
        '</div>' +
        '</div>' +
        '<div class="p-5 md:p-6">' +
        bodyHtml +
        '</div>' +
        '<div class="px-5 py-3 border-t bg-gray-50 flex flex-wrap items-center justify-between gap-2 text-xs text-gray-500">' +
        '<span>المصدر: Production / Current Report Contract</span>' +
        '<span>عرض التفاصيل: ' +
        _esc(new Date().toLocaleString('ar-EG')) +
        '</span>' +
        '</div>' +
        '</div>'
    );

    var backButton = byId('rw-report-drilldown-back');

    if (backButton) {
        backButton.onclick = function () {
            _generateReport(_currentSection, _currentReport);
        };
    }
}

function _reportMetricCard(label, value, icon, toneClass) {
    return (
        '<div class="border rounded-2xl p-4 bg-white shadow-sm">' +
        '<div class="flex items-center justify-between gap-3">' +
        '<div>' +
        '<div class="text-xs font-bold text-gray-500">' +
        _esc(label) +
        '</div>' +
        '<div class="text-xl font-black mt-1">' +
        _esc(String(value == null ? '' : value)) +
        '</div>' +
        '</div>' +
        '<div class="w-11 h-11 rounded-xl flex items-center justify-center ' +
        _esc(toneClass || 'bg-gray-100 text-gray-600') +
        '">' +
        '<i class="fa-solid ' +
        _esc(icon || 'fa-chart-column') +
        '"></i>' +
        '</div>' +
        '</div>' +
        '</div>'
    );
}

async function _showCustomerLedgerDetail(customerId, customerName) {
    _showLoader('جاري تحميل كشف حساب العميل...');

    try {
        var companyId = _companyId();

        var customerRes = await supabase
            .from('customers')
            .select('id, customer_code, name')
            .eq('id', customerId)
            .eq('company_id', companyId)
            .maybeSingle();

        if (customerRes.error) {
            throw customerRes.error;
        }

        if (!customerRes.data) {
            throw new Error('العميل غير موجود ضمن الشركة الحالية');
        }

        var customer = customerRes.data;

        var ledgerRes = await supabase
            .from('customer_ledger')
            .select('id, entry_date, description, debit, credit, balance, reference, due_date, user_email, created_at')
            .eq('customer_id', customer.id)
            .order('entry_date', { ascending: false })
            .order('created_at', { ascending: false })
            .order('id', { ascending: false });

        if (ledgerRes.error) {
            throw ledgerRes.error;
        }

        var data = ledgerRes.data || [];
        var debitTotal = 0;
        var creditTotal = 0;

        for (var i = 0; i < data.length; i++) {
            debitTotal += Number(data[i].debit) || 0;
            creditTotal += Number(data[i].credit) || 0;
        }

        var currentBalance =
            data.length > 0
                ? Number(data[0].balance) || 0
                : 0;

        _hideLoader();

        var rows = '';

        for (var j = 0; j < data.length; j++) {
            rows +=
                '<tr class="border-t hover:bg-gray-50">' +
                '<td class="p-3 whitespace-nowrap">' + _esc(data[j].entry_date) + '</td>' +
                '<td class="p-3">' + _esc(data[j].description || '') + '</td>' +
                '<td class="p-3 text-center">' + _esc(data[j].reference || '') + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(data[j].debit) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(data[j].credit) + '</td>' +
                '<td class="p-3 text-center font-black">' + _fmtNum(data[j].balance) + '</td>' +
                '<td class="p-3 text-center text-xs text-gray-500">' + _esc(data[j].user_email || '') + '</td>' +
                '</tr>';
        }

        if (!rows) {
            rows =
                '<tr><td colspan="7" class="p-8 text-center text-gray-400">' +
                'لا توجد حركات لهذا العميل' +
                '</td></tr>';
        }

        var bodyHtml =
            '<div class="mb-5">' +
            '<div class="text-sm font-bold text-gray-500">العميل</div>' +
            '<div class="text-2xl font-black mt-1">' +
            _esc(customer.name || customerName || customer.customer_code) +
            '</div>' +
            '<div class="text-xs text-gray-500 mt-1">كود العميل: ' +
            _esc(customer.customer_code) +
            '</div>' +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mb-6">' +
            _reportMetricCard('عدد الحركات', _fmtNum(data.length), 'fa-list', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('إجمالي المدين', _fmtNum(debitTotal), 'fa-arrow-up', 'bg-red-50 text-red-700') +
            _reportMetricCard('إجمالي الدائن', _fmtNum(creditTotal), 'fa-arrow-down', 'bg-emerald-50 text-emerald-700') +
            _reportMetricCard('الرصيد الحالي', _fmtNum(currentBalance), 'fa-scale-balanced', 'bg-indigo-50 text-indigo-700') +
            '</div>' +

            '<div class="border rounded-2xl overflow-hidden">' +
            '<div class="px-4 py-3 bg-gray-50 border-b flex flex-wrap items-center justify-between gap-2">' +
            '<div class="font-black">الحركات المحاسبية</div>' +
            '<div class="text-xs text-gray-500">ترتيب تنازلي حسب التاريخ</div>' +
            '</div>' +
            '<div class="overflow-x-auto">' +
            '<table class="w-full min-w-[900px] text-sm">' +
            '<thead><tr class="bg-gray-100 text-gray-700">' +
            '<th class="p-3 text-right">التاريخ</th>' +
            '<th class="p-3 text-right">البيان</th>' +
            '<th class="p-3 text-center">المرجع</th>' +
            '<th class="p-3 text-center">مدين</th>' +
            '<th class="p-3 text-center">دائن</th>' +
            '<th class="p-3 text-center">الرصيد</th>' +
            '<th class="p-3 text-center">المستخدم</th>' +
            '</tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
            '</table></div></div>';

        _renderReportDrilldownPage(
            'كشف حساب العميل',
            customer.name || customerName || customer.customer_code,
            bodyHtml
        );

    } catch (e) {
        _hideLoader();
        _showToast('فشل تحميل كشف الحساب: ' + (e.message || ''), 'error');
    }
}

async function _showItemMovementDetail(itemCode, itemName) {
    _showLoader('جاري تحميل حركة الصنف...');

    try {
        var companyId = _companyId();

        var itemRes = await supabase
            .from('items')
            .select('id, item_code, name, unit')
            .eq('item_code', itemCode)
            .eq('company_id', companyId)
            .maybeSingle();

        if (itemRes.error) {
            throw itemRes.error;
        }

        if (!itemRes.data) {
            throw new Error('الصنف غير موجود ضمن الشركة الحالية');
        }

        var item = itemRes.data;
        var fromInput = byId('rp-date-from');
        var toInput = byId('rp-date-to');

        var fromDate =
            fromInput && fromInput.value
                ? fromInput.value
                : null;

        var toDate =
            toInput && toInput.value
                ? toInput.value
                : null;

        var currentUserEmail =
            RW_STATE &&
            RW_STATE.app &&
            RW_STATE.app.currentUser
                ? RW_STATE.app.currentUser.email
                : null;

        var movementResult =
            await supabase.rpc(
                'inventory_movement_report',
                {
                    p_company_id: companyId,
                    p_user_email: currentUserEmail,
                    p_from_date: fromDate,
                    p_to_date: toDate,
                    p_branch_id: null,
                    p_item_id: item.id,
                    p_movement_type: null,
                    p_query: null,
                    p_limit: 1000,
                    p_offset: 0
                }
            );

        if (movementResult.error) {
            throw movementResult.error;
        }

        var payload = movementResult.data || {};
        var data =
            Array.isArray(payload.rows)
                ? payload.rows
                : [];

        var stockRes = await supabase
            .from('stock_branches')
            .select('branch_id, qty, allocated_qty')
            .eq('item_id', item.id);

        if (stockRes.error) {
            throw stockRes.error;
        }

        var stockRows = stockRes.data || [];
        var currentQty = 0;
        var allocatedQty = 0;
        var netMovement = 0;

        for (var s = 0; s < stockRows.length; s++) {
            currentQty += Number(stockRows[s].qty) || 0;
            allocatedQty += Number(stockRows[s].allocated_qty) || 0;
        }

        for (var m = 0; m < data.length; m++) {
            netMovement += Number(data[m].effect_qty) || 0;
        }

        var availableQty =
            Math.max(currentQty - allocatedQty, 0);

        _hideLoader();

        var rows = '';

        for (var i = 0; i < data.length; i++) {
            rows +=
                '<tr class="border-t hover:bg-gray-50">' +
                '<td class="p-3 whitespace-nowrap">' + _esc(data[i].movement_date || '') + '</td>' +
                '<td class="p-3">' + _esc(data[i].branch_name || '') + '</td>' +
                '<td class="p-3">' + _esc(data[i].movement_type || '') + '</td>' +
                '<td class="p-3">' + _esc(data[i].reference || data[i].voucher_id || '') + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(data[i].before_qty) + '</td>' +
                '<td class="p-3 text-center font-bold">' + _fmtNum(data[i].effect_qty) + '</td>' +
                '<td class="p-3 text-center font-black">' + _fmtNum(data[i].after_qty) + '</td>' +
                '<td class="p-3 text-center text-xs text-gray-500">' + _esc(data[i].user_email || '') + '</td>' +
                '</tr>';
        }

        if (!rows) {
            rows =
                '<tr><td colspan="8" class="p-8 text-center text-gray-400">' +
                'لا توجد حركات ضمن نطاق التاريخ الحالي' +
                '</td></tr>';
        }

        var periodText =
            (fromDate || 'بداية السجل') +
            ' → ' +
            (toDate || 'اليوم');

        var bodyHtml =
            '<div class="mb-5">' +
            '<div class="text-sm font-bold text-gray-500">الصنف</div>' +
            '<div class="text-2xl font-black mt-1">' +
            _esc(item.name || itemName || item.item_code) +
            '</div>' +
            '<div class="text-xs text-gray-500 mt-1">الكود: ' +
            _esc(item.item_code) +
            ' | الوحدة: ' +
            _esc(item.unit || '') +
            '</div>' +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-3 mb-6">' +
            _reportMetricCard('الرصيد الحالي', _fmtNum(currentQty), 'fa-boxes-stacked', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('المحجوز', _fmtNum(allocatedQty), 'fa-lock', 'bg-amber-50 text-amber-700') +
            _reportMetricCard('المتاح', _fmtNum(availableQty), 'fa-box-open', 'bg-emerald-50 text-emerald-700') +
            _reportMetricCard('صافي الحركة', _fmtNum(netMovement), 'fa-arrow-right-arrow-left', 'bg-indigo-50 text-indigo-700') +
            _reportMetricCard('عدد الحركات', _fmtNum(data.length), 'fa-list', 'bg-purple-50 text-purple-700') +
            '</div>' +

            '<div class="mb-4 text-xs text-gray-500">' +
            'النطاق: ' + _esc(periodText) +
            ' | المصدر: Production inventory_movement_report' +
            '</div>' +

            '<div class="border rounded-2xl overflow-hidden">' +
            '<div class="px-4 py-3 bg-gray-50 border-b font-black">سجل الحركة التفصيلي</div>' +
            '<div class="overflow-x-auto">' +
            '<table class="w-full min-w-[1050px] text-sm">' +
            '<thead><tr class="bg-gray-100 text-gray-700">' +
            '<th class="p-3 text-right">التاريخ</th>' +
            '<th class="p-3 text-right">الفرع</th>' +
            '<th class="p-3 text-right">نوع الحركة</th>' +
            '<th class="p-3 text-right">المرجع</th>' +
            '<th class="p-3 text-center">قبل الحركة</th>' +
            '<th class="p-3 text-center">التأثير</th>' +
            '<th class="p-3 text-center">بعد الحركة</th>' +
            '<th class="p-3 text-center">المستخدم</th>' +
            '</tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
            '</table></div></div>';

        _renderReportDrilldownPage(
            'حركة الصنف',
            item.name || itemName || item.item_code,
            bodyHtml
        );

    } catch (e) {
        _hideLoader();
        _showToast('فشل تحميل حركة الصنف: ' + (e.message || ''), 'error');
    }
}

async function _showRunsheetDetail(runsheetCode) {
    _showLoader('جاري تحميل تفاصيل الرانشيت...');

    try {
        var companyId = _companyId();

        var rsRes = await supabase
            .from('runsheets')
            .select('id, runsheet_code, run_date, status, driver_id, vehicle_id, total_amount')
            .eq('company_id', companyId)
            .eq('runsheet_code', runsheetCode)
            .maybeSingle();

        if (rsRes.error) {
            throw rsRes.error;
        }

        if (!rsRes.data) {
            throw new Error('الرانشيت غير موجود ضمن الشركة الحالية');
        }

        var rs = rsRes.data;

        var [itemsRes, ordersRes] =
            await Promise.all([
                supabase
                    .from('run_sheet_details')
                    .select('*')
                    .eq('runsheet_id', rs.id),

                supabase
                    .from('orders')
                    .select('order_code, customer_name, total_amount')
                    .eq('company_id', companyId)
                    .eq('runsheet_id', rs.id)
                    .order('order_code', { ascending: true })
            ]);

        if (itemsRes.error) {
            throw itemsRes.error;
        }

        if (ordersRes.error) {
            throw ordersRes.error;
        }

        var items = itemsRes.data || [];
        var orders = ordersRes.data || [];

        var orderedTotal = 0;
        var pickedTotal = 0;
        var loadedTotal = 0;
        var deliveredTotal = 0;
        var refusedTotal = 0;
        var returnedTotal = 0;

        for (var i = 0; i < items.length; i++) {
            orderedTotal += Number(items[i].qty_ordered) || 0;
            pickedTotal += Number(items[i].qty_picked) || 0;
            loadedTotal += Number(items[i].qty_loaded) || 0;
            deliveredTotal += Number(items[i].qty_delivered) || 0;
            refusedTotal += Number(items[i].qty_refused) || 0;
            returnedTotal += Number(items[i].qty_returned) || 0;
        }

        _hideLoader();

        var orderPills = '';

        for (var o = 0; o < orders.length; o++) {
            orderPills +=
                '<div class="border rounded-xl px-3 py-2 bg-blue-50">' +
                '<div class="font-black text-blue-800">' +
                _esc(orders[o].order_code || '') +
                '</div>' +
                '<div class="text-xs text-blue-700 mt-1">' +
                _esc(orders[o].customer_name || '') +
                ' — ' +
                _fmtNum(orders[o].total_amount) +
                '</div>' +
                '</div>';
        }

        if (!orderPills) {
            orderPills =
                '<div class="text-sm text-gray-400">لا توجد طلبات مرتبطة حاليًا</div>';
        }

        var rows = '';

        for (var r = 0; r < items.length; r++) {
            rows +=
                '<tr class="border-t hover:bg-gray-50">' +
                '<td class="p-3 font-semibold">' + _esc(items[r].item_name || '') + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_ordered) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_picked) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_loaded) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_delivered) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_refused) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_returned) + '</td>' +
                '</tr>';
        }

        if (!rows) {
            rows =
                '<tr><td colspan="7" class="p-8 text-center text-gray-400">' +
                'لا توجد تفاصيل أصناف للرانشيت' +
                '</td></tr>';
        }

        var bodyHtml =
            '<div class="mb-5">' +
            '<div class="text-sm font-bold text-gray-500">رانشيت ميداني</div>' +
            '<div class="text-2xl font-black mt-1">' +
            _esc(rs.runsheet_code) +
            '</div>' +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mb-6">' +
            _reportMetricCard('التاريخ', rs.run_date || '', 'fa-calendar-day', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('الحالة', rs.status || '', 'fa-route', 'bg-indigo-50 text-indigo-700') +
            _reportMetricCard('السائق', rs.driver_id || 'غير محدد', 'fa-user', 'bg-emerald-50 text-emerald-700') +
            _reportMetricCard('السيارة', rs.vehicle_id || 'غير محددة', 'fa-truck', 'bg-amber-50 text-amber-700') +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-6 gap-3 mb-6">' +
            _reportMetricCard('Ordered', _fmtNum(orderedTotal), 'fa-list-check', 'bg-slate-50 text-slate-700') +
            _reportMetricCard('Picked', _fmtNum(pickedTotal), 'fa-box', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('Loaded', _fmtNum(loadedTotal), 'fa-truck-ramp-box', 'bg-indigo-50 text-indigo-700') +
            _reportMetricCard('Delivered', _fmtNum(deliveredTotal), 'fa-circle-check', 'bg-emerald-50 text-emerald-700') +
            _reportMetricCard('Refused', _fmtNum(refusedTotal), 'fa-circle-xmark', 'bg-red-50 text-red-700') +
            _reportMetricCard('Returned', _fmtNum(returnedTotal), 'fa-rotate-left', 'bg-amber-50 text-amber-700') +
            '</div>' +

            '<div class="mb-6">' +
            '<div class="font-black mb-3">الأوردرات المرتبطة</div>' +
            '<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">' +
            orderPills +
            '</div></div>' +

            '<div class="border rounded-2xl overflow-hidden">' +
            '<div class="px-4 py-3 bg-gray-50 border-b font-black">تفاصيل التنفيذ حسب الصنف</div>' +
            '<div class="overflow-x-auto">' +
            '<table class="w-full min-w-[1050px] text-sm">' +
            '<thead><tr class="bg-gray-100 text-gray-700">' +
            '<th class="p-3 text-right">الصنف</th>' +
            '<th class="p-3 text-center">Ordered</th>' +
            '<th class="p-3 text-center">Picked</th>' +
            '<th class="p-3 text-center">Loaded</th>' +
            '<th class="p-3 text-center">Delivered</th>' +
            '<th class="p-3 text-center">Refused</th>' +
            '<th class="p-3 text-center">Returned</th>' +
            '</tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
            '</table></div></div>';

        _renderReportDrilldownPage(
            'تفاصيل الرانشيت',
            rs.runsheet_code,
            bodyHtml
        );

    } catch (e) {
        _hideLoader();
        _showToast('فشل تحميل تفاصيل الرانشيت: ' + (e.message || ''), 'error');
    }
}

async function _showSettlementDetail(settlementCode) {
    _showLoader('جاري تحميل تفاصيل التسوية...');

    try {
        var companyId = _companyId();

        var settlementRes = await supabase
            .from('daily_settlements')
            .select('*')
            .eq('company_id', companyId)
            .eq('settlement_code', settlementCode)
            .maybeSingle();

        if (settlementRes.error) {
            throw settlementRes.error;
        }

        if (!settlementRes.data) {
            throw new Error('التسوية غير موجودة ضمن الشركة الحالية');
        }

        var data = settlementRes.data;
        var runsheetCode = '';

        if (data.runsheet_id) {
            var rsRes = await supabase
                .from('runsheets')
                .select('id, runsheet_code')
                .eq('company_id', companyId)
                .eq('id', data.runsheet_id)
                .maybeSingle();

            if (rsRes.error) {
                throw rsRes.error;
            }

            if (rsRes.data) {
                runsheetCode = rsRes.data.runsheet_code || '';
            }
        }

        _hideLoader();

        var bodyHtml =
            '<div class="mb-5">' +
            '<div class="text-sm font-bold text-gray-500">التسوية اليومية</div>' +
            '<div class="text-2xl font-black mt-1">' +
            _esc(data.settlement_code) +
            '</div>' +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mb-6">' +
            _reportMetricCard('التاريخ', data.settlement_date || '', 'fa-calendar-day', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('الرانشيت', runsheetCode || data.runsheet_id || 'غير محدد', 'fa-route', 'bg-indigo-50 text-indigo-700') +
            _reportMetricCard('كمية العجز', _fmtNum(data.total_shortage), 'fa-box-open', 'bg-red-50 text-red-700') +
            _reportMetricCard('قيمة العجز', _fmtNum(data.total_shortage_value) + ' EGP', 'fa-money-bill-transfer', 'bg-amber-50 text-amber-700') +
            '</div>' +

            '<div class="border rounded-2xl p-5 bg-gray-50">' +
            '<div class="font-black mb-2">ملاحظات التسوية</div>' +
            '<div class="text-sm text-gray-700 whitespace-pre-wrap">' +
            _esc(data.notes || 'لا توجد ملاحظات') +
            '</div>' +
            '</div>';

        _renderReportDrilldownPage(
            'تفاصيل التسوية',
            data.settlement_code,
            bodyHtml
        );

    } catch (e) {
        _hideLoader();
        _showToast('فشل تحميل تفاصيل التسوية: ' + (e.message || ''), 'error');
    }
}

~~~~

## 13. PATCH 01 Rules
- لا تستخدم Swal.fire داخل وظائف التفاصيل.
- لا تغير أسماء الوظائف الأربع.
- لا تغير _generateReport.
- لا تغير report IDs.
- لا تغير operational apps.
- لا تغير order_details.
- لا تغير run_sheet_details.
- Item movement detail يجب أن يقرأ Production inventory_movement_report.
- Back يعيد التقرير الحالي.
- التقرير والـdrilldown يبقيان في نفس workspace.
- CSV/Print الحاليان سيعملان على الصفحة المعروضة لأن التفاصيل أصبحت داخل report-result.

## 14. OWNER SURGICAL PATCH 02 — Hover
ابحث في function _openSection عن هذا السطر الحالي:

~~~~javascript
html += '<div class="border rounded-xl p-4 hover:bg-' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\'' + sectionKey + '\', \'' + rep.id + '\')">';
~~~~

احذفه واستبدله بـ:

~~~~javascript
html += '<div class="border rounded-xl p-4 hover:' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\'' + sectionKey + '\', \'' + rep.id + '\')">';
~~~~

النتيجة تمنع تكوين:
hover:bg-bg-...
وتنتج class صحيحة:
hover:bg-...

## 15. ما لم يتغير
لا إعادة فتح:
- _companyId
- _generateReport
- _exportReportCsv
- _printReport
- HR blocks
- Inventory Turnover
- Finance reporting
- operational field workflows

## 16. حماية رحلة التشغيل
التقارير لا تعيد تنفيذ:
Order → order_details → Runsheet → run_sheet_details → Picking → Reservation → Loading → Delivery → Return → Settlement

التقارير تقرأ وتحقق وتكشف.

## 17. E2E State
Verified:
- Git HEAD/parent
- Mother HEAD/parent/blob
- current source
- V8 parse
- 38 reports
- Production report contracts
- Owner authenticated inventory report smoke
- unauthorized rejection smoke
- Production inventory report security repair

Still OPEN:
- Owner cutover
- Browser Production E2E
- 38-report click-through
- drilldown/back browser test
- CSV/Print browser test
- post-cutover Production re-snapshot

لا يجوز إعلان Browser PASS من SQL PASS.

## 18. Current Production Data Reality
Current Production:
- one company
- two branches
- 17 items
- 20 stock rows
- 3 inventory logs
- zero orders
- zero runsheets
- zero purchase orders
- zero stock vouchers
- zero customer ledger rows
- zero supplier ledger rows
- zero settlement rows
- two journal entries
- zero journal lines

لا تُنشأ Fixtures دائمة فقط للحصول على Test PASS.

## 19. FINAL SELF-AUDIT

### What I Proved
- Current Git and parent verified.
- Mother Git and parent verified.
- Current main.html verified.
- Full inline parser PASS.
- Current 38 report structure verified.
- Production reporting contracts verified.
- Inventory reporting auth gap proven.
- Production security repair deployed.
- Owner report smoke PASS.
- Unauthorized report execution rejected.
- Exact Modal → Page replacement parsed successfully in isolation.

### What I Did Not Prove
- Live browser after Owner cutover.
- 38-report full click-through.
- Live CSV/Print/Back browser path.
- Served production artifact after final Mother commit.

### What Could Still Be Wrong
- Owner may paste a different block than the exact replacement.
- Served artifact may lag Mother HEAD.
- An unrelated browser-only defect may appear after cutover.

## 20. Final Closure State

~~~~text
CURRENT GIT = VERIFIED
CURRENT SOURCE = VERIFIED
CURRENT PRODUCTION = VERIFIED
CURRENT DATABASE = VERIFIED
PRODUCTION INVENTORY REPORT SECURITY = CLOSED
DRILLDOWN SOURCE PATCH = OWNER READY
MAIN.HTML CTO EDIT = 0
BROWSER PRODUCTION E2E = OPEN
38 REPORT LIVE SMOKE = OPEN
FULL COMPREHENSIVE TAB = OPEN UNTIL OWNER CUTOVER + BROWSER EVIDENCE
~~~~

## 21. Session Continuity
المساعد التالي يبدأ من:
1. CURRENT_STATE
2. System HEAD + parent
3. Mother HEAD + parent + main.html blob
4. Current source recheck
5. Production report contracts
6. Exact owner patches in Report254
7. V8 parser
8. Browser E2E
9. 38-report smoke
10. Production resnapshot

لا تبدأ من Report241 كأنه Current.
لا تعيد إصلاح ما ثبت إغلاقه دون Current Evidence جديد.

# END OF REPORT
