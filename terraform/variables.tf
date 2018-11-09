# Required variables
variable "azure_subscription_id" {}
variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "tenant_id" {}
variable "ssh_public_key" {}
variable "domain_name_label" {
  type = "string"
  description = "DNS A record that will route to a public IP such as mylabel.eastus.cloudapp.azure.com"
}

# Optional variables
variable "resource_location" {
  type = "string"
  default = "eastus"
  description = "Azure resource location."
}

variable "vm_size" {
  type = "string"
  default = "Standard_DS1_v2"
  description = "SKUs for different types of VMs in Azure. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes for all sizes."
}