resource "google_secret_manager_secret" "dataform_private_ssh_key" {
  secret_id = "dataform-prvt-ssh-${var.usecase}"
  replication {
    auto {
    }
  }
}

resource "google_dataform_repository" "dataform_respository" {
  provider        = google-beta
  project         = var.project_id
  name            = var.dataform_repository_name
  region          = var.region
  service_account = var.use_default_dataform_sa ? local.dataform_default_sa_email : google_service_account.dataform_sa[0].email

  git_remote_settings {
    url            = var.dataform_git_url
    default_branch = var.dataform_default_branch
    ssh_authentication_config {
      user_private_key_secret_version = "${google_secret_manager_secret.dataform_private_ssh_key.id}/versions/latest"
      # GitHub's SSH key fingerprints : https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
      host_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
    }
  }
}

resource "google_workflows_workflow" "dataform_executor_workflow" {
  name            = "dataform-executor-${var.usecase}"
  region          = var.region
  service_account = google_service_account.dataform_executor_sa.id
  source_contents = templatefile(
    "${path.module}/dataform-executor-workflow.yaml",
    {
      dataform_region          = var.region,
      dataform_repository_name = var.dataform_repository_name,
      dataform_default_branch  = var.dataform_default_branch,
      dataform_api_version     = var.dataform_api_version
      dataform_service_account = var.use_default_dataform_sa ? local.dataform_default_sa_email : google_service_account.dataform_sa[0].email
    }
  )
}

resource "google_cloud_scheduler_job" "dataform_executor_scheduler_cron" {
  count = length(var.scheduler_cron) > 0 ? 1 : 0

  name        = "dataform-executor-${var.usecase}"
  description = "Call the workflow that executes Dataform."
  schedule    = var.scheduler_cron
  time_zone   = var.scheduler_time_zone
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.dataform_executor_workflow.name}/executions"
    body        = base64encode("{\"argument\":'{\"env\":\"${var.env}\"}',\"callLogLevel\":\"CALL_LOG_LEVEL_UNSPECIFIED\"}")
    headers     = { "Content-Type" = "application/json" }
    oauth_token {
      service_account_email = google_service_account.dataform_executor_sa.email
    }
  }
}
