# Report704 — المراجعة التشغيلية اليومية الشاملة: Inventory Control + Returns Gate
**التاريخ:** 2026-11-11 — **نقطة الفحص:** 22:47 Africa/Cairo  
**Checkpoint الجديد:** LVE-2026-11-11-704  
**الحكم:** READY WITH LIMITATIONS  
**نطاق اليوم:** Warehouse Hub، الجرد، مخزون الفروع، طلبات التحويل، ومرتجعات التشغيل. لا يمثل هذا التقرير تدقيقًا كاملًا لكل تطبيقات RAWAEA.

## 1. نقطة البداية — LAST VERIFIED EVENT
- ملف الحالة المرجعي: CURRENT_STATE.md، SHA: 38588a5f…، 1,562 سطرًا. آخر نقطة مسجلة فيه هي LVE-2026-11-10-703، مع Report703.
- الدستور التشغيلي الدائم قُرئ كاملًا: doc/Draft/Reprots/الدستور التشغيلي الدائم.md، SHA: 3a6b1e…، 34,396 بايت.
- مستودع الحالة والتقارير: main HEAD = 9e9fb9414551dbfd4020383c87a9a2518a236efa. أحدث تقرير محفوظ قبل هذا التشغيل هو Report703.
- المستودع التشغيلي: papamohammed77-glitch/erp-frontend، الفرع main، HEAD الحالي c03a47ee69f60956dc327953e027c7172fba4c71. نقطة Report703 كانت 4f018bfe…؛ يوجد 7 commits بعدها.
- الهدف التنفيذي المفتوح من آخر طلبات المالك: نقل وظائف تبويب الجرد/Inventory Control من النظام الأم إلى Warehouse Hub، لا الاكتفاء بشاشة عدّ الأصناف. لم يثبت إغلاق هذا الهدف.
- آخر إغلاق تاريخي ذي صلة: CS-WH-701-A/B/C/D وفق Report701 وReport702. أما CS-WH-703-A المقترح في Report703 فلم يكن معتمدًا وقت التقرير.

## 2. CONFIRMED
1. HEAD التشغيلي الحالي c03a47ee… والفرع main. بيانات GitHub للفرع تعيد protected=false؛ حالة Rulesets غير متاحة، لذلك لا أستنتج عدم وجود أي حماية أخرى.
2. سبعة commits جديدة بعد 4f018bfe. التغييرات ذات الصلة:
   - 0e11383c: إضافة migration موحّد لوظائف Inventory Control وCosted Count Finalization.
   - 23fabe47 و2c1dfe19: تصحيح/تنظيف اسم ملف migration.
   - 6098a1ac: إضافة Returns discrepancy integrity gate.
   - 93d9da3d وe2492121: توسيع فحص الواجهة ليشمل pending وinvestigating.
   - c03a47ee: تحديث اختبارات المصدر/الـworkflow.
3. Supabase SMART ERP (fiilmooggumokxanwiyx) حالته ACTIVE_HEALTHY، PostgreSQL 17.6.1.121، منطقة eu-west-1.
4. Production migration history يحتوي النسختين 20261110225700 و20261110233152. محتوى كل migration المخزن في سجل Supabase يطابق ملف Git الحالي بعد التطبيع النصي.
5. Migration 20261110225700، SHA 6599d3c74c43051aad3851fa320f34debf56425c، يحتوي 909 أسطر ويعرّف:
   - inventory_stock_snapshot (السطر 5)
   - inventory_movement_report (64)
   - inventory_replenishment_report (337)
   - inventory_stock_request_engine (485)
   - inventory_count_engine (660)
   وهو تغيير وظائف قاعدة بيانات، لا يضيف شاشة إلى warehouse.html.
6. Migration 20261110233152، SHA 24c122e7c391a2a8ebcb854dda887a6a885eb422، يحتوي 247 سطرًا ويضيف:
   - guard_stock_discrepancy_integrity (السطر 16)
   - prevent_runsheet_close_with_unresolved_discrepancies (134)
   - trg_stock_discrepancies_integrity (128)
   - trg_runsheets_unresolved_discrepancy_close_guard (164)
   - قيد status، وفهرس unresolved، وسياسات RLS محدّثة.
7. Edge Functions الحالية:
   - save-inventory-count v5، verify_jwt=true.
   - report-discrepancy v4.
   - complete-return v28.
   - reopen-return v2.
   - cancel-return v6.
   ملفات index.ts الحية لهذه الوظائف تطابق ملفات Git التي فُحصت. save-inventory-count يستدعي inventory_count_engine وinventory_stock_request_engine عبر service_role بعد التحقق من JWT وربط المستخدم بـauth_id.
8. inventory_count_engine وinventory_stock_request_engine وinventory_stock_snapshot محمية بصلاحية service_role، بينما inventory_control هو SECURITY DEFINER ويستند إلى auth.uid(). لا يستطيع authenticated استدعاء المحركين مباشرة.
9. complete_return_atomic يحدّث runsheets.status إلى Returned. Trigger الإغلاق الجديد يعمل قبل تغيير الحالة، ويفحص pending وinvestigating؛ إذا وجد أحدهما يرفع خطأ، فتُلغى معاملة SQL كلها. هذا يغلق مسار تجاوز الواجهة على مستوى قاعدة البيانات من حيث بنية التنفيذ.
10. stock_discrepancies لا يحتوي سجلات حاليًا، ولا توجد runsheet بحالة Returning وقت الفحص؛ لذلك لم يُنفّذ الـtrigger فعليًا على واقعة تشغيلية.
11. warehouse.html الحالي SHA 9f0b877… ويحتوي سبع وحدات native: receiver, picker, loader, returns, unloader, counter, vouchers، مع أربع تبويبات رئيسية.
12. Counter الحالي يدعم جلسات branch/general/vehicle، الإنشاء، التهيئة، قراءة الجلسة، حفظ السطور، refresh، finalize، cancel، وسجل الجرد. ويستدعي save-inventory-count Edge Function.
13. لا توجد في warehouse.html استدعاءات لـSNAPSHOT أو MOVEMENTS أو REPLENISHMENT أو REQUEST_CREATE/REQUEST_LIST، ولا تظهر واجهة Inventory Control Center لهذه الوظائف. الموجود في الواجهة هو عدّ المخزون وبعض وظائف vouchers؛ أما وظائف التقارير والطلبات الجديدة فخلفية فقط.
14. يوجد سجل جرد واحد InProgress، به 35 سطرًا، وكل counted_qty ما زال NULL، ولا توجد أسطر adjusted. لا يوجد أثر مرتبط به في inventory_log أو journal_entries أو erp_operation_registry. لم ينشئ هذا التشغيل السجل ولم يعدّله.
15. مخزون/حسابات Production في قراءة اليوم: stock_branches=58، inventory_log=78، stock_vouchers=0، journal_entries=21، journal_lines=38، supplier_ledger=3، receiving=1، receiving_details=2، stock_discrepancies=0، inventory_stock_requests=0. لم تُنفذ أي كتابة في قاعدة البيانات خلال هذا التشغيل.

## 3. UNKNOWN
- Cloudflare Pages artifact الحالي وcommit/build lineage غير معروفين. آخر مرجع تاريخي في Report703 كان SHA 83c0f39…، ولا يجوز اعتباره النشر الحالي.
- لا توجد جلسة Browser متصلة في هذا التشغيل، وتعذر جلب HTML المنشور عبر قناة الويب/الحاوية؛ Runtime وConsole وNetwork وPWA cache غير متحقق منها.
- لا توجد بيئة Staging متاحة عبر الأدوات المتصلة. لم تُجر اختبارات كتابة في Production.
- لا يمكن إثبات ما إذا كانت كل واجهات النظام الأم تستخدم inventory_stock_requests مباشرة؛ ملف main.html أعاد SHA e43707fa… لكن أداة القراءة أعادت محتوى فارغًا بسبب حجم/طريقة الإتاحة. لم يُستكمل audit كل المستهلكين.
- مصدر اعتماد المالك الدقيق للمهاجرات 20261110225700 و20261110233152 غير محسوم من سجل المحادثات المتاح. created_by في سجل migration ليس وحده مستند اعتماد ChangeSet.
- لا توجد قياسات فعلية لـRealtime latency أو التزامن أو أداء الاستعلامات تحت حمل ميداني.

## 4. CONFLICT / DELTA
1. CURRENT_STATE وReport703 يسجلان HEAD=4f018bfe، بينما GitHub الحالي c03a47ee. الحالة المرجعية متأخرة سبعة commits.
2. Migration 20261110225700 أُضيف في commit 0e11383c بتاريخ 2026-11-10 22:56:58Z، أي قبل commit Report703 بتاريخ 22:58:29Z، ومع ذلك لم يظهر في نقطة الحالة المسجلة. هذا قصور توثيق/مزامنة تاريخي، وليس دليلًا على فشل migration.
3. Report703 قال إن server-side gate لم يكن موجودًا. كان ذلك صحيحًا عند وقت التقرير؛ بعده أُضيفت migration 20261110233152 وسُجلت في Production. الحالة الحالية supersedes التقرير التاريخي.
4. يوجد تعارض عقد صلاحيات بين inventory_control wrapper وinventory_count_engine: المحرك يقبل branch-count/vehicle-count لعمليات CREATE/POPULATE، لكن wrapper يفرض v_warehouse الذي لا يشمل هاتين الصلاحيتين. Production يحتوي مستخدمًا نشطًا واحدًا بدور مدير مالي وصلاحيات branch-count/vehicle-count دون warehouse؛ لذلك مسار wrapper يمنعه من الإنشاء بينما مسار Edge المباشر يصل إلى المحرك ويقبل الصلاحية.
5. inventory_control يسمح COUNT LIST ويوجهه للمحرك، لكن inventory_count_engine لا يحتوي فرع LIST؛ الواجهة الحالية التي فُحصت تستخدم GET/قراءة مباشرة ولا يوجد إثبات أن LIST مستعمل، لذلك هذا تعارض عقد محتمل وليس عطلًا ميدانيًا مثبتًا.

## 5. UNVERIFIED
- لم يُختبر trigger المرتجعات عمليًا في معاملة اختبار مع rollback أو في Staging؛ وجوده وكونه enabled مؤكدان، وسلوكه الفعلي تحت التزامن غير مختبر.
- لم يُنفذ COUNT_FINALIZE في قاعدة معزولة. وجود المسار لا يثبت سلامة أثر المخزون والقيد المحاسبي وقت التشغيل.
- لم تُختبر دورة stock request من CREATE إلى APPROVE/REJECT/CONVERT/CANCEL.
- لم يُختبر رفض المستخدم غير المصرح له أو فرع خارج نطاقه في Browser/Runtime.
- لم يُثبت وصول Realtime events أو زمن وصولها إلى الأجهزة.
- لا يوجد دليل نشر يثبت أن c03a47ee وصل إلى Cloudflare Pages.

## 6. مصفوفة التحقق
| الطبقة | النتيجة | الدليل/القيد |
|---|---|---|
| GitHub / Source | CONFIRMED | main=c03a47ee، 7 commits بعد checkpoint |
| Supabase Production | CONFIRMED جزئيًا | ACTIVE_HEALTHY، migrations 25700 و33152، الوظائف والسياسات مقروءة |
| Deployed Artifact | UNKNOWN | لا وصول حالي إلى Cloudflare deployment أو HTML المنشور |
| Runtime / E2E | UNVERIFIED في Production | CI ناجح لكنه يستخدم mock/stub، لا Production E2E |
| Business-Data Effects | CONFIRMED read-only | لا كتابة من هذا التشغيل؛ جلسة الجرد الحالية لم ترحل مخزونًا أو حسابات |
| Staging | UNKNOWN | لا بيئة/اتصال Staging متاح |

## 7. ما تم فعليًا
- قراءة CURRENT_STATE.md والدستور التشغيلي الدائم كاملين.
- مراجعة Report701 وReport702 (بما فيه collaborator delta) وReport703 ومطابقة قراراتها مع Git وSupabase الحاليين.
- فحص branch/HEAD/commits/diffs والملفات الحالية warehouse.html وreturns.html وcore.js والمهاجرات.
- فحص Supabase migrations، function definitions/ACLs، RLS، policies، constraints، triggers، row counts، وسجلات الجرد ذات الصلة.
- فحص Edge Function versions ومطابقة مصادر index.ts الحية مع Git.
- فحص GitHub Actions:
  - Warehouse E2E: run 42925087463، job 130209432714، success.
  - Mother Inventory Forensic E2E: run 42925087498، job 130209432381، success.
  - CTO helper/current-mother checks ذات الصلة نجحت أيضًا.
- بحث Benchmarking رسمي حديث لوظائف المخزون والجرد وإعادة التوريد.
- لم يحدث أي تعديل في المستودع التشغيلي أو قاعدة Production أو Edge Functions خلال هذا التشغيل.

## 8. ما لم يتم ولماذا
- لم يُعدّل warehouse.html أو main.html أو core.js؛ لأن تغيير التطبيق التشغيلي يتطلب ChangeSet محددًا واعتماد المالك وفق بوابة الحوكمة.
- لم تُغيّر RLS/Grants أو Functions أو migrations في Production؛ لأن ذلك تغيير صلاحيات/عقود وطلب اعتماد منفصل.
- لم تُجر اختبارات كتابة في Production، ولم تُنشأ بيانات QA؛ لا توجد Staging متاحة، والدستور يمنع تحويل بيانات الأعمال إلى بيانات اختبار.
- لم يُعلن نجاح النشر أو Runtime بسبب غياب Cloudflare/browser evidence.

## 9. صحة النظام والتغطية
| النطاق | فحص اليوم | الحالة |
|---|---|---|
| Warehouse Hub | Source + DB + CI | فُحص ضمن النطاق؛ Runtime غير متحقق |
| Counter / الجرد | Source + Edge + DB | فُحص؛ finalization غير مختبر |
| Returns / discrepancy | Source + Edge + DB triggers/RLS | فُحص بنيويًا؛ لا توجد واقعة اختبار |
| Vouchers | Source/Reatime hooks | فحص جزئي؛ لا E2E مالي |
| Receiver / Picker / Loader / Unloader | host bundles وCI فقط | لم تُعد دورة الأعمال كاملة |
| Parent main.html | SHA وCI smoke فقط | المحتوى الكامل غير متاح للقراءة المباشرة |
| core.js | قراءة وحدات Auth/DB/API/Realtime ذات الصلة | لم تتغير في commits الحالية؛ لم يُجر audit لكل المستهلكين |
| Buyer/Sales/POS/Delivery/Finance | لا فحص وظيفي اليوم | خارج نطاق التغييرات الحالية؛ لا ادعاء سلامة |

## 10. تدقيق التغييرات الأخيرة
- 20261110225700: يضيف/يحدّث خمس وظائف مركزية للجرد والحركة والتوريد والطلبات والعدّ النهائي. Production migration مطابق للمصدر. لا يضيف واجهة Inventory Control Center إلى warehouse.html.
- 20261110233152: يضيف integrity triggers لمرتجعات المخزن، ويحدث RLS وقيود discrepancy. Migration مطبقة ومطابقة للمصدر.
- 93d9da3d/e2492121: الواجهة المدمجة والمستقلة أصبحتا تفحصان pending وinvestigating بدل pending فقط.
- c03a47ee: يضيف فحوصًا ثابتة في CI للـgate.
- لم يتغير main.html أو core.js ضمن المقارنة من 4f018bfe إلى c03a47ee.
- نتائج CI ناجحة، لكن اختبارات Warehouse تعتمد على Supabase/Edge mocks وDexie in-memory. لا تثبت Production DB behavior ولا COUNT_FINALIZE.

## 11. الأخطاء والفجوات والحلول
**P1 — تجاوز صلاحيات طلبات التحويل عبر REST المباشر**
- Production RLS يسمح authenticated بـSELECT/INSERT/UPDATE/DELETE على inventory_stock_requests وinventory_stock_request_details.
- السياسات من نوع ALL وتتحقق من company_id فقط، ولا تفرض transfer/warehouse permission أو انتقالات الحالة.
- لا توجد triggers على الجدولين. المحرك inventory_stock_request_engine نفسه service_role-only ويفرض صلاحيات، لكن grants/policies تسمح بتجاوزه عبر REST.
- الأثر: يمكن لمستخدم داخل الشركة إنشاء طلب بحالة Approved أو تعديل تفاصيل/حالة طلب دون المرور بمسار الموافقة. لا يوجد سجل طلبات حاليًا، لذلك لم يُرصد إساءة فعلية.
- الحل المقترح: بعد جرد كل المستهلكين، قصر الكتابة على save-inventory-count/ inventory_control الحاليين، وإزالة direct authenticated writes، مع اختبارات RLS سلبية وإيجابية.

**P2 — غياب واجهة Inventory Control Center في Warehouse Hub**
- لا توجد استدعاءات/واجهات للـsnapshot أو movement report أو replenishment report أو stock-request lifecycle في warehouse.html.
- المحرك الخلفي موجود، لكن المستخدم الميداني لا يملك في التطبيق لوحة موحدة للرصيد والحركة والاحتياج والطلبات.
- الحل: إضافة native module ضمن shell الحالي دون iframe، وربطه بالوظائف الموجودة بدل تكرار منطق الأعمال.

**P2 — عدم تطابق صلاحيات COUNT**
- مستخدم مدير مالي نشط لديه branch-count وvehicle-count دون warehouse.
- inventory_count_engine يقبل هذه الصلاحيات للإنشاء/التهيئة، بينما inventory_control wrapper يرفض قبل الوصول للمحرك لعدم تحقق v_warehouse.
- الحل: توحيد gate في wrapper مع العقد المقصود للمحرك، ثم اختبار role matrix.

**P2 — Idempotency race في stock requests**
- engine يفحص operation_id قبل أخذ advisory lock، ثم يأخذ lock وينشئ الطلب دون إعادة الفحص.
- لا يوجد unique index على (company_id, operation_id) في inventory_stock_requests.
- تزامن طلبين بنفس operation_id قد ينتج سجلين مختلفي request_code. لا توجد سجلات حالية لإثبات وقوع ذلك.
- الحل: قفل ثم إعادة فحص، مع unique constraint جزئي مناسب، وإرجاع نتيجة duplicate بصورة حتمية.

**P2 — اختلاف تاريخ الجرد بين UTC وCairo**
- TimeZone قاعدة البيانات UTC.
- جلسة الجرد الحالية count_date=2026-11-10، بينما reference يعرض 11/11/2026 وcreated_at المحلي Cairo=2026-11-11 00:20:38.
- warehouse counter script يرسل new Date().toISOString().slice(0,10)، وهو تاريخ UTC، بينما نص المرجع يُبنى بالتاريخ المحلي.
- الجلسة InProgress وبها 35 سطرًا غير معدود، ولم ينتج عنها inventory_log أو journal entries.
- الحل: اعتماد business timezone Africa/Cairo بصورة موحدة عند إنشاء count_date في مسار الواجهة/الخدمة، وعدم تغيير timezone العام لقاعدة البيانات.

**P2 — سجل التدقيق في discrepancy غير ذري**
- report-discrepancy Edge Function يسجل audit_log بعد إدخال discrepancy؛ فشل audit insert يُسجل كتحذير ولا يفشل العملية.
- migration 33152 تضيف integrity gate لكنها لا تجعل discrepancy + audit حدثًا ذريًا.
- الحل: مسار كتابة واحد ذري مع audit event داخل المعاملة، بعد اعتماد ChangeSet.

**P2 — مزامنة Counter/Returns غير لحظية**
- warehouse.html يحتوي Realtime subscriptions في Receiver وLoader وVouchers.
- لا توجد subscriptions ظاهرة لـinventory_counts أو inventory_count_details أو stock_discrepancies أو inventory_stock_requests في الوحدات التي فُحصت.
- Counter/Returns يعتمدان على جلب/تحديث يدوي أو عند فتح الإجراء. لا توجد latency أو concurrent-edit measurements.
- الحل: إضافة subscriptions/invalidation حيث يلزم، مع reconnect/reconcile واختبار تعدد الأجهزة؛ لا تُسمَّى لحظية قبل القياس.

**P2 — COUNT LIST contract**
- inventory_control يمرر LIST إلى inventory_count_engine، لكن المحرك لا يحتوي branch LIST ويتطلب count_id لعمليات GET.
- لم يظهر استخدام LIST في Counter الذي فُحص؛ يلزم تدقيق المستهلكين قبل حذف أو تنفيذ العقد.

**P3 — مرجع الجرد يكرر كلمة جرد**
- الواجهة تبني reference بصيغة "جرد " + title، والـtitle نفسه "جرد فرع/مركبة/عام"، فظهر المرجع "جرد جرد فرع".
- إصلاح نصي محدود بعد اعتماد ChangeSet الواجهة.

## 12. الكفاءة التشغيلية والميدانية
- دورة العدّ الحالية: إنشاء جلسة → تحميل الأصناف/الفروع → إدخال الكميات → refresh → finalize → إلغاء. التصميم يستخدم قفل جلسة count ويمرر الفروقات إلى post_inventory_adjustment_atomic.
- finalization يستدعي مسارًا مركزيًا للحركة المخزنية والقيود؛ cost basis المستخدم هو items.cost_price، وليس لدينا دليل على تقييم متوسط/طبقات تكلفة أو lot/bin valuation.
- جلسة الجرد النشطة الحالية لم تُرحّل شيئًا؛ يجب التعامل معها كسجل عمل قائم لا كبيانات QA، وعدم حذفها أو تعديلها.
- دورة طلب تحويل المخزون موجودة في backend، لكن لا واجهة لها في Warehouse Hub ولا سجلات Production لها.
- دورة المرتجع محمية الآن بقاعدة البيانات بنيويًا، لكن لم توجد runsheet بحالة Returning أو discrepancy لاختبارها.
- لم يُثبت اليوم أي سيناريو ميداني كامل من المورد إلى المخزن أو من المخزن إلى الفرع/العميل.

## 13. التخطيط والتنبؤ ومركز القرار الذكي
- inventory_replenishment_report موجود ويستخدم reorder_point/max_qty والرصيد المتاح/المحجوز حسب الكود.
- لا دليل على نموذج طلب تنبؤي أو قياس forecast error أو lead-time model أو موسمية أو supplier score في النطاق الحالي.
- لا يوجد UI لهذا التقرير في Warehouse Hub. يصنف كإعادة طلب rule-based، لا كذكاء تنبؤي مثبت.

## 14. المقارنة التنافسية — نطاق المخزون فقط
- SAP EWM يدعم physical inventory documents، cycle counting/continuous counting، stock types، batch/valuation context، recount/posting. المراجع: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/9905622a5c1f49ba84e9076fc83a9c2c/ee9bc7536e8e2a4be10000000a174cb4.html وhttps://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/2761bd534f22b44ce10000000a174cb4.html
- Dynamics 365 Inventory Visibility يقدم رؤية موحدة للـon-hand/supply/demand عبر المواقع والقنوات ولوحات لتحديد النقص والزيادة. https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-visibility-dashboard
- Odoo يستخدم min/max وforecasted stock وroutes ومواعيد المورد لإنتاج اقتراحات أو أوامر إعادة التوريد. https://www.odoo.com/documentation/master/applications/inventory_and_mrp/inventory/warehouses_storage/replenishment/reordering_rules.html
- ERPNext يربط Material Request بالطلب الداخلي دون أثر مخزني/محاسبي عند الإنشاء، ويستخدم Stock Entry للتحويل، وStock Reconciliation لتسوية الكميات والقيم. https://docs.frappe.io/erpnext/material-request وhttps://docs.frappe.io/erpnext/stock-entry وhttps://docs.frappe.io/erpnext/stock-reconciliation
- Daftra يعلن stocktaking، stock tracking، manual transfer، requisitions، وصلاحيات إصدار/اعتماد الطلبات. https://www.daftara.me/en/stocktaking/ وhttps://www.daftara.me/en/features/sub_feature/3
- Manager.io يربط Inventory Items بالعدّ والرصيد والحركة والربحية. https://www2.manager.io/guides/7551
- ظهر منتج NeXT ERP على nextsoftware.com.br، وهو منتج برازيلي معلن للشركات الصغيرة والمتوسطة مع stock control وfinancial module ورؤية مخزون الفروع. لا أؤكد أنه المقصود باسم Next ERP دون تعريف المالك للمنتج المستهدف. https://nextsoftware.com.br/
- فجوة RAWAEA: توجد بعض APIs للجرد والحركة وإعادة التوريد، لكن واجهة Warehouse Hub لا تجمعها، ولا يوجد دليل على cycle-count scheduling أو forecasted supply/demand أو lot/bin-level counting أو قياس دقة التنبؤ. لا ادعاء بالتكافؤ مع هذه المنتجات.

## 15. مصفوفة نضج RAWAEA
الدرجات التالية تقدير تنفيذ/تصميم من المصدر وCI فقط؛ النضج الميداني UNKNOWN في جميع المجالات.
| المجال | درجة 0–5 | الثقة | السبب |
|---|---:|---|---|
| السلامة التقنية والمعمارية | 2 | متوسطة | Core مشترك ووظائف مركزية، مع نقص Runtime |
| تكامل التطبيقات والبيانات | 2 | متوسطة | مسارات مركزية موجودة، لكن واجهة الجرد والطلبات غير مكتملة |
| العمليات التجارية | 2 | متوسطة | وحدات Warehouse موجودة واختبارات mock ناجحة |
| الرقابة المالية والمحاسبية | 1 | منخفضة | posting function موجودة، دون E2E معزول |
| المخزون وسلاسل الإمداد | 2 | متوسطة | count/report APIs، مع فجوة UI وRLS |
| التوزيع والعمل الميداني | 2 | منخفضة | وحدات تشغيل موجودة، لا إثبات ميداني اليوم |
| التخطيط والتنبؤ | 1 | منخفضة | reorder rules، لا forecast accuracy |
| التقارير وBI | 1 | منخفضة | تقارير أساسية، دون قياس BI |
| الأمان والصلاحيات والتدقيق | 2 | متوسطة | triggers/RLS موجودة مع direct-write bypass |
| الأداء والاستقرار والتوسع | UNKNOWN | غير كافية | لا runtime metrics أو load test |
| تجربة المستخدم والإنتاجية | 2 | منخفضة | native modules، مع نقص مركز المخزون وفحص النشر |
| الجاهزية والتنافسية | UNKNOWN | غير كافية | لا deployment/field evidence ولا benchmark كامل |

## 16. خريطة النظام الأم والقلب المركزي
- Parent: companies/company-1/main.html، blob SHA e43707fa…؛ لم تُقرأ محتوياته مباشرة في هذا التشغيل، ولم يتغير ضمن commits السبعة.
- Core: companies/company-1/core.js، SHA 2d11b852…؛ يحتوي RW_Auth/RW_DB/RW_API/RW_UI/RW_ImageCache/RW_SW/RW_Realtime. لم يتغير في المقارنة الحالية.
- Warehouse Hub: companies/company-1/warehouse/warehouse.html، SHA 9f0b877…؛ shell واحد وسبع native bundles دون iframe.
- Returns standalone: companies/company-1/warehouse/returns.html، SHA 397555…؛ متوافق مع filter pending/investigating.
- Backend: inventory_control wrapper، inventory_count_engine، inventory_stock_request_engine، inventory_stock_snapshot، inventory_movement_report، inventory_replenishment_report، save-inventory-count Edge Function.
- لا يوجد دليل اليوم على أن وظائف snapshot/movement/replenishment/stock requests أصبحت مستهلكة من Warehouse Hub؛ لا تُعد وجودها في DB دليل تكامل واجهة.

## 17. مصفوفة المزامنة
| الوحدة/الكيان | الآلية المرصودة في المصدر | الحكم |
|---|---|---|
| Receiver | RW_Realtime على purchase_orders/purchase_invoices/buyer_goods_custody_events/items، debounce 500ms، reconcile 30s | كود موجود؛ وصول/latency غير مختبر |
| Loader | RW_Realtime على runsheets، debounce 500ms، reconcile 60s | كود موجود؛ وصول/latency غير مختبر |
| Vouchers | subscription على stock_vouchers/stock_voucher_details/stock_branches مع refresh | كود موجود؛ Runtime غير مثبت |
| Counter | لا subscription مرصود لـinventory_counts/details؛ جلب/تحديث يدوي | لا لحظية مثبتة |
| Returns | فحص discrepancy عند الإجراء/إعادة التحميل؛ لا subscription مرصود | server gate يحمي الإغلاق؛ تحديث الشاشة غير لحظي |
| Stock requests | لا UI ولا subscription مرصود في Warehouse Hub | غير متكامل |

## 18. جاهزية استلام شعلة التطوير
**READY WITH LIMITATIONS**
- يمكن استكمال تحليل وتصميم Inventory Control Center وكتابة ChangeSet جراحي.
- لا يمكن إعلان READY للنشر أو Production changes قبل موافقة المالك المحددة، وإتاحة Staging/Browser/Deployment evidence.
- نقطة الاستئناف: LVE-2026-11-11-704؛ لا تعُد إلى 4f018bfe ولا تعتبر Report703 آخر HEAD.
- لا توجد حاجة لإنشاء Edge Function جديدة؛ المسارات الحالية save-inventory-count وinventory_control قابلة لإعادة الاستخدام بعد ضبط العقود.

## 19. الالتزام بالدستور التشغيلي الدائم
- الدستور: doc/Draft/Reprots/الدستور التشغيلي الدائم.md، SHA 3a6b1e…، قُرئ كاملًا.
- تمت مراعاة بوابة الأثر الفعلي: Draft/Count Session لا يغير المخزون أو الحسابات قبل FINALIZE الفعلي.
- تمت مراعاة حماية المسارات المركزية: لم تُكتب أرصدة أو حركات أو قيود مباشرة، ولم تُضعف RLS.
- تمت مراعاة §77.2/§77.3 من MASTER CTO GOVERNANCE: لا تغيير تشغيلي أو Production SQL دون عرض ChangeSet المحدد واعتماده.
- لا يوجد تعارض يبرر تجاوز الحماية. لا تُعد موافقة CS-WH-701-A/B/C/D تفويضًا عامًا للمهاجرات 25700 أو 33152 أو لواجهة جديدة.

## 20. المخاطر والاعتماديات والقرارات التي تحتاج اعتماد المالك
1. اعتماد ChangeSet مستقل لإزالة direct authenticated writes على inventory_stock_requests/details بعد إتمام call-site audit.
2. اعتماد unique idempotency constraint وإصلاح ترتيب lock/recheck في stock request engine.
3. اعتماد توحيد صلاحيات inventory_control wrapper مع المحرك، خصوصًا branch-count/vehicle-count.
4. اعتماد واجهة Inventory Control Center في warehouse.html وربطها بالوظائف الحالية دون تكرار منطق الأعمال.
5. اعتماد إصلاح business date Africa/Cairo ونص مرجع الجرد.
6. اعتماد مسار audit ذري لـstock_discrepancies.
7. يلزم إثبات Cloudflare deployment وBrowser E2E وStaging قبل إعلان الإغلاق.
8. main branch protected=false في بيانات GitHub؛ يلزم مراجعة Rulesets/branch governance، ولا أغيّر إعدادات المستودع دون اعتماد.

## 21. الخطوة التالية ذات الأولوية
**CS-WH-704-A — حزمة Inventory Control Center الآمنة قبل التنفيذ:**
- أولًا: تدقيق كل مستهلكي inventory_stock_requests/details، ثم قفل direct writes غير المصرح بها وإصلاح idempotency والـpermission gate.
- ثانيًا: إضافة native Inventory Control Center داخل warehouse.html لعرض الرصيد، الحركة، إعادة التوريد، طلبات التحويل، وسير الجرد، باستخدام inventory_control/save-inventory-count الحاليين.
- ثالثًا: اختبارات Staging معزولة: قراءة الصلاحيات، create/approve/reject/convert، count no-effect قبل finalize، أثر المخزون والـGL بعد finalize، concurrency/idempotency، إعادة الاتصال، وعدم بقاء QA records.
- الملفات/العقود: warehouse.html، inventory_control(text,jsonb)، inventory_count_engine، inventory_stock_request_engine، save-inventory-count، سياسات inventory_stock_requests/details.
- معيار القبول: لا direct write bypass، لا duplicate operation_id، تطابق صلاحيات Parent/Hub، ظهور الوظائف المطلوبة داخل Warehouse Hub، ونجاح E2E في Staging مع إثبات DB effects.
- **لا يبدأ تعديل Production قبل اعتماد ChangeSet الكامل ونصوصه واختباراته وخطة التراجع.**

### المراجع الأساسية
- Operational HEAD: https://github.com/papamohammed77-glitch/erp-frontend/commit/c03a47ee69f60956dc327953e027c7172fba4c71
- Inventory migration: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/migrations/20261110225700_unified_inventory_control_scope_and_costed_count_finalization.sql
- Returns integrity migration: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/migrations/20261110233152_returns_discrepancy_integrity_gate_20261111.sql
- Warehouse Hub: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/warehouse.html
- Returns app: https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/returns.html
- Report703: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report703_UNIFIED_WAREHOUSE_E2E_PASS_DISCREPANCY_TENANT_SECURITY_AND_SERVER_GATE_20261111.md
- CURRENT_STATE: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
