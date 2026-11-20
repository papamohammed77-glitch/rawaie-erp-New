# Report747 — المراجعة التشغيلية اليومية، تدقيق أمان الصلاحيات، واستمرارية CountFlow
**LVE:** LVE-2026-11-20-747
**التاريخ:** 2026-11-20  
**وقت الفحص:** 21:47–21:52 Africa/Cairo  
**الدور:** CTO / Lead Engineer / Enterprise Architecture / Operational Excellence  
**الحكم التنفيذي:** **BLOCKED** لأي كتابة أو نشر تشغيلي في نطاق SMART ERP وCountFlow إلى حين احتواء P0 واعتماد Change Set محدد. **READY WITH LIMITATIONS** للفحص القرائي والتوثيق فقط.

---

## 1. نقطة البداية وآخر نقطة مثبتة

| المرجع | الحالة عند بدء هذه المراجعة |
|---|---|
| Governance repository | papamohammed77-glitch/rawaie-erp-New، الفرع main، HEAD السابق 7a77268 |
| Governance CURRENT_STATE | SHA 3a1ad694fde03f55bed04828fb2a4220f95b9e76، 2,570 سطرًا، آخر حدث مسجل LVE-2026-11-19-735 |
| الدستور الدائم | SHA 3a6b1e220af8509e314e94df76563bbc6f84910d، 310 أسطر، قُرئ كاملًا |
| Operational repository | papamohammed77-glitch/erp-frontend، الفرع main |
| Operational code checkpoint | 4f7fba271d35d463364a5659f8e181dabad41215، وهو HEAD المسجل في LVE735 |
| CountFlow checkpoint | LVE-2026-11-20-746، CURRENT_STATE blob 8d8c83968a3dfa886857d4e853dcfeeae1fa5842، Report blob da3083d6a0847b7da9d4b78da50d1f65e14b295d |
| آخر إغلاق تشغيلي | لا يوجد إغلاق إنتاجي جديد في هذه الدورة. CountFlow ما زال قبل الإطلاق؛ لا حسابات أو جلسات أو بيانات أعمال. |
| الهدف الحالي | احتواء مخاطر الصلاحيات P0 في SMART ERP، ثم فصل مخاطر المشروع القديم الموجودة داخل rawaea-staging عن نطاق CountFlow، قبل أي حسابات أو نشر أو اختبار كتابي جديد. |

لم أبدأ من تقرير حديث أو ذاكرة. تمت قراءة CURRENT_STATE أولًا، ثم الدستور، ثم سلسلة Report735 وReport734 وCountFlow CURRENT_STATE وReport746، وبعدها جرى التحقق من GitHub وSupabase الحيين.

## 2. CONFIRMED — حقائق مثبتة اليوم

### 2.1 GitHub والاستمرارية
- Operational branch = main.
- أحدث HEAD قبل تحديث التوثيق المحلي كان b48e384319436e22a2464b6d3749c3e0069f7b14، ورسالة commit: CountFlow: pin LVE-746 state and successor handoff.
- مقارنة 4f7fba2 إلى b48e384: 159 commit إلى الأمام، صفر إلى الخلف، و49 مسارًا متغيرًا.
- 48 مسارًا من التغييرات داخل companies/company-2/Counting؛ المسار الوحيد خارج Counting هو حذف companies/company-2/test.
- الحذف تم في commit c56748b69aae2fdeffa515a98802da33e9c78f9f، والملف عند checkpoint السابق كان محتواه النصي الوحيد "test". لا يوجد دليل على حذف ملف تشغيلي.
- لا توجد GitHub commit statuses على b48e384 أو 4f0d2530؛ لذلك لا توجد نتيجة CI منشورة يمكن نسبها إلى HEAD الحالي.

### 2.2 CountFlow source snapshots
| الملف | SHA الحالي |
|---|---|
| countflow-admin.html | 57127597826ff479b52ce392c4c560afaf3c9994 |
| countflow.html | 6bbd9db32682e6e48429d85ebaf061d3ff965e25 |
| Countflow-supervisor.html | e30452120e2307472bcccfb8e3e06261d51b2734 |
| countflow-core.js | 43395393093ba9bba94959dc1cc71457327a4e5e |
| countflow-sw.js | 408fe0047d230535ae482230ea892e2edbb663f2 |
| scripts/build-pages.sh | 865629e8f1061f403f426f9c712d0ec00fdd9793 |
| 20261120230000_countflow_server_session_lifecycle.sql | f2a8d067fa6bf3a64d77e3f7a39ded18470d8113 |
| tests/import_90k_rollback.sql | d72d9ee724071446aa96888fc124a056e3470760 |

تطابقت هذه البصمات مع الملفات الحية. لا يوجد تعديل مصدر تشغيلي جديد في هذه المراجعة.

### 2.3 CountFlow Production-like database contract في rawaea-staging
المشروع hfzznsiprnwkpayskzhu:
- 23 جدول CountFlow، وجميعها RLS-enabled.
- 76 سياسة RLS تخص CountFlow.
- 78 Foreign Keys تخص CountFlow، وجميعها validated.
- لا توجد صلاحيات anon SELECT/INSERT/UPDATE/DELETE على جداول CountFlow.
- سجل المشروع يحتوي 148 migration؛ آخر إصدار حي 20261120170645 باسم countflow_platform_settings_fk_index.
- جميع جداول CountFlow فارغة: projects, members, sessions, assignments, products, entries, expected_balances, reconciliation_runs, import_batches, import_rows, session_product_costs, exports = 0.
- Auth users = 1,868؛ لا يوجد حساب owner@rawaea.com في Auth؛ ولا يوجد QA user بعنوان qa-90k.
- counting-provision-member v6 وcounting-export-session v12 حالتهما ACTIVE وverify_jwt=true. محتوى index.ts الحي مطابق تمامًا لمصدر GitHub، بطولي 8,567 و57,295 حرفًا على الترتيب.
- يوجد 24 Edge Functions في المشروع؛ ستة Legacy harness/canary لها verify_jwt=false. لم يتم استدعاء أي منها أو تعديلها، وليست أي من دالتي CountFlow أعلاه.

### 2.4 SMART ERP — صلاحيات role_permissions
المشروع fiilmooggumokxanwiyx:
- public.role_permissions عليه RLS=true وFORCE RLS=false.
- توجد سياسة Allow all for all من نوع ALL على PUBLIC مع USING=true وWITH CHECK=true.
- عدد الصفوف 21.
- الجدول مملوك postgres، ولا يوجد Trigger تدقيق على الجدول.
- ACL الحالي:
  {postgres=arwdDxtm/postgres,anon=arwdxtm/postgres,authenticated=arwdxtm/postgres,service_role=arwdxtm/postgres}
- anon وauthenticated لديهما SELECT/INSERT/UPDATE/DELETE، ولديهما أيضًا TRIGGER وREFERENCES وMAINTAIN. لا يملكان TRUNCATE؛ الحرف D موجود في ACL المالك postgres فقط، وليس في ACL anon/authenticated.
- ثماني دوال SECURITY DEFINER تقرأ role_permissions، وكلها مملوكة postgres. get_my_effective_profile() وget_warehouse_hub_snapshot() متاحتان لـauthenticated؛ ولا توجد صلاحية EXECUTE لـanon على هاتين الدالتين.
- get_my_effective_profile() تستخدم auth.uid() وتربط u.auth_id = auth.uid()، وتقرأ role_permissions بواسطة role_id. مالك الدالة postgres يستطيع قراءة الجدول بعد حجب الوصول المباشر عن anon/authenticated، ما دام مسار الدالة نفسه لم يتغير.
- main.html blob الحالي 00456494de918b36fc6792bef302319a9f65605d، وهو نفس blob الذي فحصه Report735. تعذر على أداة fetch_file إعادة محتوى الملف الضخم اليوم، لذلك لم أزعم إعادة قراءة كامل 2MB. لا توجد تغييرات على main.html منذ checkpoint 4f7fba.
- core.js الحالي 2b2211a3f95049042e27a7b2ecbab3640a584942؛ لا توجد إشارة مباشرة إلى role_permissions في المصدر الذي تم جلبه، ويستخدم مسار get_my_effective_profile.
- save-role Edge v9 ACTIVE وverify_jwt=true. مصدره الحي لا يكتب role_permissions مباشرة؛ ظهوره الوحيد هو اسم audit action: role_permissions_sync.
- save-category Edge v6 ACTIVE وverify_jwt=true، ويستخدم جدول categories مباشرة وفق مسار الصلاحيات الحالي.

### 2.5 SMART ERP — categories
- public.categories RLS=true، لكن سياسة Allow all for all تسمح بالوصول العام.
- anon وauthenticated لديهما CRUD، وكذلك TRIGGER وREFERENCES وMAINTAIN، ولا يملكان TRUNCATE.
- هذا يثبت كتابة عامة على بيانات التصنيف، لكنه لا يثبت أن جميع التطبيقات تستخدم الكتابة المباشرة.

### 2.6 rawaea-staging — Legacy exposure داخل المشروع نفسه
- 93 public base tables: 23 CountFlow + 70 Legacy.
- 65 جدول Legacy لديه RLS=false.
- 56 جدولًا لديه صلاحيات DML فعالة لـanon.
- public.users: RLS=false، وعدد الصفوف 1,871، ويحتوي أعمدة password_hash وpermissions وrole وauth_id. anon لديه SELECT/INSERT/UPDATE/DELETE/TRUNCATE. لم تُقرأ أي قيمة password_hash أو أي بيانات شخصية.
- عدد auth.users = 1,868 مقابل 1,871 صفًا في public.users؛ الفرق العددي +3 فقط، أما وجود صفوف يتيمة أو سبب الفرق فـUNKNOWN ولم يتم فحص أي قيم.
- public.role_permissions وpublic.categories داخل المشروع نفسه RLS=false وanon لديه CRUD.
- لا يجوز اعتبار المشروع معزولًا لمجرد أن جداول CountFlow نفسها محمية؛ المشروع يحتوي 70 جدول Legacy مكشوفًا جزئيًا.

### 2.7 RPCs خطرة في rawaea-staging
ثلاث دوال SECURITY DEFINER مملوكة postgres، وACL كل منها يتضمن EXECUTE لـPUBLIC وanon وauthenticated وservice_role، ولا تحتوي على auth.uid():

1. post_inventory_adjustment_atomic(uuid,uuid,text,text,text,text,jsonb)
   - تقبل p_user_email من المستدعي.
   - تنفذ post_stock_movement وتغير أثر المخزون.
   - لا تربط p_user_email بهوية auth.uid() ولا تتحقق من صلاحية المستخدم الوظيفية.

2. receive_purchase_atomic(uuid,text,text,jsonb)
   - تقبل p_user_email من المستدعي.
   - تنشئ الاستلام وتحدث PO وتنفذ حركات المخزون.
   - تنشئ journal_entries/journal_lines وتكتب supplier_ledger.
   - لا تتحقق من auth.uid() أو دور المستدعي.

3. save_sales_invoice_atomic(jsonb,jsonb,text,text)
   - تقبل p_user_email من المستدعي.
   - تنشئ مستند البيع وتفاصيله.
   - عند status=Invoiced تنفذ حركة مخزون وقيودًا/دفتر عميل وفق جسم الدالة.
   - لا تتحقق من auth.uid() أو دور المستدعي.

كما تم فحص Edge wrappers:
- bulk-stock-adjustment v2 ACTIVE وverify_jwt=true: يستدعي auth.getUser ثم يستخدم service_role لاستدعاء post_inventory_adjustment_atomic، لكنه لا ينفذ فحص role/permission أو نطاق فرع المستخدم قبل الاستدعاء.
- save-sales-invoice v2 ACTIVE وverify_jwt=true: يتحقق من وجود مستخدم Auth ثم يستدعي save_sales_invoice_atomic باستخدام service_role، دون فحص role/permission أو نطاق الفرع.
- لم يظهر Edge Function باسم receive-purchase ضمن قائمة الـ24؛ الدالة receive_purchase_atomic تبقى قابلة للاستدعاء مباشرة عبر PostgREST وفق ACL الحالي.
- verify_jwt=true يثبت وجود JWT فقط؛ لا يثبت التفويض الوظيفي ولا صلاحية الفرع.

لم يتم استدعاء أي RPC من هذه الدوال، ولم يُنشأ أي مستند أو حركة.

## 3. UNKNOWN

- لا يوجد دليل على نشر CountFlow في Cloudflare Pages أو تطابق artifact مع HEAD.
- لا توجد جلسة Browser مصادق عليها أو حساب Owner/ Supervisor/ Counter يمكن استخدامه في E2E.
- لا يوجد ملف XLSX حقيقي تم تنزيله وفتحه والتحقق من سلامة الصور/الصيغ.
- لا يوجد اختبار فعلي لـBroadcast delivery أو reconnect أو duplicate/out-of-order أو latency.
- لا يوجد اختبار على هاتف/لوحي/سطح مكتب فعلي.
- لا يوجد Benchmark رسمي حديث في هذه الدورة مع SAP أو Dynamics أو Odoo أو ERPNext أو Daftra أو Manager.io.
- لم تتم مراجعة جميع تطبيقات companies/company-1 أو جميع المستهلكين للـLegacy schema في rawaea-staging.
- لا يمكن استنتاج أن الفارق بين public.users وauth.users يعني 3 صفوف يتيمة دون ربط IDs؛ لم يتم هذا الربط.
- لا يوجد دليل على أثر أعمال حقيقي في دورة CountFlow؛ جميع جداول CountFlow فارغة.

## 4. CONFLICT

1. **تعارض بيئة CountFlow:** الدستور §6.4 (SHA 3a6b1e...) يحدد SMART ERP Production مرجع التنفيذ الوحيد ويرفض مشروع Staging بديلًا. البروتوكول اليومي الأحدث §19 يطلب Staging/بيئة معزولة لبيانات QA. CountFlow يستخدم المشروع الموجود rawaea-staging. لم يُنشأ مشروع جديد. لا أحسم التعارض بالتخمين؛ لا مزيد من write tests على rawaea-staging حتى اعتماد المالك للتفسير المقصود.
2. **تعارض تقريري داخل Report735:** القسم 9.2 يصنف categories كـP1، بينما الملخص §21 يصنفها P2. الأدلة الحالية تؤيد P1 بسبب anon CRUD على master data.
3. **مبالغة TRUNCATE في Report735:** التقرير ذكر TRUNCATE على SMART role_permissions/categories للـanon/authenticated. ACL الحي وhas_table_privilege يثبتان عدم وجود TRUNCATE لهذين الدورين. TRIGGER وREFERENCES وMAINTAIN ما زالت ممنوحة.
4. **تقادم عدادات CountFlow القديمة:** Report735 ذكر 21 جدولًا و70 سياسة؛ LVE746 والحالة الحية الحالية يثبتان 23 جدولًا و76 سياسة و78 FK. لا يُنسب هذا إلى خطأ في LVE735؛ إنه تغير لاحق موثق في LVE746.
5. **تزامن CURRENT_STATE:** ملف الحالة المرجعي في governance كان ينتهي عند LVE735، بينما CountFlow CURRENT_STATE كان قد وصل LVE746. تمت معالجة فجوة الربط في تحديث LVE747، دون حذف التاريخ السابق.

## 5. UNVERIFIED

- اختبار 90,000 صف: تمت مراجعة الملف d72d9ee؛ يبدأ BEGIN وينتهي ROLLBACK ولا يحتوي COMMIT مستقلًا، ومراجع الكتابة محصورة في auth.users وجداول CountFlow. محاولة التنفيذ أعادت خطأ داخليًا من الأداة ولم تُرجع نتيجة SQL؛ لذلك لا يوجد PASS ولا يجوز وصف الاختبار بأنه منفذ. فحص residue لاحق أثبت صفر صفوف في كل جداول CountFlow وصفر qa-90k Auth users.
- اختبارات LVE746 التاريخية مسجلة في Report746، لكنها لم تُعد في هذا التشغيل. لم أرفعها إلى نتائج اختبار جديدة.
- لا يوجد authenticated Browser E2E أو Cloudflare artifact parity.
- لا يوجد قياس latency للمزامنة.

## 6. مصفوفة التحقق

| الطبقة | SMART ERP | rawaea-staging / CountFlow |
|---|---|---|
| GitHub Source | main/core الحاليان مثبتا SHA؛ main blob لم يُعد جلب محتواه اليوم | ملفات CountFlow الحالية مثبتة SHA |
| Supabase schema | role_permissions/categories ACL وRLS مثبتة | 23 CountFlow tables/76 policies/78 FKs؛ 70 Legacy tables |
| RPC/Edge | save-role v9 وsave-category v6؛ role_permissions P0 | CountFlow v6/v12 مطابقان للمصدر؛ 3 Legacy SECURITY DEFINER RPCs مكشوفة |
| Deployed Artifact | UNKNOWN | UNKNOWN |
| Runtime / Browser E2E | UNVERIFIED | UNVERIFIED |
| Business-data effects | لا تغييرات اليوم | كل CountFlow tables صفر؛ لا حركة أعمال |
| Staging QA | لا يوجد اختبار كتابة | محاولة 90k لم ترجع نتيجة؛ residue صفر |

## 7. ما تم فعليًا في هذه الدورة

1. جلب CURRENT_STATE وقراءة 2,570 سطرًا، ثم قراءة الدستور كاملًا (310 أسطر) وتسجيل SHA.
2. مراجعة Report735 وReport734 ومحتوى CountFlow CURRENT_STATE وReport746.
3. مقارنة 159 commit منذ checkpoint 4f7fba؛ 48 ملفًا داخل CountFlow، وحذف ملف test منفرد موثق.
4. فحص SMART role_permissions/categories ACL وRLS والسياسات والمالكين والدوال المستهلكة.
5. فحص 93 جدولًا في rawaea-staging، و65 RLS-disabled، و56 anon-DML، وpublic.users دون قراءة قيم حساسة.
6. فحص تعريفات الدوال الثلاث وACL الفعلي، ومصدري Edge wrappers الخطيرين.
7. فحص CountFlow RLS/policies/FKs/migrations/Edge functions/row counts.
8. فحص سياسات وTriggers الجداول ذات مسارات الاعتماد والتسوية وإعادة العد والتنبيهات.
9. فحص static UX للصفحات الثلاث.
10. فحص residue بعد فشل محاولة 90k.
11. تحديث CountFlow CURRENT_STATE بتوثيق LVE747 فقط؛ لم يتغير أي ملف تشغيل أو قاعدة بيانات.

## 8. ما لم يتم ولماذا

- لم يتم تنفيذ REVOKE/DDL/RLS/ACL أو Edge deploy لأن الموافقة المحددة مطلوبة.
- لم يتم إنشاء حسابات لأن owner Auth غير موجود، ولا يوجد roster معتمد، ولا توجد أداة Auth Admin متاحة في هذه الجلسة.
- لم يتم تنفيذ Browser E2E لعدم وجود حساب مصادق عليه وأداة تحكم Browser تفاعلية.
- لم يتم نشر Pages لأن deployment project/artifact غير مثبت، وإنشاء مشروع جديد غير مصرح.
- لم يُنفذ اختبار 90k بعد خطأ الأداة؛ لا تكرر المحاولة دون إعادة تقييم بوابة التنفيذ.
- لم تُفحص كل تطبيقات ERP؛ التغييرات منذ LVE735 محصورة عمليًا في CountFlow ومسار test المحذوف، ولا يوجد سبب لإعادة فحص التطبيقات غير المتأثرة.

## 9. صحة التطبيقات والتغطية

| النطاق | فُحص اليوم | الحالة |
|---|---|---|
| SMART role_permissions/categories | نعم، catalog + ACL + policies + consumers الرئيسية | P0/P1 مفتوحة |
| SMART main.html/core.js | SHA فقط؛ core جُلب، main blob ضخم تعذر جلب محتواه | لا تعديل، المراجعة التفصيلية التاريخية ما زالت مرتبطة بنفس blob |
| Buyer/Receiver/Warehouse/Parent باقي التطبيقات | لم تُفتح من جديد؛ لا تغييرات عليها في المقارنة الحالية | غير متأثرة بحسب Git diff، لكن لا إعلان سلامة شاملة |
| CountFlow Admin/Counter/Supervisor | نعم، source + static UX + DB contracts | قبل الإطلاق |
| CountFlow Edge v6/v12 | نعم، exact source match | source/deployed function match فقط، لا runtime |
| Legacy schema داخل rawaea-staging | نعم، catalog + function definitions + Edge wrappers | P0 مفتوحة |
| Cloudflare/Browser | لا وصول إلى artifact أو جلسة مصادق عليها | UNKNOWN |

## 10. تدقيق التعديلات الأخيرة وآثارها

- CountFlow تغيّر بصورة كبيرة منذ 4f7fba: 159 commits و48 ملفًا في نطاق Counting. أحدث code checkpoint هو 4f0d2530، ثم تم تثبيت LVE746، ثم تحديث الحالة فقط في b48e384 وLVE747 documentation commit.
- CountFlow source blobs الحالية تطابق snapshot في CURRENT_STATE.
- CountFlow migration ledger وصل إلى 148 migration، وآخر إصدار 20261120170645.
- Edge v6/v12 مطابقان للمصدر الحالي.
- لا دليل على Cloudflare نشر.
- حذف companies/company-2/test كان حذف ملف نصي محتواه "test" فقط.
- لا تغيير على main.html أو core.js أو Buyer أو Warehouse ضمن diff بعد 4f7fba.

## 11. الأخطاء والفجوات والحلول والأولويات

### P0 — SMART ERP role_permissions
**السبب المثبت:** سياسة PUBLIC ALL غير مقيدة + anon/authenticated direct ACL + جدول يغذي effective permissions.  
**الخطر:** تغيير صلاحيات الأدوار من دون هوية موثوقة أو سجل تدقيق على الجدول.  
**الحل الأدنى المقترح:** حجب الوصول المباشر عن anon/authenticated وإزالة سياسة PUBLIC ALL، مع إبقاء مسار SECURITY DEFINER الموثوق.  
**الحالة:** Change Set جاهز للمراجعة، لم يُطبق.

### P0 — rawaea-staging public.users وLegacy RPCs
**السبب المثبت:** RLS معطل على 65 جدولًا، anon DML على 56، public.users مكشوف بما في ذلك password_hash، وثلاث RPCs SECURITY DEFINER تقبل actor email غير مربوط بـauth.uid. اثنان من Edge wrappers يكتفيان بإثبات وجود JWT ولا يفحصان role/permission/branch.
**الحل:** احتواء ACL/RLS لكل كيان بعد census كامل للمستهلكين، وإضافة authorization checks مركزية إلى wrappers أو استبدال المسار، وعدم السماح بالاستدعاء المباشر للدوال. لا يجوز تطبيق REVOKE شامل على 65 جدولًا دون تحليل الاعتماديات.
**الحالة:** P0 مفتوحة، Change Set غير جاهز للتطبيق الشامل.

### P1 — CountFlow direct workflow DML
- count_reconciliation_runs: supervisor INSERT/UPDATE مباشر؛ لا lifecycle/audit trigger؛ تحديث الحالة يمكنه تجاوز count_approve_reconciliation.
- count_recount_tasks: supervisor INSERT/UPDATE/DELETE مباشر؛ audit موجود لكن لا state guard.
- count_alerts: supervisor INSERT/UPDATE مباشر؛ Broadcast trigger فقط؛ لا row-audit أو resolution guard.
- count_sessions: supervisor DELETE مباشر؛ lifecycle guard لا يعمل على DELETE، وبعض علاقات الأبناء CASCADE.
**الحل:** نقل transitions إلى RPCs مركزية أو إضافة triggers state guards وappend-only/audit contracts، ثم تقليل direct DML إلى أقل صلاحية لازمة.
**الحالة:** P1 مفتوحة؛ لا تغيير دون موافقة.

### P1 — SMART categories
**السبب:** anon/authenticated CRUD + PUBLIC ALL policy.  
**الحل:** سياسة قراءة محددة حسب الشركة/حالة النشر، والكتابة عبر save-category Edge v6 فقط بعد حصر جميع مستهلكي القراءة العامة.  
**الحالة:** P1 مفتوحة.

### P2 — UX/accessibility CountFlow
- لا توجد aria-* attributes في صفحات Admin/Counter/Supervisor بحسب static scan.
- صور Admin لا تحمل alt؛ صفحات Counter/Supervisor بها alt واحد لكل منهما.
- لا توجد نتائج Browser/keyboard/screen-reader/device.
**الحل:** مراجعة WCAG فعلية على DOM/runtime، ثم إضافة labels/focus/error announcements حيث يثبت الاحتياج.
**الحالة:** UNVERIFIED/P2.

## 12. الكفاءة التشغيلية وسيناريوهات الأعمال

### ERP procure-to-pay / inventory
- مسار استلام المورد في rawaea-staging يستطيع إنشاء receiving وstock movement وjournal/supplier ledger عبر receive_purchase_atomic، لكنه لا يثبت هوية المنفذ. هذا مسار خطر وليس نجاحًا تشغيليًا.
- تعديل المخزون عبر bulk-stock-adjustment يمر عبر JWT ثم service_role، دون role/permission gate في Edge wrapper.
- إنشاء فاتورة بيع عبر save-sales-invoice يمر عبر JWT فقط، ثم قد يرحل المخزون والحسابات إذا status=Invoiced.
- لم يتم تشغيل أي مسار؛ الأثر التجاري الفعلي = لا شيء في هذا الفحص.

### CountFlow
التدفق التصميمي: Project → Member → Session → Import batch/rows → Count entries → Reconciliation → Recount tasks/alerts → Export.
- العقود والجداول وRPCs موجودة.
- كل جداول CountFlow فارغة.
- لا مستخدمين ولا جلسات ولا مهام ميدانية.
- لذلك لا توجد نتيجة ميدانية أو معدل إكمال أو زمن مهمة أو دقة تسوية مثبتة.

## 13. التخطيط والتنبؤ ومركز القرار

لا يوجد في هذه الدورة دليل على demand forecasting أو reorder recommendations أو safety stock أو expiry prediction أو measured forecast accuracy. لا تمنح Dashboard أو schema درجة ذكاء تشغيلي. الحالة UNKNOWN.

## 14. المقارنة التنافسية

لم يُنفذ Benchmark web رسمي في هذه الدورة لأن أولوية الأمان P0. لا توجد مقارنة حديثة متكافئة بين RAWAEA وSAP S/4HANA / Business One / Dynamics 365 / Odoo / ERPNext / Daftra / Manager.io. يجب تحديد منتج Next المقصود قبل إدخاله في المقارنة. لا ادعاء بالتفوق أو التكافؤ.

## 15. مصفوفة النضج الاثني عشر

لا أضع درجات رقمية غير قابلة للمقارنة. المصفوفة التالية UNKNOWN ما عدا وجود مانع أمني حاسم:

| المجال | التقييم الحالي | سبب عدم منح درجة |
|---|---|---|
| السلامة التقنية والمعمارية | UNKNOWN | نطاق النظام كله لم يُفحص؛ P0 في الصلاحيات يمنع READY |
| تكامل التطبيقات والبيانات | UNKNOWN | لا اختبار شامل لمنتجي/مستهلكي Parent |
| العمليات التجارية | UNKNOWN | لا E2E ميداني في هذه الدورة |
| الرقابة المالية والمحاسبية | UNKNOWN | لا اختبارات posting آمنة ولا مصالحة جديدة |
| المخزون وسلاسل الإمداد | UNKNOWN | لا اختبار حركة فعلية؛ توجد RPCs خطرة غير مصادق عليها |
| التوزيع والعمل الميداني | UNKNOWN | لا Browser/device sessions |
| التخطيط والتنبؤ | UNKNOWN | لا قياس forecast accuracy |
| التقارير وBI | UNKNOWN | مصدر export موجود لكن لا ملف فعلي تم فتحه |
| الأمان والصلاحيات والتدقيق | 1/5 في النطاق الأمني المفحوص | توجد RLS/ACL وآليات هوية، لكنها لا تمنع P0 المباشر في SMART ERP وLegacy staging |
| الأداء والاستقرار والتوسع | UNKNOWN | لا load/latency measurements |
| تجربة المستخدم والإنتاجية | UNKNOWN | static source فقط، لا user task timing |
| الجاهزية التشغيلية والتنافسية | 0/5 في نطاق الإطلاق | لا deployment/E2E، وP0 مفتوحة |

هذه ليست مقارنة مع درجات Report735؛ المقام والنطاق مختلفان.

## 16. خريطة النظام الأم والقلب المركزي

- Parent: companies/company-1/main.html، blob 00456494de918b36fc6792bef302319a9f65605d.
- Core: companies/company-1/core.js، blob 2b2211a3f95049042e27a7b2ecbab3640a584942.
- لم يتغير أي منهما ضمن 159 commit بعد checkpoint LVE735.
- Core الحالي يوفّر get_my_effective_profile RPC path؛ لم يُثبت اليوم أن جميع التطبيقات تستخدم Core واحدًا أو جلسة واحدة.
- CountFlow لديه countflow-core.js وService Worker خاصان به، ويستخدم مشروع Supabase مختلفًا. لا يستهلك RAWAEA core.js.
- لا توجد مراجعة شاملة جديدة للـRouter/Boot/Auth لكل التطبيقات في هذه الدورة.

## 17. مصفوفة المزامنة

| المسار | ما ثبت من المصدر/DB | ما لم يثبت |
|---|---|---|
| CountFlow Admin | countflow-core.js به 3 postgres_changes references؛ Triggers على sessions/alerts/reconciliation/recount | event delivery، latency، reconnect |
| CountFlow Counter | Broadcast references وIndexedDB في المصدر | وصول Broadcast على جهاز آخر، offline replay |
| CountFlow Supervisor | Broadcast references | cross-user consistency وreconnect |
| CountFlow database | Broadcast triggers على sessions/alerts/reconciliation/recount | عدم فقد/تكرار/ترتيب الأحداث في runtime |
| SMART role_permissions | RPC profile يقرأ عبر SECURITY DEFINER | post-fix behavior لأن أي إصلاح لم يُطبق |

لا أصف أي مسار بأنه لحظي مثبت.

## 18. جاهزية استلام شعلة التطوير

**الحكم: BLOCKED للتغييرات والاختبارات الكتابية، READY WITH LIMITATIONS للقراءة والتوثيق.**

المساعد التالي يبدأ من:
- Governance CURRENT_STATE بعد تحديث LVE747.
- الدستور SHA 3a6b1e220af8509e314e94df76563bbc6f84910d.
- Operational HEAD بعد تحديث CountFlow CURRENT_STATE: 095a344e20cafd768c88353c33ceecbc764a6cc4.
- CountFlow CURRENT_STATE blob: 8475499b1dea098bdaec41c3d2063cf3b48d9e82.
- آخر code commit قبل تحديث التوثيق: b48e384319436e22a2464b6d3749c3e0069f7b14.
- لا حساب Owner في rawaea-staging، ولا roster معتمد، ولا Browser E2E أو Cloudflare artifact.

## 19. الالتزام بالدستور

- قُرئ CURRENT_STATE كاملًا ثم الدستور كاملًا، وسُجل SHA.
- لم يتم DDL/DML/ACL/RLS/Edge deploy أو نشر.
- لم يتم تعديل main.html أو core.js أو أي تطبيق ERP تشغيلي.
- كل SQL الحي كان SELECT/catalog only.
- محاولة 90k لم تُرجع نتيجة؛ لا PASS.
- لم تُنشأ حسابات أو Fixtures أو حركات مخزون/مال.
- بقي تعارض §6.4 مع البروتوكول اليومي §19 معلنًا ولم يُحسم بالتخمين.

## 20. المخاطر والاعتماديات وقرارات المالك

1. موافقة صريحة على CS-747-P0-A في SMART ERP.
2. قرار صريح بشأن السماح باستخدام rawaea-staging القائم لCountFlow رغم §6.4، أو وقف الكتابة فيه.
3. اعتماد سياسة احتواء Legacy schema وRPCs في rawaea-staging بعد consumer inventory.
4. لا إنشاء owner/member accounts دون هوية Auth مؤكدة وقائمة أسماء/أدوار/بريد معتمدة.
5. لا deployment أو browser E2E قبل إغلاق P0 وتحديد النطاق المسموح.

## 21. الخطوة التالية الواحدة ذات الأولوية

**CS-747-P0-A — إغلاق الوصول المباشر إلى public.role_permissions في SMART ERP بعد اعتماد المالك.**

المصدر الحالي: SMART ERP / public.role_permissions؛ owner postgres؛ RLS=true؛ PUBLIC ALL policy؛ anon/authenticated ACL مباشر.  
المسار الذي يجب الحفاظ عليه: get_my_effective_profile() SECURITY DEFINER، owner postgres، auth.uid() guard، وCore RPC consumer.  
التغيير المقترح، غير المنفذ:

    BEGIN;
    REVOKE ALL ON TABLE public.role_permissions FROM anon, authenticated;
    DROP POLICY IF EXISTS "Allow all for all" ON public.role_permissions;
    COMMIT;

ما لن يتغير: table data، table owner، service_role ACL، get_my_effective_profile، Edge save-role v9، الأدوار أو المستخدمون.  
اختبارات القبول بعد الاعتماد: direct table privileges لـanon/authenticated = false لكل SELECT/INSERT/UPDATE/DELETE/TRIGGER/REFERENCES/MAINTAIN؛ لا PUBLIC ALL policy؛ get_my_effective_profile ما زالت قابلة للتنفيذ لـauthenticated وتعيد الصلاحيات الصحيحة؛ save-role v9 يبقى JWT-gated ويكتب audit عبر المسار الحالي.  
التراجع: لا تعاد صلاحيات anon ولا سياسة PUBLIC ALL. إذا ظهر consumer مباشر، يُعالج بمنح أقل صلاحية authenticated مع RLS محددة وبعد تحليل أثر مستقل.  
**لا تنفيذ قبل موافقة المالك على هذا النص تحديدًا.**

---

# إضافات الحوكمة والتكامل وتجربة المنتج

## 22. تدقيق موثوقية Report735

| ادعاء Report735 | المطابقة الحية | النتيجة |
|---|---|---|
| SMART role_permissions عليه PUBLIC ALL وanon CRUD | مطابق | CONFIRMED |
| role_permissions ACL يتضمن TRUNCATE لـanon/authenticated | has_table_privilege=false وACL لا يحتوي D لهذين الدورين | خطأ في وصف ACL |
| categories ACL يتضمن TRUNCATE | غير صحيح؛ TRUNCATE=false | تصحيح مطلوب |
| categories P1 في التفصيل وP2 في الملخص | تناقض داخلي | يعتمد P1 |
| 65 Legacy RLS-disabled و56 anon-DML | مطابق | CONFIRMED |
| public.users 1,871 row وpassword_hash وanon full access | مطابق | CONFIRMED |
| ثلاث SECURITY DEFINER RPCs anon-executable بلا auth.uid | مطابق، وأضيف إثبات Edge wrappers بلا role checks | P0 أقوى من الوصف السابق |
| CountFlow 21 table / 70 policies | أصبح قديمًا | الحالي 23 / 76 / 78 FK |
| main.html blob 00456494 | مطابق | لا SHA drift |
| CountFlow no deployment/account | ما زال بلا دليل نشر أو حساب owner | OPEN |

## 23. سجل التغطية القابل للتدقيق

**فُحص اليوم:**  
- Governance CURRENT_STATE، الدستور، Report735، Report734، CountFlow CURRENT_STATE، Report746.
- GitHub operational branch/head/compare و49 مسارًا متغيرًا.
- CountFlow admin/counter/supervisor/core/SW/build/migration/test/report/state.
- SMART role_permissions/categories، policies، ACL، owners، function consumers، save-role/save-category Edge.
- rawaea-staging public tables/RLS/anon DML/users columns/function ACL/function definitions/Edge wrappers.
- CountFlow 23 table policies/FKs/row counts/migration ledger/Edge versions/selected policies/triggers/FKs.

**لم يُفحص اليوم:**  
- كل ملفات Parent/Buyer/Receiver/Warehouse/Delivery/POS.
- جميع مستهلكي 70 Legacy table داخل rawaea-staging.
- جميع RPCs/Edge functions في المشروعين.
- Cloudflare deployment artifacts.
- authenticated runtime وBrowser E2E.
- أجهزة فعلية وقياس UX.
- Benchmark المنافسين.

## 24. الرؤية الثلاثية

| الرؤية | الحالة |
|---|---|
| تنافسية مؤسسية | UNKNOWN — لا Benchmark حديث أو سيناريوهات متكافئة |
| تكامل النظام الأم والتطبيقات | UNKNOWN على مستوى المنظومة؛ CountFlow مستقل عن Parent ولا توجد رحلة مستخدم موحدة مثبتة |
| قلب مركزي ومزامنة لحظية | UNKNOWN؛ توجد Core/RPC/Realtime references لكن لا اختبار delivery/latency/reconnect |

لا تُعرض نسبة تقدم لعدم وجود denominator موحد قابل للإثبات.

## 25. خريطة دورة الأعمال والأثر

- المورد → PO → استلام فعلي → stock movement → journal/supplier ledger: المسار المركزي في rawaea-staging موجود في receive_purchase_atomic، لكنه بلا auth.uid binding؛ ممنوع استدعاؤه.
- الجرد → session → entries → reconciliation → approval → export: الجداول وRPCs موجودة، لكن CountFlow لا يحتوي أعضاء أو جلسات أو بيانات، ومسارات direct DML الحرجة ما زالت مفتوحة.
- تعديل المخزون عبر post_inventory_adjustment_atomic: لا actor authentication داخلي، والـEdge wrapper لا يفحص الصلاحية الوظيفية.
- فاتورة البيع عبر save_sales_invoice_atomic: يمكن أن تتحول إلى stock/GL effect عند Invoiced؛ الـEdge wrapper يثبت JWT فقط.
- لا حركة مخزون/خزينة/قيود/دفتر مورد/عميل نُفذت في هذا التشغيل.

## 26. فجوات سلامة الأثر المالي والمخزني

- لا يجوز اعتبار JWT وحده تفويضًا لدور مخزني أو محاسبي.
- p_user_email حقل إسناد، وليس إثبات هوية.
- لا يوجد auth.uid binding داخل RPCs الثلاث.
- لا يوجد اختبار idempotency أو rollback لهذه RPCs اليوم.
- لا توجد حركات دائمة أو اختبارات على بيانات أعمال حقيقية.
- أي اختبار لاحق لمسار posting يجب أن يكون في معاملة مضمونة rollback أو بيئة مصرح بها، مع baseline/reconciliation؛ وإلا يبقى UNVERIFIED.

## 27. جودة الاختبارات

| الاختبار | البيئة | النتيجة |
|---|---|---|
| Git/source compare | GitHub | PASS للمقارنة والبصمات |
| Supabase catalog | SMART + rawaea-staging | PASS للقراءة فقط |
| CountFlow RLS/ACL/FK | rawaea-staging | PASS للقراءة فقط |
| CountFlow Edge source parity | rawaea-staging + GitHub | PASS exact match |
| 90k rollback | rawaea-staging | NOT RUN/UNVERIFIED بسبب خطأ داخلي |
| Authenticated E2E | لا جلسة/حساب | NOT RUN |
| XLSX open/validation | لا ملف فعلي | NOT RUN |
| Realtime cross-device | لا Browser sessions | NOT RUN |
| Deployment parity | لا Cloudflare artifact | UNKNOWN |

## 28. اكتمال المنتج وتجربة المستخدم

- البنية موجودة: Admin/Counter/Supervisor pages، Core helper، Service Worker، manifest، database schema، RPCs وEdge Functions.
- الوظيفة الحية غير مثبتة: لا حسابات، لا جلسات، لا بيانات، لا deployment.
- static scan أثبت RTL وviewport على الصفحات الثلاث؛ لا يثبت responsive runtime.
- صفر aria-* attributes في الصفحات الثلاث وفق المصدر الحالي؛ هذه فجوة وصول يجب مراجعتها على DOM.
- لا زمن مهمة أو first-pass success أو input-error rate أو task completion measurement.
- لا يجوز وصف CountFlow بأنه منتج مكتمل أو جاهز للميدان.

## 29. Opportunity backlog مختصر

| الأولوية | الفرصة | القيمة | الاعتماد/شرط الإغلاق |
|---|---|---|---|
| P0 | SMART role_permissions containment | منع تعديل صلاحيات الأدوار من anon | موافقة Change Set + post-change ACL/RPC tests |
| P0 | rawaea-staging legacy users/RPC containment | منع كشف password_hash وتنفيذ posting بلا actor auth | consumer census + Edge authorization + owner approval |
| P1 | central state-transition RPCs لـreconciliation/recount/alerts | منع تجاوز الموافقات والحالات | RPC contract + RLS narrowing + rollback tests |
| P1 | session DELETE lifecycle guard | منع cascade حذف جلسة نشطة أو مكتملة | status-aware DELETE guard + audit |
| P2 | Accessibility/keyboard/device review | تقليل أخطاء المستخدم وتحسين الوصول | Browser/keyboard/screen-reader evidence |
| P2 | Offline close/replay barrier وBroadcast reliability | حماية العمل الميداني من فقد/تكرار الأحداث | multi-device E2E + measured latency |
| P2 | Export validation | ثقة التقارير والصور والحدود | XLSX download/open + hash + size/row-count verification |

**النهاية — Report747.**