---
title: 'Story 1.4: User Profile Settings & Password Change'
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

**Problem:** Staff members across all operational roles (Administrator, Recovery Officer, Finance Officer) need the ability to maintain their display identity (full name) and securely rotate their account passwords without requiring administrator intervention for routine password changes.

**Approach:** Provide a dedicated `/profile` settings screen accessible to all authenticated roles. The screen features two clean cards:
1. **Profile Information:** View email and assigned role badge (read-only for security integrity) and edit full name with inline validation.
2. **Security & Password:** Form to change password with complexity enforcement (minimum 8 characters, mixed case, at least one number, and matching confirmation password).

## Boundaries & Constraints

**Always:**
- Allow all authenticated staff roles (`admin`, `recovery_officer`, `finance_officer`) access to `/profile`.
- Enforce password complexity: minimum 8 characters, at least one uppercase letter, at least one lowercase letter, and at least one digit.
- Keep email address and assigned role read-only on the profile page to prevent privilege escalation or tenant desynchronization.
- Provide clear visual feedback via toast/snackbar upon successful update or validation failure.

**Never:**
- Never display current or new password in plain text without obscuring/toggle.
- Never permit password change if the new password and confirmation password do not match.
- Never allow an empty or whitespace-only full name.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| View Profile | Authenticated user visits `/profile` | Displays current full name, email, and styled role badge | Shows skeleton/spinner if profile is loading |
| Update Name (Valid) | User changes name to "Jane Doe" and clicks "Save Changes" | Updates profile in `public.profiles`, updates Riverpod state, displays success snackbar | Shows error snackbar if database update fails |
| Update Name (Empty) | User clears name field and submits | Form validation blocks submit: "Please enter your full name" | Inline validation message |
| Change Password (Valid) | User inputs New Password: `SecurePass123!`, Confirm: `SecurePass123!` | Submits password update to Supabase Auth, clears form, shows confirmation snackbar | Shows error if network or auth service fails |
| Password Mismatch | New: `Alpha123!`, Confirm: `Beta123!` | Submission blocked: "Passwords do not match" | Inline validation error |
| Weak Password | New: `short1` | Submission blocked: "Password must be at least 8 characters with letters and numbers" | Inline validation error |

</frozen-after-approval>

## Code Map

- `lib/features/auth/data/auth_repository.dart` -- Profile update and password mutation methods.
- `lib/features/auth/presentation/auth_controller.dart` -- Riverpod controller actions for updating user profile and password.
- `lib/features/auth/presentation/profile_screen.dart` -- Responsive profile settings and password change screen.
- `lib/core/router/app_router.dart` -- Navigation route `/profile` mounted within `ShellRoute`.
- `lib/features/shell/presentation/app_shell.dart` -- Top bar profile trigger and navigation linking to `/profile`.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/auth/data/auth_repository.dart` -- Add updateProfile and updatePassword methods.
- [x] `lib/features/auth/presentation/auth_controller.dart` -- Add updateProfile and changePassword controller methods.
- [x] `lib/features/auth/presentation/profile_screen.dart` -- Build responsive profile settings and password change UI with validation.
- [x] `lib/core/router/app_router.dart` -- Register `/profile` route in ShellRoute.
- [x] `lib/features/shell/presentation/app_shell.dart` -- Connect user header avatar/name to `/profile`.
- [x] `test/features/auth/profile_screen_test.dart` -- Widget and unit tests for profile screen, validation, and actions.

**Acceptance Criteria:**
- Given an authenticated user on `/profile`, their email, role badge, and current name are accurately displayed.
- Given a name change with valid characters, clicking Save Changes updates the user profile across the app.
- Given the password change form, valid passwords meeting complexity requirements submit successfully.
- Given mismatched or weak passwords, submission is blocked with inline error messages.

## Implementation Notes

- Added `updateProfile` and `updatePassword` to `AuthRepository` with Supabase PostgREST and GoTrue Auth mutations.
- Added `updateProfile` and `changePassword` in `AuthController` updating Riverpod user profile state with offline fallback support.
- Implemented `ProfileScreen` in `lib/features/auth/presentation/profile_screen.dart` featuring read-only email and role badge, name update form, password change form, visibility toggles, and complexity validation.
- Registered `/profile` route in `appRouterProvider` under `ShellRoute` accessible to all staff roles.
- Linked profile screen via user display chip in the top app bar and `Settings` nav item in sidebar.
- Authored test suite in `test/features/auth/profile_screen_test.dart` (4 tests verifying rendering, name validation, save execution, and password matching).
- All 23 tests pass cleanly; `flutter analyze` reports zero issues.

