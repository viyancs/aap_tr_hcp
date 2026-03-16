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

module "aap" {
  source = "./modules/aap"

  count = var.enable_aap ? 1 : 0

  aap_host                 = var.aap_host
  aap_username             = var.aap_username
  aap_password             = var.aap_password
  aap_insecure_skip_verify = var.aap_insecure_skip_verify

  aap_job_template_name = var.aap_job_template_name
  aap_organization_name = var.aap_organization_name
  aap_job_extra_vars    = var.aap_job_extra_vars

  inventory_name      = local.inventory_name
  vm_name             = module.compute.vm_name
  public_ip_address   = module.compute.public_ip_address
  private_ip_address  = module.compute.private_ip_address
  vm_admin_username   = var.vm_admin_username
  resource_group_name = module.network.resource_group_name
}