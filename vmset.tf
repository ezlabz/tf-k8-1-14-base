resource "azurerm_public_ip" "k8114-ip" {
  name                = "k8114ip"
  location            = "${azurerm_resource_group.k8114-rg.location}"
  resource_group_name = "${azurerm_resource_group.k8114-rg.name}"
  allocation_method   = "Static"
  domain_name_label   = "${azurerm_resource_group.k8114-rg.name}"
  sku                 = "Basic"
  tags = {
    environment = "staging"
  }
}

resource "azurerm_lb" "k8114-lb" {
  name                = "k8114lb"
  location            = "${azurerm_resource_group.k8114-rg.location}"
  resource_group_name = "${azurerm_resource_group.k8114-rg.name}"

  frontend_ip_configuration {
    name                 = "k8114PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.k8114-ip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "k8114-bpepool" {
  resource_group_name = "${azurerm_resource_group.k8114-rg.name}"
  loadbalancer_id     = "${azurerm_lb.k8114-lb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_pool" "k8114-lbnatpool" {
  count                          = 3
  resource_group_name            = "${azurerm_resource_group.k8114-rg.name}"
  name                           = "ssh"
  loadbalancer_id                = "${azurerm_lb.k8114-lb.id}"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "k8114PublicIPAddress"
}

resource "azurerm_lb_probe" "k8114-probe" {
  resource_group_name = "${azurerm_resource_group.k8114-rg.name}"
  loadbalancer_id     = "${azurerm_lb.k8114-lb.id}"
  name                = "http-probe"
  request_path        = "/health"
  port                = 8080
}

resource "azurerm_virtual_machine_scale_set" "test" {
  name                = "mytestscaleset-1"
  location            = "${azurerm_resource_group.k8114-rg.location}"
  resource_group_name = "${azurerm_resource_group.k8114-rg.name}"

  # automatic rolling upgrade
  automatic_os_upgrade = true
  upgrade_policy_mode  = "Rolling"

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  # required when using rolling upgrade policy
  health_probe_id = "${azurerm_lb_probe.k8114-probe.id}"

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 3
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "testvm"
    admin_username       = "myadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/demo_key.pub")}"
    }
  }

  network_profile {
    name    = "k8114networkprofile"
    primary = true

    ip_configuration {
      name                                   = "k8114IPConfiguration"
      primary                                = true
      subnet_id                              = "${azurerm_subnet.k8114-subnet.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.k8114-bpepool.id}"]
      load_balancer_inbound_nat_rules_ids    = ["${element(azurerm_lb_nat_pool.k8114-lbnatpool.*.id, count.index)}"]
    }
  }

  tags = {
    environment = "staging"
  }
}
