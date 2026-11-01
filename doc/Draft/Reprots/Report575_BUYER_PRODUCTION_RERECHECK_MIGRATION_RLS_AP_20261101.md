# Report575 — إعادة التحقق من Buyer Production ومطابقة Migration / RLS / Supplier AP

**التاريخ:** 2026-11-01 — Africa/Cairo  
**الحدث:** LVE-2026-11-01-575  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` — `main`  
**HEAD الحالي:** `488dfe79f6d9291e649ee0db78d1ffb3af70e91a`  
**Supabase Production:** SMART ERP — `fiilmooggumokxanwiyx`  
**الحالة:** Buyer source وEdge v21 وعقود Production الأساسية متطابقة في الجزء المفحوص؛ ظهرت تعارضات Migration lineage وملاحظات صلاحيات/RLS وازدواج Trigger؛ Cloudflare/browser runtime ما زال UNVERIFIED. لا إغلاق للمهمة.

---

## 1. نقطة البداية والهدف الحالي

**LAST VERIFIED EVENT السابق:** `LVE-2026-11-01-574` — إصلاح عملة Buyer ومطابقة النوافذ المنبثقة، وحراسة محاسبة PO/Receiving/Invoice.

**آخر checkpoint مسجل قبل هذا الفحص:**
- Operational HEAD: `488dfe79f6d9291e649ee0db78d1ffb3af70e91a`.
- Buyer source blob: `6c26444fa80b198d305727b70791f400839a6f75`.
- Migration 574 blob: `eec96f8d1798420961275f4ea3ff7176f28b740c`.
- إصلاح المصدر وقاعدة البيانات واختبار PO → Receiving → Invoice داخل معاملة ROLLBACK مثبتة في Report574؛ لا يُعاد تقديمها كاختبار جديد في هذا التقرير.

**هدف هذه الجولة:** إعادة جلب الأدلة الحية من Operational GitHub وSupabase Production، ومقارنة عقود Buyer/migrations/RPCs مع الإنتاج، والتحقق مما يمكن إثباته من Edge deployment وCloudflare/runtime.

**النتيجة التنفيذية:** الـHEAD لم يتغير عن LVE574. العملة والـRPCs وعقد Edge الحالي مؤكدة. لكن يوجد اختلاف جوهري بين migration ledger في Production وملفات migrations الموجودة في Git، وخطآن/مخاطرتان في صلاحيات/RLS، ووجود Triggerين متزامنين لكتابة رصيد المورد. لا يُنفّذ أي ترحيل جديد قبل تسوية lineage.

## 2. CONFIRMED — حقائق مثبتة بأدلة مباشرة

### 2.1 Operational GitHub / Buyer source

- المستودع التشغيلي هو `papamohammed77-glitch/erp-frontend` والفرع الافتراضي `main`.
- HEAD الحالي ما زال `488dfe79f6d9291e649ee0db78d1ffb3af70e91a`؛ لم يظهر commit تشغيلي أحدث في فحص commits.
- `companies/company-1/purchasing/buyer.html`: blob `6c26444fa80b198d305727b70791f400839a6f75`، 100,666 حرفًا.
- `supabase/functions/save-purchase-order/index.ts`: blob `49c85a4a4648bcef6892476d92037ca56745f633`، 21,007 حرفًا / 448 سطرًا.
- Buyer يقرأ العملة من عملية `GET_SETTINGS` ويستخدم `loadSystemCurrency()` للتحقق من قيمة من ثلاث حروف؛ لم يعد يعتمد في المصدر الحالي على SAR كقيمة افتراضية.
- مسار إنشاء فاتورة الشراء في Buyer يستدعي عملية Edge `CREATE_INVOICE`؛ والـEdge يستدعي `purchase_create_invoice_atomic_v2` ويمرر العملة التي قرأها من `app_settings`.
- إنشاء PO اليدوي من Buyer يمر عبر `profileClient.rpc("purchase_create_po_atomic", ...)` مع JWT المستخدم، ولا يكتب تفاصيل PO مباشرة من الواجهة.
- لا يوجد تعديل تشغيلي جديد في هذه الجولة على Buyer أو Parent أو Edge source.

### 2.2 Supabase Production — الشركة والعملة والعقود

- فحص Production read-only في `2026-11-01 14:15:31.530019+00` UTC أظهر PostgreSQL 17.6.
- `public.app_settings`: الشركة النشطة المسجلة `00000000-0000-0000-0000-000000000001`، والعملة `EGP`. آخر تحديث لقيمة الإعداد الظاهرة: `2026-10-31T20:27:33.430405+00:00`.
- عقد `purchase_create_invoice_atomic` موجود في Production بالتوقيع:
  `(uuid,uuid,uuid,uuid,date,text,text,jsonb,text)`.
  وهو SECURITY DEFINER مع `search_path = "")، ويرفض العملة غير المطابقة لـ`app_settings.currency`، ويتحقق من المورد والفرع والـPO والشركة، ويكتب الفاتورة Draft بعملة النظام.
- عقد `purchase_create_invoice_atomic_v2` موجود في Production بالتوقيع:
  `(uuid,uuid,uuid,uuid,date,text,text,text,text,jsonb,text)`.
  وهو wrapper يستدعي الدالة الأساسية ثم يحفظ `supplier_invoice_no` و`notes`. بذلك يطابق مسار Buyer/Edge المفحوص عقد قاعدة البيانات الفعلي.
- عقد `purchase_post_invoice_atomic` موجود في Production بالتوقيع `(uuid,uuid,text)`. في PO-linked invoices يتحقق من استلام المخزن والكميات والأسعار، ولا يعيد ترحيل المخزون أو التزام المورد الذي سجله الاستلام. يرفض الخصم/الضريبة غير المدعومين في هذا المسار بدل ترحيل فرق محاسبي غير معرف.
- عقد `purchase_create_po_atomic` موجود في Production بالتوقيع `(uuid,uuid,uuid,date,text,text,jsonb,text))، SECURITY DEFINER و`search_path="")، ويتحقق من المستخدم والشركة وصلاحية المشتريات وIdempotency والمورد والفرع، ويقرأ عملة الشركة، ويقفل تسلسل كود PO، وينشئ Draft PO وتفاصيله وسجل الحالة.
- وظائف العهدة التالية موجودة في Production، SECURITY DEFINER و`search_path=""`، وEXECUTE غير متاح لـanon:
  - `buyer_custody_add_advance_atomic`
  - `buyer_custody_acknowledge_advance_atomic`
  - `buyer_custody_issue_atomic`
  - `buyer_custody_submit_expense_atomic`
  - `buyer_custody_review_expense_atomic`
  - `buyer_custody_settle_atomic`
- `buyer_custody_add_advance_atomic` يتحقق من المستخدم النشط ونطاق الشركة وصلاحية finance/finance_manager وحالة العهدة وعدم إصدار زيادة ذاتية ومفتاح العملية والخزينة؛ ثم يسجل السلفة الإضافية، ويرفع `issued_amount`، وينفذ قيد/حركة نقدية مرتبطة بالخزينة. إقرار الموظف بالزيادة له RPC مستقل `buyer_custody_acknowledge_advance_atomic`.
- `buyer_custody_submit_expense_atomic` يتحقق من ملكية الموظف للعهدة وإقراره بالاستلام والعملة ومسار مستندات Storage ووجود الفاتورة Draft المرتبطة بـPO وإثبات الاستلام وتطابق بنود/كميات الاستلام وحدود المبالغ المعتمدة. هذا فحص تعريف الدالة والعقد؛ ليس اختبار متصفح.

### 2.3 Supabase Production — Edge artifact

- `save-purchase-order` في Production: **ACTIVE / version 21 / verify_jwt=true**.
- SHA-256 المنشور من Supabase: `dab3eba49dd355080cadaa5bca4aea02056de19c4b6f3ba581f142cccfa0ea8c`.
- جلب ملف `index.ts` المنشور من Supabase ومقارنته مباشرةً بمحتوى Git الحالي أعطى **exact_content_match=true**، والطول في الطرفين 21,007 حرفًا.
- زمن تحديث Edge المسجل في API: `1793495152075` milliseconds.
- هذا يثبت تطابق Edge artifact مع المصدر الحالي للوظيفة فقط؛ لا يثبت نشر Cloudflare Pages أو صحة browser runtime.

### 2.4 RLS / grants — العهدة والمشتريات

- RLS مفعّل على جداول العهدة الخمسة: `buyer_custodies`, `buyer_custody_advances`, `buyer_custody_expenses`, `buyer_custody_payments`, `buyer_custody_settlements`.
- ACL لهذه الجداول يتيح للمستخدم `authenticated` SELECT فقط؛ لا يمنحه INSERT/UPDATE/DELETE/TRUNCATE مباشرًا. وanon لا يملك صلاحية مباشرة عليها.
- تم التحقق من أن `TRUNCATE` غير متاح لـanon أو authenticated على `purchase_requests`, `purchase_invoices`, `purchase_invoice_details`؛ وهذا يتسق مع migration `20261031230603_buyer_purchase_remove_end_user_truncate_grants_20261101.sql`.
- لا تعمم نتيجة جداول المشتريات تلك على جميع الجداول أو على `suppliers`؛ فجدول الموردين له حالة مختلفة موضحة في قسم المخاطر.

### 2.5 Business-data read-only reconciliation

- عدد الموردين في الشركة التي ظهرت في `app_settings`: 4.
- مجموع `suppliers.accounts_payable`: 3,970.
- مجموع `supplier_ledger.credit - debit`: 3,970.
- عدد اختلافات الرصيد المخزن عن صافي دفتر الموردين: 0.
- لكل مورد في العينة المقروءة، قيمة آخر `supplier_ledger.balance` تطابق مجموع `credit - debit`.
- جدول `buyer_custody_payments` يحوي 0 صفوف حاليًا؛ لا توجد سجلات يتيمة أو روابط دفع إلى عهدة من شركة أخرى في البيانات المقروءة.
- هذه قراءة حالة حالية وليست اختبار كتابة أو اختبارًا شاملاً لكل تاريخ المعاملات.

## 3. UNKNOWN — ما لا تكفي الأدلة لحسمه

- هل Cloudflare Pages يخدم commit `488dfe79f6d9291e649ee0db78d1ffb3af70e91a` أو artifact أحدث/أقدم؟ لم تتوفر قراءة موثوقة لصفحة deployment/الـartifact.
- ما هي headers/cache وcommit/build lineage للنسخة التي يحمّلها المستخدم من Cloudflare حاليًا؟
- هل نجاح Edge v21 يترجم إلى نجاح واجهة Buyer المصادق عليها من المتصفح؟
- هل سياسات RLS تُنفذ كما هو متوقع لكل مستخدم وموظف وشركة في جلسات حقيقية منفصلة؟
- لا توجد بيانات في `buyer_custody_payments` تسمح بإثبات أو نفي الأثر العملي لشرط الشركة المعيب في سياسة الجدول.
- لا توجد عملية كتابة آمنة منفذة لإثبات سلوك Triggerين الموردين تحت تحديثات متزامنة أو تصحيح دفتر قديم؛ البيانات الحالية متطابقة، لكن هذا لا يحسم سلوك كل ترتيب تحديث.
- لم يثبت فحص صلاحية TRUNCATE وحده إمكانية تنفيذ هجوم عبر PostgREST من anon/authenticated؛ الثابت هو وجود المنحة في PostgreSQL ACL، أما قابلية استغلالها عبر واجهة الشبكة فلم تُختبر.
- محتوى كل migrations التاريخية في المستودع لم يخضع لمسح شامل لكل مجلد المشروع؛ نتيجة المطابقة هنا محددة بمجلد `supabase/migrations` وبالملفات المفحوصة. بحث GitHub code عن اسم دالة واحدة أعاد صفرًا مع `incomplete_results=true`، فلا يصلح دليلًا على غيابها عن كل المستودع.

## 4. CONFLICT — تعارضات مثبتة أو عقود لا تتطابق

### 4.1 Migration lineage بين Production وGit — blocker

**Production ledger** يعرض الإصدارات التالية كمنفذة:
- `20261031233331` — `buyer_employee_custody_ledger_and_manual_settlement_20261101`
- `20261031233638` — `buyer_full_detail_realtime_publication_20261101`
- `20261031233923` — `buyer_custody_finance_separation_of_duties_20261101`
- `20261031234235` — `buyer_custody_finance_manager_permission_and_policy_20261101`
- `20261031234711` — `buyer_dashboard_effective_finance_manager_permission_20261101`
- `20261031234832` — `buyer_dashboard_use_auth_role_for_service_bypass_20261101`
- `20261031234921` — `buyer_custody_storage_path_qualification_and_cleanup_policy_20261101`
- `20261031235057` — `buyer_custody_currency_and_full_cash_reconciliation_20261101`
- كما يعرض إصدارات أخرى: `20261101003853`, `20261101003952`, `20261101005159`, `20261101005218`, `20261101005616`, `20261101005849`, `20261101010224`, ثم `20261101120225`.

**Git current migration directory** يحتوي ملفات المنطق الأول أعلاه بإصدارات مختلفة، مثل:
- `20261101010000_buyer_employee_custody_ledger_and_manual_settlement.sql`
- `20261101011000_buyer_full_detail_realtime_publication.sql`
- `20261101012000_buyer_custody_finance_separation_of_duties.sql`
- `20261101013000_buyer_custody_finance_manager_permission_and_policy.sql`
- `20261101015000_buyer_dashboard_effective_finance_manager_permission.sql`
- `20261101016000_buyer_dashboard_use_auth_role_for_service_bypass.sql`
- `20261101017000_buyer_custody_storage_path_qualification_and_cleanup_policy.sql`
- `20261101018000_buyer_custody_currency_and_full_cash_reconciliation.sql`
- وملف `20261101120225` المطابق لإصدار أحدث Migration 574.

**الأثر:** رقم migration هو جزء من هوية تطبيق migration. تشابه الاسم أو التشابه المنطقي لا يثبت أن سجل الإصدار في Production يقابل ملف Git الحالي. الملفات المعاد ترقيمها قد تظهر لدى أداة الترحيل كإصدارات لم تُطبق، بينما Production يسجل نسخًا أخرى؛ كما أن الإصدارات السبعة `20261101003853` إلى `20261101010224` لا تظهر كملفات بأسمائها/إصداراتها في المجلد الحالي الذي فُحص. وفي الوقت نفسه، توجد في Production الدالتان `purchase_create_po_atomic` و`buyer_custody_add_advance_atomic` بينما لا تظهر تعريفاتهما ضمن ملفات migrations ذات الصلة التي تمت مراجعتها في Git.
**القرار الوقائي:** لا تستخدم `supabase db push` ولا تعِد تطبيق هذه migrations حتى تُعاد مطابقة سجل كل version مع مصدر SQL الفعلي وتُستعاد الملفات المفقودة أو تُوثق آلية lineage رسمية. لا ننشئ migration بديلة تخمينية.

### 4.2 سياسة RLS لمدفوعات العهدة — شرط شركة غير مترابط

سياسة `buyer_custody_payments_scoped_select` في Production تحتوي داخل EXISTS على:
`c.company_id = c.company_id`
وهذا شرط tautology لا يربط شركة العهدة بشركة سجل الدفع. السياسة الصحيحة من حيث العقد ينبغي أن تربط `c.company_id` بعمود `buyer_custody_payments.company_id`، كما تفعل سياسة settlements مع جدولها.
**المثبت:** نص السياسة الفعلي يحتوي الشرط المعيب. **غير المثبت:** حدوث تسريب فعلي؛ الجدول حاليًا فارغ، وRLS الشركة الخارجية وقيود القراءة تؤثر في قابلية الوصول. لم يتم اختبار تجاوز أو تغيير السياسة.

### 4.3 ازدواج Trigger تحديث Supplier AP

على `public.supplier_ledger` يوجد Triggerان نشطان AFTER INSERT/UPDATE/DELETE:
1. `supplier_ledger_sync_accounts_payable` → `app_private.sync_supplier_accounts_payable()`: يحسب `SUM(credit - debit)` من كامل دفتر المورد.
2. `trg_sync_supplier_accounts_payable` → `public.sync_supplier_accounts_payable_from_ledger()`: يقرأ `balance` من آخر سطر دفتر حسب `created_at,id`.

Migration 574 أنشأت الأول ولم تُزل الثاني. كلاهما يكتب `suppliers.accounts_payable` استجابةً للحدث نفسه، لكن بمنهجي حساب مختلفين. تطابق الأرصدة الحالي (4/4) دليل سلامة snapshot الحالي فقط، وليس مبررًا لوجود كاتبين أو ضمانًا لتطابق النتيجة في كل تصحيح/إعادة ترتيب تاريخية.
**لم يتم إسقاط Trigger أو تعديل أي وظيفة** لأن هذا يتطلب تحديد الكاتب المعتمد واختبار انتقال مضبوط قبل إجراء Production DDL.

### 4.4 منحة TRUNCATE على suppliers

ACL الفعلي لـ`public.suppliers` يتضمن TRUNCATE لكل من `anon` و`authenticated`، بالإضافة إلى صلاحيات DML. RLS مفعّل، لكنه لا يقيّد TRUNCATE.
هذا يختلف عن جداول المشتريات التي جرى سحب TRUNCATE منها. المنحة مفرطة وينبغي مراجعتها ضمن hardening، لكن لم يُختبر تنفيذها عبر واجهة HTTP ولم تُجرَ أي تغييرات grants في هذه الجولة.

## 5. UNVERIFIED — نتائج لم تُختبر مباشرة

- Cloudflare Pages served artifact / commit lineage / headers / cache.
- تحميل Buyer المنشور وConsole/Network وauthenticated UI E2E.
- اختبار حساب موظف مشتريات وحساب مالية/مدير مالية من جلستين منفصلتين.
- رفع وتنزيل وحذف ملف ثنائي فعلي عبر Supabase Storage API من المتصفح.
- WebSocket delivery/reconnect لتغييرات Buyer Realtime بعد آخر نشر.
- الأثر العملي لسياسة مدفوعات العهدة المعيبة على جلسة authenticated حقيقية.
- مدى إمكانية استغلال TRUNCATE لـsuppliers من مسار API متاح؛ المثبت فقط grant ACL.
- اختبارات كتابة Trigger/AP في معاملة rollback لهذه الجولة. لم يتم تكرار اختبار rollback من Report574؛ تمت قراءة snapshot فقط.
- نجاح مسار PO → Receiving → Invoice في المتصفح. اختبار SQL السابق في Report574 يبقى Rollback-only، وCREATE_PO لم يُختبر من واجهة authenticated.

## 6. مصفوفة التحقق

| الطبقة | الحالة | ما يثبته الفحص |
|---|---|---|
| GitHub / source | CONFIRMED + CONFLICT | HEAD وBuyer وEdge source مؤكدة؛ Migration lineage غير متطابقة مع سجل Production. |
| Supabase Production | CONFIRMED + CONFLICT | EGP، RPC signatures/definitions، Edge version، RLS/ACL، Trigger list، وقراءة الأرصدة مؤكدة؛ شرط RLS خاطئ وازدواج Trigger ومنحة suppliers TRUNCATE مثبتة. |
| Deployed artifact | PARTIAL CONFIRMED / UNKNOWN | Edge `save-purchase-order v21` يطابق Git حرفيًا؛ Cloudflare Pages artifact غير معروف. |
| Runtime / E2E | UNVERIFIED | لا جلسة Buyer مصادق عليها ولا Console/Network أو WebSocket/Storage E2E. |
| Business-data effects | CONFIRMED READ-ONLY SNAPSHOT | 4 موردين؛ إجمالي AP = دفتر الموردين = 3,970؛ 0 اختلافات؛ جدول custody payments فارغ؛ لا كتابة جديدة. |

## 7. ما تم فعليًا في هذه الجولة

1. إعادة جلب `CURRENT_STATE.md` كاملًا: SHA `e20a8993420d5627c3f3d3cb6590b1ed0e5b6591`، وتثبيت LVE574 كنقطة البداية.
2. قراءة Report574 وReport573 والجزء الحالي من `Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md`، وقراءة الدستور التشغيلي الدائم لتحديد القيود العامة.
3. جلب Operational repository metadata، وتأكيد الفرع الافتراضي `main` وآخر HEAD.
4. جلب Buyer source وEdge source وMigration 574 من Operational GitHub.
5. جلب Edge function المنشورة من Supabase ومقارنة `index.ts` حرفيًا بملف Git.
6. قراءة applied migration ledger في Production، ومقارنته بقائمة ملفات `supabase/migrations` الحالية، ثم فحص مجموعة ملفات migrations ذات الصلة.
7. تنفيذ استعلامات SQL للقراءة فقط على `app_settings`، و`pg_proc`، و`pg_policies`، و`pg_trigger`، وACL، وأرصدة الموردين، وعدد مدفوعات العهدة.
8. فتح تبويب التطبيق المنشور من خلال سياق المتصفح: ما ظهر هو شاشة تسجيل الدخول؛ لم تُدخل بيانات ولم تنفذ أي نقرة/تغيير. تعذر قراءة محتوى Cloudflare dashboard بسبب صلاحية host غير متاحة لإضافة المتصفح.
9. لم يتم تغيير أي صف Production، ولا DDL/RLS/grants/trigger، ولا Edge deployment، ولا أي ملف في Operational repo.

## 8. ما لم يتم ولماذا — blockers محددة

- **Cloudflare:** لا يوجد وصول موثوق إلى صفحة deployment أو artifact عبر السياق المتاح؛ لذلك لا إثبات لربط Pages بـHEAD 488dfe7.
- **Browser E2E:** التبويب المفتوح يعرض Login فقط ولا توجد جلسة موظف/مالية مصادق عليها؛ لم يتم إدخال بيانات دخول أو تنفيذ عمليات حقيقية.
- **Storage:** لا اختبار رفع/تحميل/حذف ملف ثنائي عبر Storage API.
- **Migration reconciliation:** لا يمكن متابعة ترحيلات Production بأمان قبل مطابقة versions والـSQL؛ منعًا لإعادة تطبيق DDL أو تسجيل تاريخ migrations غير صحيح.
- **RLS/AP hardening:** لم يتم تعديل سياسة `buyer_custody_payments` أو إزالة Trigger قديم أو سحب TRUNCATE من suppliers؛ هذه تغييرات إنتاجية حساسة تحتاج مراجعة migration lineage أولًا، واختبارًا محددًا، وخطة rollback.
- **اختبار آثار الأعمال:** لم تُنفذ أي كتابة إنتاجية أو اختبار غير قابل للتراجع. القراءة الحالية لا تثبت أن كل التدفقات التشغيلية تعمل من واجهة المستخدم.

## 9. الخطوة التالية الوحيدة ذات الأولوية

**إجراء Migration Lineage Reconciliation** بين `supabase_migrations.schema_migrations` ومجلد `supabase/migrations` في `erp-frontend/main`: بناء mapping واحد لكل version مطبق إلى ملف SQL/blob/commit المقابل، واستعادة SQL المفقود من تاريخ Git/commits الموثوقة أو توثيق أنه أُنشئ خارج المستودع، وتحديد الملفات المعاد ترقيمها دون تغيير Production. لا تشغّل `db push` أثناء هذه المهمة. بعد اكتمال المطابقة فقط يمكن تجهيز migration مراجعة منفصلة لشرط RLS وازدواج Supplier AP Trigger ومنحة TRUNCATE على suppliers، ثم اختبارها بخطة rollback ومراجعة أثرها قبل تنفيذها.

**قرار الحالة:** `LVE-574 SOURCE/DB REPAIRS STILL PRESENT / EDGE v21 BYTE-MATCHED / EGP CONFIRMED / MIGRATION LINEAGE CONFLICT / CUSTODY PAYMENT RLS PREDICATE DEFECT CONFIRMED / DUPLICATE SUPPLIER AP TRIGGERS CONFIRMED / SUPPLIERS TRUNCATE GRANT CONFIRMED / CLOUDFLARE + AUTHENTICATED RUNTIME UNVERIFIED / NO PRODUCTION MUTATIONS / NOT CLOSED`.
