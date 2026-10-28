# Report536 — Fresh Production RPC + Current Consumer Reconciliation for Delivery Assignments

**Observed:** 2026-10-28T20:28:28.592024Z (UTC), direct Production SQL/RPC; source and published-tab snapshots also inspected.  
**Scope:** Delivery Supervisor assignment → `runsheets.deliverer_id` → `public.delivery_logistics_query(..., 'agents', ...)` → `RW_DeliveryLogistics.agents()` in the Parent ERP → published Cloudflare page.  
**Mutation policy:** read-only investigation. No business rows, operational HTML, RPC/ACL/RLS, deployment, Service Worker, inventory, or accounting changed.

## 1. PRE-CHANGE SELF-AUDIT

| Area | Result | Evidence |
|---|---|---|
| Business understanding | CONFIRMED | Delivery assignment is stored on `runsheets.deliverer_id`; it is distinct from the `delivery_agents` master registry. |
| Current Parent source | CONFIRMED | `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`, blob `0c1745081e8d17480433ed527d77cac9f5292021`; GitHub page identifies existing repair commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`. |
| Consumer rendering code | CONFIRMED | `RW_DeliveryLogistics.agents()` reads `d.runsheet_assignments`, builds `assignmentRows` and `assignmentTable`, then passes the assignment card to `set(shell(...))`. |
| Live DB rows | CONFIRMED | Fresh Production query at `2026-10-28 20:27:23.810731+00`: RS-1 and RS-2 exist and are `Loaded`, each has `deliverer_id`; master `delivery_agents` count for the company is 0. |
| Live RPC contract | CONFIRMED | Fresh direct call at `2026-10-28 20:28:28.592024+00` to the actual `public.delivery_logistics_query` with the active owner actor and `p_view='agents'` returned `success=true`, `rows=[]`, and two `runsheet_assignments`: RS-2 / «مندوب توصيل 3» and RS-1 / «مندوب توصيل». |
| RPC security | CONFIRMED | Live function is `SECURITY DEFINER`, `search_path=public`; ACL observed as `postgres=X, authenticated=X, service_role=X` (no anon grant shown). Function validates active actor, company, email, and allowed permissions. |
| Current migration parity | CONFIRMED FROM PRIOR VERIFIED EVENT | Report535/534 records live function body parity with `20261027_delivery_supervisor_parent_runsheet_assignments.sql`; no contrary evidence surfaced in this read-only run. |
| Published artifact identity | UNVERIFIED | No Cloudflare deployment metadata or served-source hash could be obtained through the available read-only tools. |
| Authenticated UI E2E / DOM rendering | UNVERIFIED | Published tab text snapshot contains login controls and dashboard/navigation text but does not establish a fresh authenticated visit to the target Delivery Representatives view. No authenticated Network response body, target-view DOM, or Console error was available. |

**Execution confidence:** High for the Production data/RPC contract and the current Git consumer; insufficient for declaring the published UI fixed.

## 2. Fresh Production evidence

### Live data
The current schema uses `runsheets.runsheet_code` (not `runsheet_number`). The corrected read-only query returned:

- RS-1 — status `Loaded` — assigned user «مندوب توصيل».
- RS-2 — status `Loaded` — assigned user «مندوب توصيل 3».
- Company `delivery_agents` master records: `0`.
- Both runsheets have non-null `deliverer_id` values.

The first exploratory query used a non-existent `runsheet_number` column and failed read-only; schema inspection identified the canonical `runsheet_code` column and the query was corrected. No data was mutated.

### Actual RPC invocation
The live function was called directly with the active owner row's `id`, company ID, and email, using the same view/payload shape as the Parent consumer. The returned JSON confirms:

- `success: true`
- `rows: []` — expected for an empty master-agent registry.
- `runsheet_assignments: [RS-2, RS-1]` — both real assignments returned.

This is a direct Production SQL/RPC contract test, **not** a browser HTTP E2E test.

## 3. Consumer trace

```
Delivery Supervisor
  → persists assignment to runsheets.deliverer_id
  → public.delivery_logistics_query(p_view='agents')
  → response.runsheet_assignments
  → RW_DeliveryLogistics.agents()
  → assignmentRows
  → assignmentTable
  → set(shell(card('تعيينات الرانشيت من مشرف التوصيل', ...)))
  → published Parent UI
```

The current Git consumer explicitly renders the assignments separately from the `delivery_agents` registry. Its empty-master-row state does not suppress the assignment card: the card is constructed independently from `assignmentTable`, and an empty assignment list has its own empty-state row.

## 4. Root-cause status

### Confirmed historical defect — repaired in source
The Parent originally displayed the `delivery_agents` master registry only, while supervisor assignments were persisted in `runsheets.deliverer_id`. Commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` adds the separate runsheet-assignment table.

### What is proved now
- Production data contains the assignments.
- Production RPC returns the assignments.
- Current Git source consumes and renders the `runsheet_assignments` field.
- Empty `delivery_agents` rows are not the cause of an empty assignment dataset; they are a distinct business registry.

### What is not proved
The present evidence does **not** establish why the assignment table is not seen in the published experience. The remaining possibilities cannot be distinguished without a fresh authenticated target-view observation: served artifact drift, the target view not being opened/refreshed, or a browser runtime/rendering failure. No one of these should be stated as root cause without the missing artifact.

## 5. Surgical repair decision

**No new code or Production change is justified by the evidence currently available.** Reapplying the existing `main.html` patch, fabricating `delivery_agents` rows, changing the RPC/ACL, or bumping the Service Worker would be speculative and could duplicate valid work or alter the wrong business model.

The task's boundary is respected: no direct edit to `main.html` or `supervisor.html`; no Production schema/data/security mutation; no deployment.

## 6. Exact remaining acceptance test

In a normally authenticated session on the published Parent page:

1. Open **مركز التوصيل واللوجستيات → مناديب التوصيل**.
2. Capture the Network request/response for `delivery_logistics_query` with view `agents`; redact all credentials/tokens/headers.
3. Verify the response has RS-1 and RS-2 under `runsheet_assignments`.
4. Inspect whether the DOM contains **تعيينات الرانشيت من مشرف التوصيل** and both rows.
5. If payload is correct but the card is absent, capture the first relevant Console error and the served Parent artifact identity.
6. If the payload lacks assignments, capture the actual request signature and compare the invoked endpoint/function before changing SQL.
7. If served source differs from Git blob `0c1745081e8d17480433ed527d77cac9f5292021`, reconcile Cloudflare deployment/cache only after recording direct evidence.

Do not share passwords, cookies, JWTs, or Authorization headers.

## 7. Mutation ledger

- Application source: **unchanged**.
- Production data/schema/RPC/ACL/RLS: **unchanged**.
- Edge Functions / Service Worker / Cloudflare deployment: **unchanged**.
- Runsheets, inventory, accounting: **unchanged**.
- Test fixtures: **none created**.
- Documentation: this report and the Current State event only.

## 8. SELF-AUDIT FINAL

- **What I Proved:** Fresh Production RPC returns RS-1/RS-2; both are Loaded and assigned. The live Parent consumer contains a separate assignment card wired to `runsheet_assignments`. The empty master registry is not equivalent to missing assignments.
- **What I Did Not Prove:** Served Cloudflare artifact identity; fresh authenticated browser HTTP E2E; target-view DOM rendering; Console/runtime behavior.
- **What I Fixed:** No new operational fix was applied because no new operational defect was proven; existing source repair remains in place.
- **What I Initially Missed:** The actual runsheet key is `runsheet_code`, not `runsheet_number`; this was corrected after inspecting the live schema. The first failed query was read-only and caused no change.
- **What Could Still Be Wrong:** The published artifact may differ from current Git, or a browser runtime/target-view issue may remain. Both remain UNVERIFIED.
- **Final Confidence:** Production data/RPC + current consumer source = high; published UI completion = unverified.
- **Final Closure Status:** `PRODUCTION DATA/RPC + SOURCE CONSUMER VERIFIED / PUBLISHED AUTHENTICATED UI E2E OPEN / NOT CLOSED`.
