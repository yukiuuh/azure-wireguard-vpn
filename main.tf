resource "random_pet" "rg-name" {
  prefix = var.resource_group_name_prefix
}

# wireguard config file for client
resource "local_file" "client_conf" {
  count = length(var.wg_clients)
  content = templatefile("${path.module}/templates/client_tunnel_conf.tftpl", {
    wg_server_fqdn          = azurerm_public_ip.wgpublicip.fqdn,
    wg_server_net           = var.wg_server_net,
    wg_server_public_key    = var.wg_server_public_key,
    friendly_name           = var.wg_clients[count.index].friendly_name
    wg_client_private_key   = var.wg_clients[count.index].private_key
    wg_nat                  = var.wg_clients[count.index].nat
    wg_client_ip            = "${var.wg_clients[count.index].client_ip}/24"
    wg_server_port          = var.wg_server_port,
    wg_persistent_keepalive = var.wg_persistent_keepalive
  })
  filename = "${path.module}/clients/${var.wg_config_prefix}${var.wg_clients[count.index].friendly_name}.conf"
}

# wireguard config file server
data "template_file" "wg_client_data_json" {
  template = file("${path.module}/templates/server_peer.tpl")
  count    = length(var.wg_clients)

  vars = {
    home_net             = var.home_net,
    wg_nat               = var.wg_clients[count.index].nat,
    friendly_name        = var.wg_clients[count.index].friendly_name
    wg_client_public_key = var.wg_clients[count.index].public_key
    wg_client_ip         = "${var.wg_clients[count.index].client_ip}/32"
    persistent_keepalive = var.wg_persistent_keepalive
  }
}

# random name resource group
resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg-name.id
  location = var.resource_group_location
}

# Azure internal network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Azure internal subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

# public IP
resource "azurerm_public_ip" "bastionpublicip" {
  name                = "bastionPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

}
resource "azurerm_public_ip" "wgpublicip" {
  name                = "wgPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.wg_domain_name_label

}

# allow public ssh access
resource "azurerm_network_security_group" "bastionnsg" {
  name                = "bastionNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "wg" {
  name                = "wgNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "WireGuard"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = var.wg_server_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# nic
resource "azurerm_network_interface" "bastionnic" {
  name                = "bastionNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "bastionNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.bastionpublicip.id
    private_ip_address            = "10.0.1.10"
  }
}

resource "azurerm_network_interface" "wgnic" {
  name                = "wgNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "wgNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.wgpublicip.id
    private_ip_address            = "10.0.1.11"
  }
}

# nic to security group association
resource "azurerm_network_interface_security_group_association" "bastion" {
  network_interface_id      = azurerm_network_interface.bastionnic.id
  network_security_group_id = azurerm_network_security_group.bastionnsg.id
}

resource "azurerm_network_interface_security_group_association" "wg" {
  network_interface_id      = azurerm_network_interface.wgnic.id
  network_security_group_id = azurerm_network_security_group.wg.id
}

# ramdom id for storage account name
resource "random_id" "randomId" {
  keepers = {
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# storage account
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# ssh key
resource "tls_private_key" "secret_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ssh bastion server vm
resource "azurerm_linux_virtual_machine" "bastion" {
  name                  = "bastionVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.bastionnic.id]
  size                  = "Standard_B1ls"

  os_disk {
    name                 = "bastionOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "bastion"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.secret_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  custom_data = filebase64("${path.module}/custom_data/bastion.sh")

}

# wireguard vpn server vm
resource "azurerm_linux_virtual_machine" "wireguard" {
  name                  = "wgVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = ["${azurerm_network_interface.wgnic.id}"]
  size                  = "Standard_B1ls"

  os_disk {
    name                 = "wgOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "wg"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.secret_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
  custom_data = base64encode(templatefile("${path.module}/custom_data/wireguard.tftpl", {
    wg_server_net         = var.wg_server_net,
    wg_server_private_key = var.wg_server_private_key,
    wg_server_port        = var.wg_server_port,
    wg_server_interface   = var.wg_server_interface,
    peers                 = join("\n", data.template_file.wg_client_data_json.*.rendered)
  }))
}
