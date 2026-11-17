-- Выполнять от postgres после 06–09. Все изменения откатываются.
BEGIN;
SET LOCAL TIME ZONE 'Europe/Moscow';
CREATE TEMP TABLE test_results(test_name text,result text,details text) ON COMMIT DROP;
GRANT INSERT,SELECT ON test_results TO gym_manager,gym_analyst;
CREATE FUNCTION pg_temp.expect_error(test_name text,command text,expected text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE failed boolean:=false; message text;
BEGIN
 BEGIN
  EXECUTE command;
 EXCEPTION WHEN OTHERS THEN
  failed:=true; message:=SQLERRM;
  IF position(expected in message)=0 THEN
   RAISE EXCEPTION 'Неожиданная ошибка в %: %',test_name,message;
  END IF;
 END;
 IF NOT failed THEN RAISE EXCEPTION 'Запрет не сработал: %',test_name; END IF;
 INSERT INTO pg_temp.test_results VALUES(test_name,'OK',message);
END;
$$;
CREATE FUNCTION pg_temp.expect_true(test_name text,condition boolean) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
 IF condition IS DISTINCT FROM true THEN RAISE EXCEPTION 'Проверка не пройдена: %',test_name; END IF;
 INSERT INTO pg_temp.test_results VALUES(test_name,'OK','Результат соответствует ожиданию');
END;
$$;

DO $$
DECLARE s14 bigint; s15 bigint; p14 bigint; p15 bigint; t1 bigint; t2 bigint;
 b1 bigint; audit_sub bigint; audit_pay bigint; default_sub bigint;
BEGIN
 PERFORM pg_temp.expect_error('01. Будущая дата рождения',
 'UPDATE public.clients SET birth_date=CURRENT_DATE+1 WHERE client_id=1','Дата рождения');
 PERFORM pg_temp.expect_error('02. Продажа неактивному клиенту',
 $sql$INSERT INTO public.subscriptions(client_id,membership_id,employee_id,start_date)
 VALUES(3,4,2,'2040-01-01')$sql$,'активного клиента');

 INSERT INTO public.subscriptions(client_id,membership_id,employee_id,start_date,end_date,sold_price)
 VALUES(14,4,2,'2040-01-01','2040-03-31',100) RETURNING subscription_id INTO s14;
 INSERT INTO public.subscriptions(client_id,membership_id,employee_id,start_date,end_date,sold_price)
 VALUES(15,4,2,'2040-01-01','2040-03-31',100) RETURNING subscription_id INTO s15;
 INSERT INTO public.subscriptions(client_id,membership_id,employee_id,start_date)
 VALUES(14,4,2,'2041-01-01') RETURNING subscription_id INTO default_sub;
 PERFORM pg_temp.expect_true('03. Расчёт включительной даты и цены',
 (SELECT s.end_date=s.start_date+m.duration_days-1 AND s.sold_price=m.price
 FROM public.subscriptions s JOIN public.memberships m USING(membership_id)
 WHERE s.subscription_id=default_sub));
 PERFORM pg_temp.expect_error('04. Пересечение абонементов',
 $sql$INSERT INTO public.subscriptions(client_id,membership_id,employee_id,start_date,end_date,sold_price)
 VALUES(14,4,2,'2040-01-10','2040-02-10',100)$sql$,'subscriptions_no_overlap');
 INSERT INTO public.payments(subscription_id,employee_id,amount) VALUES(s14,2,100)
 RETURNING payment_id INTO p14;
 PERFORM pg_temp.expect_error('05. Переплата',format(
 'INSERT INTO public.payments(subscription_id,employee_id,amount) VALUES(%s,2,1)',s14),'превышает цену');

 INSERT INTO public.trainings(trainer_id,hall_id,title,starts_at,duration_min,max_capacity)
 VALUES(14,14,'Проверка записи','2040-01-05 10:00+03',60,1) RETURNING training_id INTO t1;
 INSERT INTO public.trainings(trainer_id,hall_id,title,starts_at,duration_min,max_capacity)
 VALUES(15,15,'Проверка вместимости','2040-01-06 10:00+03',60,20) RETURNING training_id INTO t2;
 PERFORM pg_temp.expect_error('06. Вместимость зала',
 $sql$UPDATE public.halls SET capacity=10 WHERE hall_id=15$sql$,'вместимость зала');
 PERFORM pg_temp.expect_error('07. Пересечение по залу',
 $sql$INSERT INTO public.trainings(trainer_id,hall_id,title,starts_at,duration_min,max_capacity)
 VALUES(15,14,'Конфликт','2040-01-05 10:30+03',60,1)$sql$,'Пересечение расписания');
 PERFORM pg_temp.expect_error('08. Пересечение по тренеру',
 $sql$INSERT INTO public.trainings(trainer_id,hall_id,title,starts_at,duration_min,max_capacity)
 VALUES(14,15,'Конфликт','2040-01-05 10:30+03',60,1)$sql$,'Пересечение расписания');
 PERFORM pg_temp.expect_error('09. Неактивный тренер',
 $sql$INSERT INTO public.trainings(trainer_id,hall_id,title,starts_at,duration_min,max_capacity)
 VALUES(3,13,'Неактивный','2040-01-07 10:00+03',60,1)$sql$,'неактивного тренера');
 PERFORM pg_temp.expect_error('10. Запись без полной оплаты',format(
 'INSERT INTO public.bookings(training_id,client_id) VALUES(%s,15)',t1),'полностью оплаченного');
 INSERT INTO public.bookings(training_id,client_id) VALUES(t1,14) RETURNING booking_id INTO b1;
 PERFORM pg_temp.expect_true('11. Успешная оплаченная запись',
 (SELECT status='booked' FROM public.bookings WHERE booking_id=b1));
 INSERT INTO public.payments(subscription_id,employee_id,amount) VALUES(s15,2,100)
 RETURNING payment_id INTO p15;
 PERFORM pg_temp.expect_error('12. Переполнение занятия',format(
 'INSERT INTO public.bookings(training_id,client_id) VALUES(%s,15)',t1),'нет свободных мест');
 PERFORM pg_temp.expect_error('13. Ранняя отметка посещения',format(
 $sql$UPDATE public.bookings SET status='attended' WHERE booking_id=%s$sql$,b1),'после начала');
 PERFORM pg_temp.expect_error('14. Деактивация записанного клиента',
 'UPDATE public.clients SET is_active=false WHERE client_id=14','полностью оплаченного');
 PERFORM pg_temp.expect_error('15. Возврат при существующей записи',format(
 'UPDATE public.payments SET is_refunded=true WHERE payment_id=%s',p14),'полностью оплаченного');
 PERFORM pg_temp.expect_error('16. Перенос занятого занятия',format(
 $sql$UPDATE public.trainings SET starts_at=starts_at+INTERVAL '1 hour' WHERE training_id=%s$sql$,t1),'Сначала отмените записи');
 PERFORM pg_temp.expect_error('17. Изменение цены сделки',format(
 'UPDATE public.subscriptions SET sold_price=101 WHERE subscription_id=%s',s14),'неизменяемы');
 PERFORM pg_temp.expect_error('18. Изменение суммы платежа',format(
 'UPDATE public.payments SET amount=101 WHERE payment_id=%s',p14),'неизменяемы');
 PERFORM pg_temp.expect_error('19. Удаление невозвращённого платежа',format(
 'DELETE FROM public.payments WHERE payment_id=%s',p15),'Сначала оформите возврат');
 UPDATE public.trainings SET is_cancelled=true WHERE training_id=t1;
 PERFORM pg_temp.expect_true('20. Автоматическая отмена записи',
 (SELECT status='cancelled' FROM public.bookings WHERE booking_id=b1));
 PERFORM pg_temp.expect_error('21. Запись на отменённое занятие',format(
 'INSERT INTO public.bookings(training_id,client_id) VALUES(%s,15)',t1),'отменённое занятие');
 PERFORM pg_temp.expect_error('22. Возобновление отменённого занятия',format(
 'UPDATE public.trainings SET is_cancelled=false WHERE training_id=%s',t1),'не возобновляется');
 PERFORM pg_temp.expect_error('23. Изменение итоговой отметки',
 $sql$UPDATE public.bookings SET status='missed' WHERE booking_id=16$sql$,'неизменяема');
 PERFORM pg_temp.expect_error('24. Удаление клиента с историей',
 'DELETE FROM public.clients WHERE client_id=14','foreign key constraint');

 -- Аудит реальных INSERT, UPDATE, DELETE обеих финансовых таблиц.
 INSERT INTO public.subscriptions(client_id,membership_id,employee_id,start_date,end_date,sold_price)
 VALUES(15,4,2,'2042-01-01','2042-01-28',100) RETURNING subscription_id INTO audit_sub;
 UPDATE public.subscriptions SET end_date=end_date+1 WHERE subscription_id=audit_sub;
 INSERT INTO public.payments(subscription_id,employee_id,amount) VALUES(audit_sub,2,100)
 RETURNING payment_id INTO audit_pay;
 UPDATE public.payments SET is_refunded=true WHERE payment_id=audit_pay;
 DELETE FROM public.payments WHERE payment_id=audit_pay;
 DELETE FROM public.subscriptions WHERE subscription_id=audit_sub;
 PERFORM pg_temp.expect_true('25. Аудит INSERT UPDATE DELETE',
 (SELECT count(*)=6 AND count(DISTINCT (table_name,operation))=6 FROM public.audit_log
 WHERE (table_name='subscriptions' AND row_id=audit_sub)
 OR (table_name='payments' AND row_id=audit_pay)));
END;
$$;

SET LOCAL ROLE gym_manager;
INSERT INTO public.clients(last_name,first_name,birth_date,phone)
VALUES('Проверка','Менеджер','2000-01-01','+79998880001');
INSERT INTO public.subscriptions(client_id,membership_id,employee_id,start_date)
SELECT client_id,4,2,DATE '2043-01-01' FROM public.clients WHERE phone='+79998880001';
INSERT INTO public.payments(subscription_id,employee_id,amount)
SELECT s.subscription_id,2,s.sold_price FROM public.subscriptions s
JOIN public.clients c USING(client_id) WHERE c.phone='+79998880001';
SELECT pg_temp.expect_true('26. Менеджер оформляет продажу и оплату',
 EXISTS(SELECT 1 FROM public.v_subscription_balance v JOIN public.clients c USING(client_id)
 WHERE c.phone='+79998880001' AND v.is_paid));
SELECT pg_temp.expect_error('27. Менеджер не удаляет историю',
 'DELETE FROM public.clients WHERE client_id=1','permission denied');
SELECT pg_temp.expect_error('28. Менеджер не читает аудит',
 'SELECT * FROM public.audit_log','permission denied');
SELECT pg_temp.expect_error('29. Менеджер не подменяет аудит',
 $$INSERT INTO public.audit_log(actor,table_name,operation,row_id)
 VALUES('x','payments','INSERT',1)$$,'permission denied');
RESET ROLE;
SELECT pg_temp.expect_true('30. Аудит доступен администратору',
 has_table_privilege('gym_admin','public.audit_log','SELECT'));

SET LOCAL ROLE gym_analyst;
SELECT pg_temp.expect_true('31. Аналитик читает финансовое представление',
 (SELECT count(*)>0 FROM public.v_daily_revenue));
SELECT pg_temp.expect_error('32. Аналитик не читает контакты',
 'SELECT phone,email FROM public.clients','permission denied');
SELECT pg_temp.expect_error('33. Аналитик не изменяет клиентов',
 $$UPDATE public.clients SET first_name='X' WHERE client_id=1$$,'permission denied');
SELECT pg_temp.expect_error('34. Аналитик не создаёт таблицы',
 'CREATE TABLE public.forbidden_test(id integer)','permission denied');
RESET ROLE;
SELECT test_name,result,details FROM pg_temp.test_results ORDER BY test_name;
ROLLBACK;
