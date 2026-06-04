# gcp-billing-account-migration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Shell: Bash](https://img.shields.io/badge/shell-bash-blue)
![Requires: gcloud](https://img.shields.io/badge/requires-gcloud-4285F4?logo=google-cloud&logoColor=white)

A Bash script to migrate GCP projects from one billing account to another. It auto-discovers all projects linked to the source billing account, validates each project's current billing assignment before touching it, and defaults to a dry run so you can verify the scope before applying any changes.

---

## Prerequisites

- **gcloud CLI** — [Install guide](https://cloud.google.com/sdk/docs/install)
- **Authentication** — `gcloud auth login`
- **IAM permission** — `billing.projects.updateBillingInfo` on both billing accounts

> **Note for service accounts / CI:** `gcloud auth list` may return empty even when the SDK is authenticated via `GOOGLE_APPLICATION_CREDENTIALS`. In that case, skip the interactive auth check and ensure your SA has the required IAM permission above.

---

## Usage

```bash
# 1. Dry run (default) — validates and lists projects that would be migrated, no changes applied
OLD_BILLING_ACCOUNT="XXXXXX-YYYYYY-ZZZZZZ" \
NEW_BILLING_ACCOUNT="AAAAAA-BBBBBB-CCCCCC" \
bash migrate.sh

# 2. Live run — applies the migration after a confirmation prompt
OLD_BILLING_ACCOUNT="XXXXXX-YYYYYY-ZZZZZZ" \
NEW_BILLING_ACCOUNT="AAAAAA-BBBBBB-CCCCCC" \
DRY_RUN=false \
bash migrate.sh

# 3. Target specific projects instead of auto-discovering all
OLD_BILLING_ACCOUNT="XXXXXX-YYYYYY-ZZZZZZ" \
NEW_BILLING_ACCOUNT="AAAAAA-BBBBBB-CCCCCC" \
DRY_RUN=false \
PROJECTS_OVERRIDE="my-project-1 my-project-2 my-project-3" \
bash migrate.sh
```

---

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `OLD_BILLING_ACCOUNT` | Yes | — | Source billing account ID (format: `XXXXXX-YYYYYY-ZZZZZZ`) |
| `NEW_BILLING_ACCOUNT` | Yes | — | Destination billing account ID |
| `DRY_RUN` | No | `true` | Set to `false` to apply changes |
| `PROJECTS_OVERRIDE` | No | — | Space-separated list of project IDs to migrate; if unset, all projects linked to `OLD_BILLING_ACCOUNT` are discovered automatically |

---

## How It Works

1. **Validates** that `gcloud` is installed and an active auth session exists.
2. **Discovers** all projects currently linked to `OLD_BILLING_ACCOUNT` (or uses `PROJECTS_OVERRIDE`).
3. **Verifies** each project is actually linked to `OLD_BILLING_ACCOUNT` before attempting any change, skipping any that aren't.
4. **Prompts** for confirmation before applying a live run.
5. **Links** each project to `NEW_BILLING_ACCOUNT` using `gcloud billing projects link`, which atomically reassigns the billing account without an intermediate unlink step.
6. **Logs** all output to a timestamped file in the script's directory.
7. **Reports** a per-project success/failure tally at the end.

---

## Notes

- A timestamped log file (`migration-YYYYMMDDHHMMSS.log`) is written to the script's directory on each run.
- The atomic `gcloud billing projects link` approach avoids leaving projects in an unlinked (billing-disabled) state during migration.
- `migration-*.log` files are excluded from git via `.gitignore`.

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

To report a vulnerability, please follow the guidelines in [SECURITY.md](SECURITY.md). Do not open a public issue for security-related matters.

## License

MIT — see [LICENSE](LICENSE).
