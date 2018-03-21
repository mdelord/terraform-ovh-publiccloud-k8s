provider "openstack" {
  version   = "~> 1.2.0"
  region    = "${var.os_region_name}"
  tenant_id = "${var.os_tenant_id}"
  auth_url  = "${var.os_auth_url}"
}

module "k8s_secgroups" {
  source = "../../modules/k8s-secgroups"
  name   = "${var.name}"
  etcd   = true
  cfssl  = true
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_ssh_master" {
  count             = "${length(var.authorized_ips)}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${element(var.authorized_ips, count.index)}"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = "${module.k8s_secgroups.master_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_ssh_worker" {
  count             = "${length(var.authorized_ips)}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${element(var.authorized_ips, count.index)}"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = "${module.k8s_secgroups.worker_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s-api" {
  count             = "${length(var.authorized_ips)}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${element(var.authorized_ips, count.index)}"
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
  etcd_endpoints         = "${module.k8s_masters.etcd_endpoints}"
  post_install_modules   = true
  image_name             = "CoreOS Stable"
  flavor_name            = "${var.os_flavor_name_workers}"
  ignition_mode          = true
  ssh_user               = "core"
  ssh_authorized_keys    = ["${file("${var.public_sshkey}")}"]
  security_group_ids     = ["${module.k8s_secgroups.worker_group_id}"]
  associate_public_ipv4  = true
  associate_private_ipv4 = false
  api_endpoint           = "${module.k8s_masters.api_endpoint}"
}
