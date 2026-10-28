# CareBridge feature and readiness audit

## Included in this delivery

- Three separate role experiences: Patient, Doctor and Clinic Admin. No staff/reception portal.
- Patient registration/login, doctor discovery, speciality filtering, slot-based booking, appointment history, cancellation and notifications.
- Booking confirmation button wired to the API; backend validates the slot and creates the appointment/payment/notifications inside a MySQL transaction with slot-row locking and a duplicate-booking check.
- Doctor login, personal appointment list, schedule management, profile editing and photo upload.
- Admin dashboard, doctor creation and photo selection, patient directory, appointment management, payment ledger and clinic profile settings.
- Local password recovery: 6-digit one-time code printed in the backend terminal, 15-minute expiry, one-time use and limited reset attempts. Production email/SMS delivery is not configured.
- MySQL persistence, bcrypt password hashing, JWT authentication, role checks on protected routes, parameterised SQL and upload size/MIME checks.
- Doctor image files saved in `backend/uploads/doctors/`; their relative paths are stored in MySQL. Included sample portraits are linked during seeding.
- Responsive desktop/tablet/mobile UI and a lightweight CSS 3D hero treatment.

## Not production-certified

- Payment settlement is simulated local demo only; no real payment provider is integrated.
- The application is not a certified EMR and does not implement a clinically validated medical-record or prescription workflow.
- No MFA, formal audit-trail viewer, consent/retention workflow, medical-document vault, malware scanning or global API rate limiting. GCP DB/upload backup jobs and a local Compose restore drill are configured, but live GCP backup and restore have not been verified.
- Password reset is terminal-delivered for local demo only. Production needs verified email/SMS delivery.
- Production deployment requires HTTPS, secure secrets management, hardened session/token lifecycle, strict upload content inspection, least-privilege database credentials, observability, penetration testing, legal/privacy review and clinic-specific workflow validation.

## Verification performed in the build environment

- Backend JavaScript syntax checks passed.
- 16/16 backend automated tests passed, including regression checks for the appointment confirmation handler, password recovery routes, startup-script secret tracing and production seed requirements.
- ZIP integrity passed; local `.env` and `node_modules` are excluded.
- Live MySQL integration and frontend production build were not run in this environment because the frontend dependency install did not complete and no target MySQL server was available. Run the verification commands in the README on the company laptop before the presentation.
