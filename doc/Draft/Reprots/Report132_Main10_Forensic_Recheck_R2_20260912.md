# Report132 — إعادة الفحص الجنائي الثاني لـ Main10 — 2026-09-12

## 0. الهدف الحاكم — يجب قراءته بعناية وتكراره

**هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

هذا هو المبدأ الحاكم لهذه الإعادة.

---

## 1. نطاق التنفيذ

تم إيقاف أي مسار سابق والتركيز على:

`Current/PWA/main2/main10.md`

مع مراجعة:

- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `CURRENT_STATE.md`
- `Report131_Main10_Forensic_Recheck_20260912.md`
- `MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js`
- `Original/PWA/main/main10.md`
- `forensic_main_assembly.yml`
- الحالة الحالية المباشرة في Git وProduction المرتبطة بـMain10.

لم يتم تعديل Source Fragment نفسه لأن ملكية تعديله للمالك صراحة.

---

## 2. نتيجة التحقق المباشر — التقرير السابق أصبح قديمًا

التقرير 131 كان يسجل Main10 بالـSHA:

`169025a6836c7fdc7281ea86523b975a84d889f1`

لكن القراءة المباشرة الحالية لـGit أثبتت أن Main10 الحالي أصبح:

`76aae070e7452f5b7b233b790c39d5c864aa19a0`

وبحجم مختلف.

لذلك:

`169025a... = STALE`

و:

`76aae070... = CURRENT`

لا يجوز استخدام SHA القديم كأساس لتطبيق الحزمة السابقة.

---

## 3. القراءة الجنائية لـMain10 الحالي

تمت قراءة المصدر الحالي مباشرة على عدة نطاقات متتابعة حتى EOF.

النتيجة الحاسمة ليست مجرد فرق شكلي في الأسطر؛ المصدر الحالي يحتوي على **بقايا حرفية لحزمة الاستبدالات نفسها داخل كود التشغيل**.

### العيب الأول — `}, {` داخل RW_OwnerLicense

بعد كتلة `_loadLicenseData()` الحالية يظهر حرفيًا:

```text
}
    },
    {

    supabase
        .from('app_settings')
```

وهذا ليس تركيب JavaScript صالحًا في هذا الموضع.

### العيب الثاني — `}, {` بعد `_buildFullForm()`

يظهر حرفيًا:

```text
}
    },
    {

function _bindSaveButtons() {
```

وهذا دليل إضافي على أن عناصر الحزمة السابقة تم إدخالها إلى Source Fragment بدل استخدامها كتعليمات خارجية.

### العيب الثالث — `}, {` بعد `_bindSaveButtons()`

يظهر حرفيًا قبل `_saveSettings()`.

### العيب الرابع — EOF ملوث

ينتهي الملف الحالي بعد:

```text
window.RW_Views = RW_Views;
    }
  ]
};
```

بينما يجب أن يكون `window.RW_Views = RW_Views;` هو نهاية Main10 نفسها.

### النتيجة

`CURRENT MAIN10 = SYNTAX-CORRUPTED`

ولا يجوز تنفيذ Assembly أو اعتبار الملف صالحًا للدمج في هذه الحالة.

---

## 4. السبب الجذري

السبب الذي تم إثباته من المصدر الحالي هو خطأ في تطبيق الحزمة السابقة: تم إدخال بنية كائن الحزمة `[{...}, {...}]` إلى Source Fragment نفسه.

هذا يفسر جميع مظاهر الزيادة في الأقواس والفواصل والبنية الموجودة حاليًا.

ولذلك **الحل ليس حذف كل `}, {` يدويًا**؛ لأن ذلك قد يترك أجزاء من الحزمة أو يكسر إغلاق الدوال مرة أخرى.

الحل الجراحي الآمن هو استبدال وحدتي Main10 بالكامل:

1. `RW_OwnerLicense`
2. `RW_Views`

ولا يتم إجراء حذف منفصل للعلامات المتكررة.

---

## 5. إعادة فحص تاريخ Main10

تم فتح:

`Original/PWA/main/main10.md`

وتبين أن الهيكل التاريخي كان قائمًا على:

- `RW_OwnerLicense`
- `RW_Views`

ولا يوجد في الأصل عقد يبرر وجود كائنات array باسم:

```text
}, {
```

بين الدوال.

إذن هذه ليست compatibility structure؛ بل residue ناتج عن تطبيق package بطريقة خاطئة.

---

## 6. التحقق من `forensic_main_assembly.yml`

الحالة المباشرة سليمة:

```yaml
source_of_truth: Current/PWA/main2
historical_reference: Original/PWA/main
forbidden_sources:
  - Current/PWA/main
  - Current/PWA/New-main
assembly_status: deferred_until_all_fragments_are_owner_verified
```

ولا يوجد تعديل مطلوب في هذا الملف خلال Main10 R2.

---

## 7. Production reconciliation

تم فحص Production المرتبط بـMain10، وبالأخص `save-settings`.

ثبت أن backend الحالي:

- JWT protected.
- يستخرج Company Context من المستخدم المصادق.
- يستخدم Owner semantics في تغيير الترخيص.
- لا يحتاج Migration جديدة بسبب أخطاء Main10 الحالية.

كما ثبت من Production permission vocabulary وجود:

`finance`

و:

`hr`

وبالتالي يجب أن يكون Router في Main10:

```text
finance -> finance
hr -> hr
```

وليس `hr -> users`.

لم يتم تنفيذ أي Production migration في هذه الإعادة لأن ذلك غير مطلوب لهذه العيوب.

---

## 8. إعادة تصميم الإصلاح — بدون Patch ترقعي

### قرار M10-R2-01

**استبدال كامل للوحدة `RW_OwnerLicense`.**

لا تبحث عن `}, {` لحذفها.

نفذ بدقة:

> ابحث عن أول سطر كامل يبدأ بـ:
>
> `var RW_OwnerLicense = (function() {`
>
> ثم احذف كل شيء من هذا السطر حتى السطر الكامل:
>
> `window.RW_OwnerLicense = RW_OwnerLicense;`
>
> واستبدله بكتلة `RW_OwnerLicense` المصححة الواردة في **الملف المحلي المرشح الذي اجتاز `node --check`** والمثبت في سجل هذه الجلسة.

المبدأ: الاستبدال يكون للوحدة كاملة، وليس لدالة منفردة، حتى لا يبقى أي جزء من الحزمة الملوثة.

### قرار M10-R2-02

**استبدال كامل للوحدة `RW_Views`.**

نفذ بدقة:

> ابحث عن أول سطر كامل يبدأ بـ:
>
> `var RW_Views = {`
>
> ثم احذف كل شيء من هذا السطر حتى السطر الكامل:
>
> `window.RW_Views = RW_Views;`
>
> واستبدله بكتلة `RW_Views` المصححة من المرشح نفسه.

بعد ذلك يجب أن تكون نهاية Main10 حرفيًا:

```text
window.RW_Views = RW_Views;
```

ولا شيء بعدها.

---

## 9. خصائص النسخة المصححة التي تم إعدادها واختبارها محليًا

المرشح المصحح الذي أُعد لهذه الإعادة هو ملف JavaScript كامل بطول:

`249 lines`

وحجم:

`19458 bytes`

وتم اجتياز:

```text
node --check = PASS
```

ويتضمن الإصلاحات التالية:

- لا يوجد fallback مخترع لحالة `trial` عند غياب Company Context.
- عرض حالة واضحة عند غياب Company Context أو بيانات الترخيص.
- عدم تعبئة حقل البريد الجديد بالبريد الحالي.
- إبقاء البريد الحالي في `owner-current-email` فقط.
- إلزام تأكيد كلمة المرور ومطابقة الحقلين.
- التحقق الأساسي من صيغة البريد قبل `auth.updateUser`.
- التحقق من وجود Session قبل استدعاء `save-settings`.
- `finance -> finance`.
- `hr -> hr`.
- عناوين واضحة لـ`finance`, `hr`, `crm`, `reports-comprehensive`.
- وصف route غير المعروف بـ`التبويب غير معروف` بدل `قيد التطوير`.
- إغلاق صحيح وحيد لكل من `RW_OwnerLicense` و`RW_Views`.
- لا يوجد tail من نوع `}, { ... ]` في نهاية الملف.

هذه النتيجة تثبت أن البديل المقترح ليس إعادة إنتاج للنسخة الملوثة.

---

## 10. لماذا لا نطبق الحزمة السابقة كما هي؟

الحزمة السابقة:

`MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

ليست صالحة كأساس مباشر لهذه الإعادة لأن:

1. `source_sha_before_apply` فيها هو SHA قديم.
2. المصدر الحالي يثبت أن بنية package أُدخلت فعليًا داخل Main10.
3. الاستبدال الجزئي على المصدر الحالي سيترك خطر بقايا إضافية.

لذلك تم تصنيفها:

`HISTORICAL PACKAGE — DO NOT APPLY BLINDLY`

والحل الصحيح هو الاستبدال الكامل لوحدتي Main10 أعلاه.

---

## 11. Syntax / Structure Audit

### الحالة الحالية قبل Owner Apply

```text
Current Main10 live source = CORRUPTED
Executable node check on live source = NOT CLAIMED
Reason = direct source inspection already proves invalid stray object fragments
```

### النسخة المرشحة بعد الإصلاح

```text
Candidate node --check = PASS
RW_OwnerLicense declaration count = 1
window.RW_OwnerLicense assignment count = 1
RW_Views declaration count = 1
window.RW_Views assignment count = 1
package tail marker = 0
```

### شرط الإغلاق

لا يتم تحويل Candidate PASS إلى Main10 PASS قبل Owner Apply وإعادة قراءة المصدر الحقيقي.

---

## 12. Data / Production status

لا توجد Data migration مرتبطة مباشرة بإصلاح Main10 R2.

ولا توجد Production data changes في هذه الإعادة.

Production remains the source for runtime facts; Source Fragment remains owner-editable.

---

## 13. مقارنة جميع أجزاء Main2

تمت مطابقة بنية مسار Source of Truth وmetadata للأجزاء الموجودة في:

`Current/PWA/main2/main1.md` … `main11.md`

مع ملاحظة مهمة:

هذه الجلسة لم تنفذ Full Content Audit مستقلًا من أول حرف إلى آخر حرف لكل الأجزاء الـ11؛ لذلك لا يوجد ادعاء أن جميع الأجزاء الـ11 تم إثبات سلامتها الوظيفية في هذه الجلسة.

الهدف من هذه المطابقة كان التأكد من أن Main10 لا ينحرف عن مسار assembly وأن Main2 هو مصدر الحقيقة الصحيح.

Assembly remains deferred.

---

## 14. ما لم يتم تغييره عمدًا

- `Current/PWA/main2/main10.md` لم يعدله المساعد.
- `Current/PWA/main2/main1..main11.md` لم يجر عليها تعديل آلي.
- `forensic_main_assembly.yml` لم يعدل لأنه صحيح.
- `Original/PWA/main/main10.md` لم يعدل.
- `Current/PWA/main/*` لم يعدل.
- `Current/PWA/New-main/*` لم يعدل.
- Production لم يعدل بسبب Main10 R2.

---

## 15. Self-Audit

### What I Proved

- Source of Truth الصحيح هو `Current/PWA/main2`.
- `forensic_main_assembly.yml` صحيح المسار.
- Main10 الحالي المباشر SHA هو `76aae070e7452f5b7b233b790c39d5c864aa19a0`.
- Main10 الحالي يحتوي بقايا `}, {` غير الصالحة وبقايا tail الخاصة بالحزمة.
- تقرير131 لم يعد يمثل current Main10 SHA.
- Production `save-settings` مربوط بالسياق الصحيح وOwner semantics.
- Production permissions تثبت وجود `finance` و`hr`.
- تم إعداد candidate نظيف اجتاز `node --check`.

### What I Did Not Prove

- Owner لم يطبق البديل بعد.
- لم يُنفذ Browser/E2E على Main10 بعد Owner Apply.
- لم يتم Assembly.
- لم يتم Global Gold/Diamond closure.
- لم يتم إثبات اكتمال كل تبويبات النظام خارج Main10.

### What I Initially Missed / What This Recheck Found

العطل الحاسم الذي لم يكن ظاهرًا في التقرير السابق هو أن **بنية الحزمة نفسها تسربت إلى Source Fragment**. لذلك كانت المشكلة أكبر من مجرد 8 gaps وظيفية: المصدر صار syntactically corrupted.

### Final Closure Status

```text
MAIN10 CURRENT SOURCE = CORRUPTED
MAIN10 FORENSIC RECHECK R2 = COMPLETE
CORRECTED CANDIDATE = SYNTAX PASS
OWNER APPLY = REQUIRED
POST-APPLY READ = REQUIRED
POST-APPLY NODE CHECK = REQUIRED
BROWSER/E2E = REQUIRED
PRODUCTION RUNTIME CLOSURE = REQUIRED
ASSEMBLY = DEFERRED
GLOBAL GOLD/DIAMOND = OPEN
MAIN10 = NOT CLOSED
```

---

## 16. سجل الجلسة

هذه الوثيقة هي السجل الجديد بعد Report131، ولا تحذف Report131 أو أي تقرير سابق.

التاريخ:

`2026-09-12`

الوظيفة:

`MAIN10 FORENSIC RECHECK R2`

القرار التنفيذي:

`WHOLE-UNIT OWNER REPLACEMENT — NO FRAGMENT PATCHING`

الهدف التالي الوحيد بعد Owner Apply:

```text
READ MAIN10 AGAIN
→ EOF
→ EXECUTABLE SYNTAX
→ STRUCTURAL AUDIT
→ DUPLICATE/BRACE AUDIT
→ ROUTER/PERMISSION AUDIT
→ BROWSER/E2E
→ PRODUCTION SYNC
→ CLOSE
```

لا يسمح بالإعلان عن الإغلاق قبل اكتمال هذا التسلسل.