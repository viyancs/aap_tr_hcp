#############################################
# RANDOM SUFFIX
#############################################

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  name_prefix = "${var.prefix}-${random_string.suffix.result}"
}

locals {
  common_tags = {
    ManagedBy = "Terraform"
    Project   = "AAP"
  }
}

#############################################
# UBUNTU 22.04 AMI
#############################################

data "aws_ssm_parameter" "ubuntu_2204" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "aws_caller_identity" "current" {}

resource "terraform_data" "account_validation" {
  lifecycle {
    precondition {
      condition = (
        data.aws_caller_identity.current.account_id == var.aws_account_id
      )

      error_message = "Wrong AWS account selected."
    }
  }
}

#############################################
# VPC
#############################################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

#############################################
# INTERNET GATEWAY
#############################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

#############################################
# PUBLIC SUBNET
#############################################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-subnet"
  }
}

#############################################
# ROUTE TABLE
#############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.name_prefix}-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#############################################
# SECURITY GROUP
#############################################

resource "aws_security_group" "vm_sg" {
  name        = "${local.name_prefix}-sg"
  description = "VM Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH Custom Port"

    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

#############################################
# SSH KEY
#############################################

resource "aws_key_pair" "ssh_key" {
  key_name   = "${local.name_prefix}-key"
  public_key = var.ssh_public_key
}

#############################################
# EC2 INSTANCE
#############################################

resource "aws_instance" "vm" {
  ami           = data.aws_ssm_parameter.ubuntu_2204.value
  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.vm_sg.id
  ]

  key_name = aws_key_pair.ssh_key.key_name

  associate_public_ip_address = true

  user_data = <<-EOT
#!/bin/bash

cat <<EOF >/etc/ssh/sshd_config.d/99-custom-port.conf
Port ${var.ssh_port}
EOF

systemctl restart ssh || systemctl restart sshd
EOT

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vm"
    }
  )
}

#############################################
# WAIT FOR SSH PORT READY
#############################################

resource "terraform_data" "wait_for_ssh" {

  provisioner "local-exec" {

    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
set -e

echo "Waiting for SSH port ${var.ssh_port} on ${aws_instance.vm.public_ip}..."

for i in $(seq 1 60); do

  if bash -c "</dev/tcp/${aws_instance.vm.public_ip}/${var.ssh_port}" 2>/dev/null; then
    echo "SSH port ready"
    exit 0
  fi

  echo "SSH not ready yet... attempt $i/60"

  sleep 10

done

echo "SSH timeout"

exit 1
EOT
  }

  depends_on = [
    aws_instance.vm
  ]
}

#############################################
# OPTIONAL: TRIGGER AAP JOB
#############################################

resource "terraform_data" "run_aap_job" {

  count = var.enable_aap ? 1 : 0

  provisioner "local-exec" {

    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
set -e

echo "Register host to AAP inventory..."

CREATE_HOST_RESPONSE=$(
curl -sk \
  -H "Authorization: Bearer ${var.aap_password}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "{
    \"name\": \"${aws_instance.vm.tags["Name"]}\",
    \"enabled\": true,
    \"variables\": \"ansible_host: ${aws_instance.vm.public_ip}\nansible_user: ubuntu\nansible_port: ${var.ssh_port}\"
  }" \
  "${var.aap_host}/api/controller/v2/inventories/${var.aap_inventory_id}/hosts/"
)

echo "$${CREATE_HOST_RESPONSE}"

echo "Launching AAP job..."

LAUNCH_JOB_RESPONSE=$(
curl -sk \
  -H "Authorization: Bearer ${var.aap_password}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "{}" \
  "${var.aap_host}/api/controller/v2/job_templates/${var.aap_job_template_id}/launch/"
)

echo "$${LAUNCH_JOB_RESPONSE}"

echo "Done."
EOT
  }

  depends_on = [
    terraform_data.wait_for_ssh
  ]
}

