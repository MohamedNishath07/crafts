---
title: Debit Recovery System - Product Requirements Document
status: final
created: 2026-10-14
updated: 2026-10-14
---

# Product Requirements Document (PRD): Debit Recovery System

## 0. Document Purpose

This document defines the functional and non-functional requirements for Version 1.0 (MVP) of the **Debit Recovery System**. It serves as the single source of truth for software engineers, UX designers, QA architects, and business stakeholders. This PRD directly builds upon the product vision established in [`brief.md`](file:///C:/proj/crafts/_bmad-output/planning-artifacts/briefs/brief-crafts-2026-10-14/brief.md) and the user experience contracts defined in [`DESIGN.md`](file:///C:/proj/crafts/_bmad-output/planning-artifacts/ux-designs/ux-crafts-2026-10-14/DESIGN.md) and [`EXPERIENCE.md`](file:///C:/proj/crafts/_bmad-output/planning-artifacts/ux-designs/ux-crafts-2026-10-14/EXPERIENCE.md).

---

## 1. Vision

The Debit Recovery System is a mobile-first, multi-tenant SaaS application that equips small-to-midsize businesses, micro-lenders, and credit departments to systematically recover delinquent receivables. By replacing error-prone spreadsheets with prioritized daily queues, real-time activity logging, Promise-to-Pay (PTP) tracking, and instant payment recording, the system maximizes recovered capital, shortens Days Past Due (DPD), and enforces operational accountability across field and desk collection teams.

---

## 2. Target Users & Jobs To Be Done

### 2.1 Jobs To Be Done (JTBD)

* **Field & Desk Recovery Officers:**
  * *Functional:* "When I start my workday, I want an unambiguous, ranked list of debtors to contact or visit, so I don't waste time figuring out who is most urgent."
  * *Functional:* "When a debtor gives me cash or confirms a bank transfer, I want to record it in under 30 seconds and issue an instant receipt, so they have proof and my daily quota is credited."
  * *Emotional:* "I want confidence that my logs won't be lost when working in low-reception areas."

* **Credit Managers & Supervisors:**
  * *Functional:* "When allocating overdue accounts, I want to assign portfolios to officers by aging bracket and monitor daily outreach adherence in real time."
  * *Contextual:* "When a customer disputes an interaction, I want an auditable timestamped history of every call, visit, and payment attempt."

* **Tenant Business Owners:**
  * *Financial:* "When managing company cash flow, I want to reduce bad-debt write-offs and accelerate liquidity without paying enterprise software licensing fees."

### 2.2 Non-Users (v1)

* **Debtors / Customers (Self-Service):** Debtor login portals, online customer payment accounts, and debtor dispute forms are explicitly out of scope for v1. All communication and payment recording is facilitated through recovery officers and administrators.
* **Third-Party Collection Agencies / Law Firms:** External agency bidding, litigation tracking, and court summons management are deferred to later releases.

### 2.3 Key User Journeys

#### UJ-1: Field Collection & Instant Receipting
* **Persona & Context:** Marcus, a field recovery officer on mobile, visiting a physical retail customer in a commercial district.
* **Entry State:** Authenticated on mobile app; local cache loaded with today's queue.
* **Path:**
  1. Marcus opens the **Queue** tab and taps the top card: *David K.* (45 DPD, $750.00 balance, PTP due today).
  2. Marcus taps the address to launch navigation, arrives on-site, and speaks with David.
  3. David offers $300.00 cash today and agrees to pay the remaining $450.00 next Tuesday.
  4. Marcus taps **Record Payment**, inputs `$300.00`, selects `Cash In-Hand`, and taps *Confirm*.
  5. The system generates digital Receipt #8921. Marcus taps *Share Receipt via WhatsApp*, sending an instant PDF receipt to David's phone.
  6. Marcus schedules the follow-up PTP for *Next Tuesday at 10:00 AM* with note *"Paid $300 cash; balance on Tuesday"*.
* **Climax:** The balance updates to `$450.00` immediately on screen, the card clears from the daily queue, and Marcus's collected total increases by `$300.00`.
* **Resolution:** David K. is marked as PTP Scheduled; Marcus moves to the next debtor on his list.
* **Edge Case (Offline):** If Marcus has no mobile data reception in the building, the payment and receipt are saved to the local SQLite sync queue, and the app displays: *"Receipt #8921 generated offline — queued for cloud sync"*.

#### UJ-2: Desk Collector Follow-Up & PTP Scheduling
* **Persona & Context:** Sarah, an in-office recovery officer managing phone outreach for 30-day overdue micro-loans.
* **Entry State:** Mobile app / tablet view on desk stand.
* **Path:**
  1. Sarah filters her queue by `30 DPD (Approaching)`.
  2. She taps the phone icon on debtor *Elena Rostova*. The app invokes the native phone dialer.
  3. Elena answers, acknowledges the invoice, and promises to transfer the full $220.00 balance on Friday after payday.
  4. Sarah returns to the app. A slide-up prompt asks: *"Log outcome of call with Elena Rostova?"*
  5. Sarah taps `[Spoke with Debtor]`, selects `[Payment Promised]`, picks *Friday 5:00 PM*, sets amount `$220.00`, and hits *Save*.
* **Climax:** The call timestamp, call duration, and scheduled PTP are written to Elena's activity timeline.
* **Resolution:** Elena's card is deferred from today's active queue and scheduled to reappear automatically on Friday morning.

#### UJ-3: Supervisor Portfolio Review & Officer Assignment
* **Persona & Context:** Arthur, Credit Operations Manager, reviewing monthly aging distribution on web/tablet.
* **Entry State:** Authenticated as Tenant Admin.
* **Path:**
  1. Arthur views the **Recovery Dashboard** and sees $42,000 in the `61-90 DPD` critical bucket.
  2. He opens the **Debtors** management view, multi-selects 25 unassigned accounts over 60 DPD, and assigns them to Marcus.
  3. Arthur exports the monthly recovery summary CSV for the finance director.
* **Climax:** Marcus's mobile app receives the new assignments on his next sync; Arthur sees real-time officer workload distribution.

---

## 3. Glossary

* **Tenant:** An individual subscribing organization (business, lender, or credit department) with dedicated, isolated data.
* **Customer / Debtor:** An individual or enterprise that owes an outstanding financial balance to the Tenant.
* **Debt Record:** An individual debt obligation with a principal balance, origin date, due date, interest/penalties, and current status (`Active`, `PTP Scheduled`, `Settled`, `Written Off`).
* **Days Past Due (DPD):** The number of calendar days elapsed since a debt record's original due date.
* **Aging Bucket:** Categorical risk classification based on DPD:
  * `Current` (0 DPD)
  * `1-30 DPD` (Approaching / Early Delinquency)
  * `31-60 DPD` (Moderate Delinquency)
  * `61-90 DPD` (Severe Delinquency)
  * `90+ DPD` (Critical / Default Risk)
* **Promise-to-Pay (PTP):** A formal commitment by a debtor to pay a specific sum on or before a specified calendar date and time.
* **Broken Promise:** A PTP where the scheduled commitment date and grace period have expired without a recorded payment.
* **Recovery Officer:** An operational user responsible for contacting debtors, conducting field visits, and collecting payments.
* **Interaction Log:** An immutable audit record of a communication attempt (phone call, field visit, WhatsApp message, office meeting).
* **Payment Record:** A financial transaction crediting an outstanding debt balance with amount, payment method, timestamp, and collector ID.
* **Digital Receipt:** A uniquely numbered confirmation document generated upon payment recording that can be shared via SMS, WhatsApp, or email.

---

## 4. Features & Functional Requirements

### 4.1 Tenant Onboarding & Access Control

**Description:** Multi-tenant organization setup supporting role-based access control (RBAC). Admins manage staff, configuration, and portfolio assignments; Recovery Officers access assigned debtor queues and field logging capabilities. Realizes UJ-3.

#### FR-1: Tenant Account Registration
* **Capability:** A business administrator can register a new tenant organization with company name, default currency [ASSUMPTION: default ISO 4217 currency chosen at signup], contact email, and admin password.
* **Consequences (testable):**
  * System creates an isolated tenant schema/ID.
  * Duplicate organization email registrations return HTTP 409 Conflict.
  * System sends email verification token.

#### FR-2: Role-Based User Management
* **Capability:** An Admin can invite team members and assign roles: `Admin` (full access) or `Recovery Officer` (scoped to assigned debtor queues).
* **Consequences (testable):**
  * Recovery Officers cannot view debts or customer profiles outside their assigned queue or unassigned pool.
  * Recovery Officers cannot delete debt records, modify tenant billing, or alter audit logs.

---

### 4.2 Customer & Debt Ledger Management

**Description:** Centralized registry of customer profiles and overdue debt obligations. Tracks principal balances, interest/penalties, and real-time aging buckets. Realizes UJ-1, UJ-2, UJ-3.

#### FR-3: Customer Profile Registry
* **Capability:** Users can create and edit customer profiles including full name, phone number, secondary phone, email, physical street address, GPS coordinates [ASSUMPTION: optional capture], and national ID / tax ID.
* **Consequences (testable):**
  * Phone numbers are validated against E.164 international format.
  * Customer profile search by name, phone, or ID returns results within 200ms.

#### FR-4: Debt Record Creation & Lifecycle
* **Capability:** Admins can create debt records associated with a customer, specifying original amount, balance outstanding, original due date, loan/invoice reference number, and interest/late penalty rules.
* **Consequences (testable):**
  * Debt balance cannot be negative.
  * System updates debt status to `Settled` automatically when remaining balance reaches zero.

#### FR-5: Automated Aging Calculation
* **Capability:** The system daily recalculates DPD (Days Past Due) and assigns each debt record to its appropriate Aging Bucket (`1-30`, `31-60`, `61-90`, `90+` DPD).
* **Consequences (testable):**
  * At 00:00 UTC daily, debts transition across buckets based on `current_date - due_date`.
  * Bucket transitions generate an audit event in the debt history log.

---

### 4.3 Assignment & Prioritized Mobile Task Queue

**Description:** The operational core of the mobile application. Presents recovery officers with a clear, ranked daily task queue based on urgency, broken promises, and aging risk. Realizes UJ-1, UJ-2.

#### FR-6: Portfolio & Account Assignment
* **Capability:** Admins can assign individual debts or bulk customer accounts to specific recovery officers.
* **Consequences (testable):**
  * Debtor card immediately reflects assigned officer ID and timestamp.
  * Mobile client fetches assigned accounts on the next delta sync.

#### FR-7: Prioritized Daily Task Queue
* **Capability:** The mobile app's **Queue** tab displays an automatically prioritized list of accounts requiring action today.
* **Consequences (testable):**
  * Priority ordering is strictly enforced:
    1. Broken PTPs (overdue commitment dates).
    2. PTPs due today.
    3. Severe delinquency (90+ DPD).
    4. Delinquency (60 DPD, 30 DPD).
    5. Routine follow-ups.
  * Completed actions (recorded payment or logged interaction with future PTP) immediately remove the card from the active daily view.

---

### 4.4 Field Interaction & Promise-to-Pay (PTP) Engine

**Description:** Fast, thumb-friendly interaction logging allowing officers to record calls, physical visits, debtor responses, and PTP commitments. Realizes UJ-1, UJ-2.

#### FR-8: One-Tap Calling & Quick-Log Bottom Sheet
* **Capability:** Recovery officers can tap a phone icon to trigger native calling, and tap "Log Visit" or "Log Call" to open an action sheet with outcome chips (`Spoke with Debtor`, `Left Message`, `Not Home`, `Payment Promised`, `Dispute Raised`).
* **Consequences (testable):**
  * Form requires selecting at least one outcome chip before submission.
  * Note field supports up to 1,000 characters.
  * Submission creates an immutable, timestamped Interaction Log linked to the debtor and officer.

#### FR-9: Promise-to-Pay (PTP) Scheduling
* **Capability:** When logging an interaction, the officer can record a debtor's Promise-to-Pay, including scheduled payment date/time and promised amount.
* **Consequences (testable):**
  * Scheduled date must be in the future.
  * Promised amount cannot exceed remaining balance.
  * Debt record status changes to `PTP Scheduled`.
  * Mobile client registers a local device reminder notification 2 hours prior to scheduled PTP.

#### FR-10: Broken Promise Escalation
* **Capability:** If a PTP expires without a corresponding payment recorded, the system flags the debt as `Broken PTP`.
* **Consequences (testable):**
  * Account is escalated to the top of the officer's priority queue with crimson visual indicator.
  * Admin recovery dashboard increments the `Broken PTP` counter.

---

### 4.5 Payment Recording & Digital Receipts

**Description:** Mobile payment capture for full or partial settlements, immediate ledger balance deflation, and instant verifiable receipt sharing. Realizes UJ-1.

#### FR-11: Payment Recording Form
* **Capability:** Officers can record payments by specifying amount, payment method (`Cash In-Hand`, `Bank Transfer`, `Mobile Money / Check`), and optional transaction/reference ID.
* **Consequences (testable):**
  * Payment amount must be greater than zero and cannot exceed total balance without explicit admin overpayment override.
  * Creates an immutable Payment Record containing officer ID, device timestamp, and geolocation [ASSUMPTION: captured if permission granted].

#### FR-12: Instant Balance Deflation
* **Capability:** Upon payment submission, the system decrements the customer's outstanding balance in real time (or locally if offline).
* **Consequences (testable):**
  * `remaining_balance = previous_balance - payment_amount`.
  * If `remaining_balance == 0`, status changes to `Settled`.
  * If `remaining_balance > 0`, system prompts officer to set a follow-up PTP for the remainder.

#### FR-13: Digital Receipt Generation & Sharing
* **Capability:** Submitting a payment instantly generates a digital receipt with unique alphanumeric receipt ID, timestamp, debtor name, amount paid, remaining balance, and officer signature/name.
* **Consequences (testable):**
  * Displays one-tap sharing buttons: `Share via WhatsApp`, `Share via SMS`, and `View/Export PDF`.
  * Receipt cannot be deleted or altered once generated.

---

### 4.6 Offline Sync Engine

**Description:** Local database caching ensuring full field operability without cellular connectivity, with idempotent background synchronization. Realizes UJ-1.

#### FR-14: Local Offline Queue & Storage
* **Capability:** The Flutter mobile application caches assigned debtor profiles, priority queue tasks, and active PTPs in local encrypted SQLite/Drift storage.
* **Consequences (testable):**
  * Officers can view queues, search debtors, record payments, and log visits with zero active network connection.
  * App displays a persistent non-blocking header pill: *"Offline — N updates queued"*.

#### FR-15: Idempotent Synchronization Protocol
* **Capability:** When connectivity is restored, the mobile app automatically syncs queued actions to the server in chronological order.
* **Consequences (testable):**
  * Every offline event carries a client-generated UUID (UUIDv4) and client ISO 8601 timestamp.
  * Server processes requests idempotently: duplicate UUID transmissions do not create duplicate payments or duplicate logs.
  * On completion, header banner shows *"All updates synced"* in green for 2 seconds before dismissing.

---

### 4.7 Performance Analytics & Reporting

**Description:** Real-time visibility into collection rates, team outreach volume, and portfolio aging distributions for supervisors and executives. Realizes UJ-3.

#### FR-16: Officer Recovery Leaderboard & Daily Stats
* **Capability:** The **Performance** tab displays the logged-in officer's daily and monthly collection stats: total cash recovered, total visits logged, and PTP adherence rate.
* **Consequences (testable):**
  * Metrics update immediately upon payment confirmation.

#### FR-17: Portfolio Aging Distribution Dashboard
* **Capability:** Admin web dashboard displays visual breakdown of total receivables across the 5 aging buckets (`Current`, `1-30`, `31-60`, `61-90`, `90+` DPD).
* **Consequences (testable):**
  * Clicking an aging bracket filters the debtor list to that cohort.

#### FR-18: Audit Trail & CSV Export
* **Capability:** Admins can export filtered payment records, customer ledgers, and officer interaction histories to CSV/Excel format.
* **Consequences (testable):**
  * Export generation of up to 10,000 records completes in under 3 seconds.

---

## 5. Non-Goals (Explicit)

* **No Automated Bank Account Debiting (ACH/SEPA/Direct Debit):** The system does not pull funds directly from debtor checking accounts; all payments are initiated via officer collection or debtor transfer in v1.
* **No Inbound Automated AI Voice Dialer:** No predictive robocalling or automated IVR dialer bots.
* **No Direct Debtor Login Portal:** Debtors cannot create accounts or log in via browser to view accounts in v1.
* **No Legal Litigation Automation:** Generating court affidavits, formal legal summons, or automated judicial filings is excluded.
* **No Credit Bureau Direct Reporting:** Live automated transmission of default records to credit bureaus is deferred to v2.

---

## 6. MVP Scope Matrix

| Capability | In Scope (v1 MVP) | Out of Scope (Deferred to v2+) |
|---|:---:|:---:|
| Multi-tenant organization registration | **Yes** | |
| Role-based access control (Admin, Officer) | **Yes** | |
| Customer and debt record management | **Yes** | |
| Dynamic 30/60/90+ DPD aging buckets | **Yes** | |
| Officer account assignment | **Yes** | |
| Daily mobile priority action queue | **Yes** | |
| One-tap calling & visit interaction logging | **Yes** | |
| Promise-to-Pay (PTP) scheduling & alerts | **Yes** | |
| Broken PTP escalation flags | **Yes** | |
| Cash & transfer payment recording | **Yes** | |
| Instant digital receipt generation & WhatsApp sharing | **Yes** | |
| Offline local caching & idempotent sync | **Yes** | |
| Officer personal performance tab | **Yes** | |
| Admin portfolio aging dashboard | **Yes** | |
| CSV data exports | **Yes** | |
| Debtor self-service payment gateway (Stripe/PayPal) | | **Deferred (v2)** |
| Automated SMS/WhatsApp dunning campaigns | | **Deferred (v2)** |
| Direct bank auto-debit sweeps | | **Deferred (v2)** |
| Credit bureau reporting integrations | | **Deferred (v3)** |
| Machine learning recovery likelihood scoring | | **Deferred (v3)** |

---

## 7. Success Metrics & Counter-Metrics

### Primary Success Metrics
1. **Total Capital Recovered:** Target **15% to 25% increase** in recovered overdue debt for tenant businesses within 90 days of onboarding.
2. **PTP Fulfillment Rate:** Over **75% of scheduled Promises-to-Pay** successfully converted into recorded payments.
3. **Field Logging Compliance:** **100% of physical customer visits** recorded digitally within 2 hours of occurrence.
4. **Time-to-Log Interaction:** Median time to open app, select debtor, and submit a visit/call log is **under 20 seconds**.

### Health & Counter-Metrics
* **Receipt Dispute Rate (Counter-Metric):** Customer payment disputes must remain below **0.1% of total transactions**, verifying that digital receipts prevent embezzlement and reconciliation errors.
* **Broken Promise Rate (Counter-Metric):** Broken PTPs should not exceed **25%** of scheduled commitments; higher rates trigger supervisory queue review for unrealistic payment plans.
* **Sync Conflict Rate:** Offline conflict resolutions must remain below **0.05% of total sync batches**.

---

## 8. Cross-Cutting Non-Functional Requirements (NFRs)

### 8.1 Security & Multi-Tenancy Isolation
* **Tenant Isolation:** Complete logical isolation between tenant datasets via tenant-scoped database schemas or strict Row-Level Security (RLS) enforcement. Under no circumstances may data from Tenant A leak to Tenant B.
* **Data Encryption:** AES-256 encryption at rest for local SQLite storage and server databases; TLS 1.3 in transit for all network API traffic.
* **Authentication:** Secure JWT bearer tokens with short expiry (1 hour) and refresh token rotation. Biometric unlock (Fingerprint / FaceID) supported on mobile clients.

### 8.2 Performance & Responsiveness
* **Local UI Responsiveness:** App cold-start to interactive Queue state in **< 1.5 seconds** using cached local data.
* **Search Latency:** Debtor directory searching and filtering executes in **< 100ms** on datasets of up to 5,000 debtor records per officer.
* **API Response Time:** 95th percentile (p95) API response time **< 250ms** for all sync and logging endpoints.

### 8.3 Reliability & Offline Resilience
* **Network Tolerance:** Zero data loss when actions are performed offline. Local sync queue persists across app restarts, device crashes, and battery depletion.
* **Battery & Data Conservation:** Background sync uses efficient binary or compressed JSON payloads, minimizing cellular data consumption in the field.

### 8.4 Regulatory Compliance & Auditability
* **Immutable Audit Trail:** Interaction logs, payment entries, and user timestamps cannot be edited or hard-deleted by any user (append-only ledger).
* **Communication Window Guardrails:** System warns officers if an outreach call or visit is logged outside legal contact hours (e.g., before 8:00 AM or after 9:00 PM local time).
