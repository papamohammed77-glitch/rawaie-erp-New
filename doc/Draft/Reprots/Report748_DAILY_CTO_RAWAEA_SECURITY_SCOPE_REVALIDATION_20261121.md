
# Report748 — المراجعة اليومية لـ RAWAEA ERP: إعادة تحقق P0 للصلاحيات وفصل نطاق الجرد المستقل

**LVE:** LVE-2026-11-21-748  
**التاريخ:** 2026-11-21 (Africa/Cairo)  
**الدور:** CTO / Lead Engineer / Enterprise Architect / Operational Excellence Auditor  
**الحكم:** READY WITH LIMITATIONS للفحص القرائي والتوثيق؛ BLOCKED لأي تغيير Production أو نشر أو اختبار كتابي إلى حين اعتماد Change Set المحدد.

---

## 1. نقطة البداية والاستئناف

- Governance repository: papamohammed77-glitch/rawaie-erp-New، الفرع main.
- CURRENT_STATE قبل هذا التحديث: SHA 658ccc5a0af3bf7edc600f8822320fa4da1e7e89، 2,615 سطرًا. الملف تراكمي؛ بدايته ما زالت تعرض LVE733، لكن أحدث حدث مثبت في ذيله هو LVE-2026-11-20-747.
- Permanent Constitution: SHA 3a6b1e220af8509e314e94df76563bbc6f84910d، 310 أسطر، قُرئ كاملًا.
- Report747: blob b3e95532d3eb08ee48d56f8aa4d46049f4a645bf، commit 4d36499c44ee592c63dd4e4d6681b5707f17ed56.
- Operational repository: papamohammed77-glitch/erp-frontend، الفرع main، HEAD الحالي 095a344e20cafd768c88353c33ceecbc764a6cc4.
- أحدث code checkpoint قبل commit التوثيق: b48e384319436e22a2464b6d3749c3e0069f7b14. المقارنة بينهما: commit واحد فقط، ملف واحد فقط، وهو companies/company-2/Counting/CURRENT_STATE.md (+70 سطرًا)، ولا تغيير في companies/company-1.
- RAWAEA company-1 source baseline الذي أعيد فحصه: main.html blob 00456494de918b36fc6792bef302319a9f65605d، core.js blob 2b2211a3f95049042e27a7b2ecbab3640a584942.
- Supabase SMART ERP fiilmooggumokxanwiyx: ACTIVE_HEALTHY؛ سجل migrations الحي 800، وآخر migration مسجل 20261119010201.
- الهدف التنفيذي الحالي: احتواء الوصول المباشر إلى public.role_permissions في SMART ERP مع الحفاظ على مسار الصلاحيات المركزي، دون تغيير أي مستخدم أو دور أو أثر أعمال.

## 2. حد النطاق بين المشروعين — قرار مالك ملزم

- تطبيق الجرد المستقل CountFlow ليس جزءًا من RAWAEA ERP، ولا تُدمج خططه أو قواعده أو حساباته أو تقاريره أو بياناته مع RAWAEA.
- مسارات companies/company-2/Counting وملفات New-Project وبيئة rawaea-staging خارج نطاق مراجعة RAWAEA في هذا التقرير. لم تُنفذ عليها استعلامات أو تغييرات اليوم.
- RAWAEA يحتفظ بتطبيق الجرد الخاص به وتبويبات الجرد/Inventory Control في النظام الأم، ضمن companies/company-1. لا يجوز اعتبار Counter أو Inventory Control داخل RAWAEA هو CountFlow، ولا العكس.
- المقارنة الحية بين b48e384 و095a344 تثبت أن التغيير الأخير في مستودع التشغيل كان في CURRENT_STATE الخاص بـcompany-2/Counting فقط؛ لا يثبت ذلك اكتمال الفصل التقني الكامل بين المشروعين. حالة اكتمال الفصل نفسها تبقى UNVERIFIED حتى فحص مستقل في مسار CountFlow.
- أحدث Governance HEAD قبل هذا التقرير هو fde7bf7cb2426a8bb5baa4e07232ed2df4a36439، وتغييره الأخير في مسار New-Project/P1 المنفصل؛ لم يُعامل كجزء من RAWAEA.

## 3. CONFIRMED — فجوة P0 في SMART ERP / role_permissions

الفحص المباشر لكتالوج PostgreSQL وACL وRLS والسياسات والدوال الحية أكد:

- public.role_permissions: RLS=true، FORCE RLS=false، المالك postgres.
- سياسة واحدة باسم Allow all for all، command=ALL، roles=PUBLIC، وUSING=true وWITH CHECK=true.
- ACL الفعلي:
  {postgres=arwdDxtm/postgres,anon=arwdxtm/postgres,authenticated=arwdxtm/postgres,service_role=arwdDxtm/postgres}
- anon وauthenticated يملكان فعليًا SELECT/INSERT/UPDATE/DELETE وTRIGGER وREFERENCES وMAINTAIN. لا يملكان TRUNCATE؛ لا يوجد الحرف D الخاص بها في ACL هذين الدورين، كما أن has_table_privilege أعاد false لـTRUNCATE.
- عدد الصفوف 21، موزعة على 3 role_id؛ لكل role_id مستخدم نشط واحد حاليًا. عدد صفوف permission_key='*' حاليًا صفر.
- الأعمدة: id UUID، role_id UUID، permission_key varchar. يوجد FK من role_id إلى roles(id) مع ON DELETE CASCADE، وUnique على (role_id, permission_key).
- لا يوجد Trigger تدقيق على الجدول.
- get_my_effective_profile() دالة SQL STABLE SECURITY DEFINER، مالكها postgres، وsearch_path فارغ ومثبت. تتحقق من auth.uid() وتربط users.auth_id بالهوية الحالية، ثم تدمج permissions من users وroles وrole_permissions حسب role_id.
- app_private.current_user_has_effective_permission(text) تقرأ get_my_effective_profile() وتقبل إما المفتاح المطلوب أو '*' ضمن permissions الفعالة. لذلك كتابة permission_key على أحد الأدوار الثلاثة الحالية يمكن أن تغيّر صلاحيات المستخدم النشط المرتبط به عند قراءة ملفه الفعال. هذا مسار تصعيد صلاحيات مثبت بنيويًا؛ لم يُنفذ استغلال.
- لا تتحول هوية المستخدم إلى Owner لمجرد role_permissions؛ شرط isOwner في get_my_effective_profile منفصل ويحتاج metadata isOwner=true وusers.permissions تحتوي '*' ووجود owner_profile مربوط بـauth.uid().
- الدوال الثماني التي تقرأ role_permissions كلها SECURITY DEFINER ومالكها postgres:
  1. delete_order_atomic(uuid,text,text)
  2. get_my_effective_profile()
  3. get_warehouse_hub_snapshot()
  4. receive_purchase_atomic(uuid,text,text,jsonb,uuid)
  5. receive_quick_market_invoice_atomic(uuid,uuid,text,jsonb,uuid)
  6. save_supplier_atomic(uuid,uuid,text,jsonb,boolean,text)
  7. save_system_settings_atomic(uuid,uuid,text,boolean,jsonb)
  8. update_order_atomic(uuid,text,text,jsonb,jsonb,text,uuid)
- صلاحيات EXECUTE: anon=false على الدوال الثماني؛ authenticated=true فقط لـget_my_effective_profile وget_warehouse_hub_snapshot؛ الدوال الست الأخرى service_role-only. لم تتغير أي صلاحية أو دالة.
- التصنيف: P0 — anonymous/authenticated direct permission-table write path دون قيد شركة أو سجل تدقيق على الجدول.

## 4. تدقيق المستهلكين — توسيع ما فحصه Report747

تم فحص 35 ملف كود داخل companies/company-1 و31 ملفًا داخل supabase/functions، مع جلب Parent main.html كاملًا عبر Git blob API وفحص Core والملفات التشغيلية ذات الصلة:

- لم يظهر direct PostgREST access إلى role_permissions في Parent main.html أو core.js أو ملفات تطبيقات company-1. في main.html يوجد ظهور نصي واحد فقط في audit action label باسم role_permissions_sync عند السطر 9484، وليس استعلام جدول.
- Core يستخدم مسار get_my_effective_profile RPC، وليس قراءة الجدول مباشرة.
- وُجدت قراءات مباشرة للجدول داخل helper supabase/functions/_shared/warehouse-auth.ts وداخل report-discrepancy/index.ts.
- helper warehouse-auth.ts مستخدم من 12 Edge Functions: cancel-loading، cancel-picking، cancel-return، complete-loading، complete-picking، complete-return، reopen-loading، reopen-picking، start-loading، start-picking، start-return، unload-runsheet. جميع هذه المستهلكات تنشئ عميل service_role وتستدعي helper به؛ قراءة الجدول لا تعتمد على anon/authenticated ACL.
- report-discrepancy v4 يقرأ role_permissions عبر عميل service_role.
- bulk-stock-adjustment وreceive-purchase وsave-purchase-order وsave-inventory-count تعتمد على get_my_effective_profile RPC مع JWT، ولا تنفذ direct table read. دالة SECURITY DEFINER المملوكة postgres تحافظ على قراءة role_permissions بعد حجب الوصول المباشر.
- save-role v9 الحي لا يكتب role_permissions مباشرة؛ يستخدم users/roles/audit_log. save-category v6 يتعامل مع categories. كلاهما ACTIVE وverify_jwt=true.
- save-role وsave-category غير موجودين كملفين مطابقين داخل شجرة operational Git الحالية؛ تم جلب نسختيهما الحيتين من Supabase، لكن source lineage داخل Git غير مثبت. لا يُستبدل أي منهما بمصدر قديم أو غير موجود.
- النتيجة: direct table reads الموجودة في Edge تستخدم service_role، ولا تمنع ChangeSet المقترح من حجب anon/authenticated. هذا استنتاج من فحص المستهلكين الحاليين، وليس اختبارًا بعد التغيير.

## 5. Change Set المقترح — CS-748-P0-A (غير منفذ)

المستودع/البيئة: Supabase SMART ERP، project ref fiilmooggumokxanwiyx.  
الهدف: إغلاق الوصول المباشر إلى public.role_permissions عن anon وauthenticated وإزالة سياسة PUBLIC ALL، مع الحفاظ على الوظائف المركزية الحالية.

النص المقترح، بعد موافقة المالك الصريحة فقط:

    BEGIN;
    REVOKE ALL ON TABLE public.role_permissions FROM anon, authenticated;
    DROP POLICY IF EXISTS "Allow all for all" ON public.role_permissions;
    COMMIT;

ما لن يتغير:
- لا تعديل أو حذف لأي صف في role_permissions أو roles أو users.
- لا تغيير لمالك الجدول أو schema أو FK/Unique constraints.
- لا تغيير لصلاحيات service_role أو postgres.
- لا تغيير لـget_my_effective_profile أو get_warehouse_hub_snapshot أو أي RPC/Edge Function.
- لا تغيير لـmain.html أو core.js أو التطبيقات التشغيلية أو جلسات المستخدمين.
- لا إنشاء RLS policy جديدة؛ المستهلكون المباشرون الحاليون الذين تم العثور عليهم يستخدمون service_role، ومسار العميل يستخدم SECURITY DEFINER RPC.

اختبارات القبول بعد الاعتماد:
1. has_table_privilege لـanon وauthenticated = false على SELECT/INSERT/UPDATE/DELETE/TRIGGER/REFERENCES/MAINTAIN/TRUNCATE.
2. عدم وجود سياسة PUBLIC ALL على role_permissions.
3. بقاء service_role قادرًا على الوصول وفق ACL القائم.
4. بقاء EXECUTE لـauthenticated على get_my_effective_profile وget_warehouse_hub_snapshot، وanon=false.
5. اختبار قراءة ملف مستخدم مصادق عليه عبر سياق مصادق متاح، دون تعديل صلاحيات أو مستخدمين؛ ومقارنة المفاتيح الفعالة قبل/بعد.
6. التحقق من أن Edge helper/report-discrepancy ما زالا يستخدمان service_role في المصدر المنشور.
7. إعادة عدّ role_permissions وroles/users ذات الصلة؛ يجب أن تبقى 21 صفًا و3 أدوار دون تغيير.
8. لا اختبار exploit، ولا INSERT/UPDATE تجريبي، ولا تغيير لأي رصيد أو مستند أو حركة.
9. إذا لم تتوفر جلسة مصادق عليها، يبقى اختبار سلوك المستخدم UNVERIFIED ولا يُستبدل بمحاكاة على أنها Runtime.

التراجع:
- لا تعاد grants إلى anon/authenticated ولا تعاد سياسة PUBLIC ALL.
- إذا ظهر consumer مباشر غير معروف، يوقف المسار المتأثر ويُحل عبر RPC قائم أو تصميم SELECT ضيق مع RLS/GRANT منفصل وبعد مراجعة اعتماديات وموافقة جديدة.
- لا تستخدم إعادة فتح الوصول العام كـrollback.

**حالة الموافقة:** غير موجودة لهذا النص المحدد. لا تنفيذ.

## 6. P1 — categories

- public.categories: RLS=true، وسياسة Allow all for all من نوع ALL لـPUBLIC مع USING/WITH CHECK=true.
- anon وauthenticated يملكان CRUD وTRIGGER وREFERENCES وMAINTAIN؛ TRUNCATE=false.
- Parent main.html يقرأ categories مباشرة في المواضع 5760 و5807 و6013 و6145، مع company_id filter في الاستعلام. هذا الفلتر داخل العميل لا يحل محل RLS ولا يمنع عميلًا آخر من حذف الفلتر.
- save-category v6 ACTIVE وverify_jwt=true هو مسار الكتابة التشغيلي الذي فُحص؛ لا يبرر ذلك منح anon direct DML.
- التصنيف P1: تجاوز عزل الشركة/إفساد Master Data. يحتاج Change Set مستقل لحصر كل مستهلكي القراءة ثم سياسة قراءة tenant-scoped والكتابة عبر المسار المركزي. لم يُنفذ أي تغيير.

## 7. Security Advisor — إشارات تحتاج فرزًا لا تعميمًا

نتيجة Supabase Security Advisor الحية:
- 24 جدولًا RLS enabled بلا policy؛ مستوى INFO، ويعني default deny ما لم يوجد مسار آخر.
- View واحدة SECURITY DEFINER: public.v_finance_employee_directory؛ مستوى ERROR في اللنتر، لكن لم يثبت في هذا الفحص مسار anon مباشر.
- أربع دوال SECURITY DEFINER قابلة للتنفيذ من anon بحسب اللنتر: enforce_supplier_return_receiver، get_public_store_catalog، get_public_store_order_tracking، sync_supplier_return_buyer_custody_event. اثنتان trigger functions؛ واثنتان public read endpoints تحتاجان مراجعة حدود البيانات ومقاومة التخمين.
- 142 تحذيرًا لدوال SECURITY DEFINER قابلة للتنفيذ من authenticated؛ العدد ليس 142 ثغرة مثبتة. يلزم فحص function-by-function للهوية والصلاحية والنطاق والـsearch_path.
- Leaked Password Protection معطل؛ P2 hardening review.
- لا تغيير في Auth أو أي function/view/ACL بسبب هذه النتائج.

## 8. RAWAEA Inventory — تأكيد الفصل عن CountFlow

- Parent main.html الحالي يتضمن view inventory-control، ويحتوي على مسارات vehicle-count وbranch-count وgeneral-count، كما أن Warehouse/Counter جزء من company-1.
- GitHub Actions run 44805844091 على commit 095a344 نجح في inventory static contract وMother browser smoke.
- سجل الاختبار يثبت أن Supabase كان mock بالكامل: getSession=null وgetUser=null، واستعلامات from ترجع [] وRPC يرجع null، ولا يوجد outbound Supabase. تحقق الاختبار من عنوان الصفحة ووجود body، لا من تنفيذ جرد أو صلاحية مستخدم أو ترحيل فروقات.
- النتيجة: وجود واجهات ومسارات الجرد في RAWAEA CONFIRMED من المصدر؛ نجاح دورة الجرد الفعلية أو جودة تجربة المستخدم أو الأثر المالي/المخزني UNVERIFIED.
- لا تُحسب هذه الاختبارات على أنها CountFlow E2E، ولا تُستخدم نتائج CountFlow لتقييم RAWAEA.

## 9. مصفوفة التحقق حسب الطبقة

| الطبقة | نتيجة اليوم |
|---|---|
| GitHub Source | CONFIRMED: main/core SHAs؛ لا تغييرات company-1 منذ checkpoint المقارن |
| Supabase Production | CONFIRMED: SMART ERP ACTIVE_HEALTHY، 800 migrations، role_permissions/categories ACL/RLS/function contracts |
| Deployed Edge | CONFIRMED: save-role v9 وsave-category v6 ACTIVE/JWT؛ لم يُثبت byte parity مع Git لأن المصدر غير متتبع هناك |
| Cloudflare Artifact | UNKNOWN — لم نحصل على deployment pointer أو bytes |
| Runtime / Authenticated Browser | UNVERIFIED — لا جلسة مصادق عليها ولا DOM/Network حي |
| CI | CONFIRMED: run 44805844091 نجح، لكنه static + anonymous mocked shell smoke فقط |
| Business-data effects | CONFIRMED: لا DML/DDL/RPC تشغيلي أو Edge invocation أو حركة أعمال نفذت اليوم |
| Staging | خارج نطاق RAWAEA في هذا التقرير؛ لم يُفحص أو يُكتب |

## 10. ما تم فعليًا

1. قراءة CURRENT_STATE كاملًا، ثم الدستور كاملًا بالترتيب الإلزامي.
2. مراجعة Report747 وReport735 في الأجزاء المرتبطة بالصلاحيات وموثوقية الادعاءات.
3. التحقق من Governance/Operational branch وHEAD وcommit diff منذ checkpoint.
4. إعادة جلب main.html blob كاملًا وcore.js، ومسح 35 ملف تطبيق و31 ملف Edge/shared بحثًا عن direct role_permissions access وprofile consumers.
5. فحص Supabase project health، migration ledger، role_permissions/categories schema/ACL/RLS/policies/triggers، function definitions/owners/execute grants، وSecurity Advisor.
6. فحص نسخ Edge الحية save-role v9 وsave-category v6، ومستهلكي warehouse-auth/report-discrepancy.
7. فحص run 44805844091 وقراءة log الخاص به لتحديد نوع الاختبار الحقيقي.
8. لم يتم أي تغيير تشغيلي أو Production write.

## 11. ما لم يتم ولماذا

- لم ينفذ CS-748-P0-A لأن الموافقة الصريحة على SQL المحدد غير موجودة.
- لم تُنفذ اختبارات كتابة أو استغلال؛ ممنوعة قبل الموافقة، كما أن اختبار تغيير permission rows غير مطلوب لإثبات الخطر.
- لم يتم Cloudflare artifact/runtime لأن الأدلة المباشرة غير متاحة في هذا التشغيل.
- لم تُنفذ authenticated Browser E2E لعدم وجود جلسة مصادق عليها.
- لم تتم مراجعة جميع تطبيقات RAWAEA وظيفيًا؛ نطاق اليوم محدد للصلاحيات والجرد/النطاق.
- لم يُنفذ Benchmark رسمي حديث؛ أولوية هذه الدورة P0 security containment.
- لم تُقَس Realtime event delivery أو reconnect أو latency.
- لم تُنشأ Staging أو فرع أو مشروع أو Edge Function.

## 12. صحة التطبيقات والتغطية

| النطاق | التغطية |
|---|---|
| Parent main.html | جلب كامل للـblob + مسح الصلاحيات/categories/inventory routes؛ لم تُراجع كل الوظائف |
| core.js | جلب وفحص profile path؛ لم تُراجع كل وحداته |
| company-1 apps | 35 ملف كود ضمن مسح role_permissions؛ ليس قبولًا وظيفيًا لكل تطبيق |
| Supabase Edge | 31 ملفًا ضمن مسح consumers؛ 12 helper callers + report-discrepancy تحققوا من service_role |
| Supabase SQL functions | 8 functions المستهلكة لـrole_permissions فُحصت من live catalog |
| categories | Parent direct-read paths + save-category live version |
| Warehouse/Counter/Inventory Control | وجود مسارات مصدر واختبار mocked؛ لا authenticated operation |
| Buyer/Finance/Sales/Delivery/POS | لم تُفتح وظيفيًا اليوم؛ لا diff في company-1 يفرض إعادة فحصها |
| CountFlow/rawea-staging | مستبعدان من RAWAEA؛ لا فحص أو كتابة اليوم |

## 13. تدقيق موثوقية التقارير السابقة

### Report747
- صحيح: PUBLIC ALL policy، anon/authenticated CRUD على role_permissions، 21 صفًا، 3 roles، عدم وجود audit trigger، 8 SECURITY DEFINER consumers، get_my_effective_profile مربوط بـauth.uid.
- صحيح: main.html/core.js/save-role لا تنفذ direct role_permissions access.
- توسيع اليوم: يوجد direct read في warehouse-auth.ts وreport-discrepancy، لكن جميع المستهلكين الحاليين يستخدمون service_role؛ لذلك لا يبطل ChangeSet revoke المقترح.
- تصحيح TRUNCATE: ACL الحي وhas_table_privilege يؤكدان عدم وجود TRUNCATE لـanon/authenticated. تقرير735 بالغ في هذه النقطة، وReport747 صححها؛ إعادة الفحص اليوم تؤكد التصحيح.
- categories P1 صحيح؛ تعارض P1/P2 الداخلي في Report735 لا يُنقل.
- بيانات rawaea-staging وCountFlow الواردة في Report747 لا تدخل في تقييم RAWAEA الحالي وفق فصل نطاق المالك.

### Report735
- P0 role_permissions الأساسي صحيح.
- وصف TRUNCATE على SMART role_permissions/categories غير صحيح؛ لا يوجد privilege حاليًا لـanon/authenticated.
- categories: التصنيف الصحيح P1 في ضوء direct anonymous CRUD، لا P2.
- بقية ادعاءات CountFlow/rawea-staging ليست موضوع إعادة تحقق في هذا التقرير ولا تُعامل كحالة RAWAEA.

## 14. الأخطاء والفجوات والأولوية

| الأولوية | الفجوة | الدليل | الإجراء |
|---|---|---|---|
| P0 | Direct access إلى role_permissions | PUBLIC ALL + anon/auth CRUD + active roles + effective permission consumer | CS-748-P0-A، انتظار موافقة |
| P1 | categories public CRUD | PUBLIC ALL + anon/auth DML + Parent direct reads | Change Set مستقل بعد consumer map |
| P2 | source lineage لـsave-role/save-category | Edge live موجود، matching Git path غير موجود | استعادة المصدر الحي إلى Git بعد مراجعة المالك، دون redeploy |
| P2 | Security Definer view/anon functions/Auth hardening | Advisor findings | function/view-specific review، لا تغيير جماعي |
| P2 | Current State header stale | رأس الملف يعرض LVE733 والحدث الأحدث في الذيل LVE747 | الاستمرار بإلحاق الأحداث وعدم محو التاريخ؛ يمكن تحسين header لاحقًا |

لا توجد إصلاحات تشغيلية منفذة اليوم؛ كل فجوة أعلاه ما زالت OPEN حتى تحقق معيار إغلاقها.

## 15. الكفاءة التشغيلية وسيناريوهات الأعمال

- Supplier → PO → receiving → stock/AP/ledger: العقود المركزية موجودة تاريخيًا، لكن لم يُختبر مسار جديد اليوم.
- Warehouse → picking reservation → loading movement → unloading movement → delivery/return: وجود الوحدات ومساراتها مثبت في المصدر التاريخي والحالي جزئيًا؛ لا E2E مصادق عليه اليوم.
- Inventory count: Parent Inventory Control وvehicle/branch/general count routes موجودة؛ finalization/adjustment effects لم تُختبر اليوم.
- Custody/Treasury/Finance: لم تُنفذ أي عملية أو مصالحة جديدة.
- لا زمن دورة أو معدل نجاح من أول محاولة أو تكلفة أو فاقد مقاس في هذا التشغيل.

## 16. التخطيط والتنبؤ

UNKNOWN في هذه الدورة. لا قياس جديد لدقة الطلب أو safety stock أو stockout/expiry forecasts أو cash forecast. لا تُمنح Dashboard أو schema درجة ذكاء تنبؤي.

## 17. المقارنة التنافسية

لم يُنفذ Benchmark رسمي اليوم مع SAP S/4HANA/Business One أو Dynamics 365 أو Odoo أو ERPNext أو Daftra أو Manager.io. لا توجد مقارنة متكافئة أو ادعاء تفوق/تكافؤ. يبقى هذا العمل مفتوحًا بعد احتواء P0.

## 18. مصفوفة النضج الاثني عشر

| المجال | التقييم | الثقة/السبب |
|---|---|---|
| السلامة التقنية والمعمارية | UNKNOWN | لم يُراجع النظام كله؛ P0 قائم |
| تكامل التطبيقات والبيانات | UNKNOWN | لا cross-app E2E جديد |
| العمليات التجارية | UNKNOWN | لا اختبار ميداني |
| الرقابة المالية والمحاسبية | UNKNOWN | لا posting/reconciliation test |
| المخزون وسلاسل الإمداد | UNKNOWN | وجود عقود لا يثبت التشغيل |
| التوزيع والعمل الميداني | UNKNOWN | لا جلسات أجهزة حقيقية |
| التخطيط والتنبؤ | UNKNOWN | لا accuracy metrics |
| التقارير وBI | UNKNOWN | لا export فعلي أو تحقق بيانات |
| الأمان والصلاحيات والتدقيق | 1/5 في النطاق المفحوص | توجد هوية/RPC/SECURITY DEFINER، لكن direct P0 مفتوح ولا audit trigger على role_permissions |
| الأداء والاستقرار والتوسع | UNKNOWN | لا load/latency measurements |
| تجربة المستخدم والإنتاجية | UNKNOWN | لا task timing أو usability test |
| الجاهزية التشغيلية والتنافسية | UNKNOWN | لا artifact/runtime/competitive benchmark |

لا مقارنة رقمية مع تقييمات سابقة لأن المقام والنطاق غير متطابقين.

## 19. خريطة Parent/Core والمصدر المركزي

- Parent: companies/company-1/main.html، blob 00456494de918b36fc6792bef302319a9f65605d، جُلب كاملًا.
- Core: companies/company-1/core.js، blob 2b2211a3f95049042e27a7b2ecbab3640a584942.
- Parent يستخدم get_my_effective_profile في مسار الهوية/الصلاحيات؛ لم يُثبت اليوم توحيد جميع Auth abstractions أو كل التطبيقات على Core واحد.
- Parent يقرأ categories مباشرة، ويملك inventory-control/vehicle-count/branch-count/general-count routes.
- لا تغيير في Parent/Core أو Router/Boot/Auth اليوم. لا إعادة هيكلة مقترحة ضمن CS-748-P0-A.

## 20. مصفوفة المزامنة

| الكيان/المسار | ما ثبت | ما لم يثبت |
|---|---|---|
| Effective permissions | profile RPC يقرأ role_permissions ويحسب permissions الفعالة | لا اختبار بعد revoke |
| Warehouse helper | 12 Edge consumers تستخدم service_role | cross-device runtime غير مطلوب لهذا التغيير |
| Parent inventory | route/subscription references موجودة في المصدر | event delivery وlatency/reconnect |
| categories | direct reads من Parent | تحديث UI بعد تعديل category في جلسة أخرى |
| عامة المنظومة | Supabase Realtime موجود في بعض الوحدات تاريخيًا | لا ادعاء بمزامنة لحظية مثبتة اليوم |

## 21. جودة الاختبارات

- GitHub run 44805844091: PASS لstatic inventory contract وanonymous Mother browser smoke.
- Browser smoke استخدم Supabase mock كاملًا؛ auth session/user = null، queries فارغة، RPC null، ولا outbound network.
- لا authenticated RLS test، ولا inventory transaction، ولا business-data effects.
- لا Production QA fixtures، ولا cleanup؛ لم تُنشأ أي بيانات.
- لذلك الاختبار ليس Browser E2E تجاريًا ولا authenticated Runtime.

## 22. تجربة المنتج واكتمال الواجهة

- RAWAEA Parent inventory routes موجودة في المصدر، لكن لا دليل اليوم على أن أمين المخزن أو مدير الفرع أكمل رحلة الجرد من فتح الجلسة إلى العد والمراجعة والاعتماد والتسوية.
- لا فحص responsive فعلي أو RTL/device accessibility أو barcode/camera أو keyboard navigation أو empty/error/retry states في هذا التشغيل.
- لا أرقام لعدد النقرات أو زمن المهمة أو معدل الإكمال.
- كل هذه البنود UNVERIFIED، ولا يعلن اكتمال وحدة الجرد من وجود tabs أو workflow static test.

## 23. الالتزام بالدستور

- CURRENT_STATE قُرئ كاملًا قبل الدستور.
- الدستور قُرئ كاملًا بعده؛ SHA 3a6b1e220af8509e314e94df76563bbc6f84910d.
- §6.2 و§7 وبوابات المالك مطبقة؛ لم يُنفذ أي DDL/ACL/RLS/Edge deploy أو تعديل تطبيق.
- §6.4 التاريخي يسمح Fixtures مؤقتة على Production، لكن توجيه المالك الأحدث في هذا البروتوكول يمنع أي حركات QA دائمة ويمنع تغيير أرصدة الأعمال الحقيقية؛ لم تُنشأ أي Fixture.
- فصل CountFlow عن RAWAEA عومل كحد نطاق صريح؛ لا تُنقل نتائجه إلى حالة RAWAEA.

## 24. المخاطر والقرارات التي تحتاج المالك

1. موافقة صريحة على CS-748-P0-A بالنص الكامل في §5.
2. Change Set منفصل لـcategories بعد تثبيت جميع مستهلكي القراءة والكتابة.
3. خطة استعادة source lineage لـsave-role/save-category دون استبدال النسخ الحية.
4. إتاحة جلسة مصادق عليها/طريقة Browser runtime عند الحاجة لاختبارات UI؛ ليست شرطًا لتنفيذ revoke نفسه.
5. لا قرار تجاري جديد مطلوب اليوم؛ لا حاجة لسؤال المالك عن معلومات موجودة في المصدر.

## 25. الحكم على الجاهزية والخطوة التالية

**READY WITH LIMITATIONS** للقراءة والتوثيق وإعداد Change Set.  
**BLOCKED** لأي كتابة Production أو نشر أو اختبار يغير بيانات حتى موافقة المالك على التغيير المحدد.

الخطوة التالية الوحيدة ذات الأولوية: اعتماد CS-748-P0-A، ثم تنفيذ REVOKE/DROP POLICY والتحقق من privileges وprofile RPC دون أي تغيير في بيانات الأعمال. لا تبدأ categories أو إعادة هيكلة Parent/Core قبل إغلاق P0 وتوثيق النتيجة.

---

## سجل الأدلة والروابط

- CURRENT_STATE: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
- Permanent Constitution: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/%D8%A7%D9%84%D8%AF%D8%B3%D8%AA%D9%88%D8%B1%20%D8%A7%D9%84%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%D9%8A%20%D8%A7%D9%84%D8%AF%D8%A7%D8%A6%D9%85.md
- Report747: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report747_DAILY_CTO_SECURITY_COUNTFLOW_PRODUCT_ACCEPTANCE_20261120.md
- Operational commit 095a344: https://github.com/papamohammed77-glitch/erp-frontend/commit/095a344e20cafd768c88353c33ceecbc764a6cc4
- Inventory forensic workflow run 44805844091: https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/44805844091

**Final status:** P0 permission-table exposure CONFIRMED / CS-748-P0-A PREPARED BUT NOT APPROVED OR APPLIED / categories P1 OPEN / CountFlow excluded from RAWAEA scope / no Production writes or business-data effects / Runtime and Cloudflare artifact UNVERIFIED.
