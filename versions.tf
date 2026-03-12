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

# HCP Terraform / Terraform Cloud note:
# - For VCS-driven workspaces, you usually DO NOT need a `cloud {}` block in code.
# - Connect this repository to a workspace in the HCP Terraform UI.
# - If you prefer CLI-driven remote runs, see docs/cloud_block.example.tf.

provider "azurerm" {
  features {}
}

provider "aap" {
  host                 = var.aap_host
  username             = var.aap_username
  password             = var.aap_password
  insecure_skip_verify = var.aap_insecure_skip_verify
}
