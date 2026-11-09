-- Лабораторная работа №6
-- Выполнять по разделам в Query Tool; для опытов с ошибками запускать блоки отдельно.

-- 1. Подготовка копий и массива платежей | База: fitness_labs
CREATE SCHEMA lab06;
CREATE TABLE lab06.clients AS SELECT * FROM public.clients;
CREATE TABLE lab06.trainers AS SELECT * FROM public.trainers;
CREATE TABLE lab06.memberships AS SELECT * FROM public.memberships;
CREATE TABLE lab06.trainings AS SELECT * FROM public.trainings;
CREATE TABLE lab06.payments AS
SELECT g AS payment_id,1+g%1000 AS client_id,100+g%5000 AS amount,
 DATE '2025-01-01'+g%365 AS payment_date,g%100<>0 AS is_refunded
FROM generate_series(1,200000) g;
ANALYZE lab06.payments;

-- 2. План до создания индекса | База: fitness_labs
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab06.payments WHERE client_id=42;

-- 3. Десять индексов: по два каждой разновидности | База: fitness_labs
CREATE INDEX p_client_idx ON lab06.payments(client_id);
CREATE INDEX t_date_idx ON lab06.trainings(training_date);
CREATE INDEX t_trainer_date_idx ON lab06.trainings(trainer_id,training_date);
CREATE INDEX p_client_date_idx ON lab06.payments(client_id,payment_date DESC);
CREATE UNIQUE INDEX c_phone_unique ON lab06.clients(phone);
CREATE UNIQUE INDEX m_name_unique ON lab06.memberships(name);
CREATE INDEX t_name_lower_idx ON lab06.trainers(lower(full_name));
CREATE UNIQUE INDEX c_email_lower_unique ON lab06.clients(lower(email));
CREATE INDEX p_not_refunded_idx ON lab06.payments(client_id) WHERE NOT is_refunded;
CREATE INDEX c_active_name_idx ON lab06.clients(full_name) WHERE is_active;
ANALYZE lab06.payments;
SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='lab06' ORDER BY indexname;

-- 4. План после создания индекса | База: fitness_labs
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab06.payments WHERE client_id=42;

-- 5. Повторное выполнение запроса | База: fitness_labs
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab06.payments WHERE client_id=42;

-- 6. Проверки остальных разновидностей индексов | База: fitness_labs
SELECT 'Дата' AS test,count(*)::text AS result FROM lab06.trainings
WHERE training_date='2025-02-01'
UNION ALL SELECT 'Два поля',count(*)::text FROM lab06.trainings
WHERE trainer_id=1 AND training_date='2025-02-01'
UNION ALL SELECT 'Телефон',count(*)::text FROM lab06.clients WHERE phone='+79001234567'
UNION ALL SELECT 'Тариф',count(*)::text FROM lab06.memberships WHERE name='Месяц'
UNION ALL SELECT 'lower имени',count(*)::text FROM lab06.trainers WHERE lower(full_name)=lower('ИВАНОВ ИВАН ИВАНОВИЧ')
UNION ALL SELECT 'lower email',count(*)::text FROM lab06.clients WHERE lower(email)='sidorov@mail.ru'
UNION ALL SELECT 'Частичный платежи',count(*)::text FROM lab06.payments WHERE NOT is_refunded AND client_id=1
UNION ALL SELECT 'Частичный клиенты',count(*)::text FROM lab06.clients WHERE is_active AND full_name LIKE 'Сидоров%';

-- 7. Проверка уникальности | База: fitness_labs
INSERT INTO lab06.clients(client_id,full_name,birth_date,phone,email,is_active)
VALUES(4,'Дубликат','2000-01-01','+79001234567','another@mail.ru',true);

-- 8. Удаление учебного индекса | База: fitness_labs
DROP INDEX lab06.t_date_idx;
SELECT count(*) AS indexes_left FROM pg_indexes WHERE schemaname='lab06';
