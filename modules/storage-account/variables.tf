# --- variables.tf en Mod_AzStorageAccount_Native ---

variable "resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos donde se creará la Storage Account."
}

variable "storage_account_name" {
  type        = string
  description = "Nombre único global para la Storage Account (3-24 caracteres, solo minúsculas y números)."
}

variable "account_tier" {
  type        = string
  description = "Tier de la cuenta de almacenamiento."
  default     = "Standard"
}

variable "account_replication_type" {
  type        = string
  description = "Tipo de replicación (LRS, GRS, RAGRS, ZRS)."
  default     = "LRS"
}

variable "is_hns_enabled" {
  type        = bool
  description = "Habilita Hierarchical Namespace (ADLS Gen2)."
  default     = false
}

variable "allow_blob_public_access" {
  type        = bool
  description = "Permite acceso público a contenedores/objetos Blob."
  default     = false
}

variable "min_tls_version" {
  type        = string
  description = "Versión mínima de TLS."
  default     = "TLS1_2"
}

variable "tags" {
  type        = map(string)
  description = "Mapa de etiquetas."
  default     = {}
}

# --- Private Endpoint opcional para Blob ---
variable "enable_private_endpoint" {
  type        = bool
  description = "Si true, crea Private Endpoint para blob."
  default     = true
}

variable "private_endpoint_vnet_name" {
  type        = string
  description = "VNet donde se creará el PE."
  default     = null
}

variable "private_endpoint_vnet_rg_name" {
  type        = string
  description = "RG de la VNet del PE."
  default     = null
}

variable "private_endpoint_subnet_name" {
  type        = string
  description = "Subnet del PE."
  default     = null
}

variable "private_endpoint_ip_address" {
  type        = string
  description = "IP fija del PE."
  default     = null
}

variable "private_endpoint_ip_offset" {
  type        = number
  description = "Offset para calcular IP del PE con cidrhost()."
  default     = null
}

# --- Reglas de red públicas (solo si se requiere acceso público) ---
variable "allowed_public_ips" {
  type        = list(string)
  description = "Lista de IPs/CIDRs permitidos para acceso público."
  default     = []
}

# Private Endpoints a demanda
variable "private_endpoint_subresources" {
  type        = list(string)
  description = "Lista de subrecursos para PE: p.ej. [\"blob\", \"file\", \"dfs\"]."
  default     = ["blob"]
}

variable "require_static_private_endpoint_ip" {
  type        = bool
  description = "Si true, exige IP estática (address u offset) para cada PE creado."
  default     = true
}


