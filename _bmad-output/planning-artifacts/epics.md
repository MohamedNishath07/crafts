---
title: Epics and User Stories - Debit Recovery System
status: final
created: 2026-10-14
updated: 2026-10-14
stepsCompleted: [1, 2, 3, 4]
---

# Epics & User Stories: Debit Recovery System

## 1. Overview & Requirements Traceability

This document defines the 7 user-value Epics and 19 User Stories for Version 1.0 of the Debit Recovery System. It maps directly to the 18 Functional Requirements (FR-01 to FR-18), the 3 roles (**Administrator**, **Recovery Officer**, **Finance Officer**), and the responsive web architecture.

### Requirements Coverage Matrix

| Epic | Scope | FR Coverage | Roles Involved |
|---|---|---|---|
| **Epic 1: Authentication, User Management & RBAC** | Login, staff accounts, role permissions, profile settings | FR-01, FR-02, FR-17, FR-18 | Administrator, All Staff |
| **Epic 2: Customer Registry & Debt Ledger** | Customer profiles, debt creation, overdue identification, DPD | FR-03, FR-04, FR-05, FR-06, FR-13 | All Staff |
| **Epic 3: Payment Capture & Allocation** | Full/partial payments, balance deflation, transaction refs | FR-05, FR-07, FR-08, FR-13 | Finance Officer, Admin |
| **Epic 4: Recovery Activities & Reminders** | Action logs, follow-up dates, email/SMS reminder service | FR-09, FR-10 | Recovery Officer, Admin |
| **Epic 5: Management Dashboard & Charts** | KPI cards (totals, overdue, recovered), recovery trends | FR-11, FR-12 | All Staff |
| **Epic 6: Financial Reports & PDF/Excel Export** | Tabular reports, date filtering, PDF and Excel exports | FR-13, FR-14, FR-15 | Finance Officer, Admin |
| **Epic 7: Audit Logging & Governance** | Append-only audit logs, user action tracking | FR-16, FR-18 | Administrator |

---

## Epic 1: Authentication, User Management & RBAC

### Story 1.1: Supabase Database Schema & Multi-Tenant RLS Policies
* **User Value:** As an organization owner, I want our data isolated by tenant so that no unauthorized entity can read our financial records.
* **Requirements Covered:** FR-01, FR-02, FR-18, AD-1.
* **Acceptance Criteria:**
  1. **Given** a new Supabase database, **when** migrations run, **then** `tenants`, `profiles`, `customers`, `debts`, `payments`, `interaction_logs`, and `audit_logs` are created.
  2. **Given** an authenticated user session, **then** Row-Level Security automatically enforces `tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid`.
  3. **Given** a non-admin role, **when** attempting to query or modify user permissions, **then** Supabase rejects the query with 403 Forbidden.

### Story 1.2: User Authentication & Role-Based Navigation Guards
* **User Value:** As a staff member, I want to log in securely with my email and password so that I can access my designated role workspace.
* **Requirements Covered:** FR-01, FR-18, AD-2.
* **Acceptance Criteria:**
  1. **Given** valid credentials, **when** submitting the login form, **then** an authenticated session is created and the user is routed to the Dashboard.
  2. **Given** a user with the `recovery_officer` role, **when** attempting to access the User Management or Audit Log routes, **then** the router redirects with an unauthorized message.
  3. **Given** an active session, **when** the user clicks Logout, **then** the session token is invalidated and the login screen is displayed.

### Story 1.3: Administrator Staff Management & Role Allocation
* **User Value:** As an Administrator, I want to create, edit, and deactivate staff accounts so that I can control who has access to the system.
* **Requirements Covered:** FR-02, FR-18.
* **Acceptance Criteria:**
  1. **Given** the Administrator on the **User Management** screen, **when** submitting a new staff user form (email, full name, role: `admin`, `recovery_officer`, `finance_officer`), **then** the account is created and an invitation/temporary password is generated.
  2. **Given** an active staff member, **when** clicking *Deactivate User*, **then** their status changes to inactive and their access token is revoked immediately.

### Story 1.4: User Profile Settings & Password Change
* **User Value:** As a staff user, I want to update my profile information and change my password securely.
* **Requirements Covered:** FR-17.
* **Acceptance Criteria:**
  1. **Given** the **Profile Settings** screen, **when** entering a new name or phone number, **then** changes are saved upon clicking *Save Changes*.
  2. **Given** the password change form, **when** submitting current password and a compliant new password (min 8 chars, mixed case/numbers), **then** the password is updated and verified.

---

## Epic 2: Customer Registry & Debt Ledger

### Story 2.1: Customer Registration, Search, and Profile Management
* **User Value:** As an authorized staff member, I want to register and search customer records so that all debtor contact details are organized.
* **Requirements Covered:** FR-03, FR-13.
* **Acceptance Criteria:**
  1. **Given** the **Customers** screen, **when** submitting the customer form (Name, Primary Phone, Email, National ID, Address), **then** a new customer profile is saved.
  2. **Given** the customer list, **when** typing into the search bar, **then** results filter in real time (< 100ms) matching name, phone, or ID.
  3. **Given** a customer record, **then** pagination displays records in batches of 25, 50, or 100.

### Story 2.2: Debt Record Creation & Principal Balance Management
* **User Value:** As an authorized user, I want to create debt records with principal amounts and due dates so that we can track who owes what.
* **Requirements Covered:** FR-04, FR-05.
* **Acceptance Criteria:**
  1. **Given** an existing customer, **when** creating a debt record with principal amount, origin date, due date, and reference invoice ID, **then** the record is created with initial `remaining_balance = principal_amount`.
  2. **Given** required fields (customer, amount, due date), **then** submission is blocked with descriptive validation if any required field is empty.

### Story 2.3: Overdue Debt Identification & Days Past Due (DPD) Calculation
* **User Value:** As a recovery officer, I want overdue debts highlighted automatically so that I immediately know which accounts require action.
* **Requirements Covered:** FR-05, FR-06, FR-13.
* **Acceptance Criteria:**
  1. **Given** a debt where `current_date > due_date` and `remaining_balance > 0`, **then** the system tags the debt as `Overdue` with calculated `days_past_due`.
  2. **Given** the Debt Ledger, **when** selecting the `Overdue` filter chip, **then** only delinquent accounts are displayed, sorted by highest DPD.

---

## Epic 3: Payment Capture, Allocation & Transaction History

### Story 3.1: Payment Recording Form for Full & Partial Settlements
* **User Value:** As a Finance Officer, I want to record payments collected from customers so that our financial ledgers are up to date.
* **Requirements Covered:** FR-07, FR-08.
* **Acceptance Criteria:**
  1. **Given** the **Record Payment** modal, **when** selecting a customer debt, entering amount, selecting payment method (`Cash`, `Bank Transfer`, `Check`), and entering transaction reference, **then** the payment is saved.
  2. **Given** an entered amount, **when** the amount exceeds the outstanding balance, **then** the system prevents submission unless marked as an approved adjustment.

### Story 3.2: Atomic Balance Allocation & Ledger Deflation
* **User Value:** As a financial controller, I want the customer's balance reduced atomically when a payment is saved so that records are 100% accurate.
* **Requirements Covered:** FR-05, FR-07, AD-5.
* **Acceptance Criteria:**
  1. **Given** a payment submission, **then** a PostgreSQL transaction decrements `debts.remaining_balance` and inserts the `payments` record atomically.
  2. **Given** remaining balance reaches zero, **then** the debt status updates automatically to `Settled`.
  3. **Given** 100 simulated test transactions, **then** balance calculation achieves 100% accuracy.

### Story 3.3: Payment History & Transaction Reference Ledger
* **User Value:** As a Finance Officer, I want a complete, searchable history of all payments with transaction references so that reconciliations are transparent.
* **Requirements Covered:** FR-08, FR-13, AD-4.
* **Acceptance Criteria:**
  1. **Given** the **Payments** screen, **then** a paginated table lists payment date, customer name, amount paid, payment method, transaction reference, and recording officer.
  2. **Given** the payments table, **then** records are strictly immutable (`UPDATE` and `DELETE` actions are blocked).

---

## Epic 4: Recovery Activity Tracking & Reminder Notifications

### Story 4.1: Recovery Action Logging & Interaction History
* **User Value:** As a Recovery Officer, I want to record customer calls, visits, and notes so that our team has a clear history of collection efforts.
* **Requirements Covered:** FR-09, AD-4.
* **Acceptance Criteria:**
  1. **Given** a customer or debt record, **when** clicking **Log Action**, **then** a dialog allows recording contact date, channel (`Call`, `Visit`, `Email`, `SMS`), outcome status, and detailed notes.
  2. **Given** submission, **then** the interaction is appended to the customer's chronological recovery timeline.

### Story 4.2: Agreed Follow-Up Date Scheduling (Promise-to-Pay)
* **User Value:** As a Recovery Officer, I want to record promised payment dates so that I am reminded to follow up on agreed commitments.
* **Requirements Covered:** FR-09.
* **Acceptance Criteria:**
  1. **Given** logging an interaction, **when** entering a future follow-up date and promised amount, **then** the debt status updates to `PTP Scheduled`.
  2. **Given** the recovery screen, **when** filtering by `Follow-Up Today`, **then** all accounts with commitments scheduled for the current date are displayed.

### Story 4.3: Configurable Email and SMS Payment Reminders
* **User Value:** As an Administrator, I want the system to send automated payment reminders to customers via email or SMS so that customers pay before becoming overdue.
* **Requirements Covered:** FR-10.
* **Acceptance Criteria:**
  1. **Given** the reminder configuration settings, **when** an admin enables email/SMS notifications and sets reminder cadences (e.g., 3 days before due date, on due date), **then** the configuration is saved.
  2. **Given** an approaching due date or upcoming PTP, **when** the scheduled reminder trigger executes, **then** a formatted notification with outstanding balance and payment instructions is dispatched.

---

## Epic 5: Management Dashboard & Financial Charts

### Story 5.1: Real-Time Summary Metric Cards
* **User Value:** As an Administrator or Manager, I want to see key summary metrics upon logging in so that I immediately grasp our portfolio health.
* **Requirements Covered:** FR-11.
* **Acceptance Criteria:**
  1. **Given** the **Dashboard**, **then** 4 primary KPI cards render: Total Customers, Total Outstanding Debt, Total Overdue Amount, and Total Recovered Amount.
  2. **Given** a dataset of up to 10,000 records, **then** all dashboard metrics load in under 3 seconds.

### Story 5.2: Recovery Trends & Payment Status Breakdown Charts
* **User Value:** As a Finance Officer, I want visual charts of collection trends so that I can evaluate our monthly recovery performance.
* **Requirements Covered:** FR-12.
* **Acceptance Criteria:**
  1. **Given** the Dashboard, **then** an interactive line/bar chart displays monthly recovery volume over the past 6 months.
  2. **Given** the payment status breakdown, **then** a donut chart illustrates the proportion of debts in `Current`, `Overdue`, and `Settled` states.

---

## Epic 6: Financial Reporting & PDF / Excel Export

### Story 6.1: Tabular Report Generator with Date & Status Filters
* **User Value:** As a Finance Officer, I want to generate custom tabular reports by date range and account status so that I can review detailed recovery performance.
* **Requirements Covered:** FR-13, FR-14.
* **Acceptance Criteria:**
  1. **Given** the **Reports** screen, **when** selecting date range, debt status (`Overdue`, `Settled`, `All`), and officer filter, **then** a formatted report table renders in under 5 seconds.
  2. **Given** the generated report, **then** summary totals (Total Billed, Total Collected, Total Outstanding) calculate at the footer of the table.

### Story 6.2: PDF Report Generation & Download
* **User Value:** As an executive, I want to download printable PDF summaries for board presentations and formal documentation.
* **Requirements Covered:** FR-15.
* **Acceptance Criteria:**
  1. **Given** a generated report preview, **when** clicking **Export PDF**, **then** a formatted PDF document with company header, filter criteria, and data table is generated and downloaded.

### Story 6.3: Excel (.xlsx) Spreadsheet Export Engine
* **User Value:** As an accountant, I want to export recovery data to Excel so that I can perform deeper analysis and import into external accounting systems.
* **Requirements Covered:** FR-15.
* **Acceptance Criteria:**
  1. **Given** a generated report preview, **when** clicking **Export Excel**, **then** a clean `.xlsx` spreadsheet with formatted column types and numerical totals is downloaded in < 3 seconds.

---

## Epic 7: System Auditability & Security Governance

### Story 7.1: Immutable System Audit Logging Engine
* **User Value:** As an Auditor, I want critical actions logged automatically so that every modification has a verifiable trail.
* **Requirements Covered:** FR-16, AD-4.
* **Acceptance Criteria:**
  1. **Given** a user creating a customer, modifying debt terms, recording a payment, or deactivating a staff account, **then** the system writes an entry to `audit_logs` containing `user_id`, `action`, `entity_type`, `entity_id`, and `timestamp`.
  2. **Given** the `audit_logs` table, **then** `UPDATE` and `DELETE` permissions are revoked for all users.

### Story 7.2: Audit Log Viewer & Security Activity Filter
* **User Value:** As an Administrator, I want to search and filter audit logs so that I can investigate suspicious activity or review team actions.
* **Requirements Covered:** FR-16, FR-18.
* **Acceptance Criteria:**
  1. **Given** an Administrator on the **Audit Logs** screen, **then** a chronological timeline displays recent actions with user email and timestamp.
  2. **Given** search/filter criteria (by user, action type, or date), **then** matching audit events are displayed with pagination.
