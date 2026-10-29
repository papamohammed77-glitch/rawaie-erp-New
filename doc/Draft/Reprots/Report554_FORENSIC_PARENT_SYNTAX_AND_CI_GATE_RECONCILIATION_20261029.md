# Report554 — التحقيق الجنائي لخطأ SyntaxError في النظام الأم وتصحيح بوابة اختبار التكامل

**Last Verified Event:** `LVE-2026-10-29-554`  
**التاريخ:** 2026-10-29  
**النطاق:** استعادة إقلاع Parent `main.html`، التحقق من ظهور رانشيتات الكمية المتبقية في تبويب المرتجعات، تدقيق بوابات CI، وتصحيح دقة حالة المشروع.  
**مرجع الحوكمة:** Report545 — `GOVERNANCE_AUDIT_AND_DELIVERY_OWNER_PATCH_RESET_20261029.md`.  
**الحالة:** `PARENT SYNTAX ROOT CAUSE CONFIRMED / OWNER PATCH C+D STATIC-PASS IN MEMORY / CI FIX DRAFT PR #7 / STANDALONE RETURNS PR #6 STILL OPEN / PRODUCTION DEPLOYMENT + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED`

## 0. القرار التنفيذي

العطل الحرج الذي يفسر فشل تهيئة وظائف النظام الأم ثبت في مصدر Git الحالي: commit `151f1ad2cd48645ef1f029b7df417e66d4141eec` أضاف سلسلة HTML متعددة الأسطر داخل JavaScript string ذات اقتباس مفرد، ثم أبقى أجزاء مكررة من خلايا الصف القديم خارج تعبير `return`. لذلك يفشل تحليل كتلة JavaScript الرئيسية قبل تنفيذها، ويتوافق هذا مع خطأ المتصفح الذي أبلغ عنه المالك ومع سجل فشل Node في GitHub Actions عند السطر 15839.

تحذير Tailwind CDN ليس سبب الانهيار؛ هو تحذير استخدام CDN في الإنتاج. لم تُجرَ تغييرات على قاعدة البيانات أو بيانات الأعمال لمعالجة مشكلة JavaScript.

تم التأكد من الرقعتين الجراحيتين C وD في Report553، بعد إعادة تطبيقهما على نسخة مؤقتة من المصدر الحالي فقط:
- قبل الرقعة: خطأ تحليل `SyntaxError: Invalid or unexpected token`.
- بعد الرقعة: لم يُرجع تحليل كتلة JavaScript المضمنة خطأ.
- لم يُكتب ملف `main.html` ولم يُنشر أي إصدار.

تم إعداد Draft PR #7 لتصحيح بوابة اختبار Browser E2E التي ما زالت تتوقف بسبب افتراض نص تاريخي قديم متعلق بالرواتب، واستبداله بفحص JavaScript الفعلي للمصدر. PR #7 لا يعدّل التطبيق ولا يصلح Parent بذاته، ولم يُدمج ولم يُثبت تشغيل workflow عليه بعد.

## 1. مراجع الحقيقة وهوية المصدر

### 1.1 المستودع التشغيلي

- **Repository:** `papamohammed77-glitch/erp-frontend`
- **Branch:** `main`
- **HEAD المرصود:** `626df80fae8101fa6b1fe0ba0b6bc8d4ae69f8ca`
- **Parent source:** `companies/company-1/main.html`
- **Blob SHA:** `18d02872a1b204b73fba112f7beb5d9ba95ac72b`
- **Commit الذي أدخل النص المعطوب:** `151f1ad2cd48645ef1f029b7df417e66d4141eec`
- **تطبيق المندوب الحالي:** `companies/company-1/delivery/driver.html`, blob `d7ace0b9be52c936aee1d5f5e1250b6d2e9a48f0`.
- **تطبيق المرتجعات الحالي على main:** `companies/company-1/warehouse/returns.html`, blob `36c20e03c94dc734e015610dec1e8208697df32a`.

### 1.2 مستودع الحالة والتقارير

- **Repository:** `papamohammed77-glitch/rawaie-erp-New`
- تمت إعادة قراءة `CURRENT_STATE.md) وReport545 وReports546–553 ذات الصلة. قبل إضافة هذا السجل، كان رأس الحالة المسجلة `LVE-2026-10-29-553`.
- Report545 هو مرجع حدود الصلاحية: لا يكتب المساعد إلى Parent `main.html)؛ يُسلّم Owner Surgical Change Set بمحددات دقيقة. لا يجوز إعادة تطبيق تقرير قديم على Blob متغير.
- لا يتم استبدال محتوى التقارير التاريخية؛ يضيف هذا التقرير تصحيحًا لاحقًا للمعلومات والاختبارات التي جرى التحقق منها الآن.

## 2. السبب الجذري المثبت

### 2.1 خطأ JavaScript القاتل

في `main.html)، داخل `_applyReturn()` ثم callback الخاص بـ`RW_Table.paginate('rt-table', ...)`، يبدأ المقطع المعطوب قرب السطر 15839:

```javascript
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showReturnDetails(\'' + r.runsheet_code + '\')">
                <td class="p-3 font-bold">' + (r.runsheet_code||'') + '</td><td class="p-3">' + (r.run_date||'') + '</td>
                <td class="p-3">' + (r.driver_id||'---') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-rose-100 text-rose-700">' + statusLabel + '</span></td>
                <td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td></tr>';
                <td class="p-3 font-bold">' + (r.runsheet_code||'') + '</td><td class="p-3">' + (r.run_date||'') + '</td><td class="p-3">' + (r.driver_id||'---') + '</td>
                <td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-rose-100 text-rose-700">' + esc(r.status || '—') + '</span></td>
                <td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td></tr>';
```

هذا ليس مجرد خطأ تنسيق HTML:
1. سلسلة JavaScript ذات الاقتباس المفرد لا يجوز أن تحتوي فواصل أسطر فعلية بهذه الصورة.
2. توجد خلايا HTML مكررة بعد نهاية تعبير `return`، خارج أي سلسلة صالحة.
3. فشل تحليل كتلة JavaScript الكبيرة يمنع تنفيذ الكتلة نفسها، ومن ثم لا يمكن الاعتماد على handlers والدوال التي تعرّفها تلك الكتلة؛ يتوافق ذلك مع أعراض عدم تهيئة النظام وتوقف التفاعل بعد تسجيل الدخول.

### 2.2 الدليل المباشر من GitHub Actions

تم جلب سجل التشغيل الفعلي وليس الاكتفاء بوصف في تقرير سابق:

- Run `40918600126`, job `123605412173`, خطوة `Exact JavaScript syntax gate — original published source`: **FAIL**.
- سجل Node يطبع `INLINE_JS_BLOCKS=1)، ثم `/tmp/main-positioned.js:15839)، ثم `SyntaxError: Invalid or unexpected token`.
- Run `40918599961`, job `123605411794`: فشل فحص JavaScript المضمن.
- Run `40918600056`, job `123605411905`: فشل خطوة `Assert canonical payroll syntax in Mother source`؛ تم تخطي تثبيت Playwright وتشغيل المتصفح لأن الشرط السابق فشل.

هذا يثبت وجود خللين مختلفين في مسار التحقق:
- SyntaxError فعلي في المصدر الحالي.
- بوابة E2E تاريخية تعتمد على string قديم للرواتب لا يوجد في المصدر الحالي، وتوقف الاختبار قبل Playwright.

### 2.3 تنبيه على دقة عدّ script tags في Report553

أُعيد فحص ملفات المصدر نفسها:
- Parent `main.html`: ستة عناصر `<script>` إجمالًا، منها **كتلة JavaScript مضمنة واحدة**؛ البقية ذات `src`. وهذا يتسق مع `INLINE_JS_BLOCKS=1` في CI.
- `returns.html`: ثمانية عناصر `<script>` إجمالًا، منها **كتلة مضمنة واحدة** وسبعة عناصر بمصادر خارجية/ملفات.
- `driver.html`: تسعة عناصر `<script>` إجمالًا، منها كتلتان مضمنتان وسبعة عناصر بمصادر خارجية/ملفات.

لذلك فإن وصف Report553 الذي سمّى العناصر الستة في Parent أو العناصر الثمانية في Returns «كتل JavaScript مضمنة» غير دقيق. لا يُعاد تحرير Report553 تاريخيًا؛ يعتمد هذا التصحيح ابتداءً من LVE-554.

## 3. إصلاح Parent — Owner Surgical Change Set فقط

### 3.1 Patch C — إصلاح صف قائمة الرانشيت

**الملف المحمي:** `companies/company-1/main.html`  
**SHA الذي جرى فحصه:** `18d02872a1b204b73fba112f7beb5d9ba95ac72b`.

- بداية الاستبدال: أول سطر `var statusLabel = r.status === 'Delivered'...` داخل callback لـ`RW_Table.paginate`.
- نهاية الاستبدال: مباشرة قبل `});` الذي يغلق ذلك الـcallback.
- احتفظ بسطر إغلاق callback نفسه ثم إغلاق `_applyReturn()`.
- احذف من النطاق المعطوب كل أجزاء `<td>` القديمة المكررة.
- لا تستبدل `loadReturn()` أو `_applyReturn()` بالكامل؛ المنطق الذي يضيف Delivered ويحسِب `pending_return_qty` موجود بالفعل في المصدر الحالي.

النص البديل الدقيق موجود في قسم **2.2 Owner Surgical Patch C** من Report553. يجب إعادة جلب الملف والتحقق من SHA والمحددات وعدد المطابقات قبل التطبيق. إذا تغير SHA أو لم يعد المحدد فريدًا، فتوقف وأعد بناء الرقعة.

### 3.2 Patch D — إصلاح أعمدة تفاصيل المرتجعات

داخل `_showReturnDetails(code)`، رأس الجدول الحالي يعرض خمسة أعمدة: الصنف، المحمّل، المسلّم، المتبقي للمرتجع، المرتجع؛ لكن حلقة التفاصيل القديمة تنتج ثلاثة أعمدة فقط، وتضع `qty_delivered` تحت عنوان الكمية المحمّلة.

المحدد القديم الفريد يبدأ بـ:

```javascript
        items.forEach(it => { h += '<tr><td class="p-2 font-bold">' + (it.item_name||'') + '</td><td class="p-2 text-center">' + (it.qty_delivered||0) + '</td><td class="p-2 text-center font-bold text-rose-600">' + (it.qty_returned||0) + '</td></tr>'; });
```

استبدل هذا السطر وحده بكتلة Patch D في Report553. تُحسب الكمية المتبقية لكل سطر على مستوى `run_sheet_details` هكذا:

`max(0, qty_loaded - qty_delivered - qty_returned)`

ولا تغيّر منطق التسليم أو بدء/إكمال المرتجع أو حركات المخزون أو المحاسبة.

### 3.3 تحقق ساكن على نسخة مؤقتة

على نسخة مؤقتة من Blob الحالي:
- قبل C/D: تحليل JavaScript يفشل بـ`SyntaxError: Invalid or unexpected token`.
- بعد تطبيق C/D افتراضيًا في الذاكرة: تحليل كتلة JavaScript المضمنة ينجح.
- تم استبدال السطر القديم الخاص بصف التفاصيل مرة واحدة.
- لم تتم الكتابة إلى GitHub أو Production من خلال هذا التحقق، ولا تعني النتيجة أن الموقع المنشور أُصلح.

## 4. تحقق Production للبيانات الوظيفية

تم تنفيذ استعلام SQL قراءة فقط مباشرةً على Supabase Production، المشروع `fiilmooggumokxanwiyx`. النتيجة:

| الرانشيت | الحالة | عدد صفوف التفاصيل | إجمالي المتبقي `max(0, loaded-delivered-returned)` | بيانات بدء المرتجع |
|---|---|---:|---:|---|
| `RS-1` | `Delivered` | 5 | 0 | `return_handler_id/start/end = NULL` |
| `RS-2` | `Delivered` | 7 | 5 | `return_handler_id/start/end = NULL` |

إذًا يجب عرض `RS-2` في تبويب المرتجعات باعتباره ينتظر استلام المخزن، قبل أن تبدأ دورة المرتجعات. ولا ينبغي عرض `RS-1` في قائمة المنتظر وفق المعادلة الحالية لأنه لا يملك كمية متبقية.

لم يحدث أي تغيير في Production: لم تُستدعَ عمليات `start-return` أو `complete-return`، ولم تتغير الرانشيتات أو الكميات أو الحركات المخزنية أو القيود المالية أو المستخدمون.

## 5. بوابة CI وإصلاحها

### 5.1 العيب المؤكد

في `.github/workflows/browser_e2e_mother_20260915.yml`، الخطوة القديمة `Assert canonical payroll syntax in Mother source` تشترط وجود:

```text
esc(x.status||'-')])));
```

وتمنع النص التالي:

```text
esc(x.status||'-')]))));
```

هذا افتراض تاريخي غير متوافق مع المصدر الحالي. لذلك يتوقف Browser E2E حتى عندما يكون السبب المطلوب التحقق منه متعلقًا بمرتجعات أو بغيرها. فشل هذه الخطوة لا يثبت خللًا جديدًا في الرواتب؛ بل يثبت أن شرط الاختبار متقادم بالنسبة للمصدر الحالي.

### 5.2 التغيير الذي أُعد للمراجعة

- **Draft PR #7:** [CI: replace stale Parent payroll assertion with current syntax gate](https://github.com/papamohammed77-glitch/erp-frontend/pull/7)
- **Branch:** `fix/mother-e2e-current-syntax-gate-20261029`
- **Commit:** `a38c5d15aadcb5c1af2c310a61077f0a73560b97`
- **الملف الوحيد:** `.github/workflows/browser_e2e_mother_20260915.yml`.
- أضيف محفز `pull_request` لنفس مسارات التغيير حتى يمكن للفحص أن يعمل قبل الدمج، حسب إعدادات وإتاحة إجراءات المستودع.
- استُبدل الشرط النصي القديم ببوابة تستخرج JavaScript المضمن من Parent وتحافظ على أرقام الأسطر، ثم تستخدم `node --check` قبل السماح بوصول المسار إلى Playwright.

**حدود الحالة:** PR #7 مفتوح، Draft، وغير مدموج. لا توجد نتيجة تشغيل CI على commit هذا في البيانات المتاحة حتى وقت كتابة التقرير. لم تتغير إعدادات Cloudflare أو Branch Protection. لذلك لا أدّعي أن CI أصبح حاجز نشر إلزاميًا؛ يلزم إثبات أن checks مطلوبة قبل الدمج أو أن عملية النشر تنتظر نجاحها. بوابة GitHub التي تعمل بعد دفع `main` لا تمنع تلقائيًا نشر Cloudflare ما لم يكن التسلسل/configuration يفرض ذلك.

### 5.3 CI قرار منفصل عن إصلاح Parent

حتى بعد إصلاح Workflow، سيظل فحص JavaScript يفشل على المصدر الحالي حتى يطبق المالك Patch C. لا تدمج PR #7 بوصفه إصلاحًا للتطبيق، ولا تعتبر إعداده بديلًا عن رقع Parent.

## 6. تطبيق المرتجعات المستقل وتطبيق المندوب

### 6.1 Returns PWA

- مصدر `main`: `companies/company-1/warehouse/returns.html`, SHA `36c20e03c94dc734e015610dec1e8208697df32a`.
- **Draft PR #6**: [hardening for standalone Returns query error handling](https://github.com/papamohammed77-glitch/erp-frontend/pull/6).
- Branch: `fix/returns-partial-delivery-visibility-20261029`; commit: `8a4589dc99a4fda418dd61d9508743d4097941d5`; base SHA القديم `585f629d86f6b84038d5b96d0e8851a6ca6579c6).
- مصدر الفرع يزيل `run_sheet_details(count)` غير المستخدم من استعلامي القائمة، ويكشف أخطاء استعلام الرانشيت والكميات بدل تحويلها إلى قائمة فارغة.
- النسخة الحالية على `main` والنسخة في PR #6 اجتازتا فحص JavaScript المضمن. هذا **فحص ساكن** فقط.
- PR #6 لا يعالج خطأ Parent SyntaxError ولا فلتر Parent؛ لذلك لا يُدمج حتى استعادة Parent وتحديث فرعه على أحدث `main` وفق إجراء المراجعة.

### 6.2 Driver PWA

تمت قراءة مصدر `driver.html` الحالي وتحقق تحليل الكتلتين المضمنتين دون خطأ. لا يوجد دليل يربط خطأ JavaScript الحالي بتطبيق المندوب، ولذلك لا حاجة إلى تعديل `driver.html` لمعالجة SyntaxError في Parent.

## 7. حالة Cloudflare والواجهة المنشورة

- تقرير LVE-553 يشير إلى أن واجهة Cloudflare Production metadata كانت تعرض commit `626df80`.
- علامة Cloudflare المتصلة التي أمكن قراءتها في هذه الجولة تحمل لقطة أقدم من الساعة `2026-10-29T17:20:13Z` وتعرض آنذاك commit `585f629`. لا يجوز التعامل مع هذه اللقطة القديمة كدليل على حالة النشر الحالية.
- ملف المصدر الحالي يمكن فحصه مباشرة من GitHub؛ لكن لم تثبت مطابقة بايتية بين Artifact الذي يقدمه Cloudflare وBlob `18d02872a1b204b73fba112f7beb5d9ba95ac72b`.
- لقطة DOM لعلامة الموقع المنشور كانت غير كافية لإثبات جلسة مصادق عليها أو سلامة Console/Network الحالية.

**الحالة:** Artifact identity = `UNVERIFIED`; Browser E2E بعد الإصلاح = `OPEN`; لا ادعاء بإصلاح Production أو نشره.

## 8. Mutation Ledger

- **Parent `main.html`:** لم يتغير بواسطة المساعد؛ لا يزال Blob `18d02872a1b204b73fba112f7beb5d9ba95ac72b` في المصدر الذي فُحص.
- **Returns `returns.html`:** لم يتغير على `main`؛ تعديل PR #6 ما زال Draft.
- **Driver `driver.html`:** لم يتغير.
- **CI:** تعديل Workflow واحد في Draft PR #7 فقط، غير مدموج.
- **Supabase Production:** لا DDL/RPC/RLS/ACL أو بيانات أعمال تم تعديلها في هذه الجولة.
- **Cloudflare:** لم يتم نشر أي ملف أو تغيير أي إعداد.
- **اختبارات المرتجعات:** لم يتم بدء أو إكمال أي مرتجع، ولم تتغير الكميات أو المخزون أو المحاسبة.
- **بيانات الاختبار:** لم تُنشأ صفوف Probe أو بيانات تشغيل صناعية.

## 9. خطة الإغلاق بترتيب إلزامي

1. يعيد المالك جلب `companies/company-1/main.html` ويتأكد من SHA `18d02872a1b204b73fba112f7beb5d9ba95ac72b). إذا تغير، يعاد ضبط محددات الرقع.
2. يطبق Patch C أولًا لإصلاح تحليل JavaScript وحذف بقايا الصف المكررة، ثم Patch D لتوحيد أعمدة تفاصيل الأصناف. لا يلمس Patch A/B أو `loadReturn()` لأنهما موجودان بالفعل في المصدر الحالي.
3. يشغّل فحص JavaScript الكامل والبوابات الساكنة. لا يبدأ E2E إذا فشل التحليل.
4. تُراجع PR #7 وتُشغّل بوابته على المصدر المصحح؛ لا دمج قبل ظهور نتيجة فعلية تؤكد صحة workflow.
5. بعد نشر الإصدار عبر المسار المعتمد، تثبت هوية Artifact المخدوم ثم يُختبر Parent في جلسة مصادق عليها: نجاح تسجيل الدخول، فتح تبويب المرتجعات، ظهور `RS-2` مع 5 وحدات متبقية، وعدم ظهور `RS-1` في قائمة الكميات المنتظرة، ثم فتح التفاصيل والتأكد من أن الأعمدة والقيم متطابقة.
6. يحدّث فرع PR #6 من أحدث `main` بعد إصلاح Parent، ثم يراجع ويدمج وفق المسار المعتمد، وينشر ويختبر Returns PWA بحساب المرتجعات المصادق عليه. التحقق يجب أن يميز أخطاء الشبكة عن قائمة فارغة فعلية.
7. تراجع إعدادات Branch Protection وتسلسل Cloudflare للتأكد من أن فشل syntax gate لا يمكن أن يمر بصمت إلى نشر Production. لا أدّعي أن هذا الضمان قائم قبل فحص الإعدادات الفعلية.

## 10. SELF-AUDIT FINAL

**What I Proved**
- سبب SyntaxError في Parent مثبت من النص الحالي وسجل Node الفعلي.
- رقعتا C وD من Report553 يمكن تركيبهما على Blob الحالي دون خطأ تحليل في نسخة مؤقتة.
- استعلام Supabase Production أعاد `RS-2 pending_return_qty=5` و`RS-1 pending_return_qty=0` للمعادلة الحالية.
- بوابة Browser E2E القديمة متقادمة وتوقف الاختبار قبل Playwright.
- إعداد PR #7 اقتصر على Workflow، بينما PR #6 يظل تحسينًا منفصلًا لتطبيق المرتجعات.

**What I Did Not Prove**
- تطبيق المالك للرقعتين C/D.
- تطابق Artifact Cloudflare بايتًا ببايت مع Blob الحالي.
- نشر الإصلاح أو نجاح جلسة E2E مصادق عليها.
- أن CI/Branch Protection تمنع كل نشر فاشل قبل وقوعه.

**What I Corrected in the Process**
- لم أعد استخدام Blob Report552 الأقدم.
- لم أعد تطبيق Patch A/B لأنهما موجودان في المصدر الحالي.
- لم أخلط تحذير Tailwind مع SyntaxError.
- لم أعدّل Parent أو بيانات Production.
- وثقت تصحيح عدّ عناصر script مقابل كتل JavaScript المضمنة.

**Final Status:** `PARENT ROOT CAUSE CONFIRMED / OWNER PATCH C+D PREPARED AND STATIC-PASS IN MEMORY / CI FIX DRAFT PR #7 / STANDALONE RETURNS PR #6 OPEN / DEPLOYMENT + AUTHENTICATED E2E OPEN / NOT CLOSED`.

**Next exact action:** المالك يطبق Patch C وPatch D وفق المحددات في Report553 بعد تأكيد SHA؛ وبعد ذلك يجب أن يُشغَّل فحص JavaScript وCI، ثم يتم نشر نسخة محددة والتحقق من Artifact قبل أي إعلان إغلاق.
