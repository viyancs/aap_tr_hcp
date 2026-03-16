variable "aap_host" {}
variable "aap_username" {}
variable "aap_password" {}
variable "aap_insecure_skip_verify" {}

variable "aap_job_template_name" {}
variable "aap_organization_name" {}

variable "inventory_name" {}
variable "vm_name" {}
variable "public_ip_address" {}
variable "private_ip_address" {}
variable "vm_admin_username" {}
variable "resource_group_name" {}

variable "aap_job_extra_vars" {
  type = map(any)
}