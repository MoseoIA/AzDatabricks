# Archivo: CentroContactoDatos/network.tf

# --- INICIA LA SOLUCIÓN ---
# Creación del Network Security Group (NSG) para Databricks

resource "azurerm_network_security_group" "databricks_nsg" {
  name                = "nsg-databricks-centrocontacto"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Regla 1: Permitir comunicación interna en la VNet (clusters)
  security_rule {
    name                       = "VnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Regla 2: Permitir la conexión del Plano de Control de Databricks
  security_rule {
    name                       = "AzureDatabricksInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443" # Solo HTTPS
    source_address_prefix      = "AzureDatabricks"
    destination_address_prefix = "VirtualNetwork"
  }
  
  # Regla 3: Permitir el acceso saliente a Internet para librerías, etc.
  security_rule {
    name                       = "AllowOutboundToInternet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

  tags = {
    Proyecto = "CentroContactoDatos"
  }
}

# --- FIN DE LA SOLUCIÓN ---

# Creación de la Red Virtual (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-databricks-centrocontacto"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Creación de la subred pública
resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Creación de la subred privada
resource "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}


# --- INICIA LA SOLUCIÓN ---
# Asociación del NSG a las subredes de Databricks

resource "azurerm_subnet_network_security_group_association" "public_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.databricks_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.databricks_nsg.id
}
# --- FIN DE LA SOLUCIÓN ---