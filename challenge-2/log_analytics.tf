resource "azurerm_log_analytics_workspace" "log" {
  count = var.enable_log_analytics ? 1 : 0

  name                = "log-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}
