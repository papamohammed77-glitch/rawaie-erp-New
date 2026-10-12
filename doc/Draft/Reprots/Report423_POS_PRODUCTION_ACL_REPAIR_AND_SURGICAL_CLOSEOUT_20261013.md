# Report423 — POS تكامل الكاشير: مطابقة Production، إصلاح ACL، والتعديل الجراحي المتبقي

**التاريخ:** 2026-10-13  
**النطاق الحصري:** `erp-frontend/companies/company-1/sales/pos.html`، عقدا `save-sales-invoice` و`complete-return`، Core المرتجع المرتبط، وسجلات الحالة.  
**قيود محفوظة:** لم يتم تعديل `main.html` أو `pos.html` التشغيلي. لم تُنشأ مبيعات أو مرتجعات اصطناعية في Production. تغييرات Production الأمنية الموثقة أدناه نُفذت مباشرة ثم أعيد التحقق منها.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** البيع النقدي من POS يجب أن يُعتمد من الخادم، ويكون قابلًا لإعادة المحاولة دون تكرار، ويُنشئ آثار المخزون والمحاسبة الصحيحة. المرتجع النقدي يجب أن يتحقق من إيصال القبض الأصلي ويرد المبلغ من الخزينة الصحيحة؛ لا يجوز للواجهة أن توحي بأن المرتجع لا يرد النقد إذا كان العقد الخلفي يردّه بشروط.
- **Architecture Understanding:** PWA منفصل؛ تهيئة POS عبر RPC مصادق عليه؛ حفظ البيع عبر Edge `save-sales-invoice` ثم `save_sales_invoice_atomic`؛ المرتجع عبر Edge `complete-return` ثم `complete_sales_return_credit_note_atomic` وCore المرتجع. لا حاجة مثبتة إلى Edge جديدة.
- **Database Understanding:** Production يحتوي على `orders`, `order_details`, `cash_box`, `credit_notes`, `erp_operation_registry`، وCore مركزي لحركة المخزون. تم فحص ACL الفعلي عبر `has_function_privilege` وليس عبر تقرير سابق فقط.
- **Historical Understanding:** قورنت نسخة POS التاريخية في `rawaie-erp-review/PWA/sales/pos.html`، SHA `6ad4da791b72260b922847246ebce93b552d2bad`، بطول 80,447 حرفًا/1,115 سطرًا، مع المصدر الحالي بطول 91,752 حرفًا/1,564 سطرًا.
- **Production Understanding:** جرى استرجاع المصدر المنشور مباشرة من Supabase للمسارين `complete-return` و`save-sales-invoice`، والاستعلام عن تعريفات SQL وACL الحية. آخر فحص SQL في هذه الدورة: `2026-10-12 22:46:18.477992+00 UTC`.
- **Current Understanding:** المصدر الحالي ما زال يحتوي قراءة `app_settings` عامة غير مقيّدة بالشركة في `_setupUser`، وخياري دفع بطاقة/مختلط قابلين للاختيار رغم عدم اكتمال عقد التسوية، ونص مرتجع يناقض عقد الرد النقدي.
- **Execution Confidence:** مرتفع للنتائج المستندة إلى المصدر وProduction SQL. لا يوجد دليل على E2E في متصفح Production في هذه الدورة؛ لذلك لا يُعلن إغلاق الواجهة أو 100%.

### سجل المصادر

- Current POS: `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html`, blob SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`.
- Historical POS: `papamohammed77-glitch/rawaie-erp-review/PWA/sales/pos.html`, blob SHA `6ad4da791b72260b922847246ebce93b552d2bad`.
- Current state read: `rawaie-erp-New/CURRENT_STATE.md`, blob SHA before this report `51bb0eb158c7d023d49046ef6c99629357190f45`.
- Prior forensic report read in full: `doc/Draft/Reprots/Report422_POS_SURGICAL_REVIEW_AND_PRODUCTION_RECONCILIATION_20261013.md`, blob SHA `65f01eafafa9f915fd11c8c53fbf5e6ca0d303ca`.
- The master governance file was fetched from the supplied repository path and its rules were applied: current Production/source evidence supersedes reports; reports are clues; preserve previous reports; do not edit `main.html` or the operational app.
- The exact supplied filename with the extra final `د` returns 404. Git commit search found the actual file at `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعدد`, commit `a456097f3326af2b18941992b903c3365c89aa10`; the full 10,965-character file was opened and reviewed. Its assessment is recorded below; it is no longer treated as unreviewed.

## 2. CURRENT PRODUCTION — FRESH FINDINGS

### Edge functions read from live Supabase

| Function | Production version | JWT verification | Production artifact hash |
|---|---:|---|---|
| `save-sales-invoice` | v18 | true | `43d20f1465725c4e273f717ac927c070d4b28be48241bd2c9c46a6d43bb40308` |
| `complete-return` | v26 | true | `801e390b195522caedfcf68bae8262bb91da06e909c1d43e9344490e3a81f34d` |

### Security defect discovered and repaired in Production

The previous Report422 stated that `complete_sales_return_credit_note_atomic` was executable only by `service_role`. A fresh live ACL check contradicted that statement: Production showed `authenticated_execute=true` for the exact seven-argument `SECURITY DEFINER` function.

The live function definition accepted `p_company_id` and `p_user_email` as parameters and did not itself bind those parameters to `auth.uid()`. The intended `complete-return` Edge validates the bearer token, resolves the active user by `users.auth_id`, obtains the company from that profile, and invokes the RPC using its service-role client. Therefore direct authenticated execution was an unnecessary bypass of the intended Edge→service_role→Core security boundary.

**Repair executed directly in Production:**

```sql
REVOKE ALL ON FUNCTION public.complete_sales_return_credit_note_atomic(
  uuid, text, text, boolean, text, jsonb, text
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.complete_sales_return_credit_note_atomic(
  uuid, text, text, boolean, text, jsonb, text
) TO service_role;
```

**Post-change live verification at `2026-10-12 22:46:18.477992+00 UTC`:**

| Privilege | Result |
|---|---|
| `anon` execute on return wrapper | `false` |
| `authenticated` execute on return wrapper | `false` |
| `service_role` execute on return wrapper | `true` |
| `service_role` execute on `complete_return_atomic` | `true` |

This was an ACL-only security repair. No business rows were modified. The migration record added to Git is:
`supabase/migrations/20261013014600_revoke_authenticated_pos_return_core.sql`
Commit: `d62b773a548f849c78ef22d9e866364c4de4afa0`.

### Core contract retained

- `save_sales_invoice_atomic` remains behind `save-sales-invoice` and is not executable by `anon/authenticated`.
- `complete_return_atomic` remains service-role-only.
- `post_stock_movement` remains the central physical stock movement path; no direct client grant was added.
- `complete-return` still validates JWT and maps the authenticated user to `users.auth_id` before calling the core. The function’s live source is version 26 and its artifact hash is listed above.
- The prior report’s ACL claim is superseded by this live check and repair. Do not copy the old claim forward.

## 3. CURRENT POS SOURCE — VERIFIED DEFECTS

The source still matches SHA `0160f7cf9c4f194d954d2c7498d91fc639a5f419`; the four UI changes below have **not** been applied by the assistant.

### Patch 1 — remove the unscoped currency read

**File:** `erp-frontend/companies/company-1/sales/pos.html`  
**Function:** `self._setupUser = function(user)`, currently near line 238. Re-search by function name before editing.

**Replace the entire function with:**

```javascript
    self._setupUser = function(user) {
        var isOwner = user.isOwner;
        var perms = user.permissions || [];

        if (!isOwner && perms.indexOf('pos') === -1) {
            RW_UI.showError('غير مصرح');
            RW_Auth.doLogout();
            return;
        }

        currentUser = user;
        pubUserId = user.id;

        // Currency is loaded from company-scoped get_pos_bootstrap_data() inside syncDown().
        RW_ImageCache.loadAll(function() {
            self.enterApp();
        });
    };
```

**Why:** the current function runs `supabase.from('app_settings').select('*').limit(1).single()` without a company predicate, while the company-scoped `get_pos_bootstrap_data()` already returns `currency`. Removing the duplicate query prevents cross-company configuration leakage and a race with initial rendering.

### Patch 2 — align the return warning with the live business contract

**File:** `erp-frontend/companies/company-1/sales/pos.html`  
**Element:** the `div.bg-amber-950/30` warning inside `#returnPaymentModal`. Search the exact text: `هذه الشاشة تسجل المرتجع والإشعار الدائن فقط.`

**Replace that warning block with:**

```html
<div class="bg-amber-950/30 border border-amber-700/50 p-3 rounded-xl text-center">
    <p class="text-sm font-bold text-amber-300">المرتجع النقدي يعيد المخزون وينشئ الإشعار الدائن ويرد المبلغ إلى خزينة إيصال البيع الأصلي ضمن عقد الخادم.</p>
    <p class="text-xs text-slate-300 mt-1">رد البطاقة أو المحفظة غير مدعوم حاليًا؛ لا تعتمد المرتجع غير النقدي من هذه الشاشة.</p>
</div>
```

### Patch 3 — disable payment methods without a complete settlement contract

**File:** `erp-frontend/companies/company-1/sales/pos.html`  
**Elements:** `id="btnPayCard"` and `id="btnPaySplit"` inside `#paymentModal`.

**Replace the two buttons only with:**

```html
<button type="button" id="btnPayCard" disabled aria-disabled="true" title="يتطلب عقد تسوية محاسبيًا معتمدًا" class="py-2.5 rounded-xl border border-slate-700 bg-slate-900 text-slate-500 font-bold text-sm flex flex-col items-center opacity-60 cursor-not-allowed"><span>💳</span><span>بطاقة — قيد الربط</span></button>
<button type="button" id="btnPaySplit" disabled aria-disabled="true" title="يتطلب توزيعًا محاسبيًا معتمدًا لكل وسيلة دفع" class="py-2.5 rounded-xl border border-slate-700 bg-slate-900 text-slate-500 font-bold text-sm flex flex-col items-center opacity-60 cursor-not-allowed"><span>🔀</span><span>مختلط — قيد الربط</span></button>
```

Do not enable card, wallet, or split tender until a complete atomic settlement contract covers receipts, settlement accounts, reversal/refund, idempotency, and journal effects.

### Patch 4 — make the return action truthful

**File:** `erp-frontend/companies/company-1/sales/pos.html`  
**Element:** `id="btnPayReturn"`, current text `إتمام المرتجع وإعادة المبلغ للعميل`.

**Replace only its inner text/icon with:**

```html
<i class="fa-solid fa-undo ml-2"></i> تسجيل المرتجع ورد النقد (للفواتير النقدية)
```

## 4. REVIEW OF THE CASHIER PROPOSAL — ACCEPT THE BUSINESS GOALS, REJECT THE UNSAFE DRAFT SCHEMA

The recovered proposal is `doc/Draft/Reprots/اقتراح تطبيق الكاشير-من مساعدد` at commit `a456097f3326af2b18941992b903c3365c89aa10` (blob SHA `d8badc619764e41b77b12a98e80a2b68c99b99cc`). It asks for P0 shift/cash control, X/Z reports, cash denomination counts, Paid In/Out, supervisor approval, terminal assignment, audit trail, treasury integration, and smart suggestions, with no new Edge Functions and an ADR-first sequence.

### Proposal items accepted in principle
- Shift opening/closing with immutable close state, expected-versus-counted cash, X-report and Z-report.
- Denomination-based cash counting, paid-in/paid-out control, sensitive-action approval, terminal assignment and auditable operations.
- Reuse existing Edge Functions and PostgreSQL RPCs where the verified contracts support it; do not add Edge Functions by default.
- Start with P0 and document the architecture before implementation.

### Defects in the proposed implementation that must not be copied
1. The proposed `shifts` DDL declares `company_id` twice, so the SQL is invalid as written.
2. `shift_code UNIQUE` is global rather than company-scoped. Multi-company uniqueness should be based on the actual company contract.
3. `terminal_id` is mandatory but no `pos_terminals` table/FK is defined in that DDL; the `cashier_id`, `branch_id`, `closed_by`, and `treasury_id` references are not constrained to the correct company context.
4. Proposed `cash_movements` lacks `company_id`, a durable `operation_id`/idempotency constraint, proper company-scoped foreign keys, and a complete reversal/status model. It could become a second ungoverned financial ledger.
5. Proposed `cash_count_details` lacks constraints preventing negative counts/non-positive denominations and lacks a unique key per shift/denomination.
6. No RLS policies, grants, authorization rules, concurrency locks, duplicate-open-shift constraint, or atomic close/restore contract is supplied.
7. Storing a supervisor PIN directly in `users` is unsafe; use a verifiable credential/approval contract, never a plain PIN comparison or client-trusted flag.
8. Automatically posting `actual_cash` through a generic receipt/payment voucher can double-count cash or confuse a drawer-to-treasury transfer with new business income. It must use the existing treasury/cash ledger semantics and a unique operation reference.
9. Marking an order `Cancelled` and posting a journal entry alone is not a valid POS void contract: stock reversal, cash/refund reversal, original-operation linkage, authorization, idempotency and audit must be atomic and reconciled through the central movement/financial contracts.
10. The proposal calls Offline-First/pending updates complete, but the current POS file only reads/retries queued rows; a full offline checkout writer and reconciliation contract are not proven.
11. The suggested `get_frequently_bought_together` is an optional later enhancement, not a prerequisite for cash-drawer integrity.

### Fresh Production reality checked against the proposal
- Present: `public.cash_box`, `public.treasury`, `public.sales_payment_receipts`, `public.audit_log`, and `public.orders`.
- Not present in `public` at the time checked: `shifts`, `cash_movements`, `cash_count_details`, `pos_terminals`; no `open_shift`, `close_shift`, `get_shift_summary`, `get_pos_terminals`, or `get_frequently_bought_together` RPCs were found.
- `orders` has `company_id`, `branch_id`, `source`, `payment_type`, `operation_id`, and `order_status`; it has no `shift_id` column.
- Therefore the shift-management feature gap is real, but creating the proposal's tables verbatim would be an invalid, disconnected, and unsafe partial implementation.

### Execution decision
The four low-risk UI patches and the Production ACL fix are actionable now. Shift Management P0 requires a corrected ADR and a coordinated deployment sequence spanning schema/RLS, atomic open/close/report RPCs, the existing `save-sales-invoice` Edge contract, and the owner-applied POS UI. I did not create orphan tables or make checkout require a shift before the UI/Edge can pass and enforce a valid `shift_id`; doing so would break live POS sales. This is a sequencing/safety decision grounded in the current contract, not a claim that Shift Management is complete.

## 5. OFFLINE SALES — DO NOT CLAIM COMPLETION

The POS source reads and syncs rows from `db.pending_updates`, but a complete durable offline-sale path was not proven in the file. Reading/retrying queued operations is not proof that the checkout creates a safe pending sale with a stable `operation_id`, durable payload, conflict policy, and user-visible pending state. Do not mark Offline Sales complete based on the presence of `syncPendingOrders()` alone.

No new Edge Function was created. If the gateway/function cap remains active, any future offline work must reuse the existing sale endpoint and a properly designed idempotent contract, not add another Edge function by default.

## 6. TESTS AND VERIFICATION

### Executed and verified
1. Re-read current POS source and the historical POS baseline.
2. Retrieved live Production Edge source for `save-sales-invoice v18` and `complete-return v26`.
3. Inspected live definitions of the return wrapper and inner return core.
4. Detected the live authenticated EXECUTE grant that contradicted Report422.
5. Revoked direct `PUBLIC/anon/authenticated` execution, explicitly retained `service_role`, and re-queried live privileges.
6. Confirmed `anon=false`, `authenticated=false`, `service_role=true`, and inner Core remains service-role-executable.
7. Committed the canonical migration record to `rawaie-erp-New`.

### Not executed / not proven
- Authenticated browser E2E against the served POS was not available in this tool session.
- No production sale or return fixture was created, to avoid contaminating financial/inventory records.
- No deployed static-host artifact parity with the current Git blob was established.
- The four POS UI patches remain owner-applied changes; therefore their browser behavior is not yet verified.
- The cashier proposal was recovered at the corrected filename and reviewed; the proposed business goals are useful, but its draft DDL/security/accounting details are not safe to implement verbatim.
- A Supabase logs query for the return function failed with a backend error; no conclusion is drawn from that failed query.

### Required post-patch tests
1. Authenticated POS login; verify company currency, branches, stock and customers remain company-scoped.
2. Verify card and split methods cannot be selected and checkout stays cash-only.
3. Verify the return modal copy accurately describes cash POS returns and explicitly excludes unsupported non-cash refunds.
4. In an isolated test environment, complete a cash POS sale and return; check `operation_id`, order/detail status, `post_stock_movement`, original cash receipt, refund payment, credit note and journal entries.
5. Retry the same operation and prove no duplicate stock, receipt, refund, or journal posting.
6. Call the return RPC directly as an authenticated JWT: it must fail with permission denied; call through the authenticated Edge: it must continue to work via service_role.
7. Re-check production ACL after deploy and capture served-browser evidence.
8. Confirm no test residue remains.

## 7. FINAL CLOSURE REPORT

### A. What changed
- Production security ACL repaired for `complete_sales_return_credit_note_atomic`.
- Canonical migration record committed.
- No operational POS file or `main.html` edited.
- Four surgical UI changes prepared for the owner.

### B. What is now proven
- Current POS and historical POS source identities.
- Live Edge versions and artifact hashes for sale/return.
- Return wrapper ACL now denies anon/authenticated and permits service_role.
- Edge→service_role→Core remains the intended execution path.
- Company-scoped bootstrap returns currency; the extra UI query is redundant and unscoped.
- Non-cash payment controls are still active in the current source despite the incomplete settlement contract.

### C. What is not proven
- The assistant did not read the contents of the proposed cashier document because the supplied path returns 404 and repository searches did not locate it.
- The owner UI patches are not applied.
- Browser E2E, served artifact parity, and clean fixture restoration are not proven.
- Offline sales and non-cash settlement are not complete.

### D. Remaining work in this POS scope
1. Owner applies the four exact patches above to the current POS source SHA.
2. Publish the POS file and verify the served browser.
3. Run isolated authenticated E2E for cash sale and cash return, including retry/idempotency.
4. Use the recovered proposal's business goals, but create a corrected ADR before implementing Shift Management P0.
5. Continue offline-sale and non-cash settlement work only after designing their full business contracts.

## 8. SELF-AUDIT FINAL

- **What I Proved:** current source/historical source; live Edge versions; live return Core definition; ACL vulnerability existed before repair; the ACL repair is effective in Production; service_role retains execution.
- **What I Did Not Prove:** browser E2E; served artifact parity; completion of offline sales; support for non-cash settlement; implementation of Shift Management; final closure of the POS UI.
- **What I Fixed:** revoked `PUBLIC/anon/authenticated` execution on `complete_sales_return_credit_note_atomic(uuid,text,text,boolean,text,jsonb,text)`, retained service_role, verified privileges, committed the migration record.
- **What I Initially Missed:** Report422’s claim that the return wrapper was service_role-only was stale/wrong against live Production. The fresh ACL query exposed the discrepancy, and it was corrected before this report.
- **What Could Still Be Wrong:** a different branch/commit or served static artifact may differ; the owner patches and browser tests are pending; Shift Management still needs a corrected ADR and coordinated implementation.
- **Final Confidence:** high for the live ACL repair and source-level findings; medium for overall POS integration.
- **Final Closure Status:** `PRODUCTION RETURN-CORE ACL FIXED + VERIFIED / UI SURGICAL PATCHES READY FOR OWNER / PROPOSAL REVIEWED WITH UNSAFE DDL REJECTED / SHIFT MANAGEMENT OPEN / BROWSER E2E OPEN / POS NOT 100% CLOSED`.
