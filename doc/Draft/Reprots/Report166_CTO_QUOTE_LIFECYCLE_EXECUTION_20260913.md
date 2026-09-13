# Report166 — تنفيذ وإغلاق Quote Lifecycle

## الحوكمة
التقارير السابقة STALE/Reference فقط. الحالة المعتمدة: `CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.

## هدف هذه الجلسة
كان `Quote lifecycle = OPEN`. تم تنفيذ البنية التشغيلية في Production، وليس واجهة شكلية.

## Current Git
مستودع النظام الأم: `papamohammed77-glitch/erp-frontend`
HEAD الحالي المتحقق: `d0cfb6fefd1af960de336935d8eec6d831c2d101`
Parent: `aaebffbdd732b9861d96631f5d01c5a6697bd1e4`
Parent of Parent: `3573c92026557cb56a7782babe6f6cf690243072`
Current main.html blob: `4cc90ea87697b0e01a21900da289f3e86e1fefcb`

## Source of Truth
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
لم يتم تعديل هذا الملف من جانب المساعد؛ تعديله owner-side فقط.

## Production — الجداول
تم إنشاء:
- `sales_quotes`
- `sales_quote_details`
- `sales_quote_status_history`

العلاقات تغطي Company / Customer / Branch / Sales Rep / Items / Converted Order / Status History.
تم تفعيل RLS وFORCE RLS، وإضافة قيود وفهارس uniqueness وintegrity.

## Production — RPCs
- `rawaea_quote_actor_ok`
- `create_sales_quote_atomic`
- `update_sales_quote_atomic`
- `change_sales_quote_status_atomic`
- `expire_due_sales_quotes_atomic`
- `convert_sales_quote_to_order_atomic`
- `list_sales_quotes`
- `get_sales_quote_detail`
- `get_sales_quote_summary`

كل RPC تشغيلي: SECURITY DEFINER، search_path=public، التنفيذ من PUBLIC/anon/authenticated مسحوب، والتنفيذ التشغيلي عبر service_role فقط.

## Lifecycle
```text
Draft -> Sent -> Accepted -> Converted -> Confirmed Order
             |       |
             |       +-> Rejected
             +-------> Expired / Cancelled
Draft ----------------> Cancelled
```

لا يوجد Physical Stock Movement في Quote. لا حجز ولا خصم مخزون عند إنشاء Quote أو تحويله إلى Order.

## Idempotency
Create يعتمد على `operation_id + fingerprint`.
Convert يعتمد على `operation_id` ويعيد duplicate عند retry.

## Edge
تم نشر `sales-quotes`:
- ACTIVE
- Version `2`
- `verify_jwt=true`
- capabilities: `catalog / list / summary / detail / create / update / send / accept / reject / cancel / expire_due / convert`

Canonical source:
`Current/Edge_Functions/sales-quotes/index.ts`

## اختبارات Production
### Full transactional E2E
`CREATE -> SEND -> ACCEPT -> CONVERT -> CONVERT(RETRY)`
النتيجة:
- Quote = `Converted`
- Total = `90`
- Order = `Confirmed`
- source = `quote`
- inventory log rows = `0`
- ثم ROLLBACK كامل.

### Create idempotency
إعادة نفس operation_id أعادت `duplicate=true`، ثم ROLLBACK.

### Authorization
مستخدم بلا صلاحية Orders تم رفضه: `unauthorized_rejected`.

### Expiry
Quote منتهي تم تحويل حالته إلى `Expired` داخل Transaction، ثم ROLLBACK.

### Production persistence
بعد الاختبارات:
- `sales_quotes = 0`
- `sales_quote_details = 0`
- `sales_quote_status_history = 0`

## Inventory safety
تم فحص `convert_sales_quote_to_order_atomic` مباشرة:
لا استدعاء `post_stock_movement`، ولا كتابة `stock_branches`، ولا كتابة `inventory_log`.

العقد المخزني لم يتغير:
`Physical Movement -> post_stock_movement -> stock_branches + inventory_log`

## أخطاء تم اكتشافها وإغلاقها
- تعارض أولي في أسماء متغيرات PL/pgSQL، وتم إصلاحه قبل اعتماد المسار.
- تم منع retry غير الآمن عبر operation identity/fingerprint.
- أضيفت ثلاثة أعمدة تصميمية غير مستخدمة ثم حُذفت قبل الإغلاق النهائي لمنع Schema Debt: `customer_reference`, `payment_terms`, `price_locked`.

## Owner-side UI — المطلوب في main.html
التبويب غير موجود حاليًا في Source of Truth، ولذلك لم يُعدل من جانب المساعد.

### 1 — Navigation — السطر 1142 الحالي
احذف السطر الكامل:
```text
    { icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },
```
واستبدله بالسطر الكامل:
```text
    { icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },
```

### 2 — permissionMap — السطر 17082
ابحث عن:
```text
            'orders': 'orders',
```
وأضف تحته:
```text
            'quotes': 'orders',
```

### 3 — titles — السطر 17141
ابحث عن:
```text
            'orders':'أوردرات المبيعات',
```
وأضف تحته:
```text
            'quotes':'عروض الأسعار',
```

### 4 — route — السطر 17188
ابحث عن:
```text
        if (view === 'orders') { RW_Orders.render(); return; }
```
وأضف تحته:
```text
        if (view === 'quotes') { RW_SalesQuotes.render(); return; }
```

### 5 — module — السطر 17929
ابحث عن المقطع الكامل:
```text
// ============================================================
// EVENTS & BOOT
// ============================================================
function bindEvents() {
```
أضف فوقه الموديول الكامل الموجود في:
`Current/PWA/owner-patches/RW_SalesQuotes.js`

الموديول تم التحقق من تركيبه بواسطة `node --check` قبل تسجيله.

## Assembly
`forensic_main_assembly.yml` ما زال يشير إلى:
`erp-frontend/companies/company-1/main.html`
ولم تتم إعادته إلى `Current/PWA/main2`.

## الحالة النهائية
```text
Quote DB infrastructure       = CLOSED
Quote lifecycle RPC           = CLOSED
Quote idempotency             = CLOSED
Quote security                = CLOSED
Quote Edge                    = DEPLOYED + VERIFIED
Quote inventory safety        = VERIFIED
Quote transactional E2E       = VERIFIED
Quote owner UI                = OWNER MERGE REQUIRED
Browser click-by-click E2E    = OPEN / NOT VERIFIED
```

## SELF-AUDIT
### ما تم إثباته
البنية، العلاقات، الـRPCs، الأمن، idempotency، lifecycle، التحويل إلى Confirmed Order، وعدم وجود حركة مخزنية، واختبارات transactional.

### ما لم يتم إثباته
Browser click-by-click E2E بعد دمج owner-side.

### قاعدة المساعد القادم
لا تبدأ من تقرير. ابدأ من:
`CURRENT FRONTEND HEAD -> PARENT -> CURRENT SOURCE -> CURRENT DATABASE -> CURRENT DEPLOYMENTS -> CURRENT RUNTIME`
ثم طبّق:
`Historical Contract -> Current Behavior -> Target Contract -> Actual Gap -> Surgical Change -> Test -> Deploy -> Production Verify -> Runtime Verify -> Document -> Close`

لا تعيد Quote من الصفر، ولا تعيد فتح Closure مغلقة بدون دليل CURRENT جديد يناقضها.
