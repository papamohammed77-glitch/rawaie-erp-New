# Report 79 — إغلاق M5-13 في main5 وربط دورة الرانشيت بالـProduction

**التاريخ:** 2026-09-08
**المستودع:** `papamohammed77-glitch/rawaie-erp-New`
**الفرع:** `main`
**Production:** `SMART ERP / fiilmooggumokxanwiyx`
**الوحدة:** `Current/PWA/main2/main5.md`

## 1. نقطة البداية

تم اعتماد Report78 وCURRENT_STATE كحالة البداية، وكانت M5-13 هي العائق الوحيد أمام انتقال main5 إلى الجزء التالي.

Report78 أثبت أن المصدر الحالي لـmain5 يحتوي ثلاث عمليات مباشرة من الواجهة:

- `preConfirm` يكتب إلى `runsheets` مباشرة، ولا يفحص `result.error`.
- `_deleteRunsheet` ينفذ تحديث `orders` ثم حذف `run_sheet_details` ثم حذف `runsheets` كعمليات منفصلة.
- `_cancelRunsheet` ينفذ تحديث `runsheets` ثم `orders` ثم حذف `run_sheet_details` كعمليات منفصلة.

المصدر الحالي بقي دون تعديل من المساعد، وفق قاعدة المشروع التي تنص على أن المستخدم ينفذ التعديلات الجراحية داخل الأجزاء الـ11.

## 2. التحقق من Production قبل الإصلاح

تم فحص Production مباشرة، وثبت الآتي:

- `runsheets` لديها RLS للـUPDATE/DELETE مرتبط بصلاحية `runsheets` وسياق الشركة.
- `start-picking` يسمح ببدء التحضير فقط عندما تكون الحالة `Open` أو `Confirmed`.
- `create_runsheet_atomic` منشور كـcore capability وينشئ الرانشيت في حالة `Open` ويربط الأوردرات ويولد `run_sheet_details`.
- `force-unassign-runsheet` ليس بديلًا لعقد M5-13 لأنه يتعامل فقط مع سحب رانشيت في حالة `Delivering` ويعيده إلى `Loaded`.
- لا توجد قبل هذه الجلسة Capability canonical واحدة مسؤولة عن UPDATE/CANCEL/DELETE للرانشيت.
- Triggers التدقيق الحالية على `runsheets` و`orders` تستخدم `fn_audit_trigger()`؛ لذلك عمليات الـbackend الجديدة تبقى قابلة للتدقيق. وتم ضبط `request.jwt.claims` داخل الـRPC لتثبيت `p_user_email` كفاعل للعملية داخل مسار التدقيق.

## 3. القرار المعماري

بدل إنشاء ثلاث دوال أو ثلاث ترقيعات، تم إنشاء Capability موحدة:

`manage_runsheet_atomic`

والعمليات المسموحة داخلها هي:

`UPDATE`
`CANCEL`
`DELETE`

الـRPC:

- `SECURITY DEFINER`
- `search_path = public`
- محصور التنفيذ على `service_role`
- لا يملك `anon` أو `authenticated` صلاحية EXECUTE
- يعمل بـcompany_id + runsheet_code
- يقفل الرانشيت بـ`FOR UPDATE`
- يرفض أي عملية على حالة غير `Open/Confirmed`
- يرفض DELETE/CANCEL إذا كان أي Order قد تجاوز `Pending/Confirmed`
- يرفض DELETE/CANCEL إذا كان هناك `qty_picked` أو `qty_loaded` أو `qty_delivered` أو `qty_refused` أو `qty_returned` أو `driver_liability` غير صفرية
- في UPDATE يتحقق من أن السائق والمركبة يتبعان نفس الشركة
- UPDATE يحافظ على الحالة الحالية؛ لا يعيد `Confirmed` إلى `Open`
- CANCEL يفك ربط الأوردرات ويعيدها إلى `Confirmed` ويحذف التفاصيل ويجعل الرانشيت `Cancelled`
- DELETE يفك ربط الأوردرات ويعيدها إلى `Confirmed` ويحذف التفاصيل ثم يحذف الرانشيت بالكامل
- كل ذلك في Transaction واحدة

## 4. Capability HTTP

تم إنشاء Edge Function:

`manage-runsheet`

Production deployment:

`ACTIVE v1`

وتستخدم:

- Supabase Auth
- `users.auth_id`
- `users.company_id`
- `users.permissions`
- Owner semantics (`isOwner === true` + `owner_profile` + license state)
- صلاحية `runsheets` أو `*`
- ثم تستدعي `manage_runsheet_atomic`

وبذلك أصبح المتصفح لا يحتاج أي كتابة مباشرة على `runsheets/orders/run_sheet_details` لهذه العمليات.

## 5. الاختبارات المنفذة على Production

### UPDATE → CANCEL

تم إنشاء رانشيت اختبار مؤقت وحالة `Confirmed` داخل Transaction.

تم تنفيذ:

`UPDATE`
ثم:
`CANCEL`

النتيجة المثبتة:

- العملية نجحت.
- الأوردر أصبح `Confirmed`.
- `runsheet_id` أصبح `NULL`.
- تم إنهاء حالة الرانشيت إلى `Cancelled`.
- تم تنفيذ `ROLLBACK` كامل، وبالتالي لم تبقَ بيانات الاختبار في Production.

### DELETE

تم إنشاء رانشيت اختبار مؤقت مع Order مرتبط.

تم تنفيذ `DELETE`.

النتيجة:

- الرانشيت حُذف بنجاح.
- الأوردر أصبح `Confirmed`.
- `runsheet_id = NULL`.
- تم تنفيذ `ROLLBACK` كامل.

### Execution Guard

تم إنشاء رانشيت اختبار مؤقت مع `run_sheet_details.qty_picked = 1`.

محاولة `CANCEL` رُفضت بواسطة الـRPC.

وبعد الرفض بقي:

`status = Open`

والتفاصيل بقيت موجودة.

هذا يثبت عدم وجود حذف/إلغاء جزئي عندما تكون دورة التنفيذ قد بدأت.

### Tenant Guard

تم اختبار استدعاء الـRPC بسياق شركة غير موجود.

تم رفض العملية كما هو متوقع.

كما تم التحقق أن:

`anon EXECUTE = false`
`authenticated EXECUTE = false`
`service_role EXECUTE = true`

## 6. الملاحظة الخاصة بـMaster

تم البحث في `main` عن الملف بالاسم الحرفي:

`MASTER - RAWAEA ERP.md`

وكذلك variants الشائعة للاسم داخل المستودع الحالي، ولم يمكن resolve ملف بهذا الاسم في النسخة الحالية المتاحة من GitHub.

لذلك لا يتم الادعاء بأنه تم فتح ملف غير موجود. تم الاعتماد على Report78 وCURRENT_STATE والمصادر الأصلية وProduction الحالية بدل اختراع محتوى مفقود.

## 7. الملفات التي تم تعديلها فعليًا

### Production / Git

`supabase/migrations/20260908050000_manage_runsheet_atomic_capability_m5_13.sql`

`Current/Edge_Functions/manage-runsheet/index.ts`

### لم يتم تعديل

`Current/PWA/main2/main5.md`

طبقًا لقاعدة المشروع، تعليمات تعديل main5 أدناه هي جراحية وينفذها المستخدم بنفسه.

## 8. التعليمات الجراحية لـmain5

### M5-13-A — preConfirm

ابحث عن المقطع الذي يبدأ حرفيًا بـ:

`preConfirm: function() {`

داخل `Swal.fire({ ... })` في دالة `_details(code)`.

احذف **المقطع كاملًا** من:

`preConfirm: function() {`

وحتى السطر:

`            },`

الذي يأتي مباشرة قبل:

`            didOpen: function() {`

واستبدله بالمقطع التالي كاملًا:

```javascript
            preConfirm: async function() {
                var newDriver = document.getElementById('rs-driver-select').value;
                var newVehicle = document.getElementById('rs-vehicle-select').value;
                showLoader('جاري تحديث الرانشيت...');
                try {
                    var ses = await supabase.auth.getSession();
                    var t = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
                    if (!t) {
                        Swal.showValidationMessage('انتهت الجلسة. يرجى إعادة تسجيل الدخول.');
                        return false;
                    }

                    var res = await fetch(RW_SUPABASE_URL + '/functions/v1/manage-runsheet', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            Authorization: 'Bearer ' + t
                        },
                        body: JSON.stringify({
                            operation: 'UPDATE',
                            runsheet_code: rs.runsheet_code || code,
                            driver_id: newDriver || null,
                            vehicle_id: newVehicle || null
                        })
                    });

                    var json = await res.json().catch(function() { return {}; });
                    if (!res.ok || !json.success) {
                        Swal.showValidationMessage(json.msg || 'فشل تحديث الرانشيت');
                        return false;
                    }

                    rs.driver_id = json.driver_id || null;
                    rs.vehicle_id = json.vehicle_id || null;
                    rs.status = json.status || rs.status;

                    for (var k = 0; k < data.length; k++) {
                        if (data[k].id === rs.id) {
                            data[k].driver_id = rs.driver_id;
                            data[k].vehicle_id = rs.vehicle_id;
                            data[k].status = rs.status;
                            break;
                        }
                    }

                    _apply();
                    showToast('تم تحديث الرانشيت بنجاح', 'success');
                    return true;
                } catch (e) {
                    Swal.showValidationMessage('فشل التحديث: ' + (e.message || 'خطأ غير معروف'));
                    return false;
                } finally {
                    hideLoader();
                }
            },
```

### M5-13-B — _deleteRunsheet

ابحث عن العنصر الذي يبدأ حرفيًا بـ:

`    async function _deleteRunsheet(code) {`

واحذف **الدالة كاملة** حتى آخر `}` لها مباشرة قبل السطر الذي يبدأ بـ:

`    async function _cancelRunsheet(code) {`

أي أن آخر سطر في العنصر القديم الذي تحذفه هو:

`    }`

المباشر قبل:

`    async function _cancelRunsheet(code) {`

واستبدل الدالة كاملة بالمقطع التالي:

```javascript
    async function _deleteRunsheet(code) {
        var found = null;
        for (var i = 0; i < data.length; i++) {
            if (data[i].runsheet_code === code) { found = data[i]; break; }
        }
        if (!found) { showToast('الرانشيت غير موجود', 'error'); return; }

        var cf = await Swal.fire({
            title: 'تأكيد الحذف',
            text: 'سيتم حذف الرانشيت ' + code + ' وتحرير جميع الأوردرات المرتبطة. متابعة؟',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'نعم، احذف',
            cancelButtonText: 'تراجع',
            confirmButtonColor: '#dc2626'
        });
        if (!cf.isConfirmed) return;

        var ses = await supabase.auth.getSession();
        var t = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
        if (!t) { showToast('انتهت الجلسة. يرجى إعادة تسجيل الدخول.', 'error'); return; }

        showLoader('جاري حذف الرانشيت...');
        try {
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/manage-runsheet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: 'Bearer ' + t
                },
                body: JSON.stringify({
                    operation: 'DELETE',
                    runsheet_code: code
                })
            });

            var json = await res.json().catch(function() { return {}; });
            if (!res.ok || !json.success) {
                throw new Error(json.msg || 'فشل حذف الرانشيت');
            }

            for (var o = 0; o < ordersData.length; o++) {
                if (ordersData[o].runsheet_id === found.id) {
                    ordersData[o].runsheet_id = null;
                    ordersData[o].order_status = 'Confirmed';
                }
            }

            var idx = data.indexOf(found);
            if (idx > -1) data.splice(idx, 1);

            _apply();
            showToast('تم حذف الرانشيت وتحرير الأوردرات بنجاح', 'success');
        } catch (e) {
            showToast('فشل الحذف: ' + (e.message || 'خطأ غير معروف'), 'error');
        } finally {
            hideLoader();
        }
    }
```

### M5-13-C — _cancelRunsheet

ابحث عن العنصر الذي يبدأ حرفيًا بـ:

`    async function _cancelRunsheet(code) {`

واحذف **الدالة كاملة** حتى آخر `}` لها مباشرة قبل السطر:

`    function _changeStatus(code, funcName) {`

أي أن آخر سطر في العنصر القديم الذي تحذفه هو:

`    }`

المباشر قبل:

`    function _changeStatus(code, funcName) {`

واستبدله بالدالة التالية كاملة:

```javascript
    async function _cancelRunsheet(code) {
        var found = null;
        for (var i = 0; i < data.length; i++) {
            if (data[i].runsheet_code === code) { found = data[i]; break; }
        }
        if (!found) { showToast('الرانشيت غير موجود', 'error'); return; }

        if (found.status !== 'Open' && found.status !== 'Confirmed') {
            showToast('لا يمكن إلغاء رانشيت في حالة: ' + found.status, 'error');
            return;
        }

        var cf = await Swal.fire({
            title: 'إلغاء الرانشيت',
            text: 'سيتم إلغاء الرانشيت ' + code + ' وتحرير جميع الأوردرات المرتبطة.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'نعم، إلغاء',
            cancelButtonText: 'تراجع',
            confirmButtonColor: '#dc2626'
        });
        if (!cf.isConfirmed) return;

        var ses = await supabase.auth.getSession();
        var t = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
        if (!t) { showToast('انتهت الجلسة. يرجى إعادة تسجيل الدخول.', 'error'); return; }

        showLoader('جاري إلغاء الرانشيت...');
        try {
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/manage-runsheet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: 'Bearer ' + t
                },
                body: JSON.stringify({
                    operation: 'CANCEL',
                    runsheet_code: code
                })
            });

            var json = await res.json().catch(function() { return {}; });
            if (!res.ok || !json.success) {
                throw new Error(json.msg || 'فشل إلغاء الرانشيت');
            }

            for (var o = 0; o < ordersData.length; o++) {
                if (ordersData[o].runsheet_id === found.id) {
                    ordersData[o].runsheet_id = null;
                    ordersData[o].order_status = 'Confirmed';
                }
            }

            var idx = data.indexOf(found);
            if (idx > -1) data.splice(idx, 1);

            _apply();
            showToast('تم إلغاء الرانشيت وتحرير الأوردرات بنجاح', 'success');
        } catch (e) {
            showToast('فشل الإلغاء: ' + (e.message || 'خطأ غير معروف'), 'error');
        } finally {
            hideLoader();
        }
    }
```

## 9. نتيجة هذه الجلسة

### Production

`M5-13 backend capability = CLOSED`

`Production runtime RPC tests = PASS`

`Tenant execution isolation = PASS`

`Execution guard = PASS`

`UPDATE/CANCEL/DELETE atomicity = PASS in transactional tests`

### Source

`main5.md = NOT MODIFIED BY ASSISTANT`

وهذا مقصود حسب بروتوكول المشروع.

بعد تطبيق المستخدم للثلاثة Blocks أعلاه، يلزم إعادة قراءة `main5.md` من البداية إلى EOF وفحص syntax + structure + direct DB writes + consumer references.

## 10. Final self-audit

### What I Proved

- Report78 state was re-opened and matched with current Production.
- M5-13 direct-write defect was re-confirmed from source.
- Production lacked a canonical UPDATE/CANCEL/DELETE capability before this session.
- New atomic backend capability now exists and is deployed.
- New authenticated Edge capability now exists and is deployed.
- RPC is inaccessible to `anon` and `authenticated` directly.
- UPDATE/CANCEL/DELETE behavior was transactionally tested.
- Operations are prevented after fulfillment has started.
- Global Production counts returned to the exact pre-test state: companies=1, users=24, branches=2, items=17, orders=0, runsheets=0, order_details=0, run_sheet_details=0, stock_rows=20, inventory_logs=3.

### What I Did Not Prove

- Browser E2E through an authenticated human session for main5, because Production currently has zero orders and zero runsheets.
- Final syntax of `main5.md` after the user's application of the blocks.
- Full 11-part PWA assembly equivalence.

### Final Status

`M5-13 BACKEND = CLOSED`

`MAIN5 SOURCE = PENDING USER APPLICATION OF THREE SURGICAL BLOCKS`

`MAIN5 FINAL RELEASE GATE = OPEN AFTER USER PATCH + FULL EOF RECHECK`

لا يوجد ادعاء كاذب بأن main5 أصبحت مغلقة 100% قبل تطبيق التعديلات المصدرية وإعادة فحصها.
