# تقرير 630 — تأمين مرتجعات المشتريات ككاتب مركزي / مراجعة Parent Consumer Map
**التاريخ:** 4 نوفمبر 2026 — Africa/Cairo  
**نقطة البداية:** LVE629  
**النطاق:** صلاحيات جدولي المرتجعات في Production، مستهلكو Parent/Buyer، وتوثيق النسخ/الترحيلات.

## 1. القرار والتنفيذ

بعد مسح مستهلكي المستودع والتحقق من مسار الكتابة الفعلي، ثبت أن تطبيقات الواجهة لا تحتاج DML مباشرًا على `purchase_returns` أو `purchase_return_details`. الكتابة تتم عبر Edge `save-purchase-order` ثم RPCs مركزية بصلاحية `service_role`.

تم تطبيق Migration:
- الاسم: `buyer_purchase_returns_central_writer_only_20261104`
- الإصدار: `20261104214839`
- ملف المصدر في المستودع التشغيلي: `supabase/migrations/20261104214839_buyer_purchase_returns_central_writer_only_20261104.sql`
- تطبيق Supabase: `success=true`.

## 2. Consumer Map — ما الذي يقرأ ويكتب المرتجعات؟

### Parent `companies/company-1/main.html`
- `getData(table)` يقرأ مباشرة من Supabase باستخدام `supabase.from(table).select('*').eq('company_id', companyId()).limit(300)`.
- لوحة المشتريات وواجهة المرتجعات تستدعي قراءة `purchase_returns` مباشرة؛ لذلك أبقينا SELECT للمستخدم المصادق عليه مع RLS على الشركة.
- إنشاء المرتجع يتم عبر `api('CREATE_RETURN', payload)`.
- ترحيل المرتجع يتم عبر `api('POST_RETURN', {id})`.
- لم نجد `supabase.from('purchase_returns')` أو `supabase.from('purchase_return_details')` للكتابة المباشرة في Parent.

### Buyer `companies/company-1/purchasing/buyer.html`
- يقرأ بيانات المرتجعات عبر محرك `GET_DATA` ولا ينشئ أو يرحل مرتجعًا مباشرة.
- لا يستخدم DML مباشرًا على الجدولين.
- لا يعتمد على صلاحيات INSERT/UPDATE/DELETE للمستخدم المصادق عليه.

### بقية تطبيقات الشركة
تم مسح 34 ملف HTML/JS في `companies/company-1`، بما فيها المبيعات والتوزيع والمخازن والمكتب والتطبيقات الفرعية. لم تظهر مستهلكات أخرى لـ `purchase_returns` أو `purchase_return_details` أو عمليتي إنشاء/ترحيل المرتجع.

تم أيضًا فحص ملفات Edge Functions الستة في المستودع:
- لا توجد إشارة إلى جداول المرتجعات في بقية الدوال.
- `save-purchase-order` هو مسار الكتابة الوحيد في Edge.

## 3. RPCs المركزية — إثبات عقد الكتابة

في Production:
- `purchase_create_return_atomic`: `SECURITY DEFINER`، صلاحية EXECUTE لـ `service_role` و`postgres` فقط. ينشئ/يحدّث رأس المرتجع ويضيف تفاصيله.
- `purchase_post_return_atomic`: `SECURITY DEFINER`، صلاحية EXECUTE لـ `service_role` و`postgres` فقط. ينفذ الترحيل عبر الكاتب المركزي.
- Edge v26 يستدعي العمليتين في عمليتي `CREATE_RETURN` و`POST_RETURN` بعد تحقق المستخدم والصلاحية والشركة.

لم نمنح authenticated صلاحية تنفيذ RPC مباشرة ولم نغير الدالتين أو تواقيعهما.

## 4. التعديل الأمني في Production

### الصلاحيات بعد Migration
| الدور | SELECT | INSERT | UPDATE | DELETE |
|---|---:|---:|---:|---:|
| anon | لا | لا | لا | لا |
| authenticated | نعم | لا | لا | لا |
| service_role | نعم | نعم | نعم | نعم |

### RLS
- استبدال `purchase_returns_company` من سياسة `ALL` إلى `purchase_returns_select_company` من نوع SELECT فقط، بشرط `company_id = current_user_company_id()`.
- استبدال `purchase_return_details_company` من سياسة `ALL` إلى `purchase_return_details_select_company` من نوع SELECT فقط، مع تحقق أن رأس المرتجع تابع للشركة الحالية.
- إزالة كل صلاحيات anon وauthenticated ثم منح SELECT فقط إلى authenticated.
- service_role وpostgres احتفظا بصلاحيات الكاتب المركزي.

### الاختبارات
- نص Migration اختُبر داخل `BEGIN/ROLLBACK` قبل التطبيق.
- Migration سُجلت في Production بالنسخة `20261104214839`.
- أعيد فحص ACL والسياسات بعد التطبيق.
- `has_table_privilege` أكد أن authenticated يملك SELECT فقط، ولا يملك INSERT/UPDATE/DELETE على الجدولين؛ anon لا يملك أيًا منها؛ service_role احتفظ بـDML.
- نفذنا قراءة داخل معاملة باستخدام `SET LOCAL ROLE authenticated` وJWT subject لمستخدم نشط؛ تم حل الشركة ونجح SELECT على الجدولين (0 صفوف مرئية وقت الاختبار). المعاملة انتهت بـROLLBACK.
- لا بيانات أعمال أُنشئت أو عُدلت.

## 5. توثيق المصدر التشغيلي

تم تسجيل ملفات SQL المطبقة في المستودع التشغيلي:
1. `supabase/migrations/20261104213909_buyer_phase1_hardening_20261104.sql` — blob `<verified-on-fetch>`.
2. `supabase/migrations/20261104214839_buyer_purchase_returns_central_writer_only_20261104.sql` — migration version `20261104214839`.

وتم أرشفة المصدر الحي لـ Edge v26 في مستودع الحوكمة:
- `Current/CTO/EdgeSnapshots/20261104/save-purchase-order_v26/index.ts`
- SHA-256: `fb31ac953213d6f30a9e545f1da3b9075ca28638b5032450618769d20f2cb5b4`
- Blob: `577442e1b8fd22be056374292438a7074b966ff1`
- Manifest: `Current/CTO/EdgeSnapshots/20261104/save-purchase-order_v26/DEPLOYMENT_MANIFEST.md`
- تم التحقق أن الأرشيف مطابق للمصدر الحي المنشور.

## 6. ملاحظة Parent — العملة

أظهر فحص Parent `main.html` وجود حقول client payload ثابتة `currency: 'SAR'` في نموذج عرض المورد وفاتورة الشراء.
لكن Edge v26 في عمليتي `CREATE_QUOTATION` و`CREATE_INVOICE` لا يثق بقيمة العميل؛ يستدعي `getSystemCurrency()` من إعدادات الشركة، وبالتالي القيمة المسجلة في قاعدة البيانات هي عملة النظام (حاليًا EGP).
- لا يوجد تعديل في `main.html` ضمن هذه الدفعة.
- يجب إزالة ثوابت SAR من واجهة Parent لاحقًا لتجنب عرض/إرسال قيمة مضللة، مع بقاء العملة مصدرها إعدادات النظام الأم.
- ظهر أيضًا ثابت SAR في وحدة Sales Quote أخرى؛ هذا خارج نطاق Buyer والمشتريات ويحتاج تدقيقًا منفصلًا.

## 7. حالة المشروع بعد التنفيذ

- LVE628: Buyer custody/settlement/delete hardening + Edge v26 + Buyer Realtime/unknown outcome.
- LVE629: Quick Market supplier local search + كشف حدود Storage SELECT.
- LVE630: إغلاق DML المباشر على جداول المرتجعات بعد إثبات Consumer Map، مع إبقاء القراءة وكتابة RPC المركزية.

**المتبقي:** صورة فاتورة المورد وربطها بـ `purchase_attachments`، Storage SELECT محدد لـ Finance/Warehouse، مصفوفة RLS فواتير الشراء، Buyer→Warehouse/Supplier والقبول الجزئي، تحقق Cloudflare deployment، واختبارات Buyer E2E مصادق عليها. Receiver لا يزال مؤجلًا.

**الحالة:** `RETURNS CENTRAL WRITER ENFORCED / PARENT SELECT PRESERVED / SERVICE ROLE RPC WRITERS VERIFIED / NO BUSINESS DATA CHANGE / BUYER NOT E2E CLOSED`.
