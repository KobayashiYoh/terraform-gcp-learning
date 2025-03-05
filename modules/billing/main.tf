variable "billing_account" {}
variable "project_id" {}
variable "region" {}

resource "google_billing_budget" "budget" {
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
