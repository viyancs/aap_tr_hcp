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
  value       = aap_inventory.vm_inventory.id
  description = "Inventory ID created in Ansible Automation Platform."
}

output "aap_inventory_name" {
  value       = aap_inventory.vm_inventory.name
  description = "Inventory name created in Ansible Automation Platform."
}

output "aap_job_id" {
  value       = aap_job.configure_nginx.id
  description = "AAP job launch resource ID."
}
