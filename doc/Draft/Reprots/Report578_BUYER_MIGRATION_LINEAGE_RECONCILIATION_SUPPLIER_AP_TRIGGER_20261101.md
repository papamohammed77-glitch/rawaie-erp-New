# تقرير CTO — LVE-2026-11-01-578
## مراجعة RAWAEA ERP اليومية: مصالحة Migration Lineage وإعادة فحص Buyer / Supplier AP

**تاريخ المراجعة:** 2026-11-01 — Africa/Cairo  
**آخر لقطة Production SQL:** 2026-11-01 20:42:09 UTC  
**المشروع:** SMART ERP — Supabase ref: fiilmooggumokxanwiyx  
**النطاق:** Buyer / المشتريات / العهد / Supplier Accounts Payable / Migration Lineage  
**الحالة النهائية:** PARTIAL — لا يُعلن إغلاق المهمة أو جاهزية Production.

---

## 1) نقطة البداية — CURRENT_STATE وLAST VERIFIED EVENT

تم جلب وقراءة **CURRENT_STATE.md كاملًا** من مستودع الاستمرارية، وعدد أسطره عند بدء المراجعة 3,757 سطرًا. كان آخر checkpoint مسجل هو **LVE-2026-11-01-575**.

تمت قراءة تقرير 575 وتعليمات الحوكمة التشغيلية المشار إليها، ثم مراجعة الجزء الأخير من سجل الذاكرة 117-02 لتحديد الادعاءات التي تستلزم إعادة اختبار.

### ما كان مسجلًا عند نقطة البداية
- Operational HEAD المسجل: **488dfe79f6d9291e649ee0db78d1ffb3af70e91a**.
- Migration lineage في Buyer: تعارض أسماء/إصدارات بين Production وGit.
- سياسة قراءة buyer_custody_payments: predicate غير مترابط مع الشركة في صف الدفع.
- وجود مشغلين نشطين لتحديث suppliers.accounts_payable.
- منح TRUNCATE على public.suppliers إلى anon وauthenticated.
- Cloudflare Pages وAuthenticated Runtime E2E غير متحققين.

### الهدف الذي ورثته المراجعة
إعادة فحص Migration Lineage أولًا من المصدر الحي، ثم اختبار ما إذا كانت إصلاحات RLS وTRUNCATE قد نُفذت بالفعل، وتحديد ما بقي من ازدواجية Supplier AP. لم أبدأ من تقرير قديم باعتباره حقيقة، ولم أعد تنفيذ إصلاحات ظهرت مغلقة في الأدلة الحالية.

---

## 2) CONFIRMED — حقائق مثبتة من المصادر الحالية

### A. GitHub / SOURCE CODE

**المستودع التشغيلي:** papamohammed77-glitch/erp-frontend  
**الفرع:** main  
**HEAD الحالي:** 40bd00c91f8c52260d867f5cf020104c9e71c161  
**وقت commit:** 2026-11-01 20:26:08 UTC  
**Tree:** 4b4b36a5ee73868a058f01dde00229c510a91cdc

**ملفات Buyer الحالية:**
- companies/company-1/purchasing/buyer.html — blob 6c26444fa80b198d305727b70791f400839a6f75.
- supabase/functions/save-purchase-order/index.ts — blob 49c85a4a4648bcef6892476d92037ca56745f633.

ملف Buyer لم يتغير عن blob الذي تم التحقق منه في LVE574. المصدر الحالي يقرأ العملة من GET_SETTINGS، ويستخدم EGP كقيمة احتياطية محلية عند غياب القيمة، ولا يحتوي مسار العملة الذي تمت مراجعته على fallback إلى SAR. هذا يثبت SOURCE CODE فقط، وليس ما يقدمه Cloudflare للمستخدم.

### B. Migration Lineage — Buyer scope

تمت مقارنة قائمة ملفات supabase/migrations في HEAD الحالي بقائمة Production schema_migrations مباشرة.

**النتيجة:**
- Production يحتوي 730 سجل migration إجمالًا.
- مجلد migrations الحالي في Git يحتوي 43 ملفًا.
- من هذه الملفات، 33 ملف Buyer/Procurement/Custody.
- إصدارات وأسماء ملفات Buyer الـ33 تطابق سجلات Production الـ33 المقابلة **تطابقًا كاملًا**.
- عدد Buyer versions المسجلة في Production وغير الموجودة في Git: **0**.
- عدد Buyer files الموجودة في Git وغير المسجلة في Production: **0**.
- توجد 10 ملفات Migration إضافية تخص Delivery خارج نطاق Buyer؛ لم تُطبق ولم تُعدل في هذه المراجعة.

نطاق الإصدارات المطابق يبدأ من **20261031222956** وينتهي عند **20261101144244**، ويشمل ملفات العهد، أوامر الشراء، العملة، تسوية المورد، سياسة الدفع، وإلغاء TRUNCATE.

**الاستنتاج المحدود:** تعارض Migration Lineage الخاص بوحدة Buyer الذي سجله LVE575 أصبح محلولًا في Git مقابل Production. لا يعني ذلك أن مجلد migrations الحالي يحتوي التاريخ الكامل لكل 730 migration؛ لذلك لا يزال تنفيذ db push شاملًا أو افتراض اكتمال تاريخ المشروع ممنوعًا دون مصالحة بقية التاريخ.

### C. التغييرات المصدرية التي سبقت هذه المراجعة

تم التحقق من commits التالية في المستودع التشغيلي:

- **8030364ebc53d33e02b971f30acda46f8b00c2ef** — إضافة guard لعملة PO عند ترحيل الفاتورة وتصحيح سياسة tenant للدفع.
- **e9cda057f6168e9cf8304c0fc15d4996db8a3ccf** — مواءمة اسم ملف migration مع إصدار Production المطبق 20261101143644.
- **6f8b03ec5f79efb8fdb4fc5066f4654e33678ec3** — إزالة اسم migration المكرر 20261101150000 بعد توحيد الإصدار.
- **caea2321c88bbb7640643be20672fe28aa9c502e** — إضافة migration لإلغاء TRUNCATE من أدوار العميل وضبط default ACL.
- **40bd00c91f8c52260d867f5cf020104c9e71c161** — إعادة مواءمة ملفات Buyer مع إصدارات Production المطبقة.

هذه تغييرات موجودة بالفعل في Git قبل هذا التشغيل؛ لم أعد تنفيذها.

### D. Supabase Production

**المشروع:** SMART ERP — fiilmooggumokxanwiyx  
**الحالة:** ACTIVE_HEALTHY  
**PostgreSQL:** 17.6.1.121

**العملة:**
- public.app_settings.currency للشركة التشغيلية = **EGP**.
- Production purchase_create_invoice_atomic يقرأ عملة الشركة من app_settings ويرفض العملة المخالفة.
- purchase_post_invoice_atomic الحالي يحتوي system-currency guard، ويرفض اختلاف عملة الفاتورة أو PO عن عملة النظام.
- purchase_create_po_atomic موجود بتوقيع متوافق مع Edge، ويقرأ عملة الشركة ويخزنها على PO.

**سياسة buyer_custody_payments:**
- السياسة الحالية buyer_custody_payments_scoped_select تربط شركة العهدة بشركة صف الدفع: c.company_id = buyer_custody_payments.company_id.
- هذا يختلف عن predicate القديم الذي كان tautology.
- الجدول يحتوي حاليًا **0 صفوف**؛ لذلك تم تأكيد صحة predicate في المخطط، وليس اختبار عزل بيانات فعلية بين شركتين.

**صلاحيات وجداول العهد:**
- الجداول الخمسة buyer_custodies وbuyer_custody_advances وbuyer_custody_expenses وbuyer_custody_payments وbuyer_custody_settlements لديها RLS مفعّل.
- authenticated لديه SELECT فقط على هذه الجداول، ولا يملك INSERT أو UPDATE أو DELETE أو TRUNCATE مباشرًا.
- RPCs الخاصة بالعهد التي تمت مراجعة تواقيعها SECURITY DEFINER وsearch_path فارغ؛ anon لا يملك EXECUTE عليها، وauthenticated يملكه وفق حدود الدوال.
- تواقيع issue / add advance / acknowledge / submit expense / review / settle متوافقة مع payloads التي يرسلها Edge v21 في المصدر الحالي.

**TRUNCATE:**
- تم فحص 186 جدولًا عامًا في Production.
- لا توجد أي جداول عامة تمنح TRUNCATE إلى anon أو authenticated.
- فحص default ACL الموسع لم يُظهر TRUNCATE ممنوحًا إلى anon أو authenticated على جداول public المستقبلية؛ امتياز TRUNCATE محفوظ للمالك وservice_role.
- public.suppliers ما زال يمنح SELECT على مستوى ACL إلى anon، لكن RLS مفعّل ولا توجد سياسة anon على الجدول. لم يُنفذ اختبار HTTP anon مستقل؛ لذلك لا أستنتج منه كشف صفوف.

### E. Supplier Accounts Payable — فحص البيانات والمشغلات

**مصالحة البيانات الحالية:**
- عدد الموردين: 4.
- إجمالي suppliers.accounts_payable: **3,970**.
- صافي supplier_ledger (credit - debit): **3,970**.
- عدد صفوف supplier_ledger: 2.
- اختلافات الحسابات المخزنة عن مجموع الدفتر: **0**.
- اختلافات running balance عن إعادة احتساب التسلسل: **0**.

هذه لقطة قراءة فقط؛ لم يتم تعديل أي مورد أو قيد.

**لكن ازدواجية المشغلات ما زالت قائمة:**
1. supplier_ledger_sync_accounts_payable → app_private.sync_supplier_accounts_payable()
   - يحسب SUM(credit - debit).
   - يعالج تغيير supplier_id بتحديث المورد القديم والجديد.
   - SECURITY DEFINER مع search_path فارغ.
2. trg_sync_supplier_accounts_payable → public.sync_supplier_accounts_payable_from_ledger()
   - يستخدم آخر balance مسجل في دفتر المورد.
   - لا يعالج نقل supplier_id بتحديث رصيد المورد القديم.
   - SECURITY DEFINER مع search_path=public.

كلا المشغلين نشط ويعمل AFTER INSERT OR UPDATE OR DELETE على supplier_ledger، وكلاهما يكتب suppliers.accounts_payable.

فحص dependencies أظهر أن الدالة القديمة لا تملك اعتمادًا مباشرًا آخر غير trigger الخاص بها، ولم يظهر استدعاء لها داخل مصادر دوال قاعدة البيانات التي فُحصت. Migration 20261101120225 أنشأ المشغل الجديد، لكنه لم يُزل المشغل القديم.

**الحكم:** البيانات الحالية متطابقة، لكن وجود كاتبين لنفس projection ما زال عيب تصميم/حوكمة مؤكدًا. لم يُحذف المشغل القديم في هذا التشغيل.

### F. Supabase Edge Runtime

- save-purchase-order: ACTIVE، version 21، verify_jwt=true.
- deployed SHA-256: dab3eba49dd355080cadaa5bca4aea02056de19c4b6f3ba581f142cccfa0ea8c.
- الملف المنشور المسترجع يطابق ملف Git الحالي byte-for-byte، بطول 21,007 حرفًا.

في سجلات function_edge_logs ضمن نافذة 2026-11-01 من 00:00 إلى 20:42 UTC:
- v21: عدد 5,488 OPTIONS / 200.
- v21: عدد 5,563 POST / 200.
- v21: عدد 18 POST / 401.
- لا تظهر 5xx في التجميع المسترجع لهذه الوظيفة وهذه النافذة.
- سبب 401 غير محدد من السجلات المجمعة.
- وجود HTTP 200 يثبت استجابة Edge، ولا يثبت أن الطلب كان إنشاء PO أو فاتورة أو تسوية عهدة أو أن الأثر المحاسبي صحيح.

---

## 3) UNKNOWN — ما لم تتوفر أدلة كافية لتحديده

1. Cloudflare Pages: لم أتمكن من جلب artifact الواجهة المنشور أو إثبات commit/build lineage أو HTML/JS أو headers/cache. تعذر الوصول إلى جلسة المتصفح المرتبطة، كما تعذر فتح عنوان Buyer المنشور عبر قناة الفحص المتاحة.
2. لا يوجد إثبات حالي بأن Cloudflare يقدم blob Buyer الحالي 6c26444؛ لذلك حالة الواجهة المنشورة UNKNOWN.
3. لم ينفذ authenticated browser E2E لإنشاء مورد، أو PO، أو فاتورة، أو إصدار عهدة/زيادة عهدة، أو رفع المستندات، أو اعتماد المصروف، أو التسوية.
4. لم يُختبر فعليًا Storage binary upload/download/delete، ولا Realtime WebSocket events/reconnect.
5. جدول buyer_custody_payments فارغ؛ لم يمكن اختبار سلوك عزل صفوف دفع فعلية بين شركتين.
6. لم ينفذ اختبار insert/update/delete أو supplier_id reassignment أو concurrency بعد إزالة المشغل القديم؛ الإزالة لم تنفذ أصلًا.
7. تاريخ Production الكامل البالغ 730 migration غير موجود بالكامل في مجلد migrations الحالي الذي يحتوي 43 ملفًا. تم إغلاق Buyer slice فقط، وليس كامل تاريخ المشروع.

---

## 4) CONFLICT — التعارضات الحالية

1. **CURRENT_STATE كان متأخرًا عن الواقع الحي:** سجل LVE575 HEAD = 488dfe، بينما Git main الآن 40bd. كما سجل أن Buyer migration lineage متعارض وأن سياسة الدفع وTRUNCATE ما زالت معيبة، بينما Production/Git الحاليان يثبتان مواءمة Buyer 33/33 وتصحيح السياسة وإلغاء TRUNCATE. تم تصحيح نقطة الاستمرارية في هذا التقرير.
2. **ازدواجية Supplier AP لم تُغلق:** المصدر الحالي أنشأ writer جديدًا sum-based، لكن Production ما زال يشغل writer القديم latest-balance معه. هذا تعارض بين وجود writer canonical جديد واستمرار writer قديم على الحقل نفسه، حتى مع تطابق الأرقام الحالية.
3. لا يوجد تعارض إصدار بين Buyer migrations الـ33 الحالية وProduction ledger في نطاق هذا التحقيق.

---

## 5) UNVERIFIED — ادعاءات أو نتائج لم تُختبر مباشرة

- نجاح واجهة Buyer المنشورة على Cloudflare.
- صحة سلوك المستخدم الفعلي في المودالات بعد النشر.
- E2E كامل لتدفق PO → receiving → invoice → supplier ledger / journal.
- E2E كامل للعهدة: issue → advance → employee acknowledgement → invoice + warehouse receipt proof → finance approval/payment → settlement.
- أثر حذف المشغل القديم على insert/update/delete/concurrency.
- تفسير طلبات POST / 401 الثمانية عشر.

---

## 6) مصفوفة التحقق

| الطبقة | النتيجة | حدود الإثبات |
|---|---|---|
| GitHub / source | CONFIRMED | HEAD 40bd، Buyer blob 6c26444، Edge blob 49c85، و33/33 Buyer migrations متطابقة إصدارًا واسمًا |
| Supabase Production | CONFIRMED مع blocker | العملة EGP، السياسات والصلاحيات الحالية، migration ledger، بيانات AP؛ مشغلا AP ما زالا نشطين |
| Deployed artifact | Edge v21 CONFIRMED / Cloudflare Pages UNKNOWN | Edge source مطابق حرفيًا؛ واجهة Cloudflare لم تُجلب |
| Runtime / E2E | UNVERIFIED | توجد Edge HTTP responses، لكن لا يوجد authenticated UI workflow test |
| Business-data effects | CONFIRMED snapshot / E2E UNVERIFIED | AP يساوي ledger عند الفحص؛ لم تُنشأ معاملات اختبارية ولم يُثبت تدفق جديد |

---

## 7) ما تم فعليًا في هذا التشغيل

1. قراءة CURRENT_STATE.md كاملًا وتثبيت LVE575 كنقطة بداية تاريخية.
2. قراءة Report575 وتعليمات الحوكمة التشغيلية وسياق الذاكرة المرتبط.
3. جلب GitHub branch main وHEAD والـtree والملفات الحالية والـcommits ذات الصلة.
4. مطابقة Buyer migration versions/names بين Git وProduction؛ النتيجة 33/33.
5. تنفيذ SQL SELECT فقط على Production للتحقق من العملة، migrations، السياسات، grants، triggers، function signatures، بيانات AP، وجداول العهد.
6. استرجاع Edge function المنشور ومقارنته حرفيًا مع Git.
7. مراجعة سجلات Edge للوظيفة v21.
8. لم تُنفذ أي كتابة بيانات، أو DDL، أو تعديل RLS/grants/triggers، أو Edge deployment، أو تعديل مصدر تشغيلي.

---

## 8) ما لم يتم ولماذا

- لم أحذف trigger قديمًا؛ لأنه تغيير Production يحتاج migration محددة وخطة rollback واختبارًا يثبت عدم كسر الحسابات، ولم يتوفر اختبار staging/transactional موثق في هذا التشغيل.
- لم أنفذ db push؛ لأن مجلد migrations الحالي لا يحتوي التاريخ الكامل لـ730 إصدارًا، رغم اكتمال Buyer slice.
- لم أعدل Buyer أو Edge؛ لا يوجد عيب جديد مثبت في المصدر الحالي يستلزم تعديلًا.
- لم أعلن E2E أو Production Ready؛ لا توجد جلسة Browser authenticated ولا Cloudflare artifact مثبت.

---

## 9) الخطوة التالية ذات الأولوية الواحدة

**اختبار وإعداد إزالة المشغل القديم trg_sync_supplier_accounts_payable مع الإبقاء على supplier_ledger_sync_accounts_payable بوصفه الكاتب الوحيد.**

قبل أي Production DDL:
- اختبر في staging أو معاملة rollback معزولة insert/update/delete وتغيير supplier_id.
- تحقق من تطابق accounts_payable مع SUM(credit-debit) بعد كل حالة.
- اختبر تزامن عمليتين على المورد نفسه، وتأكد من ترتيب/قفل التحديث.
- جهز migration صغيرة قابلة لإعادة التنفيذ وrollback واضح يعيد trigger القديم عند الحاجة.
- بعد إثبات الاختبار فقط، راجع صلاحية التطبيق على Production.

**لا تُعد إصلاح سياسة buyer_custody_payments أو TRUNCATE؛ فالأدلة الحالية تثبت تطبيقهما. ولا تشغل db push شاملًا.**

---

**Arabic report:** doc/Draft/Reprots/Report578_BUYER_MIGRATION_LINEAGE_RECONCILIATION_SUPPLIER_AP_TRIGGER_20261101.md  
**Operational HEAD:** 40bd00c91f8c52260d867f5cf020104c9e71c161  
**Status:** BUYER MIGRATION SLICE RECONCILED / PAYMENT RLS FIX CONFIRMED / PUBLIC TRUNCATE REVOKED / EDGE v21 BYTE-MATCHED / SUPPLIER AP DATA RECONCILED / DUPLICATE AP TRIGGER OPEN / CLOUDFLARE + AUTHENTICATED E2E UNVERIFIED / NOT CLOSED.
