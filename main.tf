resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  name_prefix    = "${var.prefix}-${random_string.suffix.result}"
  inventory_name = coalesce(var.aap_inventory_name, "${local.name_prefix}-inventory")
}

module "network" {
  source = "./modules/network"

  prefix     = local.name_prefix
  location   = var.location
  my_ip_cidr = var.my_ip_cidr
}

module "compute" {
  source = "./modules/compute"

  prefix              = local.name_prefix
  location            = var.location
  resource_group_name = module.network.resource_group_name
  subnet_id           = module.network.subnet_id
  nsg_id              = module.network.nsg_id
  admin_username      = var.vm_admin_username
  ssh_public_key      = var.ssh_public_key
  vm_size             = var.vm_size
}

# Lookup AAP Job Template (optional)
data "aap_job_template" "configure_vm" {
  count             = var.enable_aap ? 1 : 0
  name              = var.aap_job_template_name
  organization_name = var.aap_organization_name
}

# Create inventory in AAP (optional)
resource "aap_inventory" "vm_inventory" {
  count = var.enable_aap ? 1 : 0

  name        = local.inventory_name
  description = "Terraform-managed inventory for ${module.compute.vm_name}"

  variables = jsonencode({
    tf_workspace = "hcp-terraform"
    platform     = "azure"
    provisioner  = "terraform"
  })
}

# Register VM host into inventory (optional)
resource "aap_host" "vm_host" {
  count = var.enable_aap ? 1 : 0

  inventory_id = aap_inventory.vm_inventory[0].id
  name         = module.compute.vm_name
  description  = "Azure VM provisioned by HCP Terraform"
  enabled      = true

  variables = jsonencode({
    ansible_host         = module.compute.public_ip_address
    ansible_user         = var.vm_admin_username
    private_ip           = module.compute.private_ip_address
    azure_resource_group = module.network.resource_group_name
  })
}

# Launch job template (optional)
resource "aap_job" "configure_nginx" {
  count = var.enable_aap ? 1 : 0

  job_template_id = data.aap_job_template.configure_vm[0].id
  inventory_id    = aap_inventory.vm_inventory[0].id
  extra_vars      = jsonencode(var.aap_job_extra_vars)

  depends_on = [aap_host.vm_host]
}