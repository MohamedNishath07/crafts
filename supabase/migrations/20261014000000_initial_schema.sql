-- ─────────────────────────────────────────────────────────────────
-- Debit Recovery System: Initial Schema Migration
-- Author: BMad Development
-- Target: Supabase / PostgreSQL 15+
-- Features Covered: FR-01, FR-02, FR-03, FR-04, FR-05, FR-06, FR-07, FR-08, FR-09, FR-16, FR-18
-- Architectural Decisions: AD-1 (Tenant RLS), AD-4 (Immutability), AD-5 (Atomic Balances)
-- ─────────────────────────────────────────────────────────────────

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Custom Enum Types
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'recovery_officer', 'finance_officer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE debt_status AS ENUM ('active', 'ptp_scheduled', 'settled', 'written_off');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE action_type AS ENUM ('call', 'field_visit', 'email', 'sms', 'office_visit');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method AS ENUM ('cash', 'bank_transfer', 'check', 'mobile_money');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ─────────────────────────────────────────────────────────────────
-- 1. Tenants Table (Isolated Multi-Tenant Organizations)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    default_currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────
-- 2. User Profiles Table (Linked to Supabase auth.users)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'recovery_officer',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_tenant_email UNIQUE (tenant_id, email)
);

CREATE INDEX IF NOT EXISTS idx_profiles_tenant_id ON public.profiles(tenant_id);

-- ─────────────────────────────────────────────────────────────────
-- 3. Customers Table
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    secondary_phone TEXT,
    email TEXT,
    national_id TEXT,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customers_tenant_id ON public.customers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customers_search ON public.customers(tenant_id, full_name, phone_number);

-- ─────────────────────────────────────────────────────────────────
-- 4. Debts Table (Financial Obligations)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.debts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    assigned_officer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reference_number TEXT NOT NULL,
    principal_amount_cents BIGINT NOT NULL CHECK (principal_amount_cents > 0),
    remaining_balance_cents BIGINT NOT NULL CHECK (remaining_balance_cents >= 0),
    origin_date DATE NOT NULL,
    due_date DATE NOT NULL,
    status debt_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_tenant_debt_ref UNIQUE (tenant_id, reference_number)
);

CREATE INDEX IF NOT EXISTS idx_debts_tenant_id ON public.debts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_debts_customer ON public.debts(tenant_id, customer_id);
CREATE INDEX IF NOT EXISTS idx_debts_assigned_officer ON public.debts(tenant_id, assigned_officer_id);
CREATE INDEX IF NOT EXISTS idx_debts_due_date ON public.debts(tenant_id, due_date, status);

-- Helper view for Days Past Due (DPD) & Aging Brackets
CREATE OR REPLACE VIEW public.v_debt_aging AS
SELECT 
    d.*,
    CASE 
        WHEN CURRENT_DATE > d.due_date AND d.status != 'settled' 
        THEN (CURRENT_DATE - d.due_date)
        ELSE 0 
    END AS days_past_due,
    CASE 
        WHEN d.status = 'settled' THEN 'Settled'
        WHEN CURRENT_DATE <= d.due_date THEN 'Current'
        WHEN (CURRENT_DATE - d.due_date) BETWEEN 1 AND 30 THEN '1-30 DPD'
        WHEN (CURRENT_DATE - d.due_date) BETWEEN 31 AND 60 THEN '31-60 DPD'
        WHEN (CURRENT_DATE - d.due_date) BETWEEN 61 AND 90 THEN '61-90 DPD'
        ELSE '90+ DPD'
    END AS aging_bracket
FROM public.debts d;

-- ─────────────────────────────────────────────────────────────────
-- 5. Payments Table (Immutable Ledger)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    debt_id UUID NOT NULL REFERENCES public.debts(id) ON DELETE CASCADE,
    recorded_by_id UUID NOT NULL REFERENCES public.profiles(id),
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    payment_method payment_method NOT NULL,
    transaction_reference TEXT NOT NULL,
    receipt_number TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_tenant_receipt UNIQUE (tenant_id, receipt_number)
);

CREATE INDEX IF NOT EXISTS idx_payments_tenant_debt ON public.payments(tenant_id, debt_id);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON public.payments(tenant_id, created_at);

-- ─────────────────────────────────────────────────────────────────
-- 6. Interaction Logs Table (Immutable Recovery Activities)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.interaction_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    debt_id UUID NOT NULL REFERENCES public.debts(id) ON DELETE CASCADE,
    officer_id UUID NOT NULL REFERENCES public.profiles(id),
    action_type action_type NOT NULL,
    outcome TEXT NOT NULL,
    follow_up_date TIMESTAMPTZ,
    promised_amount_cents BIGINT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_interaction_tenant_debt ON public.interaction_logs(tenant_id, debt_id);
CREATE INDEX IF NOT EXISTS idx_interaction_follow_up ON public.interaction_logs(tenant_id, follow_up_date);

-- ─────────────────────────────────────────────────────────────────
-- 7. Audit Logs Table (Append-Only Governance)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant ON public.audit_logs(tenant_id, created_at);

-- ─────────────────────────────────────────────────────────────────
-- 8. Atomic Stored Procedure: Record Payment & Deflate Balance
-- ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.record_payment_and_deflate_balance(
    p_tenant_id UUID,
    p_debt_id UUID,
    p_recorded_by UUID,
    p_amount_cents BIGINT,
    p_payment_method payment_method,
    p_transaction_ref TEXT,
    p_receipt_number TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payment_id UUID;
    v_current_balance BIGINT;
    v_new_balance BIGINT;
BEGIN
    -- Lock debt row for atomic balance subtraction
    SELECT remaining_balance_cents INTO v_current_balance
    FROM public.debts
    WHERE id = p_debt_id AND tenant_id = p_tenant_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Debt record not found for tenant % and debt %', p_tenant_id, p_debt_id;
    END IF;

    IF p_amount_cents > v_current_balance THEN
        RAISE EXCEPTION 'Payment amount (% cents) exceeds remaining balance (% cents)', p_amount_cents, v_current_balance;
    END IF;

    v_new_balance := v_current_balance - p_amount_cents;

    -- Insert immutable payment record
    INSERT INTO public.payments (
        tenant_id,
        debt_id,
        recorded_by_id,
        amount_cents,
        payment_method,
        transaction_reference,
        receipt_number,
        notes
    ) VALUES (
        p_tenant_id,
        p_debt_id,
        p_recorded_by,
        p_amount_cents,
        p_payment_method,
        p_transaction_ref,
        p_receipt_number,
        p_notes
    ) RETURNING id INTO v_payment_id;

    -- Update debt balance and status
    UPDATE public.debts
    SET 
        remaining_balance_cents = v_new_balance,
        status = CASE WHEN v_new_balance = 0 THEN 'settled'::debt_status ELSE status END,
        updated_at = now()
    WHERE id = p_debt_id AND tenant_id = p_tenant_id;

    -- Write to audit log
    INSERT INTO public.audit_logs (
        tenant_id,
        user_id,
        action,
        entity_type,
        entity_id,
        details
    ) VALUES (
        p_tenant_id,
        p_recorded_by,
        'RECORD_PAYMENT',
        'payments',
        v_payment_id,
        jsonb_build_object(
            'amount_cents', p_amount_cents,
            'debt_id', p_debt_id,
            'previous_balance', v_current_balance,
            'new_balance', v_new_balance,
            'receipt_number', p_receipt_number
        )
    );

    RETURN v_payment_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 9. Row-Level Security (RLS) Helper Functions & Policies
-- ─────────────────────────────────────────────────────────────────

-- Helper: extract tenant_id from auth JWT app_metadata
CREATE OR REPLACE FUNCTION public.current_tenant_id()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF((auth.jwt() -> 'app_metadata' ->> 'tenant_id'), '')::uuid;
$$;

-- Helper: extract user role from auth JWT app_metadata
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF((auth.jwt() -> 'app_metadata' ->> 'role'), '');
$$;

-- Enable RLS on all tables
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interaction_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Tenants Policies
CREATE POLICY tenant_isolation_tenants ON public.tenants
    FOR ALL
    USING (id = public.current_tenant_id());

-- Profiles Policies
CREATE POLICY tenant_isolation_profiles_select ON public.profiles
    FOR SELECT
    USING (tenant_id = public.current_tenant_id());

CREATE POLICY tenant_admin_profiles_mutate ON public.profiles
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() AND 
        public.current_user_role() = 'admin'
    );

-- Customers Policies
CREATE POLICY tenant_isolation_customers ON public.customers
    FOR ALL
    USING (tenant_id = public.current_tenant_id());

-- Debts Policies
CREATE POLICY tenant_isolation_debts_select ON public.debts
    FOR SELECT
    USING (tenant_id = public.current_tenant_id());

CREATE POLICY tenant_staff_debts_mutate ON public.debts
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() AND 
        public.current_user_role() IN ('admin', 'finance_officer')
    );

-- Payments Policies (Append-Only)
CREATE POLICY tenant_isolation_payments_select ON public.payments
    FOR SELECT
    USING (tenant_id = public.current_tenant_id());

CREATE POLICY tenant_finance_payments_insert ON public.payments
    FOR INSERT
    WITH CHECK (
        tenant_id = public.current_tenant_id() AND 
        public.current_user_role() IN ('admin', 'finance_officer')
    );

-- Revoke UPDATE and DELETE on payments to guarantee immutability
REVOKE UPDATE, DELETE ON public.payments FROM authenticated, anon, public;

-- Interaction Logs Policies (Append-Only)
CREATE POLICY tenant_isolation_interactions_select ON public.interaction_logs
    FOR SELECT
    USING (tenant_id = public.current_tenant_id());

CREATE POLICY tenant_staff_interactions_insert ON public.interaction_logs
    FOR INSERT
    WITH CHECK (tenant_id = public.current_tenant_id());

-- Revoke UPDATE and DELETE on interaction logs
REVOKE UPDATE, DELETE ON public.interaction_logs FROM authenticated, anon, public;

-- Audit Logs Policies (Append-Only & Admin Read-Only)
CREATE POLICY tenant_admin_audit_logs_select ON public.audit_logs
    FOR SELECT
    USING (
        tenant_id = public.current_tenant_id() AND 
        public.current_user_role() = 'admin'
    );

CREATE POLICY tenant_audit_logs_insert ON public.audit_logs
    FOR INSERT
    WITH CHECK (tenant_id = public.current_tenant_id());

-- Revoke UPDATE and DELETE on audit logs
REVOKE UPDATE, DELETE ON public.audit_logs FROM authenticated, anon, public;
