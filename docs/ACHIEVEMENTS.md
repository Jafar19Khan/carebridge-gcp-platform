# CareBridge — Achievements and evidence

This page separates what is implemented in the repository from what has actually been executed. Never convert planned configuration into a claim of successful production deployment.

## Implemented in code/configuration

- **Three-tier GCP design:** separate web, application and database subnets with firewall rules for Internet → web, web → API and API → MySQL. Only the web VM receives a public IP.
- **Identity-based access:** OS Login/IAP SSH design, three per-tier service accounts and secret-level Secret Manager permissions instead of static cloud access keys.
- **Secret handling:** Terraform-generated passwords stored in Secret Manager; startup scripts do not enable shell xtrace. Terraform state still contains sensitive values and must be protected.
- **Backup automation:** scheduled MySQL dumps and doctor-upload archives are uploaded to a private Cloud Storage bucket; the bucket lifecycle policy expires objects after 14 days. Backup success and restore must still be observed/tested in the target GCP project.
- **CI automation:** GitHub Actions configuration includes secret scanning, backend checks/tests, dependency audits, frontend build, MySQL-backed API smoke tests, Docker/Compose tests, a local Compose backup/restore drill, Terraform formatting/validation and GHCR publishing.
- **Application:** Patient, Doctor and Clinic Admin experiences with authentication, doctor discovery, appointment booking, schedule management and admin workflows.

## Verified during this archive audit

- Backend JavaScript syntax checks: passed.
- Backend built-in Node test suite: **16 tests passed, 0 failed** (`node --test`).
- ZIP archive integrity: checked after packaging.
- GCP startup shell templates: shell syntax checked after substituting Terraform template variables with test values.

## Not verified here — do not claim yet

- `npm ci` dependency installation, frontend production build and full integration suite in this environment.
- Docker image builds, running Compose stack, or the CI backup/restore drill.
- `terraform init/validate/plan` with the real provider and target project.
- Real GCP `terraform apply`, successful web/API sign-in, scheduled backup upload, restore drill, HTTPS or uptime.

## Honest measurable outcomes

Use configuration facts rather than invented impact metrics: **3 isolated network tiers, 3 tier-specific service accounts, 6 Secret Manager secrets, 14-day backup retention, and a 16-test backend suite**. These are design/configuration outcomes, not evidence of cost savings, zero vulnerabilities or production uptime.
