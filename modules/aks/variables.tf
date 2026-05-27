variable "resource_group_name"     { type = string }
variable "location"                { type = string }
variable "project_name"            { type = string }
variable "environment"             { type = string }
variable "kubernetes_version"      { type = string }
variable "aks_subnet_id"           { type = string }
variable "key_vault_id"            { type = string }
variable "acr_id"                  { type = string }
variable "log_analytics_workspace" { type = string }
variable "node_pools" {
  type = map(object({
    vm_size             = string
    node_count          = optional(number)
    min_count           = optional(number)
    max_count           = optional(number)
    enable_auto_scaling = optional(bool, true)
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    os_disk_size_gb     = optional(number, 128)
    max_pods            = optional(number, 60)
    mode                = optional(string, "User")
  }))
}
variable "tags" { type = map(string) }
