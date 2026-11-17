-- Выполнить после создания и заполнения таблиц (01, 02, 04).
BEGIN;
SET TIME ZONE 'Europe/Moscow';

-- Для небольшой учебной системы изменения выполняются последовательно.
-- Блокировка действует до COMMIT/ROLLBACK и закрывает гонки платежей и записей.
-- Поддерживаемый уровень изоляции операций изменения: READ COMMITTED.
CREATE FUNCTION public.lock_gym_changes() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
BEGIN
 IF current_setting('transaction_isolation') <> 'read committed' THEN
  RAISE EXCEPTION 'Изменения выполняются на уровне READ COMMITTED';
 END IF;
 PERFORM pg_advisory_xact_lock(821125,1);
 RETURN NULL;
END;
$$;

CREATE FUNCTION public.check_gym_state() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
BEGIN
 IF EXISTS(SELECT 1 FROM public.clients
 WHERE birth_date>(clock_timestamp() AT TIME ZONE 'Europe/Moscow')::date) THEN
  RAISE EXCEPTION 'Дата рождения не может быть в будущем';
 END IF;
 IF EXISTS(SELECT 1 FROM public.trainings t JOIN public.halls h USING(hall_id)
 WHERE t.max_capacity>h.capacity) THEN
  RAISE EXCEPTION 'Число мест превышает вместимость зала';
 END IF;
 IF EXISTS(SELECT 1 FROM public.trainings a JOIN public.trainings b
 ON a.training_id<b.training_id
 AND (a.hall_id=b.hall_id OR a.trainer_id=b.trainer_id)
 AND NOT a.is_cancelled AND NOT b.is_cancelled
 AND tstzrange(a.starts_at,a.starts_at+make_interval(mins=>a.duration_min),'[)')
 && tstzrange(b.starts_at,b.starts_at+make_interval(mins=>b.duration_min),'[)')) THEN
  RAISE EXCEPTION 'Пересечение расписания по тренеру или залу';
 END IF;
 IF EXISTS(SELECT 1 FROM public.trainings t JOIN public.trainers r USING(trainer_id)
 WHERE NOT t.is_cancelled AND t.starts_at>clock_timestamp() AND NOT r.is_active) THEN
  RAISE EXCEPTION 'У неактивного тренера есть будущие занятия';
 END IF;
 IF EXISTS(SELECT 1 FROM public.trainings t WHERE
 (SELECT count(*) FROM public.bookings b WHERE b.training_id=t.training_id
 AND b.status<>'cancelled')>t.max_capacity) THEN
  RAISE EXCEPTION 'На занятии нет свободных мест';
 END IF;
 IF EXISTS(SELECT 1 FROM public.subscriptions s WHERE
 COALESCE((SELECT sum(p.amount) FROM public.payments p
 WHERE p.subscription_id=s.subscription_id AND NOT p.is_refunded),0)>s.sold_price) THEN
  RAISE EXCEPTION 'Сумма платежей превышает цену продажи';
 END IF;
 IF EXISTS(SELECT 1 FROM public.bookings b JOIN public.trainings t USING(training_id)
 JOIN public.clients c USING(client_id)
 WHERE b.status<>'cancelled' AND
 (t.is_cancelled OR (b.status='booked' AND NOT c.is_active) OR NOT EXISTS(
 SELECT 1 FROM public.subscriptions s WHERE s.client_id=b.client_id
 AND (t.starts_at AT TIME ZONE 'Europe/Moscow')::date BETWEEN s.start_date AND s.end_date
 AND COALESCE((SELECT sum(p.amount) FROM public.payments p
 WHERE p.subscription_id=s.subscription_id AND NOT p.is_refunded),0)=s.sold_price))) THEN
  RAISE EXCEPTION 'Запись требует активного клиента и действующего полностью оплаченного абонемента';
 END IF;
END;
$$;
CREATE FUNCTION public.validate_gym_changes() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
BEGIN
 PERFORM public.check_gym_state();
 RETURN NULL;
END;
$$;

CREATE FUNCTION public.check_client_row() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
BEGIN
 IF NEW.birth_date>(clock_timestamp() AT TIME ZONE 'Europe/Moscow')::date THEN
  RAISE EXCEPTION 'Дата рождения не может быть в будущем';
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER clients_before_row BEFORE INSERT OR UPDATE ON public.clients
FOR EACH ROW EXECUTE FUNCTION public.check_client_row();

CREATE FUNCTION public.check_subscription_row() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
DECLARE days_count integer; tariff_price numeric;
BEGIN
 IF TG_OP='DELETE' THEN
  IF EXISTS(SELECT 1 FROM public.payments WHERE subscription_id=OLD.subscription_id) THEN
   RAISE EXCEPTION 'Абонемент с платежами удалить нельзя';
  END IF;
  RETURN OLD;
 END IF;
 IF TG_OP='INSERT' THEN
  IF NOT EXISTS(SELECT 1 FROM public.clients WHERE client_id=NEW.client_id AND is_active) THEN
   RAISE EXCEPTION 'Оформление возможно только для активного клиента';
  END IF;
  SELECT duration_days,price INTO days_count,tariff_price FROM public.memberships
  WHERE membership_id=NEW.membership_id AND is_active;
  IF NOT FOUND THEN RAISE EXCEPTION 'Тариф не найден или неактивен'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.employees WHERE employee_id=NEW.employee_id AND is_active) THEN
   RAISE EXCEPTION 'Сотрудник не найден или неактивен';
  END IF;
  IF NEW.end_date IS NULL THEN NEW.end_date:=NEW.start_date+days_count-1; END IF;
  IF NEW.sold_price IS NULL THEN NEW.sold_price:=tariff_price; END IF;
 ELSE
  IF ROW(NEW.client_id,NEW.membership_id,NEW.employee_id,NEW.start_date,NEW.sold_price)
   IS DISTINCT FROM ROW(OLD.client_id,OLD.membership_id,OLD.employee_id,OLD.start_date,OLD.sold_price) THEN
   RAISE EXCEPTION 'Реквизиты и цена оформленной продажи неизменяемы';
  END IF;
  IF NEW.end_date<OLD.end_date THEN
   RAISE EXCEPTION 'Срок абонемента можно только продлить';
  END IF;
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER subscriptions_before_row BEFORE INSERT OR UPDATE OR DELETE ON public.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.check_subscription_row();

CREATE FUNCTION public.check_payment_row() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
BEGIN
 IF TG_OP='DELETE' THEN
  IF NOT OLD.is_refunded THEN RAISE EXCEPTION 'Сначала оформите возврат платежа'; END IF;
  RETURN OLD;
 END IF;
 IF TG_OP='INSERT' THEN
  IF NEW.is_refunded THEN RAISE EXCEPTION 'Новый платёж не может быть возвратом'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.employees WHERE employee_id=NEW.employee_id AND is_active) THEN
   RAISE EXCEPTION 'Сотрудник не найден или неактивен';
  END IF;
 ELSE
  IF ROW(NEW.subscription_id,NEW.employee_id,NEW.amount,NEW.paid_at,NEW.method)
   IS DISTINCT FROM ROW(OLD.subscription_id,OLD.employee_id,OLD.amount,OLD.paid_at,OLD.method) THEN
   RAISE EXCEPTION 'Реквизиты проведённого платежа неизменяемы';
  END IF;
  IF OLD.is_refunded AND NOT NEW.is_refunded THEN
   RAISE EXCEPTION 'Отмена оформленного возврата не допускается';
  END IF;
 END IF;
 IF NEW.paid_at>clock_timestamp() THEN RAISE EXCEPTION 'Платёж не может быть датирован будущим'; END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER payments_before_row BEFORE INSERT OR UPDATE OR DELETE ON public.payments
FOR EACH ROW EXECUTE FUNCTION public.check_payment_row();

CREATE FUNCTION public.check_training_row() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
BEGIN
 IF TG_OP='INSERT' THEN
  IF NEW.starts_at<=clock_timestamp() THEN RAISE EXCEPTION 'Новое занятие должно быть в будущем'; END IF;
 ELSE
  IF OLD.is_cancelled AND NOT NEW.is_cancelled THEN
   RAISE EXCEPTION 'Отменённое занятие не возобновляется';
  END IF;
  IF NEW.is_cancelled AND NOT OLD.is_cancelled AND OLD.starts_at<=clock_timestamp() THEN
   RAISE EXCEPTION 'Начавшееся занятие отменить нельзя';
  END IF;
  IF ROW(NEW.starts_at,NEW.duration_min,NEW.trainer_id,NEW.hall_id)
   IS DISTINCT FROM ROW(OLD.starts_at,OLD.duration_min,OLD.trainer_id,OLD.hall_id)
   AND EXISTS(SELECT 1 FROM public.bookings WHERE training_id=OLD.training_id AND status<>'cancelled') THEN
   RAISE EXCEPTION 'Сначала отмените записи перед изменением расписания';
  END IF;
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER trainings_before_row BEFORE INSERT OR UPDATE ON public.trainings
FOR EACH ROW EXECUTE FUNCTION public.check_training_row();

CREATE FUNCTION public.check_booking_row() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
DECLARE class_start timestamptz; class_cancelled boolean;
BEGIN
 IF TG_OP='DELETE' THEN
  IF OLD.status<>'cancelled' THEN RAISE EXCEPTION 'Удаляется только отменённая запись'; END IF;
  RETURN OLD;
 END IF;
 SELECT starts_at,is_cancelled INTO class_start,class_cancelled
 FROM public.trainings WHERE training_id=NEW.training_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Занятие не найдено'; END IF;
 IF TG_OP='INSERT' THEN
  IF NEW.status<>'booked' THEN RAISE EXCEPTION 'Начальный статус записи: booked'; END IF;
  IF class_start<=clock_timestamp() OR class_cancelled THEN
   RAISE EXCEPTION 'Запись на начавшееся или отменённое занятие запрещена';
  END IF;
  NEW.booked_at:=clock_timestamp();
 ELSE
  IF ROW(NEW.training_id,NEW.client_id,NEW.booked_at)
   IS DISTINCT FROM ROW(OLD.training_id,OLD.client_id,OLD.booked_at) THEN
   RAISE EXCEPTION 'Клиента, занятие и время записи изменять нельзя';
  END IF;
  IF OLD.status IN ('attended','missed') AND NEW.status<>OLD.status THEN
   RAISE EXCEPTION 'Итоговая отметка посещения неизменяема';
  END IF;
  IF NEW.status IN ('attended','missed') AND NEW.status<>OLD.status THEN
   IF OLD.status<>'booked' OR class_start>clock_timestamp() THEN
    RAISE EXCEPTION 'Посещение отмечается после начала занятия из статуса booked';
   END IF;
  END IF;
  IF NEW.status='cancelled' AND NEW.status<>OLD.status AND class_start<=clock_timestamp() THEN
   RAISE EXCEPTION 'Отменить запись можно только до начала занятия';
  END IF;
  IF NEW.status='booked' AND OLD.status='cancelled' AND
   (class_start<=clock_timestamp() OR class_cancelled) THEN
   RAISE EXCEPTION 'Повторная запись на начавшееся или отменённое занятие запрещена';
  END IF;
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER bookings_before_row BEFORE INSERT OR UPDATE OR DELETE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.check_booking_row();

CREATE FUNCTION public.cancel_training_bookings() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
BEGIN
 IF NEW.is_cancelled AND NOT OLD.is_cancelled THEN
  UPDATE public.bookings SET status='cancelled'
  WHERE training_id=NEW.training_id AND status='booked';
 END IF;
 RETURN NULL;
END;
$$;
CREATE TRIGGER trainings_after_cancel AFTER UPDATE ON public.trainings
FOR EACH ROW EXECUTE FUNCTION public.cancel_training_bookings();

-- Журнал доступен на запись только через доверенную функцию триггера.
ALTER FUNCTION public.audit_financial_change() SECURITY DEFINER;
ALTER FUNCTION public.audit_financial_change() SET search_path=pg_catalog,public;

CREATE TRIGGER specializations_lock BEFORE INSERT OR UPDATE OR DELETE ON public.specializations
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER specializations_validate AFTER INSERT OR UPDATE OR DELETE ON public.specializations
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER halls_lock BEFORE INSERT OR UPDATE OR DELETE ON public.halls
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER halls_validate AFTER INSERT OR UPDATE OR DELETE ON public.halls
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER memberships_lock BEFORE INSERT OR UPDATE OR DELETE ON public.memberships
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER memberships_validate AFTER INSERT OR UPDATE OR DELETE ON public.memberships
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER clients_lock BEFORE INSERT OR UPDATE OR DELETE ON public.clients
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER clients_validate AFTER INSERT OR UPDATE OR DELETE ON public.clients
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER trainers_lock BEFORE INSERT OR UPDATE OR DELETE ON public.trainers
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER trainers_validate AFTER INSERT OR UPDATE OR DELETE ON public.trainers
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER employees_lock BEFORE INSERT OR UPDATE OR DELETE ON public.employees
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER employees_validate AFTER INSERT OR UPDATE OR DELETE ON public.employees
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER subscriptions_lock BEFORE INSERT OR UPDATE OR DELETE ON public.subscriptions
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER subscriptions_validate AFTER INSERT OR UPDATE OR DELETE ON public.subscriptions
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER trainings_lock BEFORE INSERT OR UPDATE OR DELETE ON public.trainings
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER trainings_validate AFTER INSERT OR UPDATE OR DELETE ON public.trainings
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER bookings_lock BEFORE INSERT OR UPDATE OR DELETE ON public.bookings
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER bookings_validate AFTER INSERT OR UPDATE OR DELETE ON public.bookings
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

CREATE TRIGGER payments_lock BEFORE INSERT OR UPDATE OR DELETE ON public.payments
FOR EACH STATEMENT EXECUTE FUNCTION public.lock_gym_changes();
CREATE TRIGGER payments_validate AFTER INSERT OR UPDATE OR DELETE ON public.payments
FOR EACH STATEMENT EXECUTE FUNCTION public.validate_gym_changes();

SELECT public.check_gym_state();
COMMIT;
