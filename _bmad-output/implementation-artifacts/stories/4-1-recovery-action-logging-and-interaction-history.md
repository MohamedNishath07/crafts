---
title: 'Story 4.1: Recovery Action Logging & Interaction History'
type: 'feature'
created: '2026-10-26'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/planning-artifacts/architecture/architecture-crafts-2026-10-14/ARCHITECTURE-SPINE.md'
  - '_bmad-output/implementation-artifacts/stories/3-3-payment-history-and-transaction-reference-ledger.md'
---
<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Recovery Officers need a complete, searchable history of all customer interactions (calls, visits, emails, SMS) with outcomes, follow-up dates, and promised amounts so that daily recovery work is transparent and auditable.

**Approach:** Extend `RecoveryScreen` with interaction logging dialog supporting 4 contact channels (call/field_visit/email/sms), outcome selection, follow-up date picker, promised amount input, and notes. Implement `filteredInteractionsProvider` with search by debtId/txn ref, and `paginatedInteractionsProvider` with configurable page sizes. Display interaction date, customer, channel label, outcome, follow-up date, and promised amount in a data table. Keep records append-only: the repository exposes only fetch and insert, never update or delete.

## Boundaries & Constraints

**Always:**
- Strictly isolate interactions by `tenant_id`
- Support real-time filtering on search input and paginated browsing
- Display channel labels in human-readable form (Call, Visit, Email, SMS)
- Show dates in ISO `YYYY-MM-DD` format and amounts as `$X,XXX.XX`
- Support follow-up date scheduling (FR-09)

**Never:**
- Never expose update or delete actions on interaction records
- Never expose cross-tenant interaction history
- Never block the UI thread during search filtering

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| History Loading | User visits `/recovery` | Paginated table lists newest interactions first | Error banner if fetch fails |
| Search (Match) | User types debt ID or channel | Table filters to matching interactions | Empty table on no match |
| Search (Clear) | User clears search input | Full paginated history restored | Instant re-render |
| Follow-Up Date | User selects a date | Interaction shows promised amount and due date | Validation error if date is past |
| Channel Selection | User selects call/email/sms | Outcome options update accordingly | Default to 'No Response' |

</frozen-after-approval>

## Code Map

- `lib/features/recovery/presentation/recovery_screen.dart` -- RecoveryActivitiesScreen with Log Action dialog
- `lib/features/recovery/presentation/widgets/log_action_dialog.dart` -- Channel, outcome, follow-up date, promised amount, notes
- `lib/features/recovery/presentation/interaction_controller.dart` -- AsyncNotifier with saveInteraction, refresh
- `lib/features/recovery/data/interaction_repository.dart` -- fetchInteractions, saveInteraction
- `lib/features/recovery/data/reminder_repository.dart` -- fetchReminderSettings, saveReminderSettings, createReminderDispatch
- `supabase/migrations/20261014000000_initial_schema.sql` -- interaction_logs table with RLS policies

## Tasks & Acceptance

**Execution:**
- [x] Interaction dialog with 4 channel chips (call/field_visit/email/sms)
- [x] Outcome dropdown with 7 standard outcomes
- [x] Follow-up date picker with calendar UX
- [x] Promised amount input (cents)
- [x] Notes field with text validation
- [x] `filteredInteractionsProvider` -- Search by debtId, channel, outcome
- [x] `paginatedInteractionsProvider` -- Configurable page size and page index
- [x] RecoveryScreen table renders channel, outcome, date, amount, method, follow-up with footer counter
- [x] Immutability: no update/delete UI or repository methods; enforced by RLS
- [x] `test/features/recovery/interaction_controller_test.dart` -- Search and pagination tests
- [x] `test/features/recovery/recovery_screen_test.dart` -- History rendering and dialog tests

**Acceptance Criteria:**
- Given the Recovery screen, a paginated table lists interaction date, channel, outcome, follow-up date, promised amount, and notes
- Given the interactions table, records are strictly immutable (no UPDATE/DELETE actions exposed)

## Implementation Notes

- Search is client-side over the fetched tenant interaction list for instant (<100ms) filtering
- Channel codes (`call`, `field_visit`, `email`, `sms`) map to labels in `InteractionChannel.label`
- Outcome codes map to `InteractionOutcome.all` labels
- Follow-up dates are stored as ISO strings and displayed as `MMM DD, YYYY`
- Promised amounts are in integer cents; display as `$X,XXX.XX`
- Receipt/referencing is auto-handled by the interaction model