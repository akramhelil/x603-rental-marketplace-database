
# Analysis

The rental marketplace was designed around six core entities: renters, properties, viewings, amenities, listing_amenities, and duration_min. These entities represent the essential business concepts required to support property discovery and viewing management while maintaining a normalized relational database structure.

Surrogate integer primary keys were chosen for all major entities. Using integer identifiers simplifies joins, improves index performance, and provides stable identifiers that are independent of business attributes. For example, renter emails may change over time, but renter_id remains constant. Similarly, property details such as titles or addresses may be updated without affecting the primary key.

The relationship between properties and amenities was modeled as a many-to-many relationship using the listing_amenities junction table. A property can have multiple amenities, such as parking, WiFi, and laundry facilities, while the same amenity may be offered by many properties. Using a junction table avoids data duplication and supports efficient querying of amenity information. A composite primary key consisting of property_id and amenity_id ensures that the same amenity cannot be assigned to the same property more than once.

Foreign key constraints were implemented to preserve referential integrity. The viewings table references both renters and properties because every viewing must be associated with a valid renter and a valid property. The ON DELETE CASCADE behavior was selected for these relationships because viewings have no business value once the associated renter or property no longer exists. Cascading deletions simplify database maintenance and prevent orphaned records.

In contrast, the relationship between properties and duration_min uses ON DELETE RESTRICT. Duration rules represent reference data that may be shared across multiple properties. Allowing those records to be deleted could invalidate existing property references and create data integrity issues. Restricting deletion ensures that duration rules remain available while they are still in use.

Several validation rules were implemented directly within the database schema rather than relying solely on application code. CHECK constraints were added to enforce positive property sizes and valid bedroom and bathroom counts. These rules prevent invalid data from entering the system regardless of the source application. Similarly, viewing status values are restricted to a defined set of permitted states to maintain consistency across all records.

Finally, a UNIQUE constraint on renter email addresses prevents duplicate accounts and supports reliable identification of users. By enforcing essential business rules and data integrity requirements at the database level, the model reduces the likelihood of inconsistent data and provides a solid foundation for future system enhancements.
