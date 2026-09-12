/* RAWAEA ERP — Main9 Owner Surgical Replacement Package — 2026-09-12
 * Source of Truth: Current/PWA/main2/main9.md
 * Current source SHA at review: b9f10ae4e727cb9495aaecbe2d752dabf13ec776
 * Owner applies this file section-by-section. Assistant does not edit main9.md.
 * Gold/Diamond mission: there is severe incompleteness across tabs; target is functional completion, not cosmetic screens.
 */

var MAIN9_OWNER_SURGICAL_REPLACEMENTS_20260912 = {

O1_FINANCE_REPORT_STRUCTURE: String.raw`
ابحث عن الكتلة التي تبدأ بالسطر:
        'finance': {
وتنتهي مباشرة قبل:
        'crm': {

احذف الكتلة الحالية كاملة واستبدلها بالكتلة التالية كاملة:

        'finance': {
            title: 'تقارير الحسابات والمالية',
            icon: 'fa-coins',
            color: 'text-purple-600',
            bgColor: 'bg-purple-50',
            reports: [
                { id: 'finance-trial-balance', label: 'ميزان المراجعة', desc: 'أرصدة جميع الحسابات', params: ['date'] },
                { id: 'finance-profit-loss', label: 'قائمة الدخل', desc: 'الإيرادات والمصروفات وصافي الربح', params: ['date'] },
                { id: 'finance-balance-sheet', label: 'الميزانية العمومية', desc: 'الأصول والخصوم وحقوق الملكية', params: ['date'] },
                { id: 'finance-cash-flow', label: 'قائمة التدفقات النقدية', desc: 'حركة النقد الداخلة والخارجة', params: ['date'] },
                { id: 'finance-general-ledger', label: 'دفتر الأستاذ العام', desc: 'حركات أي حساب', params: ['account', 'date'] },
                { id: 'finance-treasury', label: 'كشف حساب بنكي/خزينة', desc: 'رصيد وحركات الخزينة', params: ['treasury', 'date'] },
                { id: 'finance-customer-aging', label: 'أعمار ديون العملاء', desc: 'أرصدة العملاء حسب شرائح الاستحقاق', params: ['date'] },
                { id: 'finance-supplier-aging', label: 'أعمار ديون الموردين', desc: 'أرصدة الموردين حسب شرائح الاستحقاق', params: ['date'] },
                { id: 'finance-gl-activity', label: 'حركة حساب الأستاذ', desc: 'الحركات والرصيد الجاري لحساب محدد', params: ['account', 'date'] },
                { id: 'finance-period-readiness', label: 'جاهزية إغلاق الفترة', desc: 'فحوص القيود والعمليات والمخزون قبل الإقفال', params: ['date'] },
                { id: 'finance-reconciliation', label: 'مطابقة الحسابات', desc: 'مطابقة النقد والعملاء والموردين وميزان القيود', params: ['date'] },
                { id: 'finance-exceptions', label: 'مركز الاستثناءات', desc: 'العمليات الفاشلة والقيود غير المتزنة ومشكلات المخزون والذمم', params: ['date'] },
                { id: 'finance-tax', label: 'تقرير الضرائب', desc: 'ضريبة القيمة المضافة — لا يفعّل دون مصدر Production سلطوي', params: ['date'] }
            ]
        },
`,

O2_FINANCE_RUNTIME_TAIL: String.raw`
ابحث في _generateReport عن الكتلة التي تبدأ:
        else if (reportId === 'finance-tax') {
وتنتهي مباشرة قبل تعليق CRM.
احذف الكتلة كاملة واستبدلها بهذه الكتلة كاملة:

        else if (reportId === 'finance-customer-aging') {
            var rAgingCustomers = await supabase.rpc('accountant_customer_aging', { p_as_of_date: toDate });
            if (rAgingCustomers.error) throw rAgingCustomers.error;
            var rowsAgingCustomers = (rAgingCustomers.data || []).map(function(row) {
                return '<tr class="border-t"><td class="p-2">' + _esc(row.customer_code) + '</td><td class="p-2 font-semibold">' + _esc(row.customer_name) + '</td><td class="p-2 text-center">' + _fmtNum(row.current_amount) + '</td><td class="p-2 text-center">' + _fmtNum(row.days_1_30) + '</td><td class="p-2 text-center">' + _fmtNum(row.days_31_60) + '</td><td class="p-2 text-center">' + _fmtNum(row.days_61_90) + '</td><td class="p-2 text-center">' + _fmtNum(row.over_90) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(row.net_balance) + '</td></tr>';
            });
            html = '<h4 class="font-bold mb-3">أعمار ديون العملاء حتى ' + _esc(toDate) + '</h4>' + _table(['كود العميل','اسم العميل','حالي','1–30','31–60','61–90','أكثر من 90','الصافي'], rowsAgingCustomers);
        }

        else if (reportId === 'finance-supplier-aging') {
            var rAgingSuppliers = await supabase.rpc('accountant_supplier_aging', { p_as_of_date: toDate });
            if (rAgingSuppliers.error) throw rAgingSuppliers.error;
            var rowsAgingSuppliers = (rAgingSuppliers.data || []).map(function(row) {
                return '<tr class="border-t"><td class="p-2">' + _esc(row.supplier_code) + '</td><td class="p-2 font-semibold">' + _esc(row.supplier_name) + '</td><td class="p-2 text-center">' + _fmtNum(row.current_amount) + '</td><td class="p-2 text-center">' + _fmtNum(row.days_1_30) + '</td><td class="p-2 text-center">' + _fmtNum(row.days_31_60) + '</td><td class="p-2 text-center">' + _fmtNum(row.days_61_90) + '</td><td class="p-2 text-center">' + _fmtNum(row.over_90) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(row.net_balance) + '</td></tr>';
            });
            html = '<h4 class="font-bold mb-3">أعمار ديون الموردين حتى ' + _esc(toDate) + '</h4>' + _table(['كود المورد','اسم المورد','حالي','1–30','31–60','61–90','أكثر من 90','الصافي'], rowsAgingSuppliers);
        }

        else if (reportId === 'finance-gl-activity') {
            if (!account) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار حساب</div>'); return; }
            var glAccount = await _validateAccount(account);
            var rGL = await supabase.rpc('accountant_gl_account_activity', { p_account_id: glAccount.id, p_from_date: fromDate, p_to_date: toDate });
            if (rGL.error) throw rGL.error;
            var glRows = (rGL.data || []).map(function(row) {
                return '<tr class="border-t"><td class="p-2">' + _esc(row.entry_date) + '</td><td class="p-2">' + _esc(row.entry_code) + '</td><td class="p-2">' + _esc(row.reference || '') + '</td><td class="p-2">' + _esc(row.description || '') + '</td><td class="p-2 text-center">' + _fmtNum(row.debit) + '</td><td class="p-2 text-center">' + _fmtNum(row.credit) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(row.running_balance) + '</td></tr>';
            });
            html = '<h4 class="font-bold mb-3">حركة الحساب: ' + _esc(glAccount.account_name) + ' (' + _esc(glAccount.account_code) + ')</h4>' + _table(['التاريخ','رقم القيد','المرجع','البيان','مدين','دائن','الرصيد الجاري'], glRows);
        }

        else if (reportId === 'finance-period-readiness') {
            var rReadiness = await supabase.rpc('accountant_period_readiness', { p_from_date: fromDate, p_to_date: toDate });
            if (rReadiness.error) throw rReadiness.error;
            var readinessRows = (rReadiness.data || []).map(function(row) {
                var cls = row.status === 'PASS' ? 'text-green-700' : (row.status === 'FAIL' ? 'text-red-700' : 'text-amber-700');
                return '<tr class="border-t"><td class="p-2 font-bold">' + _esc(row.gate_code) + '</td><td class="p-2 ' + cls + '">' + _esc(row.status) + '</td><td class="p-2 text-center">' + _fmtNum(row.metric) + '</td><td class="p-2">' + _esc(row.detail) + '</td></tr>';
            });
            html = '<h4 class="font-bold mb-3">جاهزية إغلاق الفترة</h4>' + _table(['البوابة','الحالة','المؤشر','التفصيل'], readinessRows);
        }

        else if (reportId === 'finance-reconciliation') {
            var rRecon = await supabase.rpc('accountant_reconciliation_summary', { p_as_of_date: toDate });
            if (rRecon.error) throw rRecon.error;
            var reconRows = (rRecon.data || []).map(function(row) {
                var cls = row.status === 'OK' ? 'text-green-700' : 'text-red-700';
                return '<tr class="border-t"><td class="p-2 font-bold">' + _esc(row.check_code) + '</td><td class="p-2 ' + cls + '">' + _esc(row.status) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(row.difference) + '</td><td class="p-2">' + _esc(row.detail) + '</td></tr>';
            });
            html = '<h4 class="font-bold mb-3">مطابقة الحسابات حتى ' + _esc(toDate) + '</h4>' + _table(['الفحص','الحالة','الفرق','التفصيل'], reconRows);
        }

        else if (reportId === 'finance-exceptions') {
            var rExceptions = await supabase.rpc('accountant_exception_center', { p_as_of_date: toDate });
            if (rExceptions.error) throw rExceptions.error;
            var exceptionRows = (rExceptions.data || []).map(function(row) {
                var cls = row.severity === 'HIGH' ? 'text-red-700' : (row.severity === 'MEDIUM' ? 'text-amber-700' : 'text-gray-700');
                return '<tr class="border-t"><td class="p-2">' + _esc(row.exception_type) + '</td><td class="p-2 font-bold ' + cls + '">' + _esc(row.severity) + '</td><td class="p-2">' + _esc(row.record_key) + '</td><td class="p-2">' + _esc(row.description) + '</td><td class="p-2 text-center">' + _fmtNum(row.amount) + '</td><td class="p-2">' + _esc(row.detected_at) + '</td></tr>';
            });
            html = '<h4 class="font-bold mb-3">مركز الاستثناءات حتى ' + _esc(toDate) + '</h4>' + _table(['النوع','الخطورة','السجل','الوصف','المبلغ','وقت الاكتشاف'], exceptionRows);
        }

        else if (reportId === 'finance-tax') {
            html = '<div class="text-center py-4 text-amber-700 bg-amber-50 border border-amber-200 rounded-xl">Capability Gate: مصدر Production سلطوي للضريبة غير مثبت، لذلك لم يتم اختلاق التقرير.</div>';
        }
`,

O3_CRM_FOLLOWUPS: String.raw`
ابحث في _generateReport عن:
        else if (reportId === 'crm-customer-followups') {
وآخر سطر في الكتلة الحالية:
                '</div>';
        }

احذف الكتلة كاملة واستبدلها بالكتلة الكاملة التالية:

        else if (reportId === 'crm-customer-followups') {
            var followupRes = await supabase
                .from('customer_followups')
                .select('id, customer_id, followup_date, followup_type, subject, notes, assigned_to, status, created_by, created_at, completed_at')
                .eq('company_id', companyId)
                .order('followup_date', { ascending: false })
                .order('created_at', { ascending: false });
            if (followupRes.error) throw followupRes.error;

            var followups = followupRes.data || [];
            var followupCustomers = await supabase.from('customers').select('id, customer_code, name').eq('company_id', companyId);
            if (followupCustomers.error) throw followupCustomers.error;

            var followupCustomerMap = {};
            (followupCustomers.data || []).forEach(function(c) {
                followupCustomerMap[String(c.id)] = c;
                followupCustomerMap[String(c.customer_code)] = c;
            });

            if (customer) {
                var selectedCustomer = await _validateCustomer(customer);
                followups = followups.filter(function(row) {
                    var c = followupCustomerMap[String(row.customer_id)];
                    return c && c.id === selectedCustomer.id;
                });
            }

            var followupRows = followups.map(function(row) {
                var c = followupCustomerMap[String(row.customer_id)] || null;
                return '<tr class="border-t">' +
                    '<td class="p-2">' + _esc(row.followup_date || '') + '</td>' +
                    '<td class="p-2">' + _esc(c ? c.customer_code : row.customer_id) + '</td>' +
                    '<td class="p-2 font-semibold">' + _esc(c ? c.name : '') + '</td>' +
                    '<td class="p-2">' + _esc(row.followup_type || '') + '</td>' +
                    '<td class="p-2">' + _esc(row.subject || '') + '</td>' +
                    '<td class="p-2">' + _esc(row.assigned_to || '') + '</td>' +
                    '<td class="p-2">' + _esc(row.status || '') + '</td>' +
                    '<td class="p-2 text-xs">' + _esc(row.created_by || '') + '</td>' +
                    '</tr>';
            });

            html = '<h4 class="font-bold mb-3">سجل متابعات العملاء</h4>' +
                _table(['التاريخ','كود العميل','اسم العميل','النوع','الموضوع','المسؤول','الحالة','أنشأ بواسطة'], followupRows);
        }
`,

O4_RUNSHEET_PERFORMANCE: String.raw`
ابحث في _generateReport عن الكتلة الحالية التي تبدأ:
        else if (reportId === 'sales-runsheet-performance') {
وتنتهي مباشرة قبل تعليق INVENTORY.
احذفها كاملة واستبدلها بالكتلة التالية كاملة:

        else if (reportId === 'sales-runsheet-performance') {
            var rsRes = await supabase.from('runsheets')
                .select('id, runsheet_code, run_date, total_amount, status, driver_id, vehicle_id')
                .eq('company_id', companyId)
                .gte('run_date', fromDate)
                .lte('run_date', toDate)
                .order('run_date', { ascending: false })
                .order('runsheet_code', { ascending: true });
            if (rsRes.error) throw rsRes.error;

            var runsheetRowsData = rsRes.data || [];
            var rsIds = runsheetRowsData.map(function(r) { return r.id; }).filter(Boolean);
            var rsOrders = [];
            if (rsIds.length) {
                var rsOrdersRes = await supabase.from('orders')
                    .select('id, runsheet_id, customer_id, customer_name, total_amount, order_status')
                    .eq('company_id', companyId)
                    .in('runsheet_id', rsIds);
                if (rsOrdersRes.error) throw rsOrdersRes.error;
                rsOrders = rsOrdersRes.data || [];
            }
            var rsOrderIds = rsOrders.map(function(o) { return o.id; }).filter(Boolean);
            var rsDetails = [];
            if (rsOrderIds.length) {
                var rsDetailsRes = await supabase.from('order_details')
                    .select('order_id, qty, qty_delivered, qty_refused, qty_returned, unit_price')
                    .in('order_id', rsOrderIds);
                if (rsDetailsRes.error) throw rsDetailsRes.error;
                rsDetails = rsDetailsRes.data || [];
            }

            var metricsByRs = {};
            runsheetRowsData.forEach(function(r) {
                metricsByRs[r.id] = { orders: 0, ordered: 0, delivered: 0, refused: 0, returned: 0, deliveredValue: 0, returnedValue: 0 };
            });
            var orderToRs = {};
            rsOrders.forEach(function(o) {
                if (metricsByRs[o.runsheet_id]) metricsByRs[o.runsheet_id].orders += 1;
                orderToRs[o.id] = o.runsheet_id;
            });
            rsDetails.forEach(function(d) {
                var rsid = orderToRs[d.order_id];
                if (!rsid || !metricsByRs[rsid]) return;
                var q = Number(d.qty) || 0, delivered = Number(d.qty_delivered) || 0, refused = Number(d.qty_refused) || 0, returned = Number(d.qty_returned) || 0, price = Number(d.unit_price) || 0;
                metricsByRs[rsid].ordered += q;
                metricsByRs[rsid].delivered += delivered;
                metricsByRs[rsid].refused += refused;
                metricsByRs[rsid].returned += returned;
                metricsByRs[rsid].deliveredValue += delivered * price;
                metricsByRs[rsid].returnedValue += returned * price;
            });

            var rsReportRows = runsheetRowsData.map(function(r) {
                var m = metricsByRs[r.id] || {};
                var deliveryRate = m.ordered > 0 ? ((m.delivered / m.ordered) * 100).toFixed(1) : '0.0';
                return '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showRunsheetDetail(\\'' + _esc(r.runsheet_code) + '\\')">' +
                    '<td class="p-2 font-bold text-blue-600">' + _esc(r.runsheet_code) + '</td>' +
                    '<td class="p-2">' + _esc(r.run_date) + '</td>' +
                    '<td class="p-2">' + _esc(r.driver_id) + '</td>' +
                    '<td class="p-2 text-center">' + m.orders + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(m.ordered) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(m.delivered) + '</td>' +
                    '<td class="p-2 text-center">' + deliveryRate + '%</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(m.refused) + '</td>' +
                    '<td class="p-2 text-center">' + _fmtNum(m.returned) + '</td>' +
                    '<td class="p-2 text-center font-bold">' + _fmtNum(m.deliveredValue) + '</td>' +
                    '<td class="p-2 text-center font-bold">' + _fmtNum(m.returnedValue) + '</td>' +
                    '</tr>';
            });

            html = '<h4 class="font-bold mb-3">أداء الرانشيتات</h4>' +
                _table(['الرانشيت','التاريخ','السائق','الأوردرات','الكمية المطلوبة','المسلم','نسبة التسليم','المرفوض','المرتجع','قيمة التسليم','قيمة المرتجع'], rsReportRows);
        }
`,

O5_DRIVER_PERFORMANCE: String.raw`
ابحث في _generateReport عن الكتلة الحالية التي تبدأ:
        else if (reportId === 'logistics-driver-performance') {
وتنتهي مباشرة قبل تعليق HR.
احذفها كاملة واستبدلها بالكتلة التالية كاملة:

        else if (reportId === 'logistics-driver-performance') {
            var dpRuns = await supabase.from('runsheets')
                .select('id, driver_id')
                .eq('company_id', companyId)
                .gte('run_date', fromDate)
                .lte('run_date', toDate);
            if (dpRuns.error) throw dpRuns.error;

            var driverRuns = dpRuns.data || [];
            if (driver) driverRuns = driverRuns.filter(function(r) { return String(r.driver_id || '') === String(driver); });
            var driverRsIds = driverRuns.map(function(r) { return r.id; }).filter(Boolean);
            var driverOrders = [];
            if (driverRsIds.length) {
                var dpOrdersRes = await supabase.from('orders')
                    .select('id, runsheet_id')
                    .eq('company_id', companyId)
                    .in('runsheet_id', driverRsIds);
                if (dpOrdersRes.error) throw dpOrdersRes.error;
                driverOrders = dpOrdersRes.data || [];
            }
            var driverOrderIds = driverOrders.map(function(o) { return o.id; }).filter(Boolean);
            var driverDetails = [];
            if (driverOrderIds.length) {
                var dpDetailsRes = await supabase.from('order_details')
                    .select('order_id, qty, qty_delivered, qty_refused, qty_returned, unit_price')
                    .in('order_id', driverOrderIds);
                if (dpDetailsRes.error) throw dpDetailsRes.error;
                driverDetails = dpDetailsRes.data || [];
            }

            var rsDriver = {}, rsDriverMetrics = {};
            driverRuns.forEach(function(r) {
                var key = r.driver_id || 'غير محدد';
                rsDriver[r.id] = key;
                if (!rsDriverMetrics[key]) rsDriverMetrics[key] = { runsheets: 0, orders: 0, ordered: 0, delivered: 0, refused: 0, returned: 0, deliveredValue: 0, returnedValue: 0 };
                rsDriverMetrics[key].runsheets += 1;
            });
            driverOrders.forEach(function(o) {
                var key = rsDriver[o.runsheet_id];
                if (key && rsDriverMetrics[key]) rsDriverMetrics[key].orders += 1;
            });
            var dpOrderRs = {};
            driverOrders.forEach(function(o) { dpOrderRs[o.id] = o.runsheet_id; });
            driverDetails.forEach(function(d) {
                var key = rsDriver[dpOrderRs[d.order_id]];
                if (!key || !rsDriverMetrics[key]) return;
                var q = Number(d.qty) || 0, del = Number(d.qty_delivered) || 0, ref = Number(d.qty_refused) || 0, ret = Number(d.qty_returned) || 0, price = Number(d.unit_price) || 0;
                rsDriverMetrics[key].ordered += q;
                rsDriverMetrics[key].delivered += del;
                rsDriverMetrics[key].refused += ref;
                rsDriverMetrics[key].returned += ret;
                rsDriverMetrics[key].deliveredValue += del * price;
                rsDriverMetrics[key].returnedValue += ret * price;
            });

            var driverRows = Object.keys(rsDriverMetrics).sort(function(a,b) { return a.localeCompare(b, 'ar'); }).map(function(key) {
                var m = rsDriverMetrics[key];
                var rate = m.ordered > 0 ? ((m.delivered / m.ordered) * 100).toFixed(1) : '0.0';
                return '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(key) + '</td><td class="p-2 text-center">' + m.runsheets + '</td><td class="p-2 text-center">' + m.orders + '</td><td class="p-2 text-center">' + _fmtNum(m.ordered) + '</td><td class="p-2 text-center">' + _fmtNum(m.delivered) + '</td><td class="p-2 text-center">' + rate + '%</td><td class="p-2 text-center">' + _fmtNum(m.refused) + '</td><td class="p-2 text-center">' + _fmtNum(m.returned) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(m.deliveredValue) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(m.returnedValue) + '</td></tr>';
            });

            html = '<h4 class="font-bold mb-3">أداء السائقين</h4>' +
                _table(['السائق','عدد الرانشيتات','الأوردرات','الكمية المطلوبة','المسلم','نسبة التسليم','المرفوض','المرتجع','قيمة التسليم','قيمة المرتجع'], driverRows);
        }
`,

O6_RETURNS_COMPATIBILITY: String.raw`
ابحث داخل _generateReport > logistics-returns عن:
                    .in(
                        'movement_type',
                        [
                            'SalesReturn',
                            'DirectReturn'
                        ]
                    )

احذف هذه القائمة فقط واستبدلها بـ:

                    .in(
                        'movement_type',
                        [
                            'Return',
                            'SalesReturn',
                            'DirectReturn'
                        ]
                    )

لا تغيّر أي سطر آخر في هذه الكتلة.
`,

O7_NO_UNNECESSARY_REWRITE: String.raw`
لا تعِد كتابة _companyId أو _loadDropdowns أو دوال Drill-Down الحالية؛ الفحص الحالي أثبت أنها Company-scoped، وإعادة كتابتها بدون دليل جديد ليست مطلوبة.
`,

O8_FINAL_OWNER_CHECK: String.raw`
بعد تطبيق O1–O6 على Current/PWA/main2/main9.md:
- اقرأ الملف كاملًا من أول حرف إلى آخر حرف.
- نفذ syntax validation على الملف الكامل، وليس على المقاطع.
- ابحث عن كل ظهور لـ: قيد التطوير / غير متوفر بعد / هذا التقرير غير متوفر بعد.
- يجب أن تبقى Capability Gate فقط للقدرات التي لا يثبت لها مصدر Production سلطوي: الضريبة، الحضور، الرواتب.
- راجع جميع استدعاءات Supabase داخل _generateReport للتأكد من وجود company scope أو اعتماد RPC يشتق company context من المستخدم.
- لا تنفذ Assembly.
- لا تعدل Current/PWA/main9.md من المساعد.
`
};

MAIN9_OWNER_SURGICAL_REPLACEMENTS_20260912;
