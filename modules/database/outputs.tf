output "server_id"   { value = azurerm_postgresql_flexible_server.main.id }
output "server_fqdn" { value = azurerm_postgresql_flexible_server.main.fqdn; sensitive = true }
output "server_name" { value = azurerm_postgresql_flexible_server.main.name }
