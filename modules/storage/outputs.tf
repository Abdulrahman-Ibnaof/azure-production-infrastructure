output "acr_id"           { value = azurerm_container_registry.main.id }
output "acr_login_server" { value = azurerm_container_registry.main.login_server }
output "acr_name"         { value = azurerm_container_registry.main.name }
output "storage_account_name" { value = azurerm_storage_account.main.name }
output "storage_account_id"   { value = azurerm_storage_account.main.id }
