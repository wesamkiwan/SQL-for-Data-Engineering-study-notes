# 03. Snowflake

*Part of [Part 7 — Cloud Data Platforms](../). Previous: [02. Google BigQuery](../02-google-bigquery/).*

Snowflake was one of the pioneers of the separated storage/compute cloud
warehouse architecture, and remains one of the most widely used platforms
in the industry. Unlike BigQuery's fully serverless model, Snowflake gives
you explicit, named compute resources called **virtual warehouses**.

## Getting access

Snowflake offers a time-limited free trial with starting credits for new
accounts — sign up at [signup.snowflake.com](https://signup.snowflake.com)
and choose any cloud provider/region (this choice doesn't affect the SQL
you'll write). Snowsight, Snowflake's web UI, includes a SQL worksheet with no local setup.

## Virtual warehouses: named, resizable compute

> **New term (Snowflake-specific) — virtual warehouse**: a named, sizeable
> cluster of compute resources you create explicitly and use to run
> queries — distinct from *storage*, which exists independently. This is
> the concrete implementation of the provisioned/resizable compute idea
> introduced generally in [Module 01](../01-cloud-warehousing-overview/) and
> [Part 5, Module 06](../../05-performance-and-optimization/06-cloud-cost-optimization/).

```sql
CREATE WAREHOUSE northstar_wh
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60          -- suspend after 60 seconds idle
    AUTO_RESUME = TRUE;        -- instantly resume when a new query arrives

USE WAREHOUSE northstar_wh;
```

Recall **auto-suspend/auto-resume** directly from
[Part 5, Module 06](../../05-performance-and-optimization/06-cloud-cost-optimization/) —
this is the exact platform feature that guidance was describing. You pay
per-second for warehouse compute time *while it's running*; a warehouse
correctly configured to auto-suspend costs nothing while idle.

```sql
-- Resize on demand — no data movement required, because storage is separate
ALTER WAREHOUSE northstar_wh SET WAREHOUSE_SIZE = 'LARGE';
```

You can also run **multiple warehouses simultaneously** against the exact
same data — e.g., a small warehouse for a dashboard's frequent light
queries, and a separate large warehouse for a nightly heavy transformation
job — each billed and scaled completely independently, with zero
contention between them, since they're physically separate compute resources.

## Setting up the schema and loading data

```sql
CREATE DATABASE northstar;
CREATE SCHEMA northstar.public;
USE SCHEMA northstar.public;

CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    first_name      VARCHAR,
    last_name       VARCHAR,
    email           VARCHAR,
    country         VARCHAR,
    signup_date     DATE,
    is_active       BOOLEAN
);
-- (repeat for the other NorthStar Retail tables from
-- datasets/postgres/00_schema.sql, adjusting types as needed — Snowflake's
-- type system is close enough to PostgreSQL's that this is mostly direct)

-- Load from a file staged in cloud storage (or Snowflake's own internal stage)
COPY INTO customers
FROM @my_stage/customers.csv
FILE_FORMAT = (TYPE = 'CSV', SKIP_HEADER = 1);
```

## Micro-partitions: automatic, invisible partitioning

> **New term (Snowflake-specific) — micro-partition**: Snowflake
> automatically splits every table into small (roughly 50–500MB)
> compressed, columnar storage units, and maintains rich metadata (min/max
> values per column) about what each one contains — **entirely
> automatically**, with no `PARTITION BY` statement required at all.

This is a meaningfully different approach from BigQuery's explicit
`PARTITION BY`/`CLUSTER BY` ([Module 02](../02-google-bigquery/)) or
PostgreSQL's manual partitioning ([Part 5, Module 03](../../05-performance-and-optimization/03-partitioning-and-clustering/)):
Snowflake's query optimizer uses the automatically-maintained min/max
metadata to prune micro-partitions that can't possibly match your query's
filters — the same **pruning** concept you already know, just automatic
rather than something you explicitly configure from day one.

For very large tables where the *natural* insertion order doesn't align
well with how you typically query (causing less effective automatic
pruning), Snowflake lets you optionally define a **clustering key** to
guide how data is organized:

```sql
ALTER TABLE orders CLUSTER BY (order_date);
```

## Time Travel: querying your data as it existed in the past

> **New term (Snowflake-specific) — Time Travel**: the ability to query a
> table's data as it existed at a **past point in time** — directly,
> without needing a separate backup or manual snapshot.

```sql
-- Query the orders table as it existed exactly 1 hour ago
SELECT * FROM orders AT (OFFSET => -3600);

-- Or as of a specific timestamp
SELECT * FROM orders AT (TIMESTAMP => '2024-06-15 09:00:00'::TIMESTAMP);

-- Restore an accidentally-dropped table entirely
UNDROP TABLE orders;
```

This has direct, practical value connecting back to several earlier
modules: it's a safety net against an accidental `DELETE`/`UPDATE` without a
`WHERE` clause ([Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/)),
and it can support certain [Part 6 compliance](../../06-security/05-compliance-and-governance/)
investigations ("what did this record look like before it was changed?")
without needing a separate audit table for every possible column.

## Zero-copy cloning: instant, storage-free table/database copies

> **New term (Snowflake-specific) — zero-copy cloning**: creating a full
> copy of a table, schema, or entire database **instantly**, without
> physically duplicating the underlying data — the clone only stores
> changes made *after* the clone point; unchanged data is transparently shared.

```sql
-- Instantly create a full copy of the production schema for testing —
-- takes seconds regardless of the underlying data's actual size
CREATE SCHEMA northstar_dev CLONE northstar.public;
```

This is transformative for data engineering workflows: you can clone an
entire production database to safely test a risky transformation or schema
migration, without waiting for (or paying the storage cost of) a full
physical copy — directly useful for testing the pipeline patterns from
[Part 4](../../04-data-engineering-with-sql/) before running them for real.

## Semi-structured data: `VARIANT`

Recall JSON/semi-structured data concepts from
[Part 2, Module 06](../../02-intermediate-advanced-sql/06-json-and-semistructured-data/).
Snowflake's equivalent to PostgreSQL's `JSONB` is `VARIANT` — a single type
that can hold JSON, Avro, Parquet, or XML-derived structured data:

```sql
CREATE TABLE web_events (
    event_id    INTEGER,
    customer_id INTEGER,
    event_type  VARCHAR,
    payload     VARIANT
);

-- Similar dot/colon notation instead of PostgreSQL's -> and ->>
SELECT
    event_id,
    payload:url::STRING AS url,
    payload:device::STRING AS device
FROM web_events
WHERE event_type = 'page_view';
```

The concept is identical to what you already learned — extracting fields
from semi-structured data, with an explicit cast to a concrete type
(`::STRING` here plays the same role `->>` plus a cast played in
PostgreSQL) — only the specific syntax differs.

## Security features, mapped to Part 6

| Part 6 concept | Snowflake implementation |
|---|---|
| RBAC ([Module 02](../../06-security/02-authentication-and-authorization/)) | Native roles, `GRANT`/`REVOKE` — syntax nearly identical to what you already know |
| Dynamic data masking ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Native masking policies, applied directly to columns |
| Row-level security ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Native row access policies |
| Encryption ([Module 03](../../06-security/03-encryption/)) | Encrypted at rest and in transit by default, always |

## Monitoring cost (credits)

```sql
-- Snowflake bills compute in "credits" — see usage directly
SELECT warehouse_name, SUM(credits_used) AS total_credits
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_credits DESC;
```

## ✅ Try it yourself

If you have a Snowflake trial account set up:

```sql
CREATE WAREHOUSE IF NOT EXISTS northstar_wh WAREHOUSE_SIZE = 'X-SMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
USE WAREHOUSE northstar_wh;

SELECT order_status, COUNT(*) AS num_orders
FROM northstar.public.orders
GROUP BY order_status
ORDER BY num_orders DESC;
```

### Exercises

1. Write the SQL to create an `X-SMALL` warehouse that auto-suspends after
   just 30 seconds of inactivity — when would a very short auto-suspend
   window like this be the right choice, versus a longer one?
2. Explain, referencing [Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/),
   how Time Travel could have saved someone who ran an `UPDATE` without a
   `WHERE` clause, even after the mistaken statement already committed.
3. Explain why zero-copy cloning is described as "storage-free" at the
   moment of cloning, but not necessarily forever afterward.

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
CREATE WAREHOUSE bursty_wh WAREHOUSE_SIZE = 'X-SMALL' AUTO_SUSPEND = 30 AUTO_RESUME = TRUE;
```

```text
A short auto-suspend window suits bursty, unpredictable workloads (ad-hoc
analyst queries) where minimizing idle billing matters more than the small
resume latency. A longer window suits workloads with frequent, closely-spaced
queries (e.g., a dashboard refreshed by many users throughout the day),
where suspending and resuming repeatedly would add unnecessary resume
latency for little billing benefit.

2. Even after an UPDATE without a WHERE clause commits (recall that
   COMMIT makes a transaction's changes permanent — Part 2, Module 03 — so
   a simple ROLLBACK is no longer possible once committed), Time Travel
   lets you query the table AS IT EXISTED just before the mistaken UPDATE
   ran, then use that historical snapshot to restore the correct data —
   a safety net that exists specifically BECAUSE normal transactional
   rollback is no longer available post-commit.

3. At the moment of cloning, the clone shares 100% of its underlying data
   files with the original — no new storage is consumed, hence
   "storage-free." But as soon as EITHER the original or the clone is
   modified going forward, the changed portions must be stored separately
   for each (since they've now diverged) — so storage usage grows over
   time proportional to how much the two versions actually differ, not
   proportional to the clone's total logical size.
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What's the key architectural difference between Snowflake's virtual warehouses and BigQuery's approach to compute?</summary>

Snowflake requires you to explicitly create and size named virtual
warehouses, which you control, resize, and can run multiple of
simultaneously for workload isolation. BigQuery is fully serverless — there
is no compute resource for you to create, size, or manage at all; the
platform allocates it transparently per query.
</details>

<details>
<summary>Q: How does Snowflake achieve partition-pruning-like performance without requiring an explicit PARTITION BY statement?</summary>

Snowflake automatically splits every table into micro-partitions and
maintains min/max metadata about each one's contents, letting the query
optimizer skip micro-partitions that can't match a query's filters — all
done automatically, in contrast to BigQuery's or PostgreSQL's approach of
requiring an explicit partitioning scheme to be defined upfront.
</details>

---
⬅ [Back to Part 7](../) | ➡ Next: [04. AWS Redshift](../04-aws-redshift/)
