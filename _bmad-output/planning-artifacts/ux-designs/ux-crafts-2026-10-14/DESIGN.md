---
name: Debit Recovery System
status: final
updated: 2026-10-14
description: Mobile-first, trustworthy fintech design system for field debt recovery officers and credit managers.
colors:
  surface-base: '#F8FAFC'
  surface-raised: '#FFFFFF'
  ink-primary: '#0F172A'
  ink-secondary: '#475569'
  ink-disabled: '#94A3B8'
  brand-primary: '#0F172A'
  brand-accent: '#1E293B'
  accent-success: '#10B981'
  accent-warning: '#F59E0B'
  accent-danger: '#EF4444'
  accent-urgent: '#991B1B'
  border-subtle: '#E2E8F0'
  border-strong: '#CBD5E1'
  surface-base-dark: '#0B0F19'
  surface-raised-dark: '#151D2A'
  ink-primary-dark: '#F8FAFC'
  ink-secondary-dark: '#94A3B8'
  ink-disabled-dark: '#475569'
  border-subtle-dark: '#1E293B'
typography:
  display:
    note: 'Mobile Headline / Balance Display — 28sp / Bold / Tabular Numbers'
  title:
    note: 'Card Header / Section Title — 18sp / SemiBold'
  body:
    note: 'Primary Text / Input Fields — 15sp / Regular'
  meta:
    note: 'Timestamp / Caption / Badges — 12sp / Medium'
rounded:
  sm: 4px
  md: 8px
  lg: 16px
  pill: 9999px
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 24px
  '6': 32px
---

# Design System: Debit Recovery System

## Brand & Style

The Debit Recovery System pairs the authority and rigor of institutional banking with the speed and ergonomics required for field operations. Recovery officers work on mobile devices under varying outdoor lighting, during brief customer interactions, and often with single-hand thumb reach. 

The aesthetic is **Trustworthy Fintech**:
* **Deep Navy & Slate (`#0F172A`, `#1E293B`)** form the visual anchor, conveying operational seriousness and regulatory trust rather than gamified consumer tech.
* **Functional Color Signaling:** Color is never used for mere decoration. Every chromatic tint communicates a precise financial condition: **Emerald Green (`#10B981`)** for successful cash recovery, **Amber (`#F59E0B`)** for urgent Promise-to-Pay (PTP) commitments due today, and **Crimson (`#EF4444`)** for delinquent aging brackets (60–90+ DPD).
* **High Legibility in the Field:** Generous contrast ratios, large touch-friendly targets, and tabular numbers for financial figures ensure error-free data entry even in direct sunlight.

## Colors

### Light Mode (Default)
* **Surface Base (`#F8FAFC` - Slate 50):** Neutral, soft background reducing eye strain during extended outdoor usage.
* **Surface Raised (`#FFFFFF`):** High-contrast background for customer cards, bottom sheets, and detail modals.
* **Ink Primary (`#0F172A` - Slate 900):** Deep navy for primary headings, debt balances, and debtor names.
* **Ink Secondary (`#475569` - Slate 600):** Supporting labels, phone numbers, and past visit timestamps.
* **Border Subtle (`#E2E8F0`):** Hairline divider for list items and card borders.

### Semantic Status Colors
* **Recovered / Paid (`#10B981`):** Applied to cleared balances, payment confirmations, and daily collection totals.
* **Promise-to-Pay / Approaching (`#F59E0B`):** Applied to pending commitments, follow-ups scheduled for today, and 30-day aging.
* **Severe Overdue (`#EF4444` / `#991B1B`):** Applied to broken promises, accounts 60–90+ days past due, and escalation alerts.

## Typography

Typography prioritizes fast scanning and numerical accuracy. Monospace or tabular figure alignment is mandatory for all monetary sums.

* **Primary Font:** Native platform sans-serif (San Francisco on iOS, Roboto on Android, Inter on Flutter Web).
* **Monetary Figures:** `font-variant-numeric: tabular-nums` to ensure currency columns and balances align cleanly without jittering during updates.
* **Dynamic Type Support:** Text labels must expand gracefully up to 200% system accessibility scaling without clipping or breaking layout boundaries.

## Layout & Spacing

* **8-Point Spatial Grid:** All margins, paddings, and component heights adhere to multiples of 4px/8px (e.g., 4px, 8px, 12px, 16px, 24px, 32px).
* **Screen Edge Margins:** Standard 16px lateral padding on mobile viewports; 24px on tablet / desktop web views.
* **Thumb Zone Hierarchy:** High-frequency actions (Call Debtor, Log Visit, Record Payment) are pinned within the bottom 40% of the screen.

## Elevation & Depth

* **Level 0 (Flat):** Primary screen background (`#F8FAFC`).
* **Level 1 (Card Elevation):** 1px border (`#E2E8F0`) with subtle shadow `0 1px 3px rgba(15, 23, 42, 0.05)`. Used for task cards and debtor rows.
* **Level 2 (Modals & Bottom Sheets):** Shadow `0 10px 25px -5px rgba(15, 23, 42, 0.15)`. Used for quick-log sheets and receipt confirmations.

## Shapes

* **Cards & Containers:** `rounded-md` (8px) for clean, professional contours.
* **Bottom Sheets & Dialogs:** `rounded-lg` (16px) top radius for ergonomic slide-up sheets.
* **Status Chips & Aging Badges:** `rounded-pill` (fully rounded) for instant categorical recognition.

## Components

### 1. Daily Action Card
* Displays debtor name, total outstanding balance in bold tabular numbers, days past due (DPD) badge, and last contact note.
* Direct action buttons: one-tap phone call icon and one-tap log visit icon.

### 2. Aging Status Badge
* Compact pill with high contrast:
  * `0-30 DPD`: Slate fill with subtle border.
  * `31-60 DPD`: Amber tint with warning icon.
  * `61-90+ DPD`: Crimson tint with alert icon.

### 3. Quick Action Bottom Sheet
* Slide-up modal triggered during or immediately after a debtor encounter.
* Segmented control: `[Call] | [Field Visit] | [Payment] | [New PTP]`.
* Form inputs: Outcome selector (Reached, Refused, Paid, Left Message), Next Action Date picker, and brief note field.

### 4. Offline Sync Banner
* Persistent, non-blocking notification bar affixed beneath the app header:
  * *Syncing...* (animated spinner with count of queued logs).
  * *Offline — 3 logs queued locally* (amber pill, non-intrusive).

## Do's and Don'ts

### Do
* Display explicit currency symbols and localized delimiters (e.g., `$1,450.00`).
* Provide instant visual haptic feedback when a payment is logged or a task is swiped complete.
* Auto-save draft notes in bottom sheets so field officers never lose data if an incoming phone call interrupts them.

### Don't
* Don't use aggressive, punitive, or alarmist styling (e.g. flashing red sirens); maintain institutional decorum.
* Don't block user interaction when offline; all logging must happen locally with background sync.
* Don't bury phone numbers or physical addresses behind multiple navigation levels.
