# تقرير CTO — LVE-2026-11-02-579
## إغلاق ازدواجية Supplier Accounts Payable وتأمين الكاتب المركزي

**تاريخ التنفيذ:** 2026-11-02 — Africa/Cairo  
**Production:** SMART ERP — Supabase ref `fiilmooggumokxanwiyx`  
**النطاق:** `public.supplier_ledger` → `public.suppliers.accounts_payable`  
**الحالة:** `FIX APPLIED — SQL ROLLBACK E2E VERIFIED / CONCURRENCY MULTI-SESSION UNVERIFIED / BUYER OVERALL NOT CLOSED`

---

## 1. نقطة الاستئناف والتحقق من الحوكمة

تمت مراجعة:
- `CURRENT_STATE.md` الحالي (3,789 سطرًا قبل هذا التحديث)، وكان LVE-578 هو أحدث checkpoint.
- `doc/Draft/Reprots/Report578_BUYER_MIGRATION_LINEAGE_RECONCILIATION_SUPPLIER_AP_TRIGGER_20261101.md`.
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` (2,606 سطرًا / 29,578 حرفًا؛ أقسام الحوكمة حتى 66).
- `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`.

تم التعامل مع LVE-578 كدليل استرشادي، ثم إعادة التحقق من Production وGit قبل التنفيذ.

## 2. Git lineage — CONFIRMED

المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`، الفرع `main`.

| الحدث | Commit |
|---|---|
| نقطة البداية المثبتة في LVE-578 | `40bd00c91f8c52260d867f5cf020104c9e71c161` |
| إضافة Migration الكاتب المركزي وإزالة المشغل القديم | `0b02a33d5c05cfb67c6254da589e4752047d4ab6` |
| حذف دالة المشغل القديمة اليتيمة | `d03a2788447b78353d91a4ae7811e5ed28c6b991` |

الـparent المباشر لالتزام إضافة Migration هو `40bd00c...`. والـparent المباشر لالتزام حذف الدالة هو `0b02a33...`. لم يتم تعديل `companies/company-1/main.html` أو أي تطبيق تشغيلي أو Edge Function.

ملفات Migration المضافة إلى Git:
- `supabase/migrations/20261102142016_supplier_ap_single_writer_locking_and_legacy_trigger_retirement.sql`
- `supabase/migrations/20261102142201_drop_orphaned_legacy_supplier_ap_definer_function.sql`

## 3. التحقيق في السبب الجذري — CONFIRMED

كان على `supplier_ledger` مشغلان نشطان يكتبان الحقل نفسه `suppliers.accounts_payable`:

1. `supplier_ledger_sync_accounts_payable` → `app_private.sync_supplier_accounts_payable()`:
   - يحسب صافي الدفتر `SUM(credit - debit)`.
   - كان يعالج نقل القيد بين موردين.
   - لكنه لم يكن يقفل صف المورد قبل حساب SUM؛ لذلك لا يكفي وحده لإثبات سلامة التزامن بين معاملتين متزامنتين.

2. `trg_sync_supplier_accounts_payable` → `public.sync_supplier_accounts_payable_from_ledger()`:
   - يعتمد على آخر `balance` مسجل بدل إعادة احتساب صافي الدفتر.
   - لا يعالج نقل `supplier_id` بإعادة حساب المورد القديم.
   - يكتب projection نفسه، وبالتالي يمثل ازدواجية ملكية ومصدر اختلاف محتمل تحت التصحيح والتزامن.

تطابقت الأرقام قبل الإصلاح: 4 موردين، إجمالي الرصيد المخزن 3,970، صافي الدفتر 3,970، وعدد قيود الدفتر 2. تطابق اللقطة لم يكن دليلًا على صحة تصميم وجود كاتبين.

## 4. الإصلاح المنفذ في Production — CONFIRMED

### Migration `20261102142016`

تم تحديث الدالة المركزية `app_private.sync_supplier_accounts_payable()` لتقوم بالآتي:

1. تحديد المورد القديم والجديد حسب INSERT / UPDATE / DELETE.
2. قفل صفوف الموردين المتأثرة قبل إعادة الحساب.
3. ترتيب الأقفال تصاعديًا حسب UUID لتقليل احتمالات deadlock عند نقل القيد بين موردين.
4. إعادة حساب `SUM(credit - debit)` بعد الحصول على الأقفال.
5. عند تغيير `supplier_id`، إعادة حساب المورد القديم والجديد.
6. الإبقاء على `SECURITY DEFINER` مع `search_path = ''` وجميع أسماء الجداول مؤهلة بالمخطط.
7. إزالة المشغل القديم `trg_sync_supplier_accounts_payable`.

### Migration `20261102142201`

بعد التحقق من عدم وجود أي اعتماد قاعدة بيانات متبقٍ على الدالة القديمة، تم حذف:
`public.sync_supplier_accounts_payable_from_ledger()`.

سبب الحذف ليس مجرد تنظيف؛ ففحص الصلاحيات أثبت أن الدالة القديمة كانت SECURITY DEFINER وقابلة للتنفيذ بواسطة anon وauthenticated، رغم أنها trigger-only ولم يعد لها trigger أو اعتماد. بعد حذفها لم تعد موجودة في Production.

لم يتم إنشاء Edge Function جديد، ولم يتم تغيير Gateway أو Cap Spend.

## 5. الاختبارات — CONFIRMED / UNVERIFIED

### اختبار SQL معزول داخل Transaction ثم ROLLBACK — PASS

قبل الترحيل، تم اختبار جسم الدالة المقترح داخل معاملة، مع تعطيل المشغل القديم مؤقتًا داخل المعاملة فقط، ثم ROLLBACK.

بعد تطبيق الترحيل، أُعيد الاختبار على التركيب الفعلي النهائي، مع المشغل المركزي الوحيد النشط:

| الحالة | المتوقع | النتيجة |
|---|---:|---|
| INSERT: credit 17 | AP = 17 | PASS |
| UPDATE: credit 20 / debit 4 | AP = 16 | PASS |
| نقل القيد إلى مورد آخر: credit 25 / debit 2 | القديم = 0 والجديد = 23 | PASS |
| DELETE | AP للمورد الجديد = 0 | PASS |
| بقايا بيانات الاختبار بعد ROLLBACK | 0 | PASS |

كل بيانات الاختبار أُدخلت داخل Transaction انتهت بـROLLBACK. لم تبقَ بيانات تجريبية في Production.

### فحص Production بعد الإصلاح — PASS

- عدد مشغلات `supplier_ledger` غير الداخلية: **1**.
- المشغل النشط الوحيد: `supplier_ledger_sync_accounts_payable`.
- دالة الكاتب الوحيدة: `app_private.sync_supplier_accounts_payable()`.
- عدد الموردين المخالفين بين `accounts_payable` وصافي دفتر المورد: **0**.
- إجمالي الرصيد المخزن: **3,970.00**.
- إجمالي صافي الدفتر: **3,970.00**.
- صفوف اختبار متبقية بالمرجع `CTO-AP-ROLLBACK-TEST`: **0**.
- الدالة القديمة `public.sync_supplier_accounts_payable_from_ledger()`: غير موجودة.
- صلاحية EXECUTE على الدالة المركزية إلى anon: **false**، وإلى authenticated: **false**.

### ما لم يُختبر — UNVERIFIED

- لم تتوفر بيئة Staging مطابقة لهذا العقد؛ مشروع `rawaea-staging` لا يحتوي مشغلات Supplier AP محل المهمة، ولذلك لا يصلح كبديل لاختبارها.
- لم يُنفذ اختبار multi-session حقيقي لتزامن عمليتين متوازيتين. آلية القفل والترتيب أضيفت لمعالجة هذا الخطر، لكن لا يُسجل اختبار التزامن كنجاح حتى تنفيذه بجلسات مستقلة.
- لم يُنفذ Browser E2E مصادق عليه لواجهة Buyer، ولا تحقق Cloudflare artifact في هذه المهمة. لذلك لا يُعلن إغلاق Buyer بالكامل.

## 6. مراجعة Security Advisors — دين تقني خارج نطاق التعديل الحالي

بعد حذف الدالة القديمة، أظهر فحص Supabase Security Advisors ما يلي على Production:
- 24 جدولًا عليها RLS مفعّل دون سياسات RLS.
- 18 دالة SECURITY DEFINER قابلة للتنفيذ بواسطة anon.
- 128 دالة SECURITY DEFINER قابلة للتنفيذ بواسطة authenticated.
- دالة واحدة ذات `search_path` قابل للتغيير: `public.sales_decision_default_policy`.
- حماية كلمات المرور المسربة غير مفعّلة.

هذه نتائج تدقيق على مستوى المشروع، وليست كلها عيوبًا مثبتة في Buyer أو Supplier AP. لا يجوز تطبيق REVOKE شامل أو تفعيل RLS عشوائيًا؛ يجب مراجعة كل دالة وجدول بحسب عقده والصلاحيات المقصودة. الدالة القديمة الخاصة بـSupplier AP أزيلت بالفعل، ولم تعد ضمن نتائج الدوال القابلة للتنفيذ.

مرجع Supabase:
- https://supabase.com/docs/guides/database/database-linter
- https://supabase.com/docs/guides/auth/password-security

## 7. ما لم يتغير

- لم يتم تعديل `main.html`.
- لم يتم تعديل Buyer أو أي تطبيق منفصل.
- لم يتم تعديل Edge v21 أو نشر Edge Function.
- لم يتم تعديل مخطط المخزون أو القيود المحاسبية أو بيانات الموردين القائمة.
- لم يتم إعادة إصلاح سياسة `buyer_custody_payments` أو صلاحيات TRUNCATE؛ LVE-578 والتحقق الحالي يثبتان إغلاقهما.
- لم يتم تنفيذ `db push` شامل.

## 8. تعليمات CTO التالي — نقطة الاستئناف الدقيقة

ابدأ من HEAD الحالي في `erp-frontend/main`، وتحقق من parent commits ووجود Migration الملفين أعلاه، ثم أعد فحص المشغل الوحيد وصافي AP في Production.

بعدها نفّذ بالترتيب:

1. **اختبار تزامن حقيقي multi-session** على مورد واحد، ثم على موردين مع reassignment، باستخدام جلستين مستقلتين ومعاملة اختبارية قابلة للتنظيف. لا تعلن concurrency closure قبل إثباته.
2. راجع Security Advisor findings على مستوى كل دالة/جدول؛ لا تنفذ إصلاحًا جماعيًا ولا تغيّر سياسات tenant دون إثبات العقد.
3. استكمل التحقق من Cloudflare Pages artifact وAuthenticated Buyer browser E2E، بما في ذلك PO → Receiving → Invoice → Supplier Ledger / Journal، ثم مسار العهدة الكامل.
4. أبقِ `main.html` دون لمس. أي تعديل واجهة مطلوب يُسلّم للمالك جراحيًا بالنص الأصلي والمقطع البديل الكامل والموضع الدقيق.
5. لا تكرر إصلاح Buyer migration lineage أو سياسة الدفع أو TRUNCATE؛ هذه مثبتة الإغلاق في الأدلة الحالية.

**نقطة الإغلاق:** ازدواجية كاتب Supplier AP أُغلقت في Production، واختبارات INSERT/UPDATE/DELETE/reassignment اجتازت اختبار SQL المعزول. إغلاق التزامن متعدد الجلسات والواجهة المصادق عليها ما زال مفتوحًا.

---
**Report:** `doc/Draft/Reprots/Report579_SUPPLIER_AP_SINGLE_WRITER_LOCKING_RETIREMENT_20261102.md`  
**Production migrations:** `20261102142016`, `20261102142201`  
**Operational Git commits:** `0b02a33d5c05cfb67c6254da589e4752047d4ab6`, `d03a2788447b78353d91a4ae7811e5ed28c6b991`
