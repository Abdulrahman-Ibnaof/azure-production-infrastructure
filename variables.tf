variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Project name used in all resource naming"
  type        = string
  default     = "myapp"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric and hyphens, 3-20 chars."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vnet_address_space" {
  description = "CIDR for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Subnet configuration map"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
  }))
  default = {
    aks = {
      address_prefix    = "10.0.0.0/22"
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
    }
    db = {
      address_prefix    = "10.0.4.0/24"
      service_endpoints = ["Microsoft.Storage"]
    }
    appgw = {
      address_prefix = "10.0.5.0/24"
    }
    privatelink = {
      address_prefix = "10.0.6.0/24"
    }
  }
}

variable "node_pools" {
  description = "AKS node pool configurations"
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
  default = {
    system = {
      vm_size             = "Standard_D2ds_v5"
      min_count           = 2
      max_count           = 4
      enable_auto_scaling = true
      mode                = "System"
      node_labels = {
        "nodepool-type" = "system"
      }
    }
    workload = {
      vm_size             = "Standard_D4ds_v5"
      min_count           = 2
      max_count           = 10
      enable_auto_scaling = true
      mode                = "User"
      node_labels = {
        "nodepool-type" = "workload"
        "workload-type" = "general"
      }
    }
  }
}

variable "db_config" {
  description = "PostgreSQL Flexible Server configuration"
  type = object({
    sku_name       = string
    storage_mb     = number
    pg_version     = string
    backup_days    = number
    geo_redundant  = bool
    databases      = list(string)
  })
  default = {
    sku_name      = "GP_Standard_D2ds_v4"
    storage_mb    = 65536
    pg_version    = "15"
    backup_days   = 35
    geo_redundant = true
    databases     = ["appdb"]
  }
}

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 90

  validation {
    condition     = contains([30, 60, 90, 120, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must be one of: 30, 60, 90, 120, 180, 365."
  }
}
