# Task 1.3: Integrity Constraints

This section defines the integrity constraints used to maintain data quality and enforce business rules within the Rental Marketplace database. 
For each foreign key, the selected `ON DELETE` behavior is specified and justified.

---

# 1. Primary Key Constraints

Primary keys uniquely identify each record in a table and prevent duplicate rows.

| Table | Primary Key |
| --------- | ------------ |
| RENTERS | renter_id |
| PROPERTIES | peopery_id |
| VIEWINGS | viewing_id |
| AMENITIES | amenity_id |
| DURATION_MIN | duration_min_id |
| LISTING_AMENITIES | (viewing_id, amenity_id) |

### Justification

Each entity requires a stable and unique identifier to support relationships and efficient querying. Integer-based surrogate keys were chosen because they are compact, immutable, and independent of business data such as email addresses or property titles.

---

# 2. Foreign Key Constraints

## 2.1 VIEWINGS → RENTERS

```sql
FOREIGN KEY (renter_id)
REFERENCES RENTERS(renter_id)
ON DELETE CASCADE
```

### Justification

A viewing cannot exist without the renter who scheduled it. If a renter is removed from the platform, any associated viewing records become invalid and should be deleted automatically.

### Business Rule

Every viewing must belong to exactly one renter.

---

## 2.2 VIEWINGS → PROPERTIES

```sql
FOREIGN KEY (property_id)
REFERENCES PROPERTIES(peopery_id)
ON DELETE CASCADE
```

### Justification

Viewings are tied directly to a property listing. If the property is removed from the marketplace, maintaining viewing records would create orphaned data with no associated property.

### Business Rule

Every viewing must be associated with exactly one property.

---

## 2.3 PROPERTIES → DURATION_MIN

```sql
FOREIGN KEY (duration_min_id)
REFERENCES DURATION_MIN(duration_min_id)
ON DELETE RESTRICT
```

### Justification

Duration requirements are reference data that define rental eligibility rules. A duration record should not be removed while active properties still depend on it. Restricting deletion prevents properties from referencing non-existent duration requirements.

### Business Rule

Every property must reference a valid duration requirement.

---

## 2.4 LISTING_AMENITIES → VIEWINGS

```sql
FOREIGN KEY (viewing_id)
REFERENCES VIEWINGS(viewing_id)
ON DELETE CASCADE
```

### Justification

According to the current ERD, `LISTING_AMENITIES` references `VIEWINGS` through `viewing_id`. If a viewing is deleted, associated amenity assignments should also be removed to avoid orphaned relationship records.

### Business Rule

Every listing_amenities record must reference an existing viewing.

---

## 2.5 LISTING_AMENITIES → AMENITIES

```sql
FOREIGN KEY (amenity_id)
REFERENCES AMENITIES(amenity_id)
ON DELETE RESTRICT
```

### Justification

Amenities represent reusable lookup data shared throughout the system. Deleting an amenity that is already assigned could break existing relationships and create inconsistency. Restricting deletion ensures administrators explicitly remove all references before deleting an amenity.

### Business Rule

Every listing_amenities record must reference a valid amenity.

---

## 2.6 DURATION_MIN → VIEWINGS

```sql
FOREIGN KEY (viewing_id)
REFERENCES VIEWINGS(viewing_id)
ON DELETE CASCADE
```

### Justification

The current ERD specifies that `DURATION_MIN` references `VIEWINGS`. If the referenced viewing is deleted, the dependent duration record should also be removed to prevent invalid references.

### Business Rule

Every duration_min record must reference an existing viewing.

---

# 3. Uniqueness Constraints

## RENTERS Email

```sql
UNIQUE(email)
```

### Justification

Each renter account should be uniquely identifiable by email address. This prevents duplicate registrations and supports authentication and communication processes.

---

# 4. NOT NULL Constraints

The following attributes should not allow null values.

## RENTERS

```sql
renter_id
first_name
last_name
email
created_at
```

### Justification

These fields are required to identify and contact renters.

---

## PROPERTIES

```sql
peopery_id
duration_min_id
title
address
property_type
price
created_at
```

### Justification

These fields are essential for representing a valid property listing.

---

## VIEWINGS

```sql
viewing_id
property_id
renter_id
status
viewing_date
created_at
```

### Justification

A viewing cannot exist without a renter, property, status, and scheduled date.

---

## AMENITIES

```sql
amenity_id
name
```

### Justification

Amenities must have a unique identifier and a descriptive name.

---

## DURATION_MIN

```sql
duration_min_id
viewing_id
```

### Justification

Every duration record must be uniquely identifiable and linked to a valid viewing according to the ERD.

---

# 5. Domain Constraints

## Property Attributes

```sql
CHECK (bedrooms >= 0)

CHECK (bathrooms >= 0)

CHECK (size > 0)
```

### Justification

Properties cannot have negative room counts or a non-positive size.

---

## Viewing Status

```sql
CHECK (
    status IN (
        'Scheduled',
        'Completed',
        'Cancelled'
    )
)
```

### Justification

Restricts viewing status values to valid business states and prevents inconsistent data entry.

---

# 6. Composite Key Constraint

## LISTING_AMENITIES

```sql
PRIMARY KEY (viewing_id, amenity_id)
```

### Justification

This composite key prevents duplicate associations between the same viewing and amenity while still allowing an amenity to be associated with multiple records.

---

# Constraint Summary

| Constraint Type | Purpose |
| --------------- | --------- |
| Primary Keys | Uniquely identify records |
| Foreign Keys | Maintain referential integrity |
| ON DELETE CASCADE | Remove dependent records automatically |
| ON DELETE RESTRICT | Prevent deletion of referenced data |
| UNIQUE | Prevent duplicate renter emails |
| NOT NULL | Ensure required data is always present |
| CHECK | Enforce valid business values |
| Composite Keys | Prevent duplicate relationship records |
