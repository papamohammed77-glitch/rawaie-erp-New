# UI AND CONSUMER EVOLUTION

## CURRENT DEPLOYED CONSUMERS
### Voucher
- `Current/PWA/vouchers.html` remains the principal warehouse voucher UI.
- Voucher Edge versions currently deployed: create v8, send v19, receive v21, complete v4, cancel v4.

### Picking
- `start-picking` v33 ACTIVE.
- `complete-picking` v16 ACTIVE.
- Current Git and Production start-picking identity lookup both use `users.auth_id`.

### Fulfillment
- loading complete v11.
- return complete v24.
- order delivery complete v13.

### Purchasing
- `receive-purchase` v12.
- Current PWA consumer historically sends `po_code`, `itemsReceived`, `notes`; explicit client operation identity must remain an item for current consumer verification rather than being assumed from old reports.

### Sales / Van Sales
- `save-sales-invoice` v15.
- Prompt 51 evidence confirms current `van-sales.html::submitQuickSale()` supplies an explicit operation identity for sales.
- Receipt path `collectPayment()` calls `save-receipt-voucher` and its proven operation identity remains unresolved in the current consumer audit.

### Main Journal Consumer
- `main.html::_saveJournalEntry()` was identified by Report 52 as stale relative to Production `save-journal-entry` v8.
- The surgical replacement was prepared but the deployed `main.html` was not altered in that review.

## CURRENT DEPLOYMENT GAP
There is no complete mapping yet of every current Git source SHA to its deployed Edge version and exact runtime consumer. This is a first-class open domain.

## BROWSER RUNTIME
Database/RPC/source tests are not browser E2E. Current browser/service-worker freshness remains unproven from the available execution environment.

## TEMPORARY EDGE REGISTRY
Many runtime/canary/harness functions remain registered ACTIVE; some returned 410 in observed logs. This must be retired by explicit deletion evidence, not by assuming 410 means gone.

## PRINCIPLE
A UI should consume the current Production capability contract. A UI must not become a second domain engine.