# UI AND CONSUMER EVOLUTION

## Gold UI rule
Original UI behavior is a protected reference. A current UI is not production truth by itself. Gold/Diamond status requires original feature-set parity, owner intent, target contract, security, errors/loading/empty states, and runtime evidence.

## Critical consumers
Current source inventory identifies major PWA clients: main/core, picker, loader, receiver, unloader, returns, vouchers, van-sales, POS, telesales, driver and related supervisor/manager pages. fileciteturn231file0

## Picker
Original `picker.html` contract sends `{runsheet_code}` to `start-picking` with bearer auth and then opens the runsheet on success. This contract was used in recent forensic debugging and must remain stable unless a real consumer defect is proven.

## Current status
Consumer graph is PARTIAL in the 2026-08-21 readiness registry. Critical inventory/voucher/picking consumers are known, but full UI→Edge→RPC→DB parity is not yet proven ERP-wide. fileciteturn227file0

## Rule
Never repair a backend contract by casually modifying a Gold/Diamond UI. First prove the defect at the correct layer; then use surgical UI changes only if the UI contract itself is wrong.
