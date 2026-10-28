CREATE TABLE IF NOT EXISTS users (
 id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(120) NOT NULL,
 email VARCHAR(180) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 role ENUM('ADMIN','DOCTOR','PATIENT') NOT NULL DEFAULT 'PATIENT',
 phone VARCHAR(30) DEFAULT '',
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS clinics (
 id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(160) NOT NULL,
 address TEXT NOT NULL,
 city VARCHAR(80) NOT NULL,
 phone VARCHAR(30) DEFAULT '',
 email VARCHAR(180) DEFAULT '',
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uq_clinics_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS doctors (
 id INT AUTO_INCREMENT PRIMARY KEY,
 user_id INT UNIQUE,
 name VARCHAR(120) NOT NULL,
 specialty VARCHAR(120) NOT NULL,
 email VARCHAR(180) NOT NULL UNIQUE,
 phone VARCHAR(30) DEFAULT '',
 bio TEXT,
 photo_url VARCHAR(255) DEFAULT NULL,
 qualification VARCHAR(180) DEFAULT '',
 experience_years INT NOT NULL DEFAULT 1,
 rating DECIMAL(2,1) NOT NULL DEFAULT 4.8,
 review_count INT NOT NULL DEFAULT 0,
 consultation_fee INT NOT NULL DEFAULT 500,
 online_fee INT NOT NULL DEFAULT 500,
 languages VARCHAR(255) DEFAULT 'English,Hindi',
 clinic_id INT,
 available BOOLEAN NOT NULL DEFAULT TRUE,
 verified BOOLEAN NOT NULL DEFAULT TRUE,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_doctors_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT fk_doctors_clinic FOREIGN KEY (clinic_id) REFERENCES clinics(id) ON DELETE SET NULL,
 INDEX idx_doctors_specialty (specialty), INDEX idx_doctors_available (available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS doctor_slots (
 id INT AUTO_INCREMENT PRIMARY KEY,
 doctor_id INT NOT NULL,
 slot_date DATE NOT NULL,
 slot_time TIME NOT NULL,
 mode ENUM('CLINIC','ONLINE','BOTH') NOT NULL DEFAULT 'BOTH',
 UNIQUE KEY uq_doctor_slot (doctor_id,slot_date,slot_time),
 CONSTRAINT fk_slots_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS appointments (
 id INT AUTO_INCREMENT PRIMARY KEY,
 patient_id INT NOT NULL,
 doctor_id INT NOT NULL,
 clinic_id INT,
 appointment_date DATE NOT NULL,
 appointment_time TIME NOT NULL,
 reason TEXT,
 mode ENUM('CLINIC','ONLINE') NOT NULL DEFAULT 'CLINIC',
 status ENUM('BOOKED','CONFIRMED','COMPLETED','CANCELLED') NOT NULL DEFAULT 'BOOKED',
 payment_status ENUM('PENDING','PAID','FAILED','REFUNDED','PAY_AT_CLINIC') NOT NULL DEFAULT 'PENDING',
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_appointments_patient (patient_id,appointment_date), INDEX idx_appointments_doctor (doctor_id,appointment_date),
 CONSTRAINT fk_appointments_patient FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE RESTRICT,
 CONSTRAINT fk_appointments_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE RESTRICT,
 CONSTRAINT fk_appointments_clinic FOREIGN KEY (clinic_id) REFERENCES clinics(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS payments (
 id INT AUTO_INCREMENT PRIMARY KEY,
 appointment_id INT NOT NULL UNIQUE,
 amount INT NOT NULL,
 method ENUM('ONLINE','PAY_AT_CLINIC') NOT NULL,
 status ENUM('PENDING','PAID','FAILED','REFUNDED') NOT NULL DEFAULT 'PENDING',
 reference VARCHAR(80),
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_payments_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS notifications (
 id INT AUTO_INCREMENT PRIMARY KEY,
 user_id INT NOT NULL,
 title VARCHAR(160) NOT NULL,
 message TEXT NOT NULL,
 read_at DATETIME,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
 INDEX idx_notifications_user (user_id,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS reviews (
 id INT AUTO_INCREMENT PRIMARY KEY,
 patient_id INT NOT NULL,
 doctor_id INT NOT NULL,
 rating INT NOT NULL,
 comment TEXT,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uq_review_patient_doctor (patient_id,doctor_id),
 CONSTRAINT fk_reviews_patient FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE,
 CONSTRAINT fk_reviews_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS password_resets (
 id INT AUTO_INCREMENT PRIMARY KEY,
 user_id INT NOT NULL,
 token_hash CHAR(64) NOT NULL,
 expires_at DATETIME NOT NULL,
 used_at DATETIME DEFAULT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
 INDEX idx_password_resets_user (user_id,expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
