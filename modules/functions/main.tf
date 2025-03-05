variable "project_id" {}
variable "region" {}
variable "billing_account" {}
variable "storage_location" {}
variable "discord_webhook_url" {}

resource "google_storage_bucket" "function_bucket" {
  name                        = "function-bucket-${var.project_id}"
  location                    = var.storage_location
  uniform_bucket_level_access = true
}

resource "null_resource" "build" {
  provisioner "local-exec" {
    command     = "pwd && ls -a && npm install && npm run build"
    working_dir = "./modules/functions/functions-project"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

data "archive_file" "default" {
  type        = "zip"
  source_dir  = "./modules/functions/functions-project/dist"
  output_path = "dist/functions-project.zip"
  depends_on  = [null_resource.build]
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "functions-project.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.default.output_path
}

resource "google_cloudfunctions2_function" "billing_alert" {
  name        = "billing-alert3"
  description = "Billing Alert Function"
  location    = var.region

  build_config {
    runtime     = "nodejs20"
    entry_point = "helloWorldToDiscord"

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

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      google_storage_bucket_object.function_archive
    ]
  }
}

resource "google_pubsub_topic" "billing_alert" {
  name     = "billing-alert-topic"
}

resource "google_pubsub_subscription" "billing_subscription" {
  name     = "billing-alerts-subscription"
  topic    = google_pubsub_topic.billing_alert.name

  push_config {
    push_endpoint = google_cloudfunctions2_function.billing_alert.service_config[0].uri
  }
}
