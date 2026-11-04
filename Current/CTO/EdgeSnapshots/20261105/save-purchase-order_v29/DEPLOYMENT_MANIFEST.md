# save-purchase-order v29 — Production snapshot

- Project: `fiilmooggumokxanwiyx`
- Function: `save-purchase-order`
- Version: `29`
- Status: `ACTIVE`
- `verify_jwt`: `true`
- SHA-256: `35caa4f2759ba608a7f3bf86640b4773280bc84447872267d6e4d53896743e04`
- Captured from live Supabase immediately after deploy on 2026-11-05 (Africa/Cairo).
- Source size: 39545 characters.
- Previous live source: v28 SHA-256 `663b4bab72a4c81ec93b53d3f15a29902fa9984320f11a198209a46ac45646e2`.
- Includes routes for `SUBMIT_OTHER_CUSTODY_EXPENSE`, `REVIEW_OTHER_CUSTODY_EXPENSE`, `VERIFY_CUSTODY_EXPENSE_OPERATION`, and Finance-only `GET_OTHER_CUSTODY_EXPENSE_ACCOUNTS`.
- Continues to reuse the existing `save-purchase-order` function; no new Edge Function was created.
- Production migration: `20261105001000_buyer_custody_operational_expenses_20261105.sql` (recorded by Supabase as `20261104223538`).
- Do not deploy the previous Git copy until it is synchronized to this exact live source.
