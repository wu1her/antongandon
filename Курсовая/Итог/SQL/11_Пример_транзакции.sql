-- Контрольный пример: регистрация, продажа, оплата, занятие, запись.
-- Все действия выполняются менеджером и затем откатываются.
BEGIN;
SET LOCAL TIME ZONE 'Europe/Moscow';
SET LOCAL ROLE gym_manager;
DO $$
DECLARE new_client bigint; new_sale bigint; new_class bigint; sale_price numeric;
BEGIN
 INSERT INTO public.clients(last_name,first_name,birth_date,phone)
 VALUES('Учебный','Клиент','2000-01-01','+79998880002') RETURNING client_id INTO new_client;
 INSERT INTO public.subscriptions(client_id,membership_id,employee_id,start_date)
 VALUES(new_client,4,2,CURRENT_DATE) RETURNING subscription_id,sold_price INTO new_sale,sale_price;
 INSERT INTO public.payments(subscription_id,employee_id,amount)
 VALUES(new_sale,2,sale_price);
 INSERT INTO public.trainings(trainer_id,hall_id,title,starts_at,duration_min,max_capacity)
 VALUES(15,15,'Контрольное занятие',
 (CURRENT_DATE+6+TIME '10:00') AT TIME ZONE 'Europe/Moscow',60,1)
 RETURNING training_id INTO new_class;
 INSERT INTO public.bookings(training_id,client_id) VALUES(new_class,new_client);
 RAISE NOTICE 'Клиент: %, абонемент: %, занятие: %',new_client,new_sale,new_class;
END $$;
SELECT c.last_name,c.first_name,v.subscription_id,v.paid_amount,v.is_paid,b.status
FROM public.clients c JOIN public.v_subscription_balance v USING(client_id)
JOIN public.bookings b USING(client_id) WHERE c.phone='+79998880002';
RESET ROLE;
ROLLBACK;
-- Для реальной операции вместо ROLLBACK используется COMMIT после проверки.
