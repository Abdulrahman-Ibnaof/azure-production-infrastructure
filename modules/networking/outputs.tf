output "vnet_id"             { value = azurerm_virtual_network.main.id }
output "vnet_name"           { value = azurerm_virtual_network.main.name }
output "aks_subnet_id"       { value = azurerm_subnet.subnets["aks"].id }
output "db_subnet_id"        { value = azurerm_subnet.subnets["db"].id }
output "appgw_subnet_id"     { value = azurerm_subnet.subnets["appgw"].id }
output "private_dns_zone_id" { value = azurerm_private_dns_zone.postgres.id }
output "appgw_public_ip"     { value = azurerm_public_ip.appgw.ip_address }
