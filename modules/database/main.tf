# modules/database/main.tf

resource "random_password" "pg_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "pg_password" {
  name         = "postgresql-admin-password"
  value        = random_password.pg_admin.result
  key_vault_id = var.key_vault_id

  content_type    = "password"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year

  lifecycle {
    ignore_changes = [expiration_date, value]
  }
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.project_name}-${var.environment}"
  location               = var.location
  resource_group_name    = var.resource_group_name
  version                = var.db_config.pg_version
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = var.private_dns_zone_id
  administrator_login    = "pgadmin"
  administrator_password = random_password.pg_admin.result
  sku_name               = var.db_config.sku_name
  storage_mb             = var.db_config.storage_mb
  zone                   = "1"

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  backup_retention_days        = var.db_config.backup_days
  geo_redundant_backup_enabled = var.db_config.geo_redundant

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [administrator_password, zone]
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "configs" {
  for_each = {
    "azure.extensions"             = "UUID-OSSP,PG_TRGM,PGCRYPTO"
    "log_checkpoints"              = "on"
    "log_connections"              = "on"
    "log_disconnections"           = "on"
    "log_duration"                 = "off"
    "log_lock_waits"               = "on"
    "log_min_duration_statement"   = "1000"
    "connection_throttle.enable"   = "on"
    "ssl_min_protocol_version"     = "TLSv1.2"
  }

  server_id = azurerm_postgresql_flexible_server.main.id
  name      = each.key
  value     = each.value
}

resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = toset(var.db_config.databases)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}
