-- Лабораторная работа №5
-- Выполнять по разделам в Query Tool; для опытов с ошибками запускать блоки отдельно.

-- 1. Подзапросы 1–4: AVG, IN, MIN/MAX, NOT IN | База: fitness_labs
SELECT '1. AVG' AS query,name AS result FROM memberships
WHERE price > (SELECT AVG(price) FROM memberships)
UNION ALL
SELECT '2. IN',full_name FROM clients
WHERE client_id IN (SELECT client_id FROM subscriptions WHERE is_paid)
UNION ALL
SELECT '3. MIN/MAX',name FROM memberships
WHERE price IN ((SELECT MIN(price) FROM memberships),(SELECT MAX(price) FROM memberships))
UNION ALL
SELECT '4. NOT IN',full_name FROM clients
WHERE client_id NOT IN (SELECT client_id FROM visits WHERE client_id IS NOT NULL)
ORDER BY 1,2;

-- 2. Подзапросы 5–7: EXISTS, NOT EXISTS, скаляр в SELECT | База: fitness_labs
SELECT '5. EXISTS' AS query,c.full_name AS result FROM clients c
WHERE EXISTS (SELECT 1 FROM payments p WHERE p.client_id=c.client_id AND NOT p.is_refunded)
UNION ALL
SELECT '6. NOT EXISTS',r.full_name FROM trainers r
WHERE NOT EXISTS (SELECT 1 FROM trainings t WHERE t.trainer_id=r.trainer_id)
UNION ALL
SELECT '7. SELECT',c.full_name || ': ' ||
 COALESCE((SELECT SUM(p.amount) FROM payments p
 WHERE p.client_id=c.client_id AND NOT p.is_refunded),0)::text
FROM clients c ORDER BY 1,2;

-- 3. Подзапросы 8–10: FROM, HAVING, вложенность | База: fitness_labs
SELECT '8. FROM' AS query,r.full_name || ': ' || q.cnt AS result
FROM trainers r JOIN (SELECT trainer_id,COUNT(*) AS cnt
 FROM trainings GROUP BY trainer_id) q ON q.trainer_id=r.trainer_id
UNION ALL
SELECT '9. HAVING',c.full_name || ': ' || SUM(p.amount)
FROM clients c JOIN payments p ON p.client_id=c.client_id
WHERE NOT p.is_refunded GROUP BY c.client_id,c.full_name
HAVING SUM(p.amount) > (SELECT AVG(q.total) FROM
 (SELECT SUM(amount) AS total FROM payments WHERE NOT is_refunded GROUP BY client_id) q)
UNION ALL
SELECT '10. Вложенный',full_name FROM clients
WHERE client_id IN (SELECT client_id FROM subscriptions
 WHERE membership_id IN (SELECT membership_id FROM memberships
 WHERE price > (SELECT AVG(price) FROM memberships)))
ORDER BY 1,2;
