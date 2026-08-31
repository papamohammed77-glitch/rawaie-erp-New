# RAWAEA ERP — PHASE 10 DEPLOYMENT LINEAGE

**Date:** 2026-08-31  
**Phase:** 10 — Deployment / Artifact Lineage  
**Status:** CLOSED (investigation gate; deployment certification remains open)  
**Production mutation:** None.

## CURRENT GIT HEAD OBSERVED

`484d92ed2fb940386f6ba450cfc08fd1fd91babf`

Observed commit time: `2026-08-31T08:43:05Z`.

## CRITICAL PRODUCTION EDGE ARTIFACTS

| Function | Production version | Production SHA-256 | Production updated (UTC) | JWT gateway | Git source observed |
|---|---:|---|---|---|---|
| save-sales-invoice | 15 | `af97233812981ffead7e28eef1122bc12e2cb126d9f3abaabce99384e2be7950` | 2026-08-20 18:14:07 | enabled | `Current/Edge_Functions/save-sales-invoice` |
| receive-purchase | 12 | `bcf5f3d576cebfac3d7f3ce655515acfd33ac25cbbce376db42568da8e06aa06` | 2026-08-20 18:13:55 | enabled | `Current/Edge_Functions/receive-purchase` |
| complete-loading | 11 | `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286` | 2026-08-17 01:17:33 | enabled | `Current/Edge_Functions/complete-loading` |
| send-stock-voucher | 19 | `ec1b243418f93a5759cebfe21ea8b85e27235f7dc953c68a0242f180259303ef` | 2026-08-17 13:03:27 | disabled at platform gateway | `Current/Edge_Functions/send-stock-voucher` |

## SOURCE PARITY OBSERVATIONS

Direct current Git source was fetched for the four critical wrappers and direct Production Edge source was retrieved for the same functions.

The retrieved Production source for `save-sales-invoice`, `receive-purchase`, and `complete-loading` matches the current Git file content at the wrapper level, including authentication, company context resolution, idempotency/operation handling, and RPC delegation.

`send-stock-voucher` also has the same current wrapper behavior: it performs its own Authorization/JWT validation via Supabase Auth, resolves `users.auth_id` to company context, and calls `send_stock_voucher_atomic`. Platform `verify_jwt=false` is therefore a deployment configuration difference, not by itself proof of missing authentication; the function implements custom authentication in its body.

## IMPORTANT LINEAGE LIMITATION

Git blob SHA values are not directly comparable to Supabase `ezbr_sha256` deployment hashes because they represent different hashing contexts. A true cryptographic deployment lineage proof requires either:

- the exact deployed source hash generated from identical source bytes and a documented hashing algorithm; or
- a CI/CD release artifact mapping a specific Git commit/blob to the deployed Edge Function version/SHA.

No such complete release mapping was proven in this phase.

## DEPLOYMENT DRIFT OBSERVATION

The current Git `main` branch is actively changing on 2026-08-31, while the inspected critical Edge Function deployments were last updated on 2026-08-17 through 2026-08-20.

This does **not** prove that those functions are stale: the functions may have been intentionally released from an earlier commit and remain functionally identical. It does prove that Git `main` and Production Edge deployment do not advance in lockstep, so current Git HEAD cannot be treated as a Production deployment record.

## SPECIAL DEPLOYMENT OBSERVATION — 410 ENDPOINTS

Production currently contains historical/test-style Edge endpoints that are actively requested and return HTTP 410. These endpoints are not to be removed until their callers/consumers are identified and the retirement contract is proven.

## DEPLOYMENT GATE STATUS

### Proven

- Production Edge Function instances exist and are ACTIVE for the critical operations examined.
- Production versions and deployment SHA-256 values are directly observable.
- Current Git source exists for the same critical wrappers.
- Source behavior at wrapper level is aligned for the critical functions examined.
- Custom authentication is present in `send-stock-voucher` despite platform JWT verification being disabled.

### Not proven

- Complete Git commit → deployed function release mapping for every critical function.
- Exact deployed source provenance for every function.
- Cloudflare Pages deployment commit and current production application artifact.
- Whether every current `main` change has a corresponding intended Production rollout or is intentionally unshipped.
- Full rollback points for application and Edge deployments.

## EXIT GATE

`PHASE 10 CLOSED`

Deployment artifacts and lineage evidence have been inventoried and the remaining provenance gap has been made explicit. No deployment was changed.
