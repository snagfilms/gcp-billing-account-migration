# Security Policy

## Supported Versions

This project is a single-script utility. Only the latest revision on the `main` branch receives security fixes. Pinned copies or forks are not actively maintained.

| Version | Supported          |
| ------- | ------------------ |
| `main` (latest) | :white_check_mark: |
| Older commits / forks | :x: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Because this script operates on GCP billing accounts — resources with significant financial and operational impact — we ask that you report vulnerabilities responsibly.

### How to Report

Email **sujith@viewlift.com** with the subject line:

```
[SECURITY] gcp-billing-account-migration — <brief description>
```

Include as much of the following as possible:

- A description of the vulnerability and its potential impact
- The affected script version / commit SHA
- Steps to reproduce or a proof-of-concept (safe to share over email)
- Any suggested mitigations you have in mind

### What to Expect

| Timeline | Action |
| -------- | ------ |
| **Within 48 hours** | Acknowledgement that your report was received |
| **Within 7 days** | Initial assessment — confirmed, needs more info, or not applicable |
| **Within 30 days** | Fix published (critical/high severity) or decision communicated (lower severity) |

We will keep you informed at each stage and credit you in the release notes unless you prefer to remain anonymous.

### Scope

Issues we consider in scope:

- **Credential / secret exposure** — e.g., billing account IDs or tokens inadvertently logged or written to world-readable files
- **Privilege escalation** — logic that could cause the script to act on unintended projects or billing accounts
- **Injection vulnerabilities** — e.g., unsanitised environment variable values passed to `gcloud` or shell constructs
- **Insecure defaults** — e.g., a default configuration that silently disables dry-run protections

Issues outside scope:

- Vulnerabilities in `gcloud` CLI or GCP APIs themselves (report those to [Google](https://bughunters.google.com/))
- IAM misconfiguration in the caller's GCP environment
- Social engineering or phishing

### Disclosure Policy

We follow **coordinated disclosure**. Once a fix is available we will publish a security advisory on GitHub. We ask that you give us at least **30 days** from the date of your initial report before any public disclosure, to allow time to prepare and release a fix.

## Security Considerations for Users

- **Run dry-run first** (`DRY_RUN=true`, the default) before any live migration.
- **Limit IAM scope** — grant `billing.projects.updateBillingInfo` only to the identity running the script; avoid using Owner-level credentials.
- **Protect log files** — timestamped logs (`migration-*.log`) may contain project IDs. Keep them in a secure location and remove them when no longer needed.
- **Review the script** before running it in your environment; it is intentionally short and readable.
