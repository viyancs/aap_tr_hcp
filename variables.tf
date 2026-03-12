variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Short prefix for naming Azure and AAP resources."
  type        = string
  default     = "demo"
}

variable "vm_admin_username" {
  description = "Local admin username for the Linux VM."
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B2s"
}

variable "ssh_public_key" {
  description = "SSH public key content injected into the VM. Store this as a Terraform variable in HCP Terraform."
  type        = string
}

variable "my_ip_cidr" {
  description = "CIDR allowed to SSH to the VM, for example 203.0.113.10/32."
  type        = string
}

variable "aap_host" {
  description = "AAP / Automation Controller base URL, for example https://controller.example.com."
  type        = string
}

variable "aap_username" {
  description = "AAP username. Prefer a service account."
  type        = string
}

variable "aap_password" {
  description = "AAP password or token-backed local account secret. Mark as sensitive in HCP Terraform."
  type        = string
  sensitive   = true
}

variable "aap_insecure_skip_verify" {
  description = "Skip TLS verification for AAP API calls."
  type        = bool
  default     = false
}

variable "aap_organization_name" {
  description = "Existing organization name in AAP."
  type        = string
}

variable "aap_job_template_name" {
  description = "Existing AAP job template name that installs/configures Nginx."
  type        = string
}

variable "aap_inventory_name" {
  description = "Optional explicit AAP inventory name. Leave null to auto-generate."
  type        = string
  default     = null
}

variable "aap_job_extra_vars" {
  description = "Extra vars passed to the AAP job launch."
  type        = map(any)
  default = {
    web_server = "nginx"
  }
}
