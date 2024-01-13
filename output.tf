output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "bastion_public_ip_address" {
  value = azurerm_linux_virtual_machine.bastion.public_ip_address
}

output "wg_public_ip_address" {
  value = azurerm_linux_virtual_machine.wireguard.public_ip_address
}

output "wg_fqdn" {
  value = azurerm_public_ip.wgpublicip.fqdn
}

output "wg_private_ip_address" {
  value = azurerm_linux_virtual_machine.wireguard.private_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.secret_ssh.private_key_pem
  sensitive = true
}
