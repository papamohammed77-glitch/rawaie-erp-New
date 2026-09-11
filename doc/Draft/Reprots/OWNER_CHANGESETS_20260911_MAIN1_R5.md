# RAWAEA ERP — OWNER SOURCE CHANGE SET
## MAIN1 — R5 — 2026-09-11

> **المبدأ الحاكم:** هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يُتعامل معه كإضافات شكلية.

## 1. Source Identity
- الملف: `Current/PWA/main2/main1.md`
- SHA الحالي المثبت مباشرة من Git: `8275750c05c353dec9ed825ca4aff7a4f6d05fab`
- `Original/PWA/main/*` مرجع تاريخي فقط.
- `Current/PWA/New-main` مرحلة متوقفة وليست مصدرًا حاليًا.
- لم يتم تعديل Main1 بواسطة المساعد.

## 2. لا تعيد تطبيق الإصلاحات القديمة
الإصلاحات التالية موجودة بالفعل في Main1 الحالي:
- Finance permissions تستخدم `['finance','finance_manager']`.
- HR = `hr`.
- CRM = `customers`.
- `isAllowed()` يدعم النص والمصفوفة OR وfallback إلى `view`.
- Audit table/details الحاليان يستخدمان DOM/textContent للقيم الديناميكية.

لا تحذف أو تستبدل هذه العناصر.

## 3. CHANGE MAIN1-N1 — Missing password visibility function
### العنصر الحالي
في عنصر كلمة المرور يوجد الاستدعاء التالي حرفيًا:
```html
onclick="window.togglePasswordVisibility('rw-password', this)"
```

### المطلوب
ابحث عن:
```javascript
const byId = id => document.getElementById(id);
```
وأضف **فوقه مباشرة**:
```javascript
window.togglePasswordVisibility = function(inputId, button) {
    try {
        var input = document.getElementById(inputId);
        if (!input) return;

        var shouldShow = input.type === 'password';
        input.type = shouldShow ? 'text' : 'password';

        if (button) {
            var icon = button.querySelector('i');
            if (icon) {
                icon.className = shouldShow ? 'fa-solid fa-eye-slash' : 'fa-solid fa-eye';
            }
            button.setAttribute('aria-label', shouldShow ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور');
            button.setAttribute('title', shouldShow ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور');
        }
    } catch (e) {
        console.error('togglePasswordVisibility error:', e);
    }
};
```

### نهاية العنصر المطلوبة
ينتهي السطر الأخير المضاف بـ:
```javascript
};
```
ولا تضف نسخة ثانية من الدالة.

## 4. CHANGE MAIN1-N2 — Notification panel loses event listeners
### العنصر الحالي
داخل:
```javascript
var RW_Notification = (function() {
```
ابحث عن الدالة الكاملة:
```javascript
function showPanel() {
```

### الاستبدال
احذف الدالة `showPanel()` الحالية كاملة من:
```javascript
function showPanel() {
```
حتى القوس الأخير الذي يغلق الدالة الحالية مباشرة قبل:
```javascript
    function markAllRead() {
```

واستبدلها كاملة بـ:
```javascript
function showPanel() {
    var email = RW_STATE.app.currentUser ? RW_STATE.app.currentUser.email : null;
    if (!email) return;

    supabase.from('notifications')
        .select('*')
        .eq('user_email', email)
        .order('created_at', { ascending: false })
        .limit(50)
        .then(function(res) {
            var notifs = res.data || [];

            var root = document.createElement('div');
            root.dir = 'rtl';
            root.style.width = '420px';
            root.style.maxHeight = '500px';
            root.style.overflowY = 'auto';

            var header = document.createElement('div');
            header.style.cssText = 'padding:16px 20px;border-bottom:1px solid #e5e7eb;display:flex;justify-content:space-between;align-items:center;';

            var title = document.createElement('h3');
            title.style.cssText = 'font-size:16px;font-weight:900;color:#111827;';
            title.textContent = 'الإشعارات';
            header.appendChild(title);

            if (notifs.length > 0) {
                var markAll = document.createElement('button');
                markAll.type = 'button';
                markAll.style.cssText = 'font-size:12px;color:#2563eb;font-weight:700;background:none;border:none;cursor:pointer;';
                markAll.textContent = 'قراءة الكل';
                markAll.addEventListener('click', function(e) {
                    e.stopPropagation();
                    RW_Notification.markAllRead();
                });
                header.appendChild(markAll);
            }

            root.appendChild(header);

            if (!notifs.length) {
                var empty = document.createElement('div');
                empty.style.cssText = 'padding:40px 20px;text-align:center;color:#9ca3af;';
                empty.textContent = 'لا توجد إشعارات';
                root.appendChild(empty);
            } else {
                for (var n = 0; n < notifs.length; n++) {
                    var notif = notifs[n] || {};
                    var row = document.createElement('div');
                    row.style.cssText = 'padding:12px 20px;border-bottom:1px solid #f1f5f9;cursor:pointer;' +
                        (notif.is_read ? 'background:white;' : 'background:#eff6ff;');

                    var notifTitle = document.createElement('div');
                    notifTitle.style.cssText = 'font-size:13px;font-weight:800;color:#111827;';
                    notifTitle.textContent = notif.title || '';
                    row.appendChild(notifTitle);

                    if (notif.body) {
                        var notifBody = document.createElement('div');
                        notifBody.style.cssText = 'font-size:12px;color:#6b7280;margin-top:4px;';
                        notifBody.textContent = notif.body;
                        row.appendChild(notifBody);
                    }

                    row.addEventListener('click', (function(id, refTable, refId) {
                        return function(e) {
                            e.stopPropagation();
                            RW_Notification._clickNotif(id, refTable, refId);
                        };
                    })(notif.id, String(notif.reference_table || ''), String(notif.reference_id || '')));

                    root.appendChild(row);
                }
            }

            Swal.fire({
                html: root,
                showConfirmButton: false,
                showCloseButton: true,
                width: 600,
                padding: 0,
                customClass: { popup: 'rounded-2xl overflow-hidden' }
            });
        })
        .catch(function(e) {
            console.warn('Notification panel load error:', e);
        });
}
```

### النتيجة المقصودة
- `notif.title` و`notif.body` يبقيان textContent.
- زر `قراءة الكل` يعمل.
- الضغط على الإشعار يعمل.
- لا نستخدم `root.outerHTML` الذي يفقد event listeners.

### نهاية العنصر
آخر سطر في الدالة البديلة يجب أن يكون:
```javascript
}
```
ثم مباشرة:
```javascript
    function markAllRead() {
```

## 5. CHANGE MAIN1-N3 — Forgot password is currently inert
### العنصر الحالي
في login form ابحث حرفيًا عن:
```html
<a href="#" class="rw-forgot">نسيت كلمة المرور؟</a>
```

### الاستبدال
استبدله حرفيًا بـ:
```html
<button type="button" id="rw-forgot-password" class="rw-forgot" style="background:none;border:none;padding:0;cursor:pointer;">نسيت كلمة المرور؟</button>
```

### إضافة handler
ابحث عن آخر سطر فعلي في الملف:
```javascript
window.RW_Navigation = RW_Navigation;
```
وأضف **فوقه مباشرة**:
```javascript
(function() {
    var forgotButton = document.getElementById('rw-forgot-password');
    if (!forgotButton) return;

    forgotButton.addEventListener('click', function() {
        try {
            var emailInput = document.getElementById('rw-username');
            var email = emailInput ? String(emailInput.value || '').trim() : '';

            if (!email) {
                showToast('أدخل البريد الإلكتروني أولًا', 'warning');
                if (emailInput) emailInput.focus();
                return;
            }

            showLoader('جاري إرسال رابط استعادة كلمة المرور...');

            RW_SUPABASE_CLIENT.auth.resetPasswordForEmail(email, {
                redirectTo: window.location.origin + window.location.pathname
            }).then(function(res) {
                hideLoader();
                if (res.error) {
                    console.error('Password reset error:', res.error);
                    showToast('تعذر إرسال رابط استعادة كلمة المرور', 'error');
                    return;
                }
                showToast('تم إرسال رابط استعادة كلمة المرور إلى البريد الإلكتروني', 'success');
            }).catch(function(e) {
                hideLoader();
                console.error('Password reset exception:', e);
                showToast('حدث خطأ أثناء طلب استعادة كلمة المرور', 'error');
            });
        } catch (e) {
            hideLoader();
            console.error('Forgot password handler error:', e);
        }
    });
})();
```

### نهاية العنصر المضاف
```javascript
})();
```
ثم:
```javascript
window.RW_Navigation = RW_Navigation;
```

## 6. CHANGE MAIN1-N4 — Quick Search must not remain a decorative control
### current evidence
العنصر:
```html
<input type="text" class="rw-header-search-input" placeholder="بحث سريع...">
```
لا يوجد في Main1 نفسه handler مثبت له.

### القرار
**لا يطلب حذفًا أو replacement في Main1 الآن.**
لا نضيف handler تخمينيًا قبل إثبات Search Contract في Main2–Main11 والمستهلكين الفعليين، حتى لا ننشئ duplicate routing/search implementation.

## 7. MAIN1-WF — Workflow false-success remains OPEN
### exact element
```javascript
function evaluate(tableName, event, recordId, recordData) {
```
داخل `RW_Workflow`.

### القرار
لا حذف ولا replacement الآن.

Production الحالية تحتوي 3 قواعد:
- `UpdateStockAndJournalOnPOReceive`
- `CreateJournalOnOrderDeliver`
- `CreateStockVoucherOnOrderConfirm`

لكن Executor/Dispatcher contract لهذه الـactions لم يثبت من Production + current sources بشكل يسمح بتصميم آمن. لا يتم اختراع executor أو payload أو retry contract.

## 8. Do Not Change
لا تلمس:
- `RW_Audit_renderTable()` الحالي.
- `RW_Audit_showDetails()` الحالي.
- Finance permission entries.
- HR permission entry.
- CRM permission entry.
- `isAllowed()` الحالي.
- `Original/PWA/main/main1.md`.

## 9. Owner Verification
بعد تنفيذ N1 + N2 + N3:
1. أعد قراءة Main1 من أول حرف إلى آخر EOF.
2. تحقق من الأقواس/الأقواس المعقوفة/علامات الاقتباس.
3. تحقق أن `togglePasswordVisibility` توجد مرة واحدة فقط.
4. افتح Forgot Password وتحقق من رسالة النجاح/الفشل بدون تسجيل بيانات اعتماد.
5. افتح الإشعارات وتحقق أن `قراءة الكل` والنقر على الإشعار يعملان.
6. تحقق أن Finance/HR/CRM permissions لم تتغير.
7. لا تنتقل إلى Workflow replacement حتى يُثبت الـExecutor contract.
