# CareBridge — DevOps guide

CareBridge is focused on GCP three-tier infrastructure and application operations. It does not include Kubernetes, Jenkins, Ansible, Prometheus or Grafana; those belong to the separate Shipyard project.

## Local Docker Compose

```bash
cp .env.docker.example .env   # change every password and JWT_SECRET first
docker compose config -q
docker compose up --build -d db backend frontend
docker compose --profile setup run --rm migrate
```

Open `http://localhost:8080`. The frontend Nginx container serves the React build and proxies API, health and upload requests to the backend. Stop with `docker compose down`; `docker compose down -v` also deletes the local database and uploads volumes.

## CI workflow

`.github/workflows/ci.yml` covers:

- Backend syntax checks, tests and npm dependency audit.
- Frontend production build and dependency audit.
- Gitleaks secret scanning.
- MySQL-backed API integration/smoke tests.
- Docker image builds.
- Compose stack smoke test and backup/restore drill.
- Terraform formatting and validation for `terraform/gcp`.
- Publishing versioned container images to GHCR from `main`.

This pipeline is different from Shipyard's Jenkins + ECR + Kubernetes rollout pipeline. CareBridge's emphasis is integration reliability, recovery and GCP infrastructure controls.

## GCP infrastructure

Read `docs/ARCHITECTURE.md` and `docs/GCP_DEPLOY.md` before applying Terraform. The deployment provisions three VM tiers, a custom VPC, firewall rules, Cloud NAT, per-tier service accounts, Secret Manager and a private Cloud Storage backup bucket. The web tier is public; app and database tiers have no public IPs. Admin SSH is intended to use IAP/OS Login.

## Backup and restore

Use the scripts documented in the README/Makefile for local Compose backup and restore. On GCP, inspect the database and application startup templates, verify both database and doctor-upload objects in the private bucket, and test a restore in a disposable environment. A backup script existing in the repository is not, by itself, proof that disaster recovery has been tested successfully.

## Safety and limitations

- The app is a portfolio demo, not a certified EMR; do not enter real patient information.
- Local demo payments are not real payment processing.
- Password recovery requires a real delivery provider before production use.
- GCP deployment can incur charges. Review the plan and destroy resources after testing.
- Run all GitHub Actions checks and personally verify a GCP deployment before using resume bullets that imply successful deployment.
