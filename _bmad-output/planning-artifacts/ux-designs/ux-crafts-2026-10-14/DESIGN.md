---
name: Debit Recovery System
status: final
updated: 2026-10-14
description: Trustworthy fintech design system for responsive desktop, tablet, and mobile web browsers.
colors:
  surface-base: '#F8FAFC'
  surface-raised: '#FFFFFF'
  surface-sidebar: '#0F172A'
  ink-primary: '#0F172A'
  ink-secondary: '#475569'
  ink-disabled: '#94A3B8'
  brand-primary: '#0F172A'
  brand-accent: '#1E293B'
  accent-success: '#10B981'
  accent-warning: '#F59E0B'
  accent-danger: '#EF4444'
  accent-info: '#0284C7'
  border-subtle: '#E2E8F0'
  border-strong: '#CBD5E1'
typography:
  display:
    note: 'Dashboard Metrics & Totals — 28sp / Bold / Tabular Numbers'
  title:
    note: 'Page Headers & Table Columns — 18sp / SemiBold'
  body:
    note: 'Data Rows & Form Fields — 14sp / Regular'
  meta:
    note: 'Timestamps & Status Badges — 12sp / Medium'
rounded:
  sm: 4px
  md: 8px
  lg: 12px
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

The Debit Recovery System pairs institutional financial authority with clear data visualization and operational speed. As a **Responsive Web Application**, it adapts seamlessly across desktop workstations, tablet screens, and mobile browser viewports.

* **Visual Identity:** **Trustworthy Fintech** — anchored by Deep Slate and Navy (`#0F172A`, `#1E293B`) for navigation sidebars and headers, paired with crisp white card surfaces (`#FFFFFF`) on a subtle neutral canvas (`#F8FAFC`).
* **Semantic Signaling:**
  * **Emerald Green (`#10B981`):** Cleared accounts, verified payments, and positive recovery targets.
  * **Amber (`#F59E0B`):** Approaching due dates, scheduled follow-ups, and pending verifications.
  * **Crimson / Rose (`#EF4444`):** Past-due debts, broken promises, and critical delinquency alerts.
* **Information Density:** High-density, scannable data tables on desktop viewports; collapsible card lists on mobile viewports. All financial columns use tabular figures (`tabular-nums`) to ensure vertical alignment of digits.

## Layout & Responsive Breakpoints

* **Desktop Viewport (>= 1024px):** Fixed left navigation sidebar (240px wide), top application bar with search and user profile menu, multi-column dashboard grid, paginated data tables with sticky headers.
* **Tablet Viewport (768px – 1023px):** Collapsible navigation rail (icon-only or drawer), 2-column metric cards, responsive tables with horizontal scroll.
* **Mobile Viewport (< 768px):** Off-canvas hamburger drawer navigation, single-column card feeds, slide-up modal bottom sheets for payment and interaction logging.

## Core UI Components

1. **Dashboard Metric Cards:** Display total customers, total outstanding debt, overdue balances, and recovered amounts with status trend pills.
2. **Paginated Data Table:** Sortable column headers, status badges, customer name search, date range pickers, and direct action icons (View, Log Action, Record Payment).
3. **Action Dialog / Slide-Over Drawer:** Ergonomic forms for recording customer contact attempts, scheduling follow-ups, and capturing payment allocations.
4. **Audit Log Timeline:** Chronological list showing timestamp, staff user, action description, and affected record link.
5. **Report Export Toolbar:** Quick action buttons for **Export PDF** and **Export Excel (.xlsx)**.

## Do's and Don'ts

* **Do:** Provide immediate client-side field validation on forms with clear error messages.
* **Do:** Maintain explicit currency formatting (e.g., `$1,250.00`) and standard ISO date displays (`YYYY-MM-DD`).
* **Don't:** Overwhelm the interface with flashing alarm banners; keep notifications informative and professional.
* **Don't:** Permit accidental form submission; require explicit confirmation on financial payment recording.
