output "resource_group_name" {
  value = module.network.resource_group_name
}

output "vm_name" {
  value = module.compute.vm_name
}

output "public_ip_address" {
  value = module.compute.public_ip_address
}

output "private_ip_address" {
  value = module.compute.private_ip_address
}

output "aap_inventory_id" {
  value = try(module.aap[0].aap_inventory_id, null)
}

output "aap_inventory_name" {
  value = try(module.aap[0].aap_inventory_name, null)
}