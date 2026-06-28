application_id = "ci36432"

project     = "demo"
environment = "dev"
location    = "eastus"

vnet_address_space = ["10.0.0.0/8"]

subnets = {
  default = {
    address_prefixes = ["10.0.0.0/16"]
  }
  compute = {
    address_prefixes = ["10.1.0.0/16"]
  }
  storage = {
    address_prefixes  = ["10.2.0.0/16"]
    service_endpoints = ["Microsoft.Storage"]
  }
  privateendpoints = {
    address_prefixes = ["10.3.0.0/16"]
  }

}

enable_vm       = true
enable_keyvault = true

ssh_source_prefix = "*"
vm_size           = "Standard_D2ds_v7"
vm_admin_username = "azureuser"
vm_os_disk_type   = "Standard_LRS"
create_public_ip  = true

vm_image = {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}

extra_nsg_rules = {
  compute = [
    {
      name                       = "AllowOutboundHTTPS"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      name                       = "AllowOutboundHTTP"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      name                       = "DenyOutboundAll"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]
}

kv_soft_delete_days = 7
kv_purge_protection = false
kv_purge_on_destroy = true
