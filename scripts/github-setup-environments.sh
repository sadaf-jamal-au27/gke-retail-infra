#!/usr/bin/env bash
# GitHub Environments: dev (branch develop) + prod (branch main).
set -euo pipefail

ORG="${GITHUB_OWNER:-sadaf-jamal-au27}"
REPOS=(gke-retail-infra gke-retail-application gke-retail-devops gke-microservices)

if ! command -v gh >/dev/null; then
  echo "Install gh: https://cli.github.com/"
  exit 1
fi

put_env() {
  local repo="$1"
  local env_name="$2"
  local branch="$3"
  echo "→ ${ORG}/${repo} environment ${env_name} (deploy branch: ${branch})"
  gh api --method PUT "repos/${ORG}/${repo}/environments/${env_name}" \
    --input - <<EOF
{
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true,
    "custom_branch_policies_attributes": [
      { "name": "${branch}", "type": "branch" }
    ]
  }
}
EOF
}

for repo in "${REPOS[@]}"; do
  put_env "${repo}" "dev" "develop"
  put_env "${repo}" "prod" "main"
done

echo "Done. Add required reviewers on environment 'prod' in GitHub UI when ready."
