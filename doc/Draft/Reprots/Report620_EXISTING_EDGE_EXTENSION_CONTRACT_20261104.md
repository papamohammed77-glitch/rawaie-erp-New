# Report620 — Existing Edge Function Extension Contract (No New Functions)

**Date:** 2026-11-04 — Africa/Cairo  
**Baseline:** Exact deployed snapshots archived under `Current/CTO/EdgeSnapshots/20261104/`.  
**Status:** EDGE PATCH CONTRACT PREPARED / NO DEPLOYMENT.

## 1. Existing Edge functions and roles

### `save-purchase-order` v22

Current permission gate:
- `POST_INVOICE`, `POST_PAYMENT`, `POST_RETURN`: require purchases + finance.
- `REVIEW_CUSTODY_EXPENSE`: finance or finance_manager.
- `SUBMIT_CUSTODY_EXPENSE`, `ACKNOWLEDGE_CUSTODY`: purchases, finance or finance_manager.
- `GET_CUSTODY`: purchases, finance or finance_manager.
- default operations: purchases.

Add these operation branches without altering existing ones:
| Operation | Permission | RPC | Client |
|---|---|---|---|
| `GET_BUYER_GOODS_CUSTODY` | purchases / finance / finance_manager / reports | `get_my_buyer_goods_custody` | `profileClient` |
| `GET_BUYER_CUSTODY_MOVEMENTS` | same | `get_my_buyer_goods_custody_movements` | `profileClient` |
| `RECORD_QUICK_MARKET_HANDOVER` | purchases | `record_quick_market_handover_atomic` | `profileClient` |
| `CREATE_BUYER_CUSTODY_HANDOVER` | purchases | `create_buyer_custody_handover_atomic` | `profileClient` |
| `CREATE_RETURN_ACCEPTANCE` | purchases | `record_supplier_return_acceptance_atomic` | `profileClient` |
| `POST_RETURN_ACCEPTANCE` | purchases + finance | `purchase_post_return_acceptance_atomic` | `profileClient` |
| `RETURN_BUYER_CUSTODY_TO_WAREHOUSE` | purchases | `create_buyer_custody_handover_atomic` | `profileClient` |

Security:
- use `profileClient` for every new user-context RPC so `auth.uid()` and effective profile remain available;
- do not pass client-supplied actor/company identity as authority;
- company comes from validated profile;
- keep existing service-role calls only for operations whose existing SQL contract explicitly uses verified user email and company;
- do not add direct table insert/update endpoints.

### `receive-purchase` v13

Current input contract requires `po_code` and `itemsReceived`; it calls `receive_purchase_atomic` through the authenticated profile client and creates a deterministic operation ID.

Add two explicit mutually exclusive modes:
1. Existing PO: `po_code` + `itemsReceived` → existing `receive_purchase_atomic` unchanged.
2. Quick Market invoice: `invoice_id` + `branch_id` + `itemsReceived` → new `receive_quick_purchase_atomic`.
3. Buyer custody handover: `receiving_id` + `itemsReceived` → new `receive_buyer_custody_handover_atomic`.

Validation:
- exactly one of `po_code`, `invoice_id`, `receiving_id` supplied;
- preserve existing JWT/profile/company/branch validation;
- deterministic operation ID includes mode + source ID + normalized line quantities;
- reject mixed or ambiguous mode payloads;
- existing PO request shape and response remain unchanged.

### `create-stock-voucher` v12

The existing Edge already forwards `rep_id` as `p_rep_id` to the atomic voucher RPC. No new Edge function or new parameter is required for Buyer Delegate if the SQL create/update RPC explicitly interprets `p_rep_id` as a Purchasing Officer only when `type='SupplierReturn'` and `recipient_mode='BUYER_DELEGATE'`.

- Supplier Direct sends null rep_id.
- Buyer Delegate sends selected Purchasing Officer ID.
- SQL Trigger/RPC validates role, company, active status and branch.
- DirectSale/DirectReturn use of rep_id remains unchanged.
- Existing create Edge currently has `verify_jwt=false` but validates the Bearer token with `auth.getUser`; do not change this setting without testing all existing callers.

### `send-stock-voucher` v20

No new Edge function. Preserve current request shape and existing authenticated profile checks. Extend the called SQL atomic function so SupplierReturn:
- posts actual issued quantity once;
- inserts Buyer custody event atomically for Buyer Delegate;
- inserts no Buyer event for Supplier Direct;
- never posts supplier AP/GL at dispatch.

All other voucher types retain current behavior.

### `complete-stock-voucher` v4

No new Edge function. The linked SupplierReturn completion branch must:
- validate physical resolution of issued quantity (supplier accepted or warehouse returned);
- mark physical voucher status only;
- not write supplier ledger or GL if a linked purchase_returns case exists;
- preserve legacy unlinked completion path until reconciled.

Financial posting is a separate `POST_RETURN_ACCEPTANCE` operation requiring purchases + finance.

## 2. Currency hardening in existing Edge

Current `save-purchase-order` v22 `getSystemCurrency()` falls back to EGP if app_settings.currency is missing. Change it to fail closed:
- missing/blank currency → `SYSTEM_CURRENCY_NOT_CONFIGURED`;
- non-ISO 3-letter value → `SYSTEM_CURRENCY_INVALID`;
- never accept a client-supplied return currency.

Existing Buyer invoice builder already reads `GET_SETTINGS` and validates a 3-letter currency; keep that behavior.

## 3. Compatibility matrix

| Existing workflow | Required outcome |
|---|---|
| Purchase Request / RFQ / Quotation / PO | unchanged |
| PO-linked invoice Draft / post | unchanged |
| PO Receiving by `po_code` | unchanged request and RPC |
| PO Buyer cash-custody expense | unchanged validations and accounting |
| DirectSale / DirectReturn | unchanged vehicle/rep enforcement |
| Warehouse Transfer | unchanged |
| SupplierReturn Supplier Direct | default; no Buyer custody |
| SupplierReturn Buyer Delegate | new custodian and custody event |
| Quick Market invoice-ID receipt | new branch only |
| Buyer custody return-to-warehouse | new branch only |

## 4. Deployment sequence after exact approval

1. Apply additive schema and least-privilege migration in approved environment.
2. Deploy/replace RPCs and Trigger in dependency order.
3. Update existing Edge source only; no new Edge function.
4. Run unit/SQL idempotency and RLS JWT tests.
5. Apply Buyer/Vouchers/Receiver source patches.
6. Run full E2E and ledger reconciliation.
7. Deploy existing Edge versions and Cloudflare artifact only after all tests pass.
8. Verify production source/deployed Edge hashes, browser runtime and cross-app Realtime.
9. Rollback through additive migration rollback before real events; after real events, use compensating inventory/custody/AP/GL entries, never delete posted rows.

## 5. Status

Exact deployed Edge source snapshots are available and parity is no longer a blocker. This report defines extension contracts only; it does not contain a full edited Edge source diff or a deployment. No Edge function was deployed or created.
