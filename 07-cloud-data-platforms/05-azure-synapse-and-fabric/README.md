# 05. Azure Synapse & Fabric

*Part of [Part 7 — Cloud Data Platforms](../). Previous: [04. AWS Redshift](../04-aws-redshift/).*

Microsoft's cloud data platform story spans two related products: **Azure
Synapse Analytics** (the more established data warehouse service) and
**Microsoft Fabric** (Microsoft's newer, unified analytics platform built
around the lakehouse concept from [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)).
This module covers both, since you're likely to encounter either — or both — in the wild.

## Getting access

Azure offers trial credits for new accounts covering Synapse serverless SQL
pool usage; Microsoft Fabric offers its own trial capacity, accessible via
[app.fabric.microsoft.com](https://app.fabric.microsoft.com). Both provide
browser-based SQL editors requiring no local setup.

## Azure Synapse: dedicated vs. serverless SQL pools

Recall the serverless/provisioned spectrum from
[Module 01](../01-cloud-warehousing-overview/) — Synapse offers both
explicitly, as two distinct pool types:

> **New term (Synapse-specific) — dedicated SQL pool**: a provisioned,
> pre-allocated amount of compute and storage (measured in Data Warehouse
> Units, or DWUs) — you pay for it whether actively querying or not, in
> exchange for consistent, predictable performance for heavy, sustained workloads.

> **New term (Synapse-specific) — serverless SQL pool**: an on-demand query
> engine (directly comparable to BigQuery's model from
> [Module 02](../02-google-bigquery/)) that queries data sitting in Azure
> Data Lake Storage directly, billed per terabyte of data processed —
> **with no data loading step required at all**.

```sql
-- Serverless SQL pool: query files directly in a data lake, no loading step
SELECT
    order_status,
    COUNT(*) AS num_orders
FROM OPENROWSET(
    BULK 'https://mystorageaccount.dfs.core.windows.net/northstar/orders/*.parquet',
    FORMAT = 'PARQUET'
) AS orders
GROUP BY order_status;
```

This `OPENROWSET` pattern is conceptually the direct equivalent of
Redshift Spectrum ([Module 04](../04-aws-redshift/)) — querying a data
lake's raw files as if they were a table, without a separate load step —
another concrete illustration of the warehouse/lake bridge from
[Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/).

## Distribution in dedicated SQL pools

Synapse dedicated pools use the same underlying distributed-query concepts
you learned in [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/)
and just applied concretely in Redshift ([Module 04](../04-aws-redshift/)) —
with Synapse's own naming:

```sql
-- HASH distribution: directly analogous to Redshift's DISTKEY
CREATE TABLE orders (
    order_id INT, customer_id INT, order_date DATE,
    order_status VARCHAR(20), shipping_country VARCHAR(56)
)
WITH (DISTRIBUTION = HASH(customer_id));

-- REPLICATE: directly analogous to Redshift's DISTSTYLE ALL — a full copy on every node
CREATE TABLE products (
    product_id INT, product_name VARCHAR(100), category VARCHAR(50), unit_price DECIMAL(10,2)
)
WITH (DISTRIBUTION = REPLICATE);

-- ROUND_ROBIN: directly analogous to Redshift's DISTSTYLE EVEN
CREATE TABLE web_events (
    event_id INT, customer_id INT, event_type VARCHAR(30)
)
WITH (DISTRIBUTION = ROUND_ROBIN);
```

Notice this is genuinely the **same three-way choice** as Redshift's
`KEY`/`ALL`/`EVEN`, just with different keyword names — a direct example of
this repo's "shallower than they first appear" claim about SQL dialect
differences ([Module 01](../01-cloud-warehousing-overview/)): the concept
transfers completely; only the specific keywords change.

## T-SQL: Microsoft's SQL dialect

Synapse (and Fabric's warehouse item) use **T-SQL** (Transact-SQL), the
same dialect as SQL Server — the main differences from PostgreSQL you'll notice:

```sql
-- TOP instead of LIMIT
SELECT TOP 10 * FROM orders ORDER BY order_date DESC;

-- String concatenation with + instead of ||
SELECT first_name + ' ' + last_name AS full_name FROM customers;

-- Date functions use different names
SELECT DATEADD(DAY, 30, order_date) AS estimated_followup FROM orders;
SELECT DATEDIFF(DAY, order_date, GETDATE()) AS days_since_order FROM orders;

-- GETDATE() instead of CURRENT_DATE/NOW()
SELECT GETDATE() AS right_now;
```

Everything else you learned — joins, `GROUP BY`/`HAVING`, window functions,
CTEs, `CASE`, subqueries — transfers with identical or near-identical syntax.

## Microsoft Fabric: the unified lakehouse platform

> **New term — Microsoft Fabric**: Microsoft's newer, unified analytics
> platform built around **OneLake** — a single, organization-wide data lake
> that every Fabric workload (data engineering, warehousing, BI, real-time
> analytics) reads from and writes to, storing data in the open Delta Lake
> format (recall table formats from [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)).

Fabric offers two SQL-queryable item types that map directly onto the
warehouse/lakehouse distinction from
[Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/):

- **Warehouse**: a traditional, fully-structured T-SQL data warehouse experience.
- **Lakehouse**: combines file-based storage (accessible to Spark/Python)
  with a SQL endpoint automatically generated over Delta tables — letting
  data scientists and SQL analysts work against the **exact same
  underlying data**, in whichever tool suits them.

```sql
-- Fabric's SQL endpoint over a lakehouse — plain T-SQL against Delta tables
SELECT
    DATEPART(MONTH, order_date) AS order_month,
    COUNT(*) AS num_orders
FROM northstar_lakehouse.dbo.orders
GROUP BY DATEPART(MONTH, order_date);
```

This "one copy of data, multiple compute engines against it" idea is the
same principle behind the lakehouse concept generally
([Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)) —
Fabric's specific contribution is making that experience deeply integrated
within one platform and one underlying storage layer (OneLake), rather than
requiring separate tools pointed at shared storage.

## Security features, mapped to Part 6

| Part 6 concept | Synapse/Fabric implementation |
|---|---|
| RBAC ([Module 02](../../06-security/02-authentication-and-authorization/)) | T-SQL `GRANT`/`REVOKE`, plus Microsoft Entra ID (formerly Azure AD) integration |
| Row-level security ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Native T-SQL `CREATE SECURITY POLICY` |
| Dynamic data masking ([Module 04](../../06-security/04-data-masking-and-row-column-security/)) | Native, built directly into T-SQL column definitions (`MASKED WITH (FUNCTION = ...)`) |
| Encryption ([Module 03](../../06-security/03-encryption/)) | Transparent Data Encryption (TDE) at rest by default, TLS in transit |

## ✅ Try it yourself

```sql
-- If using a Synapse serverless SQL pool or Fabric warehouse:
SELECT TOP 10
    order_id,
    order_date,
    order_status
FROM orders
ORDER BY order_date DESC;
```

### Exercises

1. Rewrite this PostgreSQL query in T-SQL syntax:
   `SELECT product_name, unit_price FROM products ORDER BY unit_price DESC LIMIT 5;`
2. Explain why Synapse's `REPLICATE` distribution option and Redshift's
   `DISTSTYLE ALL` are the same underlying idea, connecting it back to the
   broadcast join concept from [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/).
3. Explain, in your own words, what specifically makes Microsoft Fabric's
   "lakehouse" item different from a traditional data warehouse table, using vocabulary from [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/).

<details>
<summary>💡 Solutions</summary>

```sql
-- 1.
SELECT TOP 5 product_name, unit_price FROM products ORDER BY unit_price DESC;
```

```text
2. Both REPLICATE and DISTSTYLE ALL store a full copy of the table on
   every compute node, specifically so that joins against that table never
   require a shuffle (Part 5, Module 05) — each node already has everything
   it needs locally. This is the deliberate, hand-configured version of
   what a query optimizer's automatic broadcast join decision does
   dynamically on other platforms — same underlying goal, explicitly
   declared upfront here rather than decided per-query by the optimizer.

3. A Fabric lakehouse stores its data as open Delta Lake files (accessible
   directly to non-SQL tools like Spark/Python), with a SQL endpoint
   layered on top purely for SQL querying convenience — this matches the
   "lakehouse" definition from Part 3, Module 03: table-format ACID
   guarantees and schema enforcement layered on top of cheap, flexible file
   storage. A traditional warehouse table stores data in the platform's
   own proprietary internal format, optimized purely for SQL access, with
   no native path for other tools to read the raw files directly.
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What's the practical difference between a Synapse dedicated SQL pool and a serverless SQL pool?</summary>

A dedicated pool is provisioned, pre-allocated compute/storage that you pay
for continuously regardless of usage, suited to sustained heavy workloads
needing predictable performance. A serverless pool is on-demand, billed per
terabyte processed, and can query data lake files directly without a
separate loading step — better suited to intermittent or ad-hoc querying.
</details>

<details>
<summary>Q: How does Microsoft Fabric's OneLake relate to the lakehouse concept from Part 3?</summary>

OneLake is a single, organization-wide data lake (storing data as Delta
Lake tables) that every Fabric workload reads from and writes to — it's
the concrete implementation of the lakehouse idea (ACID-capable table
formats on top of lake storage) at the platform level, letting SQL
warehousing, Spark-based data engineering, and BI tools all share one copy
of the underlying data rather than each needing their own separate storage.
</details>

---
⬅ [Back to Part 7](../) | ➡ Next: [06. Databricks SQL](../06-databricks-sql/)
