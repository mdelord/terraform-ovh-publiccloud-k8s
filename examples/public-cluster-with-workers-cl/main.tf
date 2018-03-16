provider "openstack" {
  version   = "~> 1.2.0"
  region    = "${var.os_region_name}"
  tenant_id = "${var.os_tenant_id}"
  auth_url  = "${var.os_auth_url}"
}

data "http" "myip" {
  url = "https://api.ipify.org/"
}

module "k8s_secgroups" {
  source = "../../modules/k8s-secgroups"
  name   = "${var.name}"
  etcd   = true
  cfssl  = true
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_ssh_master" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${data.http.myip.body}/32"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = "${module.k8s_secgroups.master_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_ssh_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${data.http.myip.body}/32"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = "${module.k8s_secgroups.worker_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s-api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${data.http.myip.body}/32"
  port_range_min    = 6443
  port_range_max    = 6443
  security_group_id = "${module.k8s_secgroups.master_group_id}"
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
  security_group_ids     = ["${module.k8s_secgroups.master_group_id}"]
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
  security_group_ids     = ["${module.k8s_secgroups.worker_group_id}"]
  associate_public_ipv4  = true
  associate_private_ipv4 = false

  # TODO: replace this by a DNS entry to round robin on masters IP
  api_endpoint = "${format("%s:6443", element(module.k8s_masters.public_ipv4_addrs, 1))}"
}
