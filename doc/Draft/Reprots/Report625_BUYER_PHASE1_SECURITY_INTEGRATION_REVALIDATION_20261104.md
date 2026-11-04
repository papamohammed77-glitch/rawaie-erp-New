# Report 625 — إعادة التحقق الحي من Buyer Phase 1 ومخاطر الحماية والتكامل
**التاريخ:** 4 نوفمبر 2026  
**النطاق:** مراجعة قراءة فقط بعد LVE624؛ Buyer + عقود Edge/Production + Core/Realtime/PWA + اعتماد Receiver.  
**قاعدة التنفيذ:** لم يُنفذ أي تعديل في كود تشغيلي أو قاعدة Production أو Edge أو Cloudflare. هذا التقرير وتحديثات الحالة فقط.

## 1. نقطة البداية والاستئناف

- آخر حدث مثبت عند بدء المراجعة: LVE624، ثم تحديثات LVE624 اللاحقة حتى commit Buyer النهائي bf0833c.
- CURRENT_STATE الحالي قبل هذا التقرير: blob 98bd72d58276c8b9e3c4bacdf6f7e0eb2b504aa2، 5841 سطرًا.
- آخر Checkpoint: Buyer Phase 1 schema/RPC/RLS/Realtime مطبقة في SMART ERP، Edge save-purchase-order v25، وBuyer UI موجود في operational main.
- آخر إغلاق مثبت: migrations 01–09، وإزالة raw wildcard permission bypass في migration 09، وتوجيه حذف Buyer عبر ownership-aware wrappers في commit bf0833c.
- آخر نشر Cloudflare مؤكد في سجل المشروع: commit 3717c027. آخر مصدر Git هو bf0833c؛ لم يثبت نشر 841b90f أو bf0833c.
- مراجع الحاكمية التي أعيد التحقق منها:
  - الدستور التشغيلي الدائم: 293 سطرًا، SHA d2afa896…؛ تمت قراءته كاملًا.
  - MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS: SHA 1a0c81c…؛ تمت مراجعة §§77.2–77.4.
  - Report614_NEW_P الحالي: SHA 15caa4c…، 1441 سطرًا؛ §14 هو بوابة الموافقة.
  - Report624 الحالي: SHA 99405231…، 189 سطرًا.
  - CURRENT_STATE وذاكرة المشروع هما مصدر الاستئناف؛ التقارير لا تثبت Runtime بمفردها.

## 2. CONFIRMED

### 2.1 GitHub التشغيلي

- المستودع: papamohammed77-glitch/erp-frontend، الفرع main، HEAD = bf0833c3c71d7a2dea6167bfac9b5403e8044cf7.
- المقارنة من Checkpoint e8ab54c إلى HEAD الحالي: 19 commit، والملفات المتغيرة فقط:
  1. companies/company-1/purchasing/buyer.html — 212 إضافة و29 حذفًا.
  2. companies/company-1/purchasing/buyer.tailwind.css — استبدال CSS المجمّع.
- Buyer الحالي: blob d9ffb1084a538b7f7baf48391d3048ac5e96bffa، 1364 سطرًا.
- CSS الحالي: blob 7eb4ef089a1903e405179f23f921328cad1c06e9.
- main.html لم يتغير ضمن هذه المقارنة؛ blob المعروف f6ec4ab41dc517f86e17dd3d74a9d5f8add264ca. تعذر جلب محتواه الكامل بأداة الملفات بسبب حجم الملف، لذلك لا أصفه بأنه خضع لمراجعة داخلية كاملة.
- core.js لم يتغير ضمن المقارنة؛ المسار الفعلي companies/company-1/core.js، blob f4c6a0…؛ Buyer يستدعيه عبر ../core.js ويستخدم RW_Auth وRW_API وRW_Realtime.
- Buyer الحالي لا يحتوي cost_price، ولا يستدعي Tailwind CDN. فحص parsing للـinline JavaScript نجح، وكل عمليات API الثابتة التي استخرجت من Buyer موجودة في Edge v25. عمليات الحذف الديناميكية الجديدة DELETE_BUYER_DRAFT_INVOICE وDELETE_QUICK_MARKET_DRAFT موجودة في Edge v25 أيضًا.
- commit 841b90f أضاف ownership-aware edit/delete controls. commit bf0833c نقل حذف المسودة إلى DELETE_BUYER_DRAFT_INVOICE أو DELETE_QUICK_MARKET_DRAFT بحسب مصدر الفاتورة. لذلك Buyer الحالي لم يعد يستدعي DELETE_DRAFT_INVOICE مباشرة.

### 2.2 Supabase Production

- المشروع SMART ERP، ref fiilmooggumokxanwiyx.
- migrations Buyer phase 1 من 01 إلى 09 موجودة في سجل Production؛ migration 09 هي buyer_phase1_09_effective_permission_only_rpc_guards.
- save-purchase-order نشطة ACTIVE version 25، SHA-256:
  793ba5412a27813aa715da4078971a150d592dd03b53833148b9e99a37b5be62.
- receive-purchase ما زالت version 13، SHA-256:
  50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc.
- buyer_goods_custody_events موجودة، RLS مفعّل، وسياسة SELECT المصرح بها واحدة، وappend-only trigger يمنع UPDATE/DELETE. authenticated يملك SELECT فقط ولا يملك INSERT/UPDATE/DELETE مباشرًا. الجدول عضو في Realtime publication.
- Buyer SECURITY DEFINER RPCs التي فُحصت تضبط search_path فارغًا؛ anon EXECUTE=false، وauthenticated EXECUTE على الوظائف المصرح بها. migration 09 أزالت raw permissions wildcard من غلافي Quick Market وLegacy update.
- purchase_post_buyer_invoice_atomic يمنع ترحيل Quick Market من Buyer؛ مسار الترحيل الأصلي للـPO يظل مرتبطًا بالاستلام ولا ينشئ ترحيل مخزون/AP ثانيًا.
- بيانات الأعمال الحالية:
  - العملة من app_settings = EGP.
  - items=30، suppliers=4، branches=4.
  - purchase_invoices=3؛ كلها LEGACY_UNCLASSIFIED.
  - PO-source invoices=0، Quick Market invoices=0.
  - buyer_goods_custody_events=0، buyer_custodies=0، buyer_custody_expenses=0.
  - purchase_returns=0.
  - inventory_log=76، supplier_ledger=2.
  - journal_entries Posted=17 وCancelled=2.
- الفواتير PINV-1000 وPINV-1001 وQA-SR-INV-20260927 بقيت SAR كما هي. الأخيرة Draft لكنها is_received=true، ولذلك لا تظهر قابلة للتحرير وفق شروط Buyer الحالية. لم يُحذف أو يُعكس أو يُعاد تصنيف أي صف.

### 2.3 Buyer وReceiver

- Buyer يدعم الآن مسارين منفصلين: PO invoice وQuick Market invoice بلا PO، مع مورد مركزي نشط ورقم فاتورة مورد وسعر فعلي يدوي.
- Quick Market يحتجز مبلغ العهدة النقدية دون إنشاء سداد أو حركة مخزون أو AP بمجرد Draft.
- تسليم المورد إلى Buyer يسجل حدث حيازة منفصلًا؛ vehicle_id اختياري ولا يغيّر مخزون الفرع.
- رصيد الحيازة مشتق من دفتر الأحداث؛ لا يعاد استخدام رصيد Fleet/Driver بوصفه رصيد Buyer.
- Receiver الحالي: companies/company-1/warehouse/receiver.html، blob 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6. التطبيق يشترك في purchase_orders فقط، ولا توجد فيه إشارات إلى purchase_invoices أو supplier_invoice_no أو QUICK_MARKET.
- receive-purchase v13 لا يحتوي مسار Quick Market. لذلك لا يستطيع Receiver الحالي البحث عن فاتورة السوق السريع أو قبول كمياتها. هذا تأجيل مرحلة معلن، وليس دليلًا على اكتمال دورة الشراء.

### 2.4 Supabase Advisors

- Security: 24 RLS-enabled/no-policy INFO، و1 mutable search_path WARN، و18 anon SECURITY DEFINER executable WARN، و139 authenticated SECURITY DEFINER executable WARN، و1 leaked-password protection WARN.
- Performance: 303 unindexed foreign keys، و67 RLS initplan، و59 unused indexes، و18 multiple permissive policies، و7 duplicate indexes.
- 29 من تحذيرات unindexed foreign keys تخص جداول Buyer custody، منها 6 على buyer_goods_custody_events. هذا خطر توسع/أداء، وليس دليل بطء حالي؛ الجداول الجديدة فارغة.
- لم يُنفذ blanket revoke أو تعديل عام على الوظائف أو الجداول.

## 3. UNKNOWN

- لم تتوفر جلسة Buyer مصادق عليها في المتصفح، لذلك لا توجد نتيجة authenticated Browser E2E.
- لم يثبت تشغيل سيناريو إنشاء Quick Market ثم handover ثم قبول Receiver؛ لم تُنشأ بيانات لهذا الاختبار.
- لم يُثبت وصول حدث Realtime إلى واجهة Buyer أو قياس latency.
- لم تتوفر بيئة Staging مستقلة للاختبار.
- لم أتمكن من إعادة فتح Cloudflare dashboard أو قراءة Artifact المنشور من هذه الجلسة.

## 4. CONFLICT

### 4.1 Edge source مقابل Production Edge

- مصدر GitHub التشغيلي supabase/functions/save-purchase-order/index.ts: blob bc038…، حجمه النصي 23077 حرفًا.
- المصدر الحي المستخرج من Supabase Edge v25: 30017 حرفًا، SHA-256 أعلاه.
- المصدر الحي يحتوي 10 عمليات Buyer إضافية غير موجودة في ملف GitHub: CREATE_PO_INVOICE، UPDATE_PO_INVOICE، CREATE_QUICK_MARKET_INVOICE، UPDATE_QUICK_MARKET_INVOICE، REGISTER_QUICK_MARKET_HANDOVER، GET_QUICK_MARKET_HANDOVER_PROGRESS، GET_BUYER_GOODS_CUSTODY_BALANCES، DELETE_QUICK_MARKET_DRAFT، UPDATE_BUYER_LEGACY_DRAFT، DELETE_BUYER_DRAFT_INVOICE.
- Git source لا يحتوي getVisibleInvoiceIds ولا نطاق GET_DATA الخاص بفواتير المشتري، بينما Edge v25 يحتويه.
- Current/CTO/EdgeSnapshots/20261104/save-purchase-order/index.ts يطابق المصدر القديم، وليس Edge v25. يوجد أيضًا snapshot أقدم في Current/Edge_Functions.
- النتيجة: Production Edge أحدث من مصدر Git. إعادة نشر المصدر الحالي من Git قد تسقط عمليات Buyer الجديدة ونطاق فواتير المستخدم. لا تنشر أو تستبدل Edge قبل استعادة مصدر v25 ومقارنته byte-for-byte.

### 4.2 نطاق قراءة الفواتير

- Edge GET_DATA يرشح purchase_invoices وpurchase_invoice_details حسب purchaser_user_id أو created_by، ويوسع العرض للمالية/مدير المالية/مالك النظام.
- لكن Production يمنح authenticated SELECT على purchase_invoices وpurchase_invoice_details، وسياسات RLS الحالية تقيد الشركة فقط، لا المشتري أو الدور.
- لذلك نطاق “فواتيري” محمي في مسار Edge GET_DATA، لكنه غير مفروض في طبقة RLS عند القراءة المباشرة من Data API. لا تعتبره عزلًا أمنيًا كاملًا قبل توحيد السياسة مع جميع مستهلكي الجدولين.

### 4.3 حذف المسودات

- Buyer الحالي يستخدم wrappers المخصصة، وهذا تصحيح إيجابي في commit bf0833c.
- لكن Edge v25 ما زال يعرض DELETE_DRAFT_INVOICE؛ هذا المسار يمر عبر Service Role إلى purchase_delete_draft_invoice_atomic، وحاجز Edge العام يكتفي بصلاحية purchases.
- الدالة القديمة تتحقق من حالة Draft والآثار المرتبطة، لكنها لا تتحقق من ملكية المشتري، ولا تفحص buyer_goods_custody_events.
- source_document_id في buyer_goods_custody_events ليس له FK إلى purchase_invoices. لذلك المسار القديم قد يحذف فاتورة مع بقاء أحداث حيازة يتيمة إذا أمكن تجاوز قيود الحذف الأخرى.
- Buyer UI لم يعد يستخدم هذا المسار، لكن endpoint ما زال متاحًا؛ لا تحذفه قبل حصر جميع مستهلكيه، ويجب تحصينه مركزيًا.

### 4.4 فواتير المورد والمرتجعات

- purchase_returns وpurchase_return_details ما زالتا تمنحان anon وauthenticated صلاحيات INSERT/UPDATE/DELETE، مع سياسة ALL على مستوى الشركة.
- توجد triggers لتاريخ الحالة وupdated_at، لكنها لا تجعل DML المباشر بديلًا آمنًا عن مسار الأعمال المركزي.
- هذا خطر قائم سابقًا، وليس أثرًا أنشأته مرحلة Buyer. عدد السجلات الحالي صفر.

### 4.5 النشر

- آخر deployment موثق في Cloudflare هو commit 3717c027.
- Git HEAD الحالي bf0833c، ويتضمن تعديلات 841b90f وbf0833c اللاحقة.
- لا يوجد دليل حالي يثبت أن bf0833c وصل إلى Production Artifact؛ لذلك لا تساوِ Git HEAD مع النسخة المنشورة.

## 5. UNVERIFIED

- لم يتم فحص HTML/JS الفعلي الذي يقدمه Cloudflare للـcommit bf0833c.
- لم يتم اختبار JWT مستخدم مشتريات فعليًا أو مستخدم مالي أو مستخدم آخر في الشركة.
- لم يتم اختبار Storage upload/download أو تحقق وجود evidence object.
- لم يتم قياس WebSocket event delivery أو reconnect أو cache invalidation.
- لم يتم تنفيذ أي test write في Production أو Staging.

## 6. مصفوفة التحقق

| الطبقة | النتيجة | الدليل/الحد |
|---|---|---|
| GitHub Source | CONFIRMED مع تعارض Edge | operational HEAD bf0833c؛ Buyer/CSS فقط تغيرا؛ Edge source أقدم من v25 |
| Supabase Production | CONFIRMED ضمن النطاق | migrations 01–09، Edge v25، RLS/grants/functions/data counts |
| Deployed Artifact | CONFIRMED جزئيًا | commit 3717 موثق في Report624؛ bf0833c غير مثبت |
| Runtime / Browser E2E | UNKNOWN | لا جلسة Buyer مصادق ولا Browser context |
| Business-Data Effects | CONFIRMED عدم إنشاء أثر في هذه المراجعة | لا صفوف Buyer جديدة؛ لا حركة مخزون/AP/GL/خزينة |
| Staging | UNKNOWN | لا بيئة منفصلة مثبتة |

## 7. ما تم فعليًا في هذه المراجعة

- جلب CURRENT_STATE والدستور التشغيلي والدستور CTO والتقارير ذات الصلة، ثم مطابقة LVE624 مع GitHub وSupabase.
- إعادة التحقق من HEAD والملفات المتغيرة، ومقارنة Edge Git source مع Edge Production.
- قراءة Buyer وcore.js وregister-sw.js وsw.js وReceiver، وفحص parsing للـinline JavaScript.
- استعلامات SQL كانت SELECT فقط: schema، functions، grants، policies، triggers، publications، counts، وبيانات الفواتير.
- مراجعة Supabase advisors.
- لم تُنشأ بيانات QA، ولم يحدث أي write أو migration أو deployment في هذا التشغيل.

## 8. ما لم يتم ولماذا

- لم يتم نشر Buyer commit bf0833c لأن Cloudflare artifact غير متاح للتحقق.
- لم يتم E2E لأن جلسة Buyer مصادق غير متاحة.
- لم يتم إصلاح Edge source drift لأن ذلك تعديل تشغيلي يتطلب ChangeSet وموافقة.
- لم يتم تعديل RLS أو grants أو settlement RPC أو event RPC؛ كلها بوابات Production صريحة.
- لم يتم تعديل Receiver أو SupplierReturn؛ Receiver مؤجل وفق توجيه المالك.

## 9. صحة النظام والتطبيقات والتغطية

| النطاق | تغطية اليوم | الحكم |
|---|---|---|
| Buyer | فحص المصدر الحالي والـAPI والـDB والعقود | فُحص |
| Core / RW_API / RW_Realtime | فحص المسارات المشتركة ذات الصلة | فُحص جزئيًا؛ لا تعديل |
| PWA / Service Worker | فحص register-sw وsw.js وسياسة cache | فُحص |
| Receiver | فحص UI وEdge v13 لاعتماد Quick Market | فُحص جزئيًا؛ لا تكامل |
| Main / Mother | لم يتغير ضمن diff؛ تعذر جلب محتوى main كاملًا | يحتاج دورة مستقلة |
| SupplierReturn / Returns / Vouchers | لا تغيير في diff؛ لم تُعد مراجعة جميع المسارات | غير مفحوص بالكامل |
| بقية التطبيقات | لا تغير مباشر معروف | لم تُفحص اليوم |

## 10. تدقيق التعديلات الأخيرة وآثارها

- 19 commit على operational main منذ e8ab54c؛ جميعها محصورة في Buyer وملف CSS.
- commit 77f44cc غيّر buyer.tailwind.css. الملف كان موجودًا قبل ذلك، أي أن محتوى CSS تغير مع بقاء الاسم نفسه.
- commit 841b90f أضاف تحكم الملكية في واجهة تفاصيل الفاتورة.
- commit bf0833c ربط حذف PO/Legacy وQuick Market بالـRPC wrappers الصحيحة.
- لم تتغير main.html أو core.js أو Receiver أو SupplierReturn ضمن هذه السلسلة.
- هذه commits تثبت Source فقط؛ لا تثبت deployment أو Runtime.

## 11. الأخطاء والفجوات والحلول

### P1 — تسوية العهدة تتجاهل حجوزات Quick Market

- Buyer UI يحسب qmpReserved ويعرض المتاح بعد الحجز في renderCustody (نحو الأسطر 1142–1146)، لكن زر إقفال التسوية يعتمد فقط على pendingCount===0 (السطر 1153).
- settleCustody يحسب maxReturn = issued_amount - approved expenses (الأسطر 1298–1314)، ولا يطرح qmpReserved.
- buyer_custody_settle_atomic يتحقق من المصروفات المعلقة والزيادات غير المؤكدة، لكنه لا يستعلم عن purchase_invoices ذات cash_custody_id ومصدر QUICK_MARKET.
- الأثر المحتمل: إغلاق العهدة وإرجاع النقد كاملًا بينما توجد فاتورة Quick Market Draft ما زالت تحجز جزءًا من العهدة؛ تبقى الفاتورة مرتبطة بعهدة مغلقة.
- لا توجد حاليًا أي Quick Market invoices أو cash custodies، لذلك لا يوجد أثر فعلي مسجل.
- الحل المقترح: حارس ذري داخل buyer_custody_settle_atomic يمنع التسوية ما دامت هناك حجوزات QMP مفتوحة، ثم تعطيل زر التسوية في الواجهة مع عرض سبب المنع. يجب أن يكون الحارس في DB لا في الواجهة فقط.

### P1 — DELETE_DRAFT_INVOICE العام ما زال يتجاوز ملكية المشتري

- Edge v25 يتيح DELETE_DRAFT_INVOICE عبر Service Role؛ لا يوجد في هذا الفرع تحقق purchaser_user_id أو created_by أو owner.
- الدالة القديمة لا تفحص buyer_goods_custody_events؛ وsource_document_id لا يملك FK.
- الحل المقترح: حصر جميع مستهلكي DELETE_DRAFT_INVOICE، ثم تحويل المسار المركزي إلى wrapper source-aware يعتمد JWT والملكية؛ رفض أو إزالة المسار العام بعد التأكد من المستهلكين. إبقاء wrappers المخصصة الحالية وعدم تكرار منطق الحذف.

### P1 — عزل “فواتيري” غير مكتمل في RLS

- Edge GET_DATA يرشح الفواتير، لكن RLS يسمح لأي authenticated داخل الشركة بقراءة جميع رؤوس الفواتير وتفاصيلها.
- الحل المقترح: سياسة موحدة حسب المشتري/المالية/المالك أو واجهة قراءة آمنة؛ لا تُضيق RLS قبل حصر مستهلكي الجدولين، خصوصًا Receiver والمالية والتقارير.

### P1 — DML مباشر على purchase_returns

- anon وauthenticated يملكان INSERT/UPDATE/DELETE على purchase_returns وpurchase_return_details، والسياسات ALL على مستوى الشركة.
- الحل المقترح: حصر كل المستهلكين، ثم قصر الكتابة على RPC المركزي وإزالة DML المباشر على نحو محدود ومختبر؛ لا blanket revoke.

### P1 — إثبات الحيازة غير مفروض في RPC

- UI يطلب PDF/صورة، لكن buyer_goods_custody_register_handover_atomic لا يرفض p_evidence_path=NULL ولا يتحقق من وجود object أو مساره.
- evidence_path nullable في الجدول.
- catch في Buyer يحاول التحقق من العملية بعد فشل RPC؛ إذا فشل التحقق أيضًا تبقى committed=false ثم يحذف الملف. إذا كانت العملية قد committed بالفعل والقراءة فشلت مؤقتًا، قد يبقى الحدث مع evidence_path مكسور.
- الحل المقترح: تحقق server-side من المسار والملف والمالك، وميّز ثلاث حالات: committed / not committed / unknown. لا تحذف الملف في حالة unknown؛ احفظه للمطابقة أو التنظيف الآمن لاحقًا.

### P2 — Realtime دفتر حيازة البضاعة غير موصول بواجهة Buyer

- buyer_goods_custody_events عضو في publication، لكن Buyer startRealtime لا يضيفه إلى tables (الأسطر 241–270)، وtargets لا تحتويه أو هدف vehicle.
- reconcileMs=15000؛ لذلك التحديث الحالي المتوقع دوري كل 15 ثانية، وليس event-driven لهذا الدفتر.
- الحل المقترح: إضافة الجدول إلى subscription وإضافة event targets لتبويبي custody وvehicle، ثم اختبار وصول الحدث وإعادة الاتصال وlatency. لا تصف الدفتر بأنه لحظي قبل ذلك.

### P2 — دليل الحيازة لا يظهر للمراجع

- renderVehicleBalance يعرض الحدث والكمية والفاتورة والملاحظات (نحو الأسطر 736–738)، لكنه لا يعرض evidence_path كرابط مشاهدة.
- الحل المقترح: عرض مستند الإثبات بصلاحية قراءة آمنة وربطه بالحدث؛ لا تكشف Storage path أو ملفًا دون تحقق ACL.

### P2 — Cache CSS قديم على أجهزة PWA القائمة

- buyer.tailwind.css تغير من blob ec158352… إلى 7eb4ef…، لكن sw.js ما زال يستخدم SW_BUILD RAWAEA_SW_P156_HR_REPUBLISH_20260918.
- Service Worker يخزن CSS في static cache بأسلوب cache-first، ولا يتغير cache key إلا بتغيير SW_BUILD أو URL.
- لذلك قد يستمر عميل سبق أن خزّن CSS القديم في استخدامه حتى تحديث cache. لم يُثبت حدوث ذلك على جهاز فعلي.
- الحل المقترح الأقل نطاقًا: versioned CSS URL/hash في Buyer فقط، أو تغيير SW build بعد فحص أثره على جميع التطبيقات؛ لا تعدل Service Worker المشترك دون ChangeSet.

### P2 — تحرير Legacy Draft قد يغير العملة التاريخية

- createPurchaseInvoice يقرأ عملة النظام من GET_SETTINGS ويضعها في payload حتى عند تحرير فاتورة قائمة (الأسطر 875–879 و928).
- UPDATE_BUYER_LEGACY_DRAFT يصل إلى purchase_update_draft_invoice_atomic التي تعيد كتابة currency إلى v_system_currency.
- الفاتورة التاريخية الوحيدة Draft حاليًا QA-SR-INV-20260927 is_received=true، فلا يسمح مسار Buyer الحالي بتحريرها؛ لا يوجد تغيير حالي.
- لكن Legacy Draft مستقبلية بعملة SAR وغير مستلمة قد تتحول إلى EGP دون تحويل أو موافقة.
- الحل المقترح: preserve current.currency في التعديل أو منع تحرير Legacy currency mismatch إلى أن يمر عبر مسار مطابقة/عكس مستقل.

### P1 / مرحلة تالية — Receiver لا يستقبل Quick Market

- Receiver UI يقرأ purchase_orders فقط، وRealtime على purchase_orders فقط، وreceive-purchase v13 لا يعرف QUICK_MARKET.
- لا يوجد الآن طريق لقبول كميات Quick Market في المخزن؛ لذلك لا stock/AP/GL posting لهذه الفواتير.
- هذا قيد Phase 1 المعلن، لكنه يمنع اكتمال دورة المورد → Buyer → Receiver → المخزون والحسابات. لا تبدأ Receiver قبل إغلاق قبول Buyer وباعتماد ChangeSet منفصل.

## 12. الكفاءة التشغيلية والميدانية

| السيناريو | الحالة المثبتة |
|---|---|
| إنشاء PO | كود موجود؛ Draft لا يغير المخزون/AP |
| فاتورة Quick Market بلا PO | كود + RPC + Edge موجود؛ Draft بلا stock/AP |
| المورد → Buyer | حدث حيازة append-only موجود؛ لا أثر على مخزون الفرع |
| Buyer → Receiver | غير موجود في هذه المرحلة |
| Receiver → stock/AP | موجود للـPO عبر المسار الأصلي؛ غير متاح لQuick Market |
| عهدة نقدية + حجز Quick Market | الحجز يحسب؛ قفل التسوية لا يحترم الحجز بعد |
| SupplierReturn / قبول المورد | مؤجل ولم يُعدل |
| إثبات ميداني فعلي | UNKNOWN؛ لا جلسة مستخدم أو E2E |

## 13. التخطيط والتنبؤ ومركز القرار الذكي

UNKNOWN في هذا النطاق. لم تُراجع اليوم جودة بيانات الطلب، forecast accuracy، stock safety، supplier lead-time أو مؤشرات replenishment. وجود dashboard أو حقل توقع لا يكفي لإثبات ذكاء تشغيلي.

## 14. المقارنة التنافسية

لم يُجرَ بحث منافسين جديد في هذا التشغيل؛ يُحتفظ بخط الأساس الوظيفي الموثق في Report621 للمقارنة مع Dynamics 365 وSAP وOdoo. لا توجد نتيجة جديدة تسمح بادعاء تكافؤ RAWAEA أو جاهزيته العالمية. الأولوية الحالية سلامة دورة الشراء والعهدة والملكية والتكامل قبل توسيع الميزات.

## 15. مصفوفة النضج

التقييم التالي على مستوى المنظومة كلها، لا Buyer وحده. لا توجد أدلة كافية اليوم لإسناد درجة نظامية:

| المجال | الدرجة | ملاحظة |
|---|---|---|
| السلامة التقنية والمعمارية | UNKNOWN | لم تُراجع كل التطبيقات والعقود |
| تكامل التطبيقات والبيانات | UNKNOWN | Buyer/Receiver فقط ضمن النطاق |
| العمليات التجارية | UNKNOWN | Buyer جزئي؛ لا E2E |
| الرقابة المالية والمحاسبية | UNKNOWN | ظهر خطر تسوية QMP؛ لا اختبار ميداني |
| المخزون وسلاسل الإمداد | UNKNOWN | Buyer custody لا يساوي stock acceptance |
| التوزيع والعمل الميداني | UNKNOWN | لم تُراجع التطبيقات الميدانية اليوم |
| التخطيط والتنبؤ | UNKNOWN | لم تُقاس الدقة |
| التقارير وBI | UNKNOWN | خارج النطاق |
| الأمان والصلاحيات والتدقيق | UNKNOWN | توجد فجوات P1 مؤكدة |
| الأداء والاستقرار والتوسع | UNKNOWN | advisor warnings؛ لا load test |
| تجربة المستخدم والإنتاجية | UNKNOWN | static parse فقط، بلا مستخدم ميداني |
| الجاهزية التشغيلية والتنافسية | UNKNOWN | لا E2E ولا benchmark جديد |

**Buyer procurement slice فقط:** 2/5 في التصميم والتنفيذ الجزئي؛ لا درجة ميدانية، لأنها UNVERIFIED.

## 16. خريطة النظام الأم والقلب المركزي

- Buyer ملف مستقل داخل companies/company-1/purchasing ويحمّل ../core.js و../register-sw.js وmanifest.json.
- Core الفعلي في companies/company-1/core.js؛ Buyer يستخدم RW_Auth/RW_API/RW_Realtime بدل بناء اتصال مستقل.
- main.html وcore.js لم يتغيرا ضمن commits الـ19. لم يُنفذ تدقيق كامل للنظام الأم أو لجميع مستهلكي Core في هذا التشغيل.
- save-purchase-order هو Edge الموجود الذي يحمل مسارات Buyer الجديدة؛ لا Edge Function جديدة.
- أكبر فجوة مصدرية: Edge v25 الحي لم تتم مزامنته إلى operational Git.

## 17. مصفوفة المزامنة

| البيانات | الآلية في المصدر | النتيجة |
|---|---|---|
| purchase_invoices / details | Realtime subscription + GET_DATA | الاشتراك موجود؛ وصول الحدث لم يُختبر |
| buyer_custodies / advances / expenses | Realtime subscription | الاشتراك موجود |
| buyer_goods_custody_events | Publication موجود، Buyer subscription غائب | تحديث دوري reconcile 15s فقط حسب الكود |
| Receiver purchase_orders | Realtime subscription + reconcile 60s | لا Quick Market subscription |
| CSS Buyer | Service Worker cache-first | احتمال stale cache بعد تغيير الملف دون version bump |
| Auth / RLS / JWT | Edge profileClient للعمليات الجديدة | static contract confirmed؛ E2E غير مختبر |

## 18. جاهزية المساعد واستلام شعلة التطوير

**الحكم: READY WITH LIMITATIONS.**

يمكن استكمال التحليل وإعداد ChangeSet جراحي من آخر نقطة مثبتة. لا يجوز تنفيذ كتابة Production أو نشر Edge/UI قبل موافقة صريحة على التغيير المحدد. لا تتوفر جلسة Buyer مصادق أو Staging أو Runtime artifact verification. يجب استعادة مصدر Edge v25 إلى Git قبل أي إعادة نشر.

## 19. الالتزام بالدستور التشغيلي الدائم

- الدستور الحالي SHA d2afa896…؛ تمت قراءته كاملًا.
- MASTER CTO GOVERNANCE الحالي SHA 1a0c81c…؛ §§77.2–77.4 مطبقة.
- Report614 الحالي SHA 15caa4c…؛ §14 يفرض عرض ChangeSet كامل ثم موافقة المالك الصريحة.
- لا تعديل في Production أو الكود التشغيلي أو الصلاحيات أو النشر في هذا التشغيل.
- تنبيه توثيقي: CURRENT_STATE القديم كان يشير إلى Report614 blob 5ae52…؛ الملف الحالي blob 15caa4…، ويجب أن يستخدم أي استئناف لاحق النسخة الحالية لا pointer التاريخي.

## 20. المخاطر والاعتماديات وموافقة المالك

1. حماية settlement من QMP reservations.
2. تحصين DELETE_DRAFT_INVOICE العام وحصر مستهلكيه.
3. توحيد RLS invoice scope مع GET_DATA وجميع المستهلكين.
4. إزالة direct DML على purchase_returns بعد consumer map.
5. فرض evidence validation وعدم حذف الملف عند UNKNOWN.
6. مزامنة Edge v25 byte-for-byte إلى operational Git.
7. التحقق من نشر bf0833c، ثم authenticated E2E.
8. إضافة Realtime subscription وversioned CSS.
9. Receiver Quick Market workflow مرحلة مستقلة بعد قبول Buyer.
10. أي تغيير في هذه البنود يحتاج ChangeSet محددًا، نصًا أصليًا وبديلًا، أثرًا واعتماديات واختبارات وخطة تراجع، ثم موافقة صريحة.

## 21. الخطوة التالية ذات الأولوية

إعداد ChangeSet واحد P1 لـBuyer Phase 1 Hardening قبل أي توسع ميداني: يبدأ بمزامنة مصدر Edge v25 إلى Git ثم يغلق مساري DELETE_DRAFT_INVOICE العام وتسوية العهدة مع حجوزات Quick Market، ويضيف بوابة إثبات الحيازة الآمنة. يجب أن يتضمن اختبار ملكية بين مشتريين، ورفض حذف فاتورة عليها حدث حيازة، ورفض إغلاق عهدة عليها QMP reservation، واختبار انقطاع الشبكة دون فقد ملف الإثبات، وإثبات عدم حدوث أي stock/AP/GL/cash effect غير مقصود. يُعرض ChangeSet للمالك للموافقة؛ لا يُنفذ شيء في Production قبلها.

**الخلاصة:** Buyer Phase 1 موجود في Source وSchema وEdge v25، لكن لا يصح إعلان اكتمال دورة الشراء أو الجاهزية التشغيلية. توجد مخاطر P1 مؤكدة في تسوية العهدة، وحماية الحذف العام، وعزل قراءة الفواتير، وDML المرتجعات، وإثبات الحيازة. لا توجد بيانات متأثرة حاليًا، ولا يوجد E2E مصادق أو نشر مثبت لآخر Buyer commit.
