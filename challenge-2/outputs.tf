output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.vnet.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = module.vnet.subnet_ids
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity federation"
  value       = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  description = "Login server URL for the container registry"
  value       = var.enable_acr ? azurerm_container_registry.acr[0].login_server : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_keyvault ? azurerm_key_vault.kv[0].vault_uri : null
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.log[0].id : null
}

output "get_credentials_command" {
  description = "Azure CLI command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${module.aks.cluster_name}"
}
