# RAWAEA ERP — PHASE 0 OPEN DEBT REGISTER

Date: 2026-08-24
Owner: Khalid — Governance / Evidence
Authority: Production > main > current evidence > historical > reports

| ID | Area | Evidence | Current state | Risk | Blocker | Owner | Next evidence |
|---|---|---|---|---|---|---|---|
| P0-01 | COA master data | Production `chart_of_accounts = 0`; prior tenant count 87; source-exhaustion certificate | Exact 87 historical rows not recovered | High | Yes for financial transactions that require COA | Owner / Khalid | Authoritative row-level backup/source or explicit new-master-data decision |
| P0-02 | Treasury↔COA | Current Treasury exists, COA empty; no current row pair proves historical account mapping | Contract not currently executable through COA | High | Yes for financial posting | Khalid / Owner | Current canonical COA contract and row-level account mapping |
| P0-03 | Production/Git lineage | Current Edge inventory contains deployed versions/hashes; not all have byte-for-byte Current/Git lineage | Partial | High | No for Phase 0 baseline; yes for deployment closure | Khalid/Hytham | Per-function source SHA + deploy mapping |
| P0-04 | Financial writer convergence | Current Production cores exist; PR #24 closed/unmerged | Convergence materially present but PR #24 is not source authority | High | Yes for zero-debt closure | Hytham | Main/Production reconciliation + remaining writers |
| P0-05 | Legacy RPC overloads | Production has legacy overloads for `post_stock_movement` and `complete_runsheet_picking`, plus legacy manual-voucher v2 functions | Catalog residue remains | Medium/High | No immediate functional blocker | Hytham | Consumer sweep + execution privilege proof + retirement evidence |
| P0-06 | Financial RLS | Several financial tables retain broad `ALL USING true` policies | Security debt exists | High | Yes for security closure | Hytham / Security owner | Role-by-role authorization proof and controlled policy tightening |
| P0-07 | Table grants | Broad anon/authenticated table privileges remain on many legacy tables | Capability surface wider than desired | High | Yes for security closure | Hytham | Grant matrix + consumer evidence + safe revoke plan |
| P0-08 | Runtime E2E | Current Production has zero Orders/PO/Runsheets; many prior runtime paths lack live business fixtures | Not all business flows can be proven against live business data | High | Yes for runtime closure | Hytham | Controlled isolated authenticated E2E fixtures with baseline restoration |
| P0-09 | Concurrency | Two-session proof not yet established globally | OPEN | High | Yes for zero-debt | Hytham | Independent-session race tests for critical writers |
| P0-10 | Receipt/Payment runtime | Edge functions deployed; accountant consumer remains separate | Core deployed but full runtime contract not closed | High | Yes for financial consumer closure | Hytham/Khalid | Authenticated HTTP E2E + consumer contract evidence |
| P0-11 | Daily Settlement | `save-daily-settlement` v3 deployed; writer convergence/runtime not closed | OPEN | High | Yes for financial zero-debt | Hytham | Writer sweep + contract + runtime proof |
| P0-12 | Active canary/harness functions | Multiple 20260814–20260819 canary/harness/recovery functions remain ACTIVE | Legacy operational footprint not fully classified | Medium/High | No | Khalid/Hytham | Consumer classification + retirement evidence |
| P0-13 | PWA financial consumer | `accountant.html` remains on older receipt/payment consumer contract | Not safe to patch without proven UUID contract | High | Yes for PWA finance work | Khalid | Proven Treasury/COA/consumer contract |
| P0-14 | Finance Manager | Surgical reporting alignment exists historically/currently, but full UX not closed | OPEN | Medium | No | Khalid | Backend reporting/COA closure + browser/runtime proof |
| P0-15 | Phase 0 reconciliation | Khalid baseline completed; Hytham independent baseline not yet reconciled line-by-line | PHASE 0 OPEN | Critical | Yes | Khalid + Hytham | Compare timestamps, company, cores, Edge, migrations, Git, PRs, security, drift, debt |

## Explicit non-closure rules

- `UNKNOWN` remains unknown.
- SQL definition presence is not runtime proof.
- Git presence is not Production deployment proof.
- Production deployment is not Git reproducibility proof.
- Historical count is not row-level recovery.
- No COA reconstruction is authorized by this register.
- No Treasury change is authorized by this register.
- No PWA/UI change is authorized by Phase 0.
