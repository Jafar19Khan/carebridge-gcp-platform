locals {
  apis = ["compute.googleapis.com", "secretmanager.googleapis.com", "iam.googleapis.com", "iap.googleapis.com", "storage.googleapis.com"]
  tiers = {
    web = "10.10.1.0/24"
    app = "10.10.2.0/24"
    db  = "10.10.3.0/24"
  }
}

resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  service            = each.key
  disable_on_destroy = false
}

resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

# One subnet per tier
resource "google_compute_subnetwork" "tier" {
  for_each                 = local.tiers
  name                     = "${var.name_prefix}-${each.key}"
  ip_cidr_range            = each.value
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# App and DB VMs have no public IP; Cloud NAT gives them outbound-only internet (apt, image pulls).
resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  dynamic "subnetwork" {
    for_each = toset(["app", "db"])
    content {
      name                    = google_compute_subnetwork.tier[subnetwork.key].id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ---- Firewall: the only allowed paths are Internet -> web -> app -> db ----
# (custom VPC: everything not listed here is denied for ingress)
resource "google_compute_firewall" "internet_to_web" {
  name          = "${var.name_prefix}-internet-to-web"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = var.allowed_web_cidrs
  target_tags   = ["web"]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "web_to_app" {
  name        = "${var.name_prefix}-web-to-app"
  network     = google_compute_network.vpc.name
  direction   = "INGRESS"
  source_tags = ["web"]
  target_tags = ["app"]
  allow {
    protocol = "tcp"
    ports    = ["4000"]
  }
}

resource "google_compute_firewall" "app_to_db" {
  name        = "${var.name_prefix}-app-to-db"
  network     = google_compute_network.vpc.name
  direction   = "INGRESS"
  source_tags = ["app"]
  target_tags = ["db"]
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
}

# Admin access only through Identity-Aware Proxy (no SSH port open to the internet)
resource "google_compute_firewall" "iap_ssh" {
  name          = "${var.name_prefix}-iap-ssh"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
