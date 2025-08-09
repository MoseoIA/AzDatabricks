terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "azurerm" {
    resource_group_name  = "<RG_DEL_BACKEND>"
    storage_account_name = "<STORAGE_BACKEND>"
    container_name       = "<CONTAINER_ESTADO>"
    key                  = "projects/proyecto02/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}


