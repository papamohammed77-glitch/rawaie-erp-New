# RAWAEA ERP — PRODUCTION → GIT REALITY MATRIX
## Canonical State Reference — 2026-08-19

### Authority
Production runtime/schema/RPC evidence outranks Git source. This file is the single canonical matrix for the closure stream and must be updated instead of creating parallel reality matrices.

### Allowed Status Values
DEPLOYED | CURRENT ONLY | STAGING ONLY | DRIFT | MISSING | VERIFIED | INCOMPLETE

| Closure / Component | Production version / SHA | Current path / SHA | Original path / SHA | Historical / branch / commit | Core | Consumer | Runtime | Status |
|---|---|---|---|---|---|---|---|---|
| complete-picking | Edge v16 / `90bd82415ee92039da3e7b5c5b1bdfe20e76cc6aac68c36f231a848ea9100fa4` | `Current/Edge_Functions/complete-picking` / `cadafd67c0c419996c0a8512a46582698e4ffd08`; idempotency enhancement commit `927d5bd6bb6f790b991f1e2261a72daca84593ae` | `Original/Edge Functions/complete-picking.ts` / `c981efef28e9c3e65a0729400f648bbff857a21c`; historical repository also contains the same original behavior | `rawaie-erp-review/Edge_Functions/original`; legacy responsibility was distributed in Edge | `complete_runsheet_picking` 5-arg OID 25081, SECURITY DEFINER, `search_path=public`; `reserve_stock`; 4-arg OID 23940 has no EXECUTE for application/service roles | `Current/PWA/picker.html` / `f169247f7e6389eb826bb214e2cba2f034de3300`; operation_id flows to Core | Production Core/runtime behavior verified; current 5-arg is the only executable overload for service_role; 4-arg is revoked | VERIFIED |
| send-stock-voucher | Edge v19 / `ec1b243418f93a5759cebfe21ea8b85e27235f7dc953c68a0242f180259303ef` | `Current/Edge_Functions/send-stock-voucher` / `48ad0aad0cc37ebdecfabfb77455f2b8a1151dc8`; thin authenticated adapter | `Original/Edge Functions/send-stock-voucher` / `811f458b172db1210adbb15fd483be856b45a0be`; direct physical writer historically | PR #17 merged to `main` as `acca14b580efc25eb80ed579100fe1a4f4cdf8dc`; migration artifact `supabase/migrations/20260819200000_send_stock_voucher_target_branch_fix.sql` | `send_stock_voucher_atomic` OID 23580 → `post_stock_movement` OID 23882; target branch now required for Transfer/DirectSale and passed to Core | `Current/PWA/vouchers.html` / `99573a3bab9970d1f7599ac8a89d3411dd233e40`; Send call is thin, but Create path still sends empty/string target values and must be reconciled before a full UI-driven E2E | Production Core transaction verified after live patch: first send success; identical retry duplicate; rollback residue 0. HTTP Edge E2E remains blocked by legitimate test-auth bootstrap and no bypass is permitted | INCOMPLETE |
| post_stock_movement | Canonical 10-arg OID 23882 / SECURITY DEFINER | Multiple references in `Current/Edge_Functions/*` via RPC calls | Historical direct writers replaced/removed in rescue | Legacy 9-arg wrapper OID 23687 retained only for compatibility and not executable by application/service roles | Single Physical Stock Mutation Engine | Adapters only | Core transactional tests pass; global writer sweep = 0 external physical writers | VERIFIED |
| reserve_stock | Production OID 23911 / SECURITY DEFINER | Current Core consumers call reservation API | Historical Picking orchestration called reservation from Edge | N/A | Reservation only; `allocated_qty` changes, physical `qty` does not | Picking Core | Transactional reservation verification and current runtime contract | VERIFIED |
| release_stock_reservation | Production OID 24354 / SECURITY DEFINER | Current Picking cancel/reopen Core | Historical reservation release logic | N/A | Reservation release only | Picking Core | Production definition verified | VERIFIED |
| setup_van_stock | Production OID 23248 / SECURITY DEFINER | Current setup path | Historical bootstrap path | N/A | Zero-quantity stock-row initialization only | setup-van-branch / setup flow | Production definition verified; no physical movement | VERIFIED |

## Production Physical Writer Sweep — 2026-08-19

Confirmed directly from Production PostgreSQL:

- Physical writers outside `post_stock_movement`: **0**.
- Direct `stock_branches.qty` writers outside the central/approved engines: **0**.
- `reserve_stock` and `release_stock_reservation` are reservation capabilities only.
- `setup_van_stock` is initialization-only row bootstrap.
- No inventory/stock triggers mutate `stock_branches` or `inventory_log`.
- Canonical 10-argument `post_stock_movement` is the only application/service-executable physical movement engine; legacy 9-argument overload is not executable by application/service roles.

## Security Snapshot

### Complete Picking Core
- 5-arg `complete_runsheet_picking`: SECURITY DEFINER, `search_path=public`, service_role EXECUTE only from current privilege query.
- 4-arg legacy overload: SECURITY DEFINER, `search_path=public`, EXECUTE denied to public/anon/authenticated/service_role.

### SEND / Inventory Core
- `send_stock_voucher_atomic`, `post_stock_movement(10)`, `reserve_stock`, `release_stock_reservation`: SECURITY DEFINER, `search_path=public`, not executable by public/anon/authenticated; service_role only where required.
- Edge adapters authenticate via Supabase Auth, resolve `public.users.auth_id → company_id`, then call the Core RPC.

## Open Closure Gate

`send-stock-voucher` is **NOT 100% CLOSED** yet.

Proven:
- Production defect identified in `send_stock_voucher_atomic` target propagation.
- Permanent Core repair applied directly in Production.
- Same repair committed to Git and merged to `main` (PR #17 / merge `acca14b580efc25eb80ed579100fe1a4f4cdf8dc`).
- Production transactional SEND + duplicate replay + rollback passed.

Unproven:
- Fresh authenticated Production HTTP execution through the live `send-stock-voucher` Edge v19 after this Core patch.
- Full UI-driven Create → Send contract, because current `vouchers.html` still supplies empty/string target identifiers to `create-stock-voucher` while the Production Create RPC requires concrete target IDs for Transfer/DirectSale/DirectReturn.
- The Production migration ledger does not contain version `20260819200000`; the correction was applied directly to Production and represented in Git. This is an execution-lineage item and must not be silently relabeled as migration-applied.

## Closure Rule

Do not advance to `receive-stock-voucher` until the SEND HTTP authentication gate is legitimately executed and the Consumer/Create dependency is either closed or explicitly proven irrelevant to the SEND closure path.
