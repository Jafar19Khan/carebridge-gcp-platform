import 'dotenv/config';
import pool from '../db.js';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
try {
 const schema=await readFile(fileURLToPath(new URL('../db/001_init.sql',import.meta.url)),'utf8');
 for(const statement of schema.split(';').map(s=>s.trim()).filter(Boolean)) await pool.query(statement);
 // Safe additive migrations for installations created by the earlier CareBridge MySQL build.
 try { await pool.query('ALTER TABLE appointments DROP INDEX uq_doctor_appointment_slot'); } catch(e) { if(e.code!=='ER_CANT_DROP_FIELD_OR_KEY') throw e; }
 for(const sql of [
  'ALTER TABLE doctors ADD COLUMN photo_url VARCHAR(255) DEFAULT NULL',
  "ALTER TABLE doctors ADD COLUMN qualification VARCHAR(180) DEFAULT ''",
  "ALTER TABLE clinics ADD COLUMN phone VARCHAR(30) DEFAULT ''",
  "ALTER TABLE clinics ADD COLUMN email VARCHAR(180) DEFAULT ''"
 ]) { try { await pool.query(sql); } catch(e) { if(e.code!=='ER_DUP_FIELDNAME') throw e; } }
 console.log('MySQL schema and additive migrations are ready.');
} catch(error) { console.error('Database initialization failed:',error.message); process.exitCode=1; }
finally { await pool.end(); }
