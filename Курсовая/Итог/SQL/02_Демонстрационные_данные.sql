-- Демонстрационные данные: не менее 15 строк в каждом отношении.

-- Первые три клиента, тренера, тарифа, абонемента и платежа сохранены из дампа.

-- Старые visits не переносятся: часть записей нарушает новые правила.

BEGIN;

SET TIME ZONE 'Europe/Moscow';

INSERT INTO specializations (specialization_id, name, description) OVERRIDING SYSTEM VALUE VALUES
(1, 'Кроссфит', 'Направление занятий: кроссфит'),
(2, 'Йога', 'Направление занятий: йога'),
(3, 'Бокс', 'Направление занятий: бокс'),
(4, 'Силовая подготовка', 'Направление занятий: силовая подготовка'),
(5, 'Пилатес', 'Направление занятий: пилатес'),
(6, 'Стретчинг', 'Направление занятий: стретчинг'),
(7, 'Аэробика', 'Направление занятий: аэробика'),
(8, 'Функциональный тренинг', 'Направление занятий: функциональный тренинг'),
(9, 'Спиннинг', 'Направление занятий: спиннинг'),
(10, 'Танцевальный фитнес', 'Направление занятий: танцевальный фитнес'),
(11, 'Единоборства', 'Направление занятий: единоборства'),
(12, 'ОФП', 'Направление занятий: офп'),
(13, 'Тренировки для начинающих', 'Направление занятий: тренировки для начинающих'),
(14, 'Персональный тренинг', 'Направление занятий: персональный тренинг'),
(15, 'Реабилитационный фитнес', 'Направление занятий: реабилитационный фитнес');

INSERT INTO halls (hall_id, name, capacity, description) OVERRIDING SYSTEM VALUE VALUES
(1, 'Силовой зал А', 25, 'Учебный зал фитнес-центра'),
(2, 'Зал йоги', 30, 'Учебный зал фитнес-центра'),
(3, 'Зал бокса', 20, 'Учебный зал фитнес-центра'),
(4, 'Силовой зал Б', 25, 'Учебный зал фитнес-центра'),
(5, 'Зал пилатеса', 30, 'Учебный зал фитнес-центра'),
(6, 'Зал стретчинга', 20, 'Учебный зал фитнес-центра'),
(7, 'Зал аэробики', 25, 'Учебный зал фитнес-центра'),
(8, 'Функциональный зал', 30, 'Учебный зал фитнес-центра'),
(9, 'Спиннинг-студия', 20, 'Учебный зал фитнес-центра'),
(10, 'Танцевальный зал', 25, 'Учебный зал фитнес-центра'),
(11, 'Зал единоборств', 30, 'Учебный зал фитнес-центра'),
(12, 'Зал ОФП', 20, 'Учебный зал фитнес-центра'),
(13, 'Зал начальной подготовки', 25, 'Учебный зал фитнес-центра'),
(14, 'Зал персональных занятий', 30, 'Учебный зал фитнес-центра'),
(15, 'Зал восстановительного фитнеса', 20, 'Учебный зал фитнес-центра');

INSERT INTO memberships (membership_id, name, duration_days, price, description, is_active) OVERRIDING SYSTEM VALUE VALUES
(1, 'Разовый', 1, 500, 'Тариф исходной базы', true),
(2, 'Месяц', 30, 4000, 'Тариф исходной базы', true),
(3, 'Год', 365, 35000, 'Тариф исходной базы', true),
(4, 'Неделя', 7, 1500, 'Учебный тариф; стоимость фиксируется при продаже', true),
(5, 'Месяц дневной', 30, 3000, 'Учебный тариф; стоимость фиксируется при продаже', true),
(6, 'Месяц безлимитный', 30, 5000, 'Учебный тариф; стоимость фиксируется при продаже', true),
(7, 'Три месяца', 90, 11000, 'Учебный тариф; стоимость фиксируется при продаже', true),
(8, 'Полгода', 180, 20000, 'Учебный тариф; стоимость фиксируется при продаже', true),
(9, 'Год премиум', 365, 50000, 'Учебный тариф; стоимость фиксируется при продаже', true),
(10, 'Студенческий', 30, 3200, 'Учебный тариф; стоимость фиксируется при продаже', true),
(11, 'Семейный', 30, 8000, 'Учебный тариф; стоимость фиксируется при продаже', true),
(12, 'Персональный', 30, 7000, 'Учебный тариф; стоимость фиксируется при продаже', true),
(13, 'Выходного дня', 30, 2500, 'Учебный тариф; стоимость фиксируется при продаже', true),
(14, 'Утренний', 30, 2800, 'Учебный тариф; стоимость фиксируется при продаже', true),
(15, 'Групповой', 30, 4500, 'Учебный тариф; стоимость фиксируется при продаже', true);

INSERT INTO clients (client_id, last_name, first_name, middle_name, birth_date, phone, email, registered_on, is_active) OVERRIDING SYSTEM VALUE VALUES
(1, 'Сидоров', 'Павел', 'Петрович', '1995-03-12', '+79001234567', 'sidorov@mail.ru', CURRENT_DATE, true),
(2, 'Кузнецова', 'Мария', 'Викторовна', '2000-07-25', '+79002345678', 'kuz@mail.ru', CURRENT_DATE, true),
(3, 'Орлов', 'Дмитрий', 'Сергеевич', '1988-11-05', '+79003456789', 'orlov@mail.ru', CURRENT_DATE, false),
(4, 'Смирнова', 'Анна', 'Игоревна', '1994-05-12', '+79110000004', 'client4@example.test', CURRENT_DATE, true),
(5, 'Васильев', 'Никита', 'Олегович', '1995-05-12', '+79110000005', 'client5@example.test', CURRENT_DATE, true),
(6, 'Морозова', 'Елена', 'Андреевна', '1996-05-12', '+79110000006', 'client6@example.test', CURRENT_DATE, true),
(7, 'Фёдоров', 'Алексей', 'Павлович', '1997-05-12', '+79110000007', 'client7@example.test', CURRENT_DATE, true),
(8, 'Волкова', 'Ольга', 'Сергеевна', '1998-05-12', '+79110000008', 'client8@example.test', CURRENT_DATE, true),
(9, 'Алексеев', 'Роман', 'Ильич', '1999-05-12', '+79110000009', 'client9@example.test', CURRENT_DATE, true),
(10, 'Соколова', 'Ирина', 'Петровна', '2000-05-12', '+79110000010', 'client10@example.test', CURRENT_DATE, true),
(11, 'Лебедев', 'Михаил', 'Денисович', '2001-05-12', '+79110000011', 'client11@example.test', CURRENT_DATE, true),
(12, 'Новикова', 'Дарья', 'Викторовна', '2002-05-12', '+79110000012', 'client12@example.test', CURRENT_DATE, true),
(13, 'Егоров', 'Кирилл', 'Артёмович', '2003-05-12', '+79110000013', 'client13@example.test', CURRENT_DATE, true),
(14, 'Козлова', 'Наталья', 'Ивановна', '2004-05-12', '+79110000014', 'client14@example.test', CURRENT_DATE, true),
(15, 'Павлов', 'Денис', 'Максимович', '2005-05-12', '+79110000015', 'client15@example.test', CURRENT_DATE, true);

INSERT INTO trainers (trainer_id, specialization_id, last_name, first_name, middle_name, phone, hired_on, is_active) OVERRIDING SYSTEM VALUE VALUES
(1, 1, 'Иванов', 'Иван', 'Иванович', '+79001112233', '2020-01-10', true),
(2, 2, 'Петрова', 'Анна', 'Сергеевна', '+79004445566', '2020-01-10', true),
(3, 3, 'Смирнов', 'Олег', 'Петрович', '+79007778899', '2020-01-10', false),
(4, 4, 'Смирнова', 'Анна', 'Игоревна', '+79220000004', '2022-09-01', true),
(5, 5, 'Васильев', 'Никита', 'Олегович', '+79220000005', '2022-09-01', true),
(6, 6, 'Морозова', 'Елена', 'Андреевна', '+79220000006', '2022-09-01', true),
(7, 7, 'Фёдоров', 'Алексей', 'Павлович', '+79220000007', '2022-09-01', true),
(8, 8, 'Волкова', 'Ольга', 'Сергеевна', '+79220000008', '2022-09-01', true),
(9, 9, 'Алексеев', 'Роман', 'Ильич', '+79220000009', '2022-09-01', true),
(10, 10, 'Соколова', 'Ирина', 'Петровна', '+79220000010', '2022-09-01', true),
(11, 11, 'Лебедев', 'Михаил', 'Денисович', '+79220000011', '2022-09-01', true),
(12, 12, 'Новикова', 'Дарья', 'Викторовна', '+79220000012', '2022-09-01', true),
(13, 13, 'Егоров', 'Кирилл', 'Артёмович', '+79220000013', '2022-09-01', true),
(14, 14, 'Козлова', 'Наталья', 'Ивановна', '+79220000014', '2022-09-01', true),
(15, 15, 'Павлов', 'Денис', 'Максимович', '+79220000015', '2022-09-01', true);

INSERT INTO employees (employee_id, last_name, first_name, middle_name, position, phone, hired_on, is_active) OVERRIDING SYSTEM VALUE VALUES
(1, 'Импорт', 'Исходных', 'Данных', 'administrator', NULL, '2020-01-01', false),
(2, 'Смирнова', 'Анна', 'Игоревна', 'administrator', '+79330000002', '2022-01-10', true),
(3, 'Васильев', 'Никита', 'Олегович', 'manager', '+79330000003', '2022-01-10', true),
(4, 'Морозова', 'Елена', 'Андреевна', 'administrator', '+79330000004', '2022-01-10', true),
(5, 'Фёдоров', 'Алексей', 'Павлович', 'manager', '+79330000005', '2022-01-10', true),
(6, 'Волкова', 'Ольга', 'Сергеевна', 'administrator', '+79330000006', '2022-01-10', true),
(7, 'Алексеев', 'Роман', 'Ильич', 'manager', '+79330000007', '2022-01-10', true),
(8, 'Соколова', 'Ирина', 'Петровна', 'administrator', '+79330000008', '2022-01-10', true),
(9, 'Лебедев', 'Михаил', 'Денисович', 'manager', '+79330000009', '2022-01-10', true),
(10, 'Новикова', 'Дарья', 'Викторовна', 'administrator', '+79330000010', '2022-01-10', true),
(11, 'Егоров', 'Кирилл', 'Артёмович', 'manager', '+79330000011', '2022-01-10', true),
(12, 'Козлова', 'Наталья', 'Ивановна', 'administrator', '+79330000012', '2022-01-10', true),
(13, 'Павлов', 'Денис', 'Максимович', 'manager', '+79330000013', '2022-01-10', true),
(14, 'Зайцев', 'Артём', 'Борисович', 'administrator', '+79330000014', '2022-01-10', true),
(15, 'Макарова', 'Софья', 'Дмитриевна', 'manager', '+79330000015', '2022-01-10', true);

INSERT INTO subscriptions (subscription_id, client_id, membership_id, employee_id, start_date, end_date, sold_price) OVERRIDING SYSTEM VALUE VALUES
(1, 1, 2, 1, '2025-01-01', '2025-01-31', 4000),
(2, 2, 3, 1, '2025-01-15', '2026-01-15', 35000),
(3, 3, 2, 1, '2024-06-01', '2024-06-30', 4000),
(4, 4, 4, 6, CURRENT_DATE - 1, CURRENT_DATE + 5, 1500),
(5, 5, 5, 7, CURRENT_DATE - 1, CURRENT_DATE + 28, 3000),
(6, 6, 6, 8, CURRENT_DATE - 1, CURRENT_DATE + 28, 5000),
(7, 7, 7, 9, CURRENT_DATE - 1, CURRENT_DATE + 88, 11000),
(8, 8, 8, 10, CURRENT_DATE - 1, CURRENT_DATE + 178, 20000),
(9, 9, 9, 11, CURRENT_DATE - 1, CURRENT_DATE + 363, 50000),
(10, 10, 10, 12, CURRENT_DATE - 1, CURRENT_DATE + 28, 3200),
(11, 11, 11, 13, CURRENT_DATE - 1, CURRENT_DATE + 28, 8000),
(12, 12, 12, 14, CURRENT_DATE - 1, CURRENT_DATE + 28, 7000),
(13, 13, 13, 15, CURRENT_DATE - 1, CURRENT_DATE + 28, 2500),
(14, 14, 14, 2, CURRENT_DATE - 1, CURRENT_DATE + 28, 2800),
(15, 15, 15, 3, CURRENT_DATE - 1, CURRENT_DATE + 28, 4500);

INSERT INTO payments (payment_id, subscription_id, employee_id, amount, paid_at, method, is_refunded) OVERRIDING SYSTEM VALUE VALUES
(1, 1, 1, 4000, '2025-01-01 12:00:00+03', 'card', false),
(2, 2, 1, 35000, '2025-01-15 12:00:00+03', 'card', false),
(3, 3, 1, 4000, '2024-06-01 12:00:00+03', 'card', true),
(4, 4, 6, 1500, now() - interval '1 day', 'cash', false),
(5, 5, 7, 3000, now() - interval '1 day', 'transfer', false),
(6, 6, 8, 5000, now() - interval '1 day', 'card', false),
(7, 7, 9, 11000, now() - interval '1 day', 'cash', false),
(8, 8, 10, 20000, now() - interval '1 day', 'transfer', false),
(9, 9, 11, 50000, now() - interval '1 day', 'card', false),
(10, 10, 12, 3200, now() - interval '1 day', 'cash', false),
(11, 11, 13, 8000, now() - interval '1 day', 'transfer', false),
(12, 12, 14, 7000, now() - interval '1 day', 'card', false),
(13, 13, 15, 2500, now() - interval '1 day', 'cash', false),
(14, 14, 2, 2800, now() - interval '1 day', 'transfer', false),
(15, 15, 3, 4500, now() - interval '1 day', 'card', false);

INSERT INTO trainings (training_id, trainer_id, hall_id, title, starts_at, duration_min, max_capacity, is_cancelled) OVERRIDING SYSTEM VALUE VALUES
(1, 1, 1, 'Кроссфит утро', '2025-02-01 08:00:00+03', 60, 15, false),
(2, 2, 2, 'Йога вечер', '2025-02-01 19:00:00+03', 90, 20, false),
(3, 1, 1, 'Кроссфит вечер', '2025-02-03 18:00:00+03', 60, 15, false),
(4, 4, 4, 'Силовая подготовка — группа', (CURRENT_DATE + 1 + TIME '08:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(5, 5, 5, 'Пилатес — группа', (CURRENT_DATE + 2 + TIME '10:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(6, 6, 6, 'Стретчинг — группа', (CURRENT_DATE + 3 + TIME '12:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(7, 7, 7, 'Аэробика — группа', (CURRENT_DATE + 4 + TIME '14:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(8, 8, 8, 'Функциональный тренинг — группа', (CURRENT_DATE + 5 + TIME '08:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(9, 9, 9, 'Спиннинг — группа', (CURRENT_DATE + 1 + TIME '10:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(10, 10, 10, 'Танцевальный фитнес — группа', (CURRENT_DATE + 2 + TIME '12:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(11, 11, 11, 'Единоборства — группа', (CURRENT_DATE + 3 + TIME '14:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(12, 12, 12, 'ОФП — группа', (CURRENT_DATE + 4 + TIME '08:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(13, 13, 13, 'Тренировки для начинающих — группа', (CURRENT_DATE + 5 + TIME '10:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(14, 14, 14, 'Персональный тренинг — группа', (CURRENT_DATE + 1 + TIME '12:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false),
(15, 15, 15, 'Реабилитационный фитнес — группа', (CURRENT_DATE + 2 + TIME '14:00') AT TIME ZONE 'Europe/Moscow', 60, 15, false);

INSERT INTO bookings (booking_id, training_id, client_id, booked_at, status) OVERRIDING SYSTEM VALUE VALUES
(1, 4, 4, now(), 'booked'),
(2, 5, 5, now(), 'booked'),
(3, 6, 6, now(), 'booked'),
(4, 7, 7, now(), 'booked'),
(5, 8, 8, now(), 'booked'),
(6, 9, 9, now(), 'booked'),
(7, 10, 10, now(), 'booked'),
(8, 11, 11, now(), 'booked'),
(9, 12, 12, now(), 'booked'),
(10, 13, 13, now(), 'booked'),
(11, 14, 14, now(), 'booked'),
(12, 15, 15, now(), 'booked'),
(13, 5, 4, now(), 'booked'),
(14, 6, 5, now(), 'booked'),
(15, 7, 6, now(), 'booked'),
(16, 2, 2, '2025-02-01 18:00:00+03', 'attended');

SELECT setval(pg_get_serial_sequence('specializations','specialization_id'),(SELECT max(specialization_id) FROM specializations),true);

SELECT setval(pg_get_serial_sequence('halls','hall_id'),(SELECT max(hall_id) FROM halls),true);

SELECT setval(pg_get_serial_sequence('memberships','membership_id'),(SELECT max(membership_id) FROM memberships),true);

SELECT setval(pg_get_serial_sequence('clients','client_id'),(SELECT max(client_id) FROM clients),true);

SELECT setval(pg_get_serial_sequence('trainers','trainer_id'),(SELECT max(trainer_id) FROM trainers),true);

SELECT setval(pg_get_serial_sequence('employees','employee_id'),(SELECT max(employee_id) FROM employees),true);

SELECT setval(pg_get_serial_sequence('subscriptions','subscription_id'),(SELECT max(subscription_id) FROM subscriptions),true);

SELECT setval(pg_get_serial_sequence('payments','payment_id'),(SELECT max(payment_id) FROM payments),true);

SELECT setval(pg_get_serial_sequence('trainings','training_id'),(SELECT max(training_id) FROM trainings),true);

SELECT setval(pg_get_serial_sequence('bookings','booking_id'),(SELECT max(booking_id) FROM bookings),true);

COMMIT;
