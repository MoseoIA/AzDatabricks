terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "azurerm" {
    # Rellena estos valores con tu backend real de estado remoto
    resource_group_name  = "<RG_DEL_BACKEND>"
    storage_account_name = "<STORAGE_BACKEND>"
    container_name       = "<CONTAINER_ESTADO>"
    key                  = "projects/proyecto01/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}


