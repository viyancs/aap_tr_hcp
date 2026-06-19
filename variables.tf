variable "aws_region" {
  default = "ap-southeast-1"
}

variable "prefix" {
  default = "demo"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ssh_port" {
  default = 2222
}

variable "ssh_public_key" {
  type = string
}

variable "enable_aap" {
  default = false
}

variable "aap_host" {
  default = ""
}

variable "aap_password" {
  default   = ""
  #sensitive = true
}

variable "aap_inventory_id" {
  default = 0
}

variable "aap_job_template_id" {
  default = 0
}

variable "aws_account_id" {
  type = string
}