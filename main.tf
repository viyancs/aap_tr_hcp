resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  name_prefix = "${var.prefix}-${random_string.suffix.result}"
}

#############################################
# RESOURCE GROUP
#############################################

resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
}

#############################################
# NETWORK
#############################################

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name_prefix}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#############################################
# NSG
#############################################

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name_prefix}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-Custom"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.ssh_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#############################################
# PUBLIC IP
#############################################

resource "azurerm_public_ip" "vm_ip" {
  name                = "${local.name_prefix}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

#############################################
# NIC
#############################################

resource "azurerm_network_interface" "nic" {
  name                = "${local.name_prefix}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}

#############################################
# ASSOCIATE NSG
#############################################

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#############################################
# VM
#############################################

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${local.name_prefix}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.ssh_public_key
  }

  #################################
  # CHANGE SSH PORT TO 2200
  #################################

  custom_data = base64encode(<<-EOT
#cloud-config
write_files:
  - path: /etc/ssh/sshd_config.d/99-custom-port.conf
    permissions: '0644'
    content: |
      Port ${var.ssh_port}

runcmd:
  - systemctl restart sshd || systemctl restart ssh
EOT
  )

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  #################################
  # UBUNTU IMAGE (SAFE)
  #################################

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

#############################################
# OPTIONAL: TRIGGER AAP JOB
#############################################

resource "terraform_data" "run_aap_job" {

  count = var.enable_aap ? 1 : 0

  provisioner "local-exec" {

    command = <<EOT

echo "Triggering AAP job..."

curl -k \
-u "${var.aap_username}:${var.aap_password}" \
-H "Content-Type: application/json" \
-X POST \
-d '{
  "extra_vars": {
    "ansible_host": "${azurerm_public_ip.vm_ip.ip_address}",
    "ansible_user": "${var.vm_admin_username}",
    "ansible_port": ${var.ssh_port}
  }
}' \
${var.aap_host}/api/v2/job_templates/${var.aap_job_template_id}/launch/

EOT
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]
}