---
name: Debit Recovery System
status: final
sources:
  - {planning_artifacts}/briefs/brief-crafts-2026-10-14/brief.md
  - {planning_artifacts}/briefs/brief-crafts-2026-10-14/addendum.md
updated: 2026-10-14
---

# Debit Recovery System — Experience Specification

## Foundation

* **Form Factor & Surfaces:** Mobile-first application (iOS and Android with full feature parity via Flutter) for field recovery officers, complemented by a responsive web portal for back-office administrators and supervisors.
* **UI Framework:** Flutter Material 3 with custom tokens defined in [`DESIGN.md`](file:///C:/proj/crafts/_bmad-output/planning-artifacts/ux-designs/ux-crafts-2026-10-14/DESIGN.md).
* **Network Posture:** Offline-tolerant by design. Core queues, debtor contact cards, and logging actions operate seamlessly without network connectivity, syncing automatically via a local SQLite queue when connectivity resumes.

## Information Architecture

### Primary Navigation (Mobile Bottom Bar)

| Surface | Reached from | Purpose |
|---|---|---|
| **Queue** | App Open (Default tab) | Daily prioritized action list of assigned overdue accounts and today's PTP deadlines. |
| **Debtors** | Tab Bar | Searchable directory of all assigned debtor accounts, filterable by aging bracket (30/60/90+ DPD). |
| **Activity** | Tab Bar | Reverse-chronological timeline of logged calls, field visits, PTP notes, and payment receipts. |
| **Performance** | Tab Bar | Officer's personal progress toward monthly recovery targets, total cash collected, and sync status. |

### Modal & Secondary Surfaces

| Surface | Trigger | Purpose |
|---|---|---|
| **Debtor Detail** | Tap on any debtor card | Full balance breakdown, address/location, contact history, and past promise compliance. |
| **Quick Action Sheet** | Tap "Log Action" or card action | Slide-up bottom sheet to record phone calls, physical visits, or debtor negotiations in < 15 seconds. |
| **Record Payment Modal** | Tap "Record Payment" | Form to log collected cash or bank transfer with instant digital receipt generation. |
| **PTP Scheduler** | Action sheet option | Calendar and amount picker to register a debtor's Promise-to-Pay date with reminder alerts. |

## Voice and Tone

Microcopy in the Debit Recovery System is calm, objective, precise, and legally compliant. It avoids moralizing, debtor-shaming, or alarmist exclamation points.

| Do | Don't |
|---|---|
| "Promise-to-Pay due today ($450.00)" | "Debtor is late! Follow up now!" |
| "Payment recorded. Receipt #4092 generated." | "Success! Cash bagged!" |
| "3 actions saved offline. Will sync when connected." | "Network disconnected! Action failed." |
| "Customer requested follow-up on Friday, Oct 18." | "Debtor gave excuses again." |
| "Confirm partial payment of $200.00 against $1,200.00 balance?" | "Are you sure? You cannot undo this." |

## Component Patterns

### 1. Task Action Card (Queue Tab)
* **Visual Anchor:** Debtor name, total balance (e.g., `$1,850.00`), aging bracket pill (`60 DPD`).
* **Behavior:**
  * One-tap phone icon triggers system dialer; upon returning to app, prompts: *"Log outcome of call with [Name]?"*
  * Swipe right reveals quick "Record Payment" button.
  * Swipe left reveals "Reschedule PTP" button.

### 2. Quick Action Logger (Bottom Sheet)
* Opens in half-expanded bottom sheet; expands to full screen if typing extensive notes.
* Pre-selected outcome chips: `[Spoke with Debtor]` `[Left Message]` `[Location Visited / Not Home]` `[Payment Promised]` `[Dispute Raised]`.
* Submission immediately closes sheet, triggers subtle haptic feedback, and increments the daily completed task counter.

### 3. Payment Entry & Receipt Drawer
* Prominent currency input with instant balance recalculation preview (`Current: $1,200.00 - Payment: $300.00 = Remaining: $900.00`).
* Payment method selector: `[Cash In-Hand]` `[Direct Bank Transfer]` `[Mobile Money / Check]`.
* Confirmation button produces a shareable digital receipt (SMS / WhatsApp / PDF export).

## State Patterns

| State | Surface | Treatment |
|---|---|---|
| **Cold Open (Online)** | Queue | Instant load of local cache; background delta fetch with subtle spinner indicator in header. |
| **Cold Open (Offline)** | Queue | Loads cached tasks with persistent banner: *"Working Offline — 0 updates pending sync."* |
| **All Tasks Done** | Queue | Clean illustration: *"All priority tasks complete for today. Review upcoming PTPs in Debtors tab."* |
| **Offline Sync in Progress** | Global Header | Non-blocking pill: *"Syncing 4 updates..."* → smoothly turns green: *"All updates synced."* for 2 seconds. |
| **Conflicting Record** | Debtor Detail | If payment was recorded by back-office while officer was offline, alert displays: *"Balance updated by Admin at 10:15 AM."* |

## Interaction Primitives

* **One-Tap Dialing:** Tapping phone numbers instantly prompts native phone call and pre-arms the interaction logger upon app resume.
* **Haptic Affirmations:** Medium impact haptic on payment registration; light impact haptic on task completion.
* **Form Preservation:** If the user dismisses an action bottom sheet accidentally, drafts are retained for 30 minutes in memory.
* **Banned:** Autoplaying sounds, multi-level nested modals (max 1 modal layer deep), full-screen blocking loaders when offline.

## Accessibility Floor

* **Touch Target Size:** Minimum 48 x 48 dp on all clickable icons, buttons, and segmented pills.
* **Contrast Compliance:** All text meets WCAG AA minimum 4.5:1 against surfaces (Ink Primary `#0F172A` on `#FFFFFF` achieves 14.5:1).
* **Color Blindness Parity:** Every color badge (aging bracket, PTP warning) includes both a text label and an explicit icon (never color alone).
* **Dynamic Type Scaling:** Critical balance displays and debtor names remain legible up to 200% system font scaling.

## Key Flow: Field Recovery & Cash Collection

**Protagonist:** Marcus, an experienced field recovery officer in a busy municipal district.

1. **Morning Inspection (Queue):** Marcus opens the app in his car. His **Queue** displays 14 prioritized debtors. The top card is *David K.*, carrying a $750.00 balance that is 45 Days Past Due, with a Promise-to-Pay scheduled for today at 10:00 AM.
2. **On-Site Arrival:** Marcus drives to David's store. He taps the address on the card, opening his maps app. Upon arrival, he taps *David K.* in the queue.
3. **The Negotiation:** David explains business has been slow, but he can pay $300.00 in cash right now and promises to clear the remaining $450.00 next Tuesday.
4. **Recording the Payment:** Marcus taps the green **Record Payment** button. He enters `$300.00`, selects `Cash In-Hand`, and hands his phone to David to verify. David taps *Confirm*.
5. **Instant Receipt:** The app generates digital Receipt #8921. Marcus taps *Share Receipt via WhatsApp*, sending an official PDF confirmation to David's phone.
6. **Setting the New PTP:** The app immediately asks: *"David still has a remaining balance of $450.00. Set follow-up date?"* Marcus selects *Next Tuesday, 10:00 AM*, logs a brief note (*"Paid $300 cash, promised balance on Tuesday"*), and taps *Done*.
7. **The Climax & Progress:** The task smoothly animates off Marcus's daily queue with a celebratory progress badge (*"1 of 14 completed • $300.00 collected"*). His daily total updates on the **Performance** tab, and David K.'s new balance of $450.00 is stored locally, ready to sync back to head office.
