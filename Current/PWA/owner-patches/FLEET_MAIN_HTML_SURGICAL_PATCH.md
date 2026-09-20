# RAWAEA ERP — Fleet Management / Surgical Mother Patch
## Current Mother checkpoint — refreshed 2026-09-20
- Repository: `papamohammed77-glitch/erp-frontend`
- Current Mother HEAD: `1823f9ab0e6f88c0118585c0b4f50a0b9b36bc38`
- Parent: `fb8799f854df8d7c50c2874c247a29026a80939b`
- Current `companies/company-1/main.html` blob: `abb3829ec85724f0053ec0a7a9e035731e9df310`
- **Do not replace `main.html`. Do not edit unrelated code.**
- The Mother changed after the original Fleet checkpoint through report-title enhancement and forensic HR extract commits. The Fleet anchors below were re-verified against the current blob.
- Insert the complete module from `Current/PWA/owner-patches/RW_FleetManagement.js` before the exact marker:
`// RW_Views – نظام التوجيه النهائي`

## Verified current anchors
The current Mother blob contains:
- `var permLabels = [`
- `var viewIcons = {`
- `var permissionMap = {`
- `var titles = {`
- `// RW_Views – نظام التوجيه النهائي`
- `if (view === 'inventory-control')`
- inventory navigation group `إدارة المخازن والمخزون`
- accounting navigation group `إدارة الحسابات والمالية`

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
```js
{ key: 'hr', label: 'الموارد البشرية', group: 'apps' },
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
```js
'inventory-control': 'fa-boxes-stacked',
```
this exact line:
```js
            'fleet-management': 'fa-truck-moving',
```

## Patch 4 — Router title + access + route
Find:
```js
var permissionMap = {
```
Do NOT add a normal `permissionMap` dependency for Fleet. Immediately BEFORE:
```js
var permKey = permissionMap[view];
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
```js
'finance':'الإدارة المالية',
```

Find the exact router branch:
```js
if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }
```
Insert immediately AFTER it:
```js
        if (view === 'fleet-management') { RW_FleetManagement.render(); return; }
```

## Patch 5 — Module insertion
Find the exact unique marker:
```js
// RW_Views – نظام التوجيه النهائي
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

## Owner verification gate
After applying the five patches:
1. Confirm the Fleet module occurs exactly once.
2. Confirm `RW_FleetManagement.render` is reachable.
3. Run full Mother JavaScript parse.
4. Open Fleet from navigation.
5. Verify dashboard → vehicles → vehicle detail → drivers → alerts → trips → costs → performance.
6. Create a vehicle and driver in Production test tenant only if an approved non-production tenant exists; otherwise perform read-only smoke tests.
7. Confirm no direct browser writes to Fleet tables.
8. Re-read Production counts and audit rows after the browser test.


## Patch 6 — CRITICAL runtime namespace closure — 2026-09-20

Current Mother HEAD: ddcd9995240605dd9bcf31ab1abb1a774b887f84
Current Mother parent: 1823f9ab0e6f88c0118585c0b4f50a0b9b36bc38
Current main.html blob: 6074a4fc5f915701b23af5d7b6fca8a083c0a9dd

PROVEN DEFECT
The module is declared as var RW_FleetManagement = (function() { ... })(); but the IIFE previously assigned only window.RW_FleetManagement and returned nothing. Therefore the lexical variable RW_FleetManagement became undefined while window.RW_FleetManagement existed. The router calls RW_FleetManagement.render() directly, producing the reported TypeError.

EXACT SURGICAL CHANGE
File: erp-frontend/companies/company-1/main.html
Find the exact Fleet IIFE tail immediately before the marker: // RW_Views – نظام التوجيه النهائي
Delete only the old window.RW_FleetManagement={...}; })(); tail.
Replace it with the corrected tail stored in Current/PWA/owner-patches/RW_FleetManagement.js, which creates var api, assigns window.RW_FleetManagement = api, and ends with return api; before the IIFE closes.

DO NOT CHANGE
Do not change the Fleet router branch, permissions, RPC names, database schema, or any unrelated main.html code.
