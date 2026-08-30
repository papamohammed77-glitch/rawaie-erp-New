EVENT ID: MAIN10-20260830-RECONSTRUCTION
DATE: 2026-08-30
OBJECTIVE: Reconstruct Current/PWA/main/main10.md from direct source evidence without contract/function loss.
INPUT STATE: main10 baseline blob d57cef3bd7e42f7ba7ddc90bde81bdbabd5579a; Original/PWA/main/main10.md matched that baseline.
HISTORICAL CONTRACT: Owner/License UI + global router; main10 must remain orchestration/UI and must not own Physical Stock/Accounting/Ledger truth.
CURRENT PRODUCTION FACT: app_settings is company scoped by company_id; owner_email does not exist; Owner semantics are isOwner=true with wildcard permissions handled by existing shell/backend.
CURRENT GIT FACT: main branch was re-read immediately before modification; stale Contents API update was rejected with 409 and not forced.
CURRENT EVIDENCE: main10 read in chunks through its terminal line; Current and Original baseline matched.
DISCOVERY: original main10 had unscoped app_settings select('*').limit(1) and referenced owner_email; router was integration-sensitive.
ROOT CAUSE: historical fragment had not absorbed later tenant/Owner hardening from preceding main fragments and Production.
BUSINESS IMPACT: possible wrong-company license reads and fragile merged router.
ARCHITECTURAL IMPACT: tenant context must come from RW_ShellContext and route permissions must remain centralized without creating new authorities.
DATABASE IMPACT: none from main10; reads are company-scoped.
EDGE/RPC IMPACT: save-settings remains the authoritative mutation path.
FRONTEND IMPACT: Owner/License UI hardened; router preserved.
CHANGE: full main10 reconstruction.
WHY: align source with current contracts while preserving route/function names.
ALTERNATIVES REJECTED: blind patching of original; changing backend Owner semantics; adding stock/accounting logic.
MIGRATION: none.
DEPLOYMENT: Git source change only.
TEST: node --check passed on reconstructed source before Git write.
RUNTIME TEST: full integrated browser runtime not available in this execution context.
PRODUCTION VERIFY: direct Production schema and function evidence checked.
DATA CLEANUP: none; main10 contains no data migration.
AUDIT PRESERVATION: no audit data altered.
POST-CHANGE STATE: reconstructed main10 is ready for later P11 integration.
OBSOLETE STATE: unscoped license read and owner_email reference in main10 are obsolete.
REMAINING OPEN: real-browser integrated main.html runtime gate.
