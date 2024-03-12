output "application_gallery_id" {
  description = "The gallery name of the application"
  value       = { for k, v in azurerm_gallery_application.app : k => v.gallery_id }
}

output "application_id" {
  description = "The id of the application"
  value       = { for k, v in azurerm_gallery_application.app : k => v.id }
}

output "application_name" {
  description = "The name of the application"
  value       = { for k, v in azurerm_gallery_application.app : k => v.name }
}
