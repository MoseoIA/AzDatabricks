# --- outputs.tf en Mod_AzSqlDatabase_Native ---

output "sql_server_id" {
  value       = azurerm_mssql_server.sql.id
  description = "ID del servidor SQL."
}

output "sql_database_id" {
  value       = azurerm_mssql_database.db.id
  description = "ID de la base de datos."
}


