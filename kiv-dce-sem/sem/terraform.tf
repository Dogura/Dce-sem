
terraform {
  required_providers {
    opennebula = {
      source = "OpenNebula/opennebula"
      version = "~> 1.2"
    }
  }
}
provider "opennebula" {
  endpoint      = "${var.one_endpoint}"
  username      = "${var.one_username}"
  password      = "${var.one_password}"
}

resource "opennebula_image" "os-image" {
    name = "${var.vm_image_name}"
    datastore_id = "${var.vm_imagedatastore_id}"
    persistent = false
    path = "${var.vm_image_url}"
    permissions = "600"
}

resource "opennebula_virtual_machine" "master-balancer" {
  # This will create `vm_instance_count` instances:
  name = "master-balancer"
  description = "Master-balancer VM"
  cpu = 1
  vcpu = 1
  memory = 2048
  permissions = "600"
  group = "users"

  context = {
    NETWORK  = "YES"
    HOSTNAME = "$NAME"
    SSH_PUBLIC_KEY = "${var.vm_ssh_pubkey}"
  }
  os {
    arch = "x86_64"
    boot = "disk0"
  }
  disk {
    image_id = opennebula_image.os-image.id
    target   = "vda"
    size     = 12000 # 12GB
  }

  graphics {
    listen = "0.0.0.0"
    type   = "vnc"
  }

  nic {
    network_id = var.vm_network_id
  }

  connection {
    type = "ssh"
    user = "root"
    host = "${self.ip}"
    private_key = "${file("/var/iac-dev-container-data/id_ecdsa")}"
  }

  provisioner "file" {
    source = "init-scripts/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "export INIT_USER=${var.vm_admin_user}",
      "export INIT_PUBKEY='${var.vm_ssh_pubkey}'",
      "export INIT_LOG=${var.vm_node_init_log}",
      "export INIT_HOSTNAME=${self.name}",
      "touch ${var.vm_node_init_log}",
      "sh /tmp/init-start.sh",
      "sh /tmp/init-node.sh",
      "sh /tmp/init-users.sh",
      "sh /tmp/init-finish.sh"
    ]
  }

  tags = {
    role = "master"
  }

}

resource "opennebula_virtual_machine" "slave-node" {
  # This will create `vm_instance_count` instances:
  count = var.nodes_count
  name = "slave-node-${count.index + 1}"
  description = "slave node VM #${count.index + 1}"
  cpu = 1
  vcpu = 1
  memory = 2048
  permissions = "600"
  group = "users"

  context = {
    NETWORK  = "YES"
    HOSTNAME = "$NAME"
    SSH_PUBLIC_KEY = "${var.vm_ssh_pubkey}"
  }
  os {
    arch = "x86_64"
    boot = "disk0"
  }
  disk {
    image_id = opennebula_image.os-image.id
    target   = "vda"
    size     = 12000 # 12GB
  }

  graphics {
    listen = "0.0.0.0"
    type   = "vnc"
  }

  nic {
    network_id = var.vm_network_id
  }

  connection {
    type = "ssh"
    user = "root"
    host = "${self.ip}"
    private_key = "${file("/var/iac-dev-container-data/id_ecdsa")}"
  }

  provisioner "file" {
    source = "init-scripts/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "export INIT_USER=${var.vm_admin_user}",
      "export INIT_PUBKEY='${var.vm_ssh_pubkey}'",
      "export INIT_LOG=${var.vm_node_init_log}",
      "export INIT_HOSTNAME=${self.name}",
      "touch ${var.vm_node_init_log}",
      "sh /tmp/init-start.sh",
      "sh /tmp/init-node.sh",
      "sh /tmp/init-users.sh",
      "sh /tmp/init-finish.sh"
    ]
  }

  tags = {
    role = "node"
  }

}

#-------OUTPUTS ------------

output "master-balancer" {
  value = "${opennebula_virtual_machine.master-balancer.*.ip}"
}

output "slave-node" {
  value = "${opennebula_virtual_machine.slave-node.*.ip}"
}

resource "local_file" "hosts_cfg" {
  content = templatefile("inventory.tmpl",
    {
      vm_admin_user = var.vm_admin_user,
      k8s_master = opennebula_virtual_machine.master-balancer.*.ip,
      k8s_nodes = opennebula_virtual_machine.slave-node.*.ip
    })
  filename = "./dynamic_inventories/inventory"
}

#
# EOF
#
