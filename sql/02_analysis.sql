-- Zomato restaurant market analysis (SQLite). Run with scripts/run_analysis.py
-- Averages use rated restaurants only (rating is NULL for "Not rated").

-- name: q1_country | Q1. Market overview by country
SELECT country,
       COUNT(*)                                             AS restaurants,
       ROUND(100.0 * AVG(is_rated), 1)                      AS pct_rated,
       ROUND(AVG(rating), 2)                                AS avg_rating,
       ROUND(100.0 * AVG(has_online_delivery), 1)           AS pct_online_delivery,
       ROUND(100.0 * AVG(has_table_booking), 1)             AS pct_table_booking
FROM vw_restaurants
GROUP BY country ORDER BY restaurants DESC;

-- name: q2_india_cities | Q2. India: ten biggest cities
SELECT city,
       COUNT(*)                                             AS restaurants,
       ROUND(AVG(rating), 2)                                AS avg_rating,
       ROUND(100.0 * AVG(has_online_delivery), 1)           AS pct_online_delivery,
       ROUND(100.0 * AVG(is_rated), 1)                      AS pct_rated
FROM vw_restaurants WHERE country = 'India'
GROUP BY city ORDER BY restaurants DESC LIMIT 10;

-- name: q3_delivery_effect | Q3. Online delivery vs. rating and votes (rated restaurants)
SELECT CASE has_online_delivery WHEN 1 THEN 'Offers online delivery' ELSE 'No online delivery' END AS segment,
       COUNT(*)                  AS rated_restaurants,
       ROUND(AVG(rating), 2)     AS avg_rating,
       ROUND(AVG(votes), 0)      AS avg_votes,
       ROUND(AVG(cost_for_two * 1.0), 0) AS avg_cost_for_two_local
FROM vw_restaurants WHERE is_rated = 1 AND country = 'India'
GROUP BY has_online_delivery;

-- name: q4_price_range | Q4. Price range vs. rating, delivery and table booking (India)
SELECT price_label,
       COUNT(*)                                             AS restaurants,
       ROUND(AVG(rating), 2)                                AS avg_rating,
       ROUND(100.0 * AVG(has_online_delivery), 1)           AS pct_online_delivery,
       ROUND(100.0 * AVG(has_table_booking), 1)             AS pct_table_booking,
       ROUND(AVG(votes), 0)                                 AS avg_votes
FROM vw_restaurants WHERE country = 'India'
GROUP BY price_label ORDER BY price_label;

-- name: q5_cuisines | Q5. India: most common cuisines and how well they are rated (min. 100 restaurants)
SELECT rc.cuisine,
       COUNT(*)                                             AS restaurants,
       ROUND(AVG(v.rating), 2)                              AS avg_rating,
       ROUND(100.0 * AVG(v.has_online_delivery), 1)         AS pct_online_delivery
FROM restaurant_cuisines rc JOIN vw_restaurants v USING (restaurant_id)
WHERE v.country = 'India'
GROUP BY rc.cuisine HAVING COUNT(*) >= 100
ORDER BY restaurants DESC LIMIT 12;

-- name: q6_niche_cuisines | Q6. India: small cuisines (20-99 restaurants) with the best ratings
SELECT rc.cuisine,
       COUNT(*)                   AS restaurants,
       COUNT(v.rating)            AS rated,
       ROUND(AVG(v.rating), 2)    AS avg_rating,
       ROUND(AVG(v.votes), 0)     AS avg_votes
FROM restaurant_cuisines rc JOIN vw_restaurants v USING (restaurant_id)
WHERE v.country = 'India'
GROUP BY rc.cuisine HAVING COUNT(*) BETWEEN 20 AND 99 AND COUNT(v.rating) >= 15
ORDER BY avg_rating DESC LIMIT 10;

-- name: q7_leads | Q7. Onboarding leads: well-rated, popular, but not on online delivery (India, by city)
SELECT city,
       COUNT(*)                   AS leads,
       ROUND(AVG(rating), 2)      AS avg_rating,
       ROUND(AVG(votes), 0)       AS avg_votes
FROM vw_restaurants
WHERE country = 'India' AND has_online_delivery = 0 AND rating >= 4.0 AND votes >= 100
GROUP BY city ORDER BY leads DESC LIMIT 10;

-- name: q8_vote_concentration | Q8. How concentrated is customer attention? Share of all votes by restaurant decile
WITH ranked AS (
    SELECT votes, NTILE(10) OVER (ORDER BY votes DESC) AS decile FROM restaurants
)
SELECT decile, COUNT(*) AS restaurants, SUM(votes) AS votes,
       ROUND(100.0 * SUM(votes) / (SELECT SUM(votes) FROM restaurants), 1) AS pct_of_all_votes
FROM ranked GROUP BY decile ORDER BY decile;

-- name: q9_unrated | Q9. Unrated restaurants: who are they? (India)
SELECT CASE has_online_delivery WHEN 1 THEN 'Online delivery' ELSE 'No online delivery' END AS segment,
       COUNT(*)                                   AS restaurants,
       ROUND(100.0 * AVG(1 - is_rated), 1)        AS pct_unrated
FROM vw_restaurants WHERE country = 'India'
GROUP BY has_online_delivery;
