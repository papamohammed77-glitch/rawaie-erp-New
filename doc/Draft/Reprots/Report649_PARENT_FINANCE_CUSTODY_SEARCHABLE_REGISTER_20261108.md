# Report649 — Parent Finance Employee Custody Searchable Register

**Date:** 2026-11-08  
**Checkpoint:** LVE-2026-11-08-649  
**Status:** \`CHANGESET PREPARED — STATICALLY VERIFIED — OWNER APPLICATION / DEPLOYMENT / E2E PENDING\`

## 1. Current source and governing constraints

This request was resumed from LVE648 and revalidated against the current operational source rather than relying on prior report descriptions.

- Operational repository: \`papamohammed77-glitch/erp-frontend\`, branch \`main\`.
- Latest observed operational HEAD: \`9e12088352907404b53bde4cf4a0f2fe7483c9c0\` (forensic-extraction-only descendant).
- Parent source blob used for this ChangeSet: \`4405f87169c62baf770b6b675c1582cc484772ba\`.
- Target file: \`companies/company-1/main.html\`.
- Target module: \`RW_Finance_Custody\`, in the Finance Employee Custody tab.
- Governance source: \`doc/Draft/Reprots/الدستور التشغيلي الدائم.md\`, SHA \`3a6b1e220af8509e314e94df76563bbc6f84910d\`.
- Continuity source: \`CURRENT_STATE.md\`, SHA observed before this report \`8ba97b2a351fa0d75601810d6d83584b9823dbb3\`.

**Authority boundary:** constitution §7.1 assigns direct application of Parent and operational-app source changes to the owner. The assistant must supply the exact surgical ChangeSet, source anchors, effects and tests; it must not commit or directly modify \`main.html\`. Therefore no operational repository source commit or Cloudflare deployment was made for this request.

## 2. Confirmed current behavior and gap

**CONFIRMED:** the current Finance custody tab calls the existing \`GET_CUSTODY\` loader and keeps the loaded custody records, employee list, advances, expenses, supplier payments and settlements in the module snapshot. Its current \`draw()\` renders each custody as a detailed card in a vertical list. There is no searchable custody table and no date/employee filters.

The source already contains the data needed for a client-side register:
- custody: \`id\`, \`custody_code\`, \`employee_id\`, \`branch_id\`, \`purpose\`, \`issued_date\`, \`issued_amount\`, \`currency\`, \`status\`;
- employee names in \`S.employees\` for the finance view and \`employee_name\` on loaded custody rows;
- advances, expenses, payments and settlements for the existing detail cards.

The fix does not require another table, RPC, Edge Function, migration or direct Supabase query.

## 3. Production baseline observed read-only

SMART ERP project \`fiilmooggumokxanwiyx\` was queried read-only. At the time of this task, counts were:

| Table | Rows |
|---|---:|
| \`buyer_custodies\` | 1 |
| \`buyer_custody_advances\` | 1 |
| \`buyer_custody_expenses\` | 0 |
| \`buyer_custody_payments\` | 0 |
| \`buyer_custody_settlements\` | 0 |

These rows were not created or modified by this task. No fixture, document, cash movement, treasury mutation, cash-box movement, journal entry, supplier/AP update, stock movement or inventory movement was created.

## 4. Surgical Parent ChangeSet — exact implementation

All changes below target the existing module in \`companies/company-1/main.html\`. Apply them only to the source blob above, rechecking each exact anchor against the owner's current local copy before replacement.

### Change A — own filter listener references

**Original:**
\`\`\`js
var _renderSerial=0,_boundElement=null,_boundHandler=null;
\`\`\`

**Replace with:**
\`\`\`js
var _renderSerial=0,_boundElement=null,_boundHandler=null,_boundInputHandler=null,_boundChangeHandler=null;
\`\`\`

Reason: the filter's delegated \`input\` and \`change\` listeners must be tracked and removed with the custody module's existing \`stop()\` lifecycle.

### Change B — local table filter helper

Insert immediately before the existing \`function draw(){\` inside \`RW_Finance_Custody\`:

\`\`\`js
function filterRows(root){
  if(!root)return;
  var from=root.querySelector('#custody-filter-from'),to=root.querySelector('#custody-filter-to'),employee=root.querySelector('#custody-filter-employee'),search=root.querySelector('#custody-filter-search');
  var fromDate=from&&from.value||'',toDate=to&&to.value||'',employeeId=employee&&employee.value||'',query=search&&search.value?search.value.trim().toLocaleLowerCase():'';
  var rows=root.querySelectorAll('[data-custody-row="1"]'),visible=0,invalid=!!(fromDate&&toDate&&fromDate>toDate);
  var warning=root.querySelector('#custody-filter-warning'),empty=root.querySelector('#custody-filter-empty'),count=root.querySelector('#custody-filter-count');
  if(warning){warning.textContent=invalid?'تاريخ البداية يجب ألا يتجاوز تاريخ النهاية.':'';warning.style.display=invalid?'block':'none';}
  Array.prototype.forEach.call(rows,function(row){
   var date=row.getAttribute('data-custody-date')||'',emp=row.getAttribute('data-custody-employee')||'',text=(row.getAttribute('data-custody-search')||'').toLocaleLowerCase();
   var match=!invalid&&(!fromDate||date>=fromDate)&&(!toDate||date<=toDate)&&(!employeeId||emp===employeeId)&&(!query||text.indexOf(query)>=0);
   row.style.display=match?'':'none';if(match)visible++;
  });
  if(count)count.textContent='عرض '+visible+' من '+rows.length+' عهدة';
  if(empty){empty.textContent=rows.length?'لا توجد عهد تطابق معايير البحث.':'لا توجد عهد موظفين مسجلة.';empty.style.display=visible?'none':'block';}
}
\`\`\`

The date comparison is inclusive and uses ISO \`YYYY-MM-DD\` strings already returned by the service. A reversed date range shows a validation message and produces zero matching rows. Text search is case-insensitive.

### Change C — add the register table, preserving the existing detail loop

**Original anchor at the start of the custody card list:**
\`\`\`js
if(!S.custodies.length)h+='<div class="bg-white border rounded-2xl p-8 text-center text-slate-500">لا توجد عهد موظفين مسجلة.</div>';
S.custodies.forEach(function(c){
\`\`\`

**Replace that anchor with the following block.** It builds an employee selector from both the active employee list and historical employee names on custody rows, adds the date/employee/text controls, builds one summary row per custody, then starts the original detailed-card loop again unchanged.

\`\`\`js
var employeeChoices={};
S.employees.forEach(function(x){if(x&&x.id)employeeChoices[x.id]=x.name||x.email||'موظف';});
S.custodies.forEach(function(x){if(x&&x.employee_id&&!employeeChoices[x.employee_id])employeeChoices[x.employee_id]=x.employee_name||'موظف';});
var employeeOptions='<option value="">كل الموظفين</option>';
Object.keys(employeeChoices).sort(function(a,b){return String(employeeChoices[a]).localeCompare(String(employeeChoices[b]),'ar');}).forEach(function(id){employeeOptions+='<option value="'+E(id)+'">'+E(employeeChoices[id])+'</option>';});
h+='<section class="bg-white border rounded-2xl p-4 space-y-3"><div class="flex flex-wrap items-center justify-between gap-2"><div><h3 class="font-black">سجل العهد</h3><p class="text-xs text-slate-500 mt-1">ابحث برقم العهدة أو اسم الموظف أو الغرض، وصفِّ حسب تاريخ الإصدار والموظف.</p></div><div id="custody-filter-count" class="text-xs font-bold text-slate-500"></div></div>'+
'<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-3 items-end">'+
'<label class="block text-xs font-bold">من تاريخ<input id="custody-filter-from" data-custody-filter type="date" class="mt-1 w-full border rounded-xl p-3"></label>'+
'<label class="block text-xs font-bold">إلى تاريخ<input id="custody-filter-to" data-custody-filter type="date" class="mt-1 w-full border rounded-xl p-3"></label>'+
'<label class="block text-xs font-bold">الموظف<select id="custody-filter-employee" data-custody-filter class="mt-1 w-full border rounded-xl p-3">'+employeeOptions+'</select></label>'+
'<label class="block text-xs font-bold">بحث نصي<input id="custody-filter-search" data-custody-filter type="search" placeholder="رقم العهدة / اسم الموظف / الغرض" class="mt-1 w-full border rounded-xl p-3"></label>'+
'<button type="button" data-custody-clear-filters class="px-4 py-3 rounded-xl border font-bold">مسح الفلاتر</button></div>'+
'<p id="custody-filter-warning" class="hidden text-xs text-rose-700 font-bold" style="display:none"></p>'+
'<div class="overflow-x-auto rounded-xl border"><table class="w-full text-sm min-w-[900px]"><thead class="bg-slate-50 text-slate-600"><tr><th class="p-3 text-right">رقم العهدة</th><th class="p-3 text-right">الموظف</th><th class="p-3 text-right">الفرع</th><th class="p-3 text-right">تاريخ الإصدار</th><th class="p-3 text-right">الغرض</th><th class="p-3 text-right">قيمة الإصدار</th><th class="p-3 text-right">الحالة</th><th class="p-3 text-right">التفاصيل</th></tr></thead><tbody id="custody-filter-rows">';
S.custodies.forEach(function(c){
 var employeeName=employeeChoices[c.employee_id]||c.employee_name||'موظف',branchName=bm[c.branch_id]||'فرع غير محدد';
 var waitingAck=S.advances.some(function(a){return a.custody_id===c.id&&!a.acknowledged_at;});
 var status=c.status==='Settled'?'تمت التسوية':c.status==='Closed'?'مغلقة':waitingAck?'بانتظار إقرار التسليم':c.status==='UnderReview'?'قيد المراجعة':'مفتوحة';
 var searchText=[c.custody_code,employeeName,branchName,c.purpose,c.issued_date].join(' ');
 h+='<tr data-custody-row="1" data-custody-date="'+E(c.issued_date||'')+'" data-custody-employee="'+E(c.employee_id||'')+'" data-custody-search="'+E(searchText)+'" class="border-t hover:bg-slate-50">'+
 '<td class="p-3 font-black whitespace-nowrap">'+E(c.custody_code||'عهدة')+'</td><td class="p-3">'+E(employeeName)+'</td><td class="p-3">'+E(branchName)+'</td><td class="p-3 whitespace-nowrap">'+E(c.issued_date||'—')+'</td><td class="p-3">'+E(c.purpose||'—')+'</td><td class="p-3 font-bold whitespace-nowrap">'+M(c.issued_amount,c.currency)+'</td><td class="p-3 whitespace-nowrap">'+E(status)+'</td><td class="p-3"><button type="button" data-custody-open="'+E(c.id)+'" class="px-3 py-2 rounded-lg bg-indigo-50 text-indigo-700 font-bold whitespace-nowrap">عرض التفاصيل</button></td></tr>';
});
h+='</tbody></table></div><div id="custody-filter-empty" class="hidden p-6 text-center text-slate-500" style="display:none"></div></section>';
if(!S.custodies.length)h+='<div class="bg-white border rounded-2xl p-8 text-center text-slate-500">لا توجد عهد موظفين مسجلة.</div>';
h+='<details id="custody-full-ledger" class="space-y-3"><summary class="cursor-pointer p-3 rounded-xl border bg-white font-bold">التفاصيل الكاملة للعهد وإجراءات المالية</summary><div class="space-y-4 pt-3">';
S.custodies.forEach(function(c){
\`\`\`

### Change D — associate each existing detailed card with its custody ID

**Original:**
\`\`\`js
h+='<section class="bg-white border rounded-2xl p-4 space-y-3"><div class="flex flex-wrap justify-between gap-2"><div><b>'+E(c.custody_code||'عهدة')
\`\`\`

**Replace only the opening tag:**
\`\`\`js
h+='<section data-custody-detail="'+E(c.id)+'" class="bg-white border rounded-2xl p-4 space-y-3"><div class="flex flex-wrap justify-between gap-2"><div><b>'+E(c.custody_code||'عهدة')
\`\`\`

All existing card content, calculations, advance history, expense/invoice review, supplier evidence and settlement history remain untouched.

### Change E — close the details drawer after the existing card loop

**Original:**
\`\`\`js
  });
  return h+'</div>';
 }
\`\`\`

**Replace with:**
\`\`\`js
  });
  h+='</div></details>';
  return h+'</div>';
 }
\`\`\`

### Change F — delegated filter, table-detail navigation and existing actions

Replace the existing \`function bind(root){...}\` body only. Preserve the existing \`render()\` function between \`bind\` and \`stop\`.

\`\`\`js
function bind(root){
  var h=root||byId('finance-content');if(!h)return;
  if(_boundElement){
   if(_boundElement.onclick===_boundHandler)_boundElement.onclick=null;
   if(_boundInputHandler)_boundElement.removeEventListener('input',_boundInputHandler);
   if(_boundChangeHandler)_boundElement.removeEventListener('change',_boundChangeHandler);
  }
  var handler=function(ev){
   var clear=ev.target.closest&&ev.target.closest('[data-custody-clear-filters]');
   if(clear){['custody-filter-from','custody-filter-to','custody-filter-employee','custody-filter-search'].forEach(function(id){var input=byId(id);if(input)input.value='';});filterRows(h);return;}
   var open=ev.target.closest&&ev.target.closest('[data-custody-open]');
   if(open){
    var id=open.getAttribute('data-custody-open'),details=h.querySelector('#custody-full-ledger'),target=null;
    if(details)details.open=true;
    Array.prototype.forEach.call(h.querySelectorAll('[data-custody-detail]'),function(row){if(row.getAttribute('data-custody-detail')===id)target=row;});
    if(target&&target.scrollIntoView)target.scrollIntoView({behavior:'smooth',block:'start'});
    return;
   }
   var x=ev.target.closest&&ev.target.closest('[data-custody-advance],[data-custody-settle],[data-custody-review],[data-custody-doc]');
   if(!x)return;
   if(x.hasAttribute('data-custody-advance'))advance(x.getAttribute('data-custody-advance'));
   else if(x.hasAttribute('data-custody-settle'))settle(x.getAttribute('data-custody-settle'));
   else if(x.hasAttribute('data-custody-review'))review(x.getAttribute('data-custody-review'),x.getAttribute('data-custody-type'));
   else doc(x.getAttribute('data-custody-doc'));
  };
  var applyFilter=function(ev){if(ev.target&&ev.target.closest&&ev.target.closest('[data-custody-filter]'))filterRows(h);};
  h.onclick=handler;
  h.addEventListener('input',applyFilter);
  h.addEventListener('change',applyFilter);
  _boundElement=h;_boundHandler=handler;_boundInputHandler=applyFilter;_boundChangeHandler=applyFilter;
  filterRows(h);
}
\`\`\`

### Change G — clean up only this module's listeners in stop()

**Original:**
\`\`\`js
function stop(){_renderSerial++;if(_boundElement&&_boundElement.onclick===_boundHandler)_boundElement.onclick=null;_boundElement=null;_boundHandler=null;}
\`\`\`

**Replace with:**
\`\`\`js
function stop(){_renderSerial++;if(_boundElement){if(_boundElement.onclick===_boundHandler)_boundElement.onclick=null;if(_boundInputHandler)_boundElement.removeEventListener('input',_boundInputHandler);if(_boundChangeHandler)_boundElement.removeEventListener('change',_boundChangeHandler);}_boundElement=null;_boundHandler=null;_boundInputHandler=null;_boundChangeHandler=null;}
\`\`\`

## 5. Expected UI behavior

The tab will open with:
1. A normal custody register table showing custody code, employee, branch, issue date, purpose, issue value, status and a details action.
2. An inclusive \`من تاريخ / إلى تاريخ\` date range.
3. An employee selector populated from the current employee list plus employee names on the loaded custody rows.
4. A free-text search across custody number, employee name, branch, purpose and issue date.
5. A clear-filters action and a visible count of matching rows.
6. A details button that opens the preserved, existing custody detail cards and scrolls to the selected custody. The original advance, settlement, expense review, document and settlement-history actions remain active there.

No new finance transaction or accounting behavior is introduced.

## 6. Limits, risks and explicit non-changes

- The current existing \`GET_CUSTODY\` branch in \`save-purchase-order\` v30 orders by \`issued_date DESC\` and applies \`.limit(200)\` to custody rows. This proposed UI filter searches the rows returned by that existing contract; it does **not** claim to search beyond the newest 200. This is sufficient for the current dataset (one custody observed), but historical archive completeness beyond 200 requires a separately reviewed pagination/server-side-filter ChangeSet in the existing service. No such change is included here.
- The employee list for the finance view is limited to active users; the selector additionally unions historic employee IDs/names found on the loaded custody rows.
- Do not add database columns, indexes, RPCs, Edge Functions, direct table queries, or new finance writers for this UI request.
- Do not change the cash acknowledgement gate or treat pending issue/expense/receipt entries as posted movements.
- Do not replace or remove the existing detailed custody ledger; the summary table is an index over it.

## 7. Tests completed on the proposed patch

**Static source validation — PASS**
- Rebuilt the proposal against Parent blob \`4405f87169c62baf770b6b675c1582cc484772ba\`.
- The single executable inline script in Parent \`main.html\` compiled successfully using \`new Function\`; zero syntax errors.
- Static invariants confirmed one filter helper, both date controls, employee selector, text search, tagged rows, preserved detail cards and actions, existing render-serial guard, and listener cleanup in \`stop()\`.

**Filter helper unit simulation — PASS (6/6)**
- No filter: 3 of 3 rows visible.
- Employee E1: 2 rows.
- Inclusive date interval 2026-11-03 through 2026-11-04: 1 row.
- Combined date and employee filter: 1 row.
- Case-insensitive free-text search for “AHMED”: 2 rows.
- Invalid reversed interval: 0 rows plus a visible validation message.

These tests exercise the filter function against a controlled mock DOM. They are not a live browser test or deployed E2E test.

**Production safety — PASS (read-only)**
- Current counts observed: custody 1; advances 1; expenses 0; supplier payments 0; settlements 0.
- No Supabase writes, test fixtures, storage documents or financial/inventory effects were created.

## 8. Deployment and acceptance still pending

- No operational source file was committed or edited by the assistant, per constitution §7.1.
- No Cloudflare deployment was started or claimed.
- The connected Parent browser tab remained a prior/stale view and the available browser tool was read-only; actual UI interaction is **UNVERIFIED**.

After owner application, acceptance should verify the table is visible, date start/end filtering works inclusively, employee filtering works, free-text search works, reversed date validation appears, clear filters restores all loaded rows, details opens the correct card, and existing advance/settlement/review/document controls still respond. Then verify rapid switching away from and back to the Finance tab leaves no stale filter handlers.

**Final status:** \`CHANGESET PREPARED — STATICALLY VERIFIED — OWNER APPLICATION / DEPLOYMENT / E2E PENDING\`.
