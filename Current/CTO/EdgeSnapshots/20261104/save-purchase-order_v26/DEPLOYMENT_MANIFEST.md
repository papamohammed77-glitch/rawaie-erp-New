# save-purchase-order v26 — Production Snapshot

- Function: `save-purchase-order`
- Project: `SMART ERP` (`fiilmooggumokxanwiyx`)
- Version: `26`
- Status: `ACTIVE`
- `verify_jwt`: `true`
- Deployed source SHA-256: `fb31ac953213d6f30a9e545f1da3b9075ca28638b5032450618769d20f2cb5b4`
- Source file: `index.ts`, 31,294 characters.
- Archived source blob: `577442e1b8fd22be056374292438a7074b966ff1`
- The archived file was fetched from the live Edge Function after deployment and matches the reviewed v25-derived ChangeSet byte-for-byte.
- Do not deploy the older Git source `supabase/functions/save-purchase-order/index.ts` (blob `bc038be8c60a3d593f604c7b2ae445e807bacf57`) over this version.

## Changes from live v25
1. System currency lookup uses deterministic `created_at,id` ordering and fails closed when the system setting is missing/invalid; no silent EGP fallback.
2. Generic `DELETE_DRAFT_INVOICE` checks allowed source, buyer/creator ownership or owner privilege, and absence of goods-custody events before the central atomic delete RPC.

## Verification
- Re-fetched deployed version: v26 ACTIVE.
- Deployed source content exactly equals this archived file.
- The SQL hardening migration is separate and recorded in `supabase/migrations/20261104213909_buyer_phase1_hardening_20261104.sql`.
