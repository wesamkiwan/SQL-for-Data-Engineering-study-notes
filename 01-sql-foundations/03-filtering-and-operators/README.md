# 03. Filtering & Operators

*Part of [Part 1 — SQL Foundations](../). Previous: [02. Basic Queries](../02-basic-queries/).*

`WHERE x = 5` gets you far, but real filtering needs more expressive tools.
This module covers the operators you'll use in nearly every query you ever write.

## Logical operators: `AND`, `OR`, `NOT`

```sql
SET search_path TO northstar;

SELECT product_name, category, unit_price
FROM products
WHERE category = 'Electronics' AND unit_price < 50;

SELECT product_name, category
FROM products
WHERE category = 'Books' OR category = 'Toys & Games';

SELECT product_name, is_discontinued
FROM products
WHERE NOT is_discontinued;
```

> ⚠️ **Precedence matters**: `AND` binds tighter than `OR`, exactly like `*`
> binds tighter than `+` in arithmetic. `WHERE a = 1 OR b = 2 AND c = 3` means
> `WHERE a = 1 OR (b = 2 AND c = 3)` — probably not what you meant if you
> wanted "(a=1 or b=2) and c=3". **Always use parentheses when mixing `AND`
> and `OR`** — it costs nothing and prevents a very common bug:

```sql
SELECT product_name, category, unit_price
FROM products
WHERE (category = 'Electronics' OR category = 'Toys & Games')
  AND unit_price < 50;
```

## `BETWEEN`: inclusive ranges

```sql
SELECT product_name, unit_price
FROM products
WHERE unit_price BETWEEN 20 AND 50;   -- includes both 20 and 50
```

This is shorthand for `unit_price >= 20 AND unit_price <= 50`. It works for
dates too:

```sql
SELECT order_id, order_date
FROM orders
WHERE order_date BETWEEN '2024-06-01' AND '2024-06-30';
```

## `IN`: matching against a list

```sql
SELECT product_name, category
FROM products
WHERE category IN ('Electronics', 'Beauty', 'Books');
```

This is shorthand for `category = 'Electronics' OR category = 'Beauty' OR
category = 'Books'` — much cleaner once you have more than two or three
options. `NOT IN` excludes the list instead:

```sql
SELECT product_name, category
FROM products
WHERE category NOT IN ('Electronics', 'Beauty', 'Books');
```

> 🪤 **Common pitfall**: `NOT IN` with a list that could contain `NULL`
> returns **zero rows**, surprisingly — because `x = NULL` is never true or
> false, it's *unknown* (see below), and one `unknown` in the list poisons the
> whole comparison. This is a real, frequently-hit bug. Prefer `NOT EXISTS`
> (covered in [06. Subqueries & CTEs](../06-subqueries-and-ctes/)) when the
> list comes from a subquery that might contain `NULL`.

## `LIKE`: pattern matching on text

```sql
SELECT product_name
FROM products
WHERE product_name LIKE 'Aurora%';   -- starts with "Aurora"

SELECT product_name
FROM products
WHERE product_name LIKE '%Watch%';   -- contains "Watch" anywhere

SELECT email
FROM customers
WHERE email LIKE '_mma%';            -- second character is "mma" — wait, that's wrong, see below
```

Two wildcards:

| Wildcard | Matches |
|---|---|
| `%` | Zero or more of any character |
| `_` | Exactly one of any character |

So `'_mma%'` actually means "any single character, then literally `mma`, then
anything" — matching `Emma...`, `Zmma...`, etc. Use `ILIKE` instead of `LIKE`
in PostgreSQL for a case-insensitive match (`'emma%'` matching `'Emma...'` too)
— plain `LIKE` is case-sensitive in Postgres (this varies by database!).

```sql
SELECT first_name FROM customers WHERE first_name ILIKE 'emma';
```

## `NULL`: the value that means "unknown" or "absent"

> **New term — `NULL`**: a special marker meaning "no value here" — not zero,
> not an empty string, not false. It represents *the absence of any value*.

`NULL` breaks the rules you'd expect from normal comparisons, and this is the
single most common source of subtle SQL bugs for beginners:

```sql
-- This returns ZERO rows, even for employees with no manager!
SELECT full_name FROM employees WHERE manager_id = NULL;

-- This is correct:
SELECT full_name FROM employees WHERE manager_id IS NULL;
```

Why? `NULL` means "unknown," so `manager_id = NULL` literally asks "is this
unknown value equal to unknown?" — the honest answer is "unknown," which SQL
treats as not-true, so the row gets filtered out. You must use `IS NULL` or
`IS NOT NULL` — never `= NULL`.

```sql
-- Employees who ARE someone's manager (they appear in manager_id for someone else)
-- vs employees with no manager (top of the org chart):
SELECT full_name, department
FROM employees
WHERE manager_id IS NULL;
```

This three-valued logic (`TRUE`, `FALSE`, `UNKNOWN`) also explains the `NOT
IN` pitfall above, and will come back when we cover joins and aggregates.
Keep this rule in your back pocket: **any direct comparison to `NULL` (using
`=`, `!=`, `<`, etc.) evaluates to `UNKNOWN`, which is filtered out by `WHERE`
exactly like `FALSE`.**

## ✅ Try it yourself

```sql
SET search_path TO northstar;

-- Orders shipped to English-speaking countries, placed in the last 6 months of 2024
SELECT order_id, shipping_country, order_date
FROM orders
WHERE shipping_country IN ('United States', 'United Kingdom', 'Canada', 'Australia')
  AND order_date BETWEEN '2024-07-01' AND '2024-12-31';
```

### Exercises

1. Find all products priced between $50 and $150 that are in the
   `'Electronics'` or `'Home & Kitchen'` categories.
2. Find all customers whose email address contains `'smith'` (case-insensitive).
3. Find all orders that have **no** assigned employee (hint: think about what
   `NULL` means for `employee_id`).

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
SELECT product_name, category, unit_price
FROM products
WHERE unit_price BETWEEN 50 AND 150
  AND category IN ('Electronics', 'Home & Kitchen');

-- 2.
SELECT first_name, last_name, email
FROM customers
WHERE email ILIKE '%smith%';

-- 3.
SELECT order_id, order_date
FROM orders
WHERE employee_id IS NULL;
```
</details>

## 🧠 Quick check

<details>
<summary>Q: Why does `WHERE manager_id != 3` not return employees whose manager_id is NULL, even though NULL "isn't 3"?</summary>

Because `NULL != 3` doesn't evaluate to `TRUE` — it evaluates to `UNKNOWN`,
for the same reason `NULL = 3` does. `NULL` can't be compared with `!=`
either; you always need `IS NULL` / `IS NOT NULL` to test for it explicitly.
</details>

<details>
<summary>Q: What's the difference between LIKE and ILIKE in PostgreSQL?</summary>

`LIKE` is case-sensitive (`'Emma'` won't match the pattern `'emma%'`).
`ILIKE` is case-insensitive and is PostgreSQL-specific (not standard ANSI
SQL) — other databases achieve the same effect differently, e.g.
`LOWER(column) LIKE LOWER('pattern')`, which also works in PostgreSQL and is
more portable across databases.
</details>

---
⬅ [Back to Part 1](../) | ➡ Next: [04. Aggregations](../04-aggregations/)
