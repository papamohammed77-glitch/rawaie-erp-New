# REPORT 255 — القائمة الجانبية + التقارير الشاملة
## RAWAEA ERP — تحقيق جنائي وتعديل جراحي — 2026-09-19

## 1. نطاق التنفيذ

هذه الجلسة مخصصة فقط لاستكمال نقطتين متصلتين:
1. القائمة الجانبية والتوسيع/الطي ووظيفة التنقل الحديثة داخل Mother.
2. تبويب RW_Reports_Comprehensive، مع تحويل Drill-Down من Modal إلى Page وإصلاح defect الـhover المثبت.

لم يتم تعديل Mother main.html في هذه الجلسة.
ولم يتم تنفيذ Migration جديدة على Production، لأن Production reporting contracts المطلوبة لهذه النقطة سبق إغلاقها وثبت أنها ما زالت سليمة في snapshot الحالي.

تم الالتزام بمبدأ الحوكمة:
UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH → COMPARE TARGET → IDENTIFY GAP → MINIMAL SAFE CHANGE → IMPLEMENT → VERIFY.

التقارير السابقة مرجع تاريخي فقط؛ Current Truth هو المصدر الحي الذي تم التحقق منه في هذه الجلسة.

---

## 2. Current Git / Parent

### System Repository
Repository:
papamohammed77-glitch/rawaie-erp-New

قبل إضافة هذا التقرير:
HEAD = 01bdade6a582cae79b8b732fc0c6fc81b9370ffe

Parent of that state:
55e7f32cdfa574cb33057e596e01ef743ca99ed5

التقرير 255 نفسه أصبح commit جديدًا:
ca29bb938db14afddb25111832c228ea52adf671

Parent:
01bdade6a582cae79b8b732fc0c6fc81b9370ffe

### Mother Repository
Repository:
papamohammed77-glitch/erp-frontend

HEAD:
f6d57ff5eb235af09405de7a8df81812d061edd3

Parent:
adeda04609723e221249e51621cc674b05dfc5ce

Current main.html blob:
94a30d3d7fda02967b6a1f3b112ea2ced6d77ac9

الـMother HEAD الحالي غيّر forensic extract فقط، ولم يثبت تغييرًا جديدًا على main.html.
لذلك blob المذكور هو baseline الحالي للكود.

---

## 3. Current Production Snapshot

Project:
fiilmooggumokxanwiyx

تمت المطابقة المباشرة من Production أثناء هذه الجلسة:

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

هذه بيئة Production Sparse حقيقية.
لم يتم إنشاء Fixtures دائمة للحصول على PASS.

### Reporting RPC Security

Production الحالية ما زالت تثبت:
- anon EXECUTE = false
- authenticated EXECUTE = true
- service_role EXECUTE = true

لـ:
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

Production Reporting Security = CLOSED.

لا توجد بنية Production جديدة مطلوبة لهذه النقطة.

---

# 4. Historical + Architectural Reconstruction — Sidebar

القائمة الجانبية الحالية صُممت داخل Mother كـcentral navigation object:
RW_Navigation.menuTree

ثم:
Permission filtering
↓
navigation rendering
↓
RW_Views / Finance sub-tabs
↓
module renderers

وهذا التصميم صحيح معماريًا؛ لأن القائمة ليست Business Engine ولا Physical Stock Writer.

العمليات التشغيلية الميدانية بقيت خارج القائمة نفسها وتصل إلى تطبيقاتها:
Receiving → Picking → Loading → Delivery → Return → Unloading

لم يتم تعديل هذا العقد.

### لماذا لا نعيد بناء menuTree؟

لأن التحقيق الحالي أثبت أن:
- الـviews موجودة.
- permission keys موجودة.
- Finance actions موجودة.
- operational views موجودة.
- owner audit-log موجود كـspecial permission.
- reports-comprehensive مربوط فعليًا بالrouter الحالي.

الـgap الحقيقي هو Presentation + Navigation State + Collapse UX، وليس Business Menu topology.

---

# 5. Forensic Findings — Sidebar

## Defect S-01 — Persistence ناقصة

الكود الحالي يكتب:
rw_sidebar_collapsed

لكن لا يعيد بناء الـcollapsed state تلقائيًا من localStorage عند buildSidebar.

## Defect S-02 — Collapsed Mode غير قابل للملاحة بشكل حديث

عند collapse:
- النصوص تختفي.
- submenus تختفي.
- leaf buttons الحالية لا تعرض icons الخاصة بها.
- group لا تتحول إلى flyout/expand interaction.
- زر collapse لا يعكس state باستخدام aria semantics.
- لا توجد tooltip navigation كاملة.

إذن الموجود حاليًا هو CSS collapse فقط، وليس Compact Navigation مكتملة.

## Defect S-03 — لا توجد Recent / Favorites / Search

وهي patterns موثقة في:
- Dynamics 365 Finance & Operations
- SAP Fiori
- Manager.io
- Odoo dashboards/navigation patterns
- Business Central personalization
- Daftra role-driven visibility

## Defect S-04 — Group state transient

فتح المجموعة الحالية يعتمد على:
nextElementSibling.style.display

بدون state مستقل محفوظ.

## Defect S-05 — inline click handlers

Navigation groups الحالية تستخدم inline onclick لتبديل العرض.

الإصلاح الجراحي يحول أحداث navigation إلى event delegation، مع الحفاظ على نفس IDs والـviews والـpermissions.

---

# 6. Competitive UX Contract

### Dynamics 365
Navigation pane تجمع Favorites / Recent / Workspaces / Modules، ويمكنها العمل في collapsed/expanded mode.

### SAP Fiori
Navigation تعتمد Spaces وPinned Spaces وAll Spaces، مع إمكانية إعادة ترتيب العرض للمستخدم.

### Business Central
Navigation hierarchy + submenus + personalization + saved views + تنظيم عناصر navigation.

### Manager.io
Compact navigation تعرض icons فقط، مع إظهار الاسم عند hover.

### Odoo
الوصول إلى العناصر مرتبط بالتطبيقات والصلاحيات، مع personal dashboard organization.

### Daftra
ظهور بعض الأقسام والوظائف يتأثر بتفعيل التطبيق وصلاحيات الدور.

النتيجة المعمارية لـRAWAEA:
Authorization يبقى server/permission driven.
UX personalization يصبح client-side state.
لا يتم تحويل personalization إلى Business permissions.

---

# 7. Sidebar Target Architecture

الحالة المستهدفة:

Mother
↓
RW_Navigation.menuTree
↓
RW_Permissions_check / OWNER semantics
↓
Filtered Tree
↓
Search / Favorites / Recent / Modules
↓
Expanded or Compact Sidebar
↓
RW_Views / Finance sub-tabs

### Persisted user UX

localStorage:
- rw_sidebar_collapsed
- rw_nav_expanded_v2
- rw_nav_favorites_v2
- rw_nav_recent_v2

### لا يتم إنشاء

- navigation DB table
- server-side favorites table
- role-menu mutation schema
- tenant navigation table

لأنها ليست Contract gaps مثبتة.

---

# 8. OWNER SURGICAL PATCH — Sidebar

في:
companies/company-1/main.html

ابحث حرفيًا عن:

const RW_Navigation = {

واحذف البلوك الكامل حتى:

window.RW_Navigation = RW_Navigation;

ولا تحذف الـIIFE التالية الخاصة بنسيت كلمة المرور.

استبدله بالبديل الكامل التالي:

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

### ما يغلقه هذا الـPatch

- restore للـcollapse state بعد refresh.
- expanded groups persistence.
- search.
- favorites.
- recent.
- icons لجميع leaf items.
- usable compact mode.
- collapsed tooltips.
- group expand بعد فتح compact mode.
- active navigation state.
- aria-expanded للـgroups.
- desktop collapse.
- mobile navigation دون فرض compact width.
- event delegation بدل inline group toggles.
- الحفاظ على permission filtering.
- الحفاظ على OWNER audit-log.
- الحفاظ على Finance sub-tabs.
- الحفاظ على logout.
- الحفاظ على كل view IDs الحالية.

---

# 9. Static Validation — Sidebar

تم اختبار replacement object في JavaScript parser مستقل.

النتيجة:
SIDEBAR PATCH SYNTAX = PASS

لم يتم دمجها في Mother لأن المستخدم طلب عدم تعديل main.html.

---

# 10. Current RW_Reports_Comprehensive

الـMother current source يثبت:
- 38 report IDs.
- Router:
  reports-comprehensive → RW_Reports_Comprehensive.render()
- Current source parser = PASS.
- Production reporting contracts/security = CLOSED.

التقارير لا تعيد تنفيذ العمليات الميدانية.
هي Read / Verify / Reveal layer.

---

# 11. Forensic Findings — Comprehensive Reports

## Defect R-01 — Drill-Down Modal

الوظائف الحالية:
- _showCustomerLedgerDetail
- _showItemMovementDetail
- _showRunsheetDetail
- _showSettlementDetail

تستخدم Swal.fire.

العقد المستهدف:
Report workspace → Drill-Down page → Back → Report workspace

دون فتح Modal.

## Defect R-02 — Item Movement source

الـdrill-down الصحيح يعتمد على:
inventory_movement_report

وهو Production reporting contract الحالي.

## Defect R-03 — Hover class

داخل:
function _openSection(sectionKey)

الكود الحالي:
hover:bg- + section.bgColor

لكن section.bgColor يحتوي bg- أصلًا.

الناتج الحالي:
hover:bg-bg-...

وهذا defect source مثبت.

---

# 12. OWNER SURGICAL PATCH 01 — Modal → Page

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



---

# 13. PATCH 01 Rules

- لا تستخدم Swal.fire داخل وظائف التفاصيل الأربع.
- لا تغير أسماء الوظائف الأربع.
- لا تغير _generateReport.
- لا تغير report IDs.
- لا تغير operational apps.
- لا تغير order_details.
- لا تغير run_sheet_details.
- Item movement detail يجب أن يقرأ Production inventory_movement_report.
- Back يعيد التقرير الحالي.
- الـdrill-down يبقى داخل نفس report workspace.
- CSV/Print العامان لا يتأثران لأن drill-down أصبح داخل report-result.

---

# 14. OWNER SURGICAL PATCH 02 — Hover

داخل:
function _openSection(sectionKey)

ابحث بالنص الحرفي:

~~~~javascript
html += '<div class="border rounded-xl p-4 hover:bg-' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\\'' + sectionKey + '\\', \\'' + rep.id + '\\')">';
~~~~

احذف هذا السطر فقط.

واستبدله بالسطر التالي:

~~~~javascript
html += '<div class="border rounded-xl p-4 hover:' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\\'' + sectionKey + '\\', \\'' + rep.id + '\\')">';
~~~~

---

# 15. ماذا لا نلمس؟

لا إعادة فتح:
- _companyId
- _generateReport
- _exportReportCsv
- _printReport
- Inventory Turnover
- Inventory Movement Production contract
- Low Stock Production contract
- Finance reporting contracts
- HR reporting contracts
- field operational workflows
- order_details authority
- run_sheet_details derived relationship
- inventory movement engine

---

# 16. Production Decision

لم يتم تعديل Supabase/Edge Functions لهذه النقطة.

السبب المثبت:
Production reporting RPC security contracts الحالية سليمة.
الـopen gaps الحالية source/browser وليست DB/Edge infrastructure.

هذا يمنع خلق migration لمشكلة UI.

---

# 17. سبب الخطأ — حدود الإثبات

لا يوجد في نهاية طلب المستخدم نص Error message أو stack trace محدد.

لذلك لا يوجد Root Cause يمكن نسبه إلى Error غير موجود نصيًا.

المشكلات التي تم إثباتها فقط من Current Source هي:
1. Sidebar collapse persistence ناقصة.
2. collapsed navigation غير usable مثل compact panes الحديثة.
3. غياب Recent/Favorites/Search.
4. group state transient + inline toggles.
5. Drill-Down باستخدام Swal.fire.
6. hover:bg-bg-... بسبب double prefix.

أي خطأ runtime آخر لا يجوز نسبته إلى سبب قبل توفر:
- نص الخطأ
أو
- stack trace
أو
- runtime evidence.

---

# 18. E2E — الحقيقة الحالية

## Static/Production verified
- Current Git.
- Parent.
- Current Mother Git.
- Parent.
- Current main.html blob.
- Current 38 report structure.
- V8/source parsing.
- Production reporting RPC authorization.
- Existing security closure.

## Still Open
- Owner cutover للـSidebar patch.
- Owner cutover لReport254 Patch 01.
- Owner cutover لPatch 02.
- Browser E2E.
- 38-report live click-through.
- Drill-Down / Back.
- CSV.
- Print.
- Mobile navigation.
- Production re-snapshot after served Mother artifact.

ممنوع تحويل SQL PASS أو static PASS إلى Browser PASS.

---

# 19. E2E Contract بعد Owner Cutover

### Sidebar
Login → Sidebar → Expand/Collapse → Refresh → state restored → Group open/close → Search → Favorite → Recent → Tooltip → Mobile → Permissions → OWNER audit-log → Finance action → Logout.

### Comprehensive Reports
Open Reports → Comprehensive → Section → Report → Criteria → Execute → Drill-Down → Back → CSV → Print.

ثم:
38-report smoke matrix
+
Production re-snapshot.

---

# 20. Final Self-Audit

### What I Proved
- Current sources were reopened.
- Current system HEAD/parent verified.
- Current Mother HEAD/parent/blob verified.
- Production was re-snapshotted live.
- Reporting RPC security was rechecked.
- Current sidebar defect was traced to actual source.
- Current report drill-down defect was traced to actual source.
- Current hover defect was traced to actual source.
- Sidebar replacement passed independent JavaScript syntax validation.
- Existing report security closure was not reopened unnecessarily.

### What I Did Not Prove
- Browser runtime after owner integration.
- Served production Mother artifact after owner cutover.
- Full 38-report click-through.
- Live CSV/Print.
- Mobile live navigation.

### What Could Still Be Wrong
- Owner may paste a non-exact block.
- Served artifact may lag Mother HEAD.
- Browser-only defect may appear after integration.
- Any claimed error outside the six source defects above remains unverified until runtime evidence exists.

---

# 21. Session Continuity — Exact Start for Next CTO

1. Read CURRENT_STATE.md latest section.
2. Verify System HEAD + parent.
3. Verify Mother HEAD + parent + current main.html blob.
4. Confirm whether the owner changed main.html after this report.
5. Run V8/static parse.
6. Search RW_Navigation.
7. Search the four Drill-Down functions for Swal.fire.
8. Search _openSection for hover:bg-bg-.
9. If patches are integrated, run Browser E2E.
10. Run 38-report live smoke.
11. Run Drill-Down/Back/CSV/Print.
12. Re-snapshot Production.
13. Update CURRENT_STATE.
14. Close only evidence-backed gates.
15. Do not reopen closed Production contracts without new regression evidence.

---

# 22. Closure State

~~~~text
CURRENT SYSTEM GIT       = VERIFIED
CURRENT SYSTEM PARENT    = VERIFIED
CURRENT MOTHER GIT       = VERIFIED
CURRENT MOTHER PARENT    = VERIFIED
CURRENT MAIN.HTML BLOB   = VERIFIED
CURRENT PRODUCTION       = VERIFIED
REPORTING RPC SECURITY   = CLOSED

SIDEBAR PATCH            = OWNER READY
DRILLDOWN PATCH           = OWNER READY
HOVER PATCH               = OWNER READY

MAIN.HTML CTO CHANGE      = 0
PRODUCTION DB CHANGE      = 0

BROWSER E2E               = OPEN
38 REPORT LIVE SMOKE      = OPEN
FULL COMPREHENSIVE TAB    = OPEN UNTIL OWNER CUTOVER + BROWSER EVIDENCE
~~~~

# END REPORT 255
