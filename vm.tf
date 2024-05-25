resource "azurerm_resource_group" "res" {
  name     = "aks12"
  location = "eastus"
}
resource "azurerm_public_ip" "pip" {
  depends_on = [ azurerm_resource_group.res ]
  name                = "PublicIPForLB"
  location            = "eastus"
  resource_group_name = "aks12"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network" "vnet" {
    depends_on = [azurerm_resource_group.res ]
  name                = "testVirtualNetwork1"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = "aks12"

subnet{

  name                 = "frontend"
  address_prefix       = "10.0.2.0/24"
}
}

data "azurerm_subnet" "sub" {
  depends_on = [azurerm_virtual_network.vnet ]
  name                 = "frontend"
  virtual_network_name = "testVirtualNetwork1"
  resource_group_name  = "aks12"
}

resource "azurerm_network_interface" "newnic" {
  depends_on = [ azurerm_resource_group.res ]
  name                = "nicnew22"
  location            = "eastus"
  resource_group_name = "aks12"

 
  ip_configuration {
    name                          = "configuration1"
    subnet_id                     = data.azurerm_subnet.sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}
  resource "azurerm_linux_virtual_machine" "frontendvm" {
  name                = "akkidonotdelete"
  resource_group_name = "akki_res27"
  location            = "eastus"
  size                = "Standard_DS2_v2"
  admin_username      = "akshayinsiders"
  admin_password      = "akshay_21A" 
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.newnic.id,
  ]

os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "30"
    name                 = "frontenddisk"
  }


  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

#loadbalancer ka code 

resource "azurerm_lb" "frontlb" {
  name                = "frontendlb"
  location            = "eastus"
  resource_group_name = "aks12"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}
resource "azurerm_lb_backend_address_pool" "backendpool" {
  loadbalancer_id = azurerm_lb.frontlb.id
  name            = "BackEndAddressPool"
    }
    data "azurerm_network_interface" "front1" {
      depends_on = [ azurerm_linux_virtual_machine.frontendvm ]
  name                = "nicnew22"
  resource_group_name = "aks12"
}


resource "azurerm_network_interface_backend_address_pool_association" "niba1" {
  network_interface_id    = data.azurerm_network_interface.front1.id
  ip_configuration_name   = data.azurerm_network_interface.front1.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backendpool.id
}

resource "azurerm_lb_probe" "ibprobe" {
  loadbalancer_id = azurerm_lb.frontlb.id
  name            = "frontendlb"
  port            = 80
}
resource "azurerm_lb_rule" "lbrule" {
  loadbalancer_id                = azurerm_lb.frontlb.id
  name                           = "LBRule27"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.backendpool.id]
  probe_id =azurerm_lb_probe.ibprobe.id
}


