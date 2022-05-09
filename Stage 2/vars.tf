# ---------------------------------------------------------------------------------------------------------------------
#   Resource Group
# ---------------------------------------------------------------------------------------------------------------------
variable "rg" {
  type    = string
  default = "rg-product"
  }
# ---------------------------------------------------------------------------------------------------------------------
#   Virtual Network
# ---------------------------------------------------------------------------------------------------------------------
variable "vn" {
  type        = map(any)
  default = {
    "vnname"           = "vn-product"
    "address_prefixes" = "10.0.0.0/16"
  }
}
# ---------------------------------------------------------------------------------------------------------------------
#   Network Security Group / Network Security Rule
# ---------------------------------------------------------------------------------------------------------------------
variable "nsg" {
  type        = map(any)
  description = "Creates two network security group for subnet-web and subnet-database"
  default = {
    "WebApp" = {
      name = "nsg-web"
    }

    "Database" = {
      name = "nsg-database"
    }
  }
}
#Reuse nsg_web_rule for WebApp2
variable "nsg_web_rule" {
  type        = map(any)
  description = "Creates a network security group for WebApp"
  default = {
    Allow_SSH  = "1001,Inbound,Allow,TCP,*,22,*,*"
    Allow_HTTP = "1000,Inbound,Allow,TCP,*,80,*,*"
    Allow_HTTPS = "1002,Inbound,Allow,TCP,*,443,*,*"
  }
}
variable "nsg_database_rule" {
  type        = map(any)
  description = "Creates a network security group for Database"
  default = {
    Allow_SSH   = "1001,Inbound,Allow,TCP,*,22,*,*"
    Allow_MySQL = "1000,Inbound,Allow,TCP,*,3306,10.0.0.0/8,*"
  }
}
# ---------------------------------------------------------------------------------------------------------------------
#   Public IP
# ---------------------------------------------------------------------------------------------------------------------
variable "public_ip" {
  type = map(any)
  default = {
    name              = "public-ip"
    allocation_method = "Static"
    sku               = "Standard"
  }
}
# ---------------------------------------------------------------------------------------------------------------------
#   Load Balancer / Load Balanacer Rule / Health Probe
# ---------------------------------------------------------------------------------------------------------------------
variable "lb" {
  type = map(any)
  default = {
    "Loadbalancer" = {
      name = "lb"
      sku  = "Standard"
    }

    "Frontend" = {
      name = "lb-frontend"
    }

    "Backend" = {
      name = "lb-backend"
    }
  }
}

variable "lb_rule" {
  type        = map(any)
  default = {
    SSH   = "TCP,22,22,SourceIPProtocol"
    HTTP  = "TCP,80,80,Default"
    HTTPS = "TCP,443,443,Default"
  }
}

variable "health_probe" {
  type        = map(any)
  default = {
    "SSH" = {
      name = "ssh-running-probe"
      port = "22"
    },
    "HTTP" = {
      name = "http-running-probe"
      port = "80"
    }
        "HTTPS" = {
      name = "https-running-probe"
      port = "443"
    }
  }
}
# ---------------------------------------------------------------------------------------------------------------------
#   Subnet
# ---------------------------------------------------------------------------------------------------------------------
variable "sn" {
  type = map(any)
  default = {

    "WebApp" = {
      name             = "sn-web"
      address_prefixes = "10.0.1.0/24"
    }

    "Database" = {
      name             = "sn-database"
      address_prefixes = "10.0.2.0/24"
    }
  }
}
# ---------------------------------------------------------------------------------------------------------------------
#   Network Interface
# ---------------------------------------------------------------------------------------------------------------------
variable "nic" {
  type = map(any)
  default = {

    "WebApp" = {
      nic_name                      = "nic-web"
      ip_name                       = "ip-web"
      subnet                        = "WebApp"
      private_ip_address_allocation = "Dynamic"
    }

    "Database" = {
      nic_name                      = "nic-database"
      ip_name                       = "ip-database"
      subnet                        = "Database"
      private_ip_address_allocation = "Dynamic"
    }

      "WebApp2" = {
      nic_name                      = "nic-web2"
      ip_name                       = "ip-web2"
      subnet                        = "WebApp"
      private_ip_address_allocation = "Dynamic"
    }
  }
}

variable "sn_nsg" {
  type = map(any)
  default = {

    "WebApp" = {
      name   = "WebApp"
    }

    "Database" = {
      name   = "Database"
    }
  }
}
# ---------------------------------------------------------------------------------------------------------------------
#   Virtual Machine
# ---------------------------------------------------------------------------------------------------------------------
variable "vm" {
  type = map(any)
  default = {

    "WebApp" = {
      name                 = "WebApp"
      nic                  = "WebApp"
      size                 = "Standard_B2s"
      OSname               = "WebAppOsDisk"
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
      availability_zone    = "1"
    }

    "Database" = {
      name                 = "MySQL"
      nic                  = "Database"
      size                 = "Standard_B2s"
      OSname               = "DatabaseOsDisk"
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
      availability_zone    = "1"
    }
      "WebApp2" = {
      name                 = "WebApp2"
      nic                  = "WebApp2"
      size                 = "Standard_B2s"
      OSname               = "WebApp2OsDisk"
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
      availability_zone    = "2"
      }
  }
}
variable "location" {
  type    = string
  default = "australiaeast"
}

variable "image" {
  type = map(any)
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal-daily"
    sku       = "20_04-daily-lts-gen2"
    version   = "20.04.202204040"
  }
}
# ---------------------------------------------------------------------------------------------------------------------
#   Admin Username / Password
# ---------------------------------------------------------------------------------------------------------------------
variable "adminusername" {
  type    = string
  default = "usernamehere"
}

variable "adminpassword" {
  type    = string
  default = "passwordhere"
}