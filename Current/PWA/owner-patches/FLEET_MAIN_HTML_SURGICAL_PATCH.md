# RAWAEA ERP — Fleet Management / Surgical Mother Patch
## Current Mother
- Repository: papamohammed77-glitch/erp-frontend
- Main blob: 5a628da5417a830bf22553fa99a858521cdf6673
- File: companies/company-1/main.html
- **Do not replace main.html. Do not edit unrelated code.**
- Insert the complete module from `Current/PWA/owner-patches/RW_FleetManagement.js` before the exact marker:
`// RW_Views – نظام التوجيه النهائي`

## Patch 1 — Navigation
Find the exact existing submenu anchor:
```js
{ icon: 'fa-warehouse', label: 'إدارة المخازن والمخزون', submenu: [
```
Inside `RW_Navigation.menuTree`, immediately AFTER the closing `},` of the whole inventory submenu and BEFORE:
```js
{ icon: 'fa-coins', label: 'إدارة الحسابات والمالية', submenu: [
```
insert exactly:
```js
{ icon: 'fa-truck-moving', label: 'إدارة الأسطول والحركة', submenu: [
    { view: 'fleet-management', label: 'لوحة إدارة الأسطول', perm: ['fleet.read','fleet.manage','general_manager','warehouse_manager','delivery_supervisor','finance_manager'] }
] },
```

## Patch 2 — Permission catalog
Find the exact array:
```js
var permLabels = [
```
Insert BEFORE:
```{ key: 'hr', label: 'الموارد البشرية', group: 'apps' },
```
the following two complete entries:
```js
    { key: 'fleet.read', label: 'إدارة الأسطول — قراءة وتقارير', group: 'erp' },
    { key: 'fleet.manage', label: 'إدارة الأسطول — تشغيل وتعديل', group: 'erp' },
```

## Patch 3 — Navigation icon
Find the exact object:
```js
var viewIcons = {
```
Insert immediately after:
```'inventory-control': 'fa-boxes-stacked',
```
this exact line:
```js
            'fleet-management': 'fa-truck-moving',
```

## Patch 4 — Router title + access + route
Find:
```var permissionMap = {
```
Do NOT add a normal permissionMap dependency for Fleet. Immediately BEFORE:
```var permKey = permissionMap[view];
```
insert:
```js
        if (view === 'fleet-management') {
            var fleetUser = (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app) ? RW_STATE.app.currentUser : null;
            var fleetPerms = (typeof RW_STATE !== 'undefined' && Array.isArray(RW_STATE.permissions)) ? RW_STATE.permissions : [];
            var fleetAllowed = !!(fleetUser && (
                fleetUser.isOwner === true ||
                fleetPerms.indexOf('*') !== -1 ||
                fleetPerms.indexOf('fleet.read') !== -1 ||
                fleetPerms.indexOf('fleet.manage') !== -1 ||
                fleetPerms.indexOf('general_manager') !== -1 ||
                fleetPerms.indexOf('warehouse_manager') !== -1 ||
                fleetPerms.indexOf('delivery_supervisor') !== -1 ||
                fleetPerms.indexOf('finance_manager') !== -1 ||
                fleetUser.role === 'مدير عام' ||
                fleetUser.role === 'مدير مخازن' ||
                fleetUser.role === 'مشرف توصيل' ||
                fleetUser.role === 'مدير مالي'
            ));
            if (!fleetAllowed) {
                safeHTML(c, '<div class="rw-card" style="text-align:center;padding:60px 20px"><div style="font-size:64px">🔒</div><h2>غير مصرح</h2><p>ليس لديك صلاحية الوصول إلى إدارة الأسطول</p></div>');
                return;
            }
        }
```

Find the exact `var titles = {` object and insert:
```js
            'fleet-management':'إدارة الأسطول والحركة',
```
Immediately BEFORE:
```'finance':'الإدارة المالية',
```

Find the exact router branch:
```if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }
```
Insert immediately AFTER it:
```js
        if (view === 'fleet-management') { RW_FleetManagement.render(); return; }
```

## Patch 5 — Module insertion
Find the exact unique marker:
```// RW_Views – نظام التوجيه النهائي
```
Insert the **complete content** of `RW_FleetManagement.js` immediately BEFORE that marker.

## Runtime contract
The module must call only:
- `fleet_query`
- `fleet_command_atomic`

No new Edge Function is required.
No direct browser DML against Fleet tables is allowed.

## Operational integration
Fleet must not create another runsheet/order/inventory engine.
It reads:
- `runsheets.vehicle_id`
- `runsheets.driver_id`
- `runsheets.meter_start`
- `runsheets.meter_end`
- existing vehicle mobile branch / stock model
- existing vehicle count
- existing daily settlement
- existing driver liabilities/ledger

Fleet is supervisory/control-plane functionality over the existing operational spine.
