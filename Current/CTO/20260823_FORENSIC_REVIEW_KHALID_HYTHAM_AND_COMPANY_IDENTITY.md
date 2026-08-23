# RAWAEA ERP — FORENSIC REVIEW: KHALID / HYTHAM / COMPANY IDENTITY

Date: 2026-08-23
Production: SMART ERP (`fiilmooggumokxanwiyx`)
Repository: `rawaie-erp-New`

## 1. Truth hierarchy used

Production runtime/database/deployed Edge definitions > Current Git > Current CTO/evidence records > historical/original sources > previous reports.

No historical closure claim is treated as current truth without re-verification.

## 2. Historical chain review

The Hussin Prompt 11–45 chain was reviewed as a historical evolution record, including the known reversals/corrections around:
- voucher semantics;
- owner/permission semantics;
- auth/public.users identity;
- tenant isolation;
- inventory centralization;
- item identity;
- vehicle/mobile branch semantics;
- PWA consumer binding;
- DirectSale target-stock behavior.

The chain demonstrates repeated historical corrections. Therefore later Production evidence overrides earlier "closed" language.

Prompt 49 explicitly established the correct engineering gate: no material unknown, no material conflict, no unverified claim, no unresolved Production/Current drift, no lost responsibility, no unclassified consumer, and no unproven critical runtime path before closure.

## 3. Khalid assessment

Khalid's strongest contribution is continuity/governance and financial reporting forensics. His Prompt-53 work correctly used Production reporting cores and made a surgical `finance-manager.html` change rather than rewriting the file. The report also correctly refused to modify `accountant.html` without a proven Treasury/COA consumer contract.

The current Production definitions now prove that the reporting-core direction survived: current reporting functions use authenticated company context and UUID-based journal-to-COA relationships.

Khalid's work is therefore assessed as:
- directionally correct;
- contract-conscious;
- appropriately surgical on PWA;
- NOT a complete financial closure;
- dependent on resolving Financial Tenant Identity and deployment lineage.

## 4. Hytham assessment

Hytham's strongest contribution is transactional/core execution. His accounting work created/used the canonical journal and cash posting boundaries, corrected real schema drift, preserved idempotency, and deliberately avoided inventing Treasury/COA mappings.

The current live `save_sales_invoice_atomic` confirms that the architectural direction survived: physical stock goes through `post_stock_movement`, cash uses `post_cash_receipt_atomic`, credit journal posting uses `post_journal_entry`, and customer credit uses `post_customer_ledger_entry`.

A material writer remains open: Van Credit still performs a direct `driver_ledger` INSERT. His PR #23 is still Draft/Open and Unmerged, so Git main is not the same artifact as deployed Production.

Hytham's work is therefore assessed as:
- technically strong and evidence-backed;
- correct to leave Driver Ledger open;
- correct not to modify `pos.html` unnecessarily;
- NOT fully merged/canonical in Git;
- NOT a complete writer-convergence or concurrency closure.

## 5. Production changes that supersede older reports

Current Production now contains `post_journal_entry`, `post_customer_ledger_entry`, `post_cash_receipt_atomic`, `post_cash_payment_atomic`, and the newer `receive_purchase_atomic` signature. Therefore older reports that said these objects were absent are historical snapshots, not current facts.

Current `save-sales-invoice` Edge deployment is v15 ACTIVE and passes operation identity/idempotency into `save_sales_invoice_atomic`.

## 6. Company identity forensic finding — CRITICAL

Before the owner-requested cleanup, Production contained three company records:

- `00000000-0000-0000-0000-000000000001` — الروائع — active runtime population: 24 public users, 23 linked Auth users, latest sign-in 2026-08-22.
- `73a141bd-157a-4c2c-8693-34e21325b943` — الروائع للتجارة — no active Auth user, no branches, no COA/Treasury.
- `da4ef704-88ac-4120-aa0e-65b92b2aa2bc` — الروائع للتوزيع — one active Auth user, 3 branches, 87 COA rows, one Treasury row.

The owner explicitly instructed that there should be one experimental company and requested deletion of the others.

A Production cleanup migration was then executed with a safety gate preserving `00000000-0000-0000-0000-000000000001`. The database now contains exactly one company: `00000000-0000-0000-0000-000000000001`.

The deletion was fully transactional and documented in `audit_log`; the deleted tenant's non-FK `erp_operation_registry` rows and its linked Auth user were also removed. Verification showed no residual public rows under the deleted company IDs and no residual Auth user for the deleted distribution tenant.

## 7. Post-cleanup forensic conflict discovered

After the deletion, older production-object memory was re-opened. `CTO/BACKUP_CTO/09_PRODUCTION_OBJECT_MEMORY.md` explicitly records `da4ef704-...` as the known active company and describes its MAIN branch, official experimental vehicle, and official test representative `van-sales@rawaea.com`.

Khalid's later Prompt-53 report also records that the financial/treasury domain lived under `da4ef704-...` while many operational users lived under `000...001`.

Therefore the historical evidence creates a material conflict with the runtime-user evidence used for the cleanup:

- runtime activity strongly identifies `000...001` as the only currently active user tenant;
- historical financial/experimental evidence strongly identifies `da4ef704-...` as the official experimental/financial tenant.

This means the semantic correctness of the company deletion is **NOT CERTIFIED**.

## 8. Current Production risk created by the cleanup

The remaining company `000...001` currently has no `chart_of_accounts` rows and no `treasury` row. Current sales-financial code requires company-scoped COA accounts and, for cash POS, exactly one active Treasury.

Therefore financial transactions for the retained tenant cannot be considered Production-ready until the authoritative company identity is proven and the required financial master data is present under that tenant.

No synthetic COA/Treasury data has been created.

## 9. Recovery posture

Do NOT invent or reconstruct COA, Treasury, customers, items, or users from memory.

Do NOT create a second company simply to make the system work.

Do NOT move users between companies without an explicit proven owner/contract decision.

The next closure unit must be a **Company / Financial Tenant Forensic Recovery and Canonicalization** unit that determines whether the intended experimental company was `000...001` or `da4ef704...` using:
- migration history;
- current Git/main tenant records;
- historical production object memory;
- audit-log snapshots;
- Auth identities;
- PWA consumers;
- financial master-data ownership;
- runtime evidence.

Only after the identity is proven should any company recovery/remapping occur.

## 10. Khalid next responsibility

Khalid owns:
**COMPANY / FINANCIAL TENANT IDENTITY RECOVERY + ACCOUNTING/TREASURY CANONICALIZATION + DEPLOYMENT LINEAGE**

He must resolve the company conflict first. No financial PWA redesign is authorized before that.

## 11. Hytham next responsibility

Hytham owns:
**POS WRITE-SIDE DRIVER-LEDGER CONVERGENCE + LIVE EDGE/GIT ALIGNMENT + HTTP E2E + TWO-SESSION CONCURRENCY**

He must not modify company membership, COA ownership, Treasury ownership, or `accountant.html` during this unit.

## 12. Final assessment

Inventory remains a regression foundation and is not the next reconstruction task.

Khalid = strong Continuity/Reporting/Governance track, but Company Identity is now a blocking forensic closure.

Hytham = strong Core/Runtime track, but Driver Ledger convergence, PR/main synchronization, authenticated HTTP E2E, and independent-session concurrency remain open.

Global Zero-Debt remains OPEN.

Autonomous CTO readiness remains NO.
