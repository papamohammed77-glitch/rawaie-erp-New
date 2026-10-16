# Report433 — توسيع مودال الخزينة وتثبيت QR دون ادعاء نجاح كاذب

**التاريخ:** 2026-10-17  
**النطاق:** النظام الأم — RW_Finance / الخزائن والبنوك  
**Production:** Supabase project fiilmooggumokxanwiyx

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المطلوب مودال إنشاء أعرض من 920px، ورمز QR ثابت لكل خزينة مع كود مقروء، دون تغيير الرصيد أو إنشاء حركة مالية.
- **Architecture Understanding:** المالك هو من يعدل وينشر main.html وتطبيق POS. لم أعدل أي ملف واجهة أو تطبيق تشغيلي.
- **Database Understanding:** Production تحتوي public.treasury وpublic.pos_terminals وpublic.pos_shifts وpublic.cash_box.
- **Historical Understanding:** Report431 أصلح حفظ الخزائن وربط الفرع عبر RPCs؛ Report432 أضاف QR إلى النظام الأم. يجب الحفاظ على هذه التغييرات وعدم تكرارها.
- **Production Understanding:** آخر استعلام مباشر أعاد treasury=1, pos_terminals=1, pos_shifts=1, cash_box=6 عند 2026-10-16 21:09:58.733033+00 UTC.
- **Current Source Understanding:** Git commits تؤكد وجود QR في da0f3fcddf264a77573a34a565feb8bcb653f449، ورفع العرض إلى 920 في 282d0d21d23b1b76dff9a4bcf60f350f1d58de8a. أحدث commit تمت مراجعته 80914df7ca75c754815ba22871e3aeae66d5cfe4. SHA blob الحالي لملف main.html الذي أعاده GitHub هو 10ea1297782b58f8d56b5a9409f41b01b3dac03f؛ أداة الجلب أعادت metadata/SHA دون جسم الملف الضخم، لذلك لا أدعي قراءة جسم الملف كاملًا في هذه الدورة.
- **Execution Confidence:** مرتفع في إثبات تغييرات Git والخلل المستنتج من diff؛ اختبار المتصفح والنشر غير مثبتين.

### Confirmed Facts
1. QR موجود بالفعل في Git؛ لا تضف زرًا أو دالة ثانية.
2. العرض الحالي 920px.
3. RPCs الحالية هي finance_list_treasury_branches(uuid), finance_save_treasury(uuid,uuid,text,text,numeric,uuid), finance_delete_treasury(uuid,uuid). فُحصت تعريفاتها وACL: authenticated/service_role مسموح لهما، وanon غير مسموح؛ الوظائف تتحقق من جلسة المستخدم وسياق الشركة.
4. خلل مثبت: _showTreasuryQR يمسك خطأ QR داخليًا ولا يعيد نتيجة نجاح/فشل، ثم _openTreasuryDialog يعرض دائمًا رسالة «تم حفظ الحساب وإنشاء رمز QR الخاص به». قد تظهر رسالة نجاح QR كاذبة.
5. خلل إعادة المحاولة: script الذي فشل تحميله قد يبقى في DOM بعلامة data-rawaea-qrcode، فتنتظر محاولة لاحقة حدثًا سبق حدوثه.
6. لا يوجد دليل بعد على أن مسح QR يربط POS terminal بالخزينة. الـpayload هو معرف وليس credential.

### Unknowns / Conflicts / Unverified
- Unverified: Cloudflare served artifact يطابق Git.
- Unverified: اختبار E2E من المتصفح بعد النشر.
- Unverified: POS scan-to-bind consumer.
- لا يوجد عيب Production مثبت يتطلب تغيير schema أو ACL؛ لم تُجرَ أي تغييرات Production أو بيانات.

## التعديل الجراحي المطلوب للمالك

### Change A — توسيع المودال مع الاستجابة للشاشات الصغيرة
- **الملف:** papamohammed77-glitch/erp-frontend/companies/company-1/main.html
- **SHA:** 10ea1297782b58f8d56b5a9409f41b01b3dac03f
- **الدالة:** _openTreasuryDialog()
- **محدد البحث:** title: 'إضافة خزينة / بنك',
- ابحث عن السطر:

        width: 920,

- واستبدله فقط بـ:

        width: 'min(1120px, calc(100vw - 32px))',

### Change B — منع النجاح الكاذب عند فشل QR
- **الدالة:** _openTreasuryDialog()
- **محدد البحث:** await _showTreasuryQR(savedTreasury.account_code, savedTreasury);
- استبدل كتلة النجاح كاملة:

        _refreshCache();
        renderSubTab('treasury');
        await _showTreasuryQR(savedTreasury.account_code, savedTreasury);
        _showToast('تم حفظ الحساب وإنشاء رمز QR الخاص به', 'success');

- بالكتلة التالية:

        _refreshCache();
        renderSubTab('treasury');

        var qrDisplayed = await _showTreasuryQR(savedTreasury.account_code, savedTreasury, true);
        if (qrDisplayed) {
            _showToast('تم حفظ الحساب وإنشاء رمز QR الخاص به', 'success');
        } else {
            _showToast('تم حفظ الخزينة بنجاح، لكن تعذر عرض QR. يمكنك إعادة المحاولة من زر «عرض QR» بالقائمة.', 'warning');
        }

### Change C — استبدال دالة QR كاملة لمعالجة فشل التحميل وإعادة المحاولة
- **الدالة:** _showTreasuryQR(code, fallbackItem)
- **المحدد:** async function _showTreasuryQR(code, fallbackItem) {
- احذف الدالة الموجودة كاملة واستبدلها بالنص التالي، ولا تضف نسخة ثانية:

    async function _showTreasuryQR(code, fallbackItem, suppressErrorToast) {
        var item = fallbackItem || null;
        var treasuryCache = Array.isArray(_cache.treasury) ? _cache.treasury : [];

        if (!item) {
            for (var i = 0; i < treasuryCache.length; i++) {
                if (treasuryCache[i].account_code === code || treasuryCache[i].id === code) {
                    item = treasuryCache[i];
                    break;
                }
            }
        }

        if (!item || !item.id) {
            if (!suppressErrorToast) _showToast('تعذر العثور على هوية الخزينة لإنشاء رمز QR', 'error');
            return false;
        }

        var companyId;
        try {
            companyId = _companyId();
            if (!companyId) throw new Error('سياق الشركة غير محدد');
        } catch (e) {
            if (!suppressErrorToast) _showToast((e && e.message) || 'سياق الشركة غير محدد', 'error');
            return false;
        }

        var payload = JSON.stringify({
            type: 'rawaea_treasury',
            version: 1,
            company_id: String(companyId),
            treasury_id: String(item.id)
        });

        try {
            if (typeof QRCode === 'undefined') {
                var script = document.querySelector('script[data-rawaea-qrcode="1"]');
                if (script && (script.dataset.qrLoadState === 'failed' ||
                    script.dataset.qrLoadState === 'loaded')) {
                    script.remove();
                    script = null;
                }

                await new Promise(function (resolve, reject) {
                    var target = script;
                    var settled = false;

                    function finish(ok, error) {
                        if (settled) return;
                        settled = true;
                        if (target) {
                            target.removeEventListener('load', onLoad);
                            target.removeEventListener('error', onError);
                        }
                        if (ok && typeof QRCode !== 'undefined') {
                            if (target) target.dataset.qrLoadState = 'loaded';
                            resolve();
                        } else {
                            if (target) {
                                target.dataset.qrLoadState = 'failed';
                                target.remove();
                            }
                            reject(error || new Error('تعذر تحميل مكتبة إنشاء QR'));
                        }
                    }

                    function onLoad() {
                        finish(typeof QRCode !== 'undefined',
                            typeof QRCode === 'undefined'
                                ? new Error('تم تحميل الملف لكن مكتبة QR غير متاحة')
                                : null);
                    }

                    function onError() {
                        finish(false, new Error('تعذر تحميل مكتبة إنشاء QR'));
                    }

                    if (!target) {
                        target = document.createElement('script');
                        target.src = 'https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js';
                        target.async = true;
                        target.dataset.rawaeaQrcode = '1';
                        target.dataset.qrLoadState = 'loading';
                    }

                    target.addEventListener('load', onLoad, { once: true });
                    target.addEventListener('error', onError, { once: true });
                    if (!target.isConnected) document.head.appendChild(target);
                });
            }

            if (typeof QRCode === 'undefined') throw new Error('مكتبة QR غير متاحة بعد التحميل');

            await Swal.fire({
                title: 'رمز QR — ' + String(item.account_name || 'الخزينة'),
                width: 560,
                html:
                    '<div class="text-center space-y-3">' +
                        '<div class="rounded-xl border bg-gray-50 p-4">' +
                            '<div id="treasury-qr-container" class="flex justify-center min-h-[250px] items-center"></div>' +
                        '</div>' +
                        '<div class="text-right rounded-lg bg-blue-50 border border-blue-100 p-3 text-sm">' +
                            '<div><strong>الحساب:</strong> ' + _esc(item.account_name || '') + '</div>' +
                            '<div><strong>الكود:</strong> ' + _esc(item.account_code || '') + '</div>' +
                            '<div><strong>النوع:</strong> ' + (item.type === 'Cash' ? 'خزينة نقدية' : 'بنك') + '</div>' +
                            '<p class="mt-2 text-xs text-gray-600">هذا الرمز يعرّف الخزينة فقط ولا يمنح صلاحية دخول أو تنفيذ مالي. عند مسحه يجب على تطبيق الكاشير التحقق من جلسة المستخدم والشركة وصلاحية الربط من الخادم.</p>' +
                        '</div>' +
                        '<div class="text-xs text-gray-500 break-all">هوية الخزينة: ' + _esc(item.id) + '</div>' +
                    '</div>',
                confirmButtonText: 'تم',
                didOpen: function () {
                    var container = document.getElementById('treasury-qr-container');
                    if (!container) return;
                    container.innerHTML = '';
                    new QRCode(container, {
                        text: payload,
                        width: 240,
                        height: 240,
                        colorDark: '#111827',
                        colorLight: '#ffffff',
                        correctLevel: QRCode.CorrectLevel.M
                    });
                }
            });
            return true;
        } catch (e) {
            if (!suppressErrorToast) _showToast((e && e.message) || 'تعذر إنشاء رمز QR للخزينة', 'error');
            return false;
        }
    }

- يجب أن يبقى التصدير الموجود _showTreasuryQR: _showTreasuryQR في كائن RW_Finance. لا تضف تصديرًا ثانيًا.
- لا تعتبر company_id في QR إثبات صلاحية. يجب أن يستخرج الخادم شركة المستخدم من جلسة المصادقة ويطابقها مع الشركة المالكة للخزينة عند تنفيذ أي ربط.

## Production / Supabase
لم أغير schema أو ACL أو بيانات Production؛ لا حاجة لذلك لعرض QR وتوسيع المودال. لم أنشئ fixtures. لم أنشر main.html.

## الاختبارات المطلوبة
1. إنشاء خزينة صفرية الرصيد: حفظ مرة واحدة، ثم QR؛ إذا فشل CDN يجب أن يبقى الحفظ ناجحًا وتظهر رسالة تفصل نجاح الحفظ عن فشل QR.
2. إعادة محاولة عرض QR بعد فشل تحميل المكتبة: لا انتظار دائم، ويظهر QR عند نجاح المحاولة.
3. بعد reload، QR يحمل treasury_id نفسه.
4. عرض المودال على شاشة كبيرة وصغيرة دون قص الحقول أو أزرار الحفظ.
5. تعديل خزينة لا يغير id أو الرصيد ولا يضيف cash_box أو pos_shifts.
6. لا تدّعِ أن QR scan يربط POS تلقائيًا قبل مراجعة consumer الحالي واختبار ربط مصادق عليه من HTTP إلى DB.

## FINAL CLOSURE STATUS
CURRENT GIT QR FEATURE VERIFIED / MODAL WIDTH CHANGE REQUIRED / QR FAILURE FEEDBACK DEFECT IDENTIFIED / PRODUCTION RPC CONTRACT VERIFIED / OWNER PATCH + DEPLOYMENT + BROWSER E2E OPEN

## SELF-AUDIT FINAL
- **What I Proved:** QR feature موجودة في Git؛ العرض 920؛ RPCs الحالية تتحقق من auth/company context؛ لم تتغير بيانات Production.
- **What I Did Not Prove:** جسم main.html كاملًا في هذه الدورة، تطابق Cloudflare، اختبار المتصفح، وربط POS عند المسح.
- **What I Fixed:** جهزت تعديلًا جراحيًا للعرض، والرسائل، وإعادة محاولة تحميل QR.
- **What I Initially Missed:** QR helper يمسك الخطأ ثم يسمح برسالة نجاح لاحقة، كما أن عنصر script الفاشل قد يفسد إعادة المحاولة.
- **What Could Still Be Wrong:** قد تختلف النسخة المنشورة عن Git؛ Consumer POS لم يُثبت بعد.
- **Final Confidence:** مرتفع في تحليل diff؛ التحقق التشغيلي ينتظر تطبيق المالك ونشره.
- **Final Closure Status:** OWNER CHANGESET READY — NOT CLOSED UNTIL APPLIED, DEPLOYED, AND BROWSER-VERIFIED.
