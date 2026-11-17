-- Выполнить в gym_course после файлов 01 и 02.
-- PostgreSQL 17. Индексы PK, UNIQUE и EXCLUDE уже созданы автоматически.
SET TIME ZONE 'Europe/Moscow';
BEGIN;
CREATE INDEX idx_trainers_specialization ON trainers (specialization_id);
CREATE INDEX idx_subscriptions_membership ON subscriptions (membership_id);
CREATE INDEX idx_subscriptions_employee ON subscriptions (employee_id);
CREATE INDEX idx_trainings_trainer ON trainings (trainer_id);
CREATE INDEX idx_trainings_hall ON trainings (hall_id);
CREATE INDEX idx_bookings_client ON bookings (client_id);
CREATE INDEX idx_payments_subscription ON payments (subscription_id);
CREATE INDEX idx_payments_employee ON payments (employee_id);
-- Частичный B-tree для расписания неотменённых занятий.
CREATE INDEX idx_trainings_upcoming ON trainings (starts_at)
WHERE NOT is_cancelled;
COMMIT;

ANALYZE trainers;
ANALYZE subscriptions;
ANALYZE trainings;
ANALYZE bookings;
ANALYZE payments;

-- Два вида: B-tree и GiST. GiST создан ограничением subscriptions_no_overlap.
SELECT a.amname AS index_type, count(*) AS index_count
FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid
JOIN pg_am a ON a.oid=c.relam
JOIN pg_class t ON t.oid=i.indrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public'
GROUP BY a.amname ORDER BY a.amname;

-- Все внешние ключи должны иметь подходящий полный индекс.
-- В данном проекте внешние ключи одноколоночные.
-- Для bookings.training_id подходит UNIQUE(training_id,client_id).
-- Для subscriptions.client_id подходит первый ключ GiST-индекса EXCLUDE.
SELECT c.conrelid::regclass AS table_name,
       a.attname AS foreign_key,
       EXISTS (
        SELECT 1 FROM pg_index i
        WHERE i.indrelid=c.conrelid AND i.indkey[0]=c.conkey[1]
          AND i.indisvalid AND i.indisready AND i.indpred IS NULL
       ) AS has_index
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=c.conkey[1]
WHERE c.contype='f' AND c.connamespace='public'::regnamespace
ORDER BY c.conrelid::regclass::text,a.attname;

-- Планы на небольшом рабочем наборе. Seq Scan здесь может быть выгоднее.
EXPLAIN (ANALYZE, BUFFERS)
SELECT training_id,title,starts_at FROM trainings
WHERE NOT is_cancelled
  AND starts_at >= CURRENT_DATE
  AND starts_at < CURRENT_DATE + INTERVAL '7 days'
ORDER BY starts_at;

EXPLAIN (ANALYZE, BUFFERS)
SELECT subscription_id,start_date,end_date FROM subscriptions
WHERE client_id=CAST(4 AS bigint) AND daterange(start_date,end_date,'[]') @> CURRENT_DATE;
