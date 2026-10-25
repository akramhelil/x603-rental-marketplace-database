-- ================================================================================================================
-- Theme                   actor       producer        event       catalog         junction            metric
-- Rental Marketplace      renters     properties      viewings    amenities       listing_amenities   duration_min
-- =================================================================================================================
/*
Task 4.2: Build the breakdown leadership asked for
Leadership needs additional information that cannot be obtained from the basic grouping queries in Task 4.1. Complete the following three parts to produce more detailed analytical summaries.



Part A: Two numbers in one pass
For each producer, compute the total number of events and the total number of events classified as failures,
in a single pass over the event table, without a WHERE clause filtering the whole query.
The outliers here are the producers you will name in your finding.

✓  CASE used inside an aggregate — for example SUM(CASE WHEN ... THEN 1 ELSE 0 END) or COUNT(CASE WHEN ... END).
✓  Both totals appearing as separate columns in one result set.
*/
-- Count total and disputed viewings for each property
SELECT p.property_id,
       p.property_label,
       p.city              AS property_city,

       -- Count every viewing event
       COUNT(v.viewing_id) AS total_events,

       -- Count only disputed viewing events
       SUM(
               CASE
                   WHEN v.viewing_status = 'disputed' THEN 1
                   ELSE 0
                   END
       )                   AS disputed_events,

       -- Calculate the percentage of events that were disputed
       ROUND(
               100.0 * SUM(
                       CASE
                           WHEN v.viewing_status = 'disputed' THEN 1
                           ELSE 0
                           END
                       ) / NULLIF(COUNT(v.viewing_id), 0),
               2
       )                   AS disputed_rate_percent

FROM properties p
         LEFT JOIN viewings v
                   ON p.property_id = v.property_id

GROUP BY p.property_id,
         p.property_label,
         p.city

ORDER BY disputed_events DESC,
         total_events DESC,
         p.property_id;


/*
Part B: Subtotals and a grand total
The regional director wants subtotals per region and a platform grand total, not the detail rows.
Write a query that produces regional subtotals and a platform-wide grand total without including the individual detail rows.

✓  GROUP BY ROLLUP (...), or GROUPING SETS or CUBE.
✓  A written note identifying which rows are the subtotals and which is the grand total.
*/
-- Regional subtotals plus a platform grand total
SELECT CASE
           WHEN GROUPING(booking_city) = 1
               THEN 'All Regions'
           ELSE booking_city
           END                     AS region,

       COUNT(*)                    AS total_events,

       SUM(
               CASE
                   WHEN viewing_status = 'disputed' THEN 1
                   ELSE 0
                   END
       )                           AS disputed_events,

       ROUND(AVG(duration_min), 2) AS average_duration_min,

       COUNT(DISTINCT renter_id)   AS distinct_renters

FROM viewings

GROUP BY ROLLUP (booking_city)

ORDER BY GROUPING(booking_city),
         region;

/*
Part C: A two-step pipeline
Leadership wants to establish a baseline for evaluating high-volume producers.
That needs two steps: use a WITH clause to create an intermediate result that summarizes performance for each producer,
then use a second aggregation or filter on that intermediate result to calculate a baseline for high-volume producers.

✓  A WITH clause producing an intermediate aggregate.
✓  A second aggregation or filter applied to that intermediate result.
*/
-- Step 1: Summarize performance for each property
WITH producer_performance AS (SELECT p.property_id,
                                     p.property_label,
                                     COUNT(v.viewing_id)           AS total_events,

                                     SUM(
                                             CASE
                                                 WHEN v.viewing_status = 'disputed' THEN 1
                                                 ELSE 0
                                                 END
                                     )                             AS disputed_events,

                                     ROUND(AVG(v.duration_min), 2) AS average_duration_min

                              FROM properties p
                                       JOIN viewings v
                                            ON p.property_id = v.property_id

                              GROUP BY p.property_id,
                                       p.property_label)

-- Step 2: Calculate a baseline for high-volume properties
SELECT COUNT(*)                       AS high_volume_property_count,
       ROUND(AVG(total_events), 2)    AS average_events_per_property,
       ROUND(AVG(disputed_events), 2) AS average_disputes_per_property,
       SUM(total_events)              AS combined_events,
       SUM(disputed_events)           AS combined_disputed_events,

       ROUND(
               100.0 * SUM(disputed_events)
                   / NULLIF(SUM(total_events), 0),
               2
       )                              AS high_volume_disputed_rate_percent,

       ROUND(AVG(average_duration_min), 2)
                                      AS average_property_duration_min

FROM producer_performance

WHERE total_events >= 10;

/*
Write up
For Part A, state the two questions your conditional aggregation answers side by side.
For Part B, name the reader who needs subtotals rather than detail rows,
and say what decision the grand total supports that the group rows do not.
For Part C, state the question the pipeline answers.

Response:
Part A: Two Numbers Side by Side
The conditional calculation helps us answer two questions at the same time:
How many viewings did each property receive, and how many of those viewings were disputed?
Looking at both numbers together gives us better context.
For example, two disputes out of 10 viewings would be more concerning than two disputes out of 100 viewings.

Part B: Regional Subtotals and Grand Total
The Regional Director needs the regional subtotals because they provide a clear comparison of viewing activity
and disputes across Danang, Haiphong, Hanoi, Hue, and Saigon without showing every individual viewing.
The grand total answers a broader question: Is this a platform-wide problem, or is it mostly affecting certain regions?
That helps leadership decide whether to make a change across the entire platform or focus on specific regional teams.

Part C: Two-Step Pipeline
The pipeline answers this question: What is a normal dispute rate for properties with enough viewings to make a fair comparison?
First, it summarizes the results for each property. Then it focuses on properties with at least 10 viewing events
and creates a shared baseline. Leadership can compare each high-volume property with that baseline to see which properties may need a closer review.
*/


