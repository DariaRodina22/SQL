/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Родина Дарья Александровна 
 * Дата:
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

-- Напишите ваш запрос здесь
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
cte1 as(
    SELECT id,
    case
    	when city = 'Санкт-Петербург' then 'Санкт-Петербург'
	else 'ЛенОбл'
end as region,                                      --категории объявлений по городам 
case 
	when days_exposition <= 30 then 'месяц'
	when days_exposition between 31 and 90 then 'квартал'
	when days_exposition between 91 and 180 then 'полгода'
	else 'больше полугода'
end as activity_segment,                           --категории активных объявлений по дням 
last_price / total_area as one_m,  --стоим одного кв метра 
total_area,
rooms, 
balcony,
floor
from real_estate.advertisement as a  
join real_estate.flats as f using(id)
join real_estate.city as s using(city_id)
join real_estate."type" as t using(type_id)
WHERE id IN (SELECT * FROM filtered_id)
      and days_exposition is not NULL
      and type = 'город'
group by id, total_area, city, rooms, balcony, floor, is_apartment)
select 
region,
activity_segment,
round((AVG(one_m) :: numeric), 2) as avg_one_m,            -- ср стоим одного кв метра 
round((AVG(total_area) :: numeric), 2) as avg_total_area,   --ср площадь
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) as mediana_rooms,   --медиана кол-ва комнат
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony)  as mediana_balconies,   --медиана кол-ва балконов
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor)  as mediana_floor,  --медиана этажности 
count(id)
from cte1
group by region, activity_segment;



-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

-- Напишите ваш запрос здесь


WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
cte1 as(
SELECT 
      count(id) as ad,                                                                 -- опубликованные публикации 
      EXTRACT(MONTH FROM first_day_exposition) as months                               --месяц подачи объявления 
from real_estate.advertisement as a
join real_estate.flats as f using(id)
join real_estate.city as c using(city_id)
join real_estate."type" as t using(type_id)
where id IN (SELECT * FROM filtered_id) 
      and first_day_exposition >= '2015-01-01' and first_day_exposition <= '2018-12-31'
      and type = 'город'
group by months),
cte2 as (                                     
select EXTRACT(MONTH from first_day_exposition + days_exposition :: int) as months,   --месяц снятия объявления
       count(id) as removal_ad,                                                         --снятые публикации 
       round((AVG(last_price / total_area) :: numeric), 2) as avg_one_m,                --ср стоим кв метра 
       round((avg(total_area):: numeric), 0) as avg_total_area                          -- ср площадь 
from real_estate.advertisement as a
join real_estate.flats as f using(id)
join real_estate.city as c using(city_id)
join real_estate."type" as t using(type_id)
where id IN (SELECT * FROM filtered_id) 
      and first_day_exposition >= '2015-01-01' and first_day_exposition <= '2018-12-31'
      and type = 'город'
      and days_exposition is not null
group by months)
select *,
round((removal_ad :: numeric / ad), 2) as share                                            --доля
from cte1 as c1
join cte2 as c2 using(months)



-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

-- Напишите ваш запрос здесь

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
    cte1 as(
SELECT c.city as city,
       round((avg(days_exposition) :: numeric), 1) as avg_days_exposition,            --ср продолжительность нахождения объявления на сайте (в днях)
       count (first_day_exposition) as ad,                                            --опубликованные публикации 
       count (first_day_exposition + days_exposition :: int) as removal_ad,           --снятые публикации 
       round ((avg(last_price / total_area) :: numeric), 2) as avg_one_m,             --ср стоим кв метра 
       round((avg (total_area)::numeric), 2) as avg_total_area,                       -- ср площадь
       count(a.id) as count_id
from real_estate.advertisement as a
join real_estate.flats as f using(id)
join real_estate.city as c using(city_id)
join real_estate."type" as t using(type_id)
where id IN (SELECT * FROM filtered_id)
      and city != 'Санкт-Петербург'
      and  f.total_area > 0 
      and a.last_price IS NOT NULL
group by city
order by count(a.id) desc
limit 15)
select *,
round((removal_ad :: numeric / ad), 2) as share                                            --доля
from cte1 

       -- Общие выводы и рекомендации:
-- Рынок недвижимости Санкт-Петербурга более дорогой и динамичный, с большим разбросом в ценах и сроках экспозиции.
-- Рынок недвижимости Ленинградской области более стабильный по цене и срокам, при этом цена за квадратный метр ниже чем в Санкт-Петербурге.
-- На время экспозиции влияют как характеристики объекта (площадь, цена за квадратный метр, количество комнат), так и внешние факторы (регион).
-- Квартиры-студии, как правило, продаются быстрее.
-- Активность публикаций объявлений приходится на конец осени, особенно на октябрь и ноябрь.
-- Активность снятия объявлений приходится на осень и начало зимы, в основном на октябрь и ноябрь, а также на январь.
-- Наибольшая средняя цена за квадратный метр для открытых объявлений наблюдается в конце лета и начале осени, а для закрытых объявлений - в начале зимы.
-- Колебания средней площади квартир в течение года не имеют четкой зависимости от месяца.
-- В Ленинградской области Мурино выделяется как поселок с самым активным рынком недвижимости (большое количество объявлений и высокая доля закрытых сделок), средними ценами и быстрыми продажами.
-- Акцентировать рекламу на период с февраля по ноябрь, особенно в октябре и ноябре, когда наибольшая активность продавцов.
-- Проводить кампании для покупателей в период с сентября по январь, когда сделки закрываются активнее.
	                    