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
vm_size           = "Standard_B2s"
vm_admin_username = "azureuser"
vm_os_disk_type   = "Standard_LRS"
create_public_ip  = true

kv_soft_delete_days = 7
kv_purge_protection = false
kv_purge_on_destroy = true
