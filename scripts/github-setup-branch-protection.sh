#!/usr/bin/env bash
# Protected branches: no direct push to develop/main — merge only via PR.
#   feature/* → PR develop | develop → PR main
set -euo pipefail

ORG="${GITHUB_OWNER:-sadaf-jamal-au27}"
REPOS="${*:-gke-retail-infra gke-microservices}"

if ! command -v gh >/dev/null; then
  echo "Install gh: https://cli.github.com/"
  exit 1
fi

protect_branch() {
  local repo="$1"
  local branch="$2"
  local reviews="$3"

  echo "Protecting ${ORG}/${repo}:${branch} (required PR reviews: ${reviews}) …"
  gh api --method PUT "repos/${ORG}/${repo}/branches/${branch}/protection" \
    --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Terraform static checks" },
      { "context": "Terraform plan (GCP)" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": ${reviews},
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
EOF
}

for REPO in ${REPOS}; do
  echo "=== ${ORG}/${REPO} ==="
  protect_branch "${REPO}" develop 0
  protect_branch "${REPO}" main 1
done

cat <<'NOTE'

Done. develop + main: direct push blocked (PR merge only), admins included.
  develop: PR required + CI checks (0 approvals — add 1 if you want)
  main:    PR required + CI checks + 1 approval

Flow: feature/* → PR develop → merge → manual infra-apply (dev)
      develop   → PR main    → merge → manual infra-apply (prod)

GitHub UI (optional): Settings → Branches → verify both rules; disable bypass lists.
NOTE
