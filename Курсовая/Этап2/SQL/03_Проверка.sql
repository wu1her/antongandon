SET TIME ZONE 'Europe/Moscow';
-- Число строк в каждой таблице.
SELECT 'specializations' AS table_name, count(*) AS row_count FROM specializations
UNION ALL
SELECT 'halls' AS table_name, count(*) AS row_count FROM halls
UNION ALL
SELECT 'memberships' AS table_name, count(*) AS row_count FROM memberships
UNION ALL
SELECT 'clients' AS table_name, count(*) AS row_count FROM clients
UNION ALL
SELECT 'trainers' AS table_name, count(*) AS row_count FROM trainers
UNION ALL
SELECT 'employees' AS table_name, count(*) AS row_count FROM employees
UNION ALL
SELECT 'subscriptions' AS table_name, count(*) AS row_count FROM subscriptions
UNION ALL
SELECT 'trainings' AS table_name, count(*) AS row_count FROM trainings
UNION ALL
SELECT 'bookings' AS table_name, count(*) AS row_count FROM bookings
UNION ALL
SELECT 'payments' AS table_name, count(*) AS row_count FROM payments
UNION ALL
SELECT 'audit_log' AS table_name, count(*) AS row_count FROM audit_log
ORDER BY table_name;

-- Во всех проверках ниже ожидается ноль нарушений.
SELECT 'Пересечения абонементов' AS check_name, count(*) AS violations
FROM subscriptions a JOIN subscriptions b ON a.client_id=b.client_id
 AND a.subscription_id<b.subscription_id
 AND daterange(a.start_date,a.end_date,'[]') && daterange(b.start_date,b.end_date,'[]')
UNION ALL
SELECT 'Необеспеченные записи', count(*) FROM bookings b
JOIN trainings t USING(training_id) JOIN clients c USING(client_id)
WHERE b.status <> 'cancelled' AND (NOT c.is_active OR t.is_cancelled OR NOT EXISTS (
 SELECT 1 FROM subscriptions s WHERE s.client_id=b.client_id
 AND (t.starts_at AT TIME ZONE 'Europe/Moscow')::date BETWEEN s.start_date AND s.end_date
 AND COALESCE((SELECT sum(p.amount) FROM payments p
 WHERE p.subscription_id=s.subscription_id AND NOT p.is_refunded),0)=s.sold_price))
UNION ALL
SELECT 'Переплата',count(*) FROM subscriptions s
WHERE COALESCE((SELECT sum(amount) FROM payments p
 WHERE p.subscription_id=s.subscription_id AND NOT is_refunded),0)>s.sold_price
UNION ALL
SELECT 'Превышение вместимости зала',count(*) FROM trainings t
JOIN halls h USING(hall_id) WHERE t.max_capacity>h.capacity
UNION ALL
SELECT 'Переполнение занятий',count(*) FROM trainings t
WHERE (SELECT count(*) FROM bookings b WHERE b.training_id=t.training_id
 AND b.status<>'cancelled')>t.max_capacity
UNION ALL
SELECT 'Пересечения расписания',count(*) FROM trainings a JOIN trainings b
 ON a.training_id<b.training_id AND (a.hall_id=b.hall_id OR a.trainer_id=b.trainer_id)
 AND NOT a.is_cancelled AND NOT b.is_cancelled
 AND tstzrange(a.starts_at,a.starts_at+make_interval(mins=>a.duration_min),'[)')
 && tstzrange(b.starts_at,b.starts_at+make_interval(mins=>b.duration_min),'[)')
UNION ALL
SELECT 'Будущая дата рождения',count(*) FROM clients WHERE birth_date>CURRENT_DATE;

-- Реальные события аудита после первоначальной загрузки.
SELECT table_name, operation, count(*) AS event_count
FROM audit_log GROUP BY table_name,operation ORDER BY table_name,operation;

-- Отрицательные проверки базовых ограничений. Изменения откатываются.
BEGIN;
DO $$
BEGIN
 BEGIN
  INSERT INTO subscriptions(client_id,membership_id,employee_id,start_date,end_date,sold_price)
  SELECT client_id,membership_id,employee_id,start_date,end_date,sold_price
  FROM subscriptions WHERE subscription_id=4;
  RAISE EXCEPTION 'ОШИБКА: пересечение периодов допущено';
 EXCEPTION WHEN exclusion_violation THEN
  RAISE NOTICE 'OK: пересечение абонементов отклонено';
 END;
 BEGIN
  INSERT INTO bookings(training_id,client_id)
  SELECT training_id,client_id FROM bookings WHERE booking_id=1;
  RAISE EXCEPTION 'ОШИБКА: повторная запись допущена';
 EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'OK: повторная запись отклонена';
 END;
 BEGIN
  DELETE FROM clients WHERE client_id=1;
  RAISE EXCEPTION 'ОШИБКА: клиент с историей удалён';
 EXCEPTION WHEN foreign_key_violation THEN
  RAISE NOTICE 'OK: удаление клиента с историей отклонено';
 END;
END $$;
ROLLBACK;
