---
title: 'Story 4.2: Agreed Follow-Up Date Scheduling'
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

**Problem:** Customers who promise to pay need a scheduled follow-up date tracked so that Recovery Officers can prioritize daily work and avoid forgotten commitments. The system must surface overdue commitments and track whether promises were fulfilled.

**Approach:** Extend the `Interaction` and `PromiseToPay` models with `followUpDate` support. Implement `PromiseStatus` (scheduled / due today / overdue / fulfilled / broken) projected from the interaction's follow-up date relative to today. Add `isFollowUpDueOn(DateTime day)` and `isDueOn(DateTime day)` methods to `PromiseToPay`. Render follow-up commitments on the RecoveryScreen with visual cueing (color-coded status badges). Auto-update debt status to `ptp_scheduled` when a follow-up interaction is logged for an active (non-settled) debt.

## Boundaries & Constraints

**Always:**
- Follow-up dates must be on or after today (minimum date = DateTime.now)
- Only one active follow-up commitment per debt at a time
- Promised amount in interactions is informational only; actual balance is from the debt record
- Debt status auto-updates: `ptp_scheduled` when a follow-up is logged for active debts

**Never:**
- Never allow follow-up dates in the past (except when viewing historical interactions)
- Never expose delete/edit on existing follow-up dates without explicit admin override
- Never display promised amount as balance due (distinct from actual remaining balance)

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Schedule Follow-Up | User sets follow-up date on interaction | Debt status becomes `ptp_scheduled`; PromiseToPay shows `scheduled` status | Validation error if date < today |
| View Overdue | User views commitments past due date | PromiseToPay status shows `overdue`; visual warning badge | Graceful display if no follow-up set |
| Fulfill Commitment | User logs interaction with outcome 'Payment Received' | Debt status updates to `settled`; PromiseToPay shows `fulfilled` | Auto-commit debt settlement |
| Clear Commitment | User sets new follow-up on existing scheduled debt | Old commitment replaced; status transitions appropriately | State reset on new date selection |

</frozen-after-approval>

## Code Map

- `lib/features/recovery/domain/interaction.dart` -- `followUpDate` field, `isFollowUpDueOn()`, `effectiveContactDate`
- `lib/features/recovery/domain/promise_to_pay.dart` -- `PromiseStatus` (scheduled/dueToday/overdue/fulfilled/broken), `isDueOn()`, `status`, `daysUntilDue`
- `lib/features/recovery/domain/promise_status.dart` -- Status constants and all list
- `lib/features/recovery/presentation/interaction_controller.dart` -- saveInteraction with follow-up logic, refresh
- `lib/features/recovery/presentation/recovery_screen.dart` -- Status badge rendering on interaction table
- `lib/features/recovery/data/interaction_repository.dart` -- saveInteraction with debt status auto-update

## Tasks & Acceptance

**Execution:**
- [x] `followUpDate` field added to `Interaction` entity and `fromJson` / `toJson`
- [x] `PromiseStatus` enum with scheduled/dueToday/overdue/fulfilled/broken
- [x] `PromiseToPay` extended with `followUpDate`, `remainingBalanceCents`, `daysUntilDue`, `status` getters
- [x] `isFollowUpDueOn(DateTime day)` method on Interaction
- [x] `isDueOn(DateTime day)` method on PromiseToPay
- [x] Debt status auto-update: `ptp_scheduled` when follow-up interaction logged
- [x] RecoveryScreen table renders status badges (scheduled/dueToday/overdue/fulfilled)
- [x] `test/features/recovery/promise_to_pay_test.dart` -- Status and due-date calculations
- [x] `test/features/recovery/interaction_test.dart` -- Follow-up date and isDueOn tests

**Acceptance Criteria:**
- Given an interaction with a follow-up date, the PromiseToPay model correctly computes status (scheduled/dueToday/overdue/fulfilled/broken)
- Given a past due date, PromiseStatus returns `overdue`
- Given today is the follow-up date, PromiseStatus returns `dueToday`
- Given a future date, PromiseStatus returns `scheduled`
- When a payment-received interaction is logged, the associated debt status updates to `settled`

## Implementation Notes

- Days until due computed as `due.difference(today).inDays`; negative = overdue
- Follow-up dates stored as ISO 8601 strings in `interaction_logs.follow_up_date`
- Debt status transition: `active` → `ptp_scheduled` when first follow-up interaction logged
- Settlement: `ptp_scheduled` → `settled` when outcome = `Payment Received` on follow-up date
- Status badges use `AppColors.brandPrimary` (scheduled), `AppColors.accentSuccess` (fulfilled), `AppColors.accentError` (overdue/broken)