# Report617 — Warehouse SupplierReturn Recipient & Currency Surgical Change Set

**Date:** 2026-11-04 — Africa/Cairo  
**Baseline:** Report615 / Report616; operational Vouchers blob `85e709d0f41c189c6624a6160965d3b1a41960ba`.  
**Status:** EXACT UI/DB CHANGE DESIGN PREPARED / NOT APPLIED / NO PRODUCTION WRITES.

## 1. Critical currency finding — impact now CONFIRMED

Production facts:
- `app_settings.currency = 'EGP'`.
- `stock_vouchers.return_currency` has `DEFAULT 'SAR'`.
- Warehouse Vouchers UI initializes the SupplierReturn contract with SAR and submits SAR in its payload.
- `save_supplier_return_contract` accepts the contract currency and uses SAR as its fallback; it does not validate the currency against `app_settings`.
- `complete_manual_stock_voucher_atomic_core_20260828` references `return_total_amount` but has **zero references to `return_currency`**.
- `purchase_post_return_atomic` also has **zero references to `return_currency`**.

Therefore the currency is not merely a display inconsistency: the current financial posting paths use the numeric return total without currency conversion or currency validation. A SupplierReturn contract amount labelled SAR can be posted directly into the EGP supplier ledger and GL as if it were the company base currency.

**Classification:** P0 financial correctness risk. No SupplierReturn rows existed in the Production snapshot, so no existing SupplierReturn posting was changed.

Required fix:
1. Resolve company currency from the canonical `app_settings` row inside `save_supplier_return_contract`.
2. Reject a client-supplied currency that differs from system currency; never fall back to SAR.
3. Remove the `SAR` column default; let the server-side contract/Trigger set the company currency.
4. Add a SupplierReturn Trigger guard that enforces the current company currency.
5. Financial posting functions must validate that the stored voucher currency equals the company currency before writing supplier ledger/GL. Do not silently convert or rewrite historical documents.

---

## 2. Current Vouchers UI facts

File: `companies/company-1/warehouse/vouchers.html`.

- `loadRefs()` loads active users with role `مندوب بيع مباشر` into `refs.reps`; no Purchasing Officer list is loaded.
- Initial `refs` object must add `buyers:[]`. Append the new Purchasing Officer query as the final entry in the existing `Promise.all` list, then assign `s.refs.buyers=r[7]||[]`; do not insert it before the existing return-reason/tax-code queries or their indexes will shift.
- `pickArr('wsRep')` returns `refs.reps`, with mobile-sales vehicle assignment rules for DirectSale/DirectReturn.
- SupplierReturn `routeHtml()` displays only Source Branch + Supplier + return contract button. It has no recipient mode or Purchasing Officer picker.
- `submit()` already reads `wsRep` into `rep` and passes `rep_id` to the existing `create-stock-voucher` Edge function. That Edge v12 maps `rep_id` to `p_rep_id` for the existing atomic RPC.
- Existing stock-voucher rows store `custodian_user_id`, but the current Trigger strips it for SupplierReturn.
- Voucher list/detail displays custodian only for DirectSale/DirectReturn; SupplierReturn will not show the Buyer recipient without a UI change.

---

## 3. Exact surgical UI design

### 3.1 Load Purchasing Officers without changing Sales Rep rules

In `loadRefs()`, add a separate paginated query alongside the existing `users.role='مندوب بيع مباشر'` query:

```js
readAll(function(){
    return supabase
        .from('users')
        .select('id,name,email,phone,role,status,default_branch_id,allowed_branch_ids')
        .eq('company_id',s.company)
        .eq('status','Active')
        .eq('role','مسئول مشتريات')
        .order('name')
        .order('id');
}),
```

Store its result in a separate `s.refs.buyers` array. Do not append Purchasing Officers to `s.refs.reps`; that array is part of the existing mobile-sales vehicle-assignment contract.

### 3.2 Reuse the existing searchable `wsRep` control only for the Buyer Delegate mode

Inside `pickArr(key)`, in the existing `if(key==='wsRep')` branch, add an early SupplierReturn branch:

```js
if(s.type==='SupplierReturn'){
    return (s.refs.buyers||[]).filter(function(buyer){
        return !!buyer &&
            buyer.status==='Active' &&
            buyer.role==='مسئول مشتريات' &&
            !!b &&
            s.allowedBranch(s.user,b) &&
            s.allowedBranch(buyer,b);
    });
}
```

This keeps the existing DirectSale/DirectReturn rep list and fleet checks untouched.

### 3.3 SupplierReturn route UI

Keep Source Branch and Supplier as mandatory fields. Add:
- Recipient selector, default `SUPPLIER_DIRECT`.
- `BUYER_DELEGATE` exception option.
- Existing searchable `wsRep` picker displayed only for Buyer Delegate and labelled `مسؤول المشتريات المستلم`.
- No Vehicle field and no fleet assignment dependency.

Proposed route fragment:

```js
'<div class="sm:col-span-2">'+
  '<label class="block text-xs font-bold mb-2">المستلم الفعلي</label>'+
  '<select id="wsRecipientMode" onchange="App.onSupplierReturnRecipientChange(this.value)" class="w-full p-3 rounded-xl border bg-white">'+
    '<option value="SUPPLIER_DIRECT" selected>المورد — الاستلام المباشر (القاعدة)</option>'+
    '<option value="BUYER_DELEGATE">مسؤول المشتريات — استلام بعهدته</option>'+
  '</select>'+
'</div>'+
'<div id="wsBuyerRecipientWrap" class="sm:col-span-2 hidden">'+
  '<label class="block text-xs font-bold mb-2">مسؤول المشتريات المستلم</label>'+
  p('wsRep','ابحث باسم مسؤول المشتريات أو بريده')+
'</div>'+
```

Add `onSupplierReturnRecipientChange(mode)`:
- show the Buyer picker only for `BUYER_DELEGATE`;
- clear `wsRep` on switching back to Supplier Direct;
- never clear supplier or source branch.

### 3.4 Submit validation

Before calling the existing Edge function:
- For Supplier Direct, set `rep_id=null`.
- For Buyer Delegate, require the selected `wsRep` to exist in `refs.buyers`, be active, have exact role `مسئول مشتريات`, belong to the same company, and pass `allowedBranch(buyer, sourceBranch)`.
- Pass the selected user ID in the existing `rep_id` property. The deployed `create-stock-voucher` v12 already forwards this property as `p_rep_id`; no new Edge function is needed.
- The server RPC must derive/store `recipient_mode='BUYER_DELEGATE'` when a valid Purchasing Officer is supplied; otherwise `SUPPLIER_DIRECT`.
- Client validation is UX only; the database Trigger/RPC remains authoritative.

### 3.5 Edit/list/detail preservation

- When opening a SupplierReturn Draft for edit, set `wsRecipientMode` from the persisted `recipient_mode` and restore `custodian_user_id` into `wsRep` using `refs.buyers`.
- Do not clear the Buyer selection in the generic non-DirectSale/non-DirectReturn edit branch.
- Voucher cards and detail modal must resolve SupplierReturn `custodian_user_id` against `refs.buyers` and display it as `المستلم / مسؤول المشتريات`.
- Supplier Direct should display `المورد مباشرة`, not a blank custodian or the creator.
- Vehicle remains `—` for both SupplierReturn modes.

---

## 4. Exact database contract for this UI

### Trigger `enforce_stock_voucher_custodian()`

Preserve the existing DirectSale/DirectReturn behavior and all fleet assignment requirements. Add one SupplierReturn branch:
- `SUPPLIER_DIRECT`: require `custodian_user_id IS NULL`.
- `BUYER_DELEGATE`: require active same-company user, exact role `مسئول مشتريات`, effective purchases permission, valid source branch scope; preserve `custodian_user_id`; no vehicle required.
- Reject a custodian for all other voucher types unless their existing contract permits one.
- Reject mismatched recipient_mode/custodian combinations.

### Existing create/update atomic RPCs

- Existing Edge v12 already passes `p_rep_id`; do not create another Edge function.
- For SupplierReturn only, interpret `p_rep_id` as the Buyer custodian when recipient mode is Buyer Delegate.
- Persist `recipient_mode` and `custodian_user_id` atomically.
- Update Draft RPC must preserve the same rule; posted documents cannot change recipient.
- Keep all existing DirectSale/DirectReturn `p_rep_id` behavior unchanged.

### Currency

- `save_supplier_return_contract` must select system currency from `app_settings` for `p_company_id` and use that value only.
- `stock_vouchers.return_currency` default must not be SAR; server must set it to company currency.
- Trigger and both financial posting paths must reject a currency mismatch.
- Do not use a client-supplied exchange rate or perform silent conversion.

---

## 5. Required end-to-end tests

1. Supplier Direct default creates voucher with null custodian and no vehicle dependency.
2. Buyer Delegate shows only active Purchasing Officers within source branch scope.
3. Selecting Buyer stores the correct `custodian_user_id`; Buyer sees the resulting quantity in `رصيدي` after the dispatch event.
4. Changing recipient mode back to Supplier clears the Buyer selection.
5. Draft edit preserves recipient mode and custodian; posted voucher recipient cannot be changed.
6. DirectSale/DirectReturn rep-to-vehicle validation remains unchanged.
7. Invalid/inactive/cross-company/non-purchasing custodian is rejected by server RPC/Trigger even if client is manipulated.
8. Currency UI reads EGP from app settings; browser cannot submit SAR.
9. Contract save and completion both reject any stored currency differing from company currency.
10. GL and supplier ledger amounts reconcile in company currency with accepted quantity only.

---

## 6. Status and execution boundary

- Recipient UI patch: exact design prepared; not applied.
- Trigger/RPC change: not applied.
- Currency fix: root cause and financial impact confirmed; not applied.
- No SQL/Production/Edge/operational source writes.
- This report is a surgical patch specification; it is not a deployment approval.
- The full goods-custody and single-writer return lifecycle remains subject to the exact complete change-set gate in Report614_NEW_P / Master CTO §77.2.
