terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    aap = {
      source  = "ansible/aap"
      version = ">= 1.3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "aap" {
  host                 = var.enable_aap ? var.aap_host : "http://localhost"
  username             = var.enable_aap ? var.aap_username : "dummy"
  password             = var.enable_aap ? var.aap_password : "dummy"
  insecure_skip_verify = true
}