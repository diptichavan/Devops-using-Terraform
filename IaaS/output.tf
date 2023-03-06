
output "acr_admin_password" {
  value       = azurerm_container_registry.d_acr.admin_password
  description = "The object ID of the user"
  sensitive   = true
}

output "acr_login_server" {
  value = azurerm_container_registry.d_acr.login_server
}

output "function_app_endpoint" {
  value = azurerm_function_app.d_func_app.default_hostname

}

output "function_app_name" {
  value = azurerm_function_app.d_func_app.name
  description = "Deployed function app name"
}

output "function_app_name" {
