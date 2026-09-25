# FAST landing zone (single-project retail)

Layout follows [Google Cloud Foundation Fabric FAST](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast) stage model, adapted for one GCP project per environment.

```text
infra/fast/
  datasets/<env>/env.tfvars     # project, region, GitHub WIF identity
  stages/
    0-bootstrap/                # APIs, state artifacts, CI WIF
      project_services/
      cloud_storage/
      github_wif/
    1-network/                  # Fabric net-vpc + serverless connector
      network/
    2-platform/                 # GKE, Cloud SQL, Pub/Sub, Cloud Run
      gke/
      cloudsql/
      pubsub/
      cloudrun/
  modules/                      # Wrappers; network uses Fabric net-vpc
```

Remote state prefix (unchanged): `gs://{project}-retail-tfstate-{env}/{env}/{stack}/`

## Commands

```bash
node infra/scripts/generate-fast-stages.mjs
./infra/scripts/tf.sh dev project_services plan
./infra/scripts/tf-apply-all.sh dev plan
./infra/scripts/test-unit.sh dev
./infra/scripts/test-integration.sh dev
```

See [../README.md](../README.md) and [../../docs/INFRA_SETUP.md](../../docs/INFRA_SETUP.md).
