terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = try(file("gcp-terraform-sa-key.json"), null)
  project     = var.project_id
  region      = var.region
}
