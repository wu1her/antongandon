BEGIN;
SET TIME ZONE 'Europe/Moscow';
CREATE VIEW public.v_subscription_balance AS
SELECT s.subscription_id,s.client_id,s.membership_id,m.name AS membership_name,
 s.start_date,s.end_date,s.sold_price,
 COALESCE(sum(p.amount) FILTER(WHERE NOT p.is_refunded),0)::numeric(10,2) AS paid_amount,
 (s.sold_price-COALESCE(sum(p.amount) FILTER(WHERE NOT p.is_refunded),0))::numeric(10,2) AS debt,
 COALESCE(sum(p.amount) FILTER(WHERE NOT p.is_refunded),0)=s.sold_price AS is_paid
FROM public.subscriptions s JOIN public.memberships m USING(membership_id)
LEFT JOIN public.payments p USING(subscription_id)
GROUP BY s.subscription_id,m.name;

CREATE VIEW public.v_training_load AS
SELECT t.training_id,t.title,t.starts_at,t.trainer_id,t.hall_id,h.name AS hall_name,
 t.max_capacity,t.is_cancelled,
 count(b.booking_id) FILTER(WHERE b.status<>'cancelled') AS occupied_places,
 t.max_capacity-count(b.booking_id) FILTER(WHERE b.status<>'cancelled') AS free_places,
 count(b.booking_id) FILTER(WHERE b.status='attended') AS attended_count,
 count(b.booking_id) FILTER(WHERE b.status='missed') AS missed_count,
 count(b.booking_id) FILTER(WHERE b.status='cancelled') AS cancelled_count
FROM public.trainings t JOIN public.halls h USING(hall_id)
LEFT JOIN public.bookings b USING(training_id)
GROUP BY t.training_id,h.name;

-- Это текущая сумма невозвращённых оплат по дате исходного платежа.
-- Дата возврата в принятой модели отсутствует; это не отчёт о движении денег по дате возврата.
CREATE VIEW public.v_daily_revenue AS
SELECT (paid_at AT TIME ZONE 'Europe/Moscow')::date AS payment_day,method,
 count(*) AS payment_count,
 COALESCE(sum(amount) FILTER(WHERE NOT is_refunded),0)::numeric(12,2) AS net_amount,
 COALESCE(sum(amount) FILTER(WHERE is_refunded),0)::numeric(12,2) AS refunded_amount
FROM public.payments
GROUP BY (paid_at AT TIME ZONE 'Europe/Moscow')::date,method;

CREATE VIEW public.v_schedule AS
SELECT l.training_id,l.title,l.starts_at,
 r.last_name||' '||r.first_name AS trainer_name,l.hall_name,l.free_places
FROM public.v_training_load l JOIN public.trainers r USING(trainer_id)
WHERE NOT l.is_cancelled;
COMMIT;
