-- ─────────────────────────────────────────────────────────────────
-- Debit Recovery System: Seed Data
-- Demo Tenant: Acme Credit Solutions
-- Roles: Admin, Recovery Officer, Finance Officer
-- ─────────────────────────────────────────────────────────────────

-- Insert Demo Tenant
INSERT INTO public.tenants (id, name, default_currency, is_active)
VALUES (
    'a0000000-0000-0000-0000-000000000001'::uuid,
    'Acme Credit Solutions',
    'USD',
    true
) ON CONFLICT (id) DO NOTHING;

-- Insert Sample Customers
INSERT INTO public.customers (id, tenant_id, full_name, phone_number, email, national_id, address)
VALUES 
    (
        'c0000000-0000-0000-0000-000000000001'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'David Kamau',
        '+15550192831',
        'david.kamau@example.com',
        'ID-902182',
        '742 Evergreen Terrace, Sector 4'
    ),
    (
        'c0000000-0000-0000-0000-000000000002'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'Elena Rostova',
        '+15550192832',
        'elena.rostova@example.com',
        'ID-441829',
        '104 Lincoln Blvd, Suite 200'
    ),
    (
        'c0000000-0000-0000-0000-000000000003'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'Marcus Vance',
        '+15550192833',
        'marcus.vance@example.com',
        'ID-772109',
        '55 Industrial Parkway, Warehouse B'
    )
ON CONFLICT (id) DO NOTHING;

-- Insert Sample Debts
INSERT INTO public.debts (id, tenant_id, customer_id, reference_number, principal_amount_cents, remaining_balance_cents, origin_date, due_date, status)
VALUES
    (
        'd0000000-0000-0000-0000-000000000001'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'c0000000-0000-0000-0000-000000000001'::uuid,
        'INV-2026-001',
        75000, -- $750.00
        45000, -- $450.00 (partial payment recorded)
        CURRENT_DATE - INTERVAL '60 days',
        CURRENT_DATE - INTERVAL '45 days',
        'active'
    ),
    (
        'd0000000-0000-0000-0000-000000000002'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'c0000000-0000-0000-0000-000000000002'::uuid,
        'INV-2026-002',
        22000, -- $220.00
        22000,
        CURRENT_DATE - INTERVAL '40 days',
        CURRENT_DATE - INTERVAL '20 days',
        'ptp_scheduled'
    ),
    (
        'd0000000-0000-0000-0000-000000000003'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'c0000000-0000-0000-0000-000000000003'::uuid,
        'INV-2026-003',
        120000, -- $1,200.00
        120000,
        CURRENT_DATE - INTERVAL '110 days',
        CURRENT_DATE - INTERVAL '95 days',
        'active'
    )
ON CONFLICT (id) DO NOTHING;

-- Insert Sample Interaction Logs (Epic 4 / Story 4.1 & 4.2)
-- officer_id is nullable so the seed does not depend on auth.users rows.
INSERT INTO public.interaction_logs (
    id, tenant_id, debt_id, customer_id, officer_id, action_type,
    outcome, contact_date, follow_up_date, promised_amount_cents, notes, created_at
)
VALUES
    (
        'b0000000-0000-0000-0000-000000000001'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'd0000000-0000-0000-0000-000000000001'::uuid,
        'c0000000-0000-0000-0000-000000000001'::uuid,
        NULL,
        'call',
        'No Response',
        CURRENT_DATE - INTERVAL '12 days',
        NULL,
        NULL,
        'Customer unreachable, will attempt again next week.',
        now() - INTERVAL '12 days'
    ),
    (
        'b0000000-0000-0000-0000-000000000002'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'd0000000-0000-0000-0000-000000000002'::uuid,
        'c0000000-0000-0000-0000-000000000002'::uuid,
        NULL,
        'call',
        'Promise to Pay',
        CURRENT_DATE - INTERVAL '5 days',
        now() + INTERVAL '3 days',
        22000,
        'Customer committed to paying the full balance within three days.',
        now() - INTERVAL '5 days'
    ),
    (
        'b0000000-0000-0000-0000-000000000003'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'd0000000-0000-0000-0000-000000000003'::uuid,
        'c0000000-0000-0000-0000-000000000003'::uuid,
        NULL,
        'field_visit',
        'Escalated',
        CURRENT_DATE - INTERVAL '2 days',
        now() + INTERVAL '7 days',
        NULL,
        'Case handed to legal for further action.',
        now() - INTERVAL '2 days'
    )
ON CONFLICT (id) DO NOTHING;

-- Insert Reminder Settings (Epic 4 / Story 4.3)
INSERT INTO public.reminder_settings (
    id, tenant_id, email_enabled, sms_enabled,
    email_offset_days, sms_offset_days, message_template
)
VALUES (
    'e0000000-0000-0000-0000-000000000001'::uuid,
    'a0000000-0000-0000-0000-000000000001'::uuid,
    true,
    false,
    '[3, 1, 0]'::jsonb,
    '[3, 0]'::jsonb,
    'Dear {{customer_name}}, a payment of {{amount}} on account {{reference_number}} is due on {{due_date}}. Please make your payment to avoid further collection action.'
)
ON CONFLICT (tenant_id) DO NOTHING;

-- Insert Sample Reminder Dispatches (Epic 4 / Story 4.3)
INSERT INTO public.reminder_dispatches (
    id, tenant_id, debt_id, customer_id, channel, recipient,
    message, scheduled_for, status
)
VALUES
    (
        'f0000000-0000-0000-0000-000000000001'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'd0000000-0000-0000-0000-000000000001'::uuid,
        'c0000000-0000-0000-0000-000000000001'::uuid,
        'email',
        'david.kamau@example.com',
        'Dear David Kamau, a payment of 45000 on account INV-2026-001 is due soon. Please make your payment to avoid further collection action.',
        CURRENT_DATE,
        'queued'
    ),
    (
        'f0000000-0000-0000-0000-000000000002'::uuid,
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'd0000000-0000-0000-0000-000000000002'::uuid,
        'c0000000-0000-0000-0000-000000000002'::uuid,
        'email',
        'elena.rostova@example.com',
        'Dear Elena Rostova, a payment of 22000 on account INV-2026-002 is due soon. Please make your payment to avoid further collection action.',
        CURRENT_DATE,
        'sent'
    )
ON CONFLICT (tenant_id, debt_id, channel, scheduled_for) DO NOTHING;
