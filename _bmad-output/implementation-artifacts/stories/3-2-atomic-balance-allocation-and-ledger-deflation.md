---
title: 'Story 3.2: Atomic Balance Allocation & Ledger Deflation'
type: 'feature'
created: '2026-10-19'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/planning-artifacts/architecture/architecture-crafts-2026-10-14/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/prds/prd-crafts-2026-10-14/prd.md'
  - '_bmad-output/implementation-artifacts/stories/3-1-payment-recording-form-for-full-and-partial-settlements.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Financial controllers need customer balances reduced atomically when a payment is saved so that ledger records are 100% accurate with no partial-write or double-count risks.

**Approach:** Implement balance allocation in `PaymentRepository.recordPayment`: fetch current debt balance server-side, validate amount (positive, <= remaining, not settled), insert payment record, then decrement `debts.remaining_balance_cents` and auto-transition status to `settled` when the balance reaches zero. RLS append-only policies guarantee payments cannot be updated or deleted.

## Boundaries & Constraints

**Always:**
- Validate on the server-side fetched balance (never trust client-cached balances).
- Set status to `settled` exactly when remaining balance reaches 0.
- Keep payments table append-only (no UPDATE/DELETE paths in repository).
- Emit descriptive errors for overpay, settled-debt, and zero-amount cases.

**Never:**
- Never allow negative remaining balances.
- Never expose an update/delete method on payments.
- Never mutate payment records after creation.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Partial Payment | Debt remaining 500.00, pay 125.00 | Payment saved; remaining 375.00; status stays active | N/A |
| Full Settlement | Debt remaining 500.00, pay 500.00 | Payment saved; remaining 0.00; status becomes settled | N/A |
| Overpay Attempt | Debt remaining 100.00, pay 150.00 | Rejected before write | Error: exceeds outstanding balance |
| Settled Debt | Debt status settled, any amount | Rejected before write | Error: settled debt |
| Zero Amount | Amount 0.00 | Rejected | Error: must be greater than zero |

</frozen-after-approval>

## Code Map

- `lib/features/payments/data/payment_repository.dart` -- `recordPayment` with balance validation, payment insert, balance decrement, and auto-settle.
- `supabase/migrations/20261014000000_initial_schema.sql` -- `payments` table with `CHECK (amount_cents > 0)` and RLS append-only policies; `debts.remaining_balance_cents` with `CHECK (>= 0)`.

## Tasks & Acceptance

**Execution:**
- [x] `PaymentRepository.recordPayment` -- Server-side balance fetch, validation, payment insert, balance decrement.
- [x] Auto-settle: when remaining balance reaches 0, debt status updates to `settled`.
- [x] RLS/constraints: append-only payments, non-negative balances enforced at DB level.
- [x] Client fallback: offline/test-mode local payment without balance mutation.

**Acceptance Criteria:**
- Given a payment submission, the debt's remaining balance decrements and the payment record is inserted atomically.
- Given remaining balance reaches zero, the debt status updates automatically to `Settled`.
- Given balance validation, 100% of overpay/settled/zero cases are rejected with descriptive errors.

## Implementation Notes

- Balance math uses integer cents (`amount_cents`, `remaining_balance_cents`) to avoid float errors.
- Unit tests cover amount conversion and controller create flow; append-only behavior is enforced by Supabase RLS (`REVOKE UPDATE, DELETE`).
