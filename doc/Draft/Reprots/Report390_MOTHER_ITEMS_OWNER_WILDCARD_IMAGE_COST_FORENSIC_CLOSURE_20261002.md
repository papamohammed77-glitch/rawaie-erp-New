# Report390 — التحقيق الجنائي وإغلاق دورة تبويب الأصناف + Owner Wildcard + Image + Cost Price
## التاريخ
2026-10-02

## 0. نقطة الإغلاق الحاكمة
هذا التقرير مبني على:
1. CURRENT GIT.
2. CURRENT SOURCE.
3. CURRENT PRODUCTION.
4. CURRENT DATABASE.
5. CURRENT DEPLOYMENT EVIDENCE المتاحة.

التقارير السابقة استُخدمت كمرجع تاريخي فقط. لم يُعاد تنفيذ أي إصلاح ثبت وجوده بالفعل في CURRENT HEAD.

---

# 1. CURRENT GIT / CURRENT SOURCE

## Mother Source
- Repository: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- Target: `companies/company-1/main.html`
- CURRENT HEAD: `768ee12721a85511e38618666c29568f0658615c`
- Parent: `bc4d7a02919dcaf82d11bb599e879281cd550737`
- Current `main.html` blob: `2b5b763ada7428f96a05c1144c75f13eec5b1492`
- Current source size: 1,755,533 characters / 32,349 lines.

## Important reconciliation
Commit `768ee...` already contains the historical DirectSale/DirectReturn representative column repair:
- `المندوب` header موجود.
- `custodian_name` row projection موجود.
- empty-state `colspan="11"` موجود.

Therefore **لا يجوز إعادة تطبيق Report388/384 على Current main.html**.

Current source is the source truth. A missing column in the served UI now indicates a deployment/runtime artifact mismatch until proven otherwise.

---

# 2. CURRENT PRODUCTION FIRST

## Supabase
- Project: `SMART ERP`
- Ref: `fiilmooggumokxanwiyx`

## Edge Functions capacity
Current Production contains exactly **100 Edge Functions**.
لا Function جديدة تم إنشاؤها في هذه الدورة.

## Functions changed
Only existing functions were updated:

### `save-category`
- v4 → **v5**
- `verify_jwt=true`
- authorization now uses DB `public.users.permissions` only.
- removed authorization dependence on `auth.users.raw_user_meta_data/user_metadata`.

### `delete-item`
- v4 → **v5**
- `verify_jwt=true`
- authorization now uses DB `public.users.permissions` only.
- removed authorization dependence on `auth.users.raw_user_meta_data/user_metadata`.

### `save-item`
- remains v14.
- no unnecessary redeployment.

## Owner Production evidence
Current owner row:
- email: `owner@alrawae.com`
- status: Active
- `public.users.permissions=["*"]`
- `owner_profile.license_status=active`
- auth linkage valid.

The canonical owner contract is therefore:
`permissions=["*"]` + active account + valid owner profile.

## Security basis
Current Supabase documentation explicitly warns not to rely on `user_metadata` in security-sensitive authorization logic because it is editable by the user. Edge Functions with `verify_jwt=true` receive an authenticated user JWT before handler authorization is applied.

References:
- https://supabase.com/docs/guides/auth/users
- https://supabase.com/docs/guides/functions/auth
- https://supabase.com/docs/guides/functions/auth-headers
- https://supabase.com/changelog/33720-deploy-and-update-edge-functions-using-the-management-api

---

# 3. ROOT CAUSE — OWNER / LICENSE TAB

## Current defective element
Inside:
`RW_Auth.login()`

Approximate current lines: 1268–1300.

The defective source starts with:

```javascript
return RW_SUPABASE_CLIENT
    .from('users')
    .select('company_id, status')
```

and hydrates:
```javascript
RW_STATE.app.currentUser.isOwner
RW_STATE.permissions
```
from `user.user_metadata`.

This is inconsistent with the current Production source of truth.

## Exact owner surgical replacement
In `RW_Auth.login()`, search literally for the complete block beginning:

```javascript
return RW_SUPABASE_CLIENT
    .from('users')
    .select('company_id, status')
```

and ending immediately before the closing of the login promise chain:

```javascript
        return self.enterSystem();
    });
```

Delete that complete block and replace it with:

```javascript
return RW_SUPABASE_CLIENT
    .from('users')
    .select('company_id, status, permissions, name')
    .eq('auth_id', user.id)
    .maybeSingle()
    .then(function(profileRes) {
        if (profileRes.error) throw profileRes.error;
        if (!profileRes.data || !profileRes.data.company_id) {
            throw new Error('بيانات سياق الشركة للمستخدم غير مكتملة');
        }
        if (profileRes.data.status === 'Inactive') {
            throw new Error('حساب المستخدم غير نشط');
        }

        var dbPermissions = Array.isArray(profileRes.data.permissions)
            ? profileRes.data.permissions
                .map(function(p) { return String(p).trim(); })
                .filter(function(p) { return !!p; })
            : [];
        var isOwner = dbPermissions.indexOf('*') !== -1;

        RW_STATE.app.authenticated = true;
        RW_STATE.app.currentUser = {
            name: profileRes.data.name || meta.name || user.email,
            email: user.email,
            role: meta.role || 'مدير النظام',
            isOwner: isOwner,
            permissions: dbPermissions
        };

        RW_STATE.permissions = dbPermissions;
        RW_STATE.app.company = {
            id: profileRes.data.company_id,
            name: meta.companyName || 'الروائع ERP',
            logo: meta.companyLogo || 'ر'
        };

        RW_Audit_log('login', 'auth', user.id, null, {
            email: user.email,
            role: meta.role || 'مدير النظام',
            company_id: profileRes.data.company_id
        });

        return self.enterSystem();
    });
```

## Result
- Owner wildcard is derived from DB.
- `RW_STATE.permissions=["*"]`.
- `currentUser.isOwner=true`.
- License tab guard can pass after a fresh login/session.
- No change to role table or owner_profile.

---

# 4. ITEMS — CURRENT FUNCTIONAL INVENTORY

Current `RW_Items` is present and integrated.

Verified:
- item list
- search by name/code/barcode
- category filter
- stock status filter
- sorting
- branch stock columns
- total stock drill-down
- branch-specific movement drill-down
- movement report
- branch matrix
- branch filter
- Excel export
- stock update/upload
- category management
- add item
- edit item
- delete item
- 3 item edit tabs
- opening stock
- image preview/viewer
- marketing settings
- online-store visibility
- discount fields
- active/inactive state.

The old `_renderTable()` rowHtml regression is already corrected in Current HEAD and is NOT to be touched.

---

# 5. ITEMS — ROOT CAUSE OF IMAGE SAVE FAILURE

## Defective element
Function:
`RW_Items._handleSaveFromPage()`

Nested helper:
`resolveImageUrlAndSave(item, fileInput, callback)`

Current location: approximately lines 5578–5617.

## Exact defect
Current code uploads with:

```javascript
{ upsert: true }
```

and when the upload fails it calls the save continuation using the previous image URL:

```javascript
var fallbackUrl = (item && item.image_url != null) ? item.image_url : null;
callback(fallbackUrl);
return;
```

This converts a failed image upload into a successful item save path. It is a silent partial-success defect.

It also conflicts with the Production storage model, where insert is deliberately permission-controlled and no generic overwrite path should be assumed.

## Exact surgical replacement
Search literally:

```javascript
function resolveImageUrlAndSave(item, fileInput, callback) {
```

Delete the entire nested function through its closing `}` immediately before:

```javascript
// دالة الحفظ الفعلية – تستقبل imageUrl كمعامل
```

Replace the complete nested function with:

```javascript
function resolveImageUrlAndSave(item, fileInput, callback) {
    var file = (fileInput && fileInput.files.length > 0) ? fileInput.files[0] : null;

    if (!file) {
        var existingUrl = (item && item.image_url != null) ? item.image_url : null;
        console.log('📸 لا توجد صورة جديدة. استخدام:', existingUrl);
        callback(existingUrl);
        return;
    }

    console.log('📤 بدء رفع الصورة:', file.name, file.size);

    // اسم ملف آمن – ASCII فقط مع الحفاظ على الامتداد
    var lastDot = file.name.lastIndexOf('.');
    var fileExt = lastDot > -1 ? file.name.substring(lastDot) : '.jpg';
    var safeName = encodeURIComponent(file.name.substring(0, lastDot > -1 ? lastDot : file.name.length));
    var fileName = Date.now() + '-' + safeName + fileExt;

    supabase.storage.from('product-images').upload(fileName, file, { upsert: false })
        .then(function(res) {
            if (res.error) {
                console.error('❌ فشل الرفع:', res.error.message);
                hideLoader();
                showToast('فشل رفع الصورة: ' + res.error.message, 'error');
                return;
            }

            console.log('✅ رفع ناجح. جاري توليد الرابط العام...');
            var publicUrl = supabase.storage.from('product-images').getPublicUrl(fileName).data.publicUrl;
            if (!publicUrl) {
                hideLoader();
                showToast('تم رفع الصورة لكن تعذر إنشاء الرابط العام', 'error');
                return;
            }

            console.log('✅ الرابط العام:', publicUrl);
            callback(publicUrl);
        })
        .catch(function(err) {
            console.error('❌ خطأ شبكة:', err.message);
            hideLoader();
            showToast('فشل رفع الصورة: ' + (err && err.message ? err.message : 'خطأ غير معروف'), 'error');
        });
}
```

## Result
- image upload failure stops the save continuation.
- previous image is not silently reused after a new upload failure.
- duplicate overwrite via `upsert:true` is removed.
- successful upload alone produces the new `image_url`.

No change to `executeSave()` is required for the image defect.

---

# 6. ITEMS — PROVEN MISSING COST PRICE CONTRACT IN THE UI

## Current source proof
`public.items.cost_price` exists.
`create_item_with_opening_stock` accepts and persists `cost_price`.
`save-item` v14 accepts `cost_price`.
Purchase, replenishment and inventory-control parts of the Mother source already read `cost_price`.

But the item edit/create form does not expose an input for `cost_price`, and the `executeSave()` payload currently sends `sales_price` without `cost_price`.

This is a current source-to-backend capability gap, not a speculative feature.

## Why it matters
The project already uses cost price in purchasing, replenishment, inventory valuation and decision outputs. Therefore leaving the field uneditable from the master item screen creates an incomplete item-master contract.

For reference, mature ERP products similarly expose item cost concepts and connect them to purchasing/inventory valuation:
- Microsoft Dynamics 365 Business Central documents Unit Cost / Last Direct Cost and its effect on purchasing, sales, and inventory valuation.
- Odoo documents product pricing, unit pricing and eCommerce product configuration.

References:
- https://learn.microsoft.com/en-us/dynamics365/business-central/finance-about-calculating-unit-cost
- https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-adjust-item-costs
- https://www.odoo.com/documentation/19.0/applications/websites/ecommerce/configuration/prices.html
- https://www.odoo.com/documentation/master/applications/websites/ecommerce/products/prices.html

## Surgical replacement 1 — item cost field
Function:
`RW_Items.openItemPage(itemCode)`

Approximate line: 5519.

Search literally for this complete current line:

```javascript
html += '<div class="flex flex-col"><label class="text-sm font-bold">سعر البيع</label><input id="item-price" type="number" value="' + _esc(item ? (item.sales_price || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
```

Delete that line and replace it with these two complete lines:

```javascript
html += '<div class="flex flex-col"><label class="text-sm font-bold">سعر التكلفة</label><input id="item-cost" type="number" value="' + _esc(item ? (item.cost_price || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg" min="0" step="0.01"></div>';
html += '<div class="flex flex-col"><label class="text-sm font-bold">سعر البيع</label><input id="item-price" type="number" value="' + _esc(item ? (item.sales_price || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
```

## Surgical replacement 2 — payload
Function:
nested `executeSave(imageUrl)` inside `RW_Items._handleSaveFromPage()`

Approximate line: 5631.

Search literally for:

```javascript
sales_price: parseFloat(byId('item-price') ? byId('item-price').value : 0) || 0,
```

Delete that single line and replace it with:

```javascript
cost_price: parseFloat(byId('item-cost') ? byId('item-cost').value : 0) || 0,
sales_price: parseFloat(byId('item-price') ? byId('item-price').value : 0) || 0,
```

This is intentionally surgical. Do not replace `executeSave()` itself.

---

# 7. CATEGORIES / MODALS / BUTTONS

## Current source
- `_openCategoryModal()`: company-scoped.
- `_addCategory()`: uses existing `save-category`.
- `_editCategory()`: uses existing `save-category`.
- `_deleteCategory()`: validates linked items then uses existing `save-category`.
- `_buildCategoryFilterFromDB()`: company-scoped.

## Production correction
The only defect found in this path was the authorization branch in `save-category` using `user_metadata`. It is now corrected in v5.

No frontend category code was changed.

---

# 8. DELETE ITEM

Frontend:
`_handleDeleteFromPage()` uses existing `delete-item`.

Production:
`delete-item` v5 now authorizes only from DB `users.permissions`.

No change was made to deletion workflow itself.

Current permission contract is intentionally coarse:
`items` or `*`.

No speculative granular permissions such as `items.create`, `items.update`, `items.delete` were introduced because they do not exist in the current permission vocabulary and would be an architectural expansion, not a repair.

---

# 9. FUTURE USERS / PERMISSION CONTRACT

Current Mother source maps:

```
'items' -> 'items'
```

and `RW_Permissions_check()` already gives wildcard `*` absolute authority.

Current roles in Production that explicitly contain `items` include:
- مدير النظام
- مدير عام
- مدير مخازن
- مشرف مخازن

Therefore the current architecture already supports delegated access through DB permissions.

The important security correction made in this cycle is that the backend now agrees with the DB permission source rather than allowing stale/mutable Auth user metadata to elevate a caller.

Granular CRUD permissions remain a future Business Contract decision, not a silent addition to this repair.

---

# 10. REPRESENTATIVE COLUMN — CURRENT TRUTH

The requested representative column does **not** require another source patch.

Current source at `_renderVoucherHistory(type)` around line 14432 already contains:

```javascript
<td>المندوب</td>
```

and row projection:

```javascript
esc(r.custodian_name||'—')
```

and empty-state:

```colspan="11"```

Commit `768ee...` introduced this current state.

Therefore:
- Do NOT delete/reinsert this column.
- Do NOT alter `_renderVoucherHistory()`.
- If production UI still omits it, inspect the served artifact/deployment identity after the owner publishes current source.

---

# 11. DATABASE / WORKFLOW / ACCOUNTING INVARIANTS

Current `create_item_with_opening_stock`:
- validates company.
- validates category/company.
- validates opening branch/company.
- creates item.
- if opening quantity > 0, calls existing `post_stock_movement` as `InventoryIncrease`.
- writes exactly the expected inventory movement.
- does not create a journal entry for the opening-stock test path observed in this system.

Current `post_stock_movement`:
- locks the affected stock rows.
- validates movement type.
- protects against insufficient stock.
- inserts inventory_log.
- uses idempotency.

These contracts were not replaced or redesigned.

---

# 12. TRANSACTIONAL QA — REAL PRODUCTION STRUCTURE

A Production transaction was executed using:
- company: `00000000-0000-0000-0000-000000000001`
- branch: `BR-01`
- temporary category: `__QA390_CATEGORY__`
- temporary item: `__QA390_ITEM__`
- opening quantity: 3
- cost price: 10
- sales price: 25
- image URL set
- initial `show_in_store=false`

Then the same item was edited within the same transaction:
- name changed.
- sales price 25 → 27.
- cost price 10 → 11.
- `show_in_store=false → true`.
- category cleared to NULL.
- image URL changed.

Observed before rollback:
- item code generated: `ITM-20260928`
- opening balance posted: true.
- branch quantity: 3.
- allocated quantity: 0.
- inventory log rows for the item: 1.
- journal entries total: 10 before/after the edit.
- category_id: NULL after the edit.
- `show_in_store=true`.
- image_url persisted.
- QA item count within transaction: 1.
- QA category count within transaction: 1.

The whole transaction was rolled back.

Post-rollback verification:
- items = 17
- categories = 5
- inventory_log = 12
- journal_entries = 10
- QA items = 0
- QA categories = 0
- QA inventory logs = 0

No test residue remains.

---

# 13. IMAGE / STORAGE PRODUCTION CONTRACT

Current Production storage policy:
`product_images_authenticated_insert_items`

It requires:
- authenticated caller.
- target bucket = `product-images`.
- active DB user.
- DB permissions `items` or `*`, or equivalent existing role permission.

Public SELECT remains intentional for online-store product assets.

No storage schema change was made in this cycle.

---

# 14. SOURCE SYNTAX GATE

The two exact frontend replacement payloads were independently syntax checked with Node.js after construction:
- Owner authorization replacement: PASS.
- Image helper replacement: PASS.

Current unmodified Mother source remains the Git source of truth. No owner frontend source was changed by this session.

---

# 15. SUPABASE SECURITY ADVISORY SNAPSHOT

Current Production advisors also report pre-existing broader findings outside this Items closure, including:
- 20 tables with RLS enabled but no policies.
- 3 SECURITY DEFINER views.
- 3 functions with mutable search paths.
- 18 SECURITY DEFINER functions callable by anon.

These are not silently altered here because they are separate contracts and require individual blast-radius analysis.

They are recorded as open infrastructure/security debt, not part of this closure.

---

# 16. COMPETITIVE GAP REVIEW

## What the current Items tab already has
The current screen already goes beyond a basic item master by joining:
- item master data
- stock by branch
- stock status
- movement drill-down
- opening stock
- marketing/store visibility
- image
- category management
- stock adjustment
- inventory reporting.

That integrated model should be preserved.

## Proven immediate improvement
Add the currently existing backend/database `cost_price` to the item-master UI, because it is already used elsewhere by the system.

## Mature ERP capabilities that are not proven missing and therefore were NOT invented here
Examples include:
- product variants/attributes
- multiple pricelists by customer/channel
- units-of-measure hierarchy
- item/vendor cross-reference
- lot/serial/expiry master controls
- tax classification
- packaging levels
- merchandising/category ecommerce attributes.

Odoo currently documents product variants, eCommerce visibility and pricing capabilities; Business Central documents item cost, costing methods and cost adjustments.

These are benchmark references for future Business Contracts, not reasons to alter the current RAWAEA architecture without source/database proof.

---

# 17. WHAT WAS DELIBERATELY NOT TOUCHED

- Current `main.html` table renderer fix.
- DirectSale/DirectReturn representative column.
- DirectReturn receive direction.
- runsheet lifecycle.
- picking/loading/delivery/return/unloading workflow.
- stock movement core.
- accounting writers.
- existing owner profile/license data.
- `save-item` v14.
- storage read model.
- creation of new Edge Functions.
- historical source files.

---

# 18. DEPLOYMENT BOUNDARY

Current Git source and current Production backend are verified.

Fresh served-artifact identity for the owner-published `main.html` is still not available from the available toolchain.

Therefore:
- Backend Production = CLOSED for this cycle.
- Current source forensic = CLOSED.
- Owner surgical patches = READY.
- Browser-rendered E2E = OPEN.
- Served artifact identity = OPEN.

The missing representative column in a browser cannot be attributed to Current Source because Current HEAD already contains it.

---

# 19. FINAL SELF-AUDIT

## Instruction compliance
- Historical reports used as guidance only: PASS.
- Current Git inspected: PASS.
- Parent commit checked: PASS.
- Current source inspected: PASS.
- Current Production inspected: PASS.
- Current database inspected: PASS.
- No new Edge Function: PASS.
- Existing Edge Functions updated only: PASS.
- Main.html modified by this session: NO.
- Surgical replacements are exact and complete: PASS.
- Previous closed renderer repair was not repeated: PASS.
- Representative column was not re-patched because Current HEAD already contains it: PASS.
- Test data created and rolled back: PASS.
- Database residue cleanup verified: PASS.
- Journal-entry invariant verified: PASS.
- Branch-stock invariant verified: PASS.
- Image persistence path verified at DB level: PASS.
- Browser-rendered E2E: NOT CLAIMED; OPEN.
- Served artifact identity: NOT CLAIMED; OPEN.

## Security audit
The authorization path is now consistent:
```
DB public.users.permissions
        ↓
items/* permission gate
        ↓
authorized Edge Function
```

No `user_metadata` owner bypass remains in the two affected Production item/category functions.

## Completion test
A closure is not called 100% browser-complete until:
1. owner applies the three frontend surgery groups:
   - Owner login block.
   - Image helper.
   - Cost-price field + payload.
2. publish.
3. fresh login.
4. verify license tab.
5. verify item create/edit/cost/image/store visibility.
6. verify representative column from served artifact.
7. verify current source blob == served artifact.

---

# 20. NEXT CTO / ASSISTANT START SEQUENCE

Do not restart Items.

Start with:
1. CURRENT HEAD `768ee...`.
2. Check whether owner has applied the exact surgical replacements.
3. Verify fresh served artifact hash/content.
4. Run rendered browser E2E.
5. Verify:
   - owner/license tab
   - item create
   - cost price round-trip
   - item edit
   - image success
   - image failure must abort save
   - store visibility
   - category create/update/delete
   - representative column.
6. Only then open the next real unresolved contract.

Never reopen a closed workflow because an old report says it was once broken.

# END REPORT390
