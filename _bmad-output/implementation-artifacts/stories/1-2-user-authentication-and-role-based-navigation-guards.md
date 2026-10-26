---
title: 'Story 1.2: User Authentication & Role-Based Navigation Guards'
type: 'feature'
created: '2026-10-14'
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

**Problem:** Staff members across organizations need secure, role-differentiated access to the Debit Recovery System so that Administrators, Recovery Officers, and Finance Officers only access features permitted by their operational roles.

**Approach:** Implement Supabase GoTrue authentication in Flutter with Riverpod state management (`authControllerProvider`) and declarative URL routing via `go_router`. Enforce route-level redirect guards verifying authenticated sessions and role permissions before rendering protected screens.

## Boundaries & Constraints

**Always:**
- Use Riverpod for all authentication state management.
- Wrap all protected application routes inside an authenticated `AppShell` with responsive navigation.
- Restrict `/admin/users` and `/admin/audit-logs` exclusively to users with the `admin` role.
- Provide immediate field validation on login inputs (valid email format, non-empty password).

**Never:**
- Never hardcode user roles or credentials on the client.
- Never store raw unencrypted passwords in application state or memory.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Successful Login | Valid email & password | Authenticates session, sets active profile, redirects to `/dashboard` | N/A |
| Invalid Credentials | Wrong password | Rejects login, retains email field, shows error alert | Displays "Invalid email or password" |
| Unauthenticated Deep Link | User navigates directly to `/debts` without active session | Router redirects to `/login` with return URL parameter | Preserves intended destination |
| Unauthorized Role Access | `recovery_officer` navigates directly to `/admin/users` | Router blocks access and redirects to `/dashboard` | Displays "Access restricted to Administrator role" |
| Logout Action | User clicks Logout in sidebar / drawer | Clears session token, invalidates Riverpod state, routes to `/login` | N/A |

</frozen-after-approval>

## Code Map

- `lib/core/constants/app_colors.dart` -- Visual design tokens matching DESIGN.md.
- `lib/features/auth/domain/user_profile.dart` -- User profile entity with role enum (`admin`, `recoveryOfficer`, `financeOfficer`).
- `lib/features/auth/data/auth_repository.dart` -- Authentication repository communicating with Supabase GoTrue Auth.
- `lib/features/auth/presentation/auth_controller.dart` -- Riverpod `AsyncNotifier` managing authentication state.
- `lib/features/auth/presentation/login_screen.dart` -- Responsive login interface with tenant styling and validation.
- `lib/features/shell/presentation/app_shell.dart` -- Responsive Desktop Sidebar + Mobile App Bar navigation scaffold.
- `lib/core/router/app_router.dart` -- Declarative `go_router` configuration with redirect guards.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/auth/domain/user_profile.dart` -- Create UserProfile model and UserRole enum.
- [x] `lib/features/auth/data/auth_repository.dart` -- Implement Supabase auth sign-in, sign-out, and profile fetch.
- [x] `lib/features/auth/presentation/auth_controller.dart` -- Create Riverpod state notifier for authentication state.
- [x] `lib/features/auth/presentation/login_screen.dart` -- Build responsive login form with validation and loading states.
- [x] `lib/features/shell/presentation/app_shell.dart` -- Build responsive navigation shell (desktop sidebar / mobile drawer).
- [x] `lib/core/router/app_router.dart` -- Implement declarative routes and role-based redirect guards.
- [x] `lib/main.dart` -- Initialize Supabase and run Riverpod ProviderScope with AppRouter.

**Acceptance Criteria:**
- Given an unauthenticated user, when navigating to any protected route, then the system redirects to `/login`.
- Given a valid login attempt, when credentials are submitted, then the session is authenticated and user is navigated to the Dashboard.
- Given a logged-in Recovery Officer, when attempting to open `/admin/users`, then navigation is blocked.
- Given a logged-in user, when clicking Logout, then session is terminated and user is returned to `/login`.

## Implementation Notes

- Fixed `ListTile` callback in `lib/features/shell/presentation/app_shell.dart` to use `onTap:` instead of `onPressed:`.
- Updated `lib/main.dart` Supabase initialization to use `publishableKey:` instead of deprecated `anonKey:`.
- Fixed layout constraint handling on `AdminUsersScreen` header row to prevent `RenderFlex` overflow.
- Authored test suites verifying:
  - `test/features/auth/user_profile_test.dart`: Serialization, deserialization, and role string parsing.
  - `test/features/auth/login_screen_test.dart`: Form validation for empty inputs and invalid email formats.
  - `test/core/router/app_router_test.dart`: Route redirect guards for unauthenticated access, non-admin role access restrictions to `/admin/users`, and administrative permission.
  - `test/widget_test.dart`: Overall app smoke test.
- All 11 tests pass cleanly; `flutter analyze` reports zero issues.
