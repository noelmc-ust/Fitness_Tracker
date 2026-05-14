provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "rs-1" {
    name = var.rs1-name
    location = var.rs1-loc
}

resource "azurerm_resource_group" "rs-2" {
    name = var.rs2-name
    location = var.rs2-loc
}

resource "azurerm_virtual_network" "vnet-1" {
    name = var.rs1-vnet-1-name
    address_space = var.rs1-vnet1-addressspace
    resource_group_name = azurerm_resource_group.rs-1.name
    location = azurerm_resource_group.rs-1.location
}

resource "azurerm_virtual_network" "vnet-2" {
    name = var.rs2-vnet-2-name
    address_space = var.rs2-vnet2-addressspace
    resource_group_name = azurerm_resource_group.rs-2.name
    location = azurerm_resource_group.rs-2.location
}


resource "azurerm_subnet" "appsub" {
    name = var.rs1-vnet1-sub1
    resource_group_name = azurerm_resource_group.rs-1.name
    virtual_network_name = azurerm_virtual_network.vnet-1.name
    address_prefixes = var.appsub-addressprefix
}

resource "azurerm_subnet" "dbsub" {
    name = var.rs2-vnet-2-sub2
    resource_group_name = azurerm_resource_group.rs-2.name
    virtual_network_name = azurerm_virtual_network.vnet-2.name
    address_prefixes = var.dbsub-addressprefix
}

resource "azurerm_virtual_network_peering" "peer-a-b" {
    name = "vnetpeer-a-b"
    resource_group_name = azurerm_resource_group.rs-1.name
    virtual_network_name = azurerm_virtual_network.vnet-1.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-2.id

    allow_virtual_network_access = true
    allow_forwarded_traffic = true
    allow_gateway_transit = false
}

resource "azurerm_virtual_network_peering" "peer-b-a" {
    name = "vnetpeer-b-a"
    resource_group_name = azurerm_resource_group.rs-2.name
    virtual_network_name = azurerm_virtual_network.vnet-2.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-1.id

    allow_virtual_network_access = true
    allow_forwarded_traffic = true 
    allow_gateway_transit = false 
}

resource "azurerm_nat_gateway" "natapp" {
    name = "nat-app"
    resource_group_name = azurerm_resource_group.rs-1.name
    location = azurerm_resource_group.rs-1.location
    sku_name = "Standard"
}

resource "azurerm_nat_gateway" "natdb" {
    name = "nat-db"
    resource_group_name = azurerm_resource_group.rs-2.name
    location = azurerm_resource_group.rs-2.location
    sku_name = "Standard"
}

resource "azurerm_public_ip" "nat-app-ip" {
    name = "nat-app-ip"
    resource_group_name = azurerm_resource_group.rs-1.name
    location = azurerm_resource_group.rs-1.location
    allocation_method = "Static"
    sku = "Standard"
}

resource "azurerm_public_ip" "nat-db-ip" {
    name = "nat-db-ip"
    resource_group_name = azurerm_resource_group.rs-2.name
    location = azurerm_resource_group.rs-2.location
    allocation_method = "Static"
    sku = "Standard"
  
}

resource "azurerm_nat_gateway_public_ip_association" "appnatip-assoc" {
    nat_gateway_id = azurerm_nat_gateway.natapp.id
    public_ip_address_id = azurerm_public_ip.nat-app-ip.id
}

resource "azurerm_nat_gateway_public_ip_association" "dbnatip-assoc" {
    nat_gateway_id = azurerm_nat_gateway.natdb.id
    public_ip_address_id = azurerm_public_ip.nat-db-ip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat-appsubnet-assoc" {
    nat_gateway_id = azurerm_nat_gateway.natapp.id
    subnet_id = azurerm_subnet.appsub.id
}

resource "azurerm_subnet_nat_gateway_association" "nat-dbsubnet-assoc" {
    nat_gateway_id = azurerm_nat_gateway.natdb.id
    subnet_id = azurerm_subnet.dbsub.id
}

resource "azurerm_public_ip" "bastion-ip" {
    name = "bastion-ip"
    resource_group_name = azurerm_resource_group.rs-1.name
    location = azurerm_resource_group.rs-1.location
    sku = "Standard"
    allocation_method = "Static"
  
}

resource "azurerm_network_interface" "app-nic" {
    name = "app-nic"
    resource_group_name = azurerm_resource_group.rs-1.name
    location = azurerm_resource_group.rs-1.location

    ip_configuration {
        name = "app-nic"
        subnet_id = azurerm_subnet.appsub.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.bastion-ip.id
    }
  
}

resource "azurerm_network_interface" "db-nic" {
    name = "db-nic"
    resource_group_name = azurerm_resource_group.rs-2.name
    location = azurerm_resource_group.rs-2.location

    ip_configuration {
        name = "db-nic"
        subnet_id = azurerm_subnet.dbsub.id
        private_ip_address_allocation = "Static"
        private_ip_address = "10.1.1.5"
    }
}

resource "azurerm_linux_virtual_machine" "appvm" {
    name = var.appvmname
    resource_group_name = azurerm_resource_group.rs-1.name
    location = azurerm_resource_group.rs-1.location
    size = var.appvmsize
    network_interface_ids = [azurerm_network_interface.app-nic.id]
    admin_username = var.usr
    admin_password = var.pwd
    disable_password_authentication = false 
    custom_data = base64encode(file("appsetup.sh"))

    os_disk {
        caching = var.caching
        storage_account_type = var.storage-account
    }

    source_image_reference {
      publisher = var.image-publisher
      version = var.image-version
      offer = var.image-offer
      sku = var.sku
    }
}

resource "azurerm_network_security_group" "app-nsg" {
    name                = "app-nsg"
    resource_group_name = azurerm_resource_group.rs-1.name
    location            = azurerm_resource_group.rs-1.location

    security_rule {
      name                       = "HTTP"
      priority                   = "110"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "10.0.1.0/24"
    }

    security_rule {
      name                       = "SSH"
      priority                   = "100"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }

    security_rule {
      name                       = "MongoDB"
      priority                   = "120"
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "27017"
      source_address_prefix      = "*"
      destination_address_prefix = "10.1.1.0/24"
    }

  }

resource "azurerm_subnet_network_security_group_association" "app-nsg-assic" {
    subnet_id = azurerm_subnet.appsub.id
    network_security_group_id = azurerm_network_security_group.app-nsg.id
}


resource "azurerm_linux_virtual_machine" "dbvm" {
    name = var.dbvmname
    resource_group_name = azurerm_resource_group.rs-2.name
    location = azurerm_resource_group.rs-2.location
    size = var.db-vmsize
    zone = 3
    network_interface_ids = [azurerm_network_interface.db-nic.id]
    admin_username = var.usr
    admin_password = var.pwd
    disable_password_authentication = false 
    custom_data = base64encode(file("dbsetup.sh"))

    os_disk {
        caching = var.caching
        storage_account_type = var.storage-account
    }

    source_image_reference {
      publisher = var.image-publisher
      version = var.image-version
      offer = var.image-offer
      sku = var.sku
    }
}

resource "azurerm_network_security_group" "db-nsg" {
    name                = "db-nsg"
    resource_group_name = azurerm_resource_group.rs-2.name
    location            = azurerm_resource_group.rs-2.location

    security_rule {
      name                       = "MongoDB"
      priority                   = "110"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     =  "27017"
      source_address_prefix      = "10.0.1.0/24"
      destination_address_prefix = "*"
    }

    security_rule {
      name                       = "SSH"
      priority                   = "100"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }

  }

resource "azurerm_subnet_network_security_group_association" "db-nsg-assic" {
    subnet_id = azurerm_subnet.dbsub.id
    network_security_group_id = azurerm_network_security_group.db-nsg.id
}

resource "azurerm_public_ip" "lb-ip" {
    name = "lb-ip"
    resource_group_name = azurerm_resource_group.rs-1.name
    location = azurerm_resource_group.rs-1.location
    sku = "Standard"
    allocation_method = "Static"
}

resource "azurerm_lb" "app-lb" {
    name = "app-lb"
    resource_group_name = azurerm_resource_group.rs-1.name
    location = azurerm_resource_group.rs-1.location
    sku = "Standard"

    frontend_ip_configuration {
        name = "lb-ip" # name of the public ip resource made
        public_ip_address_id = azurerm_public_ip.lb-ip.id
    }
}

resource "azurerm_lb_backend_address_pool" "back-pool" {
    name = "frontend-app"
    loadbalancer_id = azurerm_lb.app-lb.id
}

resource "azurerm_network_interface_backend_address_pool_association" "nat-bk-assoc" {
    ip_configuration_name = "app-nic" # NIC config name of the vm nic
    network_interface_id = azurerm_network_interface.app-nic.id
    backend_address_pool_id = azurerm_lb_backend_address_pool.back-pool.id
}

resource "azurerm_lb_probe" "health" {
    loadbalancer_id = azurerm_lb.app-lb.id
    name = "health"
    port = 80
    protocol = "Tcp"
}

resource "azurerm_lb_rule" "name" {
    name = "allowtoapp"
    loadbalancer_id = azurerm_lb.app-lb.id
    protocol = "Tcp"
    frontend_port = 80
    backend_port = 80
    frontend_ip_configuration_name = "lb-ip" # the name of the ip resource we created for ip
    backend_address_pool_ids = [azurerm_lb_backend_address_pool.back-pool.id]
    probe_id = azurerm_lb_probe.health.id  
}

