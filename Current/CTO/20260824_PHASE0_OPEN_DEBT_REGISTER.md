# RAWAEA ERP — PHASE 0 OPEN DEBT REGISTER — CURRENT RECONCILED STATE

Date: 2026-08-25
Owner: Khalid — Governance / Evidence
Authority: Production > main > current evidence > historical > reports

| ID | Area | Current state | Evidence status | Risk | Owner | Next evidence |
|---|---|---|---|---|---|---|
| P0-01 | COA master data | `chart_of_accounts=0`; exact historical 87 rows not recovered | PRODUCTION VERIFIED + SOURCE EXHAUSTION for accessible/reachable sources | High | Owner / Khalid | New authoritative row-level source OR explicit new-master-data decision |
| P0-02 | Treasury↔COA | Treasury exists; COA empty; historical account pairing unproven | PRODUCTION VERIFIED / contract OPEN | High | Khalid / Owner | COA source-backed account + explicit relationship proof |
| P0-03 | Production/Git lineage | Current critical Edge objects exist, but complete byte/hash lineage is not closed | OPEN EVIDENCE GAP | High | Khalid/Hytham | Per-function deployed hash ↔ Current source map |
| P0-04 | Applied migrations ↔ Git | Production migration head verified, complete historical 1:1 reconciliation not closed | OPEN EVIDENCE GAP | High | Hytham | Complete applied-set ↔ repo migration reconciliation |
| P0-05 | Writer classification | 48 public functions / 46 names verified; full function-by-function source classification not closed | OPEN EVIDENCE GAP | High | Hytham | 48-function source-backed writer matrix |
| P0-06 | Financial RLS | Sensitive financial tables still contain broad permissive policies | PRODUCTION VERIFIED / OPEN DEBT | High | Security / Hytham | Role-by-role proof + controlled revoke plan |
| P0-07 | Table grants | Broad legacy grants remain | PRODUCTION VERIFIED / OPEN DEBT | High | Security / Hytham | Grant matrix + consumer evidence |
| P0-08 | Runtime E2E | Operational tables empty; many business flows cannot be proven with live records | PRODUCTION VERIFIED / UNPROVEN RUNTIME | High | Hytham | Controlled authenticated E2E with isolated fixtures |
| P0-09 | Concurrency | Two-session proof remains open | UNVERIFIED | High | Hytham | Independent-session race tests |
| P0-10 | Receipt/Payment | Core boundary exists; consumer HTTP/runtime closure open | STRUCTURE VERIFIED / RUNTIME OPEN | High | Khalid/Hytham | Authenticated HTTP E2E + consumer contract |
| P0-11 | Daily Settlement | Edge v3 exists; writer/runtime closure not proven | DEPLOYED / OPEN | High | Hytham | Writer + consumer + runtime evidence |
| P0-12 | Active canary/harness/recovery Edge footprint | Multiple active operational functions remain unclassified as business consumers | DEPLOYED / CLASSIFICATION OPEN | Medium/High | Khalid/Hytham | Consumer classification + retirement decision |
| P0-13 | PWA financial consumer | `accountant.html` remains on older consumer contract | OPEN | High | Khalid | Proven current financial consumer contract |
| P0-14 | Finance Manager | Reporting alignment exists, full UX/runtime closure not complete | OPEN | Medium | Khalid | Backend/UX/browser proof |
| P0-15 | Phase 0 reconciliation | Current-state reconciliation completed; technical closure gates above remain | OPEN — NOT CERTIFIED CLOSED | Critical | Khalid + Hytham | Close all technical evidence gaps |

## Non-closure rules

- Historical count is not row-level recovery.
- Git presence is not Production deployment proof.
- Production deployment is not Git reproducibility proof.
- SQL definition is not HTTP runtime proof.
- One successful request is not concurrency proof.
- Unknown remains unknown.
- No COA reconstruction is authorized.
- No Treasury change is authorized.

## Current reconciliation pointer

See:
`Current/CTO/20260825_KHALID_PHASE0_PHASE1_RECONCILIATION_FINAL.md`

The earlier 2026-08-24 register remains historical evidence of its execution-time state.
