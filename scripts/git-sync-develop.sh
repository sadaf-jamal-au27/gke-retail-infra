#!/usr/bin/env bash
# Ensure remote develop exists and matches main (one-time / after release).
set -euo pipefail

REPO="${1:-.}"
cd "${REPO}"

git fetch origin
git checkout main
git pull origin main

if git show-ref --verify --quiet refs/heads/develop; then
  git checkout develop
  git merge --ff-only main || {
    echo "develop diverged from main — resolve locally, then push develop"
    exit 1
  }
else
  git checkout -b develop
fi

git push -u origin develop
echo "OK: origin/develop is synced with main"
echo "Workflow: feature/* → PR develop (infra-plan) → merge → infra-apply on develop"
