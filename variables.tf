variable "location" {
  type = string
}

variable "prefix" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "my_ip_cidr" {
  type = string
}

variable "enable_aap" {
  description = "Enable AAP automation"
  type        = bool
  default     = true
}

variable "aap_host" {
  type = string
}

variable "aap_username" {
  type      = string
  sensitive = true
}

variable "aap_password" {
  type      = string
  sensitive = true
}

variable "aap_insecure_skip_verify" {
  type    = bool
  default = false
}

variable "aap_organization_name" {
  type = string
}

variable "aap_job_template_name" {
  type = string
}

variable "aap_inventory_name" {
  type    = string
  default = null
}

variable "aap_job_extra_vars" {
  type    = map(any)
  default = {}
}