# --- outputs.tf en Mod_AzKeyVault_Native ---

output "key_vault_id" {
  value       = azurerm_key_vault.kv.id
  description = "ID del Key Vault."
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "URI del Key Vault."
}


