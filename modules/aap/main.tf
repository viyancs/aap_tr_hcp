data "aap_job_template" "configure_vm" {
  name              = var.aap_job_template_name
  organization_name = var.aap_organization_name
}

resource "aap_inventory" "vm_inventory" {
  name        = var.inventory_name
  description = "Terraform-managed inventory for ${var.vm_name}"

  variables = jsonencode({
    tf_workspace = "hcp-terraform"
    platform     = "azure"
  })
}

resource "aap_host" "vm_host" {
  inventory_id = aap_inventory.vm_inventory.id
  name         = var.vm_name
  enabled      = true

  variables = jsonencode({
    ansible_host = var.public_ip_address
    ansible_user = var.vm_admin_username
  })
}

resource "aap_job" "configure_nginx" {
  job_template_id = data.aap_job_template.configure_vm.id
  inventory_id    = aap_inventory.vm_inventory.id
  extra_vars      = jsonencode(var.aap_job_extra_vars)

  depends_on = [aap_host.vm_host]
}