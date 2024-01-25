variable "project_id" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "dataform_git_url" { type = string }
variable "dataform_default_branch" { type = string }
variable "dataform_repository_name" { type = string }
variable "scheduler_cron" {
  type        = string
  default     = ""
  description = "If empty, Dataform is not scheduled automatically and you must trigger the dataform workflow by yourself."
}
variable "scheduler_time_zone" {
  type    = string
  default = "Europe/Paris"
}
variable "usecase" {
  type        = string
  description = "The short name of your usecase."
}
variable "dataform_api_version" {
  type    = string
  default = "v1beta1"
}
variable "is_deploy_sa_project_iam_admin" {
  type        = bool
  default     = true
  description = "If false, you will have to give the project level roles manualy."
}
variable "use_default_dataform_sa" {
  type        = bool
  default     = false
  description = "Only for compatibility with old projects, leave by default for new projects."
}
