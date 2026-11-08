# Report653 — Employee Custody Detail Modal UX ChangeSet
**Date:** 2026-11-08 (Africa/Cairo)  
**Status:** CURRENT BEHAVIOR VERIFIED — MODAL RECOMMENDED — OWNER CHANGESET PREPARED / NOT APPLIED

## 1. Executive decision

The custody register's **"فتح التفاصيل"** button does **not** open a modal or a separate page in the current Parent source. It opens the page-level `<details id="custody-full-ledger">` container and scrolls to the selected custody card underneath the table.

For this workflow, the better interaction is a **dedicated wide modal**, not a new page.

A custody record is a row-level drill-down from a server-paginated Finance register. Users need to inspect its header, acknowledged cash deliveries, advances, expenses/purchase invoices, supplier payments, settlement history and the available Finance actions, then close the detail and continue with the same search filters and page. A page navigation would introduce an unnecessary route/deep-link and back-navigation contract and would risk losing the current list context. A modal preserves that context.

## 2. Current source evidence

- Operational repository: `papamohammed77-glitch/erp-frontend`
- Branch: `main`
- Current observed HEAD: `c8d40b32150d2cb0e7e5830bac4a9e3d0a846655`
- Parent file: `companies/company-1/main.html`
- Current Parent blob: `879383859d0ec20927cc718e63a7af49fa18980c`
- Module: `RW_Finance_Custody`
- Current detail button: `data-custody-open-detail="<custody id>"`.
- Current handler expands `#custody-full-ledger`, finds `[data-custody-detail]` for that ID, and calls `scrollIntoView()`.
- There is no `Swal.fire()` or route/navigation call in this detail-button branch.
- The existing detail content already includes the custody summary, five balance/amount cards, nested sections for cash deliveries/advances, expenses and supplier invoices/payments, settlement history, and the existing advance/settle/review/document actions.

## 3. Reference modal patterns inspected in the same Parent

### A. Purchase Request — `RW_PurchaseGold.createRequest()`

This is the high-quality creation-modal reference requested by the owner:
- SweetAlert2 `Swal.fire()`.
- Width `980`.
- RTL layout and right-aligned content.
- A distinct hero header with icon, gradient surface, border and descriptive subtitle.
- Clear grouped sections, consistent spacing, rounded surfaces and well-structured fields.
- `didOpen` for attaching interactive controls.
- Explicit validation and named confirm/cancel actions.

### B. Purchase Order read-only detail — `RW_Purchases.openPO()`

This is the closer behavioral reference for a read-only detail view:
- SweetAlert2 detail dialog, width `820px`.
- `showConfirmButton:false` and `showCloseButton:true`.
- Structured supplier/status summary, items table and total.
- Existing action button is wired from `didOpen`.

### C. Application to Employee Custody

Custody detail is materially richer than a simple PO summary. The recommended view therefore combines the quality of the Purchase Request modal with the read-only behavior of the PO detail modal:

- Responsive width: `min(1100px, 96vw)`.
- A Finance-indigo hero header rather than a generic browser alert.
- RTL, generous spacing, clear financial summary and the existing nested history sections.
- A vertically scrollable content body capped to the viewport; the modal title/close affordance remain outside the scroll body.
- `showCloseButton:true`, `showConfirmButton:false`, and no artificial "Save" button for a read-only detail view.
- The list, its server filters, selected page and page size remain unchanged behind the modal.

This is a modal for a detailed financial record, not a new transaction form. It should not resemble an approval form or make opening details appear to post anything.

## 4. Owner ChangeSet — exact current anchors and replacement

**Important:** this ChangeSet is based on the current blob above. Recheck each exact anchor and the blob SHA before applying.

### Change A — add a detail-modal renderer

Insert the following function immediately before the current `function bind(root)` inside `RW_Finance_Custody` (after the current `render()`):

```javascript
function openDetail(id,root){
  var host=root||byId('finance-content'),record=null,source=null;
  if(!host||!S||!Array.isArray(S.custodies)){_showToast('تعذر تحميل بيانات العهدة','warning');return;}
  record=S.custodies.filter(function(c){return String(c.id)===String(id);})[0]||null;
  if(!record){_showToast('العهدة غير موجودة في الصفحة الحالية؛ حدّث السجل وأعد المحاولة','warning');return;}
  Array.prototype.forEach.call(host.querySelectorAll('[data-custody-detail]'),function(row){if(String(row.getAttribute('data-custody-detail'))===String(id))source=row;});
  if(!source){_showToast('تعذر تجهيز تفاصيل العهدة','warning');return;}
  var code=String(record.custody_code||'عهدة');
  var intro='<div class="rounded-2xl bg-gradient-to-l from-indigo-50 to-slate-50 border border-indigo-100 p-5"><div class="flex items-center gap-3"><div class="w-12 h-12 rounded-2xl bg-indigo-600 text-white flex items-center justify-center"><i class="fa-solid fa-wallet"></i></div><div><div class="text-lg font-black text-slate-900">ملف عهدة الموظف</div><div class="text-sm text-slate-500">مراجعة تفاصيل التسليم والمصروفات والفواتير والتسويات. فتح النافذة لا ينشئ حركة مالية أو مخزنية.</div></div></div></div>';
  Swal.fire({
   title:'تفاصيل العهدة — '+code,
   width:'min(1100px, 96vw)',
   padding:'1rem',
   html:'<div id="custody-detail-modal-body" dir="rtl" class="text-right space-y-4" style="max-height:calc(100vh - 220px);overflow-y:auto;padding:4px 2px;">'+intro+source.innerHTML+'</div>',
   showConfirmButton:false,
   showCloseButton:true,
   focusConfirm:false,
   heightAuto:false,
   customClass:{popup:'rounded-3xl'},
   didOpen:function(){
    var popup=Swal.getPopup(),body=popup&&popup.querySelector('#custody-detail-modal-body');
    if(!body)return;
    body.addEventListener('click',function(ev){
     var action=ev.target.closest&&ev.target.closest('[data-custody-advance],[data-custody-settle],[data-custody-review],[data-custody-doc]');
     if(!action)return;
     if(action.hasAttribute('data-custody-advance')){var advanceId=action.getAttribute('data-custody-advance');Swal.close();advance(advanceId);}
     else if(action.hasAttribute('data-custody-settle')){var settleId=action.getAttribute('data-custody-settle');Swal.close();settle(settleId);}
     else if(action.hasAttribute('data-custody-review')){var expenseId=action.getAttribute('data-custody-review'),expenseType=action.getAttribute('data-custody-type');Swal.close();review(expenseId,expenseType);}
     else if(action.hasAttribute('data-custody-doc'))doc(action.getAttribute('data-custody-doc'));
    });
   }
  });
}
```

The function reuses the selected custody card's already-rendered `innerHTML`; it does not duplicate balance calculations or issue another backend query. It adds its own delegated handler because SweetAlert2 places the modal outside `#finance-content`. Existing actions are routed to their existing module functions. Advance, settle and review close the detail modal before opening their own action dialog; document viewing leaves the detail modal open.

### Change B — replace the detail button branch

**Original:**
```javascript
if(x.hasAttribute('data-custody-open-detail')){var id=x.getAttribute('data-custody-open-detail'),drawer=h.querySelector('#custody-full-ledger'),target=null;if(drawer)drawer.open=true;Array.prototype.forEach.call(h.querySelectorAll('[data-custody-detail]'),function(row){if(row.getAttribute('data-custody-detail')===id)target=row;});if(target&&target.scrollIntoView)target.scrollIntoView({behavior:'smooth',block:'start'});return;}
```

**Replacement:**
```javascript
if(x.hasAttribute('data-custody-open-detail')){openDetail(x.getAttribute('data-custody-open-detail'),h);return;}
```

### Change C — retain current detail markup as a hidden template source

**Original:**
```javascript
if(S.custodies.length)h+='<details id="custody-full-ledger" class="space-y-3"><summary class="cursor-pointer p-3 rounded-xl border bg-white font-bold">تفاصيل وإجراءات العهد في الصفحة الحالية ('+S.custodies.length+')</summary><div class="space-y-4 pt-3">';
```

**Replacement:**
```javascript
if(S.custodies.length)h+='<details id="custody-full-ledger" hidden class="space-y-3"><div class="space-y-4 pt-3">';
```

The existing card templates remain in the DOM so the modal can reuse the exact current values and action attributes, but the old below-table accordion is no longer presented as a competing detail interface.

### Change D — update the instruction beneath the table

**Original current line:**
```javascript
h+='<p class="text-xs text-slate-500">المؤشرات والتفاصيل أدناه تخص سجلات الصفحة الحالية؛ إجمالي الأرشيف المطابق للبحث ظاهر منفصلًا في جدول المتابعة.</p>';
```

**Replacement:**
```javascript
h+='<p class="text-xs text-slate-500">اختر «فتح التفاصيل» لعرض سجل العهدة وحركاتها في نافذة مستقلة. ستبقى فلاتر البحث والصفحة الحالية محفوظة عند إغلاق النافذة.</p>';
```

## 5. Interaction and business-safety design

- Opening the modal is read-only. It does not call `A()`, `render()`, an RPC, an Edge Function, or any posting operation.
- The modal gets the selected record from the already-loaded `S.custodies` snapshot and reuses the matching detail card template.
- The original list filter, offset/page, page size and table DOM are not reset when opening or closing the modal.
- Advance and settle call the existing functions only after the detail modal closes. Those functions retain their existing validations and backend action contracts.
- Review calls the existing review function with its original expense ID and type, after closing the detail modal.
- Document viewing continues through the current signed-URL helper; the details modal remains open.
- Missing record/template produces a warning toast rather than an empty modal.
- No duplicate API/data path, new table, route, database field, RPC, Edge Function or new business rule is introduced.

## 6. Validation performed on the proposed ChangeSet

**Static / syntax — PASS**
1. Re-fetched the current Parent blob and found each of the three primary source anchors exactly once: detail click branch, outer detail template and note line.
2. Applied the proposed changes in-memory only; no operational file was written.
3. Parsed the complete Parent inline JavaScript block after the proposed edits with zero syntax errors.
4. Confirmed the old inline scroll branch is absent in the proposed output, the modal helper is inserted, and the list note and hidden-template behavior are present.

**Controlled behavior simulation — PASS**
1. Opening a valid custody modal invokes only `Swal.fire`; no advance/settle/review/doc function runs on open.
2. Advance, settle and review buttons route to their existing callbacks with the correct custody/expense IDs and review type, after closing the details modal.
3. Document action routes to the existing document helper without closing the details modal.
4. A missing record produces a warning and does not open an empty modal.

This is an isolated JavaScript harness, not an authenticated browser test. No financial operation was executed.

## 7. Deployment / runtime evidence

- The connected Browser integration is read-only in this session; no actual button click, modal visual inspection, keyboard dismissal, mobile viewport, console or Network test was performed.
- Cloudflare deployment parity for the preceding event-binding fix remains unverified. This ChangeSet has not been applied or deployed, so the modal behavior is not yet present in Production.
- Acceptance after owner application: desktop and mobile viewport; modal opens once; close via X and Escape; body scrolls independently; underlying filters/page remain unchanged; nested accordions work; advance/settle/review/document controls route exactly once; no double event handler; closing returns focus to the corresponding table row where browser behavior permits.

## 8. Governance and scope

The current permanent constitution is SHA `3a6b1e220af8509e314e94df76563bbc6f84910d`; the execution prompt is SHA `39f18748a8a3cf633a04506216cc39fd98de523d`. The constitution §7.1 and prompt §10.1 reserve direct application of Parent operational-file changes to the owner and require a precise ChangeSet. The owner requested verification and a design decision here; this report therefore records the tested, exact Parent ChangeSet without writing `main.html` or changing the operational repository. No Supabase write or financial/inventory effect was made.

## 9. Closure state

`CURRENT INLINE DETAIL EXPANSION CONFIRMED — MODAL SELECTED AS BEST UX — MODAL CHANGESET STATICALLY VERIFIED — OWNER APPLICATION / DEPLOYMENT / AUTHENTICATED UI E2E PENDING`

Do not label the modal implemented or deployed until the approved ChangeSet is applied to the current Parent blob and its live UI acceptance tests pass.
