# Report711 — المراجعة التشغيلية للمخزن الشامل: الصور، التحميل، المرتجعات، وآثار Production
**التاريخ:** 2026-11-12 — مراجعة مسائية بتوقيت القاهرة  
**Checkpoint:** LVE-2026-11-12-710 → LVE-2026-11-12-711  
**الحكم:** READY WITH LIMITATIONS  
**النطاق:** Warehouse Hub / Picker / Loader / Returns / Supabase Production read-only / GitHub source / CI evidence

---

## 1. نقطة البداية والاستئناف

- تمت قراءة CURRENT_STATE.md كاملًا على دفعات؛ Blob SHA: `e4d0d109f70d72b80b718b2b0154110d16946513`. آخر نقطة مسجلة قبل هذه المراجعة: **LVE-2026-11-12-710**.
- تمت قراءة الدستور التشغيلي الدائم كاملًا؛ Blob SHA: `3a6b1e220af8509e314e94df76563bbc6f84910d`.
- تمت مراجعة Report710 وReport709 كاملين:
  - Report710: `ffb31eceb4483549e4210aaa5b1539497ceb07be`.
  - Report709: `df54cd4df8fce4eb32794cf739b4b6e707e1ab19`.
- تمت مراجعة بوابة الموافقة ذات الصلة في MASTER CTO GOVERNANCE؛ Blob SHA: `1a0c81c2984103b5a7f3b40db41607d74051b310`، وبالأخص §§77.2–77.3.
- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`, الفرع `main`, HEAD = `903a1fe22c3ec2f8f4f7a3ffeb45d1d8025e306d`. هذا هو نفس HEAD المثبت في LVE-710؛ لم يظهر Commit تشغيلي أحدث.
- مستودع الحالة: `papamohammed77-glitch/rawaie-erp-New`, الفرع `main`, HEAD قبل هذا التقرير = `7ddd192cd3e4f6d2b5702cf4fbbb574fde582035`.
- الهدف التنفيذي المستمر: إثبات أن إصلاح تحميل صور Picker وصل إلى الوحدة المضمّنة، وأن Loader وReturns متماثلان وظيفيًا مع الأصل، وأن مساحة Returns لا تكسر Scroll أو DOM/Keyboard isolation.

## 2. CONFIRMED

### Source Code
- Warehouse Hub الحالي: `companies/company-1/warehouse/warehouse.html`, Blob `41bab8f092dbb5ac1adf32ef34d5feaf92b8dc6e`.
- Picker الأصلي: `picker.html`, Blob `312b5e387daf2248737749c246c0174095535eac`.
- Loader الأصلي: `loader.html`, Blob `89aea6635771f1a3328e82a456f3ecfe9ee02acd`.
- Returns الأصلي: `returns.html`, Blob `39755507bc01331135a1640af5a87a22051ee3e7`.
- Core: `companies/company-1/core.js`, Blob `2d11b852862c523fc89e6a8b9c510462bb65cc4e`.
- Parent: `companies/company-1/main.html`, Blob `caf3af2cb3bf8f482d696dacfa2045d322ddd6b0`. تم جلب الـBlob نفسه بعد أن أعاد fetch_file محتوى فارغًا بسبب كبر الملف؛ رابط المخزن الشامل موجود ضمن قائمة المخازن ومقيّد بصلاحية warehouse.
- المقارنة من Commit `09dd0a738a2378abaee7f61ec86cd60ca11f7a4f` إلى HEAD الحالي أثبتت أن التغييرين ضمن النطاق هما Warehouse Hub وWorkflow؛ لم تتغير ملفات Loader/Returns/Picker الأصلية أو Parent/Core في هذه السلسلة.

### Picker image cache
- النسخة المضمّنة تحتوي مسار تهيئة بعد RW_Auth.init: تثبيت company_id الموثق، مسح كاش الوحدة، تنفيذ قراءة items محددة بـ company_id، تخزين image_url حسب item_code، ثم استدعاء refreshVisibleImages لتحديث mainContent ونافذة Swal المفتوحة.
- يتم تجاهل نتيجة القراءة إذا تغيّر company_id قبل اكتمال الطلب؛ وتبقى آلية onerror/fallback موجودة.
- لا يوجد مبرر لتوسيع RLS أو تخفيف الصلاحيات لمعالجة هذا المسار.
- هذا الكاش خاص بوحدة Picker المضمّنة؛ لا يعتمد على RW_ImageCache العام في core.js.

### Loader / Returns parity
- Loader: سطح الدوال المقارن = 30 method؛ أسماء الدوال، مجموعات RW_API.call، وجداول Supabase المقروءة متطابقة بين الأصل والنسخة المضمّنة.
- Returns: سطح الدوال المقارن = 37 method؛ أسماء الدوال، مجموعات RW_API.call، وجداول Supabase المقروءة متطابقة بين الأصل والنسخة المضمّنة.
- أجسام وظائف دورة التحميل startLoading / completeLoading / cancelLoading / reopenLoading متطابقة بعد تطبيع أسماء واجهة الوحدة.
- أجسام وظائف دورة المرتجعات startReturn / completeReturn / cancelReturn / reopenReturn متطابقة بعد تطبيع أسماء واجهة الوحدة.
- مساعدا الصور في Loader (_loaderImageHTML و_bindLoaderImageFallbacks) متطابقان؛ ومساعد صورة Returns returnItemImageHTML متطابق بعد تغيير اسم المساعد الداخلي.
- renderActiveSession في Returns متطابق وظيفيًا بعد تطبيع مرجع App إلى واجهة الوحدة المضمّنة؛ الفروق المرصودة مقتصرة على أسماء الربط والعزل.
- HTML المرئي للأصل والنسخة المضمّنة متكافئ بعد تطبيع inline handlers. زر حسابي الخاص بالوحدة حُذف من مساحة الوحدة، لكن يوجد حساب موحد في Hub يعرض الهوية والدور ونطاق الفروع، ويوجد زر خروج عام في Header. لا يوجد فقد لوظيفة تسجيل الخروج؛ اختلاف التسمية الوظيفية الخاصة بكل تطبيق أصبح عرضًا موحدًا.
- لا توجد مستمعات keydown/keyup عامة في Loader أو Returns المضمّنين.

### Returns workspace CSS
- قاعدة الحاوية القديمة التي كانت تجعل وحدة Returns نفسها fixed وبأبعاد 100% وoverflow hidden لم تعد موجودة في CSS الحالي.
- الحاوية الحالية محددة الارتفاع، position: relative، وoverflow: auto؛ وداخلها mainContent قابل للتمرير.
- Workflow الحالي يتضمن اختبارًا لحدود الحاوية والتمرير وصور Loader/Returns وfallback، وليس مجرد فحص وجود الدوال.

### Supabase Production
- حالة المشروع SMART ERP: ACTIVE_HEALTHY.
- آخر Migration مطبق: `20261110233152 returns_discrepancy_integrity_gate_20261111`; لم تظهر Migration أحدث.
- RLS الحالي:
  - items: قراءة الشركة لمن يملك effective warehouse permission.
  - app_settings: قراءة المستخدم النشط ضمن شركته.
  - stock_branches: قراءة ضمن الشركة/الفرع وبصلاحيات المخزن الفعلية.
  - runsheets وrun_sheet_details: قراءة ضمن الشركة وصلاحية المخزن/المسار المسموح.
- Storage bucket `product-images` عام؛ يحتوي 65 object. جميع روابط Supabase Storage الثمانية عشر الموجودة في كتالوج الأصناف لها object مطابق.
- سجل Storage يثبت GET 200 للصورتين المستخدمتين في بيانات RS-3/RS-4 عند 2026-11-12 15:10:28 UTC.
- جداول items: 35 صنفًا، 34 لها image_url؛ 16 Googleusercontent و18 Supabase Storage ولا توجد فئة ثالثة في العينة الحالية.
- بيانات RS-3/RS-4: سبعة أسطر؛ خمسة أسطر Googleusercontent وسطران Supabase Storage، مع أربعة أكواد Google متميزة بسبب تكرار أحد الأصناف.
- بيانات RS-1/RS-2 الحالية تستخدم Googleusercontent لكل أسطرها؛ RS-1 حالته Delivered وRS-2 حالته Returned.

### Returns integrity / Edge Functions
- Edge Functions الحالية نشطة وverify_jwt=true:
  - start-picking v36, complete-picking v19, cancel-picking v6, reopen-picking v10.
  - start-loading v7, complete-loading v12, cancel-loading v6, reopen-loading v4.
  - start-return v6, complete-return v28, cancel-return v6, reopen-return v2, report-discrepancy v4.
- reopen-return v2 موجود لكنه Fail-Closed ويرد REOPEN_RETURN_TEMPORARILY_DISABLED / HTTP 409؛ لا يعيد فتح مرتجع مرحّل.
- complete-return v28 يتحقق من أن الرانشيت Returning ومسند إلى المستخدم قبل RPC المركزي.
- report-discrepancy v4 يتحقق من الشركة والرانشيت والمستخدم والصنف قبل إدخال البلاغ.
- Trigger `trg_stock_discrepancies_integrity` وTrigger `trg_runsheets_unresolved_discrepancy_close_guard` مفعّلان في Production.

### CI
- Workflow: `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`, Blob `298441d0b6db8a83bde7d92b19b0cf3b0a27c30f`.
- Run `43276131519` على HEAD `903a1fe...` انتهى success؛ Job `warehouse-hub-browser-e2e` وجميع خطواته ناجحة.
- الاختبارات تشمل syntax/structure، parity surface، image renderer/fallback، bounded Returns scroll، وfail-closed completed-return UI.
- هذه اختبارات CI ببيانات/طلبات اصطناعية محلية؛ ليست إثباتًا لظهور صور Production أو استلام Realtime فعلي.

### Business data effects — QMP receiving
- ظهرت ثلاث جلسات استلام QMP مكتملة مرتبطة بفاتورتي PINV-1002 وPINV-1003، وخمسة أسطر استلام دون فروق.
- PINV-1002: كمية الفاتورة 20، المستلم 20، PurchaseIn = 20، وخروج عهدة البضاعة من المشتري = 20.
- PINV-1003: كمية الفاتورة 9، المستلم 9، PurchaseIn = 9، وخروج عهدة البضاعة من المشتري = 9.
- الفاتورتان من QUICK_MARKET، مرتبطتان بموردين موجودين، وحالتهما Draft مع receipt_status=RECEIVED وsettlement_status=UNSETTLED وpaid_amount=0.
- لا توجد قيود journal_entries أو حركات supplier_ledger لهاتين الفاتورتين؛ لذلك لم يثبت أثر سداد/ذمة محاسبية. الأثر المثبت هو استلام فعلي مسجل، زيادة مخزون، وخفض عهدة بضاعة المشتري بالمقدار نفسه.
- التكرار الظاهري لـ PINV-1002 ليس تكرار كمية: جلسة 2026-11-11 استلمت 15، وجلسة 2026-11-12 استلمت 5؛ الإجمالي 20 يساوي كامل كمية الفاتورة. PINV-1003 استلمت 9/9. لا توجد فروق استلام.
- هذه سجلات أعمال موجودة بالفعل وليست بيانات QA معلّمة؛ لم نعدّلها ولم نحذفها ولم نعتبرها اختبارًا.

## 3. UNKNOWN

- لا يمكن إثبات أن روابط Googleusercontent قابلة للتحميل من متصفح المستخدم الآن؛ أدوات فتح الرابط لم توفر استجابة HTTP قابلة للتحقق.
- لا يمكن إثبات ظهور الصور في جلسة Production المصادق عليها أو قياس naturalWidth/Network من المتصفح في هذا التشغيل.
- لا يمكن إثبات أن Artifact المنشور حاليًا يطابق HEAD 903a1fe byte-for-byte؛ آخر دليل Dashboard في Report710 يشير إلى Production main عند 903a1fe، لكنه لم يُعاد فحصه حيًا هنا.
- لا يمكن إثبات استلام أحداث Realtime في Runtime؛ وجود publication واشتراك في المصدر لا يثبت وصول الحدث.
- لا توجد بيئة Staging منفصلة مثبتة. قائمة Supabase أعادت فرعًا واحدًا باسم main مع with_data=false؛ لا أتعامل معه تلقائيًا كبيئة QA معتمدة.

## 4. CONFLICT

- يوجد تعارض حوكمي بين §6.4 من الدستور (سياسة QA تاريخية تسمح ببيانات اصطناعية مؤقتة على Production وتستبعد Staging) وبين §19 من تعليمات المالك الحالية (تمنع إنشاء بيانات/عمليات اختبار في Production وتطلب Staging/بيئة معزولة، وأي استثناء يحتاج موافقة منفصلة وصريحة).
- تطبيقًا لترتيب الحاكمية، تم اتباع توجيه المالك الأحدث والأكثر حماية: لا إنشاء بيانات QA أو عمليات اختبار في Production. لم تُنشأ أي بيانات أو عمليات اختبار في هذا التشغيل. يلزم حسم تعارض النصوص في تحديث دستوري لاحق، دون تجاوز التوجيه الأحدث.

## 5. UNVERIFIED

- نجاح CI لا يثبت أن النسخة المنشورة تحتوي الإصلاح أو أن Googleusercontent يعيد صورة.
- نجاح GET 200 لصور Supabase Storage لا يثبت نجاح روابط Googleusercontent.
- اكتمال استقبال PINV-1002/PINV-1003 مثبت على مستوى السجلات والمخزون والعهدة، لا على مستوى مشاهدة البضاعة ميدانيًا.
- لا يوجد اختبار متصفح مصادق عليه لهذه المراجعة؛ أداة Browser لم توفر جلسة متصفح قابلة للقراءة، ولم يمكن جلب صفحات pages.dev أو روابط Google عبر أداة الويب.

## 6. مصفوفة التحقق

| الطبقة | النتيجة | الدليل | الحد |
|---|---|---|---|
| GitHub / Source | CONFIRMED | HEAD 903a1fe والـBlobs أعلاه | لا Commit أحدث |
| Supabase Production | CONFIRMED read-only | RLS، migrations، Edge versions، inventory/receiving/custody | لا كتابة ولا DDL |
| Deployed Artifact | UNVERIFIED حاليًا | آخر لقطة Dashboard في Report710 | لم تُقرأ HTML bytes الآن |
| Runtime / E2E | CI PASS فقط | Run 43276131519 | لا جلسة Production |
| Business Data Effects | CONFIRMED على السجلات | PurchaseIn + custody events + invoice reconciliation | لا مشاهدة ميدانية |
| Staging | UNKNOWN | branch list أعاد main فقط بلا بيانات | لا بيئة QA منفصلة مثبتة |

## 7. ما تم فعليًا في هذه المراجعة

1. استعادة CURRENT_STATE والدستور والتقارير المرجعية.
2. التحقق من HEAD والـCommits والملفات الحالية والـWorkflow.
3. إعادة مقارنة Loader/Returns الأصليين بالمضمّنين: HTML handlers، method surfaces، API/table contracts، lifecycle methods، image helpers.
4. فحص CSS الخاص بـReturns ومساحة العمل والتمرير.
5. فحص RLS وStorage وMigrations وEdge Function versions وTriggers.
6. فحص سجلات Edge وAudit وInventory وReceiving وBuyer Goods Custody.
7. تسوية PINV-1002/PINV-1003 من كمية الفاتورة إلى الاستلام والمخزون وعهدة البضاعة والقيود المالية.
8. لم تُنفذ أي كتابة في المستودع التشغيلي أو قاعدة Production خلال الفحص.

## 8. ما لم يتم ولماذا

- لم تُنفذ أي تعديلات تشغيلية؛ لا يوجد عيب جديد مثبت في Loader/Returns parity، وأي تغيير في التطبيقات التشغيلية يحتاج Change Set محددًا وموافقة المالك وفق الدستور.
- لم تُنفذ عمليات بدء/إكمال/إلغاء Picking أو Loading أو Returns؛ لأنها تغيّر حالات تشغيلية أو أرصدة.
- لم تُنشأ بيانات QA في Production التزامًا بتوجيه المالك الأحدث.
- لم يُنفذ Browser E2E على Production لغياب جلسة متصفح مصادق عليها وإمكانية قراءة Artifact الحالي.
- لم يُنفذ أي تغيير RLS أو Storage أو Edge Function أو Migration.

## 9. صحة التطبيقات ونطاق التغطية

| التطبيق | فُحص اليوم | الحالة | ما لم يثبت |
|---|---|---|---|
| Warehouse Hub | نعم | المصدر الحالي وسبعة bundles متاحة | Artifact/Runtime |
| Picker | نعم | كاش صور مضمّن scoped بالشركة؛ preflight للمخزون في المصدر | ظهور الصور في Production |
| Loader | نعم | parity مع الأصل؛ اشتراك runsheets + reconciliation كل 60 ثانية | جلسة تحميل حية وصور فعلية |
| Returns | نعم | parity مع الأصل؛ صور وfallback؛ reopen fail-closed | جلسة مرتجعات حية وصور Google |
| Parent main | فحص رابط/صلاحية | رابط Hub موجود | اختبار تشغيل Parent |
| Core | فحص الوحدات ذات الصلة | RW_Auth/RW_ImageCache/RW_Realtime موجودة | مراجعة جميع مستهلكي Core |
| بقية التطبيقات | لم تُفحص اليوم | لا استنتاج عن سلامتها | خارج نطاق الدورة الحالية |

## 10. تدقيق التعديلات الأخيرة وآثارها

- `4803cdf2e6eb875eb904f62e6d4d81c2feb7fc58`: عزل CSS ومساحة الوحدة واختبارات المتصفح.
- `26ba0894fe67ec962c921f229a86e5b44b19fa9e`: تصحيح صياغة Workflow.
- `903a1fe22c3ec2f8f4f7a3ffeb45d1d8025e306d`: إصلاح تحميل صور Picker داخل الوحدة المضمّنة.
- لم تتغير ملفات Loader/Returns الأصلية؛ لم يُنشأ منطق أعمال موازٍ؛ لم تُنشأ Edge Functions جديدة.
- سجلات Production بين 16:10 و16:16 UTC تظهر ست محاولات POST إلى complete-picking v19 بنتيجة 400. قبلها start-picking v36 أعاد 200، وبعدها cancel-picking v6 أعاد 200؛ Audit يثبت أن RS-3 وRS-4 عادا إلى Open.
- لا توجد inventory_log أو erp_operation_registry rows بين 16:00 و17:10 UTC؛ لا دليل على حركة مخزون أو حجز ناتج من محاولات الإكمال الفاشلة.
- هذه المحاولات سبقت Commit 903a1fe؛ لذلك لا تثبت فشل preflight الجديد ولا نجاحه بعد النشر.

## 11. الأخطاء والفجوات والحلول

| الأولوية | الفجوة | الدليل | الحل الآمن / معيار القبول |
|---|---|---|---|
| P1 | نقص سجل stock_branches لبعض أصناف RS-3/RS-4 | ITM-20260939 وITM-20260938 بلا سجل؛ 1010 متاح 1 مقابل طلب 2 | لا تُنشأ أرصدة يدويًا. تُراجع حركة/رصيد الصنف عبر المسار المخزني المعتمد؛ يجب أن يمنع preflight الإرسال عند العجز |
| P2 | روابط Googleusercontent هي المصدر لكل أسطر RS-1/RS-2 | Production DB | فحص HTTP/Browser فعلي؛ إن فشلت الروابط يُعرض Change Set لنقل الصور إلى Storage، لا تعديل بيانات الآن |
| P2 | Picker وReturns بلا اشتراك Realtime أو polling للبيانات التشغيلية | المصدر الحالي | Change Set لاحق يضيف اشتراكًا scoped بالشركة وإعادة reconciliation، بعد موافقة المالك واختبار عدم التكرار |
| P2 | Loader يشترك في runsheets فقط لا run_sheet_details | startRealtime الحالي | تقييم الحاجة لاشتراك details أو invalidation مركزي؛ لا تعديل قبل قياس stale state |
| P2 | moduleDocument يسمح fallback إلى document العام عند فشل العثور داخل moduleRoot | Proxy الحالي | تقوية العزل تدريجيًا واختبار selectors المفقودة/المكررة؛ لم يثبت تسرب فعلي |
| P2 | اختبار Scroll لم يغطِ هاتفًا قصير الارتفاع | Workflow يستخدم viewport مكتبيًا؛ min-height 480/520px | إضافة viewport mobile E2E قبل اعتماد المظهر الميداني |
| P3 | Tailwind CDN ما زال موجودًا في Warehouse/Picker/Loader/Returns | source search | إزالة تحذير الإنتاج عبر build محلي بعد Change Set مستقل؛ ليس سببًا مثبتًا لمشكلة الصور |
| P2 | فرعا main في المستودعين غير محميين ولا توجد Rulesets | GitHub branch metadata وrulesets API | تفعيل حماية main وRequired Checks بموافقة المالك |

## 12. الكفاءة التشغيلية والميدانية

- Quick Market → PurchaseInvoice → Receiving → PurchaseIn → Buyer Goods Custody: مثبت على السجلات في PINV-1002 وPINV-1003؛ الكمية المستلمة تطابق الفاتورة، وأثر المخزون يساوي خروج عهدة البضاعة من المشتري.
- لا أثر محاسبي أو سداد مثبت للفواتير المذكورة: Draft، UNSETTLED، paid_amount=0، ولا journal_entries أو supplier_ledger rows مرتبطة بها.
- Picking: غير مكتمل في RS-3/RS-4 بسبب نقص سجل/رصيد صنفين؛ لا توجد حركة مخزون من محاولات الإكمال الفاشلة.
- Loading: توجد بيانات تاريخية لـRS-1، لكن لا توجد حالة Picked/Loading مفتوحة حاليًا في عينة الحالة الحالية.
- Returns: RS-1 Delivered وRS-2 Returned؛ كل أسطرهما تستخدم Googleusercontent، ما يجعل فحص الصور الفعلي مهمًا.
- لا يوجد إثبات ميداني مستقل لمشاهدة البضاعة أو دقة الكميات الفعلية؛ الموجود إثبات سجلات مترابطة.

## 13. التخطيط والتنبؤ ومركز القرار الذكي

لم يُقَس في هذه الدورة. لا توجد بيانات كافية هنا لإثبات توقع طلب أو دقة تنبؤ أو توصية شراء. الحالة UNKNOWN.

## 14. المقارنة التنافسية

لم يُنفذ Benchmark جديد في هذه الدورة؛ لا توجد دعوى تكافؤ مع SAP/Dynamics/Odoo/Next. يلزم نطاق مستقل ومصادر رسمية ومقاييس قابلة للمقارنة.

## 15. مصفوفة النضج — نطاق المخزن الشامل فقط

| المجال | الدرجة | الثقة | السبب |
|---|---:|---|---|
| السلامة التقنية والمعمارية | 3/5 | متوسطة | Hub وCore ووحدات مضمّنة مع CI؛ Artifact/Runtime غير مثبت |
| تكامل التطبيقات والبيانات | 2/5 | مرتفعة | Receiving/Custody مترابطان؛ Picker/Returns بلا Realtime |
| العمليات التجارية | 2/5 | متوسطة | الاستلام مثبت سجليًا؛ Picking متوقف لبعض الأصناف |
| الرقابة المالية | 2/5 | متوسطة | فصل Draft/receipt/settlement ظاهر؛ دورة السداد لم تختبر |
| المخزون وسلاسل الإمداد | 2/5 | مرتفعة | حركات PurchaseIn وعهدة متطابقة؛ صفوف مخزون ناقصة |
| التوزيع والعمل الميداني | UNKNOWN | — | لا اختبار ميداني اليوم |
| التخطيط والتنبؤ | UNKNOWN | — | لا قياسات |
| التقارير وBI | UNKNOWN | — | لا فحص |
| الأمان والصلاحيات والتدقيق | 3/5 | متوسطة | RLS وJWT وTriggers موجودة؛ لا اختبار جلسة فعلية |
| الأداء والاستقرار والتوسع | UNKNOWN | — | لا قياسات حمل |
| تجربة المستخدم والإنتاجية | 2/5 | متوسطة | CI مكتبي ناجح؛ Mobile/Production غير مثبت |
| الجاهزية التشغيلية والتنافسية | UNKNOWN | — | لا Benchmark ولا إثبات ميداني |

هذه درجات نطاقية مؤقتة وليست تقييمًا شاملًا لكل RAWAEA ERP.

## 16. خريطة النظام الأم والقلب المركزي

- Parent main.html يربط Warehouse Hub ضمن صلاحية warehouse.
- Hub يستعمل جلسة Supabase المشتركة ويحمّل سبع وحدات أصلية مضمّنة، دون إنشاء قاعدة بيانات أو مستندات موازية.
- Core الفعلي: companies/company-1/core.js، ويحتوي RW_Auth وRW_ImageCache وRW_Realtime.
- Picker المضمّن يستخدم كاش صور خاصًا ومحددًا بـcompany_id؛ Loader يستعمل JOIN على items.image_url في العرض؛ Returns يستعمل JOIN على items.image_url في العرض.
- Loader يستعمل RW_Realtime؛ Picker وReturns لا يستعملانه حاليًا.
- لم يُعدل Parent أو Core أو أي تطبيق أصلي في هذه الدورة.

## 17. مصفوفة المزامنة

| الوحدة | آلية المصدر | الجداول/الأحداث | Reconciliation | الحكم |
|---|---|---|---|---|
| Picker | تحميل يدوي عند التهيئة/فتح التبويب | runsheets/details/items عبر reads | لا Realtime ولا polling ظاهر | UNVERIFIED Runtime |
| Loader | RW_Realtime.start | runsheets فقط | 60 ثانية + reconnect/visibility | Source CONFIRMED؛ وصول الحدث غير مختبر |
| Returns | تحميل عند فتح التبويب وبعد الإجراءات | runsheets/details/items/stock_discrepancies | لا Realtime ولا polling ظاهر | فجوة تكامل P2 |
| Supabase publication | supabase_realtime | items, run_sheet_details, runsheets, stock_discrepancies | publication موجود | لا يثبت اشتراك كل عميل |

RW_Realtime في Core يتحقق من company_id عبر RW_Auth، ويوقف الاشتراكات عند sign-out، ويعيد reconciliation بعد الاشتراك وإعادة الاتصال والعودة من الخلفية. لم يتم قياس latency أو وصول حدث فعلي في هذه الدورة.

## 18. جاهزية استلام شعلة التطوير

**READY WITH LIMITATIONS**
- نقطة الاستئناف محفوظة عند LVE-711.
- GitHub وSupabase وCI فُحصت في النطاق المطلوب.
- يمكن مواصلة static/contract/DB read-only والتحضير لتغيير محدد.
- لا يمكن إعلان إغلاق مشكلة الصور قبل Browser/Artifact verification.
- لا يمكن تنفيذ تعديل تشغيلي أو تغيير Production دون Change Set وموافقة صريحة.

## 19. الالتزام بالدستور التشغيلي الدائم

- الملف المقروء كاملًا: `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`, Blob `3a6b1e220af8509e314e94df76563bbc6f84910d`.
- طُبقت بوابات §6.3 الخاصة بالفصل بين Draft والاستلام الفعلي والسداد، وبوابات §7 الخاصة بعدم تعديل التطبيقات التشغيلية مباشرة، وبوابة الموافقة في MASTER CTO GOVERNANCE §§77.2–77.3.
- لم يتم تعديل مصدر تشغيلي أو Production DB أو RLS أو Edge Function.
- تعارض QA في §4 أعلاه موثق؛ اتُّبع توجيه المالك الأحدث بمنع أي بيانات اختبار على Production.

## 20. المخاطر والاعتماديات وموافقات المالك

- يلزم Browser session مصادق عليها أو وسيلة موثوقة لقراءة Artifact المنشور وفحص Network.
- أي ترحيل لروابط Googleusercontent إلى Supabase Storage يتطلب Change Set مستقلًا يحدد مصدر كل صورة وchecksum والمسار وخطة rollback.
- أي إضافة Realtime إلى Picker/Returns أو توسيع Loader إلى run_sheet_details تتطلب تحديد الجداول والفلاتر والـRLS وreconnect/idempotency واختبارًا معزولًا وموافقة المالك.
- لا يجوز إنشاء stock_branches rows يدويًا لعلاج نقص الرصيد.
- حماية فروع main في المستودعين تحتاج قرارًا منفصلًا؛ لا توجد Rulesets حاليًا.

## 21. الخطوة التالية ذات الأولوية

**إجراء تحقق Runtime مصادق عليه للقراءة فقط بعد Forced Reload للنسخة المنشورة:**
1. إثبات Commit/Artifact الذي يقدمه Cloudflare الآن ومقارنته بـ903a1fe.
2. فتح Picker والتحقق من ظهور صور أصناف RS-3/RS-4، مع تسجيل Network status وnaturalWidth لكل صورة.
3. فتح Loader على سجل RS-1 وReturns على RS-1/RS-2 للتحقق من روابط Googleusercontent، مع اختبار fallback وعدم وجود أخطاء DOM/scroll.
4. عدم الضغط على بدء/إكمال/إلغاء أي عملية؛ لا تغيير حالة أو مخزون أو عهدة.
5. قبول المرحلة فقط إذا ثبت تحميل الصور، وثبت scroll bounded، ولم تظهر طلبات مكررة أو آثار أعمال.

إذا فشلت روابط Google فقط، يكون العمل التالي Change Set مستقلًا لنقل الصور المتأثرة إلى Storage؛ لا ينفذ قبل عرض التغيير والموافقة.

---

**الخلاصة:** تم إثبات تماثل Loader وReturns على مستوى واجهات الوظائف وعقود القراءة/الـAPI ودورة العمل، وتم إثبات إصلاح كاش صور Picker في المصدر ونجاح CI. كما أثبتت Production استقبالًا حقيقيًا مترابطًا لثلاث جلسات Quick Market، مع تطابق الاستلام والمخزون وعهدة البضاعة وعدم تسجيل أثر سداد أو ذمة محاسبية. لكن مشكلة ظهور الصور في المتصفح المنشور لم تُغلق بعد: أغلب صور السجلات الفعلية من Googleusercontent، ولم تتوفر جلسة Browser/Artifact للتحقق منها. لا تعديل تشغيلي ولا كتابة Production في هذه الدورة.
