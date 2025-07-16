# --- main.tf en el proyecto CentroContactoDatos ---
# Versión final que muestra cómo configurar el módulo para los diferentes escenarios de DNS.

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


# --- DATA SOURCES ---
# Busca los NSGs existentes que están asociados a las subnets de Databricks.
# IMPORTANTE: Reemplaza los nombres de los NSG con los nombres reales en tu entorno.
data "azurerm_network_security_group" "public_nsg" {
  name                = "nsg-databrickspub" # <-- CAMBIA ESTO AL NOMBRE REAL
  resource_group_name = "z-nsm-ccentercint-pp01-ue2-01" # RG donde está la VNet
}

data "azurerm_network_security_group" "private_nsg" {
  name                = "nsg-databrickspriv" # <-- CAMBIA ESTO AL NOMBRE REAL
  resource_group_name = "z-nsm-ccentercint-pp01-ue2-01" # RG donde está la VNet
}


# --- (OPCIONAL) DATA SOURCE PARA USAR UNA ZONA DNS EXISTENTE ---
# Descomenta este bloque solo si vas a usar el Escenario 2.
# data "azurerm_private_dns_zone" "dns_existente" {
#   name                = "privatelink.azuredatabricks.net"
#   resource_group_name = "mi-grupo-de-recursos-de-red" # <-- CAMBIA ESTO
# }


# --- LLAMADA AL MÓDULO DE DATABRICKS ---
module "databricks_contact_center" {
  source = "../AzNativeServices/Mod_AzDatabricks_Native"

  # --- Parámetros Generales ---
  resource_group_name         = "z-nsm-contactcenter-pp01-ue2-01"
  workspace_name              = "dbrk-contactcenter-pp01-ue2-01"
  managed_resource_group_name = "z-nsm-contactcenter-pp01-ue2-01-dbmng"

  # --- Parámetros de Red (VNet Injection) ---
  databricks_vnet_name           = "znsmccentercintpp01eu2net01"
  databricks_vnet_rg_name        = "z-nsm-ccentercint-pp01-ue2-01"
  databricks_public_subnet_name  = "databrickspub64-pic-rt"
  databricks_private_subnet_name = "databrickspriv64-pic-rt"
  public_subnet_nsg_id           = data.azurerm_network_security_group.public_nsg.id
  private_subnet_nsg_id          = data.azurerm_network_security_group.private_nsg.id

  # --- Parámetros de Red (Private Endpoint) ---
  private_endpoint_vnet_name    = "znsmccintpp01ue2net01"
  private_endpoint_vnet_rg_name = "z-nsm-ccint-pp01-ue2-01"
  private_endpoint_subnet_name  = "main-pic-rt"

  # --- CONFIGURACIÓN DE DNS ---
  # Escenario 1: CREAR una nueva Zona DNS.
  enable_private_dns_integration = true
  create_private_dns_zone        = true
  # Para usar una zona existente:
  # create_private_dns_zone        = false
  # private_dns_zone_id_databricks = data.azurerm_private_dns_zone.dns_existente.id

  # --- Habilitar creación de la cuenta de almacenamiento ---
  create_storage_account = true
  storage_account_name   = "stcontactcenterpp01ue2"

  tags = {
    Proyecto = "CentroContactoDatos"
    Ambiente = "Piloto-Produccion"
    Owner    = "EquipoDeDatos"
  }
}

# --- LLAMADA AL MÓDULO DE DATA FACTORY ---
module "data_factory_contact_center" {
  source = "../AzNativeServices/Mod_AzDataFactory_Native"

  # --- Parámetros Generales ---
  resource_group_name = "z-nsm-contactcenter-pp01-ue2-01"
  data_factory_name   = "adf-contactcenter-pp01-ue2-01"

  # --- Parámetros de Red (Private Endpoint) ---
  private_endpoint_vnet_name    = "znsmccintpp01ue2net01"
  private_endpoint_vnet_rg_name = "z-nsm-ccint-pp01-ue2-01"
  private_endpoint_subnet_name  = "main-pic-rt"

  # --- CONFIGURACIÓN DE DNS ---
  # Escenario 1: CREAR una nueva Zona DNS.
  enable_private_dns_integration = true
  create_private_dns_zone        = true
  # Para usar una zona existente:
  # create_private_dns_zone        = false
  # private_dns_zone_id_datafactory = data.azurerm_private_dns_zone.dns_existente_adf.id

  tags = {
    Proyecto = "CentroContactoDatos"
    Ambiente = "Piloto-Produccion"
    Owner    = "EquipoDeDatos"
  }
}
