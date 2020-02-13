
resource "azurerm_virtual_machine_scale_set" "example" {
    name                        = "${var.ProjectName}-scaleset"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.myterraformgroup.name

    # Specifies whether the Virtual Machine Scale Set should be overprovisioned. 
    overprovision               = false

    # automatic rolling upgrade
    automatic_os_upgrade        = true
    upgrade_policy_mode         = "Rolling"

    rolling_upgrade_policy {
        max_batch_instance_percent              = 20
        max_unhealthy_instance_percent          = 20
        max_unhealthy_upgraded_instance_percent = 5
        pause_time_between_batches              = "PT0S"
    }

  # required when using rolling upgrade policy
    health_probe_id = azurerm_lb_probe.myLBProbe.id

    sku {
        name                                    = "Standard_DS1_v2"
        tier                                    = "Standard"
        capacity                                = 2
    }

    storage_profile_image_reference {
        publisher                               = "MicrosoftWindowsServer"
        offer                                   = "WindowsServer"
        sku                                     = "2016-Datacenter"
        version                                 = "latest"
    }

    storage_profile_os_disk {
        name                                    = ""
        caching                                 = "ReadWrite"
        create_option                           = "FromImage"
        managed_disk_type                       = "Standard_LRS"
    }

    storage_profile_data_disk {
        lun                                     = 1
        caching                                 = "ReadWrite"
        create_option                           = "Empty"
        disk_size_gb                            = 10
    }

    os_profile {
        computer_name_prefix                    = "vm"
        admin_username                          = var.windows-admin-account
        admin_password                          = var.windows-admin-password
    }

    network_profile {
        name                                    = "terraformnetworkprofile"
        primary                                 = true

        ip_configuration {
            name                                    = "TestIPConfiguration"
            subnet_id                               = azurerm_subnet.myterraformsubnet.id
            load_balancer_backend_address_pool_ids  = [azurerm_lb_backend_address_pool.myLBBackend.id]
            load_balancer_inbound_nat_rules_ids     = [azurerm_lb_nat_pool.mylbnatpool.id]
            primary = true
        }
    }

    tags = {
        environment                             = var.EnvironmentName
        project                                 = var.ProjectName
        version                                 = var.BuildVersion
    }
    
    depends_on = [azurerm_lb.myLoadBalancer]
}

# Scale IN and scale OUT rule
resource "azurerm_monitor_autoscale_setting" "example" {
    name                                        = "myAutoscaleSetting"
    resource_group_name                         = azurerm_resource_group.myterraformgroup.name
    location                                    = var.location
    target_resource_id                          = azurerm_virtual_machine_scale_set.example.id

    profile {
        name = "defaultProfile"

        capacity {
            default                             = 2
            minimum                             = 2
            maximum                             = 6
        }

        rule {
            metric_trigger {
                metric_name                         = "Percentage CPU"
                metric_resource_id                  = azurerm_virtual_machine_scale_set.example.id
                time_grain                          = "PT1M"
                statistic                           = "Average"
                time_window                         = "PT5M"
                time_aggregation                    = "Average"
                operator                            = "GreaterThan"
                threshold                           = 80
            }

            scale_action {
                direction                           = "Increase"
                type                                = "ChangeCount"
                value                               = "1"
                cooldown                            = "PT1M"
            }
        }

        rule {
            metric_trigger {
                metric_name        = "Percentage CPU"
                metric_resource_id = azurerm_virtual_machine_scale_set.example.id
                time_grain         = "PT1M"
                statistic          = "Average"
                time_window        = "PT5M"
                time_aggregation   = "Average"
                operator           = "LessThan"
                threshold          = 25
            }

            scale_action {
                direction = "Decrease"
                type      = "ChangeCount"
                value     = "1"
                cooldown  = "PT1M"
            }
        }
    }

    notification {
        email {
            send_to_subscription_administrator    = true
            send_to_subscription_co_administrator = true
            custom_emails                         = ["aix.smichel@gmail.com"]
        }
    } 
}




# Create Network Security Group and rule
/* resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "${var.ProjectName}-myNetworkSecurityGroup"
    location            = var.location
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    
    security_rule {
        name                       = "RDP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = var.EnvironmentName
        project = var.ProjectName
        version = var.BuildVersion
    }
}

resource "azurerm_network_security_rule" "httprule" {
        name                        = "httprule01"
        priority                    = 110
        direction                   = "inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        resource_group_name        = azurerm_resource_group.myterraformgroup.name
        network_security_group_name = azurerm_network_security_group.myterraformnsg.name
    }

#Allow WinRM port
resource "azurerm_network_security_rule" "WinRM5985" {
        name                        = "WinRM5985"
        priority                    = 120
        direction                   = "inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "5985"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        resource_group_name        = azurerm_resource_group.myterraformgroup.name
        network_security_group_name = azurerm_network_security_group.myterraformnsg.name
    }

resource "azurerm_network_security_rule" "WinRM5986" {
        name                        = "WinRM5986"
        priority                    = 130
        direction                   = "inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "5986"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        resource_group_name        = azurerm_resource_group.myterraformgroup.name
        network_security_group_name = azurerm_network_security_group.myterraformnsg.name
    }


# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "${var.ProjectName}-myNIC"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.myterraformgroup.name
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id

    ip_configuration {
        name                          = "${var.ProjectName}-myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }
    tags = {
        environment = var.EnvironmentName
        project = var.ProjectName
        version = var.BuildVersion
    }
}
*/