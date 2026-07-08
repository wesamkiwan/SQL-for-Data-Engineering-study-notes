# 08. String, Date & Numeric Functions

*Part of [Part 1 — SQL Foundations](../). Previous: [07. Set Operations](../07-set-operations/).*

Real-world data is messy — inconsistent casing, extra whitespace, dates you
need to bucket by month, prices you need to round. **Scalar functions**
(functions that transform one value into another, one row at a time) are how
you clean and reshape data inline, inside a query.

> **New term — scalar function**: a function applied to each row
> individually, returning one output value per input row — different from an
> aggregate function ([Module 04](../04-aggregations/)), which collapses
> many rows into one.

> ⚠️ **Portability note**: function *names* for dates and strings vary more
> between databases than almost anything else in SQL. Everything below is
> standard PostgreSQL syntax. When you get to [Part 7](../../07-cloud-data-platforms/),
> we'll flag the equivalent functions in BigQuery, Snowflake, etc. explicitly
> — the *concepts* transfer immediately even when the exact function name doesn't.

## String functions

```sql
SET search_path TO northstar;

SELECT
    first_name,
    last_name,
    UPPER(first_name)                          AS upper_name,
    LOWER(last_name)                           AS lower_name,
    LENGTH(email)                              AS email_length,
    first_name || ' ' || last_name             AS full_name,       -- concatenation
    CONCAT(first_name, ' ', last_name)         AS full_name_alt,   -- same thing, function form
    TRIM('  padded  ')                         AS trimmed,          -- 'padded'
    SUBSTRING(email FROM 1 FOR 3)              AS first_three_chars,
    REPLACE(email, '@example.com', '')         AS username_only,
    SPLIT_PART(email, '@', 1)                  AS username
FROM customers
LIMIT 5;
```

| Function | Does |
|---|---|
| `UPPER` / `LOWER` | Change case |
| `LENGTH` | Character count |
| `\|\|` or `CONCAT()` | Join strings together |
| `TRIM` | Remove leading/trailing whitespace |
| `SUBSTRING(str FROM start FOR length)` | Extract part of a string |
| `REPLACE(str, old, new)` | Swap all occurrences of a substring |
| `SPLIT_PART(str, delimiter, n)` | Get the *n*th piece of a delimited string |

Real use case — normalizing inconsistent data before comparing it:

```sql
-- Case-insensitive, whitespace-safe comparison — a real data cleaning pattern
SELECT * FROM customers
WHERE TRIM(LOWER(email)) = TRIM(LOWER('  Emma.Smith1@Example.com  '));
```

## Date and time functions

```sql
SELECT
    order_id,
    order_date,
    EXTRACT(YEAR FROM order_date)   AS order_year,
    EXTRACT(MONTH FROM order_date)  AS order_month,
    EXTRACT(DOW FROM order_date)    AS day_of_week,       -- 0 = Sunday
    DATE_TRUNC('month', order_date) AS order_month_start,
    order_date + INTERVAL '30 days' AS estimated_followup,
    CURRENT_DATE - order_date       AS days_since_order
FROM orders
LIMIT 5;
```

| Function | Does |
|---|---|
| `EXTRACT(part FROM date)` | Pull out year, month, day, day-of-week, etc. |
| `DATE_TRUNC(unit, date)` | Round a date/timestamp *down* to the start of a unit (day, month, year...) |
| `date + INTERVAL '...'` | Date arithmetic — add/subtract time |
| `CURRENT_DATE` / `NOW()` | Today's date / the current timestamp |
| `date1 - date2` | Number of days between two dates |

`DATE_TRUNC` is one of the most useful functions in a data engineer's
toolkit — it's the standard way to bucket timestamps for reporting:

```sql
-- Monthly order counts and revenue — one of the most common report shapes there is
SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    COUNT(DISTINCT o.order_id)        AS num_orders,
    SUM(oi.quantity * oi.unit_price)  AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;
```

> 🪤 **Common pitfall**: notice we repeated `DATE_TRUNC('month', o.order_date)`
> in both `SELECT` and `GROUP BY` — you **cannot** `GROUP BY` a column alias
> in PostgreSQL's evaluation order (recall from [Module 04](../04-aggregations/)
> that `GROUP BY` runs *before* `SELECT`, so the alias doesn't exist yet when
> grouping happens). Some databases (like BigQuery) *do* allow grouping by
> alias — another example of why checking platform-specific behavior matters
> once you reach [Part 7](../../07-cloud-data-platforms/).

## Numeric functions

```sql
SELECT
    unit_price,
    ROUND(unit_price)               AS rounded,
    ROUND(unit_price, 1)            AS rounded_1dp,
    CEIL(unit_price)                AS rounded_up,
    FLOOR(unit_price)               AS rounded_down,
    unit_price * 1.08               AS price_with_tax,
    ABS(cost_price - unit_price)    AS price_gap
FROM products
LIMIT 5;
```

| Function | Does |
|---|---|
| `ROUND(n, decimals)` | Round to a given number of decimal places |
| `CEIL` / `FLOOR` | Round up / down to the nearest whole number |
| `ABS` | Absolute value |
| `+ - * /` | Standard arithmetic — works directly on numeric columns |

### Type casting

You'll frequently need to explicitly convert one type to another —
PostgreSQL's `::` shorthand is the idiomatic way:

```sql
SELECT
    '42'::INTEGER              AS text_to_int,
    unit_price::TEXT           AS price_as_text,
    CAST(unit_price AS INTEGER) AS price_as_int   -- ANSI-standard alternative to ::
FROM products
LIMIT 1;
```

> **New term — casting**: explicitly converting a value from one data type to
> another. `CAST(x AS type)` is the portable, ANSI-standard syntax that works
> everywhere; `x::type` is a PostgreSQL-specific shorthand for the same thing.

## Combining them: a realistic data-cleaning example

```sql
SELECT
    TRIM(LOWER(first_name)) || ' ' || TRIM(LOWER(last_name)) AS clean_full_name,
    DATE_TRUNC('year', signup_date)                          AS signup_year,
    ROUND(EXTRACT(DAY FROM (CURRENT_DATE - signup_date)) / 365.0, 1) AS years_as_customer
FROM customers
LIMIT 5;
```

## ✅ Try it yourself

```sql
SET search_path TO northstar;

-- Which day of the week gets the most orders?
SELECT
    EXTRACT(DOW FROM order_date) AS day_of_week,
    COUNT(*) AS num_orders
FROM orders
GROUP BY EXTRACT(DOW FROM order_date)
ORDER BY num_orders DESC;
```

### Exercises

1. Create a `product_slug` column on the fly from `product_name`: lowercase,
   with spaces replaced by hyphens (e.g., `"Aurora Blender #1"` → `"aurora-blender-#1"`).
2. Find every order placed in the **first week** of any month (hint: `EXTRACT(DAY FROM order_date) <= 7`).
3. Compute the **profit margin percentage** for every product:
   `(unit_price - cost_price) / unit_price * 100`, rounded to 1 decimal place.

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
SELECT
    product_name,
    REPLACE(LOWER(product_name), ' ', '-') AS product_slug
FROM products;

-- 2.
SELECT order_id, order_date
FROM orders
WHERE EXTRACT(DAY FROM order_date) <= 7;

-- 3.
SELECT
    product_name,
    unit_price,
    cost_price,
    ROUND(((unit_price - cost_price) / unit_price) * 100, 1) AS margin_pct
FROM products
ORDER BY margin_pct DESC;
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What's the difference between DATE_TRUNC('month', order_date) and EXTRACT(MONTH FROM order_date)?</summary>

`EXTRACT(MONTH FROM ...)` returns just the month number (1–12), losing the
year — so January 2023 and January 2024 both become `1`, which is wrong for
most reporting. `DATE_TRUNC('month', ...)` returns a full date/timestamp
rounded down to the 1st of that month (e.g., `2024-01-01`), correctly keeping
different years separate — almost always what you actually want for
time-series grouping.
</details>

<details>
<summary>Q: Why can't you GROUP BY a column alias in PostgreSQL?</summary>

Because of SQL's logical evaluation order ([Module 04](../04-aggregations/)):
`GROUP BY` is evaluated *before* `SELECT`, so the alias defined in `SELECT`
doesn't exist yet at the point `GROUP BY` runs. You must repeat the full
expression (or, in Postgres, you can also `GROUP BY` the column's position
number, like `GROUP BY 1` — handy, but less readable than repeating the expression).
</details>

---
⬅ [Back to Part 1](../) | ➡ Next: [09. CASE & Conditional Logic](../09-case-and-conditional-logic/)
