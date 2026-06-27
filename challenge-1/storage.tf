resource "azurerm_storage_account" "storage" {
  count = var.enable_storage ? 1 : 0

  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  min_tls_version          = "TLS1_2"
  tags                     = local.common_tags

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "data" {
  count = var.enable_storage ? 1 : 0

  name                  = "data"
  storage_account_name  = azurerm_storage_account.storage[0].name
  container_access_type = "private"
}
