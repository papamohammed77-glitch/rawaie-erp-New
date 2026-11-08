# Report645 — Parent Finance Cash Custody Lifecycle Runtime Hotfix

**Date:** 2026-11-08 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-08-645  
**Previous checkpoint:** LVE-2026-11-08-644  
**Scope:** Parent Finance sub-tab crash caused by RW_Finance_Custody.stop being missing; surgical lifecycle correction in the operational Parent file; static and controlled asynchronous lifecycle verification; SMART ERP read-only contract revalidation; source/deployment reconciliation.  
**Final status:** FIX APPLIED — E2E PARTIALLY VERIFIED.

---

## 1. Executive result

The Parent Finance tab crash was reproduced from the exact current GitHub source and traced to a missing method in the employee-custody module interface. The Finance dispatcher invoked RW_Finance_Custody.stop() whenever the selected Finance sub-tab was not employee-custody, but the module exported only render, refresh and issue. The resulting TypeError stopped renderSubTab before the selected Finance sub-tab could finish rendering.

A narrowly scoped repair was committed directly to operational main. The Finance custody module now exports stop(), invalidates obsolete asynchronous loads, prevents stale results from replacing the active Finance content, and detaches its click handler when the custody sub-tab is left.

**GitHub source correction: APPLIED AND RE-READ.**  
**JavaScript static compilation: PASS (6/6 inline blocks).**  
**Controlled lifecycle simulation: PASS.**  
**SMART ERP Production: unchanged; read-only contracts and zero custody-row counts verified.**  
**Cloudflare deployment of the correction: NOT CONFIRMED.**  
**Authenticated Finance browser E2E: NOT RUN.**

Do not label the issue deployed or E2E-closed until the later Cloudflare artifact and authenticated Parent Finance route are verified.

## 2. Governing sources reviewed

The following source documents were opened and reviewed for this task:

- writing-block-8-10.md — full 1,300-line instruction file; SHA 39f18748a8a3cf633a04506216cc39fd98de523d.
- الدستور التشغيلي الدائم.md — permanent execution, business-integrity, approval, surgical-change and evidence rules; SHA 3a6b1e220af8509e314e94df76563bbc6f84910d.
- CURRENT_STATE.md — LVE644 opening state and prior history; SHA 2c187e49f69f46c9126eca8d8ee339033f34d92e before this checkpoint update.
- Report644_EMPLOYEE_CUSTODY_UI_INTEGRATION_AND_RUNTIME_GAP_REVIEW_20261108.md — immediate preceding implementation and runtime report; SHA 87cf1c95e56000f268eedd967d66ac115bb670b8.
- Report643_DAILY_EMPLOYEE_CUSTODY_CONTINUITY_REVALIDATION_20261108.md — prior continuity, Finance contract and runtime boundaries; SHA 7fea83926a512962c88e0824c4997a7b810d4e86.
- Report545_GOVERNANCE_AUDIT_AND_DELIVERY_OWNER_PATCH_RESET_20261029.md — governance and Owner ChangeSet lineage; SHA e153396709ecfcc0552347db84e37c98ad8bcdd6.

The latest direct owner instruction in this task explicitly authorized a surgical operational-file correction. That task-specific authorization was used only for the defective Finance lifecycle contract. No Supabase schema, data, RPC, RLS, ACL, Edge Function, inventory or financial posting change was authorized or made.

## 3. Forensic proof of the root cause

### 3.1 Parent Finance caller

Before the correction, current main.html line 18562 contained the unguarded call:

    if (tab !== 'employee-custody' && typeof RW_Finance_Custody !== 'undefined') RW_Finance_Custody.stop();

The object-existence test did not test whether stop was a function. When the module object existed without that method, JavaScript raised the reported TypeError.

### 3.2 Module interface

The current Finance custody IIFE at approximately lines 23174–23213 ended with:

    return {render:render,refresh:render,issue:issueFirst};

Therefore stop was not part of the module's public interface. The exact source matched the user-provided stack location and error.

### 3.3 Report/source conflict

Report644 §3.1 stated that the Finance custody renderer had its own serial and exposed stop(). This statement was not supported by the operational source or by commit 68de9bfb6213d6ac7f975bff0aea76e14a1f874d.

The actual 68de9b commit added the Finance dispatcher serial and the call to RW_Finance_Custody.stop(), as well as the Driver stop call, but did not edit the Finance custody IIFE to implement stop or its render serial. The caller had been added without the corresponding module contract. The current source, not the report assertion, was treated as authoritative.

The module contains earlier duplicate declarations of bind() and render(). The repair changed only the later, effective declarations; it did not attempt an unrelated deduplication or rewrite of the module.

## 4. Surgical correction applied

**Repository:** papamohammed77-glitch/erp-frontend  
**Branch:** main  
**File:** companies/company-1/main.html  
**Fix commit:** 9aef827a8f25d7f7f7ff6bb7ba2cfd389edc783b  
**New file blob:** 84dd2ba145c9508d1ff334049be24e575f60d4ad

Only this one operational file changed in the fix commit: +6 / -4 lines in GitHub's diff, with a net content-size delta of 484 characters.

The following bounded changes were made:

1. Added a Finance-custody render serial.
2. Changed the existing asynchronous load to build a local snapshot and assign it to module state only when its request serial is still current. An obsolete request can no longer overwrite the current snapshot.
3. Changed the effective bind() to accept the exact target element and safely return if that element no longer exists.
4. Changed the effective render() to capture its target DOM element and request serial. Both success and error callbacks verify that the serial is still current and that the same target element remains active before updating the DOM.
5. Added stop(), which increments the render serial to invalidate pending callbacks and detaches the Finance-content click handler.
6. Exported stop() in the public module object so the existing renderSubTab() call is valid.

The Finance dispatcher at line 18562 remains intact. No change was made to the custody RPC payloads, Finance permissions, generic expense voucher, journal logic, Treasury operations, or Buyer/Driver modules.

## 5. Validation and tests

### 5.1 Static JavaScript validation — PASS

All six inline JavaScript blocks extracted from the updated main.html compiled successfully. No syntax failures were reported.

### 5.2 Controlled lifecycle simulation — PASS

A controlled asynchronous test exercised the actual updated custody module:

- Started a custody render with four pending data reads.
- Called stop() before those reads completed.
- Completed the old requests and verified the render returned false and did not replace the active content.
- Started a fresh render and completed its reads.
- Verified that the fresh render returned true, the custody panel was produced, and the click handler was bound.

This specifically validates the stale-request lifecycle that the earlier report claimed to protect. It is a controlled module simulation, not a browser-based authenticated E2E test.

### 5.3 Re-read after commit — PASS

The new main.html blob was re-fetched from GitHub. It contains the stop export, serial-guarded load, target-identity checks and guarded effective renderer. The same six inline script blocks passed compilation again.

## 6. Git history and latest-source reconciliation

- Parent HEAD immediately before the fix: 121c856508122e5b1f1008453526a2aece47f83a.
- Parent main.html blob before the fix: 5a4aacf5af8100db6e3c434c49fea57784857594.
- Fix commit: 9aef827a8f25d7f7f7ff6bb7ba2cfd389edc783b.
- Fix commit parent: 121c856508122e5b1f1008453526a2aece47f83a.
- Fix commit changed files: companies/company-1/main.html only; 6 additions, 4 deletions.
- The subsequent operational HEAD observed during verification is 0a08e944efc8c01e4ee87f0096ebf93fb736b7c6. It is a direct child of the fix commit and changes only _forensic_current_main_extract.md (+1838/-1838).
- The current Parent main.html path was independently fetched after that later commit and still resolves to blob 84dd2ba145c9508d1ff334049be24e575f60d4ad.

Thus the fix remains present in the current operational main tree; the later forensic-extract commit did not overwrite it. The branch update used an expected-head check and a non-force ref update.

## 7. SMART ERP Production — read-only verification

Project fiilmooggumokxanwiyx (SMART ERP) was read directly and reported ACTIVE_HEALTHY, PostgreSQL 17.6.1.121.

The existing custody RPC signatures remain present, including issue, acknowledgement, additional advance, expense submission/review and settlement. Both finance_save_expense overloads remain present. No database object or function was changed for this frontend TypeError.

The five custody business tables were read and returned zero rows:

| Table | Rows |
|---|---:|
| buyer_custodies | 0 |
| buyer_custody_advances | 0 |
| buyer_custody_expenses | 0 |
| buyer_custody_payments | 0 |
| buyer_custody_settlements | 0 |

No QA record, attachment, treasury movement, cash_box movement, journal entry, inventory movement, supplier balance movement, DDL, RPC replacement, RLS/ACL change or Edge deployment was made by this hotfix.

## 8. Cloudflare and browser runtime

The Cloudflare dashboard tab was readable and showed automatic deployments enabled. The latest deployment visible in that captured dashboard context still referenced operational commit 121c856508122e5b1f1008453526a2aece47f83a and URL https://97c7a4d0.rawaea-erp.pages.dev/. It did not show the later fix commit 9aef827 in the captured deployment list, nor expose a matching Success deployment for the fix.

The Parent browser tab showed the application shell/login view and menu content, but the available read-only browser context did not permit navigating, clicking Finance tabs or executing an authenticated workflow. Therefore Cloudflare source/artifact parity and authenticated Finance runtime behavior remain UNVERIFIED.

Required deployment/runtime acceptance:
1. Confirm a successful Production Cloudflare deployment whose source commit is 9aef827 or a later descendant containing main.html blob 84dd2ba.
2. Open the deployed Parent using an authorized Finance session.
3. Open Finance/Accounts, confirm the TypeError is absent, and confirm the selected Finance sub-tab renders.
4. Open employee custody, navigate away while its data reads are pending, then reopen it. Confirm no stale response overwrites the active sub-tab and the custody action handler works.
5. Confirm there are no new JavaScript errors and that opening/navigating tabs produces no cash, journal, Treasury or inventory side effects.

## 9. Separate Console warning

The Tailwind CDN warning at index:64 is unrelated to the missing stop() method and does not explain the Finance TypeError. It remains a separate production-build hygiene item; no CSS/build pipeline change was bundled into this hotfix.

## 10. Readiness, evidence and next action

**CONFIRMED**
- Root cause and exact caller/module API mismatch.
- Surgical fix committed to operational main.
- Current main.html blob retains the fix after the later forensic-only commit.
- All six inline scripts compile.
- Controlled stop/stale-render/fresh-render simulation passes.
- SMART ERP remains ACTIVE_HEALTHY; existing RPC contracts remain present; custody tables remain empty.

**UNVERIFIED**
- Cloudflare deployment of commit 9aef827 or descendant.
- Authenticated Finance browser E2E against the deployed artifact.
- Actual Console result after opening the Finance tab in the authenticated session.

**Final status:** FIX APPLIED — E2E PARTIALLY VERIFIED.

**Next exact action:** verify Cloudflare Production deployment of 9aef827 or a later descendant, then run the authenticated Finance navigation and stale-render acceptance sequence in §8. Do not mark the task fully closed before those checks pass.
