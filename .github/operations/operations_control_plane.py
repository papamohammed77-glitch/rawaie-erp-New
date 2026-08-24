#!/usr/bin/env python3
import hashlib
import json
import os
import pathlib
import subprocess
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone

OPS = pathlib.Path("doc/Draft/Operations_Team")
CONTROL = OPS / ".control"
LEDGER = CONTROL / "ledger.json"
INBOX = OPS / ".scheduler_inbox.md"
STATE = OPS / ".scheduler_state"

OWNER_RULES = {
    "MEDHAT": "Medhat",
    "KHALID": "Khalid",
    "HYTHAM": "Hytham",
}

TERMINAL = {"CLOSED", "SUPERSEDED"}
ACTIVE = {"NEW", "ACKNOWLEDGED", "IN_PROGRESS", "WAITING_FOR_EXECUTION", "READY_FOR_REVIEW", "REVIEWED", "REVISION_REQUIRED"}


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_ledger():
    CONTROL.mkdir(parents=True, exist_ok=True)
    if not LEDGER.exists():
        return {"schema_version": 1, "updated_at": now(), "tasks": {}}
    return json.loads(LEDGER.read_text(encoding="utf-8"))


def save_ledger(data):
    data["updated_at"] = now()
    LEDGER.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def owner_for(name):
    upper = name.upper()
    for prefix, owner in OWNER_RULES.items():
        if upper.startswith(prefix + "_"):
            return owner
    return "Medhat"


def task_id(name, source_commit):
    digest = hashlib.sha256(f"{name}|{source_commit}".encode()).hexdigest()[:16]
    return f"OPS-{digest}"


def control_files():
    files = []
    for p in sorted(OPS.iterdir() if OPS.exists() else []):
        if not p.is_file() or p.name.startswith("."):
            continue
        if p.name in {"test"}:
            continue
        source_commit = git("log", "-1", "--format=%H", "--", str(p))
        files.append((p.name, str(p), source_commit))
    return files


def dispatch(task):
    url = os.environ.get("AGENT_RUNTIME_URL", "").strip()
    token = os.environ.get("AGENT_RUNTIME_TOKEN", "").strip()
    if not url:
        return False, "AGENT_RUNTIME_URL not configured"
    payload = json.dumps({"type": "operations_task", "task": task}, ensure_ascii=False).encode()
    req = urllib.request.Request(url, data=payload, method="POST")
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            if 200 <= resp.status < 300:
                return True, body[:2000]
            return False, f"HTTP {resp.status}: {body[:500]}"
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}: {e.read().decode('utf-8', errors='replace')[:500]}"
    except Exception as e:
        return False, str(e)


def main():
    ledger = load_ledger()
    discovered = control_files()
    dispatched = []
    changed = False

    for name, path, source_commit in discovered:
        tid = task_id(name, source_commit)
        task = ledger["tasks"].get(tid)
        if task is None:
            task = {
                "message_id": tid,
                "task_id": tid,
                "owner": owner_for(name),
                "status": "NEW",
                "created_at": now(),
                "processed_at": None,
                "source_file": path,
                "source_commit": source_commit,
                "reply_file": None,
                "dispatch_attempts": 0,
                "last_dispatch_at": None,
                "last_dispatch_result": None,
            }
            ledger["tasks"][tid] = task
            changed = True

        if task["status"] in TERMINAL:
            continue

        if task["status"] == "NEW":
            ok, result = dispatch(task)
            task["dispatch_attempts"] += 1
            task["last_dispatch_at"] = now()
            task["last_dispatch_result"] = result
            task["processed_at"] = now() if ok else None
            task["status"] = "ACKNOWLEDGED" if ok else "WAITING_FOR_EXECUTION"
            changed = True
            dispatched.append((tid, ok, result))

    save_ledger(ledger)

    lines = [
        "# Operations Scheduler Inbox",
        "",
        f"Last poll: {now()}",
        "",
        "## Control Plane",
        f"- discovered files: {len(discovered)}",
        f"- dispatched this run: {len(dispatched)}",
        "- duplicate protection: task_id = SHA256(source_file + source_commit)",
        "- agent execution claim: only ACKNOWLEDGED/WAITING_FOR_EXECUTION after actual Agent Runtime HTTP response",
        "",
        "## Dispatch Results",
    ]
    if not dispatched:
        lines.append("- No NEW tasks dispatched.")
    else:
        for tid, ok, result in dispatched:
            status = "DISPATCHED" if ok else "NOT DISPATCHED"
            lines.append(f"- `{tid}` — {status} — {result}")
    lines += [
        "",
        "## Team Contract",
        "- Medhat: review NEW execution reports, verify evidence, and issue directives.",
        "- Khalid/Hytham: execute only assigned NEW/REVISION_REQUIRED tasks and return evidence.",
        "- No CLOSED/SUPERSEDED task is reprocessed.",
        "- This workflow does not claim AI execution unless Agent Runtime returned success.",
    ]
    INBOX.write_text("\n".join(lines) + "\n", encoding="utf-8")

    current = "\n".join(f"{n}|{c}" for n, _, c in discovered) + "\n"
    STATE.write_text(hashlib.sha256(current.encode()).hexdigest(), encoding="utf-8")

    if changed:
        subprocess.run(["git", "config", "user.name", "Operations Scheduler"], check=True)
        subprocess.run(["git", "config", "user.email", "operations-scheduler@users.noreply.github.com"], check=True)
        subprocess.run(["git", "add", str(LEDGER), str(INBOX), str(STATE)], check=True)
        subprocess.run(["git", "commit", "-m", "ops: update operations control ledger"], check=False)
        subprocess.run(["git", "push"], check=True)


if __name__ == "__main__":
    main()
