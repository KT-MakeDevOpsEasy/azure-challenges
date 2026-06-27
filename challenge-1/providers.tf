terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy         = var.kv_purge_on_destroy
      purge_soft_deleted_secrets_on_destroy       = var.kv_purge_on_destroy
      purge_soft_deleted_certificates_on_destroy  = var.kv_purge_on_destroy
    }
  }
  subscription_id = var.subscription_id
}
