CREATE TABLE stg_swiggy_orders (
    order_time VARCHAR(50),
    order_id INT,
    order_date DATE,
    allot_time VARCHAR(50),
    accept_time VARCHAR(50),
    pickup_time VARCHAR(50),
    delivered_time VARCHAR(50),
    rider_id INT,
    first_mile_distance NUMERIC,
    last_mile_distance NUMERIC,
    alloted_orders NUMERIC,
    delivered_orders NUMERIC,
    cancelled INT,
    undelivered_orders NUMERIC,
    lifetime_order_count NUMERIC,
    reassignment_method VARCHAR(100),
    reassignment_reason VARCHAR(255),
    reassigned_order INT,
    session_time NUMERIC,
    cancelled_time VARCHAR(50),
	location_id INT
);


SELECT * FROM stg_swiggy_orders;

CREATE TABLE dim_riders (
    rider_id INT PRIMARY KEY,
    alloted_orders INT DEFAULT 0,
    delivered_orders INT DEFAULT 0,
    undelivered_orders INT DEFAULT 0,
    lifetime_order_count INT DEFAULT 0
);

CREATE TABLE dim_geography (
    location_id INT PRIMARY KEY,
    first_mile_distance NUMERIC(10, 4),
    last_mile_distance NUMERIC(10, 4)
);

CREATE TABLE dim_date (
    order_date DATE PRIMARY KEY,
    day_of_week VARCHAR(15),
    month VARCHAR(15),
    hour_of_day INT
);

ALTER TABLE dim_date DROP COLUMN parsed_datetime;
ALTER TABLE dim_date DROP COLUMN day_of_week;
ALTER TABLE dim_date DROP COLUMN month;

ALTER TABLE dim_date
ADD parsed_datetime NUMERIC;

ALTER TABLE dim_date
ADD day_of_week VARCHAR(30);

ALTER TABLE dim_date
ADD month VARCHAR(30);

CREATE TABLE fact_swiggy_orders (
    order_id INT PRIMARY KEY,
    rider_id INT,
    location_id INT,
    order_date DATE,
    order_time TIMESTAMP,
    allot_time TIMESTAMP,
    accept_time TIMESTAMP,
    pickup_time TIMESTAMP,
    delivered_time TIMESTAMP,
    cancelled INT,
    session_time NUMERIC(12, 2),
    cancelled_time TIMESTAMP,
    reassignment_method VARCHAR(100),
    reassignment_reason VARCHAR(255),
    reassigned_order INT,
	
    CONSTRAINT fk_rider FOREIGN KEY (rider_id) REFERENCES dim_riders(rider_id),
    CONSTRAINT fk_geo FOREIGN KEY (location_id) REFERENCES dim_geography(location_id),
    CONSTRAINT fk_date FOREIGN KEY (order_date) REFERENCES dim_date(order_date)
);


--Inserting data
INSERT INTO dim_riders (rider_id, alloted_orders, delivered_orders, undelivered_orders, lifetime_order_count)
SELECT 
    rider_id,
    COALESCE(MAX(alloted_orders), 0)::INT,
    COALESCE(MAX(delivered_orders), 0)::INT,
    COALESCE(MAX(undelivered_orders), 0)::INT,
    COALESCE(MAX(lifetime_order_count), 0)::INT
FROM stg_swiggy_orders
WHERE rider_id IS NOT NULL
GROUP BY rider_id;

SELECT * FROM dim_riders;

--Insert into dim geography
INSERT INTO dim_geography (location_id, first_mile_distance, last_mile_distance)
SELECT 
	location_id,
	first_mile_distance,
	last_mile_distance
FROM stg_swiggy_orders
WHERE location_id IS NOT NULL
GROUP BY location_id, first_mile_distance, last_mile_distance;

SELECT * FROM dim_geography;

TRUNCATE TABLE dim_date CASCADE;

INSERT INTO dim_date (order_date, day_of_week, month, hour_of_day)
SELECT 
    order_date::DATE, -- Converts your text date into a true SQL Date
    EXTRACT(ISODOW FROM MIN(TO_TIMESTAMP(order_time, 'DD-MM-YYYY HH24:MI')))::INT AS day_of_week,
    EXTRACT(MONTH FROM MIN(TO_TIMESTAMP(order_time, 'DD-MM-YYYY HH24:MI')))::INT AS month,
    EXTRACT(HOUR FROM MIN(TO_TIMESTAMP(order_time, 'DD-MM-YYYY HH24:MI')))::INT AS hour_of_day
FROM stg_swiggy_orders
WHERE order_date IS NOT NULL
GROUP BY order_date;

SELECT * FROM dim_date;
	
INSERT INTO fact_swiggy_orders (    
    order_id, rider_id, location_id, order_date, order_time, 
    allot_time, accept_time, pickup_time, delivered_time, cancelled, 
    session_time, cancelled_time, reassignment_method, reassignment_reason, reassigned_order
)
SELECT 
    order_id, rider_id, location_id, order_date::DATE,
    TO_TIMESTAMP(order_time, 'DD-MM-YYYY HH24:MI'),
    TO_TIMESTAMP(allot_time, 'DD-MM-YYYY HH24:MI'),
    TO_TIMESTAMP(accept_time, 'DD-MM-YYYY HH24:MI'),
    TO_TIMESTAMP(pickup_time, 'DD-MM-YYYY HH24:MI'),
    TO_TIMESTAMP(delivered_time, 'DD-MM-YYYY HH24:MI'),
    cancelled, COALESCE(session_time, 0)::NUMERIC,
    TO_TIMESTAMP(cancelled_time, 'DD-MM-YYYY HH24:MI'),
    COALESCE(reassignment_method, 'Not Reassigned'),
    COALESCE(reassignment_reason, 'Not Reassigned'),
    reassigned_order
FROM stg_swiggy_orders
ON CONFLICT (order_id) DO NOTHING;

SELECT * FROM fact_swiggy_orders;

