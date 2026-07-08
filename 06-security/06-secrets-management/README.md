# 06. Secrets Management

*Part of [Part 6 — Security](../). Previous: [05. Compliance & Governance](../05-compliance-and-governance/).*

Every module in Part 6 has quietly depended on one assumption: that
passwords, API keys, and encryption keys are themselves kept safe. This
final module makes that explicit — closing a gap that, in real breach
reports, is one of the most common root causes of all.

## What counts as a secret

> **New term — secret**: any value that grants access or protects sensitive
> data, and that must be kept confidential — database passwords, API keys,
> encryption keys ([Module 03](../03-encryption/)), OAuth tokens, and
> service account credentials ([Module 02](../02-authentication-and-authorization/)) are all secrets.

## The mistake this module exists to prevent

```python
# ❌ NEVER do this — a hardcoded secret directly in source code
DATABASE_URL = "postgresql://svc_orders_pipeline:Sup3rSecret123@prod-db.example.com/northstar"
```

Why is this so dangerous, beyond the obvious? Because **source code has a
long, persistent, often widely-shared life** that a single password
shouldn't:

- **Version control history is forever.** Even if you delete the line in a
  later commit, the secret remains readable in the git history indefinitely
  — anyone with repo access can find it with `git log -p` or by browsing old commits.
- **Repos get shared more broadly than intended.** A private repo can become
  public by accident; a contractor or new hire gets repo access for an
  unrelated reason and now also has your production database password.
- **Automated scanners actively hunt for this.** Public GitHub repositories
  are continuously scanned by both security researchers and attackers
  specifically looking for accidentally committed credentials — this is a
  real, common, and fast attack vector, not a theoretical risk.

## Environment variables: the baseline improvement

```python
# ✅ Better: read the secret from the environment at runtime
import os
DATABASE_URL = os.environ["DATABASE_URL"]
```

```bash
# The actual value lives outside the codebase entirely —
# set locally, or injected by your deployment platform/orchestrator
export DATABASE_URL="postgresql://svc_orders_pipeline:Sup3rSecret123@prod-db.example.com/northstar"
```

This keeps the secret's actual value out of source control — a genuine,
necessary improvement. But it's still not a complete solution on its own:
environment variables can leak into logs, error messages, or process
listings; they typically have no built-in rotation, auditing, or
fine-grained access control; and every system/person needing the secret
still needs some other secure way to actually obtain the value in the first place.

## `.env` files: convenient locally, dangerous if mishandled

```bash
# .env (a local file, NEVER committed to version control)
DATABASE_URL=postgresql://svc_orders_pipeline:Sup3rSecret123@prod-db.example.com/northstar
```

```gitignore
# .gitignore — this line is what actually protects you
.env
```

> ⚠️ **The single most common real-world mistake here**: forgetting to add
> `.env` to `.gitignore` *before* the first commit that includes it — once
> it's been committed even once, it's in the permanent git history (see
> above) even after you delete it and add the ignore rule. Add `.env` to
> `.gitignore` **before** creating the file, as a standing habit for every
> new project.

## Secrets managers: the production-grade solution

> **New term — secrets manager**: a dedicated service specifically built to
> store, retrieve, rotate, and audit access to secrets — examples include
> AWS Secrets Manager, Google Secret Manager, Azure Key Vault, and
> HashiCorp Vault.

```python
# Conceptual example — actual API differs by provider
import boto3
client = boto3.client("secretsmanager")
secret = client.get_secret_value(SecretId="prod/northstar/orders-pipeline-db")
DATABASE_URL = secret["SecretString"]
```

What a real secrets manager gives you, beyond a plain environment variable
or `.env` file:

- **Centralized access control**: exactly which people/services can
  *retrieve* a given secret is itself governed by the same least-privilege
  ([Module 02](../02-authentication-and-authorization/)) principles applied
  to everything else in this repo — a pipeline's service account can be
  granted permission to fetch *only* the specific secret it needs.
- **Automatic rotation**: periodically and automatically generating a new
  credential and updating it everywhere it's used, without manual
  intervention or downtime — dramatically limiting how long a
  potentially-leaked credential remains valid and useful to an attacker.
- **Audit logging**: a record of exactly which identity accessed which
  secret, and when — directly connects to [Module 05's](../05-compliance-and-governance/) auditing requirements.
- **No secret ever needs to live in a file on disk, an environment
  variable dump, or a config file at all** — it's fetched at runtime,
  directly into memory, from a system built specifically to handle that safely.

## Database-native credential patterns

Some databases and platforms support even more dynamic approaches:

- **Short-lived, dynamically-generated database credentials**: instead of
  one long-lived password, a secrets manager can generate a brand-new
  database user with a random password *on demand*, valid only for a
  limited time — so there's no long-lived credential to leak at all.
- **IAM-based authentication**: on cloud platforms, a service can
  authenticate to a database using its cloud identity/role directly
  (leveraging the cloud provider's own authentication system), with no
  traditional password involved at all — we'll see concrete examples of
  this in [Part 7](../../07-cloud-data-platforms/) for each platform.

## Connection security checklist for pipelines

Bringing together this module with [Module 02](../02-authentication-and-authorization/)
and [Module 03](../03-encryption/), a genuinely secure pipeline connection should have:

- [ ] A dedicated **service account** ([Module 02](../02-authentication-and-authorization/)),
      not a personal or shared admin account
- [ ] **Least-privilege** permissions — only what that specific pipeline needs
- [ ] Its credential stored in a **secrets manager**, never hardcoded or committed to version control
- [ ] The connection itself using **TLS/encryption in transit** ([Module 03](../03-encryption/))
- [ ] Credential **rotation** configured, rather than a password set once and never changed
- [ ] **Audit logging** enabled on both the secrets manager and the database itself

## What to do if a secret does leak

Even with good practices, mistakes happen — knowing the correct response
matters as much as prevention:

1. **Rotate the credential immediately** — assume it's compromised the
   moment you realize it's exposed, regardless of whether you can confirm
   actual misuse yet.
2. **Don't just delete the file/commit and consider it resolved** — as
   covered above, git history retains it; the *credential itself* must be
   invalidated, not just the file removed.
3. **Review access/audit logs** for the affected credential's usage during
   the exposure window, looking for anything unexpected.
4. **Understand and fix the root cause** — was `.env` missing from
   `.gitignore`? Was a secret pasted into a shared chat? Address the
   process gap, not just this one instance.

## ✅ Try it yourself

There's no database SQL to run for this module — the skill here is
recognizing patterns in code and configuration. As practice, review this
snippet and identify every mistake:

```python
# config.py — committed to a public GitHub repository
DB_PASSWORD = "MyProdPassword2024!"
STRIPE_API_KEY = "sk_live_51H8x..."
```

<details>
<summary>💡 What's wrong, and the fix</summary>

Both are hardcoded secrets committed to a **public** repository — the
worst-case version of this module's central mistake, since public repos are
actively scanned by automated tools looking for exactly this pattern. Fix:
immediately rotate both credentials (assume they're already compromised),
remove them from the codebase entirely, add appropriate `.gitignore` rules,
and move both into a proper secrets manager (or, at minimum, environment
variables sourced from an untracked `.env` file for local development).
</details>

### Exercises

1. Explain why simply deleting a hardcoded secret in a new commit doesn't
   actually remove the security risk, even though the file no longer shows
   the secret in its current state.
2. A team currently shares one database password across all 5 of their
   pipeline services. List two concrete problems this creates, referencing
   concepts from this module and [Module 02](../02-authentication-and-authorization/).
3. Explain, in your own words, why automatic credential rotation reduces
   risk even for a secret that's never been (as far as anyone knows) leaked.

<details>
<summary>💡 Solutions</summary>

```text
1. Git preserves the FULL history of every commit by default — deleting a
   secret in commit #10 doesn't erase it from commit #9, which remains
   fully accessible to anyone who can browse the repository's history
   (`git log -p`, or simply checking out an old commit). The credential
   must be ROTATED (changed at its source) to actually neutralize the
   exposure; removing it from the current file only prevents FUTURE
   viewers from seeing it in the latest version.

2. (a) Least privilege violation (Module 02): a single shared credential
   likely has the UNION of permissions all 5 pipelines need, meaning any
   one compromised pipeline effectively grants access equivalent to all
   five combined, rather than being scoped narrowly. (b) No accountability/
   auditability: if suspicious activity is detected, there's no way to tell
   WHICH of the 5 services used the credential for a given action, since
   they're all indistinguishable in logs — audit logs (Module 05) lose
   most of their value when identities aren't actually distinct per service.

3. Even an apparently-unleaked secret could have been silently compromised
   through a channel nobody's aware of yet (a misconfigured log that
   briefly printed it, a former employee who still remembers it, a
   compromised laptop). Regular rotation limits how long ANY such
   undetected exposure remains useful to an attacker — instead of a
   credential being valid (and exploitable) indefinitely once leaked, it
   naturally expires and becomes useless after the next rotation cycle,
   regardless of whether the leak was ever noticed.
```
</details>

## 🎉 Part 6 complete!

You now have a genuinely complete security foundation: preventing
injection, controlling access with least privilege and RBAC, encrypting and
masking sensitive data, understanding the compliance frameworks that drive
real-world requirements, and protecting the credentials that hold
everything else together. Next: [Part 7 — Cloud Data Platforms](../../07-cloud-data-platforms/),
where you'll see exactly how BigQuery, Snowflake, Redshift, Fabric, and
Databricks each implement everything from Parts 5 and 6.

## 🧠 Quick check

<details>
<summary>Q: Why is committing a secret to a private (not public) GitHub repository still a real security risk?</summary>

Repository access is rarely as narrow or permanent as assumed — private
repos can be made public by accident, contractors or employees gain and
later should lose access, and the secret remains fully readable in git
history indefinitely regardless of current file contents. "Private today"
doesn't guarantee "private forever, to everyone who ever had access."
</details>

<details>
<summary>Q: What's the single most important corrective action after discovering a leaked secret?</summary>

Rotate (invalidate and replace) the credential immediately — assume
compromise even without confirmed evidence of misuse. Deleting the
exposed file or commit alone does not neutralize the risk, since the
original value remains valid and usable by anyone who saw it until it's
actually rotated.
</details>

---
⬅ [Back to Part 6](../) | ➡ Next: [Part 7 — Cloud Data Platforms](../../07-cloud-data-platforms/)
