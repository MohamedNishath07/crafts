---
title: 'Story 3.1: Payment Recording Form for Full & Partial Settlements'
type: 'feature'
created: '2026-10-19'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/planning-artifacts/architecture/architecture-crafts-2026-10-14/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/ux-designs/ux-crafts-2026-10-14/EXPERIENCE.md'
  - '_bmad-output/planning-artifacts/prds/prd-crafts-2026-10-14/prd.md'
  - '_bmad-output/implementation-artifacts/epic-2-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Finance Officers and Administrators need to record full and partial customer payments (cash, bank transfer, check, mobile money) against outstanding debts, with transaction references and receipt generation, so that financial ledgers stay accurate.

**Approach:** Build a dedicated Payments module in `PaymentsScreen` backed by `PaymentRepository` and Riverpod `PaymentController`. Provide a "Record Payment" modal (`RecordPaymentDialog`) with debt selection dropdown (outstanding debts only), principal/balance preview, amount validation (must be > 0 and <= outstanding balance), payment method selector, transaction reference, and optional notes.

## Boundaries & Constraints

**Always:**
- Strictly isolate all payment records by `tenant_id`.
- Restrict payment recording UI to Finance Officer and Admin roles (router guard).
- Require outstanding debt selection, positive amount, selected payment method, and non-empty transaction reference.
- Reject amounts exceeding the outstanding balance with a descriptive error message.
- Provide immediate UI feedback via snackbars and loading indicators.

**Never:**
- Never permit payments on settled debts.
- Never expose cross-tenant payment records.
- Never allow negative or zero payment amounts.
- Never block the UI thread during payment submission.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Payment List Loading | User visits `/payments` | Data table of payment records (Date, Debt, Amount, Method, Txn Ref, Receipt) | Shows error message if fetch fails |
| Search Filter | User types "WIRE" or "RCP-" | Table filters to matching transaction refs / receipts | Displays empty table on no match |
| Record Payment (Valid) | Debt: DR-1001, Amount: 500.00, Method: Cash, Ref: TXN-1 | Inserts into `public.payments`, shows success toast, refreshes list | Shows error snackbar on DB failure |
| Record Payment (Overpay) | Amount exceeds outstanding balance | Submission blocked with balance warning | Inline snackbar: "Payment exceeds outstanding balance" |
| Record Payment (Settled) | Debt with status 'settled' | Debt excluded from dropdown; server rejects if forced | Error snackbar: settled debt |

</frozen-after-approval>

## Code Map

- `lib/features/payments/domain/payment.dart` -- Payment entity model with JSON serialization and copyWith.
- `lib/features/payments/data/payment_repository.dart` -- Repository recording payments and deflating debt balances.
- `lib/features/payments/presentation/payment_controller.dart` -- Riverpod controller, search query notifier, and pagination providers.
- `lib/features/payments/presentation/widgets/record_payment_dialog.dart` -- Dialog form for payment recording with validation.
- `lib/features/payments/presentation/payments_screen.dart` -- Interactive payments table with add payment trigger and pagination.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/payments/domain/payment.dart` -- Create Payment entity model.
- [x] `lib/features/payments/data/payment_repository.dart` -- Create PaymentRepository with recordPayment and balance deflation.
- [x] `lib/features/payments/presentation/payment_controller.dart` -- Implement Riverpod PaymentController, search query notifier, and pagination providers.
- [x] `lib/features/payments/presentation/widgets/record_payment_dialog.dart` -- Create dialog form for payment creation with validation.
- [x] `lib/features/payments/presentation/payments_screen.dart` -- Functional data table, record payment button, pagination.
- [x] `test/features/payments/payment_controller_test.dart` -- Unit tests for payment state, search filtering, and pagination.
- [x] `test/features/payments/payments_screen_test.dart` -- Widget tests for payments rendering, dialog, and validation.

**Acceptance Criteria:**
- Given an authorized staff member on `/payments`, all tenant payment records are displayed in a clean tabular view.
- Given the Record Payment modal, selecting a customer debt, entering amount, selecting payment method, and entering transaction reference saves the payment.
- Given an entered amount exceeding the outstanding balance, submission is prevented with a clear error message.

## Implementation Notes

- Implemented `Payment` entity matching `public.payments` schema with copyWith and JSON parsing.
- Implemented `PaymentRepository` with atomic recordPayment: validates balance, inserts payment, decrements `debts.remaining_balance_cents`, auto-sets status to `settled` when balance reaches zero.
- Implemented `PaymentController` and Riverpod providers for real-time search and pagination.
- Implemented `RecordPaymentDialog` modal with debt selection, balance preview, amount validation, method dropdown, transaction ref, and notes.
- Implemented `PaymentsScreen` data table with payment method labels, pagination footer, and record payment trigger.
- Authored test suites in `test/features/payments/payment_controller_test.dart` (6 tests) and `test/features/payments/payments_screen_test.dart` (3 tests).
- `flutter analyze` reports zero issues.
