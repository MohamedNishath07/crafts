---
title: 'Logo, Login, and Dashboard Startup Flow'
type: 'feature'
created: '2026-11-23'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'aef18af33ede5207252091a7bd2eb219741a86aa'
context:
  - '_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The app's launch flow does not reliably guide a signed-out user from the logo screen to login and then to the dashboard after successful sign-in.

**Approach:** Make the logo screen the app's first screen and transition from it to login automatically once authentication initialization completes. Preserve the existing guarded authentication flow so only successful sign-in reaches the dashboard.

## Boundaries & Constraints

**Always:**
- Keep authentication state in the existing Riverpod auth controller and navigation in the existing `go_router` configuration.
- Keep login validation and failure feedback intact.
- Do not expose protected dashboard routes before authentication succeeds.
- On every launch, show login after the logo even when a session previously existed; require fresh credential submission before dashboard access.

**Never:**
- Do not change credential handling, roles, data access, or dashboard behavior.
- Do not add a new onboarding action or require the user to tap a button to reach login.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Signed-out launch | App starts; auth initialization completes with no active user | Show logo first, then automatically show login | Keep logo visible while auth state is loading |
| Returning launch | App starts with a previously active session | Show logo first, then login; do not restore dashboard access before a new sign-in | Keep login available after auth initialization |
| Successful sign-in | Valid credentials submitted on login | Establish authenticated state and navigate to dashboard | Existing success feedback remains |
| Failed sign-in | Invalid credentials submitted on login | Stay on login and do not navigate to dashboard | Existing login error feedback remains |

</frozen-after-approval>

## Code Map

- `lib/features/auth/presentation/logo_screen.dart` -- Existing logo screen to use as the initial route; avoid creating a duplicate splash UI.
- `lib/core/router/app_router.dart` -- Existing `go_router` setup and auth/role redirect guards; coordinate initial route and post-logo navigation here.
- `lib/features/auth/presentation/auth_controller.dart` -- Riverpod auth initialization and sign-in state used to determine whether startup is complete and whether a user is authenticated.
- `lib/features/auth/presentation/login_screen.dart` -- Existing sign-in form, error handling, and successful dashboard navigation; preserve its validation and feedback.
- `test/core/router/app_router_test.dart` -- Existing route guard tests; cover launch and authenticated/unauthenticated routing behavior here.
- `test/features/auth/login_screen_test.dart` -- Existing login validation tests; retain and extend only for the requested success/failure navigation behavior.
- `lib/features/splash/presentation/splash_screen.dart` -- Separate legacy Get Started flow; do not route startup through its manual button.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/auth/presentation/auth_controller.dart` -- Clear any existing session at launch and expose an active profile only after successful sign-in -- enforce fresh authentication.
- [x] `lib/features/auth/presentation/login_screen.dart` -- Navigate only for an active authenticated profile and remove debug shortcuts that bypass sign-in -- preserve login validation and feedback.
- [x] `lib/core/router/app_router.dart` -- Make the logo the app entry and redirect protected deep links while authentication initializes -- prevent protected content from rendering before auth is ready.
- [x] `lib/features/auth/presentation/logo_screen.dart` -- Automatically continue from the logo once the auth state is ready -- remove any manual step that blocks signed-out users from login.
- [x] `test/core/router/app_router_test.dart` and `test/features/auth/login_screen_test.dart` -- Cover signed-out startup, successful sign-in to dashboard, and failed sign-in remaining on login.

**Acceptance Criteria:**
- Given a signed-out user launching the app, when authentication initialization completes, then the logo is shown first and login follows without requiring a tap.
- Given a returning user with a previously active session, when authentication initialization completes after launch, then the logo is shown first and login is displayed without granting dashboard access before a new sign-in.
- Given valid credentials on the login screen, when sign-in succeeds, then the authenticated user is navigated to the dashboard.
- Given invalid credentials on the login screen, when sign-in fails, then the user stays on login and receives the existing error feedback.

## Implementation Notes

- `AuthController` clears an existing repository session during startup; `LogoScreen` waits for auth initialization before routing to login.
- Login navigation now requires an active profile, and authentication errors remain on the login screen.
- Added repository injection to `AuthController` so the returning-session startup behavior can be tested without a real database.
- Removed debug persona shortcuts and redirected protected deep links to the logo while authentication is initializing.
- Login widget tests now use the real `AuthController` with a fake repository for successful, failed, and inactive-account sign-in.

## Spec Change Log

## Review Triage Log

| Finding | Verdict | Evidence / disposition |
|---|---|---|
| Debug role chips could reach the dashboard without fresh credentials. | low | Verified in the debug-only login controls; removed the bypass. Grouped with the separate busy-state chip finding because both arise from the same controls. |
| `AuthController.build()` might sign out on later provider rebuilds. | false | No in-repository invalidation or refresh callers exist, and the controller build has no watched dependencies; startup is the only reachable build path. |
| Startup sign-out failures could leave the repository session active. | false | The current `AuthRepository.signOut()` only replaces its in-memory user value and has no I/O or failure path. |
| Logo navigation treats auth initialization errors as ready. | false | The current startup operation is the non-throwing in-memory `signOut()` above, so this error path is not reachable with the repository implementation. |
| Protected deep links could render while auth initialization was loading. | medium | `isLoading` previously returned no redirect; protected paths now redirect to `/`, covered by a pending-auth router test. |
| Slow/cancelled sign-in and unmount behavior lacked dedicated tests. | false | Duplicate submission is disabled by `_isLoggingIn`, and async feedback/navigation is guarded by `mounted`; no uncovered behavior was demonstrated. |
| Returning-session test used a fake repository rather than the concrete in-memory implementation. | false | The actual repository has no persisted session and its sign-out is a direct in-memory assignment; the controller test verifies it invokes the sign-out contract and then reaches login. |
| Demo-role chips could be used during sign-in and bypass fresh credentials. | low | The same debug controls as the first finding remained actionable during sign-in; removed with those controls and grouped under that patch. |
| Create Account remained actionable during auth loading. | false | The existing button uses `onPressed: isLoading ? null : ...`, so navigation is disabled while loading. |
| Inactive-profile sign-in lacked coverage through the auth controller. | medium | Added a widget test using `AuthController` with an inactive fake profile; it stays on login and shows an error. |
| Login tests bypassed repository-backed controller behavior for inactive sign-in. | medium | Added inactive-profile coverage through the real `AuthController`; this is the same missing-controller-coverage root cause as the prior finding. |
| Successful login navigation was tested only with a mocked controller. | medium | Replaced the mock with the real `AuthController` and fake repository; successful credentials now verify dashboard navigation. |

## Verification

**Commands:**
- `flutter test test/core/router/app_router_test.dart test/features/auth/login_screen_test.dart` -- expected: all targeted routing and login tests pass.
  - Result: Passed, 11 tests.
- `flutter analyze` -- expected: no issues found.
  - Result: No issues found.

**Manual checks (if no CLI):**
- None.
