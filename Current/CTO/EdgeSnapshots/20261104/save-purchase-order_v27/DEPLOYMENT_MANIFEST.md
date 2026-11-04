# save-purchase-order v27 — Production Snapshot

- Function: `save-purchase-order`
- Project: `SMART ERP` (`fiilmooggumokxanwiyx`)
- Version: `27`
- Status: `ACTIVE`
- `verify_jwt`: `true`
- Deployed source SHA-256: `b57d9be69c0010cb25025728aa40b56edc2481e0a15f8e90fb9873aaf2c04b52`
- Source length: 36922 characters.
- The live source was re-fetched after deployment and compared byte-for-byte with the reviewed v27 ChangeSet: MATCH.

## Changes from v26
1. Added `REGISTER_QUICK_MARKET_ATTACHMENT`: validates invoice ownership/source/draft state, exact company/user/buyer-goods/invoice path, Storage object existence, MIME and size; registers or updates `purchase_attachments` idempotently using the unique path index.
2. Scoped non-finance `GET_DATA(purchase_attachments)` to PurchaseInvoice attachments for visible invoice IDs; Finance/Finance Manager/Owner retain company-wide purchase attachment access through the established permission gate.

## Related Production migrations
- `20261104215236_buyer_goods_evidence_finance_storage_read_20261104.sql`: Finance/Finance Manager/Owner SELECT for buyer-goods objects only when a same-company QUICK_MARKET invoice exists.
- `20261104215443_purchase_attachments_storage_path_idempotency_20261104.sql`: unique path index for idempotent attachment registration.
- `20261104215757_purchase_attachments_invoice_owner_read_20261104.sql`: invoice attachment metadata SELECT scoped to owner/creator or Finance/Finance Manager/Owner.

## Safety notes
- No new Edge Function.
- `storage.objects` is read-only from SQL; Edge reads object metadata only and all object writes use the Storage API.
- Bucket `employee-documents` remains private.
- Warehouse/Receiver file access remains deferred until branch-scoped authorization is established.

## Superseded
- v27 was superseded by v28 immediately after reviewing Supabase Storage API schema exposure. The v27 attachment branch queried `storage.objects` through a schema-qualified PostgREST table name; v28 uses the documented `storage.from(...).info(path)` API instead.
- Current production version is v28 ACTIVE. Do not deploy or use v27 as current.
