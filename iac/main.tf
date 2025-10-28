terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Variables
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "govt-prep-rg"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "govt-prep-aks"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "govtprepregistry"
}

variable "node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 2
}

# Create a resource group
resource "azurerm_resource_group" "govt_prep_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Project = "GovtPrep"
    Environment = "Production"
  }
}

# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.govt_prep_rg.name
  location            = azurerm_resource_group.govt_prep_rg.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Project = "GovtPrep"
    Environment = "Production"
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Create AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.govt_prep_rg.name
  location            = azurerm_resource_group.govt_prep_rg.location
  dns_prefix          = var.cluster_name
  
  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  tags = {
    Project = "GovtPrep"
    Environment = "Production"
  }
}

# Attach ACR to AKS
resource "azurerm_role_assignment" "aks_acr_role" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.govt_prep_rg.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.acr.login_server
}

output "aks_cluster_endpoint" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.govt_prep_rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}
