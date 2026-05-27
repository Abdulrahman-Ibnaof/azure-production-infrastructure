# modules/storage/main.tf

resource "random_string" "sa_suffix" {
  length  = 8
  special = false
  upper   = false
}

# ── Azure Container Registry ──────────────────────────────────────────────────
resource "azurerm_container_registry" "main" {
  name                = "acr${var.project_name}${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = false

  georeplications {
    location                  = "westus2"
    zone_redundancy_enabled   = true
    regional_endpoint_enabled = true
  }

  network_rule_set {
    default_action = "Deny"
  }

  retention_policy {
    days    = 30
    enabled = true
  }

  trust_policy {
    enabled = true
  }

  zone_redundancy_enabled = true

  tags = var.tags
}

# ── Storage Account (Blobs, backups, etc.) ───────────────────────────────────
resource "azurerm_storage_account" "main" {
  name                            = "st${var.project_name}${var.environment}${random_string.sa_suffix.result}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.environment == "prod" ? "RAGZRS" : "LRS"
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days = 35
    }

    container_delete_retention_policy {
      days = 35
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

resource "azurerm_storage_container" "backups" {
  name                  = "database-backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
