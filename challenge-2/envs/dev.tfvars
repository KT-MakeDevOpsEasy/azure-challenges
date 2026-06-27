application_id = "ci36432"

project     = "demo"
environment = "dev"
location    = "eastus"

vnet_address_space = ["10.0.0.0/8"]
node_subnet_cidr   = "10.0.0.0/16"
appgw_subnet_cidr  = "10.1.0.0/16"

aks_sku_tier = "Free"

system_node_pool = {
  vm_size             = "Standard_B2s"
  min_count           = 1
  max_count           = 2
  auto_scaling_enabled = true
  os_disk_size_gb     = 30
  zones               = ["1"]
}

user_node_pools = {
  workload = {
    vm_size             = "Standard_B4ms"
    min_count           = 1
    max_count           = 2
    auto_scaling_enabled = true
    os_disk_size_gb     = 50
    zones               = ["1"]
    node_labels = {
      "workload-type" = "general"
    }
    node_taints = []
  }
}

enable_acr           = true
enable_keyvault      = false
enable_log_analytics = true

acr_sku             = "Basic"
log_retention_days  = 30
kv_soft_delete_days = 7
kv_purge_protection = false
kv_purge_on_destroy = true

enable_alerts = false
