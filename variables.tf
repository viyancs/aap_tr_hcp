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

variable "enable_aap" {
  type    = bool
  default = false
}

variable "aap_host" {
  type    = string
  default = ""
}

variable "aap_username" {
  type    = string
  default = ""
}

variable "aap_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "cf_access_client_id" {
  type        = string
  default     = ""
  description = "Cloudflare Access service token Client ID for AAP API requests."
}

variable "cf_access_client_secret" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Cloudflare Access service token Client Secret for AAP API requests."
}

variable "aap_job_template_id" {
  type    = number
  default = 0
}

variable "ssh_port" {
  type    = number
  default = 2200
}

variable "aap_inventory_id" {
  type = number
}