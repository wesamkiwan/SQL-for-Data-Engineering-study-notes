# 02. Google BigQuery

*Part of [Part 7 — Cloud Data Platforms](../). Previous: [01. Cloud Warehousing Overview](../01-cloud-warehousing-overview/).*

BigQuery is Google Cloud's fully serverless data warehouse, and the
purest real-world example of the on-demand, bytes-scanned pricing model
introduced in [Part 5, Module 06](../../05-performance-and-optimization/06-cloud-cost-optimization/).

## Getting access

Google Cloud offers an ongoing free tier (not just a trial) that includes a
genuinely usable monthly allotment of free query processing and storage —
enough to work through everything in this module. Set up a project at
[Google Cloud Console](https://console.cloud.google.com/) and open
**BigQuery Studio** to get a SQL editor with zero local setup required.

## Architecture: no infrastructure, at all

Recall "fully serverless" from [Module 01](../01-cloud-warehousing-overview/):
there is no cluster, no warehouse, no server size to choose. You write SQL,
submit it, and BigQuery transparently allocates however much distributed
compute the query needs behind the scenes, then releases it. This is the
most direct real-world example of the shared-disk, distributed architecture
from [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/) —
BigQuery's engine (internally called Dremel) automatically handles sharding,
shuffling, and broadcast joins for you, with zero configuration.

## The organizational hierarchy: Project → Dataset → Table

```sql
-- BigQuery table references use backticks and this exact hierarchy:
SELECT * FROM `my-project-id.northstar.orders`;
```

> **New term (BigQuery-specific) — dataset**: BigQuery's name for what
> every other platform in this repo (and this repo's own
> [`datasets/postgres/00_schema.sql`](../../datasets/postgres/00_schema.sql))
> calls a **schema** — a named container for tables. Don't confuse this with
> our repo's general use of "dataset" to mean "the NorthStar Retail sample data" —
> in BigQuery specifically, "dataset" is the schema-level container.

## Loading the NorthStar Retail dataset into BigQuery

```sql
-- Create the dataset (schema)
CREATE SCHEMA IF NOT EXISTS `my-project-id.northstar`;

-- BigQuery can query CSV/Parquet files directly from Google Cloud Storage,
-- or you can load them into native BigQuery storage:
LOAD DATA INTO `my-project-id.northstar.customers`
FROM FILES (
    format = 'CSV',
    uris = ['gs://my-bucket/customers.csv']
);
```

(You'd export each NorthStar Retail table from your PostgreSQL instance to
CSV first — `\copy customers TO 'customers.csv' CSV HEADER` in `psql` — then
upload to Cloud Storage and load as shown.)

## SQL dialect notes

Most of what you know transfers directly. Here's what's genuinely different:

### Date/time functions

```sql
-- Recall DATE_TRUNC from Part 1, Module 08 — same name, same concept, works in BigQuery:
SELECT DATE_TRUNC(order_date, MONTH) AS order_month, COUNT(*) AS num_orders
FROM `my-project-id.northstar.orders`
GROUP BY order_month;

-- BigQuery-specific: date arithmetic uses DATE_ADD/DATE_SUB with explicit units
SELECT DATE_ADD(order_date, INTERVAL 30 DAY) AS estimated_followup
FROM `my-project-id.northstar.orders`;
```

### `GROUP BY` column aliases — this one's genuinely more convenient than Postgres

Recall the pitfall from [Part 1, Module 08](../../01-sql-foundations/08-string-date-numeric-functions/) —
PostgreSQL doesn't let you `GROUP BY` a `SELECT` alias, due to logical
evaluation order. **BigQuery does allow it**:

```sql
-- This works directly in BigQuery (would need the full expression repeated in Postgres)
SELECT DATE_TRUNC(order_date, MONTH) AS order_month, COUNT(*) AS num_orders
FROM `my-project-id.northstar.orders`
GROUP BY order_month;
```

### `STRUCT` and `ARRAY`: native nested data, beyond JSON

Recall semi-structured data from
[Part 2, Module 06](../../02-intermediate-advanced-sql/06-json-and-semistructured-data/).
BigQuery supports `JSON` similarly to PostgreSQL, but also has **native**
nested and repeated fields (`STRUCT` and `ARRAY`) as first-class column
types — letting you model one-to-many relationships (like `orders` to
`order_items`) *within a single table*, avoiding a join entirely:

```sql
-- A denormalized orders table with order_items nested directly as an ARRAY of STRUCTs
SELECT
    order_id,
    order_date,
    order_items   -- an ARRAY<STRUCT<product_id INT64, quantity INT64, unit_price NUMERIC>>
FROM `my-project-id.northstar.orders_nested`;

-- Flatten a nested/repeated field into rows, with UNNEST — conceptually
-- similar to jsonb_array_elements from Part 2, Module 06
SELECT o.order_id, item.product_id, item.quantity
FROM `my-project-id.northstar.orders_nested` AS o, UNNEST(o.order_items) AS item;
```

This is a genuinely different modeling option worth recognizing: instead of
a normalized `orders` + `order_items` (Part 1, Module 05's join pattern),
BigQuery often favors nesting the one-to-many relationship directly into a
single wide table — a natural extension of the **One Big Table** idea from
[Part 3, Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/),
taken further than a traditional RDBMS allows.

## Partitioning and clustering: directly tied to cost

Recall from [Part 5, Modules 03 and 06](../../05-performance-and-optimization/03-partitioning-and-clustering/)
that partition pruning reduces bytes scanned — and bytes scanned is
literally BigQuery's billing unit. This makes partitioning a **direct,
quantifiable cost control**, not just a speed optimization:

```sql
CREATE TABLE `my-project-id.northstar.orders_optimized`
PARTITION BY order_date
CLUSTER BY customer_id, order_status
AS SELECT * FROM `my-project-id.northstar.orders`;
```

- **`PARTITION BY`** splits the table physically by date (or an integer
  range) — a query filtered to one month scans only that month's partition,
  billed accordingly.
- **`CLUSTER BY`** (recall the concept from
  [Part 5, Module 03](../../05-performance-and-optimization/03-partitioning-and-clustering/))
  sorts data *within* each partition by the given columns, letting BigQuery
  skip irrelevant blocks even within a scanned partition — unlike
  PostgreSQL's one-time manual `CLUSTER` command, BigQuery clustering is
  maintained **automatically** as new data arrives.

## Estimating and monitoring cost

```sql
-- The BigQuery UI shows an estimated bytes-processed count BEFORE you run
-- a query — always check this for large, ad-hoc queries, exactly per the
-- habit recommended in Part 5, Module 06.

-- After the fact, query your own job history for cost visibility:
SELECT
    query,
    total_bytes_processed,
    total_bytes_processed / POW(10, 12) AS terabytes_processed,
    user_email,
    creation_time
FROM `my-project-id.region-us.INFORMATION_SCHEMA.JOBS`
ORDER BY creation_time DESC
LIMIT 20;
```

This is BigQuery's platform-specific extension of the
`information_schema` concept you first saw in
[Part 1, Module 01](../../01-sql-foundations/01-databases-101/) — same
underlying idea (query the system about itself), extended here with
billing-relevant fields specific to this platform.

## Security features, mapped to Part 6

| Part 6 concept | BigQuery implementation |
|---|---|
| RBAC ([Module 02](../../06-security/02-authentication-and-authorization/)) | Cloud IAM roles, granted at the project, dataset, or table level |
| Row-level security ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Native `CREATE ROW ACCESS POLICY` |
| Dynamic data masking ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Native, built-in column-level data masking policies |
| Encryption at rest ([Module 03](../../06-security/03-encryption/)) | Enabled by default on all data, with optional customer-managed keys (CMEK) |

## ✅ Try it yourself

If you have a BigQuery project set up, try this directly in BigQuery Studio
(adjust the fully-qualified table names to your project):

```sql
SELECT
    DATE_TRUNC(order_date, MONTH) AS month,
    order_status,
    COUNT(*) AS num_orders
FROM `my-project-id.northstar.orders`
GROUP BY month, order_status
ORDER BY month;
```

### Exercises

1. Write the `CREATE TABLE ... PARTITION BY ... CLUSTER BY` statement you'd
   use for a `web_events` table (recall [Part 2, Module 06](../../02-intermediate-advanced-sql/06-json-and-semistructured-data/)),
   partitioned by `event_time` and clustered by `customer_id`.
2. Explain, using this module's concepts, why running `SELECT * FROM
   orders` on a huge, un-partitioned BigQuery table is a direct cost
   mistake, not just a style one (connect this back to
   [Part 5, Module 06](../../05-performance-and-optimization/06-cloud-cost-optimization/)).
3. Would you model `orders`/`order_items` as two separate tables (like our
   PostgreSQL schema) or as one table with a nested `ARRAY<STRUCT<...>>`
   column in BigQuery? What would inform that choice?

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
CREATE TABLE `my-project-id.northstar.web_events`
PARTITION BY DATE(event_time)
CLUSTER BY customer_id
AS SELECT * FROM `my-project-id.northstar.web_events_raw`;
```

```text
2. BigQuery bills based on bytes scanned by a query. SELECT * forces the
   engine to read every column's data (recall columnar storage from Part 3,
   Module 03 — only requested columns are normally read), directly
   increasing the bytes processed and therefore the bill, even if most of
   those columns are immediately discarded and never used in the result.
   On a huge table, this can turn a query that should cost pennies into one
   costing substantially more, for zero actual benefit.

3. Two separate, normalized tables fit better if order_items is frequently
   queried, filtered, or joined independently of its parent order (e.g.,
   "which products sell best" queries scanning order_items alone) — nesting
   would force scanning/unnesting the parent orders table every time. A
   nested ARRAY<STRUCT> fits better if orders and their items are almost
   ALWAYS read together as a unit (e.g., "show me this order's full
   details"), since it avoids a join entirely for that dominant access
   pattern. This is a genuine, deliberate modeling tradeoff, not a
   one-size-fits-all answer.
```
</details>

## 🧠 Quick check

<details>
<summary>Q: Why does partitioning have a more DIRECT cost impact on BigQuery specifically, compared to a fixed-size provisioned warehouse?</summary>

BigQuery bills per byte scanned by each query — partition pruning
(Part 5, Module 03) directly reduces bytes scanned, which directly reduces
that query's bill. On a fixed-size provisioned warehouse running for a
fixed block of time regardless of how much data a query touches, the same
partitioning still improves speed, but the cost connection is less direct
since you're already paying for the compute time whether or not it's fully utilized.
</details>

<details>
<summary>Q: What BigQuery-specific column types let you model one-to-many relationships within a single table?</summary>

`ARRAY` (a repeated field) and `STRUCT` (a nested record), often combined
as `ARRAY<STRUCT<...>>` — letting a single row hold what would otherwise
require a separate, joined child table, extending the One Big Table
philosophy from Part 3, Module 04 further than a traditional RDBMS allows.
</details>

---
⬅ [Back to Part 7](../) | ➡ Next: [03. Snowflake](../03-snowflake/)
