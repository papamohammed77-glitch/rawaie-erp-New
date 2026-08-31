# RAWAEA ERP — PHASE 11 RUNTIME DRIFT & INCIDENT FORENSICS

**Date:** 2026-08-31  
**Phase:** 11 — Runtime Drift / Incident Forensics  
**Status:** CLOSED  
**Production mutation:** None.

## INCIDENT OBSERVED

Fresh Production Edge logs show repeated HTTP 410 responses from historical/test-style endpoints, including:

- `auth-login-verification-20260818`
- `complete-picking-picker-http-gate-20260818`
- `owner-recovery-20260818`

The requests occur in the current runtime window, including calls around `2026-08-31T08:42Z`.

## CONSUMER ATTRIBUTION

Repository evidence strongly connects at least some 410 traffic to historical verification workflows rather than active product traffic.

The current repository contains `.github/workflows/medhat-auth-login-verification-20260818.yml`, which directly targets `auth-login-verification-20260818` as a CI verification endpoint. fileciteturn81file0L2-L2

The current repository also contains `.github/workflows/medhat-owner-recovery-pr-20260818.yml`, which targets `owner-recovery-20260818` for owner recovery verification. fileciteturn82file0L2-L2

A repository search did not return a current application-source reference for these retired endpoints beyond governance/workflow/report artifacts for the examples examined. This reduces, but does not eliminate, the possibility of an active browser/service consumer.

## INTERPRETATION

The 410s are therefore classified as **RUNTIME DRIFT / STALE VERIFICATION TRAFFIC**, not as a confirmed primary application outage.

This distinction is important: the server is intentionally returning 410 for retired endpoints, while old automation still requests them. Removing the endpoints or changing their behavior without first retiring the callers could break CI or historical recovery tooling.

## REQUIRED CLEANUP PATH

1. Inventory all GitHub workflows, scheduled jobs, external monitors, and application references to each 410 endpoint.
2. Classify each caller as active production dependency, CI-only, historical forensic test, or dead artifact.
3. Retire or update confirmed stale callers.
4. Keep the 410 contract until all callers are accounted for; do not resurrect retired endpoints merely to make monitoring green.
5. Recheck runtime logs after caller retirement.

## SECURITY NOTE

The inspected recovery workflow contains embedded verification material in repository source. No secret/token from that file was used or replayed during this investigation. Credential material in historical verification artifacts must be treated as sensitive operational evidence and reviewed separately.

## OTHER RUNTIME ERRORS

Recent PostgreSQL logs contain several query/inspection-related ERROR records, including invalid column/function/aggregate references. These correlate with investigation activity and are not promoted to application incidents without endpoint/application attribution.

API and Auth log queries returned no current rows in the connector response.

## INCIDENT SEVERITY

`MEDIUM — Operational Hygiene / CI Drift`

There is no current evidence from this incident alone of customer-facing application failure or unauthorized data access. The issue remains significant because stale automation can obscure real monitoring signals and can create false-negative/false-positive operational assessments.

## EXIT GATE

`PHASE 11 CLOSED`

Observed runtime drift was correlated with repository verification artifacts, the 410 behavior was classified without destructive cleanup, and the safe retirement path was established. No Production endpoint or workflow was modified.
