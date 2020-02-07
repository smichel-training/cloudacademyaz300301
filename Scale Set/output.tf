output "Public_FQDN" {
     value = azurerm_public_ip.myterraformpublicip.fqdn
 }

 output "Public_IP" {
     value = azurerm_public_ip.myterraformpublicip.ip_address
 }