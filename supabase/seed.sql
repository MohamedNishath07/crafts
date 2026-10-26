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
