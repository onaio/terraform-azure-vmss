
variable "resource_group_name" {
}

variable "location" {
  default = "germanywestcentral"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network to place the resources in"
  default     = ""
}

variable "subnet_name" {
  type        = string
  description = "(Optional) Name of the Subnet to place the resources in"
  default     = ""
}

variable "vm_instance_type" {
  type        = string
  description = "Individual instance SKU"
}

variable "vm_instance_count" {
  type        = number
  description = "The number of Virtual Machines in the Scale Set"
}

variable "admin_ssh_key" {
  type        = string
  description = "An SSH public key that exist on Azure. This key will be added to /home/{adminuser}/.ssh/authorized_keys"
  default     = "onadevops"
}

variable "vm_admin_username" {
  type        = string
  description = "(optional) The username of the local administrator on each Virtual Machine Scale Set instance"
  default     = "ubuntu"
}

variable "virtual_machine_scale_set_name" {
  type        = string
  description = "The name of the Virtual Machine Scale Set"
}

variable "virtual_machine_source_image_name" {
  type        = string
  description = "The name of an Image which each Virtual Machine in this Scale Set should be based on"
}

variable "vm_os_disk_size" {
  type        = number
  description = "The size in GB of the Data Disk which should be created"
}

variable "assign_public_ip_to_each_vm_in_vmss" {
  type        = bool
  description = "(Optional) Assign a public IP to each instance in the VMSS"
  default     = true
}
variable "upgrade_mode" {
  type        = string
  description = " Specifies how Upgrades (e.g. changing the Image/SKU) should be performed to Virtual Machine Instances. Possible values are Automatic, Manual and Rolling"
  default     = "Automatic"
}

variable "rolling_update_max_batch_instance_percent" {
  type        = number
  description = "(optional) The maximum percent of total virtual machine instances that will be upgraded simultaneously by the rolling upgrade in one batch."
  default     = 75
}
variable "rolling_update_max_unhealthy_instance_percent" {
  type        = number
  description = "(optional) The maximum percentage of the total virtual machine instances in the scale set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts. "
  default     = 75
}
variable "rolling_update_max_unhealthy_upgraded_instance_percent" {
  type        = number
  description = "(optional) The maximum percentage of upgraded virtual machine instances that can be found to be in an unhealthy state"
  default     = 75
}
variable "rolling_update_pause_time_between_batches" {
  type        = string
  description = "(optional) he wait time between completing the update for all virtual machines in one batch and starting the next batch"
  default     = "60S"
}

variable "tags" {
  description = "(Optional) A mapping of tags which should be assigned to this Virtual Machine Scale Set."
  type        = map(string)
  default     = {}
}

# https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/overview
variable "marketplace_extensions" {
  description = "Extensions to be installed on all the virtual machines"
  type = list(object({
    name               = string
    publisher          = string
    type               = string
    version            = string
    protected_settings = string
    settings           = string
  }))

  # use Azure monitor agent extension as an example
  default = [
    {
      name               = "Monitoring-agent"
      publisher          = "Microsoft.Azure.Monitor"
      type               = "AzureMonitorLinuxAgent"
      version            = "1.5"
      protected_settings = null
      settings           = null
    }
  ]
}
