---
title: 'Story 3.3: Payment History & Transaction Reference Ledger'
type: 'feature'
created: '2026-10-19'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/planning-artifacts/architecture/architecture-crafts-2026-10-14/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/ux-designs/ux-crafts-2026-10-14/EXPERIENCE.md'
  - '_bmad-output/planning-artifacts/prds/prd-crafts-2026-10-14/prd.md'
  - '_bmad-output/implementation-artifacts/stories/3-1-payment-recording-form-for-full-and-partial-settlements.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Finance Officers need a complete, searchable history of all payments with transaction references so that daily reconciliations are transparent and auditable.

**Approach:** Extend `PaymentsScreen` with real-time text search (transaction reference, receipt number, debt id) and configurable pagination (25/50/100 per page). Display payment date, related debt, amount, method label, transaction reference, and receipt number in a data table. Keep records immutable: the repository exposes only fetch and insert, never update or delete.

## Boundaries & Constraints

**Always:**
- Strictly isolate payment history by `tenant_id`.
- Support real-time filtering on search input and paginated browsing.
- Display method labels in human-readable form (Cash, Bank Transfer, Check, Mobile Money).
- Show dates in ISO `YYYY-MM-DD` format and amounts as `$X,XXX.XX`.

**Never:**
- Never expose update or delete actions on payment records.
- Never expose cross-tenant payment history.
- Never block the UI thread during search filtering.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| History Loading | User visits `/payments` | Paginated table lists newest payments first | Error banner if fetch fails |
| Search (Match) | User types "WIRE" or "RCP-" | Table filters to matching transaction refs / receipts | Empty table on no match |
| Search (Clear) | User clears search input | Full paginated history restored | Instant re-render |
| Pagination | Next page / page size change | Slice updates with counter | Next disabled on last page |

</frozen-after-approval>

## Code Map

- `lib/features/payments/presentation/payment_controller.dart` -- `filteredPaymentsProvider`, `paginatedPaymentsProvider`, page size/index notifiers.
- `lib/features/payments/presentation/payments_screen.dart` -- History table with date, debt, amount, method, txn ref, receipt columns plus pagination footer.
- `supabase/migrations/20261014000000_initial_schema.sql` -- `REVOKE UPDATE, DELETE ON public.payments` guarantees immutability.

## Tasks & Acceptance

**Execution:**
- [x] `filteredPaymentsProvider` -- Search by transaction reference, receipt number, and debt id.
- [x] `paginatedPaymentsProvider` -- Configurable page size and page index.
- [x] `PaymentsScreen` -- Table renders date, debt, amount, method, txn ref, receipt with footer counter.
- [x] Immutability: no update/delete UI or repository methods; enforced by RLS.
- [x] `test/features/payments/payment_controller_test.dart` -- Search and pagination tests.
- [x] `test/features/payments/payments_screen_test.dart` -- History rendering and dialog tests.

**Acceptance Criteria:**
- Given the Payments screen, a paginated table lists payment date, amount paid, payment method, transaction reference, and recording details.
- Given the payments table, records are strictly immutable (no UPDATE/DELETE actions exposed).

## Implementation Notes

- Search is client-side over the fetched tenant payment list for instant (<100ms) filtering.
- Method codes (`cash`, `bank_transfer`, `check`, `mobile_money`) map to labels in `_methodLabel`.
- Receipt numbers are auto-generated (`RCP-<millis>`) with a per-tenant unique constraint.
