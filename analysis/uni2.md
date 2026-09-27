
## Task 2.2 — Reasoning for schema choices

This document explains the rationale encoded in the DDL: why each foreign key uses the chosen `ON DELETE` action, and what each `CHECK` constraint prevents. The goal is to make the schema's behavioral decisions explicit so future maintainers understand the real-world events each rule governs and the tradeoffs of alternatives.

---

## The constraints table

> One row per foreign key: **Foreign key** | **ON DELETE** | **Reason (one sentence)**

| **Foreign key** | **ON DELETE** | **Reason** |
|---|---:|---|
| `user_roles.user_id → users.user_id` | **CASCADE** | When a user account is removed, remove their role assignments automatically to avoid orphaned role rows. |
| `user_roles.role_id → roles.role_id` | **CASCADE** | When a role is removed, remove assignments referencing it so user-role mappings remain consistent. |
| `properties.duration_id → rental_durations.duration_id` | **RESTRICT** | Prevent deleting a duration that is in use by properties to avoid leaving properties without a valid minimum-duration rule. |
| `property_owners.property_id → properties.property_id` | **CASCADE** | When a property is removed, remove its ownership mappings automatically to avoid orphaned ownership rows. |
| `property_owners.user_id → users.user_id` | **CASCADE** | When a user is removed, remove their property ownership/management mappings to avoid stale references. |
| `listing_amenities.property_id → properties.property_id` | **CASCADE** | When a property is removed, remove its amenity mappings automatically. |
| `listing_amenities.amenity_id → amenities.amenity_id` | **CASCADE** | When an amenity is removed, remove its property associations automatically. |
| `viewings.property_id → properties.property_id` | **CASCADE** | When a property is removed, remove scheduled viewings for that property to avoid orphaned appointments. |
| `viewings.renter_user_id → users.user_id` | **CASCADE** | When a renter account is removed, remove their viewings to avoid orphaned viewing records. |
| `viewings.created_by_user_id → users.user_id` | **NO ACTION** | Prevent accidental deletion of users who are recorded as creators; require explicit handling to preserve provenance. |
| `viewings.assigned_to_user_id → users.user_id` | **NO ACTION** | Prevent deleting users who are assigned to viewings without first reassigning or clearing the assignment. |
| `viewings.approved_by_user_id → users.user_id` | **NO ACTION** | Preserve approval provenance by preventing deletion of approvers unless approvals are explicitly handled. |
| `viewings.canceled_by_user_id → users.user_id` | **NO ACTION** | Preserve cancellation provenance by preventing deletion of users who canceled viewings unless handled explicitly. |

---

## Expanded rationale for ON DELETE choices

Below we expand on each `ON DELETE` choice and describe the real event it governs, who or what is affected, and what would go wrong under the alternative.

### CASCADE
**Applies to:** `user_roles.user_id`, `user_roles.role_id`, `property_owners.property_id`, `property_owners.user_id`, `listing_amenities.property_id`, `listing_amenities.amenity_id`, `viewings.property_id`, `viewings.renter_user_id`.

**What event it governs:**  
When the *parent* row is deleted (a user, role, property, amenity, or renter), all dependent mapping or child rows are automatically deleted by the database.

**Who/what is affected:**
- Deleting a **user** removes their role assignments and any property ownership mappings; deleting a **renter** removes their viewings.
- Deleting a **role** removes all user-role assignments for that role.
- Deleting a **property** removes its ownership mappings, amenity mappings, and scheduled viewings.
- Deleting an **amenity** removes its associations to properties.

**Why this choice:**  
These child rows are purely associative or dependent: they have no independent meaning without the parent. Automatically removing them prevents orphaned rows and keeps referential integrity without manual cleanup.

**What would go wrong under the alternative (NO ACTION / RESTRICT):**
- If we used `NO ACTION` or `RESTRICT`, attempts to delete a parent would fail until all dependent rows were removed or updated. That forces manual cleanup and can be useful when you want to force explicit decisions, but it also increases the risk of leaving stale parent rows because cleanup is tedious. For example, deleting a property would require first deleting viewings and ownership rows in the application, which is extra work and error-prone.
- If we used `SET NULL` instead, the child rows would remain but lose their link to the parent, producing orphaned or semantically meaningless rows (e.g., a viewing with no property).

### RESTRICT
**Applies to:** `properties.duration_id → rental_durations.duration_id`.

**What event it governs:**  
When someone attempts to delete a `rental_durations` row that is referenced by one or more `properties`, the delete is blocked.

**Who/what is affected:**
- The `rental_durations` row cannot be removed while any property references it. The properties remain unchanged.

**Why this choice:**  
A duration is reference data that gives properties a required business rule (minimum months). Deleting a duration that is in use would leave properties without a valid minimum-duration rule. `RESTRICT` forces an explicit decision: either reassign properties to another duration or remove the properties first.

**What would go wrong under the alternative (CASCADE or SET NULL):**
- **CASCADE:** Deleting a duration would delete all properties that reference it — a destructive and likely unacceptable side effect.
- **SET NULL:** Properties would lose their `duration_id`, leaving them in an invalid or ambiguous state unless the application can handle null durations; this undermines the invariant that properties must have a minimum rental rule.

### NO ACTION (default)
**Applies to:** `viewings.created_by_user_id`, `viewings.assigned_to_user_id`, `viewings.approved_by_user_id`, `viewings.canceled_by_user_id`.

**What event it governs:**  
The database will prevent deletion of a referenced user if any viewing row still references them (the delete will fail unless the referencing rows are removed or updated first).

**Who/what is affected:**
- Users who appear in provenance fields (creator, assignee, approver, canceler) cannot be deleted until their references are explicitly handled (reassign, nullify, or delete the viewings).

**Why this choice:**  
Provenance fields are audit data: they record who performed important actions. Automatically deleting or nulling these references would lose auditability. `NO ACTION` forces the application or DBA to make an explicit decision (reassign, anonymize, or remove the viewing) before deleting the user.

**What would go wrong under the alternative (CASCADE or SET NULL):**
- **CASCADE:** Deleting a user would delete viewings they created/approved/assigned/canceled — losing historical records and potentially removing viewings that should remain.
- **SET NULL:** The provenance would be lost (approvals and assignments would no longer show who performed them), reducing auditability and complicating dispute resolution.

---

## The CHECK constraints

Below are the `CHECK` constraints present in the schema and an explanation of the invalid states they prevent and how those states could otherwise arise.

### 1. `rental_durations.min_months INT NOT NULL CHECK (min_months >= 0)`
**Invalid state prevented:** Negative minimum-month values (e.g., `-6`) or nulls (null prevented by NOT NULL).  
**How that state could arise:** Bad data entry, a faulty import script, or a bug in business logic that computes durations incorrectly. Allowing negative durations would make no business sense and could break UI logic and eligibility checks.

---

### 2. `properties.bedrooms INT CHECK (bedrooms >= 0)`
**Invalid state prevented:** Negative bedroom counts (e.g., `-1`).  
**How that state could arise:** Typo during manual entry, incorrect mapping from an external feed, or a bug in a transformation script. Negative bedrooms are nonsensical and would break search filters and aggregations.

---

### 3. `properties.bathrooms INT CHECK (bathrooms >= 0)`
**Invalid state prevented:** Negative bathroom counts.  
**How that state could arise:** Same as bedrooms — import errors or bad UI validation. Prevents nonsensical listings and incorrect analytics.

---

### 4. `properties.size INT CHECK (size > 0)`
**Invalid state prevented:** Zero or negative property size (e.g., `0` or `-100`).  
**How that state could arise:** Missing data mapped to zero, unit conversion bugs, or bad imports. A size of zero or negative is invalid for most property listings and would break area-based calculations and filters.

---

### 5. `property_owners.role VARCHAR(20) CHECK (role IN ('owner','manager','agent'))`
**Invalid state prevented:** Arbitrary or misspelled role values (e.g., `Owner`, `landlord`, `co-owner`, `null`).  
**How that state could arise:** Free-text entry, inconsistent external data, or a bug that writes an unexpected role string. This CHECK ensures the application and DB agree on the limited set of permission-bearing roles used for authorization decisions.

---

### 6. Composite primary keys on junction tables (implicit constraint)
**Invalid state prevented:** Duplicate mappings such as the same `(property_id, amenity_id)` or `(property_id, user_id)` inserted twice.  
**How that state could arise:** Race conditions in concurrent inserts, repeated imports, or idempotency bugs in the application. The composite PK enforces uniqueness at the DB level.

---

### 7. `viewings.status` ENUM (`requested`, `scheduled`, `approved`, `completed`, `canceled`, `no_show`)
**Invalid state prevented:** Arbitrary or misspelled status values (e.g., `approve`, `in_progress`, `pending`).  
**How that state could arise:** Application bugs, inconsistent client versions, or bad imports. Using an ENUM ensures the workflow state machine remains consistent and predictable.

---

## Practical notes about enforcement and alternatives

- **Application vs DB enforcement:**
    - The schema enforces structural invariants (FKs, CHECKs, ENUMs, composite PKs). Complex authorization rules (e.g., "only property_owners with role `agent|owner|manager` may approve viewings") are enforced primarily in the application layer; the DDL includes an optional trigger to enforce the approver rule as a last-resort DB invariant.
    - For provenance fields we intentionally chose `NO ACTION` to force explicit handling before deleting users; this keeps audit trails intact unless the application intentionally reassigns or anonymizes records.

- **Tradeoffs considered:**
    - **CASCADE** simplifies cleanup for purely associative data (mappings, junctions) but is destructive if applied to audit or primary domain data.
    - **RESTRICT** protects reference data that should not be removed while in use.
    - **NO ACTION** preserves provenance and forces explicit decisions, which is important for auditability and legal/operational traceability.

- **Operational guidance:**
    - When removing a user who appears in provenance fields, the application should either (a) reassign the provenance to another user, (b) anonymize the user and keep the reference, or (c) remove or archive the dependent viewings after business review.
    - When changing or removing a `rental_durations` row, first reassign properties to a different duration or archive the properties; do not delete durations in active use.

---

## Summary

The schema choices balance automated cleanup for purely dependent mappings (CASCADE) with protection of reference data (RESTRICT) and preservation of audit provenance (NO ACTION). CHECK constraints prevent nonsensical numeric and categorical values that would otherwise arise from imports, UI bugs, or race conditions. Together these rules make the database a reliable source of truth while leaving complex authorization semantics to the application layer (with optional DB triggers for critical invariants).
