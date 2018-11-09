output "ark_public_ip" {
    value = "${azurerm_public_ip.ark_public_ip.ip_address}"
}