-- ================================================================================================================
-- Theme                   actor       producer        event       catalog         junction            metric
-- Rental Marketplace      renters     properties      viewings    amenities       listing_amenities   duration_min
-- =================================================================================================================

/*
5.1.1: Who are the people behind the events?
Write a query that joins three tables to display the actor who performed each event,
the producer associated with the event, and the event's date and time.
*/
SELECT
    v.viewing_id,
    v.renter_id,
    r.renter_name,
    v.property_id,
    p.property_label,
    v.scheduled_at,
    v.viewing_status
FROM viewings v
    INNER JOIN renters r
        ON v.renter_id = r.renter_id
    INNER JOIN properties p
        ON v.property_id = p.property_id
ORDER BY v.scheduled_at, v.viewing_id;

/*
5.1.2: How do the producers compare with one another?
Write a self-join to compare records within the producer table.
Use the results to explore whether the producers identified in
Assignment 4 share characteristics with other producers or
whether differences in activity levels may explain their performance.
*/
-- Task 5.1.2
-- Business question: Which amenities are associated with the
-- high-failure properties identified in Assignment 4?

SELECT
    p.property_id,
    p.property_label,
    p.city,
    a.amenity_id,
    a.amenity_name,
    la.verified_on
FROM properties AS p
         JOIN listing_amenities AS la
              ON p.property_id = la.property_id
         JOIN amenities AS a
              ON la.amenity_id = a.amenity_id
WHERE p.property_id IN (1, 3, 5)
ORDER BY
    p.property_id,
    a.amenity_name;

/*
How do the producers compare with one another?
Write a self join to compare records within the producer table.
Use the results to explore whether the producers identified in Assignment 4 share characteristics with other producers
or whether differences in activity levels may explain their performance.
*/
-- Task 5.1.3
-- Business question: How do the high-failure properties identified
-- in Assignment 4 compare with other properties in the same city?
WITH property_activity AS (
    SELECT
        p.property_id,
        p.property_label,
        p.city,
        p.monthly_rent,
        p.is_available,
        COUNT(v.viewing_id) AS viewing_count
    FROM properties AS p
             LEFT JOIN viewings AS v
                       ON p.property_id = v.property_id
    GROUP BY
        p.property_id,
        p.property_label,
        p.city,
        p.monthly_rent,
        p.is_available
)
SELECT
    p1.property_id AS investigated_property_id,
    p1.property_label AS investigated_property,
    p2.property_id AS comparison_property_id,
    p2.property_label AS comparison_property,
    p1.city,

    p1.monthly_rent AS investigated_rent,
    p2.monthly_rent AS comparison_rent,

    ROUND(
            ABS(p1.monthly_rent - p2.monthly_rent),
            2
    ) AS rent_difference,

    p1.viewing_count AS investigated_viewings,
    p2.viewing_count AS comparison_viewings,

    p1.is_available AS investigated_available,
    p2.is_available AS comparison_available

FROM property_activity AS p1

-- Self-join: property_activity is joined to itself
         JOIN property_activity AS p2
              ON p1.city = p2.city
                  AND p1.property_id <> p2.property_id

WHERE p1.property_id IN (1, 3, 5)

ORDER BY
    p1.property_id,
    p2.property_id;