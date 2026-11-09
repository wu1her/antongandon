-- Исходные таблицы фитнес-клуба. Выполнять в новой пустой базе fitness_labs.

CREATE TABLE public.clients (
    client_id integer NOT NULL,
    full_name text NOT NULL,
    birth_date text NOT NULL,
    phone text NOT NULL,
    email text,
    is_active boolean NOT NULL
);

CREATE TABLE public.memberships (
    membership_id integer NOT NULL,
    name text NOT NULL,
    duration_days integer NOT NULL,
    price integer NOT NULL
);

CREATE TABLE public.payments (
    payment_id integer NOT NULL,
    client_id integer NOT NULL,
    subscription_id integer,
    amount integer NOT NULL,
    payment_date text NOT NULL,
    is_refunded boolean NOT NULL
);

CREATE TABLE public.subscriptions (
    subscription_id integer NOT NULL,
    client_id integer NOT NULL,
    membership_id integer NOT NULL,
    start_date text NOT NULL,
    end_date text NOT NULL,
    is_paid boolean NOT NULL
);

CREATE TABLE public.trainers (
    trainer_id integer NOT NULL,
    full_name text NOT NULL,
    specialization text NOT NULL,
    phone text,
    is_active boolean NOT NULL
);

CREATE TABLE public.trainings (
    training_id integer NOT NULL,
    trainer_id integer NOT NULL,
    title text NOT NULL,
    training_date text NOT NULL,
    start_time text NOT NULL,
    duration_min integer NOT NULL,
    max_capacity integer NOT NULL
);

CREATE TABLE public.visits (
    visit_id integer NOT NULL,
    client_id integer NOT NULL,
    training_id integer NOT NULL,
    visit_date text NOT NULL,
    attended boolean NOT NULL
);

INSERT INTO public.clients (client_id, full_name, birth_date, phone, email, is_active) VALUES
('1', 'Сидоров Павел Петрович', '1995-03-12', '+79001234567', 'sidorov@mail.ru', 't'),
('2', 'Кузнецова Мария Викторовна', '2000-07-25', '+79002345678', 'kuz@mail.ru', 't'),
('3', 'Орлов Дмитрий Сергеевич', '1988-11-05', '+79003456789', 'orlov@mail.ru', 'f');

INSERT INTO public.memberships (membership_id, name, duration_days, price) VALUES
('1', 'Разовый', '1', '500'),
('2', 'Месяц', '30', '4000'),
('3', 'Год', '365', '35000');

INSERT INTO public.payments (payment_id, client_id, subscription_id, amount, payment_date, is_refunded) VALUES
('1', '1', '1', '4000', '2025-01-01', 'f'),
('2', '2', '2', '35000', '2025-01-15', 'f'),
('3', '3', '3', '4000', '2024-06-01', 't');

INSERT INTO public.subscriptions (subscription_id, client_id, membership_id, start_date, end_date, is_paid) VALUES
('1', '1', '2', '2025-01-01', '2025-01-31', 't'),
('2', '2', '3', '2025-01-15', '2026-01-15', 't'),
('3', '3', '2', '2024-06-01', '2024-06-30', 'f');

INSERT INTO public.trainers (trainer_id, full_name, specialization, phone, is_active) VALUES
('1', 'Иванов Иван Иванович', 'Кроссфит', '+79001112233', 't'),
('2', 'Петрова Анна Сергеевна', 'Йога', '+79004445566', 't'),
('3', 'Смирнов Олег Петрович', 'Бокс', '+79007778899', 'f');

INSERT INTO public.trainings (training_id, trainer_id, title, training_date, start_time, duration_min, max_capacity) VALUES
('1', '1', 'Кроссфит утро', '2025-02-01', '08:00', '60', '15'),
('2', '2', 'Йога вечер', '2025-02-01', '19:00', '90', '20'),
('3', '1', 'Кроссфит вечер', '2025-02-03', '18:00', '60', '15');

INSERT INTO public.visits (visit_id, client_id, training_id, visit_date, attended) VALUES
('1', '1', '1', '2025-02-01', 't'),
('2', '2', '2', '2025-02-01', 't'),
('3', '1', '3', '2025-02-03', 'f');

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT pk_clients PRIMARY KEY (client_id);

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT pk_memberships PRIMARY KEY (membership_id);

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT pk_payments PRIMARY KEY (payment_id);

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT pk_subscriptions PRIMARY KEY (subscription_id);

ALTER TABLE ONLY public.trainers
    ADD CONSTRAINT pk_trainers PRIMARY KEY (trainer_id);

ALTER TABLE ONLY public.trainings
    ADD CONSTRAINT pk_trainings PRIMARY KEY (training_id);

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT pk_visits PRIMARY KEY (visit_id);

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_pay_client FOREIGN KEY (client_id) REFERENCES public.clients(client_id);

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_pay_subscription FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(subscription_id);

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_sub_client FOREIGN KEY (client_id) REFERENCES public.clients(client_id);

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_sub_membership FOREIGN KEY (membership_id) REFERENCES public.memberships(membership_id);

ALTER TABLE ONLY public.trainings
    ADD CONSTRAINT fk_tr_trainer FOREIGN KEY (trainer_id) REFERENCES public.trainers(trainer_id);

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT fk_visit_client FOREIGN KEY (client_id) REFERENCES public.clients(client_id);

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT fk_visit_training FOREIGN KEY (training_id) REFERENCES public.trainings(training_id);
