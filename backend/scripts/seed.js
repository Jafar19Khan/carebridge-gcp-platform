import 'dotenv/config';
import bcrypt from 'bcryptjs';
import fs from 'node:fs';
import pool from '../db.js';
const hash = p => bcrypt.hash(p, 12);
const days = Array.from({length:21},(_,i)=>{const d=new Date();d.setDate(d.getDate()+i);return d.toISOString().slice(0,10)});
async function main(){
 if(process.env.SEED_INITIAL_DATA==='false'){console.log('Initial data seeding disabled');return;}
 const adminEmail=process.env.BOOTSTRAP_ADMIN_EMAIL||'admin@carebridge.local';
 const requiredPassword=(name,localDemoValue)=>{
  const configured=process.env[name];
  if(configured) return configured;
  if(process.env.NODE_ENV==='production') throw new Error(`${name} must be configured when NODE_ENV=production`);
  return localDemoValue;
 };
 const adminPassword=requiredPassword('BOOTSTRAP_ADMIN_PASSWORD','ChangeMe_Admin_123!');
 const patientPassword=requiredPassword('BOOTSTRAP_PATIENT_PASSWORD','ChangeMe_Patient_123!');
 const doctorPassword=requiredPassword('BOOTSTRAP_DOCTOR_PASSWORD','ChangeMe_Doctor_123!');
 const accounts=[
  ['CareBridge Admin',adminEmail,adminPassword,'ADMIN',''],
  ['Aarav Mehta','aarav.patient@carebridge.local',patientPassword,'PATIENT','9876543210'],
  ['Dr. Sarah Johnson','sarah.johnson@carebridge.local',doctorPassword,'DOCTOR','9876500001'],
  ['Dr. Michael Chen','michael.chen@carebridge.local',process.env.BOOTSTRAP_DOCTOR_PASSWORD||'ChangeMe_Doctor_123!','DOCTOR','9876500002'],
  ['Dr. Priya Sharma','priya.sharma@carebridge.local',process.env.BOOTSTRAP_DOCTOR_PASSWORD||'ChangeMe_Doctor_123!','DOCTOR','9876500003'],
  ['Dr. Arjun Mehta','arjun.mehta@carebridge.local',process.env.BOOTSTRAP_DOCTOR_PASSWORD||'ChangeMe_Doctor_123!','DOCTOR','9876500004'],
  ['Dr. Ananya Rao','ananya.rao@carebridge.local',process.env.BOOTSTRAP_DOCTOR_PASSWORD||'ChangeMe_Doctor_123!','DOCTOR','9876500005'],
  ['Dr. Neha Kapoor','neha.kapoor@carebridge.local',process.env.BOOTSTRAP_DOCTOR_PASSWORD||'ChangeMe_Doctor_123!','DOCTOR','9876500006']
 ];
 for(const [name,email,password,role,phone] of accounts){await pool.execute('INSERT INTO users(name,email,password_hash,role,phone) VALUES(?,?,?,?,?) ON DUPLICATE KEY UPDATE name=VALUES(name),password_hash=VALUES(password_hash),role=VALUES(role),phone=VALUES(phone)',[name,email,await hash(password),role,phone]);}
 await pool.execute("INSERT INTO clinics(name,address,city,phone,email) VALUES('CareBridge Medical Centre','14 Lakeview Avenue, Andheri East','Mumbai','02240001234','hello@carebridge.local') ON DUPLICATE KEY UPDATE address=VALUES(address),city=VALUES(city)");
 const [[clinic]]=await pool.query("SELECT id FROM clinics WHERE name='CareBridge Medical Centre' LIMIT 1");
 const docs=[
 ['Dr. Sarah Johnson','Cardiology','sarah.johnson@carebridge.local',12,4.9,184,850,750,'English,Hindi,Marathi','Heart health, preventive cardiology and hypertension care.','MBBS, MD Cardiology'],
 ['Dr. Michael Chen','Dermatology','michael.chen@carebridge.local',9,4.8,126,700,650,'English,Hindi','Clinical dermatology, acne, eczema and skin health.','MBBS, MD Dermatology'],
 ['Dr. Priya Sharma','General Medicine','priya.sharma@carebridge.local',11,4.9,241,600,550,'English,Hindi,Marathi','Primary care, preventive medicine and chronic condition management.','MBBS, MD Medicine'],
 ['Dr. Arjun Mehta','Orthopedics','arjun.mehta@carebridge.local',14,4.8,98,900,800,'English,Hindi','Sports injuries, joint pain and evidence-based rehabilitation.','MBBS, MS Orthopedics'],
 ['Dr. Ananya Rao','Pediatrics','ananya.rao@carebridge.local',8,4.9,157,650,600,'English,Hindi,Marathi','Child wellness, vaccinations and common pediatric conditions.','MBBS, MD Pediatrics'],
 ['Dr. Neha Kapoor','Mental Health','neha.kapoor@carebridge.local',10,4.9,203,800,700,'English,Hindi','Support for anxiety, stress, sleep and emotional wellbeing.','MBBS, MD Psychiatry']
 ];
 for(const [name,specialty,email,exp,rating,reviews,fee,online,languages,bio,qualification] of docs){const [[u]]=await pool.query('SELECT id FROM users WHERE email=?',[email]);await pool.execute('INSERT INTO doctors(user_id,name,specialty,email,experience_years,rating,review_count,consultation_fee,online_fee,languages,bio,qualification,clinic_id) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE user_id=VALUES(user_id),name=VALUES(name),specialty=VALUES(specialty),experience_years=VALUES(experience_years),rating=VALUES(rating),review_count=VALUES(review_count),consultation_fee=VALUES(consultation_fee),online_fee=VALUES(online_fee),languages=VALUES(languages),bio=VALUES(bio),qualification=VALUES(qualification),clinic_id=VALUES(clinic_id)',[u.id,name,specialty,email,exp,rating,reviews,fee,online,languages,bio,qualification,clinic.id]);}
 const photoByEmail={
  'sarah.johnson@carebridge.local':'Dr. Sarah Johnson.webp',
  'michael.chen@carebridge.local':'Dr. Michael Chen.webp',
  'priya.sharma@carebridge.local':'Dr. Priya Sharma.jpg',
  'arjun.mehta@carebridge.local':'Dr. Arjun Mehta.webp',
  'ananya.rao@carebridge.local':'Dr. Ananya Rao.webp',
  'neha.kapoor@carebridge.local':'Dr. Neha Kapoor.jpg'
 };
 for(const [email,file] of Object.entries(photoByEmail)){
  const absolute=new URL(`../uploads/doctors/${encodeURIComponent(file).replaceAll('%20','%20')}`,import.meta.url);
  if(fs.existsSync(absolute)) await pool.execute('UPDATE doctors SET photo_url=? WHERE email=?',[`/uploads/doctors/${encodeURIComponent(file).replaceAll('%20','%20')}`,email]);
 }
 const doctors=await pool.query('SELECT id FROM doctors ORDER BY id');
 const slotRows=[];for(const d of doctors[0])for(const date of days)for(const time of ['09:00','09:30','10:00','10:30','11:00','11:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00'])slotRows.push([d.id,date,time,'BOTH']);
 if(slotRows.length)await pool.query('INSERT IGNORE INTO doctor_slots(doctor_id,slot_date,slot_time,mode) VALUES ?',[slotRows]);
 const [[patient]]=await pool.query("SELECT id FROM users WHERE email='aarav.patient@carebridge.local'");
 const [[existing]]=await pool.query('SELECT id FROM appointments WHERE patient_id=? LIMIT 1',[patient.id]);
 if(!existing){const [[doc]]=await pool.query('SELECT id,clinic_id,consultation_fee FROM doctors ORDER BY id LIMIT 1');const date=days[1];const [ap]=await pool.execute("INSERT INTO appointments(patient_id,doctor_id,clinic_id,appointment_date,appointment_time,reason,mode,status,payment_status) VALUES(?,?,?,?,?,'Annual heart health check','CLINIC','CONFIRMED','PAY_AT_CLINIC')",[patient.id,doc.id,clinic.id,date,'10:00']);await pool.execute("INSERT INTO payments(appointment_id,amount,method,status,reference) VALUES(?,?,'PAY_AT_CLINIC','PENDING',?)",[ap.insertId,doc.consultation_fee,`CB-DEMO-${Date.now()}`]);}
 await pool.execute("INSERT INTO notifications(user_id,title,message) SELECT id,'Welcome to CareBridge','Your patient portal is ready. Explore doctors and book your next visit.' FROM users WHERE email='aarav.patient@carebridge.local' AND NOT EXISTS(SELECT 1 FROM notifications n WHERE n.user_id=users.id AND n.title='Welcome to CareBridge')");
 console.log('Demo data created. Update all bootstrap passwords before real use.');
}
main().catch(e=>{console.error(e);process.exitCode=1}).finally(()=>pool.end());
