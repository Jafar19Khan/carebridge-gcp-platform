# One service account per tier, each with only what it needs.
resource "google_service_account" "tier" {
  for_each     = toset(["web", "app", "db"])
  account_id   = "${var.name_prefix}-${each.key}"
  display_name = "CareBridge ${each.key} tier"
  depends_on   = [google_project_service.apis]
}

locals {
  secret_names = [
    "db-password", "db-root-password", "jwt-secret",
    "bootstrap-admin-password", "bootstrap-patient-password", "bootstrap-doctor-password",
  ]
  app_secrets = ["db-password", "jwt-secret", "bootstrap-admin-password", "bootstrap-patient-password", "bootstrap-doctor-password"]
  db_secrets  = ["db-password", "db-root-password"]
}

resource "random_password" "secret" {
  for_each = toset(local.secret_names)
  length   = each.key == "jwt-secret" ? 64 : 20
  special  = false
}

resource "google_secret_manager_secret" "secret" {
  for_each  = toset(local.secret_names)
  secret_id = "${var.name_prefix}-${each.key}"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "secret" {
  for_each    = toset(local.secret_names)
  secret      = google_secret_manager_secret.secret[each.key].id
  secret_data = random_password.secret[each.key].result
}

# Web tier: no secrets at all. App tier: app secrets only. DB tier: database secrets only.
resource "google_secret_manager_secret_iam_member" "app" {
  for_each  = toset(local.app_secrets)
  secret_id = google_secret_manager_secret.secret[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.tier["app"].email}"
}

resource "google_secret_manager_secret_iam_member" "db" {
  for_each  = toset(local.db_secrets)
  secret_id = google_secret_manager_secret.secret[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.tier["db"].email}"
}

# Daily database dumps go to a private bucket; the DB VM may create objects but not read or delete them.
resource "google_storage_bucket" "backups" {
  name                        = "${var.project_id}-${var.name_prefix}-backups"
  location                    = upper(var.region)
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
  lifecycle_rule {
    condition {
      age = 14
    }
    action {
      type = "Delete"
    }
  }
  depends_on = [google_project_service.apis]
}

resource "google_storage_bucket_iam_member" "db_backup_writer" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.tier["db"].email}"
}


# App tier can upload doctor-profile backups, but cannot list/read/delete backup objects.
resource "google_storage_bucket_iam_member" "app_upload_backup_writer" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.tier["app"].email}"
}
