application_id = "ci36432"

project     = "aks"
environment = "dev"
location    = "eastus"

vnet_address_space = ["10.0.0.0/8"]
node_subnet_cidr   = "10.0.0.0/16"
appgw_subnet_cidr  = "10.1.0.0/16"
pe_subnet_cidr     = "10.2.0.0/16"

aks_sku_tier = "Free"

system_node_pool = {
  vm_size              = "Standard_D2ds_v7"
  min_count            = 1
  max_count            = 2
  auto_scaling_enabled = true
  os_disk_size_gb      = 30
  zones                = ["1"]
}

user_node_pools = {}

enable_acr           = true
enable_keyvault      = false
enable_log_analytics = true

acr_sku                     = "Basic"
acr_private_endpoint_enabled = false
log_retention_days  = 30
kv_soft_delete_days = 7
kv_purge_protection = false
kv_purge_on_destroy = true

enable_alerts = false
