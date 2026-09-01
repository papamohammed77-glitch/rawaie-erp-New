# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 124+ / master governance requires direct evidence, explicit state logging, preservation of historical reports, and no false closure.
- This exceptional repair round permits direct progress toward Gold/Diamond, but product changes must still be evidenced and target-scoped.
- Historical Hany reports are preserved and must not be deleted or overwritten.

## P131 — FORENSIC CONTINUATION — 2026-09-01
### P131-01 — MEMORY_AND_HISTORY_RECONCILIATION
- Read `MASTER - RAWAEA ERP.md` from Git before initiating this round's new product mutation work.
- Re-read `CURRENT_STATE.md` before acting; latest declared state was P130 with target blob `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- Searched `doc/Draft/Hany`; current Git contains `تقرير تنفيذي 11.md` as the latest numbered Hany report discovered.
- Re-checked the requested Prompt 124+appendix path. Direct Git retrieval remains unavailable as a tracked blob; this limitation is preserved rather than fabricated.

### P131-02 — DIRECT_SOURCE_FORENSICS
- Current `New-main` blob was retrieved directly through the Git Blob API.
- Direct search across the repository confirms the historical route contract in `Current/PWA/main/main10.md`:
  - `reports-dashboard` → `window.RW_Reports.renderDashboard`
  - `reports-detailed` → `window.RW_Reports.renderDetailedReports`
  - `reports-comprehensive` → `window.RW_Reports_Comprehensive.render`
- Direct search also confirms `Current/PWA/main/main1.md` contains all three specialized report views in its menu tree.
- Commit `31d4dc3afc4e59dfd9fc5ec90c4c982ee4d310dc` directly shows the later `RAWAEA 122 DIAMOND CONTRACT CLOSURE v1` replacing the effective route table and retaining only `reports:[window.RW_Reports,'render']`; therefore the previously documented root cause is independently corroborated from Git history.

### P131-03 — FAILED_EXECUTION_PATHS_NOT_REPEATED
- Historical clean-room execution `99726102288` remains unavailable through the artifact endpoint; no artifact can be claimed.
- Historical workflow run `33508781448` has zero artifacts and previously had zero Jobs; it is not treated as target execution evidence.
- The old workflow path was not rerun in this round.
- Container network access again could not materialize the target blob locally; no reconstruction was attempted.

### P131-04 — HISTORICAL_ARTIFACT_REUSE_ASSESSMENT
- `Current/PWA/main/main10.md` is a real historical artifact containing the desired report route mappings, but it is a module file, not a full `Current/PWA/New-main` replacement. Replacing `New-main` with it would be destructive and is explicitly rejected.
- No already-verified complete `New-main` blob with the corrected late route table has yet been located.
- Direct Git low-level blob/tree tooling exists, but a safe mutation still requires exact full current blob content or an existing complete corrected blob.

### P131-05 — TARGET_MUTATION_STATUS
- `Current/PWA/New-main` has NOT been mutated in P131.
- No clean-room reconstruction was performed.
- No `Current/PWA/main.html` change was performed.
- No Supabase production mutation was performed.
- Gold/Diamond closure remains UNPROVEN.

### P131-06 — NEXT_AUTHORIZED_ACTION
- Locate a complete historical `New-main` blob/commit that contains both the current target contracts and the corrected specialized report navigation, or establish a trustworthy exact-content transport path for the current blob.
- Before any target mutation, record a new pre-mutation state event.
- Apply only the proven navigation correction; preserve all unrelated target content byte-for-byte where technically possible.
- Verify blob/tree/commit identity independently, then perform runtime verification before any Gold/Diamond claim.
- Do not repeat the failed zero-job workflow path or clean-room reconstruction path.

### P131-07 — SURGICAL_EXECUTOR_PREPARED
- Created `.github/workflows/p131-new-main-navigation-surgical.yml` in commit `1786eaf9e854dfb2599b5aca63832682ca7234a0`.
- The executor always creates a visible Job. It performs no target mutation unless the triggering commit message explicitly contains `[P131-EXECUTE]`.
- When explicitly triggered, the Job reads `Current/PWA/New-main` from the checkout, applies only two exact string substitutions in the existing file, runs `node --check`, verifies the specialized report routes and permission aliases, then commits and pushes only `Current/PWA/New-main`.
- This executor is an operational mechanism only; it is not treated as Gold/Diamond evidence.

### P131-08 — EXPLICIT_EXECUTION_TRIGGER_RECORDED
- `CURRENT_STATE.md` was updated immediately before the target mutation trigger.
- Trigger commit: `[P131-EXECUTE] Record pre-mutation state before surgical New-main repair`.
- The target blob immediately before trigger remains `d657d6e4bdd90a9b60f658a8bf28560e1b10f755` unless the executor reports otherwise.
- The only authorized target mutation in this execution is restoration of the three specialized report route aliases plus their shared `reports` permission aliases.
- The executor must abort on missing anchors, malformed outer HTML, inline-runtime count mismatch, syntax failure, or missing required routes.

### P131-09 — PR_EXECUTION_CHANNEL_HARDENED
- The first push-trigger attempt produced no workflow run and was not repeated.
- Executor commit `9991a22f67f3cc6df19999b474c56a4092f0482b` converts the executor to a `pull_request`-based execution path.
- The executor now checks the latest branch commit message from Git, executes only when `[P131-EXECUTE]` is present, checks out the PR head branch explicitly, and pushes the surgical target commit back to that branch.
- This path is intended to make the Job observable and prevent accidental direct mutation of `main` during the surgical execution step.

### P131-10 — ISOLATED_BRANCH_CREATED
- Created branch `p131-surgical-report-nav-20260901` from main commit `0bfc1ef202b4705ceaa34b9cdda99d1ffe273a08`.
- The branch is the isolated execution surface for the surgical target repair.
- `main` remains unchanged with respect to `Current/PWA/New-main` at this checkpoint.

### P131-11 — PR_EXECUTION_TRIGGER_RECORDED
- The next branch commit will carry `[P131-EXECUTE]` and is the explicit trigger for the PR workflow.
- The pre-trigger target remains the frozen blob `d657d6e4bdd90a9b60f658a8bf28560e1b10f755` until the workflow itself reports a target commit.
- No target mutation is authorized outside the PR workflow execution.

## NEXT AUTHORIZED REPAIR
### P131 — DIRECT GIT BLOB/TREE TARGET MUTATION
Goal: apply the already-proven surgical correction to the existing `Current/PWA/New-main` blob without reconstruction.

Required sequence:
1. trigger the PR workflow from this isolated branch;
2. inspect the Job, steps, and logs directly;
3. confirm the target mutation commit and resulting blob SHA on the PR branch;
4. update `CURRENT_STATE.md` immediately after the target mutation;
5. independently verify target marker/hash/static contracts;
6. only then fast-forward `main` to the verified branch tip;
7. perform runtime verification and only then assess Gold/Diamond closure.

Do not revert to clean-room rebuild.
Do not delete historical reports.
Do not treat workflow success/failure as target runtime evidence.