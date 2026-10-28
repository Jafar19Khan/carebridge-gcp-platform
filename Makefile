.PHONY: up setup down logs test check backup restore
up:      ; docker compose up --build -d db backend frontend
setup:   ; docker compose --profile setup run --rm migrate
down:    ; docker compose down
logs:    ; docker compose logs -f --tail=100
test:    ; cd backend && npm test
check:   ; cd backend && npm ci && npm run check && npm test
backup:  ; scripts/backup.sh backups
restore: ; scripts/restore.sh $(DB) $(UPLOADS)
