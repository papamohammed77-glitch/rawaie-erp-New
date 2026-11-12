# Report709 — مراجعة وإصلاح صور التحضير وفحص رصيد المخزون في Picker والمخزن الشامل
التاريخ: 2026-11-12
Checkpoint: LVE-2026-11-12-709
الحالة التنفيذية: READY WITH LIMITATIONS
النطاق: companies/company-1/warehouse/picker.html، ونسخة Picker المضمنة في companies/company-1/warehouse/warehouse.html، وSupabase SMART ERP للقراءة فقط، واختبارات CI/Browser، وبيانات نشر Cloudflare المتاحة.

## 1. نقطة البداية — LAST VERIFIED EVENT
- نقطة الاستئناف السابقة: LVE-2026-11-12-708، كما في CURRENT_STATE.md (blob SHA: 68809a455913e1b83a2e879b2ef146cd998a55df).
- التقرير السابق: Report708_RECEIVER_NETWORK_FAILURE_AND_PARENT_RECEIVING_LOG_20261112.md (SHA: e44f65aa247d507bc088d6972e97fcec08219e56). تمت قراءته كاملًا.
- ملف الدستور التشغيلي الدائم: SHA 3a6b1e220af8509e314e94df76563bbc6f84910d، تمت قراءة الملف كاملًا.
- ملف المهمة/التسليم writing-block-8888-10.md: SHA 928a98e94624e1c0a5bf4b3e97aaff560c33fcd8، 1,035 سطرًا؛ تمت قراءته كاملًا على خمس دفعات.
- طلب المالك الحالي حدّد مهمة Warehouse Picker صراحةً، وهو أحدث وأكثر تحديدًا من المهمة الافتراضية الواردة في ملف التسليم. لذلك لم يتم تحويل العمل إلى مهمة أخرى.
- المستودع التشغيلي: papamohammed77-glitch/erp-frontend، الفرع main، HEAD بعد آخر تغيير: 09dd0a738a2378abaee7f61ec86cd60ca11f7a4f.
- الهدف: إصلاح عرض صور الأصناف في شاشة الرانشيت، واستبدال خطأ stock balance not found بتحذير يشرح كل صنف ناقص والكمية المتاحة، دون تغيير أي رصيد أو مستند إنتاجي.

## 2. CONFIRMED
1. مصدر الصور في قاعدة البيانات موجود للأصناف الستة الظاهرة في RS-3 وRS-4؛ كل هذه الأصناف لها image_url. أربعة روابط من Googleusercontent ورابطان من Supabase public Storage.
2. السبب البرمجي المؤكد في مصدر Picker: واجهة الرانشيت كانت ترسم الصورة مرة واحدة وفق حالة ITEMS_IMAGE_CACHE وقت الرسم. عند وصول بيانات Cache بعد رسم الرانشيت لم يكن هناك تحديث للعناصر المرئية. أضيف تحديث DOM بعد اكتمال تحميل Cache.
3. سبب خطأ المخزون في بيانات Production الحالية: يوجد صنفان في الرانشيتين RS-3 وRS-4 لا يملكان سجلًا في stock_branches للفرع الرئيسي؛ غياب السجل يختلف عن وجود سجل بكمية صفر.
4. Edge Function complete-picking المنشورة في SMART ERP هي version 19، وverify_jwt=true. محتواها المنشور مطابق حرفيًا لملف GitHub supabase/functions/complete-picking/index.ts وقت الفحص.
5. مسار SQL المركزي complete_runsheet_picking يستدعي reserve_stock. الدالة reserve_stock تبحث عن صف stock_branches وتقفل الصف؛ عند عدم العثور على الصف ترفع الاستثناء stock balance not found. لذلك رسالة الخادم متوافقة مع حالة الصف المفقود.
6. RLS تسمح بقراءة app_settings للمستخدم النشط ضمن الشركة، وقراءة items وstock_branches لمستخدم يملك effective warehouse permission. لا حاجة لتجاوز RLS.
7. فهارس uniqueness تمنع تكرار item_code، وتمنع تكرار سجل item/branch في stock_branches. لم تظهر ازدواجية في الأصناف أو أرصدة الفرع.
8. app_settings تحتوي صفًا واحدًا للشركة محل الفحص، وmain_branch_id مضبوط؛ لذلك لا يوجد تعارض بين اختيار الفرع في الواجهة والمسار المركزي.
9. اختبارات Browser CI النهائية نجحت على commit 09dd0a، وشملت النسخة المضمنة والنسخة المستقلة، وتحذير النقص، ومنع استدعاء Edge عند وجود نقص، ومقارنة الكميات بدقة أربع منازل عشرية.
10. لم ينفذ هذا العمل أي DML أو DDL أو RPC أو Edge invocation على Production. جميع استعلامات SMART ERP كانت SELECT/قراءة سجلات فقط؛ اختبارات المتصفح استخدمت mocks وبيانات QA داخل المتصفح.

## 3. UNKNOWN
- لا يمكن من function_edge_logs ربط كل طلب 400 برقم الرانشيت؛ سجل الحافة يعرض مسار الوظيفة والحالة والتوقيت، ولا يسجل جسم الطلب الذي يتضمن runsheet_code.
- لم يتم التحقق من إمكانية تحميل كل رابط Googleusercontent الفعلي من متصفح Production بعد التعديل؛ وجود image_url في DB لا يثبت أن مزود الصورة يسمح بالتحميل من كل جلسة/شبكة.
- لم يتم قياس latency الفعلي لتحميل Cache في جلسة مستخدم Production.
- لا توجد نتيجة E2E ميدانية موثقة لعملية تحضير ناجحة ذات رصيد كافٍ؛ تنفيذ المسار الناجح على Production سيغير الحجز/المخزون، ولذلك لم يُنفذ.

## 4. CONFLICT
- لا يوجد تعارض بين عقد SQL وبيانات Production في سبب stock balance not found: العقد يتطلب صف stock_branches، والبيانات الحالية تفتقد الصف لصنفين.
- يوجد فرق حالة بين GitHub main ولقطة Cloudflare المتاحة: GitHub main عند 09dd0a، بينما آخر deployment ظاهر في لقطة Cloudflare هو de158d3. قد تكون صفحة Cloudflare المفتوحة قديمة؛ لذلك لا نرفع نشر 09dd0a إلى CONFIRMED.
- يوجد فرق بين اكتمال CI وE2E الحي: CI نجح ببيانات وهمية داخل المتصفح، لكنه لا يثبت وحده سلوك النسخة المنشورة مع جلسة المستخدم الحقيقية.

## 5. UNVERIFIED
- HTML/JS bytes التي يقدمها Cloudflare حاليًا لم يتم تنزيلها ومقارنتها مباشرة مع blob GitHub.
- تنفيذ مسار Picker داخل جلسة مصادق عليها على النطاق المنشور بعد آخر deployment غير مثبت.
- تحميل روابط الصور الفعلية من Googleusercontent وSupabase Storage لم يختبر مباشرة من المتصفح المنشور.
- deployment للـprecision commit 09dd0a غير مثبت في لقطة Cloudflare؛ آخر ما ظهر هو de158d3.

## 6. مصفوفة التحقق
| الطبقة | النتيجة | الدليل/القيد |
|---|---|---|
| GitHub / Source | CONFIRMED | main HEAD 09dd0a738a2378abaee7f61ec86cd60ca11f7a4f؛ ملفات Picker وWarehouse وWorkflow الحالية أعيد جلبها |
| Supabase Production | CONFIRMED للقراءة | project ref fiilmooggumokxanwiyx؛ schema/RLS/functions/data قرئت فقط |
| Deployed Artifact | PARTIAL / UNVERIFIED | آخر لقطة Cloudflare تعرض Production/main commit de158d3 وpreview URL https://41e4cf76.rawaea-erp.pages.dev/؛ لا دليل مباشر أن 09dd0a نُشر |
| Runtime / E2E | CONFIRMED في CI mocks | Browser E2E run 43269334660 نجح؛ لا يساوي E2E على Production |
| Business-Data Effects | CONFIRMED no-write by this task | لا DML/DDL/RPC/Edge invocation؛ snapshot counts بقيت على قيم LVE708 |
| Staging | NOT USED | لا فرع أو بيئة مستأجرة؛ CI استخدم mocks محلية فقط |

## 7. ما تم فعليًا ومراجع الأدلة
- قراءة CURRENT_STATE والدستور والتقرير السابق وملف writing-block كاملًا.
- مراجعة المصدر الحالي للملفين المستقل والمضمن؛ لم يُستخدم مقتطف تاريخي بديل.
- التعديل الأساسي في commit de158d30ad90ae648351ef5514921017e31600ae:
  - companies/company-1/warehouse/picker.html
  - companies/company-1/warehouse/warehouse.html
  - .github/workflows/warehouse_hub_browser_e2e_20261110.yml
- تحسين دقة المقارنة في commit 09dd0a738a2378abaee7f61ec86cd60ca11f7a4f.
- commits الاختبار اللاحقة: 8d6811c583e0b4a67a136faa1f46c59776a15463 و5ce5fd1d9fa1ca9d7c332b311cd698655ae0ad75 و720a6d5f5848ba523a80aee197f11a93743ff047.
- ملفات Blob الحالية: picker.html SHA 312b5e387daf2248737749c246c0174095535eac؛ warehouse.html SHA 573dfe801c6c83cdd76b52238677c22f968af0c3؛ workflow SHA 27e0d431d594a2c623f23d4a45fb61d3e337079d.
- تحقق مستقل من أن shell الخارجي لـwarehouse.html لم يتغير، وكل حزم التطبيقات الأخرى داخل RW_NATIVE_BUNDLES بقيت مطابقة بايتًا/JSON؛ الحزمة الوحيدة المتغيرة هي picker.
- تحقق من أن shell الخارجي لـpicker.html لم يتغير، وأن المقاطع التالية متطابقة بين Picker المستقل والمضمن: _getPickingStockCheck، _showPickingStockWarning، refreshVisibleImages، _img.
- اختبارات CI:
  - run 43267599994: نجاح Browser E2E للنسخة المضمنة بعد جعل اختبار تحديث الصور حتميًا.
  - run 43268001281: نجاح E2E للنسخة المستقلة والمضمنة.
  - run 43269334660 على HEAD 09dd0a: SUCCESS، وشمل اختبارات الدقة العشرية في النسختين.
  - markers مؤكدة: WAREHOUSE_PICKER_RUNSHEET_IMAGE_REFRESH_AND_BROKEN_IMAGE_FALLBACK=PASS، WAREHOUSE_PICKER_STOCK_PREFLIGHT_ALL_SHORTAGES_NO_EDGE_WRITE=PASS، WAREHOUSE_PICKER_FOUR_DECIMAL_STOCK_COMPARISON=PASS، STANDALONE_PICKER_RUNSHEET_IMAGE_REFRESH_AND_STOCK_PREFLIGHT=PASS، STANDALONE_PICKER_FOUR_DECIMAL_STOCK_COMPARISON=PASS.
- أول محاولة E2E run 43266971745 فشلت بسبب افتراض غير حتمي في الاختبار حول توقيت تحميل Cache، وليس بسبب فشل مؤكد في التطبيق. تم تعديل الاختبار ليقيس تحديث DOM بعد توافر Cache بصورة حتمية، ثم نجح في التشغيلين اللاحقين. تم الحفاظ على نتيجة الفشل وعدم محوها.

## 8. ما لم يتم ولماذا
- لم يتم إنشاء صفوف stock_branches مفقودة؛ إنشاء الرصيد يتطلب واقعة مخزنية موثقة وليس علاجًا لرسالة الواجهة.
- لم يتم تشغيل complete-picking على Production؛ أي تشغيل ناجح قد ينشئ حجزًا/أثرًا مخزنيًا.
- لم يتم تعديل Edge Function أو reserve_stock أو complete_runsheet_picking أو RLS أو أي Migration؛ العقد المركزي يعمل كما هو متوقع عند غياب صف الرصيد.
- لم يتم التحقق من artifact النهائي 09dd0a على Cloudflare؛ لقطة dashboard المتاحة تعرض de158d3 وقد تكون قديمة.

## 9. صحة النظام والتطبيقات التشغيلية ونطاق التغطية
- فُحص اليوم: Picker المستقل، Picker المضمن داخل Warehouse، تكامل الموديول مع shared auth/client، مسار إنهاء التحضير، قراءة صور الأصناف، الجداول/RLS ذات الصلة.
- اختُبرت في CI أيضًا مساحات العمل السبعة في المخزن الشامل، وخمس إجراءات أذونات، ومجموعة اختبارات الاستلام والمرتجعات والجرد/العداد وفق workflow الحالي.
- لم تُراجع اليوم كل تبويبات النظام الأم ولا كل تطبيقات البيع والتوصيل والمشتريات؛ لا يُعلن سلامتها من هذا الفحص.
- main.html وcore.js لم يتغيرا. لم يثبت وجود أثر جانبي عليهما من هذا التعديل.

## 10. تدقيق التعديلات الأخيرة وآثارها الجانبية
- تغييرات de158 محصورة في Picker المستقل، حزمة Picker المضمنة، واختبار CI.
- تغييرات 09dd0a أضافت تمثيلًا صحيحًا لكميات numeric(12,4) باستخدام وحدات صحيحة بمقياس 10,000؛ لا تغيير في عقد قاعدة البيانات.
- كل حزم warehouse الأخرى بقيت كما هي، وshells الخارجية لم تتغير.
- لا تغيير في صلاحيات المستخدم أو RLS أو Core أو parent.
- لا تغيير في المخزون أو القيود أو الموردين أو العملاء أو العهد.

## 11. الأخطاء والفجوات والسبب والحل
### P1 — فشل إنهاء التحضير عند غياب صف رصيد
- الدليل: خمسة POST 400 إلى complete-picking في function_edge_logs بين 16:14 و16:16 UTC، على النسخة المنشورة 19؛ رسالة المتصفح التي قدمها المالك هي stock balance not found.
- السبب المؤكد في SQL: reserve_stock يرفع الاستثناء إذا لم يجد صف stock_branches للصنف والفرع.
- بيانات Production الحالية: RS-3 يحتوي ITM-20260939 بلا صف رصيد في الفرع الرئيسي، وRS-4 يحتوي ITM-20260938 بلا صف رصيد. الكمية المطلوبة في كل سطر 1، والكمية المحضّرة المخزنة حاليًا 0 لأن العملية لم تنجح. غياب الصف يعرض كمتاح 0 مع علامة missing balance.
- الحل: فحص قراءة فقط قبل التأكيد، يعرض جميع الأصناف المتأثرة مع المطلوب والمتاح وسبب غياب الصف؛ يمنع طلب Edge إذا وجد نقص. الخادم يظل المرجع النهائي.

### P2 — صور الرانشيت لا تتحدث بعد وصول Cache
- الدليل: _img كان يعتمد على ITEMS_IMAGE_CACHE وقت بناء HTML ولا يعيد رسم العنصر بعد اكتمال الاستعلام.
- الحل: data attributes مستقرة على wrapper، refreshVisibleImages بعد اكتمال Cache، وإعادة الرسم في mainContent وSweetAlert popup. onerror يخفي الصورة المعطوبة ويظهر fallback.

### P2 — دقة المقارنة العشرية
- الدليل: أعمدة qty وallocated_qty وqty_picked من نوع numeric(12,4). الجمع باستخدام Number قد ينتج 0.30000000000000004 ويعطي نقصًا كاذبًا عند تساوي 0.1 + 0.2 مع 0.3.
- الحل: تحويل القيم إلى وحدات صحيحة على مقياس 10,000 ثم المقارنة؛ اختبار 0.1 + 0.2 مقابل 0.3 يثبت عدم إظهار نقص كاذب، مع إبقاء نقص 0.3 مقابل المتاح 0.2.

## 12. الكفاءة التشغيلية والميدانية
- سيناريو التحضير: الكود موجود، CI browser-tested ببيانات mocks، نشر الإصلاح الأساسي ظاهر في لقطة Cloudflare على de158d3، لكن التشغيل الميداني بعد إعادة تحميل النسخة المنشورة غير مثبت.
- سيناريو الصنف الذي لا يملك صف رصيد: التحذير يمنع الإنهاء قبل إرسال طلب Edge؛ لا ينشئ رصيدًا ولا يحجز كمية.
- دورة التحضير الكاملة الناجحة مع رصيد كافٍ لم تُنفذ على Production لتجنب حجز/أثر حقيقي دون حاجة.
- نسبة نجاح العمل الميداني وزمن التحضير غير مقاسة.

## 13. التخطيط والتنبؤ ومركز القرار الذكي
- خارج نطاق هذا الإصلاح؛ لا توجد بيانات كافية لتقييم forecast accuracy أو replenishment أو stock-out prediction. UNKNOWN.

## 14. المقارنة التنافسية
- لم تُجرَ مقارنة وظيفية مع SAP/Dynamics/Odoo في هذه المهمة؛ لا توجد حاجة لإسناد معيار تنافسي لإصلاح صور وتحذير مخزون. لا ندعي تكافؤًا أو جاهزية عالمية.

## 15. مصفوفة نضج RAWAEA — نطاق المهمة فقط
| المجال | الدرجة | الثقة/الدليل |
|---|---:|---|
| السلامة التقنية والمعمارية | 3/5 | تغيير محدود، static/contract وBrowser CI ناجحان؛ النشر النهائي 09dd0a غير مثبت |
| تكامل التطبيقات والبيانات | 3/5 | Picker المستقل والمضمن متطابقان في المقاطع المستهدفة، وسبعة workspace tests ناجحة |
| العمليات التجارية | 2/5 | preflight يحمي خطوة التحضير، لكن صنفين في الرانشيتين بلا صف رصيد |
| الرقابة المالية والمحاسبية | UNKNOWN | لم يتغير مسار مالي ولم يختبر في هذا النطاق |
| المخزون وسلاسل الإمداد | 2/5 | عقد الحجز مركزي، لكن بيانات فرع رئيسي تفتقد صفين |
| التوزيع والعمل الميداني | UNKNOWN | خارج نطاق الاختبار الحالي |
| التخطيط والتنبؤ | UNKNOWN | لا قياس في هذه المهمة |
| التقارير وذكاء الأعمال | UNKNOWN | لا تغيير |
| الأمان والصلاحيات والتدقيق | 3/5 | RLS للقراءة وفحص shared auth؛ لم يجر اختبار أمني شامل |
| الأداء والاستقرار والتوسع | UNKNOWN | لا قياس latency/تحميل إنتاجي |
| تجربة المستخدم والإنتاجية | 3/5 | صور/fallback وتحذير نقص متعدد الأصناف مختبرة في Browser CI |
| الجاهزية التشغيلية والتنافسية | UNKNOWN | لا E2E ميداني كامل ولا benchmark |

## 16. خريطة النظام الأم والقلب المركزي والعقود ذات الصلة
- warehouse.html هو الحاوية التي تحمل RW_NATIVE_BUNDLES؛ تم تعديل bundle picker فقط.
- picker.html هو التطبيق المستقل المقابل.
- كلا المسارين يستعملان shared Supabase client/auth في سياق المخزن؛ اختبارات CI تؤكد عدم إنشاء client مكرر في الحزمة المضمنة.
- لم يتم تعديل main.html أو core.js أو router أو auth أو RLS.
- مصدر بيانات الصور: items.item_code وitems.image_url.
- مصدر بيانات فحص المخزون: app_settings.main_branch_id، items.id/item_code/name، stock_branches.item_id/branch_id/qty/allocated_qty.
- مصدر الحجز الفعلي: Edge Function complete-picking → RPC complete_runsheet_picking → reserve_stock.

## 17. مصفوفة المزامنة
- الصور: قراءة Cache من items عند تهيئة التطبيق؛ بعد نجاح القراءة يُعاد تحديث DOM المرئي. لم يثبت زمن وصول Cache من Production runtime.
- فحص المخزون: قراءة لحظية عند ضغط إنهاء التحضير؛ ليس Realtime ولا يغير state.
- الحجز: يبقى عبر المسار المركزي؛ قفل/تحقق SQL هو المرجع النهائي، ويعالج الواجهة رفض الخادم بإعادة فحص الرصيد.
- لم تتغير Realtime subscriptions أو cache invalidation في core؛ لم يختبر التزامن بين مستخدمين فعليين في هذه المهمة.

## 18. جاهزية المساعد واستلام شعلة التطوير
الحكم: READY WITH LIMITATIONS.
- نقطة الاستئناف: LVE-2026-11-12-709.
- المصدر الحالي: main HEAD 09dd0a.
- CI: run 43269334660 SUCCESS.
- Supabase: قراءة فقط؛ function version19 مطابق للمصدر.
- القيود: آخر لقطة Cloudflare تعرض de158d3؛ artifact 09dd0a وسلوك Production runtime غير مثبتين.
- لا توجد حاجة لفرع أو قاعدة اختبار منفصلة؛ CI يستخدم mocks دون كتابة Production.

## 19. الالتزام بالدستور التشغيلي الدائم
- تمت قراءة الدستور كاملًا، SHA 3a6b1e220af8509e314e94df76563bbc6f84910d.
- الاستثناء الصريح الأحدث من المالك أجاز في هذه المهمة وحدها تنفيذ تعديل جراحي مباشر في picker.html وحزمة Picker المضمنة؛ لا يُعمم على ملفات أخرى.
- لم يتم تعديل النظام الأم أو Core أو قاعدة البيانات أو Edge Function أو الصلاحيات.
- لم يتم إنشاء حركات مخزنية/مالية أو بيانات اختبار دائمة.
- فشل preflight يمنع استدعاء Edge؛ نجاح preflight لا يتجاوز تأكيد المستخدم ولا يتجاوز فحص الخادم.
- لم يتم إنشاء صف رصيد اصطناعي لعلاج الخطأ.

## 20. المخاطر والاعتماديات والقرارات
- اعتماد رئيسي: نشر commit 09dd0a على Cloudflare ثم التحقق من HTML/JS الفعلي.
- اعتماد ثانٍ: فتح النسخة المنشورة في جلسة مصادق عليها والتحقق من الصور الفعلية ورسالة RS-3/RS-4 دون إتمام عملية ناجحة أو تغيير رصيد.
- خطر متبقٍ: روابط Googleusercontent قد تكون غير متاحة في بعض الجلسات؛ fallback يعالج الفراغ البصري لكنه لا يصلح صلاحية الرابط.
- خطر متبقٍ: إذا تغير الرصيد بعد preflight، سيظل الخادم يرفض العملية؛ هذا مقصود وآمن.
- ملاحظة حوكمة: commit 09f6020 كان commit بلا تغييرات بسبب خطأ مؤقت في تمرير base tree، ثم أزيل من main فورًا بإرجاع المرجع إلى 560a130. ظهر له deployment بلا تغييرات في سجل Cloudflare؛ لا يحمل تعديلًا على الملفات ولا أثرًا على قاعدة البيانات. لم يبقَ في تاريخ main الحالي.
- لقطة Cloudflare المتاحة تعرض Production/main commit de158d3 وpreview URL https://41e4cf76.rawaea-erp.pages.dev/؛ حالة نشر 09dd0a UNKNOWN/UNVERIFIED لأن اللقطة قديمة/لم تتحدث بعد.

## 21. الخطوة التالية الواحدة ذات الأولوية
تأكيد نشر 09dd0a على Cloudflare ثم تنفيذ Browser verification على النسخة المنشورة للـPicker المستقل وPicker المضمن: تحميل RS-3 وRS-4، التأكد من الصور أو fallback، ثم الضغط على إنهاء التحضير للتأكد من ظهور تحذير الصنفين المتاح لهما 0 وعدم خروج POST إلى complete-picking. لا يتم استكمال التحضير ولا إنشاء صفوف رصيد ولا أي حركة مخزنية/مالية. معيار القبول: ظهور الصنفين بالاسم والكود والمطلوب والمتاح، وعدم وجود Edge request عند وجود النقص، مع بقاء سجلات Production دون تغيير.
