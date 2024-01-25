output "dataform_executor_sa_name" {
  value = google_service_account.dataform_executor_sa.name
}

output "dataform_executor_workflow_name" {
  value = google_workflows_workflow.dataform_executor_workflow.name
}
