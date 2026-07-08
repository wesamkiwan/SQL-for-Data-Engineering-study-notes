-- =============================================================================
-- NorthStar Retail — Schema
-- =============================================================================
-- Creates a dedicated schema so this never collides with anything else in
-- your database, then creates all six tables used throughout the repo.
-- Safe to re-run: it drops the schema first if it already exists.
-- =============================================================================

DROP SCHEMA IF EXISTS northstar CASCADE;
CREATE SCHEMA northstar;
SET search_path TO northstar;

-- Customers: the people who place orders.
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    country         VARCHAR(56)  NOT NULL,
    signup_date     DATE         NOT NULL,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Employees: sales reps and their managers. Self-referencing FK on purpose —
-- this is what powers the recursive CTE / org-chart examples later.
CREATE TABLE employees (
    employee_id     SERIAL PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    department      VARCHAR(50)  NOT NULL,
    manager_id      INTEGER      REFERENCES employees(employee_id),
    hire_date       DATE         NOT NULL
);

-- Products: what NorthStar Retail sells.
CREATE TABLE products (
    product_id      SERIAL PRIMARY KEY,
    product_name    VARCHAR(100)   NOT NULL,
    category        VARCHAR(50)    NOT NULL,
    unit_price      NUMERIC(10,2)  NOT NULL CHECK (unit_price >= 0),
    cost_price      NUMERIC(10,2)  NOT NULL CHECK (cost_price >= 0),
    is_discontinued BOOLEAN        NOT NULL DEFAULT FALSE
);

-- Orders: one row per order placed. Note there is no total_amount column —
-- that's derived from order_items, which is exactly the point of the
-- normalization lessons in Part 3.
CREATE TABLE orders (
    order_id         SERIAL PRIMARY KEY,
    customer_id      INTEGER      NOT NULL REFERENCES customers(customer_id),
    employee_id      INTEGER      REFERENCES employees(employee_id),
    order_date       DATE         NOT NULL,
    order_status     VARCHAR(20)  NOT NULL
                        CHECK (order_status IN ('placed','shipped','delivered','cancelled','returned')),
    shipping_country VARCHAR(56)  NOT NULL
);

-- Order items: the line items within an order. This is where quantity and
-- the price *at time of sale* live (prices in `products` can change later —
-- another deliberate modeling decision you'll learn to spot).
CREATE TABLE order_items (
    order_item_id   SERIAL PRIMARY KEY,
    order_id        INTEGER       NOT NULL REFERENCES orders(order_id),
    product_id      INTEGER       NOT NULL REFERENCES products(product_id),
    quantity        INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

-- Payments: one or more payment attempts per order (failed attempts are
-- intentional — they show up in the data quality and reconciliation lessons).
CREATE TABLE payments (
    payment_id      SERIAL PRIMARY KEY,
    order_id        INTEGER       NOT NULL REFERENCES orders(order_id),
    payment_date    DATE          NOT NULL,
    amount          NUMERIC(10,2) NOT NULL,
    payment_method  VARCHAR(20)   NOT NULL
                        CHECK (payment_method IN ('credit_card','debit_card','paypal','bank_transfer','gift_card')),
    payment_status  VARCHAR(20)   NOT NULL
                        CHECK (payment_status IN ('success','failed','refunded','pending'))
);

-- Helpful indexes on foreign keys (Postgres does NOT create these
-- automatically — you'll learn exactly why this matters in
-- 05-performance-and-optimization/02-indexing-strategies).
CREATE INDEX idx_orders_customer_id     ON orders(customer_id);
CREATE INDEX idx_orders_employee_id     ON orders(employee_id);
CREATE INDEX idx_order_items_order_id   ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id      ON payments(order_id);

COMMENT ON SCHEMA northstar IS 'Sample e-commerce dataset used throughout SQL for Data Engineers';
