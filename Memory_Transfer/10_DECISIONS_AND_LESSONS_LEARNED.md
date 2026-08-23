# DECISIONS AND LESSONS LEARNED

## Decisions
- Production outranks all historical/source claims for current truth.
- Original/Historical behavior is preserved for comparison, not automatically accepted as target.
- Core owns business rules; UI/Edge are capability boundaries.
- Physical stock movement converges on `post_stock_movement`.
- Reservation is separate from physical movement.
- Vehicle identity is independent of representative identity.
- DirectSale is MAIN→VAN custody movement; VanSale is VAN→Customer; DirectReturn is VAN→MAIN.
- Loading is an internal MAIN→VAN movement; Reopen reverses it and creates a new loading cycle; Unloading is VAN→MAIN.

## Lessons
- Never assume columns, signatures, RLS, or generated fields; query schema first.
- Migration created != migration applied.
- Git changed != Production changed.
- Deployment != runtime verification.
- Staging != Production.
- ACTIVE + HTTP 410 stub != deleted.
- A report is evidence/lead material, not automatic truth.
- Rollback-based test data must be separated from permanent code fixes.
- If a diagnostic SQL query fails, fix the diagnostic before classifying a Production defect.
- Do not create duplicate master-data structures to simplify a test.
- Do not leave a legacy writer executable merely because it is believed unused.
- Do not hide uncertainty with a confidence percentage.
- Do not carry an unresolved closure debt into the next unit when the current unit can be finished.
- Prefer established industry accounting/inventory patterns where business logic is stable instead of inventing new semantics.

## Known process failures preserved
Earlier execution repeatedly confused Current vs Production, declared artifacts without proving deployment, and stopped at tooling gates. These failures are institutional guardrails now, not evidence to erase from memory.
