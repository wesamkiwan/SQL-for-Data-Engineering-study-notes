# 09. CASE & Conditional Logic

*Part of [Part 1 — SQL Foundations](../). Previous: [08. String, Date & Numeric Functions](../08-string-date-numeric-functions/).*

This is the last module of Part 1, and it completes your toolkit: `CASE` lets
you write "if this, then that" logic **inside** a query, turning raw values
into meaningful categories.

## `CASE WHEN`: SQL's if/else

```sql
SET search_path TO northstar;

SELECT
    product_name,
    unit_price,
    CASE
        WHEN unit_price < 25  THEN 'Budget'
        WHEN unit_price < 100 THEN 'Mid-range'
        ELSE 'Premium'
    END AS price_tier
FROM products;
```

Read it top to bottom: for each row, the database checks each `WHEN`
condition **in order** and uses the result from the **first** one that's
true. `ELSE` catches everything that didn't match any `WHEN` (and if you omit
`ELSE`, non-matching rows simply get `NULL` — usually not what you want, so
get in the habit of always including `ELSE`).

> 🪤 **Common pitfall**: order matters. `WHEN unit_price < 100 THEN 'Mid-range'
> WHEN unit_price < 25 THEN 'Budget'` would **never** return `'Budget'`,
> because anything under 25 is also under 100, and the first matching `WHEN`
> wins. Always order conditions from most to least specific.

## `CASE` inside aggregates: conditional counting

This is one of the most useful patterns in all of SQL — turning `CASE` and
`SUM`/`COUNT` into a way to pivot data by condition, without needing a
separate query per condition:

```sql
SELECT
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN order_status = 'delivered' THEN 1 END)  AS delivered_count,
    COUNT(CASE WHEN order_status = 'cancelled' THEN 1 END)  AS cancelled_count,
    SUM(CASE WHEN order_status = 'returned' THEN 1 ELSE 0 END) AS returned_count
FROM orders;
```

Why does `COUNT(CASE WHEN ... THEN 1 END)` work? Recall from
[Module 04](../04-aggregations/) that `COUNT(column)` only counts **non-NULL**
values. When the `CASE` condition is false and there's no `ELSE`, it produces
`NULL` — which `COUNT` simply skips. So this pattern counts only the rows
matching your condition, all in a single pass over the table, instead of
running a separate query with a `WHERE` for each status.

This pattern is how you build a simple "pivot"-style report by hand (a fuller
treatment of pivoting is in [Part 2 — Advanced Aggregation](../../02-intermediate-advanced-sql/02-advanced-aggregation/)):

```sql
SELECT
    shipping_country,
    COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) AS delivered,
    COUNT(CASE WHEN order_status = 'cancelled' THEN 1 END) AS cancelled,
    COUNT(*) AS total
FROM orders
GROUP BY shipping_country
ORDER BY total DESC;
```

## `CASE` in `ORDER BY`: custom sort order

Sometimes alphabetical or numerical order isn't the order you actually want
(e.g., sorting order statuses by their place in a business process, not the alphabet):

```sql
SELECT order_id, order_status
FROM orders
ORDER BY
    CASE order_status
        WHEN 'placed'    THEN 1
        WHEN 'shipped'   THEN 2
        WHEN 'delivered' THEN 3
        WHEN 'returned'  THEN 4
        WHEN 'cancelled' THEN 5
    END;
```

(Notice this is the shorthand form, `CASE column WHEN value THEN ...` — a
concise alternative to `CASE WHEN column = value THEN ...` when you're always
comparing the same column for equality.)

## `COALESCE`: the first non-NULL value

```sql
SELECT
    order_id,
    employee_id,
    COALESCE(employee_id::TEXT, 'Unassigned') AS employee_display
FROM orders;
```

`COALESCE(a, b, c, ...)` returns the first argument that isn't `NULL`,
scanning left to right. It's most commonly used with exactly two arguments —
"use this value, or fall back to a default if it's missing":

```sql
-- Recall this exact pattern from Module 05's join example
SELECT
    c.customer_id,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS lifetime_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id;
```

Without `COALESCE`, customers with zero orders would show `NULL` instead of
`0` for lifetime revenue — technically "correct" (there's truly no data to
sum), but usually not what a report needs.

## `NULLIF`: turn a specific value into NULL

`NULLIF(a, b)` returns `NULL` if `a` equals `b`, otherwise returns `a`. It's
the inverse use case of `COALESCE` — useful for guarding against division by
zero, among other things:

```sql
SELECT
    product_name,
    cost_price,
    unit_price,
    -- Without NULLIF, a $0 cost_price would cause a divide-by-zero error
    ROUND(unit_price / NULLIF(cost_price, 0), 2) AS price_to_cost_ratio
FROM products;
```

If `cost_price` is `0`, `NULLIF(cost_price, 0)` returns `NULL` instead, and
dividing by `NULL` produces `NULL` (not an error) — a graceful way to handle
an edge case inline.

## Putting it all together

```sql
SELECT
    c.customer_id,
    c.first_name,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS lifetime_revenue,
    CASE
        WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) = 0   THEN 'No purchases yet'
        WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) < 200  THEN 'Bronze'
        WHEN COALESCE(SUM(oi.quantity * oi.unit_price), 0) < 800  THEN 'Silver'
        ELSE 'Gold'
    END AS customer_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name
ORDER BY lifetime_revenue DESC;
```

## 🎉 Part 1 complete!

You now know how to explore, filter, aggregate, join, combine, and shape SQL
query results — the complete foundation every later part builds on. Take the
quiz below, then move on to [Part 2](../../02-intermediate-advanced-sql/),
where you'll learn window functions, transactions, and more.

## ✅ Try it yourself

```sql
SET search_path TO northstar;

-- Classify every payment attempt, and count each category
SELECT
    CASE
        WHEN payment_status = 'success'  THEN '✅ Success'
        WHEN payment_status = 'failed'   THEN '❌ Failed'
        WHEN payment_status = 'refunded' THEN '↩️ Refunded'
        ELSE '⏳ Other'
    END AS status_label,
    COUNT(*) AS num_payments,
    SUM(amount) AS total_amount
FROM payments
GROUP BY status_label
ORDER BY num_payments DESC;
```

### Exercises

1. Label every product as `'Discontinued'` or `'Active'` based on
   `is_discontinued`, and additionally label active products under $20 as `'Active - Clearance Candidate'`.
2. Using conditional counting (`COUNT(CASE WHEN ...)`), produce one row per
   `category` showing how many products in that category are discontinued
   vs. active, side by side.
3. Compute each order's `total_amount` (sum of `quantity * unit_price` from
   `order_items`), then use `COALESCE`/`NULLIF` logic to safely compute
   `total_amount / NULLIF(items_count, 0)` as the average line-item value per order.

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
SELECT
    product_name,
    is_discontinued,
    unit_price,
    CASE
        WHEN is_discontinued THEN 'Discontinued'
        WHEN NOT is_discontinued AND unit_price < 20 THEN 'Active - Clearance Candidate'
        ELSE 'Active'
    END AS status_label
FROM products;

-- 2.
SELECT
    category,
    COUNT(CASE WHEN is_discontinued THEN 1 END)     AS discontinued_count,
    COUNT(CASE WHEN NOT is_discontinued THEN 1 END) AS active_count
FROM products
GROUP BY category
ORDER BY category;

-- 3.
SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price) AS total_amount,
    COUNT(oi.order_item_id) AS items_count,
    ROUND(SUM(oi.quantity * oi.unit_price) / NULLIF(COUNT(oi.order_item_id), 0), 2) AS avg_line_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What does CASE return if no WHEN condition matches and there's no ELSE?</summary>

`NULL`. This is easy to miss and can quietly break downstream logic (e.g., a
`SUM()` over a column full of unexpected `NULL`s). Get in the habit of always
writing an explicit `ELSE`, even if it's just `ELSE 'Other'` or `ELSE NULL`
to make the behavior obvious to the next reader.
</details>

<details>
<summary>Q: How is COALESCE(a, b) different from CASE WHEN a IS NULL THEN b ELSE a END?</summary>

They're functionally identical — `COALESCE` is shorthand for exactly that
`CASE` pattern (extended to any number of arguments). Use `COALESCE`; it's
shorter and immediately signals "fallback value" intent to any reader familiar with SQL.
</details>

---
⬅ [Back to Part 1](../) | ➡ Next: [Part 2 — Intermediate & Advanced SQL](../../02-intermediate-advanced-sql/)
