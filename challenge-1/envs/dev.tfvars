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

kv_soft_delete_days = 7
kv_purge_protection = false
kv_purge_on_destroy = true
