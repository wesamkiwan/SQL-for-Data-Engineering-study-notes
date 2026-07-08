# 06. Databricks SQL

*Part of [Part 7 — Cloud Data Platforms](../). Previous: [05. Azure Synapse & Fabric](../05-azure-synapse-and-fabric/).*

Databricks popularized the term "lakehouse" and built **Delta Lake** — the
open table format that made the concept practical. This module is where the
lakehouse theory from [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)
becomes concrete, hands-on SQL.

## Getting access

Databricks offers a free "Community Edition" with reduced capacity, plus
trial credits on the full platform across AWS, Azure, or GCP. **Databricks
SQL** (a dedicated SQL-focused interface within the platform) provides a
familiar SQL editor experience without needing to touch a notebook at all.

## Delta Lake: ACID transactions on top of data lake files

Recall from [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/):
a plain data lake (just files in object storage) has no built-in
transaction guarantees. **Delta Lake** solves this by maintaining a
**transaction log** alongside Parquet files — every table is still
fundamentally Parquet files in cheap object storage, but with a log that
gives you real ACID guarantees ([Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/)) on top.

```sql
CREATE TABLE northstar.orders (
    order_id         INT,
    customer_id      INT,
    order_date       DATE,
    order_status     STRING,
    shipping_country STRING
)
USING DELTA;
```

That `USING DELTA` is the entire difference from a plain table — everything
else about querying it is completely standard SQL.

## Time travel: Delta Lake's version history

Recall Snowflake's **Time Travel** feature from
[Module 03](../03-snowflake/) — Delta Lake has the direct equivalent,
because both features solve the same problem (querying data as of a past
point) using a similar underlying mechanism (a log of changes over time):

```sql
-- Query a table as of a specific version number
SELECT * FROM northstar.orders VERSION AS OF 12;

-- Or as of a specific timestamp
SELECT * FROM northstar.orders TIMESTAMP AS OF '2024-06-15 09:00:00';

-- See the full history of changes to a table
DESCRIBE HISTORY northstar.orders;
```

`DESCRIBE HISTORY` returns every operation ever performed on the table
(inserts, updates, deletes, schema changes), who did it, and when — a
direct, built-in form of the **audit log** concept from
[Part 6, Module 05](../../06-security/05-compliance-and-governance/),
provided automatically by the table format itself.

## `MERGE INTO`: the same pattern you already know

Recall `MERGE` from [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/) —
Delta Lake's `MERGE INTO` is essentially identical syntax, used for exactly
the same incremental-load, idempotent-upsert purpose:

```sql
MERGE INTO northstar.customers AS target
USING staging_customers AS source
ON target.customer_id = source.customer_id
WHEN MATCHED THEN
    UPDATE SET *
WHEN NOT MATCHED THEN
    INSERT *;
```

This is worth pausing on: the exact incremental-loading pattern you learned
generically in Part 4, and saw again in standard ANSI `MERGE` syntax, works
**almost unchanged** here — a direct payoff of learning the *concept* first,
rather than memorizing one platform's specific syntax.

## `OPTIMIZE` and `ZORDER`: Databricks' clustering equivalent

```sql
-- Compact many small files into fewer, larger ones — improves read performance
OPTIMIZE northstar.orders;

-- Z-ORDER: co-locate related data for columns commonly used in filters —
-- conceptually similar to Redshift's SORTKEY (Module 04) or a clustering
-- key, but using a different underlying algorithm (Z-order curves) that
-- can effectively organize by MULTIPLE columns at once
OPTIMIZE northstar.orders ZORDER BY (customer_id, order_date);
```

Recall clustering/sort keys from
[Part 5, Module 03](../../05-performance-and-optimization/03-partitioning-and-clustering/)
and their platform-specific forms in [Module 03](../03-snowflake/) and
[Module 04](../04-aws-redshift/) — `ZORDER` is Databricks' specific
mechanism for the same underlying goal: organizing data physically so
range/filter queries touch less of it.

## Unity Catalog: governance across the whole lakehouse

> **New term (Databricks-specific) — Unity Catalog**: a unified governance
> layer across every table, file, and even ML model in a Databricks
> workspace — providing the RBAC, auditing, and lineage concepts from
> [Part 6](../../06-security/) in one consistent system, regardless of
> whether the underlying asset is a SQL table or a data science notebook's output.

```sql
-- The 3-level namespace: catalog.schema.table
SELECT * FROM northstar_catalog.northstar.orders;

-- Standard GRANT/REVOKE, working across the entire catalog
GRANT SELECT ON TABLE northstar_catalog.northstar.orders TO `data_analyst`;
```

Unity Catalog also provides automatic **data lineage** (recall
[Part 6, Module 05](../../06-security/05-compliance-and-governance/)) —
tracking exactly which tables, notebooks, and dashboards a given table's
data flowed into, generated automatically from actual query execution,
rather than requiring you to declare it explicitly (as with dbt's `ref()`
from [Part 4, Module 03](../../04-data-engineering-with-sql/03-orchestration-basics/)).

## SQL Warehouses: Databricks SQL's compute layer

> **New term (Databricks-specific) — SQL Warehouse**: Databricks' name for
> the compute resource that runs your SQL queries — directly analogous to
> Snowflake's virtual warehouses ([Module 03](../03-snowflake/)), including
> auto-suspend/auto-resume and adjustable sizing:

```sql
-- Configured via the UI or API rather than SQL DDL, but the concept is
-- identical to Module 03's virtual warehouses: choose a size, set
-- auto-stop after a period of inactivity, and it bills per active second.
```

## Databricks and Spark: SQL as one interface among several

Unlike every other platform in this part, Databricks' underlying engine
(Apache Spark) is also directly programmable in Python, Scala, and R —
meaning the exact same Delta tables you query with SQL here can also be
processed with full programming languages in a notebook, by data
scientists or engineers who need capabilities beyond SQL (like complex
machine learning training). This is a deliberate design choice supporting
genuinely mixed SQL-and-code workflows on one shared copy of data — the
practical realization of the "one copy of data serves both analytics and
ML" promise from the lakehouse pitch in
[Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/).

## Security features, mapped to Part 6

| Part 6 concept | Databricks implementation |
|---|---|
| RBAC ([Module 02](../../06-security/02-authentication-and-authorization/)) | Unity Catalog `GRANT`/`REVOKE`, spanning tables, files, and ML assets uniformly |
| Row/column security ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Unity Catalog row filters and column masks |
| Data lineage ([Module 05](../../06-security/05-compliance-and-governance/)) | Automatic, generated from actual query/job execution across the catalog |
| Encryption ([Module 03](../../06-security/03-encryption/)) | Encryption at rest and in transit by default |

## ✅ Try it yourself

```sql
-- If using Databricks SQL:
CREATE TABLE IF NOT EXISTS northstar.orders (
    order_id INT, customer_id INT, order_date DATE,
    order_status STRING, shipping_country STRING
) USING DELTA;

-- After loading data, inspect its change history:
DESCRIBE HISTORY northstar.orders;
```

### Exercises

1. Explain, in your own words, what specifically Delta Lake adds on top of
   plain Parquet files that makes the "ACID transactions on a data lake"
   claim from [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/) true.
2. Write a `MERGE INTO` statement that upserts new/changed rows from a
   `staging_products` table into `northstar.products`, matching on `product_id`.
3. Explain the practical value of Unity Catalog's *automatic* lineage
   generation compared to dbt's `ref()`-based lineage
   ([Part 4, Module 03](../../04-data-engineering-with-sql/03-orchestration-basics/)) — what's a scenario where automatic lineage would catch something declared lineage might miss?

<details>
<summary>💡 Solutions</summary>

```text
1. Delta Lake maintains a TRANSACTION LOG alongside the raw Parquet files
   — a record of every change (insert/update/delete/schema change) made to
   the table, in order. This log is what lets Delta Lake guarantee that
   a reader never sees a half-completed write (Atomicity), that concurrent
   writers don't corrupt each other's changes, and that you can query
   historical versions (Time Travel) — none of which plain, log-less
   Parquet files in object storage can provide on their own.
```

```sql
-- 2.
MERGE INTO northstar.products AS target
USING staging_products AS source
ON target.product_id = source.product_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;
```

```text
3. Automatic lineage (derived from actually observing query/job execution)
   can catch data flows that were never explicitly declared in a dbt model
   file — for example, an analyst manually running a CREATE TABLE AS SELECT
   against a source table outside of any dbt project, or a notebook-based
   data science workflow reading a table and writing derived results.
   Declared lineage (dbt's ref()) only knows about relationships explicitly
   written into dbt models, so ad-hoc or non-dbt-managed data flows would
   be invisible to it — a real gap automatic lineage is specifically
   designed to close, especially valuable in mixed SQL-and-notebook environments.
```
</details>

## 🎉 Almost there!

You've now seen how BigQuery, Snowflake, Redshift, Synapse/Fabric, and
Databricks SQL each implement the concepts from Parts 1–6. One module left
in Part 7: [choosing the right platform](../07-choosing-the-right-platform/)
for a given situation — a skill in its own right, and a common interview topic.

## 🧠 Quick check

<details>
<summary>Q: What specifically distinguishes Databricks SQL from the other platforms covered in this part?</summary>

Its underlying engine (Apache Spark) is directly programmable with
general-purpose languages (Python, Scala, R) in addition to SQL, operating
on the exact same Delta Lake tables — making it naturally suited to mixed
SQL-and-data-science workflows sharing one copy of data, more so than
platforms built primarily around a SQL-only interface.
</details>

<details>
<summary>Q: How does Delta Lake's MERGE INTO relate to what you learned generically in Part 4?</summary>

It's essentially the same ANSI-standard MERGE pattern taught generically in
[Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/)
for building idempotent, incremental upserts — a direct example of how a
concept learned once transfers with minimal syntax changes across
platforms, rather than needing to be relearned from scratch per platform.
</details>

---
⬅ [Back to Part 7](../) | ➡ Next: [07. Choosing the Right Platform](../07-choosing-the-right-platform/)
