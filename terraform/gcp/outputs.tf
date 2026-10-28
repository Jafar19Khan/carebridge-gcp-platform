output "web_url" {
  description = "Open this in a browser (give the VMs 3-5 minutes after apply to install Docker and start)"
  value       = "http://${google_compute_address.web.address}"
}
output "private_ips" {
  value = {
    app = google_compute_instance.app.network_interface[0].network_ip
    db  = google_compute_instance.db.network_interface[0].network_ip
  }
}
output "ssh_via_iap" {
  description = "No SSH port is open to the internet; use IAP tunnels"
  value = {
    web = "gcloud compute ssh ${google_compute_instance.web.name} --zone ${var.zone} --tunnel-through-iap"
    app = "gcloud compute ssh ${google_compute_instance.app.name} --zone ${var.zone} --tunnel-through-iap"
    db  = "gcloud compute ssh ${google_compute_instance.db.name} --zone ${var.zone} --tunnel-through-iap"
  }
}
output "backup_bucket" {
  value = google_storage_bucket.backups.name
}
