-- ─────────────────────────────────────────────────────────────────
-- Epic 4: Recovery Activity Tracking & Reminder Notifications
-- Story 4.1 (interaction logging), Story 4.2 (PTP follow-ups),
-- Story 4.3 (configurable email/SMS payment reminders)
-- Target: Supabase / PostgreSQL 15+
-- ─────────────────────────────────────────────────────────────────

-- 1. Extend interaction_logs with an explicit contact date and customer link.
--    `customer_id` is required by FR-09 ("record recovery actions ... and
--    future follow-up dates") and is denormalised onto the interaction so the
--    chronological recovery timeline can be read without joining debts.
ALTER TABLE public.interaction_logs
    ADD COLUMN IF NOT EXISTS contact_date DATE;

ALTER TABLE public.interaction_logs
    ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE;

-- Backfill customer_id + contact_date for pre-existing rows.
UPDATE public.interaction_logs i
SET customer_id = d.customer_id,
    contact_date = (i.created_at AT TIME ZONE 'UTC')::date
FROM public.debts d
WHERE i.debt_id = d.id AND i.customer_id IS NULL;

-- Any orphan interaction (debt removed outside the cascade) cannot be
-- attributed to a customer, so it is dropped before the NOT NULL constraint.
DELETE FROM public.interaction_logs WHERE customer_id IS NULL;

ALTER TABLE public.interaction_logs
    ALTER COLUMN customer_id SET NOT NULL;

-- The officer is optional so interactions imported from an external system
-- (or written by scheduled jobs) do not require a seeded staff profile.
ALTER TABLE public.interaction_logs
    ALTER COLUMN officer_id DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_interaction_contact_date
    ON public.interaction_logs(tenant_id, contact_date DESC);

CREATE INDEX IF NOT EXISTS idx_interaction_customer
    ON public.interaction_logs(tenant_id, customer_id, created_at DESC);

-- ─────────────────────────────────────────────────────────────────
-- 2. Reminder Settings (FR-10: configurable payment reminders)
--    One row per tenant; only tenant admins may mutate it.
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reminder_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    sms_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    -- Cadence expressed as "days before the due date" offsets.
    email_offset_days JSONB NOT NULL DEFAULT '[3, 1, 0]'::jsonb,
    sms_offset_days JSONB NOT NULL DEFAULT '[3, 0]'::jsonb,
    message_template TEXT NOT NULL DEFAULT
        'Dear {{customer_name}}, a payment of {{amount}} on account {{reference_number}} is due on {{due_date}}. Please make your payment to avoid further collection action.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_tenant_reminder_settings UNIQUE (tenant_id),
    CONSTRAINT reminder_email_offsets_is_array CHECK (jsonb_typeof(email_offset_days) = 'array'),
    CONSTRAINT reminder_sms_offsets_is_array CHECK (jsonb_typeof(sms_offset_days) = 'array')
);

CREATE INDEX IF NOT EXISTS idx_reminder_settings_tenant
    ON public.reminder_settings(tenant_id);

-- ─────────────────────────────────────────────────────────────────
-- 3. Reminder Dispatches (append-only delivery ledger)
--    The unique key on (tenant, debt, channel, scheduled_for) makes the
--    dispatch job idempotent: re-running it never double-sends a reminder.
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reminder_dispatches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    debt_id UUID NOT NULL REFERENCES public.debts(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    channel TEXT NOT NULL CHECK (channel IN ('email', 'sms')),
    recipient TEXT NOT NULL,
    message TEXT NOT NULL,
    scheduled_for DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'failed', 'skipped')),
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_tenant_reminder_dispatch
        UNIQUE (tenant_id, debt_id, channel, scheduled_for)
);

CREATE INDEX IF NOT EXISTS idx_reminder_dispatch_tenant
    ON public.reminder_dispatches(tenant_id, scheduled_for);

CREATE INDEX IF NOT EXISTS idx_reminder_dispatch_debt
    ON public.reminder_dispatches(tenant_id, debt_id, scheduled_for DESC);


-- ─────────────────────────────────────────────────────────────────
-- 4. Atomic interaction logging (Story 4.1 / 4.2)
--    Writes the interaction, flips the debt to `ptp_scheduled` when a
--    promise-to-pay is captured, and appends an audit trail entry - all in
--    a single transaction.
-- ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.log_recovery_interaction(
    p_tenant_id UUID,
    p_debt_id UUID,
    p_customer_id UUID,
    p_officer_id UUID,
    p_action_type action_type,
    p_outcome TEXT,
    p_contact_date DATE DEFAULT NULL,
    p_follow_up_date TIMESTAMPTZ DEFAULT NULL,
    p_promised_amount_cents BIGINT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_interaction_id UUID;
    v_debt_status debt_status;
BEGIN
    -- The debt must exist inside the tenant.
    SELECT d.status INTO v_debt_status
    FROM public.debts d
    WHERE d.id = p_debt_id AND d.tenant_id = p_tenant_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Debt % not found for tenant %', p_debt_id, p_tenant_id;
    END IF;

    -- ...and the customer must own it.
    IF NOT EXISTS (
        SELECT 1 FROM public.debts d
        WHERE d.id = p_debt_id AND d.tenant_id = p_tenant_id AND d.customer_id = p_customer_id
    ) THEN
        RAISE EXCEPTION 'Customer % does not own debt %', p_customer_id, p_debt_id;
    END IF;

    INSERT INTO public.interaction_logs (
        tenant_id,
        debt_id,
        customer_id,
        officer_id,
        action_type,
        outcome,
        contact_date,
        follow_up_date,
        promised_amount_cents,
        notes
    ) VALUES (
        p_tenant_id,
        p_debt_id,
        p_customer_id,
        p_officer_id,
        p_action_type,
        COALESCE(NULLIF(TRIM(p_outcome), ''), 'No Response'),
        COALESCE(p_contact_date, (now() AT TIME ZONE 'UTC')::date),
        p_follow_up_date,
        p_promised_amount_cents,
        NULLIF(TRIM(p_notes), '')
    ) RETURNING id INTO v_interaction_id;

    -- Story 4.2 AC1: capturing a PTP moves the debt to `ptp_scheduled`.
    IF p_follow_up_date IS NOT NULL AND v_debt_status NOT IN ('settled', 'written_off') THEN
        UPDATE public.debts
        SET status = 'ptp_scheduled',
            updated_at = now()
        WHERE id = p_debt_id AND tenant_id = p_tenant_id;
    END IF;

    INSERT INTO public.audit_logs (
        tenant_id,
        user_id,
        action,
        entity_type,
        entity_id,
        details
    ) VALUES (
        p_tenant_id,
        p_officer_id,
        'LOG_RECOVERY_INTERACTION',
        'interaction_logs',
        v_interaction_id,
        jsonb_build_object(
            'debt_id', p_debt_id,
            'customer_id', p_customer_id,
            'action_type', p_action_type,
            'outcome', p_outcome,
            'follow_up_date', p_follow_up_date,
            'promised_amount_cents', p_promised_amount_cents
        )
    );

    RETURN v_interaction_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 5. Scheduled Reminder Dispatch (Story 4.3 AC2)
--    Builds and queues one dispatch per configured channel for every active
--    debt whose due date matches an offset in the tenant reminder settings.
--    Idempotent: the unique constraint on (tenant, debt, channel, scheduled_for)
--    prevents duplicate dispatches when the job runs more than once.
-- ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.dispatch_due_reminders(p_tenant_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    settings_row public.reminder_settings%ROWTYPE;
    dispatch_count INTEGER := 0;
    plan JSONB := '[]'::jsonb;
    plan_item JSONB;
    target_date DATE;
    debt_row RECORD;
    rendered_message TEXT;
    channel_name TEXT;
    offset_days INTEGER;
    recipient_value TEXT;
BEGIN
    SELECT * INTO settings_row
    FROM public.reminder_settings
    WHERE tenant_id = p_tenant_id
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN 0;
    END IF;

    -- Build the dispatch plan: [{channel, offset}, ...]
    -- COALESCE guards against an empty offset array aggregating to NULL.
    IF settings_row.email_enabled THEN
        SELECT plan || COALESCE(
            jsonb_agg(jsonb_build_object('channel', 'email', 'offset', v.value::int)),
            '[]'::jsonb
        )
        INTO plan
        FROM jsonb_array_elements_text(settings_row.email_offset_days) AS v(value);
    END IF;

    IF settings_row.sms_enabled THEN
        SELECT plan || COALESCE(
            jsonb_agg(jsonb_build_object('channel', 'sms', 'offset', v.value::int)),
            '[]'::jsonb
        )
        INTO plan
        FROM jsonb_array_elements_text(settings_row.sms_offset_days) AS v(value);
    END IF;

    IF jsonb_array_length(plan) = 0 THEN
        RETURN 0;
    END IF;

    FOR plan_item IN SELECT * FROM jsonb_array_elements(plan) LOOP
        channel_name := plan_item ->> 'channel';
        offset_days := (plan_item ->> 'offset')::int;
        target_date := CURRENT_DATE + offset_days;

        FOR debt_row IN
            SELECT d.id AS debt_id,
                   d.customer_id,
                   d.reference_number,
                   d.remaining_balance_cents,
                   d.due_date,
                   c.full_name,
                   c.email,
                   c.phone_number
            FROM public.debts d
            JOIN public.customers c ON c.id = d.customer_id
            WHERE d.tenant_id = p_tenant_id
              AND d.status NOT IN ('settled', 'written_off')
              AND d.due_date = target_date
        LOOP
            recipient_value := CASE WHEN channel_name = 'email'
                                    THEN debt_row.email
                                    ELSE debt_row.phone_number END;

            -- Skip when the customer has no usable destination for the channel.
            IF recipient_value IS NULL OR recipient_value = '' THEN
                CONTINUE;
            END IF;

            rendered_message := replace(replace(replace(replace(
                settings_row.message_template,
                '{{customer_name}}', debt_row.full_name),
                '{{amount}}', debt_row.remaining_balance_cents::text),
                '{{reference_number}}', debt_row.reference_number),
                '{{due_date}}', debt_row.due_date::text);

            INSERT INTO public.reminder_dispatches (
                tenant_id, debt_id, customer_id, channel, recipient,
                message, scheduled_for, status
            )
            VALUES (
                p_tenant_id,
                debt_row.debt_id,
                debt_row.customer_id,
                channel_name,
                recipient_value,
                rendered_message,
                target_date,
                'queued'
            )
            ON CONFLICT (tenant_id, debt_id, channel, scheduled_for) DO NOTHING;

            IF FOUND THEN
                dispatch_count := dispatch_count + 1;
            END IF;
        END LOOP;
    END LOOP;

    RETURN dispatch_count;
END;
$$;
-- ─────────────────────────────────────────────────────────────────
-- 6. Row Level Security for the new tables
-- ─────────────────────────────────────────────────────────────────
ALTER TABLE public.reminder_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminder_dispatches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_reminder_settings_select ON public.reminder_settings;
CREATE POLICY tenant_isolation_reminder_settings_select ON public.reminder_settings
    FOR SELECT
    USING (tenant_id = public.current_tenant_id());

DROP POLICY IF EXISTS tenant_admin_reminder_settings_mutate ON public.reminder_settings;
CREATE POLICY tenant_admin_reminder_settings_mutate ON public.reminder_settings
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() AND
        public.current_user_role() = 'admin'
    )
    WITH CHECK (
        tenant_id = public.current_tenant_id() AND
        public.current_user_role() = 'admin'
    );

DROP POLICY IF EXISTS tenant_isolation_reminder_dispatch_select ON public.reminder_dispatches;
CREATE POLICY tenant_isolation_reminder_dispatch_select ON public.reminder_dispatches
    FOR SELECT
    USING (tenant_id = public.current_tenant_id());

DROP POLICY IF EXISTS tenant_staff_reminder_dispatch_insert ON public.reminder_dispatches;
CREATE POLICY tenant_staff_reminder_dispatch_insert ON public.reminder_dispatches
    FOR INSERT
    WITH CHECK (tenant_id = public.current_tenant_id());

-- Reminder dispatches are an append-only delivery ledger.
REVOKE UPDATE, DELETE ON public.reminder_dispatches FROM authenticated, anon, public;

-- ─────────────────────────────────────────────────────────────────
-- 7. Debt mutation permissions
--    Recovery officers must be able to flag a debt as PTP scheduled
--    (Story 4.2, AC1: debt status updates to `PTP Scheduled`).
-- ─────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS tenant_staff_debts_mutate ON public.debts;
CREATE POLICY tenant_staff_debts_mutate ON public.debts
    FOR ALL
    USING (
        tenant_id = public.current_tenant_id() AND
        public.current_user_role() IN ('admin', 'finance_officer', 'recovery_officer')
    )
    WITH CHECK (
        tenant_id = public.current_tenant_id() AND
        public.current_user_role() IN ('admin', 'finance_officer', 'recovery_officer')
    );

-- ─────────────────────────────────────────────────────────────────
-- 8. Audit trail for reminder configuration changes (AD-4)
-- ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.audit_reminder_settings_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.audit_logs (tenant_id, user_id, action, entity_type, entity_id, details)
    VALUES (
        NEW.tenant_id,
        auth.uid(),
        TG_OP,
        'reminder_settings',
        NEW.id,
        jsonb_build_object(
            'email_enabled', NEW.email_enabled,
            'sms_enabled', NEW.sms_enabled,
            'email_offset_days', NEW.email_offset_days,
            'sms_offset_days', NEW.sms_offset_days
        )
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_reminder_settings ON public.reminder_settings;
CREATE TRIGGER trg_audit_reminder_settings
    AFTER INSERT OR UPDATE ON public.reminder_settings
    FOR EACH ROW EXECUTE FUNCTION public.audit_reminder_settings_change();

-- Keep `updated_at` fresh whenever reminder settings are edited.
CREATE OR REPLACE FUNCTION public.touch_reminder_settings_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_reminder_settings ON public.reminder_settings;
CREATE TRIGGER trg_touch_reminder_settings
    BEFORE UPDATE ON public.reminder_settings
    FOR EACH ROW EXECUTE FUNCTION public.touch_reminder_settings_updated_at();

-- ─────────────────────────────────────────────────────────────────
-- 9. Grants
-- ─────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON public.reminder_settings TO authenticated;
GRANT SELECT, INSERT ON public.reminder_dispatches TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_recovery_interaction(UUID, UUID, UUID, UUID, action_type, TEXT, DATE, TIMESTAMPTZ, BIGINT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.dispatch_due_reminders(UUID) TO authenticated;



