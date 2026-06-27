output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.vnet.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.vnet.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = module.vnet.subnet_ids
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine"
  value       = var.enable_vm ? azurerm_network_interface.vm_nic[0].private_ip_address : null
}

output "vm_public_ip" {
  description = "Public IP address of the virtual machine (if created)"
  value       = var.enable_vm && var.create_public_ip ? azurerm_public_ip.vm_pip[0].ip_address : null
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = var.enable_keyvault ? azurerm_key_vault.kv[0].name : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_keyvault ? azurerm_key_vault.kv[0].vault_uri : null
}
