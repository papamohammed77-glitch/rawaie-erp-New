# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-12 — MAIN4 FORENSIC RECHECK

### GOVERNING TARGET — NON-NEGOTIABLE
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع ولا يُتعامل معه كإضافات شكلية.

الحوكمة الحاكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

## SOURCE-OF-TRUTH GOVERNANCE
- Production الحالية هي حقيقة التنفيذ.
- Git هو المصدر القانوني القابل لإعادة الإنتاج، وليس بديلًا عن Production.
- التقارير التاريخية أدلة جنائية وليست حقيقة حالية.
- Source of Truth التحريري للملف الأم: `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` مرجع تاريخي فقط.
- `Current/PWA/New-main` مرحلة تاريخية موقوفة وليست مصدر مراجعة حالي.
- `forensic_main_assembly.yml` يتبع `Current/PWA/main2` ولا يجب أن يعود إلى `Current/PWA/main`.
- Final assembly remains deferred until all owner fragment work and final integrated validation are complete.

## PREVIOUS CHECKPOINTS
- Report121: `doc/Draft/Reprots/Report121_Main2_Forensic_Recheck_20260911.md`.
- Report122: `doc/Draft/Reprots/Report122_Main3_Forensic_Recheck_20260911.md`.
- Main3 remains Owner-editable; its four surgical changes are still open until applied and reverified.

## MAIN4 — FORENSIC RESULT
Current source of truth: `Current/PWA/main2/main4.md`.
Current blob SHA: `e89d29e4164c68784c109292f27d4d77df240557`.
Current repository size reported: 64,146 bytes.
EOF verified: content exists through the `window.RW_TeleSales = RW_TeleSales;` closure; a later read starting at line 1360 returned empty content. The working file was not modified by the assistant.

### MAIN4 FUNCTIONAL AREAS
- `RW_POS` — Point of Sale.
- `RW_Roles` — User role management.
- `RW_TeleSales` — Telesales order/customer workflow.

### HISTORICAL COMPARISON
`Original/PWA/main/main4.md` was reviewed as historical reference only. The current Main4 has materially evolved beyond the original in company-scoped settings for POS and role/tele-sales integration; historical code was not restored merely because it was different.

## MAIN4 PRODUCTION CHANGES — EXECUTED
### Roles security closure
Production was directly changed and re-verified:
- `save-role` Edge Function: v7 ACTIVE, JWT required. Actor company is derived from authenticated `users.auth_id`; `roles` permission or `*` is required; update is company-scoped; system-role state cannot be escalated through the payload.
- `delete-role` Edge Function: v3 ACTIVE, JWT required. Actor company and `roles` permission are required; role lookup/delete is company-scoped; system roles cannot be deleted; assigned roles are protected.
- `seed-roles` Edge Function: v4 ACTIVE, JWT required. Company is derived from authenticated actor; no hardcoded company context; existing roles are checked within the actor company.
- `roles` RLS: the prior `Allow all for all` policy was removed. SELECT/INSERT/UPDATE/DELETE now require current tenant company and `roles` permission.

Verification after deployment confirmed the four intended `roles` policies are present and `مدير النظام` / `مدير عام` remain system roles for the existing company.

No Main4 source file was directly modified by the assistant.

## MAIN4 OWNER SURGERIES — REQUIRED BEFORE SOURCE CLOSURE
### MAIN4-N1 — POS session guard
Current line 364.
Search for this exact line:

`        var token = sessionRes.data.session && sessionRes.data.session.access_token;`

Add these complete lines immediately AFTER it:

```javascript
        if (!token) {
            hideLoader();
            showToast('انتهت الجلسة', 'error');
            return;
        }
```

Do not delete or shorten the existing token line.

### MAIN4-N2 — Roles delete button must not present a forbidden system-role action
Current line 539.
Search for this exact complete line:

```javascript
        (isEdit ? '<button type="button" id="btn-delete-role" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fas fa-trash-alt ml-1"></i> حذف</button>' : '') +
```

Delete the complete line and replace it with this complete line:

```javascript
        (isEdit && !role.is_system ? '<button type="button" id="btn-delete-role" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fas fa-trash-alt ml-1"></i> حذف الدور</button>' : (isEdit && role.is_system ? '<span class="px-4 py-2.5 bg-slate-100 text-slate-500 rounded-xl font-bold mr-auto"><i class="fas fa-lock ml-1"></i> دور نظامي</span>' : '')) +
```

### MAIN4-N3 — TeleSales customer opening debt must not be an ordinary editable master-data field
Current line 929.
Search for this exact complete line:

```javascript
    '<div class="flex flex-col"><label>الرصيد الحالي (' + currency + ')</label><input id="cust-debt" type="number" value="0" class="p-2.5 bg-gray-50 border rounded-lg"></div>' +
```

Delete the complete line and replace it with:

```javascript
    '<div class="flex flex-col"><label>الرصيد الحالي (' + currency + ')</label><input id="cust-debt" type="number" value="0" readonly disabled class="p-2.5 bg-gray-100 border rounded-lg text-gray-600 cursor-not-allowed"><p class="text-xs text-gray-500 mt-1">الرصيد المالي يُعرض للقراءة فقط ويُدار من المسار المالي الرسمي.</p></div>' +
```

### MAIN4-N4 — Preserve the existing payload shape but prevent UI-supplied opening debt
Current line 953.
Search for this exact complete line:

`              debt: parseFloat(document.getElementById('cust-debt').value)||0,`

Delete the complete line and replace it with:

```javascript
              debt: 0,
```

This keeps the payload key available for compatibility while preventing the TeleSales master-data dialog from creating or changing a financial opening balance.

## MAIN4 OWNER-SCOPE FORENSIC FINDINGS — DO NOT PATCH WITHOUT CONTRACT EVIDENCE
1. TeleSales branch visibility currently derives company branches and stock, but `users.allowed_branch_ids` exists in Production. A complete per-user branch restriction contract for this module was not proven during this Main4 session; no speculative filter was added.
2. POS correctly sets `orderHeader.operation_id = crypto.randomUUID()` and sends it to `save-sales-invoice`. This aligns with the current Production idempotency contract; it must not be replaced with a fixed or derived static key.
3. TeleSales remains a non-invoiced order flow; no stock decrement was introduced because physical stock mutation belongs to the later fulfillment lifecycle.
4. No `(قيد التطوير)` marker was found by exact repository search. Absence of the phrase is not evidence of Gold/Diamond completeness.

## VALIDATION STATUS
- Main4 was re-read from the beginning through its EOF boundary using sequential source reads; its final `RW_TeleSales` IIFE closure was verified.
- `.github/workflows/validate-main2-fragments.yml` currently exists and performs `node --check` on Main1–Main11 plus existence checks.
- The GitHub connector did not expose a reliable post-change workflow run for this checkpoint; therefore `CI PASS` is NOT claimed.
- Static source closure review found the Main4 IIFE boundaries structurally closed; this is not a substitute for CI/browser E2E.
- The full 11-fragment directory was rechecked: Main1–Main11 are all present under `Current/PWA/main2` with the expected canonical paths.

## TESTS / FAILURES / NON-FABRICATED RESULTS
- Production `roles` policy verification: PASS.
- Production `save-role` v7 deployment: PASS / ACTIVE.
- Production `delete-role` v3 deployment: PASS / ACTIVE.
- Production `seed-roles` v4 deployment: PASS / ACTIVE.
- No destructive business-data cleanup was performed as part of this Main4 review.
- A local network attempt to fetch raw GitHub content for external syntax execution failed because the runtime has no external DNS/network access. This is recorded as an execution limitation, not a syntax result.
- No browser E2E claim is made before owner source surgeries and final assembly.

## GOLD/DIAMOND GATE
Main4 is not yet declared Gold/Diamond closed.

The current source provides real POS, role management, and TeleSales workflows, but the remaining proven gaps include financial-opening-balance UX safety and system-role UX protection. Further functional depth is still required for the project-wide Gold/Diamond target, especially in downstream finance, HR, CRM, and reporting fragments. Those additions must be driven by their actual contracts and Production evidence, not by generic feature cloning.

## SELF-AUDIT
### What was proved
- Main4 current canonical path and blob SHA.
- Main4 EOF boundary.
- Production role security and tenant isolation improvements are deployed.
- `items.item_code` is globally unique in current schema, so POS item lookup by code remains aligned with the current identity contract.
- Assembly manifest already points to `Current/PWA/main2`.

### What was not proved
- CI syntax PASS after the current Main4 state.
- Browser E2E for POS/Roles/TeleSales after Owner surgeries.
- Complete per-user branch restriction contract for TeleSales.
- Gold/Diamond completion of Main4 or the entire 11-fragment system.

### What was fixed
- Production Roles capability security and tenant isolation.
- System-role deletion guard at Production level.
- Seed-role hardcoded-company drift in Production.

### What remains
- Owner must apply MAIN4-N1..N4 exactly.
- Then Main4 must be re-read to EOF and syntax-validated.
- Only after the owner source changes are applied should the next functional Gold/Diamond gap be opened.
- Final assembly remains deferred.

## FINAL CLOSURE STATUS
`MAIN4 FORENSIC RECHECK = COMPLETED`

`MAIN4 PRODUCTION SECURITY CLOSURE = COMPLETED`

`MAIN4 OWNER SOURCE SURGERY = REQUIRED`

`MAIN4 GOLD/DIAMOND FUNCTIONAL COMPLETION = NOT YET CLOSED`

`FINAL ASSEMBLY = DEFERRED`
