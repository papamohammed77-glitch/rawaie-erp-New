/*
 * RAWAEA ERP — MAIN10 OWNER SURGICAL REPLACEMENTS R3
 * Date: 2026-09-12
 * Source of Truth: Current/PWA/main2/main10.md
 * Current source SHA: cbdff2af773ee7be097eb1022710f2be327665f0
 *
 * Owner applies these replacements to Current/PWA/main2/main10.md.
 * Do not apply the historical MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js package.
 */

const MAIN10_OWNER_SURGICAL_REPLACEMENTS_R3_20260912 = {
  source: 'Current/PWA/main2/main10.md',
  source_sha: 'cbdff2af773ee7be097eb1022710f2be327665f0',
  replacements: [
    {
      id: 'M10-R3-01',
      title: 'إزالة اختراع حالة trial عند غياب بيانات الترخيص',
      line_range: '13–79',
      function: 'function _loadLicenseData()',
      action: 'ابحث عن السطر الكامل function _loadLicenseData() { واحذف الدالة كاملة حتى القوس } في آخر الدالة، ثم استبدلها كاملة بالعنصر التالي. آخر سطر في العنصر الحالي قبل بداية التعليقات هو }.',
      replacement: `function _loadLicenseData() {
    var companyId = null;

    if (
        typeof RW_STATE !== 'undefined' &&
        RW_STATE &&
        RW_STATE.app &&
        RW_STATE.app.company &&
        RW_STATE.app.company.id
    ) {
        companyId = RW_STATE.app.company.id;
    }

    if (
        !companyId &&
        typeof RW_STATE !== 'undefined' &&
        RW_STATE.app &&
        RW_STATE.app.companyId
    ) {
        companyId = RW_STATE.app.companyId;
    }

    if (
        !companyId &&
        typeof RW_STATE !== 'undefined' &&
        RW_STATE.user &&
        RW_STATE.user.companyId
    ) {
        companyId = RW_STATE.user.companyId;
    }

    if (!companyId) {
        safeHTML(byId('license-main-container'), '<div class="rw-card" style="text-align:center;padding:40px 20px"><div style="font-size:48px;margin-bottom:16px">⚠️</div><h3>تعذر تحديد سياق الشركة</h3><p style="color:#6b7280;margin-top:8px">لا يمكن تحميل بيانات الترخيص دون Company Context صالح.</p></div>');
        return;
    }

    supabase
        .from('app_settings')
        .select('*')
        .eq('company_id', companyId)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle()
        .then(function(res) {
            if (res.error) throw res.error;

            if (!res.data) {
                safeHTML(byId('license-main-container'), '<div class="rw-card" style="text-align:center;padding:40px 20px"><div style="font-size:48px;margin-bottom:16px">⚠️</div><h3>بيانات الترخيص غير متاحة</h3><p style="color:#6b7280;margin-top:8px">لم يتم العثور على إعدادات ترخيص مسجلة لهذه الشركة.</p></div>');
                return;
            }

            var s = res.data;

            _buildFullForm({
                licenseStatus: s.status || 'trial',
                trialEndDate: s.trial_end_date || '',
                subscriptionEndDate: s.subscription_end_date || '',
                ownerEmail: s.owner_email || ''
            });
        })
        .catch(function(error) {
            console.error('RW_OwnerLicense._loadLicenseData', error);
            safeHTML(byId('license-main-container'), '<div class="rw-card" style="text-align:center;padding:40px 20px"><div style="font-size:48px;margin-bottom:16px">⚠️</div><h3>تعذر تحميل بيانات الترخيص</h3><p style="color:#6b7280;margin-top:8px">حدث خطأ أثناء قراءة إعدادات الترخيص.</p></div>');
        });
}`
    },
    {
      id: 'M10-R3-02',
      title: 'رفض حفظ إعدادات الترخيص بدون Session صالحة',
      line_range: '254–286',
      function: 'function _saveSettings(payload, label)',
      action: 'ابحث عن السطر الكامل function _saveSettings(payload, label) { واحذف الدالة كاملة حتى القوس } في آخر الدالة، وآخر سطر كامل في العنصر الحالي هو } ثم الاستبدال مباشرة قبل return { render: render };.',
      replacement: `function _saveSettings(payload, label) {
    showLoader('جاري حفظ ' + (label || 'الإعدادات') + '...');

    supabase.auth.getSession().then(function(sessionRes) {
        if (
            !sessionRes ||
            sessionRes.error ||
            !sessionRes.data ||
            !sessionRes.data.session ||
            !sessionRes.data.session.access_token
        ) {
            throw new Error('جلسة المصادقة غير صالحة أو منتهية');
        }

        var headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + sessionRes.data.session.access_token
        };

        return fetch(RW_SUPABASE_URL + '/functions/v1/save-settings', {
            method: 'POST',
            headers: headers,
            body: JSON.stringify(payload)
        });
    }).then(function(res) {
        if (!res.ok) {
            return res.json().then(function(err) {
                throw new Error(err.error || 'خطأ في الخادم');
            });
        }
        return res.json();
    }).then(function(json) {
        hideLoader();
        if (json.success) {
            showToast('تم حفظ ' + (label || 'الإعدادات') + ' بنجاح', 'success');
        } else {
            showToast(json.error || 'فشل حفظ ' + (label || 'الإعدادات'), 'error');
        }
    }).catch(function(e) {
        hideLoader();
        showToast('فشل الاتصال: ' + (e.message || 'خطأ غير معروف'), 'error');
        console.error('RW_OwnerLicense._saveSettings', e);
    });
}`
    }
  ]
};
