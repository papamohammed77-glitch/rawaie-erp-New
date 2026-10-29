# Report553 — استعادة إقلاع النظام الأم وإصلاح عرض المرتجعات

**Last Verified Event:** LVE-2026-10-29-553  
**التاريخ:** 2026-10-29  
**النطاق:** إصلاح SyntaxError في Parent main.html والتحقق من عقد عرض الرانشيتات ذات الكميات المتبقية، مع فحص تطبيق المرتجعات المستقل.  
**مرجع الحوكمة:** Report545_GOVERNANCE_AUDIT_AND_DELIVERY_OWNER_PATCH_RESET_20261029.md  
**الحالة:** ROOT CAUSE CONFIRMED / IN-MEMORY PATCH STATIC-PASS / OWNER APPLICATION REQUIRED / DEPLOYMENT + AUTHENTICATED E2E OPEN / NOT CLOSED

## 0. Self-Audit

**Business Understanding:** تبويب مرتجعات المخزن يجب أن يعرض الرانشيت الذي انتهى التوصيل وفيه كمية غير مسلّمة وغير مرتجعة، حتى قبل أن يبدأ المخزن إجراء الاستلام. العرض لا يعني بدء دورة المرتجعات ولا يغيّر الحالة إلى Returned.

**Architecture Understanding:** التكامل يمر عبر Parent main.html، وتطبيق مندوب التوصيل driver.html، وتطبيق المرتجعات returns.html، وعقود Supabase/Edge. إكمال التوصيل يكتب كميات التسليم ويغيّر حالة الرانشيت؛ تطبيق المرتجعات يعرض Delivered ويبدأ دورة المخزن فقط عبر start-return بعد إجراء المستخدم.

**Database Understanding:** runsheets هو سجل الرحلة، وrun_sheet_details يحتوي qty_loaded وqty_delivered وqty_returned. إجمالي المتبقي هو مجموع max(0, qty_loaded - qty_delivered - qty_returned). لا يلزم تعديل قاعدة البيانات لحل الخطأ النحوي الحالي.

**Historical Understanding:** تمت مراجعة Report545 بصفته دستور التنفيذ والملكية، ثم تقارير 546–552. Report552 أثبت فلتر Parent الخاطئ وجهّز Owner patches، لكن Blob المذكور فيه تغيّر. لا يجوز إعادة تطبيق رقع قديمة دون إعادة فحص SHA والنص الحالي.

**Production Understanding:** مستودع التشغيل هو papamohammed77-glitch/erp-frontend، وليس مستودع التقارير. HEAD المرصود هو 626df80fae8101fa6b1fe0ba0b6bc8d4ae69f8ca، وBlob main.html الحالي 18d02872a1b204b73fba112f7beb5d9ba95ac72b. تعرض لوحة Cloudflare Production commit 626df80؛ وسلسلة المصدر تتضمن التغيير المعطوب الذي أدخله commit 151f1ad2cd48645ef1f029b7df417e66d4141eec. سجل CI يثبت فشل فحص Node عند السطر 15839.

**Current Understanding:** توسيع فلتر Delivered وحساب pending_return_qty موجودان بالفعل في المصدر الحالي. الخلل الحرج في _applyReturn هو سلسلة HTML مفردة متعددة الأسطر غير مهربة، مع بقايا مكررة من صف HTML القديم. كما أن عنوان جدول التفاصيل يحتوي خمسة أعمدة بينما حلقة البيانات تخرج أعمدة ناقصة وبترتيب خاطئ.

**Execution Confidence:** مرتفع جدًا في سبب SyntaxError ومحددات الرقعتين بعد تحقق parser في الذاكرة. مرتفع في بيانات Production المقروءة. لا يجوز إعلان الإغلاق قبل تطبيق المالك، واجتياز CI، وإثبات نشر artifact، واختبار Browser/E2E مصادق عليه.

### Confirmed Facts

1. Blob الحالي لملف companies/company-1/main.html هو 18d02872a1b204b73fba112f7beb5d9ba95ac72b، وليس Blob Report552 الأقدم 2951813e53ef7e24d79917bc272f13c95e111cb0.
2. commit 151f1ad أدخل HTML string متعددة الأسطر داخل single-quoted JavaScript string، وأبقى أجزاء من صف HTML القديم بعد نهاية return.
3. GitHub Actions run 40918600126 فشل في خطوة Exact JavaScript syntax gate عند line 15839 مع SyntaxError: Invalid or unexpected token.
4. Run 40918600056 فشل عند prerequisite صيغة JavaScript قبل Playwright؛ وrun 40918599961 فشل في inline JavaScript syntax gate. هذه بوابات فاشلة، وليست إصلاحًا.
5. Production read-only: RS-2 حالته Delivered وله 5 وحدات متبقية في run_sheet_details؛ وreturn_handler_id وreturn_start وreturn_end كلها NULL. RS-1 حالته Delivered ولا يوجد له متبقٍ وفق المعادلة نفسها.
6. لا توجد تغييرات على Production في هذه الجولة: لم تتغير بيانات الأعمال أو المخزون أو الحسابات أو حالات الرانشيت.
7. تطبيق المرتجعات المستقل لديه Draft PR #6 غير مدمج. نسخة الفرع fix/returns-partial-delivery-visibility-20261029 تجتاز تحليل JavaScript وتحتوي معالجة أخطاء الاستعلامات.

### Unknowns

- لم يُثبت التطابق byte-for-byte بين HTML الذي يقدمه Cloudflare وBlob الحالي؛ لوحة Cloudflare تثبت commit النشر، لكن لم تتوفر قراءة موثوقة كاملة لمحتوى الـartifact.
- لم يجرِ Browser E2E مصادق عليه بعد الإصلاح؛ الرقعة لم تُطبّق في المصدر أو تُنشر بعد.
- ظهور بيانات التطبيق المستقل بعد دمج PR #6 ونشره لم يُختبر.

### Conflicts

- Report552 استند إلى Blob أقدم لـmain.html، وليس Blob الحالي.
- المصدر الحالي يحتوي Patch A/B الخاصين بفلتر Delivered وحساب إجمالي المتبقي، لكنه يحتوي أيضًا خطأً نحويًا في Patch C ونقصًا في صف Patch D؛ لذلك لا تعاد رقع A/B ولا تستبدل دالة loadReturn كاملة.

### Unverified Claims

- لا أدّعي أن الإصلاح منشور.
- لا أدّعي أن Console أصبح خاليًا من الأخطاء في Production.
- لا أدّعي أن التكامل مغلق أو وصل إلى 100% CLOSED.

## 1. Source / CI / Production Evidence

| المصدر | الدليل | الحكم |
|---|---|---|
| Operational HEAD | 626df80fae8101fa6b1fe0ba0b6bc8d4ae69f8ca | CONFIRMED |
| Current main.html blob | 18d02872a1b204b73fba112f7beb5d9ba95ac72b | CONFIRMED |
| Commit الذي أدخل الخلل | 151f1ad2cd48645ef1f029b7df417e66d4141eec | CONFIRMED |
| Full forensic syntax gate | Run 40918600126؛ فشل عند line 15839 | CONFIRMED |
| Parent browser-E2E gate | Run 40918600056؛ فشل prerequisite قبل Playwright | CONFIRMED |
| Cloudflare Production metadata | تعرض commit 626df80 | CONFIRMED؛ محتوى artifact نفسه غير مطابق byte-for-byte بعد |
| Production DB | RS-2 pending return qty=5، وRS-1=0 | CONFIRMED بقراءة SQL |
| تطبيق الرقعة على المصدر | لم يحدث | CONFIRMED |
| Deploy وAuthenticated E2E بعد الإصلاح | لم يحدثا | OPEN |

## 2. السبب الجذري المؤكد في Parent Return tab

### 2.1 SyntaxError

داخل _applyReturn()، يبدأ نطاق العيب عند أول سطر يبدأ بـ:

~~~javascript
            var statusLabel = r.status === 'Delivered' && Number(r.pending_return_qty) > 0
~~~

وينتهي نطاق الاستبدال مباشرة قبل سطر إغلاق callback الذي يلي بقايا HTML القديمة:

~~~javascript
        });
~~~

المقصود بهذا المحدد هو إغلاق callback نفسه لـRW_Table.paginate، وليس إغلاقًا آخر. يجب الاحتفاظ به وبقوس إغلاق _applyReturn وبداية async function _showReturnDetails(code).

سبب الانهيار أن return string افتُتحت بعلامة اقتباس مفردة ثم امتدت عبر أسطر فعلية دون concatenation، وبعدها بقي صف HTML قديم مكرر خارج return. هذا يطابق خطأ Node وموضعه line 15839. تحذير cdn.tailwindcss.com ليس سبب SyntaxError.

### 2.2 Owner Surgical Patch C — صف قائمة الرانشيت

**الملف:** companies/company-1/main.html  
**حماية SHA:** لا تُطبق إلا إذا بقي Blob SHA هو 18d02872a1b204b73fba112f7beb5d9ba95ac72b، وكان محدد البداية موجودًا مرة واحدة وكان حد النهاية هو إغلاق callback المذكور. عند اختلاف SHA أو النص أو عدد المطابقات، أعد بناء الرقعة على النسخة الجديدة ولا تلصقها عميانيًا.

**البداية الدقيقة:** أول سطر var statusLabel = r.status === 'Delivered'... داخل callback لـRW_Table.paginate في _applyReturn.

**النهاية الدقيقة:** مباشرة قبل سطر الإغلاق المحفوظ        }); الذي يغلق callback، بعد إزالة كل بقايا HTML القديمة المكررة. لا تستبدل الدالة كاملة.

استبدل المنطقة المحددة فقط بالنص التالي:

~~~javascript
            var statusLabel = r.status === 'Delivered' && Number(r.pending_return_qty) > 0
                ? 'بانتظار المرتجع: ' + Number(r.pending_return_qty).toLocaleString('ar-EG') + ' وحدة'
                : esc(r.status || '—');
            var safeRunsheetCode = String(r.runsheet_code || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showReturnDetails(\'' + safeRunsheetCode + '\')">' +
                '<td class="p-3 font-bold">' + esc(r.runsheet_code || '') + '</td>' +
                '<td class="p-3">' + esc(r.run_date || '') + '</td>' +
                '<td class="p-3">' + esc(r.driver_id || '---') + '</td>' +
                '<td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-rose-100 text-rose-700">' + statusLabel + '</span></td>' +
                '<td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td></tr>';
~~~

**بعد الاستبدال:** يأتي سطر الإغلاق المحفوظ        }); مباشرة بعد النص أعلاه، ثم قوس الدالة. لا تترك أي td من الصف القديم بين return وهذا الإغلاق. هذا الأسلوب يتجنب newline داخل string مفردة، ويهرب runsheet_code قبل إدراجه في inline handler، ويستخدم esc للنصوص المعروضة.

### 2.3 Owner Surgical Patch D — صف تفاصيل الأصناف

عنوان جدول التفاصيل الحالي يحتوي خمسة أعمدة: الصنف، المحمّل، المسلّم، المتبقي للمرتجع، المرتجع. حلقة الأصناف الحالية تعرض قيمتين فقط وتضع qty_delivered تحت عنوان المحمّل.

**المحدد الأصلي الفريد، يجب أن يظهر مرة واحدة:**

~~~javascript
        items.forEach(it => { h += '<tr><td class="p-2 font-bold">' + (it.item_name||'') + '</td><td class="p-2 text-center">' + (it.qty_delivered||0) + '</td><td class="p-2 text-center font-bold text-rose-600">' + (it.qty_returned||0) + '</td></tr>'; });
~~~

استبدل هذا السطر وحده بالكتلة التالية، وأبقِ عنوان الجدول ودالة _showReturnDetails وباقي الملف كما هي:

~~~javascript
        items.forEach(it => {
            var loaded = Number(it.qty_loaded) || 0;
            var delivered = Number(it.qty_delivered) || 0;
            var returned = Number(it.qty_returned) || 0;
            var remaining = Math.max(0, loaded - delivered - returned);
            h += '<tr><td class="p-2 font-bold">' + esc(it.item_name || '') + '</td>' +
                '<td class="p-2 text-center">' + loaded + '</td>' +
                '<td class="p-2 text-center">' + delivered + '</td>' +
                '<td class="p-2 text-center font-bold text-amber-700">' + remaining + '</td>' +
                '<td class="p-2 text-center font-bold text-rose-600">' + returned + '</td></tr>';
        });
~~~

**تحقق قبل الحفظ:**
- محددا Patch C وPatch D موجودان مرة واحدة فقط.
- لا يتغير أي سطر في loadReturn أو في الأجزاء التي تسبق/تلي الرقعتين.
- لا تتغير Edge Functions أو RLS أو بيانات Production.
- صف التفاصيل يعرض qty_loaded ثم qty_delivered ثم max(0, loaded-delivered-returned) ثم qty_returned.
- لا تخلط بين مستوى الرانشيت في run_sheet_details ومستوى الأوردر في order_details.

## 3. نتائج الاختبار الساكن

تم جلب نص main.html الحالي من GitHub Blob والعمل على نسخة في الذاكرة فقط. بعد تطبيق التصحيحين على النسخة المؤقتة، فُحصت كتل JavaScript الست:

| الاختبار | قبل | بعد الرقعة الافتراضية |
|---|---:|---:|
| كتل JavaScript المضمنة | 6 | 6 |
| أخطاء التحليل | 1 | 0 |
| موضع الخطأ | line 15839، Invalid or unexpected token | لا أخطاء تحليل في الكتل الست |
| تحديد نطاق Patch C | فريد | فريد |
| مطابقة سطر Patch D | مرة واحدة | استُبدل مرة واحدة |
| بقايا HTML مكررة خارج return | موجودة | أزيلت من نسخة الذاكرة |

هذه نتيجة static parse على نسخة مؤقتة، وليست إثبات إصلاح أو نشر Production.

## 4. نتيجة Production — قراءة فقط

| Runsheet | الحالة | عدد صفوف التفاصيل | إجمالي المتبقي للمرتجع | حقول دورة المرتجع |
|---|---|---:|---:|---|
| RS-1 | Delivered | 5 | 0 | return_handler_id / return_start / return_end = NULL |
| RS-2 | Delivered | 7 | 5 | return_handler_id / return_start / return_end = NULL |

هذا يثبت أن RS-2 يجب أن يظهر في تبويب المرتجعات بوصفه بانتظار المرتجع قبل بدء الاستلام؛ أما RS-1 فلا يملك كمية متبقية وفق المعادلة الحالية. لم يتم استدعاء start-return أو complete-return ولم تتغير أي حالة أو كمية.

## 5. تطبيق المرتجعات المستقل

**Current source before review patch:** companies/company-1/warehouse/returns.html، Blob SHA 36c20e03c94dc734e015610dec1e8208697df32a.

**الخلل المؤكد في المصدر:** App.loadRunsheets() يطلب run_sheet_details(count) كعلاقة متداخلة غير مستخدمة في استعلامي قائمة الرانشيتات، ثم يجلب التفاصيل مرة أخرى لحساب المتبقي. كما كان يتجاهل error objects ويحول data=null إلى قائمة فارغة، مما يخفي فشل القراءة على أنه عدم وجود بيانات.

**الرقعة الحالية للمراجعة:** Draft PR #6، الفرع fix/returns-partial-delivery-visibility-20261029، commit 8a4589dc99a4fda418dd61d9508743d4097941d5. الملف الوحيد المعدّل returns.html؛ أزيلت العلاقة المتداخلة من الاستعلامين وأُضيف فحص خطأ الاستعلام الأساسي واستعلام الكميات مع رسائل واضحة.

**التحقق:** نسخة الفرع الحالية من returns.html تحتوي 8 كتل JavaScript مضمنة، واجتازت static parse بلا أخطاء. لكن PR ما زال Draft/open وغير مدمج، ولم يُنشر ولم يُختبر في جلسة Returns مصادق عليها. لا يعتبر ذلك إصلاحًا منشورًا.

لا يلزم تعديل driver.html لإصلاح SyntaxError في Parent. يظل تطبيق المندوب جزءًا من دورة تحديث التسليم، لكن العطل القاتل الحالي يقع في _applyReturn داخل main.html.

## 6. إجراءات لم تُنفذ عمدًا

- لم يكتب المساعد إلى Parent main.html؛ Report545 يخصص هذا الملف المحمي للمالك مع Owner Surgical Change Set.
- لم تُجرَ أي تعديلات Production SQL أو DDL أو RPC أو RLS أو ACL.
- لم يتم تغيير أي رانشيت أو كمية أو حركة مخزنية أو قيد محاسبي.
- لم يتم تعديل driver.html أو core.js أو Edge Functions.
- تحذير cdn.tailwindcss.com مسجل كـTechnical Debt منفصل، وليس سبب الحادثة.
- لم يُدمج PR #6 ولم يُعلن نجاح Production E2E.

## 7. خطوات الإغلاق الدقيقة

1. يعيد المالك جلب main.html ويتأكد أن SHA لا يزال 18d02872a1b204b73fba112f7beb5d9ba95ac72b.
2. يطبق Patch C بالحدود المحددة ثم Patch D على السطر المطابق مرة واحدة فقط.
3. يشغل فحص JavaScript الكامل والبوابات ذات الصلة في GitHub Actions. لا يبدأ Browser E2E قبل نجاح بوابة Syntax.
4. بعد نشر commit الناجح، تتحقق هوية Cloudflare served artifact ثم يجري اختبار مصادق عليه: تسجيل الدخول، فتح تبويب المرتجعات، ظهور RS-2 مع 5 وحدات متبقية، وفتح التفاصيل للتأكد من تطابق الأعمدة والقيم.
5. يراجع PR #6 ويدمجه عبر مسار المراجعة المعتمد، ثم ينشر ويختبر App.loadRunsheets بحساب مرتجعات مصادق عليه.
6. عند أي فشل، يسجل HTTP status ورسالة الخطأ بعد تنقيح البيانات الحساسة، ويطابق artifact المخدوم قبل إضافة أي تعديل جديد.

## 8. SELF-AUDIT FINAL

**What I Proved**
- سبب SyntaxError هو return string متعددة الأسطر مع بقايا HTML مكررة، وسجل Node/CI يطابق line 15839.
- الرقعتان المقترحتان أصلحتا الكتل المعنية في نسخة الذاكرة؛ parser اجتاز الكتل الست بلا أخطاء.
- Production data يثبت RS-2 Delivered مع 5 وحدات متبقية، وRS-1 مع صفر متبقٍ.
- مصدر returns.html يحتوي عيب تجاهل أخطاء الاستعلام، ونسخة PR #6 تجتاز static parsing.

**What I Did Not Prove**
- لم تُطبق رقعتا المالك بعد.
- لم يُثبت التطابق byte-for-byte بين artifact المنشور وBlob المصدر.
- لم يحدث Browser E2E بعد الإصلاح، ولم يُدمج PR #6 أو ينشر.

**What I Fixed**
- أعددت رقعتي Owner surgical بحدود صريحة واختبرتهما في الذاكرة.
- لم أكتب تغييرات إلى المصدر المحمي أو Production.

**What I Initially Missed**
- Blob Report552 لم يعد حديثًا.
- مصدر main يحتوي بالفعل Patch A/B، لكن Patch C تسبب في SyntaxError، وPatch D ترك صف التفاصيل غير متوافق مع الرأس.

**What Could Still Be Wrong**
- قد توجد أخطاء تشغيلية إضافية لا يمكن تقييمها قبل استعادة syntax وتشغيل الاختبارات.
- هوية artifact المخدوم وسلوك الواجهة المصادق عليها بعد الإصلاح ما زالا غير مثبتين.
- تطبيق المرتجعات المستقل يحتاج دمجًا ونشرًا وE2E مستقلًا.

**Final Confidence:** مرتفع في Root Cause والرقعة الساكنة؛ غير كافٍ لإغلاق Production.

**Final Closure Status:** ROOT CAUSE CONFIRMED / OWNER PATCH PREPARED AND STATIC-PARSED / PR #6 STILL DRAFT / DEPLOYMENT + AUTHENTICATED E2E OPEN / NOT CLOSED.
