resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  name_prefix = "${var.prefix}-${random_string.suffix.result}"
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
}

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

resource "azurerm_public_ip" "vm_ip" {
  name                = "${local.name_prefix}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

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

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RockyEnterpriseSoftwareFoundation"
    offer     = "rockylinux"
    sku       = "9"
    version   = "latest"
  }
}

#############################################
# WAIT UNTIL SSH READY
#############################################

resource "terraform_data" "wait_for_ssh" {

  provisioner "local-exec" {
    command = <<EOT

echo "Waiting for SSH..."

for i in {1..30}; do
  nc -z ${azurerm_public_ip.vm_ip.ip_address} 22 && exit 0
  sleep 10
done

echo "SSH not ready"
exit 1

EOT
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]
}

#############################################
# TRIGGER AAP JOB
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
    "ansible_user": "${var.vm_admin_username}"
  }
}' \
${var.aap_host}/api/v2/job_templates/${var.aap_job_template_id}/launch/

EOT
  }

  depends_on = [
    terraform_data.wait_for_ssh
  ]
}