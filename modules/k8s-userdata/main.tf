module "etcd" {
  source  = "ovh/publiccloud-etcd/ovh//modules/etcd-userdata"
  version = "0.1.2"
  count                = "${var.count}"
  name                 = "${var.name}"
  domain               = "${var.domain}"
  datacenter           = "${var.datacenter}"
  cidr                 = "${var.host_cidr}"
  etcd_initial_cluster = "${var.etcd_initial_cluster}"
  ipv4_addrs           = ["${var.ipv4_addrs}"]
}
