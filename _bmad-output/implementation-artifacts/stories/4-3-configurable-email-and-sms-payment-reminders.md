---  
title: 'Story 4.3: Configurable Email & SMS Payment Reminders'  
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

**Problem:** Overdue accounts need configurable automated reminder sequences (email and/or SMS) so that Recovery Officers and the system can proactively prompt customers about upcoming or overdue payments. The system must support customizable cadence (offset days before due date), message templating, and dispatch tracking with send status.

**Approach:** Implement ReminderRepository with fetchReminderSettings (creates defaults if none exist: email enabled, SMS disabled, offsets [3,1,0] for email, [3,0] for SMS, configurable message template). Add saveReminderSettings to update email/SMS enablement, offset days, and template. Add fetchReminderDispatches to retrieve dispatch history per tenant. Add createReminderDispatch to record each reminder send attempt with channel, recipient, message, status (scheduled/sent/failed), and send timestamp. Expose reminder settings through reminderSettingsProvider and reminderSettingsNotifierProvider for Riverpod consumption. Configure email/SMS toggle switches, offset day inputs, and template editor on ReminderSettingsScreen.

## Boundaries & Constraints

**Always:**
- Default reminder settings: email enabled, SMS disabled, email offsets [3,1,0], SMS offsets [3,0], template: "Dear {{customer_name}}, a payment of {{amount}} on account {{reference_number}} is due on {{due_date}}. Please make your payment to avoid further collection action."
- Offset days are positive integers representing days before the due date; [3,1,0] means send 3 days before, 1 day before, and on the due date
- SMS is disabled by default; must be explicitly enabled per tenant
- Message template uses {{customer_name}}, {{amount}}, {{reference_number}}, {{due_date}} placeholders
- Dispatch records are append-only: insert only, no update or delete

**Never:**
- Never send actual email/SMS from the client; createReminderDispatch only records the intent/dispatch metadata
- Never expose customer phone/email directly in UI without proper consent
- Never allow negative offset days
</frozen-after-approval>

## Code Map

- lib/features/recovery/data/reminder_repository.dart -- fetchReminderSettings, saveReminderSettings, fetchReminderDispatches, createReminderDispatch
- lib/features/recovery/presentation/reminder_settings_screen.dart -- Settings form with toggles, offsets, template
- lib/features/recovery/presentation/reminder_controller.dart -- Notifier provider for reminder settings
- supabase/migrations/20261014000000_initial_schema.sql -- reminder_settings and reminder_dispatches tables
- core/constants/app_colors.dart -- Color tokens for enabled/disabled toggles and status badges

## Tasks & Acceptance

**Execution:**
- [x] ReminderRepository.fetchReminderSettings -- Creates defaults if none exist (email: enabled, SMS: disabled, offsets [3,1,0]/[3,0])
- [x] ReminderRepository.saveReminderSettings -- Upsert email enabled, SMS enabled, email offset days, SMS offset days, message template
- [x] ReminderRepository.fetchReminderDispatches -- List dispatches per tenant, newest first
- [x] ReminderRepository.createReminderDispatch -- Record a single dispatch with channel, recipient, message, status, sent_at
- [x] reminderSettingsProvider -- Provider returning current ReminderSettings (or defaults)
- [x] reminderSettingsNotifierProvider -- Notifier for saving settings
- [x] ReminderSettingsScreen -- UI with email/SMS toggles, offset day inputs, message template editor
- [x] Default template pre-populated: "Dear {{customer_name}}, a payment of {{amount}} on account {{reference_number}} is due on {{due_date}}. Please make your payment to avoid further collection action."
- [x] test/features/recovery/reminder_repository_test.dart -- Settings CRUD and dispatch recording tests
- [x] test/features/recovery/reminder_settings_screen_test.dart -- Form field validation and save flow tests

**Acceptance Criteria:**
- Given a new tenant, reminder settings are auto-created with defaults (email enabled, SMS disabled, offsets [3,1,0]/[3,0])
- Given an enabled SMS toggle, sms_enabled is true and SMS offset field is interactive
- Given offset changes, the new values are persisted and used for future dispatch scheduling
- Given template changes, the new template text is saved and displayed in future dispatches
- Given dispatch history view, a table lists all reminder dispatches with channel, status, and send timestamp