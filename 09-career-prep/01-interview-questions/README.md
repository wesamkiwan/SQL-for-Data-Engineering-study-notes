# 01. SQL Interview Questions

*Part of [Part 9 — Career Prep](../). Previous: [Part 8 — Real-World Projects](../../08-real-world-projects/).*

Every question below links back to the module where it was taught in full
depth — if an answer doesn't come to you immediately, that's your cue for
which module to revisit, not a sign you're not ready. Try answering each
one yourself (out loud, as if in a real interview) before checking the answer.

## Category: SQL Fundamentals

<details>
<summary><b>Q: What's the difference between WHERE and HAVING?</b></summary>

`WHERE` filters individual rows *before* grouping/aggregation happens;
`HAVING` filters *groups*, after aggregation, and can reference aggregate
functions like `COUNT()` or `SUM()` that don't exist yet when `WHERE` runs.
Full explanation: [Part 1, Module 04](../../01-sql-foundations/04-aggregations/).
</details>

<details>
<summary><b>Q: What's the difference between COUNT(*) and COUNT(column_name)?</b></summary>

`COUNT(*)` counts every row, including ones with `NULL` values anywhere.
`COUNT(column_name)` only counts rows where that specific column is
non-`NULL`. Full explanation: [Part 1, Module 04](../../01-sql-foundations/04-aggregations/).
</details>

<details>
<summary><b>Q: Why does `WHERE column = NULL` never return any rows?</b></summary>

`NULL` represents "unknown," and any direct comparison to `NULL` (using
`=`, `!=`, etc.) evaluates to `UNKNOWN`, not `TRUE` — even comparing `NULL`
to itself. You must use `IS NULL` / `IS NOT NULL` instead.
Full explanation: [Part 1, Module 03](../../01-sql-foundations/03-filtering-and-operators/).
</details>

<details>
<summary><b>Q: What's the difference between UNION and UNION ALL?</b></summary>

`UNION` removes duplicate rows from the combined result; `UNION ALL` keeps
every row, including duplicates, and is faster since it skips the
deduplication work. Default to `UNION ALL` unless you specifically need
duplicates removed. Full explanation: [Part 1, Module 07](../../01-sql-foundations/07-set-operations/).
</details>

## Category: Joins

<details>
<summary><b>Q: Explain the difference between INNER JOIN, LEFT JOIN, and FULL JOIN.</b></summary>

`INNER JOIN` keeps only rows matching on both sides. `LEFT JOIN` keeps all
rows from the left table, with `NULL`s for unmatched right-side columns.
`FULL JOIN` keeps all rows from both tables, with `NULL`s on whichever side
didn't match. Full explanation, with diagrams: [Part 1, Module 05](../../01-sql-foundations/05-joins/).
</details>

<details>
<summary><b>Q: How would you find all customers who have never placed an order?</b></summary>

```sql
SELECT c.customer_id, c.first_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```
The `LEFT JOIN` + `WHERE ... IS NULL` idiom is the standard pattern for
"in A but not in B." Full explanation: [Part 1, Module 05](../../01-sql-foundations/05-joins/).
</details>

<details>
<summary><b>Q: What is a self join, and give a real example of when you'd use one.</b></summary>

A self join joins a table to itself (using two different aliases) —
classic use case: an `employees` table with a `manager_id` referencing
another row in the same table, used to pair each employee with their
manager's name. Full explanation: [Part 1, Module 05](../../01-sql-foundations/05-joins/).
</details>

<details>
<summary><b>Q: Why might a JOIN produce more rows than you expected?</b></summary>

Almost always a **grain** mismatch — joining a table at one grain (e.g.,
one row per order) to a table at a finer grain (e.g., one row per order
item) naturally multiplies rows. Always know each table's grain before
joining. Full explanation: [Part 1, Module 05](../../01-sql-foundations/05-joins/).
</details>

## Category: Window Functions

<details>
<summary><b>Q: What's the difference between ROW_NUMBER(), RANK(), and DENSE_RANK()?</b></summary>

They only differ when there are ties. `ROW_NUMBER()` always assigns unique,
sequential numbers, breaking ties arbitrarily. `RANK()` gives ties the same
number, then skips the next number(s). `DENSE_RANK()` gives ties the same
number without skipping. Full explanation: [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).
</details>

<details>
<summary><b>Q: How would you find the top 3 highest-paid employees in each department?</b></summary>

```sql
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT * FROM ranked WHERE rn <= 3;
```
The "rank within group, then filter in an outer query" pattern — you can't
filter directly on a window function's result in the same `SELECT` due to
logical evaluation order. Full explanation: [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).
</details>

<details>
<summary><b>Q: What's the difference between GROUP BY and PARTITION BY?</b></summary>

`GROUP BY` collapses each group into one output row. `PARTITION BY` (inside
a window function) keeps every row, computing the aggregate "as if"
grouped but attaching it back to each individual row.
Full explanation: [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).
</details>

## Category: Database Design

<details>
<summary><b>Q: What is normalization, and why would you deliberately denormalize?</b></summary>

Normalization organizes data to eliminate redundancy and prevent update/
insertion/deletion anomalies, at the cost of requiring more joins.
Denormalization deliberately reverses this for analytical (OLAP) systems,
trading some redundancy for dramatically simpler, faster queries at read
time. Full explanation: [Part 3, Modules 01–02](../../03-database-design-and-modeling/).
</details>

<details>
<summary><b>Q: Explain the difference between a star schema and a snowflake schema.</b></summary>

A star schema keeps dimension tables flat/denormalized around a central
fact table. A snowflake schema further normalizes dimensions into
sub-dimensions, trading query simplicity for reduced redundancy.
Full explanation: [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/).
</details>

<details>
<summary><b>Q: What is a Slowly Changing Dimension, and explain SCD Type 2 specifically.</b></summary>

An SCD is a strategy for handling dimension data that changes over time.
Type 2 preserves full history by expiring the old row (setting an end
date) and inserting a new row for the updated version, with a surrogate
key distinguishing each version — letting historical facts correctly join
to the dimension version that was true at the time. Full explanation,
with a hands-on build: [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
and the [capstone project](../../08-real-world-projects/01-capstone-mini-warehouse/).
</details>

<details>
<summary><b>Q: What's the difference between a data warehouse, a data lake, and a lakehouse?</b></summary>

A warehouse stores structured data with schema-on-write, optimized for SQL.
A lake stores any data type cheaply with schema-on-read, but lacks native
transaction guarantees. A lakehouse adds ACID transactions and schema
enforcement (via table formats like Delta Lake/Iceberg) on top of lake
storage, combining both models' strengths. Full explanation: [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/).
</details>

## Category: Data Engineering Concepts

<details>
<summary><b>Q: What's the difference between ETL and ELT?</b></summary>

ETL transforms data on separate infrastructure before loading the
already-clean result into the destination. ELT loads raw data into the
destination first, then transforms it there using the destination's own
compute — the modern default, enabled by cheap cloud storage/compute.
Full explanation: [Part 4, Module 01](../../04-data-engineering-with-sql/01-etl-vs-elt/).
</details>

<details>
<summary><b>Q: What does it mean for a pipeline to be idempotent, and why does it matter?</b></summary>

An idempotent operation produces the same result no matter how many times
it runs. It matters because automated pipelines get retried (due to
transient failures or manual reruns), and a non-idempotent step run twice
can silently duplicate or corrupt data with no error raised.
Full explanation: [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/).
</details>

<details>
<summary><b>Q: How would you design an incremental load that safely handles late-arriving data?</b></summary>

Use a small overlapping lookback window (e.g., always reprocess the last
3 days, not just strictly-new rows since the last watermark), combined
with an idempotent upsert/`MERGE` so reprocessing already-correct rows
causes no harm. Full explanation: [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/).
</details>

<details>
<summary><b>Q: What is Change Data Capture (CDC), and why is it preferred over re-querying an entire source table?</b></summary>

CDC reads a source database's transaction log directly to capture exactly
which rows were inserted, updated, or deleted, avoiding the cost of
re-scanning the entire table on every sync and correctly capturing
deletes as an explicit signal. Full explanation: [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/).
</details>

## Category: Performance

<details>
<summary><b>Q: How would you diagnose a slow query?</b></summary>

Run `EXPLAIN ANALYZE`, compare estimated vs. actual row counts (a big
mismatch suggests stale statistics — run `ANALYZE`), look for `Seq Scan`
on large tables with selective filters (missing index?), and check for
sargability issues (a function wrapped around a filtered column defeating
index use). Full explanation: [Part 5, Modules 01, 02, 04](../../05-performance-and-optimization/).
</details>

<details>
<summary><b>Q: When would adding an index NOT help, or even hurt?</b></summary>

Low-selectivity columns (few distinct values, like a boolean flag) rarely
benefit from an index. Every index also adds overhead to every
`INSERT`/`UPDATE`/`DELETE` touching that column, so adding indexes
indiscriminately can slow down write-heavy tables for little read benefit.
Full explanation: [Part 5, Module 02](../../05-performance-and-optimization/02-indexing-strategies/).
</details>

<details>
<summary><b>Q: What is partition pruning, and why does it matter for both speed and cost?</b></summary>

Partition pruning is the optimizer's ability to skip scanning partitions
that can't possibly contain matching rows, based on a query's filters. It
speeds up queries by reducing data scanned, and on bytes-scanned-billed
platforms (like BigQuery), it directly reduces cost too.
Full explanation: [Part 5, Modules 03 and 06](../../05-performance-and-optimization/).
</details>

<details>
<summary><b>Q: Explain what a "shuffle" is in a distributed query engine, and why it's expensive.</b></summary>

A shuffle redistributes rows across compute nodes over the network so
matching join/group-by keys end up together — it's expensive because
network transfer between machines is far slower than each node processing
data it already holds locally. Full explanation: [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/).
</details>

## Category: Security

<details>
<summary><b>Q: How do you prevent SQL injection?</b></summary>

Use parameterized queries (prepared statements), which send the SQL
structure to the database separately from user-supplied values — the
value can never be reinterpreted as SQL syntax, regardless of its content.
Never build SQL via string concatenation of untrusted input.
Full explanation: [Part 6, Module 01](../../06-security/01-sql-injection-and-prevention/).
</details>

<details>
<summary><b>Q: What is the principle of least privilege, and how do you implement it in SQL?</b></summary>

Grant only the minimum permissions genuinely necessary — implemented via
`GRANT`/`REVOKE`, role-based access control (RBAC), and dedicated,
narrowly-scoped service accounts for pipelines rather than shared admin credentials.
Full explanation: [Part 6, Module 02](../../06-security/02-authentication-and-authorization/).
</details>

<details>
<summary><b>Q: What's the difference between Row-Level Security and column-level GRANT?</b></summary>

RLS restricts *which rows* a role can see within a table, evaluated per
query based on who's asking. Column-level `GRANT` restricts *which
columns* a role can reference at all, uniformly across every row.
Full explanation: [Part 6, Module 04](../../06-security/04-data-masking-and-row-column-security/).
</details>

## Coding challenge round

Try writing the SQL for each of these against the
[NorthStar Retail dataset](../../datasets/) before checking the linked
module for the full worked solution.

1. **Second-highest value**: Find the customer with the *second-highest*
   lifetime revenue (without using `LIMIT ... OFFSET`, as a warm-up for
   the underlying logic). *Hint: `DENSE_RANK()` — [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).*
2. **Running total**: Show each day's revenue alongside a running total
   for the month. *Hint: window frame — [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).*
3. **Month-over-month growth**: Compute the percentage change in monthly
   revenue compared to the previous month. *Hint: `LAG()` — [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).*
4. **Duplicate detection**: Find any duplicate customer emails in the
   database. *Hint: `GROUP BY` + `HAVING COUNT(*) > 1` — [Part 1, Module 04](../../01-sql-foundations/04-aggregations/).*
5. **Gaps in a sequence**: Find any `order_id` values missing from an
   otherwise sequential range (a classic "gaps and islands" problem).
   *Hint: compare each row to `LAG(order_id)` and look for a difference
   greater than 1 — [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).*

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
WITH revenue AS (
    SELECT c.customer_id,
           DENSE_RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rnk
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id
)
SELECT customer_id FROM revenue WHERE rnk = 2;

-- 2.
SELECT
    order_date,
    SUM(daily_revenue) OVER (
        PARTITION BY DATE_TRUNC('month', order_date)
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT o.order_date, SUM(oi.quantity * oi.unit_price) AS daily_revenue
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_date
) daily;

-- 3.
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_date) AS month, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT month, revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month), 1) AS pct_change
FROM monthly ORDER BY month;

-- 4.
SELECT email, COUNT(*) FROM customers GROUP BY email HAVING COUNT(*) > 1;

-- 5.
WITH ordered AS (
    SELECT order_id, LAG(order_id) OVER (ORDER BY order_id) AS prev_id
    FROM orders
)
SELECT prev_id + 1 AS gap_start, order_id - 1 AS gap_end
FROM ordered
WHERE order_id - prev_id > 1;
```
</details>

## How to actually use this in an interview

Don't memorize these answers verbatim — an interviewer can tell. Instead:

1. **Explain the concept first, in plain English**, exactly like the
   modules in this repo do — this demonstrates understanding, not recall.
2. **Reference a concrete example** (from this repo's NorthStar Retail
   dataset, or a project you've built) to ground the abstract idea.
3. **Mention the tradeoff**, where one exists (most good SQL questions have
   one — "it depends" followed by the actual dependency is usually a
   stronger answer than a flat rule).
4. If you don't know something: say so directly, then reason through it
   out loud from what you *do* know — interviewers consistently rate this
   more highly than a confident wrong guess.

---
⬅ [Back to Part 9](../) | ➡ Next: [02. Cheat Sheets](../02-cheat-sheets/)
