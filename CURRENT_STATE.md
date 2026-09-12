# RAWAEA ERP — CURRENT STATE

**Last verified:** 2026-09-12
**Current checkpoint:** Main10 forensic recheck R2 completed; live Main10 source is confirmed syntactically corrupted; corrected candidate validated; owner whole-unit replacement is pending.

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
- main10: `76aae070e7452f5b7b233b790c39d5c864aa19a0`
- main11: `2adfc787c3e5f0ca56abfcc85232e7a971773c3b`

**Important reconciliation:** the previous state file recorded Main9 as `b9f10ae4...`; direct Git inspection on 2026-09-12 shows the current Main9 SHA is `b68e5d8f...`. The old state value is stale and must not be used as current truth.

## Latest Reports Reconciled

- Report129: `doc/Draft/Reprots/Report129_Main9_Forensic_Recheck_20260912.md`
- Report130: `doc/Draft/Reprots/Report130_Main9_Final_Production_Synchronization_20260912.md`
- Report131: `doc/Draft/Reprots/Report131_Main10_Forensic_Recheck_20260912.md`
- Report132: `doc/Draft/Reprots/Report132_Main10_Forensic_Recheck_R2_20260912.md`
- Main9 owner package: `doc/Draft/Reprots/MAIN9_OWNER_SURGICAL_REPLACEMENTS_20260912.js`
- Main10 previous owner package: `doc/Draft/Reprots/MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

These remain historical execution evidence. Their claims were not accepted blindly.

## Main9 Carryover

Main9 remains owner-apply pending. The previous package addresses Finance exposure, CRM followups, Runsheet performance, Driver performance, and Returns compatibility. Main9 source was not modified by the assistant.

## Main10 — 2026-09-12 — R2 authoritative override

### Direct current-source reconciliation

- Source of Truth: `Current/PWA/main2/main10.md`.
- Current live SHA: `76aae070e7452f5b7b233b790c39d5c864aa19a0`.
- The earlier Main10 SHA `169025a...` is stale.
- Direct source inspection found literal package residue inside the executable fragment.
- Confirmed malformed sequences occur after `_loadLicenseData()`, after `_buildFullForm()`, and after `_bindSaveButtons()`.
- Confirmed file tail is polluted after `window.RW_Views = RW_Views;` by:
  `}` + `]` + `};`
- This means the current Main10 source is syntactically corrupted and must not enter Assembly.

### Root cause established

The prior surgical package structure was inserted into the Main10 source fragment itself. The remedy is not to delete individual `}, {` fragments. The safe repair is whole-unit replacement of:

1. `RW_OwnerLicense`
2. `RW_Views`

### Candidate validation

A clean Main10 candidate was reconstructed and validated locally:

- `249 lines`
- `19458 bytes`
- `node --check = PASS`
- `RW_OwnerLicense` declaration count = 1
- `window.RW_OwnerLicense` assignment count = 1
- `RW_Views` declaration count = 1
- `window.RW_Views` assignment count = 1
- package tail marker = 0

### Candidate functional corrections

- No invented `trial` state when Company Context or license data is unavailable.
- Current authenticated email only populates `owner-current-email`.
- `owner-new-email` remains blank for an intentional new address.
- Password confirmation is enforced before `auth.updateUser`.
- Basic email syntax is checked before `auth.updateUser`.
- Missing authenticated session is rejected before `save-settings` call.
- `finance -> finance` permission routing.
- `hr -> hr` permission routing.
- Explicit titles for finance / HR / CRM / comprehensive reports.
- Unknown route uses `التبويب غير معروف`.

### Exact owner action

Do **not** apply `MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js` blindly; it is historical and its recorded source SHA is stale relative to the live source.

Use the following surgical boundaries on the CURRENT `Current/PWA/main2/main10.md`:

- Find the exact first line `var RW_OwnerLicense = (function() {`.
- Delete everything through the exact full line `window.RW_OwnerLicense = RW_OwnerLicense;`.
- Replace that complete unit with the corrected `RW_OwnerLicense` unit recorded in Report132.
- Find the exact first line `var RW_Views = {`.
- Delete everything through the exact full line `window.RW_Views = RW_Views;`.
- Replace that complete unit with the corrected `RW_Views` unit recorded in Report132.
- Do not separately delete `}, {` markers.
- After replacement, Main10 must end exactly at `window.RW_Views = RW_Views;`.

### Production status

No Production migration was proven necessary for Main10 R2, and no Production database/data change was made for this task.

### Validation status

```text
MAIN10 SOURCE PATH = VERIFIED
MAIN10 CURRENT SHA = VERIFIED
MAIN10 LIVE SOURCE = SYNTAX CORRUPTED
MAIN10 FORENSIC R2 = COMPLETE
CORRECTED CANDIDATE = NODE CHECK PASS
OWNER SOURCE EDIT = NOT PERFORMED BY ASSISTANT
OWNER APPLY = PENDING
POST-APPLY FULL READ = PENDING
POST-APPLY NODE CHECK = PENDING
POST-APPLY STRUCTURAL AUDIT = PENDING
BROWSER/E2E = PENDING
PRODUCTION RUNTIME CLOSURE = PENDING
ASSEMBLY = DEFERRED
GLOBAL GOLD/DIAMOND = OPEN
MAIN10 = NOT CLOSED
```

## Read/Validation Limitation

The current Main10 source was fully reconciled through the Git blob and exact line reads sufficient to establish its corruption and EOF. Executable `node --check` was run on the corrected candidate, not on the corrupted live source; no live-source PASS is claimed.

This session also did not perform an independent full-content audit of every line in Main1–Main11 sufficient to declare all eleven fragments functionally complete. That remains a separate requirement before Assembly.

## Current checkpoint for next session

Owner applies the whole-unit Main10 replacement from Report132, then the next session must re-read Main10 from line 1 through EOF, execute syntax validation on the real post-apply source, run structural/duplicate/brace/string/router checks, then proceed to Browser/E2E and only then runtime/Assembly decisions.
