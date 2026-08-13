# 25 — HISTORICAL FAILURE FORENSICS

## Status
Historical incident memory. Historical records do not prove current Production state.

## Recovered taxonomy

| Incident | Historical cause/effect | Lesson |
|---|---|---|
| Projection drift | `sync-run-sheet-details` is a manually invoked projection path | projection synchronization must be treated as a critical dependency |
| `invoke` constitutional violation | some functions/apps used `supabase.functions.invoke` | verify actual caller implementation, not just intended architecture |
| `supabase.sql` usage | treasury voucher functions used dynamic SQL patterns | SQL safety and atomicity must be verified at the DB boundary |
| Missing RLS on financial tables | historical security review identified exposed financial tables | RLS status is object-level evidence, not documentation assumption |
| Unsafe Service Worker caching | historical `sw.js` could cache HTML/API behavior incorrectly | client cache strategy can create stale business state |
| Original apps bypassed core.js | multiple PWA apps contained their own Supabase/Dexie logic | duplicated client infrastructure increases divergence risk |
| Supplier ledger incomplete | historical `receive-purchase` updated stock/accounting but supplier ledger was identified as incomplete | accounting side effects must be traced across all ledgers |
| `delete-*` vs no-hard-delete tension | API catalog contains delete functions while Constitution rejects hard delete | function name alone cannot establish permitted business behavior |
| Static company UUID | historical Edge review found hard-coded company IDs | tenant/company context must be evidence-based |
| Order detail delete/reinsert | historical `update-order` deleted and recreated details | identity/audit continuity can be lost by wholesale replacement |
| Distributed stock mutation | multiple historical Edge Functions could mutate stock directly | stock truth must be centralized and side effects mapped |
| Diagnostic vs Production confusion | historical reports mixed review observations with runtime claims | classify every statement as evidence type before acting |

## Historical report evidence
`Edge_Function_Reports/_HISTORICAL/` contains batch-based reviews. Batch 01, for example, reviewed order lifecycle functions and recorded architectural findings such as static company UUID, serial generation inside functions, absence of a formal event engine, and delete/reinsert behavior in `update-order`.

Those reports are valuable institutional memory but are explicitly historical review artifacts. Their approval scores do not constitute current Production verification.

## Failure prevention rules now carried forward
1. Never infer a schema column from a historical function.
2. Never infer deployment from source existence.
3. Never infer Production behavior from an architecture report.
4. Never repeat a failed test without new diagnostic evidence.
5. Never put a permanent fix only inside a transaction that will be rolled back.
6. Never use UI workarounds to conceal a core business defect.
7. Never conflate Vehicle with Driver/Representative.
8. Never reintroduce rejected infrastructure merely because the historical implementation used it.

## Residual historical unknowns
- Full incident-to-Production mapping for every historical Edge Function is not available from documentation alone.
- Historical report batches contain staged reviews and repeated narrative; they require per-function reconciliation before being treated as definitive.
