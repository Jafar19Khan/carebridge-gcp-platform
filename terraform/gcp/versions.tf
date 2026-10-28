terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
  # For team use, keep state in a GCS bucket (free 5 GB):
  # backend "gcs" { bucket = "<your-state-bucket>", prefix = "carebridge" }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
