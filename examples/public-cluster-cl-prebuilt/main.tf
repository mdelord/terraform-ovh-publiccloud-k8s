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


resource "openstack_networking_secgroup_rule_v2" "in_traffic_k8s_sg" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${data.http.myip.body}/32"
  port_range_min    = 6443
  port_range_max    = 6443
  security_group_id = "${module.k8s_secgroups.master_group_id}"
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

module "k8s" {
  source                 = "../.."
  region                 = "${var.os_region_name}"
  name                   = "${var.name}"
  count                  = "${var.count}"
  master_mode            = true
  worker_mode            = true
  cfssl                  = true
  etcd                   = true
  flavor_name            = "${var.os_flavor_name}"
  security_group_ids     = ["${module.k8s_secgroups.master_group_id}", "${module.k8s_secgroups.worker_group_id}"]
  ssh_authorized_keys    = ["${file("${var.public_sshkey}")}"]
  associate_public_ipv4  = true
  associate_private_ipv4 = false
}
