# BACKUP CTO 10 — UI FEATURE PARITY MEMORY

## Purpose
Preserve the non-negotiable rule that application rewrites must preserve all owner-valued features from the original implementation.

## Gold reference files
The following were identified as strong UI references and must be reviewed before declaring a new UI Gold:
- `PWA/warehouse/returns.html`
- `PWA/warehouse/picker.html`

## Primary files under repair
- `PWA/warehouse/vouchers.html`
- `PWA/sales/van-sales.html`

## Original-source rule
The original application is the behavioral baseline. The new implementation must be compared against it before deployment.

Compare at minimum:
- feature inventory;
- user actions;
- validations;
- search behavior;
- dropdown/lookup behavior;
- permissions and role gates;
- loading/error/empty states;
- offline/online behavior where applicable;
- API/RPC calls;
- data fields consumed;
- status transitions;
- notifications;
- edge cases;
- audit/trace information;
- visual/interaction conventions used by Gold reference applications.

## Manual Voucher UX requirements established by Owner
For source/target branch transfers:
- select From branch from a dropdown;
- select To branch from a dropdown.

For representatives:
- smart search/dropdown should be used as in Gold applications.

For vehicles:
- warehouse selects the vehicle from a dropdown/list coordinated with Fleet/Movement administration.

Vehicle and representative are separate selections/concepts.

## Deployment rule
Never declare a candidate UI ready merely because it renders or because RPC tests pass.
A UI release requires:
Original → Feature Matrix → Candidate → Static Audit → Runtime Contract Test → Production Smoke → Owner/CTO GO.

## No-feature-loss rule
No existing working feature may be removed, simplified, or silently changed because a new architecture is preferred. If a feature is obsolete, record the owner decision explicitly.

## Backend/UI boundary
Business rules belong in Core/DB/RPC/Edge capabilities. UI coordinates and presents them. The UI must not become a second inventory engine.
