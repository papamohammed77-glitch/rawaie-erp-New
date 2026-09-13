# Report147 — CTO E2E Login Artifact Forensic — النظام الأم

**التاريخ:** 2026-09-13

## 1. الهدف الحاكم

الهدف في هذه الجلسة هو حسم سبب عدم تجاوز شاشة الدخول في **النظام الأم المنشور فعليًا**:

```text
https://rawaea-erp.pages.dev/companies/company-1/main
```

ومصدر الحقيقة البرمجي الوحيد هو:

```text
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html
```

**المبدأ الحاكم الحاسم:** لا يجوز تعديل السطر 5592 أو `_searchCustomers()` لمجرد أن Chrome أبلغ عنه، ما لم يثبت العيب في الـartifact الذي استلمه المتصفح نفسه. أي إصلاح قبل إثبات أصل الـlexical failure سيكون تعديلًا مبنيًا على تخمين ومخالفًا للحوكمة.

---

## 2. استرجاع الحالة السابقة

تمت إعادة فتح المصادر الحاكمة التالية مباشرة من GitHub:

```text
MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md
Report146_CTO_E2E_Runtime_Reinvestigation_20260912.md
CURRENT_STATE.md
.github/workflows/forensic_main_assembly.yml
.github/workflows/cto_main_html_forensic_20260912.yml
```

كما تم فتح المصدر المنشور الحالي مباشرة من مستودع `erp-frontend`.

التقرير السابق Report146 كان قد أثبت حدودًا مهمة:

- خطأ Runtime عند `main:5592` ما زال ملاحظًا من المتصفح.
- السطر 5592 في Source of Truth المفتوح مباشرة لا يحتوي Regex ولا تركيبًا غير صالح بذاته.
- فحص GitHub Actions القديم Run `34710228654` لم يكن فحصًا كاملًا لـ`main.html`.
- لا يجوز اعتبار Cache وحده سببًا مثبتًا.
- لا يجوز العودة إلى `main2..main11` كمصدر Reconstruction.

هذه الحدود بقيت سارية.

---

## 3. الحالة الحالية الفعلية للمصدر المنشور

تمت مطابقة أحدث Git history في مستودع `erp-frontend`.

أحدث Commit وقت التحقيق:

```text
094197b8b57219630242aacfe9c564d7a4f6df58
message = Update HTML comment timestamp
created = 2026-09-12T18:38:50Z
```

والـcommit السابق مباشرة:

```text
eb3230bd8dabe29d91334b05c4c25e24505a5fc6
```

الـcommit الأحدث غيّر فقط marker أعلى `main.html` من:

```html
<!-- 2026-09-12 21:00 UTC -->
```

إلى:

```html
<!-- 2026-09-12 22:00 UTC -->
```

وبالتالي لا يوجد في أحدث commit نفسه تعديل متأخر يمكن اعتباره إصلاحًا للخطأ المبلغ عنه.

تم فتح `main.html` الحالي مباشرة، وتأكد وجود:

```html
</script>
</body>
</html>
```

في نهاية الملف.

---

## 4. فحص `_searchCustomers()` الحالي

تم فتح المنطقة الحالية مباشرة من `main.html`، والدالة الحالية هي:

```javascript
function _searchCustomers(query) {
  var div = byId('ts-customer-results');
  if (!div) return;
  if (!query || !query.trim()) { div.classList.add('hidden'); return; }
  var customers = RW_STATE.data.customers || [];
  var q = query.toLowerCase();
  var filtered = customers.filter(function(c) {
    return (c.name || '').toLowerCase().indexOf(q) !== -1 ||
           (c.customer_code || '').toLowerCase().indexOf(q) !== -1 ||
           (c.phone || '').indexOf(q) !== -1 ||
           (c.area || '').toLowerCase().indexOf(q) !== -1;
  });
  if (!filtered.length) { safeHTML(div, '<div class="p-3 text-center text-gray-400">لا توجد نتائج</div>'); div.classList.remove('hidden'); return; }
  var h = '';
  for (var i = 0; i < Math.min(filtered.length, 15); i++) {
    var c = filtered[i];
    h += '<div onclick="RW_TeleSales._selectCustomer(\\'' + c.customer_code + '\\')" class="p-3 hover:bg-blue-50 cursor-pointer flex justify-between border-b">';
    h += '<div><div class="font-bold">' + (c.name || '') + '</div><div class="text-xs text-gray-400">' + (c.customer_code || '') + '</div></div>';
    h += '<div class="text-left text-xs text-gray-500">' + (c.area || '') + ' | ' + _fmtNum(c.debt) + ' ' + currency + '</div>';
    h += '</div>';
  }
```

السطر الذي يطابق بلاغ Runtime هو:

```text
5592
```

ونصه الحالي صالح لغويًا، ولا يحتوي Regex literal.

ولذلك:

```text
OWNER PATCH FOR LINE 5592 = NOT JUSTIFIED
OWNER PATCH FOR _searchCustomers() = NOT JUSTIFIED
```

---

## 5. نتيجة اختبار Runtime التي قدمها المالك

الاختبار الذي نُفذ من Console أثبت:

```text
LIVE SERVER RESPONSE = 200
LIVE URL = https://rawaea-erp.pages.dev/companies/company-1/main
LIVE BYTES = 896292
CACHE-CONTROL = public, max-age=0, must-revalidate
```

كما أثبت:

```text
SYNTAX FAILURE: INLINE_SCRIPT_5
Name: SyntaxError
Message: Invalid regular expression: missing /
```

والخطأ الظاهر في الصفحة:

```text
main:5592 Uncaught SyntaxError: Invalid regular expression: missing /
```

كما أثبت أن `login` بقي دون تجاوز.

---

## 6. التحقيق الجنائي في النسخة الحالية

تم فحص التراكيب الشائعة التي يمكن أن تُدخل Parser إلى Regex state قبل المنطقة المستهدفة.

قبل line 5592 في المصدر الحالي تم العثور فقط على تراكيب Regex ظاهرة وصحيحة، منها:

```javascript
replace(/[^\\d.]/g, '')
replace(/-/g, '')
replace(/[&<>]/g, ...)
```

كما تم فحص `RegExp(...)` الظاهر قبل المنطقة، وهو:

```javascript
new RegExp('#\\\\{' + keys[i] + '\\\\}', 'g')
```

ولا يثبت أي منها سببًا لخطأ `missing /` عند line 5592.

تم كذلك العثور على بعض `escJs()` في مواضع لاحقة من الملف تحتوي صياغة يظهر فيها `replace(/...` عند القراءة الجزئية، لكن هذه المواضع **بعد** المنطقة المبلغ عنها، ولذلك لا يصح استخدامها لتفسير خطأ parser المسجل عند 5592 في نفس artifact دون دليل runtime يثبت خلاف ذلك.

---

## 7. مراجعة خط سير الدخول

الـLogin الحالي في `main.html` يملك مسارًا حقيقيًا:

```text
RW_Auth.login()
→ Supabase Auth signInWithPassword
→ users.auth_id = user.id
→ استخراج company_id
→ التحقق من status
→ RW_Auth.enterSystem()
→ إخفاء login page
→ إظهار main shell
→ Bootstrap
→ dashboard
```

بالتالي لا يوجد في المصدر الحالي ما يثبت أن مشكلة عدم الدخول ناتجة عن غياب منطق `enterSystem()`.

لكن بما أن الـinline script لا يُنفذ عند فشل الـparse، فإن وجود مسار Login صحيح في المصدر لا يكفي لإثبات E2E.

---

## 8. مراجعة Cache / PWA / Assembly

تمت مراجعة:

```text
forensic_main_assembly.yml
cto_main_html_forensic_20260912.yml
```

المسار المرجعي صحيح:

```text
erp-frontend/companies/company-1/main.html
```

ولا توجد إعادة Reconstruction من:

```text
Current/PWA/main2
New-main
Original/PWA/main
```

كما أن فحص النظام الحالي يتعامل مع `main.html` كملف منشور مباشر.

لا يوجد دليل حالي يثبت أن Browser Cache وحده هو Root Cause.

---

## 9. الاستنتاج الحاسم

الحالة الحالية يجب تصنيفها كالتالي:

```text
GIT SOURCE OF TRUTH = RECONCILED
CURRENT _searchCustomers() SOURCE = VALID IN OPENED CONTEXT
RUNTIME SYNTAX ERROR = OBSERVED
LOGIN E2E = FAIL / OPEN
LIVE ARTIFACT BYTE IDENTITY = NOT PROVEN
LEXICAL ORIGIN OF ERROR = NOT PROVEN
OWNER CODE PATCH = NOT JUSTIFIED
```

والاحتمالان الوحيدان اللذان يستحقان الاستمرار في التحقيق الآن هما:

### الاحتمال A — Served Artifact Divergence

الـCloudflare artifact الذي يستلمه المتصفح مختلف عن `main.html` الحالي في Git.

في هذه الحالة يكون إصلاح المصدر لن يحل المشكلة، ويجب إصلاح deployment/served artifact.

### الاحتمال B — Lexical State Earlier in Same Artifact

الـartifact مطابق، لكن parser دخل Regex/String state غير صحيح قبل line 5592، ثم أبلغ line 5592 عند أول token كشف المشكلة.

في هذه الحالة يجب تحديد **أول token سبّب انهيار الحالة اللغوية**، وليس تغيير line 5592 لأنه مجرد مكان ظهور العَرَض.

---

## 10. الحل التشخيصي الحاسم ومنع الحلقة المفرغة

الاختبار التشخيصي السابق كان يقرأ الـlive artifact فقط. المطلوب الآن اختبار مزدوج من المتصفح نفسه يثبت:

```text
LIVE BYTES
LIVE SHA256
GIT RAW BYTES
GIT RAW SHA256
BYTE_EQUALITY
LIVE LINE 5590
LIVE LINE 5591
LIVE LINE 5592
LIVE LINE 5593
LIVE EOF
INLINE SCRIPT COUNT
```

ثم محاولة Compile للـinline script نفسه من الـlive DOM.

هذا هو الاختبار الوحيد المطلوب قبل أي Owner Surgery جديد، لأنه يحسم هل المشكلة في artifact أم في source lexical state.

### Console E2E Forensic Probe

يُلصق هذا الكود في نفس الصفحة التي يظهر فيها الخطأ:

```javascript
(async function RAWAEA_E2E_ARTIFACT_FORENSIC() {
  function sha256(text) {
    return crypto.subtle.digest('SHA-256', new TextEncoder().encode(text)).then(function(buf) {
      return Array.from(new Uint8Array(buf)).map(function(b) {
        return b.toString(16).padStart(2, '0');
      }).join('');
    });
  }

  function line(text, n) {
    return (text.split('\\n')[n - 1] || '(missing)');
  }

  console.clear();
  console.log('RAWAEA E2E ARTIFACT FORENSIC');
  console.log('LIVE_PAGE', location.href);
  console.log('TIME', new Date().toISOString());

  var liveUrl = new URL(location.href);
  liveUrl.searchParams.set('__e2e_artifact', Date.now().toString());

  var liveRes = await fetch(liveUrl.href, {
    cache: 'no-store',
    credentials: 'same-origin',
    headers: { 'Cache-Control': 'no-cache', 'Pragma': 'no-cache' }
  });
  var liveText = await liveRes.text();

  var gitUrl = 'https://raw.githubusercontent.com/papamohammed77-glitch/erp-frontend/main/companies/company-1/main.html?__e2e_git=' + Date.now();
  var gitRes = await fetch(gitUrl, { cache: 'no-store' });
  var gitText = await gitRes.text();

  var liveHash = await sha256(liveText);
  var gitHash = await sha256(gitText);

  console.log('LIVE', {
    status: liveRes.status,
    finalUrl: liveRes.url,
    bytes: new TextEncoder().encode(liveText).length,
    sha256: liveHash
  });

  console.log('GIT_RAW', {
    status: gitRes.status,
    finalUrl: gitRes.url,
    bytes: new TextEncoder().encode(gitText).length,
    sha256: gitHash
  });

  console.log('BYTE_EQUALITY', {
    equal: liveText === gitText,
    sha256Equal: liveHash === gitHash
  });

  console.log('LIVE_5590', line(liveText, 5590));
  console.log('LIVE_5591', line(liveText, 5591));
  console.log('LIVE_5592', line(liveText, 5592));
  console.log('LIVE_5593', line(liveText, 5593));
  console.log('LIVE_5594', line(liveText, 5594));
  console.log('GIT_5590', line(gitText, 5590));
  console.log('GIT_5591', line(gitText, 5591));
  console.log('GIT_5592', line(gitText, 5592));
  console.log('GIT_5593', line(gitText, 5593));
  console.log('GIT_5594', line(gitText, 5594));

  console.log('LIVE_EOF', liveText.split('\\n').slice(-5));
  console.log('GIT_EOF', gitText.split('\\n').slice(-5));

  var scripts = Array.from(document.scripts);
  var inline = scripts.filter(function(s) {
    return !s.src && (!s.type || s.type === 'text/javascript' || s.type === 'application/javascript');
  });

  console.log('DOM_SCRIPTS', {
    total: scripts.length,
    inline: inline.length,
    inlineLengths: inline.map(function(s) { return (s.textContent || '').length; })
  });

  for (var i = 0; i < inline.length; i++) {
    try {
      new Function(inline[i].textContent || '');
      console.log('DOM_INLINE_COMPILE_' + i, 'PASS');
    } catch (e) {
      console.error('DOM_INLINE_COMPILE_' + i, {
        name: e.name,
        message: e.message,
        stack: e.stack
      });
    }
  }

  var liveInlineMatches = liveText.match(/<script(?=[^>]*\\b)(?![^>]*\\bsrc\\s*=)[^>]*>[\\s\\S]*?<\\/script>/gi) || [];
  console.log('LIVE_INLINE_SCRIPT_BLOCKS', liveInlineMatches.length);

  console.log('DONE');
})().catch(function(e) {
  console.error('RAWAEA_E2E_ARTIFACT_FORENSIC_FAILED', e);
});
```

---

## 11. كيفية تفسير النتيجة

### نتيجة 1 — `BYTE_EQUALITY.equal = false`

هذا يثبت:

```text
LIVE DEPLOYMENT ARTIFACT != GIT SOURCE OF TRUTH
```

والخطوة الصحيحة ليست تعديل line 5592.

بل إصلاح deployment/served artifact، ثم إعادة E2E.

### نتيجة 2 — `BYTE_EQUALITY.equal = true` + `DOM_INLINE_COMPILE = FAIL`

هذا يثبت أن الـartifact نفسه فيه lexical syntax defect.

عندها فقط يتم تجهيز Owner Surgical ChangeSet محدد بالسطر الأول الذي بدأ الـlexical corruption.

### نتيجة 3 — `BYTE_EQUALITY.equal = true` + `DOM_INLINE_COMPILE = PASS` + الصفحة ما زالت تعرض SyntaxError

عندها يصبح لدينا تعارض غير معتاد بين parser الذي يقيسه `new Function` وparser الذي نفّذ document script، ويجب تحليل HTML tokenization/script extraction نفسه قبل أي تعديل.

---

## 12. لماذا لم يتم تنفيذ Owner Patch في هذه الجلسة

وفق مبدأ الحوكمة، أي تعديل على:

```text
companies/company-1/main.html
```

مسؤولية المالك، ولا يُرسل له إلا ChangeSet مثبت.

في هذه الجلسة لا يوجد حتى الآن عنصر مصدر محدد ثبت أنه سبب:

```text
Invalid regular expression: missing /
```

وبالتالي لم يتم اختراع Patch على السطر 5592.

هذا قرار تقني مقصود، وليس تركًا للمشكلة.

---

## 13. `forensic_main_assembly.yml`

تمت مراجعة الملف مباشرة.

المسار الصحيح مثبت:

```text
https://raw.githubusercontent.com/papamohammed77-glitch/erp-frontend/main/companies/company-1/main.html
```

ولا يقوم بإعادة Reconstruction للملف المنشور.

لا يوجد تعديل مطلوب على Source of Truth path في هذه الجلسة.

لكن الفحص الحالي لا يحسم وحده الـCloudflare served artifact؛ لذلك يجب أن تبقى المقارنة بين `raw.githubusercontent.com` و`rawaea-erp.pages.dev` جزءًا دائمًا من بوابة التحقق.

---

## 14. الحالة التنفيذية النهائية

```text
Historical Governance Read              = PASS
Report146 Reconciled                    = PASS
Current Git Source Reopened             = PASS
Latest Git Commit Rechecked             = PASS
main.html Source of Truth               = CONFIRMED
_searchCustomers() Source Review       = PASS
Line 5592 Patch Justification           = NO
Main Source Modification                = NONE
Supabase Modification                   = NONE
Assembly Path                           = CORRECT
Prior Cache-only Theory                 = REJECTED AS UNPROVEN
Runtime Syntax Error                    = CONFIRMED OBSERVED
Live/Git Byte Identity                  = OPEN
Lexical Root Cause                      = OPEN
Login E2E                                = OPEN / FAIL
Gold/Diamond                            = NOT CERTIFIED
```

---

## 15. ما تم إثباته

1. مصدر الحقيقة الحالي هو `erp-frontend/companies/company-1/main.html`.
2. أحدث Commit في `erp-frontend` لم يغير الدالة المبلغ عنها؛ بل غيّر timestamp فقط.
3. `_searchCustomers()` الحالية، والسطر 5592 تحديدًا، لا يحتويان عيب Regex ظاهرًا في Source of Truth المفتوح مباشرة.
4. الخطأ في Runtime حقيقي ومؤثر ويمنع تنفيذ الـinline script وبالتالي يمنع Login E2E.
5. لا يوجد دليل يبرر تعديل line 5592.
6. `forensic_main_assembly.yml` يشير إلى المسار الصحيح ولا يعيد بناء الملف من fragments التاريخية.
7. المشكلة الحاسمة المتبقية هي إثبات هوية الـartifact الذي يراه المتصفح.

---

## 16. ما لم يُثبت بعد

```text
Cloudflare served artifact == Git raw artifact
Exact first lexical corruption token
Reason Chrome reports line 5592 instead of a previous line
```

هذه ليست فجوات نظرية؛ هي حدود الإثبات الحالية التي تمنع Owner Surgery صحيحة.

---

## 17. الخطوة التنفيذية الوحيدة التالية

تشغيل `RAWAEA_E2E_ARTIFACT_FORENSIC` من نفس الصفحة المتضررة.

لا تعديل في `main.html` قبل نتيجة:

```text
BYTE_EQUALITY
LIVE_5590..LIVE_5594
DOM_INLINE_COMPILE
```

ثم:

```text
DIVERGENCE
→ إصلاح Deployment
```

أو:

```text
MATCH
→ تحديد أول lexical corruption
→ Owner ChangeSet واحد محدد
→ إعادة النشر
→ Login E2E
```

---

# FINAL SELF-AUDIT

### What I Proved

- Current Source of Truth path.
- Latest frontend commit identity.
- Current `_searchCustomers()` context.
- Validity of current line 5592 in opened source.
- Existence of real runtime SyntaxError.
- Assembly path correctness.

### What I Did Not Prove

- Exact Cloudflare artifact byte identity.
- Exact lexical origin of the Chrome parser failure.

### What I Fixed

- No Owner frontend patch was justified, therefore none was invented.
- No unrelated Production/database modification was made for this frontend blocker.

### What I Initially Missed / Corrected

- Report146's runtime/source boundary needed to be continued from actual served-artifact identity, not from another local source excerpt.

### What Could Still Be Wrong

- Deployment artifact drift.
- Runtime HTML tokenization difference.
- Earlier lexical corruption in the same inline script not represented by the isolated `_searchCustomers()` excerpt.

### Final Confidence

```text
Source-of-Truth identification = HIGH
Line 5592 "defect" claim         = REJECTED
Runtime failure existence         = HIGH
Root cause                        = NOT YET PROVEN
```

### Final Closure Status

```text
GLOBAL E2E LOGIN FORENSIC = OPEN
OWNER PATCH = BLOCKED BY LACK OF PROOF, NOT BY INACTION
```

# END REPORT147
