output "lb-ip" {
    value = azurerm_public_ip.lb-ip.ip_address
}

output "appvmip" {
    value = azurerm_public_ip.bastion-ip
}

output "dbvmip" {
    value = azurerm_network_interface.db-nic.private_ip_address
}

