variable "applications" {
  description = "The block used to create 1 or more images"
  type = list(object({
    name                            = string
    description                     = optional(string)
    os_type                         = optional(string)
    end_of_life_date                = optional(string)
    eula                            = optional(string)
    privacy_statement_uri           = optional(string)
    release_note_uri                = optional(string)
    create_app_version              = optional(bool, false)
    app_version_name                = optional(string)
    app_version_config_file         = optional(string)
    app_version_enable_health_check = optional(bool)
    app_version_end_of_life_date    = optional(string)
    app_version_exclude_from_latest = optional(bool)
    app_version_package_file        = optional(string)
    app_version_manage_action = optional(object({
      install = string
      remove  = string
      update  = optional(string)
    }))
    app_version_source = optional(object({
      media_link                 = string
      default_configuration_link = optional(string)
    }))
    app_version_target_region = optional(list(object({
      name                   = string
      regional_replica_count = number
      exclude_from_latest    = optional(bool)
      storage_account_type   = optional(string)
    })))
  }))
}

variable "gallery_id" {
  type        = string
  description = "The id of the shared image gallery"
}

variable "location" {
  type        = string
  description = "The name of the location"
  default     = "uksouth"
}

variable "tags" {
  type        = map(string)
  description = "The tags to be applied"
}
