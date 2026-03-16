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

variable "aap_job_template_id" {
  type    = number
  default = 0
}

variable "ssh_port" {
  type    = number
  default = 2200
}