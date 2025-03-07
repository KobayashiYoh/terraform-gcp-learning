terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = try(file("gcp-terraform-sa-key.json"), null)
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
  project               = var.project_id
  billing_project       = var.project_id
  region                = var.region
  user_project_override = true
}

provider "google-beta" {
  alias                 = "no_user_project_override"
  project               = var.project_id
  billing_project       = var.project_id
  region                = var.region
  user_project_override = false
}
