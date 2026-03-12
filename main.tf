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

# Looks up an existing Automation Controller / AAP job template.
data "aap_job_template" "configure_vm" {
  name              = var.aap_job_template_name
  organization_name = var.aap_organization_name
}

resource "aap_inventory" "vm_inventory" {
  name              = local.inventory_name
  organization_name = var.aap_organization_name
  description       = "Terraform-managed inventory for ${module.compute.vm_name}"

  variables = jsonencode({
    tf_workspace = "hcp-terraform"
    platform     = "azure"
    provisioner  = "terraform"
  })
}

resource "aap_host" "vm_host" {
  inventory_id = aap_inventory.vm_inventory.id
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

# The target Job Template in AAP should have “Prompt on launch” enabled for Inventory.
resource "aap_job" "configure_nginx" {
  job_template_id = data.aap_job_template.configure_vm.id
  inventory_id    = aap_inventory.vm_inventory.id
  extra_vars      = jsonencode(var.aap_job_extra_vars)

  depends_on = [aap_host.vm_host]
}
