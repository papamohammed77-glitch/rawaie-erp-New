# Report716 — المراجعة التشغيلية اليومية، جاهزية Staging، وأمن تكامل المخزن الشامل
**التاريخ:** 2026-11-13 (Africa/Cairo)  
**النطاق:** استئناف LVE-715، Warehouse Hub، النظام الأم/Core، عقود المخزون والأذونات، Supabase Production وStaging، CI/Deployment، المزامنة، سلامة بيانات الأعمال.  
**الحكم العام:** READY WITH LIMITATIONS. القراءة والتحليل والتوثيق آمنة ومكتملة في النطاق المحدد؛ اختبار Staging وProduction Runtime غير جاهزين للإغلاق.

---

## 1. نقطة البداية — LAST VERIFIED EVENT / Checkpoint
- نقطة الاستئناف: LVE-2026-11-13-715، وليست بداية جديدة.
- Operational repo: papamohammed77-glitch/erp-frontend، الفرع main، HEAD = 5a0de601099ad2057e1cc8c757ccb2b6cd3a81e7، آخر Commit مسجل 2026-11-13 17:31:31Z.
- Governance repo: papamohammed77-glitch/rawaie-erp-New، الفرع main، آخر Commit قبل هذا التقرير ef209c9dabe169f170d14d6ae09ae4e696d2f00d.
- CURRENT_STATE.md: blob c8a6d15b3fe7722e931bd459f9c69d1861c04eab، 1,954 سطرًا. أحدث حدث مسجل عند بدء المراجعة LVE-715.
- الدستور التشغيلي الدائم: blob 3a6b1e220af8509e314e94df76563bbc6f84910d، 310 أسطر. تمت قراءة الملف كاملًا.
- آخر إغلاق: إصلاحات Warehouse Hub وسبع عمليات أذونات، صلاحية التسوية/الإتلاف للمخزن الشامل ضمن نطاقه، صلاحيات الجرد، تحديث النطاق عند إعادة التحقق، واستعادة مصادر Edge الناقصة. لا يُعاد فتحها دون دليل جديد.
- الهدف المفتوح: إثبات Production Runtime والظهور في تبويبات النظام الأم والصور الحقيقية، وتجهيز Staging صالح وآمن، وإغلاق ثغرات Inventory Control المؤكدة بموافقة ChangeSet محدد.

## 2. CONFIRMED
1. HEAD التشغيلي ما زال 5a0de601099ad2057e1cc8c757ccb2b6cd3a81e7. آخر Commit يخص Workflow اختبار Warehouse؛ لا يوجد Commit تشغيلي أحدث من LVE-715.
2. Warehouse Hub الحالي ملف مستقل، Native Bundles، بلا iframe، ويحمّل ../core.js. تبويباته اليوم/العمليات/الأذونات/حسابي، ويضم Receiver وPicker وLoader وReturns وUnloader وCounter، وسبع عمليات أذونات: Transfer وTransferReceive وDirectSale وDirectReturn وSupplierReturn وScrap وAdjustment.
3. Hub boot يستدعي get_warehouse_hub_snapshot، ويتحقق من تطابق المستخدم والشركة والدور المخزني ونطاق الفروع. إعادة التحقق تفشل مغلقًا وتغلق مساحة التشغيل عند فقد الصلاحية.
4. Production SMART ERP نشط ACTIVE_HEALTHY، PostgreSQL 17.6.1.121، و785 Migration؛ أحدث Migration مطبق 20261110233152.
5. Production يحتوي 100 Edge Function. الوظائف التشغيلية ذات الصلة نشطة وبالإصدارات التالية: bulk-stock-adjustment v9، save-inventory-count v6، start-picking v37، complete-picking v20، cancel-picking v6، reopen-picking v10، start-loading v7، complete-loading v12، cancel-loading v6، reopen-loading v4، start-return v7، complete-return v29، cancel-return v6، reopen-return v2، unload-runsheet v7، reopen-receiving v2، report-discrepancy v4، receive-purchase v18، send-stock-voucher v20، receive-stock-voucher v22، complete-stock-voucher v4، cancel-stock-voucher v4، create-stock-voucher v14، save-purchase-order v41.
6. تمت مطابقة ملفات GitHub الحالية مع مصادر Edge المنشورة للوظائف التي فُحصت؛ تطابق نص entrypoint كاملًا، وتطابق ملف warehouse-adjustment-access.mjs الخاص بـbulk-stock-adjustment. create-stock-voucher هو الاستثناء الوحيد في verify_jwt: false على مستوى Gateway، لكنه يستدعي auth.getUser بالـBearer token ويتحقق من الجلسة قبل RPC؛ لم يثبت تجاوز مصادقة.
7. Workflow Run 43473648768 وJob standalone-warehouse انتهيا SUCCESS. السجل يثبت اختبارات Static/Contract وPlaywright محلية، ومنها سجل العمليات المكتملة واختبارات الصور الاصطناعية وFallback.
8. تقرير715 يثبت Cloudflare Preview لمشروع rawaea-erp على HEAD الحالي: https://968ae7b4.rawaea-erp.pages.dev. هذا دليل Preview سابق على HEAD نفسه، وليس إثبات Production alias.
9. الملف الرئيسي main.html يفتح Warehouse Hub في نافذة مستقلة عبر warehouse/warehouse.html. المصدر الحالي لا يحتوي core.js ولا RW_Auth ولا RW_Realtime؛ بل ينشئ Supabase Client مستقلًا ويملك قنوات Realtime خاصة به.
10. core.js الحالي يحتوي RW_Auth وRW_API وRW_Realtime وRW_ImageCache وRW_SW وRW_EmployeeCustody. Hub يحمل core.js؛ النظام الأم main.html لا يحمله.
11. Production Supabase Realtime publication تشمل purchase_orders وpurchase_invoices وbuyer_goods_custody_events وitems وerp_operation_registry وinventory_counts وinventory_log وinventory_stock_requests وinventory_stock_request_details وrun_sheet_details وrunsheets وstock_branches وstock_voucher_details وstock_vouchers.
12. الحساب التشغيلي النشط الوحيد بدور مخزن شامل لديه صلاحية warehouse مباشرة، ولا يملك stock_adjustment مباشرة؛ نطاقه فرع واحد والوصول إلى الفرع الرئيسي صحيح. لا تغيير في حسابه أو صلاحياته.
13. Production row snapshot الحالي: receiving=4، receiving_details=7، inventory_log=83، stock_branches=60، stock_vouchers=0، stock_voucher_operations=32، inventory_counts=1، inventory_count_details=35، erp_operation_registry=98، stock_discrepancies=0، inventory_stock_requests=0، inventory_stock_request_details=0، runsheets=4، journal_entries=21، supplier_ledger=3، buyer_goods_custody_events=5، purchase_invoices=5، purchase_orders=3.
14. الرانشيتات الحالية: 1 Delivered و2 Open و1 Returned. لا يوجد حدث تفريغ مكتمل حالي في registry؛ لا توجد حالة Returning أو Loaded حاليًا.
15. جلسة الجرد الحالية الوحيدة InProgress من النوع branch، بها 35 سطرًا، جميع counted_qty فارغة، و0 سطر adjusted. هي سجل أعمال قائم، لا بيانات QA.
16. stock_voucher_operations بها 32 صفًا voucher_id فيها NULL، لكن FK الحالي معرف ON DELETE SET NULL؛ لذلك لا يُصنف ذلك وحده تلفًا أو فشلًا، ولا توجد أذونات stock_vouchers حالية.
17. Trigger stock_discrepancies integrity وTrigger منع إغلاق runsheet مع discrepancy بحالة pending/investigating موجودان ومفعّلان في Production. عدد البلاغات الحالي صفر؛ سلوك الحاجز لم يُختبر بمعاملة حية.

## 3. UNKNOWN
- لا يوجد قياس مباشر اليوم لعنوان Production alias أو Artifact bytes أو commit/build lineage المنشور.
- لا يوجد Browser session مصادق عليه متاح، ولا Console/Network/DOM/naturalWidth حقيقي.
- لا توجد نتيجة E2E مصادق عليها على Production أو Staging.
- لا توجد قياسات latency أو reconnect فعلية للمزامنة.
- لا توجد نتائج تشغيل ميداني حديثة تثبت دورة المورد إلى المخزن إلى العميل أو كفاءة المستخدمين.

## 4. CONFLICT / تصحيح تاريخي
- تقارير LVE-710/712 ذكرت عدم وجود Staging منفصل اعتمادًا على Supabase branches، حيث ظهر main فقط. الفحص الحالي لـlist_projects كشف مشروعًا مستقلًا اسمه rawaea-staging. هذا ليس تعارضًا مع الحقيقة الحية؛ بل نقص في نطاق الاستعلام التاريخي. تُصحح الحالة: Staging موجود لكنه غير جاهز للاختبار الآمن.
- يوجد فرق معماري بين الهدف الموثق بأن main/core مركز مشترك وبين المصدر الحي: main.html لا يحمّل core.js، بينما Warehouse Hub والتطبيقات المستقلة تحمّله. هذا CONFLICT بين التصميم المستهدف والتنفيذ الحالي، ولا يجوز إصلاحه دون خريطة اعتماديات وموافقة.
- توجيه المالك الحالي في هذا البروتوكول، القسم 19، يمنع إنشاء بيانات QA أو تنفيذ اختبارات أعمال في Production. اتُّبع التوجيه الأحدث والأكثر حماية؛ لا Production QA writes.

## 5. UNVERIFIED
- ظهور كل مستند/حركة من Hub داخل تبويب النظام الأم لم يُثبت بجلسة مصادق عليها.
- parent main.html لا يقرأ erp_operation_registry مباشرة. مصدره الحالي runsheets وrun_sheet_details وreceiving وstock_vouchers وinventory_log وغيرها. تبويب التفريغ الأمومي يعرض قائمة Loaded الحالية، ولا يستهلك سجل complete_runsheet_unloading المكتمل من registry؛ لذلك عرض تاريخ التفريغ في تبويب الأم غير مثبت.
- الاستلام والأذونات يكتبان إلى جداول مشتركة تقرؤها واجهات الأم من حيث العقد، لكن ذلك لا يثبت ظهورًا بصريًا أو تطابقًا بعد النشر.
- صور Googleusercontent وSupabase Storage الحقيقية لم تُقَس HTTP status أو naturalWidth.

## 6. مصفوفة التحقق
| الطبقة | الحالة | الدليل / الحد |
|---|---|---|
| GitHub / Source | CONFIRMED | main HEAD 5a0de؛ Warehouse Hub blob a8ae5579؛ main.html blob caf3af2c؛ core.js blob 2d11b852 |
| Supabase Production | CONFIRMED read-only | ACTIVE_HEALTHY، 785 migrations، 100 Edge Functions، عقود/RLS/Triggers |
| Deployed Artifact | PARTIAL | Cloudflare Preview مثبت في Report715؛ Production alias/bytes غير متحقق |
| Runtime / E2E | PARTIAL | CI local mocks ناجح؛ لا authenticated Production browser |
| Business-Data Effects | CONFIRMED read-only | Snapshot حي؛ لا أي DML أو posting نفذه هذا الفحص |
| Staging | BLOCKED | مشروع موجود لكن 62 migrations فقط، RLS ناقص، Edge Functions قديمة، ولا ملفات مستخدمين/شركات |

## 7. ما تم فعليًا
- قراءة CURRENT_STATE.md والدستور كاملين، ثم استعادة Report715 و714 و713 و712 ومراجعة محتواها.
- التحقق من HEAD وCommit Diff وCI job logs.
- فحص Warehouse Hub وmain.html وcore.js وملفات العمليات والأذونات.
- مقارنة مصادر Edge المنشورة مع GitHub للوظائف التشغيلية المحددة.
- قراءة مخطط Production ومهاجراته وRLS/Grants/Policies/Triggers/Realtime publication وعقود RPC.
- استعلامات SELECT فقط في Production وStaging.
- اكتشاف مشروع rawaea-staging وتقييم جاهزيته.
- لا تغييرات كود، لا DDL/DML، لا RPC ترحيل، لا نشر Edge جديد، لا بيانات QA.

## 8. ما لم يتم ولماذا
- لم يُنفذ Browser E2E حقيقي بسبب عدم توفر originating browser session.
- لم يُفتح Production alias أو Preview من قناة الويب؛ محاولات الوصول أعادت عدم إتاحة URL في هذه الجلسة.
- لم يُستخدم Staging للاختبار لأن 65 من 70 جدولًا لا تملك RLS، ولا توجد بيانات users/companies، والمخطط والوظائف متأخرة عن Production.
- لم تُنفذ عملية استلام/تحضير/تحميل/تفريغ/مرتجع/جرد/إذن حية؛ هذا يمنع تغيير أرصدة Production.
- لم يُعدل main.html أو core.js أو warehouse.html؛ التغييرات المؤثرة تحتاج ChangeSet وموافقة المالك.

## 9. صحة التطبيقات ونطاق التغطية
| التطبيق/المجال | فُحص اليوم | الحالة |
|---|---|---|
| Warehouse Hub | Source + permissions + Edge + CI | CONFIRMED source; Runtime UNVERIFIED |
| Receiver | embedded bundle + Realtime contract + receiving tables | Source confirmed; parent visual UNVERIFIED |
| Picker | completed history source + RPC/registry | Source confirmed; no Realtime subscription found |
| Loader | completed history + runsheets Realtime | Source confirmed; 60s reconcile; runtime unverified |
| Returns | Edge actor + registry + discrepancy trigger | Source/DB confirmed; no Realtime subscription found |
| Unloader | Edge v7 + registry contract | Source/DB confirmed; no Realtime subscription found |
| Counter | three count modes + inventory_count_engine | Source/DB confirmed; no Realtime subscription found |
| Vouchers | seven actions + voucher RPCs + realtime | Source/DB confirmed; runtime unverified |
| Parent main.html | own Supabase client, legacy RW_Warehouse views, own channels | Source inspected; not using core.js |
| Purchasing/Finance/Sales/Delivery | no full re-audit today | not re-opened absent a new dependency signal |

## 10. تدقيق التعديلات الأخيرة وآثارها
- LVE-715 fixes ما زالت في HEAD الحالي؛ لا Commit أحدث غيّر ملفات التشغيل.
- bulk-stock-adjustment v9 يقرأ get_my_effective_profile، ويقيد المخزن الشامل بالفرع الافتراضي/الفروع المسموحة، ثم يستدعي post_inventory_adjustment_atomic.
- save-inventory-count v6 يفرض effective warehouse على COUNT_* لدور مخزن شامل، ويحتفظ بمسار دور جرد.
- Picker/Returns تستخدم shared warehouse actor؛ بقية بعض RPCs القديمة لا تزال تعتمد users.permissions مباشرة.
- الجرد لا يرحّل عند CREATE/POPULATE/UPSERT_LINE/REFRESH؛ الترحيل يحدث في FINALIZE عبر post_inventory_adjustment_atomic، مع حركة مخزون وقيد يومية. لم يُنفذ FINALIZE في هذا الفحص.
- إنشاء مسودة إذن لا يحرّك المخزون؛ الإرسال/الاستلام/الإكمال هي مراحل الأثر الفعلي بحسب نوع الإذن.
- لا توجد آثار جانبية أحدث ناتجة عن هذا الفحص.

## 11. الأخطاء والفجوات والأولوية
### P1 — ثغرة كتابة مباشرة في طلبات المخزون
- authenticated لديه INSERT/UPDATE/DELETE على inventory_stock_requests وinventory_stock_request_details.
- سياسة ALL على الطلبات تتحقق من company_id فقط؛ وسياسة ALL على التفاصيل تتحقق من أن الطلب يتبع الشركة فقط. لا يوجد شرط صلاحية أو نطاق فرع داخل هاتين السياستين، ولا توجد Triggers على الجدولين.
- inventory_stock_request_engine نفسه service_role-only، لكن صلاحيات الجدول والسياسات تسمح بتجاوز المحرك ومسار الموافقة عبر PostgREST مباشرة.
- عدد الصفوف الحالية صفر؛ لا يوجد ضرر بيانات مثبت، لكن سطح التجاوز CONFIRMED.
- الإجراء: ChangeSet منفصل CS-INVREQ-716-A؛ بعد حصر المستهلكين، سحب DML من authenticated وإزالة ALL write policies، والإبقاء على القراءة المصرح بها، وتوجيه كل الكتابات عبر المحرك المركزي.

### P1/P2 — Idempotency لطلبات المخزون
- inventory_stock_request_engine يفحص operation_id قبل advisory lock.
- لا يوجد Unique index على (company_id, operation_id)، ولا إعادة فحص بعد القفل؛ تكرار متزامن قد ينتج طلبين.
- يلزم unique constraint/index مناسب وإعادة فحص داخل القفل واختبار concurrent retry في Staging.

### P2 — عقد الصلاحيات القديمة
- inventory_stock_request_engine وبعض وظائف إنشاء/إرسال/استلام الأذونات تفحص users.permissions وactive_warehouse_role مباشرة بدل effective role_permissions.
- الحساب النشط الحالي يملك warehouse مباشرة، فلا يظهر أثر على هذا الحساب؛ حساب يعتمد على role_permissions وحدها قد يواجه رفضًا جزئيًا.
- يلزم توحيد العقود بعد مطابقة كل مستهلك، دون توسيع الصلاحيات.

### P2 — Audit atomicy لبلاغ الاختلاف
- report-discrepancy v4 يكتب stock_discrepancies ثم audit_log؛ فشل audit_log يتحول إلى console.warn ولا يلغي البلاغ.
- Trigger integrity يحمي البلاغ وحاجز إغلاق المرتجع، لكن ذرية البلاغ مع سجل التدقيق غير مثبتة.

### P2 — UTC date في الجرد
- Counter bundle يرسل count_date عبر new Date().toISOString().slice(0,10).
- هذا تاريخ UTC لا تاريخ Africa/Cairo، وقد يسجل اليوم السابق خلال الساعات الأولى من يوم القاهرة. المصدر المؤكد في warehouse.html داخل RW_NATIVE_BUNDLES.counter.
- يلزم تغيير جراحي إلى تاريخ محلي مضبوط واختبار حدود منتصف الليل، دون لمس جلسة الجرد القائمة.

### P2 — تكامل Parent History
- parent main.html لا يقرأ erp_operation_registry؛ سجل Unloader المكتمل في Hub يعتمد registry، بينما parent Unloading يعرض Loaded queue فقط.
- لا يجوز تعديل main.html قبل تحديد العقد الأمومي النهائي وموافقة المالك.

### P3 — Tailwind CDN
- warehouse.html يحمل cdn.tailwindcss.com؛ تحذير Console المتوقع بشأن عدم استخدام CDN في Production. ليس دليلًا على فشل وظيفي؛ يعالج في حزمة أصول منفصلة.

## 12. الكفاءة التشغيلية والميدانية
- تصميم/كود: مسارات الاستلام والتحضير والتحميل والتفريغ والمرتجعات والجرد والأذونات موجودة ومتصلة بعقود مركزية.
- منشور: Edge functions التشغيلية نشطة، وCloudflare Preview مثبت سابقًا.
- مختبر: CI Browser E2E ببيانات محلية اصطناعية.
- ميداني/Production: غير مثبت في هذا التشغيل. لا يوجد اختبار حقيقي لزمن الدورة أو التزامن أو جودة الاستخدام أو الأثر بعد واقعة عمل فعلية.

## 13. التخطيط والتنبؤ ومركز القرار
لا يوجد في هذا النطاق دليل جديد يثبت Forecast accuracy أو replenishment recommendation accuracy أو cash-flow forecast. وجود inventory_replenishment_report أو Dashboard لا يثبت دقة التنبؤ. الحالة UNKNOWN.

## 14. Benchmarking تنافسي
لم تُجرَ مقارنة جديدة موثقة مع SAP/Dynamics/Odoo/Daftra/Manager.io/Next ERP في هذا التشغيل. لا أدّعي التكافؤ أو الجاهزية العالمية. يلزم Benchmark وظيفي منفصل بمصادر رسمية ومعايير قبول قابلة للقياس.

## 15. مصفوفة النضج
| المجال | تصميم/Source (0-5) | تنفيذ/Production | ميداني | الثقة |
|---|---:|---|---|---|
| السلامة التقنية والمعمارية | 2 | جزئي | UNKNOWN | متوسطة |
| تكامل التطبيقات والبيانات | 2 | جزئي | UNKNOWN | متوسطة |
| العمليات التجارية | 2 | جزئي | UNKNOWN | متوسطة |
| الرقابة المالية والمحاسبية | 2 | جزئي | UNKNOWN | متوسطة |
| المخزون وسلاسل الإمداد | 2 | جزئي | UNKNOWN | متوسطة |
| التوزيع والعمل الميداني | 1 | غير مثبت | UNKNOWN | منخفضة |
| التخطيط والتنبؤ | UNKNOWN | UNKNOWN | UNKNOWN | غير كافية |
| التقارير وBI | UNKNOWN | UNKNOWN | UNKNOWN | غير كافية |
| الأمان والصلاحيات والتدقيق | 1 | فجوة P1 مفتوحة | UNKNOWN | مرتفعة لوجود الدليل |
| الأداء والاستقرار والتوسع | UNKNOWN | UNKNOWN | UNKNOWN | غير كافية |
| تجربة المستخدم والإنتاجية | 2 | CI فقط | UNKNOWN | متوسطة |
| الجاهزية التشغيلية والتنافسية | 1 | Preview/CI فقط | UNKNOWN | منخفضة |
لا مقارنة رقمية مع التقييم السابق لعدم توافر معيار قياس مطابق.

## 16. خريطة النظام الأم والقلب المركزي
- main.html: تطبيق أم كبير، ينشئ Supabase Client داخليًا، يملك وظائف RW_Warehouse وRealtime channels مستقلة، ويفتح Hub في نافذة جديدة. لا يحمل core.js.
- core.js: قلب مشترك للتطبيقات المستقلة/Hub؛ وحداته تشمل RW_Auth وRW_DB وRW_API وRW_UI وRW_ImageCache وRW_SW وRW_Realtime وRW_EmployeeCustody.
- warehouse.html: يحمل ../core.js ويحتوي Native Bundles للتطبيقات الأصلية؛ ليس iframe ولا ينسخ قاعدة بيانات/أرصدة.
- العقود الأساسية: get_my_effective_profile، get_warehouse_hub_snapshot، inventory_count_engine، post_inventory_adjustment_atomic، complete_runsheet_picking/loading/unloading، complete_return_atomic، receive_purchase_atomic، create/send/receive/complete/cancel manual stock voucher RPCs.
- هذه خريطة جزئية للنطاق المخزني، وليست خريطة كاملة لكل النظام.

## 17. مصفوفة المزامنة
| المستهلك | الآلية المصدرية | النطاق | الحد |
|---|---|---|---|
| Receiver | RW_Realtime: purchase_orders/purchase_invoices/buyer_goods_custody_events/items + reconcile 30s | company_id | لا قياس Runtime |
| Loader | RW_Realtime: runsheets + reconcile 60s | company_id | لا run_sheet_details subscription |
| Vouchers | channel مباشر: stock_vouchers/details/stock_branches | RLS/table policy | لا قياس Runtime |
| Picker | لا subscription ظاهر في Hub bundle | refresh/manual | stale cross-user محتمل |
| Returns | لا subscription ظاهر | refresh/manual | discrepancy changes قد تتأخر |
| Unloader | لا subscription ظاهر | refresh/manual | completed history لا يتزامن تلقائيًا |
| Counter | لا subscription ظاهر | refresh/manual | parent يسمع inventory_counts لا inventory_count_details |
| Parent Inventory Control | channel مستقل: stock_branches/inventory_log/inventory_counts/inventory_stock_requests | داخل main | منفصل عن RW_Realtime |
- RW_Realtime يقبل INSERT/UPDATE فقط؛ لا يشترك في DELETE، ويعتمد periodic/visibility reconciliation. لا يوجد قياس latency فعلي.
- Production publication لا تضم receiving وreceiving_details وstock_voucher_operations؛ Receiver يعتمد أيضًا أحداث PO/Invoice/Buyer custody وreconcile.
- وجود publication/listener لا يثبت وصول الحدث في Runtime.

## 18. جاهزية استلام شعلة التطوير
- نقطة الاستئناف: LVE-715، مع تحديث LVE-716 بعد حفظ هذا التقرير.
- الأدوات: GitHub read/write للتوثيق، Supabase read-only متاح، Browser session غير متاحة، Web لا يفتح Cloudflare Pages في هذه الجلسة.
- الصلاحيات: لا DDL/DML/Edge deploy أو تعديل ملفات تشغيلية دون ChangeSet محدد وموافقة المالك.
- الحكم: READY WITH LIMITATIONS للتحليل والتوثيق؛ BLOCKED لاختبارات Staging/Production E2E إلى حين تجهيز Staging وإتاحة Browser مصادق عليه.

## 19. الالتزام بالدستور
- الدستور المقروء كاملًا: blob 3a6b1e220af8509e314e94df76563bbc6f84910d.
- تم تطبيق قواعد الأثر بعد الواقعة الفعلية، وعدم تعديل الأرصدة مباشرة، وعدم إنشاء QA على Production، وحماية RLS والعقود المركزية.
- لا تعارض غير محسوم يمنع القراءة الآمنة. توجيه المالك الحالي §19 يمنع Production QA writes؛ لم يتم إنشاء أي بيانات اختبار.
- لا تغيير على main.html أو core.js أو warehouse.html أو Supabase schema/Edge خلال هذا التشغيل.

## 20. المخاطر والاعتماديات وموافقات المالك
- P1: direct DML bypass في inventory_stock_requests/details؛ يتطلب ChangeSet CS-INVREQ-716-A وموافقة قبل Migration.
- P2: idempotency/role_permissions/UTC date/audit_log atomicity/parent registry integration؛ كل منها ChangeSet محدد بعد تتبع المستهلكين.
- Staging rawaea-staging ليس بيئة اختبار صالحة حاليًا: 62 Migration فقط، 70 public tables منها 5 RLS enabled و0 forced، 22 Edge Function قديمة، لا users/companies/requests tables، وتوجد harness functions قديمة verify_jwt=false.
- لا بيانات Production تغيرت. لا بيانات Staging تغيرت. لا توجد موافقة على أي تغيير تشغيلي جديد.

## 21. الخطوة التالية ذات الأولوية
إعداد واعتماد ChangeSet واحد أمني CS-INVREQ-716-A: حصر مستهلكي طلبات المخزون، إلغاء DML المباشر وسياسات ALL، توحيد effective permission/branch scope، إضافة idempotency unique + recheck داخل lock، ثم إعادة بناء Staging من العقود الحالية وتفعيل RLS/Edge parity قبل أي E2E. معيار القبول: رفض DML المباشر للمستخدم authenticated، نجاح العمليات المصرح بها عبر المحرك فقط، رفض الفرع غير المسموح، عدم تكرار الطلب تحت التزامن، وعدم أي حركة مخزون قبل الإرسال/الاستلام الفعلي. لا Production تنفيذ قبل موافقة المالك الصريحة على النص الكامل وخطة التراجع.

---

**سلامة البيانات:** هذا التقرير قائم على القراءة فقط. لم ينفذ DML/DDL أو RPC/Edge posting أو QA rows أو تعديل صلاحيات أو نشر.