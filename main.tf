resource "azurerm_gallery_application" "app" {
  for_each = { for k, v in var.applications : k => v }

  gallery_id = var.gallery_id
  location   = var.location
  tags       = var.tags

  name                  = try(each.value.name, null)
  description           = try(each.value.description, null)
  supported_os_type     = title(each.value.os_type)
  end_of_life_date      = each.value.end_of_life_date
  eula                  = each.value.eula
  privacy_statement_uri = each.value.privacy_statement_uri
  release_note_uri      = each.value.release_note_uri
}

resource "azurerm_gallery_application_version" "app_version" {
  for_each = { for k, v in var.applications : k => v if v.create_app_version == true }

  name                   = each.value.app_version_name != null ? each.value.app_version_name : azurerm_gallery_application.app[each.key].name
  gallery_application_id = azurerm_gallery_application.app[each.key].id
  location               = azurerm_gallery_application.app[each.key].location
  tags                   = azurerm_gallery_application.app[each.key].tags
  config_file            = each.value.app_version_config_file
  enable_health_check    = each.value.app_version_enable_health_check
  end_of_life_date       = each.value.app_version_end_of_life_date
  package_file           = each.value.app_version_package_file


  dynamic "manage_action" {
    for_each = each.value.app_version_manage_action != null ? [each.value.app_version_manage_action] : []
    content {
      install = manage_action.value.install
      remove  = manage_action.value.remove
      update  = manage_action.value.update
    }
  }

  dynamic "source" {
    for_each = each.value.app_version_source != null ? [each.value.app_version_source] : []
    content {
      media_link                 = source.value.media_link
      default_configuration_link = source.value.default_configuration_link
    }
  }

  dynamic "target_region" {
    for_each = each.value.app_version_target_region != null ? each.value.app_version_target_region : []
    content {

      name                   = target_region.value.name
      regional_replica_count = target_region.value.regional_replica_count
      exclude_from_latest    = target_region.value.exclude_from_latest
      storage_account_type   = target_region.value.storage_account_type
    }
  }
}
