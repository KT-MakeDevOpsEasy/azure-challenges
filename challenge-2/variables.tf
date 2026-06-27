variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "application_id" {
  description = "Application identifier used in resource naming and tagging (format: CIxxxxx)"
  type        = string
}

variable "project" {
  description = "Project name used in resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "node_subnet_cidr" {
  description = "CIDR for the AKS node subnet"
  type        = string
}

variable "appgw_subnet_cidr" {
  description = "CIDR for the Application Gateway subnet"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = null
}

variable "aks_sku_tier" {
  description = "AKS SKU tier: Free or Standard"
  type        = string
  default     = "Free"
}

variable "authorized_ip_ranges" {
  description = "CIDR ranges authorized to access the API server"
  type        = list(string)
  default     = []
}

variable "system_node_pool" {
  description = "System node pool configuration"
  type = object({
    vm_size             = optional(string, "Standard_D2s_v3")
    node_count          = optional(number, 1)
    min_count           = optional(number, 1)
    max_count           = optional(number, 3)
    auto_scaling_enabled = optional(bool, true)
    os_disk_size_gb     = optional(number, 50)
    zones               = optional(list(string), ["1", "2", "3"])
  })
  default = {}
}

variable "user_node_pools" {
  description = "Map of user node pool configurations"
  type = map(object({
    vm_size             = optional(string, "Standard_D4s_v3")
    node_count          = optional(number, 1)
    min_count           = optional(number, 1)
    max_count           = optional(number, 5)
    auto_scaling_enabled = optional(bool, true)
    os_disk_size_gb     = optional(number, 100)
    zones               = optional(list(string), ["1", "2", "3"])
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
  }))
  default = {}
}

# --- Feature Flags ---

variable "enable_acr" {
  description = "Create Azure Container Registry"
  type        = bool
  default     = true
}

variable "enable_keyvault" {
  description = "Create Azure Key Vault"
  type        = bool
  default     = true
}

variable "enable_log_analytics" {
  description = "Create Log Analytics workspace for Container Insights"
  type        = bool
  default     = true
}

# --- ACR ---

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

# --- Log Analytics ---

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

# --- Key Vault ---

variable "kv_soft_delete_days" {
  description = "Key Vault soft delete retention in days"
  type        = number
  default     = 7
}

variable "kv_purge_protection" {
  description = "Enable Key Vault purge protection"
  type        = bool
  default     = false
}

variable "kv_purge_on_destroy" {
  description = "Purge Key Vault soft-deleted vaults on terraform destroy"
  type        = bool
  default     = true
}
