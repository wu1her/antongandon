-- Лабораторная работа №2
-- Выполнять по разделам в Query Tool; для опытов с ошибками запускать блоки отдельно.

-- 1. Создание базы и таблицы | База: fitness_labs
-- В подключении к postgres:
CREATE DATABASE fitness_labs;
-- Далее подключение к fitness_labs:
CREATE SCHEMA lab02;

CREATE TABLE lab02.training_catalog (
    training_id   INTEGER,
    title         CHARACTER VARYING(100) NOT NULL,
    price         NUMERIC(8, 2) NOT NULL,
    is_available  BOOLEAN NOT NULL,
    training_date DATE NOT NULL,
    start_time    TIME NOT NULL,
    created_at    TIMESTAMP NOT NULL,
    weekdays      TEXT[],
    details       JSONB,
    description   TEXT,

    CONSTRAINT pk_training_catalog PRIMARY KEY (training_id)
);

-- 2. Заполнение тестовой таблицы | База: fitness_labs
INSERT INTO lab02.training_catalog VALUES
(1,'Кроссфит',500.00,true,'2026-11-10','08:00','2026-11-01 10:00',
 ARRAY['вторник','четверг'],'{"level":"advanced","hall":1}',
 'Силовая тренировка для развития выносливости'),
(2,'Йога',400.00,true,'2026-11-12','19:00','2026-11-01 10:00',
 ARRAY['четверг','суббота'],'{"level":"beginner","hall":2}',
 'Спокойная тренировка гибкости и дыхания'),
(3,'Бокс',650.00,false,'2026-11-11','18:00','2026-11-01 10:00',
 ARRAY['среда','пятница'],'{"level":"advanced","hall":1}',
 'Силовая подготовка и техника ударов'),
(4,'Пилатес',450.00,true,'2026-11-13','12:00','2026-11-01 10:00',
 ARRAY['понедельник','пятница'],'{"level":"beginner","hall":2}',
 'Укрепление мышц и развитие гибкости'),
(5,'Функциональная',550.00,false,'2026-11-14','09:00','2026-11-01 10:00',
 ARRAY['четверг','суббота'],'{"level":"intermediate","hall":3}',
 'Круговая силовая тренировка всего тела');
SELECT training_id,title,price,is_available,training_date,
 weekdays,details FROM lab02.training_catalog ORDER BY training_id;

-- 3. Три выборки по разным критериям | База: fitness_labs
SELECT '1. Доступные' AS criterion, title
FROM lab02.training_catalog WHERE is_available
UNION ALL
SELECT '2. По четвергам', title
FROM lab02.training_catalog WHERE 'четверг' = ANY(weekdays)
UNION ALL
SELECT '3. Начальный уровень', title
FROM lab02.training_catalog WHERE details ->> 'level' = 'beginner'
ORDER BY 1,2;

-- 4. Полнотекстовый поиск | База: fitness_labs
SELECT training_id, title,
 to_tsvector('russian', description) AS document,
 to_tsquery('russian', 'силовая & тренировка') AS search_query
FROM lab02.training_catalog
WHERE to_tsvector('russian', description)
   @@ to_tsquery('russian', 'силовая & тренировка')
ORDER BY training_id;
