# --- outputs.tf en el proyecto CentroContactoDatos ---
# Expone información importante de los recursos creados por los módulos.

output "url_databricks_centro_contacto" {
  value       = module.databricks_contact_center.databricks_workspace_url
  description = "URL de acceso al workspace de Databricks para el Centro de Contacto."
}

output "id_storage_account_databricks" {
  value       = module.databricks_contact_center.storage_account_id
  description = "ID del recurso de la cuenta de almacenamiento creada para Databricks."
}

output "id_private_dns_zone" {
  value       = module.databricks_contact_center.private_dns_zone_id
  description = "ID del recurso de la Zona DNS Privada creada por el módulo (si aplica)."
}
