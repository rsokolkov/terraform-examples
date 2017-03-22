# Please use fork of terraform provider libvirt
# https://github.com/rsokolkov/terraform-provider-libvirt/tree/feature_dhcp_on_off

provider "libvirt" {
  uri = "qemu+ssh://root@pdt2/system"
}

# Common variables
variable "prefix" {
  default = "rs-mcp"
}

variable "size" {
  # 100G
  default = "107374182400"
}

# Common resources
# NOTE: routable
resource "libvirt_network" "pxe" {
  name = "${var.prefix}-pxe"
  addresses = ["10.10.0.0/24"]
  mode = "nat"
  dhcp = false
}

# NOTE: routable and /29
resource "libvirt_network" "proxy" {
  name = "${var.prefix}-proxy"
  addresses = ["10.10.1.0/29"]
  mode = "nat"
  dhcp = false
}

# NOTE: routable and default gateway probably
resource "libvirt_network" "control" {
  name = "${var.prefix}-control"
  addresses = ["10.10.2.0/24"]
  mode = "nat"
  dhcp = false
}

# NOTE: 10.10.3.0/24
resource "libvirt_network" "data" {
  name = "${var.prefix}-data"
  mode = "none"
  dhcp = false
}

# NOTE: 10.10.4.0/24
resource "libvirt_network" "storage-access" {
  name = "${var.prefix}-storage-access"
  mode = "none"
  dhcp = false
}

# NOTE: 10.10.5.0/24
resource "libvirt_network" "storage-repl" {
  name = "${var.prefix}-storage-repl"
  mode = "none"
  dhcp = false
}

# Salt MAAS node
resource "libvirt_volume" "salt-maas_vol" {
  name = "${var.prefix}-vol-salt_vol"
  pool = "images"
  size = "${var.size}"
}

resource "libvirt_domain" "salt-maas" {
  name = "${var.prefix}-salt-maas"
  vcpu = 1
  memory = 4096
  running = false
  disk {volume_id = "${libvirt_volume.salt-maas_vol.id}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
}

# Rabbit
variable "num_rabbit" {
  default = 3
}

resource "libvirt_volume" "rabbit_vol" {
  name = "${var.prefix}-rabbit_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_rabbit}"
}

resource "libvirt_domain" "rabbit" {
  name = "${var.prefix}-rabbit-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.rabbit_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  count = "${var.num_rabbit}"
}

# Mysql
variable "num_mysql" {
  default = 3
}

resource "libvirt_volume" "mysql_vol" {
  name = "${var.prefix}-mysql_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_mysql}"
}

resource "libvirt_domain" "mysql" {
  name = "${var.prefix}-mysql-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.mysql_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  count = "${var.num_mysql}"
}

# Contrail
variable "num_contrail" {
  default = 3
}

resource "libvirt_volume" "contrail_vol" {
  name = "${var.prefix}-contrail_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_contrail}"
}

resource "libvirt_domain" "contrail" {
  name = "${var.prefix}-contrail-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.contrail_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  network_interface {network_name = "${libvirt_network.data.name}"}
  count = "${var.num_contrail}"
}

# LMA
variable "num_lma" {
  default = 3
}

resource "libvirt_volume" "lma_vol" {
  name = "${var.prefix}-lma_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_lma}"
}

resource "libvirt_domain" "lma" {
  name = "${var.prefix}-lma-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.lma_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  count = "${var.num_lma}"
}

# Dash
variable "num_dash" {
  default = 2
}

resource "libvirt_volume" "dash_vol" {
  name = "${var.prefix}-dash_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_dash}"
}

resource "libvirt_domain" "dash" {
  name = "${var.prefix}-dash-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.dash_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  network_interface {network_name = "${libvirt_network.proxy.name}"}
  count = "${var.num_dash}"
}

# Controller
variable "num_controller" {
  default = 3
}

resource "libvirt_volume" "controller_vol" {
  name = "${var.prefix}-controller_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_controller}"
}

resource "libvirt_domain" "controller" {
  name = "${var.prefix}-controller-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.controller_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  network_interface {network_name = "${libvirt_network.proxy.name}"}
  network_interface {network_name = "${libvirt_network.storage-access.name}"}
  count = "${var.num_controller}"
}

# Gluster
variable "num_gluster" {
  default = 3
}

resource "libvirt_volume" "gluster_vol" {
  name = "${var.prefix}-gluster_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_gluster}"
}

resource "libvirt_domain" "gluster" {
  name = "${var.prefix}-gluster-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.gluster_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  count = "${var.num_gluster}"
}

# Ceph
variable "num_ceph" {
  default = 5
}

resource "libvirt_volume" "ceph_vol" {
  name = "${var.prefix}-ceph_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_ceph}"
}

resource "libvirt_domain" "ceph" {
  name = "${var.prefix}-ceph-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.ceph_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  network_interface {network_name = "${libvirt_network.storage-access.name}"}
  network_interface {network_name = "${libvirt_network.storage-repl.name}"}
  count = "${var.num_ceph}"
}

# Compute
variable "num_compute" {
  default = 3
}

resource "libvirt_volume" "compute_vol" {
  name = "${var.prefix}-compute_vol-${count.index}"
  pool = "images"
  size = "${var.size}"
  count = "${var.num_compute}"
}

resource "libvirt_domain" "compute" {
  name = "${var.prefix}-compute-${count.index}"
  vcpu = 1
  memory = 3072
  running = false
  disk {volume_id = "${element(libvirt_volume.compute_vol.*.id, count.index)}"}
  network_interface {network_name = "${libvirt_network.pxe.name}"}
  network_interface {network_name = "${libvirt_network.control.name}"}
  network_interface {network_name = "${libvirt_network.data.name}"}
  network_interface {network_name = "${libvirt_network.storage-access.name}"}
  count = "${var.num_compute}"
}
