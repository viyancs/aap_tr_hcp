output "resource_group_name" {
  value       = module.network.resource_group_name
  description = "Azure resource group containing the VM."
}

output "vm_name" {
  value       = module.compute.vm_name
  description = "Provisioned Azure VM name."
}

output "public_ip_address" {
  value       = module.compute.public_ip_address
  description = "Public IP of the provisioned VM."
}

output "private_ip_address" {
  value       = module.compute.private_ip_address
  description = "Private IP of the provisioned VM."
}

output "aap_inventory_id" {
  value       = try(aap_inventory.vm_inventory[0].id, null)
  description = "Inventory ID created in Ansible Automation Platform."
}

output "aap_inventory_name" {
  value       = try(aap_inventory.vm_inventory[0].name, null)
  description = "Inventory name created in Ansible Automation Platform."
}

output "aap_job_id" {
  value       = try(aap_job.configure_nginx[0].id, null)
  description = "AAP job launch resource ID."
}