# RAWAEA ERP — CURRENT STATE PACK

## Checkpoint — 2026-09-08

### 1. Governance
العمل محكوم بمبادئ Engineering Governance المثبتة في ملفات MASTER وتقارير المراجعة:
- Production الحالية هي المرجع التنفيذي.
- لا تعديل قبل فهم التاريخ والعقد والسلوك الحالي.
- UNKNOWN لا يساوي BUG ولا يبرر الحذف.
- يتم العمل بوحدات Closure منفصلة، ولا ينتقل العمل إلى الوحدة التالية قبل إغلاق السابقة.
- Physical Stock Contract:
  `Physical Stock Movement -> post_stock_movement -> stock_branches + inventory_log`
- `reserve_stock` / `release_stock_reservation` مسؤولية Reservation فقط.

### 2. Current Git Reality
Repository: `papamohammed77-glitch/rawaie-erp-New`
Branch: `main`
Current HEAD: `d16d0262ce50d8e29446533347a1b56d2b38497e`

### 3. Main2 fragments
المصدر الجاري العمل عليه يدويًا بواسطة المالك هو:
`Current/PWA/main2/main1.md ... main11.md`

Current fragment identities:
- main1: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`
- main2: `58dd0da232ccca4c62bc17d87220bf8b705d85e8`
- main3: `479060e3d4bea5e2203c87f822b1dbc0e2f7d456`
- main4: `e89d29e4164c68784c109292f27d4d77df240557`
- main5: `c4518d05ada50830e819563a55169843679d3e94`
- main6: `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`
- main7: `6f7aef60ac137cd7f6b74281a17835dbd29595be`
- main8: `20f77481133d3e55ced949de16f88dadb0a69980`
- main9: `288b642d050f8b5ddeb6d43a7fd2a992fb05bb03`
- main10: `d57cef3bd7e42f7ba7ddc90bde81bdbabd5579a1`
- main11: `cad8bafa94da839ffb3a61f1a4581f52b98289f4`

### 4. Main6 Closure
Target: `Current/PWA/main2/main6.md`
Current blob: `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`

Report84 surgeries M6-01..M6-09 were verified in the actual current source after the latest user commit:
- Online Store settings company-scoped.
- Track Order company-scoped and uses `order_details.order_id`.
- Purchase Orders list company-scoped.
- Open Receive company-scoped and guards PO before details.
- Suppliers company-scoped.
- Purchase refresh company-scoped.
- Receive dialog uses remaining quantity.
- Track Order item name escaped.
- savePO explicitly guards missing session token.

Main6 EOF was inspected; the `RW_OnlineStore` and `RW_Purchases` closures are intact. No additional M6-01..M6-09 surgery remains to be performed.

### 5. Report84 -> Current reconciliation
Report84 referenced an earlier main6 blob. The current Git commit `d16d0262...` contains the user-applied main6 surgeries and is the current source evidence.

### 6. Production Reality — 2026-09-08
Supabase project: `fiilmooggumokxanwiyx`

Current Production snapshot:
- companies: 1
- branches: 2
- users: 24
- items: 17
- stock_branches: 20
- orders: 0
- order_details: 0
- purchase_orders: 0
- purchase_order_details: 0
- stock_vouchers: 0
- inventory_log: 3
- audit_log: 1868
- relevant tables remain RLS-enabled.

Current Production also contains migrations dated 2026-09-08; therefore old report snapshots must not be treated as current Production truth.

### 7. Production contracts relevant to Main6
- `items.item_code` is globally UNIQUE.
- `order_details.order_code` does not exist; `order_details.order_id` is the order relationship.
- `purchase_orders.company_id` is NOT NULL.
- `suppliers.company_id` is NOT NULL.
- `app_settings.company_id` is NOT NULL.
- `receiving.operation_id` is UNIQUE.

### 8. Critical Assembly Boundary
There are two distinct fragment trees in the repository:
1. `Current/PWA/main2/main1.md ... main11.md` — the owner-operated surgical source used for the current Main2 work.
2. `Current/PWA/main/main1.md ... main11.md` — a different maintained fragment tree.

The current official reconstruction tool `tools/run_final_main_reconstruction_20260831.py` consumes **`Current/PWA/main/`**, not `Current/PWA/main2/`, and writes `Current/PWA/New-main`.
The `forensic_main_assembly.yml` workflow follows the same `Current/PWA/main/` source path.

This source divergence is a real governance boundary. Do NOT merge `main2` into the `main` assembly path by assumption.

### 9. Main6 status
`MAIN6 SOURCE SURGERY = VERIFIED / CLOSED`
`MAIN6 PARENT INTEGRATION = OPEN`
`FULL MAIN2 ASSEMBLY = OPEN — CANONICAL ASSEMBLY SOURCE MUST BE RESOLVED WITHOUT GUESSING`

### 10. Reports
Latest session report:
`doc/Draft/Reprots/Report85_Main6_Recheck_and_Assembly_Boundary_20260908.md`

Previous:
`doc/Draft/Reprots/Report84_Main6_M6-Source_Surgical_Execution_20260908.md`

Previous reports are preserved and must not be deleted.

### 11. Next controlled action
قبل أي دمج أو نشر للملف الأم:
- إثبات أن `Current/PWA/main2/*` هو المصدر canonical المقصود للـassembly.
- بعد الإثبات فقط، تنفيذ reconstruction من هذه الأجزاء، ثم structural validation، Node syntax validation، browser smoke، ثم Production deployment/runtime verification.

### 12. Important ownership rule
- Owner/المستخدم يعدّل ملفات `Current/PWA/main2/*.md` يدويًا.
- المساعد لا يعدّل هذه الأجزاء مباشرة.
- Production/Supabase يمكن إصلاحها وتنفيذ migrations عليها عند ثبوت الحاجة.

### 13. Closure statement
لا يوجد ادعاء حالي بأن Parent PWA أو Production deployment الناتج من Main2 مغلق Gold/Diamond.
المغلق حاليًا هو **Main6 source surgery فقط**، مع بقاء **Full Main2 Assembly** مفتوحًا حتى يتم حسم مسار الـcanonical assembly بناءً على دليل المستودع الفعلي.
