variable "project_id" {}
variable "region" {}

resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}

resource "google_project_iam_member" "terraform_sa_roles" {
  # TODO: 現在はコンソールとTerraformの両方でSAのroleを管理しているため、Terraformで一元管理したい。
  for_each = toset([
    "roles/editor",
    "roles/storage.admin",
    "roles/cloudfunctions.admin",
    "roles/iam.serviceAccountUser",
    "roles/logging.admin",
    "roles/eventarc.admin",
    "roles/cloudbuild.builds.editor",
    "roles/run.admin",
    "roles/artifactregistry.reader",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

resource "google_service_account_key" "terraform_sa_key" {
  service_account_id = google_service_account.terraform_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "local_file" "sa_key_file_txt" {
  content  = google_service_account_key.terraform_sa_key.private_key
  filename = "gcp-terraform-sa-key.txt"
}

resource "local_file" "sa_key_file_json" {
  content  = base64decode(google_service_account_key.terraform_sa_key.private_key)
  filename = "gcp-terraform-sa-key.json"
}
