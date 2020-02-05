variable "location" {
  description = "Enter AzureRM Location for configuration deployment"
}

variable "SPA_Key" {
  description = "The Service Principal Account for Terraform deployment"
}

variable "EnvironmentCode" {
  type        = string
  description = "Environment short name (FAC / DEV / PPR / PRD)"
}

variable "EnvironmentName" {
  type        = string
  description = "Environment Full name (Factory / Development / Pre-Production / Production)"
}

variable "ProjectName" {
  type        = string
  description = "Name of the project, will be used for resource group name"
  
}


variable "BuildVersion" {
  type        = string
  description = "The build version"
}

// SECRETS
//Secret variables are initialized with secrets.auto.tfvars file

variable "linux-admin-account" {
  type        = string
  description = "Account name for SSH login"
}

variable "linux-admin-password" {
  type        = string
  description = "Password for linux admin account"
}

variable "linux-ssh-administrator-public-key" {
  type        = string
  description = "SSH private key used for remote access"
}

variable "windows-admin-account" {
  type        = string
  description = "Account name for SSH login"
}

variable "windows-admin-password" {
  type        = string
  description = "Password for linux admin account"
}

provider "azurerm" {
  subscription_id = var.SPA_subscription_id[var.SPA_Key]
  client_id       = var.SPA_client_id[var.SPA_Key]
  client_secret   = var.SPA_client_secret[var.SPA_Key]
  tenant_id       = var.SPA_tenant_id[var.SPA_Key]
}

# Azure Service Principal workspace configuration
# Secrets are stored in secret.auto.tfvars file
variable "SPA_subscription_id" {
  type        = map(string)
  description = "Enter Subscription ID for the provisioning resources in Azure"
}

variable "SPA_client_id" {
  type        = map(string)
  description = "Enter Client ID for the provisioning resources in Azure"
}

variable "SPA_client_secret" {
  type        = map(string)
  description = "Enter Client secret for the provisioning resources in Azure"
}

variable "SPA_tenant_id" {
  type        = map(string)
  description = "Enter Tenant ID / Directory ID of your Azure AD"
}

