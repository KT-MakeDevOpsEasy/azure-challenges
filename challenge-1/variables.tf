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
  description = "Environment name (e.g., dev, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Enabled")
  }))
}

# --- Feature Flags ---

variable "enable_vm" {
  description = "Create the Linux virtual machine"
  type        = bool
  default     = true
}

variable "enable_keyvault" {
  description = "Create Azure Key Vault"
  type        = bool
  default     = true
}

# --- VM ---

variable "ssh_source_prefix" {
  description = "Source address prefix allowed for SSH access"
  type        = string
  default     = "*"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureuser"
}

variable "vm_ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
  sensitive   = true
}

variable "vm_os_disk_type" {
  description = "Storage account type for the VM OS disk"
  type        = string
  default     = "Standard_LRS"
}

variable "vm_image" {
  description = "Source image reference for the virtual machine"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "create_public_ip" {
  description = "Whether to create a public IP for the VM"
  type        = bool
  default     = true
}

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
