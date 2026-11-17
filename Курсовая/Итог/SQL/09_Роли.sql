-- Выполнять от владельца базы / postgres. Роли групповые, без паролей и LOGIN.
BEGIN;
DO $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='gym_admin') THEN
  CREATE ROLE gym_admin NOLOGIN;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='gym_manager') THEN
  CREATE ROLE gym_manager NOLOGIN;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='gym_analyst') THEN
  CREATE ROLE gym_analyst NOLOGIN;
 END IF;
END $$;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO gym_admin,gym_manager,gym_analyst;
GRANT CREATE ON SCHEMA public TO gym_admin;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- Администратор владеет объектами проекта. Это доверенная роль.
-- Менеджер не может менять структуру или отключать триггеры.
ALTER TABLE public.specializations OWNER TO gym_admin;
ALTER TABLE public.halls OWNER TO gym_admin;
ALTER TABLE public.memberships OWNER TO gym_admin;
ALTER TABLE public.clients OWNER TO gym_admin;
ALTER TABLE public.trainers OWNER TO gym_admin;
ALTER TABLE public.employees OWNER TO gym_admin;
ALTER TABLE public.subscriptions OWNER TO gym_admin;
ALTER TABLE public.trainings OWNER TO gym_admin;
ALTER TABLE public.bookings OWNER TO gym_admin;
ALTER TABLE public.payments OWNER TO gym_admin;
ALTER TABLE public.audit_log OWNER TO gym_admin;
ALTER VIEW public.v_subscription_balance OWNER TO gym_admin;
ALTER VIEW public.v_training_load OWNER TO gym_admin;
ALTER VIEW public.v_daily_revenue OWNER TO gym_admin;
ALTER VIEW public.v_schedule OWNER TO gym_admin;
ALTER FUNCTION public.audit_financial_change() OWNER TO gym_admin;
ALTER FUNCTION public.lock_gym_changes() OWNER TO gym_admin;
ALTER FUNCTION public.check_gym_state() OWNER TO gym_admin;
ALTER FUNCTION public.validate_gym_changes() OWNER TO gym_admin;
ALTER FUNCTION public.check_client_row() OWNER TO gym_admin;
ALTER FUNCTION public.check_subscription_row() OWNER TO gym_admin;
ALTER FUNCTION public.check_payment_row() OWNER TO gym_admin;
ALTER FUNCTION public.check_training_row() OWNER TO gym_admin;
ALTER FUNCTION public.check_booking_row() OWNER TO gym_admin;
ALTER FUNCTION public.cancel_training_bookings() OWNER TO gym_admin;

GRANT SELECT ON public.specializations,public.halls,public.memberships,public.clients,
 public.trainers,public.employees,public.subscriptions,public.trainings,
 public.bookings,public.payments TO gym_manager;
GRANT INSERT,UPDATE ON public.clients,public.subscriptions,public.trainings,
 public.bookings,public.payments TO gym_manager;
GRANT USAGE,SELECT ON SEQUENCE public.clients_client_id_seq,
 public.subscriptions_subscription_id_seq,public.trainings_training_id_seq,
 public.bookings_booking_id_seq,public.payments_payment_id_seq TO gym_manager;
GRANT SELECT ON public.v_subscription_balance,public.v_training_load,
 public.v_daily_revenue,public.v_schedule TO gym_manager;
-- Аналитик видит только представления без телефонов, e-mail и ФИО клиентов.
GRANT SELECT ON public.v_subscription_balance,public.v_training_load,
 public.v_daily_revenue TO gym_analyst;
-- Групповые роли назначаются реальным учётным записям отдельно, например:
-- GRANT gym_manager TO имя_пользователя;
COMMIT;
