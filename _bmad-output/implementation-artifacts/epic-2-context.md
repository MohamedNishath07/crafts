# Epic 2 Context: Customer Registry & Debt Ledger

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Establish the core Customer Directory and Debt Ledger modules, enabling authorized staff across all roles (Administrators, Recovery Officers, Finance Officers) to register borrowers, create principal debt records with due dates, calculate Days Past Due (DPD), and identify delinquent accounts in real time.

## Stories

- Story 2.1: Customer Registration, Search, and Profile Management (FR-03, FR-13)
- Story 2.2: Debt Record Creation & Principal Balance Management (FR-04, FR-05)
- Story 2.3: Overdue Debt Identification & Days Past Due (DPD) Calculation (FR-05, FR-06, FR-13)

## Requirements & Constraints

- Every customer record is strictly scoped to the authenticated user's `tenant_id` via Supabase Row-Level Security (RLS).
- Customer records require valid Full Name and Primary Phone Number; Secondary Phone, Email, National ID, and Physical Address are optional.
- Real-time search across customer names, phone numbers, and National IDs (< 100ms response).
- Tabular data presentation supporting pagination (batches of 25, 50, 100).
- Debt creation enforces positive principal amounts, unique reference numbers per tenant, and initial `remaining_balance = principal_amount`.

## Technical Decisions

- **Database Tables:** `public.customers` and `public.debts`.
- **Aging & Delinquency:** View `public.v_debt_aging` and dynamic client-side DPD formula: `max(0, current_date - due_date)`.
- **State Management:** Riverpod `AsyncNotifier` with real-time text search filter and pagination providers.

## Cross-Story Dependencies

- Story 2.1 provides the customer records required by Story 2.2 (Debt creation) and subsequent payment and recovery modules (Epics 3 & 4).
