# تقرير 631 — إثبات فاتورة السوق السريع، تأمين المرفقات، تقوية صلاحيات النظام وفهارس المشتريات
**التاريخ:** 4 نوفمبر 2026 — Africa/Cairo  
**نقطة البداية:** LVE630  
**النطاق:** Buyer Quick Market، المرفقات، صلاحيات المرتجعات، Storage، فهارس Buyer/Purchase، وحماية دوال Trigger.

## 1. الخلاصة التنفيذية

تم تنفيذ دفعة تشغيلية متكاملة في Production والمستودع التشغيلي، دون تعديل النظام الأم أو Core أو Receiver:

1. إضافة رفع صورة/PDF فاتورة المورد إلى Quick Market، وتسجيلها في `purchase_attachments` وعرضها من تفاصيل الفاتورة.
2. نشر `save-purchase-order v28`، مع تحقق الخادم من ملكية الفاتورة ومسار الملف ووجوده ونوعه وحجمه، وتسجيل المرفق بصورة قابلة لإعادة المحاولة دون تكرار.
3. تقييد قراءة بيانات المرفقات على المشتري صاحب الفاتورة أو المالية/مدير المالية/المالك.
4. منح المالية/مدير المالية/المالك قراءة أدلة `buyer-goods` فقط عند ارتباطها بفاتورة Quick Market صحيحة في الشركة نفسها، مع بقاء bucket خاصًا.
5. تحويل المرتجعات إلى Central Writer: لا DML مباشر من anon/authenticated.
6. إضافة فهارس FK الناقصة في Buyer/Purchase وتحسين تقييم دوال RLS.
7. سحب EXECUTE العام/المجهول/للمستخدم المصادق من 16 دالة Trigger فقط، مع إبقاء الـTriggers مرتبطة وservice_role قادرًا على التنفيذ.

**الحالة:** المصدر التشغيلي ومحرك Edge والتعديلات البنيوية موجودة ومتحققة. لكن لا أعتبر Buyer مغلقًا نهائيًا قبل التحقق من نشر Cloudflare واختبار E2E مصادق لرفع الملف وقراءته من أدوار Buyer وFinance.

## 2. مصدر التغيير وحدوده

- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`
- HEAD الحالي: `b47a56379018e1965e98bb25015d860ba0f70a9f`
- Buyer blob: `d22d9d914069c820d47ba2dc7e6ead721e1b26d3`
- آخر تعديل Buyer: `a78aa2025142c3b30bbf19d155717e598f82c097`
- Tailwind CSS الناتج: commit `10e9a875053743dd9eeb593c973968086572cf14`, blob `0eaec7ca0c72047832d1fabccf0ee2415b8eb869`.
- مقارنة HEAD مع نقطة البداية `bf0833c3c71d7a2dea6167bfac9b5403e8044cf7`: 13 commit، والملفات التشغيلية المتغيرة فقط هي Buyer، ملف Buyer Tailwind الناتج، وملفات SQL migrations الثمانية.
- لم يتغير `main.html` أو `core.js` أو أي ملف Receiver. لا فرع جديد.

## 3. Buyer — فاتورة المورد ومرفقاتها

### الواجهة
- أضيف حقل ملف فاتورة المورد إلى Quick Market.
- الأنواع المقبولة: JPEG / PNG / WEBP / PDF.
- الحد الأعلى: 10 MB.
- إرفاق الملف إلزامي عند إنشاء مسودة Quick Market جديدة، أو تعديل مسودة لا يوجد لها مرفق؛ إذا كان للمسودة مرفق سابق فلا يلزم إعادة رفعه.
- بعد حفظ المسودة، يرفع Buyer الملف إلى bucket `employee-documents` الخاص، تحت مسار مرتبط بالشركة والمستخدم والفاتورة:
  `company/user/buyer-goods/invoice/supplier-invoice-operation`.
- بعد الرفع يستدعي `REGISTER_QUICK_MARKET_ATTACHMENT` لتسجيل `PurchaseInvoice` في `purchase_attachments`.
- تعرض شاشة تفاصيل الفاتورة المرفقات، ويُنشأ رابط Signed URL صالح لخمس دقائق عند طلب فتح الملف.
- إذا تم حفظ الفاتورة وفشل تأكيد ربط الملف، لا يحذف التطبيق الملف ولا يتظاهر بفشل إنشاء الفاتورة؛ يعرض بوضوح أن المسودة محفوظة وأن ربط المرفق يحتاج إعادة محاولة. يظل نفس operation id والمسار مستخدمين داخل المحاولة الحالية.

### سلامة المحاولة وإعادة التنفيذ
- مسار الملف ثابت داخل المحاولة ويستخدم `upsert` من Storage API.
- فهرس فريد على `company_id, document_type, document_id, storage_path` يمنع تسجيل المسار نفسه مرتين.
- Edge يتحقق من أن الفاتورة Quick Market، Draft وغير مستلمة، وأن المستخدم هو المشتري أو Owner.
- يتحقق من أن المسار يتبع الشركة والمستخدم والفاتورة و`buyer-goods`، ثم يتحقق من وجود الملف عبر `storage.from('employee-documents').info(path)`، ومن MIME والحجم.
- لا يكتب Edge مباشرة في `storage.objects`؛ عمليات الملفات عبر Storage API.

## 4. Edge v28 — الحالة الحية

- `save-purchase-order`: **v28 ACTIVE**.
- `verify_jwt=true`.
- SHA-256: `663b4bab72a4c81ec93b53d3f15a29902fa9984320f11a198209a46ac45646e2`.
- الأرشيف الحي: `Current/CTO/EdgeSnapshots/20261104/save-purchase-order_v28/index.ts`, blob `7291a8ca704213a244d740ed7ce8f01920f5dac4`.
- Manifest: `Current/CTO/EdgeSnapshots/20261104/save-purchase-order_v28/DEPLOYMENT_MANIFEST.md`, blob `e9ad87aca4801fbfd8b5ae45808298320586309c`.
- أعيد جلب المصدر من Production وتأكد التطابق byte-for-byte مع الأرشيف.
- v27 استُبدلت سريعًا بـv28 بعد مراجعة طريقة الوصول إلى metadata؛ v28 تستخدم Storage API `info(path)` بدل schema-qualified PostgREST lookup على `storage.objects`.

### GET_DATA
- للمستخدم غير المالي: `purchase_attachments` يعيد فقط مرفقات `PurchaseInvoice` للفواتير التي يحق للمستخدم رؤيتها.
- Finance / Finance Manager / Owner يحتفظون برؤية مرفقات الشركة وفق صلاحياتهم.
- هذا يتطابق مع سياسة RLS المباشرة على جدول المرفقات.

## 5. Production migrations — الثمانية المطبقة

| Version | Migration | النتيجة |
|---|---|---|
| `20261104213909` | `buyer_phase1_hardening_20261104` | حواجز تسوية العهدة، إثبات التسليم، وحذف الفاتورة بعد أحداث الحيازة |
| `20261104214839` | `buyer_purchase_returns_central_writer_only_20261104` | إلغاء DML المباشر على جداول المرتجعات |
| `20261104215236` | `buyer_goods_evidence_finance_storage_read_20261104` | قراءة Finance لأدلة buyer-goods المقيدة |
| `20261104215443` | `purchase_attachments_storage_path_idempotency_20261104` | فهرس فريد لمسار المرفق |
| `20261104215757` | `purchase_attachments_invoice_owner_read_20261104` | تقييد قراءة مرفقات الفاتورة |
| `20261104220325` | `buyer_phase1_fk_indexes_and_rls_eval_20261104` | فهارس أحداث الحيازة/المرتجعات وتحسين RLS |
| `20261104220515` | `buyer_purchase_cash_custody_fk_indexes_20261104` | 48 فهرس FK إضافيًا لدفاتر العهدة والمشتريات |
| `20261104220659` | `revoke_public_execute_trigger_functions_20261104` | سحب التنفيذ المباشر لدوال Trigger وتثبيت search_path |

جميع ملفات migrations الثمانية محفوظة في `supabase/migrations/` في المستودع التشغيلي، وبالأسماء المطابقة لإصدارات Production.

## 6. المرتجعات — Central Writer

تم مسح 34 ملف HTML/JS في `companies/company-1` وستة Edge function files:
- Parent `main.html` يقرأ `purchase_returns` عبر SELECT/RLS، وينشئ ويرحل المرتجع فقط عبر Edge `CREATE_RETURN` و`POST_RETURN`.
- Buyer يقرأ بيانات المرتجعات ولا ينفذ DML مباشرًا.
- RPCs `purchase_create_return_atomic` و`purchase_post_return_atomic` هما كاتبا المرتجعات المركزيان، `SECURITY DEFINER` وEXECUTE لـservice_role/postgres فقط.

بعد Migration:
- `anon`: لا صلاحيات على الجدولين.
- `authenticated`: SELECT فقط.
- `service_role`: SELECT/INSERT/UPDATE/DELETE.
- RLS للجدولين SELECT فقط وبنطاق الشركة.
- اختبار `has_table_privilege` أكد عدم وجود INSERT/UPDATE/DELETE للمستخدم المصادق عليه.

## 7. Storage وRLS للمرفقات

### Storage
- bucket `employee-documents` لا يزال Private.
- سياسة `buyer_goods_docs_select_finance` تسمح لـFinance وFinance Manager وOwner بقراءة ملفات المسار `buyer-goods` فقط عندما يطابق المسار شركة المستخدم وفاتورة Quick Market قائمة في الشركة نفسها.
- لم تُمنح Warehouse/Receiver صلاحية عامة؛ ستحتاج صلاحية مقيدة بالفرع عند فتح نطاق Receiver.
- تم التحقق من محللات مسار Storage للشركة والمستخدم ومن صلاحيات Finance. لم تُنشأ ملفات اختبار في Storage.

### purchase_attachments
- سياسة `purchase_attachments_select_scoped` تسمح بقراءة مرفقات PurchaseInvoice للمشتري/منشئ الفاتورة، أو Finance/Finance Manager/Owner.
- أنواع المستندات الأخرى احتفظت بقراءة الشركة القائمة لتجنب كسر مستهلكين خارج هذا النطاق.
- اختبار RLS بصف مؤقت داخل معاملة ثم ROLLBACK أعطى:
  - Buyer غير مالك الفاتورة: 0 صفوف.
  - Finance: صف واحد.
  - Finance Manager: صف واحد.
  - Owner: صف واحد.
  - Warehouse: 0 صفوف.
- اختبار الفهرس الفريد داخل معاملة: الإدخال الأول = 1، الإدخال المكرر = 0. انتهى الاختبار بـROLLBACK.

## 8. الأداء — فهارس Buyer/Purchase

- أضيفت 10 فهارس في migration `20261104220325` لأحداث حيازة البضاعة والمرتجعات، مع تحسين تقييم دوال RLS باستخدام scalar SELECT للدوال المستقرة.
- أضيفت 48 فهرس FK في migration `20261104220515` لدفاتر العهدة والمشتريات وتفاصيلها.
- نتيجة Supabase Performance Advisor بعد التطبيق: **0 unindexed FK findings في جداول buyer_* وpurchase_***. بقي 244 finding على مستوى بقية النظام؛ لم نعدل وحدات أخرى.
- توجد تحذيرات unused indexes على بعض الجداول الفارغة/قليلة البيانات؛ لا نحذفها لمجرد أنها لم تُستخدم بعد.

## 9. Security Advisor — نتائج التدقيق

### دوال Trigger
تم التأكد أن 16 دالة SECURITY DEFINER هي Trigger-only، ومربوطة بـTriggers فعلية، ولا توجد استدعاءات مباشرة لها في ملفات التطبيقات أو Edge التي فُحصت.
- سُحب EXECUTE من PUBLIC وanon وauthenticated.
- بقي EXECUTE لـpostgres وservice_role.
- بقيت الـTriggers الستة عشر مرتبطة بالجداول.
- لم نلغِ تنفيذ 20 RPC من Buyer/Purchase؛ فحصناها، وكلها تتحقق من `auth.uid()` ونطاق الشركة، وتطبق فحص الملكية/الصلاحيات المناسب. Edge يستخدم user JWT عبر profile client؛ سحب EXECUTE منها عشوائيًا كان سيكسر العمليات.

### Search path وPublic RPCs
- تم تثبيت `sales_decision_default_policy()` على `search_path=pg_catalog`.
- بقيت دالتا Public Store متاحتين عمدًا لـanon:
  - `get_public_store_catalog`: تعرض كتالوج المتجر المنشور.
  - `get_public_store_order_tracking`: البحث برقم الطلب وحده يعيد حالة مختصرة، والتفاصيل تتطلب رقم الطلب ورقم الهاتف.
- Security Advisor بعد التطبيق: 2 anon SECURITY DEFINER (Public Store المقصودتان)، و123 authenticated SECURITY DEFINER على مستوى النظام، و24 RLS-enabled-no-policy INFO، وتحذير Auth واحد متعلق بحماية كلمات المرور المسربة. لا تُعامل هذه الأرقام كلها كاختراقات؛ تحتاج مراجعة منفصلة حسب المستهلك والصلاحية.

## 10. الاختبارات وبيانات Production

### نجح
- اختبار SQL لكل migration داخل BEGIN/ROLLBACK قبل التطبيق، ثم تطبيقها في Production.
- تحقق migration versions الثمانية من `supabase_migrations.schema_migrations`.
- تحقق ACL/RLS بعد التطبيق.
- اختبار RLS للمرفقات بالأدوار الخمسة أعلاه مع rollback.
- اختبار unique attachment path مع rollback.
- تحقق بقاء الـTriggers مرتبطة بعد سحب EXECUTE.
- تحقق `sales_decision_default_policy` من search_path المثبت.
- Edge v28 ACTIVE ومصدره مطابق للأرشيف.
- JavaScript inline في Buyer اجتاز parse-only syntax check.
- ملف Tailwind الناتج يتضمن utilities المطلوبة، وتوجد له commit آلية بناء من GitHub Actions.

### لم ينفذ بعد
- لم ينفذ E2E مصادق لرفع ملف فعلي، تسجيله، إنشاء Signed URL، وقراءته من Buyer وFinance؛ لا توجد جلسة Browser مصادق عليها أو أداة Storage upload في هذه الجلسة.
- لم يتم التحقق من نشر Cloudflare Pages للـHEAD الحالي `b47a563`. إنشاء Tailwind CSS commit لا يثبت نشر Pages.
- لا توجد بيانات اختبار أو مرفقات اختبار باقية.

### حالة البيانات بعد التنفيذ
- العملة: EGP.
- فواتير الشراء: 3 تاريخية.
- Quick Market invoices: 0.
- Buyer cash custodies: 0.
- Buyer goods events: 0.
- Purchase returns/details: 0.
- Purchase attachments: 0.
- لم نغير الفواتير التاريخية Posted ولم نجرِ أي حركة مخزون أو خزينة أو حساب مورد.

## 11. الفجوات التي لم تُغلق بعد

1. Buyer→Warehouse handover مع قبول/رفض/قبول جزئي؛ يحتاج Receiver، وهو مؤجل حسب النطاق الحالي.
2. Buyer→Supplier handover؛ لا يوجد حتى الآن عقد مستندي مكتمل يثبت التسليم الفعلي ويربطه بمرتجع المورد/الأثر المحاسبي دون خصم مخزون غير موجود بالمخزن. لا نستخدم `purchase_returns` قسرًا على بضاعة ما زالت في عهدة السيارة.
3. صلاحية Warehouse/Receiver لقراءة أدلة البضاعة يجب أن تكون branch-scoped قبل فتح Receiver.
4. مصفوفة RLS المباشرة لـ`purchase_invoices` ما زالت أوسع من Edge GET_DATA؛ يلزم Consumer Map مستقل قبل تضييقها.
5. ثوابت `currency: 'SAR'` في Parent `main.html` ما زالت موجودة في payload واجهة الشراء، لكن Edge v28 يفرض عملة إعدادات النظام (EGP). لم نعدل Parent ضمن هذا النطاق.
6. Cloudflare deployment وAuthenticated E2E غير مثبتين.
7. بقية 244 unindexed FK findings و123 authenticated SECURITY DEFINER على مستوى النظام تحتاج خطة تدقيق مستقلة؛ لم نلمس وحدات غير Buyer/Purchase إلا ACL لدوال Trigger العامة التي ثبت أنها Trigger-only.
8. تحذير Auth الخاص بحماية كلمات المرور المسربة ما زال قائمًا ولم نغير إعدادات Auth.

**الحالة النهائية لهذه الدفعة:**  
`BUYER QUICK MARKET ATTACHMENT SOURCE IMPLEMENTED / EDGE v28 ACTIVE / RETURNS CENTRAL WRITER ENFORCED / STORAGE AND ATTACHMENT RLS HARDENED / BUYER-PURCHASE FK INDEX GAPS CLOSED / TRIGGER RPC EXPOSURE REDUCED / JS PARSE PASS / CSS GENERATED / CLOUDFLARE UNVERIFIED / AUTHENTICATED E2E NOT RUN / BUYER NOT CLOSED / RECEIVER DEFERRED`.
