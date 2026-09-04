<!DOCTYPE html>
<!-- 2026-08-22 22:00 UTC -->
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>الروائع ERP | نظام متكامل</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@200;300;400;500;600;700;800;900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <script src="https://cdn.tailwindcss.com"></script>
  <script defer src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
  <script src="https://cdn.sheetjs.com/xlsx-0.20.0/package/dist/xlsx.full.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}html{scroll-behavior:smooth}body{font-family:'Cairo',sans-serif;background:#f8fafc;overflow-x:hidden;color:#111827}:root{--rw-primary:#2563eb;--rw-primary-dark:#1d4ed8;--rw-primary-light:#eff6ff;--rw-success:#10b981;--rw-warning:#f59e0b;--rw-danger:#ef4444;--rw-info:#06b6d4;--rw-dark:#111827;--rw-dark-2:#1f2937;--rw-gray:#6b7280;--rw-gray-light:#e5e7eb;--rw-bg:#f8fafc;--rw-card:#ffffff;--rw-sidebar:#ffffff;--rw-sidebar-hover:#f1f5f9;--rw-radius:22px;--rw-shadow:0 10px 30px rgba(0,0,0,0.06);--transition-speed:0.3s}
    .rw-login-page{width:100%;min-height:100vh;display:flex;position:relative;background:linear-gradient(135deg,#0f172a 0%,#1e3a8a 35%,#2563eb 100%)}
    .rw-login-page::before{content:"";position:absolute;inset:0;background:radial-gradient(circle at top left,rgba(255,255,255,0.12),transparent 28%),radial-gradient(circle at bottom right,rgba(255,255,255,0.08),transparent 24%);pointer-events:none}
    .rw-login-left{width:50%;min-height:100vh;display:flex;flex-direction:column;justify-content:center;padding:80px 90px;position:relative;z-index:2}
    .rw-brand-badge{width:fit-content;padding:12px 22px;border-radius:999px;background:rgba(255,255,255,0.12);border:1px solid rgba(255,255,255,0.15);color:white;font-size:14px;font-weight:700;backdrop-filter:blur(12px);margin-bottom:28px}
    .rw-login-title{font-size:64px;line-height:1.2;font-weight:900;color:white;margin-bottom:28px}
    .rw-login-description{color:rgba(255,255,255,0.78);font-size:20px;line-height:2;margin-bottom:48px;max-width:620px}
    .rw-login-features{display:flex;flex-direction:column;gap:18px}
    .rw-login-feature{display:flex;align-items:center;gap:16px;color:white;font-size:18px;font-weight:700}
    .rw-login-feature-icon{width:52px;height:52px;border-radius:18px;background:rgba(255,255,255,0.12);display:flex;align-items:center;justify-content:center;font-size:22px;backdrop-filter:blur(14px)}
    .rw-login-right{width:50%;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:40px;z-index:2}
    .rw-login-card{width:100%;max-width:520px;background:rgba(255,255,255,0.96);backdrop-filter:blur(20px);border-radius:36px;padding:48px 42px;box-shadow:0 30px 80px rgba(0,0,0,0.18);position:relative}
    .rw-login-card::before{content:"";position:absolute;top:0;left:0;width:100%;height:8px;background:linear-gradient(90deg,#2563eb,#06b6d4);border-radius:36px 36px 0 0}
    .rw-login-logo-area{display:flex;flex-direction:column;align-items:center;margin-bottom:38px}
    .rw-login-logo{width:120px;height:120px;border-radius:32px;background:linear-gradient(135deg,#2563eb,#1d4ed8);display:flex;align-items:center;justify-content:center;color:white;font-size:42px;font-weight:900;box-shadow:0 20px 40px rgba(37,99,235,0.25);margin-bottom:22px}
    .rw-company-name{font-size:34px;font-weight:900;color:#111827;margin-bottom:10px}
    .rw-company-description{color:#6b7280;font-size:16px;font-weight:600}
    .rw-login-form{display:flex;flex-direction:column;gap:24px}
    .rw-form-group{display:flex;flex-direction:column;gap:10px}
    .rw-form-label{color:#374151;font-size:15px;font-weight:800}
    .rw-input-wrapper{position:relative}
    .rw-input-icon{position:absolute;top:50%;transform:translateY(-50%);right:20px;color:#9ca3af;font-size:18px}
    .rw-input{width:100%;height:64px;border-radius:20px;border:2px solid #e5e7eb;background:white;padding:0 58px 0 20px;font-size:16px;font-weight:700;transition:0.25s}
    .rw-input:focus{border-color:#2563eb;box-shadow:0 0 0 5px rgba(37,99,235,0.10)}
    .rw-login-options{display:flex;justify-content:space-between;align-items:center;margin-top:-4px}
    .rw-remember{display:flex;align-items:center;gap:10px;font-size:14px;font-weight:700;color:#4b5563}
    .rw-forgot{color:#2563eb;font-size:14px;font-weight:800;text-decoration:none}
    .rw-login-btn{width:100%;height:64px;border-radius:22px;background:linear-gradient(135deg,#2563eb,#1d4ed8);color:white;font-size:18px;font-weight:900;transition:0.25s;box-shadow:0 16px 35px rgba(37,99,235,0.22);margin-top:10px;cursor:pointer}
    .rw-login-btn:hover{transform:translateY(-2px);box-shadow:0 24px 45px rgba(37,99,235,0.28)}
    .rw-login-footer{margin-top:28px;text-align:center;color:#6b7280;font-size:13px;font-weight:700;line-height:2}
    .rw-main-shell{width:100%;min-height:100vh;display:flex;background:var(--rw-bg)}
    .rw-sidebar{width:280px;min-width:280px;height:100vh;background:var(--rw-sidebar);display:flex;flex-direction:column;position:fixed;top:0;right:0;z-index:500;border-left:1px solid #e5e7eb;overflow-y:auto;overflow-x:hidden;transition:width var(--transition-speed), min-width var(--transition-speed);box-shadow:0 0 20px rgba(0,0,0,0.03)}
    .rw-sidebar.collapsed{width:80px;min-width:80px}
    .rw-collapse-btn{width:38px;height:38px;border-radius:12px;background:#f1f5f9;display:flex;align-items:center;justify-content:center;color:#64748b;font-size:18px;cursor:pointer;transition:all var(--transition-speed);position:absolute;left:16px;top:16px;z-index:10;border:1px solid #e2e8f0}
    .rw-collapse-btn:hover{background:#e2e8f0;color:#1e293b}
    .rw-sidebar-top{padding:60px 24px 18px;border-bottom:1px solid #f1f5f9;transition:padding var(--transition-speed);position:relative}
    .rw-sidebar.collapsed .rw-sidebar-top{padding:60px 12px 18px}
    .rw-sidebar-brand-logo{width:100px;height:100px;min-width:100px;min-height:100px;border-radius:20px;background-size:contain;background-repeat:no-repeat;background-position:center;display:flex;align-items:center;justify-content:center;color:white;font-size:26px;font-weight:900;box-shadow:0 12px 28px rgba(37,99,235,0.25);transition:all var(--transition-speed)}
    .rw-sidebar-company-name{color:#0f172a;font-size:20px;font-weight:900;white-space:nowrap;opacity:1;transition:opacity var(--transition-speed)}
    .rw-sidebar.collapsed .rw-sidebar-company-name{opacity:0;width:0;overflow:hidden}
    .rw-sidebar-company-subtitle{color:#64748b;font-size:12px;font-weight:700;margin-top:4px;white-space:nowrap;opacity:1;transition:opacity var(--transition-speed)}
    .rw-sidebar.collapsed .rw-sidebar-company-subtitle{opacity:0;width:0;overflow:hidden}
    .rw-sidebar-user{display:flex;align-items:center;gap:14px;padding:18px;border-radius:24px;background:#f8fafc;border:1px solid #f1f5f9;transition:all var(--transition-speed);overflow:hidden}
    .rw-sidebar.collapsed .rw-sidebar-user{padding:18px 12px;justify-content:center}
    .rw-sidebar-user-avatar{width:48px;height:48px;min-width:48px;border-radius:16px;background:linear-gradient(135deg,#0ea5e9,#2563eb);display:flex;align-items:center;justify-content:center;color:white;font-size:18px;font-weight:900}
    .rw-sidebar-user-name{color:#0f172a;font-size:15px;font-weight:800;white-space:nowrap;opacity:1;transition:opacity var(--transition-speed)}
    .rw-sidebar.collapsed .rw-sidebar-user-name{opacity:0;width:0;overflow:hidden}
    .rw-sidebar-user-role{color:#64748b;font-size:12px;font-weight:700;margin-top:4px;white-space:nowrap;opacity:1;transition:opacity var(--transition-speed)}
    .rw-sidebar.collapsed .rw-sidebar-user-role{opacity:0;width:0;overflow:hidden}
    .rw-sidebar-nav{flex:1;overflow-y:auto;overflow-x:hidden;padding:18px 16px 20px;transition:padding var(--transition-speed)}
    .rw-sidebar.collapsed .rw-sidebar-nav{padding:18px 8px 20px}
    .rw-sidebar-link{width:100%;height:52px;border-radius:16px;display:flex;align-items:center;gap:16px;padding:0 18px;background:transparent;transition:all var(--transition-speed);margin-bottom:6px;color:#475569;cursor:pointer;overflow:hidden;white-space:nowrap;font-weight:600}
    .rw-sidebar-link:hover{background:var(--rw-sidebar-hover);color:#0f172a}
    .rw-sidebar-link.active{background:#eff6ff;color:#2563eb;font-weight:800;box-shadow:0 4px 12px rgba(37,99,235,0.10)}
    .rw-sidebar.collapsed .rw-sidebar-link{justify-content:center;padding:0;gap:0}
    .rw-sidebar-link-icon{width:38px;height:38px;min-width:38px;border-radius:12px;display:flex;align-items:center;justify-content:center;background:#f1f5f9;font-size:16px;color:#64748b;transition:all var(--transition-speed)}
    .rw-sidebar-link.active .rw-sidebar-link-icon{background:#2563eb;color:white}
    .rw-sidebar-link-text{font-size:14px;font-weight:700;opacity:1;transition:opacity var(--transition-speed)}
    .rw-sidebar.collapsed .rw-sidebar-link-text{opacity:0;width:0;overflow:hidden}
    .rw-sidebar-submenu{padding-right:16px;transition:all var(--transition-speed)}
    .rw-sidebar.collapsed .rw-sidebar-submenu{display:none}
    .rw-sidebar-footer{padding:18px;border-top:1px solid #f1f5f9;transition:padding var(--transition-speed)}
    .rw-sidebar.collapsed .rw-sidebar-footer{padding:18px 8px}
    .rw-logout-btn{width:100%;height:52px;border-radius:16px;background:#fef2f2;color:#ef4444;display:flex;align-items:center;justify-content:center;gap:12px;font-size:14px;font-weight:800;transition:all var(--transition-speed);cursor:pointer;overflow:hidden;border:1px solid #fee2e2}
    .rw-logout-btn:hover{background:#fee2e2}
    .rw-sidebar.collapsed .rw-logout-btn{justify-content:center;gap:0;font-size:0}
    .rw-sidebar.collapsed .rw-logout-btn span:first-child{font-size:18px}
    .rw-main-content{width:100%;margin-right:280px;min-height:100vh;display:flex;flex-direction:column;transition:margin-right var(--transition-speed)}
    .rw-main-content.expanded{margin-right:80px}
    .rw-header{width:100%;height:96px;background:white;border-bottom:1px solid #e5e7eb;display:flex;align-items:center;justify-content:space-between;padding:0 34px;position:sticky;top:0;z-index:100}
    .rw-header-left{display:flex;align-items:center;gap:22px}
    .rw-mobile-menu-btn{width:54px;height:54px;border-radius:18px;background:#eff6ff;display:none;align-items:center;justify-content:center;font-size:22px;color:#2563eb;cursor:pointer}
    .rw-header-title{font-size:28px;font-weight:900;color:#111827}
    .rw-header-subtitle{color:#6b7280;font-size:14px;font-weight:700;margin-top:4px}
    .rw-header-right{display:flex;align-items:center;gap:16px}
    .rw-header-search{width:340px;height:58px;border-radius:20px;background:#f3f6fb;position:relative}
    .rw-header-search-input{width:100%;height:100%;background:transparent;border:none;padding:0 56px 0 18px;font-size:15px;font-weight:700}
    .rw-header-search-icon{position:absolute;top:50%;transform:translateY(-50%);right:18px;color:#9ca3af}
    .rw-header-icon-btn{width:58px;height:58px;border-radius:20px;background:#f3f6fb;position:relative;font-size:20px;transition:0.22s;cursor:pointer}
    .rw-header-icon-btn:hover{background:#e5eefc}
    .rw-notification-badge{position:absolute;top:8px;left:8px;min-width:22px;height:22px;border-radius:999px;background:#ef4444;color:white;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:900}
    .rw-header-profile{height:58px;border-radius:22px;background:#f3f6fb;padding:0 18px;display:flex;align-items:center;gap:14px;cursor:pointer}
    .rw-header-profile-avatar{width:42px;height:42px;border-radius:14px;background:linear-gradient(135deg,#2563eb,#1d4ed8);color:white;display:flex;align-items:center;justify-content:center;font-size:15px;font-weight:900}
    .rw-header-profile-name{font-size:14px;font-weight:800;color:#111827}
    .rw-header-profile-role{color:#6b7280;font-size:12px;font-weight:700;margin-top:3px}
    .rw-page-container{width:100%;flex:1;padding:34px}
    .rw-view{display:none}
    .rw-view.active{display:block}
    .rw-kpi-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:24px;margin-bottom:28px}
    .rw-kpi-card{background:white;border-radius:30px;padding:28px;box-shadow:0 8px 30px rgba(0,0,0,0.04);transition:0.22s}
    .rw-kpi-card:hover{transform:translateY(-4px)}
    .rw-kpi-card-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:26px}
    .rw-kpi-icon{width:68px;height:68px;border-radius:22px;display:flex;align-items:center;justify-content:center;font-size:28px}
    .rw-kpi-icon.blue{background:rgba(37,99,235,0.10)}.rw-kpi-icon.green{background:rgba(16,185,129,0.10)}.rw-kpi-icon.orange{background:rgba(245,158,11,0.10)}.rw-kpi-icon.red{background:rgba(239,68,68,0.10)}
    .rw-kpi-change{padding:8px 14px;border-radius:999px;font-size:12px;font-weight:900}
    .rw-kpi-change.positive{background:rgba(16,185,129,0.12);color:#10b981}.rw-kpi-change.neutral{background:rgba(245,158,11,0.12);color:#f59e0b}
    .rw-kpi-title{color:#6b7280;font-size:14px;font-weight:700;margin-bottom:14px}
    .rw-kpi-value{font-size:34px;font-weight:900;color:#111827}
    .rw-dashboard-grid{display:grid;grid-template-columns:2fr 1fr;gap:24px;margin-bottom:24px}
    .rw-card{background:white;border-radius:30px;padding:28px;box-shadow:0 8px 30px rgba(0,0,0,0.04)}
    .rw-card-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px}
    .rw-card-title{font-size:20px;font-weight:900;color:#111827}
    .rw-table-wrapper{overflow-x:auto}
    .rw-table{width:100%;border-collapse:collapse}
    .rw-table thead th{text-align:right;padding:16px 18px;background:#f8fafc;color:#374151;font-size:13px;font-weight:900}
    .rw-table tbody td{padding:18px;border-bottom:1px solid #f1f5f9;font-size:14px;font-weight:700;color:#111827}
    .rw-table tbody tr:hover{background:#f8fbff;cursor:pointer}
    .rw-status{padding:8px 14px;border-radius:999px;font-size:12px;font-weight:900;display:inline-block}
    .rw-status.success{background:rgba(16,185,129,0.12);color:#10b981}.rw-status.warning{background:rgba(245,158,11,0.12);color:#f59e0b}.rw-status.danger{background:rgba(239,68,68,0.12);color:#ef4444}
    .rw-btn-primary{background:var(--rw-primary);color:white;height:44px;padding:0 18px;border-radius:12px;font-weight:800;cursor:pointer;border:none}
    .rw-btn-primary:hover{background:var(--rw-primary-dark)}
    @media(max-width:1400px){.rw-kpi-grid{grid-template-columns:repeat(2,1fr)}}
    @media(max-width:1200px){.rw-dashboard-grid{grid-template-columns:1fr}}
    @media(max-width:992px){.rw-sidebar{transform:translateX(100%);transition:0.25s}.rw-sidebar.active{transform:translateX(0)}.rw-main-content{margin-right:0}.rw-mobile-menu-btn{display:flex}.rw-login-left{display:none}.rw-login-right{width:100%}}
    @media(max-width:768px){.rw-header{padding:0 18px}.rw-header-search{display:none}.rw-page-container{padding:18px}.rw-kpi-grid{grid-template-columns:1fr}}
  </style>
</head>
<body>
<!-- إصدار 2026-08-29 الساعة 11:30 مساءً -->
<div id="rw-login-page" class="rw-login-page">
  <div class="rw-login-left"><div class="rw-brand-badge">RAWAEA ERP ENTERPRISE</div><h1 class="rw-login-title">منصة إدارة الأعمال الذكية والمتكاملة</h1><div class="rw-login-description">نظام ERP احترافي متكامل لإدارة المبيعات والمخزون والحسابات واللوجستيات والتوزيع.</div><div class="rw-login-features"><div class="rw-login-feature"><div class="rw-login-feature-icon">📦</div><div>إدارة المخزون والرانشيتات</div></div><div class="rw-login-feature"><div class="rw-login-feature-icon">🚚</div><div>إدارة التوزيع والتوصيل</div></div><div class="rw-login-feature"><div class="rw-login-feature-icon">💰</div><div>الحسابات والتسويات المالية</div></div><div class="rw-login-feature"><div class="rw-login-feature-icon">📊</div><div>تقارير وتحليلات لحظية</div></div></div></div>
  <div class="rw-login-right"><div class="rw-login-card"><div class="rw-login-logo-area"><div class="rw-login-logo">ر</div><div class="rw-company-name">الروائع ERP</div><div class="rw-company-description">Enterprise Management System</div></div><form class="rw-login-form" id="rw-login-form"><div class="rw-form-group"><label class="rw-form-label">اسم المستخدم</label><div class="rw-input-wrapper"><div class="rw-input-icon">👤</div><input type="text" class="rw-input" id="rw-username" placeholder="أدخل اسم المستخدم" autocomplete="username"></div></div><div class="rw-form-group"><label class="rw-form-label">كلمة المرور</label><div class="rw-input-wrapper" style="position:relative;"><div class="rw-input-icon">🔒</div><input type="password" class="rw-input" id="rw-password" placeholder="أدخل كلمة المرور" autocomplete="current-password" style="padding-left:50px;"><button type="button" onclick="window.togglePasswordVisibility('rw-password', this)" style="position:absolute; left:15px; top:50%; transform:translateY(-50%); background:transparent; border:none; cursor:pointer; color:#9ca3af; font-size:18px; z-index:5;"><i class="fa-solid fa-eye"></i></button></div></div><div class="rw-login-options"><label class="rw-remember"><input type="checkbox"> <span>تذكرني</span></label><a href="#" class="rw-forgot">نسيت كلمة المرور؟</a></div><button type="submit" class="rw-login-btn">تسجيل الدخول</button></form><div class="rw-login-footer">جميع الحقوق محفوظة © الروائع ERP 2026</div></div></div>
</div>
<div id="rw-main-shell" class="rw-main-shell" style="display: none;">
  <aside id="rw-sidebar" class="rw-sidebar"><button id="rw-collapse-btn" class="rw-collapse-btn" title="توسيع/طي القائمة">☰</button><div class="rw-sidebar-top"><div class="rw-sidebar-brand"><img id="rw-sidebar-brand-logo" src="" class="h-16 mx-auto mb-4 bg-slate-50 p-1 rounded-2xl border border-slate-100"><div><div class="rw-sidebar-company-name" id="rw-sidebar-company-name">الروائع ERP</div></div></div></div><div class="rw-sidebar-nav" id="rw-sidebar-nav"></div><div class="rw-sidebar-footer"><button id="rw-logout-btn" class="rw-logout-btn"><span>🚪</span><span>تسجيل الخروج</span></button></div></aside>
  <main class="rw-main-content" id="rw-main-content">
    <header class="rw-header"><div class="rw-header-left"><button id="rw-mobile-menu-btn" class="rw-mobile-menu-btn">☰</button><div><div id="rw-header-title" class="rw-header-title">لوحة التحكم</div><div id="rw-header-subtitle" class="rw-header-subtitle">متابعة العمليات اليومية للنظام</div></div></div><div class="rw-header-right"><div class="rw-header-search"><input type="text" class="rw-header-search-input" placeholder="بحث سريع..."><div class="rw-header-search-icon">🔍</div></div><button class="rw-header-icon-btn">🔔<span class="rw-notification-badge">3</span></button><div class="rw-header-profile"><div><div class="rw-header-profile-name" id="rw-header-user-display">مستخدم</div><div class="rw-header-profile-role">مدير النظام</div></div><div class="rw-header-profile-avatar">م</div></div></div></header>
    <div id="rw-page-container" class="rw-page-container"></div>
  </main>
</div>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.107.0/dist/umd/supabase.min.js">
</script>
<script>
(function() {
'use strict';
var RW_SUPABASE_URL = 'https://fiilmooggumokxanwiyx.supabase.co';
var RW_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpaWxtb29nZ3Vtb2t4YW53aXl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3MDkwOTIsImV4cCI6MjA5NDI4NTA5Mn0.LZScCxnCiRrTSCCBmTryszQpY1AwBgR2dkTBbC5kOc4';

var RW_SUPABASE_CLIENT = (function () {
    if (!window.supabase || typeof window.supabase.createClient !== 'function') {
        console.error('❌ Supabase SDK not loaded correctly');
        return null;
    }
    var client = window.supabase.createClient(RW_SUPABASE_URL, RW_SUPABASE_ANON_KEY, {
        auth: {
            persistSession: true,
            autoRefreshToken: true,
            detectSessionInUrl: false
        },
        global: {
            headers: {
                apikey: RW_SUPABASE_ANON_KEY
            }
        }
    });
    // تعريض العميل على window لضمان عدم تظليله
    window.RW_SUPABASE_CLIENT = client;
    console.log('✅ Supabase Client initialized successfully');
    return client;
})();
var supabase = RW_SUPABASE_CLIENT;
// ============================================================
// RW_Table – نظام Pagination العام
// ============================================================
var RW_Table = (function() {
    var state = {};

    function paginate(tableBodyId, data, page, perPage, renderRowFn) {
        if (!data || !data.length) {
            var tbody = byId(tableBodyId);
            if (tbody) safeHTML(tbody, '<tr><td colspan="10" class="text-center py-8 text-gray-500">لا توجد بيانات</td></tr>');
            return;
        }
        page = page || 1;
        perPage = perPage || 50;
        var totalPages = Math.ceil(data.length / perPage);
        if (page > totalPages) page = totalPages;
        if (page < 1) page = 1;
        var start = (page - 1) * perPage;
        var end = Math.min(start + perPage, data.length);
        var pageData = data.slice(start, end);
        var html = '';
        for (var i = 0; i < pageData.length; i++) {
            html += renderRowFn(pageData[i], start + i);
        }
        var tbody = byId(tableBodyId);
        if (tbody) safeHTML(tbody, html);
        state[tableBodyId] = { data: data, page: page, perPage: perPage, totalPages: totalPages, renderRowFn: renderRowFn };
        renderControls(tableBodyId);
    }

    function renderControls(tableBodyId) {
        var st = state[tableBodyId];
        var pc = byId(tableBodyId + '-controls');
        if (!pc || !st) return;
        if (st.totalPages <= 1) {
            safeHTML(pc, '');
            return;
        }
        var html = '<div class="flex items-center justify-center gap-2 mt-3 text-sm">';
        html += '<span class="text-gray-500">عرض ' + ((st.page - 1) * st.perPage + 1) + '-' + Math.min(st.page * st.perPage, st.data.length) + ' من ' + st.data.length + '</span>';
        if (st.page > 1) {
            html += '<button onclick="RW_Table.goPage(\'' + tableBodyId + '\', ' + (st.page - 1) + ')" class="px-3 py-1 border rounded-lg font-bold hover:bg-gray-100">السابق</button>';
        }
        for (var p = 1; p <= st.totalPages; p++) {
            if (p === st.page) {
                html += '<span class="px-3 py-1 bg-blue-600 text-white rounded-lg font-bold">' + p + '</span>';
            } else if (p === 1 || p === st.totalPages || (p >= st.page - 2 && p <= st.page + 2)) {
                html += '<button onclick="RW_Table.goPage(\'' + tableBodyId + '\', ' + p + ')" class="px-3 py-1 border rounded-lg font-bold hover:bg-gray-100">' + p + '</button>';
            } else if (p === st.page - 3 || p === st.page + 3) {
                html += '<span class="px-1">...</span>';
            }
        }
        if (st.page < st.totalPages) {
            html += '<button onclick="RW_Table.goPage(\'' + tableBodyId + '\', ' + (st.page + 1) + ')" class="px-3 py-1 border rounded-lg font-bold hover:bg-gray-100">التالي</button>';
        }
        html += '</div>';
        safeHTML(pc, html);
    }

    function goPage(tableBodyId, page) {
        var st = state[tableBodyId];
        if (!st) return;
        paginate(tableBodyId, st.data, page, st.perPage, st.renderRowFn);
    }

    return { paginate: paginate, renderControls: renderControls, goPage: goPage };
})();
window.RW_Table = RW_Table;
// ============================================================
// RW_Audit_log – تسجيل الأحداث بصمت (Fire-and-forget)
// الإصدار 2.0 – fetch اليدوي (المادة 1)
// ============================================================
function RW_Audit_log(action, tableName, recordId, oldData, newData) {
    try {
        var payload = {
            action: action,
            table_name: tableName || null,
            record_id: recordId || null,
            old_data: oldData || null,
            new_data: newData || null
        };
        if (typeof supabase !== 'undefined' && supabase && supabase.auth) {
            supabase.auth.getSession().then(function(sessionRes) {
                var token = (sessionRes && sessionRes.data && sessionRes.data.session) ? sessionRes.data.session.access_token : null;
                if (!token) return;
                
                fetch(RW_SUPABASE_URL + '/functions/v1/log-action', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ' + token
                    },
                    body: JSON.stringify(payload)
                }).then(function(res) {
                    if (!res.ok) {
                        console.warn('Audit log failed: HTTP ' + res.status);
                    }
                }).catch(function(e) {
                    console.warn('Audit log fetch error:', e);
                });
            }).catch(function(e) {
                console.warn('Audit log session error:', e);
            });
        }
    } catch (e) {
        console.warn('Audit log exception:', e);
    }
}

// ============================================================
// RW_Permissions_check – التحقق من صلاحية محددة
// ============================================================
function RW_Permissions_check(permissionKey) {
    try {
        // المالك لديه صلاحية مطلقة
        if (window.RW_STATE && RW_STATE.app && RW_STATE.app.currentUser) {
            if (RW_STATE.app.currentUser.isOwner === true) {
                return true;
            }
        }
        // إذا كانت الصلاحيات تحتوي على نجمة = صلاحية مطلقة
        if (window.RW_STATE && Array.isArray(RW_STATE.permissions)) {
            if (RW_STATE.permissions.indexOf('*') !== -1) {
                return true;
            }
            // البحث عن المفتاح
            return RW_STATE.permissions.indexOf(permissionKey) !== -1;
        }
        return false;
    } catch (e) {
        console.warn('Permission check error:', e);
        return false;
    }
}

// ============================================================
// RW_Permissions_applyUI – إخفاء/إظهار العناصر حسب الصلاحية
// ============================================================
function RW_Permissions_applyUI() {
    try {
        // معالجة الأزرار التي تحمل data-btn-permission
        var buttons = document.querySelectorAll('[data-btn-permission]');
        for (var i = 0; i < buttons.length; i++) {
            var btn = buttons[i];
            var perm = btn.getAttribute('data-btn-permission');
            if (perm && !RW_Permissions_check(perm)) {
                btn.style.display = 'none';
            }
        }

        // معالجة الأقسام التي تحمل data-section-permission
        var sections = document.querySelectorAll('[data-section-permission]');
        for (var j = 0; j < sections.length; j++) {
            var sec = sections[j];
            var perm = sec.getAttribute('data-section-permission');
            if (perm && !RW_Permissions_check(perm)) {
                sec.style.display = 'none';
            }
        }
    } catch (e) {
        console.warn('Apply UI permissions error:', e);
    }
}
// ============================================================
// RW_Workflow – محرك السير الذكي
// ============================================================
var RW_Workflow = (function() {
    var rulesCache = [];
    function loadRules() {
        supabase.from('workflow_rules').select('*').eq('is_active', true).then(function(res) {
            rulesCache = res.data || [];
        }).catch(function(e) { console.warn('Workflow load error:', e); });
    }
    function evaluate(tableName, event, recordId, recordData) {
        if (!rulesCache.length) return;
        for (var i = 0; i < rulesCache.length; i++) {
            var rule = rulesCache[i];
            if (rule.trigger_table !== tableName || rule.trigger_event !== event) continue;
            if (rule.trigger_condition) {
                var field = rule.trigger_condition.field;
                var value = rule.trigger_condition.value;
                if (!recordData || String(recordData[field]) !== String(value)) continue;
            }
            var actions = rule.actions || [];
            var executed = [];
            for (var j = 0; j < actions.length; j++) {
                executed.push({ type: actions[j].type, status: 'pending' });
            }
            supabase.from('workflow_log').insert({
                rule_id: rule.id, rule_name: rule.name,
                trigger_table: rule.trigger_table, trigger_event: rule.trigger_event,
                trigger_record_id: String(recordId),
                trigger_data: recordData || null,
                actions_executed: executed,
                status: 'success'
            }).then(function() {}).catch(function() {});
        }
    }
    return { loadRules: loadRules, evaluate: evaluate };
})();
window.RW_Workflow = RW_Workflow;

// ============================================================
// RW_Notification – نظام الإشعارات
// ============================================================
var RW_Notification = (function() {
    var templatesCache = [];
    function loadTemplates() {
        supabase.from('notification_templates').select('*').eq('is_active', true).then(function(res) {
            templatesCache = res.data || [];
        }).catch(function() {});
    }
    function send(templateCode, variables, userEmail) {
        var tpl = null;
        for (var i = 0; i < templatesCache.length; i++) {
            if (templatesCache[i].code === templateCode) { tpl = templatesCache[i]; break; }
        }
        if (!tpl) {
            supabase.from('notification_templates').select('*').eq('code', templateCode).eq('is_active', true).single().then(function(res) {
                if (res.data) { templatesCache.push(res.data); _renderAndSave(res.data, variables, userEmail); }
            }).catch(function() {});
            return;
        }
        _renderAndSave(tpl, variables, userEmail);
    }
    function _renderAndSave(tpl, vars, targetEmail) {
        var title = tpl.title_template, body = tpl.body_template || '';
        if (vars) {
            var keys = Object.keys(vars);
            for (var i = 0; i < keys.length; i++) {
                var regex = new RegExp('#\\{' + keys[i] + '\\}', 'g');
                title = title.replace(regex, String(vars[keys[i]] || ''));
                body = body.replace(regex, String(vars[keys[i]] || ''));
            }
        }
        var userEmail = targetEmail || (RW_STATE.app.currentUser ? RW_STATE.app.currentUser.email : null);
        if (!userEmail) return;
        supabase.from('notifications').insert({
            user_email: userEmail, title: title, body: body,
            type: 'info', reference_table: (vars && vars.table) || null,
            reference_id: (vars && (vars.id || vars.order_code)) || null,
            is_read: false
        }).then(function() { _updateBadge(); }).catch(function() {});
    }
    function _updateBadge() {
        var email = RW_STATE.app.currentUser ? RW_STATE.app.currentUser.email : null;
        if (!email) return;
        supabase.from('notifications').select('id', { count: 'exact', head: true }).eq('user_email', email).eq('is_read', false).then(function(res) {
            var badge = byId('rw-notification-badge');
            if (!badge) return;
            var count = res.count || 0;
            if (count > 0) { badge.textContent = count > 99 ? '99+' : String(count); badge.style.display = 'flex'; }
            else { badge.style.display = 'none'; }
        }).catch(function() {});
    }
    function renderBell() {
        var btns = document.querySelectorAll('.rw-header-icon-btn');
        var bellBtn = null;
        for (var i = 0; i < btns.length; i++) {
            if (btns[i].innerHTML.indexOf('🔔') !== -1) { bellBtn = btns[i]; break; }
        }
        if (!bellBtn) return;
        bellBtn.innerHTML = '🔔<span id="rw-notification-badge" class="rw-notification-badge" style="display:none;">0</span>';
        bellBtn.onclick = function(e) { e.stopPropagation(); showPanel(); };
        _updateBadge();
    }
    function showPanel() {
        var email = RW_STATE.app.currentUser ? RW_STATE.app.currentUser.email : null;
        if (!email) return;
        supabase.from('notifications').select('*').eq('user_email', email).order('created_at', { ascending: false }).limit(50).then(function(res) {
            var notifs = res.data || [];
            var html = '<div dir="rtl" style="width:420px;max-height:500px;overflow-y:auto;">';
            html += '<div style="padding:16px 20px;border-bottom:1px solid #e5e7eb;display:flex;justify-content:space-between;align-items:center;">';
            html += '<h3 style="font-size:16px;font-weight:900;color:#111827;">الإشعارات</h3>';
            if (notifs.length > 0) html += '<button onclick="RW_Notification.markAllRead()" style="font-size:12px;color:#2563eb;font-weight:700;background:none;border:none;cursor:pointer;">قراءة الكل</button>';
            html += '</div>';
            if (!notifs.length) {
                html += '<div style="padding:40px 20px;text-align:center;color:#9ca3af;">لا توجد إشعارات</div>';
            } else {
                for (var n = 0; n < notifs.length; n++) {
                    var notif = notifs[n];
                    var bg = notif.is_read ? 'background:white;' : 'background:#eff6ff;';
                    var refTable = (notif.reference_table || '').replace(/'/g, "\\'");
                    var refId = (notif.reference_id || '').replace(/'/g, "\\'");
                    html += '<div onclick="RW_Notification._clickNotif(\'' + notif.id + '\',\'' + refTable + '\',\'' + refId + '\')" style="padding:12px 20px;border-bottom:1px solid #f1f5f9;cursor:pointer;' + bg + '">';
                    html += '<div style="font-size:13px;font-weight:800;color:#111827;">' + (notif.title || '') + '</div>';
                    if (notif.body) html += '<div style="font-size:12px;color:#6b7280;margin-top:4px;">' + notif.body + '</div>';
                    html += '</div>';
                }
            }
            html += '</div>';
            Swal.fire({ html: html, showConfirmButton: false, showCloseButton: true, width: 600, padding: 0, customClass: { popup: 'rounded-2xl overflow-hidden' } });
        }).catch(function() {});
    }
    function markAllRead() {
        var email = RW_STATE.app.currentUser ? RW_STATE.app.currentUser.email : null;
        if (!email) return;
        supabase.from('notifications').update({ is_read: true }).eq('user_email', email).eq('is_read', false).then(function() {
            _updateBadge(); showPanel();
        }).catch(function() {});
    }
    function markRead(notifId) {
        supabase.from('notifications').update({ is_read: true }).eq('id', notifId).then(function() {
            _updateBadge();
        }).catch(function() {});
    }
    function init() { loadTemplates(); _updateBadge(); }
    function _clickNotif(notifId, refTable, refId) {
        // تعليم كمقروء
        supabase.from('notifications').update({ is_read: true }).eq('id', notifId).then(function() { _updateBadge(); }).catch(function() {});
        // إغلاق اللوحة
        Swal.close();
        // التنقل إلى السجل المرتبط
        if (refTable && refId) {
            var viewMap = { 'orders': 'orders', 'items': 'items', 'customers': 'customers', 'purchase_orders': 'purchases', 'suppliers': 'suppliers' };
            var targetView = viewMap[refTable];
            if (targetView && typeof RW_Navigation !== 'undefined') {
                RW_Navigation.navigate(targetView);
            }
        }
    }
    return {
        send: send, renderBell: renderBell, markAllRead: markAllRead, markRead: markRead, init: init, _clickNotif: _clickNotif
    };
})();
window.RW_Notification = RW_Notification;
// ============================================================
// RW_Audit_renderTab – تبويب سجل التدقيق (للمالك فقط)
// ============================================================
function RW_Audit_renderTab() {
    var container = byId('rw-page-container');
    if (!container) return;
    safeText(byId('rw-header-title'), 'سجل التدقيق');
    safeText(byId('rw-header-subtitle'), 'جميع الأحداث والتغييرات في النظام');

    var html = '<div class="p-4">';
    html += '<div class="bg-white rounded-2xl shadow-sm border p-4 mb-4">';
    html += '<div class="flex flex-wrap gap-2">';
    html += '<input type="text" id="audit-search" placeholder="بحث بالبريد أو الجدول..." class="p-2 border rounded-lg text-sm w-64" oninput="RW_Audit_filterTable()">';
    html += '<select id="audit-filter-action" class="p-2 border rounded-lg text-sm" onchange="RW_Audit_filterTable()"><option value="">كل الإجراءات</option><option value="create">إنشاء</option><option value="update">تعديل</option><option value="delete">حذف</option><option value="login">دخول</option><option value="logout">خروج</option></select>';
    html += '<input type="date" id="audit-filter-from" class="p-2 border rounded-lg text-sm" onchange="RW_Audit_filterTable()">';
    html += '<input type="date" id="audit-filter-to" class="p-2 border rounded-lg text-sm" onchange="RW_Audit_filterTable()">';
    html += '<button onclick="RW_Audit_filterTable()" class="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-bold">تطبيق</button>';
    html += '</div></div>';
    html += '<div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh" id="audit-table-container">';
    html += '<div class="text-center py-10 text-gray-400">جاري تحميل سجل التدقيق...</div>';
    html += '</div>';
    html += '<div id="audit-pagination-controls" class="mt-3 flex justify-center gap-2"></div>';
    html += '</div>';

    safeHTML(container, html);
    RW_Audit_loadData();
}

// متغيرات داخلية للتبويب
var RW_AUDIT_PAGE = 1;
var RW_AUDIT_PAGE_SIZE = 50;
var RW_AUDIT_TOTAL = 0;
var RW_AUDIT_DATA = [];

async function RW_Audit_loadData() {
    var container = byId('audit-table-container');
    if (!container) return;
    safeHTML(container, '<div class="text-center py-10 text-gray-400"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</div>');

    try {
        var from = (RW_AUDIT_PAGE - 1) * RW_AUDIT_PAGE_SIZE;
        var to = from + RW_AUDIT_PAGE_SIZE - 1;

        var query = supabase
            .from('audit_log')
            .select('*', { count: 'exact' })
            .order('created_at', { ascending: false })
            .range(from, to);

        // تطبيق الفلاتر
        var searchVal = (byId('audit-search') ? byId('audit-search').value : '');
        if (searchVal) {
            query = query.or('user_email.ilike.%' + searchVal + '%,table_name.ilike.%' + searchVal + '%');
        }
        var actionVal = byId('audit-filter-action') ? byId('audit-filter-action').value : '';
        if (actionVal) {
            query = query.eq('action', actionVal);
        }
        var fromDate = byId('audit-filter-from') ? byId('audit-filter-from').value : '';
        var toDate = byId('audit-filter-to') ? byId('audit-filter-to').value : '';
        if (fromDate) {
            query = query.gte('created_at', fromDate);
        }
        if (toDate) {
            query = query.lte('created_at', toDate + 'T23:59:59');
        }

        var res = await query;
        if (res.error) {
            safeHTML(container, '<div class="text-center py-10 text-red-500">فشل تحميل البيانات</div>');
            return;
        }

        RW_AUDIT_DATA = res.data || [];
        RW_AUDIT_TOTAL = res.count || 0;
        RW_Audit_renderTable(RW_AUDIT_DATA);
    } catch (e) {
        console.error('Audit load error:', e);
        safeHTML(container, '<div class="text-center py-10 text-red-500">فشل الاتصال</div>');
    }
}

function RW_Audit_renderTable(data) {
    var container = byId('audit-table-container');
    if (!container) return;
    if (!data || data.length === 0) {
        safeHTML(container, '<div class="text-center py-10 text-gray-400">لا توجد سجلات</div>');
        return;
    }
    var html = '<table class="w-full text-sm"><thead class="bg-gray-50 sticky top-0"><tr>';
    html += '<th class="p-2">التاريخ</th><th class="p-2">المستخدم</th><th class="p-2">الإجراء</th><th class="p-2">الجدول</th><th class="p-2">رقم السجل</th><th class="p-2 text-center">تفاصيل</th>';
    html += '</tr></thead><tbody>';
    for (var i = 0; i < data.length; i++) {
        var log = data[i];
        var dateStr = log.created_at ? new Date(log.created_at).toLocaleString('ar-EG') : '';
        var actionLabel = log.action === 'create' ? 'إنشاء' : log.action === 'update' ? 'تعديل' : log.action === 'delete' ? 'حذف' : log.action === 'login' ? 'دخول' : log.action === 'logout' ? 'خروج' : log.action;
        html += '<tr class="border-t hover:bg-gray-50">';
        html += '<td class="p-2 text-xs">' + dateStr + '</td>';
        html += '<td class="p-2">' + (log.user_email || '') + '</td>';
        html += '<td class="p-2">' + actionLabel + '</td>';
        html += '<td class="p-2">' + (log.table_name || '-') + '</td>';
        html += '<td class="p-2 text-xs">' + (log.record_id ? log.record_id.substring(0, 8) + '...' : '-') + '</td>';
        html += '<td class="p-2 text-center"><button onclick="RW_Audit_showDetails(\'' + log.id + '\')" class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td>';
        html += '</tr>';
    }
    html += '</tbody></table>';
    safeHTML(container, html);
    RW_Audit_renderPagination();
}

function RW_Audit_renderPagination() {
    var pc = byId('audit-pagination-controls');
    if (!pc) return;
    var totalPages = Math.ceil(RW_AUDIT_TOTAL / RW_AUDIT_PAGE_SIZE);
    if (totalPages <= 1) {
        safeHTML(pc, '');
        return;
    }
    var html = '<span class="text-sm text-gray-500 ml-4">صفحة ' + RW_AUDIT_PAGE + ' من ' + totalPages + ' (إجمالي ' + RW_AUDIT_TOTAL + ' سجل)</span>';
    if (RW_AUDIT_PAGE > 1) {
        html += '<button onclick="RW_Audit_goPage(' + (RW_AUDIT_PAGE - 1) + ')" class="px-3 py-1 border rounded-lg text-sm font-bold">السابق</button>';
    }
    if (RW_AUDIT_PAGE < totalPages) {
        html += '<button onclick="RW_Audit_goPage(' + (RW_AUDIT_PAGE + 1) + ')" class="px-3 py-1 border rounded-lg text-sm font-bold">التالي</button>';
    }
    safeHTML(pc, html);
}

function RW_Audit_goPage(page) {
    RW_AUDIT_PAGE = page;
    RW_Audit_loadData();
}

function RW_Audit_filterTable() {
    RW_AUDIT_PAGE = 1;
    RW_Audit_loadData();
}

function RW_Audit_showDetails(logId) {
    var log = null;
    for (var i = 0; i < RW_AUDIT_DATA.length; i++) {
        if (RW_AUDIT_DATA[i].id === logId) {
            log = RW_AUDIT_DATA[i];
            break;
        }
    }
    if (!log) return;
    var oldDataText = log.old_data ? JSON.stringify(log.old_data, null, 2) : 'لا يوجد';
    var newDataText = log.new_data ? JSON.stringify(log.new_data, null, 2) : 'لا يوجد';
    var html = '<div class="text-right text-sm">' +
        '<p><b>المستخدم:</b> ' + (log.user_email || '') + '</p>' +
        '<p><b>الإجراء:</b> ' + log.action + '</p>' +
        '<p><b>الجدول:</b> ' + (log.table_name || '-') + '</p>' +
        '<p><b>رقم السجل:</b> ' + (log.record_id || '-') + '</p>' +
        '<p><b>التاريخ:</b> ' + (log.created_at ? new Date(log.created_at).toLocaleString('ar-EG') : '') + '</p>' +
        '<div class="mt-4"><b>البيانات القديمة:</b><pre class="bg-gray-100 p-2 rounded-lg mt-1 text-xs overflow-auto max-h-32">' + oldDataText + '</pre></div>' +
        '<div class="mt-2"><b>البيانات الجديدة:</b><pre class="bg-gray-100 p-2 rounded-lg mt-1 text-xs overflow-auto max-h-32">' + newDataText + '</pre></div>' +
        '</div>';
    Swal.fire({
        title: 'تفاصيل سجل التدقيق',
        html: html,
        width: '800px',
        showCloseButton: true,
        showConfirmButton: false
    });
}
const byId = id => document.getElementById(id);
const safeHTML = (el, html) => { if (!el) return; try { el.innerHTML = html; } catch(e) { console.error(e); } };
const safeText = (el, text) => { if (!el) return; try { el.innerText = text; } catch(e) { console.error(e); } };
const showLoader = (title = 'جاري التحميل...') => { try { Swal.fire({ title, allowOutsideClick: false, didOpen: () => Swal.showLoading() }); } catch(e) { console.error(e); } };
const hideLoader = () => { try { Swal.close(); } catch(e) {} };
const showToast = (message, type = 'success') => { try { Swal.fire({ title: message, icon: type, timer: 2000, showConfirmButton: false }); } catch(e) { alert(message); } };

const RW_STATE = { app: { initialized: false, authenticated: false, loading: false, currentView: 'dashboard', currentUser: null, company: { name: 'الروائع ERP', logo: 'ر' } }, data: { items: [], customers: [], suppliers: [], branches: [] }, permissions: [], ui: { sidebarOpen: false, sidebarCollapsed: false } };
window.RW_STATE = RW_STATE;
const RW_Auth = {
    login: function(username, password) {
        if (!username || !password) {
            showToast('يرجى إدخال اسم المستخدم وكلمة المرور', 'error');
            return;
        }
        showLoader('جاري تسجيل الدخول...');
        if (!RW_SUPABASE_CLIENT) {
            hideLoader();
            showToast('خطأ داخلي: عميل Supabase غير مهيأ', 'error');
            return;
        }
        var self = this;
        RW_SUPABASE_CLIENT.auth.signInWithPassword({
            email: username,
            password: password
        }).then(function(authRes) {
            if (authRes.error) {
                hideLoader();
                var msg = authRes.error.message || 'بيانات الدخول غير صحيحة';
                RW_Audit_log('failed_login', 'auth', username, null, { reason: msg });
                showToast('فشل الدخول: ' + msg, 'error');
                return;
            }
            var user = authRes.data.user;
            var meta = user.user_metadata || {};

            RW_STATE.app.authenticated = true;
            RW_STATE.app.currentUser = {
                name: meta.name || user.email,
                email: user.email,
                role: meta.role || 'مدير النظام',
                isOwner: meta.isOwner === true || meta.isOwner === 'true'
            };
            RW_STATE.permissions = meta.permissions || ['*'];
            RW_STATE.app.company = {
                name: meta.companyName || 'الروائع ERP',
                logo: meta.companyLogo || 'ر'
            };

            RW_Audit_log('login', 'auth', user.id, null, { email: user.email, role: meta.role || 'مدير النظام' });

            self.enterSystem();
        }).catch(function(e) {
            hideLoader();
            showToast('حدث خطأ أثناء الاتصال', 'error');
            console.error(e);
        });
    },
enterSystem: function() {
    hideLoader();
    try {
        byId('rw-login-page').style.display = 'none';
        byId('rw-main-shell').style.display = 'flex';
        
        var user = RW_STATE.app.currentUser;
        var userName = user ? (user.name || user.email) : 'مستخدم';
        
        safeText(byId('rw-sidebar-company-name'), RW_STATE.app.company.name || 'الروائع ERP');
        safeText(byId('rw-header-user-display'), userName);
        
        // تحديث اسم الشركة والشعار من الإعدادات (اختياري)
        RW_SUPABASE_CLIENT
            .from('app_settings')
            .select('*')
            .limit(1)
            .then(function(r){

                console.log('APP_SETTINGS_RESULT', r);

                if (!r || !r.data || !r.data.length) return;

                var row = r.data[0];

                safeText(
                    byId('rw-sidebar-company-name'),
                    row.company_name || 'الروائع ERP'
                );

                var logoImg = byId('rw-sidebar-brand-logo');

                if (logoImg && row.company_logo) {
                    logoImg.src = row.company_logo;
                    logoImg.style.objectFit = 'contain';
                    logoImg.style.backgroundColor = '#f8fafc';
                }

            })
            .catch(function(e){
                console.error('APP_SETTINGS_ERROR', e);
            });
        
        RW_Navigation.buildSidebar();
        RW_Workflow.loadRules();
        RW_Notification.init();
        // ✅ Bootstrap: تحميل البيانات الأساسية مرة واحدة لجميع التبويبات
        Promise.all([
            RW_Data.loadItems(),
            RW_Data.loadCustomers(),
            RW_Data.loadBranches()
        ]).then(function() {
            console.log('✅ Bootstrap data loaded successfully.');
            console.log('ITEMS COUNT', window.RW_STATE.data.items?.length);
    console.log('CUSTOMERS COUNT', window.RW_STATE.data.customers?.length);
    console.log('SUPPLIERS COUNT', window.RW_STATE.data.suppliers?.length);
    console.log('BRANCHES COUNT', window.RW_STATE.data.branches?.length);
            // تحميل الموردين (اختياري، لا يمنع الدخول)
            supabase.from('suppliers').select('*').then(function(r) {
                RW_STATE.data.suppliers = r.data || [];
                console.log('✅ Suppliers loaded.');
            });
        }).catch(function(e) {
            console.warn('⚠️ Bootstrap data failed:', e);
        }).finally(function() {
            // الانتقال للوحة التحكم في جميع الأحوال
            RW_Navigation.navigate('dashboard');
          setTimeout(function() { RW_Notification.renderBell(); }, 500);
        });
    } catch(e) {
        console.error(e);
        this.forceEnterFallback();
    }
},
        forceEnterFallback: function() {
        hideLoader();
        try {
            byId('rw-login-page').style.display = 'none';
            byId('rw-main-shell').style.display = 'flex';
            RW_Navigation.buildSidebar();
            RW_Navigation.navigate('dashboard');
            showToast('تم تشغيل النظام في الوضع الآمن', 'warning');
        } catch(e) {
            document.body.innerHTML = '<div style="min-height:100vh;display:flex;align-items:center;justify-content:center;flex-direction:column;font-family:Cairo;"><h1>RAWAEA ERP</h1><p>حدث خطأ أثناء تشغيل النظام</p><button onclick="location.reload()">إعادة التحميل</button></div>';
        }
    },
    logout: function() {
        var userEmail = 'unknown';
        if (RW_STATE.app.currentUser && RW_STATE.app.currentUser.email) {
            userEmail = RW_STATE.app.currentUser.email;
        }
        RW_Audit_log('logout', 'auth', userEmail, null, null);

        supabase.auth.signOut().then(function() {
            RW_STATE.app.authenticated = false;
            byId('rw-main-shell').style.display = 'none';
            byId('rw-login-page').style.display = 'flex';
        }).catch(function(e) {
            console.error(e);
        });
    }
};

var RW_Data = {
    loadItems: function() {
        return supabase.from('items').select('*').then(function(res) {
            if (res.error) throw res.error;
            RW_STATE.data.items = res.data || [];
            return RW_STATE.data.items;
        }).catch(function(e) {
            console.error('loadItems', e);
            RW_STATE.data.items = [];
            return [];
        });
    },
    loadCustomers: function() {
        return supabase.from('customers').select('*').then(function(res) {
            if (res.error) throw res.error;
            RW_STATE.data.customers = res.data || [];
            return RW_STATE.data.customers;
        }).catch(function(e) {
            console.error('loadCustomers', e);
            RW_STATE.data.customers = [];
            return [];
        });
    },
    loadBranches: function() {
        return supabase.from('branches').select('*').then(function(res) {
            if (res.error) throw res.error;
            RW_STATE.data.branches = res.data || [];
            return RW_STATE.data.branches;
        }).catch(function(e) {
            console.error('loadBranches', e);
            RW_STATE.data.branches = [];
            return [];
        });
    }
};
const RW_Navigation = {
    menuTree: [
    { view: 'dashboard', icon: 'fa-chart-pie', label: 'لوحة التحكم' },
    { icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'runsheets', label: 'الرانشيتات' }] },
    { icon: 'fa-truck', label: 'إدارة المشتريات', submenu: [{ view: 'suppliers', label: 'الموردين' }, { view: 'purchase-pos', label: 'نقطة شراء' }, { view: 'purchases', label: 'أوردرات الشراء' }] },
    { icon: 'fa-warehouse', label: 'إدارة المخازن والمخزون', submenu: [{ view: 'items', label: 'الأصناف' }, { view: 'branches', label: 'المخازن والفروع' }, { label: 'العمليات المخزنية', icon: 'fa-timeline', submenu: [{ view: 'receiving', label: 'الاستلام' }, { view: 'picking', label: 'التحضير' }, { view: 'loading', label: 'التحميل' }, { view: 'delivery', label: 'التوصيل' }, { view: 'return', label: 'المرتجعات' }, { view: 'unloading', label: 'التفريغ' }] }, { label: 'الأذونات المخزنية', icon: 'fa-file-signature', submenu: [{ view: 'transfer', label: 'تحويل مخزني' }, { view: 'direct-sale', label: 'صرف سيارة بيع مباشر' }, { view: 'direct-return', label: 'استلام مرتجع سيارة' }, { view: 'supplier-return', label: 'مرتجع لمورد' }, { view: 'vouchers', label: 'عرض الأذونات' }] }, { label: 'الجرد', icon: 'fa-clipboard-check', submenu: [{ view: 'vehicle-count', label: 'جرد سيارة' }, { view: 'branch-count', label: 'جرد فرع' }, { view: 'general-count', label: 'جرد عام' }] }] },
    { icon: 'fa-coins', label: 'إدارة الحسابات والمالية', submenu: [{ action: 'showFinanceTab', arg: 'treasury', label: 'الخزائن والبنوك' }, { action: 'showFinanceTab', arg: 'accounts', label: 'دليل الحسابات' }, { action: 'showFinanceTab', arg: 'journal', label: 'قيود يومية' }, { action: 'showFinanceTab', arg: 'receipts', label: 'سندات القبض' }, { action: 'showFinanceTab', arg: 'payments', label: 'سندات الصرف' }, { action: 'showFinanceTab', arg: 'transfers', label: 'التحويلات' }, { action: 'showFinanceTab', arg: 'reports', label: 'التقارير المالية' }, { view: 'settlement', label: 'إغلاق اليومية' }] },
    { icon: 'fa-chart-simple', label: 'التقارير الذكية', submenu: [
    { view: 'reports-dashboard', label: 'لوحة القيادة' },
    { view: 'reports-detailed', label: 'التقارير التفصيلية' },
    { view: 'reports-comprehensive', label: 'التقارير الشاملة' }
] },
    { view: 'hr', icon: 'fa-id-card', label: 'الموارد البشرية' },
    { view: 'crm', icon: 'fa-handshake', label: 'إدارة علاقات العملاء (CRM)' },
    { view: 'users', icon: 'fa-users-gear', label: 'المستخدمين والصلاحيات' },
    { view: 'roles', icon: 'fa-user-shield', label: 'إدارة أدوار المستخدمين' },
    { view: 'license', icon: 'fa-shield-haltered', label: 'إدارة الترخيص', perm: 'owner' },
    { view: 'settings', icon: 'fa-gear', label: 'إعدادات النظام' },
    { action: 'logout', icon: 'fa-right-from-bracket', label: 'تسجيل الخروج' }
],
_buildMenuHTML(items) { 
    let html = '<ul style="list-style:none;padding:0;margin:0;">'; 
    items.forEach(item => { 
        if (item.submenu) { 
            html += `<li style="margin-bottom:4px;">
                <div class="rw-sidebar-link" style="justify-content:space-between;" onclick="event.stopPropagation(); var s=this.nextElementSibling; if(s)s.style.display=s.style.display==='none'?'block':'none';">
                    <div style="display:flex;align-items:center;gap:16px;">
                        <div class="rw-sidebar-link-icon"><i class="fa-solid ${item.icon||'fa-folder'}"></i></div>
                        <div class="rw-sidebar-link-text">${item.label}</div>
                    </div>
                    <i class="fa-solid fa-chevron-down" style="font-size:11px;color:#94a3b8;"></i>
                </div>
                <div style="display:none;padding-right:16px;" class="rw-sidebar-submenu">${this._buildMenuHTML(item.submenu)}</div>
            </li>`; 
        } else if (item.action) { 
            html += `<li style="margin-bottom:4px;">
                <button class="rw-sidebar-link" onclick="RW_Navigation._handleAction('${item.action}','${item.arg||''}')">
                    <div class="rw-sidebar-link-text">${item.label}</div>
                </button>
            </li>`; 
        } else { 
            html += `<li style="margin-bottom:4px;">
                <button class="rw-sidebar-link" data-view="${item.view}">
                    <div class="rw-sidebar-link-text">${item.label}</div>
                </button>
            </li>`; 
        } 
    }); 
    return html + '</ul>'; 
},
_handleAction(action, arg) { if (action === 'showFinanceTab') {
    RW_STATE.app.currentView = 'finance';
    if (typeof RW_Finance !== 'undefined' && typeof RW_Finance.renderSubTab === 'function') {
        RW_Finance.renderSubTab(arg || 'treasury');
        safeText(byId('rw-header-title'), 'الحسابات والمالية');
    } else {
        RW_Views.render('finance');
    }
    return;
} if (action === 'logout') { RW_Auth.logout(); return; } if (typeof RW_Views !== 'undefined' && RW_Views.render) RW_Views.render(action); },
    buildSidebar() {
        try {
            var nav = byId('rw-sidebar-nav');
            if (!nav) return;

            // إضافة تبويب سجل التدقيق لقائمة إدارة النظام (للمالك فقط)
            var existingAudit = this.menuTree.find(function(item) { return item.view === 'audit-log'; });
            if (!existingAudit) {
                this.menuTree.push({ view: 'audit-log', icon: 'fa-clock-rotate-left', label: 'سجل التدقيق', perm: 'owner' });
            }

            function isAllowed(item) {
                if (item.perm === 'owner') {
                    return (RW_STATE.app.currentUser && RW_STATE.app.currentUser.isOwner === true);
                }
                if (item.perm) {
                    return RW_Permissions_check(item.perm);
                }
                if (item.view) {
                    return RW_Permissions_check(item.view);
                }
                return true;
            }

            function filterMenu(items) {
                var filtered = [];
                for (var i = 0; i < items.length; i++) {
                    var item = items[i];
                    if (!isAllowed(item)) continue;
                    if (item.submenu) {
                        var sub = filterMenu(item.submenu);
                        if (sub.length > 0) {
                            var n = {};
                            n.icon = item.icon;
                            n.label = item.label;
                            n.submenu = sub;
                            filtered.push(n);
                        }
                    } else {
                        filtered.push(item);
                    }
                }
                return filtered;
            }

            var tree = filterMenu(this.menuTree);
            safeHTML(nav, this._buildMenuHTML(tree));

            // إضافة مستمعات الأحداث وإخفاء البنود حسب الصلاحية
            var links = nav.querySelectorAll('.rw-sidebar-link[data-view]');
            for (var i = 0; i < links.length; i++) {
                (function(btn) {
                    btn.addEventListener('click', function(e) {
                        e.stopPropagation();
                        RW_Navigation.navigate(btn.getAttribute('data-view'));
                    });
                })(links[i]);
            }
        } catch(e) {
            console.error(e);
        }
    },
toggleSidebar() { const sidebar = byId('rw-sidebar'), main = byId('rw-main-content'); if (!sidebar || !main) return; const collapsed = sidebar.classList.toggle('collapsed'); main.classList.toggle('expanded', collapsed); RW_STATE.ui.sidebarCollapsed = collapsed; try { localStorage.setItem('rw_sidebar_collapsed', collapsed ? '1' : '0'); } catch(e) {} },
    navigate(view) { try { RW_STATE.app.currentView = view; document.querySelectorAll('.rw-sidebar-link').forEach(el => el.classList.remove('active')); const active = document.querySelector(`.rw-sidebar-link[data-view="${view}"]`); if (active) active.classList.add('active'); window.RW_Views.render(view); } catch(e) { console.error(e); showToast('حدث خطأ', 'error'); } }
};
window.RW_Navigation = RW_Navigation;
