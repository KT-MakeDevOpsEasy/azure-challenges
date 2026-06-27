data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  count = var.enable_keyvault ? 1 : 0

  name                       = "kv-${local.name_suffix}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = var.kv_soft_delete_days
  purge_protection_enabled   = var.kv_purge_protection
  tags                       = local.common_tags
}
