# GIT CHANGE LEDGER

## Current HEAD at memory rebuild start
`579722996367998327fda7340408f1ad32ce955f`

Commit date: 2026-08-23 03:36:08 UTC
Message: `Add memory certification and current state`

## Historical execution anchors
| Area | Commit / SHA | Status in current context |
|---|---|---|
| Manual Voucher execution | `8607614cd647674ede009182c439f229d9d038b7` | Historical anchor |
| DirectReturn correction | `6c8e83697f8182790d79a019cb3483494c0b940a` | Historical anchor |
| Voucher handler repair | `968f8ec6123a8b55256073e16b61f40c408826ab` | Historical anchor |
| Supervisor company-context fix | `f0b668bdf12615bc8965dd8f1090a4079b8da814` | Historical anchor |
| Supervisor team scope | `36db0401e9ab4e14932272687440689de52477fa` | Historical anchor |
| Supervisor re-execution | `8966d8b1ccc2388ee9a6a25688fcadd5b62d5d98` | Historical anchor |
| Supervisor team table | `83f6b7f36ff7a8445bc76100b66cf60395838639` | Historical anchor |
| Team read scope | `5c6c0612f6cc7473c38853c26d6e4f7bb6d1b249` | Historical anchor |
| Inventory source alignment | `bd66bab8a4ad55f7df32f24c75a82133cf7b1688` | Historical anchor |
| POS-style voucher workspace | `4cfcee850e088c2ef366411dd9c255bd755771a8` | Historical anchor |
| Voucher recovery/Auth | `a7aaa2cc1f326709a0623dfd2246f22c4af3c8f1` | Historical anchor |
| Main memory handoff package | `579722996367998327fda7340408f1ad32ce955f` | Current package base |

## Current source facts
- Current `Current/Edge_Functions/start-picking` blob SHA: `c34a64fad53524720d80eede9d4848612a334b5f`.
- Current Git `start-picking` uses `users.auth_id`, matching current Production v33.
- Current Memory_Transfer files are canonicalized on `main`.

## Required status labels
- Git file changed = YES/NO
- Migration created = YES/NO
- Migration applied = YES/NO
- Edge deployed = YES/NO
- Runtime verified = YES/NO

A Git SHA is never treated as Production deployment proof without a Production deployment/version record.

## Current Git-wide limitation
A complete commit-by-commit history of the repository is not re-indexed here. This ledger records all high-value anchors exposed by the forensic sources and the current package commits. Therefore `FULL GIT HISTORY = PARTIALLY VERIFIED`.