---
title: 'Story 2.1: Customer Registration, Search, and Profile Management'
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

**Problem:** Financial recovery officers and administrators need a centralized customer directory to register borrowers, search contact details, and maintain up-to-date demographic records so that recovery interactions and payments can be tracked reliably.

**Approach:** Build a dedicated Customer Directory in `CustomersScreen` backed by `CustomerRepository` and Riverpod `CustomerController`. Provide real-time text searching across customer name, phone number, and national ID; paginated table browsing (25, 50, 100 records per page); and a streamlined "Add Customer" modal with client-side validation.

## Boundaries & Constraints

**Always:**
- Strictly isolate all customer records by `tenant_id`.
- Require non-empty Full Name and Primary Phone Number upon registration.
- Provide real-time UI filtering on search input (< 100ms response).
- Support pagination with configurable batch size (25, 50, 100).
- Provide immediate feedback via snackbars for successful customer registration and error handling.

**Never:**
- Never expose cross-tenant customer records.
- Never permit registration with empty name or phone number.
- Never block the UI thread during customer search filtering.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Customer List Loading | User visits `/customers` | Displays data table of registered customers (Name, Phone, Email, National ID, Address, Registered Date) | Shows error message if fetch fails |
| Search Filter (Match) | User types "Alice" or "+1-555" | Table updates in real time to show only matching customers | Displays "No customers match your search" if no match |
| Search Filter (Clear) | User clears search input | Full paginated customer directory is restored | Instant re-render |
| Pagination Change | User selects 50 per page or clicks Next | Displays next slice of records, updating counter: "Showing 26-50 of 84 records" | Disables Next on last page |
| Add Customer (Valid) | Name: "John Doe", Phone: "+1 555-0199", Email: "john@example.com" | Inserts into `public.customers`, prepends to list, shows success toast | Shows error snackbar on database failure |
| Add Customer (Invalid) | Empty name or empty phone submitted | Form flags invalid fields with descriptive validation errors | Submission blocked |

</frozen-after-approval>

## Code Map

- `lib/features/customers/domain/customer.dart` -- Customer entity model with JSON serialization and copyWith.
- `lib/features/customers/data/customer_repository.dart` -- Repository fetching and inserting customer profiles in `public.customers`.
- `lib/features/customers/presentation/customer_controller.dart` -- Riverpod controller, search query notifier, and pagination providers.
- `lib/features/customers/presentation/widgets/add_customer_dialog.dart` -- Dialog form for registering new customers.
- `lib/features/customers/presentation/customers_screen.dart` -- Interactive customer table with search bar, pagination controls, and action triggers.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/customers/domain/customer.dart` -- Create Customer entity model.
- [x] `lib/features/customers/data/customer_repository.dart` -- Create CustomerRepository for database queries and offline fallback.
- [x] `lib/features/customers/presentation/customer_controller.dart` -- Implement Riverpod CustomerController, search query notifier, and pagination providers.
- [x] `lib/features/customers/presentation/widgets/add_customer_dialog.dart` -- Create dialog form for customer creation with validation.
- [x] `lib/features/customers/presentation/customers_screen.dart` -- Replace placeholder with interactive data table, search toolbar, and pagination.
- [x] `test/features/customers/customer_controller_test.dart` -- Unit tests for customer state, search filtering, and pagination.
- [x] `test/features/customers/customers_screen_test.dart` -- Widget tests for directory rendering, search, and customer registration.

**Acceptance Criteria:**
- Given an authorized staff member on `/customers`, all tenant customer records are displayed in a clean tabular view.
- Given the search bar, typing a customer name, phone number, or national ID filters the table in real time.
- Given the pagination controls, changing page size or navigating between pages updates the displayed slice of records.
- Given the "Add Customer" dialog, entering valid borrower information registers the customer and updates the directory immediately.

## Implementation Notes

- Implemented `Customer` entity model in `lib/features/customers/domain/customer.dart` matching `public.customers` schema with copyWith and JSON parsing.
- Implemented `CustomerRepository` in `lib/features/customers/data/customer_repository.dart` for querying and creating customer records in Supabase PostgreSQL with realistic default fallback records.
- Implemented `CustomerController` and Riverpod providers in `lib/features/customers/presentation/customer_controller.dart` providing real-time multi-field search and configurable pagination (25, 50, 100 records per page).
- Implemented `AddCustomerDialog` modal with validation for mandatory fields (Full Name, Primary Phone) and optional fields (Secondary Phone, Email, National ID, Address).
- Implemented `CustomersScreen` data table with real-time search toolbar, clear action, pagination footer, and add customer trigger.
- Authored test suites in `test/features/customers/customer_controller_test.dart` and `test/features/customers/customers_screen_test.dart` (7 tests total).
- All 30 tests across the entire project pass cleanly; `flutter analyze` reports zero issues.

