-- =================================================================
-- EX 603 Assignment 2 — schema.sql
-- Theme: Rental Marketplace
-- Author: Akram Helil
-- Target: PostgreSQL V15
-- =================================================================
-- Reset script: drop schema objects in reverse creation order
BEGIN;

-- 1) Remove trigger on viewings if it exists (guarded)
DO $$
    BEGIN
        IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'viewings') THEN
            IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_check_approver') THEN
                EXECUTE 'DROP TRIGGER IF EXISTS trg_check_approver ON viewings';
            END IF;
        END IF;
    END
$$;

-- -- 2) Drop trigger function (if exists)
-- DROP FUNCTION IF EXISTS fn_check_approver_is_property_manager() CASCADE;

-- 3) Drop viewings table and dependent type
DROP TABLE IF EXISTS viewings CASCADE;
DROP TYPE IF EXISTS viewing_status;

-- 4) Drop listing_amenities and amenities
DROP TABLE IF EXISTS listing_amenities CASCADE;
DROP TABLE IF EXISTS amenities CASCADE;

-- 5) Drop property_owners and properties
DROP TABLE IF EXISTS property_owners CASCADE;
DROP TABLE IF EXISTS properties CASCADE;

-- 6) Drop rental_durations
DROP TABLE IF EXISTS rental_durations CASCADE;

-- 7) Drop user_roles, roles, users
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

COMMIT;

-- Rental Marketplace schema for Postgres
-- Apply on a fresh database. All statements are ordered to satisfy FK dependencies.
BEGIN;

-- 1. Roles (no dependencies)
CREATE TABLE roles (
  role_id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
);

-- 2. Users (no dependencies)
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(30),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ
);

-- 3. user_roles (depends on users, roles)
CREATE TABLE user_roles (
  user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id INT NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- 4. rental_durations (no FK dependencies)
CREATE TABLE rental_durations (
  duration_id SERIAL PRIMARY KEY,
  min_months INT NOT NULL CHECK (min_months >= 0),
  label VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. properties (depends on rental_durations)
CREATE TABLE properties (
  property_id SERIAL PRIMARY KEY,
  duration_id INT NOT NULL REFERENCES rental_durations(duration_id) ON DELETE RESTRICT,
  title VARCHAR(255),
  description TEXT,
  address TEXT,
  property_type VARCHAR(50),
  price DECIMAL(12,2),
  bedrooms INT CHECK (bedrooms >= 0),
  bathrooms INT CHECK (bathrooms >= 0),
  size INT CHECK (size > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ
);

-- 6. property_owners (depends on properties, users)
CREATE TABLE property_owners (
  property_id INT NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
  user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL CHECK (role IN ('owner','manager','agent')),
  is_primary_contact BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (property_id, user_id)
);

-- 7. amenities (no FK dependencies)
CREATE TABLE amenities (
  amenity_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT
);

-- 8. listing_amenities (depends on properties, amenities)
CREATE TABLE listing_amenities (
  property_id INT NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
  amenity_id INT NOT NULL REFERENCES amenities(amenity_id) ON DELETE CASCADE,
  PRIMARY KEY (property_id, amenity_id)
);

-- 9. viewing_status type (ENUM) — create before viewings
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'viewing_status') THEN
    CREATE TYPE viewing_status AS ENUM ('requested','scheduled','approved','completed','canceled','no_show');
  END IF;
END$$;

-- 10. viewings (depends on properties, users)
CREATE TABLE viewings (
  viewing_id SERIAL PRIMARY KEY,
  property_id INT NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
  renter_user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  created_by_user_id INT NOT NULL REFERENCES users(user_id),
  assigned_to_user_id INT REFERENCES users(user_id),
  approved_by_user_id INT REFERENCES users(user_id),
  canceled_by_user_id INT REFERENCES users(user_id),
  status viewing_status NOT NULL DEFAULT 'requested',
  viewing_date TIMESTAMPTZ NOT NULL,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ
);

-- 11. Indexes for common queries
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_viewings_property_date ON viewings(property_id, viewing_date);
CREATE INDEX idx_viewings_renter ON viewings(renter_user_id);
CREATE INDEX idx_properties_search ON properties(price, bedrooms, bathrooms);

-- -- 12. Trigger function to enforce approver authorization (optional but recommended)
-- -- This function ensures approved_by_user_id, if set, is a property owner/manager/agent for the property.
-- CREATE OR REPLACE FUNCTION fn_check_approver_is_property_manager()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   IF NEW.approved_by_user_id IS NOT NULL THEN
--     IF NOT EXISTS (
--       SELECT 1 FROM property_owners po
--       WHERE po.property_id = NEW.property_id
--         AND po.user_id = NEW.approved_by_user_id
--         AND po.role IN ('owner','manager','agent')
--     ) THEN
--       RAISE EXCEPTION 'User % is not authorized to approve viewings for property %', NEW.approved_by_user_id, NEW.property_id;
--     END IF;
--   END IF;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trg_check_approver
-- BEFORE INSERT OR UPDATE ON viewings
-- FOR EACH ROW
-- EXECUTE FUNCTION fn_check_approver_is_property_manager();

COMMIT;
