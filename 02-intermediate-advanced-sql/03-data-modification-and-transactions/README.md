# 03. Data Modification & Transactions

*Part of [Part 2 — Intermediate & Advanced SQL](../). Previous: [02. Advanced Aggregation](../02-advanced-aggregation/).*

Every module so far has only *read* data. This module covers *writing* it —
and the safety mechanism, **transactions**, that makes writing data reliable
even when things go wrong halfway through.

> ⚠️ **Practice safely**: run these examples inside a transaction you can
> `ROLLBACK` (explained below) so you don't permanently alter your practice
> dataset, or just re-run [`datasets/postgres/02_reset.sql`](../../datasets/postgres/02_reset.sql)
> and reseed afterward if you want a clean slate.

## `INSERT`: adding rows

```sql
SET search_path TO northstar;

INSERT INTO customers (first_name, last_name, email, country, signup_date, is_active)
VALUES ('Nadia', 'Petrov', 'nadia.petrov@example.com', 'Sweden', CURRENT_DATE, true);

-- Insert multiple rows in one statement — more efficient than one INSERT per row
INSERT INTO customers (first_name, last_name, email, country, signup_date, is_active)
VALUES
    ('Kai', 'Nakamura', 'kai.nakamura@example.com', 'Australia', CURRENT_DATE, true),
    ('Sofia', 'Lindqvist', 'sofia.lindqvist@example.com', 'Sweden', CURRENT_DATE, true);
```

You can also insert the *result of a query* directly — a very common data
engineering pattern (e.g., copying/archiving rows):

```sql
CREATE TABLE inactive_customers_archive (LIKE customers INCLUDING ALL);

INSERT INTO inactive_customers_archive
SELECT * FROM customers WHERE is_active = false;
```

## `UPDATE`: modifying existing rows

```sql
UPDATE customers
SET is_active = false
WHERE signup_date < '2022-06-01' AND customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders WHERE order_date > CURRENT_DATE - INTERVAL '365 days'
);
```

> 🪤 **The single most dangerous mistake in SQL**: forgetting the `WHERE`
> clause on an `UPDATE` (or `DELETE`, below) updates or deletes **every row
> in the table.** Before running any `UPDATE`/`DELETE` against real data,
> always run the equivalent `SELECT` with the same `WHERE` clause first, to
> confirm exactly which rows will be affected:

```sql
-- ALWAYS do this first...
SELECT * FROM customers
WHERE signup_date < '2022-06-01' AND customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders WHERE order_date > CURRENT_DATE - INTERVAL '365 days'
);
-- ...THEN convert it to an UPDATE once you've confirmed the row set looks right.
```

## `DELETE`: removing rows

```sql
DELETE FROM inactive_customers_archive
WHERE customer_id = 1;
```

`DELETE` removes entire rows matching `WHERE` (or the whole table's data, if
you omit `WHERE` — the same danger as `UPDATE`). To empty a table
completely and efficiently, `TRUNCATE` is faster than `DELETE` with no
`WHERE` (it deallocates the storage directly rather than deleting row by row),
but it can't be filtered and, depending on configuration, may not fire triggers:

```sql
TRUNCATE TABLE inactive_customers_archive;
```

## Upserts: `INSERT ... ON CONFLICT`

> **New term — upsert**: "update or insert" — insert a new row, but if a row
> with a conflicting key already exists, update it instead. This is one of
> the most common operations in real data pipelines (e.g., "if this customer
> ID already exists, update their info; otherwise, add them").

```sql
INSERT INTO customers (customer_id, first_name, last_name, email, country, signup_date, is_active)
VALUES (1, 'Emma', 'Smith-Jones', 'emma.smith1@example.com', 'Canada', '2022-03-14', true)
ON CONFLICT (customer_id)
DO UPDATE SET
    last_name = EXCLUDED.last_name,
    is_active = EXCLUDED.is_active;
```

`EXCLUDED` is a special reference to "the row that *would have* been
inserted" — letting you use its values in the `UPDATE` part. `ON CONFLICT
(customer_id) DO NOTHING` is the other common variant — "insert if new,
silently skip if it already exists."

> 💡 This exact pattern is central to [Part 4 — SQL for Pipelines](../../04-data-engineering-with-sql/02-sql-for-pipelines/),
> where you'll use upserts to load incremental data safely, over and over,
> without creating duplicates.

> **New term — `MERGE`**: the ANSI-standard, more powerful cousin of
> `ON CONFLICT` — it can insert, update, *and* delete in one statement based
> on a join condition, and is supported by PostgreSQL (since v15), SQL
> Server, Snowflake, BigQuery, and Oracle. We cover it in depth alongside
> incremental loading patterns in
> [Part 4](../../04-data-engineering-with-sql/02-sql-for-pipelines/), since
> that's where its full power is actually needed.

## Transactions: making multiple writes safe together

> **New term — transaction**: a group of one or more SQL statements executed
> as a single, indivisible unit — either **all** of them succeed and are
> saved, or **none** of them are, even if the database crashes halfway through.

Why does this matter? Imagine transferring stock between two warehouses:
subtract 5 units from Warehouse A, add 5 units to Warehouse B. If the
database crashes after the subtraction but before the addition, you've just
lost 5 units of stock into thin air. A transaction prevents exactly this.

```sql
BEGIN;

UPDATE products SET unit_price = unit_price * 1.10 WHERE category = 'Electronics';
UPDATE products SET unit_price = unit_price * 0.95 WHERE category = 'Books';

-- Check the results look right before committing:
SELECT product_name, category, unit_price FROM products WHERE category IN ('Electronics', 'Books');

COMMIT;   -- makes both changes permanent, together
-- or: ROLLBACK;  -- undoes everything since BEGIN, as if none of it happened
```

- **`BEGIN`** (or `START TRANSACTION`) starts a transaction.
- **`COMMIT`** permanently saves every change made since `BEGIN`.
- **`ROLLBACK`** discards every change made since `BEGIN`, as if it never happened.

This is also how you should **practice** `UPDATE`/`DELETE` safely — wrap it
in `BEGIN` ... `ROLLBACK` to see what would happen with zero risk:

```sql
BEGIN;
DELETE FROM customers WHERE is_active = false;
SELECT COUNT(*) FROM customers;   -- check the impact
ROLLBACK;                          -- undo it — nothing was actually deleted
```

## ACID: the four guarantees a transactional database makes

> **New term — ACID**: the four properties a database must guarantee for
> transactions to be trustworthy.

| Letter | Stands for | Means |
|---|---|---|
| **A** | Atomicity | All statements in a transaction succeed, or none do — no partial results |
| **C** | Consistency | A transaction can only take the database from one valid state to another (constraints are never violated, even mid-transaction failure) |
| **I** | Isolation | Concurrent transactions don't see each other's uncommitted changes |
| **D** | Durability | Once committed, data survives even a crash immediately afterward |

Every module you've done so far implicitly relied on Consistency and
Durability. This module is where Atomicity and Isolation become directly
visible and directly under your control.

## A glimpse of isolation levels (the "I" in ACID)

> **New term — isolation level**: how strictly the database prevents one
> transaction from seeing another's in-progress changes. Stricter isolation
> is safer but can reduce how many transactions run concurrently without
> waiting on each other.

PostgreSQL's default is `READ COMMITTED` — a transaction only ever sees data
that other transactions have already `COMMIT`ted, never in-progress
uncommitted changes. This prevents the worst problem (**dirty reads** —
reading data that gets rolled back a moment later and never really existed)
while still allowing high concurrency. Stricter levels (`REPEATABLE READ`,
`SERIALIZABLE`) exist for cases needing stronger guarantees, at some cost to
concurrency — this becomes relevant for high-throughput pipeline design, and
we revisit it briefly in [Part 5](../../05-performance-and-optimization/).
For now, know that this dial exists and that "isolation level" is the
correct term when you encounter it later.

## ✅ Try it yourself

```sql
SET search_path TO northstar;

BEGIN;

-- Discontinue any product that has never sold a single unit
UPDATE products
SET is_discontinued = true
WHERE product_id NOT IN (SELECT DISTINCT product_id FROM order_items);

SELECT product_name FROM products WHERE is_discontinued = true;

ROLLBACK;   -- undo it, this was just practice
```

### Exercises

1. Write an `UPDATE` that marks all orders older than 2 years with status
   `'placed'` as `'cancelled'` (an abandoned-cart cleanup) — remember to
   `SELECT` first to check the impact, and wrap it in `BEGIN`/`ROLLBACK` to practice safely.
2. Write an upsert: insert a new product with `product_id = 999`; if it
   already exists, update its `unit_price` instead.
3. Explain, in your own words, why wrapping two related `UPDATE` statements
   in a single transaction is safer than running them as two separate
   statements outside a transaction.

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
BEGIN;
SELECT order_id, order_date, order_status
FROM orders
WHERE order_status = 'placed' AND order_date < CURRENT_DATE - INTERVAL '2 years';

UPDATE orders
SET order_status = 'cancelled'
WHERE order_status = 'placed' AND order_date < CURRENT_DATE - INTERVAL '2 years';
ROLLBACK; -- or COMMIT; once you've verified the result

-- 2.
INSERT INTO products (product_id, product_name, category, unit_price, cost_price, is_discontinued)
VALUES (999, 'Test Product', 'Electronics', 49.99, 25.00, false)
ON CONFLICT (product_id)
DO UPDATE SET unit_price = EXCLUDED.unit_price;

-- 3. (conceptual)
-- If the two UPDATEs run outside a transaction and the database crashes (or
-- the connection drops) after the first succeeds but before the second
-- runs, the data is left in an inconsistent, half-finished state with no
-- way to know it happened. Wrapping both in BEGIN/COMMIT guarantees they
-- succeed or fail together — Atomicity — so the data can never be caught
-- halfway between the old and new state.
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What's the difference between DELETE and TRUNCATE?</summary>

`DELETE` removes rows matching a `WHERE` clause (or all rows if omitted),
row by row, and can be rolled back inside a transaction. `TRUNCATE`
deallocates the table's storage directly, is much faster for clearing an
entire table, but can't filter which rows to remove — it's all or nothing.
</details>

<details>
<summary>Q: Why should you run a SELECT with the same WHERE clause before running an UPDATE or DELETE?</summary>

Because an `UPDATE`/`DELETE` with an incorrect or missing `WHERE` clause can
silently affect far more rows than intended — including every row in the
table. Running the equivalent `SELECT` first lets you visually confirm
exactly which rows will be touched before committing to the change.
</details>

---
⬅ [Back to Part 2](../) | ➡ Next: [04. Views & Materialized Views](../04-views-and-materialized-views/)
