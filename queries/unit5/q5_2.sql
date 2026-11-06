-- ================================================================================================================
-- Theme                   actor       producer        event       catalog         junction            metric
-- Rental Marketplace      renters     properties      viewings    amenities       listing_amenities   duration_min
-- =================================================================================================================
/*
Task 5.2: Find Records That Joins May Exclude

Part A: Compare INNER JOIN and LEFT JOIN
Write two queries to compare the results of an inner join and a left join.
Use LEFT JOIN to return all producers, including those who have never had an event.
*/
-- 5.2.A.1: LEFT JOIN
-- Business Question:How many viewing events does every property have, including properties with no events?
SELECT p.property_id,
       p.property_label,
       COUNT(v.viewing_id) AS total_viewings
FROM properties p
         LEFT JOIN
     viewings v ON p.property_id = v.property_id
GROUP BY p.property_id,
         p.property_label
ORDER BY p.property_id;

-- 5.2.A.2: INNER JOIN
-- Business Question: How many viewing events does every property have, excluding properties with no events?
SELECT p.property_id,
       p.property_label,
       COUNT(v.viewing_id) AS total_viewings
FROM properties p
         INNER JOIN
     viewings v ON p.property_id = v.property_id
GROUP BY p.property_id,
         p.property_label
ORDER BY p.property_id;

-- Task 5.2.A.3
-- Business question: How many unique properties are excluded
-- from the INNER JOIN result?
SELECT COUNT(DISTINCT p.property_id) AS excluded_property_count
FROM properties AS p
         LEFT JOIN viewings AS v
                   ON p.property_id = v.property_id
WHERE v.viewing_id IS NULL;

-- Task 5.2.A.4
-- Business question: Which properties are excluded from
-- the INNER JOIN, and why?
SELECT p.property_id,
       p.property_label,
       'No recorded viewing events' AS exclusion_reason
FROM properties AS p
         LEFT JOIN viewings AS v
                   ON p.property_id = v.property_id
WHERE v.viewing_id IS NULL
ORDER BY p.property_id;

/*
Part B: Explore RIGHT JOIN and FULL OUTER JOIN
Next, examine the same relationship using two additional join types.
Write a RIGHT JOIN that returns the same records as your LEFT JOIN from Part A.
Compare the results to confirm that they match.
*/

-- Task 5.2.B.1: RIGHT JOIN
-- Business question: Can a RIGHT JOIN produce the same
-- all-property summary as the LEFT JOIN?
SELECT p.property_id,
       p.property_label,
       COUNT(v.viewing_id) AS total_viewings
FROM viewings AS v
         RIGHT JOIN properties AS p
                    ON v.property_id = p.property_id
GROUP BY p.property_id,
         p.property_label
ORDER BY p.property_id;

-- Task 5.2.B.2
-- Business question: Do the LEFT JOIN and RIGHT JOIN
-- return exactly the same property summaries?
WITH left_join_results AS (SELECT p.property_id,
                                  p.property_label,
                                  COUNT(v.viewing_id) AS total_viewings
                           FROM properties AS p
                                    LEFT JOIN viewings AS v
                                              ON p.property_id = v.property_id
                           GROUP BY p.property_id,
                                    p.property_label),
     right_join_results AS (SELECT p.property_id,
                                   p.property_label,
                                   COUNT(v.viewing_id) AS total_viewings
                            FROM viewings AS v
                                     RIGHT JOIN properties AS p
                                                ON v.property_id = p.property_id
                            GROUP BY p.property_id,
                                     p.property_label)
SELECT (SELECT COUNT(*)
        FROM (SELECT *
              FROM left_join_results
              EXCEPT
              SELECT *
              FROM right_join_results) AS left_only) AS rows_only_in_left_join,

       (SELECT COUNT(*)
        FROM (SELECT *
              FROM right_join_results
              EXCEPT
              SELECT *
              FROM left_join_results) AS right_only) AS rows_only_in_right_join;
/*
Write a FULL OUTER JOIN that includes matching and unmatched records from both tables.
Explain what a full outer join can reveal that a left join or right join alone may not show.
Be sure to verify your results rather than assuming the queries are equivalent.
*/

-- Task 5.2.B.3: FULL OUTER JOIN
-- Business question: Which properties and viewings match,
-- and are there unmatched records on either side?
SELECT p.property_id,
       p.property_label,
       v.viewing_id,
       v.viewing_status,
       CASE
           WHEN p.property_id IS NULL
               THEN 'Viewing without a matching property'
           WHEN v.viewing_id IS NULL
               THEN 'Property without a viewing'
           ELSE 'Matched property and viewing'
           END AS match_status
FROM properties AS p
         FULL OUTER JOIN viewings AS v
                         ON p.property_id = v.property_id

ORDER BY p.property_id NULLS LAST,
         v.viewing_id NULLS LAST;


-- Task 5.2.B.4
-- Business question: How many matched and unmatched records
-- did the FULL OUTER JOIN find?
SELECT CASE
           WHEN p.property_id IS NULL
               THEN 'Viewing without a matching property'
           WHEN v.viewing_id IS NULL
               THEN 'Property without a viewing'
           ELSE 'Matched property and viewing'
           END  AS match_status,
       COUNT(*) AS record_count
FROM properties AS p
         FULL OUTER JOIN viewings AS v
                         ON p.property_id = v.property_id
GROUP BY CASE
             WHEN p.property_id IS NULL
                 THEN 'Viewing without a matching property'
             WHEN v.viewing_id IS NULL
                 THEN 'Property without a viewing'
             ELSE 'Matched property and viewing'
             END
ORDER BY match_status;

/*
Part C: Find Producers with No Events Using Two Approaches
Write two queries that identify producers who have never had an event and compare them.
✓  NOT EXISTS.
✓  EXCEPT.
Run both queries and compare their results.
In one or two sentences, explain how the approaches differ and confirm whether they identify the same producers.
*/

-- Task 5.2.C.1: NOT EXISTS
-- Business question: Which properties have never had
-- a recorded viewing event?
SELECT p.property_id,
       p.property_label
FROM properties AS p
WHERE NOT EXISTS (SELECT 1
                  FROM viewings AS v
                  WHERE v.property_id = p.property_id)
ORDER BY p.property_id;

-- Task 5.2.C.2: EXCEPT
-- Business question: Which property identifiers exist in
-- properties but never appear in viewings?
SELECT p.property_id,
       p.property_label
FROM properties AS p
WHERE p.property_id IN (SELECT property_id
                        FROM properties
                        EXCEPT
                        SELECT property_id
                        FROM viewings)
ORDER BY p.property_id;