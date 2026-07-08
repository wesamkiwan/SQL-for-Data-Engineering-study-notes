# 05. Stored Procedures, Functions & Triggers

*Part of [Part 2 — Intermediate & Advanced SQL](../). Previous: [04. Views & Materialized Views](../04-views-and-materialized-views/).*

Everything so far has been logic you write and re-run manually. This module
covers packaging that logic **inside the database itself**, so it runs on
demand (functions/procedures) or automatically in response to data changes
(triggers) — and, just as importantly, when *not* to do that.

## User-defined functions

> **New term — user-defined function (UDF)**: a named, reusable piece of
> logic, stored in the database, that takes inputs and returns a value — you
> call it inside a query exactly like a built-in function such as `ROUND()`.

```sql
SET search_path TO northstar;

CREATE FUNCTION profit_margin_pct(price NUMERIC, cost NUMERIC)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT ROUND(((price - cost) / NULLIF(price, 0)) * 100, 1);
$$;
```

Now you can use it anywhere a normal expression goes:

```sql
SELECT
    product_name,
    unit_price,
    cost_price,
    profit_margin_pct(unit_price, cost_price) AS margin_pct
FROM products
ORDER BY margin_pct DESC;
```

- `LANGUAGE SQL` means the function's body is plain SQL (PostgreSQL also
  supports `LANGUAGE plpgsql` for more complex, procedural logic with loops
  and conditionals — see below).
- `IMMUTABLE` tells PostgreSQL this function always returns the same output
  for the same input, with no side effects — an important promise that lets
  the query optimizer cache/reuse its results more aggressively. Get this
  wrong (mark something `IMMUTABLE` that isn't, e.g., one that reads
  `CURRENT_DATE`) and you can get subtly wrong query results — only use it
  when it's genuinely true.

## `plpgsql`: functions with real procedural logic

For anything needing loops, conditionals, or multiple steps, PostgreSQL's
procedural extension `PL/pgSQL` is the standard choice:

```sql
CREATE FUNCTION customer_tier(p_customer_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    total_spend NUMERIC;
BEGIN
    SELECT COALESCE(SUM(oi.quantity * oi.unit_price), 0)
    INTO total_spend
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id;

    IF total_spend >= 800 THEN
        RETURN 'Gold';
    ELSIF total_spend >= 200 THEN
        RETURN 'Silver';
    ELSIF total_spend > 0 THEN
        RETURN 'Bronze';
    ELSE
        RETURN 'No purchases yet';
    END IF;
END;
$$;

SELECT customer_id, customer_tier(customer_id) AS tier
FROM customers
LIMIT 10;
```

This is the exact same tiering logic from
[Module 09's CASE example](../../01-sql-foundations/09-case-and-conditional-logic/),
just packaged behind a name — a good illustration of the tradeoff coming up next.

## Stored procedures: for actions, not just values

> **New term — stored procedure**: similar to a function, but designed to be
> **called directly** (via `CALL`) to *perform an action* — often involving
> multiple statements and its own transaction control — rather than to
> return a single value used inside a query.

```sql
CREATE PROCEDURE archive_old_cancelled_orders(cutoff_date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO orders_archive
    SELECT * FROM orders
    WHERE order_status = 'cancelled' AND order_date < cutoff_date;

    DELETE FROM orders
    WHERE order_status = 'cancelled' AND order_date < cutoff_date;

    COMMIT;  -- procedures can manage their own transactions; functions cannot
END;
$$;

CALL archive_old_cancelled_orders('2024-01-01');
```

| | Function | Procedure |
|---|---|---|
| Called with | Inside an expression / `SELECT` | `CALL procedure_name(...)` |
| Returns | A value (required) | Nothing, or `OUT` parameters |
| Can manage transactions (`COMMIT`/`ROLLBACK`)? | No | Yes |
| Typical use | Computing a reusable value | Performing a multi-step action |

## The real tradeoff: should logic live in the database at all?

This is a genuinely important, debated design decision in data engineering —
not just trivia.

**Arguments for logic in the database (functions/procedures/triggers):**
- Enforces a rule *no matter what* touches the data — even a rogue script or
  a different application, because the rule lives with the data itself.
- Can be more efficient — the logic runs right next to the data, with no
  network round-trip back to an application.

**Arguments against:**
- Business logic becomes harder to version-control, test, and code-review
  compared to application code in a normal codebase with CI/CD.
- It's easy to forget it exists — a colleague debugging "unexpected" data
  changes might not think to check for a trigger.
- It ties your logic to one specific database's procedural language
  (`plpgsql`, T-SQL, PL/SQL are all different), hurting portability —
  directly relevant once you reach [Part 7](../../07-cloud-data-platforms/)
  and see that BigQuery, Snowflake, and Redshift each handle this differently.

> 💡 **Modern data engineering default**: prefer keeping transformation logic
> in version-controlled SQL files managed by a tool like dbt (introduced in
> [Part 4](../../04-data-engineering-with-sql/03-orchestration-basics/)) over
> stored procedures, specifically *because* of the maintainability and
> portability tradeoffs above. Reach for procedures/functions/triggers
> deliberately, for genuine data-integrity guarantees — not as your default
> place to put business logic.

## Triggers: logic that runs automatically on data changes

> **New term — trigger**: a function that the database calls automatically
> whenever a specified event (`INSERT`, `UPDATE`, or `DELETE`) happens on a
> specified table — you never call it directly.

A very common real use: automatically maintaining an audit trail.

```sql
CREATE TABLE product_price_history (
    history_id   SERIAL PRIMARY KEY,
    product_id   INTEGER NOT NULL,
    old_price    NUMERIC(10,2),
    new_price    NUMERIC(10,2),
    changed_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE FUNCTION log_price_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.unit_price IS DISTINCT FROM OLD.unit_price THEN
        INSERT INTO product_price_history (product_id, old_price, new_price)
        VALUES (OLD.product_id, OLD.unit_price, NEW.unit_price);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_price_change
AFTER UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION log_price_change();
```

Now, *every single* `UPDATE` that changes `unit_price` — from any source,
any application, any analyst running ad-hoc SQL — automatically gets logged,
with zero chance of anyone forgetting to log it manually.

```sql
-- Try it: this UPDATE will silently also insert a row into product_price_history
UPDATE products SET unit_price = unit_price * 1.05 WHERE product_id = 1;
SELECT * FROM product_price_history;
```

`NEW` and `OLD` are special references available inside a trigger function:
`OLD` is the row *before* the change, `NEW` is the row *after* (only `NEW`
exists for `INSERT` triggers; only `OLD` exists for `DELETE` triggers).

> 🪤 **Common pitfall**: triggers are invisible in the query that fires them
> — the `UPDATE` statement above shows no hint that it also touched
> `product_price_history`. This "spooky action at a distance" is exactly why
> the tradeoff discussion above matters: triggers are powerful precisely
> because they're automatic and unavoidable, and dangerous for the same reason.

## ✅ Try it yourself

```sql
SET search_path TO northstar;

-- A function that classifies an order as small/medium/large by its item count
CREATE FUNCTION order_size_label(item_count INTEGER)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT CASE
        WHEN item_count <= 1 THEN 'Small'
        WHEN item_count <= 3 THEN 'Medium'
        ELSE 'Large'
    END;
$$;

SELECT
    o.order_id,
    COUNT(oi.order_item_id) AS item_count,
    order_size_label(COUNT(oi.order_item_id)::INTEGER) AS size_label
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id
ORDER BY item_count DESC
LIMIT 10;
```

### Exercises

1. Write a SQL function `days_since(d DATE)` that returns how many days have
   passed between the given date and today.
2. Write a trigger that prevents (raises an error on) any `UPDATE` that would
   set a product's `unit_price` below its `cost_price` — a real data-integrity
   guardrail (hint: research `RAISE EXCEPTION` inside a `BEFORE UPDATE` trigger).
3. In your own words, explain one scenario where a trigger is clearly the
   right tool, and one where it would be better handled in application or
   pipeline code instead.

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
CREATE FUNCTION days_since(d DATE)
RETURNS INTEGER
LANGUAGE SQL
STABLE   -- depends on CURRENT_DATE, which changes daily, so not IMMUTABLE
AS $$
    SELECT (CURRENT_DATE - d);
$$;

-- 2.
CREATE FUNCTION prevent_underpriced_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.unit_price < NEW.cost_price THEN
        RAISE EXCEPTION 'unit_price (%) cannot be less than cost_price (%) for product %',
            NEW.unit_price, NEW.cost_price, NEW.product_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_prevent_underpriced_update
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION prevent_underpriced_update();

-- 3. (conceptual)
-- Right tool: enforcing a hard data-integrity rule that must NEVER be
-- violated regardless of what application or script writes to the table
-- (like exercise 2's price guardrail) — the guarantee is worth the
-- maintainability cost.
-- Better elsewhere: general business/transformation logic, like computing
-- customer tiers or monthly revenue rollups — that belongs in
-- version-controlled, testable pipeline code (e.g., dbt models, covered in
-- Part 4), where it's visible, reviewable, and portable.
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What's the key difference between a function and a stored procedure in PostgreSQL?</summary>

A function must return a value and is called inside an expression or
`SELECT` statement; it cannot manage its own transactions. A procedure is
called with `CALL`, doesn't have to return a value, and can `COMMIT`/`ROLLBACK`
internally — making it suited to multi-step actions rather than value computation.
</details>

<details>
<summary>Q: Why is it risky to put important business logic only inside a database trigger?</summary>

Because triggers execute invisibly, outside of the SQL statement that
triggers them — a developer reading the calling code has no indication the
trigger exists or what it does. This makes triggers easy to forget about,
hard to test in isolation, and harder to track in version control compared
to logic written explicitly in application or pipeline code.
</details>

---
⬅ [Back to Part 2](../) | ➡ Next: [06. JSON & Semi-Structured Data](../06-json-and-semistructured-data/)
