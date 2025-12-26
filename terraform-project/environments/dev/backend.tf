terraform {
  required_version = ">= 1.6.0"
  
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod"
    storage_account_name = "sttfstateproXXXX"  # Replace XXXX with unique suffix
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
