/*
Task 3.3: Hand the team a corrected query
You want to give the dashboard team a query they can trust. The same question can be asked in several ways.

================================================================================================================
Theme                   actor       producer        event       catalog         junction            metric
Rental Marketplace      renters     properties      viewings    amenities       listing_amenities   duration_min
=================================================================================================================

What to do
Answer a two-step question about your data — for example, which actors were involved in the disputed events — and express it three ways.
5. Name one input condition under which the three would not be equivalent. NULLs, duplicates, and empty result sets are the usual places equivalence breaks.
*/



-- Two-step question: Which renters were involved in disputed viewing?
    -- Required steps:
    -- 1. Find the disputed viewings.
    -- 2. Find the renters involved in those viewings.

-- 1. First as a subquery using IN or NOT IN.
SELECT renter_id, renter_name FROM renters
WHERE renter_id IN
      (SELECT renter_id FROM
                            viewings WHERE
                                         viewing_status = 'disputed');

-- 2. Then as a Common Table Expression using WITH.
WITH disputed_renters AS (
    SELECT DISTINCT renters.renter_id, renters.renter_name
    FROM renters
    JOIN viewings ON renters.renter_id = viewings.renter_id
    WHERE viewings.viewing_status = 'disputed'
)
SELECT * FROM disputed_renters;

-- 3. Then a third way, distinct from both — a different subquery form, a CASE-based construction, or a set-based approach. If the Renter has a disputed viewing, then they are classified as having a disputed viewing; otherwise, they are classified as not having a disputed viewing.

SELECT renter_id,
       renter_name
FROM (SELECT r.renter_id,
             r.renter_name,
             CASE
                 WHEN EXISTS (SELECT 1
                              FROM viewings v
                              WHERE v.renter_id = r.renter_id
                                AND v.viewing_status = 'disputed')
                     THEN 'Has Disputed Viewing'
                 ELSE 'No Disputed Viewing'
                 END AS dispute_status
      FROM renters r) classified_renters
WHERE dispute_status = 'Has Disputed Viewing';


-- 4. Demonstrate that all three return identical result sets.
-- Matching row counts is not enough: show that the rows themselves match.
-- <CHECK SCREENSHOT OF RESULTS>

-- 5. Name one input condition under which the three would not be equivalent.
-- NULLs, duplicates, and empty result sets are the usual places equivalence breaks.
-- One situation where the three queries would not be equivalent is if a renter has more than one disputed viewing.
-- The IN and EXISTS versions return each renter only once because they only check whether a disputed viewing exists.
-- However, the CTE + JOIN version returns one row for every matching disputed viewing.
-- This means the same renter could appear multiple times in the results.
-- To make the JOIN version return the same output as the others, DISTINCT would need to be added.
