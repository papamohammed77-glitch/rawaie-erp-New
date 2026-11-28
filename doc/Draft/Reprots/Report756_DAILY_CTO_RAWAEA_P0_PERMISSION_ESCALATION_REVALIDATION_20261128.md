# Report756 — المراجعة التشغيلية اليومية واحتواء P0 لصلاحيات الأدوار

**التاريخ:** 2026-11-28 — Africa/Cairo  
**النطاق:** RAWAEA ERP / companies/company-1 فقط. CountFlow/company-2 مستبعد تمامًا.  
**الدور:** CTO / Lead Engineer / Enterprise Architecture / Operational Security Review  
**الحالة:** READY WITH LIMITATIONS للفحص القرائي والتوثيق؛ BLOCKED لتطبيق تغيير Production المحدد حتى موافقة المالك الصريحة.  
**نمط التنفيذ اليوم:** GitHub read-only + Supabase catalog/SQL read-only + Edge source reads + log sampling. لم تُنفذ كتابة أو نشر أو عملية أعمال.

---

## 1. نقطة البداية والاستئناف

- جُلب CURRENT_STATE.md أولًا من مستودع الحالة المرجعي، كاملًا عبر GitHub fetch result ثم فُحصت بنيته ونهايته: 298,919 حرفًا / 2,904 سطرًا، blob SHA: 2e6b9a9b14203601c342817b2fcc53d9481ca2ff.
- أحدث نقطة مثبتة قبيل هذه المراجعة: LVE-2026-11-27-755 / Report755.
- جُلب الدستور التشغيلي الدائم بعد CURRENT_STATE مباشرة، كاملًا: 19,916 حرفًا / 310 أسطر، SHA: 3a6b1e220af8509e314e94df76563bbc6f84910d.
- تقرير الاستئناف Report755: SHA 99119aa1c1194e304679cf0c7b822e52fbac1915، 12,456 حرفًا / 147 سطرًا.
- تقرير الأصل التاريخي ذي الصلة Report753: SHA e6a1d6a96b55800fc84e0dc876d331faa2dc461d، 21,001 حرف / 315 سطرًا.
- مستودع الحالة، branch main، HEAD قبل تقرير اليوم: 2f29284e5fd1162b70b3f7e3da629ea7bc9c13d2.
- المستودع التشغيلي، branch main، HEAD: 095a344e20cafd768c88353c33ceecbc764a6cc4. لم يتغير عن Checkpoint السابق؛ لا يوجد commit تشغيلي أحدث يفرض إعادة فتح ملفات company-1.
- الهدف المستمر: احتواء الكتابة المباشرة إلى public.role_permissions دون المساس بقراءة الصلاحيات المركزية أو بيانات الأعمال.
- لا يوجد إغلاق جديد لـP0؛ CS-748-P0-A ما زال غير مطبق وغير معتمد.

## 2. CONFIRMED

### 2.1 GitHub / Source

- Operational HEAD ثابت عند 095a344e20cafd768c88353c33ceecbc764a6cc4.
- Parent: companies/company-1/main.html، blob 00456494de918b36fc6792bef302319a9f65605d، 2,038,589 bytes حسب Git tree، و1,935,680 character في محتوى blob المسترجع.
- Core: companies/company-1/core.js، blob 2b2211a3f95049042e27a7b2ecbab3640a584942، 53,676 characters / 1,094 lines.
- app.html: blob 2e47a68fe83956e27d569e786a08dcee91af2924.
- warehouse/warehouse.html: blob b9c132a6f10db7524cdc9f0767935069371d5562، 642,519 characters.
- تصحيح مهم لتقرير Report755: fetch_file على main.html ما زال يعيد محتوى فارغًا، لكن fetch_blob بالـSHA نفسه أعاد الملف كاملًا. لذلك عبارة «محتوى Parent غير متاح» أصبحت قيدًا خاصًا بطريقة fetch_file لا قيدًا على استعادة blob. لم يتغير SHA أو الكود؛ تغيرت طريقة الاسترجاع فقط.
- فُحصت 35/35 ملفات النص البرمجية تحت companies/company-1 (HTML/JS/TS، مع استبعاد manifest.json غير البرمجي) بحثًا عن role_permissions وget_my_effective_profile وget_warehouse_hub_snapshot وواجهات الصلاحيات المرتبطة. لم يظهر استدعاء مباشر للجدول من واجهات المستخدم؛ ظهر:
  - app.html يستدعي get_my_effective_profile بعد تسجيل الدخول.
  - core.js يستدعي get_my_effective_profile أثناء تهيئة RW_Auth.
  - warehouse/warehouse.html يستدعي get_warehouse_hub_snapshot للتحقق من المستخدم ونطاق الفروع.
  - main.html يحتوي ذكر role_permissions_sync في عرض سجل التدقيق، وليس استدعاءً مباشرًا للجدول.
- هذا فحص نصي كامل لهذه الملفات والأنماط المحددة، وليس إثباتًا مطلقًا لغياب SQL ديناميكي أو wrappers أو استدعاءات مبنية نصيًا خارج الأنماط المفحوصة.
- Parent main يهيئ window.RW_SUPABASE_CLIENT قبل تحميل core.js، ثم يتحقق Core من العميل نفسه ويستخدمه؛ هذا يثبت مشاركة Parent وCore للعميل في هذا المسار المصدرّي، ولا يثبت وجود singleton واحد عبر جميع التطبيقات المستقلة.

### 2.2 Supabase Production — SMART ERP

- المشروع fiilmooggumokxanwiyx: ACTIVE_HEALTHY؛ PostgreSQL 17.6.1.121؛ المنطقة eu-west-1.
- Migration ledger: 800؛ أحدث migration 20261119010201 باسم quick_market_supplier_credit_receiving_trigger_guard.
- رصد SQL/catalog الأخير: 2026-11-28T20:32:44.338421Z.
- كل استعلامات هذه المراجعة SELECT/catalog فقط؛ لم يُستدعَ RPC أعمال ولم يحدث DDL/DML/ACL/RLS write.

### 2.3 P0 — public.role_permissions: مسار تصعيد صلاحيات مؤكد على مستوى الكتالوج

الحالة الحالية:

| العنصر | النتيجة الحية |
|---|---|
| RLS | enabled = true |
| FORCE RLS | false |
| Policy | واحدة: Allow all for all |
| Policy role | PUBLIC |
| Command | ALL |
| USING / WITH CHECK | true / true |
| Rows | 21 |
| Distinct role_id | 3 |
| permission_key = '*' | 0 صف حاليًا |
| Triggers | لا يوجد user trigger على الجدول |
| Columns | id, role_id, permission_key فقط |
| company_id | غير موجود |
| Constraints | PK(id)، UNIQUE(role_id, permission_key)، FK(role_id) → roles(id) ON DELETE CASCADE؛ لا يوجد CHECK constraint يمنع '*' |

التمييز بين ACL وRLS:

- توجد منح مباشرة لـanon وauthenticated على SELECT/INSERT/UPDATE/DELETE/REFERENCES/TRIGGER/MAINTAIN.
- لا توجد لهما TRUNCATE على هذا الجدول.
- service_role يحتفظ بمنح الكتابة وTRUNCATE، ويمتلك BYPASSRLS.
- لا يوجد grantee باسم PUBLIC في relacl الحالي للجدول؛ PUBLIC هو نطاق سياسة RLS، بينما منح anon/authenticated صريحة.
- لا توجد عضوية أدوار موروثة لـanon أو authenticated تفسر المنح؛ direct ACL هو المصدر المرصود.

مسار التأثير الذي أثبته الكود والكتالوج:

1. public.get_my_effective_profile() دالة SECURITY DEFINER مملوكة postgres، search_path فارغ، وEXECUTE للمصادقين true ولـanon false. تجمع صلاحيات المستخدم من users.permissions، وصلاحيات الدور من roles.permissions، ثم تضيف role_permissions.permission_key للدور نفسه.
2. app_private.current_user_has_effective_permission(text) دالة SECURITY DEFINER مملوكة postgres، search_path فارغ، وEXECUTE للمصادقين true ولـanon false. تعيد true إذا احتوى ملف المستخدم الفعال على '*' أو المفتاح المطلوب.
3. حصر السياسات الحية وجد 19 RLS policy تعتمد على current_user_has_effective_permission عبر جداول تشمل branches وitems وreceiving وreceiving_details وsupplier_ledger وbuyer custody وdriver liabilities وHR وغيرها.
4. RW_Auth.checkPermission في Core يقبل '*' كصلاحية شاملة على مستوى واجهة التطبيق.
5. get_warehouse_hub_snapshot() يقرأ role_permissions مباشرة للتحقق من مفتاح warehouse، وهو SECURITY DEFINER مملوك postgres وEXECUTE للمصادقين true ولـanon false.

النتيجة الأمنية:

اجتماع direct DML grants مع PUBLIC ALL policy، وغياب company_id وغياب قيد يمنع wildcard، يتيح مسار كتابة مباشرًا إلى جدول يغذي الصلاحيات الفعالة. إضافة permission_key='*' لدور مستخدم قد تجعل ملفه الفعال شاملًا، وتُمرر فحوص current_user_has_effective_permission المستخدمة في 19 سياسة. هذا مسار تصعيد صلاحيات P0 مثبت من GRANT + POLICY + function path؛ لم يُنفذ exploit أو DML لإثباته عمليًا. عدم وجود wildcard حاليًا لا يزيل قابلية الكتابة.

### 2.4 عقود الأدوار والـEdge Functions ذات الصلة

- قائمة Production الحالية: 100 Edge Function بحالة ACTIVE.
- تمت قراءة مصادر أربع وظائف مرتبطة بالنطاق:
  - save-role v9، verify_jwt=true.
  - delete-role v4، verify_jwt=true.
  - seed-roles v4، verify_jwt=true.
  - save-category v6، verify_jwt=true.
- save-role وseed-roles وdelete-role تستخدم service_role بعد التحقق من Authorization وملف المستخدم والشركة وصلاحية roles أو المالك. save-role يكتب roles وusers ويزامن metadata والتدقيق؛ لا يكتب role_permissions مباشرة.
- delete-role يحذف role_permissions للدور عبر service_role قبل حذف الدور؛ هذا المسار يبقى صالحًا بعد حجب anon/authenticated لأن service_role يحتفظ بالمنح ويتجاوز RLS.
- save-category يتحقق من جلسة المستخدم وصلاحية items/data-entry أو wildcard ويقيد العملية بالشركة، ثم يكتب categories/items عبر service_role. هذا لا يلغي الخطر المستقل الناتج عن منح DML المباشرة على categories.
- لم تُراجع مصادر جميع الوظائف الـ100؛ هذه مراجعة محددة لأربع وظائف مرتبطة بالنطاق.

### 2.5 P1 — categories

- public.categories: 5 صفوف؛ RLS=true وFORCE=false؛ سياسة واحدة PUBLIC ALL مع USING=true وWITH CHECK=true.
- anon وauthenticated يملكان CRUD فعالًا.
- Parent يستخدم save-category Edge Function في إنشاء/تعديل التصنيف، لكن منح الجدول المباشرة تسمح بمسار يتجاوز تحقق الصلاحية ونطاق الشركة داخل Edge Function.
- P1 مستقل تمامًا عن CS-748-P0-A، ولا يُضم إليه.

### 2.6 P1 — Default ACL للمستقبل

- pg_default_acl في public ما زال يحتوي منحًا واسعة لـanon/authenticated.
- الجداول التي ينشئها owner postgres ترث مجموعة arwdxtm دون TRUNCATE.
- الجداول التي ينشئها owner supabase_admin ترث arwdDxtm بما فيها TRUNCATE.
- هذا إعداد افتراضي للجداول المستقبلية التي ينشئها هذان المالكان؛ لا يعني أن كل جدول حالي يحمل هذه المنح.
- تغيير Default ACL نطاق مستقل يحتاج Change Set وموافقة مستقلة.

### 2.7 Security Advisor

الرصد: 2026-11-28T20:32:44.988Z.

| Finding | Level | Count | التفسير |
|---|---:|---:|---|
| RLS enabled / no policy | INFO | 24 | جداول بلا سياسة؛ غالبًا default-deny، ويلزم تصنيفها لا افتراض التسريب |
| SECURITY DEFINER view | ERROR | 1 | v_finance_employee_directory |
| anon SECURITY DEFINER functions | WARN | 4 | دالتا Trigger ودالتا storefront عامتان |
| authenticated SECURITY DEFINER functions | WARN | 142 | جرد واسع يتطلب triage حسب العقد، وليس 142 ثغرة مثبتة |
| Leaked Password Protection disabled | WARN | 1 | إعداد Auth يحتاج قرارًا منفصلًا |

تحقق إضافي:

- v_finance_employee_directory مملوكة postgres، security_barrier=true، وتفلتر company_id بواسطة current_user_company_id ثم finance/finance_manager/hr أو المستخدم نفسه. anon SELECT=false وauthenticated SELECT=true. تحذير Advisor قائم، لكن لم يثبت تسريبًا في هذا الفحص.
- enforce_supplier_return_receiver() وsync_supplier_return_buyer_custody_event() ترجعان trigger ولكل منهما trigger واحد؛ تحذير anon لا يثبت إمكانية استدعائهما كـRPC أعمال ناجح.
- get_public_store_catalog وget_public_store_order_tracking نقطتا storefront عامتان؛ كود tracking يحد تفاصيل الاستعلامات الجزئية ويشترط مفتاح المتجر، لكن rate-limit/abuse testing لم ينفذ.
- لا يجوز تحويل عدادات Advisor إلى عدد ثغرات مستغلة.

## 3. UNKNOWN

- لا نعرف من هذه المراجعة ما إذا استُخدم مسار role_permissions المباشر فعليًا من عميل خارجي؛ لم يظهر طلب له في عينة logs، وهذا لا يثبت عدم الاستخدام أو عدم الاستغلال.
- لا توجد نتيجة exploit test، ولا Browser E2E مصادق، ولا تحقق cross-user/cross-device.
- لا يوجد قياس ميداني لزمن المهمة أو معدل الخطأ أو إعادة العمل.
- لا يوجد قياس دقة تنبؤ أو replenishment أو forecast.
- لا توجد مقارنة تنافسية حديثة موثقة في تشغيل اليوم.
- لا يوجد score صالح لمجالات النضج الاثني عشر؛ لا تُمنح درجات من هذه العينة.

## 4. CONFLICT

- تقرير Report755 ذكر أن محتوى Parent main.html غير متاح. هذا صحيح بالنسبة إلى fetch_file، لكنه لم يعد صحيحًا كحكم عام على قابلية الاسترجاع؛ fetch_blob بالـSHA نفسه أعاد المحتوى كاملًا. لا يوجد اختلاف SHA أو تغيير كود.
- توجد فروق حاكمية اختبار بين الدستور §6.4 الأقدم الذي يسمح Fixtures QA مؤقتة قابلة للإزالة في Production، وبين توجيه المالك الأحدث في البروتوكول الحالي الذي يمنع إنشاء بيانات/عمليات اختبار في Production دون استثناء منفصل صريح، ويشترط BEGIN/ROLLBACK أو سياقًا آمنًا مصرحًا به لمسارات الأثر، ويحظر ترك حركات مالية/مخزنية تجريبية دائمة. التطبيق الوقائي: لا fixtures أو عمليات اختبار مؤثرة في Production دون الموافقة المنفصلة؛ لا إنشاء Staging/فرع/مشروع جديد؛ قراءة فقط إلى أن يتوفر سياق آمن مصرح به.
- لا يوجد تعارض في حالة P0: الأدلة الحية ما زالت تطابق أن الجدول مفتوح وأن Change Set لم يطبق.

## 5. UNVERIFIED

- Cloudflare deployed artifact bytes/build lineage: UNVERIFIED.
- Browser authenticated runtime/E2E: UNVERIFIED.
- business effects بعد ترحيل فعلي: UNVERIFIED.
- Realtime event delivery وreconnect وordering وlatency: UNVERIFIED.
- كل دور ورحلة عمل ميدانية، Responsive على أجهزة حقيقية، وإتاحة الوصول: UNVERIFIED.
- جميع التطبيقات والوظائف التشغيلية ليست مصنفة سليمة؛ نطاق اليوم أمني/مصدر صلاحيات فقط.

## 6. مصفوفة التحقق

| الطبقة | نتيجة اليوم | التصنيف |
|---|---|---|
| GitHub / Source | branch main وHEAD وParent/Core و35 ملفًا نصيًا في نطاق الصلاحيات | CONFIRMED ضمن النطاق |
| Supabase Production | project health، 800 migrations، ACL/RLS، functions، Advisor | CONFIRMED read-only |
| Deployed Artifact | فتح URL المنشور عبر web فشل، والتنزيل المباشر فشل | UNKNOWN |
| Runtime / E2E | logs موجودة، لكن لا Browser context ولا جلسة E2E | UNVERIFIED |
| Business-data effects | لا DML أو RPC أعمال أو QA fixtures من المراجعة | CONFIRMED: لا أثر أحدثته المراجعة |
| Staging | لم يُنشأ ولم يُستخدم | CONFIRMED |

## 7. ما تم فعليًا

1. استعادة CURRENT_STATE والدستور والتقرير السابقين.
2. التحقق من branch/HEAD للمستودعين.
3. استرجاع Parent main blob كاملًا وتصحيح قيد fetch السابق.
4. قراءة core.js وapp.html وwarehouse/warehouse.html.
5. مسح 35 ملفًا برمجيًا في company-1 بحثًا عن مستهلكي الصلاحيات المحددين.
6. قراءة أربع Edge Functions مرتبطة بالأدوار والتصنيفات.
7. تنفيذ استعلامات catalog/ACL/RLS/constraints/functions/policies/default ACL read-only.
8. إعادة تشغيل Security Advisor.
9. قراءة عينات logs وتحديد PostgREST timeout messages.
10. البحث في سياق الموافقات السابقة؛ لم يظهر اعتماد/رفض لاحق للنص المحدد CS-748-P0-A.

لم يتم تعديل كود تشغيلي أو قاعدة بيانات أو إعدادات أو نشر.

## 8. ما لم يتم ولماذا

- لم يطبق CS-748-P0-A: لا توجد موافقة صريحة على SQL المحدد.
- لم يختبر DML أو exploit: محظور وفق حوكمة المالك، ولا حاجة لإحداث كتابة لإثبات catalog path.
- لم يجر اختبار authenticated profile بعد الإغلاق: لا يوجد Browser context مصادق صالح في هذه الجلسة.
- لم يجر اختبار E2E مالي/مخزني: لا توجد بيئة معزولة مصرح بها؛ لا اختبار مؤثر على Production.
- لم يفحص كل Edge Functions أو كل RPCs أو كل التطبيقات وظيفيًا: النطاق اليوم محدد بمسار الصلاحيات، ولم يحدث تغيير يفرض إعادة فحص شامل.

## 9. سجل التغطية

| النطاق | ما فُحص اليوم | ما لم يفحص |
|---|---|---|
| Parent | blob كامل، boot/client، RW_Roles، category flow | رحلة UX كاملة وDOM/Browser |
| Core | كامل core.js، Auth، Realtime | كل مستهلكيه في كل تطبيق ميدانيًا |
| company-1 apps | 35 ملفًا نصيًا للأنماط الأمنية المحددة | الوظائف والرحلات الكاملة |
| Supabase tables | role_permissions، categories، roles policies، default ACL | جميع الجداول والـFKs والـtriggers |
| RPCs | الوظائف المرتبطة بـrole_permissions وprofile/warehouse snapshot | كل RPC في Production |
| Edge | save-role/delete-role/seed-roles/save-category | 96 وظيفة أخرى |
| Logs | source counts، HTTP error counts، PostgREST errors، Realtime idle events | trace لكل عملية أعمال |
| Deployment | محاولة فتح URL وتنزيله | artifact bytes وbuild lineage |
| UX / Benchmark | لم يجر اليوم | كل الشاشات والمنافسين |

CountFlow خارج هذا النطاق بالكامل.

## 10. تدقيق موثوقية Report755

- صحيح ومؤكد مجددًا: P0 grants/policy/rows، categories P1، default ACL P1، migration count/latest، Advisor counts، عدم وجود موافقة محددة، عدم وجود تطبيق للتغيير.
- صحيح لكنه يحتاج صياغة أدق: Parent fetch كان فارغًا عبر fetch_file، لا عبر كل طرق الاسترجاع؛ fetch_blob نجح الآن.
- توسع الإثبات اليوم: رُبطت role_permissions بـget_my_effective_profile وcurrent_user_has_effective_permission و19 RLS policy، وأثبت غياب company_id وCHECK constraint، وجرى فحص 35 ملفًا نصيًا.
- ما زال صحيحًا: artifact parity وauthenticated E2E وRealtime delivery والـUX الميداني والـbenchmark غير مثبتة.
- لا توجد أرقام/SHAs حالية تناقض Report755؛ SHA ملفات Parent/Core ثابت.

## 11. الأخطاء والفجوات والأولوية

### P0 — كتابة مباشرة إلى role_permissions
- الدليل: direct ACL لـanon/authenticated + PUBLIC ALL policy + profile aggregation + wildcard authorization + 19 policy consumers.
- السبب الجذري المثبت: الجدول لا يملك company_id ولا قيدًا يمنع wildcard، وسياسة RLS مفتوحة بالكامل مع DML grants.
- الإجراء: تطبيق CS-748-P0-A فقط بعد موافقة صريحة.
- معيار الإغلاق: سحب كل privileges الفعالة عن anon/authenticated، غياب السياسة المفتوحة، بقاء service_role، بقاء profile/warehouse RPCs، قراءة ملف مستخدم مصادق والتحقق من نفس الصلاحيات، ثبات 21 صفًا و3 أدوار، وعدم أي أثر أعمال.
- الحالة: OPEN / NOT APPROVED / NOT APPLIED.

### P1 — categories
- direct CRUD لـanon/authenticated وسياسة PUBLIC ALL.
- الإجراء: Change Set مستقل بعد حصر جميع المستهلكين والكتابة عبر save-category فقط أو مسار معتمد.
- الحالة: OPEN / NOT BUNDLED.

### P1 — Default ACL
- منح واسع للجداول المستقبلية من postgres/supabase_admin.
- الإجراء: Change Set مستقل مع جرد الجداول/المالكين والـdefault privileges.
- الحالة: OPEN / NOT BUNDLED.

### P1 — Security Advisor
- v_finance_employee_directory و4 anon SECURITY DEFINER functions و142 authenticated functions تحتاج triage حسب المسار والـgrants والـpolicy، لا تغييرات جماعية.
- Leaked Password Protection يحتاج قرار Auth مستقل.
- الحالة: OPEN / TRIAGE.

### P2 — PostgREST timeouts
- 7 رسائل Warp server error: Thread killed by timeout manager بين 2026-11-27 23:15 و2026-11-28 14:52 UTC.
- لا يوجد في هذه السجلات route/status يربطها بطلب أعمال محدد؛ لم يثبت أثر المستخدم.
- الإجراء: correlation مع query/trace/slow query عند توفر سجل أعمق؛ لا تغيّر timeout عشوائيًا.
- الحالة: OPEN / IMPACT UNKNOWN.

### P2 — حماية main branch
- GitHub API يعيد protected=false وrequired status checks off لكل من operational main وgovernance main.
- هذا ضعف حوكمة تغيير، وليس إثباتًا أن مستخدمًا غير مخول يملك push.
- الإجراء: Change Set إداري مستقل؛ لا نغير إعدادات المستودع ضمن مراجعة اليوم.
- الحالة: OPEN / OWNER DECISION.

### P2 — Realtime delete semantics
- Core engine يقبل INSERT/UPDATE فقط؛ لا يسجل DELETE events.
- قد يكون هذا مقصودًا لبعض المستهلكين؛ أثره على كل شاشة لم يختبر.
- الإجراء: حصر المستهلكين الذين يعتمدون على حذف فوري، ثم اختبار cross-user/reconnect قبل أي تعديل.
- الحالة: OPEN / IMPACT UNKNOWN.

## 12. الكفاءة التشغيلية ودورة المورد إلى العميل

لم تنفذ اليوم أي دورة أعمال فعلية من المورد إلى الاستلام والمخزن والفرع والعميل ثم الخزينة/الحسابات. لا يجوز وصف أي مسار بأنه مختبر أو مكتمل بناءً على وجود RPC أو شاشة.

| المرحلة | دليل اليوم | الحالة |
|---|---|---|
| مورد → PO → استلام | عقود وRPCs موجودة في Production، لا E2E | غير مثبتة ميدانيًا |
| استلام → مخزون | لا posting test ولا أثر | UNVERIFIED |
| تجهيز/تحميل/تسليم | لا Browser E2E اليوم | UNVERIFIED |
| مرتجع/عهدة | سياسات قراءة تستعمل effective permissions | عقد جزئي فقط |
| تحصيل/تسوية/قيود | لا أثر ولا اختبار اليوم | UNVERIFIED |

## 13. التخطيط والتنبؤ ومركز القرار

لم يجر قياس دقة forecast أو reorder recommendations أو نفاد/ركود/تكدس أو cash forecasting اليوم. لا توجد نسبة أو score صالح للإعلان. الحالة UNKNOWN.

## 14. Benchmark تنافسي

لم يجر بحث رسمي حديث اليوم في SAP S/4HANA أو Business One أو Dynamics 365 أو Odoo أو ERPNext أو Daftra أو Manager.io. لم يُحدد أي منتج مبهم باسم Next. لا توجد مقارنة عادلة أو ادعاء تفوق. يبقى benchmark OPEN.

## 15. مصفوفة نضج المجالات الاثني عشر

لا توجد أدلة تشغيلية شاملة كافية لإسناد درجات من 0 إلى 5 في مراجعة اليوم؛ جميع المجالات تبقى UNKNOWN:

1. السلامة التقنية والمعمارية — UNKNOWN.
2. تكامل التطبيقات والبيانات — UNKNOWN.
3. العمليات التجارية — UNKNOWN.
4. الرقابة المالية والمحاسبية — UNKNOWN.
5. المخزون وسلاسل الإمداد — UNKNOWN.
6. التوزيع والعمل الميداني — UNKNOWN.
7. التخطيط والتنبؤ — UNKNOWN.
8. التقارير وBI — UNKNOWN.
9. الأمان والصلاحيات والتدقيق — لا درجة شاملة؛ P0 محدد مؤكد.
10. الأداء والاستقرار والتوسع — UNKNOWN؛ توجد PostgREST timeout logs تحتاج correlation.
11. تجربة المستخدم والإنتاجية — UNKNOWN.
12. الجاهزية التشغيلية والتنافسية — UNKNOWN.

## 16. خريطة Parent/Core ذات الصلة

- Parent main.html يهيئ Supabase client واحدًا في window.RW_SUPABASE_CLIENT، ثم يحمل core.js، ثم يتحقق من نفس العميل ويستخدمه كـsupabase.
- Core RW_Auth يقرأ get_my_effective_profile ويحوّل الصلاحيات إلى currentProfile.
- Parent RW_Roles يقرأ roles/users، ويحفظ عبر save-role Edge Function، ويحذف عبر delete-role؛ لا يستدعي role_permissions مباشرة من الواجهة.
- delete-role يزيل role_permissions باستخدام service_role.
- app.html يستخدم get_my_effective_profile لتحديد إعادة التوجيه حسب الصلاحيات والدور المخزني.
- warehouse/warehouse.html يستخدم get_warehouse_hub_snapshot ويتحقق من تطابق user/company ونطاق الفروع قبل فتح التشغيل.
- لا تثبت هذه الخريطة وجود Core موحد في كل التطبيقات أو عميل Supabase وحيد على مستوى المنظومة كلها.

## 17. مصفوفة المزامنة

- RW_Realtime في core.js ينشئ Supabase channel، ويستقبل postgres_changes على INSERT/UPDATE، ويطبق company_id filter افتراضيًا، ويستدعي onEvent بعد debounce.
- عند SUBSCRIBED ينفذ reconcile، ويعيد reconcile عند إعادة الاشتراك/الظهور، كما ينفذ periodic reconcile بحد أدنى 15 ثانية وافتراضي 60 ثانية.
- عند SIGNED_OUT يوقف القنوات.
- لا يوجد DELETE في قائمة الأحداث المسموحة.
- هذه أدلة Source Code فقط؛ logs أظهرت Realtime idle shutdown عند عدم وجود مستخدمين/اشتراكات. لم يثبت event delivery أو latency أو ترتيب الأحداث أو cross-device behavior.
- لا يوصف النظام بأنه لحظي مثبت.

## 18. اختبار المنتج وتجربة المستخدم

- لم ينفذ Browser/DOM أو Responsive أو Accessibility أو persona journey اليوم.
- لا توجد قياسات زمن أو clicks أو first-pass success أو error rate.
- لا توجد حالات UI جرى اختبارها في loading/empty/error/offline/reconnect.
- بنية الواجهة ليست دليلًا على اكتمال المنتج.
- بوابة UX/المنتج تظل OPEN، ولا توجد توصية UI تغيير ضمن هذه المهمة الأمنية.

## 19. جودة الاختبارات

| النوع | النتيجة |
|---|---|
| Static / source inspection | تم في نطاق الملفات المذكورة |
| Schema / ACL / RLS / function catalog | تم read-only |
| Unit / Integration | لم ينفذ |
| Staging | غير متاح/غير منشأ |
| Authenticated Browser E2E | لم ينفذ |
| Deployment parity | لم ينفذ |
| Business effects | لم ينفذ؛ لا بيانات QA ولا حركات |
| Cleanup | لا fixtures أنشئت، فلا يوجد cleanup مطلوب |

## 20. حوكمة الدستور والاختبارات

- CURRENT_STATE ثم الدستور الكامل ثم التاريخ ثم الأدلة الحية؛ الترتيب متحقق.
- طُبقت §6.2 و§7: لا تعديل مؤثر دون النص المحدد وموافقة المالك.
- طُبقت بوابة عدم العبث بالأرصدة والقيود والمخزون، وعدم إجراء عمليات اختبار دائمة في Production.
- الدستور §6.4 أقدم ويسمح Fixtures QA مؤقتة في Production بشروط تنظيف؛ البروتوكول الحالي الأحدث أشد تقييدًا ويشترط استثناءً منفصلًا لأي اختبار في Production. التفسير الوقائي هو عدم إنشاء بيانات/عمليات اختبار مؤثرة دون اعتماد منفصل، وعدم إنشاء Staging جديد.
- لا تعديل مباشر على main.html أو core.js أو التطبيقات التشغيلية؛ لا تعديل على Supabase أو نشر.

## 21. المخاطر والقرارات المطلوبة

1. موافقة أو رفض صريح للنص المحدد CS-748-P0-A.
2. Change Set مستقل لـcategories.
3. Change Set مستقل لـDefault ACL.
4. قرار مستقل بشأن حماية main branches.
5. خطة correlation لسبع PostgREST timeout messages.
6. جلسة Browser مصادق عليها/Artifact access عند الحاجة لاختبار القبول؛ لا يطلب من المالك إعادة إرسال معلومات موجودة.

### CS-748-P0-A — النص المقترح فقط، لم يطبق

~~~sql
BEGIN;
REVOKE ALL ON TABLE public.role_permissions FROM anon, authenticated;
DROP POLICY IF EXISTS "Allow all for all" ON public.role_permissions;
COMMIT;
~~~

النطاق: public.role_permissions فقط. لا تعديل للصفوف أو users أو roles أو service_role أو RPCs أو categories أو default ACL أو Parent/Core أو Edge Functions.

قبول التغيير بعد موافقة المالك وتطبيقه:
- anon/authenticated effective privileges = false لكل SELECT/INSERT/UPDATE/DELETE/REFERENCES/TRIGGER/MAINTAIN/TRUNCATE.
- اختفاء سياسة Allow all for all.
- service_role grants وBYPASSRLS محفوظة.
- بقاء EXECUTE للمصادقين على get_my_effective_profile وget_warehouse_hub_snapshot.
- قراءة profile في جلسة مصادق عليها والتحقق من تطابق الصلاحيات قبل/بعد دون تعديل rows.
- بقاء عدد الصفوف 21 وdistinct role_id = 3.
- عدم إنشاء أو تغيير أي حركة مخزنية/مالية أو قيد أو رصيد.
- لا rollback يعيد الوصول العام المفتوح؛ أي تراجع بديل يحتاج Change Set وموافقة.

## 22. حكم الجاهزية واستلام الشعلة

**READY WITH LIMITATIONS** للقراءة والتوثيق واستمرار تدقيق P0.  
**BLOCKED** لتطبيق CS-748-P0-A حتى اعتماد المالك للنص المحدد.  
**BLOCKED** لاختبارات الأثر غير المعزولة أو غير القابلة للتراجع.  
نقطة الاستئناف التالية: قرار المالك على CS-748-P0-A؛ بعده لا يعاد التحقيق من الصفر، بل ينفذ فقط النطاق المعتمد ثم تحقق ACL/RLS/profile المحدد.

## 23. المراجع

- CURRENT_STATE: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
- Constitution: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/%D8%A7%D9%84%D8%AF%D8%B3%D8%AA%D9%88%D8%B1%20%D8%A7%D9%84%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%D9%8A%20%D8%A7%D9%84%D8%AF%D8%A7%D8%A6%D9%85.md
- Report755: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report755_DAILY_CTO_RAWAEA_SECURITY_GATE_REVALIDATION_20261127.md
- Report753: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report753_DAILY_CTO_RAWAEA_P0_SECURITY_GATE_AND_ADVISOR_TRIAGE_20261125.md
- Operational HEAD: https://github.com/papamohammed77-glitch/erp-frontend/commit/095a344e20cafd768c88353c33ceecbc764a6cc4
- Governance HEAD before this report: https://github.com/papamohammed77-glitch/rawaie-erp-New/commit/2f29284e5fd1162b70b3f7e3da629ea7bc9c13d2

---
**الخلاصة التنفيذية:** P0 ليس مجرد تحذير ACL؛ إنه مسار تصعيد صلاحيات عبر جدول يشارك في 19 RLS policy. الحالة الحية تؤكد أن المنح والسياسة ما زالت مفتوحة. لم يُنفذ أي تغيير لأن الموافقة المحددة غير موجودة. الأولوية الوحيدة التالية هي اعتماد أو رفض CS-748-P0-A بالنص أعلاه.
