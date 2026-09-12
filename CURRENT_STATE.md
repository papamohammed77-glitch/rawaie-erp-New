# RAWAEA ERP — CURRENT STATE

**Last verified:** 2026-09-12
**Current checkpoint:** Main10 forensic recheck completed; Owner surgical package created; Main10 source fragment remains owner-edit only.

## Governing Rules

- Production must be rechecked at report time for any Production-dependent claim.
- Reports are evidence/clues, not current truth.
- `NO EVIDENCE = NO CLAIM`.
- `NO EOF = NO FULL READ`.
- `NO FUNCTIONAL TEST = NO FUNCTIONAL VERIFICATION`.
- `NO PRODUCTION CHECK = NO PRODUCTION VERIFICATION`.
- `NO CROSS-MODULE TRACE = NO BUSINESS COMPLETION`.
- `NO DATA CHECK = NO DATA CLOSURE`.
- Historical reconstruction precedes surgical change.
- Owner edits `Current/PWA/main2/main1..main11.md` source fragments.
- Production DB/Edge changes are performed by the assistant only when a proven Production gap exists.
- Assembly remains deferred until all eleven fragments are owner-verified and integrated.

## Gold / Diamond Mission

هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يُتعامل معه كإضافات شكلية.

وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

## Source of Truth

`Current/PWA/main2/main1.md` … `Current/PWA/main2/main11.md`

Historical reference only:
`Original/PWA/main/*`

Forbidden / retired:
`Current/PWA/main/*`
`Current/PWA/New-main/*`

`forensic_main_assembly.yml` is currently correct and points to `Current/PWA/main2`.

## Current Fragment Git SHAs — direct Git reconciliation

- main1: `f68d47c7574c34f678cfba2aafa5ad294aadbfe5`
- main2: `65815e23b03e29c125957e6fe283cc1e253a7f7d`
- main3: `eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe`
- main4: `e9f967859aeda729cd0811739a280ceec5266d7c`
- main5: `800ad51c88a2e80d060480990836a3c975c7435a`
- main6: `1dc500849a600e6436c1d319bdc93f3d270f6af9`
- main7: `5839252a9807ae1758939dad754a4f3a4505c76f`
- main8: `f67c0217a804d2cb2388ce48fb7f95176c075fb3`
- main9: `b68e5d8f0f52258080950add12fd7fcecbf8c0d7`
- main10: `169025a6836c7fdc7281ea86523b975a84d889f1`
- main11: `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

**Important reconciliation:** the previous state file recorded Main9 as `b9f10ae4...`; direct Git inspection on 2026-09-12 shows the current Main9 SHA is `b68e5d8f...`. The old state value is stale and must not be used as current truth.

## Latest Reports Reconciled

- Report129: `doc/Draft/Reprots/Report129_Main9_Forensic_Recheck_20260912.md`
- Report130: `doc/Draft/Reprots/Report130_Main9_Final_Production_Synchronization_20260912.md`
- Main9 owner package: `doc/Draft/Reprots/MAIN9_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

These remain historical execution evidence. Their claims were not accepted blindly.

## Main9 Carryover

Main9 remains owner-apply pending. The previous package addresses Finance exposure, CRM followups, Runsheet performance, Driver performance, and Returns compatibility. Main9 source was not modified by the assistant.

## Main10 — 2026-09-12

### Verified source

- Source of Truth: `Current/PWA/main2/main10.md`.
- Current SHA: `169025a6836c7fdc7281ea86523b975a84d889f1`.
- Direct Git metadata reports file size `20018` bytes.
- Sequential source reads covered lines 1–400.
- Direct read of lines 401–480 returned empty content; Main10 EOF is therefore verified at 400 lines.
- Historical reference opened: `Original/PWA/main/main10.md`.
- Historical Main10 contains the same basic Owner License and `RW_Views` architecture; the current file inherits several UX/router behaviors from that structure.

### Main10 confirmed functional gaps

1. **False/default license state when Company Context is missing.** Current source falls back to `licenseStatus: 'trial'`; this invents state instead of reporting an unavailable context.
2. **False email-field update.** `_buildFullForm()` asynchronously writes the authenticated email into `owner-new-email`, which pre-populates the NEW email field with the current email and can mislead the owner.
3. **Password confirmation is not enforced.** The UI contains `owner-confirm-password`, but `_bindSaveButtons()` does not compare it with the new password before calling `auth.updateUser`.
4. **Email validation is incomplete.** The button handler does not enforce a basic email syntax check before invoking `auth.updateUser`.
5. **Router permission gap: `finance`.** Production users have a real `finance` permission, but the current `permissionMap` has no `finance` entry, so the finance route bypasses the common permission gate.
6. **Router permission mismatch: `hr`.** Production contains a real `hr` permission, while Main10 maps `hr` to `users`; this is a contract mismatch that should use the explicit `hr` key.
7. **Missing router titles.** `finance`, `hr`, `crm`, and `reports-comprehensive` have no dedicated titles in the current title map.
8. **Misleading unknown-view fallback.** The final fallback says `قيد التطوير`; this is unsafe because an unknown route is not proof of an unfinished business capability.

### Main10 evidence about Production dependency

The current Production `save-settings` Edge Function is JWT-protected, derives `company_id` from the authenticated `users` row, and checks license edits with Owner semantics requiring `isOwner=true` plus wildcard permissions in both auth metadata and DB permissions. Therefore no Production migration is required to repair the Main10 findings above.

### Owner Surgical Package

Created:
`doc/Draft/Reprots/MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

Commit:
`6d289a85d6e3a8a2b71c41f242e425c808f86c0b`

The package contains exact surgical instructions and complete replacement blocks for:

- `M10-O1`: missing Company Context block inside `_loadLicenseData()`.
- `M10-O2`: complete `_buildFullForm(licenseInfo)` replacement.
- `M10-O3`: complete `_bindSaveButtons()` replacement.
- `M10-O4`: complete `RW_Views` replacement.

Main10 Source Fragment itself was **not edited by the assistant**.

### Exact owner locations

- `M10-O1`: inside `_loadLicenseData()`, current `if (!companyId) { ... }` block.
- `M10-O2`: `function _buildFullForm(licenseInfo)` — current lines 102–163.
- `M10-O3`: `function _bindSaveButtons()` — current lines 165–221.
- `M10-O4`: `var RW_Views = {` — current lines 262–400 through `window.RW_Views = RW_Views;`.

### What was intentionally not changed

- `_saveSettings(payload, label)` was reviewed and left unchanged.
- No Production schema/data change was introduced for Main10.
- No Inventory/Purchase/Return/Loading/Delivery Writer changes were continued after the Main10 task began.
- No edit was made to `Current/PWA/main2/main1..main11.md` by the assistant.
- `forensic_main_assembly.yml` required no change; it already points to `Current/PWA/main2`.

## Validation Status — Main10

```text
MAIN10 SOURCE PATH = VERIFIED
MAIN10 SOURCE SHA = VERIFIED
MAIN10 EOF = VERIFIED AT LINE 400
MAIN10 HISTORICAL REFERENCE = OPENED
PRODUCTION LICENSE BACKEND = VERIFIED
MAIN10 GAP LIST = VERIFIED
OWNER SURGICAL PACKAGE = CREATED
MAIN10 SOURCE EDITED BY ASSISTANT = NO
OWNER APPLY = PENDING
POST-APPLY EXECUTABLE SYNTAX = PENDING OWNER APPLY
POST-APPLY BROWSER/E2E = PENDING
ASSEMBLY = DEFERRED
GLOBAL GOLD/DIAMOND = OPEN
```

## Read/Validation Limitation

The GitHub connector exposed Main10 in exact line ranges and allowed EOF verification, but it did not expose a locally mountable full-source artifact for direct `node --check` execution in this session. Accordingly, no claim of executable `node --check` PASS is recorded. The Owner package itself was structurally reviewed before being written.

## Next Exact Checkpoint

1. Owner applies `M10-O1` → `M10-O4` exactly from `MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js`.
2. Re-read Main10 from line 1 through the new EOF.
3. Run executable syntax validation on the complete post-apply Main10 source.
4. Verify duplicate declarations, braces, string escaping, DOM IDs, route coverage, and Console errors.
5. Reconcile Main10 with main1..main11 and assembly only after owner verification of the fragment.
6. Production sync is required immediately before any final Main10 closure report.
