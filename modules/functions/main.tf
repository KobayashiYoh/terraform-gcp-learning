variable "project_id" {}
variable "region" {}
variable "billing_account" {}
variable "storage_location" {}
variable "discord_webhook_url" {}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  user_project_override = true
  credentials           = file("gcp-terraform-sa-key.json")
  project               = var.project_id
  billing_project       = var.project_id
  region                = var.region

}

provider "google" {
  alias                 = "no_user_project_override"
  user_project_override = false
  credentials           = file("gcp-terraform-sa-key.json")
  project               = var.project_id
  billing_project       = var.project_id
  region                = var.region
}

resource "google_storage_bucket" "function_bucket" {
  provider                    = google.no_user_project_override
  name                        = "function-bucket-${var.project_id}"
  location                    = var.storage_location
  uniform_bucket_level_access = true
}

data "archive_file" "default" {
  type        = "zip"
  output_path = "dist/functions.zip"
  source_dir  = "./modules/functions/functions/src"
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "functions.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.default.output_path
}

resource "google_pubsub_topic" "billing_alert" {
  provider = google.no_user_project_override
  name     = "billing-alert-topic"
}

resource "google_pubsub_subscription" "billing_subscription" {
  provider = google.no_user_project_override
  name     = "billing-alerts-subscription"
  topic    = google_pubsub_topic.billing_alert.name
}

resource "google_cloudfunctions2_function" "billing_alert" {
  name        = "billing-alert"
  description = "Billing Alert Function"
  location    = var.region

  build_config {
    runtime     = "nodejs20"
    entry_point = "sendAlert"

    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_archive.name
      }
    }
  }

  service_config {
    available_memory = "256M"
    timeout_seconds  = 60
    environment_variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.billing_alert.id
  }
}

output "function_url" {
  value = google_cloudfunctions2_function.billing_alert.service_config[0].uri
}
