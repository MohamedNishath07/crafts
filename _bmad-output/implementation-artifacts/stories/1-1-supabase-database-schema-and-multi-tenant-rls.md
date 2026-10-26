---
title: 'Story 1.1: Supabase Database Schema & Multi-Tenant RLS Policies'
type: 'feature'
created: '2026-10-14'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/planning-artifacts/architecture/architecture-crafts-2026-10-14/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/prds/prd-crafts-2026-10-14/prd.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Debit Recovery System requires a secure, multi-tenant relational schema on Supabase PostgreSQL with strict Row-Level Security (RLS) to ensure customer records and financial ledgers are completely isolated by tenant, with role-based restrictions for Administrators, Recovery Officers, and Finance Officers.

**Approach:** Author a production-grade PostgreSQL migration script `supabase/migrations/20261014000000_initial_schema.sql` defining `tenants`, `profiles`, `customers`, `debts`, `payments`, `interaction_logs`, and `audit_logs` with non-nullable `tenant_id UUID REFERENCES tenants(id)`, foreign keys, and RLS policies enforcing tenant isolation and role permissions.

## Boundaries & Constraints

**Always:**
- Every tenant-scoped table must include a non-nullable `tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE`.
- RLS must be explicitly enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`) on all public tables.
- All primary keys must be `UUID DEFAULT gen_random_uuid()`.
- Financial currency values must be stored as `BIGINT` (in cents/smallest units) or `NUMERIC(12,2)` to prevent floating-point rounding errors.
- `payments`, `interaction_logs`, and `audit_logs` must be strictly append-only (revoke `UPDATE` and `DELETE` permissions).

**Never:**
- Never create permissive `USING (true)` RLS policies on tenant data.
- Never allow cross-tenant queries or data access.
- Never use floating point (`FLOAT`, `REAL`) for monetary amounts.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Tenant Schema Setup | Execute migration SQL script | Tables, indexes, triggers, and RLS policies created cleanly | Rollback transaction on syntax error |
| Tenant Isolation Query | Authenticated JWT with `tenant_id = A` queries `customers` | Returns only rows where `tenant_id = A` | Returns empty set if no rows match tenant |
| Cross-Tenant Query Attempt | Authenticated user from Tenant A queries data with `tenant_id = B` | RLS filter blocks visibility; zero rows returned | RLS silently filters out non-tenant rows |
| Non-Admin Access Violation | `recovery_officer` attempts `INSERT` into `audit_logs` or modifies `profiles` | PostgreSQL rejects query with permission denied | Returns HTTP 403 / PostgreSQL error 42501 |
| Immutability Violation | Any user attempts `DELETE FROM payments WHERE id = ...` | PostgreSQL rejects query; deletion denied | Returns permission denied error |

</frozen-after-approval>

## Code Map

- `supabase/migrations/20261014000000_initial_schema.sql` -- Core database DDL migration defining tables, indexes, triggers, and Row-Level Security (RLS) policies.
- `supabase/seed.sql` -- Optional sample seed data with demo tenant, profiles, customers, and debts for local verification.

## Tasks & Acceptance

**Execution:**
- [x] `supabase/migrations/20261014000000_initial_schema.sql` -- Create core tables (`tenants`, `profiles`, `customers`, `debts`, `payments`, `interaction_logs`, `audit_logs`) with appropriate constraints, foreign keys, and timestamps.
- [x] `supabase/migrations/20261014000000_initial_schema.sql` -- Enable RLS on all tables and create tenant isolation policies using `auth.jwt() -> 'app_metadata' ->> 'tenant_id'`.
- [x] `supabase/migrations/20261014000000_initial_schema.sql` -- Implement role-based policies distinguishing `admin`, `recovery_officer`, and `finance_officer`.
- [x] `supabase/migrations/20261014000000_initial_schema.sql` -- Implement atomic stored procedure `record_payment_and_deflate_balance` for transactional balance deduction.

**Acceptance Criteria:**
- Given a clean PostgreSQL / Supabase database, when `20261014000000_initial_schema.sql` is applied, then all 7 tables and custom types are created with zero syntax errors.
- Given an active user JWT with `tenant_id`, when executing any `SELECT`, `INSERT`, `UPDATE` query, then RLS enforces that all affected rows match the authenticated `tenant_id`.
- Given a `payments` or `audit_logs` record, when an `UPDATE` or `DELETE` statement is executed, then the database rejects the command with a permission error.

## Implementation Notes

- Created `supabase/migrations/20261014000000_initial_schema.sql` with full multi-tenant schema, custom ENUMs (`user_role`, `debt_status`, `action_type`, `payment_method`), `v_debt_aging` view for automated DPD brackets, atomic payment allocation stored procedure, and immutable append-only constraints.
- Created `supabase/seed.sql` with test tenant "Acme Credit Solutions", customers, and aged debts.
- Verified all acceptance criteria and constraints. Ready for client integration in Story 1.2.
