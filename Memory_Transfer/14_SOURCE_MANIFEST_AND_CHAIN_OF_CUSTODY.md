# SOURCE MANIFEST AND CHAIN OF CUSTODY

## PRIMARY GOVERNANCE SOURCE
`doc/Draft/medhat/MASTER_MEMORY_TRANSFER_DIRECTIVE_RAWAEA_ERP.md`
- Source SHA at direct read: `e8837dc54d51877fd37720c6b0f554376067207e`.
- Directive requires complete forensic memory transfer, current revalidation and no false closure.

## GOVERNING ENGINEERING PRINCIPLES
- `doc/Draft/medhat/تقرير مبادئ حاكمة`
- `doc/Draft/medhat/برومبت استكمال مهام`

## HISTORICAL SEQUENCE
`doc/Draft/Hussin/HISTORICAL_SEQUENCE_PROMPTS_11_TO_39.md`
- Historical consolidation SHA read: `896c57a812f4e8d0abbc12466aba565ac5cec54d`.
- Used for Prompt 11→39 reconstruction.

## LATE FORENSIC / CONTINUITY SOURCES
- `Current/CTO/20260821_KNOWLEDGE_MODEL_REBASELINE.md` — SHA `64dc690e3490f25bd388890429f0585c51d0f04b`.
- `doc/Draft/medhat/برومبت 47 وتقرير تنفيذه` — SHA recorded in source retrieval.
- `doc/Draft/medhat/برومبت 49` — SHA `e2534fe0a71e4a3fbae198b6cc7f8bc2c8381e72`.
- `Current/CTO/20260822_KHALID_PROMPT51_EXECUTION.md` — SHA `829d654507200ca40e0c92dc3e22948348b57204`.
- `doc/Draft/Hytham /تقرير هيثم 3` — SHA `877bd429d9db66114f69ca4982445ed2a62a2f93`.
- `doc/Draft/medhat/تقرير 52` — SHA `c0e73d07f4c19daa7d6c29c4a69f0722131d226c`.

## CURRENT PRODUCTION CHAIN
- Supabase project: `fiilmooggumokxanwiyx`.
- Snapshot UTC: `2026-08-23 03:41:38.004558`.
- Public functions: 45.
- Public tables: 62.
- RLS tables: 62.
- RLS policies: 102.
- Triggers: 38.
- Migration head: `20260822182733 fix_post_journal_entry_schema_drift_20260822`.

## CURRENT GIT CHAIN
- Repository: `papamohammed77-glitch/rawaie-erp-New`.
- Branch: `main`.
- Git HEAD at start of this package rebuild: `579722996367998327fda7340408f1ad32ce955f`.
- Current `start-picking` source SHA: `c34a64fad53524720d80eede9d4848612a334b5f`.

## REQUIRED CURRENT EDGE MAP
Critical live versions captured in the same session:
`start-picking v33`, `complete-picking v16`, `complete-loading v11`, `complete-return v24`, `create-stock-voucher v8`, `send-stock-voucher v19`, `receive-stock-voucher v21`, `complete-stock-voucher v4`, `cancel-stock-voucher v4`, `receive-purchase v12`, `save-sales-invoice v15`, `save-journal-entry v8`, `save-receipt-voucher v5`, `save-payment-voucher v3`, `save-daily-settlement v3`, `update-driver-ledger v1`, `complete-order-delivery v13`.

## HISTORICAL ARCHIVE SOURCES
- `rawaie-erp-review/Edge_Functions/original/`
- `Original/`
- `Current/`
- `Inventory/`
- `Evidence/`
- `Governance/`
- `SQL_Evidence/`
- `Rescue/`
- `CTO/`
- `Memory_Transfer/`

## KEY NON-EQUIVALENCES
- Git commit ≠ deployed Edge artifact.
- Migration file ≠ applied Production migration.
- Staging PASS ≠ Production runtime PASS.
- ACTIVE + HTTP 410 ≠ deleted function.
- Historical report ≠ current truth.
- Current memory package ≠ substitute for next Production snapshot.

## CHAIN-OF-CUSTODY LIMITATION
This manifest is evidence-grade for the sources actually reopened in this build. Full commit-by-commit repository history and every historical file body are not duplicated into this package. Where that evidence is not re-opened, the state is marked partial rather than invented.