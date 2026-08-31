# RAWAEA ERP — PHASE 1 SOURCE AUTHORITY DISCOVERY

**Date:** 2026-08-31  
**Phase:** 1 — Source Authority Discovery  
**Status:** CLOSED  
**Mission Protocol:** `doc/Draft/medhat/RAWAEA ERP — MASTER CTO ONBOARDING & CONTINUITY PROTOCOL.md`

## Authority Rule

`Production Current State > Git Current State > Historical Source > Reports > Memory`

This document records the evidence established for Phase 1 only. It is not a substitute for the required fresh Production Snapshot in Phase 2.

## SOURCE AUTHORITY MAP

| Source | Type | Current? | Historical? | Authoritative For | Confidence |
|---|---|---:|---:|---|---|
| Supabase project `fiilmooggumokxanwiyx` / `SMART ERP` | Production database/control plane | YES | NO | Current Production runtime/database state | HIGH |
| GitHub `papamohammed77-glitch/rawaie-erp-New`, branch `main` | Current source repository | YES | NO | Current Git source and canonical tracked artifacts | HIGH |
| GitHub `papamohammed77-glitch/rawaie-erp-review`, branch `main` | Historical repository | NO | YES | Historical architecture, prior code, forensic evidence, migrations | HIGH |
| `rawaie-erp-New/Current/` | Current Git artifact set | YES | NO | Current application, Edge Function source, CTO evidence | HIGH |
| `rawaie-erp-New/Original/` | Historical/canonical source archive | NO | YES | Historical/original application artifacts and reconstruction evidence | HIGH |
| `rawaie-erp-New/Evidence/` | Evidence repository | MIXED | YES | Recorded forensic evidence; must be revalidated against Production when claiming current truth | MEDIUM-HIGH |
| `rawaie-erp-New/SQL_Evidence/` | SQL evidence archive | MIXED | YES | Historical/database investigation evidence | MEDIUM-HIGH |
| `rawaie-erp-New/CTO/`, `Current/CTO/` | Governance/continuity records | MIXED | YES | Historical and current engineering decisions/closure records | MEDIUM-HIGH |
| Supabase Edge Functions in `fiilmooggumokxanwiyx` | Deployed runtime artifacts | YES | NO | Current deployed function existence/version/status | HIGH |
| `CURRENT_STATE.md` | Current-state navigation record | YES | YES | Operational checkpoint/navigation; not a replacement for fresh Production proof | MEDIUM-HIGH |
| Historical reports/prompts | Reports / historical evidence | NO | YES | Leads, historical claims, reconstruction context | MEDIUM |
| Model memory | Context only | NO | YES | Navigation only; never authoritative | LOW |

## DIRECTLY VERIFIED REPOSITORY FACTS

- `rawaie-erp-New` exists, is public, is not archived, and its default branch is `main`.
- The current repository contains dedicated `Current`, `Original`, `CTO`, `Evidence`, `Inventory`, `Rescue`, `SQL_Evidence`, `Governance`, and `doc` areas.
- The historical repository `rawaie-erp-review` exists and contains `Architecture`, `Edge_Functions`, `Edge_Function_Reports`, `PWA`, `SQL_Evidence`, `docs`, and `supabase`.
- The current `main` branch has active reconstruction/forensic branches and multiple open verification PRs; these are evidence of ongoing engineering history, not proof that their artifacts are deployed.
- The latest observed `main` commit at Phase 1 execution time is `a9d1c746dc99734b4d056c2da40258e0d9f270b7` (`fix: use verified open-script fragment composition for New-main`).

## DIRECTLY VERIFIED PRODUCTION FACTS

- Supabase project `fiilmooggumokxanwiyx` is named `SMART ERP`, region `eu-west-1`, and status `ACTIVE_HEALTHY`.
- Supabase also exposes a separate project `hfzznsiprnwkpayskzhu` named `rawaea-staging`; it is therefore treated as staging, not Production, pending later runtime/deployment verification.
- Production Edge Functions are directly discoverable in the `SMART ERP` project, including canonical operational functions such as `save-sales-invoice`, `receive-purchase`, `send-stock-voucher`, `receive-stock-voucher`, `complete-picking`, `complete-loading`, `complete-return`, `complete-order-delivery`, `unload-runsheet`, and accounting/reporting functions.
- Deployed Edge Function versions and SHA-256 artifacts are observable directly from Supabase; these are deployment evidence and must be compared with Git source during the later Deployment Lineage phase.

## CURRENT AUTHORITY LOCATION

### Current Production Truth
`Supabase / SMART ERP / fiilmooggumokxanwiyx`

### Current Git Truth
`GitHub / rawaie-erp-New / main`

### Current Application / Edge Source
`rawaie-erp-New/Current/`

### Historical / Original Source
`rawaie-erp-New/Original/` and `rawaie-erp-review/main`

### Historical / Forensic Evidence
`rawaie-erp-New/Evidence/`, `SQL_Evidence/`, `Current/CTO/`, and `rawaie-erp-review/Edge_Function_Reports/`, `Architecture/`, `SQL_Evidence/`, `docs/`

### Deployment Evidence
Supabase deployed Edge Function inventory/version/SHA data; deployment lineage is intentionally not claimed closed in Phase 1.

## IMPORTANT CONFLICT / DRIFT OBSERVATION

Existing continuity records contain older Git snapshots. The repository has advanced since those records were written. Therefore older `CURRENT_STATE.md` / baseline values are navigation evidence only until re-synchronized through Phase 2+ fresh snapshots.

## PHASE 1 UNKNOWNs

The following are intentionally NOT resolved in Phase 1:

- Exact current Production schema/function/trigger/policy/index/migration inventory at the Phase 1 timestamp.
- Exact current business-row counts and integrity checks at the Phase 1 timestamp.
- Exact runtime logs/errors/current consumers at the Phase 1 timestamp.
- Complete Git-to-Production deployment lineage for every critical artifact.
- Historical contract classification for every critical behavior.
- Complete system dependency graph.

These are Phase 2 and later investigation obligations.

## EXIT GATE

`PHASE 1 CLOSED`

Phase 1 is considered closed because the principal current, historical, evidence, and deployment source families have been identified directly, the current Production candidate has been verified against the Supabase project registry, and the current Git head has been independently observed.

No Production data or application behavior was modified during Phase 1.
