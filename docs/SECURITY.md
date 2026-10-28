# Security notes and release gate

CareBridge is a portfolio demonstration, not a certified medical-record system. Never use real patient data or expose the demo to the public as a real clinic service.

## Controls in this repository

- Passwords are hashed with bcrypt; SQL queries use parameters for user-controlled values.
- JWT signing requires a secret of at least 32 characters.
- CORS is restricted to configured origins; request/response security headers are set by the API and Nginx.
- Doctor image uploads are limited by size and declared image MIME type. MIME headers can be spoofed, so production needs file-signature validation, image re-encoding and malware scanning.
- GCP startup scripts do not enable shell xtrace; this avoids printing command arguments, metadata tokens or secret values into startup logs.
- Production database seeding fails if bootstrap passwords are missing.
- Password recovery returns `503` in production until a real delivery provider is configured; the local demo terminal-code flow must not be used in production.
- GitHub Actions runs syntax checks, tests, dependency audits, integration smoke tests, Docker image builds and Terraform validation.

## Before a public demo or production release

- [ ] Rotate every credential that has appeared in a sample file, terminal, screenshot, archive or repository history.
- [ ] Use a secret manager and least-privilege identities; never commit `.env`, Terraform state, or rendered Secret manifests.
- [ ] Configure HTTPS and secure cookie/session strategy; the current frontend stores its bearer token in `localStorage`, which is vulnerable if an XSS bug is introduced.
- [ ] Add distributed rate limiting for login, registration, password reset and other sensitive routes. The in-process reset attempt map is not suitable for multi-replica deployments.
- [ ] Add audit trails for patient-record reads and writes, data retention/consent workflows, MFA and privacy/legal review for applicable Indian DPDP requirements.
- [ ] Validate uploaded image file signatures and re-encode images before serving them.
- [ ] Configure production email/SMS recovery, real payment provider, monitoring/alerting and documented incident response.
- [ ] Test encrypted backups and restore drills; verify recovery time and recovery point objectives.
- [ ] Use a managed database, private networking, restricted ingress, TLS, image provenance and policy checks before real clinical use.
- [ ] Review Terraform plan, cost estimate, IAM permissions and state backend before `terraform apply`.

## Reporting a vulnerability

Do not publish credentials or sensitive data in an issue. For a portfolio demo, privately contact the repository owner and include reproduction steps without real patient data.
