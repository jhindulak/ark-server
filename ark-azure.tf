provider "azurerm" {
    subscription_id = "${var.azure_subscription_id}"
    client_id       = "${var.azure_client_id}"
    client_secret   = "${var.azure_client_secret}"
    tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "ark_resource_group" {
    name     = "ark_server"
    location = "${var.resource_location}"

    tags {
        environment = "ark_server"
    }
}

resource "azurerm_virtual_network" "ark_vnet" {
    name                = "ark_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${azurerm_resource_group.ark_resource_group.location}"
    resource_group_name = "${azurerm_resource_group.ark_resource_group.name}"

    tags {
        environment = "ark_server"
    }
}

resource "azurerm_subnet" "ark_subnet" {
    name                 = "ark_subnet"
    resource_group_name  = "${azurerm_resource_group.ark_resource_group.name}"
    virtual_network_name = "${azurerm_virtual_network.ark_vnet.name}"
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "ark_public_ip" {
    name                         = "ark_public_ip"
    location                     = "${azurerm_resource_group.ark_resource_group.location}"
    resource_group_name          = "${azurerm_resource_group.ark_resource_group.name}"
    public_ip_address_allocation = "dynamic"
    domain_name_label            = "${var.domain_name_label}"

    tag {
        environment = "ark_server"
    }
}

resource "azurerm_network_security_group" "ark_nsg" {
    name                        = "ark_nsg"
    location                    = "${azurerm_resource_group.ark_resource_group.location}"
    resource_group_name         = "${azurerm_resource_group.ark_resource_group.name}"

    security_rule {
        name                       = "ssh"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "steam_server_browser"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Udp"
        source_port_range          = "*"
        destination_port_range     = "27015"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "game_client_port"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Udp"
        source_port_range          = "*"
        destination_port_range     = "7777"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "raw_udp_port"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Udp"
        source_port_range          = "*"
        destination_port_range     = "7778"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "remote_console_server_access"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "27020"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "ark_server"
    }
}

resource "azurerm_network_interface" "ark_nic" {
    name                      = "ark_nic"
    location                  = "${azurerm_resource_group.ark_resource_group.location}"
    resource_group_name       = "${azurerm_resource_group.ark_resource_group.name}"
    network_security_group_id = "${azurerm_network_security_group.ark_nsg.id}"

    ip_configuration {
        name                          = "ark_nic_config"
        subnet_id                     = "${azurerm_subnet.ark_subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.ark_public_ip.id}"
    }

    tags {
        environment = "ark_server"
    }
}

resource "random_id" "randomId" {
    keepers {
        resource_group = "${azurerm_resource_group.ark_resource_group.name}"
    }

    byte_length = 8
}

resource "azurerm_storage_account" "ark_storage_account" {
    name                     = "diag${random_id.randomId.hex}"
    resource_group_name      = "${azurerm_resource_group.ark_resource_group.name}"
    location                 = "${azurerm_resource_group.ark_resource_group.location}"
    account_replication_type = "LRS"
    account_tier             = "Standard" 

    tags {
        environment = "ark_server"
    }
}

resource "azurerm_virtual_machine" "ark_vm" {
    name                        = "ark_vm"
    location                    = "${azurerm_resource_group.ark_resource_group.location}"
    resource_group_name         = "${azurerm_resource_group.ark_resource_group.name}"
    network_interface_ids       = ["${azurerm_network_interface.ark_nic.id}"]
    vm_size                     = "${var.vm_size}"

    storage_os_disk {
        name              = "ark_os_disk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name = "ark_vm"
        admin_username = "${var.vm_username}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.vm_username}/.ssh/authorized_keys"
            key_data = "${var.ssh_public_key}"
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.ark_storage_account.primary_blob_endpoint}"
    }

    tags {
        environment = "ark_server"
    }
}