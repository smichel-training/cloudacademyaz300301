
# Create a new resource group# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "${var.EnvironmentCode}-${var.ProjectName}-rg"
    location = var.location

    tags = {
        environment = var.EnvironmentName
        project = var.ProjectName
        version = var.BuildVersion
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "${var.ProjectName}-myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = var.EnvironmentName
        project = var.ProjectName
        version = var.BuildVersion
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "${var.ProjectName}-mySubnet"
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "${var.ProjectName}-myPublicIP"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method = "Dynamic"

    tags = {
        environment = var.EnvironmentName
        project = var.ProjectName
        version = var.BuildVersion
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
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

# Create virtual machine
resource "azurerm_virtual_machine" "windows001" {
    name                  = "${var.ProjectName}-WIN001"
    location              = var.location
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }


    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.ProjectName}-WIN001"
        admin_username = var.windows-admin-account
        admin_password = var.windows-admin-password
    }

    os_profile_windows_config {
        }
    
    storage_data_disk {
      name                = "${var.ProjectName}-data-disk001"
      managed_disk_type   = "Standard_LRS"
      caching             = "None"
      create_option       = "Empty"
      disk_size_gb        = "30"
      lun                 = "1"
    }
        
    tags = {
        environment = var.EnvironmentName
        project = var.ProjectName
        version = var.BuildVersion
    }
}
