#!/usr/bin/env bash
# Branch protection: develop (integration) + main (release).
set -euo pipefail

ORG="${GITHUB_OWNER:-sadaf-jamal-au27}"
REPO="${1:-gke-retail-infra}"

if ! command -v gh >/dev/null; then
  echo "Install gh: https://cli.github.com/"
  exit 1
fi

protect() {
  local branch="$1"
  echo "Protecting ${ORG}/${REPO}:${branch} …"
  gh api --method PUT "repos/${ORG}/${REPO}/branches/${branch}/protection" \
    --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Terraform static checks" },
      { "context": "Terraform plan (GCP)" }
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
}

protect develop
protect main

echo "Done."
