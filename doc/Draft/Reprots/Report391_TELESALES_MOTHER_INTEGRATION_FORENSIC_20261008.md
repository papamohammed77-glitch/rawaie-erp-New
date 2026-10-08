# Report391 — Telesales / Mother-System Integration Forensic Closure
## Date
2026-10-08

## SELF-AUDIT
- Mission scope: integration between Mother System authority and standalone Telesales application.
- Mother source inspected: `papamohammed77-glitch/erp-frontend` / `companies/company-1/main.html` (current blob recorded in Report390).
- Telesales source inspected: `companies/company-1/sales/telesales.html`.
- Shared runtime inspected: `companies/company-1/core.js`.
- Current Production database inspected directly.
- Current Production Edge Functions inspected directly.
- Current RLS policies inspected directly.
- Historical governance/checkpoint inspected: Report390 + CURRENT_STATE.
- No `main.html` or `telesales.html` source file was modified by this cycle.

## 1. CURRENT PRODUCTION SNAPSHOT

Project: `fiilmooggumokxanwiyx` / SMART ERP.

Verified users:
- `owner@alrawae.com`: DB permissions=["*"], Active.
- `telesales@rawaea.com`: permissions=["telesales"], Active, allowed branch=`BR-01`.
- `order-taker@rawaea.com`: permissions=["orders"], Active, allowed branch=`BR-01`.

Existing Edge count remains 100 before/after this work. No new function was created.

### Production changes executed

#### save-sales-invoice
- v15 → v16.
- verify_jwt remains true.
- DB user identity is read through `auth_id`.
- DB permissions now gate the operation.
- Allowed sales-entry permissions: `*`, `telesales`, `orders`, `van-sales`, `pos`.
- Telesales/order-taker cannot submit an `Invoiced` stock-moving operation.
- Source is canonicalized from the caller's DB permission when the caller is not owner.
- Branch access is checked against the user's `allowed_branch_ids` / `default_branch_id`.
- Existing `save_sales_invoice_atomic` remains the central transaction engine.
- Deployment SHA: `fef1f4111c6ad06c0a38eed6621b3d5d5e066352c46e0f2209099ebd811eaba2`.

#### delete-order
- v9 → v10.
- verify_jwt remains true.
- DB permissions are now checked before invoking the privileged RPC.
- Telesales/order-taker can delete only their own non-invoiced, non-runsheet orders.
- General/sales managers and owner remain privileged according to the existing RPC contract.
- Deployment SHA: `e219c09f35c96e33800c36866ed48e7b65234164117df58985db151c96728eb6`.

## 2. ROOT CAUSE FINDINGS

### F1 — RLS prevented Telesales from reading the data it needs
Before this repair, Production had no SELECT policy for `telesales` / `orders` on:
- `customers`
- `items`
- `stock_branches`
- `orders`
- `order_details`

The application source performs direct reads of all five objects. This was a real integration defect.

### F2 — Branch selection was also blocked
There was no Telesales/Order-Taker branch SELECT policy. The app requires branch selection before adding products.

### F3 — save-sales-invoice trusted the authenticated identity but did not authorize the application capability
The v15 Edge Function authenticated the JWT but did not verify DB sales permission before invoking the service-role RPC.

Because the RPC is service-role-only, browser RLS cannot compensate for this. The authorization had to be enforced in the Edge Function.

### F4 — Telesales source identity was missing
The current Telesales frontend sends `status: Confirmed` but does not send `source: telesales`.
The existing RPC therefore fell back to its generic branch-based source rule.

Production v16 now canonicalizes source from DB permission for non-owner callers.

### F5 — delete-order was over-privileged at the Edge boundary
The old Edge Function accepted any active authenticated user and passed the requested order code to the service-role RPC.
For non-invoiced orders, the RPC did not enforce ownership.
Production v10 now enforces ownership for ordinary Telesales/Order-Taker users.

### F6 — frontend authorization in Telesales relies on shared core metadata
Current `core.js` hydrates `permissions` and `isOwner` from `user_metadata`.
That is not the canonical DB authorization source.

This is NOT repaired by changing the DB metadata. The correct repair is a surgical Telesales auth hydration patch and, separately, the already documented Mother `RW_Auth.login()` patch from Report390.

## 3. RLS CHANGES

Created SELECT policies:
- `branches_select_sales_entry`
- `customers_select_sales_entry`
- `items_select_sales_entry`
- `stock_branches_select_sales_entry`
- `orders_select_sales_entry_own`
- `order_details_select_sales_entry_own`

The policies:
- require authenticated access;
- use current DB company context;
- require `telesales` or `orders`;
- limit branch/stock access to assigned/default branches;
- limit order history/details to orders created by the current user.

## 4. PRODUCTION RLS VERIFICATION

Using an authenticated-role simulation with the real Telesales auth identity:
- branches visible: 1
- branch codes: BR-01
- customers visible: 3
- items visible: 17
- stock rows visible: 17
- own orders visible: 0
- own order details visible: 0

The same branch/customer/item/stock visibility was verified for the real Order-Taker auth identity.

No production data was inserted, edited, deleted, or left as test residue.

## 5. BUSINESS CONTRACT

Telesales:
`Customer → Product → Branch → Confirmed Order → Runsheet later → Picking → Loading → Delivery`

At Telesales order creation:
- no physical stock movement;
- no invoice stock deduction;
- order remains eligible for downstream Runsheet workflow;
- source is `telesales`;
- order ownership remains with the authenticated user.

Order-Taker follows the same non-invoiced order principle with source `order-taker`.

Van Sales remains distinct:
- source `van-sales`;
- its own mobile branch architecture;
- existing `post_stock_movement` contract preserved.

POS remains distinct:
- source `pos`;
- existing invoiced/stock-moving contract preserved.

## 6. PROTECTED CORE

Not changed:
- `save_sales_invoice_atomic`
- `post_stock_movement`
- Runsheet lifecycle.
- Picking.
- Loading.
- Delivery.
- Return.
- Unloading.
- Accounting writers.
- Mother `main.html`.
- Telesales `telesales.html`.
- Shared `core.js`.

The production repair strengthens the boundary around the existing central engine instead of creating a parallel sales engine.

## 7. REQUIRED SURGICAL FRONTEND PATCHES — OWNER APPLIES

### Patch A — Telesales DB authorization hydration

File:
`companies/company-1/sales/telesales.html`

Function:
`self.init = function(user)`

Unique start:
`function _setup(u) {`

Unique end:
the closing `}` immediately before:
`if (user) _setup(user);`

Delete that complete `_setup(u)` function and replace it with:

```javascript
function _setup(u) {
    if (!u) { RW_UI.showError('فشل استعادة الجلسة'); return; }

    var email = String(u.email || '').trim().toLowerCase();
    if (!email) { RW_UI.showError('هوية المستخدم غير مكتملة'); return; }

    RW_UI.showLoader('جاري التحقق من صلاحيات الحساب...');

    supabase.from('users')
        .select('id,name,email,status,permissions,company_id,default_branch_id,allowed_branch_ids,role')
        .eq('email', email)
        .maybeSingle()
        .then(function(res) {
            RW_UI.hideLoader();

            if (res.error) {
                RW_UI.showError('تعذر قراءة صلاحيات المستخدم: ' + res.error.message);
                return;
            }

            var p = res.data;
            if (!p || !p.company_id) {
                RW_UI.showError('بيانات المستخدم أو الشركة غير مكتملة');
                RW_Auth.doLogout();
                return;
            }

            if (String(p.status || 'Active') === 'Inactive') {
                RW_UI.showError('حساب المستخدم غير نشط');
                RW_Auth.doLogout();
                return;
            }

            var perms = Array.isArray(p.permissions)
                ? p.permissions.map(function(x) { return String(x).trim(); }).filter(function(x) { return !!x; })
                : [];

            var isOwner = perms.indexOf('*') !== -1;

            if (!isOwner && perms.indexOf('telesales') === -1 && perms.indexOf('orders') === -1) {
                RW_UI.showError('غير مصرح – ليس لديك صلاحية التلي سيلز');
                RW_Auth.doLogout();
                return;
            }

            currentUser = {
                id: p.id,
                email: p.email || u.email,
                name: p.name || u.name || u.email,
                role: p.role || u.role || 'موظف',
                isOwner: isOwner,
                permissions: perms,
                company_id: p.company_id,
                default_branch_id: p.default_branch_id || null,
                allowed_branch_ids: p.allowed_branch_ids || null
            };

            pubUserId = p.id;

            supabase.from('app_settings').select('*').limit(1).single().then(function(sRes) {
                if (sRes.data) {
                    delFee = Number(sRes.data.delivery_fee) || 0;
                    taxRate = Number(sRes.data.tax_rate) || 0;
                    minAmt = Number(sRes.data.min_invoice_amount) || 0;
                }
            });

            RW_ImageCache.loadAll(function() { self.enterApp(); });
        })
        .catch(function(e) {
            RW_UI.hideLoader();
            RW_UI.showError(e.message || 'فشل التحقق من صلاحيات المستخدم');
        });
}
```

### Patch B — Telesales source identity in new-order payload

File:
`companies/company-1/sales/telesales.html`

Function:
`self.submitOrder`

Unique current block:

```javascript
var hdr = {
    customer_code: selCust.customer_code,
    custName: selCust.name,
    area: selCust.area || '',
    total: t.total,
    deliveryFees: t.del,
    status: 'Confirmed',
    paymentType: selCust.payment_type || 'أجل',
    taxAmount: t.tax,
    taxRate: taxRate
};
```

Delete the complete block and replace with:

```javascript
var hdr = {
    customer_code: selCust.customer_code,
    custName: selCust.name,
    area: selCust.area || '',
    total: t.total,
    deliveryFees: t.del,
    status: 'Confirmed',
    source: 'telesales',
    paymentType: selCust.payment_type || 'أجل',
    taxAmount: t.tax,
    taxRate: taxRate
};
```

This is intentionally redundant with Production v16 canonicalization: the frontend states its business intent explicitly while Production remains the authority.

### Patch C — Remove direct client-side order UPDATE during edit

Current defect:
The `isEdit` branch of `self.submitOrder` performs direct:
- `orders.update()`
- `order_details.delete()`
- `order_details.insert()`

This conflicts with the central Edge/RPC transaction boundary and is not reliable under current RLS.

The complete `isEdit` branch must be replaced with a call to the existing `save-sales-invoice` Edge Function using the existing order's operation identity.

Required replacement:

```javascript
if (isEdit) {
    supabase.from('orders')
        .select('id,operation_id,order_code')
        .eq('order_code', oldOrderCode)
        .maybeSingle()
        .then(function(res) {
            if (res.error) throw new Error(res.error.message);
            if (!res.data) throw new Error('الأوردر القديم غير موجود');

            var operationId = res.data.operation_id || crypto.randomUUID();

            var hdr = {
                customer_code: selCust.customer_code,
                custName: selCust.name,
                area: selCust.area || '',
                total: t.total,
                deliveryFees: t.del,
                status: 'Confirmed',
                source: 'telesales',
                paymentType: selCust.payment_type || 'أجل',
                taxAmount: t.tax,
                taxRate: taxRate,
                operation_id: operationId,
                existing_order_code: oldOrderCode
            };

            return new Promise(function(resolve) {
                RW_API.call('save-sales-invoice', {
                    orderHeader: hdr,
                    itemsList: items,
                    branchCode: selBranch,
                    operation_id: operationId
                }, function(json) {
                    if (!json || !json.success) {
                        resolve(Promise.reject(new Error((json && json.msg) || 'فشل تحديث الأوردر')));
                        return;
                    }
                    resolve(json);
                });
            });
        })
        .then(function(json) {
            RW_UI.hideLoader();
            RW_UI.toast('تم تحديث الأوردر ' + oldOrderCode + ' بنجاح', 'success');
            cart = [];
            selCust = null;
            selBranch = null;
            editingOrderCode = null;
            self.clearCustomer();
            self.updateFloatingCart();
            self.switchTab('today');
        })
        .catch(function(e) {
            RW_UI.hideLoader();
            RW_UI.showError(e.message || 'فشل تحديث الأوردر');
        });

} else {
```

IMPORTANT:
This patch exposes a remaining backend contract: `save_sales_invoice_atomic` currently creates a new order when the operation_id is not already registered; it does not implement an explicit update-by-existing-order contract. Therefore Patch C must NOT be applied as-is until a dedicated update contract is verified in Production.

Consequently, the safe immediate action is:
- Keep the current edit UI disabled for existing orders until an explicit update RPC/Edge contract is added.
- Do NOT use the above block in Production without proving update semantics.
- The existing direct UPDATE path is currently blocked by RLS for normal users, so it cannot be considered a valid integration path.

This is deliberately classified OPEN rather than hiding the contract gap.

## 8. ADDITIONAL FRONTEND DATA-SYNC PATCH

Current `self.syncDown` ignores Supabase errors and replaces local stores with empty arrays when a query is denied.

The owner should replace the complete `self.syncDown = function() { ... };` block with a version that checks `r.error` for every query before clearing Dexie.

This is required for reliable synchronization discipline and prevents an authorization failure from looking like valid empty data.

Recommended complete replacement:

```javascript
self.syncDown = function() {
    function read(table) {
        return supabase.from(table).select('*').then(function(r) {
            if (r.error) throw r.error;
            return r.data || [];
        });
    }

    return Promise.all([
        read('customers'),
        read('items'),
        read('stock_branches'),
        read('branches')
    ]).then(function(rows) {
        return db.transaction('rw', db.customers, db.items, db.stock, db.branches, function() {
            return db.customers.clear()
                .then(function() { return db.customers.bulkPut(rows[0]); })
                .then(function() { return db.items.clear(); })
                .then(function() { return db.items.bulkPut(rows[1]); })
                .then(function() { return db.stock.clear(); })
                .then(function() { return db.stock.bulkPut(rows[2]); })
                .then(function() { return db.branches.clear(); })
                .then(function() { return db.branches.bulkPut(rows[3]); });
        });
    });
};
```

## 9. ITEMS / CUSTOMERS / BRANCH / STOCK CONTRACT

After the Production RLS repair, the application can legitimately read:
- BR-01 branch.
- 3 customers.
- 17 items.
- 17 stock rows.

The frontend must still preserve the rule:
`available = qty - allocated_qty`.

No frontend stock movement is permitted.

## 10. OPEN CONTRACTS — NOT HIDDEN

1. Mother `main.html` owner/license-tab surgery from Report390 is still not applied/verified in the served artifact.
2. Shared `core.js` still derives authorization from metadata; no direct source change was made because the owner explicitly controls frontend file changes.
3. Existing-order edit requires a canonical update contract; it must not be emulated by direct multi-step client writes.
4. Browser-rendered E2E cannot be claimed from this toolchain without a browser/runtime interaction artifact.
5. Telesales password was not changed and no test credentials were created.

## 11. WHAT IS CLOSED

### Production integration foundation
- DB identity exists.
- DB permission exists.
- branch visibility exists.
- customer visibility exists.
- item visibility exists.
- stock visibility exists.
- own-order visibility contract exists.
- own-order-detail visibility contract exists.
- sales Edge authorization exists.
- sales source identity exists.
- delete-order ownership enforcement exists.
- no new Edge Function created.
- no stock-core change.
- no accounting-core change.
- no Mother/Telesales source file modified.

## 12. SELF-AUDIT FINAL

### What I Proved
- The original Telesales RLS integration gap was real.
- It was not caused by missing Telesales code alone.
- Production now exposes the minimum required read surface to the Telesales/Order-Taker permissions.
- Production sales creation is now permission-gated and source-aware.
- Production order deletion is now ownership-gated for ordinary sales users.
- Branch restriction is enforced from the DB user assignment.
- The central sales RPC remains the transaction engine.

### What I Did Not Prove
- Browser-rendered Telesales login.
- Browser-rendered new-order creation.
- Production HTTP E2E with a real Telesales password.
- Existing-order edit closure.
- Mother license-tab served artifact.
- Full cross-module E2E through Runsheet → Picking → Loading → Delivery.

### What I Fixed
- RLS read surface.
- Branch selection access.
- Sales Edge authorization.
- Telesales source canonicalization.
- Delete-order authorization.

### What I Initially Missed
- The standalone Telesales source itself was relying on shared metadata authorization.
- Existing-order editing was attempting direct client writes rather than a canonical update contract.
- The RLS surface was incomplete even though the UI code existed.

### What Could Still Be Wrong
- The owner may not yet have applied the frontend surgery.
- Browser cache/service-worker may still serve an older artifact.
- Existing-order edit needs an explicit backend update contract before closure.

### Final Confidence
Production integration foundation: HIGH / VERIFIED.
Full Telesales functional closure: NOT YET CLAIMED.

### Final Closure Status
`PRODUCTION INTEGRATION FOUNDATION = VERIFIED`
`TELESALES FULL FUNCTIONAL CLOSURE = OPEN`

## إلى CTO القادم

Start from:
1. Report391.
2. Current Production Edge versions: save-sales-invoice v16, delete-order v10.
3. Current RLS policies listed in this report.
4. Apply/verify Patch A and the syncDown patch.
5. Add source='telesales' explicitly in the frontend.
6. Do not implement the existing-order edit replacement until an explicit update contract is added and tested.
7. Then run real authenticated E2E with a real Telesales account.
8. After Telesales closes, continue the next business capability without reopening protected inventory core.

