# Report434 — تكامل POS مع الجهاز والخزينة الثابتة — 2026-10-17

## PRE-CHANGE SELF-AUDIT

**Business Understanding:** حساب الكاشير يمثل الموظف الذي ينفذ البيع، وليس الجهاز أو درج النقد. يجب السماح للموظف بتسجيل الدخول على أكثر من جهاز، مع بقاء كل جهاز ثابت الهوية ومربوطًا بخزينة محددة. لا يجوز أن يؤدي تبديل المستخدم إلى تبديل الخزينة أو نقل وردية مفتوحة.

**Architecture Understanding:** POS PWA → authenticated PostgreSQL RPCs للتهيئة والوردية؛ بيع POS الفعلي يظل عبر مسار البيع المركزي الحالي ولا تُمنح الواجهة صلاحية تنفيذ محرك البيع مباشرة. لا حاجة إلى Edge Function جديدة، وهو مهم بسبب حد وظائف Edge في المشروع.

**Database Understanding:** Production يحتوي بالفعل على `pos_terminals`, `pos_shifts`, `pos_shift_events`, `pos_shift_cash_counts` و`treasury`. `pos_shifts` يربط `cashier_user_id`, `terminal_id`, `treasury_id`. كان `pos_terminals` يفتقد علاقة خزينة ثابتة.

**Historical Understanding:** راجعت `CURRENT_STATE.md`، تقرير POS السابق Report426، وتقرير QR الأخير Report433، ثم قارنتها بالمصدر الحي وقاعدة البيانات. التقارير السابقة أدلة تاريخية وليست مرجع الحالة النهائية.

**Production Understanding:** فحصت Production مباشرة في المشروع `fiilmooggumokxanwiyx`، ثم أضفت عمود الربط وRPC مصادقًا عليه، وحصّنت `pos_open_shift`، وأعدت الاستعلام بعد التغيير.

**Current Understanding:** المصدر التشغيلي الحالي في GitHub هو `erp-frontend/companies/company-1/sales/pos.html`, SHA `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d`، 111,290 حرفًا / 1,904 أسطر. لم أعدّل `main.html` أو `pos.html`.

**Execution Confidence:** مرتفع في تشخيص فجوة العقد وتعديل Production واختبارات SQL المعزولة؛ غير كافٍ لإعلان إغلاق الواجهة لأن التعديل الجراحي في PWA ما زال على المالك، ولم يُنفّذ Browser/HTTP E2E كامل من جلسة مستخدم حقيقية في هذه الدورة.

### Confirmed Facts

- Production وقت التحقق: `2026-10-16 22:02:07 UTC`.
- عدد الخزائن النشطة المرصود: 3؛ منها خزينة عامة `الخزينة الرئيسية` وخزينتان مربوطتان بالفرع `كاشير1 - الفرع الرئيسي` و`كاشير2-الفرع الرئيسي`.
- قبل التعديل كان `pos_open_shift` يختار الخزينة تلقائيًا فقط إذا كان عدد الخزائن النشطة للشركة يساوي واحدًا، بينما `pos.html` يرسل `p_treasury_id: null`. مع ثلاث خزائن، جهاز جديد غير مهيأ سيفشل برسالة `SHIFT_TREASURY_SELECTION_REQUIRED`.
- كانت `pos_terminals` بلا `treasury_id`; لذلك لم يكن هناك عقد دائم على مستوى الجهاز يثبت الخزينة.
- `main.html` يحتوي بالفعل مولد QR في `RW_Finance._showTreasuryQR`. حمولة QR من الشكل `{type:"rawaea_treasury", version:1, company_id, treasury_id}`. لم أغيّر `main.html`.
- POS الحالي لا يحتوي Consumer يقرأ QR الخزينة ولا يستدعي `pos_bind_terminal_treasury`.
- Production قبل التعديل كان يحتوي محطة واحدة ووردية واحدة وحدث وردية واحدًا و6 سجلات `cash_box`. الوردية المفتوحة الحالية تبقى مرتبطة بالخزينة الرئيسية؛ لم أغير الوردية أو الخزينة أو سجلات النقد.
- `pos_open_shift` كانت متاحة لـ`authenticated` ومرفوضة لـ`anon`. بقيت هذه الحدود بعد التعديل.

### Unknowns / Conflicts / Unverified Claims

- **تم حسم الفجوة البنيوية:** الجهاز لم يكن مرتبطًا بخزينة دائمة في الجدول؛ أضيفت العلاقة.
- **تم حسم فجوة الأمان:** لا يستطيع كاشير عادي إنشاء/إعادة ربط جهاز بخزينة باختيار معرف مرسل من المتصفح؛ إعداد الربط يتطلب Owner أو `general_manager` أو `cash_manager` مع صلاحية الوصول إلى POS/الفرع.
- **UNVERIFIED:** لم يتم تطبيق التعديل الجراحي في ملف POS، لأن تعليمات المشروع تقضي بأن يطبقه المالك.
- **UNVERIFIED:** لم يُثبت بعد مسح QR فعليًا من الكاميرا في المتصفح، ولا Browser/HTTP E2E بعد نشر واجهة POS.
- **UNVERIFIED:** لا يوجد ادعاء بأن ملف Git يطابق ملف Cloudflare Pages المخدوم؛ لم تُجرَ مقارنة artifact served في هذه المهمة.

## 1. السبب الجذري

المشكلة ليست في غياب مفهوم الوردية؛ بل في عدم وجود هوية ثابتة للخزينة على مستوى الجهاز:

1. `localStorage.rawaea_pos_terminal_code` يولد هوية جهاز في المتصفح.
2. `pos_open_shift` ينشئ/يعثر على `pos_terminals` حسب `company_id + terminal_code`.
3. الخزينة كانت تُحسم عند فتح الوردية فقط، وليس على سجل الجهاز.
4. كان المتصفح يرسل `p_treasury_id: null`.
5. بعد إضافة خزائن متعددة، لم يعد الاختيار التلقائي ممكنًا؛ وحتى عند نجاح وردية واحدة لم يكن العقد يمنع ربط نفس الجهاز بخزينة مختلفة في دورة لاحقة.

**العقد الصحيح:** `Cashier User ≠ Physical POS Terminal ≠ Treasury`. كل وردية تربط الثلاثة، لكن `pos_terminals.treasury_id` هو الربط الثابت للجهاز، ولا يحق للكاشير تغييره.

## 2. ما نُفّذ فعليًا في Production

### Migration 1

- Git file: `supabase/migrations/20261016220000_pos_terminal_treasury_binding.sql`
- Commit: `a7906e063da2db614eddd876668258454a0976d6`
- Production migration: `pos_terminal_treasury_binding_20261016`
- أضيف `pos_terminals.treasury_id` مع FK إلى `treasury(id)`.
- تمت تعبئة الربط التاريخي فقط عندما كانت كل ورديات الجهاز تستخدم خزينة واحدة. لم تُغيّر مبالغ أو ورديات أو سجلات مالية.
- عُدّلت `pos_open_shift` كي تستخدم خزينة الجهاز المثبتة، وتتحقق من الشركة والفرع وحالة الخزينة، وترفض عدم التطابق.

### Migration 2

- Git file: `supabase/migrations/20261016221000_pos_terminal_manager_binding_guard.sql`
- Commit: `0bdb2bfa9573d3532cec63d5bd9b1d4fb696efff`
- Production migration: `pos_terminal_manager_binding_guard_20261016`
- أضيفت `public.pos_bind_terminal_treasury(uuid,text,uuid,text)` كـRPC مصادق عليه، بلا Edge Function جديدة.
- الـRPC يتحقق من المستخدم النشط، الشركة، صلاحية Owner/مدير عام/مدير خزينة، الفرع المسموح، والخزينة النشطة التابعة للشركة والفرع.
- يمنع إعادة ربط جهاز له سجل ورديات بخزينة أخرى.
- `pos_open_shift` يرفض تمرير خزينة صريحة لإنشاء/تهيئة جهاز غير مربوط؛ الربط الأولي يمر عبر RPC الإعداد المقيّد بالصلاحيات.

### Migration 3

- Git file: `supabase/migrations/20261016222000_pos_terminal_bind_idempotency_fix.sql`
- Commit: `81e0826260c99a0f6ba9971907767d25a682c28c`
- Production migration: `pos_terminal_bind_idempotency_fix_20261016`
- صُحح مؤشر `duplicate` في استجابة RPC بحيث لا يصنف إنشاء جهاز جديد على أنه تكرار.

### Production ACL

- `pos_bind_terminal_treasury`: `anon EXECUTE=false`, `authenticated EXECUTE=true`.
- `pos_open_shift`: `anon EXECUTE=false`, `authenticated EXECUTE=true`.
- لا توجد Edge Function جديدة، ولا منح مباشر لكتابة جدول `treasury`، ولا تغيير في `cash_box` أو قيود المحاسبة.

## 3. اختبارات Production المنفذة

| الاختبار | النتيجة |
|---|---|
| إضافة عمود ربط الجهاز بالخزينة وFK | PASS |
| الحفاظ على ربط الجهاز الحالي بالوردية المفتوحة والخزينة الرئيسية | PASS |
| إعادة طلب فتح الوردية نفسها بنفس `operation_id` | PASS — رجعت `duplicate=true` والوردية نفسها |
| محاولة تمرير خزينة مختلفة إلى جهاز مربوط | PASS — رُفضت بـ`SHIFT_TERMINAL_TREASURY_MISMATCH` |
| محاولة كاشير عادي تنفيذ ربط خزينة لجهاز | PASS — رُفضت بـ`POS_TERMINAL_CONFIGURATION_PERMISSION_REQUIRED` |
| اختبار SQL داخل Transaction ثم `ROLLBACK` | PASS — لا أثر دائم |
| Baseline بعد الاختبار | PASS — `pos_terminals=1`, `pos_shifts=1`, `pos_shift_events=1`, `cash_box=6`, `test_terminal_residue=0` |
| HTTP/Browser E2E بالكاميرا وواجهة POS | UNVERIFIED — يحتاج تطبيق Patch المالك والنشر واختبار المتصفح |

لم يتم إغلاق الوردية الحالية أو تعديلها. لم تُنشأ فاتورة أو حركة نقدية اختبارية دائمة.

## 4. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | قبل | بعد |
|---|---|---|
| هوية الموظف | `cashier_user_id` في الوردية | RETAINED |
| هوية الجهاز | `terminal_code` من المتصفح | RETAINED |
| خزينة الجهاز الثابتة | لا توجد على `pos_terminals` | ADDED: `pos_terminals.treasury_id` |
| ربط الخزينة بالوردية | `pos_shifts.treasury_id` | RETAINED + VALIDATED |
| اختيار الخزينة | اختيار ضمني عندما توجد خزينة واحدة | HARDENED: ربط إداري ثابت، والتحقق من الشركة والفرع |
| تغيير الخزينة بعد وجود تاريخ | لم يكن هناك عقد ثابت للجهاز | BLOCKED BY CONTRACT: `POS_TERMINAL_TREASURY_HISTORY_LOCKED` |
| فتح الوردية | RPC الحالي | RETAINED + HARDENED |
| Edge Functions | غير مطلوب | لا Function جديدة |
| محرك البيع/المخزون/المحاسبة | المسار المركزي القائم | RETAINED — لا تعديل |
| QR من النظام الأم | مُولّد فقط | يبقى مولدًا؛ Consumer المسح في POS مطلوب من المالك |

## 5. التعديل الجراحي المطلوب من المالك — ملف POS فقط

**الملف:** `erp-frontend/companies/company-1/sales/pos.html`  
**SHA قبل التعديل:** `5f2ad2fa52c2c63d9e307cbaa27f6455351f738d`  
**لا تعدّل `main.html`، ولا تنفّذ Patch إذا تغيّر SHA. أعد جلب المصدر أولًا.**

### Patch A — إضافة زر ربط الخزينة إلى نافذة الوردية

ابحث داخل `#posShiftOpenPanel` عن هذا المقطع:

```html
      <div id="posShiftOpenPanel" class="space-y-3">
        <p class="text-sm text-slate-300">اختر الفرع أولًا، ثم سجّل النقدية الموجودة فعليًا في بداية الوردية.</p>
        <label class="block text-xs text-slate-400">العهدة الافتتاحية</label>
        <input id="posShiftOpeningFloat" type="number" min="0" step="0.01" value="0" class="w-full p-3 rounded-lg bg-slate-800 border border-slate-600 text-white">
        <button type="button" onclick="POS.startShift()" class="w-full p-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-black">بدء الوردية</button>
      </div>
```

استبدله كاملًا بهذا:

```html
      <div id="posShiftOpenPanel" class="space-y-3">
        <p class="text-sm text-slate-300">هوية الموظف منفصلة عن الجهاز. اربط الجهاز بالخزينة الثابتة مرة واحدة قبل فتح أول وردية عليه.</p>
        <button type="button" onclick="POS.bindTerminalTreasuryQR()" class="w-full p-3 rounded-xl bg-violet-700 hover:bg-violet-600 text-white font-black">
          <i class="fa-solid fa-qrcode ml-2"></i>ربط هذا الجهاز بخزينة ثابتة عبر QR
        </button>
        <p class="text-[11px] text-slate-400">يجب مسح QR للخزينة من النظام الأم بحساب المالك أو مدير مخوّل. الربط يتحقق منه الخادم ولا يعتمد على قيمة محلية وحدها.</p>
        <label class="block text-xs text-slate-400">العهدة الافتتاحية</label>
        <input id="posShiftOpeningFloat" type="number" min="0" step="0.01" value="0" class="w-full p-3 rounded-lg bg-slate-800 border border-slate-600 text-white">
        <button type="button" onclick="POS.startShift()" class="w-full p-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-black">بدء الوردية</button>
      </div>
```

### Patch B — إدراج مستهلك QR وRPC الربط

**الموضع:** بعد الدالة `self._getShiftTerminalCode = function() { ... };` مباشرة (حاليًا قرب السطر 297)، وقبل `self._renderShiftState`.

أدرج الدالة كاملة:

```javascript
self.bindTerminalTreasuryQR = function() {
    var perms = currentUser && Array.isArray(currentUser.permissions) ? currentUser.permissions : [];
    var canConfigure = !!(currentUser && (
        currentUser.isOwner === true ||
        perms.indexOf('*') !== -1 ||
        perms.indexOf('general_manager') !== -1 ||
        perms.indexOf('cash_manager') !== -1
    ));

    if (!canConfigure) {
        RW_UI.toast('إعداد خزينة الجهاز يتطلب المالك أو مديرًا مخولًا', 'warning');
        return;
    }
    if (!selBranch || !branchMap[selBranch]) {
        RW_UI.toast('اختر الفرع المسموح أولًا', 'warning');
        return;
    }

    function applyPayload(raw) {
        var payload;
        try {
            payload = JSON.parse(String(raw || '').trim());
        } catch (e) {
            RW_UI.showError('محتوى QR ليس JSON صالحًا');
            return;
        }

        var uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        if (!payload || payload.type !== 'rawaea_treasury' ||
            Number(payload.version) !== 1 ||
            !uuidPattern.test(String(payload.treasury_id || ''))) {
            RW_UI.showError('رمز QR ليس رمز خزينة RAWAEA صالحًا');
            return;
        }

        RW_UI.showLoader('جاري التحقق من الخزينة وربط جهاز الكاشير...');
        supabase.rpc('pos_bind_terminal_treasury', {
            p_branch_id: branchMap[selBranch],
            p_terminal_code: self._getShiftTerminalCode(),
            p_treasury_id: String(payload.treasury_id),
            p_terminal_label: 'POS ' + selBranch
        }).then(function(res) {
            RW_UI.hideLoader();
            if (res.error || !res.data || res.data.success !== true) {
                var message = (res.error && res.error.message) || 'تعذر ربط الجهاز بالخزينة';
                if (message.indexOf('POS_TERMINAL_TREASURY_HISTORY_LOCKED') !== -1) {
                    message = 'هذا الجهاز له سجل ورديات سابق؛ لا يمكن تغيير خزينته. استخدم جهازًا جديدًا أو اطلب إجراء إعادة تهيئة معتمدًا.';
                } else if (message.indexOf('POS_TERMINAL_CONFIGURATION_PERMISSION_REQUIRED') !== -1) {
                    message = 'ليس لديك صلاحية إعداد أجهزة الكاشير والخزائن.';
                } else if (message.indexOf('SHIFT_TREASURY_NOT_ALLOWED') !== -1) {
                    message = 'الخزينة لا تتبع الشركة الحالية أو لا تتوافق مع الفرع المحدد.';
                }
                RW_UI.showError(message);
                return;
            }

            try {
                localStorage.setItem('rawaea_pos_terminal_treasury_id', String(res.data.treasury_id));
                localStorage.setItem('rawaea_pos_terminal_id', String(res.data.terminal_id));
            } catch (e) {}

            RW_UI.toast(
                res.data.duplicate
                    ? 'هذا الجهاز مربوط بالفعل بالخزينة المحددة'
                    : 'تم ربط جهاز الكاشير بالخزينة الثابتة بنجاح',
                'success'
            );
            self.loadShiftState();
        }).catch(function(err) {
            RW_UI.hideLoader();
            RW_UI.showError((err && err.message) || 'تعذر الاتصال بخدمة ربط جهاز الكاشير');
        });
    }

    function manualEntry() {
        Swal.fire({
            title: 'إدخال QR يدويًا',
            input: 'textarea',
            inputLabel: 'الصق النص الكامل الموجود داخل QR للخزينة',
            inputPlaceholder: '{"type":"rawaea_treasury","version":1,"company_id":"...","treasury_id":"..."}',
            showCancelButton: true,
            confirmButtonText: 'التحقق والربط',
            cancelButtonText: 'إلغاء',
            preConfirm: function(value) {
                if (!value || !String(value).trim()) {
                    Swal.showValidationMessage('أدخل محتوى QR');
                    return false;
                }
                return value;
            }
        }).then(function(result) {
            if (result.isConfirmed) applyPayload(result.value);
        });
    }

    if (!('BarcodeDetector' in window) ||
        !navigator.mediaDevices ||
        typeof navigator.mediaDevices.getUserMedia !== 'function') {
        manualEntry();
        return;
    }

    var detector;
    try {
        detector = new BarcodeDetector({ formats: ['qr_code'] });
    } catch (e) {
        manualEntry();
        return;
    }

    var stream = null;
    var scanning = false;
    var handled = false;

    function stopStream() {
        scanning = false;
        if (stream) {
            stream.getTracks().forEach(function(track) { track.stop(); });
            stream = null;
        }
    }

    Swal.fire({
        title: 'امسح QR الخزينة من النظام الأم',
        html: '<video id="posTreasuryQrVideo" style="width:100%;max-width:340px;border-radius:12px" playsinline></video><p class="text-xs mt-2">سيتم التحقق من الشركة والفرع والصلاحية في قاعدة البيانات.</p>',
        showCancelButton: true,
        showConfirmButton: false,
        cancelButtonText: 'إلغاء',
        customClass: { popup: '!bg-slate-900 !rounded-3xl !border !border-slate-700' },
        didOpen: function() {
            navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } })
                .then(function(cameraStream) {
                    stream = cameraStream;
                    var video = document.getElementById('posTreasuryQrVideo');
                    if (!video) {
                        stopStream();
                        return;
                    }
                    video.srcObject = stream;
                    video.play().then(function() {
                        scanning = true;
                        function scanLoop() {
                            if (!scanning || handled) return;
                            detector.detect(video).then(function(codes) {
                                if (!scanning || handled) return;
                                if (codes && codes.length && codes[0].rawValue) {
                                    handled = true;
                                    var raw = codes[0].rawValue;
                                    stopStream();
                                    Swal.close();
                                    applyPayload(raw);
                                    return;
                                }
                                requestAnimationFrame(scanLoop);
                            }).catch(function() {
                                if (scanning && !handled) requestAnimationFrame(scanLoop);
                            });
                        }
                        scanLoop();
                    }).catch(function() {
                        stopStream();
                        Swal.close();
                        RW_UI.toast('تعذر تشغيل كاميرا QR؛ استخدم الإدخال اليدوي', 'warning');
                        manualEntry();
                    });
                }).catch(function() {
                    stopStream();
                    Swal.close();
                    RW_UI.toast('تعذر الوصول للكاميرا؛ استخدم الإدخال اليدوي', 'warning');
                    manualEntry();
                });
        },
        willClose: stopStream
    });
};
```

ملاحظة أمنية: `company_id` داخل QR ليس تصريحًا ولا يُوثق به. الـRPC يتحقق من الشركة والخزينة والفرع والصلاحية من قاعدة البيانات. لا تضف صلاحية كتابة مباشرة على `pos_terminals` أو `treasury` للواجهة.

### Patch C — استبدال `self.startShift` بالكامل

**الموضع الحالي:** قرب الأسطر 373–405. ابحث عن `self.startShift = function() {` واستبدل الدالة كاملة حتى `};` المغلقة لها بهذا النص:

```javascript
self.startShift = function() {
    if (!selBranch || !branchMap[selBranch]) {
        RW_UI.toast('اختر الفرع أولًا', 'warning');
        return;
    }

    var opening = Number(RW_UI.byId('posShiftOpeningFloat').value);
    var op = self._newShiftOperationId();
    if (!isFinite(opening) || opening < 0 || !op) {
        RW_UI.showError('العهدة الافتتاحية أو هوية العملية غير صالحة');
        return;
    }

    RW_UI.showLoader('جاري فتح الوردية والتحقق من هوية الجهاز والخزينة...');
    supabase.rpc('pos_open_shift', {
        p_branch_id: branchMap[selBranch],
        p_terminal_code: self._getShiftTerminalCode(),
        p_opening_float: opening,
        p_operation_id: op,
        p_treasury_id: null,
        p_terminal_label: 'POS ' + selBranch
    }).then(function(res) {
        RW_UI.hideLoader();

        if (res.error || !res.data || res.data.success !== true) {
            var message = (res.error && res.error.message) || 'تعذر فتح الوردية';
            if (message.indexOf('SHIFT_TREASURY_SELECTION_REQUIRED') !== -1 ||
                message.indexOf('SHIFT_TERMINAL_CONFIGURATION_REQUIRED') !== -1) {
                message = 'هذا الجهاز غير مربوط بخزينة ثابتة. اربطه أولًا بمسح QR الخزينة من النظام الأم بحساب مخول.';
            } else if (message.indexOf('SHIFT_TERMINAL_TREASURY_MISMATCH') !== -1) {
                message = 'الخزينة المختارة لا تطابق الخزينة الثابتة لهذا الجهاز. لم تُفتح وردية ولم تُغيّر الخزينة.';
            } else if (message.indexOf('SHIFT_TERMINAL_BRANCH_MISMATCH') !== -1) {
                message = 'هذا الجهاز مسجل لفرع آخر. لا يمكن نقله بتغيير اختيار الفرع.';
            }
            RW_UI.showError(message);
            return;
        }

        self.loadShiftState(function(ok) {
            if (ok) {
                RW_UI.toast(
                    res.data.duplicate ? 'الوردية موجودة بالفعل' : 'تم فتح الوردية على الجهاز والخزينة المرتبطين',
                    'success'
                );
            }
        });
    }).catch(function(err) {
        RW_UI.hideLoader();
        RW_UI.showError((err && err.message) || 'تعذر فتح الوردية');
    });
};
```

### Patch D — لا تعِد تطبيق التغييرات التاريخية عميانيًا

المصدر الحالي ما زال يحتوي عناصر Report426 الأصلية غير المعدلة: اختيار الفرع في السطر 87، واختيار العميل في السطر 86، ونسخة `self.loadBranches` البسيطة قرب السطر 623. تقرير Report426 يحتوي التعديلات الجراحية السابقة A–F لعقد العميل النقدي والفرع. المصدر الحالي ما زال على SHA المستهدف القديم نفسه، لذلك لم يثبت أن المالك طبّقها. راجع [Report426](Report426_POS_BRANCH_CASH_CONTRACT_REPAIR_20261016.md) وطبّق فقط الأجزاء التي ما زالت مطابقة للمصدر الحالي؛ لا تكررها إذا تغير المصدر أو كانت مطبقة في نسخة أخرى.

## 6. Benchmark — نماذج عالمية موثقة

| النظام | ما يدعمه رسميًا | الدرس لـRAWAEA |
|---|---|---|
| Microsoft Dynamics 365 Commerce | يميز Register وDevice ومحطة الأجهزة، ويدعم جهاز دفع مخصصًا مع اختيار درج نقد/طابعة عند الحاجة. [Microsoft Learn](https://learn.microsoft.com/en-us/dynamics365/commerce/pos-multi-hws) | فصل هوية الجهاز عن المستخدم وعن الأجهزة الطرفية، وربط درج النقد بملف عتاد/محطة |
| SAP Customer Checkout | يدعم إدارة درج محلي أو مركزي؛ في الإدارة المركزية يمكن للمستخدم العمل على أجهزة POS مختلفة مع استمرار بيانات الدرج في النظام المركزي. [SAP Help](https://help.sap.com/docs/SAP_CUSTOMER_CHECKOUT/0c0627c1f3754c22929c8aea88b50cf6/1a82d5705e0b442c8e799627b98d2996.html) | لا تجعل سجل الدرج معتمدًا على المتصفح وحده؛ يجب أن يبقى مركزيًا وقابلًا للاسترداد |
| Oracle Retail Xstore | يدعم Register Accountability وTill Accountability، واختيار درج نقد عند وجود عدة أدراج. [Oracle Xstore](https://docs.oracle.com/en/industries/retail/retail-xstore-point-of-service/24.0/rpxmo/register-open-and-close.htm) | فصل مسؤولية الجهاز عن مسؤولية العهدة النقدية، مع فتح/إغلاق وعدّ واضح |
| Odoo POS | الجلسات تتضمن فتحًا وإغلاقًا وضبط نقدي، وتعرض المبالغ المتوقعة حسب وسيلة الدفع. [Odoo 18 POS](https://www.odoo.com/documentation/18.0/applications/sales/point_of_sale.html) و[Cash Control](https://www.odoo.com/documentation/14.0/applications/sales/point_of_sale/shop/cash_control.html) | استمرار الرقابة على الرصيد المتوقع والفعلي والفرق، لا الاكتفاء بتسجيل الفاتورة |

هذا Benchmark لعقود POS الرسمية، وليس ادعاءً بأن كل سلسلة هايبرماركت تستخدم المنتج نفسه.

## 7. ما لم يتغير

- لم أعدّل `main.html` أو `pos.html`.
- لم أعدّل الوردية المفتوحة أو الخزائن أو `cash_box`.
- لم أغيّر `save-sales-invoice` أو محرك المخزون/المحاسبة.
- لم أضف Edge Function.
- لم أمنح `anon` صلاحيات، ولم أفتح الكتابة المباشرة على الجداول.
- لم أدّعِ أن QR scanning أو Browser E2E نجح قبل تطبيق Patch المالك.

## SELF-AUDIT FINAL

**What I Proved**
- السبب الجذري: لا يوجد ربط خزينة دائم على سجل جهاز POS، مع أن الوردية نفسها تحمل معرف الخزينة.
- Production كان يحتوي ثلاث خزائن نشطة، ولذلك كان `p_treasury_id: null` غير كافٍ لجهاز جديد.
- أضيفت علاقة الخزينة بالجهاز، وRPC إعداد محمي، وحارس يمنع الكاشير من تغيير خزينة الجهاز، مع المحافظة على الوردية الحالية.
- اختبار إعادة فتح الوردية نفسها أعاد نفس `shift_id` كعملية مكررة.
- محاولة تغيير خزينة جهاز له وردية قائمة رُفضت، ومحاولة كاشير عادي لربط جهاز رُفضت.
- لم يبق أثر لبيانات الاختبار بعد `ROLLBACK`.

**What I Did Not Prove**
- لم أثبت Browser/HTTP E2E للكاميرا أو QR من واجهة POS.
- لم أثبت تطابق Cloudflare served artifact مع Git.
- لم أختبر مسار الربط الناجح بحساب مدير حي من واجهة المتصفح.

**What I Fixed**
- أضفت `pos_terminals.treasury_id` وFK.
- عدّلت `pos_open_shift` ليستخدم الخزينة المثبتة ويمنع اختلاف الشركة/الفرع والخزينة.
- أضفت `pos_bind_terminal_treasury` مع ACL آمن وصلاحيات إعداد إدارية.
- أصلحت دلالة `duplicate` في RPC الربط.

**What I Initially Missed**
- أول نسخة من RPC الربط كانت ستعيد `duplicate=true` عند إنشاء جهاز جديد؛ أضيفت Migration تصحيحية مستقلة وأُعيد نشرها قبل التقرير النهائي.

**What Could Still Be Wrong**
- قد تختلف واجهة POS المخدومة عن Git.
- قد لا يدعم متصفح/جهاز الكاشير `BarcodeDetector`; لذلك يحتوي Patch على إدخال QR يدوي كمسار احتياطي.
- يلزم اختبار فعلي لحساب Owner/مدير مخول، ثم كاشير، على جهاز جديد مع الخزينة المختارة.
- تغييرات Report426 في واجهة الفرع/العميل ما زالت غير ظاهرة في المصدر الحالي.

**Final Confidence:** مرتفع في Production DB/RPC contracts واختبارات SQL المعزولة؛ متوسط في التكامل الكامل حتى تطبيق Patch واختبار المتصفح.

**Final Closure Status:** `PRODUCTION DB/RPC REPAIR APPLIED + SQL VERIFIED / POS OWNER PATCH READY / BROWSER E2E OPEN / NOT 100% CLOSED`.

**Next exact step:** المالك يطبق Patches A–C على `pos.html` فقط بعد مطابقة SHA، ويراجع الأجزاء غير المطبقة من Report426، ثم يختبر: Owner binds new terminal via treasury QR → cashier logs in on same device → shift opens on the bound treasury → same cashier logs in on another device with a different terminal binding → treasury mismatch is rejected → sale/refund/cash-box shift linkage verified → served artifact parity verified.


## Addendum — Final branch-scope hardening (2026-10-16 22:05 UTC)

During final self-audit I found that the first deployed binding RPC called `get_pos_branches()`, which itself requires the `pos` permission. That would unnecessarily couple a manager's terminal-configuration authority to the POS read RPC. I corrected this before finalizing the checkpoint.

- Migration: `pos_terminal_bind_branch_scope_fix_20261016`
- Git file: `supabase/migrations/20261016223000_pos_terminal_bind_branch_scope_fix.sql`
- Git commit: `0e18d089b1570c913a54139b1588e7090e905c8a`
- The binding RPC now validates the branch directly against `public.branches`, company scope, active state, `default_branch_id`, `allowed_branch_ids`, and the explicit owner authorization; it no longer depends on the POS branch-list RPC for authorization.
- Fresh post-migration Production verification at `2026-10-16 22:05:16 UTC`: binding column exists; `pos_bind_terminal_treasury` and `pos_open_shift` are authenticated-executable and anon-denied; counts remain `pos_terminals=1`, `pos_shifts=1`, `pos_shift_events=1`, `cash_box=6`, `E2E residue=0`.
- The permission-denial test passed before this branch-scope-only correction. The follow-up attempt to rerun the identity-simulated permission test was blocked by the tool safety layer; no data mutation occurred. The final catalog/ACL/baseline query succeeded.
- This correction does not change the remaining owner UI patch or the honest closure status: Browser/HTTP E2E and served-artifact parity remain open.
