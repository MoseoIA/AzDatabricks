# --- main.tf en el proyecto CentroContactoDatos ---
# Versión final que delega la creación de la Zona DNS al módulo.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# --- LLAMADA AL MÓDULO DE DATABRICKS ---
module "databricks_contact_center" {
  # IMPORTANTE: Reemplaza la URL con la de tu repositorio de GitHub.
  # Usa una nueva versión/tag que refleje los últimos cambios.
  source = "git::https://github.com/tu-organizacion/AzNativeServices.git//Mod_AzDatabricks_Native?ref=v1.3.0"

  # --- Parámetros Generales ---
  resource_group_name            = "z-nsm-contactcenter-pp01-ue2-01"
  workspace_name                 = "dbrk-contactcenter-pp01-ue2-01"
  managed_resource_group_name    = "z-nsm-contactcenter-pp01-ue2-01-dbmng"
  
  # --- Parámetros de Red ---
  databricks_vnet_name           = "znsmccentercintpp01eu2net01"
  databricks_vnet_rg_name        = "z-nsm-ccentercint-pp01-ue2-01"
  databricks_public_subnet_name  = "databrickspub64-pic-rt"
  databricks_private_subnet_name = "databrickspriv64-pic-rt"

  private_endpoint_vnet_name     = "znsmccintpp01ue2net01"
  private_endpoint_vnet_rg_name  = "z-nsm-ccint-pp01-ue2-01"
  private_endpoint_subnet_name   = "main-pic-rt"
  
  # --- Habilitar creación de la Zona DNS Privada ---
  # El módulo ahora se encargará de crear la zona y el VNet link.
  create_private_dns_zone = true
  # 'private_dns_zone_id_databricks' ya no es necesario aquí.

  # --- Habilitar creación de la cuenta de almacenamiento ---
  create_storage_account = true
  storage_account_name   = "stcontactcenterpp01ue2"

  tags = {
    Proyecto = "CentroContactoDatos"
    Ambiente = "Piloto-Produccion"
    Owner    = "EquipoDeDatos"
  }
}
