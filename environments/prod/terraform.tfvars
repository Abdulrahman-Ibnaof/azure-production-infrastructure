# environments/prod/terraform.tfvars
# Production environment — Azure East US 2

project_name = "myapp"
environment  = "prod"
location     = "eastus2"

kubernetes_version = "1.29"
log_retention_days = 90

vnet_address_space = ["10.0.0.0/16"]

subnets = {
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

node_pools = {
  system = {
    vm_size             = "Standard_D2ds_v5"
    min_count           = 3
    max_count           = 5
    enable_auto_scaling = true
    mode                = "System"
    os_disk_size_gb     = 128
    max_pods            = 60
    node_labels = {
      "nodepool-type" = "system"
    }
  }
  workload = {
    vm_size             = "Standard_D8ds_v5"
    min_count           = 3
    max_count           = 20
    enable_auto_scaling = true
    mode                = "User"
    os_disk_size_gb     = 256
    max_pods            = 60
    node_labels = {
      "nodepool-type" = "workload"
      "workload-type" = "general"
    }
  }
  gpu = {
    vm_size             = "Standard_NC6s_v3"
    min_count           = 0
    max_count           = 4
    enable_auto_scaling = true
    mode                = "User"
    os_disk_size_gb     = 256
    max_pods            = 30
    node_labels = {
      "nodepool-type" = "gpu"
      "hardware-type" = "nvidia-gpu"
    }
    node_taints = ["nvidia.com/gpu=present:NoSchedule"]
  }
}

db_config = {
  sku_name      = "GP_Standard_D4ds_v4"
  storage_mb    = 131072
  pg_version    = "15"
  backup_days   = 35
  geo_redundant = true
  databases     = ["appdb", "analyticsdb"]
}
