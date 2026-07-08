# 02. Case Studies

*Part of [Part 8 — Real-World Projects](../). Previous: [01. Capstone: Build a Mini Data Warehouse](../01-capstone-mini-warehouse/).*

The capstone had you build one complete system. This closing module of Part
8 asks you to **read and reason about** three different, realistic
architectures — a skill in its own right, and exactly what you'll do in
system design interviews and when joining a new team. Each case study
describes a fictional but realistic company; work through the discussion
questions yourself before checking the analysis.

## Case Study 1: A small e-commerce startup

**Situation**: A 15-person startup selling direct-to-consumer products
online. Their data: an application database (orders, customers, products —
much like our `northstar` schema), a marketing email tool, and a support
ticketing system. They want a single place to answer basic business
questions and are extremely cost- and time-constrained.

**Their architecture**: Google BigQuery, fed by a managed connector service
that syncs their application database and third-party tools automatically.
A small number of SQL transformation queries turn raw synced data into a
handful of reporting tables, scheduled to run every morning via BigQuery's
built-in scheduled queries feature. No dedicated orchestration tool, no
dbt — just a few `CREATE OR REPLACE TABLE ... AS SELECT` statements running on a timer.

### Discussion questions

1. Using the decision framework from [Part 7, Module 07](../../07-cloud-data-platforms/07-choosing-the-right-platform/),
   why does BigQuery fit this situation particularly well?
2. Is skipping dbt and Airflow ([Part 4, Module 03](../../04-data-engineering-with-sql/03-orchestration-basics/))
   a mistake here, or a reasonable choice? At what point would you expect
   this company to outgrow this simple approach?
3. What's the biggest data quality risk in this setup, given there's no
   formal testing framework in place (recall [Part 4, Module 04](../../04-data-engineering-with-sql/04-data-quality-and-testing/))?

<details>
<summary>💡 Analysis</summary>

```text
1. BigQuery's fully serverless model (Part 7, Module 02) means this small
   team never has to think about compute sizing, cluster management, or
   capacity planning at all — a disproportionate win for a small,
   generalist team without a dedicated infrastructure specialist. Its
   on-demand pricing also naturally fits a small, low/unpredictable query
   volume without paying for idle provisioned compute.

2. Reasonable, not a mistake, AT THIS SCALE. A handful of simple, scheduled
   CREATE TABLE AS SELECT statements is easy to understand and maintain for
   a small number of models with straightforward dependencies. The company
   would likely outgrow this once they have enough MODELS that manually
   tracking dependency order between them becomes error-prone (missing that
   model B needs model A to run first), or once they need proper testing/
   documentation/version-controlled change review at a scale where ad-hoc
   scripts become risky — exactly the problem dbt (Part 4, Module 03) solves.

3. Without automated tests, a silent upstream change (a marketing tool
   renaming a field, an application schema migration) could break or subtly
   corrupt a downstream reporting table with no alert at all — the team
   would only find out when someone notices a dashboard number looks wrong,
   possibly much later. This is exactly the gap Part 4, Module 04's
   "test as part of the pipeline, not a manual afterthought" principle addresses.
```
</details>

## Case Study 2: A fintech company under strict regulatory scrutiny

**Situation**: A company processing loan applications and payments,
subject to strict financial regulations requiring full auditability of
every piece of customer financial data, precise records of data lineage
for regulatory reporting, and strict, provable least-privilege access
control across dozens of internal teams.

**Their architecture**: Snowflake, with a Data Vault-modeled ([Part 3,
Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/))
integration layer combining data from 6 different source systems (a loan
origination system, a payments processor, a core banking platform, and
three acquired companies' legacy databases). Native row-level security
policies ([Part 6, Module 04](../../06-security/04-data-masking-and-row-column-security/))
restrict each team to only the accounts/records relevant to their function.
Time Travel ([Part 7, Module 03](../../07-cloud-data-platforms/03-snowflake/))
is explicitly relied upon as part of their audit story.

### Discussion questions

1. Why does Data Vault's hub/link/satellite structure
   ([Part 3, Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/))
   fit this scenario better than it fit our capstone project's simpler,
   single-source NorthStar Retail scenario?
2. How does Snowflake's Time Travel feature concretely support "provable
   auditability," beyond just being a convenient safety net for mistakes
   (recall [Part 7, Module 03](../../07-cloud-data-platforms/03-snowflake/) and
   [Part 6, Module 05](../../06-security/05-compliance-and-governance/))?
3. This company still needs a business-facing star schema or OBT
   ([Part 3, Modules 02 and 04](../../03-database-design-and-modeling/)) on
   top of their Data Vault layer for actual analyst reporting. Why can't
   analysts just query the Data Vault hubs/links/satellites directly?

<details>
<summary>💡 Analysis</summary>

```text
1. Data Vault's core value proposition is integrating MANY independent,
   evolving source systems with strong auditability and easy extensibility
   (Part 3, Module 04) — this company has SIX source systems, including
   legacy systems from acquisitions that likely have inconsistent schemas
   and will need ongoing integration work. Our capstone had exactly ONE
   source system, where Data Vault's overhead would provide little benefit
   — the fit genuinely depends on the number and complexity of sources,
   not company size alone.

2. Time Travel lets the company query EXACTLY what a record looked like at
   any past point in time, directly from the platform itself, which
   supports answering a regulator's question like "prove what this
   customer's account status was on this specific date" with a verifiable,
   platform-guaranteed answer — rather than relying entirely on
   manually-maintained audit tables (Part 2, Module 05) that could
   theoretically have gaps or bugs in their trigger logic.

3. Data Vault's hub/link/satellite structure is optimized for INTEGRATION
   and AUDITABILITY, not for easy, intuitive querying — answering a simple
   business question directly against it would require joining many
   satellite tables together in non-obvious ways. A star schema or OBT
   built ON TOP of the Data Vault layer (Part 3, Module 04's "these
   patterns combine, not compete" point) gives analysts the simple,
   familiar query shape they need, while the Data Vault layer underneath
   still provides the integration and audit guarantees the compliance
   requirements demand.
```
</details>

## Case Study 3: A media/streaming company with heavy ML needs

**Situation**: A video streaming platform with petabytes of raw viewing
event logs, video files, and recommendation model training data, alongside
more modest, structured subscription billing data. Their data science team
builds recommendation models directly against raw viewing logs; their
finance team needs standard SQL reporting on subscription revenue.

**Their architecture**: Databricks, with all data — structured and
unstructured — landing in a Medallion-style bronze/silver/gold lakehouse
([Part 3, Modules 03 and 04](../../03-database-design-and-modeling/)) built
on Delta Lake. Data scientists work directly against silver-layer Delta
tables using Spark/Python notebooks; the finance team queries gold-layer
tables through Databricks SQL, using standard `SELECT` queries against
what looks, to them, like an ordinary data warehouse.

### Discussion questions

1. Why does a lakehouse architecture ([Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/))
   fit this company better than either a pure data warehouse or a pure data
   lake would, given their two very different user groups?
2. The finance team never needs to know or care that the underlying storage
   is Delta Lake files rather than a "traditional" warehouse's proprietary
   format. Why does that matter as a design goal (recall
   [Part 7, Module 06](../../07-cloud-data-platforms/06-databricks-sql/))?
3. What role does `OPTIMIZE ... ZORDER BY` ([Part 7, Module 06](../../07-cloud-data-platforms/06-databricks-sql/))
   likely play for the data science team's raw viewing-log queries, given
   the sheer scale of that data?

<details>
<summary>💡 Analysis</summary>

```text
1. A pure data warehouse can't efficiently or naturally handle petabytes of
   raw video files and unstructured event data, or serve the flexible,
   code-based access patterns Spark/Python-based ML training needs (Part 3,
   Module 03). A pure data lake alone would leave the finance team without
   the reliable, fast SQL and ACID guarantees they need for financial
   reporting. A lakehouse lets BOTH groups work against the SAME underlying
   data (avoiding costly, error-prone duplicate copies for each use case),
   each through the interface that suits them.

2. This matters because it means the finance team gets the SIMPLICITY and
   familiarity of "just write normal SQL against normal-looking tables"
   without needing ANY awareness of the more complex underlying
   architecture that serves the data science team's very different needs
   — a good architecture hides unnecessary complexity from users who don't
   need to reason about it, letting each team work at the right level of
   abstraction for their job.

3. At petabyte scale, even a well-distributed query (Part 5, Module 05)
   benefits enormously from physically organizing data so that a given
   query touches as little irrelevant data as possible. ZORDER BY on
   columns commonly used to filter viewing logs (e.g., a date range, or a
   specific content ID) lets Databricks skip large amounts of irrelevant
   data automatically — the exact same pruning/clustering principle from
   Part 5, Modules 02-03, applied at genuinely massive scale where it
   matters most.
```
</details>

## Your turn: analyze a real company

As a final exercise for this module (and, really, for the entire repo),
research a company's published engineering blog post about their data
platform (search for "[Company Name] data engineering blog" or "[Company
Name] data platform architecture" — many tech companies publish these).
Using every concept from Parts 1–8, answer:

1. What storage paradigm(s) do they use (warehouse, lake, lakehouse — [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/))?
2. What modeling pattern(s) can you identify (star schema, OBT, Data Vault, Medallion — [Part 3, Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/))?
3. What orchestration/transformation tooling do they mention ([Part 4, Module 03](../../04-data-engineering-with-sql/03-orchestration-basics/))?
4. What performance or cost optimizations do they specifically call out ([Part 5](../../05-performance-and-optimization/))?
5. Using [Part 7, Module 07's](../../07-cloud-data-platforms/07-choosing-the-right-platform/)
   decision framework, can you reconstruct *why* they likely made the platform choices they made?

## 🎉 Part 8 complete!

You've built a genuine end-to-end project and practiced reading and
reasoning about real-world architectures. Just one part left:
[Part 9 — Career Prep](../../09-career-prep/), where everything you've
learned gets organized for interviews and your ongoing career.

---
⬅ [Back to Part 8](../) | ➡ Next: [Part 9 — Career Prep](../../09-career-prep/)
