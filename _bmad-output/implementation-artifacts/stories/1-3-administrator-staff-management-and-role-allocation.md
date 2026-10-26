---
title: 'Story 1.3: Administrator Staff Management & Role Allocation'
type: 'feature'
created: '2026-10-19'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/planning-artifacts/architecture/architecture-crafts-2026-10-14/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/ux-designs/ux-crafts-2026-10-14/EXPERIENCE.md'
  - '_bmad-output/planning-artifacts/prds/prd-crafts-2026-10-14/prd.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** System administrators need to view, invite, configure roles for, and activate/deactivate staff user accounts within their organization so that organizational access is controlled and operations are segregated by role.

**Approach:** Build a dedicated staff user management interface in `AdminUsersScreen` backed by `StaffRepository` and Riverpod `StaffController`. Enable administrators to list all staff members belonging to their tenant, filter by role/status, add new staff accounts with assigned roles (`admin`, `recovery_officer`, `finance_officer`), and toggle user active status (`is_active`).

## Boundaries & Constraints

**Always:**
- Restrict all mutating operations to authenticated users with the `admin` role.
- Filter staff users strictly to the authenticated tenant.
- Provide real-time UI feedback (success snackbars, error banners, loading indicators).
- Prevent administrators from deactivating their own currently authenticated user account.
- Require valid email format and non-empty name when adding a staff member.

**Never:**
- Never expose password hashes or sensitive authorization tokens in the client table.
- Never permit client-side bypass of the `admin` role check.
- Never hardcode tenant identifiers.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Staff List Loading | Administrator visits `/admin/users` | Displays table of staff with name, email, role badge, status badge, created date | Shows error banner if fetch fails |
| Filter Staff | User selects role "Recovery Officer" or status "Inactive" | List dynamically filters to matching profiles | Displays "No staff members match the selected filters" |
| Add Staff Member (Valid) | Admin inputs Name: "Alice Smith", Email: "alice@acme.com", Role: `recovery_officer` | Inserts profile into tenant, refreshes list, displays success snackbar | Shows error banner on duplicate email or database error |
| Add Staff Member (Invalid) | Empty name or malformed email submitted | Form highlights invalid fields with helper text, submission blocked | Displays validation error inline |
| Toggle Staff Status | Admin clicks "Deactivate" on an active staff member | Updates `is_active` to `false`, status badge turns inactive, shows confirmation | Displays error alert if update fails |
| Self-Deactivation Prevention | Admin clicks deactivate on their own row | Action button is disabled or modal prevents deactivation | Displays "You cannot deactivate your own administrative account" |

</frozen-after-approval>

## Code Map

- `lib/features/auth/domain/user_profile.dart` -- Existing `UserProfile` model and `UserRole` enum.
- `lib/features/admin/data/staff_repository.dart` -- Repository fetching and mutating staff records in `public.profiles`.
- `lib/features/admin/presentation/staff_controller.dart` -- Riverpod `AsyncNotifier` managing staff list, filtering, and mutations.
- `lib/features/admin/presentation/admin_users_screen.dart` -- Staff management screen with search/filter toolbar, data table, and add/edit modals.
- `lib/features/admin/presentation/widgets/add_staff_dialog.dart` -- Dialog form for adding new staff members.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/admin/data/staff_repository.dart` -- Create StaffRepository for querying and updating tenant staff profiles.
- [x] `lib/features/admin/presentation/staff_controller.dart` -- Create Riverpod StaffController with state management for fetch, create, and status toggle.
- [x] `lib/features/admin/presentation/widgets/add_staff_dialog.dart` -- Build dialog form for creating new staff members with validation.
- [x] `lib/features/admin/presentation/admin_users_screen.dart` -- Replace placeholder with interactive staff table, role/status filters, and action dialogs.
- [x] `test/features/admin/staff_controller_test.dart` -- Unit tests for staff state transitions, creation, and deactivation.
- [x] `test/features/admin/admin_users_screen_test.dart` -- Widget tests for staff table rendering, filtering, and add dialog.

**Acceptance Criteria:**
- Given an Administrator on `/admin/users`, all staff members of their tenant are displayed with email, full name, role, and active status.
- Given the "Add Staff Member" dialog, submitting valid user details registers the user and updates the table.
- Given an active staff member, clicking Deactivate toggles their status to inactive.
- Given an administrator viewing their own profile row, the deactivate button is disabled or prevented.

## Implementation Notes

- Implemented `StaffRepository` in `lib/features/admin/data/staff_repository.dart` providing queries for staff listing, staff creation, status updates, and role mutations with offline roster fallback.
- Implemented `StaffController` and filter providers in `lib/features/admin/presentation/staff_controller.dart` with state management for role/status filtering and search indexing.
- Implemented `AddStaffDialog` in `lib/features/admin/presentation/widgets/add_staff_dialog.dart` providing validation for full name, email format, and role selection dropdown.
- Implemented interactive `AdminUsersScreen` in `lib/features/admin/presentation/admin_users_screen.dart` featuring real-time search, filter chips, staff data table, self-deactivation prevention guard, and confirmation modals.
- Authored test suites in `test/features/admin/staff_controller_test.dart` and `test/features/admin/admin_users_screen_test.dart`, all 8 tests passing.
- Fixed `AppShell` sidebar brand row to prevent RenderFlex overflow in widget tests.
- Full test suite passes (19/19 tests) and `flutter analyze` reports zero issues.
