-- Выполнить в новой пустой базе gym_course (PostgreSQL 17).
BEGIN;
SET TIME ZONE 'Europe/Moscow';
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE specializations (
 specialization_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 name varchar(60) NOT NULL UNIQUE,
 description text
);
CREATE TABLE halls (
 hall_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 name varchar(60) NOT NULL UNIQUE,
 capacity smallint NOT NULL CHECK (capacity > 0),
 description text
);
CREATE TABLE memberships (
 membership_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 name varchar(60) NOT NULL UNIQUE,
 duration_days smallint NOT NULL CHECK (duration_days > 0),
 price numeric(10,2) NOT NULL CHECK (price > 0),
 description text,
 is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE clients (
 client_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 last_name varchar(60) NOT NULL,
 first_name varchar(60) NOT NULL,
 middle_name varchar(60),
 birth_date date NOT NULL CHECK (birth_date >= DATE '1900-01-01'),
 phone varchar(12) NOT NULL UNIQUE CHECK (phone ~ '^\+7[0-9]{10}$'),
 email varchar(150) UNIQUE CHECK (email ~ '^[^@]+@[^@]+\.[^@]+$'),
 registered_on date NOT NULL DEFAULT CURRENT_DATE,
 is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE trainers (
 trainer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 specialization_id bigint NOT NULL REFERENCES specializations ON DELETE RESTRICT,
 last_name varchar(60) NOT NULL,
 first_name varchar(60) NOT NULL,
 middle_name varchar(60),
 phone varchar(12) UNIQUE CHECK (phone ~ '^\+7[0-9]{10}$'),
 hired_on date NOT NULL,
 is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE employees (
 employee_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 last_name varchar(60) NOT NULL,
 first_name varchar(60) NOT NULL,
 middle_name varchar(60),
 position varchar(20) NOT NULL CHECK (position IN ('administrator','manager')),
 phone varchar(12) CHECK (phone ~ '^\+7[0-9]{10}$'),
 hired_on date NOT NULL,
 is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE subscriptions (
 subscription_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 client_id bigint NOT NULL REFERENCES clients ON DELETE RESTRICT,
 membership_id bigint NOT NULL REFERENCES memberships ON DELETE RESTRICT,
 employee_id bigint NOT NULL REFERENCES employees ON DELETE RESTRICT,
 start_date date NOT NULL,
 end_date date NOT NULL CHECK (end_date >= start_date),
 sold_price numeric(10,2) NOT NULL CHECK (sold_price >= 0),
 CONSTRAINT subscriptions_no_overlap EXCLUDE USING gist (
 client_id WITH =, daterange(start_date,end_date,'[]') WITH &&)
);
CREATE TABLE trainings (
 training_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 trainer_id bigint NOT NULL REFERENCES trainers ON DELETE RESTRICT,
 hall_id bigint NOT NULL REFERENCES halls ON DELETE RESTRICT,
 title varchar(100) NOT NULL,
 starts_at timestamptz NOT NULL,
 duration_min smallint NOT NULL CHECK (duration_min BETWEEN 15 AND 240),
 max_capacity smallint NOT NULL CHECK (max_capacity > 0),
 is_cancelled boolean NOT NULL DEFAULT false
);
CREATE TABLE bookings (
 booking_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 training_id bigint NOT NULL REFERENCES trainings ON DELETE RESTRICT,
 client_id bigint NOT NULL REFERENCES clients ON DELETE RESTRICT,
 booked_at timestamptz NOT NULL DEFAULT now(),
 status varchar(10) NOT NULL DEFAULT 'booked'
 CHECK (status IN ('booked','attended','missed','cancelled')),
 UNIQUE (training_id,client_id)
);
CREATE TABLE payments (
 payment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 subscription_id bigint NOT NULL REFERENCES subscriptions ON DELETE RESTRICT,
 employee_id bigint NOT NULL REFERENCES employees ON DELETE RESTRICT,
 amount numeric(10,2) NOT NULL CHECK (amount > 0),
 paid_at timestamptz NOT NULL DEFAULT now(),
 method varchar(10) NOT NULL DEFAULT 'card' CHECK (method IN ('card','cash','transfer')),
 is_refunded boolean NOT NULL DEFAULT false
);
CREATE TABLE audit_log (
 audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 occurred_at timestamptz NOT NULL DEFAULT now(),
 actor text NOT NULL,
 table_name varchar(30) NOT NULL,
 operation varchar(6) NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
 row_id bigint NOT NULL,
 old_data jsonb,
 new_data jsonb
);

-- Журнал заполняется реальными событиями, а не искусственными строками.
CREATE FUNCTION audit_financial_change() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, public AS $$
DECLARE
 before_row jsonb;
 after_row jsonb;
 id_value bigint;
BEGIN
 IF TG_OP <> 'INSERT' THEN before_row := to_jsonb(OLD); END IF;
 IF TG_OP <> 'DELETE' THEN after_row := to_jsonb(NEW); END IF;
 id_value := (COALESCE(after_row,before_row) ->> TG_ARGV[0])::bigint;
 INSERT INTO public.audit_log(actor,table_name,operation,row_id,old_data,new_data)
 VALUES(session_user,TG_TABLE_NAME,TG_OP,id_value,before_row,after_row);
 RETURN NULL;
END;
$$;
CREATE TRIGGER subscriptions_audit
AFTER INSERT OR UPDATE OR DELETE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION audit_financial_change('subscription_id');
CREATE TRIGGER payments_audit
AFTER INSERT OR UPDATE OR DELETE ON payments
FOR EACH ROW EXECUTE FUNCTION audit_financial_change('payment_id');
COMMIT;
-- Полные бизнес-проверки устанавливаются файлом 06, права — файлом 09.
-- Данный файл создаёт базовую структуру и начальный аудит.
