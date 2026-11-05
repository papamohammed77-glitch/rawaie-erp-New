# Report637 — RAWAEA ERP Daily CTO Review: PO Approval, Receiver Security and Production Revalidation

**التاريخ:** 2026-11-05 — 22:29 Africa/Cairo (20:29 UTC)  
**نقطة الاستئناف:** LVE636 / Report636 — اعتماد PO وحارس Receiving في SMART ERP Production.  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`.  
**مستودع الحوكمة:** `papamohammed77-glitch/rawaie-erp-New` / `main`.  
**Supabase:** مشروع SMART ERP `fiilmooggumokxanwiyx`.  
**طبيعة هذا التشغيل:** قراءة وتحقق فقط؛ لا تغييرات في الكود التشغيلي أو Supabase، ولا إنشاء بيانات QA أو معاملات اختبار.

---

## 1. نقطة البداية — LAST VERIFIED EVENT / CHECKPOINT

- بدأ الفحص من `CURRENT_STATE.md` كاملًا (Blob SHA وقت القراءة: `1801c1831381ef6c5421ce73ee4d02d2ebfc10fb`)، ثم قُرئ `doc/Draft/Reprots/الدستور التشغيلي الدائم.md` كاملًا (Blob SHA: `d2afa896514b1cb6abd247d2af7a862251ce0604`)، قبل التقارير والكود وProduction.
- آخر نقطة مثبتة كانت **LVE636**، تقرير التنفيذ `Report636_PO_APPROVAL_PRODUCTION_EXECUTION_20261105.md`، Commit `3ce25b9b368841b31be0106206cd243d28cc4685` بتاريخ 2026-11-05 17:49:49 UTC.
- LVE636 أثبت تنفيذ RPC الاعتماد وحارس الاستلام مباشرة في Production، ونشر Edge v30/v14، وتحديث `supervisor.html` و`receiver.html` على `main`، مع بقاء نشر Cloudflare غير مثبت.
- ظهر خلل توثيقي: بداية `CURRENT_STATE.md` ما زالت تعرض LVE632 على أنه الأحدث، بينما LVE636 موجود في نهاية الملف. هذا لا يغيّر النظام، لكنه قد يضلل نقطة الاستئناف؛ سيُضاف LVE637 في مقدمة الحالة ويُعاد وسم LVE632 كتاريخي.

## 2. CONFIRMED — الحقائق الحالية

### 2.1 GitHub / Source

- المستودع التشغيلي عام، والفرع الافتراضي `main`.
- أحدث Commit تشغيلي متحقق: `b728c09e1bb4c482effc48a492546b393ff02c1f` — تعديل `warehouse/receiver.html`.
- Commit المشرف: `cf07aba424f5ca37cf75ac1804d756448841f4ea`.
- Commit تعديل المالك في `main.html`: `684a55240a2f1145134b367204ef0da2c0b696e2`.
- لا توجد Commit status checks على b728 في GitHub وقت الفحص؛ هذا ليس دليل فشل نشر، ولا يثبت نجاح Cloudflare.
- Blobs الحالية:
  - `main.html`: `59241e741abcbc318fa68d3c10775e40e2688927` — نحو 1.8MB.
  - `purchasing/supervisor.html`: `8d46c3c6d6df487ebd880c29d438bcdd2bd789bf`.
  - `warehouse/receiver.html`: `075ddf9e5801c25bd337d65bf883b4bf4b5736c3`.
  - `purchasing/buyer.html`: `5ab9f4e268cbf266e6ff950fe41bf5c9a4c9390a` — لم يتغير منذ نقطة Buyer السابقة.
  - `core.js`: `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`.
  - `app.html`: `2e47a68fe83956e27d569e786a08dcee91af2924`.
  - `sw.js`: `6123fce8b99391d70e6937bde5c4fcbd3f2d8f48`.
  - `register-sw.js`: `319697023f64265dd93691b078c070284733e1f0`.

### 2.2 مراجعة main.html التي نفذها المالك

- لم أعدّل `main.html`.
- شرط زر اعتماد PO في مودال تفاصيل الأمر هو Draft + `RW_Permissions_check('purchases')`.
- دالة `approvePO` تتحقق من `purchases`، وتستدعي `api('APPROVE_PO', { id: poId }))، وهي مصدّرة ضمن `RW_PurchaseGold` ويستدعيها زر المودال.
- دالة `api()` داخل Parent تنشئ `operation_id` فريدًا وترسله في الجسم وHeader `Idempotency-Key`.
- التعديل الوظيفي صحيح ومتوافق مع توضيح المالك بتاريخ 2026-11-05 16:59 UTC: لا يشترط `purchases_supervisor` لاعتماد PO من النظام الأم؛ يكفي `purchases`. أما تطبيق `supervisor.html` فيبقى لمستخدم `purchases_supervisor` أو المالك.
- بقيت رسالة رفض قديمة داخل `approvePO` تقول «يتطلب صلاحية مشرف المشتريات» رغم أن الشرط `purchases`. خلل نصي فقط؛ لم أعدّل الملف.

### 2.3 Supabase Production — الدوال والعقود

- `save-purchase-order`: ACTIVE v30، `verify_jwt=true`، SHA-256 `838f8c05d5e64f040dc4a346eae52816877d635bab41684d32d77eebeae304e6`.
- `receive-purchase`: ACTIVE v14، `verify_jwt=true`، SHA-256 `05584598ded76f17ff6e29d4c6fb951d2f347ed7fdd3549ec457d929756a74fb`.
- `APPROVE_PO` في Edge v30 يتحقق من Effective Profile عبر JWT المستخدم، ثم يسمح بـ`purchases` أو `purchases_supervisor` ويستدعي RPC عبر Client يحمل JWT المستخدم، لا عبر Service Role.
- `public.purchase_approve_po_atomic(uuid)` موجودة: `SECURITY DEFINER`, `search_path TO ''`, تحقق من `auth.uid()` والمستخدم النشط والشركة والصلاحية، تقفل PO بـ`FOR UPDATE`, تسمح بـDraft فقط، وتعيد duplicate عند Approved. تحديثها يقتصر على `status` و`updated_at` وتضبط `rawaea.purchase_actor`.
- ACL: `authenticated` لديه EXECUTE على RPC الاعتماد؛ `anon` و`PUBLIC` لا يملكونه.
- `app_private.guard_po_receiving_status()` موجودة مع Trigger `trg_receiving_require_approved_po BEFORE INSERT ON public.receiving`. تقبل PO المرتبط فقط عند Approved/Sent/Partially Received، وترفض غياب الشركة أو PO غير الموجود. تنفيذ الدالة مباشرة غير ممنوح للأدوار العامة.
- `receive_purchase_atomic` بالنسختين 4 و5 معاملات لا يملك EXECUTE عليهما إلا `service_role`; لذلك Edge v14 هو بوابة المستخدم الحالية. Edge v14 يرفض استلامًا لا يتضمن كمية موجبة.
- لا يوجد PO-approval Migration في سجل Supabase migrations؛ DDL الاعتماد والحارس نُفذ مباشرة في Production حسب قرار المالك، وMigration/ملفات المستودع هنا توثيق فقط.

### 2.4 تغيّر بيانات Production بعد LVE636

تقرير636 Commit عند 17:49:49 UTC سجل أمرًا واحدًا Draft وصفر Receiving وصفر PO history. بعد ذلك أظهرت القراءة الحالية:

| المستند | الحدث الحالي | الدليل |
|---|---|---|
| `QA-SR-PO-20260927` | Draft → Approved في 17:52:32 UTC بواسطة دور مدير النظام/Owner | سجل `purchase_status_history` |
| `PO-20260928` | أُنشئ Draft في 18:02:42 UTC بواسطة دور مسؤول مشتريات، ثم Draft → Approved في 18:05:00 UTC بواسطة دور مشرف مشتريات | سجلان في `purchase_status_history` |

- `PO-20260928`: إجمالي 700 EGP، بندان، `qty_received=0`.
- `QA-SR-PO-20260927`: ما زالت تفاصيله تسجل 5/5 مستلمة، لكن لا يوجد أي Receiving أو Receiving Details مرتبطان به. أصبح الآن Approved، ولذلك سيظهر في قائمة Receiver رغم عدم وجود كمية متبقية قابلة للاستلام.
- لقطة Production: `purchase_orders=2` (كلاهما Approved)، `receiving=0`, `receiving_details=0`, `purchase_status_history=3`, `purchase_invoices=3`, `buyer_custodies=0`, `buyer_custody_expenses=0`.
- لم يظهر مرجع لأي من رقمي PO في `inventory_log` أو `supplier_ledger` أو `journal_entries`. إجماليات الجداول وقت القراءة: inventory_log 76، supplier_ledger 2، journal_entries 19.
- لا دليل على أثر مخزني أو مالي ناتج عن الاعتمادين. هذا متوافق مع قاعدة أن اعتماد PO وحده لا ينشئ استلامًا أو مخزونًا أو قيدًا.
- لا أغيّر `QA-SR-PO-20260927` تلقائيًا؛ يجب اعتباره سجل QA متعارضًا يحتاج مصالحة، وليس بيانات اختبار جديدة أنشأها هذا التشغيل.

### 2.5 RLS / GRANTS / Audit

- `purchase_orders` و`purchase_order_details`: صلاحية authenticated هي SELECT فقط، ولا يملك المستخدم العادي INSERT/UPDATE/DELETE.
- `receiving` و`receiving_details`: توجد Grants DML على مستوى الجدول، لكن RLS الحالي يوفّر SELECT فقط ولا توجد سياسات DML للأدوار العامة؛ لذلك لا يثبت هذا الفحص قدرة المستخدم المصادق على الكتابة فيهما.
- **مشكلة مؤكدة:** `purchase_status_history` لديه RLS مفعّل وسياسة `ALL` باسم `purchase_status_history_company` موجّهة إلى `public` مع `USING` و`WITH CHECK` على `current_user_company_id()`. كما أن authenticated يملك SELECT/INSERT/UPDATE/DELETE على الجدول. النتيجة: مستخدم مصادق داخل الشركة يستطيع إضافة أو تعديل أو حذف سجل تاريخ الحالة الخاص بشركته، بما يضعف سلامة سجل التدقيق. لا يوجد Trigger على جدول التاريخ يمنع UPDATE/DELETE. لم أجرّب كتابة في Production.
- Trigger `purchase_company_status_history` يسجل INSERT وتغير الحالة، لكنه لا يجعل جدول التاريخ append-only ما دامت سياسة DML المباشرة تسمح بالتعديل.

### 2.6 Buyer / COA

- Buyer blob لم يتغير منذ LVE636.
- قراءة COA الحالية أظهرت الحسابات النشطة ذات الصلة: 5 «المصروفات وتكلفة المبيعات»، 51 «تكلفة المبيعات»، 52 «فروقات وتسويات المخزون والتوالف». لا يظهر حساب مصروف تشغيلي واضح كحساب Leaf للنقل/الوقود.
- هذا يعيد تأكيد مانع ترحيل المصروفات التشغيلية في Buyer كما ورد في Report632؛ لم تُنشأ عهد أو مصروفات اختبار.

## 3. UNKNOWN

1. هل اعتماد PO ذاتيًا بواسطة منشئه مسموح تجاريًا؟ الـRPC الحالي لا يمنعه. Report634 اقترح منع المنشئ، بينما Report635 حذف هذا المنع استنادًا إلى تفسير قرار الصلاحية. توضيح المالك في 2026-11-05 16:59 UTC حسم من يملك صلاحية Parent approval، لكنه لم يذكر صراحةً فصل المنشئ عن المعتمد.
2. هل سجل `QA-SR-PO-20260927` يمثل تسليمًا ميدانيًا سابقًا أم مجرد بيانات QA غير مكتملة؟ لا يوجد Receiving يثبت الواقعة.
3. هل النشر الحالي على Cloudflare يطابق Commit b728؟ لا تتوفر في هذا التشغيل أدلة لوحة Pages أو Artifact حي.
4. لا توجد نتيجة Runtime مصادق عليها لتسجيل دخول مستخدم `purchases` أو `purchases_supervisor` أو Receiver.
5. لا يوجد Staging مثبت بتماثل Schema مع Production.

## 4. CONFLICT

- **تعارض سياسة فصل الواجبات:** Report633/Report634 طلبا منع منشئ PO من اعتماد أمره. Report635 نص على عدم منع المنشئ، مستندًا إلى قرار الصلاحية. قرار المالك الصريح بتاريخ 2026-11-05 16:59 UTC يحدد صلاحية الاعتماد في Parent بـ`purchases` ويخصص `purchases_supervisor` لتطبيق المشرف، لكنه لا يحسم صراحةً قاعدة self-approval. المصدر الحي يسمح بها. لا أغيّر ذلك بالتخمين.
- **تعارض حالة QA:** Report636 أثبت أن QA-SR PO بقي Draft دون تاريخ حالة؛ القراءة الحالية بعد 17:52 UTC تُظهره Approved مع `qty_received=5` دون Receiving. هذا تغير Production بعد LVE636، وليس سببًا لإعادة ضبط المستند.
- **تعارض توثيقي:** أول CURRENT_STATE ما زال يشير إلى LVE632 كالأحدث، بينما LVE636 موجود لاحقًا في الملف.

## 5. UNVERIFIED

- نشر Cloudflare لآخر Commits `cf07aba` و`b728c09`.
- HTML/JS الذي يخدمه Pages حاليًا، cache headers، وService Worker الفعلي.
- Console/Network وأخطاء JavaScript أثناء جلسة مصادق عليها.
- E2E من إنشاء PO إلى الاعتماد ثم الاستلام الفعلي ثم فاتورة المورد.
- Realtime delivery/latency في متصفحين أو جهازين؛ وجود Publication وListener لا يثبت وصول الحدث.
- اختبار عدم الأثر التجاري في بيئة Staging؛ لم تُستخدم Production كبيئة اختبار.

## 6. مصفوفة التحقق

| الطبقة | النتيجة | الحالة |
|---|---|---|
| GitHub / Source | HEAD b728؛ main/supervisor/receiver/core مفحوصة في النطاق | CONFIRMED |
| Supabase Production | RPC/Trigger/ACL/RLS/Edge والبيانات الحالية مقروءة | CONFIRMED |
| Deployed Artifact | آخر نشر Pages غير متاح للتحقق | UNKNOWN |
| Runtime / E2E | لا جلسة Browser مصادق عليها ولا Console/Network | UNVERIFIED |
| Business-data effects | لا Receiving ولا أثر PO matching في المخزون/دفتر المورد/GL | CONFIRMED ضمن الاستعلامات |
| Staging | لم يثبت وجود بيئة منفصلة متطابقة | UNKNOWN |

## 7. ما تم فعليًا في هذا التشغيل

- قراءة CURRENT_STATE والدستور التشغيلي الدائم قبل التاريخ والكود.
- مطابقة Report632–Report636 وReport612 وReport633، مع مراجعة باب الموافقات في Report614.
- إعادة التحقق من الفرع وHEAD وCommits وBlobs الحالية.
- مراجعة main.html دون تعديله.
- قراءة supervisor.html وreceiver.html وcore.js وapp.html وsw.js وregister-sw.js.
- فحص صياغة JavaScript للملفين Supervisor وReceiver بنجاح.
- قراءة Edge v30/v14 وRPC/Trigger definitions وACL/RLS/Publication.
- مراجعة سجلات PO الجديدة وعدم وجود أثر مخزني/مالي مطابق.
- عدم تنفيذ أي DDL أو DML أو نشر أو تعديل ملفات تشغيلية.

## 8. ما لم يتم ولماذا

- لم يتم تعديل Production لأن هذه المراجعة لم تتضمن ChangeSet جديدًا محددًا معتمدًا؛ الدستور §14 يتطلب عرض SQL/النص والأثر والاختبارات والتراجع ثم الموافقة الصريحة.
- لم يتم تعديل main.html أو supervisor.html أو receiver.html أو core.js؛ ملفات النظام الأم والتطبيقات التشغيلية يطبق المالك تعديلاتها.
- لم يتم إنشاء PO أو Receiving أو بيانات QA في Production.
- لم يتم اختبار Cloudflare أو Browser بسبب عدم توافر Artifact/جلسة Browser قابلة للفحص في هذا التشغيل.
- لم يتم إجراء اختبار كتابة داخل Production على سياسة التاريخ أو الاستلام؛ النتائج مستخلصة من ACL/RLS والعقود فقط.

## 9. صحة النظام والتطبيقات التشغيلية والتغطية

**فُحص اليوم:** Parent main.html، Supervisor، Receiver، Core، app router، Service Worker، دوال PO/Receiving، وجداول المشتريات ذات الصلة.

**فُحص سابقًا ولم يتغير حسب Source HEAD:** Buyer، وملفات البيع والتوصيل والمخازن الأخرى؛ لم تُعد مراجعتها كاملة اليوم.

**لم يُفحص اليوم:** POS، Telesales، Order Taker، Van Sales، Driver، Picker، Loader، Unloader، Returns، Vouchers، Counter، Warehouse Manager، Accountant، Finance Manager، Treasury، Storefront، BI، Forecasting. لا أصف هذه التطبيقات بأنها سليمة؛ لا يوجد تغير معروف في ملفاتها ضمن Commits الحالية، ولذلك لم تُفتح دورة فحص جديدة لها.

**حالة التطبيقات في النطاق:**
- Parent: مسار اعتماد PO صحيح من المصدر، مع رسالة رفض قديمة.
- Supervisor: بوابة دخول `purchases_supervisor`/Owner، قائمة كل أوامر الشركة مع Pagination وبحث وتصفية وتفاصيل واعتماد.
- Receiver: Pagination وتفاصيل عبر `po_id` والتحقق من الكميات وحد الاستلام، لكنه يحمل مخاطر XSS وIdempotency ونطاق الفرع.
- Buyer: المصدر لم يتغير؛ مانع حساب المصروفات التشغيلية ما زال قائمًا.

## 10. تدقيق التعديلات الأخيرة وآثارها

- Commit 684a: تعديل المالك لشرط Parent approval من `purchases_supervisor` إلى `purchases`; صحيح.
- Commit cf07: Supervisor pagination/search/filter/details/approval; source parse PASS.
- Commit b728: Receiver tenant filter/pagination/detail error handling/positive quantity/upper bound; source parse PASS.
- Edge v30/v14 نشطتان. لا يوجد دليل نشر Pages للـCommits الأخيرة.
- تغير Production بعد Report636: اعتماد QA-SR PO وإنشاء واعتماد PO-20260928. لا توجد Receiving أو حركات مخزون/دفتر مورد/قيود مطابقة؛ لم يحدث أثر مالي أو مخزني من مجرد الاعتماد.
- لا أعتبر هذا اختبار E2E؛ هو سجل أعمال Production ومراجعة آثار قراءة فقط.

## 11. الأخطاء والفجوات والأسباب

### P1 — Stored XSS sink في Receiver

- `RW_UI.safeHTML` في Core لا ينظف HTML؛ ينفذ `element.innerHTML = html`.
- `receiver.html` يركب في HTML قيمًا قادمة من DB دون escaping، ومنها `po.po_code` و`supplier_name` و`item_name` و`item_code` و`unit` واسم المستخدم، كما يضع PO code داخل inline onclick.
- السبب الجذري: الخلط بين اسم `safeHTML` وبين Sanitizer فعلي، وعدم ترميز قيم البيانات قبل إدخالها إلى DOM.
- النتيجة: مصدر Stored DOM-XSS مؤكد في المصدر؛ لم يتم حقن Payload أو اختبار استغلال. يجب إصلاحه قبل اعتبار Receiver آمنًا.

### P1 — Idempotency collision في الاستلام

- `receiver.html` يستدعي `RW_API.call('receive-purchase', {po_code, itemsReceived, notes})` دون `operation_id`.
- `RW_API.call` في `core.js` يرسل Authorization وContent-Type فقط؛ لا يرسل `Idempotency-Key`.
- Edge v14 يولد fallback UUID حتميًا من user/company/PO/items إذا لم يصل مفتاح.
- `receive_purchase_atomic` يعيد duplicate success إذا وجد نفس operation key ونفس fingerprint، قبل فحص الكمية المتبقية.
- لذلك استلام جزئي لاحق مستقل بنفس الكمية ونفس قائمة الأصناف قد يُعامل كتكرار للعملية السابقة ولا يسجل حركة جديدة. لا توجد Receiving حاليًا تثبت وقوع الضرر؛ الخطر مثبت من مسار المصدر.
- العلاج المطلوب: operation_id فريد لكل نية استلام مادية، ثابت عند إعادة محاولة النتيجة المجهولة، ويُرسل صراحةً في body/Idempotency-Key. لا يُستخدم deterministic fallback لعمليات مستقلة.

### P1 — سجل حالة PO قابل للتعديل مباشرة

- authenticated لديه DML grants على `purchase_status_history`.
- سياسة RLS الحالية ALL على `public` تسمح للمستخدم داخل شركته بـINSERT/UPDATE/DELETE.
- لا يوجد Trigger على جدول history يمنع التعديل أو الحذف.
- السبب: صلاحيات الجدول وسياسة RLS أوسع من عقد سجل تدقيق append-only.
- لا أطبق REVOKE أو تغيير Policy قبل ChangeSet معتمد وبعد مسح كل مستهلكي الجدول. المقترح الفني الأولي: سحب INSERT/UPDATE/DELETE من anon/authenticated، والإبقاء على SELECT tenant-scoped، مع إثبات أن Trigger status writer يعمل تحت صلاحياته الحالية.

### P2 — نطاق الفرع في Receiver

- `loadPurchaseOrders` يفلتر بالشركة والحالة فقط ولا يحدد `branch_id` أو `allowed_branch_ids`.
- `receive_purchase_atomic` يتحقق من فرع المستخدم قبل الكتابة، فيمنع الاستلام غير المصرح، لكنه لا يمنع عرض أوامر فروع أخرى.
- المطلوب تحديد نطاق العرض من الملف الشخصي الموثق، مع الحفاظ على تحقق RPC.

### P2 — لا يوجد إرسال رسمي لـPO للمورد

- Edge v30 يحتوي `APPROVE_PO` ولا يحتوي `SEND_PO` أو `ISSUE_PO`.
- لا يوجد إجراء إرسال أو سجل قناة/تاريخ/مستلم يثبت تسليم نسخة PO للمورد.
- Approved يسمح لـReceiver بالاستلام، لكن Approved لا يثبت أن المورد استلم أمر الشراء.
- هذا يتبع فجوة Report633 §9.5 ولا تُغلقها إضافة الاعتماد وحدها.

### P2 — Supervisor Dashboard

- حساب اليوم يستخدم `toISOString()` (UTC) بدل تاريخ القاهرة المحلي، وقد يخطئ حد اليوم في الساعات الأولى محليًا.
- `renderDashboard` لا يفحص `error` لكل استعلام؛ قد يعرض أصفارًا عند فشل القراءة بدل إظهار خطأ.
- لا يوجد اختبار Runtime لهذا التبويب.

### P2 — QA PO غير قابل للاستلام

- `QA-SR-PO-20260927` Approved، لكن `qty_received=5/5` بلا Receiving.
- سيظهر في قائمة Receiver، مع عدم وجود كمية متبقية وزر الاستلام مخفي.
- لا تنظف أو تعكس الحالة تلقائيًا؛ يلزم تحديد الحقيقة التجارية/QA قبل أي تعديل.

## 12. الكفاءة التشغيلية والميدانية

| السيناريو | التصميم/الكود | Production evidence | الحكم |
|---|---|---|---|
| إنشاء PO Draft | موجود في Parent/Buyer عبر RPC | PO-20260928 موجود | مثبت جزئيًا |
| اعتماد PO | RPC/Edge/Parent/Supervisor موجود | حدثان Approved مسجلان | انتقال DB مثبت؛ UI E2E غير مثبت |
| إرسال PO للمورد | لا يوجد SEND_PO | لا يوجد سجل إرسال | غير موجود/غير مثبت |
| استلام PO | Edge/RPC/Trigger موجودة | Receiving صفر | كود موجود، لا واقعة استلام مثبتة |
| فاتورة المورد والمطابقة | جداول وRPC منفصلة | 3 فواتير، لا اختبار ربط اليوم | غير مكتمل في هذه المراجعة |
| مصروفات المشتري | عقد Buyer/Finance موجود جزئيًا | لا عهد/مصروفات، ولا Leaf تشغيلية في COA | معطل بمانع COA |
| تسوية المورد والخزينة | لم تُختبر اليوم | لا أثر PO مطابق | UNKNOWN |

## 13. التخطيط والتنبؤ ومركز القرار الذكي

- لا يوجد في نطاق الملفات أو الجداول المفحوصة اليوم دليل على Forecasting مقاس للطلب أو MAPE أو توقع نفاد أو توصية شراء تمت مقارنتها بنتائج فعلية.
- وجود KPI شهري بسيط في Supervisor لا يثبت ذكاءً تنبؤيًا.
- الحالة: UNKNOWN؛ لا تُمنح درجة نضج دون بيانات تاريخية واختبار Backtesting.

## 14. Benchmarking

- المرجع التاريخي الحالي هو Report633 §12، الذي قارن الفصل بين PO وفاتورة المورد ومراحل الاستلام/الفوترة في Odoo وDynamics 365 Finance وSAP S/4HANA وManager.io.
- Report633 لم يجد وثائق رسمية كافية لتأكيد تفاصيل Daftra وNeXT ERP، ولذلك لم ينسب إليهما خصائص غير مثبتة.
- لا توجد حاجة إلى إعادة بحث تنافسي اليوم؛ الفجوة الجديدة الواضحة هي غياب حدث إرسال PO للمورد، مع ضرورة الحفاظ على فصل PO عن Vendor Invoice وGRN/Receiving.
- لا أدعي تكافؤ RAWAEA مع الأنظمة المرجعية أو جاهزية عالمية من هذه الأدلة.

## 15. مصفوفة النضج — نطاق المشتريات/الاعتماد فقط

| المجال | الدرجة | الدليل/الثقة |
|---|---:|---|
| 1. السلامة التقنية والمعمارية | 2/5 | Parent/Core منفصلان جزئيًا؛ Source-only |
| 2. تكامل التطبيقات والبيانات | 2/5 | DB مشتركة وRealtime مهيأ؛ Runtime غير مثبت |
| 3. العمليات التجارية | 2/5 | PO approval موجود؛ SEND_PO والاستلام الفعلي غير مثبتين |
| 4. الرقابة المالية والمحاسبية | UNKNOWN | لا E2E مالي؛ COA مصروف تشغيلي ناقص |
| 5. المخزون وسلاسل الإمداد | 2/5 | RPC/Trigger موجودان؛ لا Receiving فعلي، وIdempotency خطر |
| 6. التوزيع والعمل الميداني | UNKNOWN | لم يفحص اليوم |
| 7. التخطيط والتنبؤ | UNKNOWN | لا قياس أو Backtesting |
| 8. التقارير وBI | 1/5 (Supervisor فقط) | KPIs شهرية بسيطة غير متحققة |
| 9. الأمان والصلاحيات والتدقيق | 2/5 | Server permissions/RLS، مقابل XSS وhistory DML |
| 10. الأداء والاستقرار والتوسع | 2/5 | Pagination وReconcile 60s؛ لا load test |
| 11. تجربة المستخدم والإنتاجية | 2/5 | بحث/تفاصيل/اعتماد؛ لا E2E ومخاطر Receiver |
| 12. الجاهزية التشغيلية والتنافسية | 1/5 (نطاق PO) | دورة PO غير مكتملة من الاعتماد إلى الإرسال والاستلام والفاتورة |

هذه درجات نطاقية وليست تقييمًا شاملًا لكل RAWAEA ERP؛ المجالات غير المفحوصة تبقى UNKNOWN.

## 16. خريطة النظام الأم والقلب المركزي

- `companies/company-1/core.js` هو المسار الفعلي؛ Blob `f4c6a0df...`, 1008 سطرًا تقريبًا.
- وحداته: RW_Auth, RW_DB (Dexie/local), RW_API (Edge fetch), RW_UI, RW_ImageCache, RW_SW, RW_Realtime.
- Supervisor وReceiver يحملان `../core.js` و`../register-sw.js`.
- `main.html` لا يحمل `core.js`; لديه Supabase client وAuth/permission/API محلية، ودالة `api()` مستقلة، وقنوات Supabase مباشرة.
- `app.html` Router/Login مستقل ولا يحمل `core.js`.
- Report612 سبق أن أحصى 30 HTML و26 Core consumers في لقطة 2026-11-04؛ لم أعد مسح كل التطبيقات اليوم لأن Core لم يتغير ضمن Commits الحالية.
- Core ليس قلبًا موحدًا لكل النظام حتى الآن؛ المركزية جزئية بين PWAs، بينما Parent له مسار موازٍ.
- `RW_API.call` لا يوفر `operation_id` أو `Idempotency-Key`; Parent `api()` يفعل ذلك، ما يفسر تفاوت عقد إعادة المحاولة.

## 17. مصفوفة المزامنة

| المكوّن | الآلية | ما ثبت | ما لم يثبت |
|---|---|---|---|
| Supervisor | RW_Realtime على purchase_orders، INSERT/UPDATE، company filter، debounce 500ms، reconcile 60s | Source + Publication | وصول الحدث/latency |
| Receiver | RW_Realtime على purchase_orders، نفس النمط | Source + Publication | وصول الحدث/latency |
| Core | SUBSCRIBED يسبب reconcile أولي/بعد reconnect؛ visibility وperiodic reconcile؛ cleanup عند logout | Source | reconnect E2E |
| Parent | قنوات Supabase مباشرة داخل main | Source count فقط | خريطة كل قناة/Runtime |
| DB Publication | purchase_orders وpurchase_order_details وpurchase_status_history في supabase_realtime | Production metadata | event delivery |
| DELETE | RW_Realtime يرشح INSERT/UPDATE فقط | Source | لا يوجد اشتراك DELETE في هذا المحرك |

لا توصف المزامنة بأنها لحظية مثبتة؛ هناك Realtime مهيأ مع reconciliation كل 60 ثانية، لكن لا يوجد قياس متصفح.

## 18. جاهزية استلام الشعلة

**الحكم: READY WITH LIMITATIONS.**

المتاح:
- CURRENT_STATE والدستور والتاريخ تمت قراءتها.
- GitHub وSupabase read access متاحان.
- مسار PO/Receiver وCore والاعتماديات المباشرة معروفة.
- يمكن تجهيز ChangeSet جراحي ومراجعته.

القيود:
- لا Cloudflare deployment artifact حالي.
- لا Browser مصادق/Console/Network.
- لا Staging.
- تغييرات Production الجديدة تتطلب ChangeSet محددًا وموافقة المالك.
- ملفات النظام الأم والتطبيقات التشغيلية يطبقها المالك.

## 19. الالتزام بالدستور التشغيلي الدائم

- قُرئ `doc/Draft/Reprots/الدستور التشغيلي الدائم.md` كاملًا قبل فحص التقارير والكود وProduction.
- طُبقت بوابة §14: لا DDL/DML/Edge deploy أو تعديل تطبيق تشغيلي دون ChangeSet محدد وموافقة صريحة.
- لم أستخدم Production كبيئة اختبار، ولم أنشئ سجلات أو أحذف/أعدل بيانات أعمال.
- لم أعدّل `main.html` أو `core.js` أو ملفات PWA.
- Migration لا تُستخدم كوسيلة تنفيذ؛ أي DDL مستقبلًا ينفذ مباشرة في SMART ERP بعد الموافقة، وتوثق SQL والنتيجة في تقرير فقط.

## 20. المخاطر والاعتماديات وقرارات المالك

1. اعتماد ChangeSet أمني لـReceiver: escaping لكل بيانات DB قبل DOM، وإزالة inline onclick المبني من PO code.
2. اعتماد عقد idempotency للاستلام: operation_id لكل واقعة مادية، ثابت عند retry لنفس المحاولة، ومختلف لواقعة لاحقة.
3. اعتماد تغيير RLS/GRANTS لجعل `purchase_status_history` append-only، بعد حصر جميع مستهلكيه.
4. حسم سياسة self-approval صراحةً: هل يُمنع منشئ PO من اعتماده، أم أن `purchases` كافية حتى للمنشئ؟
5. حسم هل Receiver يعرض أوامر كل الشركة أم أوامر الفروع المسموح بها فقط.
6. تصميم إجراء `SEND_PO` داخل Edge الحالية، مع سجل إرسال/مستلم/قناة/وقت؛ لا Edge Function جديدة.
7. تأكيد Cloudflare نشر b728 ثم اختبار Browser مصادق.
8. إضافة حسابات مصروفات تشغيلية Leaf مناسبة للنقل/الوقود عبر ChangeSet محاسبي معتمد، لا باستخدام حساب COGS أو inventory variance كبديل.

## 21. الخطوة التالية الواحدة ذات الأولوية

**إعداد ChangeSet واحد معتمد لحماية Receiver قبل إغلاق دورة PO:** يشمل إزالة DOM-XSS، وإرسال operation_id ثابت لكل محاولة استلام، وتطبيق نطاق الفرع، ثم حزمة Supabase منفصلة append-only لسجل التاريخ بعد مراجعة مستهلكيه. يطبق المالك تعديل `receiver.html`، ولا ينفذ CTO تغييرات Production/RLS إلا بعد موافقة المالك على النص والأثر والاختبارات والتراجع. معيار القبول: لا قيم DB غير مرمزة تدخل DOM، ولا عمليتا استلام ماديتان مستقلتان تشتركان في المفتاح، ولا مستخدم يرى/يستلم PO خارج نطاقه، ولا يستطيع تعديل سجل الحالة مباشرة، مع إثبات عدم تكرار المخزون/المورد/GL في Staging أو اختبار معزول.

---

**الخلاصة:** LVE636 لم يعد يعكس بيانات Production الحالية؛ ظهرت عمليتا اعتماد PO بعده، دون استلام أو أثر مالي/مخزني. الاعتماد والحارس الخلفيان ما زالا موجودين وACL الخاص بهما سليم في النطاق المفحوص. لكن لا يمكن إغلاق دورة PO: نشر الواجهات غير مثبت، Receiver يحمل ثلاثة مخاطر P1/P2 (XSS، Idempotency، نطاق الفرع)، وسجل تاريخ الحالة قابل للتعديل المباشر. لا تغييرات تشغيلية تمت في هذا التشغيل.
