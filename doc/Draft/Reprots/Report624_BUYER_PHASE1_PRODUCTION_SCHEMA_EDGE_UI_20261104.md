# Report 624 — تنفيذ المرحلة الأولى من Buyer على Production
**التاريخ:** 4 نوفمبر 2026  
**النطاق:** Buyer فقط — قاعدة SMART ERP + Edge Function القائمة + مصدر Buyer في المستودع التشغيلي.  
**المؤجل صراحة:** Receiver.html / Receiver workflow UI، SupplierReturn acceptance، وأي تعديل للنظام الأم أو Core أو التطبيقات الأخرى.

## 1. الحالة التنفيذية

تم تنفيذ الجزء الخلفي من مرحلة Buyer في Production، ونُشرت النسخة 25 من Edge Function القائمة `save-purchase-order`، كما عُدّل ملف Buyer المطلوب وحده في `erp-frontend/main`.

| المكوّن | الحالة |
|---|---|
| Supabase SMART ERP schema/RPC/RLS/Realtime | **مطبق ومتحقق من الوجود والتواقيع والمنح** |
| Edge `save-purchase-order` | الإصدار 25 ACTIVE |
| Buyer `companies/company-1/purchasing/buyer.html` | التعديل committed على main |
| Buyer Cloudflare Pages production deployment | **منشور ومؤكد**؛ لوحة Cloudflare تعرض commit `3717c027` وPreview deployment `633d858b.rawaea-erp.pages.dev` |
| اختبار مستخدم مشتريات مصادق end-to-end | لم ينفذ؛ لا توجد جلسة Buyer مفتوحة في المتصفح الحالي |
| Receiver | لم يُعدل ولم يُنشر |
| بيانات الفواتير/المخزون/المورد/القيود/الخزينة | لم تُنشأ أو تُعدل لهذا التنفيذ |

تم تأكيد اكتمال Cloudflare Pages deployment للـcommit الحالي من لوحة Cloudflare. هذا يثبت النشر فقط؛ لم يتم اختبار تحميل التطبيق وتفاعلاته من جلسة Buyer مصادق.

## 2. تغييرات قاعدة البيانات المطبقة

المشروع: `fiilmooggumokxanwiyx` — SMART ERP.  
تم تطبيق migrations التالية بالتتابع، وكلها أعادت `success=true`:

| رقم | Migration | الغرض |
|---:|---|---|
| 1 | `buyer_phase1_01_supplier_invoice_guard` | منع تكرار رقم فاتورة المورد لنفس المورد بقفل تزامني |
| 2 | `buyer_phase1_02_core_quick_market_and_goods_custody` | مصدر الفاتورة، مصدر التسوية، دفتر حيازة البضاعة، Quick Market |
| 3 | `buyer_phase1_03_po_idempotency_and_permission_hardening` | عمليات PO/Quick Market المحصنة وIdempotency |
| 4 | `buyer_phase1_04_invoice_posting_guard` | منع ترحيل Quick Market قبل استلام Receiver، مع الحفاظ على PO |
| 5 | `buyer_phase1_05_invoice_handover_progress` | قراءة تقدم تسليم كل بند إلى عهدة Buyer |
| 6 | `buyer_phase1_06_goods_custody_realtime` | عضوية أحداث الحيازة في Realtime |
| 7 | `buyer_phase1_07_draft_ownership_guards` | منع مشتري من تعديل/حذف مسودة مشتري آخر |
| 8 | `buyer_phase1_08_legacy_invoice_duplicate_guard` | إعادة تثبيت غلاف Legacy بعد إضافة حارس تكرار رقم فاتورة المورد إليه |
| 9 | `buyer_phase1_09_effective_permission_only_rpc_guards` | إزالة أي تجاوز لصلاحية `*` من حقل المستخدم الخام؛ الاعتماد على `current_user_has_effective_permission` والمالك الفعلي فقط |

### 2.1 الدفتر المركزي

تم إنشاء `public.buyer_goods_custody_events`:
- Append-only trigger `buyer_goods_custody_events_append_only` فعال.
- RLS مفعّل وسياسة القراءة الوحيدة هي `buyer_goods_custody_events_select_authorized`.
- authenticated يملك SELECT فقط؛ لا INSERT/UPDATE/DELETE مباشر.
- Realtime membership موجود.
- لا يوجد رصيد قابل للتحرير؛ الرصيد مشتق من مجموع `qty_delta`.
- المركبة `vehicle_id` اختيارية وليست شرطًا أو مفتاحًا للرصيد.

### 2.2 الوظائف المنشورة

تم التحقق من وجود التواقيع التالية، وأن SECURITY DEFINER الجديدة تضبط `search_path = ''`:

- `purchase_create_po_invoice_atomic`
- `purchase_update_po_invoice_atomic`
- `purchase_create_quick_market_invoice_atomic`
- `purchase_update_quick_market_invoice_atomic`
- `purchase_delete_quick_market_draft_atomic`
- `buyer_goods_custody_register_handover_atomic`
- `buyer_goods_custody_get_balances_atomic`
- `buyer_goods_custody_get_invoice_handover_progress_atomic`
- `purchase_post_buyer_invoice_atomic`
- `purchase_update_buyer_legacy_draft_atomic`
- `purchase_delete_buyer_draft_invoice_atomic`

الدالة الداخلية `app_private.assert_unique_purchase_supplier_invoice` ليست SECURITY DEFINER، ولا يملك anon أو authenticated أو service_role EXECUTE مباشرًا عليها؛ تستدعيها أغلفة العمليات من سياق مالك الوظيفة.

### 2.3 حماية الترحيل

- `purchase_post_invoice_atomic` الأصلية لم تتغير.
- Edge يوجّه POST_INVOICE إلى `purchase_post_buyer_invoice_atomic`.
- Quick Market يُرفض عند محاولة الترحيل من Buyer، ويشترط استلام المخزن من Receiver مستقبلًا.
- PO يستخدم الكاتب الأصلي؛ لا ينشئ هذا الغلاف حركة مخزون أو AP ثانية.
- لا يوجد مسار استلام Quick Market في هذه المرحلة، ولا تغيير في Receiver.

## 3. Edge Function

تم تحديث slug القائمة فقط `save-purchase-order` إلى:
- **Version:** 25
- **Status:** ACTIVE
- **SHA-256:** `793ba5412a27813aa715da4078971a150d592dd03b53833148b9e99a37b5be62`

أضيفت العمليات:
`CREATE_PO_INVOICE`, `UPDATE_PO_INVOICE`, `CREATE_QUICK_MARKET_INVOICE`, `UPDATE_QUICK_MARKET_INVOICE`, `REGISTER_QUICK_MARKET_HANDOVER`, `GET_QUICK_MARKET_HANDOVER_PROGRESS`, `GET_BUYER_GOODS_CUSTODY_BALANCES`, `DELETE_QUICK_MARKET_DRAFT`, `UPDATE_BUYER_LEGACY_DRAFT`, `DELETE_BUYER_DRAFT_INVOICE`.

جميع RPC التي تعتمد على `auth.uid()` تستخدم `profileClient` مع JWT المستخدم، لا Service Role. POST_INVOICE كذلك يستخدم `profileClient`.

### 3.1 نطاق فواتير المستخدم

تم تعديل GET_DATA:
- `purchase_invoices`: مشتري عادي يرى فواتيره حسب `purchaser_user_id` أو `created_by`.
- `purchase_invoice_details`: تفاصيل فواتير المستخدم نفسه فقط.
- المالية/مدير المالية/مالك النظام يملكون نطاق العرض الشامل.
- GET_DATA للمركبات يسمح لمستخدم المشتريات بقراءة مركبات الشركة النشطة/المتاحة؛ لا يغير أي تعيين مركبة.

لم تُنشأ Edge Function جديدة.

## 4. Buyer UI

الملف الوحيد المعدل في المستودع التشغيلي:
`companies/company-1/purchasing/buyer.html`

- فصل زر/مسار فاتورة PO عن شراء السوق السريع.
- Quick Market أصبح نموذجًا مستقلًا بلا PO، بمورد مركزي نشط، فرع، رقم فاتورة مورد، بنود من كتالوج الأصناف، كمية وسعر فعلي يدوي.
- إزالة عرض `cost_price` من بحث الأصناف وعدم استخدامه كسعر افتراضي.
- اختيار مصدر التسوية: عهدة الموظف النقدية أو ائتمان المورد؛ العهدة مطلوبة فقط لمصدر EMPLOYEE_CUSTODY.
- حجز قيمة فواتير Quick Market من المتاح النقدي، مع طرح المصروفات المرتبطة بالفاتورة من الحجز نفسه حتى لا تخصم القيمة مرتين.
- قائمة «فواتيري» تبدأ بالمستخدم الحالي؛ GET_DATA يفرض نطاق الملكية من الخادم، والمالية تستطيع توسيع العرض.
- تعديل/حذف المسودات يمر عبر العمليات الجديدة بحسب مصدر الفاتورة.
- إثبات تسليم المورد إلى Buyer بكمية لكل صنف، وإثبات مستند مرفق، ومركبة اختيارية.
- تبويب «رصيدي» تحول إلى دفتر عهدة البضاعة: رصيد حسب الصنف والفرع، وسجل الأحداث؛ لا يستعمل رصيد Fleet كبديل.
- صفحة «عهدتي» تعرض رصيد حيازة البضاعة وتخصم حجوزات Quick Market من المتاح النقدي.

**Buyer blob SHA:** `9cc971d8c5ae9ce960c9395d53e36d43a30e9c73`  
**آخر commit تعديل Buyer:** `3717c0279b856127d29fb9f912ec502523761da5`.

تم فحص JavaScript inline في الملف، ونجح parsing دون SyntaxError. وتمت مقارنة أصناف Tailwind المستخدمة مع `buyer.tailwind.css`؛ لا توجد utility classes جديدة ناقصة من CSS الحالي.

## 5. اختبارات وتحقق Production

### 5.1 التواقيع والحماية
- جميع الوظائف المطلوبة موجودة بالتواقيع المتوقعة؛ Migration 09 أعادت تثبيت الحارسين بعد إزالة wildcard الخام.
- SECURITY DEFINER الجديدة لديها `search_path` فارغ.
- anon لا يملك EXECUTE على الوظائف الجديدة.
- جدول الحيازة RLS=ON، authenticated SELECT=true، وINSERT/UPDATE/DELETE=false.
- سياسة واحدة للقراءة، وAppend-only trigger فعال.
- Realtime membership=true.
- اختبارات استدعاء غير مصادق لعمليات Quick Market والقراءة والترحيل رفضت الوصول برسائل AUTH متوقعة؛ لم ينتج عنها أي صف.

### 5.2 الحالة الفعلية للبيانات بعد التنفيذ

| البيان | العدد/القيمة الحالية |
|---|---:|
| العملة من app_settings | EGP |
| purchase_invoices | 3 |
| LEGACY_UNCLASSIFIED invoices | 3 |
| PURCHASE_ORDER invoices | 0 |
| QUICK_MARKET invoices | 0 |
| buyer_goods_custody_events | 0 |
| buyer_custodies | 0 |
| buyer_custody_expenses | 0 |
| inventory_log | 76 |
| supplier_ledger | 2 |
| purchase_returns | 0 |
| journal_entries Posted | 17 |
| journal_entries Cancelled | 2 |

لم تُنشأ بيانات اختبار دائمة. الفواتير الثلاث القديمة بقيت Legacy دون إعادة تصنيف:
- PINV-1000: Posted SAR 2,640.
- PINV-1001: Posted SAR 1,330.
- QA-SR-INV-20260927: Draft SAR 375 مع حالة received التاريخية غير المتسقة.

لم تتغير حركات المخزون أو دفتر المورد أو القيود أو الخزينة بسبب هذا التنفيذ. عدد القيود Posted ما زال 17؛ إجمالي 19 يتضمن قيدين Cancelled، وليس 19 قيدًا مرحّلًا.

### 5.3 Supabase Advisors
الملاحظات الحالية على مستوى المشروع:
- 24 RLS enabled/no policy — INFO.
- 1 mutable search_path — WARN.
- 18 anon SECURITY DEFINER executable — WARN (لم ترتفع عن baseline؛ anon لا يملك تنفيذ وظائف Buyer الجديدة).
- 139 authenticated SECURITY DEFINER executable — WARN؛ تشمل وظائف النظام القائمة وRPC Buyer الجديدة المقصودة، وكل RPC Buyer الجديدة تتحقق من هوية المستخدم والصلاحية داخل الوظيفة.
- 1 leaked-password protection disabled — WARN.

لم ننفذ blanket revoke أو تعديلًا على جداول/وظائف غير مرتبطة.

## 6. ما لم يكتمل بعد — لا يُخفى

1. **Cloudflare Pages UI deployment:** تم تأكيد نشر commit `3717c0279b856127d29fb9f912ec502523761da5` في Production؛ Preview URL: `https://633d858b.rawaea-erp.pages.dev/`. تعذر فحص الصفحة عبر أداة قراءة الويب، ولم يتم اختبار التطبيق من جلسة Buyer مصادق.
2. **Authenticated E2E:** لم تتوفر جلسة Buyer مصادق في المتصفح؛ لم ننشئ فاتورة أو حدث حيازة دائمًا للاختبار. يلزم اختبار قبول بمستخدم مشتريات حقيقي داخل transaction rollback أو مسار QA مؤقت آمن.
3. **Quick Market receiving/financial settlement:** يبقى محجوبًا عمدًا حتى تطوير Receiver لاحقًا. لا يتم POST ولا stock/AP/GL/cash posting من Buyer.
4. **SupplierReturn:** لم يُعدل؛ قبول المورد والخصم المالي بعد الإثبات ما زالا مرحلة لاحقة مستقلة.
5. **Cash custody Quick Market expense approval:** لم يُفتح؛ تقديم المصروف واعتماده ينتظر Receiver المقبول. الحجز فقط يعمل الآن.
6. **Employee due payment:** لا يصنف مستحق الموظف مدفوعًا دون سند خزينة فعلي.

## 7. القيود التي حافظنا عليها

- لم يُعدل `Receiver.html` أو `main.html` أو `core.js` أو أي تطبيق آخر.
- لم تُنشأ Edge Function جديدة أو فرع أو PR.
- لم تُحذف أو تُعكس الفواتير التاريخية ولا حركاتها.
- لا يوجد Quick Market invoice Posted ولا حركة مخزون/مورد/GL/خزينة جديدة.
- المركبة ليست شرطًا لحيازة Buyer.
- لا يُخصم المورد إلا عند إثبات قبول المورد لاحقًا.
- لم يتم تعديل بيانات النظام الأم أو عملته؛ العملة ما زالت EGP من الإعداد المركزي.

## 8. نقطة الاستئناف التالية

1. افتح Buyer المنشور من Cloudflare Pages بمستخدم مشتريات مصادق، واختبر القراءة والنماذج أولًا. لا تحفظ Quick Market أو handover على بيانات Production الحقيقية لأغراض التجربة.
2. نفّذ اختبار صلاحيات على مستخدمين مختلفين: كل مشتري يرى فواتيره وحيازته فقط، والمالية ترى النطاق المصرح.
3. اختبر عمليات الإنشاء/التعديل/التكرار في معاملة معزولة تنتهي بـROLLBACK مع مستخدم JWT مصرح، ثم تحقق من عدم تغير counts.
4. بعد قبول Buyer، افتح مرحلة Receiver منفصلة وفق توجيه المالك؛ لا تبدأ SupplierReturn قبل توحيد الكاتب المخزني/المحاسبي.
