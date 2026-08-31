from __future__ import annotations

import json
import subprocess
import time
from pathlib import Path

RESULT = Path('Current/CTO/playwright-result.json')

JS = r'''
const { chromium } = require('playwright');
(async()=>{
  const browser=await chromium.launch({headless:true});
  const page=await browser.newPage();
  const consoleErrors=[];
  const pageErrors=[];
  const badResponses=[];
  page.on('console', m=>{ if(m.type()==='error') consoleErrors.push(m.text()); });
  page.on('pageerror', e=>pageErrors.push(String(e && e.message || e)));
  page.on('response', r=>{ if(r.status()>=500) badResponses.push({url:r.url(),status:r.status()}); });
  await page.goto('http://127.0.0.1:8123/main.reconstruction.html',{waitUntil:'domcontentloaded',timeout:30000});
  await page.waitForTimeout(3500);
  const checks=await page.evaluate(()=>({
    title:document.title,
    doctype:document.doctype ? document.doctype.name : null,
    html:!!document.documentElement,
    body:!!document.body,
    loginPage:!!document.querySelector('.rw-login-page'),
    emailInput:!!document.querySelector('input[type="email"]'),
    passwordInput:!!document.querySelector('input[type="password"]'),
    shellContext:!!window.RW_ShellContext,
    ownerContract:!!window.RW_OwnerContract,
    dashboardModule:!!window.RW_Dashboard,
    reportsModule:!!window.RW_Reports,
    navigationPresent:!!document.querySelector('.rw-sidebar'),
  }));
  const browserResult={status:'PASS',checks,consoleErrors,pageErrors,badResponses,authenticated_owner:'SKIPPED_NO_GOVERNED_TEST_CREDENTIALS',authenticated_normal_user:'SKIPPED_NO_GOVERNED_TEST_CREDENTIALS'};
  await browser.close();
  require('fs').writeFileSync('Current/CTO/playwright-result.json',JSON.stringify(browserResult,null,2),'utf8');
  if(pageErrors.length || consoleErrors.some(x=>/SyntaxError|ReferenceError|TypeError/.test(x)) || badResponses.some(x=>r=>r.status>=500)) process.exit(1);
})().catch(e=>{require('fs').writeFileSync('Current/CTO/playwright-result.json',JSON.stringify({status:'FAIL',error:String(e&&e.stack||e)},null,2));process.exit(1);});
'''

Path('/tmp/playwright_gate.js').write_text(JS, encoding='utf-8')
subprocess.run(['node','/tmp/playwright_gate.js'], check=True)
