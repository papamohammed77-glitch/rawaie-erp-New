
var RW_OwnerLicense = (function () {
    'use strict';

    var state = {
        companies: [],
        selectedCompanyId: null,
        detail: null,
        filterText: '',
        filterStatus: 'all'
    };

    function isOwner() {
        try {
            return !!(
                RW_STATE &&
                RW_STATE.app &&
                RW_STATE.app.currentUser &&
                RW_STATE.app.currentUser.isOwner === true
            );
        } catch (e) {
            return false;
        }
    }

    function esc(value) {
        var s = value == null ? '' : String(value);
        return s
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function valueOrDash(value) {
        return value == null || value === '' ? 'غير محدد' : esc(value);
    }

    function dateInput(value) {
        return value == null ? '' : esc(value);
    }

    function fmtDate(value) {
        if (!value) return 'غير محدد';
        var s = String(value);
        if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
        var d = new Date(s);
        if (isNaN(d.getTime())) return esc(s);
        return d.toISOString().slice(0, 10);
    }

    function fmtNum(value) {
        var n = Number(value);
        return isFinite(n) ? n.toLocaleString('ar-EG') : '0';
    }

    function statusLabel(status) {
        var map = {
            trial: 'فترة تجربة',
            active: 'نشطة',
            suspended: 'موقوفة',
            cancelled: 'ملغاة'
        };
        return map[status] || (status ? status : 'غير مهيأ');
    }

    function statusTone(status) {
        if (status === 'active') return 'background:#ecfdf5;color:#047857;';
        if (status === 'trial') return 'background:#fffbeb;color:#b45309;';
        if (status === 'suspended') return 'background:#fff7ed;color:#c2410c;';
        if (status === 'cancelled') return 'background:#fef2f2;color:#b91c1c;';
        return 'background:#f8fafc;color:#64748b;';
    }

    function getToken() {
        return supabase.auth.getSession().then(function (res) {
            if (
                !res ||
                res.error ||
                !res.data ||
                !res.data.session ||
                !res.data.session.access_token
            ) {
                throw new Error('جلسة المصادقة غير صالحة أو منتهية');
            }
            return res.data.session.access_token;
        });
    }

    function api(adminAction, companyId, payload) {
        return getToken().then(function (token) {
            return fetch(RW_SUPABASE_URL + '/functions/v1/save-settings', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token
                },
                body: JSON.stringify({
                    action: 'license-admin',
                    admin_action: adminAction,
                    company_id: companyId || null,
                    payload: payload || {}
                })
            });
        }).then(function (res) {
            return res.text().then(function (text) {
                var data = {};
                try { data = text ? JSON.parse(text) : {}; } catch (e) {}
                if (!res.ok || !data || data.success !== true) {
                    throw new Error((data && (data.error || data.msg)) || 'فشل الاتصال بخدمة إدارة التراخيص');
                }
                return data;
            });
        });
    }

    function render() {
        var container = byId('rw-page-container');
        if (!container) return;

        safeText(byId('rw-header-title'), 'إدارة التراخيص');
        safeText(
            byId('rw-header-subtitle'),
            'إدارة الشركات والتراخيص من مركز المالك — سجل موحد دون Modal'
        );

        if (!isOwner()) {
            safeHTML(
                container,
                '<div class="rw-card" style="max-width:760px;margin:50px auto;padding:70px 24px;text-align:center">' +
                '<div style="font-size:64px;margin-bottom:20px">🔒</div>' +
                '<h2 style="font-weight:900;margin-bottom:10px">غير مصرح</h2>' +
                '<p style="color:#64748b;font-weight:700">هذا التبويب مخصص للمالك فقط.</p>' +
                '</div>'
            );
            return;
        }

        safeHTML(
            container,
            '<div id="license-main-container" style="display:flex;flex-direction:column;gap:24px">' +
                '<div id="license-owner-card"></div>' +
                '<div id="license-directory-card"></div>' +
                '<div id="license-detail-card"></div>' +
            '</div>'
        );

        renderOwnerCard();
        renderDirectoryShell();
        loadDirectory();
    }

    function renderOwnerCard() {
        var host = byId('license-owner-card');
        if (!host) return;

        var currentEmail = '';
        try {
            currentEmail = RW_STATE.app.currentUser.email || '';
        } catch (e) {}

        var html =
            '<section class="rw-card" style="padding:26px">' +
                '<div style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:20px">' +
                    '<div>' +
                        '<div style="font-size:20px;font-weight:900;color:#111827">ملف المالك</div>' +
                        '<div style="font-size:12px;color:#64748b;font-weight:700;margin-top:4px">هوية المالك وصلاحية الوصول إلى مركز إدارة التراخيص.</div>' +
                    '</div>' +
                    '<span class="rw-status" style="' + statusTone('active') + '">OWNER • permissions:["*"]</span>' +
                '</div>' +
                '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px">' +
                    '<div style="padding:16px;border:1px solid #e5e7eb;border-radius:18px;background:#f8fafc">' +
                        '<div style="font-size:11px;color:#64748b;font-weight:800;margin-bottom:6px">البريد الحالي</div>' +
                        '<div style="font-size:15px;font-weight:900;color:#111827;word-break:break-all">' + esc(currentEmail) + '</div>' +
                    '</div>' +
                    '<div style="padding:16px;border:1px solid #e5e7eb;border-radius:18px;background:#f8fafc">' +
                        '<div style="font-size:11px;color:#64748b;font-weight:800;margin-bottom:6px">حالة الحساب</div>' +
                        '<div style="font-size:15px;font-weight:900;color:#047857">Active</div>' +
                    '</div>' +
                    '<div style="display:flex;align-items:end;gap:10px;flex-wrap:wrap">' +
                        '<input id="owner-new-email" type="email" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px;min-width:220px" placeholder="بريد إلكتروني جديد">' +
                        '<button type="button" id="btn-owner-change-email" class="rw-btn-primary">تغيير البريد</button>' +
                    '</div>' +
                '</div>' +
                '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;margin-top:16px">' +
                    '<input id="owner-new-password" type="password" autocomplete="new-password" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px" placeholder="كلمة المرور الجديدة">' +
                    '<input id="owner-confirm-password" type="password" autocomplete="new-password" class="rw-input" style="height:48px;padding:0 14px;border-radius:14px" placeholder="تأكيد كلمة المرور">' +
                    '<button type="button" id="btn-owner-change-password" class="rw-btn-primary" style="background:#dc2626">تغيير كلمة المرور</button>' +
                '</div>' +
            '</section>';

        safeHTML(host, html);

        var emailBtn = byId('btn-owner-change-email');
        if (emailBtn) {
            emailBtn.onclick = function () {
                if (!isOwner()) return showToast('غير مصرح', 'error');
                var input = byId('owner-new-email');
                var next = String(input && input.value || '').trim().toLowerCase();
                if (!next || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(next)) {
                    return showToast('أدخل بريدًا إلكترونيًا صالحًا', 'error');
                }

                showLoader('جاري تحديث البريد الإلكتروني...');
                supabase.auth.updateUser({ email: next }).then(function (res) {
                    hideLoader();
                    if (res.error) throw res.error;
                    if (input) input.value = '';
                    showToast('تم إرسال رسالة تأكيد إلى البريد الجديد.', 'success');
                }).catch(function (e) {
                    hideLoader();
                    showToast(e.message || 'فشل تغيير البريد الإلكتروني', 'error');
                });
            };
        }

        var passwordBtn = byId('btn-owner-change-password');
        if (passwordBtn) {
            passwordBtn.onclick = function () {
                if (!isOwner()) return showToast('غير مصرح', 'error');
                var pass = String((byId('owner-new-password') || {}).value || '');
                var confirm = String((byId('owner-confirm-password') || {}).value || '');
                if (pass.length < 6) return showToast('كلمة المرور يجب ألا تقل عن 6 أحرف.', 'error');
                if (pass !== confirm) return showToast('تأكيد كلمة المرور غير مطابق.', 'error');

                showLoader('جاري تغيير كلمة المرور...');
                supabase.auth.updateUser({ password: pass }).then(function (res) {
                    hideLoader();
                    if (res.error) throw res.error;
                    byId('owner-new-password').value = '';
                    byId('owner-confirm-password').value = '';
                    showToast('تم تغيير كلمة المرور بنجاح.', 'success');
                }).catch(function (e) {
                    hideLoader();
                    showToast(e.message || 'فشل تغيير كلمة المرور', 'error');
                });
            };
        }
    }

    function renderDirectoryShell() {
        var host = byId('license-directory-card');
        if (!host) return;

        safeHTML(
            host,
            '<section class="rw-card" style="padding:26px">' +
                '<div style="display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap;margin-bottom:20px">' +
                    '<div>' +
                        '<div style="font-size:20px;font-weight:900;color:#111827">الشركات والتراخيص</div>' +
                        '<div style="font-size:12px;color:#64748b;font-weight:700;margin-top:4px">مركز واحد لإدارة حالة كل شركة وربطها بالحالة الفعلية في النظام.</div>' +
                    '</div>' +
                    '<button type="button" id="license-refresh" class="rw-btn-primary">↻ تحديث</button>' +
                '</div>' +
                '<div id="license-kpis" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px;margin-bottom:18px"></div>' +
                '<div style="display:grid;grid-template-columns:minmax(240px,1fr) 220px;gap:12px;margin-bottom:18px">' +
                    '<input id="license-search" type="search" class="rw-input" style="height:48px;padding:0 16px;border-radius:14px" placeholder="ابحث باسم الشركة أو الكود أو البريد...">' +
                    '<select id="license-status-filter" class="rw-input" style="height:48px;padding:0 16px;border-radius:14px">' +
                        '<option value="all">كل الحالات</option>' +
                        '<option value="active">نشطة</option>' +
                        '<option value="trial">تجربة</option>' +
                        '<option value="suspended">موقوفة</option>' +
                        '<option value="cancelled">ملغاة</option>' +
                    '</select>' +
                '</div>' +
                '<div id="license-company-table"></div>' +
            '</section>'
        );

        var refresh = byId('license-refresh');
        if (refresh) refresh.onclick = function () { loadDirectory(); };

        var search = byId('license-search');
        if (search) {
            search.oninput = function () {
                state.filterText = search.value || '';
                renderCompanyTable();
            };
        }

        var filter = byId('license-status-filter');
        if (filter) {
            filter.onchange = function () {
                state.filterStatus = filter.value || 'all';
                renderCompanyTable();
            };
        }
    }

    function loadDirectory() {
        var tableHost = byId('license-company-table');
        if (tableHost) {
            safeHTML(tableHost, '<div style="padding:50px;text-align:center;color:#64748b;font-weight:800">جاري قراءة Production...</div>');
        }

        api('list').then(function (res) {
            state.companies = Array.isArray(res.companies) ? res.companies : [];
            updateKpis();
            renderCompanyTable();

            if (state.selectedCompanyId) {
                return loadCompany(state.selectedCompanyId, true);
            }
        }).catch(function (e) {
            if (tableHost) {
                safeHTML(
                    tableHost,
                    '<div class="rw-card" style="padding:40px;text-align:center;border:1px solid #fecaca;background:#fef2f2">' +
                        '<div style="font-size:42px">⚠️</div>' +
                        '<div style="font-weight:900;color:#991b1b">تعذر تحميل سجل التراخيص</div>' +
                        '<div style="color:#7f1d1d;margin-top:8px;font-weight:700">' + esc(e.message || e) + '</div>' +
                    '</div>'
                );
            }
        });
    }

    function updateKpis() {
        var host = byId('license-kpis');
        if (!host) return;

        var total = state.companies.length;
        var active = 0, trial = 0, suspended = 0, cancelled = 0;
        state.companies.forEach(function (c) {
            if (c.license_status === 'active') active++;
            else if (c.license_status === 'trial') trial++;
            else if (c.license_status === 'suspended') suspended++;
            else if (c.license_status === 'cancelled') cancelled++;
        });

        safeHTML(
            host,
            kpi('إجمالي الشركات', total, '🏢', '#eff6ff', '#1d4ed8') +
            kpi('نشطة', active, '✓', '#ecfdf5', '#047857') +
            kpi('تجربة', trial, '◷', '#fffbeb', '#b45309') +
            kpi('موقوفة/ملغاة', suspended + cancelled, '!', '#fef2f2', '#b91c1c')
        );
    }

    function kpi(title, value, icon, bg, fg) {
        return '<div style="padding:18px;border:1px solid #e5e7eb;border-radius:18px;background:white">' +
            '<div style="width:42px;height:42px;border-radius:13px;background:' + bg + ';color:' + fg + ';display:flex;align-items:center;justify-content:center;font-weight:900;font-size:18px;margin-bottom:12px">' + icon + '</div>' +
            '<div style="font-size:11px;color:#64748b;font-weight:800">' + esc(title) + '</div>' +
            '<div style="font-size:27px;font-weight:900;color:#111827;margin-top:4px">' + fmtNum(value) + '</div>' +
        '</div>';
    }

    function filteredCompanies() {
        var q = String(state.filterText || '').trim().toLowerCase();
        return state.companies.filter(function (c) {
            if (state.filterStatus !== 'all' && String(c.license_status || '') !== state.filterStatus) return false;
            if (!q) return true;
            var hay = [
                c.name, c.company_code, c.email, c.phone, c.plan_code,
                c.license_status, c.billing_cycle
            ].join(' ').toLowerCase();
            return hay.indexOf(q) >= 0;
        });
    }

    function renderCompanyTable() {
        var host = byId('license-company-table');
        if (!host) return;

        var rows = filteredCompanies();
        if (!rows.length) {
            safeHTML(host, '<div style="padding:50px;text-align:center;color:#94a3b8;font-weight:800">لا توجد شركات مطابقة.</div>');
            return;
        }

        var html =
            '<div class="rw-table-wrapper">' +
                '<table class="rw-table">' +
                    '<thead><tr>' +
                        '<th>الشركة</th><th>الحالة</th><th>الخطة</th><th>التجربة</th><th>الاشتراك</th><th>المستخدمون</th><th>الفروع</th><th>إجراء</th>' +
                    '</tr></thead><tbody>';

        rows.forEach(function (c) {
            var selected = String(c.company_id) === String(state.selectedCompanyId);
            html +=
                '<tr style="' + (selected ? 'background:#eff6ff;' : '') + '">' +
                    '<td><div style="font-weight:900">' + esc(c.name || 'شركة بلا اسم') + '</div><div style="font-size:11px;color:#64748b;margin-top:3px">' + esc(c.company_code || '') + '</div></td>' +
                    '<td><span class="rw-status" style="' + statusTone(c.license_status) + '">' + esc(statusLabel(c.license_status)) + '</span></td>' +
                    '<td>' + valueOrDash(c.plan_code) + '</td>' +
                    '<td>' + esc(fmtDate(c.trial_end_date)) + '</td>' +
                    '<td>' + esc(fmtDate(c.subscription_end_date)) + '</td>' +
                    '<td>' + fmtNum(c.active_users) + '</td>' +
                    '<td>' + fmtNum(c.active_branches) + '</td>' +
                    '<td><button type="button" class="rw-btn-primary" style="height:38px;padding:0 14px" onclick="RW_OwnerLicense.selectCompany(\\'' + esc(c.company_id) + '\\')">إدارة</button></td>' +
                '</tr>';
        });

        html += '</tbody></table></div>';
        safeHTML(host, html);
    }

    function selectCompany(companyId) {
        if (!companyId) return;
        state.selectedCompanyId = String(companyId);
        loadCompany(companyId, false);
        renderCompanyTable();
    }

    function renderLoadingDetail() {
        var host = byId('license-detail-card');
        if (!host) return;
        safeHTML(host, '<section class="rw-card" style="padding:50px;text-align:center;color:#64748b;font-weight:800">جاري فتح صفحة الشركة...</section>');
    }

    function loadCompany(companyId, silent) {
        if (!silent) renderLoadingDetail();

        return api('detail', companyId).then(function (res) {
            state.detail = res;
            state.selectedCompanyId = String(companyId);
            renderDetail();
            return res;
        }).catch(function (e) {
            var host = byId('license-detail-card');
            if (host) {
                safeHTML(host,
                    '<section class="rw-card" style="padding:40px;text-align:center;border:1px solid #fecaca;background:#fef2f2">' +
                        '<div style="font-size:40px">⚠️</div>' +
                        '<div style="font-weight:900;color:#991b1b">تعذر تحميل تفاصيل الشركة</div>' +
                        '<div style="margin-top:8px;color:#7f1d1d;font-weight:700">' + esc(e.message || e) + '</div>' +
                    '</section>'
                );
            }
            if (!silent) throw e;
        });
    }

    function renderDetail() {
        var host = byId('license-detail-card');
        if (!host || !state.detail) return;

        var d = state.detail;
        var c = d.company || {};
        var l = d.license || {};
        var r = d.runtime || {};
        var metrics = d.metrics || {};
        var audit = Array.isArray(d.audit) ? d.audit : [];

        var html =
            '<section class="rw-card" style="padding:26px">' +
                '<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:14px;flex-wrap:wrap;margin-bottom:24px">' +
                    '<div>' +
                        '<button type="button" id="license-back-to-list" style="border:none;background:none;color:#2563eb;font-weight:900;cursor:pointer;padding:0 0 8px">← العودة إلى الشركات</button>' +
                        '<div style="font-size:26px;font-weight:900;color:#111827">' + esc(c.name || 'الشركة') + '</div>' +
                        '<div style="font-size:12px;color:#64748b;font-weight:700;margin-top:4px">Code: ' + esc(c.company_code || '') + ' • Company ID: ' + esc(c.id || '') + '</div>' +
                    '</div>' +
                    '<span class="rw-status" style="' + statusTone(l.license_status || r.status) + '">' + esc(statusLabel(l.license_status || r.status)) + '</span>' +
                '</div>' +

                '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin-bottom:24px">' +
                    statBox('المستخدمون النشطون', fmtNum(metrics.active_users), '👥') +
                    statBox('الفروع النشطة', fmtNum(metrics.active_branches), '🏬') +
                    statBox('الحالة التشغيلية', statusLabel(r.status), '⚙') +
                    statBox('انتهاء الاشتراك', fmtDate(r.subscription_end_date), '📅') +
                '</div>' +

                '<div style="display:grid;grid-template-columns:1fr;gap:20px">' +
                    '<div style="border:1px solid #e5e7eb;border-radius:22px;padding:22px">' +
                        '<div style="font-size:18px;font-weight:900;margin-bottom:18px">إدارة الترخيص</div>' +
                        '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px">' +
                            fieldSelect('license-edit-status','حالة الترخيص',l.license_status || r.status || 'trial', [
                                ['trial','فترة تجربة'],['active','نشطة'],['suspended','موقوفة'],['cancelled','ملغاة']
                            ]) +
                            fieldInput('license-edit-plan','الخطة / Plan Code',l.plan_code,'text','مثال: Standard / Pro / Enterprise') +
                            fieldSelect('license-edit-cycle','دورة الفوترة',l.billing_cycle || '', [
                                ['','غير محدد'],['monthly','شهري'],['quarterly','ربع سنوي'],['semiannual','نصف سنوي'],['annual','سنوي'],['custom','مخصص']
                            ]) +
                            fieldInput('license-edit-trial-start','بداية التجربة',l.trial_start_date,'date','') +
                            fieldInput('license-edit-trial-end','نهاية التجربة',l.trial_end_date || r.trial_end_date,'date','') +
                            fieldInput('license-edit-sub-start','بداية الاشتراك',l.subscription_start_date,'date','') +
                            fieldInput('license-edit-sub-end','نهاية الاشتراك',l.subscription_end_date || r.subscription_end_date,'date','') +
                            fieldInput('license-edit-grace-end','نهاية المهلة Grace',l.grace_end_date,'date','') +
                        '</div>' +
                        '<div style="margin-top:14px">' +
                            '<label style="display:block;font-size:12px;font-weight:900;color:#374151;margin-bottom:7px">ملاحظات تشغيلية</label>' +
                            '<textarea id="license-edit-notes" class="rw-input" rows="4" style="height:auto;padding:12px 14px;border-radius:14px;resize:vertical" placeholder="ملاحظات حول العقد أو الحالة">' + esc(l.notes || '') + '</textarea>' +
                        '</div>' +
                        '<div style="display:flex;gap:10px;justify-content:flex-end;flex-wrap:wrap;margin-top:18px">' +
                            '<button type="button" id="license-save" class="rw-btn-primary" style="height:48px;padding:0 22px">حفظ التعديلات</button>' +
                        '</div>' +
                    '</div>' +

                    '<div style="border:1px solid #dbeafe;border-radius:22px;padding:22px;background:#f8fbff">' +
                        '<div style="font-size:18px;font-weight:900;margin-bottom:14px">مطابقة Runtime</div>' +
                        '<div style="font-size:12px;color:#475569;font-weight:700;line-height:1.9">القيم التالية هي الإسقاط الفعلي إلى <code>app_settings</code> الذي تعتمد عليه التطبيقات الحالية. التعديل المركزي يحدث داخل Transaction واحدة مع سجل الترخيص.</div>' +
                        '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;margin-top:14px">' +
                            statBox('Runtime Status', statusLabel(r.status), '●') +
                            statBox('Trial End', fmtDate(r.trial_end_date), '◷') +
                            statBox('Subscription End', fmtDate(r.subscription_end_date), '⌛') +
                        '</div>' +
                    '</div>' +

                    '<div style="border:1px solid #e5e7eb;border-radius:22px;padding:22px">' +
                        '<div style="font-size:18px;font-weight:900;margin-bottom:14px">سجل التغييرات</div>' +
                        (audit.length ? renderAudit(audit) : '<div style="padding:25px;text-align:center;color:#94a3b8;font-weight:800">لا توجد تغييرات مسجلة للترخيص بعد.</div>') +
                    '</div>' +
                '</div>' +
            '</section>';

        safeHTML(host, html);
        bindDetail();
    }

    function statBox(title, value, icon) {
        return '<div style="padding:14px;border:1px solid #e5e7eb;border-radius:16px;background:#fff">' +
            '<div style="font-size:15px;margin-bottom:6px">' + icon + '</div>' +
            '<div style="font-size:11px;color:#64748b;font-weight:800">' + esc(title) + '</div>' +
            '<div style="font-size:16px;color:#111827;font-weight:900;margin-top:4px">' + esc(value) + '</div>' +
        '</div>';
    }

    function fieldInput(id, label, value, type, placeholder) {
        return '<div>' +
            '<label style="display:block;font-size:12px;font-weight:900;color:#374151;margin-bottom:7px">' + esc(label) + '</label>' +
            '<input id="' + esc(id) + '" type="' + esc(type) + '" class="rw-input" style="height:46px;padding:0 13px;border-radius:13px" value="' + dateInput(value) + '" placeholder="' + esc(placeholder || '') + '">' +
        '</div>';
    }

    function fieldSelect(id, label, value, options) {
        var html = '<div><label style="display:block;font-size:12px;font-weight:900;color:#374151;margin-bottom:7px">' + esc(label) + '</label>' +
            '<select id="' + esc(id) + '" class="rw-input" style="height:46px;padding:0 13px;border-radius:13px">';
        options.forEach(function (op) {
            html += '<option value="' + esc(op[0]) + '"' + (String(op[0]) === String(value || '') ? ' selected' : '') + '>' + esc(op[1]) + '</option>';
        });
        html += '</select></div>';
        return html;
    }

    function renderAudit(rows) {
        var html = '<div style="display:flex;flex-direction:column;gap:10px">';
        rows.forEach(function (a) {
            html += '<div style="padding:14px;border-radius:16px;background:#f8fafc;border:1px solid #e5e7eb">' +
                '<div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap">' +
                    '<div style="font-weight:900;color:#111827">' + esc(a.action || 'update') + '</div>' +
                    '<div style="font-size:11px;color:#64748b;font-weight:700">' + esc(a.user_email || 'system') + ' • ' + esc(a.created_at || '') + '</div>' +
                '</div>' +
                '<div style="font-size:11px;color:#64748b;margin-top:7px">record_id: ' + esc(a.record_id || '') + '</div>' +
            '</div>';
        });
        return html + '</div>';
    }

    function bindDetail() {
        var back = byId('license-back-to-list');
        if (back) {
            back.onclick = function () {
                state.selectedCompanyId = null;
                state.detail = null;
                safeHTML(byId('license-detail-card'), '');
                renderCompanyTable();
            };
        }

        var save = byId('license-save');
        if (save) {
            save.onclick = function () {
                saveLicense();
            };
        }
    }

    function saveLicense() {
        if (!state.selectedCompanyId) return showToast('لم يتم تحديد الشركة.', 'error');

        var trialStart = String((byId('license-edit-trial-start') || {}).value || '').trim() || null;
        var trialEnd = String((byId('license-edit-trial-end') || {}).value || '').trim() || null;
        var subStart = String((byId('license-edit-sub-start') || {}).value || '').trim() || null;
        var subEnd = String((byId('license-edit-sub-end') || {}).value || '').trim() || null;
        var graceEnd = String((byId('license-edit-grace-end') || {}).value || '').trim() || null;

        if (trialStart && trialEnd && trialEnd < trialStart) {
            return showToast('نهاية التجربة يجب ألا تسبق بدايتها.', 'error');
        }
        if (subStart && subEnd && subEnd < subStart) {
            return showToast('نهاية الاشتراك يجب ألا تسبق بدايته.', 'error');
        }
        if (subEnd && graceEnd && graceEnd < subEnd) {
            return showToast('نهاية المهلة يجب ألا تسبق نهاية الاشتراك.', 'error');
        }

        var payload = {
            license_status: String((byId('license-edit-status') || {}).value || 'trial'),
            plan_code: String((byId('license-edit-plan') || {}).value || '').trim() || null,
            billing_cycle: String((byId('license-edit-cycle') || {}).value || '').trim() || null,
            trial_start_date: trialStart,
            trial_end_date: trialEnd,
            subscription_start_date: subStart,
            subscription_end_date: subEnd,
            grace_end_date: graceEnd,
            notes: String((byId('license-edit-notes') || {}).value || '').trim() || null
        };

        showLoader('جاري حفظ الترخيص وتحديث Runtime...');
        api('save', state.selectedCompanyId, payload).then(function (res) {
            hideLoader();
            state.detail = res;
            state.companies = state.companies.map(function (c) {
                if (String(c.company_id) !== String(state.selectedCompanyId)) return c;
                var l = res.license || {};
                var r = res.runtime || {};
                return Object.assign({}, c, {
                    license_status: l.license_status || r.status,
                    plan_code: l.plan_code,
                    billing_cycle: l.billing_cycle,
                    trial_start_date: l.trial_start_date,
                    trial_end_date: l.trial_end_date || r.trial_end_date,
                    subscription_start_date: l.subscription_start_date,
                    subscription_end_date: l.subscription_end_date || r.subscription_end_date,
                    grace_end_date: l.grace_end_date
                });
            });
            updateKpis();
            renderCompanyTable();
            renderDetail();
            showToast('تم حفظ الترخيص وتحديث Runtime بنجاح.', 'success');
        }).catch(function (e) {
            hideLoader();
            showToast(e.message || 'فشل حفظ الترخيص.', 'error');
        });
    }

    return {
        render: render,
        reload: loadDirectory,
        selectCompany: selectCompany,
        saveLicense: saveLicense
    };
})();

window.RW_OwnerLicense = RW_OwnerLicense;
