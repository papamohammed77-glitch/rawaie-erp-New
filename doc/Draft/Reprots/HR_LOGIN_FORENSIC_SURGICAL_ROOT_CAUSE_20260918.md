# RAWAEA ERP — HR LOGIN FORENSIC SURGICAL ROOT-CAUSE CLOSURE
## 2026-09-18

### 1. نطاق الجلسة

النطاق الوحيد في هذه الجلسة هو **HR / Mother login parser incident**.

- `companies/company-1/main.html` لم يتم تعديله.
- لا توجد Migration مطلوبة في Supabase لهذا العطل.
- كل ما يلي بُني على CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE، مع استخدام التقارير السابقة كسياق تاريخي فقط.
- لا تُعاد أي معالجة سبق إغلاقها إلا عند ظهور دليل حالي جديد.

---

## 2. الحالة الحالية المثبتة قبل التعديل

### Mother repository
`papamohammed77-glitch/erp-frontend`

Current HEAD:
```
6a9cfb3b28b27023320f4a0cd8c049e76d0fc6db
```

Parent:
```
1a8d0144446fe42b706eadd5683f6789dbbfac2f
```

Current `companies/company-1/main.html` blob:
```
a2551e35b50c3fa8de03114ea54094e0eaca14dd
```

### System repository
`papamohammed77-glitch/rawaie-erp-New`

Latest verified system commit before this report:
```
a58c53e4ef8e90b719ab6bc22679446455a9297a
```

Parent:
```
0ccfe870adcb5dccded96684ae347f3dbe6a3e89
```

---

## 3. دليل Production / Database

تمت إعادة التحقق من HR Production قبل تحديد Patch:

HR core functions الحالية:

- `hr_query`
- `hr_command_atomic`
- `hr_user_has_permission`
- `hr_payroll_calculate_impl`
- `hr_payroll_post_impl`
- `hr_save_attendance`
- `hr_set_leave_status`
- `hr_upsert_employee_profile`

جميعها موجودة كـ SECURITY DEFINER في Production.

Audit actor guard:
```
trg_hr_command_log_actor_identity
    -> hr_command_log_enforce_actor_identity()
```

Production HR counts وقت التحقيق:
```
employee_profiles = 0
employee_attendance = 0
employee_leave_requests = 0
employee_documents = 0
```

**النتيجة:** لا يوجد دليل أن بيانات HR أو بنية HR في Supabase هي سبب عدم تجاوز شاشة الدخول، ولا توجد حاجة لتعديل Production Database لهذا العطل.

---

# 4. التحقيق الجنائي لخطأ Console

## العَرَض

ظهر:

```
(index):64
cdn.tailwindcss.com should not be used in production
```

ثم:

```
main:25370
Uncaught SyntaxError: Unexpected token ')'
```

### الفصل بين الخطأين

رسالة Tailwind هي **Production warning** وليست سبب SyntaxError.

سبب توقف JavaScript هو خلل تركيب JavaScript داخل المصدر الحالي.

---

# 5. إعادة بناء التاريخ الفعلي للخلل

## Commit 15325117153959536d8035b603ef9cfd64fc736d

الرسالة:

```
Refactor RW_HR assignment in main.html
```

الـdiff أزال تحديدًا:

```
}());
```

الذي كان يأتي مباشرة بعد:

```
window.RW_HR={render:render,reload:render,openEmployee360:open360};
```

أي أنه أزال **إغلاق IIFE الخاص بـ RW_HR**.

---

## Commit 7adb14563ff7601bd28e05007bb2584be359016f

الرسالة:

```
Update main.html
```

أزال الإغلاق النهائي الموجود في نهاية الملف:

```
})();
```

---

## Commit 48139d0b711496712d3c43572eef0e0e4ee5934c

الرسالة:

```
Fix script closure in main.html
```

أعاد `})();` في نهاية الملف.

لكن إغلاق RW_HR كان قد أُزيل سابقًا من مكانه الصحيح، لذلك الإغلاق الأخير لم يعد يغلق الـscope المقصود له.

---

## Current HEAD 6a9cfb3b28b27023320f4a0cd8c049e76d0fc6db

التغيير الحالي الأخير قبل هذا التحقيق هو تحديث comment/date فقط، وليس إصلاحًا نحويًا.

---

# 6. النتيجة الجنائية

لدينا **خطآن نحويان حاليان داخل RW_HR**:

## العيب رقم 1 — modal()

الموضع:

```
RW_HR
global line 23818
```

الدالة:

```
function modal(title,body,onSubmit,key)
```

الدالة الحالية تنتهي بـ:

```
}}}}
```

من دون `}` إضافية لإغلاق `modal()`.

تم اختبار الدالة منفردة بواسطة JavaScript parser وكانت النتيجة:

```
Unexpected token ')'
```

---

## العيب رقم 2 — إغلاق RW_HR IIFE مفقود

RW_HR يبدأ عند:

```
global line 23788
var RW_HR = (function() {
```

والإغلاق الموجود عند:

```
23893:   }());
```

هو إغلاق **installModalResilience()** الداخلي فقط.

بعده حاليًا:

```
realtime();
window.RW_HR={render:render,reload:render,openEmployee360:open360};
window.RW_HR = RW_HR;
```

المفقود هو:

```
}());
```

بين السطرين الأخيرين.

---

# 7. اختبار إثبات السببية

تم فحص المصدر الحالي كاملًا كـinline JavaScript.

الحالة الحالية:

```
FULL INLINE SCRIPT = FAIL
Unexpected token ')'
```

بعد تطبيق **التعديلين فقط**:

1. إضافة `}` إلى نهاية دالة `modal()`.
2. استعادة `}());` بعد export object الخاص بـ RW_HR.

النتيجة:

```
FULL INLINE SCRIPT = PASS
```

وهذا تم إثباته على **نفس المصدر الحالي**، وليس على نسخة تاريخية.

---

# 8. التعديل الجراحي المطلوب على Mother

> لا يتم تعديل أي جزء من `main.html` خارج العنصرين أدناه.

## PATCH A — modal()

### ابحث عن:

```
global line 23818
function modal(title,body,onSubmit,key)
```

### احذف الدالة كاملة واستبدلها بهذه الدالة كاملة:

```javascript
function modal(title,body,onSubmit,key){
  var old=E('rw-hr-modal-root');
  if(old)old.remove();
  var r=document.createElement('div');
  r.id='rw-hr-modal-root';
  r.innerHTML='<div class="fixed inset-0 z-[1200] bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4"><div class="bg-white w-full max-w-6xl max-h-[94vh] overflow-hidden rounded-3xl shadow-2xl flex flex-col"><div class="flex items-center justify-between px-6 py-4 bg-slate-50 border-b"><div><div class="font-black text-lg">'+esc(title)+'</div><div class="text-xs text-slate-500 mt-1">تحكم مركزي من النظام الأم</div></div><button id="rw-hr-close" type="button" class="w-10 h-10 rounded-xl bg-white border text-lg">×</button></div><form id="rw-hr-form" class="overflow-y-auto p-6">'+body+'<div class="flex justify-end gap-2 mt-6 pt-4 border-t"><button type="button" id="rw-hr-cancel" class="px-5 py-3 rounded-xl bg-slate-100 font-black">إلغاء</button><button class="px-5 py-3 rounded-xl bg-indigo-600 text-white font-black">حفظ</button></div></form></div></div>';
  document.body.appendChild(r);
  E('rw-hr-close').onclick=closeModal;
  E('rw-hr-cancel').onclick=closeModal;
  r.addEventListener('click',function(e){
    var ac=e.target.closest&&e.target.closest('[data-hr-action]');
    if(ac){
      e.preventDefault();
      handle(ac.getAttribute('data-hr-action'));
    }
  });
  if(onSubmit===null){
    var f=E('rw-hr-form');
    if(f&&f.lastElementChild)f.lastElementChild.style.display='none';
  }else{
    E('rw-hr-form').onsubmit=async function(e){
      e.preventDefault();
      var save=e.target.querySelector('button[type="submit"]');
      try{
        if(save){
          save.disabled=true;
          save.textContent='جارٍ الحفظ…';
        }
        await onSubmit(key||'form:'+Date.now());
      }catch(err){
        toast(err.message||'تعذر الحفظ','error');
        if(save){
          save.disabled=false;
          save.textContent='حفظ';
        }
      }
    };
  }
}
```

### لا تعدل:

- توقيع الدالة.
- استدعاءات `modal(...)`.
- سلوك read-only عندما `onSubmit === null`.
- سلوك الحفظ والخطأ.
- أي دالة أخرى في RW_HR.

---

# 9. PATCH B — RW_HR IIFE closure

### ابحث عن النص الفريد:

```
window.RW_HR={render:render,reload:render,openEmployee360:open360};
window.RW_HR = RW_HR;
```

### أدخل السطر التالي بينهما:

```
}());
```

### النتيجة النهائية المطلوبة:

```
realtime();
window.RW_HR={render:render,reload:render,openEmployee360:open360};
}());
window.RW_HR = RW_HR;
```

### مهم

**لا تحذف ولا تغير `})();` الموجود في نهاية الملف.**

بعد هذا الإصلاح:

- `})();` داخل RW_HR يغلق RW_HR.
- `})();` النهائي يغلق الـouter script wrapper.
- لا توجد حاجة لإضافة closure ثالثة.

---

# 10. لماذا لم نستخدم PATCH أقدم

يوجد Patch تاريخي كان يعالج:

```
esc(x.status||'-')]))));
```

إلى:

```
esc(x.status||'-')])));
```

هذا العيب ليس مثبتًا كخلل حالي في المصدر الحالي؛ دالة `payrollTab` الحالية تمر بالـparser منفردة.

**لذلك لم تتم إعادة فتح هذا الإصلاح ولم تتم إعادة تعديله.**

---

# 11. HR Functional / Competitive Gap Check

نطاق HR الحالي في Mother:

```
dashboard
employees
organization
contracts
attendance
leaves
requests
advances
payroll
documents
```

Production data/engines الحالية تغطي أساسيات:

| المجال | RAWAEA الحالي | النتيجة الحالية |
|---|---|---|
| Employee master | موجود | مثبت مصدرًا وDB |
| Organization | موجود | مثبت مصدرًا وDB |
| Contracts | موجود | مثبت مصدرًا وDB |
| Attendance | موجود | مثبت مصدرًا وDB |
| Attendance raw events | موجود | مثبت مصدرًا وDB |
| Leave types/balances | موجود | مثبت مصدرًا وDB |
| Requests/approvals | موجود | مثبت مصدرًا وDB |
| Advances | موجود | مثبت مصدرًا وDB |
| Payroll periods/runs/payslips | موجود | مثبت مصدرًا وDB |
| Payroll accounting map | موجود | مثبت مصدرًا وDB |
| Employee documents | موجود | مثبت مصدرًا وDB |
| Employee 360 | موجود | مثبت في Mother source |

الفجوات التي ظهرت في المقارنة لا تدخل في هذا الـsyntax closure:

- لا يوجد دليل Runtime Browser مكتمل على ESS/self-service.
- لا يوجد دليل E2E على device/geofence/time-clock integrations.
- لا يوجد دليل Runtime كامل على accrual automation المتقدم.
- لا يوجد دليل مكتمل على training/certifications/performance/talent.
- لا يوجد دليل Browser Production مكتمل على Payroll E2E.
- هذه تظل **Closure Units مستقلة لاحقًا**، ولا تدخل في إصلاح parser.

### Benchmark references

Odoo:
https://www.odoo.com/documentation/19.0/applications/hr/employees.html

Odoo Time Off:
https://www.odoo.com/documentation/19.0/applications/hr/time_off.html

Microsoft Dynamics 365 Human Resources:
https://learn.microsoft.com/en-us/dynamics365/human-resources/

SAP SuccessFactors Time Management:
https://help.sap.com/docs/successfactors-employee-central/operating-time-management-in-sap-successfactors

Daftra HRM:
https://www.daftra.com/en/hrm/

Manager.io:
https://www2.manager.io/manager.pdf

المقارنة هنا لتحديد **حدود المجال والقدرات المتوقعة**، وليس لنسخ أي منتج خارجي أو ترتيب المنتجات.

---

# 12. Production decision

لا توجد بنية Production لازمة لهذا الإصلاح.

```
Supabase migration required = NO
HR database modification = NO
HR business data modification = NO
Authentication database modification = NO
```

السبب الحالي هو JavaScript source syntax فقط.

---

# 13. Closure Status

| البند | الحالة |
|---|---|
| Historical reconstruction | VERIFIED |
| Current Mother source inspection | VERIFIED |
| Current Production HR inspection | VERIFIED |
| Root cause modal() | VERIFIED |
| Root cause missing RW_HR IIFE close | VERIFIED |
| Surgical patch defined | VERIFIED |
| Full-source parser after both fixes | PASS |
| main.html modified by assistant | 0 |
| Production DB changed | 0 |
| Mother patch applied by owner | OPEN |
| Mother deployment verified | OPEN |
| Live login browser verified | OPEN |
| Authenticated HR smoke | OPEN |
| Full HR transactional E2E | OPEN |

**لا تتحول OPEN إلى CLOSED بمجرد تطبيق Patch في Git.**

---

# 14. تعليمات التحقق بعد التنفيذ

بعد تطبيق PATCH A وPATCH B في Mother:

1. أعد جلب `companies/company-1/main.html` من Git الحالي.
2. نفذ parser gate على الـinline JavaScript.
3. النتيجة المطلوبة:
```
V8_INLINE_JS_PARSE = PASS
```
4. تحقق أن `RW_HR` له:
   - opening عند `var RW_HR = (function() {`
   - closing عند `}());` بعد `window.RW_HR={...}`.
5. تحقق أن الإغلاق النهائي للملف ما زال موجودًا.
6. تحقق أن `window.RW_HR = RW_HR;` بقي بعد إغلاق IIFE الداخلي مباشرة.
7. افتح Production URL فعليًا.
8. اختبر login → session → company → Mother.
9. افتح HR.
10. نفذ smoke read-only لكل تبويب.
11. لا تستخدم بيانات HR وهمية في Production لإجبار PASS.

---

# 15. Self-Audit

## What I Proved

- Production HR ليست سبب SyntaxError الحالي.
- Tailwind warning ليس سبب توقف JavaScript.
- `modal()` الحالية ناقصة إغلاق function brace.
- RW_HR IIFE الحالية ناقصة closing `}();` في مكانها الصحيح.
- تاريخ Git يثبت متى وكيف أزيل إغلاق RW_HR.
- الإغلاق النهائي الذي أُعيد لاحقًا لم يكن بديلًا عن الإغلاق المفقود داخل RW_HR.
- تطبيق التعديلين فقط يجعل current inline script يمر بالـparser.

## What I Did Not Prove

- live browser Production بعد Patch لم يُنفذ بعد، لأن Mother source هو الجزء الذي يطبقه المالك يدويًا.
- لا يوجد Browser E2E حالي مكتمل لكل HR tabs.
- لا يوجد دليل مكتمل على كل HR capabilities المتقدمة.

## What I Fixed

في هذه الجلسة لم أعدل Mother `main.html`.

حددت بدقة التعديلين المطلوبين فقط وقدمت replacement كاملًا لـ`modal()` واستعادة closure المفقود.

## What I Initially Missed

لا يوجد إصلاح Production مطلوب لهذه النقطة.

## What Could Still Be Wrong

إذا بقي parser FAIL بعد تطبيق التعديلين، يجب عدم تعديل HR عشوائيًا؛ يجب أخذ current served artifact وإعادة مطابقته مع Git SHA الحالي قبل أي Patch جديد.

## Final Confidence

```
Root cause confidence = HIGH
Patch syntax confidence = HIGH
Production DB impact = NONE
Live browser closure = OPEN
```

---

# 16. تعليمات البداية للمساعد التالي

ابدأ من:

```
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT
```

ثم:

1. تحقق من Mother HEAD وparent.
2. تحقق أن main.html يحتوي PATCH A وPATCH B.
3. شغّل parser gate.
4. تحقق من deployed artifact الفعلي، لا من Git فقط.
5. اختبر login.
6. اختبر HR routing.
7. اختبر HR read-only tabs.
8. بعد إثبات login closure فقط، افتح أول HR Closure Unit وظيفية مستقلة.
9. لا تعد إلى parser/payroll fixes المغلقة دون دليل جديد.
10. لا تعدل `main.html` خارج Closure Unit مثبتة.

**هذه الوثيقة هي سجل الحقيقة التنفيذي لهذه الجلسة، وليست مجرد ملخص.**
