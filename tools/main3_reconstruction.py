#!/usr/bin/env python3
from pathlib import Path
import hashlib,re

TARGET=Path("Current/PWA/main/main3.md")
TEXT=TARGET.read_text(encoding="utf-8")
BEFORE=hashlib.sha1(TEXT.encode()).hexdigest()
EXPECTED="1bfedd3b16abb804d83e2b7d5671f1b31f320a14"
if BEFORE != EXPECTED:
    raise SystemExit(f"MAIN3_SOURCE_GUARD_FAILED:{BEFORE}")
required=["var RW_Customers = (function()","var RW_Suppliers = (function()","var RW_Branches = (function()","var RW_Settings = (function()","var RW_Users = (function()","window.RW_Customers","window.RW_Suppliers","window.RW_Branches","window.RW_Settings","window.RW_Users"]
for x in required:
    if x not in TEXT: raise SystemExit(f"MAIN3_CONTRACT_MISSING:{x}")
TEXT=re.sub(r"supabase\.from\(['\"]suppliers['\"]\)\.select\(['\"]\*['\"]\)","supabase.from('suppliers').select('*').eq('company_id', RW_MAIN3.getCompanyId())",TEXT)
TEXT=re.sub(r"supabase\.from\(['\"]users['\"]\)\.select\(['\"]\*['\"]\)","supabase.from('users').select('*').eq('company_id', RW_MAIN3.getCompanyId())",TEXT)
TEXT=re.sub(r"supabase\.from\(['\"]roles['\"]\)\.select\(['\"]\*['\"]\)","supabase.from('roles').select('*').eq('company_id', RW_MAIN3.getCompanyId())",TEXT)
TEXT=re.sub(r"supabase\.from\(['\"]app_settings['\"]\)\.select\(['\"]\*['\"]\)\.limit\(1\)\.single\(\)","supabase.from('app_settings').select('*').eq('company_id', RW_MAIN3.getCompanyId()).order('created_at', { ascending: true }).order('id', { ascending: true }).limit(1).single()",TEXT)
TEXT=re.sub(r"supabase\.from\(['\"]app_settings['\"]\)\.select\(['\"]\*['\"]\)\.limit\(1\)\.maybeSingle\(\)","supabase.from('app_settings').select('*').eq('company_id', RW_MAIN3.getCompanyId()).order('created_at', { ascending: true }).order('id', { ascending: true }).limit(1).maybeSingle()",TEXT)
TEXT=TEXT.replace("(RW_STATE.app.currentUser && RW_STATE.app.currentUser.email) || null","(RW_STATE.app && RW_STATE.app.userId) || null")
TEXT=re.sub(r"(\.from\(['\"]customer_assignments['\"]\)\.select\(['\"][^'\"]*customers!inner\([^'\"]*['\"]\))",lambda m:m.group(1)+".eq('customers.company_id', RW_MAIN3.getCompanyId())",TEXT)
governance="// ============================================================\n// RAWAEA ERP — MAIN3 GOVERNANCE CONTRACT\n// Tenant authority = RW_ShellContext.getCompanyId()\n// No Physical Stock writer is permitted in this source fragment.\n// ============================================================\n(function(){\n    if (!window.RW_ShellContext || typeof window.RW_ShellContext.getCompanyId !== 'function') { throw new Error('MAIN3_REQUIRES_RW_SHELL_CONTEXT'); }\n    window.RW_MAIN3 = window.RW_MAIN3 || {};\n    window.RW_MAIN3.getCompanyId = function(){ return window.RW_ShellContext.getCompanyId(); };\n})();\n"
marker="// ============================================================\n// RW_Customers"
if marker not in TEXT: raise SystemExit("MAIN3_MARKER_MISSING")
TEXT=TEXT.replace(marker,governance+marker,1)
for p in [r"from\(['\"]suppliers['\"]\)\.select\(['\"]\*['\"]\)(?!\.eq\(['\"]company_id['\"])",r"from\(['\"]users['\"]\)\.select\(['\"]\*['\"]\)(?!\.eq\(['\"]company_id['\"])",r"from\(['\"]roles['\"]\)\.select\(['\"]\*['\"]\)(?!\.eq\(['\"]company_id['\"])",r"from\(['\"]app_settings['\"]\)\.select\(['\"]\*['\"]\)\.limit\(1\)"]:
    if re.search(p,TEXT): raise SystemExit(f"MAIN3_UNSAFE_PATTERN:{p}")
if re.search(r"stock_branches.*\.(update|insert|upsert)\(",TEXT,re.S): raise SystemExit("MAIN3_DIRECT_PHYSICAL_STOCK_WRITE")
if re.search(r"inventory_log.*\.(update|insert|upsert)\(",TEXT,re.S): raise SystemExit("MAIN3_DIRECT_INVENTORY_LOG_WRITE")
for x in required:
    if x not in TEXT: raise SystemExit(f"POST_REWRITE_CONTRACT_MISSING:{x}")
TARGET.write_text(TEXT,encoding='utf-8')
print('MAIN3_REBUILT',hashlib.sha1(TEXT.encode()).hexdigest(),TEXT.count('\n')+1)
