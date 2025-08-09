# --- variables.tf en Mod_AzDataFactory_Native ---
# Este archivo define todas las variables de entrada que el módulo acepta.

# --- Variables de Data Factory ---

variable "resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos donde se creará el Data Factory."
}

variable "data_factory_name" {
  type        = string
  description = "Nombre para la instancia de Azure Data Factory."
}

# --- Variables de Red para el Private Endpoint ---

variable "private_endpoint_vnet_name" {
  type        = string
  description = "Nombre de la VNet donde se creará el Private Endpoint."
}

variable "private_endpoint_vnet_rg_name" {
  type        = string
  description = "Nombre del grupo de recursos de la VNet del Private Endpoint."
}

variable "private_endpoint_subnet_name" {
  type        = string
  description = "Nombre de la subnet para el Private Endpoint."
}

# --- Variables de DNS Privado ---

variable "enable_private_dns_integration" {
  type        = bool
  description = "Interruptor principal. Si es true, se habilita la integración con Zonas DNS Privadas."
  default     = true
}

variable "create_private_dns_zone" {
  type        = bool
  description = "Si es true, el módulo creará una nueva Zona DNS Privada. Solo es relevante si enable_private_dns_integration es true."
  default     = false
}

variable "private_dns_zone_name" {
  type        = string
  description = "Nombre de la Zona DNS Privada a crear. Relevante solo si create_private_dns_zone es true."
  default     = "privatelink.datafactory.azure.net"
}

variable "private_dns_zone_id_datafactory" {
  type        = string
  description = "ID de una Zona DNS Privada existente. Usar solo si enable_private_dns_integration es true y create_private_dns_zone es false."
  default     = null
}

# --- Variable de Etiquetas ---

variable "tags" {
  type        = map(string)
  description = "Un mapa de etiquetas para aplicar a todos los recursos creados."
  default     = {}
}

# --- Variable para la IP del Private Endpoint ---

variable "private_endpoint_ip_address" {
  type        = string
  description = "Dirección IP privada para el Private Endpoint. Si se deja en null, se asignará una dinámicamente."
  default     = null
}

variable "private_endpoint_ip_offset" {
  type        = number
  description = "Offset para calcular la IP del Private Endpoint usando cidrhost(base_subnet_cidr, offset). Alternativa a especificar la IP literal."
  default     = null
}

variable "require_static_private_endpoint_ip" {
  type        = bool
  description = "Si true, el módulo exigirá que se provea una IP estática vía address u offset para el Private Endpoint."
  default     = true
}