-- ================================================================================================================
-- Theme                   actor       producer        event       catalog         junction            metric
-- Rental Marketplace      renters     properties      viewings    amenities       listing_amenities   duration_min
-- =================================================================================================================
/*
Task 5.3: Understand Join Performance and Execution Plans
In this task, you will explore how joins affect query performance and how PostgreSQL decides to execute a query.

Part A: Explore CROSS JOIN
Write a CROSS JOIN between two small tables.
Then:
1.Count the rows in each source table.
2.Run the CROSS JOIN and count the resulting rows.
3.Show how the result matches the multiplication of the two source table counts.
4.Explain when a Cartesian product might be useful and when it could indicate a query error.
For example, if one table has 5 rows and another has 4 rows, the cross join produces 20 rows.
Choose small tables so the result is manageable.
*/
-- Task 5.3.A.1
-- Business question: How many properties and amenities
-- participate in the CROSS JOIN?
SELECT (SELECT COUNT(*) FROM properties) AS property_count,
       (SELECT COUNT(*) FROM amenities)  AS amenity_count;

-- Task 5.3.A.2
-- Business question: How many possible property-and-amenity
-- combinations are created by the CROSS JOIN?
SELECT COUNT(*) AS cross_join_row_count
FROM properties AS p
         CROSS JOIN amenities AS a;

-- Task 5.3.A.3
-- Business question: Does the CROSS JOIN row count equal
-- the two source-table counts multiplied together?

SELECT property_count,
       amenity_count,
       property_count * amenity_count               AS expected_rows,
       actual_rows,
       property_count * amenity_count = actual_rows AS counts_match
FROM (SELECT COUNT(*) AS property_count FROM properties) AS p
         CROSS JOIN
         (SELECT COUNT(*) AS amenity_count FROM amenities) AS a
         CROSS JOIN
     (SELECT COUNT(*) AS actual_rows
      FROM properties
               CROSS JOIN amenities) AS result;


/*
Part B: Examine a Query Execution Plan
Return to your three-table join from Task 5.1, Part A.
Use PostgreSQL's EXPLAIN command to examine how the database plans to execute the query.
EXPLAIN
SELECT ...    -- your three-table join from 5.1;
-- EXPLAIN ANALYZE also runs the query and reports actual timings.
-- Safe here; be careful with it on statements that modify data.
Review the execution plan and complete the following:
1. Capture the full execution plan.
2. Identify the join algorithm or algorithms used, such as Nested Loop, Hash Join, or Merge Join.
3. Explain why PostgreSQL may have selected these algorithms, considering table sizes and available indexes.
4. Predict which part of the query might become less efficient as the dataset grows.
5. You may also use EXPLAIN ANALYZE to measure actual execution behavior. Unlike EXPLAIN, it runs the query.
It is appropriate for your read-only SELECT query, but use caution with statements that modify data.
*/
-- Task 5.3.B.1
-- Business question: How does PostgreSQL plan to connect
-- renters, viewings, and properties?
-- This runs the read-only query and reports real execution behavior
EXPLAIN
SELECT
    v.viewing_id,
    r.renter_id,
    r.renter_name AS actor_name,
    p.property_id,
    p.property_label AS producer_name,
    v.scheduled_at AS event_date_time,
    v.viewing_status
FROM viewings AS v
         INNER JOIN renters AS r
                    ON v.renter_id = r.renter_id
         INNER JOIN properties AS p
                    ON v.property_id = p.property_id
ORDER BY
    v.scheduled_at,
    v.viewing_id;