-- Лабораторная работа №8
-- Выполнять по разделам в Query Tool; для опытов с ошибками запускать блоки отдельно.
-- Требуются два независимых подключения A и B. Не запускать весь файл одним блоком.

-- 1. Подготовка двух сеансов | База: fitness_labs | Сеанс: A
CREATE SCHEMA IF NOT EXISTS lab08;
DROP TABLE IF EXISTS lab08.accounts;
CREATE TABLE lab08.accounts(id integer PRIMARY KEY,price integer NOT NULL);
INSERT INTO lab08.accounts VALUES(1,100),(2,200);
SELECT pg_backend_pid() AS session_a;

-- 2. Проверка второго подключения | База: fitness_labs | Сеанс: B
SELECT pg_backend_pid() AS session_b;

-- 3. Read Uncommitted: незавершённое изменение | База: fitness_labs | Сеанс: A
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
UPDATE lab08.accounts SET price=999 WHERE id=1;

-- 4. Read Uncommitted: чтение в другом сеансе | База: fitness_labs | Сеанс: B
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SELECT pg_backend_pid() AS session_b, current_setting('transaction_isolation') AS isolation,
 price AS visible_price FROM lab08.accounts WHERE id=1;

-- 5. Отмена транзакции B | База: fitness_labs | Сеанс: B
ROLLBACK;

-- 6. Отмена транзакции A | База: fitness_labs | Сеанс: A
ROLLBACK;

-- 7. Read Committed: первое прибавление | База: fitness_labs | Сеанс: A
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE lab08.accounts SET price=price+10 WHERE id=1;

-- 8. Read Committed: второе прибавление ожидает | База: fitness_labs | Сеанс: B
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE lab08.accounts SET price=price+20 WHERE id=1;

-- 9. Проверка блокировки второго сеанса | База: fitness_labs | Сеанс: A
SELECT pid,state,wait_event_type,wait_event
FROM pg_stat_activity WHERE datname=current_database()
AND wait_event_type='Lock';

-- 10. Фиксация первого прибавления | База: fitness_labs | Сеанс: A
COMMIT;

-- 11. Фиксация второго прибавления | База: fitness_labs | Сеанс: B
COMMIT;
SELECT price FROM lab08.accounts WHERE id=1;

-- 12. Read Committed: первое чтение | База: fitness_labs | Сеанс: A
BEGIN ISOLATION LEVEL READ COMMITTED;
CREATE TEMP TABLE before_rc ON COMMIT DROP AS
SELECT price FROM lab08.accounts WHERE id=1;

-- 13. Read Committed: изменение и COMMIT | База: fitness_labs | Сеанс: B
BEGIN;
UPDATE lab08.accounts SET price=price+5 WHERE id=1;
COMMIT;

-- 14. Неповторяющееся чтение | База: fitness_labs | Сеанс: A
SELECT b.price AS first_read,a.price AS second_read
FROM before_rc b CROSS JOIN lab08.accounts a WHERE a.id=1;

-- 15. Завершение Read Committed | База: fitness_labs | Сеанс: A
COMMIT;

-- 16. Repeatable Read: исходный снимок | База: fitness_labs | Сеанс: A
BEGIN ISOLATION LEVEL REPEATABLE READ;
CREATE TEMP TABLE before_rr AS
SELECT count(*) AS cnt,sum(price) AS total FROM lab08.accounts;

-- 17. Repeatable Read: изменение и новая строка | База: fitness_labs | Сеанс: B
BEGIN;
UPDATE lab08.accounts SET price=price+5 WHERE id=1;
INSERT INTO lab08.accounts VALUES(3,50);
COMMIT;

-- 18. Стабильный снимок и отсутствие фантомов | База: fitness_labs | Сеанс: A
CREATE TEMP TABLE inside_rr AS
SELECT count(*) AS cnt,sum(price) AS total FROM lab08.accounts;
COMMIT;
SELECT '1. Начальный снимок' AS stage,cnt,total FROM before_rr
UNION ALL SELECT '2. Внутри Repeatable Read',cnt,total FROM inside_rr
UNION ALL SELECT '3. После COMMIT',count(*),sum(price) FROM lab08.accounts
ORDER BY 1;

-- 19. Repeatable Read: конкурентное обновление A | База: fitness_labs | Сеанс: A
BEGIN ISOLATION LEVEL REPEATABLE READ;
UPDATE lab08.accounts SET price=price+10 WHERE id=1;

-- 20. Repeatable Read: снимок B | База: fitness_labs | Сеанс: B
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT price FROM lab08.accounts WHERE id=1;

-- 21. Repeatable Read: ожидающее обновление B | База: fitness_labs | Сеанс: B
UPDATE lab08.accounts SET price=price+20 WHERE id=1;

-- 22. Repeatable Read: фиксация A | База: fitness_labs | Сеанс: A
COMMIT;

-- 23. Ошибка сериализации Repeatable Read | База: fitness_labs | Сеанс: B
-- Результат ожидавшего UPDATE после COMMIT сеанса A.

-- 24. Откат ошибочной транзакции | База: fitness_labs | Сеанс: B
ROLLBACK;

-- 25. Подготовка таблицы сравнения | База: fitness_labs | Сеанс: A
CREATE TEMP TABLE outcomes(stage text,price integer);
INSERT INTO outcomes SELECT '1. До изменения',price FROM lab08.accounts WHERE id=1;

-- 26. Проверка ROLLBACK | База: fitness_labs | Сеанс: A
BEGIN;
UPDATE lab08.accounts SET price=price+7 WHERE id=1;
ROLLBACK;

-- 27. Сохранение результата отката | База: fitness_labs | Сеанс: A
INSERT INTO outcomes SELECT '2. После ROLLBACK',price FROM lab08.accounts WHERE id=1;

-- 28. Проверка COMMIT | База: fitness_labs | Сеанс: A
BEGIN;
UPDATE lab08.accounts SET price=price+7 WHERE id=1;
COMMIT;

-- 29. Сравнение COMMIT и ROLLBACK | База: fitness_labs | Сеанс: A
INSERT INTO outcomes SELECT '3. После COMMIT',price FROM lab08.accounts WHERE id=1;
SELECT * FROM outcomes ORDER BY stage;

-- 30. Serializable: подготовка дополнительного задания | База: fitness_labs | Сеанс: A
CREATE TABLE lab08.duty(id integer PRIMARY KEY,on_duty boolean);
INSERT INTO lab08.duty VALUES(1,true),(2,true);

-- 31. Serializable: чтение A | База: fitness_labs | Сеанс: A
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) FROM lab08.duty WHERE on_duty;

-- 32. Serializable: чтение B | База: fitness_labs | Сеанс: B
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) FROM lab08.duty WHERE on_duty;

-- 33. Serializable: изменение A | База: fitness_labs | Сеанс: A
UPDATE lab08.duty SET on_duty=false WHERE id=1;

-- 34. Serializable: изменение B | База: fitness_labs | Сеанс: B
UPDATE lab08.duty SET on_duty=false WHERE id=2;

-- 35. Serializable: фиксация A | База: fitness_labs | Сеанс: A
COMMIT;

-- 36. Serializable: защита от аномалии | База: fitness_labs | Сеанс: B
COMMIT;

-- 37. Итог дополнительного задания | База: fitness_labs | Сеанс: A
SELECT * FROM lab08.duty ORDER BY id;
