# CareBridge on GCP — zero to live demo

This guide deploys the current **portfolio/demo** architecture. It is not a certified or production-ready healthcare service: the web tier uses HTTP, the database is self-managed on a VM, and the application has demo-only payment and password-recovery behavior. Do not use real patient data.

## 0. Understand cost and cleanup first

The configuration creates three Compute Engine VMs, disks, a static external IP, Cloud NAT, Secret Manager secrets, a Cloud Storage bucket and supporting networking. The database VM is `e2-small`; Cloud NAT and the app/database VMs can incur charges. The Always Free tier does not cover this entire stack. Review current pricing and your billing account before proceeding. **Run `terraform destroy` after the demo.**

## 1. Prerequisites

- A GCP project with billing enabled and permission to enable APIs/create Compute Engine, IAM, Secret Manager and Storage resources.
- `gcloud` CLI, Terraform >= 1.6, Git and Docker (for local checks).
- GitHub access to this repository.
- A user account granted, by the project administrator, `roles/iap.tunnelResourceAccessor`, `roles/compute.osLogin` (or `roles/compute.osAdminLogin` if sudo is required), and sufficient Compute Viewer/instance metadata permissions to connect with IAP. Do not grant broad Owner just for SSH.

## 2. Validate locally before cloud spend

From the repository root:

```bash
cd backend
node --check server.js
node --test
cd ../terraform/gcp
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

The test suite is currently 16 tests. A passing unit suite does not replace the full Docker/CI and live cloud checks.

## 3. Publish the container images

1. Push the project to `main` on GitHub. The CI workflow runs tests and publishes images to GitHub Container Registry (GHCR) only after its required integration and Compose jobs pass.
2. Open the repository's **Packages** and set both `carebridge-backend` and `carebridge-frontend` packages to **Public** for this demo deployment. The VMs do not log in to GHCR; private packages will fail to pull.
3. For a versioned release, create and push a tag after `main` CI is green:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

   Wait for the Release workflow to finish and confirm both versioned packages exist. Do not assume the tag workflow passed just because the tag was pushed.

## 4. Select a GCP project and enable billing

```bash
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT_ID
gcloud services enable compute.googleapis.com secretmanager.googleapis.com iam.googleapis.com iap.googleapis.com storage.googleapis.com
```

If you need a new project, create it in the Cloud Console or with `gcloud projects create YOUR_UNIQUE_PROJECT_ID`, then link a billing account in the Console or with `gcloud billing projects link YOUR_GCP_PROJECT_ID --billing-account=YOUR_BILLING_ACCOUNT_ID`.

Before Terraform, confirm the project ID and billing account are correct. The resource names use the `carebridge` prefix by default; change `name_prefix` if you already have conflicting names.

## 5. Configure Terraform

```bash
cd terraform/gcp
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
project_id = "YOUR_GCP_PROJECT_ID"
ghcr_owner = "jafar19khan" # lowercase GitHub username
image_tag  = "v1.0.0"      # use the tag published in Step 3
# Optional but recommended for a restricted demo:
# allowed_web_cidrs = ["YOUR_PUBLIC_IP/32"]
```

For the default setup, `allowed_web_cidrs` permits public HTTP access. Restrict it to your own public IP for a private demo where practical. Do not commit `terraform.tfvars` or `terraform.tfstate`: generated secrets are present in Terraform state. The repository ignores both, but you must still protect the files and disk. For team/production work, configure a separately created, access-controlled GCS remote state bucket with versioning before applying.

Run a plan and inspect every resource:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform show tfplan
```

Only proceed if the plan is expected and the cost is acceptable:

```bash
terraform apply tfplan
```

## 6. Wait for startup and get the demo credentials

VM startup scripts install Docker, pull the images, configure the app/database and install scheduled backup jobs. This can take several minutes; do not assume that the URL is ready immediately after `apply`.

```bash
terraform output -raw web_url
gcloud secrets versions access latest --secret=carebridge-bootstrap-admin-password
```

Open the `web_url` in your browser. Admin email is `admin@carebridge.local`; use the password returned by Secret Manager. Patient and doctor bootstrap passwords are stored in similarly named secrets: `carebridge-bootstrap-patient-password` and `carebridge-bootstrap-doctor-password`. Keep the output private and do not paste it into GitHub, screenshots or chat.

## 7. Verify the running service

```bash
WEB_URL="$(terraform output -raw web_url)"
curl -fsS "$WEB_URL/health"
curl -fsS "$WEB_URL/ready"
```

Log in to the app and test patient, doctor and admin workflows with synthetic demo data. To inspect VM startup logs through IAP (the VMs do not allow direct internet SSH), use the zone from `terraform.tfvars`/variables (default `us-central1-a`):

```bash
gcloud compute ssh carebridge-web --zone us-central1-a --tunnel-through-iap --command "sudo docker ps; sudo tail -80 /var/log/carebridge-startup.log"
gcloud compute ssh carebridge-app --zone us-central1-a --tunnel-through-iap --command "sudo docker ps; sudo tail -80 /var/log/carebridge-startup.log"
gcloud compute ssh carebridge-db --zone us-central1-a --tunnel-through-iap --command "sudo docker ps; sudo tail -80 /var/log/carebridge-startup.log"
```

The private app and database IPs should not be reachable directly from your laptop. The intended paths are public web → private API → private database.

## 8. Verify backup uploads

Database backups are scheduled daily at 02:00 UTC; doctor-upload backups are scheduled at 02:15 UTC. The bucket lifecycle policy expires backup objects after 14 days. To run each backup immediately:

```bash
gcloud compute ssh carebridge-db --zone us-central1-a --tunnel-through-iap --command "sudo /usr/local/bin/carebridge-backup.sh"
gcloud compute ssh carebridge-app --zone us-central1-a --tunnel-through-iap --command "sudo /usr/local/bin/carebridge-uploads-backup.sh"
gcloud storage ls "gs://$(terraform output -raw backup_bucket)"
```

These commands verify upload only. Before a real production service, restore both database and uploads into an isolated environment and verify application consistency. A backup file existing is not proof that restore works.

## 9. Update a release

1. Merge changes into `main` and wait for all required CI jobs to pass.
2. Publish a new version tag, for example `v1.0.1`, and wait for the Release workflow.
3. Change `image_tag` in `terraform.tfvars` to the new tag.
4. Review `terraform plan` carefully. A startup-script metadata change may cause VM changes/replacements depending on provider behavior; schedule this as a maintenance operation and back up data first.
5. Apply, wait for startup, and re-run the smoke tests. For a rollback, use the previous known-good image tag and plan/apply again.

## 10. Destroy the demo resources

Back up anything you need first. From `terraform/gcp`:

```bash
terraform destroy
```

Confirm the plan lists only CareBridge demo resources before approving. Check the Cloud Console for remaining disks, static IPs, NAT, bucket objects or other resources if the apply had partially failed. Terraform leaves enabled Google APIs enabled by design; they normally do not incur resource charges by themselves.

## 11. What is required before production use?

This configuration is a live demo, not production-ready. At minimum, production work needs:

- HTTPS with a domain and managed certificate/load balancer; do not collect credentials over public HTTP.
- A managed/private database such as Cloud SQL, automated HA, private IP, patching, monitoring and tested point-in-time recovery.
- Stronger identity controls (MFA, secure session/token lifecycle, rate limiting, audit logs and formal access reviews).
- Production email/SMS password recovery and a real payment provider if payment is required.
- Upload content-signature validation/re-encoding/malware scanning; durable object storage and tested restore procedures.
- Centralized logs/metrics/alerts, vulnerability management, image provenance, incident response and least-privilege review.
- Legal/privacy review for applicable Indian DPDP requirements and clinical workflow validation before handling any real health information.

Never claim zero bugs, zero vulnerabilities, cost savings, uptime or production readiness without evidence from a real test and deployment.
