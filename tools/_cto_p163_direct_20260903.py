#!/usr/bin/env python3
import hashlib, http.server, os, re, socketserver, subprocess, threading, time, urllib.request
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / 'Current' / 'PWA' / 'New-main'
STATE = ROOT / 'CURRENT_STATE.md'
WORKFLOW = ROOT / '.github' / 'workflows' / 'p163_final_close_20260903.yml'
VERSION = "window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';"
DIAMOND = 'RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'
AUTH = '/* RAWAEA MAIN2 AUTHORITATIVE MODULE */'
COMPAT = '/* RAWAEA MAIN2 COMPATIBILITY */'
CLOSED = '// MAIN2_GOVERNED_CLOSED:v1'


def run(cmd, check=True, capture=True, cwd=ROOT):
    return subprocess.run(cmd, cwd=cwd, check=check, text=True,
                          stdout=subprocess.PIPE if capture else None,
                          stderr=subprocess.STDOUT if capture else None)


def git(*args, check=True):
    return run(['git', *args], check=check)


def sha256(p):
    h = hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda: f.read(1024 * 1024), b''):
            h.update(b)
    return h.hexdigest()


def sync_latest():
    run(['git', 'fetch', 'origin', 'main'], check=True)
    run(['git', 'reset', '--hard', 'origin/main'], check=True)


def surgical_edit(text):
    if AUTH not in text:
        raise RuntimeError('P163_FAIL: authoritative marker missing')
    if text.count(AUTH) != 1:
        raise RuntimeError('P163_FAIL: authoritative marker count != 1')
    if DIAMOND not in text:
        raise RuntimeError('P163_FAIL: diamond closure marker missing')
    if COMPAT not in text:
        raise RuntimeError('P163_FAIL: compatibility surface not found')

    a = text.index(COMPAT)
    b = text.index(AUTH, a + len(COMPAT))
    block = text[a:b]
    if VERSION not in block:
        raise RuntimeError('P163_FAIL: compatibility block version marker missing')
    closes = list(re.finditer(r'\}\)\(\);', block))
    if not closes:
        raise RuntimeError('P163_FAIL: compatibility IIFE close missing')
    close_end = closes[-1].end()
    prefix = block[:closes[-1].start()]
    if 'function renderDashboard' not in prefix and 'renderDashboard' not in prefix:
        raise RuntimeError('P163_FAIL: unexpected compatibility block shape')
    replacement = block[close_end - 3:close_end]  # keep exact ');' tail? validated below
    # Preserve only the IIFE close itself.  The authoritative module remains byte-for-byte otherwise.
    replacement = block[closes[-1].start():closes[-1].end()]
    text = text[:a] + replacement + '\n\n' + text[b:]

    text = text.replace('window.RW_Dashboard={render:renderDashboard};', '')
    text = text.replace('window.RW_Items={render:renderItems};', '')
    text = re.sub(r'window\.RW_Items\s*=\s*RW_Items\s*;', 'window.RW_Items=RW_Items;', text)

    # De-duplicate governed/version markers but never synthesize any application fragment.
    text = text.replace(VERSION, '')
    text = text.replace(CLOSED, '')
    insert_at = text.index(AUTH) + len(AUTH)
    text = text[:insert_at] + '\n' + VERSION + '\n' + CLOSED + '\n' + text[insert_at:]

    if COMPAT in text:
        raise RuntimeError('P163_FAIL: compatibility surface remains')
    if text.count(AUTH) != 1 or text.count(DIAMOND) != 1:
        raise RuntimeError('P163_FAIL: ownership/diamond marker cardinality failed')
    if text.count(VERSION) != 1 or text.count(CLOSED) != 1:
        raise RuntimeError('P163_FAIL: governed/version marker cardinality failed')
    if 'window.RW_Dashboard={render:renderDashboard};' in text or 'window.RW_Items={render:renderItems};' in text:
        raise RuntimeError('P163_FAIL: legacy aliases remain')
    required = [
        'RW_ShellContext','RW_Auth','RW_Navigation','RW_Views','RW_OwnerLicense',
        'MAIN3','MAIN11','function main1Delegation(','var actions=',
        'post_stock_movement','get_trial_balance','get_profit_loss','get_balance_sheet',
        'edgeCall',DIAMOND
    ]
    missing = [x for x in required if x not in text]
    if missing:
        raise RuntimeError('P163_FAIL: required contracts missing: ' + ', '.join(missing))
    return text


class GateParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.scripts = []
        self.styles = 0
        self._script = None
    def handle_starttag(self, tag, attrs):
        attrs_d = dict(attrs)
        if tag.lower() == 'style':
            self.styles += 1
        if tag.lower() == 'script':
            self._script = {'src': attrs_d.get('src'), 'text': ''}
            self.scripts.append(self._script)
    def handle_data(self, data):
        if self._script is not None:
            self._script['text'] += data
    def handle_endtag(self, tag):
        if tag.lower() == 'script':
            self._script = None


def static_gate():
    text = TARGET.read_text(encoding='utf-8')
    p = GateParser(); p.feed(text); p.close()
    if not p.scripts:
        raise RuntimeError('STATIC_FAIL: no actual script tags parsed')
    if not any(s['src'] is None and s['text'].strip() for s in p.scripts):
        raise RuntimeError('STATIC_FAIL: no inline application script parsed')
    # Syntax-gate every inline script that is plausibly JavaScript.
    inline = [s['text'] for s in p.scripts if s['src'] is None and s['text'].strip()]
    for i, js in enumerate(inline):
        probe = ROOT / f'.p163_inline_{i}.js'; probe.write_text(js, encoding='utf-8')
        try:
            r = run(['node', '--check', str(probe)], check=False)
            if r.returncode != 0:
                raise RuntimeError('STATIC_FAIL: node syntax on inline script %d\n%s' % (i, r.stdout[-4000:]))
        finally:
            probe.unlink(missing_ok=True)
    return {'scripts': len(p.scripts), 'styles': p.styles, 'inline': len(inline)}


def browser_gate():
    port = 8123
    class Handler(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *args):
            pass
    os.chdir(ROOT)
    srv = socketserver.TCPServer(('127.0.0.1', port), Handler)
    t = threading.Thread(target=srv.serve_forever, daemon=True); t.start()
    time.sleep(0.5)
    js = """
    async ({page}) => {
      const errors=[];
      page.on('pageerror', e => errors.push('pageerror:'+e.message));
      page.on('console', m => { if(m.type()==='error') errors.push('console:'+m.text()); });
      await page.goto('http://127.0.0.1:8123/Current/PWA/New-main', {waitUntil:'networkidle', timeout:30000});
      const out=await page.evaluate(() => ({
        lang:document.documentElement.lang,
        auth:!!window.RW_Auth, nav:!!window.RW_Navigation, views:!!window.RW_Views,
        shell:!!window.RW_ShellContext, owner:!!window.RW_OwnerLicense,
        version:window.RW_PWA_RECONSTRUCTION_VERSION,
        diamond:document.documentElement.innerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),
        compat:document.documentElement.innerHTML.includes('RAWAEA MAIN2 COMPATIBILITY'),
        governed:document.documentElement.innerHTML.includes('MAIN2_GOVERNED_CLOSED:v1')
      }));
      return {out, errors};
    }
    """
    # Use a short Node launcher so Python does not need a Playwright import.
    launcher = ROOT / '.p163_browser_gate.mjs'
    launcher.write_text("""
import { chromium } from 'playwright';
const browser=await chromium.launch({headless:true});
const page=await browser.newPage(); const errors=[];
page.on('pageerror',e=>errors.push('pageerror:'+e.message));
page.on('console',m=>{if(m.type()==='error')errors.push('console:'+m.text())});
await page.goto('http://127.0.0.1:8123/Current/PWA/New-main',{waitUntil:'networkidle',timeout:30000});
const out=await page.evaluate(()=>({lang:document.documentElement.lang,auth:!!window.RW_Auth,nav:!!window.RW_Navigation,views:!!window.RW_Views,shell:!!window.RW_ShellContext,owner:!!window.RW_OwnerLicense,version:window.RW_PWA_RECONSTRUCTION_VERSION,diamond:document.documentElement.innerHTML.includes('RAWAEA 122 DIAMOND CONTRACT CLOSURE v1'),compat:document.documentElement.innerHTML.includes('RAWAEA MAIN2 COMPATIBILITY'),governed:document.documentElement.innerHTML.includes('MAIN2_GOVERNED_CLOSED:v1')}));
console.log(JSON.stringify({out,errors})); await browser.close();
""", encoding='utf-8')
    try:
        r = run(['node', str(launcher)], check=False)
        if r.returncode != 0:
            raise RuntimeError('BROWSER_FAIL: launcher exit\n'+r.stdout[-4000:])
        line = r.stdout.strip().splitlines()[-1]
        import json
        data = json.loads(line)
        o, errors = data['out'], data['errors']
        if errors: raise RuntimeError('BROWSER_FAIL: ' + repr(errors))
        expected = {'lang':'ar','auth':True,'nav':True,'views':True,'shell':True,'owner':True,
                    'version':'MAIN2-COMPLETE-SURGICAL-v1','diamond':True,'compat':False,'governed':True}
        bad=[k for k,v in expected.items() if o.get(k)!=v]
        if bad: raise RuntimeError('BROWSER_FAIL: '+repr(o))
        return o
    finally:
        launcher.unlink(missing_ok=True); srv.shutdown(); srv.server_close()


def update_state(before, after, static, browser):
    old = STATE.read_text(encoding='utf-8') if STATE.exists() else ''
    old = re.sub(r'\n## CTO P163 CLOSED — 2026-09-03\n.*?(?=\n## |\Z)', '\n', old, flags=re.S)
    old = re.sub(r'\n## GOLD / DIAMOND STATUS\n```text\n.*?```', '\n## GOLD / DIAMOND STATUS\n```text\nGOLD    = PROVEN\nDIAMOND = PROVEN\nCLOSED  = PROVEN\n```', old, flags=re.S)
    section = f"""

## CTO P163 CLOSED — 2026-09-03 (DIRECTLY VERIFIED)
- Target: `Current/PWA/New-main`
- Previous SHA-256: `{before}`
- Verified SHA-256: `{after}`
- P163 target-preserving surgery executed against the live latest `main`; no fragment reconstruction.
- Compatibility duplicate removed while its IIFE close was preserved; authoritative MAIN2 owner retained.
- Legacy Dashboard/Items aliases removed; exact governed/version markers normalized.
- Static HTMLParser gate: PASS (`scripts={static['scripts']}`, `styles={static['styles']}`, `inline={static['inline']}`).
- Node syntax gate: PASS.
- Browser Gold contract gate: PASS (`lang=ar`, Auth/Navigation/Views/Shell/Owner globals present, version exact, no page/console errors).
- Diamond closure marker preserved exactly once; compatibility marker absent at runtime.
- GOLD = PROVEN
- DIAMOND = PROVEN
- CLOSED = PROVEN
"""
    # Replace stale status block with proven status, and append authoritative event at end.
    old = re.sub(r'\n## GOLD / DIAMOND STATUS\n```text\n.*?```', '\n## GOLD / DIAMOND STATUS\n```text\nGOLD    = PROVEN\nDIAMOND = PROVEN\nCLOSED  = PROVEN\n```', old, flags=re.S)
    STATE.write_text(old.rstrip()+section, encoding='utf-8')


def commit_push(before):
    # Ensure the only persisted changes are target/state. Remove this executor and its one-shot workflow.
    if WORKFLOW.exists(): WORKFLOW.unlink()
    Path(__file__).unlink(missing_ok=True)
    run(['git','add','Current/PWA/New-main','CURRENT_STATE.md','.github/workflows/p163_final_close_20260903.yml','tools/_cto_p163_direct_20260903.py'])
    run(['git','rm','--cached','.github/workflows/p163_final_close_20260903.yml','tools/_cto_p163_direct_20260903.py'], check=False)
    status = git('status','--short').stdout
    allowed = {'M  Current/PWA/New-main','M  CURRENT_STATE.md'}
    lines = {x for x in status.splitlines() if x.strip()}
    if not lines.issubset(allowed):
        raise RuntimeError('P163_FAIL: unexpected staged changes: '+status)
    run(['git','config','user.name','cto-p163-executor'])
    run(['git','config','user.email','cto-p163-executor@users.noreply.github.com'])
    git('commit','-m','[P163-EXECUTED] close New-main target-preserving Gold Diamond')
    r = run(['git','push','origin','HEAD:main'], check=False)
    return r.returncode, r.stdout


def main():
    last = ''
    for attempt in range(1, 9):
        try:
            sync_latest()
            before = sha256(TARGET)
            text = TARGET.read_text(encoding='utf-8')
            edited = surgical_edit(text)
            if edited == text:
                raise RuntimeError('P163_FAIL: target did not change')
            TARGET.write_text(edited, encoding='utf-8')
            static = static_gate()
            browser = browser_gate()
            after = sha256(TARGET)
            if before == after:
                raise RuntimeError('P163_FAIL: SHA unchanged')
            update_state(before, after, static, browser)
            rc, out = commit_push(before)
            if rc == 0:
                print('P163_SUCCESS', before, after)
                return 0
            last = out[-4000:]
            print('P163_PUSH_RACE', attempt, last)
        except Exception as e:
            last = str(e)
            print('P163_RETRY', attempt, last)
    raise SystemExit('P163_ABORT after retries: '+last)

if __name__ == '__main__':
    main()
