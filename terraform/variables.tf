variable "rs1-name" {
    description = "resource group 1 name"
    type = string
    default = "central-ind"
}

variable "rs1-loc" {
    description = "resource group 1 location"
    type = string
    default = "Central India"  
}

variable "rs2-name" {
    description = "resource group 2 name"
    type = string
    default = "east-us"
}

variable "rs2-loc" {
    description = "resource group 2 location"
    type = string
    default = "East US"  
}

variable "rs1-vnet-1-name" {
    description = "vnet 1 name of rs 1"
    type = string
    default = "ind-vnet"
}

variable "rs1-vnet1-addressspace" {
    description = "vnet1 address space"
    type = list(string)
    default = [ "10.0.0.0/16" ]
}


variable "rs2-vnet-2-name" {
    description = "vnet 2 name of rs 2 "
    type = string
    default = "eastus-vent"
}

variable "rs2-vnet2-addressspace" {
    description = "vnet 2 address space"
    type = list(string)
    default = [ "10.1.0.0/16" ]
}

variable "rs1-vnet1-sub1" {
    description = "subnet of app in rs1"
    type = string
    default = "ind-subnet"
}

variable "appsub-addressprefix" {
    description = "app subnet address space"
    type = list(string)
    default = [ "10.0.1.0/24" ]
}

variable "rs2-vnet-2-sub2" {
    description = "subnet of db in rs2"
    type = string
    default = "eastus-subnet"
}

variable "dbsub-addressprefix" {
    description = "app subnet address space"
    type = list(string)
    default = [ "10.1.1.0/24" ]
}

variable "appvmname" {
    type = string
    default = "ind-appvm"
}

variable "appvmsize" {
    type = string
    default = "Standard_B2ats_v2"
}

variable "dbvmname" {
    type = string
    default = "eastus-dbvm"
}

variable "db-vmsize" {
    type = string
    default = "DC1s_v3"
  
}

variable "usr" {
    type = string
    default = "noelmc9812"
}

variable "pwd" {
    type = string
    default = "Azurenmc@1234"  
}

variable "caching" {
    type = string
    default = "ReadWrite"
}

variable "storage-account" {
    type = string
    default = "Standard_LRS"
}

variable "image-publisher" {
    type = string
    default = "Canonical"
}

variable "image-version" {
    type = string
    default = "latest"  
}

variable "image-offer" {
    type = string
    default = "0001-com-ubuntu-server-jammy"
}

variable "sku" {
    type = string
    default = "22_04-lts"
  
}