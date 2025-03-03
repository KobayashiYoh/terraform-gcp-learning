variable "billing_account" {}
variable "project_id" {}
variable "region" {}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials           = try(file("../gcp-terraform-sa-key.json"), null)
  project               = var.project_id
  billing_project       = var.project_id
  region                = var.region
  user_project_override = true
}

resource "google_billing_budget" "budget" {
  provider        = google
  billing_account = var.billing_account
  display_name    = "Billing Budget"

  amount {
    specified_amount {
      currency_code = "JPY"
      units         = "1"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
}
