# CareBridge — GCP 3-Tier Clinic Appointment Platform

CareBridge is a portfolio application with Patient, Doctor and Clinic Admin workspaces. Its DevOps story focuses on **GCP network isolation, IAM, Secret Manager, GitHub Actions, repeatable VM provisioning, and database/upload backups**. It intentionally does not duplicate Shipyard’s Kubernetes, Jenkins, Ansible, Prometheus/Grafana or Trivy platform story.

> **Safety:** This is a learning/demo project, not a certified EMR or production clinical system. Use synthetic data only. The payment flow is simulated; password recovery is local-demo only. Do not expose it as a real clinic service or enter real patient data.

## What this project demonstrates

- React/Vite frontend, Express API, MySQL database and role-separated patient/doctor/admin flows.
- Local development with Docker Compose and a repeatable schema/seed setup.
- GitHub Actions for syntax checks, 16 backend tests, frontend build, dependency audit, Gitleaks, MySQL integration smoke tests, Docker builds, Compose smoke/backup-restore drill, Terraform validation and GHCR publishing.
- GCP Terraform configuration for three VM tiers/subnets, firewall boundaries, Cloud NAT, IAP/OS Login, per-tier service accounts, Secret Manager and a private Cloud Storage bucket.
- Scheduled database and doctor-upload backups to Cloud Storage with a 14-day bucket lifecycle policy.

The local backend test suite was run during this audit: **16/16 passed**. That does not mean the full Docker workflow, Terraform apply or live GCP deployment has been executed. Check `docs/ACHIEVEMENTS.md` for the exact evidence status.

## Fastest local start (Docker Desktop)

Requirements: Docker Desktop with Compose v2, Git, and a terminal.

1. Copy the environment template:

   ```powershell
   Copy-Item .env.docker.example .env
   ```

2. Edit `.env`: replace every sample password and generate a unique JWT secret. Generate one with:

   ```powershell
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

3. Validate configuration and start services:

   ```powershell
   docker compose config -q
   docker compose up --build -d db backend frontend
   docker compose --profile setup run --rm migrate
   ```

4. Open `http://localhost:8080`. API health: `http://localhost:8080/health`; readiness: `http://localhost:8080/ready`.

5. Stop services with `docker compose down`. **`docker compose down -v` deletes local database and uploads data.**

The seeded demo accounts use the password values configured in `.env`: `admin@carebridge.local`, `aarav.patient@carebridge.local`, and the doctor emails listed in `docs/FEATURE_AUDIT.md`. Change all sample passwords before any external demo.

## Run checks locally

Backend (Node.js 20.14+ / npm 10+):

```bash
cd backend
npm ci
npm run check
npm test
```

Frontend production build (separate terminal):

```bash
cd frontend
npm ci
npm run build
```

Docker/backup smoke test and Terraform commands are described in `docs/DEVOPS.md` and `docs/GCP_DEPLOY.md`.

## GCP deployment

Start with `docs/GCP_DEPLOY.md`. It includes image publishing, GCP project/billing setup, IAM prerequisites, Terraform plan/apply, validation, backups, cost controls and teardown. **A public GCP deployment uses HTTP in this demo configuration. Do not treat it as production-ready without HTTPS, a domain/load balancer, stronger application controls, restore drills and a professional security/privacy review.**

## Documentation

- `docs/ACHIEVEMENTS.md` — implemented outcomes, verified checks and unverified claims.
- `docs/ARCHITECTURE.md` — three-tier design and network flow.
- `docs/DEVOPS.md` — local Docker, CI and recovery workflows.
- `docs/FEATURE_AUDIT.md` — application features and limitations.
- `docs/GCP_DEPLOY.md` — zero-to-live demo deployment and teardown.
- `docs/PORTFOLIO.md` — how this project differs from Shipyard and resume wording.
- `docs/SECURITY.md` — security controls and production release gate.

## Repository hygiene

Do not commit `.env`, `backend/.env`, `terraform.tfvars`, Terraform state, real credentials, production uploads or real patient data. The archive excludes dependency folders and local environment files; use `npm ci` to install from lockfiles.
