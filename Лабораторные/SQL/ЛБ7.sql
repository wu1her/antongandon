-- Лабораторная работа №7
-- Выполнять по разделам в Query Tool; для опытов с ошибками запускать блоки отдельно.

-- 1. A1. Демобаза: EXPLAIN: последовательное чтение | База: demo
EXPLAIN
SELECT * FROM bookings.aircrafts;

-- 2. A2. Демобаза: COSTS OFF | База: demo
EXPLAIN (COSTS OFF)
SELECT * FROM bookings.aircrafts;

-- 3. A3. Демобаза: WHERE и Filter | База: demo
EXPLAIN
SELECT * FROM bookings.aircrafts WHERE range>4000;

-- 4. A4. Демобаза: ORDER BY и Sort | База: demo
EXPLAIN
SELECT * FROM bookings.aircrafts ORDER BY aircraft_code;

-- 5. A5. Демобаза: Индексная сортировка | База: demo
EXPLAIN
SELECT * FROM bookings.bookings ORDER BY book_ref LIMIT 100;

-- 6. A6. Демобаза: Index Cond | База: demo
EXPLAIN
SELECT * FROM bookings.bookings WHERE book_ref < '000100' ORDER BY book_ref;

-- 7. A7. Демобаза: Битовая карта | База: demo
EXPLAIN
SELECT * FROM bookings.seats WHERE aircraft_code='319';

-- 8. A8. Демобаза: Чтение только индекса | База: demo
EXPLAIN
SELECT book_ref FROM bookings.bookings WHERE book_ref BETWEEN '000000' AND '000100';

-- 9. A9. Демобаза: Агрегирование COUNT | База: demo
EXPLAIN
SELECT COUNT(*) FROM bookings.seats WHERE aircraft_code='319';

-- 10. A10. Демобаза: Агрегирование SUM | База: demo
EXPLAIN
SELECT SUM(total_amount) FROM bookings.bookings WHERE book_ref<'000100';

-- 11. A11. Демобаза: Соединение самолётов и мест | База: demo
EXPLAIN
SELECT a.model,s.seat_no,s.fare_conditions FROM bookings.aircrafts a JOIN bookings.seats s USING(aircraft_code) WHERE a.model LIKE 'Airbus%';

-- 12. A12. Демобаза: Соединение маршрутов и самолётов | База: demo
EXPLAIN
SELECT r.flight_no,r.departure_city,a.model FROM bookings.routes r JOIN bookings.aircrafts a USING(aircraft_code) ORDER BY r.departure_city;

-- 13. A13. Демобаза: Соединение билетов и перелётов | База: demo
EXPLAIN
SELECT t.ticket_no,t.passenger_name,f.flight_id FROM bookings.tickets t JOIN bookings.ticket_flights f USING(ticket_no) ORDER BY t.ticket_no;

-- 14. Подготовка собственных опытов и измерений | База: fitness_labs
CREATE SCHEMA lab07;
CREATE TABLE lab07.payments AS SELECT * FROM lab06.payments;
CREATE TABLE lab07.clients AS SELECT g AS client_id,
 'client' || g || '@example.ru' AS email FROM generate_series(1,50000) g;
CREATE TABLE lab07.measurements (
 test text, execution_ms numeric, actual_rows integer,
 shared_hit integer,shared_read integer,node text,plan jsonb);
CREATE FUNCTION lab07.measure(p_test text,p_sql text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE p jsonb; r jsonb;
BEGIN
 EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || p_sql INTO p;
 r:=p->0->'Plan';
 INSERT INTO lab07.measurements VALUES(p_test,
 (p->0->>'Execution Time')::numeric,(r->>'Actual Rows')::integer,
 COALESCE((r->>'Shared Hit Blocks')::integer,0),
 COALESCE((r->>'Shared Read Blocks')::integer,0),r->>'Node Type',p);
END;
$$;
ANALYZE lab07.payments;
ANALYZE lab07.clients;

-- 15. 1. Одиночный индекс — до | База: fitness_labs
SELECT lab07.measure('1. Одиночный индекс — до','SELECT * FROM lab07.payments WHERE client_id=42');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.payments WHERE client_id=42;

-- 16. 1. Одиночный индекс — создание индекса | База: fitness_labs
CREATE INDEX p_client_idx ON lab07.payments(client_id);
ANALYZE lab07.payments;

-- 17. 1. Одиночный индекс — после | База: fitness_labs
SELECT lab07.measure('1. Одиночный индекс — после','SELECT * FROM lab07.payments WHERE client_id=42');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.payments WHERE client_id=42;

-- 18. 2. Составной индекс — до | База: fitness_labs
SELECT lab07.measure('2. Составной индекс — до','SELECT * FROM lab07.payments WHERE client_id=42 ORDER BY payment_date DESC LIMIT 10');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.payments WHERE client_id=42 ORDER BY payment_date DESC LIMIT 10;

-- 19. 2. Составной индекс — создание индекса | База: fitness_labs
CREATE INDEX p_client_date_idx ON lab07.payments(client_id,payment_date DESC);
ANALYZE lab07.payments;

-- 20. 2. Составной индекс — после | База: fitness_labs
SELECT lab07.measure('2. Составной индекс — после','SELECT * FROM lab07.payments WHERE client_id=42 ORDER BY payment_date DESC LIMIT 10');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.payments WHERE client_id=42 ORDER BY payment_date DESC LIMIT 10;

-- 21. 3. Индекс выражения — до | База: fitness_labs
SELECT lab07.measure('3. Индекс выражения — до','SELECT * FROM lab07.clients WHERE lower(email)=''client12345@example.ru''');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.clients WHERE lower(email)='client12345@example.ru';

-- 22. 3. Индекс выражения — создание индекса | База: fitness_labs
CREATE INDEX c_email_idx ON lab07.clients(lower(email));
ANALYZE lab07.clients;

-- 23. 3. Индекс выражения — после | База: fitness_labs
SELECT lab07.measure('3. Индекс выражения — после','SELECT * FROM lab07.clients WHERE lower(email)=''client12345@example.ru''');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.clients WHERE lower(email)='client12345@example.ru';

-- 24. 4. Частичный индекс — до | База: fitness_labs
SELECT lab07.measure('4. Частичный индекс — до','SELECT * FROM lab07.payments WHERE NOT is_refunded AND amount>=4500');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.payments WHERE NOT is_refunded AND amount>=4500;

-- 25. 4. Частичный индекс — создание индекса | База: fitness_labs
CREATE INDEX p_partial_idx ON lab07.payments(amount) WHERE NOT is_refunded;
ANALYZE lab07.payments;

-- 26. 4. Частичный индекс — после | База: fitness_labs
SELECT lab07.measure('4. Частичный индекс — после','SELECT * FROM lab07.payments WHERE NOT is_refunded AND amount>=4500');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.payments WHERE NOT is_refunded AND amount>=4500;

-- 27. Индекс даты для обоих вариантов | База: fitness_labs
CREATE INDEX p_date_idx ON lab07.payments(payment_date);

-- 28. 5. Диапазон дат — до | База: fitness_labs
SELECT lab07.measure('5. Диапазон дат — до','SELECT * FROM lab07.payments WHERE EXTRACT(YEAR FROM payment_date)=2025 AND EXTRACT(MONTH FROM payment_date)=6');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.payments WHERE EXTRACT(YEAR FROM payment_date)=2025 AND EXTRACT(MONTH FROM payment_date)=6;

-- 29. 5. Диапазон дат — после | База: fitness_labs
SELECT lab07.measure('5. Диапазон дат — после','SELECT * FROM lab07.payments WHERE payment_date>=DATE ''2025-06-01'' AND payment_date<DATE ''2025-07-01''');
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab07.payments WHERE payment_date>=DATE '2025-06-01' AND payment_date<DATE '2025-07-01';

-- 30. Итог пяти опытов оптимизации | База: fitness_labs
SELECT test,execution_ms,actual_rows,shared_hit,shared_read,node
FROM lab07.measurements ORDER BY test;
