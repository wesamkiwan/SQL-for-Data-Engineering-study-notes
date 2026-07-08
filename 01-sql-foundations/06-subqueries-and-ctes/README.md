# 06. Subqueries & CTEs

*Part of [Part 1 — SQL Foundations](../). Previous: [05. Joins](../05-joins/).*

Real questions are often naturally multi-step: "find customers whose total
spend is above the *average* total spend." You can't write that as a single
flat `WHERE` clause, because "the average total spend" is itself a query
result. **Subqueries** and **CTEs** let you compose queries out of smaller queries.

## Subqueries: a query inside a query

> **New term — subquery**: a `SELECT` statement nested inside another SQL
> statement, used as if it were a single value, a list, or a table.

### Scalar subquery: returns a single value

```sql
SET search_path TO northstar;

SELECT product_name, unit_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products);
```

The inner query `(SELECT AVG(unit_price) FROM products)` runs first,
produces one number, and the outer query then compares every row's
`unit_price` against that single number. This is called a **scalar
subquery** because it must return exactly one row and one column — if it
returned more, the database would raise an error.

### Subquery returning a list: use with `IN`

```sql
SELECT customer_id, first_name, last_name
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE order_status = 'cancelled'
);
```

This finds every customer who has **at least one** cancelled order. The inner
query returns a list of `customer_id`s (possibly with duplicates — that's
fine for `IN`), and the outer query keeps rows whose `customer_id` appears
anywhere in that list.

### Subquery in `FROM`: treat a query result as a table

```sql
SELECT category, avg_price
FROM (
    SELECT category, AVG(unit_price) AS avg_price
    FROM products
    GROUP BY category
) AS category_averages
WHERE avg_price > 80;
```

Any subquery used in `FROM` **must** have an alias (`category_averages`
here) — this is a hard rule in PostgreSQL and most databases.

### Correlated subquery: the inner query depends on the outer row

```sql
-- Products priced above the average price *within their own category*
SELECT p1.product_name, p1.category, p1.unit_price
FROM products AS p1
WHERE p1.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM products AS p2
    WHERE p2.category = p1.category      -- references the outer query's row!
);
```

> **New term — correlated subquery**: a subquery that references a column
> from the outer query, meaning it conceptually re-runs **once per outer
> row**, using that row's values. This is powerful but can be slow on large
> tables — we'll cover exactly why, and how the optimizer sometimes rewrites
> these automatically, in [Part 5](../../05-performance-and-optimization/01-how-databases-execute-queries/).

### `EXISTS` / `NOT EXISTS`: the safer alternative to `IN` / `NOT IN`

```sql
-- Customers with at least one order (same result as the IN example, different tool)
SELECT customer_id, first_name, last_name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- Customers with NO orders at all
SELECT customer_id, first_name, last_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);
```

`EXISTS` doesn't care *what* the subquery returns — only *whether it returns
any rows at all* (that's why `SELECT 1` is a common convention — the actual
value is irrelevant). This makes `NOT EXISTS` immune to the `NULL` trap that
makes `NOT IN` dangerous (see [Module 03](../03-filtering-and-operators/)) —
**prefer `NOT EXISTS` over `NOT IN` whenever the list comes from a subquery.**

## CTEs: naming your subqueries

> **New term — CTE (Common Table Expression)**: a named, temporary result set
> defined with a `WITH` clause, that you can reference later in the same query
> — like giving a subquery a name and using that name instead of re-writing
> (or nesting) the whole subquery.

The category-average example from above, rewritten as a CTE:

```sql
WITH category_averages AS (
    SELECT category, AVG(unit_price) AS avg_price
    FROM products
    GROUP BY category
)
SELECT category, avg_price
FROM category_averages
WHERE avg_price > 80;
```

For a single use like this, it's roughly equivalent to the subquery version
— but CTEs shine once logic gets more complex, because you can:

**Reference the same CTE multiple times** without repeating its logic:

```sql
WITH order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
)
SELECT
    (SELECT AVG(order_total) FROM order_totals)               AS avg_order_value,
    (SELECT MAX(order_total) FROM order_totals)               AS biggest_order,
    (SELECT COUNT(*) FROM order_totals WHERE order_total > 500) AS orders_over_500;
```

**Chain multiple CTEs**, each building on the last, reading top-to-bottom like
a recipe instead of nesting nine subqueries inside each other:

```sql
WITH order_totals AS (
    SELECT o.order_id, o.customer_id,
           SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
),
customer_lifetime_value AS (
    SELECT customer_id, SUM(order_total) AS lifetime_value
    FROM order_totals
    GROUP BY customer_id
)
SELECT
    c.first_name, c.last_name, clv.lifetime_value
FROM customer_lifetime_value clv
JOIN customers c ON c.customer_id = clv.customer_id
ORDER BY clv.lifetime_value DESC
LIMIT 10;
```

> 💡 **Best practice**: once a query needs more than one nested subquery, or
> the same subquery logic twice, reach for a CTE instead. It costs nothing in
> most modern databases and makes the query dramatically easier for the next
> person (often future-you) to read.

## Recursive CTEs: walking a hierarchy

This is the advanced form, perfect for our employee org chart — it lets a CTE
reference **itself**, repeatedly, until a stopping condition is met.

```sql
WITH RECURSIVE org_chart AS (
    -- Anchor: the top of the hierarchy (no manager)
    SELECT employee_id, full_name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive step: find employees whose manager is already in org_chart
    SELECT e.employee_id, e.full_name, e.manager_id, oc.level + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
)
SELECT employee_id, full_name, level
FROM org_chart
ORDER BY level, employee_id;
```

- The **anchor member** (before `UNION ALL`) is the starting point.
- The **recursive member** (after `UNION ALL`) repeatedly joins back to the
  CTE's own growing result, adding one more "level" of the hierarchy each
  pass, until no new rows are produced (that's the automatic stopping condition).

We'll use this exact pattern again in [Part 3](../../03-database-design-and-modeling/)
when modeling hierarchical dimensions like org charts or product category trees.

## ✅ Try it yourself

```sql
SET search_path TO northstar;

-- Customers whose lifetime revenue is above the average lifetime revenue of all customers
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS lifetime_revenue
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT *
FROM customer_revenue
WHERE lifetime_revenue > (SELECT AVG(lifetime_revenue) FROM customer_revenue)
ORDER BY lifetime_revenue DESC;
```

### Exercises

1. Rewrite the "products priced above their category average" correlated
   subquery from earlier as a query using a CTE instead — which do you find more readable?
2. Find employees who manage at least one other employee (hint: `EXISTS`
   against `employees` referencing itself).
3. Extend the recursive org-chart CTE to also show, for each employee, the
   **path** of names from the top down to them (hint: build a text string in
   the recursive step with `||`).

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
WITH category_avg AS (
    SELECT category, AVG(unit_price) AS avg_price
    FROM products
    GROUP BY category
)
SELECT p.product_name, p.category, p.unit_price
FROM products p
JOIN category_avg ca ON p.category = ca.category
WHERE p.unit_price > ca.avg_price;

-- 2.
SELECT DISTINCT m.employee_id, m.full_name
FROM employees m
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.manager_id = m.employee_id
);

-- 3.
WITH RECURSIVE org_chart AS (
    SELECT employee_id, full_name, manager_id, 1 AS level,
           full_name::text AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.employee_id, e.full_name, e.manager_id, oc.level + 1,
           oc.path || ' -> ' || e.full_name
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
)
SELECT full_name, level, path
FROM org_chart
ORDER BY level, employee_id;
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What's the practical difference between a subquery and a CTE?</summary>

Logically, very little for a single use — a CTE is largely "syntactic sugar"
for readability. The real advantages of CTEs are (1) you can reference the
same named result multiple times without repeating the query, and (2) you
can chain several together top-to-bottom instead of nesting them, which is
far easier for humans to read and debug.
</details>

<details>
<summary>Q: Why prefer NOT EXISTS over NOT IN?</summary>

`NOT IN` returns zero rows for the entire query if the subquery's result
list contains even a single `NULL` — a surprising, easy-to-miss bug (see
[Module 03](../03-filtering-and-operators/)). `NOT EXISTS` has no such trap:
it only cares whether matching rows exist, so `NULL` values in the subquery
don't cause silent, wrong results.
</details>

---
⬅ [Back to Part 1](../) | ➡ Next: [07. Set Operations](../07-set-operations/)
