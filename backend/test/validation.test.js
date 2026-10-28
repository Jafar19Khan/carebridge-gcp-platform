import test from 'node:test';
import assert from 'node:assert/strict';

const email = /^\S+@\S+\.\S+$/;
const date = /^\d{4}-\d{2}-\d{2}$/;
const time = /^\d{2}:\d{2}$/;
const slotSupports = (slotMode, requestedMode) => slotMode === 'BOTH' || slotMode === requestedMode;

test('valid email accepted', () => assert.equal(email.test('user@example.com'), true));
test('invalid email rejected', () => assert.equal(email.test('not-an-email'), false));
test('valid date format accepted', () => assert.equal(date.test('2026-10-05'), true));
test('malformed date rejected', () => assert.equal(date.test('05-10-2026'), false));
test('valid time format accepted', () => assert.equal(time.test('10:30'), true));
test('clinic slot accepts clinic booking', () => assert.equal(slotSupports('CLINIC', 'CLINIC'), true));
test('clinic slot rejects online booking', () => assert.equal(slotSupports('CLINIC', 'ONLINE'), false));
test('online slot rejects clinic booking', () => assert.equal(slotSupports('ONLINE', 'CLINIC'), false));
test('both slot accepts either booking mode', () => assert.equal(slotSupports('BOTH', 'ONLINE') && slotSupports('BOTH', 'CLINIC'), true));

import { readFile } from 'node:fs/promises';

test('appointment confirmation button is wired to the booking handler', async () => {
  const source = await readFile(new URL('../../frontend/src/main.jsx', import.meta.url), 'utf8');
  assert.match(source, /onClick=\{book\}[^>]*>\s*\{busy\?\s*'Booking…'\s*:\s*'Confirm appointment'\}/);
});

test('forgot-password and reset-password endpoints are present', async () => {
  const source = await readFile(new URL('../server.js', import.meta.url), 'utf8');
  assert.match(source, /\/api\/auth\/forgot-password/);
  assert.match(source, /\/api\/auth\/reset-password/);
});

test('GCP startup templates do not enable shell xtrace around secret handling', async () => {
  const { readFile } = await import('node:fs/promises');
  for (const file of ['../../terraform/gcp/templates/app.sh.tftpl','../../terraform/gcp/templates/db.sh.tftpl','../../terraform/gcp/templates/web.sh.tftpl']) {
    const source = await readFile(new URL(file, import.meta.url), 'utf8');
    assert.doesNotMatch(source, /set -[a-z]*x[a-z]*/);
  }
});

test('production password recovery fails closed without a delivery provider', async () => {
  const { readFile } = await import('node:fs/promises');
  const source = await readFile(new URL('../server.js', import.meta.url), 'utf8');
  assert.match(source, /NODE_ENV==='production'[\s\S]{0,160}status\(503\)/);
});

test('production demo seeding requires explicit bootstrap passwords', async () => {
  const { readFile } = await import('node:fs/promises');
  const source = await readFile(new URL('../scripts/seed.js', import.meta.url), 'utf8');
  assert.match(source, /NODE_ENV==='production'[\s\S]{0,120}must be configured/);
});

test('GCP app upload backups are scheduled and use the private bucket', async () => {
  const { readFile } = await import('node:fs/promises');
  const appTemplate = await readFile(new URL('../../terraform/gcp/templates/app.sh.tftpl', import.meta.url), 'utf8');
  const computeConfig = await readFile(new URL('../../terraform/gcp/compute.tf', import.meta.url), 'utf8');
  const iamConfig = await readFile(new URL('../../terraform/gcp/iam.tf', import.meta.url), 'utf8');
  assert.match(appTemplate, /carebridge-uploads-backup\.sh/);
  assert.match(appTemplate, /\$\{bucket\}/);
  assert.match(computeConfig, /bucket\s+=\s+google_storage_bucket\.backups\.name/);
  assert.match(iamConfig, /app_upload_backup_writer[\s\S]*roles\/storage\.objectCreator/);
});

test('GCP database backup schedule installs cron and retains object-only access', async () => {
  const { readFile } = await import('node:fs/promises');
  const dbTemplate = await readFile(new URL('../../terraform/gcp/templates/db.sh.tftpl', import.meta.url), 'utf8');
  const iamConfig = await readFile(new URL('../../terraform/gcp/iam.tf', import.meta.url), 'utf8');
  assert.match(dbTemplate, /apt-get install -y docker\.io jq curl cron/);
  assert.match(dbTemplate, /carebridge-backup\.sh/);
  assert.match(iamConfig, /db_backup_writer[\s\S]*roles\/storage\.objectCreator/);
});
