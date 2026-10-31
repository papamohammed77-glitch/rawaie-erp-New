# Report573 — تحقيق وإصلاح Buyer Purchasing / عهد الموظف / المصادقة / Realtime / Tailwind

**التاريخ:** 2026-11-01 — Africa/Cairo  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` — `main`  
**HEAD وقت التقرير:** `1db1db2927005d12a1531b7518d103c4c7b8140f`  
**Supabase:** SMART ERP — `fiilmooggumokxanwiyx`  
**الحالة:** إصلاحات مصدر وإنتاج مؤكدة، واختبارات قاعدة بيانات rollback ناجحة؛ تشغيل Cloudflare والمتصفح الفعلي لم يُغلق بعد.

---

## 1. الخلاصة التنفيذية

تمت معالجة السبب الجذري لخطأ `PURCHASE_AUTH_REQUIRED`، وإضافة عقد مستقل لعهدة موظف المشتريات بدل استعمال الخزينة أو سلف الموارد البشرية، وتوسيع تغطية Realtime من 12 إلى 26 جدولًا، وإزالة Tailwind CDN من مصدر Buyer لصالح CSS إنتاجي محلي.

**لم يتم تعديل** `companies/company-1/main.html`. كما لم تُنفذ حركات مخزون أو قيود أو مدفوعات أو بيانات عهدة فعلية؛ كل اختبارات الأعمال التي أنشأت بيانات تمت داخل معاملات `ROLLBACK`.

**لا يُعلن إغلاق المهمة:** لا يوجد في هذه الجولة اختبار متصفح موثّق بعد آخر نشر، ولا إثبات أن Cloudflare يخدم آخر commit، ولا اختبار WebSocket فعلي من جلستين منفصلتين.

## 2. التحقيق الجنائي — سبب PURCHASE_AUTH_REQUIRED

### CONFIRMED — السبب

كان مسار `GET_SUMMARY` في Edge يستدعي `purchase_get_dashboard` بواسطة عميل `service_role`. وكانت الدالة تميز الخدمة عبر:

`current_setting('request.jwt.claim.role', true)`

ثم تعتبر أي قيمة لا تساوي `service_role` مستخدمًا عاديًا، وتطلب `auth.uid()`. في سياق الاختبار الفعلي لـ `service_role` ثبت أن:

- `current_setting('request.jwt.claim.role', true)` = NULL
- `auth.role()` = `service_role`
- `auth.uid()` = NULL

وبالتالي كان الشرط القديم يدخل مسار المستخدم العادي رغم أن الدور الحقيقي `service_role`، فيرفع `PURCHASE_AUTH_REQUIRED`. هذا يفسر ظهور 400 بعد نجاح تسجيل الدخول، وتكراره عند إعادة تحميل Today/Realtime.

### CONFIRMED — العلاج المطبق

1. عدّلت `purchase_get_dashboard` لاستخدام `auth.role()` في التمييز بين الخدمة والمستخدم المصادق.
2. عدّلت Edge `GET_SUMMARY` ليستخدم `profileClient.rpc(...)` مع JWT المستخدم، بحيث يجري التحقق من `auth.uid()` والشركة والصلاحيات الفعلية بدل الاعتماد على service role لهذا الملخص.
3. وسّعت شرط الصلاحية ليشمل `finance_manager` بجانب `purchases` و`finance`.
4. أضفت واجهة خطأ واضحة مع زر إعادة المحاولة في Buyer؛ لا تبقى الشاشة في حالة تحميل غير مفهومة عند فشل طلب بيانات.

### اختبارات قاعدة البيانات

- استدعاء الدالة تحت `service_role` بعد التصحيح أعاد Dashboard بنجاح رغم أن `auth.uid()` فارغ.
- استدعاء الدالة تحت `authenticated` لمستخدم صلاحية `finance_manager` نجح.
- Edge `save-purchase-order` أصبح **v18 ACTIVE**، و`verify_jwt=true`، والملف المنشور `index.ts` يطابق المصدر الحالي byte-for-byte.
- لا يوجد اختبار HTTP مصادق من المتصفح بعد النشر؛ لذلك إزالة 400 من واجهة الإنتاج تبقى **UNVERIFIED runtime** إلى أن يعاد الاختبار في Buyer المنشور.

## 3. عقد «عهدتي» — نموذج عمل مستقل

لم أعد استخدام `treasury` أو `cash_box` أو `hr_salary_advances`؛ فهذه ليست دفتر عهدة موظف مشتريات.

### الجداول الجديدة

- `buyer_custodies`: سجل تسليم العهدة، الموظف، الشركة، الفرع، الغرض، العملة، المبلغ، تاريخ التسليم، مرجع التسليم اليدوي، مسجل التسليم، تأكيد الموظف، الحالة.
- `buyer_custody_expenses`: المصروفات التي يقدمها الموظف، المورد، رقم الفاتورة، التاريخ، المبلغ، العملة، وصف المصروف، اسم ومسار المستند، حالة المراجعة، المراجع ووقت المراجعة.
- `buyer_custody_settlements`: إجمالي المصروفات المعتمدة، النقد المرتجع الذي تسلمته المالية يدويًا، المستحق للموظف إن تجاوزت المصروفات قيمة العهدة، مرجع التسوية، الملاحظات، ومسجل التسوية.

### دورة التشغيل

1. المالية تسجل يدويًا تسليم مبلغ العهدة إلى موظف نشط بالشركة؛ لا يتم إنشاء حركة خزينة تلقائية.
2. الموظف يؤكد الاستلام.
3. الموظف يرفع فاتورة أو مستندًا PDF/صورة ويرسل بيانات المصروف إلى المالية.
4. المالية تعتمد المستند أو ترفضه مع ملاحظة.
5. لا يمكن إقفال العهدة مع وجود مستندات `Submitted` لم تُراجع.
6. عند الإقفال تسجل المالية يدويًا كامل الرصيد النقدي غير المصروف الذي استلمته؛ ويُحسب المستحق للموظف إن زادت المصروفات المعتمدة على مبلغ العهدة.
7. تم منع اختلاف عملة المصروف عن عملة العهدة، ومنع إقفال العهدة بقيمة نقد مرتجع لا تطابق الرصيد غير المصروف. هذا يمنع إظهار عهدة مغلقة مع رصيد نقدي غير مفسر.

### فصل الصلاحيات والحماية

- الموظف يرى عهده ومصروفاته فقط؛ المالية/مدير المالية يرى سجلات الشركة.
- إنشاء العهدة واعتماد المستندات والتسوية للمالية أو مدير المالية.
- الموظف لا يعتمد مستنداته ولا يسوي عهدته بنفسه؛ الحماية مطبقة في RPC، وليست مجرد إخفاء أزرار.
- الجداول الثلاثة عليها RLS، وSELECT للمستخدم المصادق ضمن النطاق فقط. لا توجد صلاحيات مباشرة للمستخدم النهائي على INSERT/UPDATE/DELETE؛ التغييرات عبر RPCs محمية.
- وظائف العهدة الخمس: `buyer_custody_issue_atomic`, `buyer_custody_acknowledge_atomic`, `buyer_custody_submit_expense_atomic`, `buyer_custody_review_expense_atomic`, `buyer_custody_settle_atomic`. صلاحية EXECUTE لـ authenticated فقط، وanon غير مخول.
- ملفات المستندات في bucket الخاص `employee-documents` بمسار شركة/موظف/عهدة. تم إصلاح خطأ تأهيل عمود المسار في سياسات Storage: المرجع أصبح `storage.objects.name` داخل الاستعلامات الفرعية بدل التباسه بعمود `users.name`. أضيفت سياسة حذف للموظف صاحب الملف حتى تستطيع واجهة Storage API تنظيف الملف عند فشل الإرسال.
- واجهة Buyer تسمح للمالية ومدير المالية بالدخول إلى مساحة العهدة، وأضيف رابط من `accountant.html` و`finance-manager.html` إلى مساحة العهدة. لا تعديل على Parent `main.html`.

### اختبار دورة العهدة — CONFIRMED / ROLLBACK

تم اختبار السيناريو كاملًا داخل معاملة واحدة تم التراجع عنها:

- المالية تسجل عهدة 100 SAR لموظف آخر.
- الموظف يرفع metadata لمستند داخل مسار العهدة وفق سياسة Storage.
- الموظف يقدم مصروفًا بقيمة 40 SAR.
- المالية تعتمد المستند.
- المالية تسجل استلام 60 SAR نقدًا.
- نتيجة التسوية: مصروفات معتمدة 40، نقد مرتجع 60، رصيد مستحق للشركة 0.
- الموظف استطاع قراءة مستنده، والمالية استطاعت قراءته.
- المعاملة انتهت بـ `ROLLBACK`; لا توجد عهدة أو مصروف أو settlement أو object تجريبي متروك في Production.

**حد الاختبار:** هذا اختبار SQL لسياسات metadata وعقد RPC، وليس رفع ملف ثنائي فعلي من المتصفح عبر Storage API. كما لم يُختبر حذف الملف من خلال Storage API في المتصفح. لا نخلط بين الاختبارين.

## 4. Realtime وCore.js

### CONFIRMED — التغطية

تم توسيع اشتراك Buyer إلى 26 جدولًا:

- دورة PR/RFQ/Quotation/PO: `purchase_requests`, `purchase_request_details`, `purchase_rfqs`, `purchase_rfq_details`, `purchase_rfq_suppliers`, `purchase_quotations`, `purchase_quotation_details`, `purchase_orders`, `purchase_order_details`.
- الفواتير والمدفوعات والمرتجعات والتدقيق: `purchase_invoices`, `purchase_invoice_details`, `purchase_payments`, `purchase_payment_allocations`, `purchase_returns`, `purchase_return_details`, `purchase_status_history`, `purchase_attachments`, `purchase_document_links`, `purchase_settings`.
- العهدة: `buyer_custodies`, `buyer_custody_expenses`, `buyer_custody_settlements`.
- البيانات المرجعية والتوافر: `suppliers`, `items`, `branches`, `stock_branches`.

فحص Production أكد لكل جدول في القائمة: RLS مفعّل، SELECT للمستخدم المصادق موجود، سياسة SELECT/ALL موجودة، والجدول منشور في `supabase_realtime`. تفاصيل الجداول التي لا تحتوي `company_id` تستعمل `companyColumn:false` وتعتمد على سياسة RLS المرتبطة بالأصل.

### سلوك الواجهة

- Debounce: 400ms.
- Reconcile دوري: 15 ثانية بدل 30.
- تغيير الجدول يحدث تبويب Buyer المرتبط به، مع إبطال الكاش.
- إذا وصل الحدث أثناء ظهور SweetAlert، يُعلّق التحديث ثم يلتقط إغلاق النافذة عبر MutationObserver ويعيد تحميل التبويب، بدل ترك واجهة قديمة بعد إغلاق الحوار.
- تم توسيع `RW_Realtime.normalizeTables` في Core لدعم قائمة أحداث لكل جدول مع إبقاء الافتراضي الحالي دون تغيير؛ Core ما زال يسمح فقط بـ INSERT/UPDATE.

### الحد المعروف

لا توجد اشتراكات DELETE في Core الحالي. لذلك حذف السجلات لا يُدّعى أنه لحظي؛ تتم مراجعته عبر reconcile كل 15 ثانية. لا يجوز إضافة DELETE عشوائيًا إلى قناة متعددة الشركات دون إثبات عزل المستأجر في payload. كذلك لم يُجر اختبار WebSocket مصادق من جلستين منفصلتين بعد التغييرات. سجل المستخدم السابق أظهر `[Buyer] Realtime connected`، لكنه لا يثبت كل اشتراك وكل حدث بعد توسيع القائمة.

## 5. Tailwind — تحذير CDN في الإنتاج

- أزيل `https://cdn.tailwindcss.com` من `buyer.html`.
- أضيف `buyer.tailwind.css` محليًا، حجمه 15,038 حرفًا، ومترجم من Tailwind CLI.
- أضيف GitHub Actions workflow: `.github/workflows/buyer-tailwind-build.yml` لإعادة توليد CSS عند تغيّر Buyer أو ملف الإدخال.
- ثبت وجود commit توليد CSS `1fa7a3d73dc73645b1dc88b2ad33c41ecfe37bec`.
- مصدر Buyer الحالي لا يحتوي CDN ويربط الملف المحلي.

**UNVERIFIED:** لا يوجد إثبات من Cloudflare أن آخر deployment يخدم Buyer وCSS المحليين؛ لذلك لا أؤكد اختفاء التحذير من Console الإنتاج حتى فحص الصفحة المنشورة.

## 6. الاختبارات والأدلة

| الاختبار | النتيجة |
|---|---|
| Buyer inline JS syntax | PASS |
| Core.js syntax | PASS |
| Accountant / Finance Manager inline JS syntax | PASS |
| Edge v18 active + verify_jwt | CONFIRMED |
| Edge source / deployed byte match | PASS |
| `purchase_get_dashboard` service_role بعد إصلاح `auth.role()` | PASS |
| `purchase_get_dashboard` finance_manager JWT | PASS |
| دورة العهدة issue → upload metadata → submit → approve → settle | PASS / ROLLBACK |
| Employee/Finance document SELECT policies | PASS / ROLLBACK |
| Custody table anon SELECT | false |
| Custody table authenticated direct writes | INSERT/UPDATE/DELETE false |
| 26-table Realtime publication + RLS SELECT | PASS |
| Cloudflare deployment identity / CSS served | UNVERIFIED |
| Authenticated browser E2E / real Storage upload | UNVERIFIED |
| WebSocket event delivery / reconnect after changes | UNVERIFIED |
| Instant DELETE event | NOT IMPLEMENTED; reconcile 15s |

### Security Advisor

التحذيرات العامة المستمرة في المشروع لم تُغلق ضمن هذه المهمة: 24 جدولًا RLS بلا سياسات (INFO) في نطاقات أخرى، تحذير mutable search_path واحد خارج Buyer، 19 SECURITY DEFINER متاحًا لـ anon، و121 متاحًا لـ authenticated، إضافة إلى تحذير حماية كلمات المرور المسربة. وظائف العهدة الجديدة لا تسمح لـ anon بالتنفيذ، وsearch_path فيها فارغ ومثبت. لا تعلن إغلاق أمان ERP بالكامل.

## 7. ملفات المصدر وProduction

**Operational HEAD:** `1db1db2927005d12a1531b7518d103c4c7b8140f`

| الملف | Blob الحالي |
|---|---|
| `companies/company-1/purchasing/buyer.html` | `ee2fb5676a99a9c17371b3a7f44ab0b2bb320506` |
| `companies/company-1/core.js` | `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1` |
| `companies/company-1/app.html` | `2e47a68fe83956e27d569e786a08dcee91af2924` |
| `companies/company-1/office/accountant.html` | `74794dd24277eac92c652061b2540d5cb772425e` |
| `companies/company-1/office/finance-manager.html` | `db8a5c4ef7029833ec7777dd4f992f737475e85f` |
| `companies/company-1/purchasing/buyer.tailwind.css` | `25b1b840e0a03c42d3de2593b08baf6af95d0f4b` |
| `supabase/functions/save-purchase-order/index.ts` | `6d6b6ce45a18e6275f043b6e397da528d2c58124` |

**Edge Production:** `save-purchase-order v18 ACTIVE`, `verify_jwt=true`, SHA-256 `e9fab386b72cc9e3d10b49931324117dea1e2df6828cb50d9e8d010e0923996f`; exact byte match مع Git.

### Migrations المطبقة والمحفوظة في operational repo

1. `20261031233331_buyer_employee_custody_ledger_and_manual_settlement_20261101`
2. `20261031233638_buyer_full_detail_realtime_publication_20261101`
3. `20261031233923_buyer_custody_finance_separation_of_duties_20261101`
4. `20261031234235_buyer_custody_finance_manager_permission_and_policy_20261101`
5. `20261031234711_buyer_dashboard_effective_finance_manager_permission_20261101`
6. `20261031234832_buyer_dashboard_use_auth_role_for_service_bypass_20261101`
7. `20261031234921_buyer_custody_storage_path_qualification_and_cleanup_policy_20261101`
8. `20261031235057_buyer_custody_currency_and_full_cash_reconciliation_20261101`

كلها ظاهرة في `supabase_migrations.schema_migrations`، وSQL محفوظ في `supabase/migrations/`.

## 8. ما بقي مفتوحًا — لا نختلق عقودًا

- PO: `expected_delivery_date`, `payment_terms`, `approved_by`, `sent_at`، ودورة إنشاء/تعديل/اعتماد/إرسال المورد.
- المورد: البريد، تصنيف A/B/C، rubric التقييم والزيارات.
- Payment: تمرير `payment_method` في `purchase_post_payment_atomic`.
- Quick Purchase: حفظ `supplier_invoice_no`، الاستلام المباشر دون PO، OCR.
- PR: `department_id` ومجاميع المستلم/المتبقي.
- Server-side pagination/search بدل حدود 500 صف.
- هذه البنود تحتاج عقد قاعدة بيانات + RPC + صلاحيات + واجهة + اختبار آثار، ولم تُعرض كميزات وهمية.

## 9. الخطوة التالية الوحيدة ذات الأولوية

تأكيد Cloudflare Pages على آخر commit `1db1db2927005d12a1531b7518d103c4c7b8140f`، ثم اختبار Buyer بحساب موظف مشتريات وحساب مالية/مدير مالية: تسجيل الدخول، GET_SUMMARY، فتح «عهدتي»، رفع ملف حقيقي، اعتماد المالية، التسوية، ومزامنة حدث من جلسة ثانية. بعدها يُغلق runtime فقط إذا نجح الاختبار، ثم ننتقل لعقد PO lifecycle.

**قرار الإغلاق:** `PARTIAL REPAIRS CONFIRMED / ROOT CAUSE CONFIRMED / CUSTODY DB WORKFLOW ROLLBACK-TESTED / EDGE v18 BYTE-MATCHED / 26 TABLES PUBLISHED + RLS-READ VERIFIED / TAILWIND CDN REMOVED FROM SOURCE / CLOUDFLARE + BROWSER RUNTIME UNVERIFIED / OTHER BUSINESS CONTRACTS OPEN / NOT CLOSED`.
