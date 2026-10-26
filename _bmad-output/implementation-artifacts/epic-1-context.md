# Epic 1 Context: Multi-Tenant Foundation & Security

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Establish the multi-tenant data foundation, Supabase PostgreSQL database schema with Row-Level Security (RLS), authentication infrastructure, and role-based access control across three primary roles: Administrator, Recovery Officer, and Finance Officer.

## Stories

- Story 1.1: Supabase Database Schema & Multi-Tenant RLS Policies
- Story 1.2: User Authentication & Role-Based Navigation Guards
- Story 1.3: Administrator Staff Management & Role Allocation
- Story 1.4: User Profile Settings & Password Change

## Requirements & Constraints

- Secure email and password authentication with encrypted token sessions.
- Multi-tenancy isolation: all tenant queries strictly scoped to the authenticated organization.
- Three active staff roles:
  - `admin`: Full system access, staff management, audit logs, system configuration.
  - `recovery_officer`: Access scoped to debtor follow-ups, contact logs, and assigned accounts.
  - `finance_officer`: Access scoped to payment recording, transaction verification, and financial reports.
- User profile updates and password change with complexity validation.
- All unauthorized access attempts to restricted features or cross-tenant data rejected with 403 Forbidden.

## Technical Decisions

- **AD-1: PostgreSQL Row-Level Security (RLS)** enabled on all public tables (`tenants`, `profiles`, `customers`, `debts`, `payments`, `interaction_logs`, `audit_logs`). Enforced by policy: `tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid`.
- **AD-2: Role-Based Authorization** using Supabase GoTrue Auth with custom claims (`tenant_id`, `role`) injected into JWT.
- Primary keys: UUIDv4 across all tables.
- Flutter Web routing configured via `go_router` with declarative redirect guards verifying role permissions before loading screens.

## UX & Interaction Patterns

- Responsive desktop sidebar navigation with active role badge.
- Clean authentication forms with inline validation and clear error messages.
- Immediate logout and session clearing with automatic redirect to login screen.

## Cross-Story Dependencies

- Story 1.1 provides the foundational database tables and RLS security policies that Stories 1.2, 1.3, and 1.4 depend upon.
