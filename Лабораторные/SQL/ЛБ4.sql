-- Лабораторная работа №4
-- Выполнять по разделам в Query Tool; для опытов с ошибками запускать блоки отдельно.

-- 1. Подготовка несовпадающих данных для внешних соединений | База: fitness_labs
CREATE SCHEMA lab04;
CREATE TABLE lab04.clients AS SELECT * FROM public.clients;
CREATE TABLE lab04.memberships AS SELECT * FROM public.memberships;
CREATE TABLE lab04.subscriptions AS SELECT * FROM public.subscriptions;
CREATE TABLE lab04.trainers AS SELECT * FROM public.trainers;
CREATE TABLE lab04.trainings AS SELECT * FROM public.trainings;
CREATE TABLE lab04.visits AS SELECT * FROM public.visits;
INSERT INTO lab04.clients VALUES(4,'Тестовый клиент','2001-01-01','+79000000004',NULL,true);
INSERT INTO lab04.memberships VALUES(4,'Неделя',7,2000);
INSERT INTO lab04.visits VALUES(4,4,2,'2025-02-01',true);

-- 2. Запросы 1–4: INNER, три таблицы, NATURAL, LEFT | База: fitness_labs
SELECT '1. INNER' AS query, c.client_id AS id,
 c.full_name || ': подписка ' || s.subscription_id AS result
FROM lab04.clients c INNER JOIN lab04.subscriptions s ON s.client_id=c.client_id
UNION ALL
SELECT '2. Три таблицы',c.client_id,c.full_name || ': ' || m.name
FROM lab04.clients c JOIN lab04.subscriptions s ON s.client_id=c.client_id
JOIN lab04.memberships m ON m.membership_id=s.membership_id
UNION ALL
SELECT '3. NATURAL', trainer_id, full_name || ': ' || title
FROM (SELECT trainer_id,full_name FROM lab04.trainers) r
NATURAL JOIN (SELECT trainer_id,title FROM lab04.trainings) t
UNION ALL
SELECT '4. LEFT',c.client_id,c.full_name || ': ' || COALESCE(s.subscription_id::text,'NULL')
FROM lab04.clients c LEFT OUTER JOIN lab04.subscriptions s ON s.client_id=c.client_id
ORDER BY 1,2,3;

-- 3. Запросы 5–8: RIGHT, FULL, CROSS, USING | База: fitness_labs
SELECT '5. RIGHT' AS query,m.membership_id AS id,
 m.name || ': ' || COALESCE(s.subscription_id::text,'NULL') AS result
FROM lab04.subscriptions s RIGHT OUTER JOIN lab04.memberships m
ON m.membership_id=s.membership_id
UNION ALL
SELECT '6. FULL',COALESCE(a.client_id,b.client_id),
 'подписка=' || COALESCE(a.client_id::text,'NULL') || ', визит=' || COALESCE(b.client_id::text,'NULL')
FROM (SELECT DISTINCT client_id FROM lab04.subscriptions) a
FULL OUTER JOIN (SELECT DISTINCT client_id FROM lab04.visits) b USING(client_id)
UNION ALL
SELECT '7. CROSS',r.trainer_id,r.full_name || ': ' || m.name
FROM lab04.trainers r CROSS JOIN lab04.memberships m
UNION ALL
SELECT '8. USING',trainer_id,r.full_name || ': ' || t.title
FROM lab04.trainers r JOIN lab04.trainings t USING(trainer_id)
ORDER BY 1,2,3;
