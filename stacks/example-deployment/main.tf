# --- main.tf para el Stack de Ejemplo: example-deployment ---

# --- 1. Configuración del Proveedor y Backend ---

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  # NOTA: En un escenario real, aquí se configuraría el backend remoto.
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstateeus"
  #   container_name       = "tfstate"
  #   key                  = "example-deployment.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

# --- 2. Recursos Base (Grupo de Recursos y Red) ---

locals {
  project_name = "example-stack"
  location     = "East US"
  tags = {
    Environment = "Demo"
    Project     = "ExampleDeployment"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.project_name}"
  location = local.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.project_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  # Deshabilitar políticas de red para Private Endpoints
  private_endpoint_network_policies_enabled = false
}

# --- 3. Zonas DNS Privadas ---

resource "azurerm_private_dns_zone" "dns_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "dns_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "dns_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

# --- 4. Instancias de los Módulos ---

# Módulo para un Data Lake (Storage Account Gen2) con Private Endpoints
module "data_lake" {
  source = "../../modules/storage-account"

  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  storage_account_name     = "stdatalake${local.project_name}eus"
  is_hns_enabled           = true # <-- Habilitado como Data Lake

  # Conexión de red para PEs
  private_endpoint_subnet_id = azurerm_subnet.private_endpoints.id

  # Habilitación de PEs
  enable_private_endpoint_blob = true
  enable_private_endpoint_dfs  = true

  # Integración con DNS
  enable_private_dns_integration = true
  private_dns_zone_ids = {
    blob = azurerm_private_dns_zone.dns_blob.id
    dfs  = azurerm_private_dns_zone.dns_dfs.id
  }

  tags = local.tags
}

# Módulo para un Key Vault con Private Endpoint
module "key_vault" {
  source = "../../modules/key-vault"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  key_vault_name      = "kv-${local.project_name}"
  sku_name            = "standard"

  # Política de acceso de ejemplo (se necesitaría un object_id real)
  # access_policies = [
  #   {
  #     object_id = "00000000-0000-0000-0000-000000000000" # Reemplazar con un ID de objeto de AAD
  #     key_permissions         = ["Get"]
  #     secret_permissions      = ["Get", "List"]
  #     certificate_permissions = []
  #     storage_permissions     = []
  #   }
  # ]

  # Conexión de red para PE
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.private_endpoints.id

  # Integración con DNS
  enable_private_dns_integration = true
  private_dns_zone_id            = azurerm_private_dns_zone.dns_vault.id

  tags = local.tags
}

# --- 5. Salidas del Stack ---

output "data_lake_id" {
  value = module.data_lake.storage_account_id
}

output "data_lake_dfs_endpoint" {
  value = module.data_lake.primary_dfs_endpoint
}

output "key_vault_id" {
  value = module.key_vault.key_vault_id
}

output "key_vault_uri" {
  value = module.key_vault.key_vault_uri
}
