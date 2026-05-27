variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project_name"        { type = string }
variable "environment"         { type = string }
variable "retention_days"      { type = number; default = 90 }
variable "aks_cluster_id"      { type = string; default = null }
variable "tags"                { type = map(string) }
