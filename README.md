# gke-retail-infra

Fabric FAST Terraform — see `docs/FAST_STRUCTURE.md` and `docs/INFRA_SETUP.md`.

**Paths here:** `fast/` + `scripts/` (not `infra/fast`).

```bash
cd ~/Projects/gke-retail-infra

node scripts/generate-fast-stages.mjs
terraform fmt -recursive fast

./scripts/gcp-bootstrap.sh dev
export TF_VAR_database_password='your-password'
./scripts/test-static.sh dev
./scripts/tf-apply-all.sh dev plan
```
