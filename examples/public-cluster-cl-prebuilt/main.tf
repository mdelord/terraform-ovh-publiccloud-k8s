provider "openstack" {
  version   = "~> 1.2.0"
  region    = "${var.os_region_name}"
  tenant_id = "${var.os_tenant_id}"
  auth_url  = "${var.os_auth_url}"
}

data "http" "myip" {
  url = "https://api.ipify.org/"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${data.http.myip.body}/32"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = "${module.k8s.public_security_group_id}"
}

module "k8s" {
  source                    = "../.."
  region                    = "${var.os_region_name}"
  name                      = "${var.name}"
  count                     = "${var.count}"
  master_mode               = true
  master_as_worker          = true
  cfssl                     = true
  etcd                      = true
  post_install_modules      = false
  image_name                = "CoreOS Stable K8s"
  flavor_name               = "${var.os_flavor_name}"
  ignition_mode             = true
  ssh_authorized_keys       = ["${file("${var.public_sshkey}")}"]
  associate_public_ipv4     = true
  associate_private_ipv4    = false
}
