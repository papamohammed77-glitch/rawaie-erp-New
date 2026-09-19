# REPORT 255 — القائمة الجانبية + التقارير الشاملة
## RAWAEA ERP — تحقيق جنائي وتعديل جراحي — 2026-09-19

## 1. نطاق التنفيذ

هذه الجلسة أغلقت التحقيق والتصميم الجراحي في نطاقين مترابطين فقط:

1. القائمة الجانبية والتوسيع/الطي ووظيفة التنقل الحديثة داخل Mother.
2. تبويب RW_Reports_Comprehensive، مع إكمال فجوة Modal → Page وإصلاح defect الـhover المثبت.

لم يتم تعديل Mother main.html في هذه الجلسة.
لم يتم إنشاء تغيير Production جديد لأن التحقيق أثبت أن البنية الحالية للـReports Production قد أغلقت بالفعل ولا تحتاج Migration إضافية.

مبدأ الحوكمة المستخدم هو:
UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH → COMPARE TARGET → IDENTIFY GAP → MINIMAL SAFE CHANGE → IMPLEMENT → VERIFY.

المصادر القديمة استُخدمت لإعادة بناء السبب والسياق، وليس باعتبارها Current Truth.

---

## 2. Source of Truth المثبت

### System Repository

Repository:
papamohammed77-glitch/rawaie-erp-New

Current HEAD:
01bdade6a582ca79b8b732fc0c6fc81b9370ffe

هذا commit يسجل حالة Comprehensive Reports الحالية.

Commit السابق الذي يحمل التنفيذ التشغيلي للتقارير:
55e7f32cdfa574cb33057e596e01ef743ca99ed5

Parent:
c5dea0197fbc1a96500e436fee4d996f2fb624ad

### Mother Repository

Repository:
papamohammed77-glitch/erp-frontend

Current HEAD:
f6d57ff5eb235af09405de7a8df81812d061edd3

Parent:
adeda04609723e221249e51621cc674b05dfc5ce

Current verified main.html blob:
94a30d3d7fda02967b6a1f3b112ea2ced6d77ac9

آخر commit الحالي غيّر forensic extract فقط ولم يغيّر main.html.
لذلك blob المذكور هو مصدر الكود الحالي الذي بُني عليه هذا التحقيق.

### Current State

CURRENT_STATE.md تم قراءته، وآخر قسم حكومي له يثبت أن Comprehensive Reports كان عند:
- Current Git verified
- Current Source verified
- Production reporting security closed
- Drilldown source patch = Owner Ready
- Browser E2E = Open
- 38-report live smoke = Open
- Full Comprehensive Reports = Open until Owner cutover + browser evidence

هذه الحالة ما زالت مطابقة للكود الحالي بعد التحقق الجنائي.

---

## 3. Current Production — إعادة المطابقة في نفس لحظة التقرير

Production:
fiilmooggumokxanwiyx

الحالة الفعلية التي تم قراءتها مباشرة:

- companies = 1
- active branches = 2
- active items = 16
- stock rows = 20
- inventory_log = 3
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- purchase_orders = 0
- purchase_order_details = 0
- stock_vouchers = 0
- stock_voucher_details = 0
- customer_ledger = 0
- supplier_ledger = 0
- daily_settlements = 0
- journal_entries = 2
- journal_lines = 0

هذه البيانات تؤكد أن Production الحالية ما زالت Sparse Runtime وليست بيئة اختبار مكتملة.
لذلك لم يتم اختراع Fixtures دائمة للحصول على Browser/Report PASS.

### Reporting RPC Production

تم التحقق من صلاحيات RPC الحالية، ومن بينها:

- inventory_movement_report
- inventory_replenishment_report
- comprehensive_inventory_turnover_report
- finance_tax_report
- finance_tax_settlements_report
- accountant_gl_account_activity
- get_trial_balance
- get_profit_loss
- get_balance_sheet_data
- get_cash_flow

النتيجة المثبتة:
- anon EXECUTE = false
- authenticated EXECUTE = true
- service_role EXECUTE = true

وبالتالي Production security closure السابق للتقارير ما زال قائمًا ولا يحتاج إعادة فتح.

لا يوجد Production schema gap مثبت يحتاج تنفيذًا جديدًا لهذه الجلسة.

---

# 4. التحقيق التاريخي والمعماري — القائمة الجانبية

## 4.1 لماذا بُنيت القائمة الحالية بهذا الشكل؟

الكود الحالي يعرّف RW_Navigation داخل Mother ويحتوي على menuTree مركزي واحد يربط:

Navigation
↓
Permission filtering
↓
RW_Views
↓
Module renderers

والقائمة لا تدير بيانات أعمال ولا تنفذ عمليات مخزنية.
هي طبقة UX/orchestration للوصول إلى الوحدات.

الـmenuTree الحالي يحافظ على البنية الوظيفية المعتمدة للنظام:
- المبيعات
- المشتريات
- المخازن والمخزون
- الحسابات والمالية
- التقارير الذكية
- HR
- CRM
- المستخدمون
- الأدوار
- الترخيص
- الإعدادات

كما أن العمليات الميدانية موجودة كوحدات مستقلة داخل المخازن:
Receiving → Picking → Loading → Delivery → Return → Unloading

لم يتم تغيير هذا البناء.

## 4.2 ما الخطأ الحقيقي في التنفيذ الحالي؟

الخلل ليس في Business Menu نفسه.
الخلل في طبقة UX التي تعرضه.

### Defect A — Collapse State غير مكتمل

الكود الحالي يكتب:
rw_sidebar_collapsed

إلى localStorage.

لكن buildSidebar لا يعيد تطبيق الحالة المخزنة على:
- sidebar
- main
- زر التوسيع

أي أن persistence ناقصة.

### Defect B — Collapse Mode يفقد وظيفة navigation

عند collapse:
- النصوص تختفي.
- submenus تختفي.
- العناصر leaf الحالية لا تعرض icons الخاصة بها.
- العناصر group لا تفتح كـflyout.
- الزر نفسه يبقى ☰ فقط دون state semantics.

وبالتالي الـCollapsed Sidebar ليست Compact Navigation حقيقية.

### Defect C — لا توجد Recent / Favorites

القائمة الحالية لا تقدم:
- Favorites
- Recent
- Search داخل navigation

وهذا يفوّت أنماطًا مثبتة في أنظمة حديثة.

### Defect D — حالة مجموعات القائمة ليست persistent

فتح/طي المجموعات الحالية يعتمد على:
nextElementSibling.style.display

ولا يوجد state مستقل للمجموعات.

### Defect E — inline onclick

القائمة الحالية تبني الأحداث داخل HTML strings:
onclick="..."

وهذا يجعل navigation أقل وضوحًا وأصعب في الضبط المركزي.

الإصلاح المقترح يستخدم event delegation مع keys واضحة دون تغيير الـviews أو الـpermissions.

---

# 5. المقارنة التنافسية

## Dynamics 365

توثيق Microsoft يثبت أن Navigation Pane الحديثة تجمع:
Favorites
Recent
Workspaces
Modules

كما أن pane يمكن أن تكون expanded/collapsed، ويمكن توسيعها من الأيقونات في الوضع المطوي.

المبدأ المنقول إلى RAWAEA:
Compact icons + Favorites + Recent + Modules + expandable groups.

## SAP Fiori

توثيق SAP الحالي يثبت مفهوم:
Pinned Spaces
All Spaces
إعادة ترتيب العناصر
إظهار ما يحتاجه المستخدم أولًا

المبدأ المنقول:
ترتيب navigation شخصيًا دون تغيير صلاحيات النظام.

## Business Central

توثيق Microsoft يثبت:
- root navigation items
- submenus
- personalization
- حفظ views
- إعادة ترتيب navigation/actions

المبدأ المنقول:
Hierarchy واضحة + حالة UI محفوظة + عدم خلط personalization مع authorization.

## Manager.io

التوثيق الرسمي يثبت compact navigation:
- icons فقط في الوضع الضيق
- hover يظهر اسم العنصر
- الرجوع للوضع الكامل من control واضح

المبدأ المنقول:
Collapsed mode يجب أن يبقى usable، وليس مجرد شريط فارغ.

## Odoo

توثيق Odoo الحديث يثبت:
- menu hierarchy
- menu grouping
- visibility by access rights
- personal dashboard/navigation organization

المبدأ المنقول:
Visibility يجب أن تكون permission-driven، بينما ترتيب/عرض navigation يمكن أن يكون UX state.

## Daftra

التوثيق الحالي يثبت أن إظهار أقسام ووظائف النظام يتأثر بتفعيل التطبيقات والصلاحيات المرتبطة بالدور.

المبدأ المنقول:
القائمة لا تعطي صلاحية؛ بل تعكس صلاحية موجودة بالفعل.

---

# 6. القرار المعماري للقائمة

لم تتم إضافة:
- DB navigation table
- Server-side favorites
- role menu mutation schema
- cross-tenant navigation config

والسبب:
هذه ليست فجوة Business Contract مثبتة.
هي User UX state.

الحل الصحيح الآن:
localStorage لكل مستخدم/متصفح في:
- collapsed state
- expanded groups
- favorites
- recent

أما Authorization فيظل:
RW_Permissions_check
+
OWNER semantics

وبذلك لا تختلط:
User personalization
مع
Business authorization.

هذا يحافظ على النظام الأم كـcontrol center دون إدخال Production debt جديد.

---

# 7. OWNER SURGICAL PATCH — RW_Navigation

## البحث والحذف

في:
companies/company-1/main.html

ابحث عن العنصر الكامل:

const RW_Navigation = {

واحذف البلوك الكامل من هذا السطر حتى السطر:

window.RW_Navigation = RW_Navigation;

أي احذف RW_Navigation بالكامل فقط، ولا تحذف الـIIFE التالية الخاصة بنسيت كلمة المرور.

## البديل الجاهز الكامل

استبدل البلوك المحذوف بالنص التالي:

~~~~javascript

const RW_Navigation = {
    menuTree: [
        { view: 'dashboard', icon: 'fa-chart-pie', label: 'لوحة التحكم' },
        { icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [
            { view: 'telesales', label: 'التلي سيلز' },
            { view: 'customers', label: 'العملاء' },
            { view: 'online-store', label: 'المتجر الإلكتروني' },
            { view: 'pos', label: 'نقطة البيع' },
            { view: 'orders', label: 'أوردرات المبيعات' },
            { view: 'quotes', label: 'عروض الأسعار' },
            { view: 'price-lists', label: 'قوائم الأسعار' },
            { view: 'promotions', label: 'العروض والخصومات' },
            { view: 'sales-decision-center', label: 'مركز قرار المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] },
            { view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] },
            { view: 'loyalty', label: 'الولاء والمكافآت', perm: ['sales_manager','sales_supervisor','general_manager','reports','customers','pos','telesales','orders','van-sales'] },
            { view: 'runsheets', label: 'الرانشيتات' },
            { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }
        ] },
        { icon: 'fa-truck', label: 'إدارة المشتريات', submenu: [
            { view: 'suppliers', label: 'الموردين' },
            { view: 'purchase-pos', label: 'نقطة شراء' },
            { view: 'purchases', label: 'دورة المشتريات' }
        ] },
        { icon: 'fa-warehouse', label: 'إدارة المخازن والمخزون', submenu: [
            { view: 'items', label: 'الأصناف' },
            { view: 'branches', label: 'المخازن والفروع' },
            { view: 'inventory-control', label: 'مركز التحكم في المخزون' },
            { label: 'العمليات المخزنية', icon: 'fa-timeline', submenu: [
                { view: 'receiving', label: 'الاستلام' },
                { view: 'picking', label: 'التحضير' },
                { view: 'loading', label: 'التحميل' },
                { view: 'delivery', label: 'التوصيل' },
                { view: 'return', label: 'المرتجعات' },
                { view: 'unloading', label: 'التفريغ' }
            ] },
            { label: 'الأذونات المخزنية', icon: 'fa-file-signature', submenu: [
                { view: 'transfer', label: 'تحويل مخزني' },
                { view: 'direct-sale', label: 'صرف سيارة بيع مباشر' },
                { view: 'direct-return', label: 'استلام مرتجع سيارة' },
                { view: 'supplier-return', label: 'مرتجع لمورد' },
                { view: 'vouchers', label: 'عرض الأذونات' }
            ] },
            { label: 'الجرد', icon: 'fa-clipboard-check', submenu: [
                { view: 'vehicle-count', label: 'جرد سيارة' },
                { view: 'branch-count', label: 'جرد فرع' },
                { view: 'general-count', label: 'جرد عام' }
            ] }
        ] },
        { icon: 'fa-coins', label: 'إدارة الحسابات والمالية', submenu: [
            { action: 'showFinanceTab', arg: 'treasury', label: 'الخزائن والبنوك', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'accounts', label: 'دليل الحسابات', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'journal-list', label: 'قائمة القيود اليومية', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'journal', label: 'قيد يومي جديد', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'recurring-journals', label: 'القيود المتكررة', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'receipts', label: 'سندات القبض', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'payments', label: 'سندات الصرف', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'expenses', label: 'المصروفات', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'transfers', label: 'التحويلات', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'cheques', label: 'الشيكات', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'bank-reconcile', label: 'مطابقة البنك', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'tax', label: 'الضرائب', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'assets', label: 'الأصول والإهلاك', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'budgets', label: 'الموازنات', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'periods', label: 'الفترات المحاسبية', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'installments', label: 'التقسيط والتحصيل الآجل', perm: ['finance', 'finance_manager'] },
            { action: 'showFinanceTab', arg: 'commission', label: 'العمولات', perm: ['finance', 'finance_manager'] },
            { view: 'settlement', label: 'إغلاق اليومية' }
        ] },
        { icon: 'fa-chart-simple', label: 'التقارير الذكية', submenu: [
            { view: 'reports-dashboard', label: 'لوحة القيادة' },
            { view: 'reports-detailed', label: 'التقارير التفصيلية' },
            { view: 'reports-comprehensive', label: 'التقارير الشاملة' }
        ] },
        { view: 'hr', icon: 'fa-id-card', label: 'الموارد البشرية', perm: 'hr' },
        { view: 'crm', icon: 'fa-handshake', label: 'إدارة علاقات العملاء (CRM)', perm: 'customers' },
        { view: 'users', icon: 'fa-users-gear', label: 'المستخدمين والصلاحيات' },
        { view: 'roles', icon: 'fa-user-shield', label: 'إدارة أدوار المستخدمين' },
        { view: 'license', icon: 'fa-shield-haltered', label: 'إدارة الترخيص', perm: 'owner' },
        { view: 'settings', icon: 'fa-gear', label: 'إعدادات النظام' },
        { action: 'logout', icon: 'fa-right-from-bracket', label: 'تسجيل الخروج' }
    ],

    _storage: {
        collapsed: 'rw_sidebar_collapsed',
        groups: 'rw_nav_expanded_v2',
        favorites: 'rw_nav_favorites_v2',
        recent: 'rw_nav_recent_v2'
    },

    _state: {
        search: '',
        tree: [],
        leaves: [],
        openGroups: [],
        favorites: [],
        recent: []
    },

    _escape(value) {
        var s = value == null ? '' : String(value);
        return s
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    },

    _safeParse(value, fallback) {
        try {
            var parsed = JSON.parse(value);
            return parsed == null ? fallback : parsed;
        } catch (e) {
            return fallback;
        }
    },

    _loadState() {
        try {
            this._state.openGroups = this._safeParse(localStorage.getItem(this._storage.groups), []);
            this._state.favorites = this._safeParse(localStorage.getItem(this._storage.favorites), []);
            this._state.recent = this._safeParse(localStorage.getItem(this._storage.recent), []);
        } catch (e) {
            this._state.openGroups = [];
            this._state.favorites = [];
            this._state.recent = [];
        }

        if (!Array.isArray(this._state.openGroups)) this._state.openGroups = [];
        if (!Array.isArray(this._state.favorites)) this._state.favorites = [];
        if (!Array.isArray(this._state.recent)) this._state.recent = [];
    },

    _persist(key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
        } catch (e) {}
    },

    _hasPermission(item) {
        var user = RW_STATE && RW_STATE.app ? RW_STATE.app.currentUser : null;
        if (item.perm === 'owner') {
            return !!(user && user.isOwner === true);
        }

        if (Array.isArray(item.perm)) {
            for (var i = 0; i < item.perm.length; i++) {
                if (RW_Permissions_check(item.perm[i])) return true;
            }
            return false;
        }

        if (item.perm) {
            return RW_Permissions_check(item.perm);
        }

        if (item.view) {
            return RW_Permissions_check(item.view);
        }

        return true;
    },

    _key(item) {
        if (item.action) return 'action:' + item.action + ':' + String(item.arg || '');
        if (item.view) return 'view:' + String(item.view);
        return 'group:' + String(item.label || '');
    },

    _iconFor(item) {
        if (item.icon) return item.icon;

        var viewIcons = {
            dashboard: 'fa-chart-pie',
            telesales: 'fa-headset',
            customers: 'fa-users',
            'online-store': 'fa-globe',
            pos: 'fa-cash-register',
            orders: 'fa-file-invoice',
            quotes: 'fa-file-circle-question',
            'price-lists': 'fa-tags',
            promotions: 'fa-percent',
            'sales-decision-center': 'fa-bullseye',
            'sales-targets': 'fa-chart-line',
            loyalty: 'fa-gift',
            runsheets: 'fa-route',
            'sales-returns': 'fa-rotate-left',
            suppliers: 'fa-truck-field',
            'purchase-pos': 'fa-cart-shopping',
            purchases: 'fa-file-invoice-dollar',
            items: 'fa-box-open',
            branches: 'fa-warehouse',
            'inventory-control': 'fa-boxes-stacked',
            receiving: 'fa-inbox',
            picking: 'fa-list-check',
            loading: 'fa-truck-ramp-box',
            delivery: 'fa-truck-fast',
            return: 'fa-arrow-rotate-left',
            unloading: 'fa-dolly',
            transfer: 'fa-right-left',
            'direct-sale': 'fa-arrow-right-from-bracket',
            'direct-return': 'fa-arrow-right-to-bracket',
            'supplier-return': 'fa-reply',
            vouchers: 'fa-file-signature',
            'vehicle-count': 'fa-truck-front',
            'branch-count': 'fa-warehouse',
            'general-count': 'fa-clipboard-check',
            settlement: 'fa-cash-register',
            hr: 'fa-id-card',
            crm: 'fa-handshake',
            users: 'fa-users-gear',
            roles: 'fa-user-shield',
            license: 'fa-shield-halved',
            settings: 'fa-gear'
        };

        if (item.action === 'logout') return 'fa-right-from-bracket';
        if (item.action === 'showFinanceTab') {
            var financeIcons = {
                treasury: 'fa-vault',
                accounts: 'fa-book',
                'journal-list': 'fa-list',
                journal: 'fa-pen-to-square',
                'recurring-journals': 'fa-arrows-rotate',
                receipts: 'fa-circle-arrow-down',
                payments: 'fa-circle-arrow-up',
                expenses: 'fa-receipt',
                transfers: 'fa-money-bill-transfer',
                cheques: 'fa-money-check',
                'bank-reconcile': 'fa-building-columns',
                tax: 'fa-percent',
                assets: 'fa-landmark',
                budgets: 'fa-chart-column',
                periods: 'fa-calendar-days',
                reports: 'fa-chart-pie',
                installments: 'fa-file-invoice',
                commission: 'fa-coins'
            };
            return financeIcons[item.arg] || 'fa-coins';
        }

        return viewIcons[item.view] || 'fa-circle';
    },

    _filterTree(items) {
        var result = [];

        for (var i = 0; i < items.length; i++) {
            var item = items[i];

            if (item.submenu) {
                var children = this._filterTree(item.submenu);
                if (!children.length) continue;

                var group = {
                    label: item.label,
                    icon: item.icon || 'fa-folder-tree',
                    submenu: children,
                    _key: this._key(item)
                };

                result.push(group);
                continue;
            }

            if (this._hasPermission(item)) {
                result.push(item);
            }
        }

        return result;
    },

    _collectLeaves(items, out) {
        out = out || [];

        for (var i = 0; i < items.length; i++) {
            var item = items[i];

            if (item.submenu) {
                this._collectLeaves(item.submenu, out);
            } else {
                out.push(item);
            }
        }

        return out;
    },

    _resolveKey(key) {
        for (var i = 0; i < this._state.leaves.length; i++) {
            var item = this._state.leaves[i];
            if (this._key(item) === key) return item;
        }
        return null;
    },

    _isOpen(key) {
        return this._state.openGroups.indexOf(key) !== -1;
    },

    _toggleGroup(key) {
        var index = this._state.openGroups.indexOf(key);

        if (index === -1) {
            this._state.openGroups.push(key);
        } else {
            this._state.openGroups.splice(index, 1);
        }

        this._persist(this._storage.groups, this._state.openGroups);
        this._renderNav();
    },

    _ensureActiveParents(view) {
        var path = [];

        function walk(items, target, chain) {
            for (var i = 0; i < items.length; i++) {
                var item = items[i];

                if (item.submenu) {
                    var next = chain.concat([item._key || 'group:' + item.label]);

                    if (walk(item.submenu, target, next)) {
                        for (var j = 0; j < next.length; j++) {
                            if (path.indexOf(next[j]) === -1) path.push(next[j]);
                        }
                        return true;
                    }
                } else if (item.view === target) {
                    return true;
                }
            }

            return false;
        }

        if (walk(this._state.tree, view, [])) {
            for (var i = 0; i < path.length; i++) {
                if (this._state.openGroups.indexOf(path[i]) === -1) {
                    this._state.openGroups.push(path[i]);
                }
            }
            this._persist(this._storage.groups, this._state.openGroups);
        }
    },

    _favorite(item) {
        var key = this._key(item);
        var index = this._state.favorites.indexOf(key);

        if (index === -1) {
            this._state.favorites.unshift(key);
        } else {
            this._state.favorites.splice(index, 1);
        }

        this._persist(this._storage.favorites, this._state.favorites);
        this._renderNav();
    },

    _recent(item) {
        var key = this._key(item);
        this._state.recent = this._state.recent.filter(function(x) {
            return x !== key;
        });
        this._state.recent.unshift(key);

        if (this._state.recent.length > 6) {
            this._state.recent.length = 6;
        }

        this._persist(this._storage.recent, this._state.recent);
    },

    _ensureStyles() {
        if (document.getElementById('rw-navigation-modern-style')) return;

        var style = document.createElement('style');
        style.id = 'rw-navigation-modern-style';
        style.textContent = [
            '.rw-nav-search-wrap{display:flex;gap:8px;align-items:center;padding:10px 8px 12px}',
            '.rw-nav-search{flex:1;position:relative}',
            '.rw-nav-search-input{width:100%;height:46px;border:1px solid #e2e8f0;background:#f8fafc;border-radius:14px;padding:0 42px 0 12px;font-size:13px;font-weight:700;outline:none;transition:.2s}',
            '.rw-nav-search-input:focus{background:#fff;border-color:#93c5fd;box-shadow:0 0 0 4px rgba(37,99,235,.08)}',
            '.rw-nav-search-icon{position:absolute;right:14px;top:50%;transform:translateY(-50%);color:#94a3b8;font-size:14px}',
            '.rw-nav-search-trigger{display:none;width:46px;height:46px;border:1px solid #e2e8f0;border-radius:14px;background:#f8fafc;color:#64748b;align-items:center;justify-content:center;cursor:pointer}',
            '.rw-nav-section{margin:2px 6px 12px}',
            '.rw-nav-section-title{display:flex;align-items:center;justify-content:space-between;padding:6px 8px;color:#94a3b8;font-size:10px;font-weight:900;letter-spacing:.04em}',
            '.rw-nav-quick{display:flex;flex-direction:column;gap:3px}',
            '.rw-nav-group{margin-bottom:4px}',
            '.rw-nav-group-toggle{width:100%;border:0;background:transparent;display:flex;align-items:center;justify-content:space-between;gap:8px;height:52px;padding:0 12px;border-radius:16px;color:#475569;cursor:pointer;font-weight:800;transition:.2s}',
            '.rw-nav-group-toggle:hover{background:#f8fafc;color:#0f172a}',
            '.rw-nav-group-toggle[aria-expanded="true"]{background:#f8fbff;color:#1d4ed8}',
            '.rw-nav-group-leading{display:flex;align-items:center;gap:12px;min-width:0}',
            '.rw-nav-group-chevron{font-size:11px;color:#94a3b8;transition:transform .2s}',
            '.rw-nav-group-toggle[aria-expanded="true"] .rw-nav-group-chevron{transform:rotate(180deg);color:#2563eb}',
            '.rw-nav-group-children{padding:2px 0 4px 0}',
            '.rw-nav-group-children.rw-nav-collapsed{display:none}',
            '.rw-sidebar-link.rw-nav-leaf{position:relative;padding:0 12px 0 10px;height:48px;margin-bottom:3px;border:0}',
            '.rw-sidebar-link.rw-nav-leaf .rw-sidebar-link-text{overflow:hidden;text-overflow:ellipsis}',
            '.rw-nav-leaf-icon{width:34px;height:34px;min-width:34px;border-radius:11px;display:flex;align-items:center;justify-content:center;background:#f1f5f9;color:#64748b;font-size:14px}',
            '.rw-sidebar-link.active .rw-nav-leaf-icon{background:#2563eb;color:#fff}',
            '.rw-nav-leaf-main{display:flex;align-items:center;gap:12px;min-width:0;flex:1}',
            '.rw-nav-favorite-toggle{border:0;background:transparent;color:#cbd5e1;width:28px;height:28px;border-radius:8px;cursor:pointer;display:flex;align-items:center;justify-content:center;flex:0 0 auto}',
            '.rw-nav-favorite-toggle:hover{background:#f1f5f9;color:#64748b}',
            '.rw-nav-favorite-toggle.is-favorite{color:#f59e0b}',
            '.rw-sidebar.collapsed .rw-nav-search-wrap{justify-content:center;padding:10px 6px}',
            '.rw-sidebar.collapsed .rw-nav-search{display:none}',
            '.rw-sidebar.collapsed .rw-nav-search-trigger{display:flex}',
            '.rw-sidebar.collapsed .rw-nav-section-title{display:none}',
            '.rw-sidebar.collapsed .rw-nav-leaf{justify-content:center;padding:0;gap:0}',
            '.rw-sidebar.collapsed .rw-nav-leaf-main{justify-content:center;gap:0}',
            '.rw-sidebar.collapsed .rw-nav-leaf .rw-nav-favorite-toggle{display:none}',
            '.rw-sidebar.collapsed .rw-nav-text{display:none}',
            '.rw-sidebar.collapsed .rw-nav-group-toggle{justify-content:center;padding:0;gap:0}',
            '.rw-sidebar.collapsed .rw-nav-group-leading{justify-content:center;gap:0;width:100%}',
            '.rw-sidebar.collapsed .rw-nav-group-chevron{display:none}',
            '.rw-sidebar.collapsed .rw-nav-group-children{display:none}',
            '.rw-nav-empty{padding:18px 10px;text-align:center;color:#94a3b8;font-size:12px;font-weight:800}',
            '.rw-nav-tooltip{position:fixed;display:none;z-index:3000;padding:9px 12px;border-radius:10px;background:#0f172a;color:#fff;font-size:12px;font-weight:800;box-shadow:0 10px 30px rgba(15,23,42,.25);white-space:nowrap;pointer-events:none}',
            '@media(max-width:992px){.rw-sidebar,.rw-sidebar.collapsed{width:280px!important;min-width:280px!important}.rw-sidebar.collapsed .rw-nav-search{display:block}.rw-sidebar.collapsed .rw-nav-search-trigger{display:none}.rw-sidebar.collapsed .rw-nav-section-title{display:flex}.rw-sidebar.collapsed .rw-nav-text{display:block}.rw-sidebar.collapsed .rw-nav-leaf{justify-content:flex-start;padding:0 12px 0 10px;gap:12px}.rw-sidebar.collapsed .rw-nav-leaf-main{justify-content:flex-start;gap:12px}.rw-sidebar.collapsed .rw-nav-favorite-toggle{display:flex}.rw-sidebar.collapsed .rw-nav-group-toggle{justify-content:space-between;padding:0 12px}.rw-sidebar.collapsed .rw-nav-group-leading{justify-content:flex-start;gap:12px}.rw-sidebar.collapsed .rw-nav-group-chevron{display:block}}'
        ].join('');
        document.head.appendChild(style);
    },

    _tooltip() {
        var el = document.getElementById('rw-nav-tooltip');

        if (!el) {
            el = document.createElement('div');
            el.id = 'rw-nav-tooltip';
            el.className = 'rw-nav-tooltip';
            document.body.appendChild(el);
        }

        return el;
    },

    _showTooltip(target, text) {
        if (!byId('rw-sidebar') || !byId('rw-sidebar').classList.contains('collapsed')) return;

        var tip = this._tooltip();
        if (!tip) return;

        tip.textContent = text || '';
        tip.style.display = 'block';

        var r = target.getBoundingClientRect();
        var left = Math.max(8, r.left - tip.offsetWidth - 10);
        var top = Math.max(8, r.top + (r.height - tip.offsetHeight) / 2);

        tip.style.left = left + 'px';
        tip.style.top = top + 'px';
    },

    _hideTooltip() {
        var tip = document.getElementById('rw-nav-tooltip');
        if (tip) tip.style.display = 'none';
    },

    _renderLeaf(item) {
        var key = this._key(item);
        var isFavorite = this._state.favorites.indexOf(key) !== -1;
        var isActive = item.view && RW_STATE.app.currentView === item.view;
        var icon = this._iconFor(item);
        var attrs = [
            'type="button"',
            'class="rw-sidebar-link rw-nav-leaf' + (isActive ? ' active' : '') + '"',
            'data-nav-key="' + this._escape(key) + '"',
            'data-nav-label="' + this._escape(item.label || '') + '"',
            'title="' + this._escape(item.label || '') + '"'
        ];

        if (item.view) attrs.push('data-view="' + this._escape(item.view) + '"');
        if (item.action) attrs.push('data-action="' + this._escape(item.action) + '"');
        if (item.arg) attrs.push('data-arg="' + this._escape(item.arg) + '"');

        return '<button ' + attrs.join(' ') + '>' +
            '<span class="rw-nav-leaf-main">' +
                '<span class="rw-nav-leaf-icon"><i class="fa-solid ' + this._escape(icon) + '"></i></span>' +
                '<span class="rw-sidebar-link-text rw-nav-text">' + this._escape(item.label || '') + '</span>' +
            '</span>' +
            '<span class="rw-nav-favorite-toggle' + (isFavorite ? ' is-favorite' : '') + '" ' +
                'data-nav-favorite="' + this._escape(key) + '" ' +
                'role="button" tabindex="0" aria-label="' + (isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة') + '">' +
                '<i class="fa-' + (isFavorite ? 'solid' : 'regular') + ' fa-star"></i>' +
            '</span>' +
        '</button>';
    },

    _renderGroup(item) {
        var key = item._key || this._key(item);
        var open = this._isOpen(key);
        var children = '';

        for (var i = 0; i < item.submenu.length; i++) {
            var child = item.submenu[i];
            children += child.submenu ? this._renderGroup(child) : this._renderLeaf(child);
        }

        return '<div class="rw-nav-group" data-nav-group-wrap="' + this._escape(key) + '">' +
            '<button type="button" class="rw-nav-group-toggle" data-nav-group="' + this._escape(key) + '" aria-expanded="' + (open ? 'true' : 'false') + '" title="' + this._escape(item.label || '') + '">' +
                '<span class="rw-nav-group-leading">' +
                    '<span class="rw-nav-leaf-icon"><i class="fa-solid ' + this._escape(item.icon || 'fa-folder-tree') + '"></i></span>' +
                    '<span class="rw-sidebar-link-text rw-nav-text">' + this._escape(item.label || '') + '</span>' +
                '</span>' +
                '<i class="fa-solid fa-chevron-down rw-nav-group-chevron"></i>' +
            '</button>' +
            '<div class="rw-nav-group-children' + (open ? '' : ' rw-nav-collapsed') + '">' +
                children +
            '</div>' +
        '</div>';
    },

    _renderQuickSection(title, keys) {
        var html = '';
        var count = 0;

        for (var i = 0; i < keys.length; i++) {
            var item = this._resolveKey(keys[i]);
            if (!item) continue;

            html += this._renderLeaf(item);
            count++;
        }

        if (!count) return '';

        return '<div class="rw-nav-section">' +
            '<div class="rw-nav-section-title"><span>' + this._escape(title) + '</span></div>' +
            '<div class="rw-nav-quick">' + html + '</div>' +
        '</div>';
    },

    _renderSearchResults() {
        var q = String(this._state.search || '').trim().toLowerCase();

        if (!q) return '';

        var rows = [];

        for (var i = 0; i < this._state.leaves.length; i++) {
            var item = this._state.leaves[i];
            var hay = [item.label || '', item.view || '', item.arg || ''].join(' ').toLowerCase();

            if (hay.indexOf(q) !== -1) rows.push(item);
        }

        var html = '<div class="rw-nav-section">' +
            '<div class="rw-nav-section-title"><span>نتائج البحث</span><span>' + rows.length.toLocaleString('ar-EG') + '</span></div>';

        if (!rows.length) {
            html += '<div class="rw-nav-empty">لا توجد نتائج مطابقة</div></div>';
            return html;
        }

        html += '<div class="rw-nav-quick">';
        for (var j = 0; j < rows.length; j++) html += this._renderLeaf(rows[j]);
        html += '</div></div>';

        return html;
    },

    _renderNav() {
        var nav = byId('rw-sidebar-nav');
        if (!nav) return;

        this._ensureStyles();

        this._state.tree = this._filterTree(this.menuTree);
        this._state.leaves = this._collectLeaves(this._state.tree, []);

        var html =
            '<div class="rw-nav-search-wrap">' +
                '<div class="rw-nav-search">' +
                    '<i class="fa-solid fa-magnifying-glass rw-nav-search-icon"></i>' +
                    '<input id="rw-nav-search-input" class="rw-nav-search-input" type="search" autocomplete="off" value="' + this._escape(this._state.search) + '" placeholder="ابحث داخل القائمة..." aria-label="البحث في القائمة">' +
                '</div>' +
                '<button type="button" class="rw-nav-search-trigger" data-nav-search-trigger title="بحث">' +
                    '<i class="fa-solid fa-magnifying-glass"></i>' +
                '</button>' +
            '</div>';

        var searchHtml = this._renderSearchResults();

        if (searchHtml) {
            html += searchHtml;
        } else {
            html += this._renderQuickSection('المفضلة', this._state.favorites);
            html += this._renderQuickSection('الأحدث', this._state.recent);
            html += '<div class="rw-nav-section">' +
                '<div class="rw-nav-section-title"><span>الوحدات</span><span>' + this._state.leaves.length.toLocaleString('ar-EG') + '</span></div>';

            for (var i = 0; i < this._state.tree.length; i++) {
                var item = this._state.tree[i];
                html += item.submenu ? this._renderGroup(item) : this._renderLeaf(item);
            }

            html += '</div>';
        }

        safeHTML(nav, html);
    },

    _handleItem(item) {
        if (!item) return;

        this._recent(item);

        if (item.action) {
            this._handleAction(item.action, item.arg || '');
            return;
        }

        if (item.view) this.navigate(item.view);
    },

    _handleAction(action, arg) {
        if (action === 'showFinanceTab') {
            RW_STATE.app.currentView = 'finance';

            if (typeof RW_Finance !== 'undefined' && typeof RW_Finance.renderSubTab === 'function') {
                RW_Finance.renderSubTab(arg || 'treasury');
                safeText(byId('rw-header-title'), 'الحسابات والمالية');
            } else {
                RW_Views.render('finance');
            }

            this._hideTooltip();
            this._renderNav();
            return;
        }

        if (action === 'logout') {
            this._hideTooltip();
            RW_Auth.logout();
            return;
        }

        if (typeof RW_Views !== 'undefined' && RW_Views.render) {
            RW_Views.render(action);
        }
    },

    _bindEvents() {
        var nav = byId('rw-sidebar-nav');
        if (!nav || nav.getAttribute('data-rw-nav-bound') === '1') return;

        nav.setAttribute('data-rw-nav-bound', '1');

        nav.addEventListener('click', function(e) {
            var favorite = e.target.closest('[data-nav-favorite]');
            if (favorite) {
                e.preventDefault();
                e.stopPropagation();

                var key = favorite.getAttribute('data-nav-favorite');
                var item = RW_Navigation._resolveKey(key);
                if (item) RW_Navigation._favorite(item);
                return;
            }

            var searchTrigger = e.target.closest('[data-nav-search-trigger]');
            if (searchTrigger) {
                e.preventDefault();
                RW_Navigation.toggleSidebar(false);
                setTimeout(function() {
                    var input = byId('rw-nav-search-input');
                    if (input) input.focus();
                }, 50);
                return;
            }

            var group = e.target.closest('[data-nav-group]');
            if (group) {
                e.preventDefault();
                var key = group.getAttribute('data-nav-group');

                if (byId('rw-sidebar').classList.contains('collapsed')) {
                    RW_Navigation.toggleSidebar(false);
                    setTimeout(function() { RW_Navigation._toggleGroup(key); }, 20);
                } else {
                    RW_Navigation._toggleGroup(key);
                }
                return;
            }

            var leaf = e.target.closest('.rw-nav-leaf');
            if (leaf) {
                e.preventDefault();
                var key = leaf.getAttribute('data-nav-key');
                var item = RW_Navigation._resolveKey(key);
                if (item) RW_Navigation._handleItem(item);
            }
        });

        nav.addEventListener('mouseover', function(e) {
            var leaf = e.target.closest('.rw-nav-leaf');
            if (!leaf || !byId('rw-sidebar').classList.contains('collapsed')) return;
            RW_Navigation._showTooltip(leaf, leaf.getAttribute('data-nav-label') || '');
        });

        nav.addEventListener('mouseout', function(e) {
            var from = e.target.closest('.rw-nav-leaf');
            var to = e.relatedTarget && e.relatedTarget.closest ? e.relatedTarget.closest('.rw-nav-leaf') : null;
            if (from && from !== to) RW_Navigation._hideTooltip();
        });

        nav.addEventListener('focusin', function(e) {
            var leaf = e.target.closest('.rw-nav-leaf');
            if (leaf && byId('rw-sidebar').classList.contains('collapsed')) {
                RW_Navigation._showTooltip(leaf, leaf.getAttribute('data-nav-label') || '');
            }
        });

        nav.addEventListener('focusout', function(e) {
            if (e.target.closest && e.target.closest('.rw-nav-leaf')) RW_Navigation._hideTooltip();
        });

        document.addEventListener('click', function(e) {
            if (!e.target.closest('#rw-sidebar')) RW_Navigation._hideTooltip();
        });
    },

    _applyCollapsedState(collapsed) {
        var sidebar = byId('rw-sidebar');
        var main = byId('rw-main-content');
        var btn = byId('rw-collapse-btn');

        if (!sidebar || !main) return;

        var isCollapsed = !!collapsed;

        sidebar.classList.toggle('collapsed', isCollapsed);
        main.classList.toggle('expanded', isCollapsed);
        RW_STATE.ui.sidebarCollapsed = isCollapsed;

        if (btn) {
            btn.setAttribute('aria-expanded', isCollapsed ? 'false' : 'true');
            btn.setAttribute('aria-label', isCollapsed ? 'توسيع القائمة الجانبية' : 'طي القائمة الجانبية');
            btn.title = isCollapsed ? 'توسيع القائمة' : 'طي القائمة';
            btn.innerHTML = '<i class="fa-solid ' + (isCollapsed ? 'fa-angles-left' : 'fa-angles-right') + '"></i>';
        }

        try {
            localStorage.setItem(this._storage.collapsed, isCollapsed ? '1' : '0');
        } catch (e) {}

        this._hideTooltip();
    },

    toggleSidebar(forceCollapsed) {
        var sidebar = byId('rw-sidebar');
        if (!sidebar) return;

        if (window.innerWidth <= 992) {
            var mobileOpen = !sidebar.classList.contains('active');
            sidebar.classList.toggle('active', mobileOpen);
            RW_STATE.ui.sidebarOpen = mobileOpen;
            return;
        }

        var current = sidebar.classList.contains('collapsed');
        var next = typeof forceCollapsed === 'boolean' ? forceCollapsed : !current;

        this._applyCollapsedState(next);
        this._renderNav();
    },

    navigate(view) {
        try {
            RW_STATE.app.currentView = view;

            this._ensureActiveParents(view);
            this._hideTooltip();

            var sidebar = byId('rw-sidebar');
            if (sidebar && window.innerWidth <= 992) {
                sidebar.classList.remove('active');
                RW_STATE.ui.sidebarOpen = false;
            }

            var item = this._resolveKey('view:' + view);
            if (item) this._recent(item);

            var links = document.querySelectorAll('.rw-sidebar-link[data-view]');
            for (var i = 0; i < links.length; i++) {
                links[i].classList.toggle('active', links[i].getAttribute('data-view') === view);
            }

            window.RW_Views.render(view);
            this._renderNav();
        } catch (e) {
            console.error('RW_Navigation.navigate', e);
            showToast('حدث خطأ أثناء فتح التبويب', 'error');
        }
    },

    buildSidebar() {
        try {
            this._ensureStyles();
            this._loadState();

            var nav = byId('rw-sidebar-nav');
            if (!nav) return;

            var existingAudit = false;
            for (var i = 0; i < this.menuTree.length; i++) {
                if (this.menuTree[i].view === 'audit-log') {
                    existingAudit = true;
                    break;
                }
            }

            if (!existingAudit) {
                this.menuTree.push({
                    view: 'audit-log',
                    icon: 'fa-clock-rotate-left',
                    label: 'سجل التدقيق',
                    perm: 'owner'
                });
            }

            var collapsed = false;
            try {
                collapsed = localStorage.getItem(this._storage.collapsed) === '1';
            } catch (e) {}

            this._applyCollapsedState(collapsed);
            this._state.search = '';
            this._renderNav();
            this._bindEvents();

            var currentView = RW_STATE.app.currentView || 'dashboard';
            this._ensureActiveParents(currentView);
            this._renderNav();
        } catch (e) {
            console.error('RW_Navigation.buildSidebar', e);
        }
    }
};

window.RW_Navigation = RW_Navigation;

~~~~

## وظيفة الإصلاح

البديل يضيف دون تغيير Business Navigation الحالي:

1. persistence حقيقية لـCollapse State.
2. persisted expanded groups.
3. Favorites.
4. Recent.
5. Search داخل navigation.
6. icons حقيقية لكل leaf.
7. collapsed mode usable.
8. tooltips في collapsed mode.
9. الضغط على group أثناء collapse يوسع القائمة ثم يفتح المجموعة.
10. keyboard/focus semantics أساسية.
11. aria-expanded للـgroups.
12. mobile behavior منفصل عن desktop collapse.
13. permission filtering محفوظ كما هو.
14. OWNER audit-log semantics محفوظة.
15. Finance actions الحالية محفوظة.
16. logout الحالي محفوظ.
17. جميع view IDs الحالية محفوظة.
18. لا تغيير في operational apps.

### لا تغير

- menuTree business semantics.
- permission keys.
- OWNER wildcard contract.
- RW_Views.
- module renderers.
- field operations.
- inventory workflow.

---

# 8. Static Validation للـSidebar Patch

تم اختبار replacement object في parser JavaScript مستقل.

النتيجة:

SIDEBAR PATCH SYNTAX = PASS

لم يتم تشغيله داخل Production Browser لأن main.html لم يغيره CTO في هذه الجلسة.

Browser E2E للـsidebar يبقى Owner Cutover Gate.

---

# 9. التحقيق الجنائي — RW_Reports_Comprehensive

## الوضع الحالي المثبت

RW_Reports_Comprehensive:
- 38 report IDs
- Current inline module موجود داخل main.html
- V8 syntax parse = PASS
- router الحالي:
  reports-comprehensive → RW_Reports_Comprehensive.render()

هذه الطبقة ليست مجرد شاشة؛ هي façade فوق Production reporting contracts.

التدفق الصحيح:

Mother Reports UI
↓
report definition
↓
criteria
↓
RPC / read contract
↓
Production
↓
result
↓
CSV / Print / Drill-Down

ولا تعيد التقارير تنفيذ:
Order
Runsheet
Picking
Loading
Delivery
Return
Settlement

---

# 10. Production Contract — التقارير

الإصلاح الأمني السابق الذي تم في Production closed هذه الحدود:

JWT
↓
authenticated actor
↓
company context
↓
reports permission
↓
validated user identity
↓
report RPC

لذلك لم يتم اختراع schema جديدة لتبويب التقارير.

---

# 11. الفجوات الفعلية في Source

الفجوة الحالية المثبتة ليست في Production reporting engine.

هي في Mother UI:

### Gap 01 — Modal Drill-Down

الوظائف الحالية:

async function _showCustomerLedgerDetail(customerId, customerName)

async function _showItemMovementDetail(itemCode, itemName)

async function _showRunsheetDetail(runsheetCode)

async function _showSettlementDetail(settlementCode)

كانت تعرض التفاصيل داخل Swal.fire.

### Gap 02 — Hover class defect

داخل:

function _openSection(sectionKey)

الكود الحالي يبني:

hover:bg- + section.bgColor

بينما section.bgColor يحتوي أصلًا على bg-.

الناتج الحالي:

hover:bg-bg-...

وهذا defect شكلي مثبت من source الحالي.

---

# 12. OWNER SURGICAL PATCH 01 — Modal → Page

المرجع الحاكم الكامل لهذا البلوك هو:

doc/Draft/Reprots/Report254_COMPREHENSIVE_REPORTS_CURRENT_FORENSIC_SURGICAL_EXECUTION_20260919.md

والبلوك الكامل المعتمد أدناه هو نفس PATCH 01 كما هو، دون إعادة تصميم أو تغيير Business Contract:

## 12. OWNER SURGICAL PATCH 01 — Modal → Page

ابحث داخل main.html عن:

// ==================== دوال التفاصيل (Drill-Down) ====================

ثم ابحث عن:

async function _showCustomerLedgerDetail(customerId, customerName) {

واحذف البلوك الكامل الذي يبدأ بهذا السطر وينتهي عند آخر قوس في:

async function _showSettlementDetail(settlementCode) {

ولا تحذف:

// ==================== توليد التقرير (مع Drill-Down) ===

استبدل البلوك كاملًا بالنص التالي:

~~~~javascript

function _renderReportDrilldownPage(title, subtitle, bodyHtml) {
    var resultDiv = byId('report-result');

    if (!resultDiv) {
        return;
    }

    safeHTML(
        resultDiv,
        '<div class="bg-white rounded-2xl border shadow-sm overflow-hidden">' +
        '<div class="px-5 py-4 bg-gradient-to-l from-slate-900 via-indigo-900 to-indigo-700 text-white">' +
        '<div class="flex flex-wrap items-center justify-between gap-3">' +
        '<div>' +
        '<div class="text-xs font-bold text-white/70 mb-1">التقارير الشاملة / Drill-Down</div>' +
        '<h3 class="text-xl md:text-2xl font-black">' +
        _esc(title || 'تفاصيل التقرير') +
        '</h3>' +
        '<div class="text-xs md:text-sm text-white/75 mt-1">' +
        _esc(subtitle || '') +
        '</div>' +
        '</div>' +
        '<button id="rw-report-drilldown-back" type="button" ' +
        'class="px-4 py-2 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 font-black text-sm transition">' +
        '<i class="fa-solid fa-arrow-right ml-1"></i>' +
        'عودة إلى التقرير' +
        '</button>' +
        '</div>' +
        '</div>' +
        '<div class="p-5 md:p-6">' +
        bodyHtml +
        '</div>' +
        '<div class="px-5 py-3 border-t bg-gray-50 flex flex-wrap items-center justify-between gap-2 text-xs text-gray-500">' +
        '<span>المصدر: Production / Current Report Contract</span>' +
        '<span>عرض التفاصيل: ' +
        _esc(new Date().toLocaleString('ar-EG')) +
        '</span>' +
        '</div>' +
        '</div>'
    );

    var backButton = byId('rw-report-drilldown-back');

    if (backButton) {
        backButton.onclick = function () {
            _generateReport(_currentSection, _currentReport);
        };
    }
}

function _reportMetricCard(label, value, icon, toneClass) {
    return (
        '<div class="border rounded-2xl p-4 bg-white shadow-sm">' +
        '<div class="flex items-center justify-between gap-3">' +
        '<div>' +
        '<div class="text-xs font-bold text-gray-500">' +
        _esc(label) +
        '</div>' +
        '<div class="text-xl font-black mt-1">' +
        _esc(String(value == null ? '' : value)) +
        '</div>' +
        '</div>' +
        '<div class="w-11 h-11 rounded-xl flex items-center justify-center ' +
        _esc(toneClass || 'bg-gray-100 text-gray-600') +
        '">' +
        '<i class="fa-solid ' +
        _esc(icon || 'fa-chart-column') +
        '"></i>' +
        '</div>' +
        '</div>' +
        '</div>'
    );
}

async function _showCustomerLedgerDetail(customerId, customerName) {
    _showLoader('جاري تحميل كشف حساب العميل...');

    try {
        var companyId = _companyId();

        var customerRes = await supabase
            .from('customers')
            .select('id, customer_code, name')
            .eq('id', customerId)
            .eq('company_id', companyId)
            .maybeSingle();

        if (customerRes.error) {
            throw customerRes.error;
        }

        if (!customerRes.data) {
            throw new Error('العميل غير موجود ضمن الشركة الحالية');
        }

        var customer = customerRes.data;

        var ledgerRes = await supabase
            .from('customer_ledger')
            .select('id, entry_date, description, debit, credit, balance, reference, due_date, user_email, created_at')
            .eq('customer_id', customer.id)
            .order('entry_date', { ascending: false })
            .order('created_at', { ascending: false })
            .order('id', { ascending: false });

        if (ledgerRes.error) {
            throw ledgerRes.error;
        }

        var data = ledgerRes.data || [];
        var debitTotal = 0;
        var creditTotal = 0;

        for (var i = 0; i < data.length; i++) {
            debitTotal += Number(data[i].debit) || 0;
            creditTotal += Number(data[i].credit) || 0;
        }

        var currentBalance =
            data.length > 0
                ? Number(data[0].balance) || 0
                : 0;

        _hideLoader();

        var rows = '';

        for (var j = 0; j < data.length; j++) {
            rows +=
                '<tr class="border-t hover:bg-gray-50">' +
                '<td class="p-3 whitespace-nowrap">' + _esc(data[j].entry_date) + '</td>' +
                '<td class="p-3">' + _esc(data[j].description || '') + '</td>' +
                '<td class="p-3 text-center">' + _esc(data[j].reference || '') + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(data[j].debit) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(data[j].credit) + '</td>' +
                '<td class="p-3 text-center font-black">' + _fmtNum(data[j].balance) + '</td>' +
                '<td class="p-3 text-center text-xs text-gray-500">' + _esc(data[j].user_email || '') + '</td>' +
                '</tr>';
        }

        if (!rows) {
            rows =
                '<tr><td colspan="7" class="p-8 text-center text-gray-400">' +
                'لا توجد حركات لهذا العميل' +
                '</td></tr>';
        }

        var bodyHtml =
            '<div class="mb-5">' +
            '<div class="text-sm font-bold text-gray-500">العميل</div>' +
            '<div class="text-2xl font-black mt-1">' +
            _esc(customer.name || customerName || customer.customer_code) +
            '</div>' +
            '<div class="text-xs text-gray-500 mt-1">كود العميل: ' +
            _esc(customer.customer_code) +
            '</div>' +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mb-6">' +
            _reportMetricCard('عدد الحركات', _fmtNum(data.length), 'fa-list', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('إجمالي المدين', _fmtNum(debitTotal), 'fa-arrow-up', 'bg-red-50 text-red-700') +
            _reportMetricCard('إجمالي الدائن', _fmtNum(creditTotal), 'fa-arrow-down', 'bg-emerald-50 text-emerald-700') +
            _reportMetricCard('الرصيد الحالي', _fmtNum(currentBalance), 'fa-scale-balanced', 'bg-indigo-50 text-indigo-700') +
            '</div>' +

            '<div class="border rounded-2xl overflow-hidden">' +
            '<div class="px-4 py-3 bg-gray-50 border-b flex flex-wrap items-center justify-between gap-2">' +
            '<div class="font-black">الحركات المحاسبية</div>' +
            '<div class="text-xs text-gray-500">ترتيب تنازلي حسب التاريخ</div>' +
            '</div>' +
            '<div class="overflow-x-auto">' +
            '<table class="w-full min-w-[900px] text-sm">' +
            '<thead><tr class="bg-gray-100 text-gray-700">' +
            '<th class="p-3 text-right">التاريخ</th>' +
            '<th class="p-3 text-right">البيان</th>' +
            '<th class="p-3 text-center">المرجع</th>' +
            '<th class="p-3 text-center">مدين</th>' +
            '<th class="p-3 text-center">دائن</th>' +
            '<th class="p-3 text-center">الرصيد</th>' +
            '<th class="p-3 text-center">المستخدم</th>' +
            '</tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
            '</table></div></div>';

        _renderReportDrilldownPage(
            'كشف حساب العميل',
            customer.name || customerName || customer.customer_code,
            bodyHtml
        );

    } catch (e) {
        _hideLoader();
        _showToast('فشل تحميل كشف الحساب: ' + (e.message || ''), 'error');
    }
}

async function _showItemMovementDetail(itemCode, itemName) {
    _showLoader('جاري تحميل حركة الصنف...');

    try {
        var companyId = _companyId();

        var itemRes = await supabase
            .from('items')
            .select('id, item_code, name, unit')
            .eq('item_code', itemCode)
            .eq('company_id', companyId)
            .maybeSingle();

        if (itemRes.error) {
            throw itemRes.error;
        }

        if (!itemRes.data) {
            throw new Error('الصنف غير موجود ضمن الشركة الحالية');
        }

        var item = itemRes.data;
        var fromInput = byId('rp-date-from');
        var toInput = byId('rp-date-to');

        var fromDate =
            fromInput && fromInput.value
                ? fromInput.value
                : null;

        var toDate =
            toInput && toInput.value
                ? toInput.value
                : null;

        var currentUserEmail =
            RW_STATE &&
            RW_STATE.app &&
            RW_STATE.app.currentUser
                ? RW_STATE.app.currentUser.email
                : null;

        var movementResult =
            await supabase.rpc(
                'inventory_movement_report',
                {
                    p_company_id: companyId,
                    p_user_email: currentUserEmail,
                    p_from_date: fromDate,
                    p_to_date: toDate,
                    p_branch_id: null,
                    p_item_id: item.id,
                    p_movement_type: null,
                    p_query: null,
                    p_limit: 1000,
                    p_offset: 0
                }
            );

        if (movementResult.error) {
            throw movementResult.error;
        }

        var payload = movementResult.data || {};
        var data =
            Array.isArray(payload.rows)
                ? payload.rows
                : [];

        var stockRes = await supabase
            .from('stock_branches')
            .select('branch_id, qty, allocated_qty')
            .eq('item_id', item.id);

        if (stockRes.error) {
            throw stockRes.error;
        }

        var stockRows = stockRes.data || [];
        var currentQty = 0;
        var allocatedQty = 0;
        var netMovement = 0;

        for (var s = 0; s < stockRows.length; s++) {
            currentQty += Number(stockRows[s].qty) || 0;
            allocatedQty += Number(stockRows[s].allocated_qty) || 0;
        }

        for (var m = 0; m < data.length; m++) {
            netMovement += Number(data[m].effect_qty) || 0;
        }

        var availableQty =
            Math.max(currentQty - allocatedQty, 0);

        _hideLoader();

        var rows = '';

        for (var i = 0; i < data.length; i++) {
            rows +=
                '<tr class="border-t hover:bg-gray-50">' +
                '<td class="p-3 whitespace-nowrap">' + _esc(data[i].movement_date || '') + '</td>' +
                '<td class="p-3">' + _esc(data[i].branch_name || '') + '</td>' +
                '<td class="p-3">' + _esc(data[i].movement_type || '') + '</td>' +
                '<td class="p-3">' + _esc(data[i].reference || data[i].voucher_id || '') + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(data[i].before_qty) + '</td>' +
                '<td class="p-3 text-center font-bold">' + _fmtNum(data[i].effect_qty) + '</td>' +
                '<td class="p-3 text-center font-black">' + _fmtNum(data[i].after_qty) + '</td>' +
                '<td class="p-3 text-center text-xs text-gray-500">' + _esc(data[i].user_email || '') + '</td>' +
                '</tr>';
        }

        if (!rows) {
            rows =
                '<tr><td colspan="8" class="p-8 text-center text-gray-400">' +
                'لا توجد حركات ضمن نطاق التاريخ الحالي' +
                '</td></tr>';
        }

        var periodText =
            (fromDate || 'بداية السجل') +
            ' → ' +
            (toDate || 'اليوم');

        var bodyHtml =
            '<div class="mb-5">' +
            '<div class="text-sm font-bold text-gray-500">الصنف</div>' +
            '<div class="text-2xl font-black mt-1">' +
            _esc(item.name || itemName || item.item_code) +
            '</div>' +
            '<div class="text-xs text-gray-500 mt-1">الكود: ' +
            _esc(item.item_code) +
            ' | الوحدة: ' +
            _esc(item.unit || '') +
            '</div>' +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-3 mb-6">' +
            _reportMetricCard('الرصيد الحالي', _fmtNum(currentQty), 'fa-boxes-stacked', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('المحجوز', _fmtNum(allocatedQty), 'fa-lock', 'bg-amber-50 text-amber-700') +
            _reportMetricCard('المتاح', _fmtNum(availableQty), 'fa-box-open', 'bg-emerald-50 text-emerald-700') +
            _reportMetricCard('صافي الحركة', _fmtNum(netMovement), 'fa-arrow-right-arrow-left', 'bg-indigo-50 text-indigo-700') +
            _reportMetricCard('عدد الحركات', _fmtNum(data.length), 'fa-list', 'bg-purple-50 text-purple-700') +
            '</div>' +

            '<div class="mb-4 text-xs text-gray-500">' +
            'النطاق: ' + _esc(periodText) +
            ' | المصدر: Production inventory_movement_report' +
            '</div>' +

            '<div class="border rounded-2xl overflow-hidden">' +
            '<div class="px-4 py-3 bg-gray-50 border-b font-black">سجل الحركة التفصيلي</div>' +
            '<div class="overflow-x-auto">' +
            '<table class="w-full min-w-[1050px] text-sm">' +
            '<thead><tr class="bg-gray-100 text-gray-700">' +
            '<th class="p-3 text-right">التاريخ</th>' +
            '<th class="p-3 text-right">الفرع</th>' +
            '<th class="p-3 text-right">نوع الحركة</th>' +
            '<th class="p-3 text-right">المرجع</th>' +
            '<th class="p-3 text-center">قبل الحركة</th>' +
            '<th class="p-3 text-center">التأثير</th>' +
            '<th class="p-3 text-center">بعد الحركة</th>' +
            '<th class="p-3 text-center">المستخدم</th>' +
            '</tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
            '</table></div></div>';

        _renderReportDrilldownPage(
            'حركة الصنف',
            item.name || itemName || item.item_code,
            bodyHtml
        );

    } catch (e) {
        _hideLoader();
        _showToast('فشل تحميل حركة الصنف: ' + (e.message || ''), 'error');
    }
}

async function _showRunsheetDetail(runsheetCode) {
    _showLoader('جاري تحميل تفاصيل الرانشيت...');

    try {
        var companyId = _companyId();

        var rsRes = await supabase
            .from('runsheets')
            .select('id, runsheet_code, run_date, status, driver_id, vehicle_id, total_amount')
            .eq('company_id', companyId)
            .eq('runsheet_code', runsheetCode)
            .maybeSingle();

        if (rsRes.error) {
            throw rsRes.error;
        }

        if (!rsRes.data) {
            throw new Error('الرانشيت غير موجود ضمن الشركة الحالية');
        }

        var rs = rsRes.data;

        var [itemsRes, ordersRes] =
            await Promise.all([
                supabase
                    .from('run_sheet_details')
                    .select('*')
                    .eq('runsheet_id', rs.id),

                supabase
                    .from('orders')
                    .select('order_code, customer_name, total_amount')
                    .eq('company_id', companyId)
                    .eq('runsheet_id', rs.id)
                    .order('order_code', { ascending: true })
            ]);

        if (itemsRes.error) {
            throw itemsRes.error;
        }

        if (ordersRes.error) {
            throw ordersRes.error;
        }

        var items = itemsRes.data || [];
        var orders = ordersRes.data || [];

        var orderedTotal = 0;
        var pickedTotal = 0;
        var loadedTotal = 0;
        var deliveredTotal = 0;
        var refusedTotal = 0;
        var returnedTotal = 0;

        for (var i = 0; i < items.length; i++) {
            orderedTotal += Number(items[i].qty_ordered) || 0;
            pickedTotal += Number(items[i].qty_picked) || 0;
            loadedTotal += Number(items[i].qty_loaded) || 0;
            deliveredTotal += Number(items[i].qty_delivered) || 0;
            refusedTotal += Number(items[i].qty_refused) || 0;
            returnedTotal += Number(items[i].qty_returned) || 0;
        }

        _hideLoader();

        var orderPills = '';

        for (var o = 0; o < orders.length; o++) {
            orderPills +=
                '<div class="border rounded-xl px-3 py-2 bg-blue-50">' +
                '<div class="font-black text-blue-800">' +
                _esc(orders[o].order_code || '') +
                '</div>' +
                '<div class="text-xs text-blue-700 mt-1">' +
                _esc(orders[o].customer_name || '') +
                ' — ' +
                _fmtNum(orders[o].total_amount) +
                '</div>' +
                '</div>';
        }

        if (!orderPills) {
            orderPills =
                '<div class="text-sm text-gray-400">لا توجد طلبات مرتبطة حاليًا</div>';
        }

        var rows = '';

        for (var r = 0; r < items.length; r++) {
            rows +=
                '<tr class="border-t hover:bg-gray-50">' +
                '<td class="p-3 font-semibold">' + _esc(items[r].item_name || '') + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_ordered) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_picked) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_loaded) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_delivered) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_refused) + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(items[r].qty_returned) + '</td>' +
                '</tr>';
        }

        if (!rows) {
            rows =
                '<tr><td colspan="7" class="p-8 text-center text-gray-400">' +
                'لا توجد تفاصيل أصناف للرانشيت' +
                '</td></tr>';
        }

        var bodyHtml =
            '<div class="mb-5">' +
            '<div class="text-sm font-bold text-gray-500">رانشيت ميداني</div>' +
            '<div class="text-2xl font-black mt-1">' +
            _esc(rs.runsheet_code) +
            '</div>' +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mb-6">' +
            _reportMetricCard('التاريخ', rs.run_date || '', 'fa-calendar-day', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('الحالة', rs.status || '', 'fa-route', 'bg-indigo-50 text-indigo-700') +
            _reportMetricCard('السائق', rs.driver_id || 'غير محدد', 'fa-user', 'bg-emerald-50 text-emerald-700') +
            _reportMetricCard('السيارة', rs.vehicle_id || 'غير محددة', 'fa-truck', 'bg-amber-50 text-amber-700') +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-6 gap-3 mb-6">' +
            _reportMetricCard('Ordered', _fmtNum(orderedTotal), 'fa-list-check', 'bg-slate-50 text-slate-700') +
            _reportMetricCard('Picked', _fmtNum(pickedTotal), 'fa-box', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('Loaded', _fmtNum(loadedTotal), 'fa-truck-ramp-box', 'bg-indigo-50 text-indigo-700') +
            _reportMetricCard('Delivered', _fmtNum(deliveredTotal), 'fa-circle-check', 'bg-emerald-50 text-emerald-700') +
            _reportMetricCard('Refused', _fmtNum(refusedTotal), 'fa-circle-xmark', 'bg-red-50 text-red-700') +
            _reportMetricCard('Returned', _fmtNum(returnedTotal), 'fa-rotate-left', 'bg-amber-50 text-amber-700') +
            '</div>' +

            '<div class="mb-6">' +
            '<div class="font-black mb-3">الأوردرات المرتبطة</div>' +
            '<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">' +
            orderPills +
            '</div></div>' +

            '<div class="border rounded-2xl overflow-hidden">' +
            '<div class="px-4 py-3 bg-gray-50 border-b font-black">تفاصيل التنفيذ حسب الصنف</div>' +
            '<div class="overflow-x-auto">' +
            '<table class="w-full min-w-[1050px] text-sm">' +
            '<thead><tr class="bg-gray-100 text-gray-700">' +
            '<th class="p-3 text-right">الصنف</th>' +
            '<th class="p-3 text-center">Ordered</th>' +
            '<th class="p-3 text-center">Picked</th>' +
            '<th class="p-3 text-center">Loaded</th>' +
            '<th class="p-3 text-center">Delivered</th>' +
            '<th class="p-3 text-center">Refused</th>' +
            '<th class="p-3 text-center">Returned</th>' +
            '</tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
            '</table></div></div>';

        _renderReportDrilldownPage(
            'تفاصيل الرانشيت',
            rs.runsheet_code,
            bodyHtml
        );

    } catch (e) {
        _hideLoader();
        _showToast('فشل تحميل تفاصيل الرانشيت: ' + (e.message || ''), 'error');
    }
}

async function _showSettlementDetail(settlementCode) {
    _showLoader('جاري تحميل تفاصيل التسوية...');

    try {
        var companyId = _companyId();

        var settlementRes = await supabase
            .from('daily_settlements')
            .select('*')
            .eq('company_id', companyId)
            .eq('settlement_code', settlementCode)
            .maybeSingle();

        if (settlementRes.error) {
            throw settlementRes.error;
        }

        if (!settlementRes.data) {
            throw new Error('التسوية غير موجودة ضمن الشركة الحالية');
        }

        var data = settlementRes.data;
        var runsheetCode = '';

        if (data.runsheet_id) {
            var rsRes = await supabase
                .from('runsheets')
                .select('id, runsheet_code')
                .eq('company_id', companyId)
                .eq('id', data.runsheet_id)
                .maybeSingle();

            if (rsRes.error) {
                throw rsRes.error;
            }

            if (rsRes.data) {
                runsheetCode = rsRes.data.runsheet_code || '';
            }
        }

        _hideLoader();

        var bodyHtml =
            '<div class="mb-5">' +
            '<div class="text-sm font-bold text-gray-500">التسوية اليومية</div>' +
            '<div class="text-2xl font-black mt-1">' +
            _esc(data.settlement_code) +
            '</div>' +
            '</div>' +

            '<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mb-6">' +
            _reportMetricCard('التاريخ', data.settlement_date || '', 'fa-calendar-day', 'bg-blue-50 text-blue-700') +
            _reportMetricCard('الرانشيت', runsheetCode || data.runsheet_id || 'غير محدد', 'fa-route', 'bg-indigo-50 text-indigo-700') +
            _reportMetricCard('كمية العجز', _fmtNum(data.total_shortage), 'fa-box-open', 'bg-red-50 text-red-700') +
            _reportMetricCard('قيمة العجز', _fmtNum(data.total_shortage_value) + ' EGP', 'fa-money-bill-transfer', 'bg-amber-50 text-amber-700') +
            '</div>' +

            '<div class="border rounded-2xl p-5 bg-gray-50">' +
            '<div class="font-black mb-2">ملاحظات التسوية</div>' +
            '<div class="text-sm text-gray-700 whitespace-pre-wrap">' +
            _esc(data.notes || 'لا توجد ملاحظات') +
            '</div>' +
            '</div>';

        _renderReportDrilldownPage(
            'تفاصيل التسوية',
            data.settlement_code,
            bodyHtml
        );

    } catch (e) {
        _hideLoader();
        _showToast('فشل تحميل تفاصيل التسوية: ' + (e.message || ''), 'error');
    }
}

~~~~

## 13. PATCH 01 Rules
- لا تستخدم Swal.fire داخل وظائف التفاصيل.
- لا تغير أسماء الوظائف الأربع.
- لا تغير _generateReport.
- لا تغير report IDs.
- لا تغير operational apps.
- لا تغير order_details.
- لا تغير run_sheet_details.
- Item movement detail يجب أن يقرأ Production inventory_movement_report.
- Back يعيد التقرير الحالي.
- التقرير والـdrilldown يبقيان في نفس workspace.
- CSV/Print الحاليان سيعملان على الصفحة المعروضة لأن التفاصيل أصبحت داخل report-result.

## 14. OWNER SURGICAL PATCH 02 — Hover
ابحث في function _openSection عن هذا السطر الحالي:

~~~~javascript
html += '<div class="border rounded-xl p-4 hover:bg-' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\'' + sectionKey + '\', \'' + rep.id + '\')">';
~~~~

احذفه واستبدله بـ:

~~~~javascript
html += '<div class="border rounded-xl p-4 hover:' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\'' + sectionKey + '\', \'' + rep.id + '\')">';
~~~~

النتيجة تمنع تكوين:
hover:bg-bg-...
وتنتج class صحيحة:
hover:bg-...

## 15. ما لم يتغير
لا إعادة فتح:
- _companyId
- _generateReport
- _exportReportCsv
- _printReport
- HR blocks
- Inventory Turnover
- Finance reporting
- operational field workflows

## 16. حماية رحلة التشغيل
التقارير لا تعيد تنفيذ:
Order → order_details → Runsheet → run_sheet_details → Picking → Reservation → Loading → Delivery → Return → Settlement

التقارير تقرأ وتحقق وتكشف.

## 17. E2E State
Verified:
- Git HEAD/parent
- Mother HEAD/parent/blob
- current source
- V8 parse
- 38 reports
- Production report contracts
- Owner authenticated inventory report smoke
- unauthorized rejection smoke
- Production inventory report security repair

Still OPEN:
- Owner cutover
- Browser Production E2E
- 38-report click-through
- drilldown/back browser test
- CSV/Print browser test
- post-cutover Production re-snapshot

لا يجوز إعلان Browser PASS من SQL PASS.

## 18. Current Production Data Reality
Current Production:
- one company
- two branches
- 17 items
- 20 stock rows
- 3 inventory logs
- zero orders
- zero runsheets
- zero purchase orders
- zero stock vouchers
- zero customer ledger rows
- zero supplier ledger rows
- zero settlement rows
- two journal entries
- zero journal lines

لا تُنشأ Fixtures دائمة فقط للحصول على Test PASS.

## 19. FINAL SELF-AUDIT

### What I Proved
- Current Git and parent verified.
- Mother Git and parent verified.
- Current main.html verified.
- Full inline parser PASS.
- Current 38 report structure verified.
- Production reporting contracts verified.
- Inventory reporting auth gap proven.
- Production security repair deployed.
- Owner report smoke PASS.
- Unauthorized report execution rejected.
- Exact Modal → Page replacement parsed successfully in isolation.

### What I Did Not Prove
- Live browser after Owner cutover.
- 38-report full click-through.
- Live CSV/Print/Back browser path.
- Served production artifact after final Mother commit.

### What Could Still Be Wrong
- Owner may paste a different block than the exact replacement.
- Served artifact may lag Mother HEAD.
- An unrelated browser-only defect may appear after cutover.

## 20. Final Closure State

~~~~text
CURRENT GIT = VERIFIED
CURRENT SOURCE = VERIFIED
CURRENT PRODUCTION = VERIFIED
CURRENT DATABASE = VERIFIED
PRODUCTION INVENTORY REPORT SECURITY = CLOSED
DRILLDOWN SOURCE PATCH = OWNER READY
MAIN.HTML CTO EDIT = 0
BROWSER PRODUCTION E2E = OPEN
38 REPORT LIVE SMOKE = OPEN
FULL COMPREHENSIVE TAB = OPEN UNTIL OWNER CUTOVER + BROWSER EVIDENCE
~~~~

## 21. Session Continuity
المساعد التالي يبدأ من:
1. CURRENT_STATE
2. System HEAD + parent
3. Mother HEAD + parent + main.html blob
4. Current source recheck
5. Production report contracts
6. Exact owner patches in Report254
7. V8 parser
8. Browser E2E
9. 38-report smoke
10. Production resnapshot

لا تبدأ من Report241 كأنه Current.
لا تعيد إصلاح ما ثبت إغلاقه دون Current Evidence جديد.



---

# 13. OWNER SURGICAL PATCH 02 — Hover

داخل:

function _openSection(sectionKey)

ابحث بالنص الحرفي عن:

~~~~javascript
html += '<div class="border rounded-xl p-4 hover:bg-' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\\'' + sectionKey + '\\', \\'' + rep.id + '\\')">';
~~~~

احذف هذا السطر فقط.

واستبدله بالسطر التالي كاملًا:

~~~~javascript
html += '<div class="border rounded-xl p-4 hover:' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\\'' + sectionKey + '\\', \\'' + rep.id + '\\')">';
~~~~

النتيجة:
section.bgColor = bg-...
↓
hover: + bg-...
↓
hover:bg-...

ولا يتم توليد:
hover:bg-bg-...

---

# 14. ماذا تم إثباته؟

## Proven

- System HEAD verified.
- System parent verified.
- Mother HEAD verified.
- Mother parent verified.
- Current main.html blob verified.
- Current RW_Reports_Comprehensive verified.
- 38 report IDs verified.
- Current Production snapshot verified مباشرة.
- Reporting RPC privileges verified.
- Inventory reporting auth closure remains valid.
- Current sidebar source structure verified.
- Current collapse persistence gap proven.
- Current collapsed navigation UX gap proven.
- Current modal drill-down gap proven.
- Current hover defect proven.
- Sidebar replacement syntax PASS.
- Existing Report254 Drill-Down patch remains the exact current surgical patch.

## Not Proven

- Owner integration of Sidebar patch.
- Owner integration of Report254 Patch 01/02.
- Served Mother artifact after cutover.
- Browser E2E.
- 38-report live click-through.
- Drill-Down → Back browser path.
- CSV browser path.
- Print browser path.
- Mobile navigation E2E بعد cutover.

---

# 15. سبب الخطأ

الرسالة الأصلية لا تحتوي نص Error message محددًا في آخرها يمكن إثبات سبب مستقل له.

لذلك لم يتم اختراع Root Cause غير موجود.

الأسباب المثبتة من المصدر الحالي فقط هي:

1. Collapsed Sidebar persistence موجودة في write path ولا يوجد restore كامل عند build.
2. Collapsed mode يخفي النصوص وsubmenus دون بديل navigation equivalent.
3. leaf nodes في القائمة الحالية لا تحمل icon usable في collapsed mode.
4. Group interaction تعتمد inline style toggling ولا تمتلك persistent navigation state.
5. Drill-Down الحالي يعتمد Swal.fire بدل Page workspace.
6. _openSection يولد hover:bg-bg-... بسبب double bg- prefix.

أي Error آخر يحتاج نص الخطأ أو runtime trace مستقل قبل إصدار Root Cause.

---

# 16. Production Action Taken In This Session

لا توجد Migration جديدة.

لا توجد Edge Function جديدة.

لا يوجد Production DDL جديد.

السبب:
Production reporting contracts مثبتة وسليمة.
المشكلة المفتوحة Source/UI + Owner cutover + Browser verification.

إعادة كتابة Production بدون Contract gap مثبت كان ستخلق debt غير ضروري.

---

# 17. عدم المساس بالعمليات الميدانية

لم يتم تعديل:

Order lifecycle
Runsheet lifecycle
Picking
Reservation
Loading
Delivery
Return
Unloading
Settlement
Inventory movement

التقارير تبقى Read/Verify/Reveal layer.

والقائمة الجانبية تبقى Navigation/Orchestration layer.

ولا توجد dual-write جديدة.

---

# 18. E2E Gate المطلوب بعد Owner Cutover

بعد أن يطبق Owner البلوكات الجراحية فقط:

### Navigation

- تسجيل الدخول.
- فتح القائمة.
- فتح/طي القائمة.
- Refresh.
- التأكد أن state محفوظ.
- فتح Group.
- Refresh.
- التأكد أن state محفوظ.
- تشغيل Search.
- فتح نتيجة.
- إضافة Favorite.
- إزالة Favorite.
- فتح Recent.
- اختبار collapsed tooltip.
- اختبار mobile menu.
- اختبار permissions.
- اختبار OWNER audit-log.
- اختبار Finance action.
- اختبار logout.

### Comprehensive Reports

- فتح التقارير الشاملة.
- فتح كل section.
- التأكد من عدم وجود hover:bg-bg.
- فتح تقرير.
- إدخال criteria.
- تنفيذ التقرير.
- فتح Customer Drill-Down.
- Back.
- فتح Item Movement Drill-Down.
- Back.
- فتح Runsheet Drill-Down.
- Back.
- فتح Settlement Drill-Down.
- Back.
- CSV.
- Print.
- التحقق من بقاء كل شيء داخل نفس workspace.
- Smoke لجميع 38 report IDs.
- Production re-snapshot بعد cutover.

ولا يجوز تحويل Static PASS أو SQL PASS إلى Browser PASS.

---

# 19. Session Continuity — للمساعد التالي

ابدأ بالترتيب التالي:

1. اقرأ هذا التقرير كاملًا.
2. اقرأ CURRENT_STATE.md وآخر section حاكم.
3. Verify System HEAD + parent.
4. Verify Mother HEAD + parent + current main.html blob.
5. Verify Owner patch integration فقط؛ لا تفترض أنه طُبق.
6. Run V8/static parse على current Mother.
7. تأكد أن RW_Navigation هو replacement المحدد هنا.
8. تأكد من عدم رجوع Swal.fire إلى وظائف Drill-Down الأربع.
9. تأكد من إصلاح hover line.
10. Run authenticated Browser E2E.
11. Run 38-report smoke.
12. Run Drill-Down/Back/CSV/Print.
13. Re-read Production.
14. Update CURRENT_STATE.
15. لا تعيد فتح Production reporting security إلا بدليل Regression جديد.
16. لا تعيد إصلاح أي closure سابق أغلقته Current Evidence.
17. لا تنتقل إلى نقطة أخرى قبل إغلاق هذه النقطة بدليل Production + Browser.

---

# 20. Final Closure State

~~~~text
CURRENT SYSTEM GIT       = VERIFIED
CURRENT SYSTEM PARENT    = VERIFIED
CURRENT MOTHER GIT       = VERIFIED
CURRENT MOTHER PARENT    = VERIFIED
CURRENT MAIN.HTML BLOB   = VERIFIED
CURRENT PRODUCTION       = VERIFIED
REPORTING RPC SECURITY   = CLOSED
SIDEBAR SURGICAL PATCH   = OWNER READY
REPORTS DRILLDOWN PATCH  = OWNER READY
HOVER PATCH              = OWNER READY
MAIN.HTML CTO EDIT       = 0
PRODUCTION DB CHANGE     = 0
BROWSER E2E              = OPEN
38 REPORT LIVE SMOKE     = OPEN
FULL CLOSURE             = OPEN UNTIL OWNER CUTOVER + BROWSER EVIDENCE
~~~~

# END REPORT 255
