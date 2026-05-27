variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "project_name"        { type = string }
variable "environment"         { type = string }
variable "db_subnet_id"        { type = string }
variable "private_dns_zone_id" { type = string }
variable "key_vault_id"        { type = string }
variable "db_config" {
  type = object({
    sku_name       = string
    storage_mb     = number
    pg_version     = string
    backup_days    = number
    geo_redundant  = bool
    databases      = list(string)
  })
}
variable "tags" { type = map(string) }
