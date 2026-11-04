# RAWAEA ERP — Buyer Phase 1
# ترتيب ChangeSet التنفيذي وبوابة التحقق

**الهدف:** تطبيق مرحلة Buyer أولًا فقط، مع إبقاء Receiver وSupplierReturn خارج التعديل التشغيلي في هذه المرحلة. هذا الملف هو ترتيب التشغيل الوحيد؛ لا تجمع المسودات التاريخية.

## 1. الترتيب الإلزامي لملفات SQL

تُنفذ الملفات بالتتابع، وكل ملف في migration مستقل، ولا يبدأ التالي قبل نجاح التحقق من السابق:

| الترتيب | الملف | الاعتماد |
|---:|---|---|
| 1 | `03K_buyer_supplier_invoice_duplicate_guard_REVIEWED_DRAFT.sql` | لا يعتمد على أعمدة Buyer الجديدة؛ ينشئ helper خاصًا لمنع التكرار |
| 2 | `03B_buyer_phase1_atomic_contracts_FINAL_REVIEW_DRAFT.sql` | يضيف تصنيف الفاتورة ودفتر الحيازة وعمليات Quick Market الأساسية |
| 3 | `03D_buyer_source_idempotency_and_permission_hardening_REVIEWED_DRAFT.sql` | يعيد تعريف عمليات PO/Quick Market ويشدّد idempotency ونطاق القراءة |
| 4 | `03E_buyer_invoice_posting_guard_FINAL_REVIEW_DRAFT.sql` | يمنع ترحيل Quick Market المباشر ويبقي كاتب PO الأصلي |
| 5 | `03F_buyer_invoice_handover_progress_FINAL_REVIEW_DRAFT.sql` | قراءة تقدم التسليم على مستوى كل بند |
| 6 | `03H_buyer_goods_custody_realtime_REVIEWED_DRAFT.sql` | يضيف جدول الحيازة إلى publication بعد إنشائه |
| 7 | `03J_buyer_draft_ownership_guards_REVIEWED_DRAFT.sql` | يعتمد على أعمدة التصنيف والمشتري التي أضافها 03B |

**لا تشغّل 03B قبل 03K** لأن وظائف الإنشاء/التعديل تستدعي helper منع التكرار. **لا تشغّل 03D قبل 03B** لأنه يعيد تعريف عمليات تعتمد على جدول وأعمدة 03B. **لا تشغّل 03J قبل 03B** لأنه يتحقق من `purchase_source` و`purchaser_user_id`.

كل ملف SQL مستقل ويحتوي BEGIN/COMMIT. عند تحويله إلى migration، لا تلصق ملفين في migration واحدة ولا تنفذ ترتيبًا متوازيًا. بعد كل migration: افحص تعريف الوظائف والقيود والمنح من قاعدة البيانات الحية.

**ما تم فعليًا في 4 نوفمبر:** طبقت migrations 01–07، ثم 08 لإضافة duplicate guard إلى Legacy، ثم 09 لإزالة أي wildcard خام من QMP create وLegacy update والاعتماد على resolver الفعال والمالك الحقيقي. ملف التنفيذ الدقيق هو `03L_buyer_effective_permission_only_rpc_hardening.sql`. راجع Report624 للـversion/hash وحالة Production.

## 2. Edge Function القائمة فقط

يُحدّث `save-purchase-order` الحالي (slug واحد، لا وظيفة جديدة) بعد نجاح SQL:

- كل RPC جديد يعتمد `auth.uid()` يُستدعى بــ `profileClient` وبـJWT المستخدم؛ لا يستخدم `service_role` في هذه المسارات.
- عمليات PO invoice: `CREATE_PO_INVOICE`, `UPDATE_PO_INVOICE`.
- عمليات Quick Market: `CREATE_QUICK_MARKET_INVOICE`, `UPDATE_QUICK_MARKET_INVOICE`, `DELETE_QUICK_MARKET_DRAFT`.
- حيازة البضاعة: `REGISTER_QUICK_MARKET_HANDOVER`, `GET_BUYER_GOODS_CUSTODY_BALANCES`, `GET_QUICK_MARKET_HANDOVER_PROGRESS`.
- ملكية المسودات: `UPDATE_BUYER_LEGACY_DRAFT`, `DELETE_BUYER_DRAFT_INVOICE`.
- الترحيل: استبدال POST_INVOICE باستدعاء `purchase_post_buyer_invoice_atomic` عبر `profileClient`.
- قراءة الفواتير وتفاصيلها: لا تُرجع لكل مشتري إلا فواتيره هو؛ التوسيع إلى الشركة يتطلب `finance` أو `finance_manager` أو مالك النظام. تفاصيل الفواتير تتبع نفس نطاق الآباء.

يظل `purchase_post_invoice_atomic` الأصلي كما هو. لا يُزال حارس `PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED`. ولا يُضاف أي مسار استلام Quick Market الآن؛ Receiver مؤجل صراحة.

## 3. Buyer UI

التعديل الوحيد في المستودع التشغيلي هو:
`companies/company-1/purchasing/buyer.html`

- فصل PO invoice عن Quick Market في الأزرار والنماذج.
- Quick Market يستخدم موردًا نشطًا من الدليل المركزي، فرعًا، رقم فاتورة المورد، صنفًا من كتالوج DB، كمية وسعرًا فعليًا يدويًا. لا يعرض `cost_price` ولا يستعمله افتراضيًا.
- مصدر التسوية: عهدة نقدية مؤكدة للمشتري أو ائتمان المورد؛ لا يختلطان.
- حيازة المورد→Buyer تسجل حدثًا append-only بعد التسليم الفعلي، والمركبة اختيارية.
- عرض تقدم التسليم من RPC، والرصيد مشتق من أحداث الحيازة لا من السيارة.
- «فواتيري» يبدأ بالمستخدم الحالي. لا يظهر «كل فواتير الشركة» إلا للصلاحية المالية/مالك النظام.
- تعديل/حذف المسودة يمر عبر غلاف الملكية حسب مصدرها.
- عرض رصيد العهدة النقدية يخصم المصروفات وحجوزات Quick Market بصافي غير مزدوج.

## 4. بوابة بيانات API

اعتبارًا من 2026-10-30، لم تعد جداول public الجديدة تُعرض تلقائيًا عبر Data API. ملف 03B يمنح SELECT صراحةً للمستخدم المصادق على جدول الحيازة مع RLS؛ يجب التحقق من Data API grant والـRLS معًا. لا تمنح DML مباشرًا على دفتر الأحداث. مصدر: [Supabase breaking change — tables not exposed automatically](https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically).

## 5. اختبارات ما قبل الإنتاج وما بعده

### ما قبل التغيير
1. snapshot counts وSHA للملفات وEdge version.
2. dry-run لكل SQL داخل transaction واحدة مع ROLLBACK، بالترتيب أعلاه، لإثبات صحة DDL والتبعيات دون تغيير دائم.
3. راجع Supabase Advisors، وميّز الملاحظات القائمة عن أي ملاحظة جديدة.
4. افحص عدم وجود صفوف/أحداث Buyer جديدة أو بيانات QA غير منضبطة.

### بعد نشر SQL/Edge/UI
1. التحقق من signatures وSECURITY DEFINER وsearch_path الفارغ وACL وRLS.
2. اختبار RPC بمستخدم مصادق فعلي من الشركة وبصلاحياته؛ اختبارات الكتابة تُنفذ داخل transaction rollback فقط.
3. اختبار عمليات GET_DATA على مستخدمين مختلفين للتأكد من عدم تسرب فواتير أو تفاصيل مستخدم آخر.
4. اختبار Buyer من Cloudflare: إنشاء PO Draft لا يغير مخزونًا أو AP/GL؛ إنشاء Quick Market Draft لا يغير مخزونًا أو AP/GL/الخزينة؛ handover يغير دفتر الحيازة فقط.
5. إعادة المحاولة بنفس operation_id ثم payload مختلف؛ الأولى idempotent والثانية ترفض.
6. اختبارات concurrency على عهدة واحدة في بيئة آمنة/معاملة معزولة.
7. لا تستخدم فواتير PINV-1000/1001/QA-SR ولا تعدّلها أو تحذفها.
8. لا تختبر Receiver في هذه المرحلة.

## 6. حدود النشر

- لا تعدل Receiver.html أو أي تطبيق آخر أو النظام الأم أو core.js.
- لا تنشئ Edge Function جديدة أو فرعًا أو PR.
- لا تحذف أو تعكس الفواتير التاريخية ولا تعدل المخزون أو المورد أو GL أو الخزينة الحالية.
- إذا فشل أي اختبار أو ظهر أثر مالي/مخزني غير متوقع، يتوقف النشر ويُرجع فقط آخر تغيير غير مؤثر؛ لا يجرى rollback للمخطط بعد وجود أحداث حيازة أو مستندات مصنفة.
