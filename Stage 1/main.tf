# ---------------------------------------------------------------------------------------------------------------------
#   Azure Provider
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">=0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}
provider "azurerm" {
  features {}
}
# ---------------------------------------------------------------------------------------------------------------------
#   Resource Group
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.rg
  location = var.location
}
# ---------------------------------------------------------------------------------------------------------------------
#   Virtual Network
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vn.vnname
  address_space       = [var.vn.address_prefixes]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}
# ---------------------------------------------------------------------------------------------------------------------
#   Security Group / Security Rule
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.nsg
  name                = each.value.name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_network_security_rule" "web" {
  for_each                    = var.nsg_web_rule
  name                        = each.key
  priority                    = split(",", each.value)[0]
  direction                   = split(",", each.value)[1]
  access                      = split(",", each.value)[2]
  protocol                    = split(",", each.value)[3]
  source_port_range           = split(",", each.value)[4]
  destination_port_range      = split(",", each.value)[5]
  source_address_prefix       = split(",", each.value)[6]
  destination_address_prefix  = split(",", each.value)[7]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg["WebApp"].name
}
resource "azurerm_network_security_rule" "database" {
  for_each                    = var.nsg_database_rule
  name                        = each.key
  priority                    = split(",", each.value)[0]
  direction                   = split(",", each.value)[1]
  access                      = split(",", each.value)[2]
  protocol                    = split(",", each.value)[3]
  source_port_range           = split(",", each.value)[4]
  destination_port_range      = split(",", each.value)[5]
  source_address_prefix       = split(",", each.value)[6]
  destination_address_prefix  = split(",", each.value)[7]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg["Database"].name
}
# ---------------------------------------------------------------------------------------------------------------------
#   Public IP
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "public" {
  name                = var.public_ip.name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = var.public_ip.allocation_method
  sku                 = var.public_ip.sku
}
# ---------------------------------------------------------------------------------------------------------------------
#   Load Balancer
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_lb" "lb" {
  name                = var.lb["Loadbalancer"].name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.lb["Loadbalancer"].sku

  frontend_ip_configuration {
    name                 = var.lb["Frontend"].name
    public_ip_address_id = azurerm_public_ip.public.id
  }
}
resource "azurerm_lb_backend_address_pool" "lb" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = var.lb["Backend"].name
}
resource "azurerm_network_interface_backend_address_pool_association" "lb" {
  network_interface_id    = azurerm_network_interface.nic["WebApp"].id
  ip_configuration_name   = azurerm_network_interface.nic["WebApp"].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb.id

  depends_on = [ azurerm_network_interface.nic, azurerm_subnet.sn ]
}
resource "azurerm_lb_probe" "lb" {
  for_each            = var.health_probe
  name                = each.value.name
  port                = each.value.port
  loadbalancer_id     = azurerm_lb.lb.id
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_lb_rule" "lb" {
  for_each                       = var.lb_rule
  name                           = each.key
  protocol                       = split(",", each.value)[0]
  frontend_port                  = split(",", each.value)[1]
  backend_port                   = split(",", each.value)[2]
  loadbalancer_id                = azurerm_lb.lb.id
  probe_id                       = azurerm_lb_probe.lb[each.key].id
  resource_group_name            = azurerm_resource_group.rg.name
  frontend_ip_configuration_name = var.lb["Frontend"].name
  backend_address_pool_ids       = [azurerm_network_interface_backend_address_pool_association.lb.backend_address_pool_id]
}
# ---------------------------------------------------------------------------------------------------------------------
#   Network Interface
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "nic" {
  for_each            = var.nic
  name                = each.value.nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = each.value.ip_name
    subnet_id                     = azurerm_subnet.sn[each.value.subnet].id
    private_ip_address_allocation = each.value.private_ip_address_allocation
  }
}
# ---------------------------------------------------------------------------------------------------------------------
#   Subnet
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "sn" {
  for_each             = var.sn
  name                 = each.value.name
  address_prefixes     = [each.value.address_prefixes]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}
resource "azurerm_subnet_network_security_group_association" "nsg" {
  for_each                  = var.sn_nsg
  subnet_id                 = azurerm_subnet.sn[each.value.name].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.name].id
}
# ---------------------------------------------------------------------------------------------------------------------
#   Virtual Machine: WebApp / MySQL 
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = var.vm
  name                            = each.value.name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [azurerm_network_interface.nic[each.value.nic].id]
  size                            = each.value.size
  admin_username                  = var.adminusername
  admin_password                  = var.adminpassword
  disable_password_authentication = false

  os_disk {
    name                 = each.value.OSname
    caching              = each.value.caching
    storage_account_type = each.value.storage_account_type
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }
}

