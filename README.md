# Hyperlocal Food Delivery Analytics Pipeline

## Project Overview
This project builds a complete data analytics pipeline using a raw dataset of 450,000+ Swiggy delivery logs. The goal is to take messy, flat transactional data, organize it into a structured database, and set it up for clear dashboard reporting.

By separating the raw data into specialized tables, we can easily track delivery performance, understand where orders get delayed or cancelled, and see how rider experience impacts delivery speeds.

---

## The Data Pipeline

1. **Staging Step (Data Loading):** Raw transactional data is streamed directly into a flat PostgreSQL staging table (`stg_swiggy_orders`).
2. **Data Cleaning & Transformation:** Using SQL, the raw data is cleaned—converting text columns into proper dates/timestamps, handling missing values logically, and separating the single massive sheet into a clean **Star Schema** design.
3. **Analytics Ready Warehouse:** The final structured data is organized into one central table for metrics and three supporting tables for details.

---

## Database Design (Star Schema)

To make queries fast and efficient, the database is split into four distinct tables:

* **fact_swiggy_orders (The Central Engine):** Stores every single order ID, tracking timestamps (order time, pickup time, delivery time), cancellation statuses, and link keys to the other tables.
* **dim_riders:** Tracks individual driver metrics, including total orders allocated, delivered, undelivered, and their lifetime order counts.
* **dim_geography:** Pairs up unique trip segments, capturing both the first-mile distance (driver to restaurant) and last-mile distance (restaurant to customer).
* **dim_date:** Breaks down time components by day of the week, month, and hour to spot ordering trends throughout the week.

---

## Project Structure & Files

```text
├── Data/                   # Local raw CSV logs (Git ignored)
├── schema.sql              # SQL scripts creating the warehouse tables
├── pipeline_queries.sql    # SQL scripts moving and cleaning data from staging
├── README.md               # Project overview and documentation