# 02. Cheat Sheets

*Part of [Part 9 — Career Prep](../). Previous: [01. SQL Interview Questions](../01-interview-questions/).*

Quick-reference tables for everything covered in this repo. Each links back
to its full module for the complete explanation — use these for lookup, not
first-time learning.

## Query clause order

**Written order:**
```
SELECT ... FROM ... WHERE ... GROUP BY ... HAVING ... ORDER BY ... LIMIT ...
```

**Logical evaluation order** (explains what can reference what):
```
FROM → WHERE → GROUP BY → HAVING → window functions → SELECT → ORDER BY → LIMIT
```
Full explanation: [Part 1, Module 04](../../01-sql-foundations/04-aggregations/) and [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).

## Join types

| Join | Keeps |
|---|---|
| `INNER JOIN` | Only matching rows from both tables |
| `LEFT JOIN` | All left rows, matched or `NULL` right columns |
| `RIGHT JOIN` | All right rows, matched or `NULL` left columns (prefer rewriting as `LEFT JOIN`) |
| `FULL JOIN` | All rows from both, `NULL` on the unmatched side |
| `CROSS JOIN` | Every combination of rows (no condition) |
| Self join | A table joined to itself via two aliases |

Full explanation: [Part 1, Module 05](../../01-sql-foundations/05-joins/).

## Filtering & operators

| Operator | Use |
|---|---|
| `BETWEEN a AND b` | Inclusive range |
| `IN (...)` / `NOT IN (...)` | Match/exclude a list — avoid `NOT IN` with a subquery that might contain `NULL` |
| `LIKE` / `ILIKE` | Pattern match (`%` = any chars, `_` = one char); `ILIKE` is case-insensitive (Postgres-specific) |
| `IS NULL` / `IS NOT NULL` | The only correct way to test for `NULL` |
| `EXISTS` / `NOT EXISTS` | Subquery match test — prefer over `IN`/`NOT IN` for subqueries |

Full explanation: [Part 1, Module 03](../../01-sql-foundations/03-filtering-and-operators/) and [Module 06](../../01-sql-foundations/06-subqueries-and-ctes/).

## Aggregate functions

| Function | Notes |
|---|---|
| `COUNT(*)` | Counts all rows, including `NULL`s |
| `COUNT(col)` | Counts non-`NULL` values only |
| `SUM(col)` / `AVG(col)` | Ignore `NULL`s (never treat as 0) |
| `MIN(col)` / `MAX(col)` | Works on numbers, dates, text |
| `STRING_AGG(col, sep)` | Concatenate group values into one string (Postgres) |

Full explanation: [Part 1, Module 04](../../01-sql-foundations/04-aggregations/).

## Window functions

| Function | Purpose |
|---|---|
| `ROW_NUMBER()` | Unique sequential number per row |
| `RANK()` | Same rank for ties, skips next number |
| `DENSE_RANK()` | Same rank for ties, no skip |
| `LAG(col, n)` / `LEAD(col, n)` | Value from `n` rows before/after |
| `FIRST_VALUE(col)` / `LAST_VALUE(col)` | First/last value in the window frame |
| `SUM()/AVG()/COUNT() OVER (...)` | Running/moving aggregates |

```sql
function(...) OVER (PARTITION BY col ORDER BY col ROWS BETWEEN x AND y)
```

Full explanation: [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/).

## Date/time functions (PostgreSQL)

| Function | Purpose |
|---|---|
| `EXTRACT(part FROM date)` | Pull out year/month/day/dow |
| `DATE_TRUNC('month', date)` | Round down to the start of a unit — use for grouping |
| `date + INTERVAL 'n days'` | Date arithmetic |
| `CURRENT_DATE` / `NOW()` | Today / current timestamp |

Full explanation, plus platform equivalents: [Part 1, Module 08](../../01-sql-foundations/08-string-date-numeric-functions/) and [Part 7](../../07-cloud-data-platforms/).

## Data modification & transactions

```sql
BEGIN;
  -- statements
COMMIT;    -- or ROLLBACK;

INSERT INTO t (...) VALUES (...)
ON CONFLICT (key_col) DO UPDATE SET col = EXCLUDED.col;   -- upsert

MERGE INTO target USING source ON (condition)
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...;
```

**ACID**: Atomicity, Consistency, Isolation, Durability.
Full explanation: [Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/).

## Normalization quick rules

| Form | Rule |
|---|---|
| 1NF | Atomic values, no repeating groups |
| 2NF | No partial dependency on part of a composite key |
| 3NF | No transitive dependency (non-key depends on another non-key) |

Full explanation: [Part 3, Module 01](../../03-database-design-and-modeling/01-normalization-and-keys/).

## Dimensional modeling quick rules

| Concept | Rule of thumb |
|---|---|
| Fact table | Verbs — measurements/events, usually additive |
| Dimension table | Nouns — descriptive context, used to filter/group |
| SCD Type 1 | Overwrite, no history |
| SCD Type 2 | New row + `valid_from`/`valid_to`, full history |
| Star schema | Denormalized dimensions, fewer joins |
| Snowflake schema | Normalized dimensions, less redundancy |

Full explanation: [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/).

## Performance diagnostic checklist

1. `EXPLAIN ANALYZE` the query.
2. Estimated vs. actual rows way off? → `ANALYZE` the table.
3. `Seq Scan` on a large table with a selective filter? → consider an index.
4. Function wrapped around a filtered column? → rewrite to be sargable.
5. `Sort` before a `LIMIT`? → index the `ORDER BY` column(s).
6. Many similar small queries in logs? → look for an N+1 pattern.
7. Query always filters a huge table by date range? → consider partitioning.

Full explanation: [Part 5](../../05-performance-and-optimization/).

## Security checklist for a new pipeline/service

- [ ] Dedicated service account, not personal/shared credentials ([Part 6, Module 02](../../06-security/02-authentication-and-authorization/))
- [ ] Least-privilege grants only ([Part 6, Module 02](../../06-security/02-authentication-and-authorization/))
- [ ] Parameterized queries, never string-built SQL ([Part 6, Module 01](../../06-security/01-sql-injection-and-prevention/))
- [ ] Credentials in a secrets manager, never hardcoded/committed ([Part 6, Module 06](../../06-security/06-secrets-management/))
- [ ] TLS enforced on the connection ([Part 6, Module 03](../../06-security/03-encryption/))
- [ ] Sensitive columns classified and masked/restricted as needed ([Part 6, Modules 04–05](../../06-security/))

## Platform cheat sheet (Part 7)

| Concept | PostgreSQL | BigQuery | Snowflake | Redshift | Synapse/Fabric | Databricks |
|---|---|---|---|---|---|---|
| Row limit | `LIMIT n` | `LIMIT n` | `LIMIT n` | `LIMIT n` | `TOP n` | `LIMIT n` |
| Upsert | `ON CONFLICT` | `MERGE` | `MERGE` | `MERGE` | `MERGE` | `MERGE INTO` |
| Semi-structured type | `JSONB` | `STRUCT`/`ARRAY`/`JSON` | `VARIANT` | `SUPER` | `JSON` functions | `JSON` functions on `STRING`/`VARIANT` |
| Partitioning | `PARTITION BY RANGE/LIST` | `PARTITION BY` | Automatic (micro-partitions) | `DISTKEY`/`SORTKEY` | `DISTRIBUTION = HASH/...` | `PARTITIONED BY` + `ZORDER` |
| Point-in-time query | Not built-in (use audit tables) | Time travel (limited window) | `AT`/`BEFORE` (Time Travel) | Not built-in | Not built-in | `VERSION AS OF` / `TIMESTAMP AS OF` |
| Compute model | Single server | Fully serverless | Virtual warehouses | Clusters or serverless | Dedicated or serverless pools | SQL warehouses |

Full explanation: [Part 7](../../07-cloud-data-platforms/).

---
⬅ [Back to Part 9](../) | ➡ Next: [03. Glossary of Terms](../03-glossary/)
