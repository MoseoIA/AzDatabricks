# --- outputs.tf en Mod_AzDataFactory_Native ---
# Este archivo define los valores que el módulo devuelve después de su ejecución.

output "data_factory_id" {
  value       = azurerm_data_factory.adf.id
  description = "El ID del recurso de Azure Data Factory."
}

output "private_endpoint_id" {
  value       = azurerm_private_endpoint.adf_pe.id
  description = "El ID del recurso del Private Endpoint creado para Data Factory."
}

output "private_dns_zone_id" {
  value       = var.enable_private_dns_integration && var.create_private_dns_zone ? azurerm_private_dns_zone.adf_pvdns[0].id : null
  description = "El ID de la Zona DNS Privada creada por el módulo. Será nulo si no se creó."
}
