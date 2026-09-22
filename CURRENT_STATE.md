# CURRENT STATE — AUTHORITATIVE FORENSIC CHECKPOINT — 2026-09-22

## 1. Authoritative sources
Current truth for this checkpoint is:
- CURRENT GIT
- CURRENT SOURCE
- CURRENT PRODUCTION
- CURRENT DATABASE
- CURRENT DEPLOYMENT EVIDENCE

Reports are forensic clues only.

## 2. Current Git
### System repository
Repository: papamohammed77-glitch/rawaie-erp-New
HEAD observed:
5efcbae22691a7d09574412056faf5a6494765ce
Parent:
6693d1c55c6b35314f18ddde63afe3613d59833c

### Frontend repository
Repository: papamohammed77-glitch/erp-frontend
HEAD observed:
78ecba3fd0e1adfa3af0249dc6bf1b7d80984c40
Parent:
bf88f28e33b789b4822f2dd2b7ec025827a8c54a
Current vouchers.html blob:
712f717c818819c5d5d9afba843465c7ae892672

Latest forensic report:
doc/Draft/Reprots/Report310_WAREHOUSE_VEHICLE_PICKER_CURRENT_SOURCE_REGRESSION_CLOSURE_20260922.md

## 3. Scope lock
Target:
- Warehouse → Inventory Management → Stock Vouchers.
- Vehicle smart search for DirectSale and DirectReturn.

Intentionally untouched:
- erp-frontend/companies/company-1/main.html
- erp-frontend/companies/company-1/warehouse/vouchers.html
- erp-frontend/companies/company-1/sales/van-sales.html

No new Edge Function.
No second Physical Stock Engine.

## 4. Production reality verified
Company:
00000000-0000-0000-0000-000000000001

Voucher operator:
vouchers@rawaea.com
role = مخزني
active_warehouse_role = أذونات
allowed_branch_ids = BR-01
status = Active

Direct-sales representative:
vansales@rawaea.com
role = مندوب بيع مباشر
permissions = [van-sales]
status = Active
