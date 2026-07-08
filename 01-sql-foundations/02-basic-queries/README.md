# 02. Basic Queries

*Part of [Part 1 — SQL Foundations](../). Previous: [01. Databases 101](../01-databases-101/).*

Every SQL query in this repo — no matter how advanced it eventually gets — is
built from the same handful of core clauses. Learn these well; everything else
is refinement.

## `SELECT` and `FROM`: the two you can't live without

```sql
SET search_path TO northstar;

SELECT product_name, category, unit_price
FROM products;
```

Read this the way a human would: "**select** the columns `product_name`,
`category`, and `unit_price`, **from** the table `products`." SQL clauses read
almost like English on purpose — that readability is a real design goal of the
language, not an accident.

> **New term — clause**: one labeled part of a SQL statement (`SELECT`,
> `FROM`, `WHERE`, etc.). A full query is clauses stacked in a specific order.

Want every column instead of naming each one? Use `*` — but be careful, we'll
explain why in a moment.

```sql
SELECT * FROM products;
```

> ⚠️ **Best practice**: avoid `SELECT *` in real pipeline code and application
> queries. It's fine for quick exploration (like right now), but in production
> code it silently breaks if someone adds a column later, and it wastes
> performance by fetching data you don't need. We'll revisit this in
> [Part 5 — Query Optimization](../../05-performance-and-optimization/04-query-optimization-techniques/).

## `WHERE`: filtering rows

`WHERE` keeps only the rows that match a condition — it's evaluated **before**
any columns are selected, row by row, against the raw table data.

```sql
SELECT product_name, unit_price
FROM products
WHERE unit_price > 100;
```

Comparison operators work as you'd expect: `=`, `!=` (or `<>`), `<`, `>`, `<=`, `>=`.

```sql
SELECT product_name, category
FROM products
WHERE category = 'Electronics';
```

> 🪤 **Common pitfall**: SQL uses a single `=` for comparison, not `==` like
> most programming languages. Using `==` in SQL is a syntax error.

## `ORDER BY`: sorting results

Without `ORDER BY`, a database gives you rows in whatever order is convenient
for it internally — **never assume it's meaningful or consistent**. Always sort
explicitly if order matters to you.

```sql
SELECT product_name, unit_price
FROM products
ORDER BY unit_price DESC;   -- highest price first. Default is ASC (ascending).
```

You can sort by multiple columns — ties in the first column are broken by the second:

```sql
SELECT product_name, category, unit_price
FROM products
ORDER BY category ASC, unit_price DESC;
```

## `LIMIT` and `OFFSET`: taking a slice of results

```sql
SELECT product_name, unit_price
FROM products
ORDER BY unit_price DESC
LIMIT 5;                -- just the 5 most expensive products
```

`OFFSET` skips rows — useful for pagination (e.g., "page 2" of results):

```sql
SELECT product_name, unit_price
FROM products
ORDER BY unit_price DESC
LIMIT 5 OFFSET 5;        -- the *next* 5 most expensive products
```

> **New term — pagination**: splitting a large result set into smaller
> "pages" so an application doesn't have to load everything at once.
> `LIMIT`/`OFFSET` is the simplest way to do it, though at very large scale
> data engineers often use "keyset pagination" instead (filtering on the last
> seen value) because `OFFSET` gets slower the deeper you page — you'll
> understand exactly why after [Part 5](../../05-performance-and-optimization/).

## `DISTINCT`: removing duplicate rows

```sql
SELECT DISTINCT category
FROM products;
```

This returns each unique category exactly once. `DISTINCT` applies to the
**whole row** of selected columns, not each column independently — so
`SELECT DISTINCT category, is_discontinued` returns each unique
*combination* of the two.

## Aliases: renaming columns and tables in your output

```sql
SELECT
    product_name AS name,
    unit_price   AS price_usd
FROM products AS p
ORDER BY price_usd DESC
LIMIT 3;
```

`AS` is optional (`unit_price price_usd` works too) but writing it explicitly
makes queries far more readable — we'll always write it out in this repo.

## Comments

```sql
-- A single-line comment, ignored by the database entirely.
SELECT product_name  -- you can also comment at the end of a line
FROM products;

/* A multi-line comment,
   useful for explaining a whole block of logic. */
```

Comment your SQL the same way you'd comment any code: explain *why*, not
*what* — the SQL itself already says what it does.

## Putting it together: clause order

SQL clauses must be **written** in this order:

```
SELECT ... 
FROM ...
WHERE ...
ORDER BY ...
LIMIT ...
```

But here's a subtlety that trips up almost every beginner: they are not
**evaluated** in that order. The database conceptually processes `FROM` and
`WHERE` first (find and filter the rows), then `SELECT` (pick/compute the
columns), then `ORDER BY`, then `LIMIT`. You don't need to memorize this yet —
it will matter a lot once we reach `GROUP BY` in the next module, and we'll
give you the complete picture then.

## ✅ Try it yourself

```sql
SET search_path TO northstar;

SELECT first_name, last_name, country, signup_date
FROM customers
WHERE country = 'Germany'
ORDER BY signup_date DESC
LIMIT 10;
```

### Exercises

1. List the names of every distinct country that appears in `customers`, alphabetically.
2. Find the 5 cheapest products that are **not** discontinued, showing name,
   category, and price, cheapest first.
3. Show the 3rd and 4th most expensive products only (hint: combine `LIMIT` and `OFFSET`).

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
SELECT DISTINCT country
FROM customers
ORDER BY country ASC;

-- 2.
SELECT product_name, category, unit_price
FROM products
WHERE is_discontinued = false
ORDER BY unit_price ASC
LIMIT 5;

-- 3.
SELECT product_name, unit_price
FROM products
ORDER BY unit_price DESC
LIMIT 2 OFFSET 2;
```
</details>

## 🧠 Quick check

<details>
<summary>Q: Does WHERE run before or after ORDER BY?</summary>

Before. Conceptually, the database filters rows with `WHERE` first, and only
sorts the *surviving* rows afterward with `ORDER BY`. This is also why you
can't use `WHERE` to filter on something that doesn't exist until later in
processing — like an aggregate result (that's what `HAVING` is for, coming up
in the next module).
</details>

<details>
<summary>Q: Is SELECT * ever OK to use?</summary>

Yes — during interactive exploration, when you're just getting to know a
table and want to see everything. The rule against it is specifically about
code that will run repeatedly in an application or pipeline, where an
unexpected new column or wasted bandwidth can cause real problems.
</details>

---
⬅ [Back to Part 1](../) | ➡ Next: [03. Filtering & Operators](../03-filtering-and-operators/)
