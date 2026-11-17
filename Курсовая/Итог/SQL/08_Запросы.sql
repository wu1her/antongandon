SET TIME ZONE 'Europe/Moscow';
-- 1. Расписание на семь дней: несколько INNER JOIN через представление, сортировка.
SELECT * FROM public.v_schedule
WHERE starts_at>=CURRENT_DATE AND starts_at<CURRENT_DATE+INTERVAL '7 days'
ORDER BY starts_at,training_id;

-- 2. Поиск клиентов по шаблону и сведения о продажах: INNER JOIN.
SELECT c.client_id,c.last_name,c.first_name,s.subscription_id,s.membership_name,s.debt
FROM public.clients c JOIN public.v_subscription_balance s USING(client_id)
WHERE c.last_name ILIKE 'С%' ORDER BY c.last_name,s.start_date DESC;

-- 3. Клиенты без записей: LEFT JOIN и проверка NULL.
SELECT c.client_id,c.last_name,c.first_name
FROM public.clients c LEFT JOIN public.bookings b USING(client_id)
WHERE b.booking_id IS NULL ORDER BY c.client_id;

-- 4. Должники: агрегирование выполнено представлением, фильтр и упорядочение.
SELECT subscription_id,client_id,membership_name,sold_price,paid_amount,debt
FROM public.v_subscription_balance WHERE debt>0 ORDER BY debt DESC,subscription_id;

-- 5. Популярность тарифов: GROUP BY, COUNT, SUM, HAVING.
SELECT m.name,count(s.subscription_id) AS sales_count,
 COALESCE(sum(s.sold_price),0) AS sales_total
FROM public.memberships m LEFT JOIN public.subscriptions s USING(membership_id)
GROUP BY m.membership_id,m.name HAVING count(s.subscription_id)>0
ORDER BY sales_count DESC,sales_total DESC,m.name;

-- 6. Загрузка тренеров: LEFT JOIN, агрегаты, COALESCE.
SELECT r.trainer_id,r.last_name,r.first_name,count(l.training_id) AS classes,
 COALESCE(sum(l.attended_count),0) AS visits,
 COALESCE(sum(l.occupied_places),0) AS reservations
FROM public.trainers r LEFT JOIN public.v_training_load l USING(trainer_id)
GROUP BY r.trainer_id ORDER BY visits DESC,r.trainer_id;

-- 7. Абонементы, заканчивающиеся за неделю: BETWEEN и подзапрос.
SELECT s.subscription_id,c.last_name,c.first_name,s.end_date
FROM public.subscriptions s JOIN public.clients c USING(client_id)
WHERE s.end_date BETWEEN CURRENT_DATE AND CURRENT_DATE+7
AND EXISTS(SELECT 1 FROM public.v_subscription_balance v
 WHERE v.subscription_id=s.subscription_id AND v.is_paid)
ORDER BY s.end_date,c.last_name;

-- 8. Тарифы с ценой выше средней: скалярный подзапрос.
SELECT name,price,duration_days FROM public.memberships
WHERE is_active AND price>(SELECT avg(price) FROM public.memberships WHERE is_active)
ORDER BY price DESC,name;

-- 9. Финансовая сводка по месяцу и способу: GROUP BY, date_trunc, SUM.
SELECT date_trunc('month',payment_day)::date AS month,method,
 sum(net_amount) AS net_amount,sum(refunded_amount) AS refunded_amount
FROM public.v_daily_revenue GROUP BY date_trunc('month',payment_day),method
ORDER BY month DESC,method;

-- 10. История клиента: четыре связанных отношения и LEFT JOIN.
SELECT c.client_id,t.title,t.starts_at,h.name AS hall,r.last_name AS trainer,b.status
FROM public.clients c JOIN public.bookings b USING(client_id)
JOIN public.trainings t USING(training_id) JOIN public.halls h USING(hall_id)
LEFT JOIN public.trainers r USING(trainer_id)
WHERE c.client_id=4 ORDER BY t.starts_at DESC;

-- 11. Продажи сотрудника в сравнении со средним числом продаж сотрудников.
WITH sales AS (
 SELECT e.employee_id,e.last_name,count(s.subscription_id) AS n
 FROM public.employees e LEFT JOIN public.subscriptions s USING(employee_id)
 GROUP BY e.employee_id)
SELECT employee_id,last_name,n FROM sales
WHERE n>(SELECT avg(n) FROM sales) ORDER BY n DESC,employee_id;

-- 12. Сопоставление дней занятий и платежей: FULL OUTER JOIN, CTE, COALESCE.
-- Независимые показатели по календарному дню; это не связь платежа с конкретным занятием.
WITH classes AS (
 SELECT (starts_at AT TIME ZONE 'Europe/Moscow')::date AS day,count(*) AS n
 FROM public.trainings WHERE NOT is_cancelled GROUP BY 1),
receipts AS (
 SELECT payment_day AS day,sum(net_amount) AS amount
 FROM public.v_daily_revenue GROUP BY payment_day)
SELECT COALESCE(c.day,r.day) AS day,COALESCE(c.n,0) AS classes,
 COALESCE(r.amount,0) AS receipts
FROM classes c FULL OUTER JOIN receipts r ON c.day=r.day ORDER BY day;
