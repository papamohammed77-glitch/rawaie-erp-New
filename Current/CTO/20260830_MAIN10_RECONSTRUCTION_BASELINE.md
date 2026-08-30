# MAIN10 Reconstruction — Forensic Baseline

EVENT ID: MAIN10-20260830-BASELINE
DATE: 2026-08-30
SOURCE: Direct Git inspection + direct Supabase inspection + historical governance sources
OBJECTIVE: Reconstruct Current/PWA/main/main10.md without losing functions/contracts.

INPUT STATE
- Current/PWA/main/main10.md was opened directly and read in chunks through its end (419 lines in the pre-change snapshot).
- Original/PWA/main/main10.md had the same blob SHA as Current at baseline: d57cef3bd7e42f7ba7ddc90bde81bdbabd5579a.
- Therefore main10 had not previously incorporated the later fragment-level hardening.

BUSINESS UNDERSTANDING
- MAIN10 owns Owner/License UI and the global view router.
- It must not become a physical stock, accounting, ledger, or tenant-authority writer.

ARCHITECTURE UNDERSTANDING
- Tenant identity comes from the established RW_ShellContext -> users.auth_id/company_id path.
- Owner semantics remain isOwner=true; backend remains authoritative for license mutations.
- Router dispatches capabilities implemented by main1..main9 and warehouse/finance/report modules.

DATABASE UNDERSTANDING
- app_settings is company-scoped by company_id; owner_email is not a current column.
- Relevant current columns for main10 are verified directly from information_schema.
- items.item_code is globally UNIQUE; stock_branches is keyed by branch_id + item_id.

HISTORICAL UNDERSTANDING
- Governance requires study before change and forbids treating suspicious behavior as a bug without context.
- Previous reports 93–105 were used only as historical context, never as current production truth.

CURRENT GIT UNDERSTANDING
- main10 was the untouched/original baseline at d57cef3bd7e42f7ba7ddc90bde81bdbabd5579a.
- Latest main branch commit at baseline was verified directly before modification.

CURRENT PRODUCTION UNDERSTANDING
- Current Production schema was queried directly.
- save-settings is an active authenticated Edge Function and remains the authoritative mutation path.

DEPLOYMENT UNDERSTANDING
- main10 is source code only; no direct database mutation is embedded in it.

RUNTIME UNDERSTANDING
- Static JavaScript syntax verification performed on the reconstructed source.
- Full browser runtime cannot be truthfully marked verified until the integrated main.html is executed in a real browser runtime.

CONFIRMED FACTS
- The original main10 used unscoped app_settings reads and referenced non-existent owner_email.
- The global router is cross-fragment integration-sensitive code.
- Current app_settings schema contains company_id, status, trial_end_date, subscription_end_date, main_branch_id and related fields.

UNKNOWNS
- Real-browser execution of the complete merged main.html is not available in this execution context.
- Whether every legacy route is still consumed by an external hidden caller is not provable from PWA source alone.

CONFLICTS
- Git main advanced during investigation after an initial stale SHA was captured; the stale update was rejected with 409 and was not forced.

UNVERIFIED CLAIMS
- None used as a basis for the reconstruction.

CHECKLIST
Production Opened: YES
Current Git Opened: YES
Historical Opened: YES
Schema Checked: YES
Triggers Checked: YES
RLS Checked: YES
Permissions Checked: YES
Consumers Checked: YES
Dependencies Checked: YES
Git History Checked: YES

BASELINE DECISION
- Rebuild main10 from direct source evidence.
- Preserve all established route keys and handler names.
- Correct tenant scoping in Owner/License reads.
- Preserve Owner wildcard semantics; do not rewrite permissions semantics.
- Preserve global togglePasswordVisibility compatibility.
- Do not introduce stock/accounting/ledger mutation logic.
