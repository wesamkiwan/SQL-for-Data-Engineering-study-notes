# 02. Advanced Aggregation

*Part of [Part 2 — Intermediate & Advanced SQL](../). Previous: [01. Window Functions](../01-window-functions/).*

`GROUP BY` gives you one level of summary. Real reports often need **several
levels at once** — totals by category, totals by month, and a grand total,
all in one result set. `GROUPING SETS`, `ROLLUP`, and `CUBE` do exactly that
in a single query pass, instead of running (and `UNION`-ing) several separate
`GROUP BY` queries.

## The problem: subtotals and grand totals

Imagine a report that needs: revenue per category, revenue per
(category, discontinued-status), **and** one grand total row — the kind of
report a finance team asks for constantly. The naive approach is three
separate queries stitched together with `UNION ALL`. There's a better way.

## `GROUPING SETS`: explicit control over which groupings you want

```sql
SET search_path TO northstar;

SELECT
    category,
    is_discontinued,
    SUM(unit_price) AS total_list_price
FROM products
GROUP BY GROUPING SETS (
    (category, is_discontinued),   -- group by both
    (category),                    -- subtotal per category
    ()                              -- grand total (empty grouping set = everything)
)
ORDER BY category, is_discontinued;
```

This runs what is logically three `GROUP BY` queries — `(category,
is_discontinued)`, `(category)` alone, and `()` (nothing — the whole table)
— and stacks their results together, in one query, more efficiently than the
database would compute them separately.

Notice the subtotal and grand-total rows will show `NULL` in whichever column
wasn't part of that particular grouping — that `NULL` doesn't mean "unknown
data" here, it means **"this row is a subtotal across all values of this
column."** This is an important, PostgreSQL/ANSI-standard convention to
recognize when you see it in real reports.

## `ROLLUP`: hierarchical subtotals

`ROLLUP` is shorthand for a common, specific pattern of `GROUPING SETS`:
progressively removing columns from the right, like drilling *up* a hierarchy.

```sql
SELECT
    category,
    is_discontinued,
    SUM(unit_price) AS total_list_price
FROM products
GROUP BY ROLLUP (category, is_discontinued)
ORDER BY category, is_discontinued;
```

`ROLLUP (category, is_discontinued)` is exactly equivalent to:

```sql
GROUP BY GROUPING SETS (
    (category, is_discontinued),
    (category),
    ()
)
```

This is perfect for genuinely hierarchical data — like (year, month, day) or
(country, region, city) — where subtotals naturally "roll up" one level at a time:

```sql
SELECT
    EXTRACT(YEAR FROM order_date)  AS order_year,
    EXTRACT(MONTH FROM order_date) AS order_month,
    COUNT(*) AS num_orders
FROM orders
GROUP BY ROLLUP (EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date))
ORDER BY order_year, order_month;
```

This produces: a row per (year, month), a subtotal row per year (month =
`NULL`), and one grand total row (both `NULL`).

## `CUBE`: every possible combination

`CUBE` goes further than `ROLLUP` — it generates subtotals for **every
combination** of the listed columns, not just the hierarchical progression:

```sql
SELECT
    category,
    is_discontinued,
    SUM(unit_price) AS total_list_price
FROM products
GROUP BY CUBE (category, is_discontinued)
ORDER BY category, is_discontinued;
```

`CUBE (category, is_discontinued)` produces **all four** groupings: `(category,
is_discontinued)`, `(category)`, `(is_discontinued)`, and `()`. Use `CUBE`
when subtotals matter in every dimension independently (not just one
hierarchical path); use `ROLLUP` when there's a natural drill-down order;
use plain `GROUPING SETS` when you need a specific custom combination that's
neither.

| | Produces |
|---|---|
| `ROLLUP (a, b)` | `(a,b)`, `(a)`, `()` — 3 groupings |
| `CUBE (a, b)` | `(a,b)`, `(a)`, `(b)`, `()` — 4 groupings |
| `GROUPING SETS (...)` | Exactly whatever you list — full control |

## `GROUPING()`: telling a real value apart from a subtotal's NULL

Since subtotal rows show `NULL`, how do you tell "this row is a subtotal for
`category`" apart from "this category value happens to genuinely be `NULL`"?
The `GROUPING()` function answers exactly that — it returns `1` if the column
was rolled up into a subtotal for that row, `0` if it's a real grouped value:

```sql
SELECT
    category,
    is_discontinued,
    GROUPING(category)        AS is_category_subtotal,
    GROUPING(is_discontinued) AS is_discontinued_subtotal,
    SUM(unit_price) AS total_list_price
FROM products
GROUP BY ROLLUP (category, is_discontinued)
ORDER BY category, is_discontinued;
```

You can use this to produce cleaner labels for a report:

```sql
SELECT
    CASE WHEN GROUPING(category) = 1 THEN 'All Categories' ELSE category END AS category_label,
    SUM(unit_price) AS total_list_price
FROM products
GROUP BY ROLLUP (category)
ORDER BY GROUPING(category), category;
```

## Pivoting: turning rows into columns

> **New term — pivot**: reshaping data so that distinct values from one
> column become separate output *columns*, instead of separate rows. This is
> a spreadsheet-style "cross-tab" view.

PostgreSQL doesn't have a built-in `PIVOT` keyword (SQL Server and Snowflake
do — we'll cover that platform difference in [Part 7](../../07-cloud-data-platforms/)).
In standard SQL, you achieve the same result with conditional aggregation —
the `CASE` + aggregate pattern you already learned in
[Module 09](../../01-sql-foundations/09-case-and-conditional-logic/):

```sql
-- Turn order_status values into columns, one row per shipping_country
SELECT
    shipping_country,
    COUNT(CASE WHEN order_status = 'delivered' THEN 1 END)  AS delivered,
    COUNT(CASE WHEN order_status = 'shipped'   THEN 1 END)  AS shipped,
    COUNT(CASE WHEN order_status = 'placed'    THEN 1 END)  AS placed,
    COUNT(CASE WHEN order_status = 'cancelled' THEN 1 END)  AS cancelled,
    COUNT(CASE WHEN order_status = 'returned'  THEN 1 END)  AS returned
FROM orders
GROUP BY shipping_country
ORDER BY shipping_country;
```

This is exactly what a pivot table in a spreadsheet does — categories that
used to be *values in a column* (`order_status`) become *columns
themselves*. PostgreSQL also offers a `crosstab()` function (in the
`tablefunc` extension) for a more automatic version of this, but the manual
`CASE` approach above is more portable and, for a fixed, known set of
categories, arguably more readable.

## ✅ Try it yourself

```sql
SET search_path TO northstar;

-- Revenue by category and month, with subtotals per category and a grand total
SELECT
    p.category,
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY ROLLUP (p.category, DATE_TRUNC('month', o.order_date))
ORDER BY p.category NULLS LAST, month NULLS LAST;
```

### Exercises

1. Using `GROUPING SETS`, produce a report with exactly two groupings:
   revenue by `payment_method`, and a single grand total row — no other combinations.
2. Using `CUBE`, produce every combination of subtotal for
   (`order_status`, `shipping_country`) — but limit the query to just 3
   countries first with a `WHERE` so the output stays readable.
3. Rewrite the "orders by status, pivoted by country" idea from this module's
   main example but the other way around: one row per `order_status`, one
   column per country (pick 4 countries).

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
SELECT
    payment_method,
    SUM(amount) AS total_amount
FROM payments
GROUP BY GROUPING SETS ((payment_method), ())
ORDER BY payment_method NULLS LAST;

-- 2.
SELECT
    order_status,
    shipping_country,
    COUNT(*) AS num_orders
FROM orders
WHERE shipping_country IN ('United States', 'Canada', 'Germany')
GROUP BY CUBE (order_status, shipping_country)
ORDER BY order_status NULLS LAST, shipping_country NULLS LAST;

-- 3.
SELECT
    order_status,
    COUNT(CASE WHEN shipping_country = 'United States' THEN 1 END) AS united_states,
    COUNT(CASE WHEN shipping_country = 'Canada'        THEN 1 END) AS canada,
    COUNT(CASE WHEN shipping_country = 'Germany'       THEN 1 END) AS germany,
    COUNT(CASE WHEN shipping_country = 'Australia'     THEN 1 END) AS australia
FROM orders
GROUP BY order_status
ORDER BY order_status;
```
</details>

## 🧠 Quick check

<details>
<summary>Q: When would you use CUBE instead of ROLLUP?</summary>

Use `ROLLUP` when your columns have a natural hierarchy and you only care
about drilling up that specific path (e.g., day → month → year). Use `CUBE`
when you need subtotals for every dimension independently, including
combinations that skip a "middle" level (e.g., total by country regardless
of status, AND total by status regardless of country).
</details>

<details>
<summary>Q: How do you tell a real NULL value in your data apart from a ROLLUP subtotal's NULL?</summary>

Use the `GROUPING()` function — it returns `1` specifically when a column's
`NULL` in that row is a subtotal marker (because the column was excluded
from that grouping), and `0` when the value is a genuine grouped value
(which could itself be a real, meaningful `NULL` in your source data).
</details>

---
⬅ [Back to Part 2](../) | ➡ Next: [03. Data Modification & Transactions](../03-data-modification-and-transactions/)
