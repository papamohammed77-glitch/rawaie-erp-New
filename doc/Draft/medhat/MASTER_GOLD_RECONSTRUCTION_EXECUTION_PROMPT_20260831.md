# MASTER GOLD RECONSTRUCTION EXECUTION PROMPT — 2026-08-31

## MISSION
Execute the RAWAEA ERP MASTER RECONSTRUCTION from investigation to a production-verifiable GOLD/DIAMOND artifact. Do not stop at analysis, report, plan, or static preparation.

## SOURCE OF TRUTH
1. Live Supabase Production at execution time.
2. Current Git repository state at execution time.
3. Direct source files, migrations, Edge Function definitions, schema, triggers, RLS, grants, runtime logs.
4. Historical reports/fragments only as evidence to investigate, never as unverified current truth.

Never infer missing facts. Every material claim must have direct evidence.

## NON-NEGOTIABLE GOVERNANCE
- Freeze the current world before reconstruction.
- Never mutate Production merely to make a test pass.
- Preserve valid historical contracts and current Production contracts.
- Never mechanically concatenate main1..main11. Treat them as logical feature evidence.
- No direct Physical Stock writer in the browser: physical movement must pass through post_stock_movement.
- reserve_stock is reservation only.
- Tenant identity: authenticated user -> users.auth_id -> users.id -> users.company_id -> RW_ShellContext. No unscoped app_settings LIMIT 1 for tenant identity.
- Preserve OWNER semantics; do not replace isOwner/wildcard behavior with role-only inference.
- order_details remains authoritative fulfillment detail where that is the current contract; derived aggregates must not become a competing source of truth.

## GATE 0 — FREEZE CURRENT WORLD
Capture a fresh baseline before building:
- Git HEAD SHA and working tree state.
- Current/PWA/main.html hash, size, line count.
- main1..main11 hashes, sizes, line counts.
- Original/PWA/main.html and Original/PWA/main/* hashes.
- PWA companion files, service worker, manifests, relevant Core/Edge files.
- Production migration head.
- Required Production RPC definitions, signatures, SECURITY DEFINER state, grants.
- Required Production Edge Function versions and source hashes.
- Relevant table schema, constraints, indexes, RLS, triggers.
- Current Production counts and integrity indicators.
Write RECONSTRUCTION_BASELINE.json. Any later mismatch must be marked STALE and re-baselined, never silently reused.

## GATE 1 — CANONICAL REGISTRIES
Build machine-readable registries from the frozen source:
- feature_registry.json
- function_registry.json
- contract_registry.json
- dependency_graph.json
Include for each feature/module: UI surface, public symbols, DOM IDs, tables, RPCs, Edge Functions, permissions, state transitions, errors, storage/offline/realtime dependencies, source evidence and target disposition.

## GATE 2 — GAP RESOLUTION
Resolve only evidence-backed gaps in:
main3, main5, main7, main8, main9, main10.
For each gap:
FOUND -> ROOT CAUSE -> HISTORICAL REVIEW -> CURRENT PRODUCTION CONTRACT -> SAFE DESIGN -> IMPLEMENT -> STATIC TEST -> RUNTIME TEST -> CLOSE.
No gap may disappear merely because a symbol was renamed or hidden.
No responsibility may disappear without proving where it moved.

## GATE 3 — BUILD ONE NEW ARTIFACT
Create exactly one candidate artifact:
Current/PWA/main.reconstruction.html
Do not overwrite Current/PWA/main.html yet.
Build semantically from the current complete application plus validated fragment contracts and governed repairs.
Required properties:
- one complete HTML document;
- complete feature surface;
- no duplicated competing business engines;
- no direct stock_branches/inventory_log mutation;
- no unscoped tenant fallback;
- current owner semantics preserved;
- current Production RPC/Edge contracts respected;
- rec-purchase and rec-offers remain distinct capabilities.

## GATE 4 — AUTOMATED PARITY
Hard-fail on:
- structural HTML failure;
- JavaScript syntax failure;
- original public-function loss;
- required fragment-contract loss;
- required DOM/API/RPC/table/Edge contract loss;
- direct Physical Stock writer;
- direct inventory_log writer;
- hard-coded tenant/company identity;
- unscoped app_settings LIMIT 1;
- unresolved forbidden legacy writer.
Produce parity.json with explicit losses, gains and disposition. Zero unexplained losses is required.

## GATE 5 — PLAYWRIGHT
Serve main.reconstruction.html in a clean browser profile and run automated tests for:
- login/shell boot;
- navigation;
- all critical feature entry points;
- no pageerror/console errors attributable to reconstruction;
- Owner route guard and Owner semantics;
- normal-user denial/allowance semantics;
- critical PWA/offline/service-worker assumptions;
- critical forms and state transitions.
Where authenticated credentials are available through an already-governed test facility, perform authenticated Owner and normal-user flows. Never invent credentials.

## GATE 6 — PRODUCTION CONTRACT VERIFICATION
Against live Production, verify:
- required RPCs exist with expected signatures and security boundaries;
- physical writer count outside post_stock_movement is zero;
- required Edge Functions are present/current;
- tenant/item identity contracts hold;
- critical data integrity checks pass;
- runtime-compatible contract probes pass.
Never label staging/static evidence as Production PASS.

## GATE 7 — FINAL FRESH-BASELINE COMPARISON
Immediately before replacement, freeze again.
Compare the candidate against the fresh baseline and classify every difference as:
INTENDED RECONSTRUCTION / GOVERNED REPAIR / UNEXPECTED DRIFT.
Any unexpected material drift is a hard stop requiring re-investigation, not guessing.

## GATE 8 — REPLACE MAIN.HTML
Only after Gates 0–7 pass:
- copy main.reconstruction.html -> main.html;
- preserve the candidate artifact for audit;
- commit the exact replacement and all evidence registries;
- do not perform unrelated cleanup in the same release.

## GATE 9 — POST-REPLACEMENT PRODUCTION VERIFICATION
Re-run the full relevant Production contract verification and browser/runtime smoke tests against the replacement.
Compare final main.html hash with the approved candidate hash.
Verify that no new runtime regression appears.

## GATE 10 — FINAL VERDICT
Only two valid verdicts:
- MASTER RECONSTRUCTION = GOLD
- MASTER RECONSTRUCTION = DIAMOND
GOLD requires every mandatory gate to pass with no material unexplained gap.
DIAMOND requires GOLD plus zero known closure debt, reproducible evidence, final artifact/hash traceability, final Production verification, and no unresolved material Unknown/Conflict/Unverified Claim.
Never manufacture a verdict to make the task appear finished.

## REQUIRED EVIDENCE
Store in Current/CTO/:
- RECONSTRUCTION_BASELINE.json
- feature_registry.json
- function_registry.json
- contract_registry.json
- dependency_graph.json
- parity.json
- playwright-result.json
- production-contract-result.json
- final-baseline-comparison.json
- MASTER_RECONSTRUCTION_RESULT.md
- a deterministic execution log with Gate 0–10 status

## STOP CONDITIONS
Stop only for a true safety/integrity block such as destructive uncertainty, unreconcilable live drift, or missing authority required to perform a safe operation. Ordinary discovery of bugs is not a stop condition.

## SELF-AUDIT
At the end record:
- What I proved.
- What I did not prove.
- What I fixed.
- What I initially missed.
- What could still be wrong.
- Remaining Unknowns / Conflicts / Unverified Claims.
- Final evidence references.
- Final closure status.
