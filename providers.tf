terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

variable "azure_subscription_id" {}
variable "azure_subscription_tenant_id" {}
variable "azure_service_principal_appid" {}
variable "azure_service_principal_password" {}

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_subscription_tenant_id
  client_id       = var.azure_service_principal_appid
  client_secret   = var.azure_service_principal_password
}
