# --- outputs.tf para el Módulo de Key Vault ---

output "key_vault_id" {
  value       = azurerm_key_vault.kv.id
  description = "El ID del recurso del Key Vault."
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "La URI del Key Vault."
}

output "private_endpoint_id" {
  value       = length(azurerm_private_endpoint.pe_kv) > 0 ? azurerm_private_endpoint.pe_kv[0].id : null
  description = "El ID del Private Endpoint para el Key Vault. Es nulo si no se creó."
}

output "private_endpoint_ip_address" {
  value       = length(azurerm_private_endpoint.pe_kv) > 0 ? azurerm_private_endpoint.pe_kv[0].private_service_connection[0].private_ip_address : null
  description = "La dirección IP privada del Private Endpoint. Es nula si no se creó."
}
