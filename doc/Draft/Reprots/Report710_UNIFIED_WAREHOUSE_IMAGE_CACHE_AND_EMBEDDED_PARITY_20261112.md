# Report710 — Unified Warehouse: إصلاح Cache الصور وتماثل التحميل والمرتجعات
التاريخ: 2026-11-12
Checkpoint: LVE-2026-11-12-710
الحالة: READY WITH LIMITATIONS
النطاق: companies/company-1/warehouse/warehouse.html، وحدات Picker/Loader/Returns المضمّنة، اختبارات Browser E2E، والتحقق القرائي من SMART ERP وCloudflare.

## 1. نقطة البداية واستعادة التاريخ
- CURRENT_STATE قبل هذا التقرير كان ينتهي عند LVE-2026-11-12-706 (SHA: ec17628f95b85793031891634d9e3072f90bc4fe).
- تقارير 707 و708 و709 كانت موجودة في الأرشيف، لكن CURRENT_STATE لم يكن قد ربطها أو يرفع آخر Checkpoint إليها. Report709 يسجل LVE-2026-11-12-709 (SHA: df54cd4df8fce4eb32794cf739b4b6e707e1ab19).
- تمت مراجعة Report707 وReport708 وReport709، ثم إعادة التحقق من الحالة الحية بدل اعتماد ادعاءاتها تلقائيًا.
- تمت قراءة الدستور التشغيلي الدائم كاملًا (SHA: 3a6b1e220af8509e314e94df76563bbc6f84910d)، وMASTER CTO GOVERNANCE (SHA: 1a0c81c2984103b5a7f3b40db41607d74051b310)، وMASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md (SHA: 933362a65f560285dad24b763ca178eb2b39b5ee)، وwriting-block-8888-10.md كاملًا (SHA: 928a98e94624e1c0a5bf4b3e97aaff560c33fcd8، 1,035 سطرًا).
- ملف writing-block-8888-10.md ينتهي بتكليف تاريخي عن عهد الموظفين النقدية؛ نطاق المالك الأحدث في المحادثة الحالية هو المخزن الشامل، ولذلك استُخدم الملف لاستعادة قواعد الحوكمة والحماية ولم يُحوّل العمل إلى مهمة العهد النقدية.
- المستودع التشغيلي: papamohammed77-glitch/erp-frontend، الفرع main، HEAD الحالي: 903a1fe22c3ec2f8f4f7a3ffeb45d1d8025e306d.

## 2. CONFIRMED — السبب الجذري للصور
- حزمة Picker المضمّنة في warehouse.html تستبدل init الأصلية بدالة تهيئة تعتمد RW_Auth.init لتوحيد الجلسة مع النظام الأم.
- استعلام ITEMS_IMAGE_CACHE كان داخل init الأصلية في picker.html، لكن wrapper المضمّن لم ينفذ تلك init ولم ينقل استعلام الصور؛ لذلك كانت المصادقة والواجهة تعملان بينما Cache الصور يظل فارغًا.
- هذا يفسر فشل الصورة في التطبيق المجمّع رغم وجود image_url في items، ويثبت أن تعديل picker.html وحده لا يصلح مسار التهيئة المضمّن.
- Commit 903a1fe22c3ec2f8f4f7a3ffeb45d1d8025e306d أضاف استعلام الصور إلى shared-auth bootstrap داخل Picker المضمّن بعد ضبط company_id، مع تفريغ Cache السابق، وربط الاستعلام بالشركة الحالية، وتجاهل نتيجة الاستعلام القديمة إذا تغيرت الشركة، ثم استدعاء refreshVisibleImages.
- الاستعلام قراءة فقط من items؛ لا يغيّر بيانات أعمال أو صلاحيات أو مخزونًا.

## 3. CONFIRMED — إصلاح CSS المرتجعات المضمّنة
- كان في warehouse.html selector مكرر لوحدة Returns يفرض height:100% وoverflow:hidden وposition:fixed وwidth:100%.
- هذه القاعدة أخرجت الوحدة من تدفق حاوية المخزن الشامل، وربطت عرضها بالنافذة بدل مساحة العمل، وهددت التمرير الداخلي.
- Commit 4803cdf2e6eb875eb904f62e6d4d81c2feb7fc58 أزال هذه القاعدة من النسخة المضمّنة فقط؛ وبذلك ترث الوحدة حدود .rw-native-module القائمة: position:relative، ارتفاع مساحة العمل، وoverflow:auto.
- لم يُعدل ملف returns.html الأصلي أو CSS الخاص به في وضع التشغيل المستقل.

## 4. التغييرات والملفات والـCommits
- 4803cdf2e6eb875eb904f62e6d4d81c2feb7fc58: إزالة قاعدة fixed الخاطئة في Returns المضمّنة، وتوسيع اختبارات Picker/Loader/Returns.
- 26ba0894fe67ec962c921f229a86e5b44b19fa9e: تصحيح صياغة حلقة اختبار التماثل بعد فشل CI؛ سُجل الفشل ولم يُخفَ.
- 903a1fe22c3ec2f8f4f7a3ffeb45d1d8025e306d: إصلاح السبب الجذري لغياب صور Picker المضمّن عبر shared-auth bootstrap.
- الملفات المعدلة في المستودع التشغيلي: companies/company-1/warehouse/warehouse.html و.github/workflows/warehouse_hub_browser_e2e_20261110.yml فقط.
- لم تتغير picker.html أو loader.html أو returns.html أو main.html أو core.js أو SQL migrations أو RLS أو RPCs أو Edge Functions.
- لم يُنشأ فرع Git أو Supabase branch أو بيئة مستأجرة؛ كل commits التشغيلية على main وفق توجيه المالك.

## 5. بصمات المصدر الحالية
- warehouse.html: 41bab8f092dbb5ac1adf32ef34d5feaf92b8dc6e
- picker.html: 312b5e387daf2248737749c246c0174095535eac
- loader.html: 89aea6635771f1a3328e82a456f3ecfe9ee02acd
- returns.html: 39755507bc01331135a1640af5a87a22051ee3e7
- warehouse_hub_browser_e2e_20261110.yml: 2984414dfc0a5b9e2fa1118adaa46c71c2a92c80
- core.js: 2d11b852862c523fc89e6a8b9c510462bb65cc4e
- main.html blob: caf3af2cb3bf8f482d696dacfa2045d322ddd6b0؛ أداة GitHub أعادت SHA دون محتوى بسبب حجم الملف، لذلك لم يُدّعَ فحص محتواه كاملًا في هذه الجولة.

## 6. CONFIRMED — تماثل Loader وReturns
- تمت مقارنة واجهات الدوال بين Loader/Returns الأصليتين والوحدتين المضمّنتين؛ لم تظهر دوال أصلية مفقودة من الحزمة المضمّنة.
- مجموعات استدعاءات API/Edge Functions وأسماء جداول Supabase وRPCs متطابقة بين الأصل والمضمّن في الوحدتين.
- تمت مقارنة أجسام startLoading وcompleteLoading وcancelLoading وreopenLoading، وكذلك startReturn وcompleteReturn وcancelReturn وreopenReturn بعد تطبيع أسماء wrappers؛ الوظائف الأساسية متطابقة.
- renderActiveSession في Returns متطابقة بعد التطبيع. توجد فروق محدودة في بعض دوال تحميل القوائم المضمّنة لإضافة معالجة أخطاء صريحة؛ لم تُحذف وظيفة تشغيلية.
- دوال الصور موجودة في النسختين: _loaderImageHTML و_bindLoaderImageFallbacks في Loader، وreturnItemImageHTML في Returns.
- عمليات التحميل والمرتجعات تظل على جداول runsheets وrun_sheet_details والعقود المركزية نفسها؛ لا يوجد تبويب عمليات موازٍ جديد.
- actor fields في Production هي picker_id وloader_id وreturn_handler_id؛ سجلات RS-1 وRS-2 الحالية تظهر تعيين معرفات الممثلين حسب مرحلة العملية. القوائم المكتملة في التطبيقات الأصلية تعرض أعمال المستخدم الحالي، وليس سجلًا عامًا باسم منشئ كل بطاقة.
- تبويب الحساب الداخلي للوحدات المضمّنة يظل مخفيًا وفق تصميم الدمج، ويستخدم حسابي على مستوى المخزن الشامل. لم يُغير هذا التصميم؛ تطابق محتوى شاشة الحساب بالكامل ليس ضمن الاختبار الحالي.

## 7. الأحداث وDOM
- لم يُعثر في Loader/Returns المضمّنتين على window/document keydown أو keyup أو keypress listeners عامة؛ معالجات لوحة المفاتيح الموجودة محلية على عناصرها.
- توجد مستمعات online/offline على window لتحديث حالة الاتصال.
- moduleDocument Proxy يسمح بالرجوع إلى document العام عند عدم العثور على selector داخل moduleRoot؛ هذا مطلوب حاليًا لبعض عناصر SweetAlert2 الموجودة خارج الجذر، لكنه يظل اقتران DOM محتملًا إذا أضيف selector جديد ولم يوجد داخل الوحدة. لم يثبت تسرب فعلي إلى وحدة أخرى، ولم يُعدل Proxy في هذه المهمة.
- لا يوجد دليل على تكرار mount في التشغيل الحالي؛ لكن دورة mount/unmount الكاملة لم تُختبر في جلسة Production مصادق عليها.

## 8. E2E والاختبارات
- Run 43275616509 فشل بسبب syntax error في حلقة parity test؛ تم تصحيحها في 26ba089.
- Run 43275733111 فشل في اختبار الصور الحقيقي، وكشف أن Cache الصور لا يصل إلى Picker المضمّن؛ هذا الفشل كشف السبب الجذري ولم يكن فشلًا مخفيًا.
- Run 43276131519 على commit 903a1fe انتهى SUCCESS.
- علامات الاختبار النهائية:
  - WAREHOUSE_PICKER_REAL_IMAGE_CACHE_REFRESH_AND_BROKEN_IMAGE_FALLBACK=PASS
  - WAREHOUSE_LOADER_REAL_IMAGE_RENDER_AND_BROKEN_IMAGE_FALLBACK=PASS
  - WAREHOUSE_RETURNS_REAL_IMAGE_RENDER_AND_BROKEN_IMAGE_FALLBACK=PASS
  - WAREHOUSE_RETURNS_BOUNDED_WORKSPACE_AND_SCROLL=PASS
  - WAREHOUSE_LOADER_RETURNS_STANDALONE_METHOD_SURFACE_PARITY=PASS
  - WAREHOUSE_LOADER_RETURNS_IMAGE_RENDERERS_PRESERVED=PASS
  - WAREHOUSE_LOADER_RETURNS_NO_GLOBAL_KEYBOARD_LISTENERS=PASS
  - WAREHOUSE_PICKER_STOCK_PREFLIGHT_ALL_SHORTAGES_NO_EDGE_WRITE=PASS
  - WAREHOUSE_PICKER_FOUR_DECIMAL_STOCK_COMPARISON=PASS
  - WAREHOUSE_RETURNS_COMPLETED_REOPEN_FAIL_CLOSED_UI=PASS
  - WAREHOUSE_RETURNS_DISCREPANCY_FORM_CONTRACT=PASS
  - WAREHOUSE_RETURNS_SESSION_SCOPED_LOCAL_DRAFT_AND_ZERO_VALUE=PASS
- اختبارات Playwright تعمل محليًا ببيانات وصور QA اصطناعية واعتراضات للشبكة وSupabase؛ لم تتصل بقاعدة Production ولم تنشئ بيانات أعمال.

## 9. SMART ERP — صور الأصناف
- الاستعلام المباشر للقراءة فقط على RS-3 وRS-4 أعاد 7 أسطر أصناف و6 أكواد متميزة؛ 7 من 7 لها image_url.
- خمسة روابط من Googleusercontent ورابطان من Supabase public Storage.
- bucket product-images موجود ومعلن public=true، وكائنان من عينة الروابط المطلوبة موجودان في storage.objects.
- وجود الرابط/الكائن لا يثبت استجابة HTTP ناجحة من متصفح المستخدم. تحميل روابط Googleusercontent الفعلية من جلسة Production لا يزال UNKNOWN/UNVERIFIED.

## 10. SMART ERP — RLS
- items_select_company يسمح بالقراءة ضمن الشركة مع effective warehouse permission أو صلاحيات items/data-entry/purchases.
- app_settings_select_company يسمح للمستخدم النشط بقراءة إعدادات شركته.
- stock_branches_select_company يسمح بالقراءة عند effective warehouse/runsheets/reports/purchases permission مع قيد الفرع والشركة.
- تعريفات السياسات الحالية لا تبرر توسيع RLS؛ لم تتغير أي Policy أو Grant.
- أدوار أمين مخزن/امين مخزن في roles تحمل warehouse permission. لا توجد جلسة مصادق عليها حاليًا لإثبات mapping لمستخدم بعينه يحمل activeWarehouseRole=تحضير؛ هذا الجزء runtime غير متحقق.

## 11. SMART ERP — تحميل ومرتجعات
- Edge Functions النشطة والإصدارات: start-loading v7، complete-loading v12، cancel-loading v6، reopen-loading v4، start-return v6، complete-return v28، cancel-return v6، report-discrepancy v4، complete-picking v19.
- ملفات index.ts المنشورة تطابق ملفات GitHub المقابلة حرفيًا، وملف _shared/warehouse-auth.ts المنشور يطابق المصدر لكل الوظائف التي تتضمنه.
- RPCs المركزية الموجودة: complete_runsheet_loading، complete_sales_return_credit_note_atomic، complete_runsheet_picking، reserve_stock.
- Triggers الحالية: trg_audit_runsheets، trg_runsheets_unresolved_discrepancy_close_guard، trg_stock_discrepancies_integrity.
- لم تُستدعَ أي Edge Function تشغيلية أثناء هذه المراجعة.

## 12. SMART ERP — رصيد التحضير
- إعادة الاستعلام المباشر على RS-3 وRS-4 أظهرت:
  - RS-3 / item 1010: qty=1، allocated_qty=0، available=1 مقابل qty_ordered=2.
  - RS-3 / item ITM-20260939: سجل stock_branches غير موجود؛ available=0.
  - RS-4 / item ITM-20260938: سجل stock_branches غير موجود؛ available=0.
  - بقية الأسطر في الرانشيتين لها رصيد كافٍ للكميات المطلوبة المسجلة.
- هذه مقارنة مع qty_ordered فقط؛ preflight الفعلي يقارن pickedQty الذي أدخله المستخدم، وليس كامل الطلب تلقائيًا. لذلك لا يمكن الجزم بكمية النقص النهائية قبل إدخال الكميات الفعلية.
- Picker preflight يقرأ main_branch_id من app_settings، ويطابق items، ويقرأ qty/allocated_qty، ويعامل غياب سجل الرصيد كمتاح صفرًا، ويجمع النواقص مع الكميات المتاحة.
- عند النقص يمنع الواجهة استدعاء complete-picking؛ ويظل الخادم/RPC هو الحارس النهائي إذا تغير الرصيد بالتزامن.
- complete-picking Production v19 يطابق المصدر؛ reserve_stock لا ينشئ صف رصيد مفقودًا، ويمنع الاستمرار عند غياب الصف أو عدم كفاية المتاح.
- لم يتغير أي qty أو allocated_qty أو movement أو journal أو cash ledger.

## 13. Deployment
- Cloudflare يعرض Automatic deployments enabled، وProduction/main عند commit 903a1fe22c3ec2f8f4f7a3ffeb45d1d8025e306d.
- Production domain: https://rawaea-erp.pages.dev/
- deployment preview: https://d7b70c9e.rawaea-erp.pages.dev/
- هذا يثبت lineage النشر من لوحة Cloudflare، لكنه لا يثبت byte-for-byte تطابق HTML/JS الذي يقدمه الخادم؛ لم تُنزّل استجابة artifact للتحقق من hash.
- المتصفح المتصل يعرض صفحة النظام الأم دون جلسة مصادق عليها؛ لذلك لا توجد نتيجة Production authenticated browser E2E بعد هذا النشر.

## 14. المصفوفة
| الطبقة | الحالة | الدليل |
|---|---|---|
| GitHub / Source | CONFIRMED | HEAD 903a1fe، blobs الحالية أعيد جلبها |
| Supabase Production | CONFIRMED للقراءة | RLS، الصور، الأرصدة، RPCs، triggers، Edge versions |
| Deployed Artifact | CONFIRMED lineage / UNVERIFIED bytes | Cloudflare Production/main عند 903a1fe |
| Runtime / Browser | UNVERIFIED للجلسة الحقيقية | المتصفح المتصل غير مصادق |
| Local Playwright E2E | PASS | run 43276131519 |
| Business-data effects | CONFIRMED no-write | SELECT فقط؛ CI mocks لا تتصل بقاعدة Production |
| Staging | غير مستخدم | لا فرع أو مشروع أو نسخة موازية |

## 15. ما لم يُفحص أو لم يثبت
- لم يُقرأ محتوى main.html كاملًا في هذه الجولة؛ أداة GitHub أعادت SHA فقط دون محتوى بسبب حجم الملف. لم يُعدل الملف.
- لم تُختبر روابط Googleusercontent الخمسة من متصفح Production.
- لم تُنفذ عملية تحميل أو مرتجع فعلية على Production؛ لا يجوز اعتبار E2E المحلي إثباتًا لأثر مخزني/محاسبي.
- لم يُقَس زمن Cache أو Realtime latency في جلسة حقيقية.
- لم تُراجع بقية وحدات المخزن الستة مراجعة وظيفية شاملة؛ التغطية اليوم محددة بـPicker/Loader/Returns وتكاملها في shell.

## 16. المخاطر المفتوحة
- P1: إثبات الصور الفعلية بعد تسجيل الدخول؛ URLs Googleusercontent قد تفشل لأسباب خارج Cache.
- P1: التحقق من سلوك تحذير النقص في جلسة Picker حقيقية دون استدعاء Edge أو تغيير الأرصدة.
- P2: مراجعة نطاق moduleDocument Proxy لتقليل fallback إلى DOM العام مع الإبقاء على SweetAlert2.
- P2: التحقق من تكافؤ شاشة الحساب المركزية مع account tabs المخفية في الوحدات الأصلية.
- P3: تحذير Tailwind CDN للإنتاج لا يزال قائمًا، وهو خارج إصلاح الصور/التحميل/المرتجعات.

## 17. الالتزام بالحوكمة
- §77.2/§77.3 من MASTER CTO GOVERNANCE تبقي بوابة المراجعة والموافقة المحددة للتغييرات المؤثرة.
- §6.4 من الدستور التشغيلي يحدد نموذج QA الاصطناعي القابل للإزالة على Production عند الحاجة، لكنه لا يلغي موافقة التغيير أو خطة التنظيف.
- التغييرات المنفذة في هذه المهمة محدودة بواجهة warehouse.html المضمّنة وملف CI، وبحسب نطاق المالك الحالي؛ لا تغييرات مالية/مخزنية/صلاحيات/عقود/DB.
- لم تُنشأ Fixtures على Production ولم تُنفذ DML/DDL/RPC/Edge invocation.

## 18. حكم الجاهزية
READY WITH LIMITATIONS:
- جاهز لاستكمال أعمال Source/CI/التحقق القرائي.
- لا يُعلن READY للاختبار الميداني النهائي حتى تتوفر جلسة Production مصادق عليها ويُختبر تحميل الصور الفعلية.
- لا توجد حاجة لتوسيع RLS أو تغيير Edge Functions أو تعديل loader.html/returns.html الأصلية.

## 19. ما تم وما ينتظر
- المساعد: أصلح root cause لصور Picker المضمّن، أصلح حدود Returns المضمّنة، وسّع E2E، تحقق من Edge/RPC/RLS والبيانات للقراءة فقط، وسجل الأدلة.
- المالك/المستخدم: بعد إعادة تحميل النسخة المنشورة وتسجيل الدخول، اختبار الصور الحقيقية في RS-3/RS-4 ومراجعة تحذير الكميات قبل أي إنهاء للتحضير.
- لا ينتظر أي تعديل Production أو DML.

## 20. الخطوة التالية ذات الأولوية
إجراء تحقق Runtime مصادق عليه بعد إعادة تحميل https://rawaea-erp.pages.dev/companies/company-1/main، وفتح المخزن الشامل ثم Picker/Loader/Returns؛ تسجيل نتيجة صور الأصناف الفعلية ورسالة نقص الرصيد، دون إنهاء تحضير أو تحميل أو مرتجع ودون أي أثر مخزني/مالي. إذا فشل Googleusercontent، تُجهز خطة نقل روابط الصور إلى Supabase Storage بعد عرض Change Set وموافقة المالك.

## 21. معيار الإغلاق
- كل الصور الفعلية المطلوبة تظهر أو يعرض بديل واضح مع تسجيل سبب فشل URL.
- تحذير Picker يجمع كل الأصناف الناقصة، ويعرض المطلوب/المتاح/المفقود، ولا يستدعي complete-picking عند وجود نقص.
- وحدة Returns تبقى داخل مساحة العمل مع تمرير صحيح ولا تتجاوز حاوية المخزن الشامل.
- لا اختلاف في APIs/tables/RPCs أو actor attribution بين الأصل والمضمّن.
- لا يتغير أي رصيد/حجز/حركة/قيد أثناء اختبار العرض والتحذير.
- لا يُغلق العمل بمجرد نجاح CI المحلي؛ يلزم اختبار Production مصادق عليه للصور والسلوك الظاهر.
