application_id = "ci36432"

project     = "demo"
environment = "prod"
location    = "westeurope"

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

enable_vm      = true
enable_storage = true

ssh_source_prefix        = "10.0.0.0/8"
vm_size                  = "Standard_B2s"
vm_admin_username        = "azureuser"
vm_os_disk_type          = "Premium_LRS"
create_public_ip         = false
storage_replication_type = "GRS"
