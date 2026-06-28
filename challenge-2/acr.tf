resource "azurerm_container_registry" "acr" {
  count = var.enable_acr ? 1 : 0

  name                          = local.acr_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = var.acr_sku
  admin_enabled                 = false
  public_network_access_enabled = var.acr_private_endpoint_enabled ? false : true
  tags                          = local.common_tags
}

resource "azurerm_private_endpoint" "acr" {
  count = var.enable_acr && var.acr_private_endpoint_enabled ? 1 : 0

  name                = "pe-acr-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = module.vnet.subnet_ids["snet-private-endpoints"]
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-acr-${local.name_suffix}"
    private_connection_resource_id = azurerm_container_registry.acr[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }
}

resource "azurerm_private_dns_zone" "acr" {
  count = var.enable_acr && var.acr_private_endpoint_enabled ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count = var.enable_acr && var.acr_private_endpoint_enabled ? 1 : 0

  name                  = "vnetlink-acr-${local.name_suffix}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = module.vnet.vnet_id
  tags                  = local.common_tags
}
