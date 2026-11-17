-- Изолированный эксперимент: только временные таблицы, рабочие данные не меняются.
-- В pgAdmin выполнить файл целиком в Query Tool базы gym_course.
-- Вкладка Messages содержит реальные планы EXPLAIN ANALYZE до/после.
BEGIN;
SET LOCAL TIME ZONE 'Europe/Moscow';

CREATE TEMP TABLE bench_trainings ON COMMIT DROP AS
SELECT training_id,starts_at,is_cancelled,title FROM public.trainings WITH NO DATA;
INSERT INTO bench_trainings
SELECT g, TIMESTAMPTZ '2025-01-01 08:00:00+03' + (g-1)*INTERVAL '1 hour',
       g%10=0, 'Учебное занятие ' || g
FROM generate_series(1,20000) AS g;
ANALYZE bench_trainings;

-- B-tree: до индекса, ожидается последовательное чтение.
EXPLAIN (ANALYZE, BUFFERS)
SELECT training_id,title,starts_at FROM bench_trainings
WHERE NOT is_cancelled
  AND starts_at >= TIMESTAMPTZ '2026-11-17 00:00:00+03'
  AND starts_at < TIMESTAMPTZ '2026-11-24 00:00:00+03'
ORDER BY starts_at;

CREATE INDEX bench_trainings_start ON bench_trainings (starts_at)
WHERE NOT is_cancelled;
ANALYZE bench_trainings;

-- B-tree: тот же запрос после создания индекса.
EXPLAIN (ANALYZE, BUFFERS)
SELECT training_id,title,starts_at FROM bench_trainings
WHERE NOT is_cancelled
  AND starts_at >= TIMESTAMPTZ '2026-11-17 00:00:00+03'
  AND starts_at < TIMESTAMPTZ '2026-11-24 00:00:00+03'
ORDER BY starts_at;

CREATE TEMP TABLE bench_subscriptions ON COMMIT DROP AS
SELECT subscription_id,client_id,start_date,end_date
FROM public.subscriptions WITH NO DATA;
INSERT INTO bench_subscriptions
SELECT g, ((g-1)%2000)+1,
       DATE '2025-01-01'+((g-1)/2000)*31,
       DATE '2025-01-01'+((g-1)/2000)*31+29
FROM generate_series(1,20000) AS g;
ANALYZE bench_subscriptions;

-- GiST: до индекса.
EXPLAIN (ANALYZE, BUFFERS)
SELECT subscription_id FROM bench_subscriptions
WHERE client_id=CAST(1729 AS bigint)
  AND daterange(start_date,end_date,'[]') @> DATE '2025-05-15';

-- Те же ключи и метод, что у ограничения EXCLUDE рабочей таблицы.
CREATE INDEX bench_subscriptions_period ON bench_subscriptions
USING gist (client_id,daterange(start_date,end_date,'[]'));
ANALYZE bench_subscriptions;

-- GiST: тот же запрос после создания индекса.
EXPLAIN (ANALYZE, BUFFERS)
SELECT subscription_id FROM bench_subscriptions
WHERE client_id=CAST(1729 AS bigint)
  AND daterange(start_date,end_date,'[]') @> DATE '2025-05-15';

SELECT 'B-tree' AS index_type,
       pg_size_pretty(pg_relation_size('bench_trainings_start')) AS index_size
UNION ALL
SELECT 'GiST',pg_size_pretty(pg_relation_size('bench_subscriptions_period'));
ROLLBACK;
-- После ROLLBACK временных таблиц и индексов в сеансе не остаётся.
