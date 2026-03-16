terraform {
  required_providers {
    aap = {
      source  = "ansible/aap"
      version = ">= 1.3.0"
    }
  }
}

provider "aap" {
  host                 = var.aap_host
  username             = var.aap_username
  password             = var.aap_password
  insecure_skip_verify = var.aap_insecure_skip_verify
}