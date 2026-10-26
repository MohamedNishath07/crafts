---
name: Debit Recovery System
status: final
sources:
  - {planning_artifacts}/prds/prd-crafts-2026-10-14/prd.md
updated: 2026-10-14
---

# Debit Recovery System — Experience Specification

## Foundation

* **Platform & Surfaces:** Responsive Web Application supporting modern desktop browsers (Chrome, Edge, Firefox, Safari) and adaptive tablet/mobile layouts.
* **UI Framework:** Flutter Web / responsive Material 3 with tokens defined in [`DESIGN.md`](file:///C:/proj/crafts/_bmad-output/planning-artifacts/ux-designs/ux-crafts-2026-10-14/DESIGN.md).
* **Role-Based Adaptation:** The interface adapts to the authenticated role:
  * **Administrator:** Full access to all modules, staff management, audit logs, and system settings.
  * **Recovery Officer:** Focused on assigned customer queues, logging contact attempts, tracking agreed payment dates, and monitoring recovery status.
  * **Finance Officer:** Focused on payment recording, transaction reconciliation, balance allocations, and financial report exports.

## Information Architecture

### Main Navigation (Desktop Sidebar / Mobile Drawer)

| Module / Screen | Primary Audience | Core Capabilities |
|---|---|---|
| **Dashboard** | All Staff | Financial summaries (Total Debt, Overdue, Recovered), recovery trends, and quick status charts. |
| **Customers** | All Staff | Searchable customer directory, customer creation/edit modal, profile details, and debt history. |
| **Debt Ledger** | All Staff | Centralized debt list, overdue indicators, days past due (DPD), and debt record creation form. |
| **Payments** | Finance & Admin | Payment entry form (full/partial), transaction reference logging, payment history, and receipt views. |
| **Recovery Activity** | Officers & Admin | History of contact attempts, call/visit notes, and scheduled follow-up dates (Promise-to-Pay). |
| **Reports** | Finance & Admin | Tabular financial & recovery reports with date/status filters, PDF export, and Excel (.xlsx) export. |
| **User Management** | Admin Only | Staff user list, role assignment (Admin, Recovery, Finance), user deactivation, and reset password. |
| **Audit Logs** | Admin Only | Immutable chronological log of user logins, debt adjustments, payments, and system events. |

## Voice and Tone

Microcopy is clear, objective, professional, and audit-compliant.

| Context | Recommended Copy (Do) | Discouraged Copy (Don't) |
|---|---|---|
| **Payment Recorded** | "Payment of $350.00 recorded. Transaction Ref: TXN-8921." | "Payment successful!" |
| **Overdue Debt** | "Account is 42 days past due. Follow-up scheduled for 2026-10-18." | "Customer is defaulting! Action needed!" |
| **Validation Error** | "Payment amount cannot exceed outstanding balance of $650.00." | "Invalid input entered." |
| **Report Generation** | "Generating monthly recovery summary (420 records)..." | "Please wait..." |
| **Permission Restriction** | "Access restricted to Finance and Administrator roles." | "You are not allowed here." |

## Component Patterns

### 1. Metric Overview Cards (Dashboard)
* Clean white card elevation with subtle slate border.
* Displays primary KPI in bold tabular figures (e.g. `$142,500.00`), secondary delta trend indicator (`+12% this month`), and semantic color accents (Emerald for recovered, Amber for approaching, Crimson for overdue).

### 2. Search, Filter & Pagination Bar
* Unified top toolbar on all table views:
  * Real-time text search input (matches customer name, phone number, debt ID, or transaction ref).
  * Dropdown filters for status (`Active`, `Overdue`, `Settled`, `Pending`) and date ranges.
  * Pagination footer showing *"Showing 1-25 of 148 records"* with previous/next controls and page size selector (`25`, `50`, `100`).

### 3. Payment Allocation Modal
* Two-step guided dialog for Finance Officers:
  1. *Amount & Method:* Enter amount collected, select method (`Cash`, `Bank Transfer`, `Check`), and enter transaction reference.
  2. *Allocation Preview:* Displays breakdown of how payment is applied against principal and interest, displaying updated remaining balance before submission.

### 4. Recovery Action Logging Sheet
* Slide-over panel accessible from any customer card or debt row:
  * Contact date and channel (`Phone Call`, `In-Person Visit`, `Email`, `SMS`).
  * Action outcome selector (`Spoke with Customer`, `Left Message`, `Payment Promised`, `Dispute Raised`).
  * Promised payment date & amount picker.
  * Notes area with character counter.

## Key Operational Flows

### Flow 1: Finance Officer Records and Verifies a Bank Payment
1. **Selection:** Finance Officer Elena opens the **Payments** module and clicks **+ Record Payment**.
2. **Search:** She types customer name "Marcus Vance" or invoice ref "INV-1092". The system returns Marcus's active debt showing `$1,200.00` outstanding.
3. **Entry:** Elena enters payment amount `$500.00`, selects `Bank Transfer`, and enters bank reference code `WIRE-99210`.
4. **Allocation & Confirmation:** The dialog displays: *"New remaining balance will be $700.00. Confirm allocation?"* Elena clicks **Confirm & Issue Receipt**.
5. **Outcome:** Balance updates immediately in the ledger, transaction is logged to the payment history with a unique ID, and an entry is written to the system audit log.

### Flow 2: Recovery Officer Follows Up on Overdue Accounts
1. **Review:** Recovery Officer David opens the **Debt Ledger** and clicks the `Overdue` filter.
2. **Prioritization:** David views accounts sorted by highest days past due.
3. **Contact & Log:** He clicks **Log Action** on customer "Sarah Jenkins". He records that Sarah agreed to pay $250 on Friday, October 20th.
4. **Follow-Up Scheduling:** David selects *Follow-Up Date: 2026-10-20* and clicks **Save Action**.
5. **Outcome:** The follow-up date is registered, and Sarah's account is scheduled for notification reminders.

### Flow 3: Administrator Generates Financial Export
1. **Report Selection:** Administrator Arthur navigates to the **Reports** module.
2. **Configuration:** Arthur selects report type *Monthly Recovery Summary*, selects date range *2026-10-01 to 2026-10-31*, and filters by *All Officers*.
3. **Preview & Export:** The system renders the summary table in under 2 seconds. Arthur clicks **Export Excel (.xlsx)** to download the report for the executive board.
