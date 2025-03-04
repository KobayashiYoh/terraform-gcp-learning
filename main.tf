resource "google_project" "default" {
  name            = "Terraform GCP Learning Yo"
  provider        = google
  project_id      = var.project_id
  billing_account = var.billing_account
}

resource "google_project_service" "enable_services" {
  project = google_project.default.project_id
  service = each.key

  for_each = toset([
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
    "firebase.googleapis.com",
    "firebaserules.googleapis.com",
  ])
}

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  region     = var.region
}

module "billing" {
  source          = "./modules/billing"
  billing_account = var.billing_account
  project_id      = var.project_id
  region          = var.region
}

module "functions" {
  source           = "./modules/functions"
  project_id       = var.project_id
  region           = var.region
  billing_account  = var.billing_account
  storage_location = var.storage_location
}
