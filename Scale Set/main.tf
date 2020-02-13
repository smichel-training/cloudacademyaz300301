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

resource "random_string" "fqdn" {
 length  = 6
 special = false
 upper   = false
 number  = false
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "${var.ProjectName}-Vnet"
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
    name                 = "${var.ProjectName}-Subnet"
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.0.2.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                        = "${var.ProjectName}-PublicIP"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    allocation_method           = "Static"
    domain_name_label           = random_string.fqdn.result

    # Virtual IP SKU should match Loadbalancer SKU. Basic is by default
    sku                         = "Standard"

    tags = {
        environment = var.EnvironmentName
        project = var.ProjectName
        version = var.BuildVersion
    }   
}

resource "azurerm_lb" "myLoadBalancer" {
    name                        = "${var.ProjectName}-LB"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    sku                         = "Standard"

    frontend_ip_configuration {
        name                 = "NLBPublicIP"
        public_ip_address_id = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = var.EnvironmentName
        project = var.ProjectName
        version = var.BuildVersion
    }
}

resource "azurerm_lb_backend_address_pool" "myLBBackend" {
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    loadbalancer_id             = azurerm_lb.myLoadBalancer.id
    name                        = "${var.ProjectName}-BackEndAddressPool"
}

resource "azurerm_lb_probe" "myLBProbe" {
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    loadbalancer_id     = azurerm_lb.myLoadBalancer.id
    name                = "LBProbe"
    port                = "3389"
}

resource "azurerm_lb_rule" "example" {
  resource_group_name            = azurerm_resource_group.myterraformgroup.name
  loadbalancer_id                = azurerm_lb.myLoadBalancer.id
  probe_id                       = azurerm_lb_probe.myLBProbe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.myLBBackend.id
  frontend_ip_configuration_name = "NLBPublicIP"
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
}

resource "azurerm_lb_nat_pool" "mylbnatpool" {
    resource_group_name            = azurerm_resource_group.myterraformgroup.name
    name                           = "rdp"
    loadbalancer_id                = azurerm_lb.myLoadBalancer.id
    protocol                       = "Tcp"
    frontend_port_start            = 50000
    frontend_port_end              = 50119
    backend_port                   = 3389
    frontend_ip_configuration_name = "NLBPublicIP"
}