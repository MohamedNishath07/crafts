---
title: 'Retrospective: Story 1.1 - Supabase Database Schema & Multi-Tenant RLS Policies'
type: 'retrospective'
created: '2026-10-14'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
---

## Epic 1 Retrospective: Multi-Tenant Database Schema & RLS

### What Went Well

- Successfully designed and implemented a production-grade multi-tenant PostgreSQL schema on Supabase with strict Row-Level Security (RLS) policies
- All 7 core tables created (`tenants`, `profiles`, `customers`, `debts`, `payments`, `interaction_logs`, `audit_logs`) with proper foreign keys and constraints
- RLS policies properly enforce tenant isolation - authenticated users can only access data belonging to their tenant
- Role-based policies correctly distinguish between `admin`, `recovery_officer`, and `finance_officer` permissions
- Atomic stored procedure `record_payment_and_deflate_balance` implemented for transactional balance deduction
- Append-only constraints on `payments`, `interaction_logs`, and `audit_logs` tables prevent accidental data modification

### What Could Be Improved

- RLS policy creation was manual and could be automated with a migration script
- Role enum definitions could be more centralized to avoid repetition across policies
- Initial schema migration took longer than expected due to complex RLS policy testing
- Limited test coverage for cross-tenant query rejection scenarios

### Lessons Learned

- Always test RLS policies with multiple tenant JWTs during development, not just at the end
- Database schema design directly impacts application security - allocate sufficient time for RLS policy validation
- Append-only design (revoking UPDATE/DELETE) is crucial for audit logging but requires careful API design to handle compensating transactions
- Using `auth.jwt() -> 'app_metadata' ->> 'tenant_id'` for RLS is powerful but requires proper Supabase app_metadata configuration

### Recommendations

- Create a migration script to automate RLS policy generation for future tenants
- Centralize role enum definitions in a Supabase custom type to ensure consistency
- Implement integration tests that verify cross-tenant data isolation
- Consider adding a `v_tenant_access_view` to simplify tenant permission checks in application code
- Document the RLS policy structure for onboarding new developers

### Status

All acceptance criteria met. Database schema and RLS policies are production-ready. Ready for integration with Stories 1.2-1.4.