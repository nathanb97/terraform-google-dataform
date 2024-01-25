data "google_project" "project" {
}

resource "google_service_account" "dataform_sa" {
  count        = var.use_default_dataform_sa ? 0 : 1
  project      = var.project_id
  account_id   = "${replace(var.usecase, "_", "-")}-sa-dataform-${var.env}"
  display_name = "Service Account used by Dataform to execute BigQuery transformations."
}

resource "google_service_account_iam_member" "dataform_sa_token_creator" {
  # Link to documentation : https://cloud.google.com/dataform/docs/required-access#grant_token_creation_access_to_a_non-default_service_account
  count              = var.use_default_dataform_sa ? 0 : 1
  service_account_id = google_service_account.dataform_sa[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${local.dataform_default_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "dataform_secret_accessor" {
  count     = var.use_default_dataform_sa ? 0 : 1
  project   = var.project_id
  secret_id = google_secret_manager_secret.dataform_private_ssh_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.dataform_sa[0].email}"
}

resource "google_secret_manager_secret_iam_member" "dataform_default_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.dataform_private_ssh_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.dataform_default_sa_email}"
}

resource "google_project_iam_member" "dataform_bq_admin" {
  count   = var.is_deploy_sa_project_iam_admin == true ? 1 : 0
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${var.use_default_dataform_sa ? local.dataform_default_sa_email : google_service_account.dataform_sa[0].email}"
}

resource "google_service_account" "dataform_executor_sa" {
  project      = var.project_id
  account_id   = "dataform-executor-${replace(var.usecase, "_", "-")}"
  display_name = "Service Account used to execute Dataform from a workflow."
}

resource "google_project_iam_member" "dataform_executor_sa_iam" {
  project  = var.project_id
  for_each = var.is_deploy_sa_project_iam_admin == true ? toset(["roles/workflows.invoker", "roles/dataform.editor"]) : []
  role     = each.key
  member   = "serviceAccount:${google_service_account.dataform_executor_sa.email}"
}
