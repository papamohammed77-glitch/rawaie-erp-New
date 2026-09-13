# Report149 — تقرير التحقيق الجنائي الكامل لمشكلة E2E Login

**التاريخ:** 2026-09-13  
**المرحلة:** E2E — النظام الأم `main.html`  
**نوع المهمة:** Forensic Syntax / Login Bootstrap  
**Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html` على `main`  

---

## 1. المبدأ الحاكم — نقطة البداية

**الـSource of Truth الوحيد في هذه المهمة هو الملف المنشور الحالي:**

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

ولا يجوز استخدام `Current/PWA/main2` أو أي ملف تاريخي كبديل عنه. أجزاء `main2` والمصادر التاريخية استُخدمت فقط كمرجع لفهم السياق عند الحاجة.

تم تطبيق تسلسل الحوكمة:

```text
UNDERSTAND
→ RECONSTRUCT HISTORICAL CONTRACT
→ TRACE CURRENT BEHAVIOR
→ TRACE DATA/AUTH/CONTROL FLOW
→ IDENTIFY ACTUAL GAP
→ SURGICAL FIX
→ DIAGNOSTIC VERIFY
```

---

## 2. الواقع الحالي الذي تم التحقق منه

تم فحص GitHub مباشرة، وليس الاعتماد على التقارير السابقة فقط.

### Current frontend identity

```text
Repository: papamohammed77-glitch/erp-frontend
Branch: main
Latest inspected commit: 1048877b6bec6152332d102e11782a036b61e09f
Current main.html blob: eb1123a431b9f173aa8095f22dee435d0bbe8920
```

الملف الحالي يحتوي على Inline JavaScript واحد رئيسي داخل `main.html`.

---

## 3. إثبات أن المشكلة ليست Cache

تمت مراجعة طبقات النشر ذات الصلة:

- الملف الحالي في GitHub هو نفسه Source of Truth المفترض للنشر.
- `_redirects` يوجّه `/main` إلى `companies/company-1/main.html`.
- `_headers` يضع سياسة عدم التخزين المؤقت للـHTML والـservice-worker.
- Service Worker الحالي يستخدم مسار Network-first للـHTML/Navigation.

لذلك، استمرار الخطأ في متصفح خفي جديد لا يغير حقيقة أن **الملف الحالي نفسه يحتوي على أخطاء Syntax مثبتة**.

---

## 4. نتيجة الاختبار المباشر للملف الحالي

تم تشغيل GitHub Actions على نسخة Git الحالية للملف مع استخراج JavaScript مع الحفاظ على أرقام الأسطر.

النتيجة الحالية:

```text
INLINE_JS_BLOCKS=1
/tmp/main-positioned.js:5592
SyntaxError: Invalid regular expression: missing /
```

وهذا يثبت أن الملف الحالي نفسه لا يجتاز JavaScript parse.

---

## 5. التصحيح الجوهري لنتيجة Report148

Report148 السابق اعتبر أن المشكلة الجذرية تقع في line 5590.

التحقيق الجديد أثبت أن هذا الاستنتاج غير صحيح.

السطر 5590 الحالي صحيح نحويًا، وهو:

```javascript
      h += '<div onclick="RW_TeleSales._selectCustomer(\'' + c.customer_code + '\')" class="p-3 hover:bg-blue-50 cursor-pointer flex justify-between border-b">';
```

أما الخطأ الحقيقي الذي يجعل المتصفح يبلغ عن `Invalid regular expression: missing /` فهو في السطر 5592، حيث خرج `</div>` من الـstring literal بسبب فقدان quote قبل وسم HTML.

**إذًا 5592 هو أول Syntax Root فعلي، و5590 ليس العيب الحالي.**

---

## 6. لماذا يعرض Chrome رسالة Regex رغم أن الخطأ String؟

السطر الحالي:

```javascript
h += '<div class="text-left text-xs text-gray-500">' + (c.area || '') + ' | ' + _fmtNum(c.debt) + ' ' + currency</div>';
```

بعد `currency` ينتهي JavaScript من string عند آخر `'` قبل `;`، ثم يرى:

```text
</div>
```

فيُفسر `/` باعتباره بداية Regular Expression Literal، ولا يجد `/` مقابلًا، ولذلك تظهر الرسالة:

```text
Invalid regular expression: missing /
```

إذًا الرسالة التي تظهر في Console هي **أثر تأخري لحالة lexical مكسورة** وليست دليلًا على وجود Regex مقصود في هذا السطر.

---

## 7. لم يكن الخطأ واحدًا

بعد اكتشاف الجذر الأول، تم إنشاء نسخة تشخيصية مطابقة للملف الحالي، وتم تطبيق التصحيحات المعروفة عليها فقط، ثم تشغيل `node --check`.

النتيجة: النسخة المصححة تشخيصيًا اجتازت فحص Syntax كاملًا.

هذا أثبت وجود **سبعة مواضع Syntax مستقلة** في الملف الحالي:

| الخط | سبب الخطأ | نوعه |
|---|---|---|
| 5592 | فقدان quote قبل `</div>` | String termination |
| 5614 | فقدان quote قبل `</strong>` | String termination |
| 5731 | فقدان quote قبل `</div>` | String termination |
| 5805 | فقدان quote قبل `</td>` | String termination |
| 5807 | فقدان quote قبل `</td>` | String termination |
| 7436 | فقدان quote قبل `</span>` | String termination |
| 9391 | قوس `)` زائد داخل `.join(''))}` | Template expression syntax |

---

## 8. الإصلاحات الجراحية المطلوبة في النظام الأم

**لم يتم تعديل `erp-frontend/companies/company-1/main.html` بواسطة المساعد، التزامًا بفصل المسؤوليات.**

التعديلات التالية هي التعديل الكامل المطلوب على الملف الحالي.

### FIX-01 — line 5592

**ابحث عن السطر 5592 الحالي كاملًا:**

```javascript
      h += '<div class="text-left text-xs text-gray-500">' + (c.area || '') + ' | ' + _fmtNum(c.debt) + ' ' + currency</div>';
```

**احذفه واستبدله كاملًا بهذا السطر:**

```javascript
      h += '<div class="text-left text-xs text-gray-500">' + (c.area || '') + ' | ' + _fmtNum(c.debt) + ' ' + currency + '</div>';
```

### FIX-02 — line 5614

**ابحث عن السطر 5614 الحالي كاملًا:**

```javascript
      detailsHtml += '<div><i class="fa-solid fa-money-bill-wave ml-1 text-blue-400"></i> الرصيد: <strong>' + _fmtNum(selectedCustomer.debt) + currency</strong></div>';
```

**احذفه واستبدله كاملًا بهذا السطر:**

```javascript
      detailsHtml += '<div><i class="fa-solid fa-money-bill-wave ml-1 text-blue-400"></i> الرصيد: <strong>' + _fmtNum(selectedCustomer.debt) + currency + '</strong></div>';
```

### FIX-03 — line 5731

**ابحث عن السطر 5731 الحالي كاملًا:**

```javascript
      h += '<div class="font-bold text-blue-600">'+_fmtNum(it.sales_price)+ ' ' + currency</div>';
```

**احذفه واستبدله كاملًا بهذا السطر:**

```javascript
      h += '<div class="font-bold text-blue-600">'+_fmtNum(it.sales_price)+ ' ' + currency + '</div>';
```

### FIX-04 — line 5805

**ابحث عن السطر 5805 الحالي كاملًا:**

```javascript
      h += '<td class="p-4 border-y font-bold text-blue-600">'+_fmtNum(it.price)+ ' ' + currency</td>';
```

**احذفه واستبدله كاملًا بهذا السطر:**

```javascript
      h += '<td class="p-4 border-y font-bold text-blue-600">'+_fmtNum(it.price)+ ' ' + currency + '</td>';
```

### FIX-05 — line 5807

**ابحث عن السطر 5807 الحالي كاملًا:**

```javascript
      h += '<td class="p-4 border-y font-black">'+_fmtNum(line)+ ' ' + currency</td>';
```

**احذفه واستبدله كاملًا بهذا السطر:**

```javascript
      h += '<td class="p-4 border-y font-black">'+_fmtNum(line)+ ' ' + currency + '</td>';
```

### FIX-06 — line 7436

**ابحث عن السطر 7436 الحالي كاملًا:**

```javascript
            ordersHtml += '<span style="display:inline-block;background:#fff;border-radius:8px;padding:4px 12px;margin:4px;font-size:13px;box-shadow:0 1px 3px rgba(0,0,0,0.1);">' + orders[o].order_code + ' - ' + orders[o].customer_name + '(' + _fmtNum(orders[o].total_amount) + ' ' + currency + ')'</span>';
```

**احذفه واستبدله كاملًا بهذا السطر:**

```javascript
            ordersHtml += '<span style="display:inline-block;background:#fff;border-radius:8px;padding:4px 12px;margin:4px;font-size:13px;box-shadow:0 1px 3px rgba(0,0,0,0.1);">' + orders[o].order_code + ' - ' + orders[o].customer_name + '(' + _fmtNum(orders[o].total_amount) + ' ' + currency + ')</span>';
```

### FIX-07 — line 9391

**ابحث عن السطر 9391 الحالي كاملًا:**

```javascript
                <div><label class="text-xs font-bold block mb-1">الفرع</label><select id="bc-branch-select" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200 font-bold"><option value="">-- اختر --</option>${branches.map(b => '<option value="' + (b.id || b.branch_code || '') + '">' + (b.name || b.branch_name || '') + '</option>').join(''))}</select></div>
```

**احذفه واستبدله كاملًا بهذا السطر:**

```javascript
                <div><label class="text-xs font-bold block mb-1">الفرع</label><select id="bc-branch-select" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200 font-bold"><option value="">-- اختر --</option>${branches.map(b => '<option value="' + (b.id || b.branch_code || '') + '">' + (b.name || b.branch_name || '') + '</option>').join('')}</select></div>
```

---

## 9. إثبات أن مجموعة الإصلاحات كاملة من ناحية Syntax

تم بناء نسخة تشخيصية من نفس `main.html` الحالي، دون تعديل Git source-of-truth، ثم تطبيق الإصلاحات السبعة أعلاه على النسخة المؤقتة فقط.

تم تشغيل:

```text
node --check /tmp/main-repaired.js
```

نتيجة خطوة الاختبار في GitHub Actions:

```text
Apply known repairs to a diagnostic copy and re-parse = completed / success
```

وهذا يعني أن مجموعة الإصلاحات السبعة أزالت جميع أخطاء JavaScript Syntax التي تمنع الـparser من قراءة الملف كاملًا حتى نهايته.

---

## 10. مسار Login بعد Syntax Repair

تم فحص المسار الفعلي في `main.html` بعد إزالة عائق Syntax من التحليل:

### `bindEvents()`

يربط:

```javascript
byId('rw-login-form').addEventListener('submit', ... RW_Auth.login(...))
```

### `RW_Auth.login()`

يقوم بالترتيب التالي:

```text
RW_SUPABASE_CLIENT
→ auth.signInWithPassword
→ users lookup by auth_id
→ company_id validation
→ RW_STATE.app.authenticated = true
→ RW_STATE.app.currentUser
→ RW_STATE.permissions
→ RW_STATE.app.company.id
→ enterSystem()
```

وبالتالي **لا يوجد دليل حالي يثبت أن شاشة الدخول عالقة بسبب زر Submit أو بسبب فشل `signInWithPassword` في حالة Fresh Login.**

العائق المؤكد قبل Login هو أن JavaScript كله لا يبدأ بسبب Syntax Parse failure.

---

## 11. عيب مستقل تم اكتشافه في Session Restore

في `boot()` توجد استعادة جلسة سابقة تقوم بتعيين:

```javascript
RW_STATE.app.company = {
    name: meta.companyName || 'الروائع ERP',
    logo: meta.companyLogo || 'ر'
};
```

لكنها لا تعيد:

```javascript
RW_STATE.app.company.id
```

بينما `enterSystem()` يعتمد على:

```javascript
RW_STATE.app.company.id
```

هذا **Defect مستقل** في Session Restore.

لم يتم دمجه في إصلاح Login الحالي لأن Fresh Login بعد `signInWithPassword` يملأ `company.id` بشكل صحيح من جدول `users`، ولا يوجد داعٍ لخلط Fix مستقل مع Syntax Closure.

سيُفتح كـClosure Unit منفصل بعد إغلاق Syntax وE2E Login الحالي.

---

## 12. Tailwind Console Warning

الرسالة:

```text
cdn.tailwindcss.com should not be used in production
```

هي تحذير Production من CDN وليس Syntax Error.

ولا تمنع parser من تحميل JavaScript.

لذلك لم تعتبر سبب شاشة الدخول الحالية.

---

## 13. Production / Supabase

لا توجد حاجة لتعديل Supabase لإصلاح الخطأ الحالي.

```text
SUPABASE CHANGE = NONE
```

أي تعديل Database لن يعالج JavaScript Syntax Error في `main.html`.

---

## 14. Assembly Source-of-Truth Drift

تم اكتشاف Drift حقيقي في:

```text
rawwaie-erp-New/forensic_main_assembly.yml
```

كان يعلن:

```text
source_of_truth: Current/PWA/main2
```

وهذا يخالف القرار الحالي بأن الملف المنشور في `erp-frontend` هو المرجع النهائي.

تم تعديل الملف مباشرة إلى:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
```

مع إبقاء `Current/PWA/main2` ضمن historical/reference فقط ومنعه كمصدر إعادة بناء.

Commit:

```text
8a7efadd89520ab09016180a433fb96a5d1d0788
```

---

## 15. ما تم تغييره فعليًا

### تم تغييره

```text
rawwaie-erp-New/forensic_main_assembly.yml
```

تم تصحيح Source of Truth ليشير إلى الملف المنشور الحالي.

### لم يتم تغييره

```text
erp-frontend/companies/company-1/main.html
```

السبب: هذا الملف من اختصاص المالك حسب قاعدة المسؤوليات المعتمدة.

### Supabase

```text
NO CHANGE
```

---

## 16. ما فشل سابقًا ولماذا

### الفشل الأول

تم التركيز على line 5590 بناءً على قراءة غير كافية للسياق المحيط.

**السبب:** تم أخذ تقرير سابق كحقيقة ولم تتم مطابقة parser الحالية للملف قبل تقرير الجذر.

### الفشل الثاني

تم التعامل مع line 5592 كأنه مجرد نتيجة لخطأ سابق في 5590.

**السبب:** لم يتم إجراء `node --check` على الملف الكامل الحالي قبل استخلاص الاستنتاج.

### التصحيح المنهجي

تم الآن:

```text
Current Git artifact
→ direct parser verification
→ independent diagnostic parser
→ complete known repair set
→ full parse verification
```

---

## 17. حالة المهمة الآن

```text
CURRENT FILE INSPECTED = PASS
CURRENT SOURCE IDENTITY = PROVEN
CACHE HYPOTHESIS = NOT ROOT CAUSE
LINE 5590 = NOT CURRENT ROOT
LINE 5592 = ROOT CONFIRMED
ADDITIONAL SYNTAX ROOTS = 6 CONFIRMED
KNOWN SYNTAX REPAIR SET = COMPLETE
PATCHED COPY NODE CHECK = PASS
PRODUCTION/SUPABASE CHANGE = NONE
SOURCE-OF-TRUTH GOVERNANCE DRIFT = FIXED
OWNER MAIN.HTML PATCH = PENDING
LIVE LOGIN E2E = NOT YET RE-RUN AFTER OWNER PATCH
SESSION RESTORE COMPANY-ID DEFECT = OPEN / SEPARATE
```

---

## 18. الخطوة التالية الوحيدة المطلوبة

يقوم المالك بتطبيق **FIX-01 إلى FIX-07 حرفيًا** في:

```text
erp-frontend/companies/company-1/main.html
```

ثم يُعاد نشر الملف الحالي نفسه.

بعد ذلك تكون دورة E2E الصحيحة:

```text
DEPLOYED MAIN
→ BYTE / COMMIT IDENTITY
→ DOM INLINE JS EXTRACTION
→ NODE PARSE = PASS
→ SUPABASE SDK INITIALIZATION
→ LOGIN SUBMIT
→ AUTH SESSION
→ USERS COMPANY CONTEXT
→ enterSystem()
→ dashboard
→ E2E LOGIN = PASS
```

لا يجوز اعتبار E2E Login مغلقًا قبل نجاح هذه الدورة الفعلية.

---

## 19. SELF-AUDIT

### What I Proved

- الملف الحالي هو الذي يحتوي الخطأ فعليًا.
- line 5592 هو أول Syntax Root حقيقي.
- توجد ستة مواضع أخرى مستقلة.
- مجموعة الإصلاحات السبعة تجتاز JavaScript parser على نسخة تشخيصية مطابقة.
- bindEvents وRW_Auth.login موجودان ومترابطان في مسار الدخول.
- Supabase ليس سبب Syntax blocker.
- `forensic_main_assembly.yml` كان يحمل Source-of-Truth قديمًا وتم إصلاحه.

### What I Did Not Prove

- نجاح Login الفعلي من متصفح بعد نشر النسخة المصححة، لأن `main.html` نفسه لم يعدّله المساعد ولم يُنشر بعد التعديل اليدوي.
- اكتمال E2E لجميع التبويبات والعمليات بعد الدخول.
- إغلاق Session Restore defect.

### What I Fixed

- Source-of-Truth drift في `forensic_main_assembly.yml`.

### What I Initially Missed

- تعدد أخطاء Syntax بعد الخطأ الأول.
- أن تقرير الجذر السابق عن line 5590 غير صحيح بعد مطابقة Current HEAD.

### What Could Still Be Wrong

بعد إصلاح Syntax، يجب التحقق فعليًا من Login E2E؛ ومن الممكن ظهور runtime/auth defects جديدة، لكنها لا يجوز افتراضها قبل الاختبار.

### Final Confidence

```text
SYNTAX ROOT-CAUSE CONFIDENCE = HIGH / DIRECTLY VERIFIED
LOGIN PATH STATIC CONFIDENCE = HIGH
LIVE LOGIN E2E CONFIDENCE = NOT YET PROVEN
```

### Final Closure Status

```text
GLOBAL E2E LOGIN SYNTAX CLOSURE = OWNER PATCH PENDING
LIVE LOGIN E2E = OPEN
```

# END REPORT149
