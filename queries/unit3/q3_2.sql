/*
Task 3.2: Find the bug
The dashboard query contains two SQL problems.
Your goal is to reproduce each problem, show what goes wrong, and then fix it.
================================================================================================================
Theme                   actor       producer        event       catalog         junction            metric
Rental Marketplace      renters     properties      viewings    amenities       listing_amenities   duration_min
=================================================================================================================
 */
/*
===================================
Part A: The rows that vanished
===================================
SQL use three-valued logic: TRUE, FALSE, and UNKNOWN.
A comparison against NULL yields UNKNOWN, and a WHERE clause keeps only rows where the predicate is TRUE.
A filter that looks exhaustive can therefore discard rows silently, without an error and without warning anyone.

Reproduce it:
Pick a nullable column on your event or producer table.
If the dataset has no NULLs in it, insert a few deliberately and say that you did.
— for example, WHERE status != 'completed' — and record the row count it returns.
*/
-- 22 Counts
SELECT COUNT(*) AS no_show_count
FROM viewings
WHERE no_show_reason != 'Renter no show';
-- there are many roes have null on no_show_reason,
-- many of the rows attended and disputed viewings have a NULL reason.
-- Null != 'Renter no show' does not evaluate as TRUE,
-- it evaluates as Unknown, so these rows are excluded from the result

/*
Write a query with a negation or inequality predicate on that column
*/
-- 188 counts
SELECT COUNT(*) AS no_show_count
FROM viewings
WHERE no_show_reason != 'Renter no show'
OR no_show_reason IS NULL;

--  Second Options: 188 counts
SELECT  COUNT(*) AS no_show_count
FROM viewings
WHERE no_show_reason IS DISTINCT FROM 'Renter no show';

/*
Write a second query counting the rows the first one silently omitted
and show that the two counts do not sum to the table total.
Repair the first query using an explicit IS NULL condition or COALESCE,
so it returns what you intended.
 */
-- Original query count: 22
SELECT COUNT(*) AS not_renter_no_show
FROM viewings
WHERE no_show_reason != 'Renter no show';

-- Show the Totals: 200
SELECT COUNT(*) AS total_viewings
FROM viewings;
-- No Show Reason NULL: 166
SELECT COUNT(*)
FROM viewings
WHERE no_show_reason IS NULL;

-- the problem renter no show + null = 22 + 166 = 188.
-- The total is 200, so 12 rows are missing from the original query.
SELECT (SELECT COUNT(*) FROM viewings
            WHERE no_show_reason != 'Renter no show') AS first_count,
        (SELECT COUNT(*) FROM viewings
            WHERE no_show_reason IS NULL) AS omitted_count,
       COUNT(*)  AS total_viewings
FROM viewings;

-- Correct Query:
SELECT COUNT(*) AS corrected_count
FROM viewings
WHERE no_show_reason != 'Renter no show'
   OR no_show_reason IS NULL;
-- OR
SELECT COUNT(*) AS corrected_count
FROM viewings
WHERE COALESCE( no_show_reason, 'Unknown')
          != 'Renter no show';

/*
===================================
Part B: The alias that did not exist yet
===================================
SQL is written FROM, WHERE, SELECT, ORDER BY, but it is not evaluated in that order.
    Produce two correct rewrites:
    one repeating the expression in WHERE.
    one wrapping the query in a CTE or subquery so the alias becomes a real column.
 */

-- Write a query defining an alias in SELECT and referencing that alias in WHERE.
-- Capture the error message verbatim.
SELECT
    property_id,
    property_label,
    monthly_rent,
    CASE
        WHEN monthly_rent < 1000 THEN 'Budget'
        WHEN monthly_rent < 2500 THEN 'Mid-Range'
        ELSE 'Premium'
        END AS rent_category
FROM properties
WHERE rent_category = 'Premium';

-- Corrected Query 1: Repeating the expression in WHERE
SELECT
    property_id,
    property_label,
    monthly_rent,
    CASE
        WHEN monthly_rent < 1000 THEN 'Budget'
        WHEN monthly_rent < 2500 THEN 'Mid-Range'
        ELSE 'Premium'
        END AS rent_category
FROM properties
WHERE
    CASE
        WHEN monthly_rent < 1000 THEN 'Budget'
        WHEN monthly_rent < 2500 THEN 'Mid-Range'
        ELSE 'Premium'
        END = 'Mid-Range'; -- Change this value to 'Premium' or 'Budget' to see different results

-- Corrected Query 2: Wrapping the query in a CTE
WITH categorized_properties AS (
    SELECT
        property_id,
        property_label,
        monthly_rent,
        CASE
            WHEN monthly_rent < 1000 THEN 'Budget'
            WHEN monthly_rent < 2500 THEN 'Mid-Range'
            ELSE 'Premium'
            END AS rent_category
    FROM properties
)
SELECT *
FROM categorized_properties
WHERE rent_category = 'Mid-Range'; -- Change this value to 'Premium' or 'Budget' to see different results

