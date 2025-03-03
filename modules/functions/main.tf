variable "project_id" {}
variable "region" {}
variable "billing_account" {}
variable "storage_location" {}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials           = try(file("gcp-terraform-sa-key.json"), null)
  project               = var.project_id
  billing_project       = var.project_id
  region                = var.region
  user_project_override = true
}

resource "google_storage_bucket" "function_bucket" {
  name     = "function-bucket-${var.project_id}"
  location = var.storage_location
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "function-source.zip"
  source = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
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
      DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/XXXX/YYYY"
    }
  }

  event_trigger {
    trigger_region = "us-central1"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.billing_alert.id
  }
}

resource "google_pubsub_topic" "billing_alert" {
  name = "billing-alert-topic"
}

output "function_url" {
  value = google_cloudfunctions2_function.billing_alert.service_config[0].uri
}
