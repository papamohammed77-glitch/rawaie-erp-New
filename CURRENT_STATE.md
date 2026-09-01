# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git `main` HEAD, Production Supabase, deployed Edge Functions, and qualifying runtime evidence.
- Historical reports/prompts are evidence only; direct Git/DB/Deployment facts override them.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Browser E2E is PAUSED by explicit user directive and is not a PASS or FAIL in this round.
- Field/production trial is DEFERRED.
- No reconstruction of MAIN1→MAIN11, no source-copy rewrite, no overlay-based closure, and no speculative production mutation are authorized.

## LAST VERIFIED EVENT
### P124-015 — FORENSIC CONTINUITY AND CLOSURE STATUS
- Direct source, repository, Production Supabase, deployed Edge Functions, and the Hany report chain were used as the basis for this state update.
- Hany Report 10 was created at `doc/Draft/Hany/تقرير تنفيذي 10` and records the forensic timeline, failure causes, remediation, self-audit, and exact next action.
- MAIN1 contract mapping is CLOSED at the static/source level: shell, auth/session, tenant context, owner/license, permissions, navigation, data, audit, workflow, notification, search, PWA lifecycle, and specialized-app delegation are represented in the target lineage.
- Production confirms `post_stock_movement` as the canonical Physical Stock writer and confirms the bulk-adjustment path requires canonical item identity.
- Production CRUD/Audit functions examined are JWT-protected and critical CRUD paths derive tenant context from authenticated `users.company_id`.
- Browser E2E is intentionally paused. Field trial is intentionally deferred.

## KNOWN PRODUCT GAP
The remaining product-level gap is bulk stock upload identity propagation in `Current/PWA/New-main`:
- preserve `mappedItem.id` as `_uploadFileData[f].item_id`;
- send canonical `item_id` in the bulk adjustment payload while retaining `item_code` for compatibility.

Required target expressions:
```text
if(mappedItem){_uploadFileData[f].item_code=mappedItem.item_code;_uploadFileData[f].item_id=mappedItem.id;}
items.push({item_id:_uploadFileData[u].item_id||null,item_code:_uploadFileData[u].item_code||_uploadFileData[u].barcode,qty:_uploadFileData[u].qty});
```

## FAILURE ROOT CAUSES IDENTIFIED
1. State drift between CURRENT_STATE and later code changes.
2. Scope drift into broad reconstruction/overlay work.
3. Static labels being mistaken for behavioral parity.
4. Clean-room executor `IndentationError` stopping before persistence.
5. Validator false positive caused by matching literal `<script>` text inside JavaScript.
6. Runner working-tree evidence being confused with Git blob evidence.
7. A legacy `save-item` Production path directly writing opening stock to `stock_branches`, bypassing the canonical stock engine; this was remediated to RPC architecture.
8. Temporary forensic tooling became part of the test variable instead of remaining an external verifier.

## PRODUCTION STATUS
- `post_stock_movement`: PRESENT / SECURITY DEFINER / canonical stock writer.
- `reserve_stock`: PRESENT / SECURITY DEFINER.
- `post_journal_entry`: PRESENT / SECURITY DEFINER.
- Sensitive tables inspected: RLS ENABLED.
- Main CRUD/Audit Edge Functions inspected: JWT protected.
- Workflow/notification policy hardening was applied and rechecked.

## CURRENT GATES
| Gate | Status |
|---|---|
| Master continuity | CLOSED |
| Prompt 124 continuity | CLOSED |
| MAIN1 source mapping | CLOSED |
| MAIN1 static contract presence | CLOSED |
| Production canonical stock engine | CLOSED |
| Production JWT/RLS baseline | CLOSED |
| Production opening-stock architecture | CLOSED at RPC architecture level |
| Bulk-upload target `item_id` repair in final blob | OPEN — direct final blob proof still required |
| Final New-main syntax | OPEN |
| Final document closure | OPEN |
| No direct stock writer in New-main | OPEN |
| Legacy `main.html` integrity | OPEN |
| Browser E2E | PAUSED BY DIRECTIVE |
| Owner/Non-Owner E2E | PAUSED / UNPROVEN |
| Tenant-isolation E2E | PAUSED / UNPROVEN |
| Service Worker runtime | PAUSED / UNPROVEN |
| Field trial | DEFERRED |
| Git→Production source lineage | OPEN |
| GOLD | NOT YET CLAIMED |
| DIAMOND | NOT YET CLAIMED |
| COMPLETE | NOT YET CLAIMED |

## DO-NOT-REPEAT
- A workflow trigger is not persistence proof.
- A runner checksum is not a Git blob SHA.
- Historical reports are not current truth.
- Do not reconstruct MAIN1→MAIN11.
- Do not create a second Physical Stock writer.
- Do not resume Browser E2E during the explicit pause.
- Do not claim 100% closure before the target blob and required evidence are actually verified.

## NEXT AUTHORIZED ACTION
`P124-016 — DIRECT_TARGET_BLOB_REPAIR_AND_VERIFICATION`
1. Read `Current/PWA/New-main` directly from Git.
2. Verify whether the two exact `item_id` changes are already present.
3. If absent, persist only those two changes into `Current/PWA/New-main`.
4. Verify the resulting Git blob SHA and exact diff.
5. Run non-browser syntax/document/contract checks.
6. Verify `Current/PWA/main.html` integrity.
7. Update this ledger with exact evidence.
8. Keep Browser E2E and field trial deferred.
