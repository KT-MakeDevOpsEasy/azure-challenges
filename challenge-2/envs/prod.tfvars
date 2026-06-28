application_id = "ci36432"

project     = "aks"
environment = "prod"
location    = "westeurope"

vnet_address_space = ["10.0.0.0/8"]
node_subnet_cidr   = "10.0.0.0/16"
appgw_subnet_cidr  = "10.1.0.0/16"
pe_subnet_cidr     = "10.2.0.0/16"
authorized_ip_ranges = ["10.0.0.0/8"]

aks_sku_tier = "Standard"

system_node_pool = {
  vm_size             = "Standard_D2s_v3"
  min_count           = 2
  max_count           = 5
  auto_scaling_enabled = true
  os_disk_size_gb     = 50
  zones               = ["1", "2", "3"]
}

user_node_pools = {
  workload = {
    vm_size             = "Standard_D4s_v3"
    min_count           = 2
    max_count           = 10
    auto_scaling_enabled = true
    os_disk_size_gb     = 100
    zones               = ["1", "2", "3"]
    node_labels = {
      "workload-type" = "general"
    }
    node_taints = []
  }
}

enable_acr           = true
enable_keyvault      = true
enable_log_analytics = true

acr_sku                      = "Premium"
acr_private_endpoint_enabled = true
log_retention_days  = 90
kv_soft_delete_days = 90
kv_purge_protection = true
kv_purge_on_destroy = false

enable_alerts = true
alert_email   = "ops-team@example.com"
