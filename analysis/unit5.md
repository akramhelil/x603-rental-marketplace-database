[## 5.1 Three-Table Join

The three-table join could be used to create a Viewing Activity Report for the property operations team.
Instead of showing only identification numbers, the report would show the renter’s name, the property they planned to
visit, the scheduled date and time, and the outcome of the viewing. This would make it easier for the team to review
viewing activity and investigate cancelled or disputed appointments.

## 5.1.2 Why the Junction Table Matters

The listing_amenities table is important because one property can have several amenities, and the same amenity can be
offered by several properties. It connects each property to amenities such as a Pool, Gym, Parking, or Furnished status
without repeating the same information in multiple places.
Without the junction table, the amenities might be stored as one long list inside each property record or spread across
multiple columns. That would make the information harder to search, update, and compare. Using the junction table, we
found that Property IDs 1 and 5 both have a Pool, while Property IDs 3 and 5 both have a Gym. These similarities give
the team something to investigate, but they do not prove that the amenities caused the disputed viewings.

## 5.2 Part A finding

The LEFT JOIN returns all 15 properties, while the INNER JOIN returns only 13.
Therefore, the inner join excludes two producers: Property IDs 14 and 15.
These properties are missing because they have no matching records in the viewings table.
The data proves that they have no recorded viewing events, but it does not explain why.
They may have low renter interest, listing visibility problems, recent activation, or another issue that requires
further investigation.

## 5.2 Part B finding

The RIGHT JOIN returns the same information as the LEFT JOIN when the table order is reversed.
The verification query confirms this by returning zero differences.
A FULL OUTER JOIN can reveal unmatched records from both sides at the same time.
It can find properties without viewings and, if the database allowed them, viewings without valid properties.
A left or right join preserves only one chosen side, while the full outer join checks both sides in one result.

## 5.2 Part C findings

1. **Which producers were excluded by the inner join?**
   The inner join excluded Property ID 14 and Property ID 15. Both properties exist in the properties table, but neither
   has a matching event in the viewings table.
2. **What does it mean when a producer has no events?**
   In this dataset, having no events means that a property has no recorded viewing appointments. The data confirms that
   Properties 14 and 15 have no viewings, but it does not explain why. They may be new listings, unavailable to renters,
   difficult to find in search results, incorrectly configured, or receiving little renter interest. These are possible
   explanations that require further investigation.
3. **How could an inner-join report give leadership an incomplete picture?**
   A report based only on an inner join would completely remove Properties 14 and 15 because they have no matching
   viewing records. Leadership would see only the 13 properties with activity and might incorrectly assume that every
   property on the platform was included. This would hide properties that may have visibility, availability, or
   activation problems.
4. **Why should leadership identify producers that have never been active?**
   A property with no activity may require a different response from one with frequent disputes. Properties with
   disputes are receiving renter attention but may have quality or operational problems. Properties with no viewings may
   need help becoming visible or active. Identifying both groups gives leadership a more complete view of platform
   performance.
5. **What action could leadership take?**
   Leadership should ask the Property Operations Manager to perform a listing-health review for Property IDs 14 and 15.
   The review should confirm whether each listing is available, visible in renter searches, accurately described, and
   ready to accept viewing requests. If the listings are configured correctly, the team could then investigate pricing,
   location, renter demand, or how recently the properties were listed. The current data proves only that the properties
   have no recorded viewings. It does not establish the reason for that inactivity.

## 5.3.A.4 Explore CROSS JOIN

Business question: When might a Cartesian product be useful, and when could it indicate a query error?
A Cartesian product could be useful for creating a complete property-and-amenity checklist.
The operations team could generate every possible property-and-amenity combination and
then compare it with listing_amenities to see which amenities are assigned or missing.
However, a Cartesian product can indicate an error when it appears unintentionally.
For example, forgetting the join condition between properties and viewings would combine every property with every
viewing,
producing thousands of unrelated rows and incorrect totals. The risk becomes much larger as the tables grow.

## 5.3.B Examine a Query Execution Plan

1. Full Execution Plan

   | QUERY PLAN                                                                                     |
                        |:-----------------------------------------------------------------------------------------------|
   | Sort  \(cost=35.98..36.48 rows=200 width=549\)                                                 |
   | Sort Key: v.scheduled\_at, v.viewing\_id                                                       |
   | -&gt;  Nested Loop  \(cost=12.40..28.34 rows=200 width=549\)                                   |
   | -&gt;  Hash Join  \(cost=12.25..17.80 rows=200 width=291\)                                     |
   | Hash Cond: \(v.renter\_id = r.renter\_id\)                                                     |
   | -&gt;  Seq Scan on viewings v  \(cost=0.00..5.00 rows=200 width=33\)                           |
   | -&gt;  Hash  \(cost=11.00..11.00 rows=100 width=262\)                                          |
   | -&gt;  Seq Scan on renters r  \(cost=0.00..11.00 rows=100 width=262\)                          |
   | -&gt;  Memoize  \(cost=0.15..0.41 rows=1 width=262\)                                           |
   | Cache Key: v.property\_id                                                                      |
   | Cache Mode: logical                                                                            |
   | -&gt;  Index Scan using properties\_pkey on properties p  \(cost=0.14..0.40 rows=1 width=262\) |
   | Index Cond: \(property\_id = v.property\_id\)                                                  |

2. Join Algorithms Used
   PostgreSQL used two different join methods:
    - A Hash Join connected viewings with renters using renter_id.
    - A Nested Loop connected that result with properties using property_id.

3. Why PostgreSQL Selected These Algorithms
    - The Hash Join makes sense because the tables are small and the join uses equality between the renter identifiers.
      PostgreSQL scans the renters table, creates an in-memory hash table, and matches each viewing to the appropriate
      renter.
    - PostgreSQL then uses a Nested Loop to find the property for each viewing. The properties_pkey index allows it to
      locate
      one property efficiently using property_id. Because many viewings refer to the same properties, Memoize saves
      previously
      found property records. If another viewing uses the same property_id, PostgreSQL can reuse the cached result
      instead of
      repeating the index scan.
    - The sequential scans are reasonable for the current dataset because scanning 200 viewing rows and the small renter
      table
      is inexpensive. Using additional indexes may require more work than simply reading these small tables completely.

4. What May Become Less Efficient
    - The viewings scan is most likely to become less efficient as the platform grows because it is already the largest
      table and participates in both joins. If it grows to millions of records, reading the entire table will require
      much more time and storage access.

    - The final sort could also become expensive because PostgreSQL must order all returned rows by viewing date and
      viewing ID. Indexes on viewings.renter_id, viewings.property_id, and possibly (scheduled_at, viewing_id) may
      become more valuable as the event table grows.

5. What changes to the data or database might make another join algorithm more appropriate?

   Changes in table size, indexes, and the number of matching records could lead PostgreSQL to choose a different join
   algorithm. In the current plan, PostgreSQL uses a Nested Loop to connect viewing records to properties. This works
   well because the `properties` table is small, `property_id` is indexed as its primary key, and Memoize allows
   repeated
   property lookups to be reused.

   For example, suppose the `viewings` table grows from 200 rows to several million rows. Adding indexes to the
   foreign-key
   columns could make property and renter lookups more efficient:

   ```sql
      CREATE INDEX idx_viewings_property_id
       ON viewings (property_id);

      CREATE INDEX idx_viewings_renter_id
        ON viewings (renter_id);
   ```
   If a query filters for only a few properties, PostgreSQL could use `idx_viewings_property_id` to find the relevant
   viewing records instead of scanning the entire event table. In that situation, an Index Scan combined with a Nested
   Loop
   may be efficient because only a small number of rows need to be retrieved. If most of the millions of viewing records
   are needed, however, repeatedly using an index may require more work than
   reading the table once. PostgreSQL might instead use a sequential scan and a Hash Join. A Merge Join could become
   appropriate if both tables can provide rows in join-key order, such as through indexes on `viewings.property_id` and
   `properties.property_id`.

   After creating indexes or loading a large amount of new data, the database statistics should be refreshed:

   ```sql
   ANALYZE viewings;
   ANALYZE properties;
   ANALYZE renters;
   ```
   PostgreSQL uses its estimates of row counts, scan costs, and available indexes when selecting an execution plan.
   Updated
   statistics help it compare those choices accurately.

## Reflection

PostgreSQL’s choice of join algorithm can change as the tables grow, indexes are added, or the number of matching
records changes. In the current execution plan, PostgreSQL used a Hash Join between `viewings` and `renters`, followed
by a Nested Loop to connect the results to `properties`. This is reasonable because the dataset is small, the property
primary-key index supports fast lookups, and Memoize can reuse properties referenced by multiple viewings.

If `viewings` grows from 200 rows to millions, repeatedly scanning or sorting the event table will become more
expensive. Indexes on `viewings.renter_id` and `viewings.property_id` could make a Nested Loop more attractive when a
query requests only a small group of renters or properties. For example, an index on `viewings.property_id` could
quickly locate events for Property ID 1 without scanning every viewing.

If a query needs most of the event table, repeated index lookups may cost more than one sequential scan. PostgreSQL
could then prefer a Hash Join. A Merge Join may become practical if both inputs can be read in join-key order through
suitable indexes. Updated statistics also matter because PostgreSQL relies on estimated row counts and costs. After
major data loads or index changes, running `ANALYZE` helps the planner make a better-informed choice.