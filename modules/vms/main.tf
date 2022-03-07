resource "azurerm_resource_group" "dev-test-group" {
  name     = "dev-test-group"
  location = "West Europe"
}

resource "azurerm_virtual_network" "dev-network" {
  name                = "dev-network"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.dev-test-group.location
  resource_group_name = azurerm_resource_group.dev-test-group.name
}

resource "azurerm_subnet" "dev-subnet" {
  name                 = "spot-subnet"
  resource_group_name  = azurerm_resource_group.dev-test-group.name
  virtual_network_name = azurerm_virtual_network.dev-network.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_public_ip" "pip" {
  for_each = { for conf in var.vms: conf.nic.name => conf }
  name                = each.value.nic.name
  resource_group_name = azurerm_resource_group.dev-test-group.name
  location            = azurerm_resource_group.dev-test-group.location
  allocation_method   = each.value.pip.allocation_method
}

output "pip" {
  value = { for k in azurerm_public_ip.pip : k.name => k.id }
}

resource "azurerm_network_interface" "nics" {
  for_each = { for conf in var.vms: conf.nic.name => conf }
  name                = each.value.nic.name
  location            = azurerm_resource_group.dev-test-group.location
  resource_group_name = azurerm_resource_group.dev-test-group.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = each.value.nic.ipconfname
    subnet_id                     = azurerm_subnet.dev-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.value.nic.name].id
  }
}

output "nics" {
  value = { for k in azurerm_network_interface.nics : k.name => k.id }
  depends_on = [azurerm_network_interface.nics]
}

resource "azurerm_linux_virtual_machine" "spot-machine" {
  for_each = { for conf in var.vms: conf.vm.name => conf}
  name                = each.value.vm.name
  resource_group_name = azurerm_resource_group.dev-test-group.name
  location            = azurerm_resource_group.dev-test-group.location
  size                = "Standard_B2s"
  admin_username      = "bob"
  network_interface_ids = [
     azurerm_network_interface.nics[each.value.nic.name].id
  ]

  admin_ssh_key {
    username   = "bob"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.vm.publisher
    offer     = each.value.vm.offer
    sku       = each.value.vm.sku
    version   = each.value.vm.version
  }
  depends_on = [azurerm_network_interface.nics]
}

output "ips" {
  value = [ for ip in azurerm_linux_virtual_machine.spot-machine : { "${ip.computer_name}" = [ip.public_ip_address, ip.private_ip_address] }]
}