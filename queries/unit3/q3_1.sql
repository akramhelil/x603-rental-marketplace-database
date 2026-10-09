/*
Task 3.1: Establish what the data contains
Before you can audit a rate you need to know the population it was computed over.
Write a set of queries that answer these questions, and record what each one told you.

================================================================================================================
Theme                   actor       producer        event       catalog         junction            metric
Rental Marketplace      renters     properties      viewings    amenities       listing_amenities   duration_min
=================================================================================================================
*/
--  1. Find available, highly rated properties. Use your theme’s filter condition from the appendix.
--  Sort them and return the first ten.
SELECT property_id, property_label, city, monthly_rent, is_available FROM properties
WHERE is_available = TRUE
AND monthly_rent < 2000
ORDER BY monthly_rent DESC
LIMIT 10;

--2. Find all possible event statuses. Display the distinct values in the event status column.
-- Look carefully at the results. Are there more statuses than you expected?
SELECT DISTINCT viewing_status
FROM viewings; -- Look up what kinda status viewings got


-- 3. Filter the events in two different ways.
-- Write: one query that filters a numeric range,
-- and one query that filters using an explicit list of values with IN.
SELECT property_id, viewing_id, viewing_status, duration_min FROM viewings
WHERE interest_score > 1.5 AND interest_score < 5; -- Filter by numeric range

SELECT property_id, viewing_id, viewing_status, duration_min FROM viewings
WHERE viewing_status IN ('cancelled', 'attended'); -- Filter by explicit list of values

-- 4. Work with text and missing values.
-- Write queries that: find producers whose names match a text pattern using LIKE, and identify records where a reason/value is missing (NULL).
-- Use COALESCE to replace a missing value with a useful label such as: No reason provided.
SELECT * FROM properties
WHERE property_label LIKE '%Property_0%'; -- Find producers whose names match a text pattern

SELECT
    r.renter_id,
    r.renter_name,
    v.viewing_id,
    v.viewing_status,
    COALESCE(v.no_show_reason, 'No reason provided') AS no_show_reason,
    v.booking_city,
    r.search_city
FROM renters r
    JOIN viewings v ON v.renter_id = r.renter_id
WHERE v.viewing_status = 'disputed'
  AND v.no_show_reason IS NULL; -- Identify records where a reason/value is missing (NULL)

--5. Make the results easier to understand.
-- Create a query with calculated/computed columns that would make sense to someone who does not work with SQL.
-- Depending on your theme, you might calculate or label:Use CASE where appropriate to create plain-language categories.

-- Time from scheduled to actual viewing, or another useful business measure.
SELECT v.viewing_id, v.property_id, v.renter_id, v.scheduled_at, v.attended_at,
    CASE
        WHEN v.attended_at IS NULL THEN 'Not yet attended'
        WHEN v.attended_at is NULL AND v.viewing_status = 'cancelled' THEN 'Cancelled'
        WHEN v.attended_at < v.scheduled_at THEN 'Attended early'
        WHEN v.attended_at = v.scheduled_at THEN 'Attended on time'
        WHEN v.attended_at > v.scheduled_at THEN 'Attended late'
    END AS attendance_status,
    CASE
        WHEN v.duration_min < 30 THEN 'Short viewing'
        WHEN v.duration_min BETWEEN 30 AND 60 THEN 'Medium viewing'
        WHEN v.duration_min > 60 THEN 'Long viewing'
    END AS viewing_duration_category
FROM viewings v;

SELECT
    v.viewing_id,
    r.renter_name,
    p.property_label,
    p.city,
    p.monthly_rent,
    ROUND(v.travel_km, 2) AS travel_distance_km,

    CASE
        WHEN v.travel_km < 10 THEN 'Nearby'
        WHEN v.travel_km < 20 THEN 'Moderate Distance'
        ELSE 'Long Distance'
        END AS travel_category,
    ROUND(v.interest_score, 2) AS interest_score,

    CASE
        WHEN v.interest_score >= 2.0 THEN 'Highly Interested'
        WHEN v.interest_score >= 1.5 THEN 'Interested'
        ELSE 'Low Interest'
        END AS interest_level,

    CASE
        WHEN p.monthly_rent < 1000 THEN 'Budget Property'
        WHEN p.monthly_rent < 2500 THEN 'Mid-Range Property'
        ELSE 'Premium Property'
        END AS rent_category,

    CASE
        WHEN v.viewing_status = 'attended' THEN 'Viewing Completed'
        WHEN v.viewing_status = 'cancelled' THEN 'Viewing Cancelled'
        ELSE 'Requires Review'
        END AS viewing_outcome

FROM viewings v
         JOIN renters r
              ON v.renter_id = r.renter_id
         JOIN properties p
              ON v.property_id = p.property_id
ORDER BY v.viewing_id;