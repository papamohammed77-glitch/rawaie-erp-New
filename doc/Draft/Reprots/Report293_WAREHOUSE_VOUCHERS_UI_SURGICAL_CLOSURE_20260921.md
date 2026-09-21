# تقرير 293 — إغلاق جراحي لتطبيق الأذونات المخزنية
## Warehouse Vouchers UI / Quantity Selection / Upper Panel Collapse
### التاريخ: 2026-09-21

## 1. نطاق التنفيذ
Closure Unit واحدة فقط:
- الملف المستهدف: `erp-frontend/companies/company-1/warehouse/vouchers.html`
- المطلوب: زر طي/توسيع الجزء العلوي من مساحة إنشاء الإذن + اختيار كمية الإضافة إلى السلة من مودال الصنف.
- التكامل: الحفاظ على العقد الحالي مع النظام الأم والـRPC/Edge الحالي.
- الممنوع: تعديل `main.html`، أو إعادة بناء Van Sales، أو إعادة فتح عقود V-03/V-04/V-05/V-06/V-07/V-08 المغلقة.

## 2. مصادر الحقيقة التي تم الرجوع إليها
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS.
- CURRENT_STATE.md.
- سلسلة التقارير 288 → 292.
- الملف التاريخي: `Architecture/الأذونات المخزنية اليدوية.md`.
- CURRENT SOURCE: `erp-frontend/.../warehouse/vouchers.html`.
- CURRENT SOURCE: `erp-frontend/.../sales/van-sales.html`.
- CURRENT PRODUCTION: PostgreSQL/RPCs/Edge Functions والبيانات التشغيلية.

التقارير السابقة استُخدمت لإعادة بناء السياق فقط، ولم تُعامل كمصدر للحالة الحالية.

## 3. CURRENT GIT
### System repository
- HEAD: `327deadd5d1824f6e0d564ffbe7ba622014ae215`
- Parent القريب الموثق في سجل الاستمرارية: `bc2d238b332016d89430a750b71f283e3246fd23`
- طبيعة آخر commits ضمن نطاق الحالة: توثيق/مزامنة حالة Production، وليس إعادة بناء واجهة الأذونات.

### Frontend repository
قبل إصلاح هذه الوحدة:
- آخر commit المرجعي: `16cb01c637857c7a4ed675ddb98cc05cc2b836fe`
- ذلك commit عدّل timestamp فقط في `vouchers.html`.
- Parent الموثق له: `f59bce9bac6b4d76fda2b16e6889f5d8b1e2466d`.

بعد الإصلاح:
- commit: `4f4afdc102fe6293d9755a134bc692d8f44bb43f`
- ثم إصلاح syntax جراحي في نفس الملف:
  `0115399c79d5a9fc5ef9c92450cc42381d560f22`
- Current blob:
  `1bf0382d45bcc06f524eefccc962abe6dcbbe4f3`

الـcommit `0115399...` أصلح escape فقط داخل handlers الجديدة؛ ليس تغييرًا وظيفيًا ثانيًا.

## 4. CURRENT PRODUCTION SNAPSHOT
Production أثبت في لحظة الفحص:
- companies = 1
- branches = 3
- vehicles = 1
- manual stock vouchers = 1
- stock_voucher_operations = 1
- inventory_log = 6
- audit_log = 2034

الهوية التشغيلية الحالية:
- Warehouse operator: `vouchers@rawaea.com`
- Direct-sales representative: `vansales@rawaea.com`
- Vehicle: `VEH-TEST-260921`
- Vehicle mobile branch: `VAN-VEH-TEST-260921`
- Vehicle driver = direct-sales representative
- `mobile_stock_enabled = true`

رصيد Production قبل اختبار الـE2E:
- BR-01 / item 1001 = 2
- Vehicle mobile branch / item 1001 = 0

ملاحظة حالة مهمة: التقارير السابقة كانت تصف `IN-1` كـDraft، لكن CURRENT PRODUCTION الآن يثبت أنه `Cancelled`. هذه الحالة الحالية هي المرجع ولا تم تغييرها بغرض التقرير.

## 5. CURRENT PRODUCTION CONTRACT
### Create
Production يحتوي على overloads موثقة لـ:
`create_manual_stock_voucher_atomic`
- 10 arguments
- 12 arguments، ويتضمن `p_rep_id` و`p_operation_id`

النسخة 12-argument:
- تتحقق من actor داخل الشركة.
- تتحقق من Direct Sales Rep داخل الشركة.
- تتحقق من role = `مندوب بيع مباشر`.
- تتحقق من permission = `van-sales`.
- تتحقق من branch scope.
- تمرر التنفيذ إلى `create_manual_stock_voucher_atomic_core_12_20260828`.

### Send
`send_stock_voucher_atomic` موجود كـSECURITY DEFINER ويستدعي:
`send_stock_voucher_atomic_core_20260828`

### Physical Stock
العقد الحالي مثبت:
`post_stock_movement` هو Physical Stock engine.
DirectSale يستخدم:
- source branch = Branch
- target branch = vehicle mobile branch
- Physical update + inventory_log من خلال الـcore.

لا توجد حاجة لإنشاء Edge Function جديدة لهذا الإصلاح.

## 6. التحقيق الجنائي في البلاغ الحالي
### العيب الأول — Upper panel UX
العيب لم يكن نقصًا في الـRPC أو الـbackend.
الحالة الحالية قبل الإصلاح كانت تبني Header مساحة العمل بحيث يظل:
- Branch/Rep/Vehicle route
- Reference/Notes
- Item search
- Categories

داخل الجزء العلوي الدائم من مساحة العمل.

النتيجة التشغيلية:
- مساحة الكتالوج تقل، خاصة على الشاشات الصغيرة.
- لا توجد آلية UX تحافظ على نفس البيانات مع إعطاء الكتالوج مساحة أكبر.
- لا توجد حالة collapse/expand مرتبطة بمساحة العمل نفسها.

### العيب الثاني — Quantity entry في Item Detail
الدالة الحالية `add:function(code)` كانت تقبل الكود فقط وتضيف `+1`.
كما أن `itemDetails` كانت تعرض زر إضافة فقط عندما لا يكون الصنف في السلة.

وبالتالي:
- لا يمكن إدخال 5/10/20 وحدات مباشرة من مودال الصنف.
- المستخدم مضطر لتكرار الضغط أو استخدام +/- بعد الإضافة.
- ذلك أقل إنتاجية من Van Sales الذي يتيح تعديل الكمية من سياق الصنف/السلة.

السبب الجذري إذن **Frontend UX capability gap**، وليس Physical Stock أو Database gap.

## 7. لماذا تم الحفاظ على البناء الحالي؟
الأذونات المخزنية اليدوية لها دور مستقل عن Orders/Runsheets:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

والتاريخ المعماري يثبت أن:
- الإنشاء = Draft.
- التنفيذ = Send/Receive حسب النوع.
- المخزون لا يُحدّث من الواجهة مباشرة.
- التنفيذ يمر بالمحرك المركزي.

لذلك لم نُدخل أي Writer جديد، ولم نربط الأذونات مباشرة بمنطق Van Sales أو Order/Runsheet.

## 8. تكامل Van Sales
Van Sales استُخدم كمرجع UX فقط:
- السلة تدعم quantity state.
- توجد +/−.
- توجد quantity controls داخل detail modal.
- عند التعديل تبقى السلة هي state الوحيدة للحقيقة.

تم نقل هذا المبدأ إلى Vouchers دون نسخ منطق Van Sales أو ربط التطبيقين ببعضهما runtime.

## 9. التعديل الجراحي المنفذ
### PATCH V-09 — Upper Panel Collapse
الملف:
`companies/company-1/warehouse/vouchers.html`

العنصر:
`renderWorkspace:function()`

إضافة:
- `id="wsTopToggle"`
- `id="wsTopPanel"`
- `App.toggleTopPanel()`
- `aria-expanded`
- حالات نصية:
  - `توسيع الخيارات`
  - `طي الخيارات`

الجزء العلوي أصبح قابلًا للطي دون حذف route/reference/search/category state.

### PATCH V-10 — Quantity Selection
العنصر:
`itemDetails:function(id)`

أضيف:
- quantity input.
- + / − للكمية قبل الإضافة.
- عرض المتاح.
- عرض الكمية الموجودة في السلة.
- تعديل الكمية من داخل المودال إذا كان الصنف موجودًا في السلة.

الدوال الجديدة:
- `setDetailDraftQty`
- `adjustDetailDraftQty`
- `addFromDetail`
- `changeDetailCartQty`

### PATCH V-11 — Quantity-aware cart add
العنصر:
`add:function(code,requestedQty)`

بدل `+1` الثابت:
- يقبل `requestedQty`.
- يتحقق من أنها رقم صالح وأكبر من صفر.
- يحافظ على حدود `avail()`.
- يحافظ على الاستثناءات الموجودة لـDirectReturn وAdjustment.
- إذا كان الصنف موجودًا يضيف الكمية إلى state الحالية.
- يعيد boolean لتمكين caller من معرفة نجاح الإضافة.

### PATCH V-12 — Workspace initial state
العنصر:
`newWorkspace:function()`

إضافة:
`this.topPanelCollapsed=false`
حتى يبدأ كل إذن جديد مفتوحًا بشكل واضح.

### PATCH V-13 — Styling
أضيفت classes:
- `ws-top-panel`
- `ws-top-collapsed`

مع transition وpointer-events guard.

## 10. ما لم يتم تعديله
- `main.html`: لم يُلمس.
- `van-sales.html`: لم يُلمس.
- V-03/V-04 smart vehicle search: لم يُعدّل.
- V-05 rep-first search: لم يُعدّل.
- V-06 branch/rep retention: لم يُعدّل.
- V-07 Escape handling: لم يُعدّل.
- V-08 Service Worker: لم يُعدّل.
- RPCs الحالية: لم يُعدّل Business Contract الخاص بها.
- Physical Stock engine: لم يُعدّل.

## 11. Source Verification
Current `vouchers.html`:
- lines = 1826
- chars ≈ 92.5K
- JavaScript complete-file syntax parse = PASS

مواضع العناصر بعد الإصلاح:
- `newWorkspace` ≈ line 795
- `toggleTopPanel` ≈ line 100 داخل App object
- `renderWorkspace` ≈ line 1150
- `add(code,requestedQty)` ≈ line 1189
- `itemDetails` ≈ line 1333
- `setDetailDraftQty` ≈ line 1350
- `adjustDetailDraftQty` ≈ line 1357
- `addFromDetail` ≈ line 1358
- `changeDetailCartQty` ≈ line 1359
- `handleKeys` ≈ line 1751 — existing closure retained

نتيجة الـstatic gate:
`PASS`

## 12. Production E2E
تم اختبار العقد الفعلي في Transaction مؤقتة ثم `ROLLBACK`:
1. CREATE DirectSale عبر 12-argument canonical RPC.
2. SEND عبر canonical `send_stock_voucher_atomic`.
3. النتيجة:
   - status = Sent
   - movement_count = 1
   - inventory_log = 1
   - stock_voucher_operations = 1
   - BR-01 item 1001: 2 → 1
   - VAN mobile branch item 1001: 0 → 1
4. ثم تم `ROLLBACK`.

إذن الاختبار لم يلوث Production ولم يترك Voucher إضافيًا.

## 13. Gateway / Edge Capacity
لم تُنشأ Edge Function جديدة.
التطبيق يستمر باستخدام:
- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher

والمسار الحالي يعمل من خلال RPCs المعتمدة.

## 14. مقارنة تنافسية
### Odoo
Odoo 19 يتيح في Barcode:
- تعديل الكمية يدويًا.
- +1 / -1.
- إدخال كمية مباشرة.
- مراجعة ثم Confirm.
كما يدعم عمليات الجرد من خلال تعيين مهام وعدّ المنتجات.  
المصدر الرسمي:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

### Dynamics 365
Inventory Journals تدعم:
- Movement
- Inventory Adjustment
- Transfer
- Counting
- Item Arrival
مع Posting ومتابعة Inventory Transactions.  
المصدر الرسمي:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals

### SAP
SAP يربط Goods Movement بمستند مادي يسجل حركة المخزون، ويدعم Goods Receipt / Goods Issue / Stock Transfer / Transfer Posting.  
المصدر الرسمي:
https://help.sap.com/docs/SAP_S4HANA_CLOUD/32da8359c8ee4e8b6c8e8c8e8c8e5p15cac5aa/4fdef17912454fe595400e1c00df32ca.html
كما يدعم إنشاء Material Document بحقل كمية وسياق حركة.  
المصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/eb2a39dd0c124fed8252f684002d55e1/8bb0d08295044ee3af444b4f2a6e4457.html

### Daftra
Daftra يركز على:
- detailed inventory movements
- warehouse filtering
- transaction types
- notes/reference
- stocktaking sessions
- actual quantity مقابل النظام.

المصادر الرسمية:
https://docs.daftra.com/en/tutorial/inventory-detailed-transactions-report/
https://docs.daftra.com/en/user_manual/how-to-perform-inventory-stocktaking-of-tracked-products/

### Manager.io
Manager يدعم:
- Inventory Transfers
- Inventory Adjustments
- quantity per line
- From/To locations
- stock quantity by location.

المصادر الرسمية:
https://www2.manager.io/guides/10707
https://www2.manager.io/guides

## 15. فجوات تنافسية حقيقية — لم تُضم إلى هذه PATCH
هذه ليست أسباب البلاغ الحالي، ولذلك لم تُدخل في الإصلاح:
- batch/lot/expiry tracking.
- serial tracking.
- explicit inventory location/bin layer.
- richer approval workflow.
- print/export templates.
- advanced stocktaking assignment.
- richer reason codes.

إضافتها الآن كانت ستفتح Business Contract جديدًا وتخلط Closure Units.

## 16. سبب الخطأ النهائي
**السبب النهائي المثبت في هذه الجولة:**
لم يكن التطبيق ناقصًا في المخزون أو الـRPC.
كان ناقصًا في طبقة UX الخاصة بـWorkspace:
1. Header قابل للعرض فقط بلا collapse state.
2. Item detail إضافة كمية ثابتة = 1.
3. لا توجد quantity input مباشرة قبل الإضافة.

ولهذا كان التطبيق يعمل وظيفيًا لكن إنتاجيته أقل من المستوى المطلوب.

## 17. Self Audit
### What I Proved
- Current source محدد وثابت.
- Current Production identities مثبتة.
- Current RPC/Edge path موجود.
- Physical Stock core بقي مركزيًا.
- Complete-file syntax = PASS.
- CREATE/SEND Production E2E = PASS داخل Transaction ثم ROLLBACK.
- التعديل محصور في vouchers.html.

### What I Did Not Prove
- Real authenticated browser click-through لم يُنفذ في هذه البيئة.
- لم أعتبر ذلك PASS من باب عدم اختلاق دليل.
- نشر CDN/Cloudflare بعد Git commit لم يُعتبر PASS لأن GitHub Actions لم تُرجع workflow run مرتبطًا بالـcommit.

### What I Fixed
- Upper panel collapse/expand.
- Quantity selection in item detail.
- Quantity-aware add to cart.
- Preserved existing contracts.

### What I Initially Missed
- الـembedded handler escaping في أول كتابة؛ تم اكتشافه بالـsyntax gate وإصلاحه مباشرة في commit لاحق.

### What Could Still Be Wrong
- Browser-only CSS/layout issue.
- runtime behavior الخاص بـmodal/keyboard focus على أجهزة محددة.

## 18. Final Closure
- VOUCHERS TOP PANEL COLLAPSE = SOURCE CLOSED
- VOUCHERS ITEM QUANTITY SELECTION = SOURCE CLOSED
- VOUCHERS CART QUANTITY INTEGRATION = SOURCE CLOSED
- PRODUCTION CREATE/SEND CONTRACT = PRODUCTION VERIFIED
- PHYSICAL STOCK CENTRALIZATION = NOT REOPENED
- PREVIOUS SMART SEARCH CLOSURES = PRESERVED
- BROWSER E2E = OPEN / NOT CLAIMED

## 19. تعليمات الاستمرارية للمساعد التالي
ابدأ من:
1. CURRENT GIT الحالي.
2. CURRENT vouchers blob الحالي: `1bf0382d45bcc06f524eefccc962abe6dcbbe4f3`.
3. CURRENT PRODUCTION snapshot جديد، وليس من أرقام هذا التقرير.
4. لا تُعد V-03 إلى V-08.
5. لا تعدّل main.html.
6. لا تعدّل van-sales.html إلا إذا فتح Closure منفصل بدليل جديد.
7. إذا توفر Browser execution، اختبر:
   - فتح New Voucher.
   - DirectSale route.
   - Collapse/Expand.
   - فتح Item Detail.
   - إدخال كمية 5.
   - Add to cart.
   - تحقق cart = 5.
   - decrement/increment من المودال.
   - submit draft عبر current canonical Edge/RPC.
8. بعد Browser E2E خذ Production snapshot جديدًا في نفس لحظة الإغلاق.

## END OF REPORT 293
