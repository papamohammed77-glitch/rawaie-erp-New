# Report619 — LVE616 Schema Review, Receiver Patch Completion and Integrated Buyer Custody Contract

**Date:** 2026-11-04 — Africa/Cairo  
**Starting checkpoint:** LVE616 / Report616.  
**Operational repository:** papamohammed77-glitch/erp-frontend / main.  
**Production:** SMART ERP / fiilmooggumokxanwiyx.  
**Status:** LVE616 ARTIFACTS REVIEWED / FIRST SQL DRAFT REJECTED FOR EXECUTION / REVIEWED SCHEMA V2 PREPARED / RECEIVER PATCH COMPLETED FOR OWNER APPLICATION / RPC + TRIGGER + EDGE + E2E REMAIN OPEN.  
**Change control:** No operational app source, Production schema/data, ACL/RLS/Grant, RPC/Trigger, Edge deployment or Cloudflare deployment was changed.

---

## 1. Executive result

LVE616 contains useful work: an exact PO Receiver correction and an initial additive SQL scaffold. This review found that the first SQL scaffold should not be executed even after the missing RPCs are later added. It has structural risks that could affect the wrong voucher types, bypass migration preconditions or create inconsistent lifecycle states.

A reviewed second schema draft is prepared:

`Current/CTO/ChangeSets/20261104/02_buyer_goods_custody_schema_security_REVIEWED_DRAFT.sql`

It preserves current purchase-return status constraints and `purchase_returns.purchase_invoice_id NOT NULL`, does not put SupplierReturn fields on unrelated voucher types, uses explicit source/settlement vocabulary, records supplier delegation evidence and keeps acceptance as event detail instead of duplicate mutable acceptance counters on the physical voucher line.

This second file is still a schema/security scaffold only. It has **not** been executed and is not a complete deployable migration. Full atomic RPC/Trigger bodies, existing Edge updates, application patches, security tests, rollback and owner approval remain necessary.

---

## 2. LVE616 source and evidence revalidation

### 2.1 Current source identity

- Operational HEAD observed: `e8ab54c75572e15e71581212479d22be139c8020`.
- Buyer `companies/company-1/purchasing/buyer.html`: `311f2673a90149df6f56d59a9a187a3379e6981c`.
- Warehouse Vouchers `companies/company-1/warehouse/vouchers.html`: `85e709d0f41c189c6624a6160965d3b1a41960ba`.
- Receiver `companies/company-1/warehouse/receiver.html`: `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`.
- Parent `companies/company-1/main.html`: `f6ec4ab41dc517f86e17dd3d74a9d5f8add264ca`, remains locked.
- No operational source changed.

### 2.2 Edge source recovery

All six archived snapshots in `Current/CTO/EdgeSnapshots/20261104/` were compared byte-for-byte with the currently deployed Supabase Edge source; all matched:
- save-purchase-order v22
- receive-purchase v13
- create-stock-voucher v12
- send-stock-voucher v20
- receive-stock-voucher v22
- complete-stock-voucher v4

Only `save-purchase-order/index.ts` is already tracked at the matching operational path and byte-identical to Production. The other five sources are archived but not yet restored to `erp-frontend/supabase/functions`. No Edge function was deployed or modified.

This closes the recovery/parity question for the review window; it does not approve editing or deployment.

### 2.3 Production schema facts used for the draft

- `receiving.po_number` is nullable, so a Quick Market receipt need not fabricate a PO code.
- `receiving.company_id` and existing operation identity remain present.
- `receiving_details` already has `qty_expected`, `qty_received`, `difference`, and `reason`; no existing columns were overwritten.
- `purchase_invoice_details.received_qty` already exists and is used for invoice-line receiving accumulation.
- `buyer_custody_expenses` already has references for `purchase_invoice_id`, `receiving_operation_id`, receipt document path, `payment_id` and `journal_entry_id`; reuse these rather than invent parallel receipt/expense storage.
- `stock_vouchers` already has `custodian_user_id`, supplier return contract fields, optional PO/invoice references, return-currency and tax/value fields.
- `stock_voucher_details` already has gross/discount/tax/net values, tax code and received quantity. Supplier accepted quantity must not be conflated with generic `received_qty`.
- Current `purchase_returns_status_check` allows exactly `Draft`, `Posted`, `Cancelled`.
- Existing DirectSale/DirectReturn custodian constraint and Transfer vehicle/driver constraint are still in force.
- Production helper `app_private.current_user_has_effective_permission(text)` exists as a SECURITY DEFINER SQL function and calls `get_my_effective_profile()`. It is present for the proposed SELECT RLS policy.
- The complete live column/constraint snapshot is in the source review evidence; no Production write was made.

---

## 3. First SQL scaffold review — defects requiring correction

The file `01_buyer_goods_custody_schema_security_DRAFT.sql` is useful as a first outline but must not be run. This review identified:

1. **Unconditional `purchase_invoice_id DROP NOT NULL`:** the first draft makes stand-alone return headers possible before all existing functions, views and consumers are scanned for that non-null assumption. The reviewed v2 leaves this constraint unchanged. A future nullable-invoice migration must be a separate gated change with a documented dependency scan and migration precondition.
2. **Destructive status constraint replacement:** the first draft replaces `purchase_returns_status_check` with a different allowed-value set. Existing Parent/RPC consumers expect Draft/Posted/Cancelled. The reviewed v2 preserves the current constraint and adds separate `physical_status` and `financial_status` dimensions.
3. **Recipient mode on every voucher:** the first draft adds `recipient_mode NOT NULL DEFAULT 'SUPPLIER_DIRECT'`, which incorrectly assigns SupplierReturn semantics to unrelated Transfer/DirectSale/DirectReturn/Scrap voucher types. The reviewed v2 leaves it NULL for non-SupplierReturn types and validates it only for SupplierReturn.
4. **Missing Buyer delegation proof:** the first draft has no mandatory supplier delegation reference/evidence check for Buyer Delegate. The reviewed v2 adds explicit reference and private evidence-path columns and a mode/custodian consistency check.
5. **Duplicate acceptance counters:** the first draft adds supplier accepted/returned totals to stock voucher details and also adds an acceptance event table. That creates two mutable sources of truth. The reviewed v2 keeps only the immutable issued quantity on the stock voucher line; accepted quantities come from acceptance detail events and are projected to Parent through the linked return case.
6. **Incorrect source vocabulary:** the first draft used `BUYER_CASH_CUSTODY` rather than the owner-agreed settlement source `EMPLOYEE_CUSTODY`, and omitted `TREASURY_CASH`. The reviewed v2 uses `SUPPLIER_CREDIT`, `EMPLOYEE_CUSTODY`, and `TREASURY_CASH`, with `UNSET` for historical unclassified rows.
7. **Missing responsible purchaser and cash-custody link:** the first draft did not preserve the Buyer user on the invoice or identify the existing cash custody when employee-custody settlement is chosen. Reviewed v2 adds nullable `purchaser_user_id` and `buyer_custody_id`.
8. **Missing rejected/partial detail:** the first draft's acceptance details captured accepted quantity only. Reviewed v2 adds rejected quantity and rejection reason; physical return-to-warehouse remains a separately documented handover/stock event.
9. **Missing signed-event invariants:** the first draft accepted any nonzero signed delta for every custody event type. Reviewed v2 adds a sign check so inbound events are positive, outbound events negative and only correction events may use either sign.
10. **Incomplete ACL revocation:** the first draft omitted explicit revoke from `PUBLIC`. Reviewed v2 revokes PUBLIC, anon and authenticated and then restores authenticated SELECT only.
11. **No currency contract:** the first draft does not remove the hardcoded SAR behavior from the live Voucher UI or force new contracts to read `app_settings.currency`. That must be implemented in the existing RPC/Trigger and Vouchers contract patch; do not silently change legacy values.
12. **No complete server writers:** neither SQL draft includes the required atomic RPC/Trigger bodies. Neither may be executed as a migration by itself.

Reviewed v2 path:
`Current/CTO/ChangeSets/20261104/02_buyer_goods_custody_schema_security_REVIEWED_DRAFT.sql`.

### Remaining explicit limits in v2

- It intentionally does not drop `purchase_returns.purchase_invoice_id NOT NULL`.
- It does not replace the existing return status constraint.
- It does not set a hardcoded new currency default; all new SupplierReturn writes must get currency from the system-setting RPC.
- Some foreign keys are added NOT VALID to allow a future controlled validation step without implicitly scanning/rewriting old records. The final migration must decide when to validate them after proving historical data.
- It does not create/replace business RPCs, stock movement writers, acceptance posting, Edge handlers or application source.
- It does not settle the account mapping for a refund/credit created by returning goods originally paid from employee cash. That mapping remains a Finance configuration dependency.

---

## 4. Receiver surgical patch — completed owner-side patch specification

Current Receiver source has:
- `App.purchaseOrders` already available.
- `loadPurchaseOrders()` selects `po_code, po_date, supplier_name, status, total_amount` without the header UUID.
- `loadPODetails()` queries `purchase_order_details.eq('po_code', code)`, but Production detail table has only `po_id`.
- The query omits `qty_received`; UI therefore shows ordered quantity instead of remaining quantity.
- It reveals the Receive button even when the query returns no remaining lines or the query itself fails.
- Quantity entry uses `parseInt`, so fractional units are silently truncated.
- Submission sends all lines even if zero and gives no client operation ID; server fallback deterministic key can collide for a separate future physical receipt with identical lines.

### 4.1 PO list query

Replace only the select list:
```js
supabase.from('purchase_orders')
  .select('id, po_code, po_date, supplier_name, status, total_amount')
```

The existing list already stores the result in `this.purchaseOrders`, so the exact PO UUID can be resolved in `loadPODetails`.

### 4.2 Safer replacement for loadPODetails

The earlier Report616 replacement is updated here to escape all DB-supplied text before placing it into an HTML string. It also hides the Receive button on any lookup failure, empty remaining quantity or missing PO header.

```js
loadPODetails: function(i, code){
    var po = (this.purchaseOrders || []).find(function(x){
        return String(x.po_code) === String(code);
    });
    var host = RW_UI.byId('details-' + i);
    var btn = RW_UI.byId('btn-rec-' + i);

    function esc(value){
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    if (btn) btn.classList.add('hidden');
    if (!host) return;

    if (!po || !po.id) {
        RW_UI.safeHTML(host,
            '<p class="text-red-600 text-center py-4">تعذر تحديد أمر الشراء. أعد تحميل القائمة.</p>');
        return;
    }

    RW_UI.safeHTML(host,
        '<div class="text-center py-4"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</div>');

    supabase.from('purchase_order_details')
        .select('item_code, item_name, qty_ordered, qty_received, unit')
        .eq('po_id', po.id)
        .order('item_code', {ascending:true})
        .then(function(r){
            if (r.error) {
                RW_UI.safeHTML(host,
                    '<p class="text-red-600 text-center py-4">فشل تحميل بنود أمر الشراء: ' +
                    esc(r.error.message || 'خطأ غير معروف') + '</p>');
                return;
            }

            var rows = Array.isArray(r.data) ? r.data : [];
            var items = rows.map(function(it){
                var ordered = Number(it.qty_ordered || 0);
                var received = Number(it.qty_received || 0);
                return {
                    item_code: it.item_code,
                    item_name: it.item_name,
                    unit: it.unit,
                    remaining: Math.max(0, ordered - received)
                };
            }).filter(function(it){
                return Number.isFinite(it.remaining) && it.remaining > 0;
            });

            if (!items.length) {
                RW_UI.safeHTML(host,
                    '<p class="text-slate-400 text-center py-4">لا توجد كميات متبقية للاستلام في هذا الأمر.</p>');
                return;
            }

            var html = '';
            for (var j = 0; j < items.length; j++) {
                var it = items[j];
                html += '<div class="flex justify-between items-center p-3 border-b"><div><p class="font-bold">' +
                    esc(it.item_name) +
                    '</p><p class="text-xs text-slate-400">' +
                    esc(it.item_code) + ' | المتبقي: ' + esc(it.remaining) + ' ' + esc(it.unit || 'حبة') +
                    '</p></div><input type="number" id="qty-' + i + '-' + j +
                    '" value="' + esc(it.remaining) + '" min="0" max="' + esc(it.remaining) +
                    '" step="0.001" class="w-24 p-2 border rounded-xl text-center font-bold text-sm" data-item-code="' +
                    esc(it.item_code) + '"></div>';
            }

            RW_UI.safeHTML(host, html);
            if (btn) btn.classList.remove('hidden');
        })
        .catch(function(err){
            RW_UI.safeHTML(host,
                '<p class="text-red-600 text-center py-4">تعذر الاتصال ببيانات بنود أمر الشراء.</p>');
            console.error('[Receiver] loadPODetails failed:', err);
        });
},
```

### 4.3 Decimal validation and operation identity

Replace `parseInt` with:
```js
var q = Number(qtyInputs[j].value);
var max = Number(qtyInputs[j].max);
if (!Number.isFinite(q) || q < 0 || q > max) {
    RW_UI.toast('راجع الكمية المستلمة؛ يجب أن تكون بين صفر والكمية المتبقية.', 'warning');
    return;
}
if (q === 0) continue;
```

After the loop, reject empty positive lines before asking for confirmation.

**Operation identity:** for each new physical receipt, generate a new UUID and persist it with a fingerprint of PO ID + submitted line quantities under a company/user/PO-scoped localStorage key until success is confirmed. If the network response is ambiguous, an exact retry reuses the same UUID. If a user changes the quantity payload, generate a new UUID. After confirmed success, remove the stored key. This prevents the deployed Edge fallback from reusing one deterministic ID for two separate physical receipts with identical payloads.

The server `receive_purchase_atomic` must still reject an all-zero receipt before inserting a Receiving header. UI validation alone is not sufficient.

### 4.4 Receiver patch tests

- PO UUID selected and detail relation is `po_id`.
- Full PO receive.
- Partial receive, reopen, and display only the unreceived remainder.
- Decimal 1.250 is not truncated.
- Zero line is omitted.
- Negative, NaN, Infinity and above-remaining values rejected.
- All-zero submission rejected in the browser and in the atomic RPC.
- Retry with same physical receipt ID returns duplicate and no second stock movement.
- A separate later receipt with the same quantities receives a different ID.
- Query error/empty data never exposes the Receive button.
- DB-supplied item values are HTML-escaped.
- Branch scope and Receiving-role checks remain enforced by server code.

**No Receiver source was edited.** This is the exact owner-side change specification.

---

## 5. Canonical lifecycle and one-writer rule

### 5.1 Supplier Direct (default)

- Default `recipient_mode='SUPPLIER_DIRECT'`.
- The physical quantity issued from the warehouse is the quantity the supplier actually accepts at the warehouse handover.
- Branch stock decreases once at this handover; supplier acceptance evidence is attached to the same handover/acceptance batch.
- No Buyer goods-custody event exists for direct Supplier receipt.
- AP/GL/tax reversal is posted once for the accepted amount and accepted tax only.
- If the supplier refuses any goods, those goods are not included in issued/accepted quantity; they stay in warehouse stock until accepted/reissued.

### 5.2 Buyer Delegate

- `recipient_mode='BUYER_DELEGATE'` is allowed only with explicit supplier delegation reference and secure evidence path.
- The selected user must be active, same company, valid Buyer/Purchasing role, and within allowed branch scope.
- At actual warehouse handover: branch stock decreases once and Buyer goods-custody quantity increases by the same issued quantity in the same transaction.
- No supplier AP/GL/tax effect at dispatch.
- Later supplier acceptance batch records accepted and rejected quantity per voucher line, with signed supplier receipt/credit-note proof.
- Accepted quantity decreases Buyer custody and posts Supplier AP/GL/tax only for the accepted amount. Unaccepted goods stay in Buyer custody.
- If Buyer physically returns goods to warehouse, that is another documented physical event: Buyer custody out and warehouse stock in once. Use an existing movement type only after validating its actual mapping in `post_stock_movement`; do not invent a movement name or post stock directly.

### 5.3 Parent Return register

- Keep `purchase_returns` as the Parent financial return register.
- Link each new manual physical SupplierReturn voucher to exactly one Parent return case with a unique FK.
- Parent recipient comes from the linked voucher: Supplier for Direct; Buyer user for Delegate.
- Do not duplicate recipient/custodian state in two headers.
- For linked cases, `purchase_post_return_atomic` must not call `post_stock_movement` again.
- The manual voucher send remains the single branch-stock-out writer; supplier acceptance batch remains the single AP/GL/tax writer.
- Existing unlinked legacy return cases retain their prior writer only until reconciliation and controlled cutover. Do not mass-link or repost old records without evidence.
- The Parent `main.html` column remains owner-side because the source lock is active.

---

## 6. Quick Market and cash custody — one financial counter-entry

### 6.1 Quick Market

1. Buyer creates a Draft invoice with `purchase_source='QUICK_MARKET'`, explicit `settlement_source`, purchaser, branch, supplier, actual price, invoice number/date and document evidence.
2. Draft has no stock, supplier ledger, AP/GL, Treasury or cash-custody settlement effect.
3. Supplier physically hands goods to Buyer; record supplier-to-Buyer custody event only at the actual handover.
4. Receiver searches by RAWAEA invoice code or supplier invoice number, sees remaining invoice-line quantities and captures accepted/rejected quantity, branch and receipt evidence.
5. Accepted quantity leaves Buyer custody and enters branch stock once. Rejected quantity remains in Buyer custody unless separately returned to Supplier/warehouse.

### 6.2 Financial source

- `SUPPLIER_CREDIT`: accepted receipt recognizes Supplier AP once; actual payment is separately documented.
- `EMPLOYEE_CUSTODY`: if supplier has already been paid from the Buyer’s cash advance, accepted inventory must be capitalized against Employee Custody (DR Inventory / CR Employee Custody), not the PO Supplier AP path; do not create a second Supplier AP or supplier payment.
- `TREASURY_CASH`: Treasury is affected only by the actual payment event with its receipt/instrument evidence.
- Fuel/Transport/Other expense categories require an active Finance-approved expense account; no inventory movement or supplier AP by default.
- Cash-paid goods later returned by the supplier may create a refund receivable, credit for future purchase or actual cash refund; the current COA mapping is not confirmed. Do not invent the account or debit Supplier AP if no AP was created.
- Existing `buyer_custody_review_expense_atomic` remains the PO supplier-credit settlement route. Add a distinct Quick Market invoice-ID branch; do not rewrite the PO branch's behavior.
- Existing `receive_purchase_atomic` posts accepted PO receipt as DR Inventory 124 / CR Supplier AP 211 and supplier_ledger credit. Quick Market employee-custody cannot reuse that AP branch.

---

## 7. Security and migration review

### 7.1 Direct-write return table security

Current direct DML grants and PUBLIC ALL RLS policies remain a confirmed P0. The reviewed SQL v2 explicitly revokes all privileges from PUBLIC, anon and authenticated, then grants authenticated SELECT and adds SELECT-only company/permission policies. Existing server-owned SECURITY DEFINER/Edge writers must be verified to continue functioning.

Test with real JWT contexts:
- anon SELECT/INSERT/UPDATE/DELETE denied;
- authenticated Buyer SELECT only within company and permission;
- authenticated direct INSERT/UPDATE/DELETE denied;
- Finance/Procurement Edge writer succeeds after the ACL change;
- service role and SECURITY DEFINER RPC continue to operate.

### 7.2 Critical migration guards

- Recheck active return rows immediately before migration.
- Do not drop the existing purchase-return invoice FK / NOT NULL in this change.
- Do not alter existing purchase_returns.status check; the new physical and financial statuses remain separate.
- Do not change historic SAR documents or system currency values.
- Verify all foreign keys against existing rows before validating NOT VALID constraints.
- Do not publish new tables to Realtime until RLS, role scopes, and subscription filters are tested.
- Existing `app_private.current_user_company_id()` and `app_private.current_user_has_effective_permission(text)` were confirmed present in Production. The latter calls `get_my_effective_profile()`.
- Private evidence paths must use an explicit procurement prefix and company/role checks. Do not store delegation or signed supplier acceptance evidence in public product-images.

### 7.3 Migration transaction and rollback

The reviewed schema file is wrapped in a transaction. It must be applied only in a schema-parity isolated environment first. A rollback script must remove newly added objects/columns only before any live custody/acceptance rows exist. After real events exist, corrections must be compensating events and accounting reversals; never drop the event history.

---

## 8. E2E acceptance matrix — required

1. Supplier Direct: branch dispatch quantity equals supplier handover accepted quantity; no Buyer custody; one stock-out; one AP/GL/tax posting.
2. Buyer Delegate: supplier delegation mandatory; branch stock-out once + Buyer custody in once; no AP/GL until Supplier acceptance; partial accept out of Buyer custody and AP/GL only by accepted quantity.
3. Buyer return to warehouse: custody out once + branch stock in once; supplier AP unchanged.
4. Quick Market Draft: zero effects; supplier-to-Buyer physical handover creates custody only; Receiver finds invoice and records partial accepted/rejected; stock increases only accepted quantity.
5. Employee Custody cash: accepted receipt settles Inventory against Employee Custody with no Supplier AP/payment duplicate.
6. Supplier Credit: AP created once on accepted receipt; Treasury only on actual payment.
7. Operating expenses: Finance-mapped expense account only, no stock/AP by default.
8. Two old Posted SAR invoices: totals and movements/journal/ledger remain unchanged; no retro-conversion.
9. QA-SR Draft PO/invoice: all old document links and status history remain intact. No hard delete; any cancel/archive uses approved writer and must prove no stock/AP/GL effect.
10. Cumulative supplier return: multiple draft/dispatched/accepted cases cannot exceed invoice actual received quantity; concurrent creation serialized.
11. Same operation ID + same payload is idempotent; same operation ID + changed payload fails.
12. Return-table anon/direct DML denied; role-scoped SELECT still works.
13. Receiver PO partial + decimal regression; all-zero request rejected before Receiving header.
14. Existing Transfer / DirectSale / DirectReturn / PO receiving / cash custody regression passes unchanged.
15. Inventory, custody events, Supplier Ledger, tax transactions, balanced journals and cash custody reconcile exactly.

Test environment remains a prerequisite: current Staging is not schema-parity. No persistent Production fixtures are allowed.

---

## 9. Status, approval boundary and next work unit

**Prepared in this turn**
- Reviewed LVE616 Report616 and its SQL scaffold.
- Revalidated exact Receiver source and confirmed `purchaseOrders` already exists on the application object.
- Prepared a safer Receiver patch specification that also escapes HTML values, hides Receive on errors/empty lines, validates remaining quantity and persists a retry identity.
- Prepared `02_buyer_goods_custody_schema_security_REVIEWED_DRAFT.sql` with the above schema corrections.
- Revalidated the RLS helper functions in Production.
- No operational app or Production writes.

**Still not implemented**
- Full replacement Trigger `enforce_stock_voucher_custodian()`.
- Full create/update/send/complete/accept/return-to-warehouse RPC bodies, preserving existing DirectSale/DirectReturn and legacy return contracts.
- Cumulative return locking and single-writer purchase_post_return_atomic branch.
- Full invoice-ID Quick Market receive RPC/Edge behavior and category-aware cash-custody Finance review branch.
- Buyer/Vouchers/Receiver runtime source changes and Parent owner-side patch.
- Signed-in Browser E2E, schema-parity integration tests and deployment verification.

**Next coherent implementation unit:** author the full SQL/function bodies and the existing Edge/app diffs against the exact archived source snapshots. Do not split into disconnected patches. Submit the exact change set, its impacts, E2E and rollback plan for explicit owner approval under §77.2 before Production or operational app writes. No questions are needed for decisions already recorded in Report606.
