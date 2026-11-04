# Report616 — Surgical Receiver Fix + Buyer Custody Schema Draft Package

**Date:** 2026-11-04 — Africa/Cairo  
**Purpose:** turn LVE615 findings into exact, reviewable patches without modifying operational source or Production.  
**Status:** PATCH PREPARATION ONLY / NOT APPLIED / NOT APPROVED FOR EXECUTION.

## 1. Receiver surgical patch — exact current defect

Current file: `companies/company-1/warehouse/receiver.html`  
Current blob: `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`.

### 1.1 Add the PO primary key to the list query

Current:
```js
supabase.from('purchase_orders').select('po_code, po_date, supplier_name, status, total_amount')
```

Replace only the select list:
```js
supabase.from('purchase_orders').select('id, po_code, po_date, supplier_name, status, total_amount')
```

Reason: the selected row must carry the UUID `id` used by `purchase_order_details.po_id`.

### 1.2 Replace the detail query and remaining-quantity calculation

Current method uses `.eq('po_code', code)` against `purchase_order_details`. Production schema has no `po_code` column on this table; it has `po_id`.

Replace only the `loadPODetails` method with:

```js
loadPODetails: function(i, code){
    var self = this;
    var host = RW_UI.byId('details-' + i);
    var btn = RW_UI.byId('btn-rec-' + i);
    var po = (this.purchaseOrders || []).find(function(x){
        return String(x.po_code) === String(code);
    });

    if (!po || !po.id) {
        if (btn) btn.classList.add('hidden');
        RW_UI.safeHTML(host, '<p class="text-red-600 text-center py-4">تعذر تحديد أمر الشراء. أعد تحميل القائمة.</p>');
        return;
    }

    RW_UI.safeHTML(host, '<div class="text-center py-4"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</div>');
    if (btn) btn.classList.add('hidden');

    supabase.from('purchase_order_details')
        .select('item_code, item_name, qty_ordered, qty_received, unit')
        .eq('po_id', po.id)
        .order('item_code', {ascending:true})
        .then(function(r) {
            if (r.error) {
                RW_UI.safeHTML(host, '<p class="text-red-600 text-center py-4">فشل تحميل بنود أمر الشراء: ' + (r.error.message || 'خطأ غير معروف') + '</p>');
                return;
            }

            var rows = Array.isArray(r.data) ? r.data : [];
            var items = rows.map(function(it) {
                var ordered = Number(it.qty_ordered || 0);
                var received = Number(it.qty_received || 0);
                return {
                    item_code: it.item_code,
                    item_name: it.item_name,
                    unit: it.unit,
                    remaining: Math.max(0, ordered - received)
                };
            }).filter(function(it) {
                return it.remaining > 0;
            });

            if (!items.length) {
                RW_UI.safeHTML(host, '<p class="text-slate-400 text-center py-4">لا توجد كميات متبقية للاستلام في هذا الأمر.</p>');
                return;
            }

            var html = '';
            for (var j = 0; j < items.length; j++) {
                var it = items[j];
                html += '<div class="flex justify-between items-center p-3 border-b"><div><p class="font-bold">' +
                    (it.item_name || '') +
                    '</p><p class="text-xs text-slate-400">' +
                    it.item_code + ' | المتبقي: ' + it.remaining + ' ' + (it.unit || 'حبة') +
                    '</p></div><input type="number" id="qty-' + i + '-' + j +
                    '" value="' + it.remaining + '" min="0" max="' + it.remaining +
                    '" step="0.001" class="w-24 p-2 border rounded-xl text-center font-bold text-sm" data-item-code="' +
                    it.item_code + '"></div>';
            }

            RW_UI.safeHTML(host, html);
            if (btn) btn.classList.remove('hidden');
        })
        .catch(function(err) {
            if (btn) btn.classList.add('hidden');
            RW_UI.safeHTML(host, '<p class="text-red-600 text-center py-4">تعذر الاتصال ببيانات بنود أمر الشراء.</p>');
            console.error('[Receiver] loadPODetails failed:', err);
        });
},
```

### 1.3 Replace integer parsing with decimal-safe validation

Current line:
```js
var q = parseInt(qtyInputs[j].value) || 0;
```

Use:
```js
var q = Number(qtyInputs[j].value);
var max = Number(qtyInputs[j].max);
if (!Number.isFinite(q) || q < 0 || q > max) {
    RW_UI.toast('راجع الكمية المستلمة؛ يجب أن تكون بين صفر والكمية المتبقية.', 'warning');
    return;
}
if (q === 0) continue;
```

The surrounding loop should continue to append:
```js
items.push({ itemCode: itemCode, itemName: '', receivedQty: q, reason: '' });
```

After the loop, before `RW_UI.showConfirm`, add:
```js
if (!items.length) {
    RW_UI.toast('أدخل كمية مستلمة واحدة على الأقل.', 'warning');
    return;
}
```

The existing SQL RPC auto-generates a shortage/overage reason when the supplied reason is empty. It rejects quantities above the remaining ordered amount. The UI must therefore calculate the remaining amount for usability, while the RPC remains the authoritative guard.

### 1.4 Required Receiver regression

- Full PO receipt.
- Partial receipt, then reopen same PO and show only remaining quantity.
- Fractional item quantity, e.g. 1.250.
- Zero quantity line omitted.
- Negative, NaN, Infinity and above-remaining quantity rejected client-side and server-side.
- Duplicate same payload uses the deterministic operation key and returns duplicate success without second stock movement.
- RLS/branch scope: receiving role can receive only assigned branch; unauthorized role rejected.
- Ensure Receiving header/detail, PurchaseIn movement, supplier ledger and balanced journal are created once.

**No Receiver source was changed.**

---

## 2. Security SQL — exact scope and risk

Current Production policies:
- `purchase_returns_company`: PUBLIC / ALL / company-only `USING` and `WITH CHECK`.
- `purchase_return_details_company`: PUBLIC / ALL / parent return company-only `USING`.

Current grants give both `anon` and `authenticated` DML. The DDL draft file below removes these direct write grants and replaces policies with authorized SELECT-only rules.

Draft:
`Current/CTO/ChangeSets/20261104/01_buyer_goods_custody_schema_security_DRAFT.sql`

This file is **not executable as a complete feature migration**. It only contains additive schema/security scaffolding; it intentionally omits the full RPC/Trigger replacement bodies and must not be run by itself.

---

## 3. Business and data contract

### 3.1 Buyer goods custody events

The proposed append-only table records item quantity deltas with:
- company, branch, custodian user, item;
- event type, signed quantity;
- source header and line;
- related document;
- operation ID;
- actor, timestamp, evidence and reversal reference.

Balances are derived from events; never stored as a manually editable number.

### 3.2 SupplierReturn

- Default recipient is Supplier Direct.
- Buyer Delegate requires an active Purchasing Officer, same company, valid permissions and branch scope; no vehicle.
- Warehouse dispatch is the only stock-out writer.
- Supplier acceptance batches are the only supplier AP/GL return writer.
- Linked `purchase_post_return_atomic` must skip stock movement.
- Buyer custody decreases only by supplier-accepted quantity or a separately accepted return-to-warehouse quantity.
- Unaccepted quantity remains in Buyer custody.

### 3.3 Quick Market

- Buyer records physical Supplier → Buyer handover separately from Draft invoice creation.
- Existing `receive-purchase` v13 is extended for `invoice_id` while preserving its `po_code` branch.
- New invoice Receiving header/line links provide traceability.
- Accepted warehouse quantity alone posts PurchaseIn and supplier AP.
- Accounts settlement from cash custody requires the same invoice ID and completed Receiving lines; no PO is required for the Quick Market branch.
- PO-linked custody expense checks remain unchanged.

---

## 4. Remaining exact package components

The following must accompany the DDL draft before approval:
1. Complete replacement body for `enforce_stock_voucher_custodian()`, preserving DirectSale/DirectReturn validation.
2. Complete linked-return-aware body for `send_stock_voucher_atomic_core_20260828`, `complete_manual_stock_voucher_atomic_core_20260828`, and `purchase_post_return_atomic`.
3. New acceptance-batch posting RPC with AP/GL idempotency and no second stock movement.
4. New invoice-ID Quick Market receiving RPC; update existing `receive-purchase` v13 only.
5. Full Quick Market branch in `buyer_custody_review_expense_atomic`, retaining the current PO branch.
6. Currency correction in `save_supplier_return_contract`: read `app_settings.currency` server-side; reject client mismatch; remove SAR fallback.
7. Buyer/Vouchers/Receiver exact source diffs and Realtime changes.
8. Parent `main.html` recipient-column patch proposal remains owner-side only while the governance lock is active.
9. Full RLS negative tests with authenticated JWTs, E2E matrix, transaction rollback, and compensating-event rollback plan.

---

## 5. Status

- Receiver patch: prepared, not applied.
- Security/schema DDL: drafted, not applied.
- RPC/Trigger/Edge/UI full change set: still being assembled.
- Production data: unchanged.
- No test rows created.
- No Edge function deployed or added.
- No operational source modified.
- Not production-ready.
