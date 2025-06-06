/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: 
 * Дата: 
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
 WITH all_duser AS(
SELECT COUNT(*) AS all_user, --общее количество игроков, зарегистрированных в игре
         (SELECT COUNT(payer) AS quan_payer FROM fantasy.users WHERE payer = 1) AS payer_per_users --количество платящих игроков
FROM fantasy.users)
SELECT *,
       ROUND(payer_per_users / all_user :: NUMERIC,2)  AS share_payer --доля платящих игроков от общего количества пользователей, зарегистрированных в игре
FROM all_duser;
  


-- 1.2. Доля платящих пользователей в разрезе расы персонажа: (попробовать сделать через сте в where)
-- Напишите ваш запрос здесь
   WITH all_duser AS(
SELECT COUNT(DISTINCT id) AS all_user,                 --общее количество зарегистрированных игроков
        race,                                          --раса персонажа
         SUM(payer) AS payer_per_users                   
FROM fantasy.users AS u
LEFT JOIN fantasy.race AS r ON r.race_id = u.race_id
GROUP BY race
)
SELECT *,
       ROUND(payer_per_users/ all_user :: NUMERIC, 2)  AS share_payer  --доля платящих игроков от общего количества пользователей, зарегистрированных в игре в разрезе каждой расы персонажа
FROM all_duser
ORDER BY share_payer;



-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT
       COUNT(DISTINCT transaction_id) AS total_transaction,    --общее количество покупок
       SUM(amount) AS sum_amount,                              --суммарная стоимость всех покупок
       MIN(amount) AS min_amount,                              --минимальная стоимость покупки
       MAX(amount) AS max_amount,                              --максимальная стоимость покупки
       AVG(amount) AS avg_amount,                              --среднее значение стоимости покупки
       STDDEV(amount) AS so_amount,                            --стандартное отклонение стоимости покупки
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount)  AS mediana -- медиана стоимости покупки
FROM fantasy.events


-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
WITH all_transaction AS(
SELECT COUNT(transaction_id) AS all_p,
        (SELECT COUNT(transaction_id) FROM fantasy.events WHERE amount = '0') AS zero_p
FROM fantasy.events)
SELECT *,
       zero_p / all_p :: NUMERIC AS share_p
FROM all_transaction;



-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
WITH all_things AS(
SELECT u.payer AS payer, 
       u.id AS id,
       COUNT(DISTINCT transaction_id) AS all_buy, --общее кол-во покупок 
       SUM(amount) AS petals_paradise             --общее кол-во покупок по райским лепесткам 
FROM fantasy.users u 
LEFT JOIN fantasy.events e ON u.id = e.id
WHERE amount != 0
GROUP BY u.payer, u.id)
SELECT payer,
       COUNT(DISTINCT id) AS all_payer,           -- общее кол-во игроков 
       AVG(all_buy) :: NUMERIC AS avg_buy,        -- ср. кол-во всех покупок 
       AVG(petals_paradise):: NUMERIC AS avg_pp   -- ср. кол-во покупок по р/л
FROM all_things
GROUP BY payer;


-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
WITH CTE1 AS (
SELECT game_items,
      COUNT(transaction_id) AS buy_per_items,                       -- кол-во продаж по каждому элементу 
      (SELECT COUNT(transaction_id) FROM fantasy.events) AS all_buy, -- общее кол-во продаж  
      ROUND(COUNT(DISTINCT id)::numeric/(SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount > 1),2) AS share_players -- доля игроков 
FROM fantasy.items 
INNER JOIN fantasy.events AS e USING (item_code)
WHERE amount != 0
GROUP BY game_items)
SELECT game_items,
       buy_per_items,
       ROUND(buy_per_items * 100 / all_buy :: NUMERIC, 2) AS share_buy, -- доля продаж 
       share_players
FROM CTE1 
GROUP BY game_items, buy_per_items, all_buy, share_players
ORDER BY buy_per_items DESC;




-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH registration_players AS (
SELECT race, 
       COUNT( DISTINCT u.id) AS all_registration_player,  --все зарегестрированные игроки 
        COUNT(DISTINCT e.id) AS ingame_players          -- игроки, которые совершают внутриигровые покупки 
FROM fantasy.race AS r
LEFT JOIN fantasy.users AS u USING (race_id)
LEFT JOIN fantasy.events AS e ON e.id = u.id  
GROUP BY race),
agregation_function AS (
SELECT r.race,
       COUNT(transaction_id)/COUNT(DISTINCT e.id) AS middle_per_player, -- среднее кол-во покупок на одного игрока 
       ROUND(SUM(amount) :: NUMERIC / COUNT(amount),2) AS middle_per_buy,        --средняя стоим. одной покупки на одного игрока 
       ROUND(SUM(amount) :: NUMERIC / COUNT(DISTINCT e.id),2) AS middle_sum_buy  -- средняя суммарная стом. всех покупок на одного игрока 
FROM fantasy.race r 
INNER JOIN fantasy.users AS u USING(race_id)
INNER JOIN fantasy.events AS e USING(id)
WHERE amount > 0
GROUP BY race),
shayerplayers AS (
SELECT race,
       COUNT(DISTINCT id) AS for_formul 
FROM fantasy.users u 
LEFT JOIN fantasy.race r USING (race_id)
LEFT JOIN fantasy.events e USING (id)
WHERE payer = 1 AND amount > 0 
GROUP BY race 
) 
 SELECT race,
        all_registration_player,
        ingame_players,
        ROUND (ingame_players / all_registration_player :: NUMERIC, 2) AS shayer_ingame_players, --доля внутриигровой покупки
        ROUND(for_formul :: NUMERIC / ingame_players, 2) AS shayer_players,  -- доля платящих игроков от количества игроков, которые совершили покупки
        middle_per_player,
        middle_per_buy,
        middle_sum_buy
 FROM registration_players
 JOIN agregation_function USING (race)
 JOIN shayerplayers USING (race);
