module "aks" {
  source = "git::https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-aks.git?ref=v1.0.0"

  cluster_name        = "aks-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.aks_sku_tier

  node_subnet_id          = module.vnet.subnet_ids["snet-aks-nodes"]
  private_cluster_enabled = false
  authorized_ip_ranges    = var.authorized_ip_ranges

  system_node_pool = var.system_node_pool
  user_node_pools  = var.user_node_pools

  tenant_id                  = data.azurerm_client_config.current.tenant_id
  workload_identity_enabled  = true
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.log[0].id : null

  tags = local.common_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count = var.enable_acr ? 1 : 0

  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

resource "azurerm_role_assignment" "aks_keyvault" {
  count = var.enable_keyvault ? 1 : 0

  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.kubelet_identity_object_id
}
