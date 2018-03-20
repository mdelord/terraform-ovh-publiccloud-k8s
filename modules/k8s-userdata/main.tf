locals {
  scheme = "${var.cfssl ? "https" : "http"}"
}

module "cfssl" {
  source  = "ovh/publiccloud-cfssl/ovh//modules/cfssl-userdata"
  version = ">= 0.1.3"

  ignition_mode        = "${var.ignition_mode}"
  cidr                 = "${var.host_cidr}"
  ssh_authorized_keys  = ["${var.ssh_authorized_keys}"]
  ipv4_addr            = "${element(var.ipv4_addrs,0)}"
  cacert               = "${var.cacert}"
  cacert_key           = "${var.cacert_key}"
  ca_validity_period   = "${var.cfssl_ca_validity_period}"
  cert_validity_period = "${var.cfssl_cert_validity_period}"
  cn                   = "${var.domain}"
  c                    = "${var.region}"
  l                    = "${var.datacenter}"
  o                    = "${var.name}"
  key_algo             = "${var.cfssl_key_algo}"
  key_size             = "${var.cfssl_key_size}"
  bind                 = "${var.cfssl_bind}"
  port                 = "${var.cfssl_port}"
}

module "etcd" {
  source  = "ovh/publiccloud-etcd/ovh//modules/etcd-userdata"
  version = "0.1.2"
  count                = "${var.count}"
  name                 = "${var.name}"
  ignition_mode        = "${var.ignition_mode}"
  domain               = "${var.domain}"
  datacenter           = "${var.datacenter}"
  cidr                 = "${var.host_cidr}"
  cfssl                = "${var.cfssl}"
  cfssl_endpoint       = "${module.cfssl.endpoint}"
  etcd_initial_cluster = "${var.etcd_initial_cluster}"
  ipv4_addrs           = ["${var.ipv4_addrs}"]
}
