# FAST landing zone (single-project retail)

Adapted [Fabric FAST](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast) — **full structure:** [`docs/FAST_STRUCTURE.md`](../../docs/FAST_STRUCTURE.md).

**This repo (`gke-retail-infra`):** `fast/` and `scripts/` at repo root (no `infra/` prefix).

```text
fast/
  datasets/<env>/          ← edit env + stack tfvars HERE
  stages/0-bootstrap|1-network|2-platform/<stack>/
  modules/
scripts/                   ← tf.sh, generate-fast-stages.mjs, …
```

```bash
node scripts/generate-fast-stages.mjs
terraform fmt -recursive fast
./scripts/gcp-bootstrap.sh dev
./scripts/test-static.sh dev
./scripts/tf-apply-all.sh dev plan
```

Monorepo mirror uses the same layout under `infra/fast/` and `infra/scripts/` (`gke-microservices`).
