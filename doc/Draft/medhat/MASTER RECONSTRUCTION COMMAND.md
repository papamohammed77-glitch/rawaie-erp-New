# MASTER RECONSTRUCTION COMMAND
# RAWAEA ERP — CURRENT/PWA/main.html
# GOLD / DIAMOND GREENFIELD REBUILD
# SINGLE-FILE PRODUCTION ARTIFACT
# ZERO FUNCTION LOSS / ZERO CONTRACT LOSS / ZERO UNDOCUMENTED DEBT

---

# 0. MISSION CLASSIFICATION

هذه ليست مهمة Patch.

ليست مهمة Merge ميكانيكي.

ليست مهمة Concatenation.

ليست مهمة تجميل.

ليست مهمة إعادة تنسيق.

ليست مهمة اختصار للكود.

وليست إعادة كتابة سطحية لواجهة قديمة.

هذه مهمة:

**GREENFIELD RECONSTRUCTION UNDER CONTRACT COMPATIBILITY LOCK**

الهدف هو إعادة بناء:

```text
Current/PWA/main.html
```

من الصفر، كملف واحد نظيف، متكامل، production-ready، Gold/Diamond، بحيث يحتفظ بكل:

- الوظائف
- الخصائص
- الوحدات
- التبويبات
- الـUI
- الـDOM Contracts
- الـPublic APIs
- الـglobal functions المطلوبة
- الـevent contracts
- الـAPI contracts
- الـRPC contracts
- الـSupabase interactions
- الـstorage contracts
- الـoffline behavior
- الـsync behavior
- الـrealtime behavior
- الـPWA behavior
- الـpermissions
- الـOWNER semantics
- الـlicense semantics
- الـbusiness rules
- الـdata relationships
- الـhistorical contracts
- الـcurrent production contracts
- الـfeatures التي أضيفت عبر الرحلة السابقة
- الـfixes الصحيحة التي ثبتت
- الـedge cases
- الـerror handling
- الـloading states
- الـempty states
- الـvalidation rules
- الـauditability
- الـtraceability

مع إزالة:

- legacy defects
- duplicate logic
- hidden overrides
- obsolete assumptions
- unsafe fallbacks
- global tenant leakage
- duplicate initialization
- dead code
- accidental shadowing
- undocumented coupling
- stale contracts
- direct database writers غير المسموح بها
- obsolete API usage
- architectural violations
- functionality regressions

والنتيجة النهائية يجب أن تكون:

```text
ONE COMPLETE MAIN.HTML
+
ALL 11 LOGICAL PARTS
+
ALL SURVIVING FEATURES
+
ALL VALID HISTORICAL CONTRACTS
+
CURRENT PRODUCTION COMPATIBILITY
+
CURRENT GIT COMPATIBILITY
+
CENTRAL CORE COMPATIBILITY
+
NO REGRESSION
+
NO UNDOCUMENTED DEBT
```

---

# 1. ABSOLUTE AUTHORITY RULE

DO NOT TRUST:

- memory
- previous assistant conclusions
- previous reports
- previous completion percentages
- previous snapshots
- previous commits merely because they exist
- previous statements such as "fixed", "closed", "verified", "production-ready"
- old SHA values without refreshing Git
- old Production counts
- old runtime claims
- old workflows
- old CI status
- historical assumptions
- inferred contracts
- guesses

TRUST ONLY:

```text
CURRENT PRODUCTION
+
CURRENT GIT
+
DIRECT SOURCE INSPECTION
+
DIRECT DATABASE EVIDENCE
+
DIRECT EDGE/RPC INSPECTION
+
DIRECT RUNTIME EVIDENCE
+
DOCUMENTED HISTORICAL CONTEXT
```

Historical reports are evidence of history and intent.

They are NOT current operational truth unless independently revalidated.

---

# 2. GOVERNING ENGINEERING PRINCIPLE

The governing sequence is mandatory:

```text
UNDERSTAND
↓
RECONSTRUCT HISTORICAL CONTRACT
↓
OPEN CURRENT GIT
↓
OPEN CURRENT PRODUCTION
↓
OPEN CURRENT DATABASE
↓
OPEN CURRENT EDGE/RPC
↓
OPEN CURRENT CORE / PWA DEPENDENCIES
↓
TRACE DATA FLOW
↓
TRACE AUTH FLOW
↓
TRACE TENANT FLOW
↓
TRACE UI FLOW
↓
TRACE CROSS-PART DEPENDENCIES
↓
TRACE HISTORICAL DELTAS
↓
COMPARE ORIGINAL vs CURRENT
↓
COMPARE CURRENT vs PRODUCTION
↓
COMPARE CURRENT vs TARGET
↓
IDENTIFY ACTUAL GAPS
↓
DESIGN SAFE RECONSTRUCTION
↓
IMPLEMENT GREENFIELD MAIN.HTML
↓
STATIC VALIDATION
↓
SEMANTIC VALIDATION
↓
FUNCTIONAL VALIDATION
↓
INTEGRATION VALIDATION
↓
PRODUCTION CONTRACT VALIDATION
↓
RUNTIME VALIDATION
↓
AUDIT
↓
DOCUMENT
↓
CLOSE
```

NEVER:

```text
BUG FOUND
↓
GUESS
↓
PATCH
```

---

# 3. CRITICAL CHANGE OF STRATEGY

## DO NOT BUILD THE NEW MAIN.HTML BY CONCATENATING:

```text
main1
+
main2
+
main3
...
+
main11
```

blindly.

The previous investigation demonstrated that this is unsafe.

The 11 files are **logical fragments**, not guaranteed physical slices of the current `main.html`.

Therefore the correct strategy is:

```text
CURRENT MAIN1..MAIN11
+
ORIGINAL MAIN1..MAIN11
+
CURRENT MAIN.HTML
+
ORIGINAL MAIN.HTML
+
CORE
+
PWA COMPANIONS
+
CURRENT PRODUCTION CONTRACTS
+
CURRENT EDGE FUNCTIONS
+
CURRENT RPCS
+
CURRENT DATABASE SCHEMA
+
HISTORICAL VALID CONTRACTS
+
CROSS-PART DEPENDENCY MAP
=
NEW CANONICAL MAIN.HTML
```

The new file must be **reconstructed semantically**, not assembled mechanically.

---

# 4. FIRST COMMAND — FREEZE THE CURRENT WORLD

Before changing anything, obtain a fresh snapshot of:

```text
Git HEAD
Git branch
Git status
Current main.html SHA
Current main1..main11 SHA
Original main.html SHA
Original main1..main11 SHA
core.js SHA
sw.js SHA
register-sw.js SHA
all relevant PWA companion SHAs
all relevant Edge Function versions
all relevant Production RPC definitions
all relevant Production schema objects
all relevant RLS policies
all relevant triggers
all relevant grants
all relevant runtime logs
```

Record them in:

```text
CURRENT_RECONSTRUCTION_BASELINE
```

This baseline MUST be generated from current sources at execution time.

No value from an old report may replace a fresh query.

---

# 5. MANDATORY PRE-SWEEP SELF-AUDIT

Before modifying anything, internally complete:

```text
Business Understanding:
Architecture Understanding:
Database Understanding:
Historical Understanding:
Current Git Understanding:
Current Production Understanding:
Deployment Understanding:
Runtime Understanding:
```

Then:

```text
Confirmed Facts:
Unknowns:
Conflicts:
Unverified Claims:
```

Then:

```text
Production Opened:
Current Git Opened:
Historical Opened:
Schema Checked:
Triggers Checked:
RLS Checked:
Permissions Checked:
Consumers Checked:
Dependencies Checked:
Git History Checked:
```

Do not silently fill any field.

If something is unknown:

```text
UNKNOWN
```

must be recorded internally.

If something conflicts:

```text
CONFLICT
```

must be recorded.

If a claim comes from an older report only:

```text
HISTORICAL CLAIM — NOT CURRENT TRUTH
```

---

# 6. REQUIRED HISTORICAL SOURCES

Open and inspect directly:

```text
MASTER EXECUTION PROMPT.md

تقرير مبادئ حاكمة

برومبت 89+ملحق تقرير
برومبت 90+تقرير
برومبت 91+ملحق تقرير
برومبت 92+ملحق تقرير
تقرير 93
تقرير 94
تقرير 95
تقرير 96
تقرير 97
تقرير 98 إن وجد
تقرير 99
تقرير 100
تقرير 101
تقرير 102
تقرير 103 إن وجد
تقرير 104
تقرير 105
تقرير 106
تقرير 107
تقرير 108
تقرير 109
```

If a historical file cannot be found:

DO NOT INVENT IT.

Record:

```text
BLOCKING UNKNOWN
Historical source unavailable
```

but continue using all other direct evidence.

Do not stop the entire mission merely because a non-authoritative historical report is missing.

---

# 7. CURRENT SOURCE SET

Open directly:

```text
Current/PWA/main.html

Current/PWA/main/main1.md
Current/PWA/main/main2.md
Current/PWA/main/main3.md
Current/PWA/main/main4.md
Current/PWA/main/main5.md
Current/PWA/main/main6.md
Current/PWA/main/main7.md
Current/PWA/main/main8.md
Current/PWA/main/main9.md
Current/PWA/main/main10.md
Current/PWA/main/main11.md
```

Also open:

```text
Original/PWA/main.html

Original/PWA/main/main1.*
Original/PWA/main/main2.*
Original/PWA/main/main3.*
...
Original/PWA/main/main11.*
```

Use the actual repository paths discovered from Git.

DO NOT infer the paths.

---

# 8. READ-TO-END RULE

For every large file:

DO NOT claim that it was fully read merely because a viewer displayed a preview.

If output is truncated:

```text
STOP CLAIMING FULL READ
↓
READ IN CHUNKS
↓
CONTINUE UNTIL LAST LINE
↓
VERIFY END BOUNDARY
```

This applies especially to:

```text
main.html
main1
main2
main3
main4
main5
main6
main7
main8
main9
main10
main11
core.js
```

No reconstruction may be based on truncated content.

---

# 9. MAIN.HTML FORENSIC MODEL

Build:

```text
MASTER_FILE_INTEGRITY_MAP
```

with:

```text
Part
Original location
Current location
Start boundary
End boundary
Primary responsibility
Secondary responsibility
HTML structure
CSS ownership
DOM IDs
DOM classes
Forms
Tables
Modals
Drawers
Tabs
Buttons
Global functions
Scoped functions
Global variables
State objects
Caches
Event listeners
Event delegation
Initialization
DOMContentLoaded handlers
Boot functions
Timers
Intervals
Observers
Realtime listeners
BroadcastChannel
Storage keys
IndexedDB/Dexie usage
Service Worker interactions
Supabase reads
Supabase writes
Edge Function calls
RPC calls
API wrappers
Error handlers
Loading handlers
Toast/alert usage
Print/export behavior
File uploads
Downloads
CSV/XLSX logic
QR logic
Navigation
Router logic
Permission checks
Owner checks
License checks
Offline behavior
Sync behavior
Dependencies
Cross-part references
Historical contract
Current production contract
Target contract
```

---

# 10. FEATURE INVENTORY — ABSOLUTE NO-LOSS GATE

Build:

```text
MASTER_FEATURE_INVENTORY
```

Every feature in Original and Current must appear.

For each feature:

```text
Feature ID
Feature Name
Original source
Current source
Current production support
Historical contract
Business purpose
UI entry point
Function owner
Dependencies
Backend dependency
Data dependency
Permission dependency
State dependency
Required DOM elements
Required events
Required API/RPC
Required storage
Required errors
Required empty state
Required loading state
Status
Target
```

Every feature must end as one of:

```text
PRESERVED
REBUILT
IMPROVED WITHOUT CONTRACT LOSS
DEPRECATED WITH PROOF
```

Never silently drop a feature.

---

# 11. FUNCTION INVENTORY — NO FUNCTION LOSS

Extract from all versions:

```text
All function declarations
All named function expressions
All object methods
All arrow functions
All IIFE exports
All window/global functions
All callbacks
All event handlers
All DOM callbacks
All async functions
```

Build:

```text
MASTER_FUNCTION_REGISTRY
```

For each:

```text
Function Name
Current Owner
Original Owner
Callers
Callees
Parameters
Return contract
Side effects
DOM dependencies
State dependencies
Backend dependencies
Permission requirements
Error behavior
Historical status
Target status
```

Then perform:

```text
CURRENT vs ORIGINAL
CURRENT vs CURRENT-FRAGMENTS
CURRENT vs TARGET
```

The final main.html must contain every function required by surviving contracts.

---

# 12. SYMBOL COLLISION ANALYSIS

Before generating the final file, detect:

```text
Duplicate function names
Duplicate global variables
Duplicate DOM IDs
Duplicate event listeners
Duplicate initialization
Duplicate modal IDs
Duplicate table IDs
Duplicate form IDs
Duplicate CSS class ownership
Duplicate state variables
Duplicate Supabase clients
Duplicate API wrappers
Duplicate router functions
Duplicate render functions
Duplicate utility functions
```

Detect:

```text
shadowing
override
late-definition override
hoisting dependence
script-order dependence
implicit global creation
window namespace pollution
```

The final implementation MUST have one deliberate owner for each global contract.

---

# 13. GLOBAL CONTRACT LEDGER

Create:

```text
MAIN_HTML_CONTRACT_LEDGER
```

Minimum domains:

```text
Authentication
Session
Token lifecycle
User identity
Company identity
OWNER semantics
Permissions
License
Navigation
Router
Dashboard
Customers
Suppliers
Branches
Users
Roles
Items
Inventory
Stock availability
Stock vouchers
Orders
Runsheets
Picking
Loading
Delivery
Returns
Unloading
Vehicles
Drivers
Purchasing
Receiving
POS
TeleSales
Van Sales
Online Store
Accounting
Treasury
Chart of Accounts
Journal
Receipts
Payments
Transfers
Reports
HR
CRM
Audit
Settings
Notifications
Realtime
Offline
Sync
Cache
PWA
Print
Export
Search
Validation
Error handling
Mobile behavior
Responsive behavior
Branding
```

For every contract:

```text
Historical
Original
Current Git
Current Production
Target
Final implementation
```

No contract may disappear.

---

# 14. TENANT / COMPANY CONTRACT — HARD LOCK

The final main.html must never assume tenant identity from:

```text
app_settings LIMIT 1
global lookup
first row
cached company from unknown source
hardcoded company UUID
frontend-only trust
```

Current contract must be:

```text
Authenticated User
↓
users.auth_id
↓
users.id
↓
users.company_id
↓
RW_ShellContext
↓
Company-scoped reads/writes
```

The frontend must consume the authoritative company context exposed by the established shell contract.

Do NOT invent a second Tenant Context.

Do NOT create another company resolver if an established canonical resolver already exists.

---

# 15. OWNER CONTRACT — ABSOLUTE LOCK

Do not simplify:

```text
OWNER
```

into:

```text
role === 'مدير النظام'
```

Do not replace:

```text
permissions = ["*"]
```

with a hardcoded permission array.

Do not remove:

```text
isOwner
owner_profile
license state
Owner guards
License guards
```

unless direct current evidence proves the contract changed.

The established historical contract must remain compatible with:

```text
isOwner
+
permissions=["*"]
+
owner profile
+
active license
```

Any change requires explicit evidence.

---

# 16. PHYSICAL STOCK CONTRACT — ABSOLUTE LOCK

The new `main.html` MUST NOT become a stock engine.

Physical movement contract:

```text
Physical Stock Movement
↓
post_stock_movement
↓
stock_branches
+
inventory_log
```

Reservation:

```text
reserve_stock
release_stock_reservation
```

Only reservation responsibility.

The PWA may:

```text
read stock
request business operation
display stock
display availability
send approved payloads
```

It may NOT:

```text
directly mutate stock_branches.qty
directly insert inventory_log
reimplement stock engine
reimplement stock arithmetic
```

Any existing historical direct-writer code must be classified as:

```text
ACTIVE
LEGACY
OBSOLETE
BRIDGE
```

using direct current evidence.

---

# 17. CORE CONTRACT

Open:

```text
core.js
sw.js
register-sw.js
all relevant shared PWA utilities
```

Do not duplicate:

```text
Authentication
Token handling
Permission infrastructure
Tenant infrastructure
Cache
Offline
Sync
Realtime
API infrastructure
Shared Supabase client
Service Worker behavior
```

unless the actual current contract requires a local adapter.

If Core is the correct owner:

```text
USE CORE
```

not:

```text
COPY CORE INTO MAIN
```

If Core itself is deficient:

```text
REPAIR CORE CONTRACT
```

only when justified by direct evidence and only after checking all consumers.

---

# 18. CURRENT PRODUCTION MUST OVERRIDE HISTORICAL SNAPSHOTS

Before every material contract decision, check whether Production has moved after the historical report.

Especially revalidate:

```text
Edge Function versions
RPC definitions
Database schema
RLS
grants
triggers
item identity
branch identity
company identity
accounting identifiers
treasury identifiers
driver identifiers
runsheet identifiers
operation IDs
idempotency contracts
```

Do not preserve an old implementation merely because a report called it "correct".

Do not remove an old implementation merely because it looks old.

The current evidence decides.

---

# 19. DATABASE IDENTITY RULE

Always distinguish between:

```text
Display Code
Business Code
Primary Key
Foreign Key
Tenant Key
Global Key
```

Do not automatically treat:

```text
item_code
customer_code
branch_code
account_code
voucher_code
runsheet_code
order_code
driver email
treasury code
```

as primary database identity.

For every object:

```text
What identifies it?
Where is uniqueness enforced?
Is it global or company scoped?
What FK depends on it?
What does Production currently use?
```

Use the actual schema.

---

# 20. DATA SOURCE OF TRUTH RULE

When two tables represent related business state:

explicitly identify:

```text
Authoritative
Derived
Cached
Aggregate
Projection
Audit
```

Do not create dual sources of truth.

Examples must be revalidated, not assumed:

```text
order_details
run_sheet_details
inventory_log
stock_branches
journal_entries
journal_lines
ledger tables
```

If a field is derived:

```text
do not make it a second independent business source
```

unless the database contract proves otherwise.

---

# 21. ERROR HANDLING CONTRACT

Do not swallow errors.

Do not convert:

```text
TENANT_CONTEXT_UNAVAILABLE
AUTH_FAILURE
RPC_FAILURE
SERVER_FAILURE
VALIDATION_FAILURE
```

into silent fallback behavior.

The final UI must distinguish:

```text
Loading
Success
Empty
Validation error
Authorization error
Tenant error
Network error
Backend error
Unexpected error
```

No dangerous fallback may reopen access or silently change company context.

---

# 22. FAIL-CLOSED RULE

For security-sensitive conditions:

```text
Unknown tenant
Unknown user
Unknown permission
Invalid identity
Invalid branch
Invalid record
Missing license
Unauthorized action
```

the UI must fail closed.

Never:

```text
Unknown
↓
Fallback to MAIN
```

Never:

```text
Unknown company
↓
First app_settings row
```

Never:

```text
Permission unavailable
↓
Allow
```

---

# 23. PRESERVE EXISTING UX CONTRACT

Greenfield reconstruction does NOT mean redesigning away functionality.

Preserve:

```text
navigation
search
filters
sorting
pagination
modals
drawers
forms
validation
toasts
alerts
loading
empty states
confirmation dialogs
printing
export
responsive behavior
mobile interaction
keyboard behavior
QR functionality
file upload
image handling
charts
tables
drilldowns
reports
tabs
subtabs
```

Where the old design is unnecessarily complex but behavior is valid:

```text
KEEP CONTRACT
IMPROVE IMPLEMENTATION
```

not:

```text
DELETE BEHAVIOR
```

---

# 24. VISUAL RECONSTRUCTION RULE

The new UI should be:

```text
Professional
Enterprise-grade
Consistent
Responsive
Fast
Accessible
Visually coherent
Maintainable
```

Use design patterns inspired by:

```text
SAP
Microsoft Dynamics 365
Odoo
NetSuite
Modern enterprise SaaS
```

But NEVER copy their UI or architecture literally.

Extract:

```text
Business Pattern
+
Control Pattern
+
Accounting Pattern
+
Audit Pattern
+
Reconciliation Pattern
+
Closing Pattern
+
UX Pattern
```

Then adapt them to RAWAEA.

Creativity is encouraged only when:

```text
Better Outcome
+
Lower Complexity
+
Higher Auditability
+
Less Manual Effort
+
Same or Stronger Safety
```

---

# 25. VISUAL DESIGN TARGET

The new `main.html` should have a coherent design system with:

```text
Design tokens
Typography system
Spacing system
Radius system
Elevation system
Button hierarchy
Form hierarchy
Table hierarchy
Modal hierarchy
Alert hierarchy
Toast hierarchy
Navigation hierarchy
Card hierarchy
Responsive breakpoints
Dark/light decision based on current contract
RTL correctness
Arabic text rendering
Mobile touch targets
Keyboard navigation
Focus states
Disabled states
Loading skeletons
Empty states
Error states
```

Do not let each part invent its own CSS language.

---

# 26. PERFORMANCE TARGET

Avoid:

```text
duplicate Supabase clients
duplicate fetch wrappers
duplicate event listeners
repeated full-table reloads
unnecessary DOM recreation
unbounded timers
wasteful polling
recursive reload
duplicate Realtime subscriptions
blocking initialization
```

Use:

```text
lazy loading
event delegation where appropriate
request cancellation/stale-load protection
minimal re-rendering
controlled subscription lifecycle
controlled cache lifecycle
```

But do not break existing behavior merely for theoretical performance gains.

---

# 27. OFFLINE / SYNC / CACHE

Current offline behavior must be identified before rewrite.

Inventory:

```text
IndexedDB stores
Dexie schemas
storage keys
pending operations
sync queues
retry behavior
conflict behavior
auth dependency
service worker messages
cache keys
cache invalidation
offline navigation
```

The new main.html MUST preserve all valid existing behavior.

Do NOT create a second offline architecture.

---

# 28. REALTIME

Map all:

```text
Realtime subscriptions
channels
filters
callbacks
unsubscribe logic
reconnect behavior
state refresh
duplicate subscription prevention
```

The final file must guarantee:

```text
one intended subscription
one intended owner
no duplicate listeners
no memory leak
no stale callback overwrite
```

---

# 29. NAVIGATION / ROUTER

Create:

```text
MASTER_ROUTE_REGISTRY
```

Include:

```text
Route
Label
Permission
Owner-only?
License dependency?
DOM target
Renderer
Initialization
Cleanup
Related functions
Cross-part dependency
```

Every route currently expected by the application must survive unless direct evidence proves it is obsolete.

---

# 30. MODULE CONTRACTS

The final reconstruction must preserve the complete business surface currently represented by the 11 parts.

At minimum verify the existence and correct integration of the surviving contracts represented by:

```text
Foundation / Shell
Authentication / Tenant / Owner
Dashboard / Items / Inventory / Categories
Customers / Suppliers / Branches / Users / Settings
POS / Roles / TeleSales
Orders / Runsheets
Online Store / Purchasing / Receiving
Warehouse / Picking / Loading / Delivery / Returns / Unloading
Finance / Treasury / Accounting / Reports
Owner / License / Router / Global integration
HR / CRM / supporting modules
```

Do not use this list as proof of actual current contents.

Reconstruct the actual module inventory from source.

---

# 31. REGRESSION PROTECTION

The following is mandatory:

For every Original feature:

```text
Original behavior
↓
Current behavior
↓
Target behavior
↓
Final behavior
```

If:

```text
Original ≠ Current
```

do NOT assume the Current behavior is correct.

Investigate:

```text
Was it a deliberate change?
Was it a migration?
Was it a bug?
Was it a regression?
Was it compatibility?
Was it obsolete?
```

If a regression is discovered:

```text
FOUND
↓
ROOT CAUSE
↓
HISTORICAL REVIEW
↓
CURRENT PRODUCTION REVIEW
↓
TARGET REVIEW
↓
RESTORE OR IMPROVE
↓
TEST
```

---

# 32. KNOWN INVESTIGATION LEADS — MUST REVALIDATE

The following are not truths.

They are forensic leads discovered during previous investigation and MUST be rechecked against current sources:

```text
main3 missing historical/functional contracts
main5 cross-part dependencies
main7 warehouse integration gaps
main8 finance/report dependencies
main9 rec-offers regression
main10 route/permission integration
```

Also revalidate:

```text
create-stock-voucher
receive-stock-voucher
receive-purchase
save-sales-invoice
complete-return
complete-order-delivery
save-purchase-order
submit-online-order
save-settings
finance endpoints
```

Do not assume any report's status is still current.

---

# 33. SPECIAL MAIN9 REGRESSION GATE

Because historical investigation directly identified a potential regression around:

```text
rec-offers
rec-purchase
```

perform a mandatory semantic comparison:

```text
Original main9
vs
Current main9
vs
Production-supported behavior
vs
Target behavior
```

Verify whether `rec-offers` still has independent business meaning.

Do NOT accept a UI label as proof that the feature exists.

Do NOT delete it.

Do NOT collapse it into another recommendation.

Either:

```text
RESTORE
PRESERVE
IMPROVE
```

with evidence.

---

# 34. GREENFIELD REBUILD RULE

Do not reuse the old main.html as the implementation template.

The old main.html is a reference artifact.

Use it for:

```text
behavior archaeology
visual reference
feature discovery
contract discovery
historical comparison
```

but create the new file as a clean architecture.

Recommended internal conceptual layers:

```text
1. Document Shell
2. Design System
3. Runtime State
4. Auth / Tenant Context
5. Permission / Owner / License Guards
6. Shared Infrastructure
7. API / RPC adapters
8. Data loaders
9. Navigation / Router
10. Shared UI helpers
11. Module views
12. Module controllers
13. Events
14. Realtime
15. Offline / Sync adapters
16. Error / Notification layer
17. Boot / lifecycle
```

These layers may be implemented with the project's actual JavaScript conventions.

Do not introduce a framework solely for aesthetic reasons.

---

# 35. GLOBAL NAMESPACE POLICY

Use explicit namespaces such as:

```text
RW_*
```

only where compatible with existing contracts.

Each global symbol must have exactly one deliberate owner.

For each public symbol:

```text
PUBLIC
PRIVATE
ADAPTER
LEGACY-COMPATIBILITY
```

must be explicit.

Do not casually expose new globals.

Do not remove an existing required global without consumer analysis.

---

# 36. EVENT SYSTEM POLICY

Inventory:

```text
onclick
addEventListener
DOMContentLoaded
load
change
input
submit
click
keydown
popstate
hashchange
visibilitychange
online
offline
message
service worker messages
custom events
```

Then rebuild them intentionally.

Prevent:

```text
duplicate handlers
double submit
double initialization
stale handlers
modal handler accumulation
realtime handler duplication
```

---

# 37. ASYNC SAFETY

All asynchronous stateful flows must explicitly handle:

```text
loading
success
failure
cancellation
stale response
double invocation
retry
session expiry
network recovery
```

A stale response MUST NOT overwrite a newer UI state.

---

# 38. FORM SAFETY

For every form:

```text
initial state
edit state
create state
validation
submit state
duplicate submit prevention
error response
success response
reset
cancel
```

must be reconstructed.

No valid field may disappear from Original/Current without a justified contract change.

---

# 39. API/RPC CONTRACT REGISTER

Build:

```text
MAIN_HTML_BACKEND_CONTRACT_REGISTER
```

Columns:

```text
Consumer
Function / RPC / Edge
Current Production version
Request schema
Response schema
Auth requirement
Tenant requirement
Idempotency
Error contract
Current Git implementation
Target implementation
Status
```

Every backend call in the final file must correspond to a verified current contract.

Do not invent parameter names.

Do not infer response fields.

Do not replace UUIDs with labels.

Do not use obsolete endpoint signatures because they were present historically.

---

# 40. SECURITY / AUTHORIZATION GATE

Audit all:

```text
permission checks
Owner checks
role checks
license checks
tenant checks
frontend guards
backend authorization assumptions
```

The final UI must not accidentally expose an action simply because a button is hidden.

Frontend hiding is UX only.

Backend authorization remains authoritative.

---

# 41. DATA VALIDATION GATE

For every mutation request:

```text
Identity
Tenant
Permission
Required fields
Allowed values
Numeric validity
Quantity validity
State validity
Duplicate prevention
Operation identity
```

must be validated at the correct layer.

Do not move security-critical validation exclusively to frontend.

---

# 42. CLEAN ARCHITECTURE RULE

The new file must eliminate unnecessary:

```text
duplicate functions
dead helpers
deprecated aliases
nested obsolete fallbacks
copy/paste business logic
duplicated API clients
parallel state stores
duplicate routers
duplicate modal systems
duplicate toast systems
```

But compatibility aliases required by real consumers may remain.

Mark such compatibility code deliberately:

```text
COMPATIBILITY CONTRACT — DO NOT REMOVE
```

---

# 43. NO SHORTCUTS

The following are prohibited as substitutes for complete reconstruction:

```text
TODO
FIXME
temporary
placeholder
stub
fake data
hardcoded production values
mock API
fake success
silent catch
console-only failure
empty function
noop handler
feature hiding
button-only implementation
UI-only implementation for backend feature
```

No new "temporary patch layer".

No `main-patch.js`.

No `main-fix.js`.

No `main2-fix.js`.

No duplicate override file.

The desired artifact is:

```text
Current/PWA/main.html
```

one coherent implementation.

---

# 44. DATA PRESERVATION

Do not mutate business data merely to make the UI tests pass.

Do not:

```text
delete historical records
rewrite production quantities
rewrite users
rewrite owners
rewrite items
rewrite branches
rewrite orders
rewrite accounting
```

unless the task explicitly requires a data repair and that repair is independently proven safe.

Use transactional test data where appropriate.

Clean every artificial test artifact.

---

# 45. PRODUCTION DATA CLEANUP RULE

If stale or corrupt data is discovered:

```text
DISCOVER
↓
CLASSIFY
↓
TRACE ORIGIN
↓
CONFIRM BUSINESS EFFECT
↓
CHECK FOREIGN KEYS
↓
CHECK AUDIT
↓
CHECK HISTORICAL CONTRACT
↓
DECIDE
```

Allowed outcomes:

```text
KEEP
REPAIR
ARCHIVE
DELETE
```

Never:

```text
LOOKS LIKE FIXTURE
↓
DELETE
```

---

# 46. TESTING MATRIX

The final reconstruction must pass at least:

## Static

```text
HTML parsing
CSS parsing
JavaScript syntax
No duplicate IDs
No broken references
No duplicate globals
No undefined required functions
No duplicate boot
No duplicate event wiring
```

## Semantic

```text
Original feature matrix
Current feature matrix
Final feature matrix
```

## Contract

```text
Auth
Tenant
Owner
License
Permissions
API
RPC
Storage
Realtime
Offline
Sync
PWA
```

## Business

```text
Customer
Supplier
Branch
Item
Inventory view
POS
TeleSales
Orders
Runsheets
Picking
Loading
Delivery
Returns
Purchasing
Receiving
Online Store
Finance
Treasury
Reports
HR
CRM
Settings
Owner
License
Audit
```

Use the actual current feature set discovered from source.

---

# 47. WHOLE-FILE INTEGRATION TEST

After the new file is built, treat it as one program.

Test:

```text
Boot
↓
Authentication
↓
Tenant Context
↓
Permission Context
↓
Navigation
↓
Module loading
↓
Cross-module transitions
↓
Data loading
↓
Mutations
↓
Realtime
↓
Offline
↓
Sync
↓
Logout
↓
Re-login
```

No individual fragment PASS can substitute for Whole-File PASS.

---

# 48. BROWSER TEST

Launch the actual final:

```text
Current/PWA/main.html
```

in a browser-capable environment.

Do not use only:

```text
node --check
```

A syntax pass is not a runtime pass.

Test:

```text
Login
Owner login
Normal user
Tenant loading
Dashboard
Navigation
Each module
Main forms
Modal open/close
Search
Filters
Tables
Reports
Print
Export
File upload
QR
Mobile layout
Responsive layout
Realtime
Offline
Reconnect
Session expiry
Logout
```

Record:

```text
Browser Console
Network
JS Errors
Unhandled Promise Rejections
Failed requests
RPC failures
UI exceptions
```

---

# 49. PRODUCTION RUNTIME TEST

Production runtime verification must distinguish:

```text
SOURCE PASS
STATIC PASS
LOCAL PASS
DATABASE PASS
EDGE PASS
INTEGRATION PASS
BROWSER PASS
PRODUCTION RUNTIME PASS
```

Never collapse these labels.

The final closure requires the appropriate gates for the artifact being declared closed.

---

# 50. PRODUCTION ALIGNMENT GATE

Immediately before declaring ready for deployment:

refresh:

```text
Git HEAD
Current main1..main11
Current main.html
Production Edge versions
Production RPC definitions
Production schema
Production RLS
Production triggers
Production grants
```

Then compare.

If Production changed during reconstruction:

```text
DO NOT overwrite blindly
```

Rebase/reconcile against the latest state.

---

# 51. CURRENT GIT ALIGNMENT GATE

The final source must be committed as:

```text
Current/PWA/main.html
```

The commit must contain the actual file change.

Do NOT use:

```text
workflow-only commit
executor-only commit
test-only commit
comment-only commit
metadata-only commit
```

as evidence that the source artifact was rebuilt.

The final source commit must contain the real `main.html`.

---

# 52. VERSIONING / TRACEABILITY

The new file must contain a clear internal build marker, for example:

```text
RAWAEA ERP — MAIN PWA
GOLD/DIAMOND RECONSTRUCTION
BUILD:
SOURCE:
RECONSTRUCTION EVENT:
```

Do not change runtime contracts through the marker.

Keep the marker informational.

---

# 53. MANDATORY EVENT LOGGING

For every material discovery/change:

```text
EVENT ID:
DATE:
SOURCE:
OBJECTIVE:
INPUT STATE:

HISTORICAL CONTRACT:
CURRENT PRODUCTION FACT:
CURRENT GIT FACT:
CURRENT EVIDENCE:

DISCOVERY:
ROOT CAUSE:
BUSINESS IMPACT:
ARCHITECTURAL IMPACT:
DATABASE IMPACT:
EDGE/RPC IMPACT:
FRONTEND IMPACT:

CHANGE MADE:
WHY:
ALTERNATIVES REJECTED:

MIGRATION:
DEPLOYMENT:
COMMIT:

TEST:
RUNTIME TEST:
PRODUCTION VERIFY:

DATA CLEANUP:
AUDIT PRESERVATION:

POST-CHANGE STATE:
OBSOLETE STATE:
REMAINING OPEN ITEMS:
LATER CORRECTIONS:

CURRENT SURVIVING STATE:
SOURCE REFERENCES:
```

---

# 54. REQUIRED FORENSIC DOCUMENTS

Maintain/update:

```text
Current/CTO/MAIN_HTML_RECONSTRUCTION_BASELINE.md
Current/CTO/MAIN_HTML_CONTRACT_LEDGER.md
Current/CTO/MAIN_HTML_FEATURE_INVENTORY.md
Current/CTO/MAIN_HTML_DEPENDENCY_MAP.md
Current/CTO/MAIN_HTML_RECONSTRUCTION_EVENT_*.md
Current/CTO/MAIN_HTML_FINAL_CLOSURE.md
```

These documents are traceability artifacts.

They must never become substitutes for implementation.

---

# 55. WHAT TO DO WHEN A DEFECT IS FOUND

Never stop at:

```text
FOUND
```

Execute:

```text
FOUND
↓
ROOT CAUSE
↓
HISTORICAL REVIEW
↓
CURRENT PRODUCTION REVIEW
↓
CURRENT GIT REVIEW
↓
TARGET REVIEW
↓
SAFE DESIGN
↓
RECONSTRUCTION
↓
TEST
↓
DEPLOY
↓
PRODUCTION VERIFY
↓
DOCUMENT
↓
CLOSE
```

When one defect is repaired, immediately check for:

```text
new dependency
new regression
new dead reference
new contract drift
```

---

# 56. BLOCKING UNKNOWN RULE

If evidence is missing:

DO NOT INVENT IT.

Record:

```text
BLOCKING UNKNOWN
```

Then identify exactly:

```text
What is missing?
Why does it matter?
What object depends on it?
What cannot safely be decided without it?
What evidence would resolve it?
```

But continue all work that can be safely completed.

Do not turn one missing historical report into a reason to abandon the entire reconstruction if current direct evidence is sufficient.

---

# 57. FINAL QUALITY BAR

The new `main.html` is NOT acceptable merely because:

```text
it loads
```

or:

```text
it looks good
```

or:

```text
node --check passes
```

or:

```text
all tabs appear
```

or:

```text
buttons exist
```

It is acceptable only when:

```text
FUNCTIONAL COMPLETENESS
+
CONTRACT COMPLETENESS
+
DATA COMPLETENESS
+
ARCHITECTURAL COMPLETENESS
+
SECURITY COMPLETENESS
+
TENANT COMPLETENESS
+
AUDITABILITY
+
CROSS-PART INTEGRITY
+
PRODUCTION COMPATIBILITY
+
RUNTIME VERIFICATION
```

are satisfied.

---

# 58. MAIN.HTML MUST BE SELF-CONSISTENT

The final file must not depend on accidental ordering of fragments.

The final code must have an intentional initialization lifecycle:

```text
document
↓
shared infrastructure
↓
auth
↓
tenant
↓
permission
↓
license
↓
router
↓
module registration
↓
event registration
↓
realtime
↓
offline/sync
↓
boot
```

No module may assume that another module already executed merely because it happened to appear earlier in a historical file.

---

# 59. FINAL FUNCTIONAL PARITY GATE

Build a parity table:

```text
Original Feature
Current Fragment Feature
Final Feature
Status
Evidence
```

Acceptance:

```text
MISSING VALID FEATURE = 0
UNEXPLAINED FUNCTION LOSS = 0
UNEXPLAINED DOM LOSS = 0
UNEXPLAINED ROUTE LOSS = 0
UNEXPLAINED API LOSS = 0
UNEXPLAINED RPC LOSS = 0
UNEXPLAINED STORAGE LOSS = 0
UNEXPLAINED PERMISSION LOSS = 0
UNEXPLAINED BEHAVIOR LOSS = 0
```

---

# 60. FINAL SECURITY GATE

Verify:

```text
No hardcoded company context
No hardcoded user context
No hardcoded owner authorization
No insecure permission fallback
No global operational lookup
No unsafe app_settings LIMIT 1
No direct stock mutation
No direct inventory_log mutation
No bypass of backend authorization
No cross-tenant operational reads
No accidental public writer
```

---

# 61. FINAL DATA GATE

Verify:

```text
No unintended Production mutations
No orphan test rows
No test customers
No test items
No test orders
No test vouchers
No test ledger rows
No test audit pollution
No altered stock quantity
No altered allocations
No altered accounting balances
```

unless a separately authorized repair was required and documented.

---

# 62. FINAL RUNTIME GATE

The final browser execution must explicitly verify:

```text
No fatal console error
No unhandled promise rejection
No repeated boot
No duplicate subscription
No failed initial tenant resolution
No navigation failure
No broken module initialization
No RPC contract failure
No Edge contract failure
No DOM contract failure
No stale-load corruption
No unauthorized UI exposure
```

---

# 63. FINAL DOCUMENTATION GATE

The final closure record must answer:

```text
WHAT I PROVED
WHAT I DID NOT PROVE
WHAT I CHANGED
WHAT I DID NOT CHANGE
WHAT I DISCOVERED
WHAT I INITIALLY MISSED
WHAT BECAME OBSOLETE
WHAT REMAINS OPEN
WHAT COULD STILL BE WRONG
```

Then:

```text
PRODUCTION DEPLOYED?
PRODUCTION RUNTIME VERIFIED?
AUDIT VERIFIED?
DATA VERIFIED?
CURRENT GIT ALIGNED?
```

---

# 64. FINAL CLOSURE RULE

Do NOT write:

```text
CLOSED
```

because:

```text
the source compiles
```

Do NOT write:

```text
PRODUCTION READY
```

because:

```text
Git contains the file
```

Do NOT write:

```text
100%
```

because:

```text
all 11 parts exist
```

The final closure requires:

```text
ALL VALID FEATURES
+
ALL VALID CONTRACTS
+
NO UNEXPLAINED REGRESSIONS
+
NO UNCONTROLLED DEPENDENCIES
+
CURRENT GIT ALIGNMENT
+
CURRENT PRODUCTION ALIGNMENT
+
RUNTIME VERIFICATION
+
AUDIT TRACEABILITY
```

---

# 65. MANDATORY FINAL SELF-AUDIT

## WHAT I PROVED

List only direct evidence.

## WHAT I DID NOT PROVE

List everything not directly verified.

## WHAT I CHANGED

Exact files, exact commits, exact backend objects.

## WHAT I DID NOT CHANGE

Important protected contracts and data.

## WHAT I DISCOVERED

New facts discovered during reconstruction.

## WHAT I INITIALLY MISSED

Mistakes or incomplete assumptions discovered and corrected.

## WHAT BECAME OBSOLETE

Old implementations, obsolete contracts, obsolete assumptions.

## WHAT REMAINS OPEN

Only genuinely unresolved items.

## WHAT COULD STILL BE WRONG

Residual risk that remains after all tests.

---

# 66. FINAL SUCCESS CRITERIA

The task is CLOSED only when all are true:

```text
CURRENT PRODUCTION OPENED
+
CURRENT GIT OPENED
+
HISTORICAL SOURCES REVIEWED
+
MAIN.HTML OPENED TO END
+
MAIN1..MAIN11 OPENED TO END
+
ORIGINALS OPENED
+
CORE OPENED
+
SERVICE WORKER OPENED
+
PWA COMPANIONS OPENED
+
SCHEMA CHECKED
+
RLS CHECKED
+
TRIGGERS CHECKED
+
PERMISSIONS CHECKED
+
CONSUMERS CHECKED
+
DEPENDENCIES CHECKED
+
GIT HISTORY CHECKED
+
FEATURE INVENTORY COMPLETE
+
FUNCTION INVENTORY COMPLETE
+
DOM CONTRACT COMPLETE
+
CROSS-PART MAP COMPLETE
+
FINAL MAIN.HTML REBUILT FROM ZERO
+
NO VALID FEATURE LOST
+
NO UNDOCUMENTED CONTRACT LOST
+
NO DUPLICATE CORE
+
NO PHYSICAL STOCK WRITER IN MAIN
+
TENANT INTEGRITY
+
OWNER INTEGRITY
+
LICENSE INTEGRITY
+
AUTH INTEGRITY
+
API/RPC COMPATIBILITY
+
OFFLINE/SYNC COMPATIBILITY
+
REALTIME COMPATIBILITY
+
RESPONSIVE UX
+
STATIC PASS
+
SEMANTIC PASS
+
FUNCTIONAL PASS
+
WHOLE-FILE PASS
+
BROWSER PASS
+
PRODUCTION CONTRACT PASS
+
PRODUCTION RUNTIME PASS
+
AUDIT PASS
+
DATA PASS
+
GIT ALIGNMENT PASS
```

Then and only then:

```text
FINAL CLOSURE STATUS:
MAIN.HTML GOLD / DIAMOND = CLOSED
```

---

# 67. FINAL COMMAND

Do not rebuild the old architecture merely because it already exists.

Do not copy historical defects into the new file.

Do not simplify away features.

Do not create patches around the new file.

Do not create parallel engines.

Do not trust old reports over current evidence.

Do not trust old Production snapshots over current Production.

Do not trust the existence of a commit as proof of runtime.

Do not trust a successful workflow as proof of source modification.

Do not trust a source-level test as proof of browser behavior.

Do not use assumptions where the database can answer.

Do not use guesses where Git can answer.

Do not use reports where Production can answer.

Do not create debt to close debt.

Build one clean canonical artifact:

```text
Current/PWA/main.html
```

that is:

```text
FUNCTIONALLY COMPLETE
+
ARCHITECTURALLY GOVERNED
+
PRODUCTION COMPATIBLE
+
SECURE
+
AUDITABLE
+
TRACEABLE
+
RESPONSIVE
+
MAINTAINABLE
+
PERFORMANT
+
GOLD
+
DIAMOND
```

The objective is not:

```text
More Code
More Reports
More Patches
More Layers
```

The objective is:

```text
ONE CORRECT MAIN.HTML
```

representing:

```text
ONE COHERENT RAWAEA ERP PWA
```

with:

```text
ZERO VALID FEATURE LOSS
ZERO UNEXPLAINED CONTRACT LOSS
ZERO UNCONTROLLED CROSS-PART DRIFT
ZERO PARALLEL PHYSICAL STOCK ENGINE
ZERO UNDOCUMENTED SECURITY REGRESSION
ZERO UNDOCUMENTED TENANT REGRESSION
ZERO UNDOCUMENTED ACCOUNTING REGRESSION
ZERO UNDOCUMENTED UX REGRESSION
ZERO UNDOCUMENTED TECHNICAL DEBT
```

and final evidence sufficient for:

```text
PUBLISH
```

---

# 68. FINAL OUTPUT PACKAGE

At completion produce:

```text
1. Current/PWA/main.html
2. Current/CTO/MAIN_HTML_RECONSTRUCTION_BASELINE.md
3. Current/CTO/MAIN_HTML_CONTRACT_LEDGER.md
4. Current/CTO/MAIN_HTML_FEATURE_INVENTORY.md
5. Current/CTO/MAIN_HTML_DEPENDENCY_MAP.md
6. Current/CTO/MAIN_HTML_FINAL_CLOSURE.md
7. All material event records
8. Exact commit SHA
9. Exact final main.html blob SHA
10. Final test evidence
11. Final Production verification evidence
12. Final audit evidence
```

The final closure record MUST explicitly state:

```text
MAIN.HTML RECONSTRUCTION = CLOSED / NOT CLOSED

FUNCTIONAL PARITY = ...
CROSS-PART INTEGRITY = ...
TENANT INTEGRITY = ...
OWNER INTEGRITY = ...
LICENSE INTEGRITY = ...
INVENTORY CONTRACT = ...
ACCOUNTING CONTRACT = ...
AUTHORIZATION = ...
OFFLINE/SYNC = ...
REALTIME = ...
BROWSER RUNTIME = ...
PRODUCTION RUNTIME = ...
AUDIT = ...
DATA = ...
CURRENT GIT = ...

FINAL CLOSURE STATUS =
```

No false closure.

No cosmetic closure.

No report-based closure.

Only evidence-based closure.