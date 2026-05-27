terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "prod/infrastructure.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

# ── Resource Group ──────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# ── Networking ───────────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
  tags                = local.common_tags
}

# ── Security (Key Vault + Managed Identity) ──────────────────────────────────
module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  tenant_id           = var.tenant_id
  aks_subnet_id       = module.networking.aks_subnet_id
  tags                = local.common_tags

  depends_on = [module.networking]
}

# ── AKS Cluster ──────────────────────────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  resource_group_name     = azurerm_resource_group.main.name
  location                = var.location
  project_name            = var.project_name
  environment             = var.environment
  kubernetes_version      = var.kubernetes_version
  aks_subnet_id           = module.networking.aks_subnet_id
  key_vault_id            = module.security.key_vault_id
  acr_id                  = module.storage.acr_id
  log_analytics_workspace = module.monitoring.log_analytics_workspace_id
  node_pools              = var.node_pools
  tags                    = local.common_tags

  depends_on = [module.networking, module.security]
}

# ── Database (PostgreSQL Flexible) ───────────────────────────────────────────
module "database" {
  source = "./modules/database"

  resource_group_name  = azurerm_resource_group.main.name
  location             = var.location
  project_name         = var.project_name
  environment          = var.environment
  db_subnet_id         = module.networking.db_subnet_id
  private_dns_zone_id  = module.networking.private_dns_zone_id
  key_vault_id         = module.security.key_vault_id
  db_config            = var.db_config
  tags                 = local.common_tags

  depends_on = [module.networking, module.security]
}

# ── Storage (ACR + Storage Account) ─────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = local.common_tags
}

# ── Monitoring (Log Analytics + App Insights) ────────────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  retention_days      = var.log_retention_days
  tags                = local.common_tags
}
