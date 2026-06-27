module "vnet" {
  source = "git::https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-vnet.git?ref=v1.0.0"

  name                = "vnet-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.vnet_address_space

  subnets = {
    snet-aks-nodes = {
      address_prefixes = [var.node_subnet_cidr]
    }
    snet-appgw = {
      address_prefixes = [var.appgw_subnet_cidr]
    }
  }

  tags = local.common_tags
}
