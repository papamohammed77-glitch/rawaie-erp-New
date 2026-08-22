# RAWAEA ERP — PWA LIFECYCLE / FUNCTIONAL KNOWLEDGE MAP
## خالد — 2026-08-22

### Scope
This is a source-derived knowledge map of `Current/PWA` and its relationship to the ERP runtime. It does not modify application code. Production remains runtime truth; Git is the canonical source record; historical material is navigation evidence only.

## 1. Runtime Topology

```text
RAWAEA ERP
│
├── ERP Core / System Data
│   ├── Supabase PostgreSQL
│   ├── Edge Functions
│   ├── SECURITY DEFINER business RPCs
│   └── Auth / tenant / RLS / audit
│
├── System Mother / Main PWA
│   └── Current/PWA/main.html
│
├── Entry / Routing Layer
│   └── Current/PWA/app.html
│
├── Shared PWA Runtime
│   ├── core.js
│   ├── manifest.json
│   ├── sw.js
│   ├── register-sw.js
│   └── schema-validator.js
│
├── Sales / Order Capture
│   ├── pos.html
│   ├── van-sales.html
│   ├── order-taker.html
│   └── telesales.html
│
├── Warehouse Execution
│   ├── picker.html
│   ├── loader.html
│   ├── unloader.html
│   ├── receiver.html
│   ├── Returns.html
│   ├── vouchers.html
│   └── counter.html
│
├── Delivery / Vehicle
│   └── driver.html
│
├── Purchasing
│   └── buyer.html
│
├── Finance / Accounting
│   ├── accountant.html
│   └── finance-manager.html
│
├── Management / Governance
│   ├── owner.html
│   ├── general-manager.html
│   ├── warehouse.manager.html
│   ├── sales.manager.html
│   ├── buyers.supervisor.html
│   ├── sales.supervisor.html
│   ├── warehouse.supervisor
│   ├── driver.supervisor.html
│   └── hr.html
│
└── External Customer Store
    ├── store.index.html
    └── store.track.html
```

## 2. System Mother — `main.html`

`main.html` is the largest current PWA artifact (692,870 bytes in Git) and is explicitly branded `الروائع ERP | نظام متكامل`. It implements the ERP shell: login, fixed sidebar, header, application views, search, notifications/profile, and navigation into functional domains. It is materially different from the role-specific PWAs: it is the central ERP workspace rather than one operational capability. Git current SHA: `c979db75df1de4d08e5d2eed49d80fa9a09a3f62`.

The source carries a current build date comment `2026-08-22 04:00 UTC`, showing that it is an actively moving artifact rather than a frozen historical PWA.

## 3. Entry / Redirect App — `app.html`

`app.html` is not the ERP mother UI. It is a compact authentication/entry surface branded `الروائع ERP`, then redirects authenticated users toward `/companies/company-1/...`. It reads `app_settings` for company branding and `users.active_warehouse_role`, and routes according to owner/permissions/warehouse role. It explicitly offers a link to `main.html` as the system-mother entry. Git SHA: `b5861b087bbe4315852d8bbf03c0c377a12b5402`.

This distinction matters: `app.html` is an entry/routing layer; `main.html` is the central ERP workspace.

## 4. Shared Runtime Layer

- `core.js` is shared by many current PWAs and provides common auth/UI/DB behavior. Git SHA: `b3da51ee5a577e1aef346beb0ed4a866df7d563c`.
- `sw.js` and `register-sw.js` provide PWA/service-worker behavior.
- `manifest.json` is the PWA manifest.
- `schema-validator.js` is a shared validation utility.
- `vouchers-gold-master-ui.js` is a dedicated UI helper attached to the Voucher Gold Master path, not a standalone business application.

Therefore the PWA layer has a shared runtime foundation but not a single shared business-domain implementation: business capabilities remain distributed across the functional PWAs and backend contracts.

## 5. Sales / Order Lifecycle

### `pos.html` — POS

Direct operational sales terminal. Source UI includes:
- product search / barcode scanner
- branch selection
- customer selection
- fast-selling products
- categories
- smart suggestions
- cart
- hold / resume / clear invoice
- payment action
- connectivity/sync state

It is a transactional consumer and participates in the Sales → Inventory → Accounting chain. Git SHA: `6ad4da791b72260b922847246ebce93b552d2bad`.

### `van-sales.html` — Direct / Van Sales

Source title: `فان سيلز | الروائع ERP` / `مندوب البيع المباشر`.
It maintains vehicle/VAN context, cart, customer selection, map/account/vehicle views, offline/local data through Dexie, synchronization, and order submission. It explicitly reads `stock_branches`, `branches`, `items`, customers and settings before loading the vehicle context.

The operational role is not simply another POS: it is the mobile vehicle-sales consumer and therefore depends on custody state, VAN branch inventory, order identity, and the save-sales flow. Current SHA: `fe5fa249df732a89bdc3887c4d354952f96180ed`.

### `order-taker.html` — Sales Representative / Order Taker

Source title: `مندوب المبيعات`. Navigation exposes `اليوم`, `المنتجات`, `السلة`, `أوردراتي`, plus customer and map/account controls. It is an order-capture consumer rather than an inventory-posting worker. Current SHA: `6fa258e51284bfc8c35fd66fb709d904024f989f`.

### `telesales.html` — Telesales

Source title: `التلي سيلز`. Navigation exposes `اليوم`, `المنتجات`, `السلة`, `أوردراتي`, with customer/sync controls. It is a remote order-capture consumer and therefore belongs to Order → Fulfillment, not warehouse execution. Current SHA: `d839ff043631d365be8eb2832ee98aa4fabcb43c`.

## 6. Warehouse Lifecycle

### `picker.html` — Picking

Source role: `المحضّر`.
Tabs: `قيد التحضير`, `مكتملة`, `حسابي`.
The source requires warehouse access and uses `activeWarehouseRole`; it retrieves `users.id/name/company_id/active_warehouse_role` by `auth_id`. It is the reservation/picking worker. It is not the physical stock movement writer. Current SHA: `f169247f7e6389eb826bb214e2cba2f034de3300`.

### `loader.html` — Loading

Source role: `المحمّل`.
Tabs: `قيد التحميل`, `مكتملة`, `حسابي`.
Access is role-bound to active warehouse role `تحميل`. It operates on runsheets with `Loading` / `Picked` state and is the warehouse Loading consumer. Current SHA: `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`.

### `unloader.html` — Unloading

Source role: `مسؤول التفريغ`.
Tabs: `قيد التفريغ`, `مكتملة`, `حسابي`.
It reads runsheets in `Loaded` / `Delivering` states and operates the unloading side of the vehicle custody lifecycle. Current SHA: `11e80107b7b8ea4ba76e686f1b0f82235b57a303`.

### `receiver.html` — Purchase Receiving

Source role: `مسؤول الاستلام`.
Tabs: `قيد الاستلام`, `مكتملة`, `حسابي`.
Access is tied to active warehouse role `استلام`. It loads purchase orders and is therefore the receiving consumer that bridges Purchasing → Warehouse → Inventory → Accounting. Current SHA: `fedab298e5217c82bc07b2a3972e63038ce288d2`.

### `Returns.html` — Returns

Source title: `نظام إدارة المرتجعات`.
Tabs: `قيد المرتجعات`, `مكتملة`, `حسابي`.
Access is role-bound to `مرتجعات`. It explicitly loads items and active return reasons, and the source includes return classification/state handling. This is the operational return consumer, distinct from generic vouchers. Current SHA: `36c20e03c94dc734e015610dec1e8208697df32a`.

### `vouchers.html` — Stock Voucher / Inventory Movement Workspace

This is the Gold Master inventory-voucher application. Build marker: `RAWAEA-VOUCHERS-GOLD-MASTER-2026-08-21-VRS-SURGICAL-R1`.

The source exposes explicit business operation choices:
- Transfer — branch → branch
- DirectSale — branch → vehicle
- DirectReturn — vehicle → branch
- SupplierReturn — branch → supplier
- Scrap — Adjustment Engine
- Adjustment — Adjustment Engine

Tabs: `معلقة`, `مكتملة`, `حسابي`.
The workspace is POS-like with catalog/search/cart behavior, but its role is inventory-document orchestration, not direct stock mutation. Current SHA: `2434b44d520a9a62b90e1735353343a6ad02ca72`.

### `counter.html` — Smart Inventory Count

Source title: `الجرد الذكي`.
Tabs: `جرد جديد`, `جردات سابقة`, `حسابي`.
Supports branch/vehicle/general count types, barcode scanning, item search and count submission. It is an inventory-adjustment/counting consumer and must therefore remain inside the Inventory regression boundary. Current SHA: `938d9b1959705fb2b73cd12fa7b5d9415860b808`.

## 7. Delivery / Vehicle Lifecycle

### `driver.html` — Delivery Representative

Source title: `مندوب التوصيل`.
Tabs: `الرئيسية`, `الأوردرات`, `الخريطة`, `السيارة`, `رصيدي`, `حسابي`.
It handles runsheet/customer delivery work, map state, vehicle/stock visibility and driver balance. The source currently contains a user-provisioning fallback path with a hard-coded company identifier; this is recorded as a security/tenant boundary requiring direct Production lineage verification before any correction.

Current SHA: `2df69860184f5a7c1b211ba059e1d6f57826c96b`.

## 8. Purchasing

### `buyer.html` — Buyer

Tabs: `أوامر الشراء`, `أمر جديد`, `الموردين`.
It reads purchase orders and suppliers, builds new POs from selected items, and submits through the `save-purchase-order` Edge Function. Current SHA: `27fe0812faebc218ddfd8454b41e55ef858a0043`.

### `buyers.supervisor.html`

Supervisor-level purchasing surface. Its exact current business tabs/consumer dependencies require direct function-level closure before treating it as a transactional authority; the filename and role are present in the current PWA set, but no business-contract claim is made from the name alone.

## 9. Finance / Accounting

### `accountant.html` — Accountant

Tabs: `KPI`, `سندات قبض`, `سندات صرف`, `قيود`.
The current source directly calls:
- `save-receipt-voucher`
- `save-payment-voucher`

This is the confirmed current Consumer for those financial Edge Functions. The current PWA request shape does not match the deployed `save-receipt-voucher` contract exactly, making this a genuine Consumer Contract Gate.

Current SHA: `a0469e81cded644fafada4df24e5628111357e74`.

### `finance-manager.html` — Finance Manager

Tabs: `KPI`, `التقارير`.
The current source reads orders, purchases and treasury for management KPIs and explicitly states that advanced reports are managed by the mother system. It is therefore primarily a read/report consumer, not the direct voucher writer. Current SHA: `f4f4fa63692c614cc4719cf9d0e335ea0d2ccb6d`.

## 10. Management / Governance

### `owner.html`

Tabs: `لوحة التحكم`, `التقارير`, `الإعدادات`, `التدقيق`.
Owner-only access. This is the highest-level governance/oversight surface among the role PWAs. Current SHA: `d22067a5d83a214364ffde6096ca74f5cf17cec5`.

### `general-manager.html`

Owner-style executive dashboard; current source is owner-only and reads sales, purchases, treasury, customer debt and employee counts. It intentionally delegates advanced reports to the mother system. Current SHA: `3e1d8d2fd6b16707c11e32739ef2b2e24bb19e6c`.

### `warehouse.manager.html`

Tabs: `لوحة التحكم`, `الفريق`, `التقارير`.
Reads stock, low-stock items, active runsheets and recent vouchers; loads warehouse staff. It is a management/read-side surface over Warehouse operations, not the executor of Picking/Loading/Unloading. Current SHA: `f3fe6fa42e51be6c659b062eed7e6762251add32`.

### `sales.manager.html`

Tabs: `KPI`, `الأهداف`, `التقارير`.
Reads order performance, growth, geography and sales-rep counts. Current SHA: `60c6281d2a07e59d82391c225c701fc2cbb6fdff`.

### `sales.supervisor.html`

Sales-supervisor management surface. Treat as supervisory/read-side until its exact write consumers are proven; no transactional authority is inferred from the filename.

### `warehouse.supervisor`

Warehouse-supervisor surface. It must be treated as a supervisory control surface over warehouse workers unless direct write consumers are proven.

### `driver.supervisor.html`

Supervisor surface for delivery/driver operations. Exact write authority remains a Consumer Matrix item rather than a filename-based assumption.

### `hr.html`

Tabs: `الموظفين`, `الحضور`, `الرواتب`.
The source explicitly implements employee listing and states Attendance and Salary are `قيد التطوير`. Current SHA: `b18f71bfeef24581576375f73544a0b10b928db7`.

## 11. External Store

### `store.index.html`

Public storefront. It loads `app_settings` for store branding, delivery fee, tax, minimum invoice amount, syncs product catalog, supports categories, search, daily deals, cart, coupon, customer data and checkout. It is a customer-facing sales/order channel, not a back-office PWA. Current SHA: `2d227aa2bbd44df38071313c0fb848127678f72`.

### `store.track.html`

Public order-tracking surface. It is part of the Store lifecycle and should be treated as a read-side customer channel until its backend lookup contract is separately verified.

## 12. Lifecycle Model Across PWAs

```text
CUSTOMER / SALES CHANNELS
    store.index / POS / Order Taker / Telesales / Van Sales
                    │
                    ▼
                 Orders
                    │
                    ▼
             Runsheet / Fulfillment
                    │
        ┌───────────┼──────────────┐
        ▼           ▼              ▼
      Picking     Loading        Delivery
      reserve      MAIN→VAN      Driver
        │           │              │
        └───────────┼──────────────┘
                    ▼
            Return / Unloading
                    │
                    ▼
             Inventory Core
          post_stock_movement
                    │
                    ├─────────────► Accounting
                    │
                    └─────────────► Audit / Registry

PURCHASING
buyer → purchase_order → receiver → receive_purchase_atomic → inventory + accounting

FINANCE
accountant → receipt/payment consumers → financial core (current convergence not yet closed)

MANAGEMENT
owner / GM / managers / supervisors = oversight/read/control surfaces over the operational graph
```

## 13. Current Position Against Inventory Rescue

### CLOSED / VERIFIED FOUNDATION
- Physical inventory mutation boundary is centralized in Production around `post_stock_movement(10)`, with reservation separated from movement.
- Picking is a reservation/fulfillment activity, not a physical stock writer.
- Loading/Unloading are custody movements around the central inventory engine.
- Voucher operation types are explicit in the Gold Master UI.
- Current PWA inventory consumers are now identifiable as separate capabilities.

### REGRESSION FOUNDATION, NOT CURRENT PRIMARY WORK
- `main.html`
- `pos.html`
- `van-sales.html`
- `order-taker.html`
- `telesales.html`
- `picker.html`
- `loader.html`
- `unloader.html`
- `receiver.html`
- `Returns.html`
- `counter.html`
- `vouchers.html`

These applications remain part of the Inventory regression graph even while the project moves into Accounting/Ledger/Treasury.

## 14. Current ERP-Wide Closure Position

### Next critical domains
1. Accounting Contract
2. Ledger Contract
3. Treasury ↔ COA identity
4. Financial Security
5. Consumer Matrix
6. Deployment Lineage
7. Concurrency
8. Data Reconciliation
9. Global Zero-Debt

### Important current consumer gate
`accountant.html` is confirmed as a direct consumer of `save-receipt-voucher` and `save-payment-voucher`. Its request envelope must be reconciled with the deployed Production Edge contract before any surgical PWA change is accepted.

### No-change rule
No PWA change is authorized by this document. Any future change must follow:

`PRODUCTION EVIDENCE → CURRENT PWA SOURCE → HISTORICAL CONTRACT → EXACT TARGET FUNCTION → SURGICAL REPLACEMENT → TEST → PRODUCTION DEPLOY → RUNTIME VERIFY → CLOSE`

## 15. Knowledge Confidence

- System Mother topology: HIGH
- PWA inventory/journey map: HIGH for named artifacts and role boundaries
- Critical operational PWA contracts: HIGH where code and Production lineage were directly checked
- Every non-critical supervisory write path: PARTIAL until Consumer Matrix evidence is attached
- Store tracking exact backend contract: PARTIAL
- Global PWA→Edge→RPC→DB deployment lineage: OPEN
- Full browser runtime parity: OPEN

No business contract is inferred from a filename when source evidence was not available.
