# Report572 — إصلاح تكامل تطبيق مسؤول المشتريات والمزامنة والصلاحيات
**تاريخ الفحص:** 2026-11-01 — Africa/Cairo  
**التصنيف:** CTO Production Reconciliation / Partial Repairs Confirmed / Runtime Closure Pending  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` — `main`  
**مشروع Production:** Supabase SMART ERP — `fiilmooggumokxanwiyx`

## 1. نقطة البداية

بدأ التحقيق بجلب وقراءة `CURRENT_STATE.md` كاملًا من المستودع الحاكم `papamohammed77-glitch/rawaie-erp-New`، ولم يبدأ من التقرير أو الذاكرة.

كان آخر checkpoint هو **LVE-2026-11-01-571 — Buyer Purchasing Integration**، وحالته PARTIAL / NOT CLOSED.  
آخر حدث موثق فيه: إصلاحات عقود PR وRFQ وQuotation وPO وReceiver في Production، وEdge `save-purchase-order` v11 ACTIVE، واختبار PR→RFQ→Quotation→PO→Receiver داخل SQL transaction مع rollback. النشر الفعلي للواجهة وBrowser E2E وRealtime runtime كانت غير متحققة.

الهدف الذي استُكمل في هذا الفحص: معالجة الفجوات المثبتة التي تمنع الوصول إلى Buyer، وحفظ المورد، وتحديث الشاشات على تغييرات بيانات المشتريات؛ ثم مطابقة المصدر مع Production دون العبث بدورة المخزون أو المحاسبة.

## 2. CONFIRMED — ما ثبت وما تم إصلاحه

### 2.1 GitHub / Source

**HEAD الحالي بعد التعديلات:**  
`511efd0cd032183515e5834027abe949d9e55649` — operational repo `erp-frontend/main`.

الملفات ذات الصلة:
| الملف | Blob الحالي | النتيجة |
|---|---|---|
| `companies/company-1/purchasing/buyer.html` | `996bb04ebe6e3c8b34586e2cef2c52ec01400fbb` | PR actions + Realtime subscriptions + refresh routing |
| `companies/company-1/app.html` | `2e47a68fe83956e27d569e786a08dcee91af2924` | توجيه التطبيقات من effective profile المركزي |
| `companies/company-1/core.js` | `a95ee6b29ff54b4a240ce4b81f9a535aa87686db` | محرك RW_Realtime موجود، لم يُستبدل |
| `companies/company-1/main.html` | لم يتغير | لم يُعدل احترامًا لحدود الملكية في المهمة |
| `supabase/functions/save-purchase-order/index.ts` | `508aee8b7941ef3d631d4a61ab60e336f1ed8836` | إصلاح SAVE_SUPPLIER dispatch |

**إصلاحات المصدر المحددة:**

1. **SAVE_SUPPLIER:** كان فرع فحص الصلاحية في Edge ينفذ `call("save_supplier_atomic", ...)` قبل تعريف `call` وقبل تعريف متغيري `data/error`. هذا ترتيب يسبب خطأ JavaScript (Temporal Dead Zone) قبل بلوغ RPC. نُقل تنفيذ RPC إلى فرع التنفيذ بعد تعريف المساعد والمتغيرات، وأصبح preflight يفحص فقط `purchases/suppliers`. أزيل فرع فحص الصلاحية المكرر.
   - Commit: `91c1a20a90cd6372a811d7b8f46095aa2548b3d8`.

2. **اعتماد PR:** كانت الواجهة تعرض زر الاعتماد/الرفض فقط عندما `status === 'PendingApproval'`، بينما عقد Production يقبل `Submitted`. أصبحت الحالتان تعرضان الأزرار، وتغيرت تسمية Submitted إلى «مرسل للاعتماد».
   - Commit: `1ee5b4c53331c1f1b416750d519704411e87e7b7`.

3. **Realtime في Buyer:** استُبدل الاشتراك المنفرد بـ `purchase_orders` باشتراك في 12 جدولًا موجودًا فعلًا في Realtime publication:
   - `purchase_requests`, `purchase_rfqs`, `purchase_quotations`, `purchase_orders`, `purchase_order_details`, `purchase_invoices`, `purchase_payments`, `purchase_returns`, `suppliers`, `items`, `branches`, `stock_branches`.
   - `purchase_order_details` و`stock_branches` يستخدمان `companyColumn:false` لأنهما لا يحملان عمود company_id؛ ويعتمدان على RLS وربط الشركة عبر parent/branch.
   - debounce 500ms وreconcile 30 seconds.
   - تُبطل cache عند كل حدث، وتُحدّث الشاشة النشطة وفق علاقة التبويب بالجداول؛ Today يستجيب لجميع الأحداث، والموردون يتحدثون أيضًا مع تغيّر فواتير/مدفوعات/مرتجعات المورد، وحسابي يتحدث مع تغيّر المستندات أو الموردين.
   - تمت إضافة مؤشر مرئي لحالة الاشتراك `SUBSCRIBED` أو آلية إعادة التحقق. لم تتم مشاهدة هذه الحالة في Runtime حتى الآن.
   - Commits: `cc1ac9d78db90d647c0ad324a66f66406eaa1310`، ثم `9f6be17dca57a62ac175d4b178ae1691bf358f79` لتوسيع invalidation المالي في الموردين والحساب.

4. **توحيد مصدر الصلاحيات في Smart Router:** كان `app.html` يستخرج `permissions` من JWT `user_metadata` فقط، بينما صلاحية المستخدم قد تأتي من `users.permissions` أو `roles.permissions` أو `role_permissions`. تم تحويل `redirectAfterLogin` إلى `get_my_effective_profile()` والتحقق من company_id ووجود permissions array؛ وعند فشل استرجاع الملف يظهر خطأ ولا يحدث fallback إلى JWT metadata القديمة.
   - هذا يتفق مع الدالة الحية التي تعيد permissions مجمعة، و`active_warehouse_role` و`isOwner`.
   - Commit: `9016396ab29c88a9014ecff9f602ed94c50c7023`.
   - مسار `purchases` في app router يوجه إلى `/companies/company-1/purchasing/buyer.html`.
   - لم يُعدل `main.html`. قائمته الداخلية لا تزال تعرض «الموردين»، «نقطة شراء»، «دورة المشتريات» كعناصر Parent منفصلة، ولا تحتوي إحالة نصية إلى `buyer.html`. توحيد قوائم Parent على مستوى الصفحة الأم ما زال من مسؤولية المستخدم.

5. **Static parse:** استُخرج JavaScript inline من الملفين الحاليين وشُغّل V8 `new Function`:
   - Buyer script: 48,979 حرفًا — parse ناجح.
   - app.html script: 8,181 حرفًا — parse ناجح.
   هذا فحص نحوي للـscript المضمن، وليس E2E أو اختبار ملف HTML بالمتصفح.

### 2.2 Supabase Production

**Edge Function:**
- `save-purchase-order`: الإصدار **v12 ACTIVE**، `verify_jwt=true`.
- SHA-256 المنشور: `4748aede3bd45c6fce4b251408f4ca91a6368e7abeae36a3d87e182e4e723d37`.
- أعيد جلب ملف Production ومقارنته مع ملف Git الحالي: **exact byte match = true**.
- هذا يثبت تطابق Artifact الخاص بالـEdge مع Git، ولا يثبت استدعاء API ناجحًا من متصفح مصادق.

**ستة تغييرات Production إضافية في هذا الفحص (كلها محددة النطاق):**

| Migration | الأثر |
|---|---|
| `20261031230252_buyer_realtime_read_permission_alignment_20261101` | helper لصلاحيات المستخدم الفعالة مع wildcard؛ وتوحيد SELECT RLS للموردين والأصناف والفروع وأرصدة الفروع مع صلاحية المشتريات الفعالة مع الإبقاء على company scope |
| `20261031230550_buyer_purchase_views_use_caller_rls_20261101` | supplier_ledger SELECT بالـeffective permission وtenant scope؛ تحويل 3 reporting views إلى security_invoker |
| `20261031230557_buyer_purchase_requests_remove_end_user_truncate_20261101` | إزالة TRUNCATE من purchase_requests لـanon/authenticated |
| `20261031230603_buyer_purchase_remove_end_user_truncate_grants_20261101` | إزالة TRUNCATE من بقية جداول/Views المشتريات لـanon/authenticated |
| `20261031230748_buyer_purchase_reporting_views_revoke_anon_select_20261101` | إزالة SELECT المباشر من anon على 3 reporting views |
| `20261031231142_buyer_purchase_trigger_functions_pin_search_path_20261101` | تثبيت search_path فارغ لدالتي Trigger المشتريات |

جميع ملفات هذه الـmigrations أُضيفت إلى operational Git تحت `supabase/migrations/`، ولم تبق التغييرات الجديدة خارج إصدار المصدر.

**RLS / read verification — read-only transactions مع ROLLBACK:**
- مستخدم لديه صلاحيات المشتريات المباشرة: effective purchases/suppliers true؛ وظهر له 4 suppliers و30 items و4 branches و57 stock_branches.
- مستخدم آخر تعتمد صلاحية المشتريات لديه على `role_permissions`: أعاد `get_my_effective_profile` صلاحية purchases؛ وظهر له 4 supplier rows و30 item rows و4 branches (في فحصه السابق) و57 stock rows.
- فحص anon على suppliers/items/branches/stock_branches أعاد صفر صفوف/رفضًا حسب صلاحية الدالة.
- بعد التغيير: `anon` لا يملك SELECT على `purchase_supplier_balance` ولا `purchase_invoice_aging` ولا `purchase_quotation_comparison`؛ authenticated يحتفظ بقراءة عرض رصيد المورد.
- TRUNCATE grants بعد الإصلاح: **0 لـanon و0 لـauthenticated** عبر جداول/Views المشتريات التي شملها الفحص.
- تمت مراجعة تعريف دالتي Trigger: كلاهما SECURITY INVOKER وبلا dynamic SQL. بعد ضبط search_path:
  - `purchase_company_status_history`: 7 Triggers مفعلة.
  - `purchase_touch_updated_at`: 7 Triggers مفعلة.
  - تم التأكد أن `proconfig` يحتوي `search_path=""` لكل منهما.

**Realtime publication:** تأكد أن جداول الاشتراك الـ12 المحددة في Buyer موجودة في `supabase_realtime` في Production. هذه مطابقة إعداد/Publication وRLS، وليست دليلًا على اتصال WebSocket أو استلام حدث من المستخدم.

**بيانات الأعمال:** لا توجد أي كتابة على طلبات أو أوامر أو فواتير أو مخزون أو قيود محاسبية ضمن هذا الفحص. كل اختبارات القراءة كانت معاملات rollback. لم تُنشأ بيانات تجريبية ولم تُحذف بيانات إنتاج.

### 2.3 Security Advisor

بعد التغييرات، لم يعد Security Advisor يعرض تحذير `SECURITY DEFINER VIEW` الخاص بـViews المشتريات الثلاث، ولم يعد يحذر من mutable search_path لدالتي Trigger المشتريات.

ما زالت تحذيرات عامة على مستوى النظام، لم تُعالج في نطاق Buyer:
- `rls_enabled_no_policy`: INFO count 24.
- `function_search_path_mutable`: WARN count 1 (sales_decision_default_policy).
- `anon_security_definer_function_executable`: WARN count 19.
- `authenticated_security_definer_function_executable`: WARN count 121.
- `auth_leaked_password_protection`: WARN count 1.
لا يجوز اعتبار أمان Supabase بالكامل مغلقًا بناءً على معالجة نطاق المشتريات وحده.

## 3. UNKNOWN

1. هل Cloudflare Pages يخدم حاليًا `buyer.html` و`app.html` على آخر HEAD؟ لا توجد حتى الآن قراءة موثوقة للـartifact المنشور أو commit/build lineage أو Response Headers من مصدر Cloudflare.
2. هل مستخدم مصادق يستطيع فتح Buyer فعليًا عبر app.html بعد التعديل؟ لم يُجرَ تسجيل دخول أو redirect في المتصفح.
3. هل اتصال Realtime يصل إلى `SUBSCRIBED` ويستقبل فعلًا أحداث INSERT/UPDATE من عملية مشتريات مستقلة؟ لم يُجرَ اختبار websocket حي.
4. هل تعمل إعادة المصالحة بعد عودة الاتصال أو إعادة إظهار الصفحة على النسخة المنشورة؟ لم يُختبر Runtime.

## 4. CONFLICT

لا يوجد تعارض مثبت جديد بين Edge Git وEdge Production بعد الإصلاح؛ المصدر المنشور يطابق المصدر المحفوظ في Git byte-for-byte.

هناك حدّ تكاملي يجب عدم خلطه: Parent `main.html` يحتوي وحداته الداخلية للمشتريات، بينما `app.html` هو مدخل التطبيقات المنفصلة ويوجه صلاحية purchases إلى Buyer PWA. هذا ليس إثباتًا على أن أحدهما يحل محل الآخر. لم يجر تعديل main.html، وبالتالي فإن ربط زر أو مدخل الـParent مباشرة بـBuyer لم يُنجز في هذا الفحص.

## 5. UNVERIFIED — Business Contracts المتبقية

هذه فجوات مؤكدة من المصدر والمخطط، لكنها لم تُنفذ بعد:

1. **PO lifecycle:** لا توجد حقول/عقود مؤكدة لـexpected_delivery_date وpayment_terms وapproved_by وsent_at، ولا عمليات مستقلة مكتملة لإنشاء PO يدويًا/تعديله/اعتماده/إرساله للمورد. المسار الحالي المثبت هو عرض PO الناتج عن قبول Quotation وربطه باستلام Receiver.
2. **Supplier relationship:** لا يوجد عقد مكتمل للبريد الإلكتروني وتصنيف A/B/C ومعايير التقييم، ولا Supplier Visits تشمل GPS وصورة/صوت ونتيجة الزيارة.
3. **Buyer custody:** لا يوجد دفتر عهدة شخصي لموظف المشتريات ووارد/صرف/تسوية ومرفقات واعتماد. لا تستخدم treasury أو cash_box أو HR salary advances كبدائل.
4. **Payment method:** جدول/عقد الدفع الحالي لا يحمل طريقة الدفع في RPC `purchase_post_payment_atomic`؛ توقيعه لا يتضمن payment_method والافتراضي Cash. لا تُظهر أو تنفذ تحويلًا كأنه مدعوم قبل إكمال العقد.
5. **Quick purchase:** الواجهة تنشئ Draft invoice فقط. الحقل `supplier_invoice_no` المرسل من الواجهة لا تحفظه الدالة الحالية `purchase_create_invoice_atomic`، كما لا يوجد استلام مباشر من دون PO أو تصوير فاتورة وOCR. لا يجوز تحويل Draft إلى stock/journal effect دون خطوة ترحيل محاسبية/مخزنية صحيحة.
6. **PR quantities/departments:** لا يوجد `department_id` في PR، ولا received/remaining aggregate صريح في تفاصيل PR؛ كمية الاستلام في عقد PO details/Receiver.
7. **Scale:** القوائم محدودة بـ500 سجل والبحث Client-side؛ pagination/search server-side غير مكتمل.
8. **Supplier image/video/voice and location:** لم يثبت عقد تخزين وتفويض لهذه المرفقات؛ لا تنشأ bucket أو permissions عشوائيًا.

لم تُنشأ هذه العقود بالتخمين لأنها تغير مسؤوليات اعتماد ومخزون ومحاسبة وأمن ومرفقات، ويجب تثبيت مالك القرار، مصدر الإرسال، حالات المستند، الربط بالاستلام، والأثر المحاسبي قبل بنائها.

## 6. مصفوفة التحقق

| الطبقة | الحالة | الدليل/الحد |
|---|---|---|
| GitHub / source | **CONFIRMED** | HEAD وBlob الحالية، commits الجراحية، parser ناجح |
| Supabase Production schema/RLS/grants | **CONFIRMED ضمن نطاق المشتريات** | migrations مسجلة، read tests rollback، grants/Views/Triggers re-read |
| Production Edge artifact | **CONFIRMED** | v12 ACTIVE وexact byte match مع Git |
| Cloudflare deployed artifact | **UNVERIFIED** | لم يتم إثبات artifact/build commit/headers |
| Authenticated browser runtime | **UNVERIFIED** | التبويب المتاح يعرض شاشة الدخول؛ Browser connector في هذه الجلسة للقراءة فقط |
| Realtime WebSocket/events | **UNVERIFIED** | Publication وRLS وsubscription source متوافقة؛ لا يوجد حدث حي مشاهد |
| PR→Receiver workflow E2E | **CONFIRMED تاريخيًا في Report571 فقط** | اختبار SQL سابق rollback-only؛ لم يُعد في هذا الفحص |
| Business-data effects this run | **CONFIRMED: none** | لم تُنفذ business DML أو stock/journal posting؛ اختبارات القراءة rollback |

## 7. ما تم فعليًا ومراجع الأدلة

### Operational commits (erp-frontend/main)
- `91c1a20a90cd6372a811d7b8f46095aa2548b3d8` — Edge SAVE_SUPPLIER dispatch.
- `1ee5b4c53331c1f1b416750d519704411e87e7b7` — PR Submitted approval.
- `cc1ac9d78db90d647c0ad324a66f66406eaa1310` — Buyer realtime tables.
- `9f6be17dca57a62ac175d4b178ae1691bf358f79` — supplier/account financial refresh.
- `9016396ab29c88a9014ecff9f602ed94c50c7023` — app router effective profile.
- `dc957006099a2d1e763678544c38b6ebf008e389`, `0287bf8c2d45a0a8f3535bddf9738a4d71ba0b88`, `f73f6e928d97678fd40aa3700c4d596b080cfd8e`, `65afd289f90f35d41a9d494cd590e65f7fbbb9e5`, `e9973d873af5444b18c1a6af5e1b0d2062c93a10`, `511efd0cd032183515e5834027abe949d9e55649` — committed Production migrations.

### Supabase Production migrations added this turn
- `20261031230252_buyer_realtime_read_permission_alignment_20261101`
- `20261031230550_buyer_purchase_views_use_caller_rls_20261101`
- `20261031230557_buyer_purchase_requests_remove_end_user_truncate_20261101`
- `20261031230603_buyer_purchase_remove_end_user_truncate_grants_20261101`
- `20261031230748_buyer_purchase_reporting_views_revoke_anon_select_20261101`
- `20261031231142_buyer_purchase_trigger_functions_pin_search_path_20261101`

## 8. ما لم يُنفذ ولماذا

- لم أُجرِ نشرًا لـPages أو أغيّر Cloudflare؛ لا يوجد دليل نشر/artifact متاح من الأدوات الحالية.
- لم أقم بتسجيل الدخول أو Browser E2E؛ التبويب الحالي يعرض شاشة الدخول وأداة Browser في هذا السياق read-only.
- لم أستدعِ Edge Function ببيانات مستخدم حقيقية؛ لا تتوفر أداة invoke في الجلسة. تم التحقق من deployed bundle فقط.
- لم أكتب أو أحذف بيانات اختبار في Production، ولم أُحدث مخزونًا أو قيدًا أو Treasury.
- لم أُكمل العهدة، الزيارات، تقييم المورد، PO send/approval، OCR أو payment method لأنها تتطلب عقود أعمال حقيقية غير موجودة حاليًا.
- لم أعدل `main.html` لأن المهمة المرفقة حددت أن تعديلات النظام الأم ينفذها المستخدم.
- لم أعالج تحذيرات Security Advisor العامة خارج نطاق المشتريات دون تحقيق مستقل.

## 9. الخطوة التالية الواحدة ذات الأولوية

**إثبات النسخة المنشورة وRealtime Runtime على Cloudflare بعد نشر HEAD الحالي:** مطابقة `app.html` و`buyer.html` المنشورين مع Git، ثم اختبار الدخول بحساب مشتريات مصادق والتحقق من حالة `SUBSCRIBED` ووصول حدث آمن إلى التبويب الصحيح بعد تغيير PR/PO من جلسة أخرى، مع فحص عدم وجود أثر مخزني/محاسبي من مجرد العرض.

بعد إغلاق هذا الاختبار فقط، انتقل إلى عقد PO lifecycle باعتباره أولوية Business Contract التالية.

---

**الحالة:** `PARTIAL REPAIRS CONFIRMED / EDGE v12 MATCHED / PRODUCTION READ CONTRACTS HARDENED / SOURCE REALTIME WIRED / CLOUDFLARE + WEBSOCKET RUNTIME UNVERIFIED / BUSINESS CONTRACTS OPEN / NOT CLOSED`.
