variable "project_id" {
  description = "GCP project ID (not the name)"
  type        = string
}
variable "ghcr_owner" {
  description = "GitHub username that owns the published images, LOWERCASE (e.g. jafar19khan). Packages must be public."
  type        = string
}
variable "image_tag" {
  description = "Image tag to deploy (release tag such as v1.0.0). Change it and re-apply to roll forward/back."
  type        = string
  default     = "latest"
}
variable "region" {
  description = "Always-Free e2-micro and 5 GB storage regions: us-west1, us-central1, us-east1"
  type        = string
  default     = "us-central1"
}
variable "zone" {
  type    = string
  default = "us-central1-a"
}
variable "name_prefix" {
  type    = string
  default = "carebridge"
}
variable "allowed_web_cidrs" {
  description = "Who may reach the website. Narrow this to your own IP (x.x.x.x/32) for a private demo."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
variable "web_machine_type" {
  description = "e2-micro is covered by the Always Free tier (one per account)"
  type        = string
  default     = "e2-micro"
}
variable "app_machine_type" {
  type    = string
  default = "e2-micro"
}
variable "db_machine_type" {
  description = "MySQL 8 needs more than 1 GB RAM to be comfortable"
  type        = string
  default     = "e2-small"
}
variable "disk_size_gb" {
  description = "Per VM. 3 x 10 GB = 30 GB, the Always Free standard persistent disk allowance."
  type        = number
  default     = 10
}
