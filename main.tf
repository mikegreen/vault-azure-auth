terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.46"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~>2.2"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = { "owner" = "mike-green", "managed_by" = "terraform", "deleteable" = "yes" }
}


resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = "Central US"
  tags     = var.common_tags
}

resource "azurerm_user_assigned_identity" "example" {
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  name = "vault-azure-auth-demo-identity"
  tags = var.common_tags
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network-vault-auth"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags                = var.common_tags
}

resource "azurerm_subnet" "example" {
  name                 = "internal-vault-auth"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.2.2.0/24"]
}


resource "azurerm_public_ip" "dynamicip-rg" {
  name                = "myPublicIP-rg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"

  tags = var.common_tags
}

resource "azurerm_network_interface" "example-rg" {
  name                = "example-nic-vault-auth-rg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dynamicip-rg.id

  }
  tags = var.common_tags
}


resource "azurerm_public_ip" "dynamicip-ua" {
  name                = "myPublicIP-ua"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"

  tags = var.common_tags
}

resource "azurerm_network_interface" "example-ua" {
  name                = "example-nic-vault-auth-ua"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dynamicip-ua.id
  }
  tags = var.common_tags
}


resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = var.common_tags
}

resource "azurerm_network_security_rule" "example" {
  name                        = "SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "22"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}


resource "azurerm_network_interface_security_group_association" "example-ua" {
  network_interface_id      = azurerm_network_interface.example-ua.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_network_interface_security_group_association" "example-rg" {
  network_interface_id      = azurerm_network_interface.example-rg.id
  network_security_group_id = azurerm_network_security_group.example.id
}


resource "azurerm_linux_virtual_machine" "example-rg" {
  name                = "example-machine-in-rg"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_A1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example-rg.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.common_tags
}

resource "azurerm_linux_virtual_machine" "example-ua" { # 39196f8c-6a93-4010-abcd-50ddc93e52bf 
  name                = "example-machine-in-ua"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_A1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example-ua.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.example.id]
  }
  tags = var.common_tags
}
