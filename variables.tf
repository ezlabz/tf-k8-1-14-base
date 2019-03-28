
# This is the deployment lifecycle that should be one of the following values.
# - prod
# - qa
# - test
variable "DeploymentLifecycle" {}

variable "AppName" {}

# This is the associate/contractor that spun up the instance, or the associate or contractor that should be contacted regarding this AE
variable "Owner" {}

# This is the Line of Business that the AE belongs to for Charge Back purposes.
variable "LOB" {}

# Our Azure Subscription.
variable "azure_subscription_id" {
  default = ""
}

# The default Azure Region we build in.
variable "azure_region" {
  default = "eastus"
}

# The Azure SP(Service Principle) used to authenticate to Azure api
# (This can be create in the azure cli with az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/{SubscriptionID}")
variable "azure_sp" {
  default = ""
}


variable "vnet_address" {
  default = ""
}