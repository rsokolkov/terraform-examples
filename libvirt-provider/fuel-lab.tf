provider "libvirt" {
  uri = "qemu+ssh://root@pdt2/system"
}

# Common variables
variable "prefix" {
  default = "rs-terraform"
}

# Common resources
resource "libvirt_network" "adm_net" {
  name = "${var.prefix}-adm_net"
  domain = "lab"
  mode = "none"
}

resource "libvirt_network" "trunk_net" {
  name = "${var.prefix}-trunk_net"
  domain = "lab"
  mode = "none"
}

# Fuel node
resource "libvirt_volume" "fuel_vol" {
  name = "${var.prefix}-vol-fuel_vol"
  pool = "images"
  size = "${100 * 1024 * 1024 * 1024}"
}

resource "libvirt_domain" "fuel" {
  name = "${var.prefix}-fuel"
  vcpu = 1
  memory = 4096
  running = false
  disk {volume_id = "${libvirt_volume.fuel_vol.id}"}
  network_interface {network_name = "${libvirt_network.adm_net.name}"}
  network_interface {network_name = "${libvirt_network.trunk_net.name}"}
}

# Slave nodes (Controllers and computes)
variable "num_slaves" {
  default = 6
}

resource "libvirt_volume" "slave_vol" {
  name = "${var.prefix}-slave_vol-${count.index}"
  pool = "images"
  size = "${100 * 1024 * 1024 * 1024}"
  count = "${var.num_slaves}"
}

resource "libvirt_domain" "slave" {
  name = "${var.prefix}-slave-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.slave_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.adm_net.name}"}
  network_interface {network_name = "${libvirt_network.trunk_net.name}"}
  count = "${var.num_slaves}"
}

# Ceph nodes
variable "num_ceph" {
  default = 6
}

resource "libvirt_volume" "ceph_vol_os" {
  name = "${var.prefix}-ceph_vol_os-${count.index}"
  pool = "images"
  size = "${100 * 1024 * 1024 * 1024}"
  count = "${var.num_ceph}"
}

resource "libvirt_volume" "ceph_vol_1" {
  name = "${var.prefix}-ceph_vol_1-${count.index}"
  pool = "images"
  size = "${100 * 1024 * 1024 * 1024}"
  count = "${var.num_ceph}"
}

resource "libvirt_volume" "ceph_vol_2" {
  name = "${var.prefix}-ceph_vol_2-${count.index}"
  pool = "images"
  size = "${100 * 1024 * 1024 * 1024}"
  count = "${var.num_ceph}"
}

resource "libvirt_domain" "ceph" {
  name = "${var.prefix}-ceph-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.ceph_vol_os.*.id, count.index)}"}
  disk {volume_id = "${element(libvirt_volume.ceph_vol_1.*.id, count.index)}"}
  disk {volume_id = "${element(libvirt_volume.ceph_vol_2.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.adm_net.name}"}
  network_interface {network_name = "${libvirt_network.trunk_net.name}"}
  count = "${var.num_ceph}"
}
