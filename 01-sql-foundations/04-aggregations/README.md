# 04. Aggregations

*Part of [Part 1 — SQL Foundations](../). Previous: [03. Filtering & Operators](../03-filtering-and-operators/).*

So far every query returned one output row per input row. **Aggregation**
flips that: it summarizes many rows into fewer (often just one) — "how many
orders did we get?", "what's the average order value per country?" This is
where SQL starts to feel genuinely powerful.

> **New term — aggregate function**: a function that takes many rows as input
> and returns a single summary value.

## The five aggregate functions you'll use constantly

```sql
SET search_path TO northstar;

SELECT
    COUNT(*)              AS total_orders,
    COUNT(employee_id)    AS orders_with_employee,
    SUM(quantity)         AS total_units_sold,
    AVG(unit_price)       AS average_unit_price,
    MIN(unit_price)       AS cheapest_line_item,
    MAX(unit_price)       AS most_expensive_line_item
FROM order_items;
```

| Function | Does | Note |
|---|---|---|
| `COUNT(*)` | Counts rows | Counts every row, `NULL`s included |
| `COUNT(column)` | Counts non-`NULL` values in that column | `NULL`s are skipped |
| `SUM(column)` | Adds up a numeric column | `NULL`s are skipped |
| `AVG(column)` | Averages a numeric column | `NULL`s are skipped (not treated as 0!) |
| `MIN(column)` / `MAX(column)` | Smallest / largest value | Works on numbers, dates, and text |

> 🪤 **Common pitfall**: `COUNT(*)` and `COUNT(some_column)` can give
> **different answers** if `some_column` has `NULL`s. `COUNT(employee_id)`
> above only counts orders that actually have an assigned employee — exactly
> the distinction we needed in the last module's exercise about unassigned orders.

## `GROUP BY`: aggregating per category

Without `GROUP BY`, aggregates summarize the *entire* table into one row.
`GROUP BY` gives you one summary row **per group**:

```sql
SELECT
    category,
    COUNT(*)         AS num_products,
    AVG(unit_price)  AS avg_price
FROM products
GROUP BY category
ORDER BY avg_price DESC;
```

Read this as: "split `products` into groups by `category`, then compute
`COUNT(*)` and `AVG(unit_price)` **within each group**."

> ⚠️ **The rule that trips up every beginner once**: every column in your
> `SELECT` list must be either (a) inside an aggregate function, or (b) listed
> in `GROUP BY`. If you `SELECT category, product_name, AVG(unit_price)
> GROUP BY category`, the database will raise an error — it has no way to
> pick a single `product_name` to show for a whole group of products. Ask
> yourself: *"for each group, is there exactly one value of this column?"* If
> not, it needs an aggregate function or to join the `GROUP BY` list.

You can group by multiple columns to get finer-grained summaries:

```sql
SELECT
    category,
    is_discontinued,
    COUNT(*) AS num_products
FROM products
GROUP BY category, is_discontinued
ORDER BY category, is_discontinued;
```

## `HAVING`: filtering *after* aggregation

We already have `WHERE` for filtering — so why do we need something else?
Because `WHERE` runs **before** grouping happens, on raw rows, so it can't
reference an aggregate result like `COUNT(*)` or `AVG(...)`. `HAVING` runs
**after** grouping, and filters the *groups themselves*.

```sql
SELECT
    category,
    COUNT(*) AS num_products,
    AVG(unit_price) AS avg_price
FROM products
GROUP BY category
HAVING COUNT(*) > 5          -- only categories with more than 5 products
ORDER BY avg_price DESC;
```

| | Filters | Runs | Can reference aggregates? |
|---|---|---|---|
| `WHERE` | Individual rows | Before grouping | ❌ No |
| `HAVING` | Groups | After grouping | ✅ Yes |

You can use both in the same query — `WHERE` to cut down rows *before*
grouping (for efficiency and correctness), `HAVING` to filter the resulting groups:

```sql
SELECT
    category,
    COUNT(*) AS num_active_products,
    AVG(unit_price) AS avg_price
FROM products
WHERE is_discontinued = false        -- filter rows first
GROUP BY category
HAVING COUNT(*) >= 4                 -- then filter groups
ORDER BY avg_price DESC;
```

## The complete clause order (now with GROUP BY / HAVING)

**Written order:**
```
SELECT ... FROM ... WHERE ... GROUP BY ... HAVING ... ORDER BY ... LIMIT ...
```

**Logical (evaluation) order** — this is the order that actually explains the
behavior above:

```mermaid
flowchart LR
    A[FROM] --> B[WHERE] --> C[GROUP BY] --> D[HAVING] --> E[SELECT] --> F[ORDER BY] --> G[LIMIT]
```

Notice `SELECT` happens *after* `GROUP BY`/`HAVING` but *before* `ORDER BY` —
which is exactly why you're allowed to `ORDER BY` a column alias you just
created in `SELECT` (like `avg_price` above), but you can't reference that
same alias inside `WHERE`.

## ✅ Try it yourself

```sql
SET search_path TO northstar;

-- Total revenue and number of orders per shipping country,
-- only for countries with more than 20 orders
SELECT
    shipping_country,
    COUNT(*) AS num_orders
FROM orders
GROUP BY shipping_country
HAVING COUNT(*) > 20
ORDER BY num_orders DESC;
```

### Exercises

1. For each `order_status`, count how many orders exist and find the earliest
   and latest `order_date`.
2. Find every product `category` where the average `unit_price` (of
   non-discontinued products only) exceeds $100.
3. Which employees have handled more than 80 orders? Show their `employee_id`
   and order count, most orders first.

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
SELECT
    order_status,
    COUNT(*) AS num_orders,
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM orders
GROUP BY order_status;

-- 2.
SELECT
    category,
    AVG(unit_price) AS avg_price
FROM products
WHERE is_discontinued = false
GROUP BY category
HAVING AVG(unit_price) > 100;

-- 3.
SELECT
    employee_id,
    COUNT(*) AS num_orders
FROM orders
GROUP BY employee_id
HAVING COUNT(*) > 80
ORDER BY num_orders DESC;
```
</details>

## 🧠 Quick check

<details>
<summary>Q: Why can't you write WHERE COUNT(*) > 20 instead of using HAVING?</summary>

Because `WHERE` is evaluated before rows are grouped and aggregated — at that
point, `COUNT(*)` doesn't exist yet as a per-group value. `HAVING` runs after
grouping specifically so it *can* see aggregate results.
</details>

<details>
<summary>Q: If a category has 5 products and one of them has a NULL unit_price, what does AVG(unit_price) divide by — 5 or 4?</summary>

4. `AVG()`, like all standard aggregate functions except `COUNT(*)`, silently
ignores `NULL` values entirely — both from the sum and from the count it
divides by. This is a common source of subtle bugs when people expect
`NULL` to be treated as zero; it never is.
</details>

---
⬅ [Back to Part 1](../) | ➡ Next: [05. Joins](../05-joins/)
