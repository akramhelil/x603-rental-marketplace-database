# Relation Schemas

## Overview

The Rental Marketplace database consists of six relations:

1. RENTERS
2. PROPERTIES
3. VIEWINGS
4. AMENITIES
5. LISTING_AMENITIES
6. DURATION_MIN

Each relation is described below with its attributes, domains, primary keys, and foreign keys.

---

# 1. RENTERS

## Relation Schema

```text
RENTERS(
    renter_id,
    first_name,
    last_name,
    email,
    phone,
    created_at
)
```

## Attributes and Domains

| Attribute | Domain |
| ------------ | ---------- |
| renter_id | INTEGER |
| first_name | VARCHAR |
| last_name | VARCHAR |
| email | VARCHAR |
| phone | VARCHAR |
| created_at | DATE |

## Primary Key

```text
PK(renter_id)
```

---

# 2. PROPERTIES

## Relation Schema

```text
PROPERTIES(
    peopery_id,
    duration_min_id,
    title,
    desciption,
    address,
    property_type,
    price,
    bedrooms,
    bathrooms,
    size,
    created_at
)
```

## Attributes and Domains

| Attribute | Domain |
| ------------ | ---------- |
| peopery_id | INTEGER |
| duration_min_id | INTEGER |
| title | VARCHAR |
| desciption | VARCHAR |
| address | VARCHAR |
| property_type | VARCHAR |
| price | VARCHAR |
| bedrooms | INTEGER |
| bathrooms | INTEGER |
| size | INTEGER |
| created_at | DATE |

## Primary Key

```text
PK(peopery_id)
```

## Foreign Keys

```text
FK(duration_min_id)
    → DURATION_MIN(duration_min_id)
```

---

# 3. VIEWINGS

## Relation Schema

```text
VIEWINGS(
    viewing_id,
    property_id,
    renter_id,
    status,
    viewing_date,
    created_at
)
```

## Attributes and Domains

| Attribute | Domain |
| ------------ | ---------- |
| viewing_id | INTEGER |
| property_id | INTEGER |
| renter_id | INTEGER |
| status | VARCHAR |
| viewing_date | DATE |
| created_at | DATE |

## Primary Key

```text
PK(viewing_id)
```

## Foreign Keys

```text
FK(property_id)
    → PROPERTIES(peopery_id)

FK(renter_id)
    → RENTERS(renter_id)
```

---

# 4. AMENITIES

## Relation Schema

```text
AMENITIES(
    amenity_id,
    name,
    description
)
```

## Attributes and Domains

| Attribute | Domain |
| ------------ | ---------- |
| amenity_id | INTEGER |
| name | VARCHAR |
| description | VARCHAR |

## Primary Key

```text
PK(amenity_id)
```

---

# 5. LISTING_AMENITIES

## Relation Schema

```text
LISTING_AMENITIES(
    viewing_id,
    amenity_id
)
```

## Attributes and Domains

| Attribute | Domain |
| ------------ | ---------- |
| viewing_id | INTEGER |
| amenity_id | INTEGER |

## Primary Key

```text
PK(viewing_id, amenity_id)
```

## Foreign Keys

```text
FK(viewing_id)
    → VIEWINGS(viewing_id)

FK(amenity_id)
    → AMENITIES(amenity_id)
```

---

# 6. DURATION_MIN

## Relation Schema

```text
DURATION_MIN(
    duration_min_id,
    viewing_id
)
```

## Attributes and Domains

| Attribute | Domain |
| ------------ | ---------- |
| duration_min_id | INTEGER |
| viewing_id | INTEGER |

## Primary Key

```text
PK(duration_min_id)
```

## Foreign Keys

```text
FK(viewing_id)
    → VIEWINGS(viewing_id)
```

---

# Relationship Summary

| Parent Relation | Child Relation | Cardinality |
| ---------------- | --------------- | ------------- |
| RENTERS | VIEWINGS | 1 : M |
| PROPERTIES | VIEWINGS | 1 : M |
| PROPERTIES | LISTING_AMENITIES | 1 : M |
| AMENITIES | LISTING_AMENITIES | 1 : M |
| DURATION_MIN | PROPERTIES | 1 : M |

---

# Relational Model

```text
RENTERS(
    renter_id PK,
    first_name,
    last_name,
    email,
    phone,
    created_at
)

PROPERTIES(
    peopery_id PK,
    duration_min_id FK,
    title,
    desciption,
    address,
    property_type,
    price,
    bedrooms,
    bathrooms,
    size,
    created_at
)

VIEWINGS(
    viewing_id PK,
    property_id FK,
    renter_id FK,
    status,
    viewing_date,
    created_at
)

AMENITIES(
    amenity_id PK,
    name,
    description
)

LISTING_AMENITIES(
    viewing_id FK,
    amenity_id FK,
    PK(viewing_id, amenity_id)
)

DURATION_MIN(
    duration_min_id PK,
    viewing_id FK
)
```
