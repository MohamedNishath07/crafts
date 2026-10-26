---  
title: 'Story 5.1: Real-time Summary Metric Cards'  
type: 'feature'  
created: '2026-10-26'  
status: 'done'  
route: 'dispatch'  
review_loop_iteration: 0  
context:  
  - '_bmad-output/planning-artifacts/architecture/architecture-crafts-2026-10-14/ARCHITECTURE-SPINE.md'  
  - '_bmad-output/implementation-artifacts/stories/3-3-payment-history-and-transaction-reference-ledger.md'  
---  
<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Finance Officers and Recovery Officers need real-time visibility into key portfolio metrics (total customers, total outstanding debt, overdue balances, recovered amounts) so that they can make informed daily decisions without manually calculating summaries from tables.

**Approach:** Implement `dashboard_metrics_provider` with Riverpod that fetches aggregated metrics from the Supabase backend via `fetchDashboardMetrics()`. Render 4 metric cards with icons and value displays: total customers, total outstanding debt, overdue balances, and recovered amounts. Support real-time updates via Supabase change tracking. Display amounts in formatted currency (`$X,XXX.XX`) and counts with comma separators. Keep metrics strictly isolated by `tenant_id` per RLS policies.

## Boundaries & Constraints

**Always:**
- Metrics strictly isolated by `tenant_id` via Supabase RLS
- All amounts displayed as `$X,XXX.XX` format (2 decimal places)
- Counts displayed with comma separators (e.g., 1,500 customers)
- Metrics refresh automatically on interval or manual refresh pull
- Support dark/light theme via `AppColors` tokens

**Never:**
- Never expose raw database values without formatting
- Never allow metrics to reflect cross-tenant data
- Never block UI thread during metric fetch

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Initial Load | User visits `/dashboard` | 4 metric cards render with tenant-scoped data | Error banner if fetch fails; show zeros if no data |
| Real-time Update | Supabase channel triggers update | Metric cards update instantly without full page reload | Graceful fallback if channel disconnects |
| No Data | First-time tenant with no records | All metrics display `0` or `$0.00` | Show placeholder text: "No data available" |
| Tenant Switch | User changes tenant context | Metrics recalculate for new tenant | Maintain RLS isolation; no data leak |

</frozen-after-approval>

## Code Map

- `lib/features/dashboard/dashboard_metrics_provider.dart` -- Riverpod provider for dashboard metrics
- `lib/features/dashboard/dashboard_metrics_screen.dart` -- 4 metric cards UI
- `lib/features/dashboard/dashboard_controller.dart` -- Notifier for manual refresh
- `lib/features/recovery/data/reminder_repository.dart` -- Reference for data layer pattern
- `supabase/migrations/20261014000000_initial_schema.sql` -- Ensure dashboard metrics view or queries
- `core/constants/app_colors.dart` -- Color tokens for metric card styling

## Tasks & Acceptance

**Execution:**
- [x] `fetchDashboardMetrics()` -- Supabase query returning {totalCustomers, totalDebt, overdueBalance, recoveredAmount}
- [x] `dashboardMetricsProvider` -- Provider returning `AsyncDashboardMetrics` state
- [x] `dashboardMetricsNotifierProvider` -- Notifier for manual refresh trigger
- [x] `DashboardMetricsScreen` -- 4 metric cards with formatted display
- [x] `test/features/dashboard/dashboard_metrics_test.dart` -- Metrics fetch and formatting tests
- [x] `test/features/dashboard/dashboard_metrics_screen_test.dart` -- UI rendering and real-time update tests

**Acceptance Criteria:**
- Given the Dashboard screen, 4 metric cards display: total customers, total outstanding debt, overdue balances, recovered amounts
- Amounts formatted as `$X,XXX.XX`; counts as `X,XXX`
- Metrics are strictly isolated by tenant_id via RLS
- Metrics update in real-time when underlying data changes
- Error state displayed gracefully if fetch fails

## Implementation Notes

- Metrics computed via Supabase aggregation queries or view: `count(*), sum(balance), sum(case when overdue then balance else 0 end), sum(recovered)`
- Data refreshed via Supabase realtime channel on `/dashboard` route
- Card colors: `AppColors.brandPrimary` (primary), `AppColors.accentSuccess` (recovered), `AppColors.accentError` (overdue)
- Loading state: skeleton cards during initial fetch
- Metrics model is immutable; notifier triggers rebuild on update
- Route: `/dashboard` with metric cards as central visual element