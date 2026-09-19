
# RAWAEA ERP — Report 256
# التحقيق الجنائي الحالي — القائمة الجانبية + البحث الذكي + تبويب التقارير الشاملة
## 2026-09-19

---

## 1. Scope Lock

هذه الجلسة أوقفت أي مسار سابق وركزت حصراً على:

1. القائمة الجانبية في Mother main.html.
2. البحث داخل القائمة الجانبية وتحويله إلى Smart Navigation Search.
3. تبويب التقارير الشاملة الموجود بالفعل في النظام الأم.
4. التحقق من Production ذات الصلة.
5. تحديث الحالة للاستمرارية.

**تم احترام القاعدة:** لا تعديل مباشر على Mother main.html بواسطة CTO.

---

## 2. Governing Evidence

تم فتح الملف الحاكم كاملاً من أول سطر إلى آخر سطر:

doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md

الحجم المثبت:

- 29,578 حرفاً.
- 2,606 سطراً.

القواعد الحاكمة التي أثّرت مباشرة على هذه الجلسة:

- لا ثقة عمياء في التقارير.
- لا تخمين.
- لا إعادة إصلاح لعنصر ثبت إصلاحه.
- الدراسة قبل التعديل.
- Current Git + Current Source + Current Production + Current Database + Current Deployment Evidence.
- لا تحويل Static PASS إلى Production Browser PASS.
- لا ترك Closure Unit نصف مكتمل.
- لا تغيير في عقد قائم دون إثبات.
- النهاية: Verify → Repair → Complete → Deploy → Verify → Document → Update State.

---

## 3. آخر التقارير ذات الصلة

آخر السلسلة التي تم فتحها ومقارنتها مع Current Source:

- Report 252 — Owner License.
- Report 253 — Audit Log.
- Report 254 — Comprehensive Reports.
- Report 255 — Sidebar + Comprehensive Reports.

### تصحيح جنائي مهم

Report 255 كان يسجل أن:

- Sidebar = OWNER READY.
- Drill-down Modal → Page = OWNER READY.
- Hover fix = OWNER READY.

لكن Current Mother Source الحالية أثبتت أن جزء التقارير الذي كان مفتوحاً أصبح منفذاً بالفعل في المصدر الحالي.

لذلك **لم تتم إعادة تنفيذ هذه الإصلاحات**.

---

# 4. CURRENT SYSTEM GIT

Repository:

papamohammed77-glitch/rawaie-erp-New

Current HEAD:

2786cd9e568ef000be24b0067616f568ba54522a

Commit:

state: update Report255 sidebar and comprehensive reports continuity

Parent chain المعتمد:

2786cd9e568ef000be24b0067616f568ba54522a
↓
01bdade6a582cae79b8b732fc0c6fc81b9370ffe
↓
55e7f32cdfa574cb33057e596e01ef743ca99ed5

Canonical Report255 commit:

ad405e731c4106cf07a0f22e8b7f4ed5ba4fb613

---

# 5. CURRENT MOTHER GIT

Repository:

papamohammed77-glitch/erp-frontend

Current HEAD:

25bf5635114f4f804684657d5b28e1852c730cef

Commit:

forensic: persist current Mother HR extract

Parent المثبت عبر Git compare:

5d009ef32b874659866696c8173f959aee07070f

Git compare أثبت:

- ahead_by = 1
- behind_by = 0
- 25bf يحتوي commit واحد فقط بعد 5d009.
- 25bf عدل forensic extract فقط.

Functional Mother baseline للقائمة الحالية موجود في:

5d009ef32b874659866696c8173f959aee07070f

---

# 6. CURRENT MOTHER SOURCE

Authoritative file:

companies/company-1/main.html

Current blob:

e5989329c9c160ec756886d77b17b769e6a04c61

Current source:

- 1,553,973 characters.
- 28,621 lines.

**Mother main.html لم يتم تعديله في هذه الجلسة.**

---

# 7. CURRENT PRODUCTION SNAPSHOT

Supabase project:

fiilmooggumokxanwiyx

تمت إعادة القراءة من Production قبل اعتماد أي Source patch:

| Entity | Current |
|---|---:|
| Companies | 1 |
| Active Branches | 2 |
| Active Items | 16 |
| Stock Rows | 20 |
| Inventory Log | 3 |
| Orders | 0 |
| Order Details | 0 |
| Runsheets | 0 |
| Run Sheet Details | 0 |
| Purchase Orders | 0 |
| Purchase Order Details | 0 |
| Stock Vouchers | 0 |
| Stock Voucher Details | 0 |
| Daily Settlements | 0 |
| Journal Entries | 2 |
| Journal Lines | 0 |

Current company:

- id = 00000000-0000-0000-0000-000000000001
- name = الروائع

لا يوجد سبب Production DB لإصلاح Sidebar Search، لأنها capability محلية فوق Navigation metadata.

---

# 8. SIDEBAR — HISTORICAL / ARCHITECTURAL RECONSTRUCTION

التحقيق في Current Git أثبت أن القائمة الحالية ليست مجرد HTML static menu.

commit:

5d009ef32b874659866696c8173f959aee07070f

حوّلها إلى:

const RW_Navigation = { ... }

مع hierarchy واسعة تشمل:

## Sales

- التلي سيلز
- العملاء
- المتجر الإلكتروني
- نقطة البيع
- أوردرات المبيعات
- عروض الأسعار
- قوائم الأسعار
- العروض والخصومات
- مركز قرار المبيعات
- أهداف المبيعات
- الولاء والمكافآت
- الرانشيتات
- مرتجعات المبيعات

## Purchasing

- الموردين
- نقطة شراء
- دورة المشتريات

## Inventory

- الأصناف
- المخازن والفروع
- مركز التحكم في المخزون
- العمليات المخزنية
  - الاستلام
  - التحضير
  - التحميل
  - التوصيل
  - المرتجعات
  - التفريغ
- الأذونات المخزنية
  - تحويل مخزني
  - صرف سيارة بيع مباشر
  - استلام مرتجع سيارة
  - مرتجع لمورد
  - عرض الأذونات
- الجرد
  - جرد سيارة
  - جرد فرع
  - جرد عام

## Finance

- الخزائن والبنوك
- دليل الحسابات
- قائمة القيود اليومية
- قيد يومي جديد
- القيود المتكررة
- سندات القبض
- سندات الصرف
- المصروفات
- التحويلات
- الشيكات
- مطابقة البنك
- الضرائب
- الأصول والإهلاك
- الموازنات
- الفترات المحاسبية
- التقارير المالية
- التقسيط والتحصيل الآجل
- العمولات
- إغلاق اليومية

## Reports

- لوحة القيادة
- التقارير التفصيلية
- التقارير الشاملة

## Platform

- الموارد البشرية
- CRM
- المستخدمين والصلاحيات
- إدارة أدوار المستخدمين
- إدارة الترخيص
- إعدادات النظام
- سجل التدقيق للمالك
- تسجيل الخروج

---

# 9. ما هو موجود بالفعل في Sidebar

Current RW_Navigation يحتوي بالفعل على:

- Nested module hierarchy.
- Permission-aware filtering.
- OWNER special semantics.
- Persistent collapsed state.
- Persistent group state.
- Favorites.
- Recent.
- Compact-mode tooltips.
- Leaf icons.
- Mobile behavior.
- Runtime rendering.
- Recent tracking.
- Keyboard-friendly buttons.

إذن:

**لا نعيد بناء Sidebar.**

المشكلة الحالية ليست Architecture gap في menu tree.

المشكلة هي Search interaction gap.

---

# 10. ROOT CAUSE للبحث

## Input موجود

Current Source line 2064 يحتوي فعلياً على:

id="rw-nav-search-input"

والـplaceholder:

ابحث داخل القائمة...

إذن input نفسه ليس المشكلة.

## State موجود

_current state المستخدم في search هو:

this._state.search

## التحقيق في كل الاستخدامات

تم البحث في Current main.html عن:

_state.search

والنتيجة:

1. _renderSearchResults() يقرأ القيمة.
2. _renderNav() يحقن القيمة في input.
3. buildSidebar() يعمل reset للقيمة إلى empty.

لم يوجد أي مسار Current Source يقوم بعملية:

input.value → this._state.search

كما لم يوجد:

addEventListener('input', ...)

ولا:

addEventListener('keydown', ...)

لـsearch field.

### Root Cause المثبت

**Search UI موجود، لكن Search State Wiring مفقود.**

المسار الفعلي الآن:

User types
↓
DOM input.value changes
↓
لا يوجد listener
↓
RW_Navigation._state.search يبقى فارغاً
↓
_renderSearchResults() لا تستقبل query جديداً
↓
لا توجد نتائج

هذا هو السبب المثبت جنائياً لمشكلة البحث.

---

# 11. CURRENT SEARCH FUNCTION

الموضع:

main.html lines 2022–2048

الدالة:

_renderSearchResults()

حالياً تقوم بـsubstring search على:

- label
- view
- arg

ولكن حتى هذا المنطق لا يتم استدعاؤه مع قيمة جديدة لأن state لا يتغير.

كما أن current search لا يحتوي:

- Arabic normalization.
- ranked relevance.
- navigation path ranking.
- multi-word scoring.
- keyboard navigation.
- Ctrl/Cmd+K.
- selected result.

لذلك تم تصميم Patch A لرفع الوظيفة من basic filter إلى Smart Navigation Search.

---

# 12. SURGICAL PATCH A — SMART SEARCH ENGINE

## احذف

داخل:

const RW_Navigation = { ... }

ابحث بالنص الحرفي:

_renderSearchResults() {

حدد الدالة كاملة حتى الفاصلة التي تسبق:

_renderNav() {

**احذف الدالة كاملة فقط.**

## استبدلها بالكامل

~~~javascript
    _renderSearchResults() {
        var rawQuery = String(this._state.search || '');
        var q = rawQuery
            .replace(/\s+/g, ' ')
            .trim();

        try {
            q = q.normalize('NFKC');
        } catch (e) {}

        q = q
            .replace(/[\u064B-\u065F\u0670\u0640]/g, '')
            .replace(/[أإآ]/g, 'ا')
            .replace(/ى/g, 'ي')
            .replace(/ؤ/g, 'و')
            .replace(/ئ/g, 'ي')
            .toLowerCase()
            .replace(/\s+/g, ' ')
            .trim();

        if (!q) {
            this._state.searchIndex = 0;
            return '';
        }

        var queryTokens = q.split(' ').filter(function(token) {
            return !!token;
        });

        var rows = [];

        function normalize(value) {
            var s = String(value == null ? '' : value);

            try {
                s = s.normalize('NFKC');
            } catch (e) {}

            return s
                .replace(/[\u064B-\u065F\u0670\u0640]/g, '')
                .replace(/[أإآ]/g, 'ا')
                .replace(/ى/g, 'ي')
                .replace(/ؤ/g, 'و')
                .replace(/ئ/g, 'ي')
                .toLowerCase()
                .replace(/\s+/g, ' ')
                .trim();
        }

        function scoreField(text, token, weight) {
            if (!text || !token) return 0;

            if (text === token) {
                return 1000 * weight;
            }

            if (text.indexOf(token) === 0) {
                return 700 * weight;
            }

            if (text.indexOf(' ' + token) !== -1) {
                return 520 * weight;
            }

            if (text.indexOf(token) !== -1) {
                return 320 * weight;
            }

            return 0;
        }

        function walk(items, path) {
            for (var i = 0; i < items.length; i++) {
                var item = items[i];
                var nextPath = path || [];

                if (item.submenu) {
                    walk(
                        item.submenu,
                        nextPath.concat([item.label || ''])
                    );
                    continue;
                }

                var label = normalize(item.label || '');
                var view = normalize(item.view || '');
                var arg = normalize(item.arg || '');
                var fullPath = normalize(
                    nextPath.join(' ')
                );

                var score = 0;
                var matched = true;

                score += scoreField(label, q, 4);
                score += scoreField(view, q, 2);
                score += scoreField(arg, q, 2);
                score += scoreField(fullPath, q, 1);

                for (var t = 0; t < queryTokens.length; t++) {
                    var token = queryTokens[t];

                    var tokenScore = Math.max(
                        scoreField(label, token, 4),
                        scoreField(view, token, 2),
                        scoreField(arg, token, 2),
                        scoreField(fullPath, token, 1)
                    );

                    if (!tokenScore) {
                        matched = false;
                        break;
                    }

                    score += tokenScore;
                }

                if (matched && score > 0) {
                    rows.push({
                        item: item,
                        path: nextPath,
                        score: score
                    });
                }
            }
        }

        walk(this._state.tree, []);

        rows.sort(function(a, b) {
            if (b.score !== a.score) {
                return b.score - a.score;
            }

            return normalize(a.item.label || '')
                .localeCompare(
                    normalize(b.item.label || ''),
                    'ar'
                );
        });

        var maxResults = 20;

        if (rows.length > maxResults) {
            rows = rows.slice(0, maxResults);
        }

        var selectedIndex = Number(
            this._state.searchIndex || 0
        );

        if (selectedIndex < 0) {
            selectedIndex = 0;
        }

        if (selectedIndex >= rows.length) {
            selectedIndex = rows.length
                ? rows.length - 1
                : 0;
        }

        this._state.searchIndex = selectedIndex;

        var html =
            '<div class="rw-nav-section">' +
                '<div class="rw-nav-section-title">' +
                    '<span>نتائج البحث</span>' +
                    '<span>' +
                        rows.length.toLocaleString('ar-EG') +
                    '</span>' +
                '</div>';

        if (!rows.length) {
            html +=
                '<div class="rw-nav-empty">' +
                    'لا توجد نتائج مطابقة' +
                '</div></div>';

            return html;
        }

        html +=
            '<div class="rw-nav-quick" ' +
                'role="listbox" ' +
                'aria-label="نتائج البحث">';

        for (var j = 0; j < rows.length; j++) {
            var result = rows[j];
            var item = result.item;
            var key = this._key(item);
            var icon = this._iconFor(item);
            var selected = j === selectedIndex;
            var breadcrumb = result.path.length
                ? result.path.join(' ← ')
                : 'الوحدات';

            html +=
                '<button type="button" ' +
                    'class="rw-sidebar-link rw-nav-leaf' +
                        (selected ? ' active' : '') +
                    '"' +
                    ' data-nav-key="' +
                        this._escape(key) +
                    '"' +
                    ' data-nav-label="' +
                        this._escape(item.label || '') +
                    '"' +
                    ' data-nav-search-result="1"' +
                    ' role="option"' +
                    ' aria-selected="' +
                        (selected ? 'true' : 'false') +
                    '">' +

                    '<span class="rw-nav-leaf-main">' +

                        '<span class="rw-nav-leaf-icon">' +
                            '<i class="fa-solid ' +
                                this._escape(icon) +
                            '"></i>' +
                        '</span>' +

                        '<span ' +
                            'class="rw-sidebar-link-text rw-nav-text" ' +
                            'style="min-width:0;">' +

                            '<span ' +
                                'style="display:block;' +
                                    'overflow:hidden;' +
                                    'text-overflow:ellipsis;' +
                                    'white-space:nowrap;">' +
                                this._escape(
                                    item.label || ''
                                ) +
                            '</span>' +

                            '<span ' +
                                'style="display:block;' +
                                    'font-size:10px;' +
                                    'font-weight:700;' +
                                    'color:#94a3b8;' +
                                    'overflow:hidden;' +
                                    'text-overflow:ellipsis;' +
                                    'white-space:nowrap;">' +
                                this._escape(breadcrumb) +
                            '</span>' +

                        '</span>' +
                    '</span>' +

                    '<span ' +
                        'style="font-size:10px;' +
                            'color:#94a3b8;' +
                            'font-weight:900;' +
                            'min-width:22px;' +
                            'text-align:center;">' +
                        (j + 1) +
                    '</span>' +

                '</button>';
        }

        html += '</div></div>';

        return html;
    },
~~~

---

# 13. SURGICAL PATCH B — SEARCH EVENT WIRING

## العنصر

الدالة:

_bindEvents()

الموضع الحالي:

main.html lines 2132–2209

## احذف

ابحث بالنص الحرفي:

_bindEvents() {

داخل:

const RW_Navigation = { ... }

حدد الدالة كاملة حتى الفاصلة التي تسبق:

_applyCollapsedState(...)

**احذفها بالكامل.**

## استبدلها بالكامل

~~~javascript
    _bindEvents() {
        var nav = byId('rw-sidebar-nav');

        if (
            !nav ||
            nav.getAttribute('data-rw-nav-bound') === '1'
        ) {
            return;
        }

        nav.setAttribute(
            'data-rw-nav-bound',
            '1'
        );

        nav.addEventListener(
            'input',
            function(e) {
                if (
                    !e.target ||
                    e.target.id !==
                        'rw-nav-search-input'
                ) {
                    return;
                }

                var input = e.target;
                var value = input.value || '';

                var caret =
                    typeof input.selectionStart ===
                    'number'
                        ? input.selectionStart
                        : value.length;

                RW_Navigation._state.search =
                    value;

                RW_Navigation._state.searchIndex =
                    0;

                RW_Navigation._renderNav();

                var raf =
                    window.requestAnimationFrame ||
                    function(cb) {
                        return setTimeout(cb, 0);
                    };

                raf(function() {
                    var next =
                        byId(
                            'rw-nav-search-input'
                        );

                    if (!next) return;

                    next.focus();

                    try {
                        next.setSelectionRange(
                            caret,
                            caret
                        );
                    } catch (err) {}
                });
            }
        );

        nav.addEventListener(
            'keydown',
            function(e) {
                if (
                    !e.target ||
                    e.target.id !==
                        'rw-nav-search-input'
                ) {
                    return;
                }

                var key =
                    String(e.key || '');

                var results =
                    nav.querySelectorAll(
                        '[data-nav-search-result="1"]'
                    );

                if (key === 'ArrowDown') {
                    e.preventDefault();

                    if (results.length) {
                        RW_Navigation._state.searchIndex =
                            Math.min(
                                results.length - 1,
                                Number(
                                    RW_Navigation
                                        ._state
                                        .searchIndex || 0
                                ) + 1
                            );

                        RW_Navigation._renderNav();

                        var inputDown =
                            byId(
                                'rw-nav-search-input'
                            );

                        if (inputDown) {
                            inputDown.focus();
                        }
                    }

                    return;
                }

                if (key === 'ArrowUp') {
                    e.preventDefault();

                    if (results.length) {
                        RW_Navigation._state.searchIndex =
                            Math.max(
                                0,
                                Number(
                                    RW_Navigation
                                        ._state
                                        .searchIndex || 0
                                ) - 1
                            );

                        RW_Navigation._renderNav();

                        var inputUp =
                            byId(
                                'rw-nav-search-input'
                            );

                        if (inputUp) {
                            inputUp.focus();
                        }
                    }

                    return;
                }

                if (key === 'Enter') {
                    e.preventDefault();

                    var selected =
                        nav.querySelector(
                            '[data-nav-search-result="1"]' +
                            '[aria-selected="true"]'
                        );

                    if (
                        !selected &&
                        results.length
                    ) {
                        selected =
                            results[0];
                    }

                    if (selected) {
                        selected.click();
                    }

                    return;
                }

                if (key === 'Escape') {
                    e.preventDefault();

                    RW_Navigation._state.search =
                        '';

                    RW_Navigation._state.searchIndex =
                        0;

                    RW_Navigation._renderNav();

                    return;
                }
            }
        );

        nav.addEventListener(
            'click',
            function(e) {
                var favorite =
                    e.target.closest(
                        '[data-nav-favorite]'
                    );

                if (favorite) {
                    e.preventDefault();
                    e.stopPropagation();

                    var key =
                        favorite.getAttribute(
                            'data-nav-favorite'
                        );

                    var item =
                        RW_Navigation._resolveKey(
                            key
                        );

                    if (item) {
                        RW_Navigation._favorite(
                            item
                        );
                    }

                    return;
                }

                var searchTrigger =
                    e.target.closest(
                        '[data-nav-search-trigger]'
                    );

                if (searchTrigger) {
                    e.preventDefault();

                    RW_Navigation.toggleSidebar(
                        false
                    );

                    setTimeout(function() {
                        var input =
                            byId(
                                'rw-nav-search-input'
                            );

                        if (input) {
                            input.focus();
                        }
                    }, 50);

                    return;
                }

                var group =
                    e.target.closest(
                        '[data-nav-group]'
                    );

                if (group) {
                    e.preventDefault();

                    var key =
                        group.getAttribute(
                            'data-nav-group'
                        );

                    if (
                        byId('rw-sidebar')
                            .classList
                            .contains('collapsed')
                    ) {
                        RW_Navigation.toggleSidebar(
                            false
                        );

                        setTimeout(
                            function() {
                                RW_Navigation
                                    ._toggleGroup(
                                        key
                                    );
                            },
                            20
                        );
                    } else {
                        RW_Navigation
                            ._toggleGroup(
                                key
                            );
                    }

                    return;
                }

                var leaf =
                    e.target.closest(
                        '.rw-nav-leaf'
                    );

                if (leaf) {
                    e.preventDefault();

                    var key =
                        leaf.getAttribute(
                            'data-nav-key'
                        );

                    var item =
                        RW_Navigation._resolveKey(
                            key
                        );

                    if (item) {
                        RW_Navigation._handleItem(
                            item
                        );
                    }
                }
            }
        );

        nav.addEventListener(
            'mouseover',
            function(e) {
                var leaf =
                    e.target.closest(
                        '.rw-nav-leaf'
                    );

                if (
                    !leaf ||
                    !byId('rw-sidebar')
                        .classList
                        .contains('collapsed')
                ) {
                    return;
                }

                RW_Navigation._showTooltip(
                    leaf,
                    leaf.getAttribute(
                        'data-nav-label'
                    ) || ''
                );
            }
        );

        nav.addEventListener(
            'mouseout',
            function(e) {
                var from =
                    e.target.closest
                        ? e.target.closest(
                            '.rw-nav-leaf'
                          )
                        : null;

                var to =
                    e.relatedTarget &&
                    e.relatedTarget.closest
                        ? e.relatedTarget.closest(
                            '.rw-nav-leaf'
                          )
                        : null;

                if (
                    from &&
                    from !== to
                ) {
                    RW_Navigation._hideTooltip();
                }
            }
        );

        nav.addEventListener(
            'focusin',
            function(e) {
                var leaf =
                    e.target.closest(
                        '.rw-nav-leaf'
                    );

                if (
                    leaf &&
                    byId('rw-sidebar')
                        .classList
                        .contains('collapsed')
                ) {
                    RW_Navigation._showTooltip(
                        leaf,
                        leaf.getAttribute(
                            'data-nav-label'
                        ) || ''
                    );
                }
            }
        );

        nav.addEventListener(
            'focusout',
            function(e) {
                if (
                    e.target.closest &&
                    e.target.closest(
                        '.rw-nav-leaf'
                    )
                ) {
                    RW_Navigation._hideTooltip();
                }
            }
        );

        document.addEventListener(
            'keydown',
            function(e) {
                var key =
                    String(
                        e.key || ''
                    ).toLowerCase();

                if (
                    !(e.ctrlKey || e.metaKey) ||
                    key !== 'k'
                ) {
                    return;
                }

                e.preventDefault();

                var sidebar =
                    byId('rw-sidebar');

                if (
                    sidebar &&
                    sidebar.classList
                        .contains('collapsed')
                ) {
                    RW_Navigation.toggleSidebar(
                        false
                    );
                }

                setTimeout(
                    function() {
                        var input =
                            byId(
                                'rw-nav-search-input'
                            );

                        if (input) {
                            input.focus();

                            try {
                                input.select();
                            } catch (err) {}
                        }
                    },
                    40
                );
            }
        );

        document.addEventListener(
            'click',
            function(e) {
                if (
                    !e.target.closest(
                        '#rw-sidebar'
                    )
                ) {
                    RW_Navigation._hideTooltip();
                }
            }
        );
    },
~~~

---

# 14. SMART SEARCH CONTRACT AFTER PATCH

البحث يصبح Navigation Search حقيقياً وليس Data Search.

## Normalization

- إزالة التشكيل.
- إزالة التطويل.
- أ / إ / آ → ا.
- ى → ي.
- ؤ → و.
- ئ → ي.
- lowercase للإنجليزية.
- collapse للمسافات.

## Search fields

- Label.
- View ID.
- Action argument.
- Parent navigation path.

## Ranking

1. Exact label.
2. Label prefix.
3. Word prefix.
4. Contains.
5. Technical identifier.
6. Parent path.

## Multi-word

كل token يجب أن يطابق على الأقل واحداً من:

- label
- view
- arg
- path

## Permissions

البحث يبدأ من:

this._state.tree

وهذا tree تم تصفيته مسبقاً بواسطة:

_filterTree()

إذن search لا يكتشف pages ممنوعة من المستخدم.

## Navigation context

كل نتيجة تعرض:

اسم الصفحة + المسار الأب.

## Keyboard

- Ctrl/Cmd + K.
- Arrow Down.
- Arrow Up.
- Enter.
- Escape.

---

# 15. COMPETITIVE FORENSIC COMPARISON

## Microsoft Dynamics 365 Finance & Operations

Microsoft توثق Navigation Search كأداة للعثور على الصفحات والتنقل إليها، وليس للبحث عن البيانات.

كما أن المطابقة تتم مع:

- page title.
- navigation path.

والنتائج تعرض page title + navigation path، وتراعي الصفحات التي يملك المستخدم access إليها.

كما أن Navigation Pane يتضمن Favorites وRecent وWorkspaces وModules.

Sources:

https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/fin-ops/get-started/navigation-search

https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/user-interface/page-navigation

## Odoo 19

Odoo يعتمد left panel منظم حسب sections، مع collapse وfavorites، ويستخدم search bar/global filters في dashboards.

Sources:

https://www.odoo.com/documentation/19.0/applications/productivity/dashboards.html

https://www.odoo.com/documentation/19.0/applications/productivity/spreadsheet/work_with_data/global_filters.html

كما توجد في بعض واجهات Odoo الحديثة Command Palette عبر Ctrl/Cmd+K:

https://www.odoo.com/documentation/19.0/applications/productivity/knowledge.html

## SAP Fiori

SAP App Finder يوفر بحثاً عن التطبيقات المتاحة للدور، مع keyword/tag filtering وتنظيم التطبيقات.

Sources:

https://help.sap.com/docs/btp/sap-fiori-launchpad-for-sap-btp/48a5dbb0308b47d8969485845d5966ae.html

https://help.sap.com/docs/btp/sap-fiori-launchpad-for-sap-btp/adding-apps-to-home-page

## Daftra

الوثائق الحالية تثبت:

- فصل المستخدم عن الموظف.
- دور المستخدم في الصلاحيات.
- الفروع المسموح بها.
- المستودعات والخزائن المرتبطة بالفروع.
- البحث باستخدام tags.
- صفحة معلومات وحركة مخزون وسجل نشاط.

Sources:

https://docs.daftra.com/user_manual/الفرق-بين-الموظف-والمستخدم-في-دفترة/

https://docs.daftra.com/user_manual/دليل-بدء-البيع-لفرع-معين/

https://docs.daftra.com/user_manual/إضافة-منتج-جديد-أو-خدمة-جديدة/

## Manager.io

Manager يضع Reports في left navigation ويجعل ظهور التقارير مرتبطاً بالـtabs enabled وبصلاحيات المستخدم.

Sources:

https://www2.manager.io/guides/7468

https://www2.manager.io/guides/7397

https://www2.manager.io/guides/33078

---

# 16. COMPETITIVE DECISION FOR RAWAEA

لا توجد حاجة إلى إنشاء Command Palette subsystem مستقل في هذه الجلسة.

السبب الهندسي:

RAWAEA يملك بالفعل:

Modules
→ Groups
→ Pages
→ Favorites
→ Recent
→ Compact Mode

وما ينقصه هو:

Search State Wiring
+
Ranked Search
+
Keyboard Navigation.

لذلك Patch A + Patch B تكمل Architecture الموجودة بدلاً من بناء نظام جديد.

كما تم الحفاظ على الفصل بين:

Sidebar Navigation Search

و

Header Global Search

الأول يحدد الصفحة المطلوبة.

الثاني يبحث في بيانات النظام.

وهذا الفصل يتوافق مع pattern موثق في Dynamics.

---

# 17. COMPREHENSIVE REPORTS — CURRENT SOURCE

تم تحليل Current Mother Source مباشرة.

## Report structure

- 38 report IDs.
- 38 matching generator branches.
- Missing = 0.
- Extra = 0.

إذن كل report listed لها implementation branch داخل _generateReport.

---

# 18. DRILL-DOWN — CURRENTLY CLOSED

Current Source يثبت أن:

_showCustomerLedgerDetail
_showItemMovementDetail
_showRunsheetDetail
_showSettlementDetail

أصبحت بالفعل Page-based.

التحقق البرمجي المباشر:

- Swal.fire داخل الوظائف الأربع = غير موجود.
- _renderReportDrilldownPage = موجود.

الحالة:

**Modal → Page = CLOSED IN CURRENT SOURCE**

لا تعيد استبدال هذه الدوال.

---

# 19. _openSection — CURRENTLY CLOSED

Current Source line 21829:

hover:' + section.bgColor

وهذا صحيح لأن section.bgColor يحتوي بالفعل على bg- prefix.

إذن:

hover:bg-bg-...

لم يعد موجوداً.

الحالة:

**Hover defect = CLOSED**

لا تعيد إصلاحه.

---

# 20. REPORT BACKEND — CURRENTLY CLOSED

Production تحتوي بالفعل على report engines المطلوبة، ومنها:

- inventory_movement_report
- inventory_replenishment_report
- comprehensive_inventory_turnover_report
- finance_tax_report
- finance_tax_settlements_report
- purchase_get_reports
- hr_query
- get_balance_sheet_data
- get_trial_balance
- get_profit_loss
- get_cash_flow

تمت إعادة قراءة وجودها وتعريفاتها الحالية.

ولا يوجد Current Evidence يثبت حاجة إلى:

- جدول جديد.
- Edge Function جديدة.
- RPC جديدة.

بسبب مشكلة Sidebar Search.

---

# 21. DO NOT TOUCH

لا تلمس:

- _generateReport()
- report IDs الـ38.
- _showCustomerLedgerDetail
- _showItemMovementDetail
- _showRunsheetDetail
- _showSettlementDetail
- _renderReportDrilldownPage
- _openSection
- report Production RPCs.
- Inventory Movement contract.
- Inventory Turnover contract.
- Low Stock contract.
- Finance reporting contract.
- HR reporting contract.
- operational field apps.
- order_details authority.
- run_sheet_details semantics.

---

# 22. PRODUCTION DECISION

**لا يوجد Production change لهذه الجلسة.**

سبب القرار:

Sidebar Smart Search client capability.

ولا توجد فجوة Database/Edge يجب علاجها.

إضافة Search table/RPC/Edge ستكون architectural debt غير مبرر.

---

# 23. E2E CONTRACT

## Sidebar

Login
→ Sidebar
→ Type Arabic
→ Results instantly
→ Open result
→ return
→ search again.

### Arabic

- مخزون
- مخازن
- أصناف
- اصناف
- مرتجع
- جرد

### Multi-word

- إدارة المبيعات
- تقرير المخزون
- التقارير الشاملة
- قيد يومي

### Technical

- inventory
- reports
- pos
- hr

### Keyboard

- Ctrl+K
- ArrowDown
- ArrowUp
- Enter
- Escape

### Security

يجب ألا يظهر في نتائج المستخدم أي page لا يملك permission لها.

### Compact

Collapse
→ Search trigger
→ Expand
→ Focus
→ Search

### Mobile

Open
→ Search
→ Result
→ Page
→ Sidebar closes.

---

# 24. COMPREHENSIVE REPORTS E2E

Reports
→ التقارير الشاملة
→ Section
→ Report
→ Criteria
→ Execute
→ Drill-down
→ Back
→ CSV
→ Print

ثم smoke matrix للـ38 report.

### Production data limitation

Current Production sparse:

- Orders = 0.
- Runsheets = 0.
- Purchases = 0.
- Stock vouchers = 0.

لا يجوز إنشاء fake Production fixtures فقط للحصول على PASS.

مسموح:

- route/render smoke.
- function/contract verification.

ويؤجل business-data correctness إلى وجود بيانات حقيقية.

---

# 25. EXACT OWNER CUTOVER

## CHANGE A

في:

erp-frontend/companies/company-1/main.html

ابحث عن:

_renderSearchResults() {

داخل:

const RW_Navigation = { ... }

احذف الدالة كاملة.

استبدلها بــPATCH A أعلاه.

## CHANGE B

في نفس الملف:

erp-frontend/companies/company-1/main.html

ابحث عن:

_bindEvents() {

داخل:

const RW_Navigation = { ... }

احذف الدالة كاملة.

استبدلها بــPATCH B أعلاه.

### لا تلمس

- _renderNav()
- _renderLeaf()
- _renderGroup()
- _filterTree()
- _collectLeaves()
- buildSidebar()
- Router
- RW_Reports_Comprehensive
- أي operational application.

---

# 26. SURGICAL PATCH VALIDATION

تم استخراج PATCH A + PATCH B وتشغيلهما كـstandalone JavaScript.

V8 new Function():

**PATCH_SYNTAX_PASS**

---

# 27. ERROR ROOT CAUSE — FINAL

المستخدم أشار إلى Error في نهاية الطلب، لكن لم يقدم:

- Error message.
- Stack trace.
- Browser console output.

لذلك لا يتم اختراع Root Cause لخطأ غير محدد.

الخطأ المثبت في Current Source هو:

**Sidebar Search Input is rendered but not wired to Search State.**

Root Cause chain:

DOM input
→ value changes
→ no input listener
→ state.search unchanged
→ renderSearchResults gets empty query
→ search appears non-functional.

هذه هي الحقيقة الوحيدة التي تم إثباتها.

---

# 28. WHAT WAS ALREADY COMPLETE

لم تتم إعادة إصلاح:

- Sidebar structure.
- collapse persistence.
- Favorites.
- Recent.
- Tooltips.
- Permission filtering.
- Report count 38.
- 38 generator branches.
- Drill-down pages.
- Hover fix.
- Production reporting security.

لأن Current Source أثبت أنها بالفعل موجودة.

---

# 29. FINAL SELF-AUDIT

## What I Proved

- MASTER CTO GOVERNANCE reopened completely.
- Latest relevant system reports reopened.
- Current System HEAD and parent verified.
- Current Mother HEAD and parent verified.
- Current Mother main.html blob verified.
- Current Production snapshot re-read.
- Current sidebar source inspected.
- Search input existence proved.
- All Current _state.search references traced.
- Missing input/keyboard wiring proved.
- Current Comprehensive Reports contains exactly 38 report IDs.
- Generator mapping = 38 → 38.
- Four drill-downs are already Page-based.
- Hover fix already exists.
- Report backend infrastructure already exists.
- No DB/Edge change is required for this Search closure.
- Patch A syntax validated.
- Patch B syntax validated.

## What I Did Not Prove

- Browser Production E2E after Owner cutover.
- Full keyboard test in the browser after cutover.
- 38-report live click-through.
- Live CSV/Print after cutover.

## What I Changed

- Mother main.html = 0.
- Comprehensive Reports source = 0.
- Reporting Production DB = 0.
- Operational apps = 0.

---

# 30. EXACT NEXT SESSION START

1. Verify System HEAD:
2786cd9e568ef000be24b0067616f568ba54522a

2. Verify Mother HEAD:
25bf5635114f4f804684657d5b28e1852c730cef

3. Verify Mother parent:
5d009ef32b874659866696c8173f959aee07070f

4. Verify current main.html blob:
e5989329c9c160ec756886d77b17b769e6a04c61

5. Confirm owner applied exactly:
- PATCH A.
- PATCH B.

6. Run V8 parse.

7. Run Mother Assembly Guard.

8. Browser E2E:
- Arabic.
- English.
- Multi-word.
- Technical ID.
- Ctrl+K.
- Arrow Up/Down.
- Enter.
- Escape.
- Permission filtering.
- Compact.
- Mobile.

9. Open Comprehensive Reports.

10. Execute all 38 report routes.

11. Test:
- Drill-down.
- Back.
- CSV.
- Print.

12. Re-read Production.

13. Update CURRENT_STATE.

14. Close only evidence-backed Browser gates.

### Anti-reset rule

Do not reopen:

- Drill-down Page conversion.
- Hover fix.
- Report backend.
- Reporting Production security.

unless fresh evidence demonstrates Regression.

---

# 31. CLOSURE STATE

~~~text
CURRENT SYSTEM GIT                = VERIFIED
CURRENT SYSTEM PARENT             = VERIFIED
CURRENT MOTHER GIT                = VERIFIED
CURRENT MOTHER PARENT             = VERIFIED
CURRENT MAIN.HTML                 = VERIFIED
CURRENT PRODUCTION                = VERIFIED

SIDEBAR STRUCTURE                 = CLOSED
SIDEBAR MODERN UX                 = CLOSED IN CURRENT SOURCE
SIDEBAR SMART SEARCH              = OWNER READY
COMPREHENSIVE REPORT COUNT        = CLOSED / 38
COMPREHENSIVE REPORT BRANCH MAP   = CLOSED / 38→38
DRILLDOWN MODAL→PAGE              = CLOSED IN CURRENT SOURCE
OPEN-SECTION HOVER FIX            = CLOSED IN CURRENT SOURCE
REPORTING PRODUCTION BACKEND      = CLOSED

PRODUCTION DB CHANGE THIS SESSION = 0
MOTHER MAIN.HTML CTO CHANGE       = 0

BROWSER E2E                       = OPEN
38-REPORT LIVE SMOKE              = OPEN
FINAL COMPREHENSIVE CLOSURE       = OPEN UNTIL OWNER CUTOVER + BROWSER EVIDENCE
~~~

# END REPORT 256
