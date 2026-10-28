resource "google_compute_address" "web" {
  name       = "${var.name_prefix}-web-ip"
  region     = var.region
  depends_on = [google_project_service.apis]
}

locals {
  image_base = "ghcr.io/${var.ghcr_owner}/carebridge"
  common_metadata = {
    enable-oslogin         = "TRUE" # IAM-based SSH, no static keys
    block-project-ssh-keys = "TRUE"
  }
}

# ---------------- Tier 3: data (private, no public IP) ----------------
resource "google_compute_instance" "db" {
  name                      = "${var.name_prefix}-db"
  machine_type              = var.db_machine_type
  zone                      = var.zone
  tags                      = ["db"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.tier["db"].id
  }
  service_account {
    email  = google_service_account.tier["db"].email
    scopes = ["cloud-platform"]
  }
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  metadata = local.common_metadata
  metadata_startup_script = templatefile("${path.module}/templates/db.sh.tftpl", {
    project_id = var.project_id
    prefix     = var.name_prefix
    bucket     = google_storage_bucket.backups.name
  })
  depends_on = [google_secret_manager_secret_version.secret, google_secret_manager_secret_iam_member.db, google_storage_bucket_iam_member.db_backup_writer, google_compute_router_nat.nat]
}

# ---------------- Tier 2: application (private, no public IP) ----------------
resource "google_compute_instance" "app" {
  name                      = "${var.name_prefix}-app"
  machine_type              = var.app_machine_type
  zone                      = var.zone
  tags                      = ["app"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.tier["app"].id
  }
  service_account {
    email  = google_service_account.tier["app"].email
    scopes = ["cloud-platform"]
  }
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  metadata = local.common_metadata
  metadata_startup_script = templatefile("${path.module}/templates/app.sh.tftpl", {
    project_id = var.project_id
    prefix     = var.name_prefix
    image      = "${local.image_base}-backend:${var.image_tag}"
    db_ip      = google_compute_instance.db.network_interface[0].network_ip
    web_ip     = google_compute_address.web.address
    bucket     = google_storage_bucket.backups.name
  })
  depends_on = [google_secret_manager_secret_version.secret, google_secret_manager_secret_iam_member.app, google_storage_bucket_iam_member.app_upload_backup_writer, google_compute_router_nat.nat]
}

# ---------------- Tier 1: web (only tier with a public IP) ----------------
resource "google_compute_instance" "web" {
  name                      = "${var.name_prefix}-web"
  machine_type              = var.web_machine_type
  zone                      = var.zone
  tags                      = ["web"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.tier["web"].id
    access_config {
      nat_ip = google_compute_address.web.address
    }
  }
  service_account {
    email  = google_service_account.tier["web"].email
    scopes = ["cloud-platform"]
  }
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  metadata = local.common_metadata
  metadata_startup_script = templatefile("${path.module}/templates/web.sh.tftpl", {
    image  = "${local.image_base}-frontend:${var.image_tag}"
    app_ip = google_compute_instance.app.network_interface[0].network_ip
  })
}
