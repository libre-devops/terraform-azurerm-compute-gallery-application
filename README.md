```hcl
resource "azurerm_shared_image" "shared_image" {
  for_each                            = { for k, v in var.images : k => v }
  gallery_name                        = var.gallery_name
  resource_group_name                 = var.rg_name
  location                            = var.location
  tags                                = var.tags
  name                                = try(each.value.name, null)
  description                         = try(each.value.description, null)
  specialized                         = try(each.value.specialised, null)
  hyper_v_generation                  = upper(try(each.value.hyper_v_generation, null))
  os_type                             = title(each.value.os_type)
  accelerated_network_support_enabled = try(each.value.accelerated_network_support_enabled, null)
  eula                                = each.value.eula
  end_of_life_date                    = each.value.end_of_life_date
  disk_types_not_allowed              = each.value.disk_types_not_allowed
  architecture                        = each.value.architecture
  max_recommended_vcpu_count          = each.value.max_recommended_vcpu_count
  min_recommended_vcpu_count          = each.value.min_recommended_vcpu_count
  max_recommended_memory_in_gb        = each.value.max_recommended_memory_in_gb
  min_recommended_memory_in_gb        = each.value.min_recommended_memory_in_gb
  release_note_uri                    = each.value.release_note_uri
  trusted_launch_enabled              = each.value.trusted_launch_enabled
  trusted_launch_supported            = each.value.trusted_launch_supported
  confidential_vm_enabled             = each.value.confidential_vm_enabled
  confidential_vm_supported           = each.value.confidential_vm_supported

  dynamic "identifier" {
    for_each = each.value.identifier != null ? [each.value.identifier] : []
    content {
      offer     = identifier.value.offer
      publisher = identifier.value.publisher
      sku       = identifier.value.sku
    }
  }

  dynamic "purchase_plan" {
    for_each = each.value.purchase_plan != null ? [each.value.purchase_plan] : []
    content {
      name      = purchase_plan.value.name
      publisher = purchase_plan.value.publisher
      product   = purchase_plan.value.product
    }
  }
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_shared_image.shared_image](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gallery_name"></a> [gallery\_name](#input\_gallery\_name) | The name of the shared image gallery | `string` | n/a | yes |
| <a name="input_images"></a> [images](#input\_images) | The block used to create 1 or more images | <pre>list(object({<br>    name                                = string<br>    description                         = optional(string)<br>    specialized                         = optional(bool, false)<br>    hyper_v_generation                  = optional(string, "V2")<br>    os_type                             = optional(string)<br>    accelerated_network_support_enabled = optional(string)<br>    disk_types_not_allowed              = optional(list(string))<br>    end_of_life_date                    = optional(string)<br>    eula                                = optional(string)<br>    architecture                        = optional(string, "x64")<br>    max_recommended_vcpu_count          = optional(number)<br>    min_recommended_vcpu_count          = optional(number)<br>    max_recommended_memory_in_gb        = optional(number)<br>    min_recommended_memory_in_gb        = optional(number)<br>    privacy_statement_uri               = optional(string)<br>    release_note_uri                    = optional(string)<br>    trusted_launch_supported            = optional(bool)<br>    trusted_launch_enabled              = optional(bool)<br>    confidential_vm_supported           = optional(bool)<br>    confidential_vm_enabled             = optional(bool)<br>    identifier = object({<br>      offer     = string<br>      publisher = string<br>      sku       = string<br>    })<br>    purchase_plan = optional(object({<br>      name      = string<br>      publisher = optional(string)<br>      product   = optional(string)<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The name of the location | `string` | `"uksouth"` | no |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to be applied | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_gallery_name"></a> [image\_gallery\_name](#output\_image\_gallery\_name) | The gallery name of the image |
| <a name="output_image_id"></a> [image\_id](#output\_image\_id) | The id of the image |
| <a name="output_image_name"></a> [image\_name](#output\_image\_name) | The name of the image |
| <a name="output_image_resource_group_name"></a> [image\_resource\_group\_name](#output\_image\_resource\_group\_name) | The rg name of the image |
