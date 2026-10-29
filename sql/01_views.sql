-- Views used by the analysis queries and by Power BI.
DROP VIEW IF EXISTS vw_restaurants;
CREATE VIEW vw_restaurants AS
SELECT r.restaurant_id, r.name, c.country, r.city, r.locality, r.latitude, r.longitude,
       r.cuisines, r.cost_for_two, r.currency, r.price_range,
       r.has_table_booking, r.has_online_delivery, r.is_delivering_now,
       r.is_rated, r.rating, r.votes,
       CASE WHEN r.is_rated = 0          THEN 'Not rated'
            WHEN r.rating >= 4.0         THEN '4.0+ (Very good / Excellent)'
            WHEN r.rating >= 3.0         THEN '3.0 - 3.9 (Average / Good)'
            ELSE                              'Below 3.0 (Poor)' END AS rating_band,
       CASE r.price_range WHEN 1 THEN '1 - Budget' WHEN 2 THEN '2 - Moderate'
                          WHEN 3 THEN '3 - Upscale' ELSE '4 - Fine dining' END AS price_label,
       r.name_encoding_issue
FROM restaurants r JOIN countries c USING (country_code);
