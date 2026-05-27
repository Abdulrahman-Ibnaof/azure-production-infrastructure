output "cluster_name"          { value = azurerm_kubernetes_cluster.main.name }
output "cluster_id"            { value = azurerm_kubernetes_cluster.main.id }
output "cluster_fqdn"          { value = azurerm_kubernetes_cluster.main.fqdn }
output "oidc_issuer_url"       { value = azurerm_kubernetes_cluster.main.oidc_issuer_url }
output "kubelet_identity"      { value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id }
output "aks_identity_id"       { value = azurerm_user_assigned_identity.aks.id }
output "aks_identity_client_id"{ value = azurerm_user_assigned_identity.aks.client_id }
