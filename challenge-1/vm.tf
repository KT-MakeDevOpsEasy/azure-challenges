resource "azurerm_public_ip" "vm_pip" {
  count = var.enable_vm && var.create_public_ip ? 1 : 0

  name                = "pip-vm-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "vm_nic" {
  count = var.enable_vm ? 1 : 0

  name                = "nic-vm-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnet_ids["compute"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.vm_pip[0].id : null
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count = var.enable_vm ? 1 : 0

  name                            = "vm-${local.name_suffix}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  tags                            = local.common_tags

  network_interface_ids = [azurerm_network_interface.vm_nic[0].id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_ssh_public_key
  }

  os_disk {
    name                 = "osdisk-vm-${local.name_suffix}"
    caching              = "ReadWrite"
    storage_account_type = var.vm_os_disk_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
