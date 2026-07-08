# 04. AWS Redshift

*Part of [Part 7 — Cloud Data Platforms](../). Previous: [03. Snowflake](../03-snowflake/).*

Redshift is Amazon Web Services' data warehouse, and — being one of the
older cloud warehouses — it gives you more direct, explicit control over
data distribution than BigQuery or Snowflake, making it an excellent
platform for solidifying the distributed query concepts from
[Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/).

## Getting access

AWS Free Tier includes limited Redshift Serverless usage for new accounts —
sign up through the [AWS Console](https://aws.amazon.com/redshift/) and use
the Redshift Query Editor v2 for a browser-based SQL environment with no local setup.

## Provisioned clusters vs. Redshift Serverless

Recall the serverless/provisioned spectrum from
[Module 01](../01-cloud-warehousing-overview/). Redshift offers both:

- **Provisioned clusters**: you explicitly choose node type and count — full
  control, billed per node-hour whether or not you're actively querying.
- **Redshift Serverless**: automatically provisions and scales capacity,
  billed per second of actual usage — the better starting point for
  learning, and what the free tier covers.

## Distribution styles: explicit control over data placement

Recall **data skew** and **shuffle** from
[Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/) —
Redshift is unusual among modern cloud warehouses in that **you explicitly
choose** how each table's rows are distributed across nodes, rather than
the platform handling it invisibly:

```sql
-- KEY distribution: rows are distributed based on a hash of the specified
-- column — rows with the same key always land on the same node, which is
-- exactly what avoids a shuffle when joining on that same column
CREATE TABLE orders (
    order_id         INTEGER,
    customer_id      INTEGER,
    order_date       DATE,
    order_status     VARCHAR(20),
    shipping_country VARCHAR(56)
)
DISTSTYLE KEY
DISTKEY (customer_id);

-- ALL distribution: a FULL COPY of the table is stored on every node —
-- this is the manual, explicit version of the "broadcast join" concept
-- from Part 5, Module 05, ideal for small dimension tables
CREATE TABLE customers (
    customer_id INTEGER,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    country     VARCHAR(56)
)
DISTSTYLE ALL;

-- EVEN distribution: rows are spread round-robin, evenly, regardless of
-- content — a reasonable default when there's no clear, safe join key to
-- distribute by, or where the table is rarely joined at all
CREATE TABLE web_events (
    event_id    INTEGER,
    customer_id INTEGER,
    event_type  VARCHAR(30)
)
DISTSTYLE EVEN;
```

| Distribution style | Behavior | Best for |
|---|---|---|
| `KEY` | Hash-distributed by a chosen column | Large tables frequently joined on that same column — avoids shuffling both sides |
| `ALL` | Full copy on every node | Small dimension tables (recall the star schema pattern from [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)) — this is exactly the manual "broadcast" every query would otherwise need to do dynamically |
| `EVEN` | Round-robin, ignoring content | Large tables with no dominant, safe join key, or rarely joined |

> ⚠️ **Choosing the wrong distribution key recreates the data skew problem
> from [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/)
> deliberately, by hand** — e.g., distributing `orders` by `order_status`
> (only 5 distinct values) would concentrate rows onto just 5 nodes' worth
> of hash buckets, wasting the other nodes' capacity entirely. Choose a
> high-cardinality column that's also commonly used in joins, mirroring the
> **selectivity** reasoning from [Part 5, Module 02](../../05-performance-and-optimization/02-indexing-strategies/).

## Sort keys: Redshift's answer to physical clustering

```sql
CREATE TABLE orders (
    order_id         INTEGER,
    customer_id      INTEGER,
    order_date       DATE,
    order_status     VARCHAR(20),
    shipping_country VARCHAR(56)
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (order_date);
```

> **New term (Redshift-specific) — sort key**: the column(s) Redshift
> physically orders a table's data by on disk within each node — directly
> analogous to the `CLUSTER` command and clustering concept from
> [Part 5, Module 03](../../05-performance-and-optimization/03-partitioning-and-clustering/),
> but automatically *maintained* as new data loads in (unlike PostgreSQL's
> one-time manual `CLUSTER`).

A well-chosen sort key (often a date column, since range-filtered date
queries are extremely common) lets Redshift skip large chunks of irrelevant
data via **zone maps** — small, per-block min/max metadata, conceptually
identical to the pruning metadata behind Snowflake's micro-partitions
([Module 03](../03-snowflake/)) and BigQuery's partition pruning
([Module 02](../02-google-bigquery/)) — three different platforms
implementing essentially the same core idea from
[Part 5, Modules 02–03](../../05-performance-and-optimization/02-indexing-strategies/), each in their own way.

## Redshift Spectrum: querying your data lake directly

> **New term (Redshift-specific) — Redshift Spectrum**: lets Redshift query
> data sitting directly in Amazon S3 (files, not loaded into Redshift's own
> storage) as if it were a normal table — a direct, practical bridge between
> the warehouse and lake concepts from
> [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/).

```sql
-- Register an external schema pointing at S3 data (e.g., raw Parquet files
-- representing your "bronze" layer from Part 3, Module 04)
CREATE EXTERNAL SCHEMA northstar_raw
FROM DATA CATALOG
DATABASE 'northstar_raw_db'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftSpectrumRole';

-- Query S3 data directly, joined against normal Redshift tables, in one query
SELECT c.country, COUNT(*) AS num_events
FROM northstar_raw.web_events_parquet e
JOIN customers c ON e.customer_id = c.customer_id   -- customers lives in normal Redshift storage
GROUP BY c.country;
```

This is a direct, hands-on illustration of the Medallion architecture idea
from [Part 3, Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/):
raw bronze data can stay cheaply in S3 as files, queried on demand via
Spectrum, while frequently-accessed, already-modeled gold-layer tables live
in Redshift's own fast, native storage — one query engine spanning both.

## Vacuum and analyze: maintenance you're responsible for

Recall `ANALYZE` from
[Part 5, Module 01](../../05-performance-and-optimization/01-how-databases-execute-queries/) —
Redshift uses the exact same concept and largely the same command, plus a
`VACUUM` step specific to how it physically reclaims space after
deletes/updates (conceptually similar to what PostgreSQL's autovacuum
handles automatically, but historically requiring more manual attention in
Redshift, especially on provisioned clusters):

```sql
VACUUM orders;    -- reclaim space, re-sort rows according to the sort key
ANALYZE orders;   -- refresh statistics the query planner relies on
```

## Security features, mapped to Part 6

| Part 6 concept | Redshift implementation |
|---|---|
| RBAC ([Module 02](../../06-security/02-authentication-and-authorization/)) | Standard `GRANT`/`REVOKE` roles, plus AWS IAM integration for authentication |
| Row-level security ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Native row-level security policies |
| Dynamic data masking ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Native dynamic data masking policies |
| Encryption ([Module 03](../../06-security/03-encryption/)) | Encryption at rest via AWS KMS, encryption in transit via SSL |

## ✅ Try it yourself

If you have a Redshift Serverless workgroup set up:

```sql
CREATE TABLE orders (
    order_id INTEGER, customer_id INTEGER, order_date DATE,
    order_status VARCHAR(20), shipping_country VARCHAR(56)
)
DISTSTYLE KEY DISTKEY (customer_id) SORTKEY (order_date);

-- After loading data, check how well-utilized your distribution is:
SELECT slice, COUNT(*) AS row_count
FROM orders, STV_TBL_PERM
WHERE STV_TBL_PERM.name = 'orders'
GROUP BY slice
ORDER BY slice;
```

### Exercises

1. Would you use `DISTSTYLE ALL` or `DISTSTYLE KEY` for a `products` table
   with 40 rows that's joined against `order_items` in nearly every
   analytical query? Justify your choice using this module's guidance.
2. Explain why choosing `order_status` (5 distinct values) as a `DISTKEY`
   for a multi-million-row `orders` table would likely cause the exact data
   skew problem described in [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/).
3. Explain, in your own words, how Redshift Spectrum lets you apply the
   Medallion architecture (bronze/silver/gold) from
   [Part 3, Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/)
   across both S3 and native Redshift storage in a single platform.

<details>
<summary>💡 Solutions</summary>

```text
1. DISTSTYLE ALL. Products is small (40 rows) and joined constantly against
   order_items — copying it in full to every node means EVERY join against
   it can happen entirely locally on each node, with zero shuffle needed,
   exactly like a broadcast join. This mirrors the star schema reasoning
   from Part 3, Module 02: small dimension tables benefit from being
   available everywhere.

2. With only 5 distinct order_status values, KEY-distributing by it would
   concentrate all rows into at most 5 hash "buckets" — regardless of how
   many actual compute nodes exist, only 5 of them (at most) would ever
   receive any data at all, leaving the rest completely idle for any query
   touching this table. This is the data skew concept applied directly and
   deliberately (if mistakenly) through a poor distribution key choice.

3. Bronze data (raw, high-volume, less frequently queried) can live cheaply
   as files in S3, queried on-demand via Spectrum external tables when
   needed. Frequently-accessed, already-transformed gold-layer tables (like
   fact_order_items, dim_customer) live in Redshift's own fast native
   storage for the best query performance. A single SQL query can JOIN
   across both simultaneously, giving you the storage-cost benefits of a
   data lake for raw/cold data and the query-performance benefits of a
   warehouse for your modeled, frequently-used tables — without needing to
   choose one platform exclusively.
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What's the main tradeoff of Redshift giving you explicit control over distribution keys, compared to Snowflake's automatic micro-partitioning?</summary>

Explicit control lets you deliberately optimize for known, dominant join
patterns (e.g., DISTKEY matching your most common join column) potentially
better than an automatic system could guess — but it also means a POOR
choice (like distributing by a low-cardinality column) actively creates a
data skew problem yourself, requiring you to understand and reason about
distribution correctly rather than relying entirely on the platform.
</details>

<details>
<summary>Q: What does Redshift Spectrum let you do that a normal Redshift table can't?</summary>

Query data files sitting directly in Amazon S3 as if they were a normal
table — including joining that S3 data against tables stored natively in
Redshift — without first loading the S3 data into Redshift's own storage,
bridging the data lake and data warehouse paradigms from
Part 3, Module 03 within one query engine.
</details>

---
⬅ [Back to Part 7](../) | ➡ Next: [05. Azure Synapse & Fabric](../05-azure-synapse-and-fabric/)
