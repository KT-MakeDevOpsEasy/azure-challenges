module "vnet" {
  source = "git::https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-vnet.git?ref=v1.0.0"

  name                = "vnet-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.vnet_address_space
  subnets             = var.subnets
  nsg_rules           = local.nsg_rules
  tags                = local.common_tags
  blocks = "test"
}
