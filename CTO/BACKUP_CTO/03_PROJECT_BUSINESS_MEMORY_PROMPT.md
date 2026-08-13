# BACKUP CTO — PROMPT 03
## RAWAEA PROJECT / BUSINESS MEMORY RECONSTRUCTION

استوعب المشروع كنظام أعمال، لا كمجموعة ملفات.

## ERP CONTEXT
RAWAEA ERP هو نظام توزيع FMCG يشمل:
Sales / POS / Telesales / Van Sales / Order Ticker / Purchasing / Warehouse / Receiving / Picking / Loading / Runsheet / Delivery / Returns / Settlement / Treasury / Accounting / Ledgers / Reporting / Store.

## CORE BUSINESS MODEL
- POS: بيع نقدي فوري، ينعكس على المخزون حسب Production contract.
- Telesales: دورة طلبات قبل التنفيذ.
- Runsheets: تجميع الطلبات للتوزيع.
- Warehouse: Receiving / Picking / Loading / Return / Unloading.
- Vehicle: مخزن/وعاء متنقل.
- Representative: مسؤول عهدة ومبيعات وتحصيل، مستقل عن هوية المركبة.

## INVENTORY MODEL
`stock_branches.qty` = physical stock.
`allocated_qty` = reserved/allocated stock.
`available_qty` = qty - allocated_qty، وقد تكون Generated.

لا تتعامل مع allocated_qty كحركة مخزون.
لا تجعل Sales/Accounting تعيد حساب المخزون يدويًا.

## DIRECT SALE
المقصود بـ DirectSale ليس بيعًا من MAIN للمستهلك.
المقصود: صرف بضاعة إلى سيارة/مندوب البيع المباشر، والسيارة وعاء متنقل.

الهدف:
MAIN → VAN

بعد ذلك:
VAN → Customer عبر VanSale

## CUSTODY
مسؤولية المندوب تشمل:
1. البضاعة.
2. قيمة البضاعة المباعة.
3. قيمة التحصيل الآجل من السوق.

السيارة ليست صاحب العهدة.

تغيير السيارة للمندوب لا يتم بتعديل بسيط في البيانات إذا كانت هناك عهدة؛ يجب استخدام إجراءات مخزنية وعهدة صارمة.

## SYSTEM-OF-RECORD RULE
حساب السيارات والمناديب والعملاء والحسابات يتم من النظام الأم.
المساعد لا ينشئ حسابات بديلة إذا كان النظام الأم يملك الكيان.

## VEHICLE BASELINE
المركبة الوحيدة المعتمدة حاليًا للاختبار:
`VEH-92yrzb`

Mobile branch:
`VAN-VEH-92yrzb`

Demo representative:
`van-sales@rawaea.com`

## BUSINESS TERMINOLOGY RULE
إذا اكتشفت أن اسمًا تقنيًا قديمًا لا يعبّر عن Business meaning، يجوز إعادة التسمية فقط إذا حافظنا على كل الآثار والعلاقات والتقارير والـaudit والـaccounting consequences.

لا تغير terminology في العزل؛ اعمل Contract Reconciliation.
