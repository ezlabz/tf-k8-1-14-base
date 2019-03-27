provider "azurerm" {
  version = "1.22.0"
  subscription_id  = "${var.azure_subscription_id}"
}

# Create a resource group
resource "azurerm_resource_group" "k8114-rg" {
  name     = "${var.AppName}${var.LOB}k8114rg"
  location = "${var.azure_region}"
}
#Create a virtual network within the resource group
resource "azurerm_virtual_network" "k8114-vnet" {
  name                = "${var.DeploymentLifecycle}${var.AppName}${var.LOB}vnet"
  resource_group_name = "${azurerm_resource_group.k8114-rg.name}"
  location = "${var.azure_region}"
  address_space       = ["${var.vnet_address}"]
}
resource "azurerm_subnet" "k8114-subnet" {
  name                 = "${var.AppName}${var.LOB}k8114subnet"
  resource_group_name  = "${azurerm_resource_group.k8114-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.k8114-vnet.name}"
  address_prefix       = "${cidrsubnet(var.vnet_address, 2, 1)}"
}
resource "random_string" "password" {
  length = 16
  special = true
  override_special = "/@\" "
}

output "password" {
  value = "${random_string.password.result}"
}
