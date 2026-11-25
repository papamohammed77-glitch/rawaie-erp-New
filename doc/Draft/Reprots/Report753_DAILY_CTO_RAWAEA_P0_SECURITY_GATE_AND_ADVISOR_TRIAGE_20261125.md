# Report753 — RAWAEA ERP Daily CTO Review: P0 Permission Gate, Default ACL and Security Advisor Triage

**LVE:** LVE-2026-11-25-753  
**Date:** 2026-11-25 (Africa/Cairo)  
**Scope:** RAWAEA ERP / company-1 only؛ daily continuation from LVE-2026-11-24-752  
**Readiness:** READY WITH LIMITATIONS للقراءة والتوثيق؛ BLOCKED لتطبيق CS-748-P0-A حتى ثبوت اعتماد المالك المحدد  
**Execution mode:** قراءة GitHub وSupabase catalog/SQL فقط؛ لا تغييرات تشغيلية أو Production writes

---

## 1. نقطة البداية والاستئناف

- جُلب `CURRENT_STATE.md` كاملًا أولًا من `papamohammed77-glitch/rawaie-erp-New/main`: **287,001 character / 2,791 lines / blob SHA `c9e1747ea79559eda32c4d6af946ad520b502dab`**.
- أُعيد بعده مباشرة جلب الدستور التشغيلي كاملًا: **310 lines / 19,916 characters / SHA `3a6b1e220af8509e314e94df76563bbc6f84910d`**.
- أحدث نقطة سابقة: **LVE-2026-11-24-752 / Report752**؛ Report752 قُرئ كاملًا (92 سطرًا، blob `98f1a56408c98c979c7f5d637bb273234721ea26`، commit `907472b828099b97e820b516c5c0ec7f4551b4ae`).
- تمت مراجعة Report751 وReport749 وReport748 في نطاق بوابة الصلاحيات وموثوقية الادعاءات. لم تُستخدم تقارير CountFlow لإثبات حالة RAWAEA.
- Governance repository: branch `main`؛ أحدث commit مرصود `afca741e40da92c27766077d484f8af536f95ec7`، وتغييره `CURRENT_STATE.md` فقط.
- Operational repository: `papamohammed77-glitch/erp-frontend`، branch `main`، HEAD `095a344e20cafd768c88353c33ceecbc764a6cc4`.
- المقارنة من `b48e384319436e22a2464b6d3749c3e0069f7b14` إلى HEAD الحالي: commit واحد، ملف واحد فقط `companies/company-2/Counting/CURRENT_STATE.md` (+70 سطرًا). لا تغيير في `companies/company-1`.
- Parent `main.html` blob الحالي `00456494de918b36fc6792bef302319a9f65605d`. جلب SHA نجح لكن محتوى الملف أعاد فارغًا حتى مع طلب جزء من السطور؛ لذلك لم تُدّعَ قراءة كاملة اليوم.
- `core.js` blob الحالي `2b2211a3f95049042e27a7b2ecbab3640a584942`؛ قُرئت الأسطر 1–8 للتحقق من الهوية فقط، لا مراجعة كاملة لوحداته.
- الهدف التنفيذي المستمر: احتواء الكتابة المباشرة إلى `public.role_permissions` مع المحافظة على قراءة الصلاحيات المركزية، دون لمس بيانات الأعمال.

## 2. CONFIRMED

### 2.1 GitHub / Source

- Operational `main` HEAD ثابت عند `095a344e20cafd768c88353c33ceecbc764a6cc4`.
- آخر commit في النطاق المقارن يغيّر ملف توثيق CountFlow تحت `company-2` فقط؛ لا يوجد diff جديد في تطبيقات RAWAEA `company-1`.
- Parent/Core SHAs أعلاه متطابقة مع baseline السابق؛ هذا لا يثبت سلامة كل الوظائف، بل يثبت عدم ظهور تغيير مصدر جديد يفرض إعادة فتحها اليوم.

### 2.2 Supabase Production

- المشروع `SMART ERP`، ref `fiilmooggumokxanwiyx`، الحالة `ACTIVE_HEALTHY`، PostgreSQL `17.6.1.121`.
- Migration ledger: **800 migrations**؛ أحدث إصدار `20261119010201` باسم `quick_market_supplier_credit_receiving_trigger_guard`.
- SQL catalog/ACL observation عند **2026-11-25 20:42:04.972972 UTC** (22:42:04 Africa/Cairo).
- جميع الاستعلامات في هذه المراجعة SELECT/catalog reads؛ لم يُنفذ DDL أو DML أو RPC أعمال.

### 2.3 P0 — `public.role_permissions`

الكتالوج الحي أعاد إثبات:

| الخاصية | النتيجة |
|---|---|
| RLS | enabled = true |
| FORCE RLS | false |
| Policies | واحدة: `Allow all for all` |
| Policy roles | PUBLIC |
| USING / WITH CHECK | true / true |
| Rows | 21 |
| Distinct role_id | 3 |
| `permission_key='*'` rows | 0 |
| User triggers | 0 |

الـACL الفعلي للجدول يحتوي منحًا صريحة لـ`anon` و`authenticated` على SELECT/INSERT/UPDATE/DELETE/REFERENCES/TRIGGER/MAINTAIN. لا توجد لهما صلاحية TRUNCATE على هذا الجدول. `service_role` يحتفظ بمنح الكتابة وTRUNCATE.

**تمييز مهم:** لا يوجد grantee باسم PUBLIC في `relacl` الحالي للجدول؛ المنح المباشرة لـanon/authenticated صريحة، بينما سياسة RLS نفسها مطبقة على PUBLIC. لذلك لا يجوز خلط ACL بالـRLS policy.

الـACL الفعلي:
- anon: SELECT/INSERT/UPDATE/DELETE/REFERENCES/TRIGGER/MAINTAIN = true؛ TRUNCATE = false.
- authenticated: القيم نفسها.
- service_role: يحتفظ بالوصول التشغيلي الممنوح، بما فيه TRUNCATE.

النتيجة: **P0 CONFIRMED / OPEN**. اجتماع direct DML grants مع PUBLIC ALL policy يسمح بنقطة كتابة مباشرة إلى جدول يغذي صلاحيات المستخدمين الفعالة. لم يُنفذ exploit أو أي كتابة لإثبات ذلك.

### 2.4 مسار الصلاحيات المركزي

إعادة قراءة تعريفات Production أثبتت:

- `public.get_my_effective_profile()`: SECURITY DEFINER، owner=`postgres`، `search_path=''`، EXECUTE لـauthenticated=true وanon=false. يربط المستخدم الحالي بـ`auth.uid()` ثم يدمج صلاحيات المستخدم والدور و`role_permissions`.
- `app_private.current_user_has_effective_permission(text)`: SECURITY DEFINER، owner=`postgres`، `search_path=''`، EXECUTE لـauthenticated=true وanon=false؛ يتحقق من `auth.uid()` ويعتمد على profile permissions.
- `app_private.current_user_company_id()`: SECURITY DEFINER، owner=`postgres`، `search_path=''`، EXECUTE لـauthenticated=true وanon=false؛ يربط `users.auth_id` بـ`auth.uid()` ويستبعد المستخدم غير النشط.
- `public.get_warehouse_hub_snapshot()`: SECURITY DEFINER، owner=`postgres`، `search_path=''`، EXECUTE لـauthenticated=true وanon=false.
- `FORCE RLS=false` على `role_permissions`، والدوال المركزية مملوكة postgres؛ لذلك لا يستلزم إغلاق وصول العميل المباشر حذف قراءة الصلاحيات المركزية. بقاء السلوك بعد التغيير يظل اختبار قبول مطلوبًا في جلسة مصادق عليها، ولم يُختبر اليوم.

### 2.5 P1 — Default ACL في public schema

فحص `pg_default_acl` كشف default table privileges للمالكين `supabase_admin` و`postgres` في schema `public` تمنح `anon` و`authenticated` مجموعة واسعة تشمل SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN.

- هذه default privileges تنطبق على الجداول المستقبلية التي ينشئها المالكان المعنيان ضمن النطاق المحدد، ما لم تُراجع/تُلغَ.
- لا تعني أن كل جدول حالي يحمل TRUNCATE؛ جدول `role_permissions` نفسه لا يمنح TRUNCATE لـanon/authenticated.
- هذه فجوة **P1 مستقلة** عن `CS-748-P0-A`. لا يُعدل default ACL ضمن Change Set الجدول الواحد، ولا يُجرى revoke جماعي دون جرد المنشئين والمستهلكين وخطة تغيير مستقلة.

### 2.6 P1 — `public.categories`

- RLS=true، FORCE RLS=false.
- Policy واحدة `Allow all for all` على PUBLIC مع USING/WITH CHECK=true.
- anon وauthenticated لديهما CRUD مباشر؛ TRUNCATE غير مثبت لهما في اللقطة السابقة/الحالية المتاحة.
- Parent direct reads موثقة تاريخيًا في Report749؛ لم تُعد قراءة كل مواضع Parent اليوم بسبب عدم وجود diff في company-1.
- التصنيف P1، وله Change Set مستقل بعد حصر المستهلكين؛ لا يضم إلى CS-748-P0-A.

## 3. UNKNOWN

- هل صدر اعتماد المالك لـCS-748-P0-A خارج سجل المشروع والمحادثات المتاحة: **UNKNOWN**. لا يوجد اعتماد موثق في CURRENT_STATE أو commits أو السياق المتاح؛ لذلك لا يُعامل التغيير على أنه معتمد.
- هل وصل HEAD الحالي إلى Cloudflare deployment: UNKNOWN.
- هل النسخة المنشورة مطابقة byte-for-byte للمصدر: UNKNOWN.
- هل profile RPC يعمل بعد سحب grants في جلسة مستخدم مصادق عليها: UNKNOWN، لأن التغيير لم يُطبق ولم تتوفر جلسة اختبار.
- مدى اكتمال كل رحلات UX والتشغيل الميداني وRealtime والتنبؤ: UNKNOWN.
- دقة التنبؤات أو مؤشرات الأداء وزمن إنجاز المهام: UNKNOWN.

## 4. CONFLICT

**بوابة بيئة الاختبار:** يوجد تعارض حوكمي بين دستور §6.4 الذي يحدد Production بوصفه بيئة التنفيذ الوحيدة ويسمح بآلية QA مؤقتة قابلة للتنظيف، وبين البروتوكول الحالي §19 الذي يطلب Staging/بيئة معزولة ويمنع اختبار بيانات Production الحقيقية، و§25.E الذي يمنع committed QA postings، و§25.F الذي يمنع إنشاء Staging أو مشروع/فرع جديد.

القاعدة الأكثر حماية المطبقة اليوم: لا اختبار كتابي لمسار أعمال مؤثر في Production، ولا إنشاء بيئة بديلة جديدة، ولا استخدام CountFlow staging لأنه مشروع مستقل خارج RAWAEA. تستمر القراءة فقط إلى أن تتوفر بيئة RAWAEA معزولة قائمة ومصرح بها أو يصدر حسم صريح لهذه البوابة. لا يؤثر هذا التعارض على استعلامات القراءة المنفذة اليوم.

## 5. UNVERIFIED

- Cloudflare artifact/deployment lineage والـbytes الفعلية.
- Authenticated Browser/DOM/Network/E2E.
- Cross-user/cross-device Realtime delivery وreconnect وlatency.
- رحلة `get_my_effective_profile` بعد تغيير ACL.
- الأداء والـmobile/responsive وUX field testing.
- اكتمال دورات procure-to-pay وorder-to-cash وwarehouse execution وinventory count وcustody settlement.
- Benchmark رسمي حديث مع SAP/Dynamics/Odoo/ERPNext/Daftra/Manager.io.
- لا يُدّعى READY أو COMPLETE أو GOLD أو COMPETITIVE.

## 6. مصفوفة التحقق حسب الطبقة

| الطبقة | ما فُحص | الحالة |
|---|---|---|
| GitHub Source | branch/HEAD/commit diff؛ Parent/Core blob identity | CONFIRMED جزئيًا |
| Supabase Production | project health، 800 migrations، RLS/ACL/policies، default ACL، profile functions، advisor | CONFIRMED ضمن النطاق |
| Deployed Edge | لا جلب جديد لنسخ Edge في هذه الجولة | UNKNOWN |
| Cloudflare Artifact | open/download لم ينجح | UNVERIFIED |
| Runtime / Authenticated E2E | Browser connector رفض لغياب originating browser context؛ لا جلسة مصادق عليها | UNVERIFIED |
| Business-data Effects | لم يحدث أي DML أو business RPC أو posting | CONFIRMED: لا أثر أدخله هذا الفحص |
| Staging | لم تُستخدم بيئة CountFlow ولم تُنشأ بيئة RAWAEA جديدة | غير مستخدمة |

## 7. ما تم فعليًا

1. قراءة CURRENT_STATE كاملًا ثم الدستور كاملًا بالترتيب الإلزامي.
2. قراءة Report752 وReport751 وReport749 وReport748 في نطاق بوابة الصلاحيات وموثوقية التقارير.
3. فحص branch/HEAD وcommit history ومقارنة operational commits منذ checkpoint السابق.
4. إعادة فحص SMART ERP health وmigration ledger.
5. إعادة فحص role_permissions RLS/policy/row count/ACL/effective privileges/direct ACL entries.
6. فحص default ACL للـpublic tables.
7. جلب تعريفات profile permission functions وcompany resolver وwarehouse hub snapshot grants.
8. جلب تعريف view `v_finance_employee_directory` وتبعياته وACL الفعلي.
9. تصنيف دوال SECURITY DEFINER الأربع التي تظهر في anon Advisor warning.
10. فحص currency configuration aggregate للمتجر المنشور: سجل واحد مفعّل، العملة EGP، ولا توجد قيمة currency فارغة.
11. فحص Supabase Security Advisor عند `2026-11-25T20:37:42.289Z`.
12. لا تغييرات في source أو database أو deployment أو business data.

## 8. ما لم يتم ولماذا

- لم يُنفذ CS-748-P0-A: لا توجد موافقة محددة موثقة.
- لم تُنفذ أي exploit test أو DML على `role_permissions`.
- لم يُنفذ DDL/DML/ACL/RLS/Edge/Cloudflare deployment.
- لم يُنفذ أي business RPC أو posting أو QA fixture.
- لم يُنفذ Browser E2E أو Authenticated Runtime لعدم توفر originating browser context/session.
- لم يمكن جلب Cloudflare artifact أو raw deployed bytes؛ محاولات فتح URL والتنزيل لم تنجح.
- لم تُقرأ main.html كاملًا؛ fetch أعاد SHA مع محتوى فارغ.
- لم تُراجع كل وحدات core.js أو جميع مستهلكي كل التطبيقات؛ لا diff جديد في company-1 يفرض إعادة فتحها.
- لم يُنفذ Benchmark أو قياس UX أو اختبار Realtime أو قياس توقعات.
- لم تُفحص بيانات CountFlow أو بيئته؛ يظل خارج نطاق RAWAEA.

## 9. صحة النظام والتطبيقات والتغطية

- SMART ERP database متاح وصحته ACTIVE_HEALTHY عند الفحص.
- لا يوجد دليل جديد على تغيير في تطبيقات company-1 منذ checkpoint المقارن.
- هذا لا يثبت صحة كل التطبيقات أو كل مسارات الأعمال.
- Inventory Control داخل RAWAEA وPicker/Receiver/Loader/Returns/Unloader/Vouchers/Buyer/Finance/Sales/Delivery/POS لم تُختبر وظيفيًا اليوم.
- Parent main.html وcore.js لم يخضعا لمراجعة كاملة اليوم؛ تم تثبيت SHA فقط/جزئيًا.
- CountFlow منفصل تمامًا عن نطاق النتائج والبيانات والحسابات والمقاييس.

## 10. تدقيق التعديلات الأخيرة وآثارها الجانبية

- Operational commit `095a344` يغيّر ملف CountFlow توثيقيًا فقط؛ لا أثر على company-1.
- Governance commit `afca741` يثبت CURRENT_STATE فقط.
- لا source patch ولا database change ولا deployment في هذه الجولة.
- لا أثر مخزني أو مالي أو على الموردين/العملاء/الخزينة/العهد.
- لا تغيير في Auth أو RLS أو ACL أو SECURITY DEFINER objects.

## 11. الأخطاء والفجوات والسبب الجذري

| الأولوية | الفجوة | السبب/الدليل | الإجراء |
|---|---|---|---|
| P0 | direct write إلى role_permissions | explicit anon/auth DML grants + PUBLIC ALL RLS policy + profile consumer | اعتماد CS-748-P0-A ثم تطبيقه واختباره |
| P1 | default ACL واسع للجداول المستقبلية في public | pg_default_acl يمنح anon/auth مجموعة واسعة للمالكين supabase_admin/postgres | Change Set مستقل بعد جرد الإنشاء والـconsumers |
| P1 | categories public CRUD + PUBLIC ALL | live ACL/policy، وParent direct reads تاريخيًا | Change Set مستقل بعد consumer map |
| P2 | SECURITY DEFINER view | Advisor ERROR؛ view owner postgres، security_barrier، auth SELECT فقط، لا anon SELECT، filter company/permission/self | مراجعة متعددة الشركات وجلسة مصادق عليها؛ لا تعديل جماعي |
| P2 | anon SECURITY DEFINER functions | 4 warnings؛ اثنتان trigger functions واثنتان public storefront endpoints | مراجعة حدود البيانات ومقاومة التخمين والـACL، لا revoke جماعي |
| P2 | 142 authenticated SECURITY DEFINER warnings | lint count فقط | فرز function-by-function؛ لا revoke جماعي |
| P2 | Leaked Password Protection disabled | Advisor WARN | تقييم Auth hardening منفصل |
| P2 | Cloudflare/runtime parity | لا artifact أو browser evidence | يتطلب وصولًا صالحًا إلى artifact/browser |
| P3 | fallback currency في public catalog | الدالة تملك fallback SAR عند null؛ الإعداد الحالي EGP وغير null | لا خلل فعلي في snapshot الحالي؛ راقب مصدر العملة |

### 11.1 تفاصيل Advisor الجديدة

- 24 جدولًا RLS-enabled بلا Policy — INFO؛ لا تُعامل تلقائيًا كثغرات، إذ يكون default deny غالبًا.
- View واحدة SECURITY DEFINER: `public.v_finance_employee_directory` — ERROR في Advisor. تعريفها يرشح الشركة الحالية، ويطلب finance/finance_manager/hr أو المستخدم نفسه. anon SELECT=false وauthenticated SELECT=true. helper `current_user_company_id()` مرتبط بـauth.uid. لم يُختبر عزل شركات فعليًا.
- أربع دوال SECURITY DEFINER قابلة للتنفيذ من anon:
  - `enforce_supplier_return_receiver()`: RETURNS trigger، ولها trigger واحد؛ لا يثبت التحذير وحده إمكانية استدعائها كـRPC عادي.
  - `sync_supplier_return_buyer_custody_event()`: RETURNS trigger، ولها trigger واحد؛ لا exploit test.
  - `get_public_store_catalog(text)`: endpoint عام يعرض أصناف المتجر المنشور وبيانات السعر/الكمية؛ يلزم تقييم نطاق كشف الكميات باعتباره قرارًا تجاريًا/خصوصيًا.
  - `get_public_store_order_tracking(text,text,text)`: full detail يتطلب order code + phone؛ lookup بالرمز وحده يعرض حالة مختصرة، وبالهاتف وحده يعرض حتى 10 ملخصات؛ rate limiting ومقاومة enumeration غير مثبتين.
- 142 authenticated SECURITY DEFINER warnings: لا تعني 142 ثغرة مثبتة.
- Leaked Password Protection معطل.
- لا تعديل لأي دالة أو View أو Auth setting.

## 12. الكفاءة التشغيلية والميدانية

لم تُنفذ اليوم أي رحلة أعمال. جميع السيناريوهات التالية UNVERIFIED في هذه الجولة: المورد→PO→استلام→AP/دفتر المورد؛ الطلب→التجهيز→التحميل→التسليم→التحصيل؛ الجرد من فتح الجلسة حتى اعتماد الفروقات؛ المرتجعات؛ عهد الموظفين؛ التسويات والخزينة؛ التشغيل الميداني على الهاتف. وجود كود أو شاشة لا يثبت إتمام الرحلة.

## 13. التخطيط والتنبؤ ومركز القرار

UNKNOWN. لا قياس لدقة الطلب أو safety stock أو stockout/expiry forecast أو cash forecast أو الانحراف عن الخطة. لا Dashboard أو قاعدة if تُحسب ذكاءً تنبؤيًا دون مقارنة بنتائج فعلية.

## 14. المقارنة التنافسية

لم يُنفذ Benchmark جديد. المقارنة مع SAP S/4HANA/Business One وDynamics 365 وOdoo وERPNext وDaftra وManager.io لم تُبحث اليوم بمصادر رسمية حديثة أو سيناريوهات متكافئة. لا ادعاء تفوق أو تكافؤ. تحديد أي منتج باسم Next يظل مطلوبًا قبل إدراجه.

## 15. مصفوفة نضج RAWAEA

| المجال | الدرجة | الثقة والدليل |
|---|---:|---|
| السلامة التقنية والمعمارية | UNKNOWN | لا مراجعة شاملة؛ P0 قائم |
| تكامل التطبيقات والبيانات | UNKNOWN | لا cross-app E2E |
| العمليات التجارية | UNKNOWN | لا رحلة أعمال مصادق عليها |
| الرقابة المالية والمحاسبية | UNKNOWN | لا posting/reconciliation test |
| المخزون وسلاسل الإمداد | UNKNOWN | لا business E2E |
| التوزيع والعمل الميداني | UNKNOWN | لا device/runtime test |
| التخطيط والتنبؤ والقرار الذكي | UNKNOWN | لا accuracy metrics |
| التقارير وذكاء الأعمال | UNKNOWN | لا export/reconciliation |
| الأمان والصلاحيات والتدقيق | 1/5 في نطاق الصلاحيات المفحوص فقط | direct-write P0 مفتوح؛ لا audit trigger على role_permissions؛ لا اختبار exploit |
| الأداء والاستقرار والتوسع | UNKNOWN | لا load/latency |
| تجربة المستخدم والإنتاجية | UNKNOWN | لا task timing/usability |
| الجاهزية التشغيلية والتنافسية | UNKNOWN | artifact/runtime/benchmark غير مثبت |

لا تُقارن هذه الدرجات رقميًا بتقييم سابق مختلف النطاق.

## 16. خريطة Parent/Core والعقود

- Parent: `companies/company-1/main.html`، blob `00456494de918b36fc6792bef302319a9f65605d`؛ المحتوى الكامل لم يُسترجع اليوم.
- Core: `companies/company-1/core.js`، blob `2b2211a3f95049042e27a7b2ecbab3640a584942`؛ مراجعة الأسطر الأولى فقط.
- المسار المثبت للصلاحيات: authenticated identity → `get_my_effective_profile()` → `users/roles/role_permissions` → profile permissions → `current_user_has_effective_permission()`.
- لا يثبت هذا المسار وجود Supabase client واحد أو Core موحد فعليًا في كل التطبيقات.
- لا تعديل على Parent/Core/Auth/Router أو أي تطبيق.

## 17. مصفوفة المزامنة

| المسار | ما ثبت | ما لم يثبت |
|---|---|---|
| Effective permissions | profile RPC يقرأ role_permissions عبر SECURITY DEFINER | authenticated behavior بعد revoke |
| categories | Parent direct reads تاريخيًا | cross-user refresh وcache invalidation |
| Warehouse/Inventory | وجود migrations وواجهات سابقة | event delivery/reconnect/latency |
| Realtime العام | وجود بعض Publications/listeners تاريخيًا | وصول الأحداث الفعلي وزمنها |
| Cloudflare/PWA | لا artifact/runtime evidence | deployment lineage وSW/cache behavior |

لا وصف للمزامنة بأنها لحظية.

## 18. جاهزية المساعد واستلام شعلة التطوير

**READY WITH LIMITATIONS** للقراءة والتوثيق وتجهيز Change Sets.  
**BLOCKED** لتطبيق CS-748-P0-A بسبب عدم ثبوت الموافقة المحددة؛ وUNVERIFIED لاختبار authenticated runtime والنشر.  
نقطة الاستئناف التالية: LVE-753، P0 role_permissions، ثم مراجعة default ACL كمسار P1 مستقل. لا إعادة فتح CountFlow أو وظائف company-1 غير المتأثرة دون دليل جديد.

## 19. الالتزام بالدستور

- CURRENT_STATE قُرئ كاملًا قبل الدستور.
- الدستور قُرئ كاملًا SHA `3a6b1e220af8509e314e94df76563bbc6f84910d`.
- طُبقت بوابات §6.1/§6.2/§7/§8/§9/§10/§11/§12/§13.
- لم يُنفذ أي تعديل تشغيلي أو Production write أو business RPC أو deployment.
- تعارض بيئة الاختبار موضح في القسم 4؛ تم اختيار القراءة فقط كخيار أكثر حماية.
- لم يُخلط CountFlow مع RAWAEA.

## 20. المخاطر والاعتماديات وما ينتظر المالك

1. اعتماد صريح لـCS-748-P0-A بالنص الكامل قبل التنفيذ.
2. Change Set منفصل للـdefault ACL بعد تحليل الأدوار المنشئة والجداول المستقبلية.
3. Change Set منفصل لـcategories بعد جرد جميع مستهلكي القراءة والكتابة.
4. لا تغيير جماعي لدوال SECURITY DEFINER أو Views اعتمادًا على Advisor counts وحدها.
5. حسم بيئة الاختبار المصرح بها قبل أي اختبار ذي أثر.
6. لا حاجة إلى سؤال تجاري جديد؛ المانع الوحيد الحالي هو الاعتماد المحدد والأدلة التشغيلية غير المتاحة.

### CS-748-P0-A — النص المحدد الذي ما زال PREPARED / NOT APPLIED

```sql
BEGIN;
REVOKE ALL ON TABLE public.role_permissions FROM anon, authenticated;
DROP POLICY IF EXISTS "Allow all for all" ON public.role_permissions;
COMMIT;
```

النطاق: الجدول `public.role_permissions` فقط. لا تغيير للصفوف أو users/roles أو service_role أو profile RPCs أو categories أو default ACL أو Parent/Core/Edge.

قبول ما بعد التطبيق:
1. effective privileges لـanon/authenticated تصبح false على SELECT/INSERT/UPDATE/DELETE/TRIGGER/REFERENCES/MAINTAIN/TRUNCATE.
2. اختفاء policy `Allow all for all` عن الجدول.
3. بقاء grants المطلوبة لـservice_role.
4. بقاء EXECUTE لـauthenticated على `get_my_effective_profile` و`get_warehouse_hub_snapshot`، وanon=false.
5. profile read في جلسة مصادق عليها، مع مقارنة permission keys دون تعديل أي صف.
6. row_count=21 وdistinct role_id=3 وعدم تغير users/roles.
7. لا exploit ولا business DML ولا أي أثر مخزني/مالي.
8. إذا تعذر Authenticated session يبقى runtime acceptance UNVERIFIED.

لا يُستخدم إرجاع PUBLIC ALL أو grants العامة كـrollback. إذا ظهر consumer مباشر، يوقف المسار ويُجهز Change Set ضيق جديد.

## 21. الخطوة التالية الواحدة

الحصول على اعتماد المالك الصريح لنص **CS-748-P0-A** أعلاه. بعد ثبوت الاعتماد فقط، يُطبق النطاق المحدد ويُعاد فحص ACL/policy/profile grants، ثم يُختبر profile في جلسة مصادق عليها دون تغيير بيانات الأعمال. لا تُضم categories أو default ACL إلى التغيير نفسه.

## 22. سجل الأدلة

- CURRENT_STATE: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md
- Permanent Constitution: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/%D8%A7%D9%84%D8%AF%D8%B3%D8%AA%D9%88%D8%B1%20%D8%A7%D9%84%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%D9%8A%20%D8%A7%D9%84%D8%AF%D8%A7%D8%A6%D9%85.md
- Report752: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report752_DAILY_CTO_RAWAEA_P0_PERMISSION_REVALIDATION_20261124.md
- Report751: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report751_DAILY_CTO_RAWAEA_P0_PERMISSION_REVALIDATION_20261123.md
- Report749: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report749_DAILY_CTO_RAWAEA_P0_PERMISSION_REVALIDATION_20261121.md
- Operational HEAD: https://github.com/papamohammed77-glitch/erp-frontend/commit/095a344e20cafd768c88353c33ceecbc764a6cc4
- Governance state pin before this review: https://github.com/papamohammed77-glitch/rawaie-erp-New/commit/afca741e40da92c27766077d484f8af536f95ec7

**الخلاصة:** P0 role_permissions ما زالت CONFIRMED/OPEN؛ CS-748-P0-A PREPARED/NOT APPROVED/NOT APPLIED؛ default ACL P1 جديدة ومثبتة كإعداد افتراضي للمستقبل؛ categories P1 مفتوحة؛ لا تغييرات تشغيلية أو آثار أعمال؛ Cloudflare/Runtime/E2E غير مثبتة.
