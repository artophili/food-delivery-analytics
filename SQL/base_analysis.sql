SELECT 
    f.order_id,
    r.rider_id,
    g.first_mile_distance,
    g.last_mile_distance,
    d.day_of_week,
    f.order_time,
    f.delivered_time
FROM fact_swiggy_orders f
JOIN dim_riders r ON f.rider_id = r.rider_id
JOIN dim_geography g ON f.location_id = g.location_id
JOIN dim_date d ON f.order_date = d.order_date
LIMIT 5;

--Delivery Bottleneck Analysis
SELECT 
    d.hour_of_day,
    COUNT(f.order_id) AS total_orders,
    
    -- 1. Avg minutes from order placed to rider accepted
    ROUND(AVG(EXTRACT(EPOCH FROM (f.accept_time - f.order_time)) / 60)::NUMERIC, 2) AS avg_assignment_mins,
    
    -- 2. Avg minutes from rider accepted to food picked up
    ROUND(AVG(EXTRACT(EPOCH FROM (f.pickup_time - f.accept_time)) / 60)::NUMERIC, 2) AS avg_prep_and_travel_mins,
    
    -- 3. Avg minutes from food picked up to delivered to customer
    ROUND(AVG(EXTRACT(EPOCH FROM (f.delivered_time - f.pickup_time)) / 60)::NUMERIC, 2) AS avg_last_mile_delivery_mins,
    
    -- 4. Total Avg Order Cycle Time (Order Placement to Delivery)
    ROUND(AVG(EXTRACT(EPOCH FROM (f.delivered_time - f.order_time)) / 60)::NUMERIC, 2) AS total_avg_cycle_mins
FROM fact_swiggy_orders f
JOIN dim_date d ON f.order_date = d.order_date
-- We only look at completed deliveries, ignoring cancellations without valid times
WHERE f.delivered_time IS NOT NULL 
  AND f.pickup_time IS NOT NULL 
  AND f.accept_time IS NOT NULL
GROUP BY d.hour_of_day
ORDER BY d.hour_of_day;

--It seems like the rider is spending almost the exact same amount of time waiting around at the restaurant as they are driving across town to the customer!
--Is this because of distance or kitchen delays
SELECT 
    CASE 
        WHEN g.first_mile_distance <= 1 THEN '0-1 km (Very Close)'
        WHEN g.first_mile_distance > 1 AND g.first_mile_distance <= 3 THEN '1-3 km (Moderate)'
        ELSE '3+ km (Long Distance)'
    END AS rider_to_restaurant_distance,
    COUNT(f.order_id) AS total_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (f.pickup_time - f.accept_time)) / 60)::NUMERIC, 2) AS avg_prep_and_travel_mins
FROM fact_swiggy_orders f
JOIN dim_geography g ON f.location_id = g.location_id
WHERE f.pickup_time IS NOT NULL AND f.accept_time IS NOT NULL
GROUP BY 1
ORDER BY avg_prep_and_travel_mins DESC;

--The rider accepts an order less than 1 kilometer away from the restaurant.
--At a standard city driving speed, traveling 1 km takes about 2 to 3 minutes.
--Yet, the total time from acceptance to pickup is 13.22 minutes.

--riders are spending roughly 10 to 11 minutes just standing around inside or outside the restaurant, 
--waiting for the kitchen to finish cooking and packaging the food.

--Query to check if these delays directly cause orders to get cancelled
SELECT 
    CASE 
        WHEN g.first_mile_distance <= 1 THEN '0-1 km (Very Close)'
        WHEN g.first_mile_distance > 1 AND g.first_mile_distance <= 3 THEN '1-3 km (Moderate)'
        ELSE '3+ km (Long Distance)'
    END AS rider_to_restaurant_distance,
    COUNT(f.order_id) AS total_cancelled_orders,
    -- Calculate avg minutes elapsed before the order blew up
    ROUND(AVG(EXTRACT(EPOCH FROM (f.cancelled_time - f.accept_time)) / 60)::NUMERIC, 2) AS avg_mins_before_cancellation
FROM fact_swiggy_orders f
JOIN dim_geography g ON f.location_id = g.location_id
WHERE f.cancelled = 1 
  AND f.cancelled_time IS NOT NULL 
  AND f.accept_time IS NOT NULL
GROUP BY 1
ORDER BY total_cancelled_orders DESC;


--Experienced rider test
SELECT * FROM dim_riders;
SELECT * FROM fact_swiggy_orders;
SELECT * FROM dim_geography;

SELECT 
	CASE
		WHEN r.lifetime_order_count < 10 THEN 'New Rider'
		ELSE 'Experienced Rider'
	END AS Rider_experience,
	ROUND(AVG(EXTRACT(EPOCH FROM (f.delivered_time - f.accept_time)) / 60)::NUMERIC, 2) AS avg_mins_for_delivery
FROM fact_swiggy_orders f
JOIN dim_riders r ON f.rider_id = r.rider_id
GROUP BY 1
ORDER BY avg_mins_for_delivery DESC;

--Query to check the travel mins and total trip mins
SELECT 
    CASE
        WHEN r.lifetime_order_count < 10 THEN 'New Rider'
        ELSE 'Experienced Rider'
    END AS Rider_experience,
    COUNT(f.order_id) AS total_orders,
    -- Checking pure driving/navigation time
    ROUND(AVG(EXTRACT(EPOCH FROM (f.delivered_time - f.pickup_time)) / 60)::NUMERIC, 2) AS avg_driving_mins,
    -- Checking total trip time from acceptance to delivery
    ROUND(AVG(EXTRACT(EPOCH FROM (f.delivered_time - f.accept_time)) / 60)::NUMERIC, 2) AS avg_total_trip_mins
FROM fact_swiggy_orders f
JOIN dim_riders r ON f.rider_id = r.rider_id
WHERE f.delivered_time IS NOT NULL AND f.pickup_time IS NOT NULL
GROUP BY 1
ORDER BY avg_driving_mins DESC;
	

SELECT 
    CASE 
        WHEN g.last_mile_distance <= 1 THEN '0-1 miles (Very Close)'
        WHEN g.last_mile_distance > 1 AND g.last_mile_distance <= 3 THEN '1-3 miles (Moderate)'
        ELSE '3+ km (Long Distance)'
    END AS rider_to_restaurant_distance,
	COUNT(f.order_id) AS total_cancelled_orders
FROM fact_swiggy_orders f
JOIN dim_geography g ON f.location_id = g.location_id
WHERE f.cancelled = 1
GROUP BY 1;

	