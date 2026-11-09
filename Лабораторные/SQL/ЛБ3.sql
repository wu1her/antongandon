-- Лабораторная работа №3
-- Выполнять по разделам в Query Tool; для опытов с ошибками запускать блоки отдельно.

-- 1. Создание связанных таблиц | База: fitness_labs
CREATE SCHEMA lab03;
CREATE TABLE lab03.trainers (
 trainer_id integer PRIMARY KEY, full_name text NOT NULL);
CREATE TABLE lab03.trainings (
 training_id integer PRIMARY KEY,
 trainer_id integer REFERENCES lab03.trainers(trainer_id),
 title text NOT NULL);
INSERT INTO lab03.trainers
SELECT trainer_id,full_name FROM public.trainers;
INSERT INTO lab03.trainings
SELECT training_id,trainer_id,title FROM public.trainings;
SELECT t.training_id,t.title,r.full_name
FROM lab03.trainings t JOIN lab03.trainers r USING(trainer_id)
ORDER BY t.training_id;

-- 2. Проверка защиты зависимой таблицы | База: fitness_labs
DROP TABLE lab03.trainers;

-- 3. Удаление с CASCADE и восстановление связи | База: fitness_labs
DROP TABLE lab03.trainers CASCADE;
DROP TABLE IF EXISTS lab03.trainers;
CREATE TABLE lab03.trainers (
 trainer_id integer PRIMARY KEY, full_name text NOT NULL);
INSERT INTO lab03.trainers
SELECT trainer_id,full_name FROM public.trainers;
ALTER TABLE lab03.trainings ADD CONSTRAINT fk_trainer
 FOREIGN KEY(trainer_id) REFERENCES lab03.trainers(trainer_id);
SELECT count(*) AS trainings_preserved FROM lab03.trainings;

-- 4. Ошибка NOT NULL при добавлении столбца | База: fitness_labs
ALTER TABLE lab03.trainings ADD COLUMN duration integer NOT NULL;

-- 5. Модификация столбцов, типов и имени таблицы | База: fitness_labs
ALTER TABLE lab03.trainings ADD COLUMN duration integer;
UPDATE lab03.trainings SET duration=60;
ALTER TABLE lab03.trainings ALTER COLUMN duration SET NOT NULL;
ALTER TABLE lab03.trainings ADD COLUMN city text DEFAULT 'Казань';
ALTER TABLE lab03.trainings DROP COLUMN city;
ALTER TABLE lab03.trainings ADD COLUMN number integer DEFAULT 500;
ALTER TABLE lab03.trainings RENAME COLUMN number TO price;
ALTER TABLE lab03.trainings ALTER COLUMN price TYPE numeric(8,2);
ALTER TABLE lab03.trainings ADD COLUMN date_text text DEFAULT '2026-11-10';
ALTER TABLE lab03.trainings ALTER COLUMN date_text DROP DEFAULT;
ALTER TABLE lab03.trainings ALTER COLUMN date_text TYPE date USING date_text::date;
ALTER TABLE lab03.trainings RENAME COLUMN date_text TO training_date;
ALTER TABLE lab03.trainings RENAME TO sessions;
ALTER TABLE lab03.sessions ADD CONSTRAINT positive_price CHECK(price>0);
INSERT INTO lab03.sessions(training_id,trainer_id,title,duration,training_date)
VALUES(4,2,'Йога тест',90,'2026-11-12');
SELECT training_id,title,duration,price,training_date FROM lab03.sessions
ORDER BY training_id;

-- 6. Проверка CHECK и удаление учебного объекта | База: fitness_labs
INSERT INTO lab03.sessions(training_id,title,duration,price)
VALUES(5,'Неверная цена',60,-1);

-- 7. Снятие ограничений и удаление временной таблицы | База: fitness_labs
ALTER TABLE lab03.sessions DROP CONSTRAINT positive_price;
ALTER TABLE lab03.sessions ALTER COLUMN price DROP DEFAULT;
CREATE TABLE lab03.temp_table(id integer);
DROP TABLE lab03.temp_table;
SELECT table_name,column_name,data_type,is_nullable,column_default
FROM information_schema.columns WHERE table_schema='lab03'
AND table_name='sessions' ORDER BY ordinal_position;
