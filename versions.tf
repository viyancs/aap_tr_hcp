terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    aap = {
      source  = "ansible/aap"
      version = ">= 1.3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "aap" {
  host                 = var.enable_aap ? var.aap_host : null
  username             = var.enable_aap ? var.aap_username : null
  password             = var.enable_aap ? var.aap_password : null
  insecure_skip_verify = var.enable_aap ? var.aap_insecure_skip_verify : false
}