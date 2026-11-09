# Report668 — Buyer Quick-Market Storage RLS and Supplier Invoice Attachment Recovery

**Date:** 2026-11-09 (Africa/Cairo)  
**Status:** ROOT CAUSE CONFIRMED · PRODUCTION STORAGE POLICIES APPLIED · BUYER ERROR / RETRY FLOW FIXED IN SOURCE · POLICY-SCOPE SIMULATION PASS · AUTHENTICATED BROWSER / CLOUDFLARE PARITY OPEN

## 1. Incident and root cause

Buyer → «فواتيري» → «شراء سوق سريع» saved the invoice draft, then the supplier invoice image upload failed with:

- Storage POST: `new row violates row-level security policy for table "objects"` (PostgreSQL SQLSTATE `42501`, Storage `AccessDenied`).
- Buyer continued to `REGISTER_QUICK_MARKET_ATTACHMENT` despite the failed upload.
- The existing Edge handler then called `storage.info(storagePath)`; no object had been created, so Storage returned `NoSuchKey` / `Object not found`, and Edge returned HTTP 400.

This exact sequence was confirmed in SMART ERP logs, not inferred only from the browser console. On 2026-11-09 at approximately 12:42:57 UTC, the Storage upload request was authenticated as the Buyer user, had `x_upsert=true`, and failed with RLS SQLSTATE 42501. The following service-role `object/info` request for the same exact path returned 404 `NoSuchKey`. Therefore the 400 `Object not found` was the downstream symptom; the first failure was the missing Storage authorization policy.

The bucket `employee-documents` is private. Before the repair, Production had an existing `buyer_goods_docs_select_finance` policy only for finance/finance_manager/owner, but had no Buyer-owner INSERT or UPDATE policy and no Buyer-owner SELECT policy on `buyer-goods`. The owner was a valid active user with effective `purchases` permission, and the invoice was a valid owner-linked `QUICK_MARKET` Draft. The required path structure and ownership match were proven with a simulated authenticated JWT inside a rolled-back SQL transaction.

## 2. Current invoice preservation / recovery

The failed save already created the invoice draft. Read-only Production inspection confirmed:

| Field | Current value |
|---|---|
| Invoice | `PINV-1003` |
| Source / status | `QUICK_MARKET` / `Draft` |
| Received | `false`; `received_date IS NULL` |
| Attachment rows | 0 |
| Storage objects at the failed path | 0 |
| Goods handover events | 0 |
| Linked custody expenses | 0 |

The existing invoice remains safe to reopen and edit. No replacement invoice should be created merely to retry the attachment. The recovery path is to open the existing `PINV-1003` draft in Buyer and attach the supplier invoice again after the updated Buyer artifact is deployed/served.

## 3. SMART ERP Production Storage policy change

Project: `fiilmooggumokxanwiyx`  
Bucket: `employee-documents` (`public=false`).

Three owner-restricted policies were applied directly to `storage.objects`:

1. `buyer_goods_docs_insert_owner` — authenticated INSERT only when the object path has exactly four folders and matches company / internal user ID / `buyer-goods` / QUICK_MARKET invoice ID. The active user must have effective `purchases` permission and be the exact `purchase_invoices.purchaser_user_id`. The invoice must be a Draft, not received, and have no received date.
2. `buyer_goods_docs_select_owner` — allows the exact purchaser to read their own approved evidence path. It is scoped to the same company, internal user, invoice ownership and `QUICK_MARKET` source, but is not restricted to Draft so evidence remains readable after the invoice progresses.
3. `buyer_goods_docs_update_owner` — allows replacement only for `supplier-invoice-*` objects while the same owner-linked invoice remains an unreceived Draft. This is required because the Buyer supplier invoice upload uses `upsert=true`. The update policy has both `USING` and `WITH CHECK`.

The original finance SELECT policy remains intact. No public access, DELETE policy, bucket-public change, direct table DML grant, service-role browser key, new RPC, new Edge Function, or new table was introduced.

### Second Buyer upload path discovered and covered

A repository-wide targeted inspection of current Buyer source found a second legitimate upload under the same `buyer-goods` folder: `recordQuickMarketHandover()` uploads physical handover evidence with `upsert=false`. A policy restricted only to supplier invoice filenames would leave that path broken.

Accordingly:
- INSERT and owner SELECT policies accept exactly two filename families: `supplier-invoice-*` and `handover-<timestamp>_<safe-filename>`.
- UPDATE is still restricted to `supplier-invoice-*` only; handover evidence stays insert-only.
- Buyer now prefixes the handover evidence filename with `handover-` so it can be securely distinguished from supplier-invoice evidence and other files.

All four folder segments, tenant/user identity and invoice ownership remain required. Any other filename family, wrong user, wrong company, wrong invoice, or wrong folder fails the owner predicate.

### Production policy verification

Read-only inspection confirms these current policies exist:

- `buyer_goods_docs_insert_owner` — INSERT
- `buyer_goods_docs_select_finance` — pre-existing SELECT, unchanged
- `buyer_goods_docs_select_owner` — SELECT
- `buyer_goods_docs_update_owner` — UPDATE

The bucket remains private. Simulated authenticated-policy predicates using the actual Buyer auth subject and invoice context returned:
- supplier invoice: INSERT/SELECT allowed; UPDATE allowed for owner Draft;
- handover evidence: INSERT/SELECT allowed; UPDATE denied;
- wrong filename: denied;
- wrong company, user, invoice or folder path: denied.

These tests used SQL transactions with rollback and did not create Storage objects or business rows.

## 4. Surgical Buyer source correction

Operational repo: `papamohammed77-glitch/erp-frontend`, branch `main`.  
Final operational HEAD at verification: `0fe255e3d9dae44332ee1863c43d9c1b0ea0ff79`.  
Final Buyer blob: `c6baf1cdedd4e6f5d219a3c95b6c9450a54dd2d0`.

Two source commits changed only the relevant areas of `companies/company-1/purchasing/buyer.html`:

- `e76592865ef3e11a6fbbe6960655c5ba8e2b2eaf` — fail closed on supplier invoice upload errors; validate the returned attachment identity/path; keep a retryable modal state.
- `539768dcab4f3a47b4512454155fcf1d1c94a7b4` — namespace the separate handover evidence filename with `handover-`.

### Before

The source logged a Storage upload error with `console.warn`, then always invoked `REGISTER_QUICK_MARKET_ATTACHMENT`. That guaranteed a second error when the upload failed and no object existed.

### After

- A Storage upload error now throws immediately; registration is not called.
- The modal displays a message stating that the draft was saved but the file upload did not complete, and explicitly tells the user that no attachment-registration request was sent for a missing object.
- The modal stays open with the file input available for retry.
- The stable `operation_id` and deterministic storage path are reused on retry, so Quick Market invoice creation/update remains idempotent and upsert can safely replace the same supplier invoice file.
- After upload, Buyer calls the existing `REGISTER_QUICK_MARKET_ATTACHMENT` operation.
- Buyer verifies the returned attachment has `success=true`, the same invoice ID, and the same storage path before treating the upload as complete.
- If upload succeeded but attachment registration did not, the error distinguishes that partial state from upload failure and does not close the modal.
- The separate handover evidence uses a `handover-` filename and keeps `upsert=false`.

The existing Edge v37 registration handler, its ownership/path/mime/size checks and the PurchaseAttachment central registration flow were not changed.

## 5. Verification

| Check | Result | Evidence / limit |
|---|---|---|
| Exact Storage root cause | PASS | Production Storage/Postgres logs show upload RLS 42501, then same-path `NoSuchKey`. |
| Exact owner/company/invoice predicate | PASS | Simulated authenticated JWT and rollback-only SQL. |
| Wrong user/company/invoice/folder rejection | PASS | Owner predicate tests all returned false. |
| Supplier-invoice filename permissions | PASS | INSERT/SELECT/UPDATE allowed for owner Draft only. |
| Handover filename permissions | PASS | INSERT/SELECT allowed; UPDATE denied. |
| Other filename rejected | PASS | Predicate false. |
| Private bucket retained | PASS | `storage.buckets.public=false`. |
| Policies re-read from Production | PASS | Three owner policies plus original Finance SELECT policy present. |
| Buyer inline JavaScript parse | PASS | Entire executable inline script compiled. |
| Upload failure stops registration | PASS | Controlled harness injected Storage RLS rejection; no REGISTER API call occurred. |
| Modal retry stays open | PASS | Harness invoked preConfirm again using same modal state. |
| Draft idempotency on retry | PASS | Same operation ID forwarded to create attempt and retry. |
| Retry / attachment registration | PASS | Second upload succeeded; registration invoked exactly once; returned invoice/path matched. |
| Handover filename isolation | PASS | Current Buyer source prefixes handover evidence with `handover-`; upload remains `upsert=false`. |
| Business-data writes | NONE | No invoice, attachment row, Storage object, custody, inventory, supplier, cash-box, treasury, journal or GL row was created by tests. |
| Existing invoice status | PASS / unchanged | `PINV-1003` remains Draft, not received, with no attachments/handover/linked expenses. |
| Authenticated live browser upload | UNVERIFIED | No live browser retry was executed in this session. |
| Cloudflare served artifact parity | UNVERIFIED | GitHub main source re-fetched; terminal Pages build / served byte parity not confirmed. |

## 6. Source SQL record and deployment semantics

Source record:
`supabase/migrations/20261109130000_buyer_goods_supplier_invoice_owner_storage_rls_20261109.sql`

Final migration-source blob:
`88374d3d25f328ad9f5763b04908d1d280599fd1`

This repository file records the exact Production policy definitions. It was not applied through the Supabase migration runner and no migration-history record was created; policies were applied directly through the project's authorized SQL path. Do not run this file via `apply_migration` and do not apply duplicate policy definitions.

## 7. Rollback

If this Storage policy repair must be rolled back, first confirm no Buyer or handover evidence depends on the owner SELECT policy. The exact policy rollback is:

```sql
DROP POLICY IF EXISTS buyer_goods_docs_insert_owner ON storage.objects;
DROP POLICY IF EXISTS buyer_goods_docs_select_owner ON storage.objects;
DROP POLICY IF EXISTS buyer_goods_docs_update_owner ON storage.objects;
```

This leaves the pre-existing Finance SELECT policy untouched. It will, however, disable Buyer upload/read/replace for this evidence path again.

To revert source changes only, revert commits in reverse order:
1. `539768dcab4f3a47b4512454155fcf1d1c94a7b4`
2. `e76592865ef3e11a6fbbe6960655c5ba8e2b2eaf`

Do not delete `PINV-1003`; no cleanup is required for this task because no test objects or business rows were created.

## 8. Next operational acceptance

1. Verify Cloudflare Production terminal Success and compare the served Buyer asset with final blob `c6baf1cdedd4e6f5d219a3c95b6c9450a54dd2d0`.
2. Open the existing `PINV-1003` draft in Buyer → «فواتيري» and edit it; do not create a duplicate invoice.
3. Attach the supplier invoice image/PDF and save. Confirm the Storage upload succeeds, `REGISTER_QUICK_MARKET_ATTACHMENT` returns the same invoice ID/storage path, and one `purchase_attachments` row is visible.
4. Reopen the invoice and verify the signed attachment link can be read by its owner.
5. Verify Finance can still read the evidence under the existing Finance policy, and a different Buyer cannot read/upload/replace it.
6. Exercise the separate Supplier→Buyer handover evidence upload under the new `handover-` path.
7. Confirm no stock, treasury, cash-box, supplier-ledger, journal, GL or custody posting occurred merely from saving the Draft.

**Final status:** STORAGE RLS ROOT CAUSE FIXED IN PRODUCTION · OWNER-BOUND INSERT/SELECT/UPDATE POLICIES VERIFIED · BUYER UPLOAD ERROR FLOW FIXED IN SOURCE · CONTROLLED RETRY / CONTRACT TEST PASS · EXISTING DRAFT RECOVERABLE · AUTHENTICATED BROWSER / CLOUDFLARE DEPLOYMENT E2E OPEN.
