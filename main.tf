data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "subnet" {
  name                 = length(var.subnet_name) > 0 ? var.subnet_name : data.azurerm_virtual_network.vnet.subnets[0]
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = var.resource_group_name
}

data "azurerm_ssh_public_key" "admin" {
  name                = var.admin_ssh_key
  resource_group_name = var.resource_group_name
}

data "azurerm_image" "image" {
  name                = var.virtual_machine_source_image_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_group" "primary" {
  name                = var.virtual_machine_scale_set_name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = var.network_security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

}
# VMSS
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  count               = 1
  name                = var.virtual_machine_scale_set_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_instance_type
  instances           = var.vm_instance_count
  admin_username      = var.vm_admin_username
  upgrade_mode        = var.upgrade_mode

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = data.azurerm_ssh_public_key.admin.public_key
  }

  source_image_id = data.azurerm_image.image.id

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = var.vm_os_disk_size
  }

  network_interface {
    name    = var.virtual_machine_scale_set_name
    primary = true

    network_security_group_id = azurerm_network_security_group.primary.id

    ip_configuration {
      name      = var.virtual_machine_scale_set_name
      primary   = true
      subnet_id = data.azurerm_subnet.subnet.id

      dynamic "public_ip_address" {
        for_each = var.assign_public_ip_to_each_vm_in_vmss ? [{}] : []
        content {
          name              = lower("pip-${format("vm%s%s", lower(replace(var.virtual_machine_scale_set_name, "/[[:^alnum:]]/", "")), "0${count.index + 1}")}")
          domain_name_label = format("vm-%s-pip0${count.index + 1}", lower(replace(var.virtual_machine_scale_set_name, "/[[:^alnum:]]/", "")))
        }
      }
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = var.upgrade_mode == "Rolling" ? [{}] : []
    content {
      max_batch_instance_percent              = var.rolling_update_max_batch_instance_percent
      max_unhealthy_instance_percent          = var.rolling_update_max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = var.rolling_update_max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = var.rolling_update_pause_time_between_batches
    }
  }
  tags = var.tags
}

resource "azurerm_virtual_machine_scale_set_extension" "agent" {
  count                        = length(var.marketplace_extensions)
  name                         = var.marketplace_extensions[count.index].name
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss[0].id
  publisher                    = var.marketplace_extensions[count.index].publisher
  type                         = var.marketplace_extensions[count.index].type
  type_handler_version         = var.marketplace_extensions[count.index].version
  settings                     = jsonencode(var.marketplace_extensions[count.index].settings)
  protected_settings           = jsonencode(var.marketplace_extensions[count.index].protected_settings)
}
