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
  # IMPORTANTE: Reemplaza la URL con la de tu repositorio de GitHub.
  # Usa una nueva versión/tag que refleje los últimos cambios (ej. v1.4.0).
  source = "git::https://github.com/tu-organizacion/AzNativeServices.git//Mod_AzDatabricks_Native?ref=v1.4.0"

  # --- Parámetros Generales ---
  resource_group_name            = "z-nsm-contactcenter-pp01-ue2-01"
  workspace_name                 = "dbrk-contactcenter-pp01-ue2-01"
  managed_resource_group_name    = "z-nsm-contactcenter-pp01-ue2-01-dbmng"
  
  # --- Parámetros de Red ---
  databricks_vnet_name           = "znsmccentercintpp01eu2net01"
  databricks_vnet_rg_name        = "z-nsm-ccentercint-pp01-ue2-01"
  databricks_public_subnet_name  = "databrickspub64-pic-rt"
  databricks_private_subnet_name = "databrickspriv64-pic-rt"
  # --- NUEVOS PARÁMETROS PARA LOS NSG ---
  public_subnet_nsg_id           = data.azurerm_network_security_group.public_nsg.id
  private_subnet_nsg_id          = data.azurerm_network_security_group.private_nsg.id
  # --- NUEVOS PARÁMETROS PARA EL PRIVATE ENDPOINT ---
  private_endpoint_name          = "private-endpoint-databricks-pic-rt" # <-- CAMBIA ESTO
  private_endpoint_vnet_name     = "znsmccintpp01ue2net01"
  private_endpoint_vnet_rg_name  = "z-nsm-ccint-pp01-ue2-01"
  private_endpoint_subnet_name   = "main-pic-rt"
  

  # --- CONFIGURACIÓN DE DNS ---
  # Elige UNO de los siguientes 3 escenarios y comenta los otros dos.

  # --- Escenario 1: CREAR una nueva Zona DNS (Configuración Actual) ---
  enable_private_dns_integration = true
  create_private_dns_zone        = true

  # --- Escenario 2: USAR una Zona DNS existente ---
  # Comenta el Escenario 1 y descomenta las siguientes 3 líneas.
  # enable_private_dns_integration = true
  # create_private_dns_zone        = false # Opcional, es el valor por defecto
  # private_dns_zone_id_databricks = data.azurerm_private_dns_zone.dns_existente.id

  # --- Escenario 3: SIN integración con DNS ---
  # Comenta los Escenarios 1 y 2 y descomenta la siguiente línea.
  # enable_private_dns_integration = false


  # --- Habilitar creación de la cuenta de almacenamiento ---
  create_storage_account = true
  storage_account_name   = "stcontactcenterpp01ue2"

  tags = {
    Proyecto = "CentroContactoDatos"
    Ambiente = "Piloto-Produccion"
    Owner    = "EquipoDeDatos"
  }
}
