# Example only.
# Use this only if you want CLI-driven remote runs from your workstation to HCP Terraform.
# For normal VCS-driven HCP Terraform workspaces, do not add this file.

terraform {
  cloud {
    organization = "your-hcp-terraform-org"

    workspaces {
      name = "azure-aap-nginx"
    }
  }
}
