-- =============================================================================
-- NorthStar Retail — Seed Data
-- =============================================================================
-- Generates reproducible sample data using generate_series() + setseed().
-- Everyone who runs this script gets the same rows, so your query results
-- will match the numbers shown in every lesson.
--
-- Why generate data with SQL instead of shipping a giant CSV?
-- Because reading this script IS your first real data engineering lesson:
-- generating synthetic test data with SQL is a genuine, common task
-- (seeding staging environments, load testing, demoing pipelines).
-- =============================================================================

SET search_path TO northstar;

-- Fix the random seed so random() is reproducible across everyone's machine.
SELECT setseed(0.4242);

-- -----------------------------------------------------------------------------
-- Employees — hand-authored so the org chart is clean and easy to reason
-- about (1 executive -> 2 managers -> 6 reps, plus a small support team).
-- -----------------------------------------------------------------------------
INSERT INTO employees (employee_id, full_name, department, manager_id, hire_date) VALUES
 (1,  'Alexandra Chen',   'Executive', NULL, '2018-01-15'),
 (2,  'Marcus Webb',      'Sales',     1,    '2018-06-01'),
 (3,  'Priya Natarajan',  'Sales',     1,    '2019-02-11'),
 (4,  'Daniel Osei',      'Sales',     2,    '2019-09-23'),
 (5,  'Laura Fitzgerald', 'Sales',     2,    '2020-01-13'),
 (6,  'Tomas Novak',      'Sales',     2,    '2020-07-06'),
 (7,  'Hana Suzuki',      'Sales',     3,    '2020-03-02'),
 (8,  'Omar Haddad',      'Sales',     3,    '2020-11-19'),
 (9,  'Chloe Dubois',     'Sales',     3,    '2021-04-08'),
 (10, 'Ben Whitfield',    'Support',   1,    '2019-05-27'),
 (11, 'Ingrid Larsson',   'Support',   10,   '2021-02-14'),
 (12, 'Ravi Deshpande',   'Support',   10,   '2022-01-10');
SELECT setval('employees_employee_id_seq', 12);

-- -----------------------------------------------------------------------------
-- Customers — 200 rows generated from name/country arrays.
-- -----------------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, country, signup_date, is_active)
SELECT
    first_names[1 + floor(random() * array_length(first_names, 1))::int],
    last_names[1 + floor(random() * array_length(last_names, 1))::int],
    lower(
        first_names[1 + floor(random() * array_length(first_names, 1))::int] || '.' ||
        last_names[1 + floor(random() * array_length(last_names, 1))::int] || n || '@example.com'
    ),
    countries[1 + floor(random() * array_length(countries, 1))::int],
    (DATE '2022-01-01' + floor(random() * 1000)::int),
    (random() < 0.9)
FROM generate_series(1, 200) AS n,
LATERAL (SELECT ARRAY[
    'Emma','Liam','Olivia','Noah','Ava','Ethan','Sophia','Mason','Isabella','Lucas',
    'Mia','Elijah','Amelia','James','Harper','Benjamin','Evelyn','Henry','Abigail','Alexander',
    'Grace','Sebastian','Chloe','Jack','Zoey','Owen','Lily','Daniel','Ella','Matthew'
] AS first_names) fn,
LATERAL (SELECT ARRAY[
    'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez',
    'Hernandez','Lopez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin','Lee',
    'Perez','Thompson','White','Harris','Sanchez','Clark','Ramirez','Lewis','Robinson','Walker'
] AS last_names) ln,
LATERAL (SELECT ARRAY[
    'United States','Canada','United Kingdom','Germany','France',
    'Australia','Netherlands','Sweden','Ireland','Spain'
] AS countries) c;

-- -----------------------------------------------------------------------------
-- Products — 40 rows spread evenly across 6 categories.
-- -----------------------------------------------------------------------------
INSERT INTO products (product_name, category, unit_price, cost_price, is_discontinued)
SELECT
    adjectives[1 + floor(random() * array_length(adjectives, 1))::int] || ' ' ||
        nouns[1 + floor(random() * array_length(nouns, 1))::int] || ' #' || n,
    categories[1 + ((n - 1) % array_length(categories, 1))],
    price,
    round(price * (0.4 + random() * 0.2), 2),
    (random() < 0.08)
FROM generate_series(1, 40) AS n,
LATERAL (SELECT ARRAY[
    'Electronics','Home & Kitchen','Sports & Outdoors','Books','Beauty','Toys & Games'
] AS categories) cat,
LATERAL (SELECT ARRAY[
    'Aurora','Nimbus','Vertex','Solace','Crimson','Atlas','Willow','Zephyr','Quartz','Halcyon'
] AS adjectives) adj,
LATERAL (SELECT ARRAY[
    'Blender','Backpack','Headphones','Journal','Lamp','Sneakers','Watch','Speaker','Tent','Serum'
] AS nouns) noun,
LATERAL (SELECT round((10 + random() * 190)::numeric, 2) AS price) p;

-- -----------------------------------------------------------------------------
-- Orders — ~1,000 rows over the last two years. Status distribution is
-- deliberately skewed: mostly delivered, some in flight, a few cancelled or
-- returned — that skew is what makes the GROUP BY / filtering exercises
-- interesting later.
-- -----------------------------------------------------------------------------
INSERT INTO orders (customer_id, employee_id, order_date, order_status, shipping_country)
SELECT
    c.customer_id,
    e.employee_id,
    (DATE '2024-01-01' + floor(random() * 730)::int),
    CASE
        WHEN r < 0.70 THEN 'delivered'
        WHEN r < 0.85 THEN 'shipped'
        WHEN r < 0.93 THEN 'placed'
        WHEN r < 0.97 THEN 'cancelled'
        ELSE 'returned'
    END,
    c.country
FROM generate_series(1, 1000) AS n
JOIN LATERAL (
    SELECT customer_id, country FROM customers
    ORDER BY customer_id OFFSET floor(random() * 200) LIMIT 1
) c ON TRUE
JOIN LATERAL (
    SELECT employee_id FROM employees WHERE department = 'Sales'
    ORDER BY employee_id OFFSET floor(random() * 8) LIMIT 1
) e ON TRUE
CROSS JOIN LATERAL (SELECT random() AS r) rnd;

-- -----------------------------------------------------------------------------
-- Order items — 1 to 5 line items per order.
-- -----------------------------------------------------------------------------
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.order_id,
    p.product_id,
    (1 + floor(random() * 4))::int,
    p.unit_price
FROM orders o
JOIN LATERAL (
    SELECT generate_series(1, (1 + floor(random() * 5))::int)
) AS item_count ON TRUE
JOIN LATERAL (
    SELECT product_id, unit_price FROM products
    ORDER BY product_id OFFSET floor(random() * 40) LIMIT 1
) p ON TRUE;

-- -----------------------------------------------------------------------------
-- Payments — one successful payment per order for most orders; a slice of
-- orders get an extra failed attempt first (realistic payment-retry pattern),
-- and cancelled orders are correctly left unpaid or refunded.
-- -----------------------------------------------------------------------------

-- 1) A failed attempt 0-2 days before the real one, for ~12% of orders.
INSERT INTO payments (order_id, payment_date, amount, payment_method, payment_status)
SELECT
    o.order_id,
    o.order_date - (1 + floor(random() * 2))::int,
    order_total.total,
    methods[1 + floor(random() * array_length(methods, 1))::int],
    'failed'
FROM orders o
JOIN LATERAL (
    SELECT COALESCE(SUM(quantity * unit_price), 0) AS total
    FROM order_items WHERE order_items.order_id = o.order_id
) order_total ON TRUE,
LATERAL (SELECT ARRAY['credit_card','debit_card','paypal','bank_transfer','gift_card'] AS methods) m
WHERE o.order_status != 'placed' AND random() < 0.12;

-- 2) The real payment for every order that isn't still just "placed" (unpaid cart).
INSERT INTO payments (order_id, payment_date, amount, payment_method, payment_status)
SELECT
    o.order_id,
    o.order_date + floor(random() * 2)::int,
    order_total.total,
    methods[1 + floor(random() * array_length(methods, 1))::int],
    CASE WHEN o.order_status = 'returned' THEN 'refunded' ELSE 'success' END
FROM orders o
JOIN LATERAL (
    SELECT COALESCE(SUM(quantity * unit_price), 0) AS total
    FROM order_items WHERE order_items.order_id = o.order_id
) order_total ON TRUE,
LATERAL (SELECT ARRAY['credit_card','debit_card','paypal','bank_transfer','gift_card'] AS methods) m
WHERE o.order_status != 'placed';

-- -----------------------------------------------------------------------------
-- Quick sanity check — run this after seeding to confirm row counts look right.
-- -----------------------------------------------------------------------------
-- SELECT 'customers' AS table_name, COUNT(*) FROM customers
-- UNION ALL SELECT 'employees', COUNT(*) FROM employees
-- UNION ALL SELECT 'products', COUNT(*) FROM products
-- UNION ALL SELECT 'orders', COUNT(*) FROM orders
-- UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
-- UNION ALL SELECT 'payments', COUNT(*) FROM payments;
