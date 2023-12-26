# Define el proveedor de Terraform para Azure
provider "azurerm" {
  features {}
}

# Crea un grupo de recursos en Azure
resource "azurerm_resource_group" "VS" {
  name     = "VS-resources"
  location = "West Europe"
}

# Define una red virtual dentro del grupo de recursos
resource "azurerm_virtual_network" "VS" {
  name                = "VS-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.VS.location
  resource_group_name = azurerm_resource_group.VS.name
}

# Crea una subred dentro de la red virtual
resource "azurerm_subnet" "VS" {
  name                 = "VS-subnet"
  resource_group_name  = azurerm_resource_group.VS.name
  virtual_network_name = azurerm_virtual_network.VS.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Define una interfaz de red para la máquina virtual
resource "azurerm_network_interface" "VS" {
  name                = "VS-nic"
  location            = azurerm_resource_group.VS.location
  resource_group_name = azurerm_resource_group.VS.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.VS.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Configura una máquina virtual Linux (Ubuntu 22.04) en Azure
resource "azurerm_linux_virtual_machine" "VS" {
  name                = "VS-vm"
  resource_group_name = azurerm_resource_group.VS.name
  location            = azurerm_resource_group.VS.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.VS.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}
