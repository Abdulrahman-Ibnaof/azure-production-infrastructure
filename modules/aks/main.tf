# modules/aks/main.tf

data "azurerm_client_config" "current" {}

# ── Managed Identity for AKS ─────────────────────────────────────────────────
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "id-aks-kubelet-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ── Role Assignments ──────────────────────────────────────────────────────────
resource "azurerm_role_assignment" "aks_network" {
  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks_kubelet.principal_id
}

resource "azurerm_role_assignment" "aks_kv" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# ── AKS Cluster ───────────────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                      = "aks-${var.project_name}-${var.environment}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "${var.project_name}-${var.environment}"
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = var.environment == "prod" ? "Standard" : "Free"
  node_resource_group       = "rg-aks-nodes-${var.project_name}-${var.environment}"
  private_cluster_enabled   = var.environment == "prod" ? true : false
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_pools["system"].vm_size
    vnet_subnet_id              = var.aks_subnet_id
    enable_auto_scaling         = true
    min_count                   = var.node_pools["system"].min_count
    max_count                   = var.node_pools["system"].max_count
    os_disk_size_gb             = var.node_pools["system"].os_disk_size_gb
    os_disk_type                = "Ephemeral"
    max_pods                    = var.node_pools["system"].max_pods
    only_critical_addons_enabled = true
    zones                       = ["1", "2", "3"]
    temporary_name_for_rotation = "systmp"

    upgrade_settings {
      max_surge = "33%"
    }

    node_labels = var.node_pools["system"].node_labels
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.aks_kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.aks_kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_kubelet.id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "10.96.0.0/16"
    dns_service_ip      = "10.96.0.10"
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace
    msi_auth_for_monitoring_enabled = true
  }

  azure_policy_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [1, 2]
    }
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "0s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      tags["CreatedAt"],
    ]
  }
}

# ── Additional Node Pools ─────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  for_each = { for k, v in var.node_pools : k => v if k != "system" }

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.aks_subnet_id
  enable_auto_scaling   = each.value.enable_auto_scaling
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = "Ephemeral"
  max_pods              = each.value.max_pods
  mode                  = each.value.mode
  zones                 = ["1", "2", "3"]

  node_labels = each.value.node_labels
  node_taints = each.value.node_taints

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}
