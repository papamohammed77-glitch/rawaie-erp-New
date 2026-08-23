# DECISIONS AND LESSONS LEARNED

## GOVERNING DECISIONS
1. Production is current truth.
2. Current Git is code lineage, not deployment proof.
3. Historical reports remain historical evidence.
4. One Closure Unit at a time.
5. No direct Physical Stock writer outside `post_stock_movement`.
6. Reservation is not movement.
7. Do not invent database relationships that are absent from live schema.
8. No `LIMIT 1` for tenant identity when tenant context is required.
9. Do not convert UNKNOWN into a fabricated answer.
10. Do not call a migration a deployment or a deployment a runtime proof.

## REPEATED FORENSIC LESSONS
- A “complete” UI can contain missing handlers.
- `NO_SESSION` is not the same as expired session.
- JavaScript parser failures can surface as `App is not defined`.
- RLS can present as missing/empty data.
- `auth_id` vs `id` must be verified from live identity constraints.
- Vehicle and Representative are different entities.
- Supplier branch relationships must not be invented.
- Legacy database functions can remain dangerous after they are “unused”; grants matter.
- Operation identity derived from mutable business state is unsafe for retries.
- A repair overlay can itself lose required helpers.
- Browser E2E cannot be claimed from SQL/source tests.
- Data drift in row counts requires provenance before deletion/reconstruction.
- File-size reduction is not proof of functional loss.
- ACTIVE + HTTP 410 is not equivalent to deleted.

## CURRENT PROJECT LESSON
The next CTO must not reopen the Inventory Core merely because an old report says it was incomplete. The current Production writer sweep is the controlling evidence. Reopen only on a fresh contradiction.