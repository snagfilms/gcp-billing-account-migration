#!/usr/bin/env bash
set -euo pipefail

# ---- Config (set via environment variables) ----
OLD_BILLING_ACCOUNT="${OLD_BILLING_ACCOUNT:?Set OLD_BILLING_ACCOUNT env var (e.g. XXXXXX-YYYYYY-ZZZZZZ)}"
NEW_BILLING_ACCOUNT="${NEW_BILLING_ACCOUNT:?Set NEW_BILLING_ACCOUNT env var (e.g. XXXXXX-YYYYYY-ZZZZZZ)}"
DRY_RUN="${DRY_RUN:-true}"   # set to false to actually apply changes
OLD_BILLING_ACCOUNT_NAME="billingAccounts/${OLD_BILLING_ACCOUNT}"

# Optional: space-separated project IDs to target instead of auto-discovering.
# e.g. PROJECTS_OVERRIDE="my-project-1 my-project-2"
PROJECTS=()
PROJECTS_OVERRIDE_SET=false
if [[ ${PROJECTS_OVERRIDE+x} == x ]]; then
  PROJECTS_OVERRIDE_SET=true
  read -ra PROJECTS <<< "$PROJECTS_OVERRIDE"
  if [[ ${#PROJECTS[@]} -eq 0 ]]; then
    echo "ERROR: PROJECTS_OVERRIDE is set but contains no project IDs." >&2
    exit 1
  fi
fi

# ---- Prerequisites ----
if ! command -v gcloud &>/dev/null; then
  echo "ERROR: gcloud CLI not found. Install it from https://cloud.google.com/sdk/docs/install" >&2
  exit 1
fi

if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | grep -q .; then
  echo "ERROR: No active gcloud auth session. Run: gcloud auth login" >&2
  exit 1
fi

validate_project_source_billing() {
  local project="$1"
  local current_billing_account
  local display_billing_account

  if ! current_billing_account="$(
    gcloud billing projects describe "${project}" \
      --format="value(billingAccountName)"
  )"; then
    echo "    ERROR: failed to read current billing account for ${project}" >&2
    return 1
  fi

  if [[ "$current_billing_account" != "$OLD_BILLING_ACCOUNT_NAME" ]]; then
    display_billing_account="${current_billing_account:-<none>}"
    echo "    ERROR: ${project} is linked to ${display_billing_account}, expected ${OLD_BILLING_ACCOUNT_NAME}" >&2
    return 1
  fi
}

# ---- Logging ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/migration-$(date +%Y%m%d%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging to ${LOG_FILE}"
echo

# ---- Discover projects if none specified ----
if [[ "$PROJECTS_OVERRIDE_SET" == false && ${#PROJECTS[@]} -eq 0 ]]; then
  echo "Discovering projects linked to ${OLD_BILLING_ACCOUNT}..."
  # Include projects whose billing is disabled but still associated with the source account.
  while IFS= read -r line; do
    [[ -n "$line" ]] && PROJECTS+=("$line")
  done < <(
    gcloud billing projects list \
      --billing-account="${OLD_BILLING_ACCOUNT}" \
      --format="value(projectId)"
  )
fi

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  echo "No projects found linked to ${OLD_BILLING_ACCOUNT}. Nothing to do."
  exit 0
fi

echo "The following ${#PROJECTS[@]} project(s) will be migrated:"
printf '  - %s\n' "${PROJECTS[@]}"
echo "  From: ${OLD_BILLING_ACCOUNT}"
echo "  To:   ${NEW_BILLING_ACCOUNT}"
echo

# ---- Confirmation prompt (skipped in dry-run) ----
if [[ "$DRY_RUN" == false ]]; then
  if ! read -r -p "Proceed with live migration? [y/N] " CONFIRM; then
    echo
    echo "Aborted."
    exit 0
  fi
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
  echo
fi

# ---- Migrate ----
SUCCEEDED=0
FAILED=0

for PROJECT in "${PROJECTS[@]}"; do
  echo "==> ${PROJECT}"

  if ! validate_project_source_billing "$PROJECT"; then
    (( FAILED++ )) || true
    continue
  fi

  if [[ "$DRY_RUN" != false ]]; then
    echo "    verified linked to ${OLD_BILLING_ACCOUNT}"
    echo "    [DRY RUN] would link to ${NEW_BILLING_ACCOUNT}"
    continue
  fi

  # Atomically re-assign billing account (no unlink step needed)
  if gcloud billing projects link "${PROJECT}" \
       --billing-account="${NEW_BILLING_ACCOUNT}"; then
    echo "    linked to ${NEW_BILLING_ACCOUNT}"
    (( SUCCEEDED++ )) || true
  else
    echo "    ERROR: failed to link ${PROJECT} to ${NEW_BILLING_ACCOUNT}" >&2
    (( FAILED++ )) || true
  fi
done

echo
if [[ "$DRY_RUN" != false ]]; then
  VALIDATED=$(( ${#PROJECTS[@]} - FAILED ))
  if (( VALIDATED > 0 )); then
    echo "Dry run complete. ${VALIDATED} validated, ${FAILED} failed. Re-run with DRY_RUN=false to apply."
  else
    echo "Dry run complete. ${VALIDATED} validated, ${FAILED} failed. Resolve validation failures before running a live migration."
  fi
else
  echo "Done. ${SUCCEEDED} succeeded, ${FAILED} failed."
fi
