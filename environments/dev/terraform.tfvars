# environments/dev/terraform.tfvars
# Development environment — smaller, cost-optimized

project_name = "myapp"
environment  = "dev"
location     = "eastus2"

kubernetes_version = "1.29"
log_retention_days = 30

vnet_address_space = ["10.1.0.0/16"]

subnets = {
  aks = {
    address_prefix    = "10.1.0.0/22"
    service_endpoints = ["Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
  }
  db = {
    address_prefix = "10.1.4.0/24"
  }
  appgw = {
    address_prefix = "10.1.5.0/24"
  }
  privatelink = {
    address_prefix = "10.1.6.0/24"
  }
}

node_pools = {
  system = {
    vm_size             = "Standard_B2ms"
    min_count           = 1
    max_count           = 3
    enable_auto_scaling = true
    mode                = "System"
    os_disk_size_gb     = 64
    max_pods            = 60
    node_labels = {
      "nodepool-type" = "system"
    }
  }
}

db_config = {
  sku_name      = "B_Standard_B1ms"
  storage_mb    = 32768
  pg_version    = "15"
  backup_days   = 7
  geo_redundant = false
  databases     = ["appdb"]
}
