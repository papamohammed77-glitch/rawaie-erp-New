# RAWAEA ERP — Vouchers / Shared PWA Core — Single Source Governance

## EVENT
- Event ID: `VCHR-CORE-20260828-001`
- Date: 2026-08-28
- Scope: `Current/PWA` shared runtime and `Current/PWA/vouchers.html`
- Authority: Production Supabase + current Git; governing principles in `doc/Draft/medhat/تقرير مبادئ حاكمة` and `doc/Draft/medhat/برومبت 72`

## Governing Rules

### 1. Single Shared Core
The only canonical shared PWA core is:
`Current/PWA/core.js`

No assistant, developer, CTO, workflow, migration, or compatibility layer may create or maintain a second shared `core.js` outside `Current/PWA`.

`Current/core.js` is prohibited and is intentionally absent.

### 2. Single Service Worker Source
The canonical worker files are:
- `Current/PWA/register-sw.js`
- `Current/PWA/sw.js`

PWA pages must resolve these resources locally from `Current/PWA` unless a future Target Architecture explicitly changes the deployment layout.

### 3. Source-of-Truth Rule
Before changing a shared runtime file:
1. read the current file in `Current/PWA`;
2. verify the current `main` commit;
3. verify all current consumers;
4. verify the Production-facing contracts affected by the change;
5. record the event and resulting commit.

### 4. No Compatibility Duplication
A path mismatch is fixed by correcting the consumer/deployment path or canonical layout, not by creating a duplicate shared implementation.

### 5. Vouchers Responsibility
`vouchers.html` remains an operational UI/client capability. It must not become an autonomous Physical Stock engine. Physical movement must converge on the canonical server-side inventory contract.

### 6. Evidence Hierarchy
For this governance boundary:
`Production → Current Git → persisted evidence → historical reports`

Historical reports can explain intent and history but cannot override current Production or current Git.

## Change Record — 2026-08-28

### Attempt 1
A temporary one-shot canonicalization workflow initially normalized `core.js`/registration paths but failed its validation because it did not catch every `RW_SW.register('../sw.js')` usage.

Status: `FAILED VALIDATION — NOT CLOSED`

### Attempt 2
The workflow was widened to normalize the complete `Current/PWA` runtime path surface.

Status: `SUCCESS`

Final canonicalization commit:
`fd7a597198027e061b79039634af0091682aff3f`

The one-shot workflow then removed itself.

### Follow-up correction
Direct inspection of `Current/PWA/register-sw.js` showed that the bootstrap file itself still registered `../sw.js` even after page-level normalization. The bootstrap was corrected to local `sw.js`.

Correction commit:
`b38cfd917217fe73a53f05b1542d75c014eea1eb`

### Documentation reconciliation
The earlier voucher forensic report contained an obsolete statement that `Current/core.js` should remain as a compatibility entry point. That statement was explicitly superseded and the report was updated.

Documentation reconciliation commit:
`46302a77b94fab2ee0cf2ca3128e3e96ae8e567a`

## Final Verified State
- `Current/PWA/core.js` exists.
- `Current/core.js` is absent.
- `Current/PWA/register-sw.js` exists and registers `sw.js`.
- `Current/PWA/sw.js` exists.
- `Current/PWA/vouchers.html` references `core.js` locally.
- The temporary canonicalization workflow is absent after self-removal.

## Runtime Boundary
This governance change is source/layout verified in Git. It is not by itself proof of browser-runtime E2E because no live browser/devtools session was available during this execution.

## Future CTO / Assistant Instruction
Never recreate `Current/core.js` to solve a relative-path problem. Treat `Current/PWA/core.js` as the only shared frontend runtime source. Any required compatibility behavior must be implemented at the actual consumer/deployment boundary and recorded here before being merged.