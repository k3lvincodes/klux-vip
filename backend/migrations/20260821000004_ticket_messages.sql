-- ============================================
-- TICKET MESSAGES (conversation system)
-- ============================================

create table if not exists public.ticket_messages (
  id          uuid          default gen_random_uuid() primary key,
  ticket_id   uuid          references public.support_tickets on delete cascade not null,
  sender_id   uuid          references public.profiles on delete cascade not null,
  message     text          not null,
  created_at  timestamptz   default timezone('utc', now()) not null
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket ON public.ticket_messages(ticket_id, created_at);

-- RLS
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view messages on own tickets" ON public.ticket_messages;
  DROP POLICY IF EXISTS "Users can insert messages on own tickets" ON public.ticket_messages;
  DROP POLICY IF EXISTS "Admins can view all ticket messages" ON public.ticket_messages;
  DROP POLICY IF EXISTS "Admins can insert ticket messages" ON public.ticket_messages;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Users can view messages on tickets they own
CREATE POLICY "Users can view messages on own tickets"
  ON public.ticket_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets
      WHERE support_tickets.id = ticket_messages.ticket_id
        AND support_tickets.user_id = auth.uid()
    )
  );

-- Users can insert messages on their own open/in_progress tickets
CREATE POLICY "Users can insert messages on own tickets"
  ON public.ticket_messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM public.support_tickets
      WHERE support_tickets.id = ticket_messages.ticket_id
        AND support_tickets.user_id = auth.uid()
        AND support_tickets.status IN ('open', 'in_progress')
    )
  );

-- Admins can view all ticket messages
CREATE POLICY "Admins can view all ticket messages"
  ON public.ticket_messages FOR SELECT
  USING (public.is_admin());

-- Admins can insert ticket messages
CREATE POLICY "Admins can insert ticket messages"
  ON public.ticket_messages FOR INSERT
  WITH CHECK (public.is_admin());

-- Migrate existing ticket descriptions as the first message
DO $$
  DECLARE
    ticket RECORD;
  BEGIN
    FOR ticket IN
      SELECT id, user_id, description, created_at
      FROM public.support_tickets
      WHERE description IS NOT NULL AND description != ''
    LOOP
      INSERT INTO public.ticket_messages (ticket_id, sender_id, message, created_at)
      VALUES (ticket.id, ticket.user_id, ticket.description, ticket.created_at)
      ON CONFLICT DO NOTHING;
    END LOOP;
END $$;
