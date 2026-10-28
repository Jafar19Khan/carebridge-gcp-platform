#!/usr/bin/env bash
# End-to-end smoke test against a running CareBridge API.
# Usage: scripts/smoke-test.sh http://127.0.0.1:4000   (needs curl + jq)
# Env: ADMIN_EMAIL, ADMIN_PASSWORD, PATIENT_EMAIL, PATIENT_PASSWORD
set -euo pipefail
BASE="${1:-http://127.0.0.1:4000}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@carebridge.local}"
PATIENT_EMAIL="${PATIENT_EMAIL:-aarav.patient@carebridge.local}"
: "${ADMIN_PASSWORD:?set ADMIN_PASSWORD}" "${PATIENT_PASSWORD:?set PATIENT_PASSWORD}"

pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; exit 1; }
post() { curl -sS -o /tmp/smoke_body -w '%{http_code}' -X POST "$BASE$1" -H 'Content-Type: application/json' ${3:+-H "Authorization: Bearer $3"} -d "$2"; }

[ "$(curl -sS -o /dev/null -w '%{http_code}' "$BASE/health")" = 200 ] && pass "/health (API + database)" || fail "/health"
[ "$(curl -sS -o /dev/null -w '%{http_code}' "$BASE/ready")" = 200 ] && pass "/ready" || fail "/ready"

[ "$(post /api/auth/admin-login "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")" = 200 ] && pass "admin login" || fail "admin login"
ADMIN_TOKEN=$(jq -r .token /tmp/smoke_body)
[ "$(post /api/auth/login "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")" = 401 ] && pass "admin cannot use patient login (role separation)" || fail "role separation"

[ "$(post /api/auth/login "{\"email\":\"$PATIENT_EMAIL\",\"password\":\"$PATIENT_PASSWORD\"}")" = 200 ] && pass "patient login" || fail "patient login"
TOKEN=$(jq -r .token /tmp/smoke_body)

[ "$(curl -sS -o /dev/null -w '%{http_code}' "$BASE/api/dashboard" -H "Authorization: Bearer $TOKEN")" = 403 ] && pass "patient blocked from admin dashboard" || fail "RBAC on /api/dashboard"
[ "$(curl -sS -o /dev/null -w '%{http_code}' "$BASE/api/dashboard" -H "Authorization: Bearer $ADMIN_TOKEN")" = 200 ] && pass "admin dashboard" || fail "admin dashboard"

COUNT=$(curl -sS "$BASE/api/doctors" | jq length)
[ "$COUNT" -ge 1 ] && pass "doctor directory ($COUNT doctors)" || fail "doctor directory empty"
DOCTOR=$(curl -sS "$BASE/api/doctors" | jq -r '.[-1].id')
DATE=$(date -u -d '+2 days' +%F)
SLOT=$(curl -sS "$BASE/api/doctors/$DOCTOR/slots?date=$DATE" -H "Authorization: Bearer $TOKEN" | jq -r '[.[]|select(.available==1)][0].slot_time')
[ -n "$SLOT" ] && [ "$SLOT" != null ] && pass "free slot found ($DATE $SLOT)" || fail "no free slot"
SLOT="${SLOT:0:5}"

BOOK="{\"doctor_id\":$DOCTOR,\"appointment_date\":\"$DATE\",\"appointment_time\":\"$SLOT\",\"reason\":\"smoke test\",\"mode\":\"CLINIC\",\"payment_method\":\"PAY_AT_CLINIC\"}"
[ "$(post /api/appointments "$BOOK" "$TOKEN")" = 201 ] && pass "booking created" || fail "booking ($(cat /tmp/smoke_body))"
[ "$(post /api/appointments "$BOOK" "$TOKEN")" = 409 ] && pass "double booking rejected (transaction + row lock)" || fail "double booking was NOT rejected"
echo "All smoke tests passed."
