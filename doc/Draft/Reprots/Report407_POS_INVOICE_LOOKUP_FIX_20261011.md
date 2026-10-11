# Report407 — POS Invoice Lookup Numeric Suffix Repair — 2026-10-11

## القرار التنفيذي

**تم إصلاح Production RPC مباشرةً**. لم يتطلب الإصلاح تعديل `pos.html` أو `main.html` لأن سبب العطل كان عقد مطابقة رقم الفاتورة داخل قاعدة البيانات، وليس خطأ في استدعاء الواجهة.

## 1. الأدلة الحية قبل الإصلاح

- Production project: `fiilmooggumokxanwiyx`.
- POS frontend repository: `papamohammed77-glitch/erp-frontend`.
- Current fetched `companies/company-1/sales/pos.html` blob SHA: `fc52e51c185d945bff1ebc1c55b76601410db824`.
- Browser evidence supplied for the real failure: authenticated cashier `cashier@rawaea.com`, RPC `get_pos_invoice_data`, action `return_lookup`, payload `p_order_code='1006'`, HTTP 200, response `{order:null, details:[], success:true}`.
- Live Production row: `orders.order_code='ORD-1006'`, company `00000000-0000-0000-0000-000000000001`, branch `a38332b6-6cea-480a-ada1-6eb6ab0590db` (BR-01 / الفرع الرئيسي), source `pos`, status `Invoiced`, created by `cashier@rawaea.com`.
- The order has two `order_details` rows.
- Live user profile maps auth UUID `8dbcede3-3a94-40c6-a6c9-7d500f127f4a` to application user `4cd61391-b14c-4194-813c-221acac9f57e`; profile is active, permission includes `pos`, allowed branch value is `BR-01`.
- `get_pos_branches()` explicitly supports a string `allowed_branch_ids` containing the branch code, so branch authorization was not the cause.
- The old live lookup used exact equality `o.order_code = btrim(p_order_code)`; this cannot match `1006` to `ORD-1006`.
- A company/source-scoped uniqueness check found exactly one current `POS` suffix match for `1006`.

## 2. Root cause

The UI label invites the cashier to enter the invoice number and sends the value unchanged. Production stores the actual code with a prefix (`ORD-1006`). The RPC required a literal full-code match and returned a successful JSON response with a null order. The UI then displayed its generic “الفاتورة غير موجودة في فروع POS المصرح بها” message, incorrectly suggesting a branch-permission problem.

## 3. Repair applied to Production

Migration applied through Supabase:

- Migration name: `pos_invoice_lookup_numeric_suffix_20261011`
- Production migration version: `20261011085921`
- Canonical repository file: `supabase/migrations/20261011_pos_invoice_lookup_numeric_suffix.sql`
- Repository commit: `0296c0d2d331c1a09e9e60694d6933a1b225c923`

Behavior after repair:
1. An exact full `order_code` match is always preferred.
2. If the input has no hyphen and exact matching fails, the RPC searches for a matching suffix within the same company, authorized branches, and `source='pos'`.
3. Suffix lookup is accepted only when exactly one match exists.
4. If multiple authorized POS invoices share the suffix, the RPC raises an explicit ambiguity error and asks for the full invoice code; it does not pick an arbitrary row.
5. Existing authentication, POS permission, company scope, branch scope, read-only behavior, response shape, and `today` behavior are preserved.
6. Execute ACL was explicitly re-established for `authenticated` and `service_role` after revoking `PUBLIC`.

No order, order-detail, stock, cash, refund, or accounting data was modified by this repair.

## 4. Verification

- [x] Production function definition re-read after applying migration.
- [x] Production function remains `SECURITY DEFINER` with empty search path and explicit schema-qualified relations.
- [x] Production ACL re-read: `postgres`, `authenticated`, and `service_role` are listed; `anon` and `PUBLIC` are not granted EXECUTE.
- [x] Database match simulation confirms `1006 → ORD-1006`, one match, two invoice detail rows.
- [x] Production migration registry includes `20261011085921 / pos_invoice_lookup_numeric_suffix_20261011`.
- [x] Canonical SQL migration committed to `rawaie-erp-New/main`.
- [ ] Authenticated browser/HTTP E2E after the change is **not yet evidenced in this session**; the owner must retry the lookup from the logged-in POS screen. This is a runtime verification item, not a reason to revert the deployed repair.
- [ ] Do not claim the entire POS return workflow is closed: this repair only closes the invoice-lookup defect.

## 5. Owner verification — one-minute check

1. Refresh the POS application (hard refresh if the PWA has a cached shell).
2. Sign in as the same authorized cashier.
3. Open **مرتجع** and enter `1006`.
4. Press **تحميل الفاتورة** once.
5. Expected: the screen loads invoice `ORD-1006` and its two item rows. No return should be finalized as part of this lookup test.
6. If the old message remains, capture the new RPC payload/response and the served POS asset URL; do not change permissions or modify invoice data.

## SELF-AUDIT FINAL

- **What I Proved:** the exact mismatch between the browser payload and the live invoice code; valid cashier profile/branch access; a unique scoped suffix match; live RPC replacement; ACL and migration registry.
- **What I Did Not Prove:** post-deploy authenticated browser E2E or Cloudflare/PWA served-asset parity.
- **What I Fixed:** Production invoice lookup now supports full invoice codes and unique numeric suffixes without widening tenant/branch scope.
- **What I Initially Missed:** the displayed error text was a generic consequence of `order:null`, not evidence of a permissions defect.
- **What Could Still Be Wrong:** if a different deployment serves an old/cached application shell, its visible behavior may not reflect the current database fix; ambiguous suffixes are deliberately rejected.
- **Final Confidence:** high for root cause and Production SQL repair; browser E2E pending.
- **Final Closure Status:** `PRODUCTION RPC REPAIRED / MIGRATION COMMITTED / AUTHENTICATED UI E2E PENDING / THIS DEFECT NOT FULL POS CLOSURE`.
