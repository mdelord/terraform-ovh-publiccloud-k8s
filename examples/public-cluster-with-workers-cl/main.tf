provider "openstack" {
  version   = "~> 1.2.0"
  region    = "${var.os_region_name}"
  tenant_id = "${var.os_tenant_id}"
  auth_url  = "${var.os_auth_url}"
}

data "http" "myip" {
  url = "https://api.ipify.org/"
}

resource "openstack_networking_secgroup_v2" "sg" {
  name        = "${var.name}_ssh_sg"
  description = "${var.name} security group for k8s provisionning"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${data.http.myip.body}/32"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = "${openstack_networking_secgroup_v2.sg.id}"
}

module "k8s_masters" {
  source                 = "../.."
  region                 = "${var.os_region_name}"
  name                   = "${var.name}_master"
  count                  = "${var.masters_count}"
  master_mode            = true
  worker_mode            = false
  cfssl                  = true
  etcd                   = true
  post_install_modules   = true
  image_name             = "CoreOS Stable"
  flavor_name            = "${var.os_flavor_name_masters}"
  ignition_mode          = true
  ssh_user               = "core"
  ssh_authorized_keys    = ["${file("${var.public_sshkey}")}"]
  ssh_security_group_id  = "${openstack_networking_secgroup_v2.sg.id}"
  associate_public_ipv4  = true
  associate_private_ipv4 = false
}

module "k8s_workers" {
  source                 = "../.."
  region                 = "${var.os_region_name}"
  name                   = "${var.name}_worker"
  count                  = "${var.workers_count}"
  master_mode            = false
  worker_mode            = true
  cfssl                  = false
  cfssl_endpoint         = "${module.k8s_masters.cfssl_endpoint}"
  etcd                   = true
  etcd_endpoints         = "${join(",", formatlist("https://%s:2379", module.k8s_masters.public_ipv4_addrs))}"
  post_install_modules   = true
  image_name             = "CoreOS Stable"
  flavor_name            = "${var.os_flavor_name_workers}"
  ignition_mode          = true
  ssh_user               = "core"
  ssh_authorized_keys    = ["${file("${var.public_sshkey}")}"]
  ssh_security_group_id  = "${openstack_networking_secgroup_v2.sg.id}"
  associate_public_ipv4  = true
  associate_private_ipv4 = false
  custom_security_group  = true
  security_group_id      = "${module.k8s_masters.security_group_id}"
  # TODO: replace this by a DNS entry to round robin on masters IP
  api_endpoint           = "${format("%s:6443", element(module.k8s_masters.public_ipv4_addrs, 1))}"
}
