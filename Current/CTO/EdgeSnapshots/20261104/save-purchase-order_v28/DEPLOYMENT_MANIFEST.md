# save-purchase-order v28 — Production Snapshot

- Function: `save-purchase-order`
- Project: `SMART ERP` (`fiilmooggumokxanwiyx`)
- Version: `28`
- Status: `ACTIVE`
- `verify_jwt`: `true`
- Deployed source SHA-256: `663b4bab72a4c81ec93b53d3f15a29902fa9984320f11a198209a46ac45646e2`
- Source length: 36865 characters.
- Live source exactly matches reviewed v28 ChangeSet: MATCH.

## Changes retained from v27
1. `REGISTER_QUICK_MARKET_ATTACHMENT`: validates Quick Market draft ownership, exact company/user/buyer-goods/invoice path, Storage object existence, MIME/size, and registers `purchase_attachments` idempotently.
2. `GET_DATA(purchase_attachments)`: non-finance users receive only invoice attachments for their visible invoice IDs.

## v28 correction
- Replaced a schema-qualified PostgREST table lookup `sb.from("storage.objects")` with the documented Storage API `sb.storage.from("employee-documents").info(path)`.
- This avoids depending on exposing Supabase-managed `storage` schema through PostgREST and uses the Storage API to retrieve object metadata.

## Related Production migrations
- `20261104215236_buyer_goods_evidence_finance_storage_read_20261104.sql`
- `20261104215443_purchase_attachments_storage_path_idempotency_20261104.sql`
- `20261104215757_purchase_attachments_invoice_owner_read_20261104.sql`

## Safety notes
- No new Edge Function.
- Bucket `employee-documents` remains private.
- Warehouse/Receiver access remains deferred pending branch-scoped authorization.
- v27 was superseded by v28 immediately after the Storage API review; v28 is the current live version.
