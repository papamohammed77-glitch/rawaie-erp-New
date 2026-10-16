# Report425 — تدقيق POS الحالي: الوردية والخزينة والمرتجع — 2026-10-16

## 1. نطاق العمل وحدود التغيير

النطاق: `papamohammed77-glitch/erp-frontend/companies/company-1/sales/pos.html` مع Production Supabase للمشروع `fiilmooggumokxanwiyx`.

لم أعدّل `main.html` أو ملف POS التشغيلي، ولم أنشئ معاملات بيع/مرتجع أو ورديات تجريبية في Production. ملف POS من اختصاص المالك؛ دوري هو تثبيت ما يلزم من Production وإعطاء استبدالات جراحية محددة. لم أغيّر Production في هذه الدورة لأن عقود الوردية الأساسية موجودة بالفعل، ولا يوجد Shift حالي يمكن اختباره، ولا أملك Browser/Auth session صالحة لتنفيذ E2E حقيقي بأمان.

## 2. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** مسؤولية النقد تبدأ بفتح وردية مرتبطة بكاشير/فرع/محطة، والرصيد المتوقع يجب أن يساوي العهدة الافتتاحية زائد المقبوضات النقدية ناقص المردودات والمدفوعات النقدية المسجلة فعليًا. إغلاق العدّ لا يساوي تسليم عهدة المحصل إلى المحاسب.
- **Architecture Understanding:** POS PWA → authenticated PostgreSQL RPC للوردية، وPOS sale/return عبر Edge JWT → service_role → Core. لا تُمنح الواجهة تنفيذًا مباشرًا لدوال Core المالية.
- **Database Understanding:** جداول `pos_terminals`, `pos_shifts`, `pos_shift_cash_counts`, `pos_shift_events` وعمود `orders.shift_id` موجودة في Production. جداول الوردية عليها RLS، ولا توجد صلاحيات مباشرة للـanon/authenticated على الجداول؛ التغيير يتم عبر RPCs مصادق عليها.
- **Historical Understanding:** Report421–Report424 وADR `ADR_POS_SHIFT_MANAGEMENT_P0_20261013.md` استُخدمت كأدلة تاريخية لا كحقيقة حالية. آخر مصدر POS قُرئ مباشرة هو SHA الموضح أدناه.
- **Production Understanding:** تمت إعادة الاستعلام عن المخطط، ACL، تعريفات RPC، الفهارس، الـtriggers، وعدد الخزائن النشطة في نفس دورة العمل.
- **Current Understanding:** المصدر الحالي يتضمن بالفعل مودال فتح/إغلاق الوردية، وعدّ الفئات، والتحقق من الوردية قبل الدفع. لكنه لا يتضمن تبويبًا مستقلًا باسم «خزينتي»، ولا يوجد مسار مثبت لتسليم النقد للمحاسب أو اعتماد المشرف للمرتجع بكود.
- **Execution Confidence:** مرتفع لوجود عقود قاعدة البيانات ولتحليل المصدر؛ غير كافٍ لإثبات Served Artifact parity أو HTTP/Browser E2E.

### سجل الأدلة

| البند | دليل الدورة الحالية |
|---|---|
| Current source | `erp-frontend/companies/company-1/sales/pos.html` |
| Current blob SHA | `1c5ee4b674e11bc22a141ade3743687fcf4d0ec0` |
| Current source size | 106,570 characters / 1,847 lines |
| Current shift UI commit found | `23fba26051c8cece0a56e31eeeb12d9189921d48` — Implement shift management modal in POS |
| Production project | `fiilmooggumokxanwiyx` |
| Production checked at | `2026-10-16 17:12:50 UTC` for database identity; subsequent live schema/ACL queries in this cycle |
| Production shift tables | Present: `pos_terminals`, `pos_shifts`, `pos_shift_cash_counts`, `pos_shift_events` |
| Production linkage | `orders.shift_id`, `cash_box.shift_id`, and INSERT triggers `trg_pos_assign_order_shift`, `trg_pos_assign_cash_box_shift` present |
| Active treasuries | One active treasury in company `00000000-0000-0000-0000-000000000001`; therefore current `p_treasury_id: null` fallback can resolve in this observed dataset |
| Current shifts | Zero rows in `pos_shifts`; no Production shift fixture was created |
| Direct table grants | anon/authenticated have no SELECT/INSERT/UPDATE grants on POS shift tables |
| RPC ACL | `pos_open_shift`, `pos_get_shift_summary`, `pos_close_shift`: authenticated EXECUTE=true, anon=false; helper/trigger functions not directly executable |
| Migration lineage in Production | `20261012233000_pos_shift_management_core`, `20261012234000_pos_shift_authenticated_acl`, `20261012235000_pos_shift_linkage_hardening`, `20261012235500_pos_shift_z_report_snapshot` recorded in `supabase_migrations.schema_migrations` |

## 3. Confirmed current behavior

1. `POS._setupUser` calls `loadShiftState()`.
2. `POS.openPaymentModal()` reloads shift state and rejects checkout without an active shift or if the branch differs.
3. `POS.finalizeCheckout()` repeats the active-shift/branch guard and permits only cash settlement.
4. `pos_open_shift` derives the user/company from `auth.uid()`, checks POS permission and branch, validates an active company treasury, uses `operation_id`/fingerprint for retry safety, and creates a company-scoped terminal and shift.
5. `pos_close_shift` locks the shift, validates denomination totals, calculates expected cash from the database, requires a discrepancy reason when needed, writes an immutable close snapshot and audit event.
6. `pos_assign_order_shift` attaches POS orders to the cashier’s open shift when it can resolve the authenticated application user through the server-set creator email. However, it intentionally remains backward-compatible: if no matching open shift is found, it returns without rejecting the POS order. Do not harden that trigger until the served POS artifact and checkout contract are confirmed deployed; otherwise a stale PWA could be broken.
7. `pos_get_shift_summary` is callable only by authenticated sessions and returns the caller’s own shift unless the caller has approved manager/accounting permissions.
8. No current shift records exist, so there is no business baseline to restore and no fixture residue to clean.

## 4. Verified defects / gaps

### P0 — no «خزينتي» tab and no live refresh loop

The current navigation has only `pos`, `suspended`, `invoices`, and `returns`. Shift data appears only in a modal. The source has no timer or Realtime subscription that refreshes the current shift summary after sales/refunds or while the modal is closed. The UI therefore does not satisfy the requested standalone, near-live «خزينتي» view.

### P0 — cashier handover to branch accountant is not implemented

`pos_close_shift` closes the shift and records the count; it does not require acknowledgement by the accountant who physically receives the drawer cash. The current schema has no handover state/receipt contract and the POS UI does not prevent logout while handover is pending. A close report alone is not proof that the money was handed over.

### P0 — supervisor code is not enforced for POS return

Current `POS._finalizeReturn()` invokes the existing `complete-return` Edge Function. No supervisor-code prompt or database-enforced approval is present in the POS source/core contract. A front-end-only PIN prompt is not sufficient: direct invocation of the Edge endpoint could bypass it. Production `users` has no supervisor PIN/hash column. Do not store a PIN in plaintext or silently reuse `password_hash`; a dedicated hashed credential + rate limit/lockout + one-time approval bound to the return payload is required, and the existing Edge/Core path must enforce/consume that approval.

### P1 — current shift opening assumes one active treasury

The live company currently has exactly one active treasury, so the null fallback succeeds for this observed company. The UI does not show a treasury selector; if the company later has more than one active treasury, `pos_open_shift` returns `SHIFT_TREASURY_SELECTION_REQUIRED`. This is not a current failure for the observed data, but is a real multi-treasury compatibility gap.

### P1 — production runtime proof is absent

No active shift exists and no authenticated browser session is available in this execution context. Do not claim HTTP E2E, concurrent-open/close, return-approval, handover, or served-artifact parity as PASS.

## 5. Surgical POS patch — owner applies only

### Patch A — add the «خزينتي» navigation entry

**File:** `companies/company-1/sales/pos.html`  
**Current source SHA:** `1c5ee4b674e11bc22a141ade3743687fcf4d0ec0`  
**Location:** lines 115–120, bottom navigation.

**Find this exact block:**
```html
    <nav class="bg-slate-900 border-t border-slate-800 flex items-center justify-around shrink-0 py-1" style="padding-bottom:max(12px,var(--sab));min-height:60px">
        <button onclick="POS.switchView('pos')" class="tab-btn active" id="nav-pos"><i class="fa-solid fa-cash-register text-xl mb-0.5"></i><span>البيع</span></button>
        <button onclick="POS.switchView('suspended')" class="tab-btn" id="nav-suspended"><i class="fa-solid fa-pause-circle text-xl mb-0.5"></i><span>معلقة</span></button>
        <button onclick="POS.switchView('invoices')" class="tab-btn" id="nav-invoices"><i class="fa-solid fa-file-invoice text-xl mb-0.5"></i><span>فواتير اليوم</span></button>
        <button onclick="POS.switchView('returns')" class="tab-btn" id="nav-returns"><i class="fa-solid fa-rotate-left text-xl mb-0.5"></i><span>مرتجع</span></button>
    </nav>
```

**استبدله كاملًا بهذا:**
```html
    <nav class="bg-slate-900 border-t border-slate-800 flex items-center justify-around shrink-0 py-1" style="padding-bottom:max(12px,var(--sab));min-height:60px">
        <button onclick="POS.switchView('pos')" class="tab-btn active" id="nav-pos"><i class="fa-solid fa-cash-register text-xl mb-0.5"></i><span>البيع</span></button>
        <button onclick="POS.switchView('suspended')" class="tab-btn" id="nav-suspended"><i class="fa-solid fa-pause-circle text-xl mb-0.5"></i><span>معلقة</span></button>
        <button onclick="POS.switchView('invoices')" class="tab-btn" id="nav-invoices"><i class="fa-solid fa-file-invoice text-xl mb-0.5"></i><span>فواتير اليوم</span></button>
        <button onclick="POS.switchView('returns')" class="tab-btn" id="nav-returns"><i class="fa-solid fa-rotate-left text-xl mb-0.5"></i><span>مرتجع</span></button>
        <button onclick="POS.switchView('treasury')" class="tab-btn" id="nav-treasury"><i class="fa-solid fa-wallet text-xl mb-0.5"></i><span>خزينتي</span></button>
    </nav>
```

### Patch B — add the treasury view to the existing view router

**Location:** `POS.switchView`, current lines 1376–1431.

**Find:**
```javascript
var allowedViews = ['pos', 'suspended', 'invoices', 'returns'];
```

**Replace with:**
```javascript
var allowedViews = ['pos', 'suspended', 'invoices', 'returns', 'treasury'];
```

**Then find the tail of the same function:**
```javascript
        } else if (isReturnView) {
            self.renderReturnsView();
        }
    };
```

**Replace with:**
```javascript
        } else if (isReturnView) {
            self.renderReturnsView();
        } else if (view === 'treasury') {
            self.renderTreasuryView();
        }
    };
```

### Patch C — add a read-only, near-live «خزينتي» renderer

**Insertion point:** immediately before `self.switchView = function(view) {` (current line 1376). Insert this complete function; do not replace any other function.

```javascript
    self._treasuryRefreshTimer = null;

    self.renderTreasuryView = function() {
        var grid = RW_UI.byId('productsGrid');
        var cartCont = RW_UI.byId('cartItemsContainer');

        function money(v) {
            var n = Number(v || 0);
            return isFinite(n) ? n.toFixed(2) : '0.00';
        }

        function paint() {
            if (currentView !== 'treasury') return;
            var summary = self._shiftSummary || {};
            var shift = summary.shift || null;
            var active = !!(self._activeShiftId && shift);
            var status = active ? 'وردية مفتوحة' : 'لا توجد وردية مفتوحة';
            var html = '<div class="col-span-full p-4 space-y-4">' +
                '<div class="flex items-center justify-between gap-3"><div><h2 class="text-xl font-black text-white">خزينتي</h2>' +
                '<p class="text-xs text-slate-400 mt-1">تحديث تلقائي كل 5 ثوانٍ من قاعدة البيانات</p></div>' +
                '<button type="button" onclick="POS.loadShiftState(function(){POS.renderTreasuryView();})" class="px-3 py-2 rounded-lg bg-blue-700 text-white font-bold text-xs">تحديث الآن</button></div>' +
                '<div class="rounded-2xl border border-slate-700 bg-slate-900 p-4">' +
                '<div class="text-xs text-slate-400">الحالة</div><div class="text-lg font-black ' + (active ? 'text-emerald-300' : 'text-amber-300') + '">' + status + '</div>' +
                (active ? '<div class="mt-2 text-xs text-slate-400">وقت البداية: ' + String(shift.opened_at || '—') + '</div>' : '') +
                '</div>' +
                '<div class="grid grid-cols-1 sm:grid-cols-2 gap-3">' +
                '<div class="rounded-2xl border border-slate-700 bg-slate-900 p-4"><div class="text-xs text-slate-400">العهدة الافتتاحية</div><div class="text-2xl font-black text-white mt-1">' + money(shift && shift.opening_float) + '</div></div>' +
                '<div class="rounded-2xl border border-emerald-800 bg-emerald-950/30 p-4"><div class="text-xs text-emerald-300">الرصيد النقدي المتوقع</div><div class="text-2xl font-black text-emerald-200 mt-1">' + money(summary.expected_cash) + '</div></div>' +
                '<div class="rounded-2xl border border-slate-700 bg-slate-900 p-4"><div class="text-xs text-slate-400">المبيعات النقدية</div><div class="text-xl font-black text-white mt-1">' + money(summary.cash_sales) + '</div></div>' +
                '<div class="rounded-2xl border border-slate-700 bg-slate-900 p-4"><div class="text-xs text-slate-400">المردودات النقدية</div><div class="text-xl font-black text-red-300 mt-1">' + money(summary.cash_refunds) + '</div></div>' +
                '</div>' +
                '<div class="rounded-xl border border-slate-700 bg-slate-900 p-3 text-xs text-slate-400">الرصيد المعروض هو رصيد متوقع من قيود النقد المسجلة. لا يمثل استلام المحاسب للعهدة، ولا يُعدّ إغلاقًا ماليًا.</div>' +
                (active ? '<button type="button" onclick="POS.openShiftModal()" class="w-full rounded-xl bg-indigo-700 p-3 font-black text-white">إدارة الوردية والعدّ النقدي</button>' : '<button type="button" onclick="POS.openShiftModal()" class="w-full rounded-xl bg-emerald-700 p-3 font-black text-white">بدء وردية جديدة</button>') +
                '</div>';
            if (grid) RW_UI.safeHTML(grid, html);
            if (cartCont) RW_UI.safeHTML(cartCont, '<div class="p-4 space-y-3"><h3 class="font-black text-white">ملخص الخزينة</h3><div class="flex justify-between text-sm"><span class="text-slate-400">الرصيد المتوقع</span><strong class="text-emerald-300">' + money(summary.expected_cash) + '</strong></div><div class="flex justify-between text-sm"><span class="text-slate-400">عدد الفواتير</span><strong class="text-white">' + String(summary.sale_count || 0) + '</strong></div><div class="text-xs text-slate-500">آخر تحديث: ' + new Date().toLocaleTimeString() + '</div></div>');
        }

        if (self._treasuryRefreshTimer) {
            clearInterval(self._treasuryRefreshTimer);
            self._treasuryRefreshTimer = null;
        }
        paint();
        self.loadShiftState(function() { paint(); });
        self._treasuryRefreshTimer = setInterval(function() {
            if (currentView !== 'treasury') {
                clearInterval(self._treasuryRefreshTimer);
                self._treasuryRefreshTimer = null;
                return;
            }
            self.loadShiftState(function() { paint(); });
        }, 5000);
    };
```

**مهم:** هذا التغيير يقدم تحديثًا قريبًا من اللحظي عبر RPC كل 5 ثوانٍ، وليس Supabase Realtime subscription. لا تسمّه Realtime حقيقيًا في الواجهة أو التقرير. الاشتراك الحقيقي يحتاج قناة آمنة/آلية بث معتمدة لأن جداول الوردية محمية بـRLS ولا تملك الواجهة صلاحية القراءة المباشرة.

## 6. Production — ما تغيّر وما لم يتغيّر

لم تُنفذ DDL أو تغييرات ACL في هذه الدورة؛ لأن:
- بنية الوردية الأساسية موجودة بالفعل.
- RPCs الحالية تتحقق من الهوية والصلاحيات والسياق.
- لا توجد ورديات حالية ولا سجل مالي مرتبط بـshift لاختباره.
- لم تتوفر جلسة Browser/Auth لتنفيذ اختبار حقيقي من الواجهة إلى Production.
- إضافة جداول أو منح صلاحيات قراءة مباشرة ليست لازمة لعرض «خزينتي»؛ يجب الاستمرار عبر `pos_get_shift_summary`.

## 7. اختبارات المالك بعد تطبيق Patch A–C

1. تسجيل الدخول بحساب كاشير فعلي يملك `pos`.
2. فتح «خزينتي» دون وردية: يظهر صفر/لا وردية ولا يتعطل التطبيق.
3. فتح وردية بعهدة افتتاحية صفرية ثم بمبلغ موجب في بيئة اختبار معتمدة.
4. التحقق أن الشركة/الفرع والهوية المعروضة تأتي من `pos_get_shift_summary`، لا من قيم يرسلها المتصفح.
5. تسجيل بيع نقدي ثم التأكد من تحديث الرصيد في «خزينتي» خلال 5 ثوانٍ.
6. تسجيل مرتجع نقدي من فاتورة POS ثم التأكد من انخفاض الرصيد المتوقع وفق قيود النقد الفعلية.
7. تغيير الفرع مع وجود وردية مفتوحة: يجب رفض البيع لعدم تطابق الفرع.
8. تجربة فتح متزامن من جهازين: يجب أن يمنع القيد الفريد وجود ورديتين مفتوحتين للكاشير نفسه.
9. إغلاق الوردية مع عدّ صحيح، ثم عدّ غير مطابق بلا سبب (يُرفض)، ثم مع سبب (يُقبل).
10. إعادة فتح «خزينتي» والتنقل بعيدًا عنها والتأكد من توقف مؤقت التحديث وعدم تكرار المؤقتات.

## 8. نقاط لا يجوز إعلان إغلاقها الآن

- **تسليم النقد للمحاسب:** يحتاج عقد handover مستقلًا يثبت المستلم والمبلغ ووقت الاستلام، ثم يمنع خروج الكاشير قبل تأكيد الاستلام. الإغلاق الحالي لا يثبت هذا.
- **كود مشرف المرتجع:** يحتاج اعتمادًا مشفرًا ومحدود المحاولات، مرتبطًا بطلب المرتجع نفسه، يفرضه Core/Edge لا الواجهة فقط. لا توجد حاليًا بيانات اعتماد مشرف آمنة مثبتة.
- **الخزينة متعددة الخيارات:** واجهة اختيار الخزينة غير موجودة؛ تعمل البيانات الحالية لأن Production لديها خزينة نشطة واحدة فقط.
- **Production HTTP E2E / Served artifact parity:** UNVERIFIED.
- **Offline checkout:** ما زال غير مثبت؛ وجود cache لا يساوي بيعًا offline آمنًا.
- **تسوية البطاقة/المختلط:** ما زالت معطلة عمدًا حتى اكتمال عقد التسوية.

## 9. SELF-AUDIT FINAL

- **What I Proved:** المصدر الحالي يتضمن مودال وردية؛ عقود Production والجداول والـACL موجودة؛ جداول الوردية غير قابلة للقراءة المباشرة من الواجهة؛ لا توجد ورديات حاليًا؛ توجد خزينة نشطة واحدة في الشركة المرصودة.
- **What I Did Not Prove:** نشر نسخة POS الحالية إلى الاستضافة، أو E2E حقيقي، أو قبول المحاسب للعهدة، أو اعتماد مشرف المرتجع، أو البيع دون اتصال.
- **What I Fixed:** لا تغيير مباشر في POS أو Production في هذه الدورة؛ أعددت ترقيعات جراحية دقيقة للمالك ولم أكرر تغييرات موجودة.
- **What I Initially Missed:** وجود shift core في Production رغم أن التقارير القديمة وصفت غيابه؛ كما أن مودال الوردية أضيف في مصدر أحدث من SHA المسجل في Report424.
- **What Could Still Be Wrong:** قد تختلف النسخة المخدومة عن Git؛ كما أن الإغلاق لا يزال منفصلًا عن التسليم الفعلي، وغياب اعتماد المشرف قابل للتجاوز عبر المسار الخلفي الحالي.
- **Final Confidence:** مرتفع في نتائج SQL/المصدر؛ منخفض في runtime بسبب غياب E2E.
- **Final Closure Status:** `PARTIAL — SURGICAL UI PATCH READY / NOT CLOSED`. لا يُسمح بإعلان 100% حتى تنفيذ التسليم للمحاسب واعتماد المرتجع وتحقق Production HTTP E2E.
