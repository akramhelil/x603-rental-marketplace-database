-- ================================================================================================================
-- Theme                   actor       producer        event       catalog         junction            metric
-- Rental Marketplace      renters     properties      viewings    amenities       listing_amenities   duration_min
-- =================================================================================================================

/*
Task 4.1: Measure the platform
Your first task is to calculate the platform's actual performance metrics and examine how they vary across producers.

Write SQL queries that answer each of the following questions. Run each query, review its results, and record what you learned.



The questions
4.1.1: Calculate the following statistics across the entire event table using your theme's metric:
the count, total, average, minimum, and maximum of your theme’s metric across the whole event table,
and how many distinct actors appear. Review your results carefully.
For example, if your metric should never be zero but your minimum value is zero, this may indicate another
data-quality issue that needs investigation.
*/
-- Calculate overall viewing activity and duration statistics
SELECT
    COUNT(*) AS total_events,
    ROUND(SUM(duration_min), 2) AS total_viewing_minutes,
    ROUND(AVG(duration_min), 2) AS average_viewing_minutes,
    MIN(duration_min) AS shortest_viewing_minutes,
    MAX(duration_min) AS longest_viewing_minutes,
    COUNT(DISTINCT renter_id) AS distinct_renters
FROM viewings;

-- Investigate events with a zero-minute duration
SELECT
    viewing_status,
    COUNT(*) AS zero_duration_count
FROM viewings
WHERE duration_min = 0
GROUP BY viewing_status;

-- Calculate duration statistics only for completed viewings
SELECT
    COUNT(*) AS completed_viewings,
    ROUND(AVG(duration_min), 2) AS average_completed_duration,
    MIN(duration_min) AS shortest_completed_duration,
    MAX(duration_min) AS longest_completed_duration
FROM viewings
WHERE viewing_status = 'attended';


/*
4.1.2: Write a query that calculates the event count and average metric for each producer. Sort the results from the
producer with the most events to the producer with the fewest. Consider what these results tell you about differences
in activity and performance across producers.
*/
-- Calculate event count and average duration for each property
SELECT
    p.property_id,
    p.property_label,
    COUNT(v.viewing_id) AS total_events,

    COUNT(v.viewing_id) FILTER (
        WHERE v.viewing_status = 'attended'
        ) AS attended_events,

    ROUND(
                    AVG(v.duration_min) FILTER (
                WHERE v.viewing_status = 'attended'
                ),
                    2
    ) AS average_attended_duration
FROM properties p
         LEFT JOIN viewings v
                   ON p.property_id = v.property_id
GROUP BY
    p.property_id,
    p.property_label
ORDER BY
    total_events DESC,
    p.property_id;


/*
4.1.3: Which producers have enough volume for their rate to mean anything? A producer with only a few events may have
a high failure rate that is not representative of their usual performance. Choose a minimum event-count threshold and
use HAVING to include only producers who meet that threshold. Explain why you selected your threshold.
*/
-- Include only properties with at least 10 viewing events
SELECT
    p.property_id,
    p.property_label,
    p.city,
    COUNT(v.viewing_id) AS event_count,
    ROUND(AVG(v.duration_min), 2) AS average_duration_min
FROM properties p
         JOIN viewings v
              ON p.property_id = v.property_id
GROUP BY
    p.property_id,
    p.property_label,
    p.city
HAVING COUNT(v.viewing_id) >= 10
ORDER BY
    event_count DESC,
    p.property_id;

/*
4.1.4: How does the picture change along two dimensions at once? Leadership also wants to understand how performance
varies across regions. Write a query that groups the data by two dimensions, including region, and calculates the
relevant summary statistics. Your results should contain one row for each combination of the two dimensions so that
regional leaders can review their results.
*/
-- Calculate viewing performance by property and booking region
SELECT
    p.property_id,
    p.property_label,
    v.booking_city AS region,
    COUNT(*) AS event_count,
    ROUND(SUM(v.duration_min), 2) AS total_duration_min,
    ROUND(AVG(v.duration_min), 2) AS average_duration_min,
    MIN(v.duration_min) AS minimum_duration_min,
    MAX(v.duration_min) AS maximum_duration_min,
    COUNT(DISTINCT v.renter_id) AS distinct_renters
FROM viewings v
         JOIN properties p
              ON v.property_id = p.property_id
GROUP BY
    p.property_id,
    p.property_label,
    v.booking_city
ORDER BY
    p.property_label,
    event_count DESC,
    v.booking_city;