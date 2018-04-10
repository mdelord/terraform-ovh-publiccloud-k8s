locals {
  scheme = "${var.cfssl ? "https" : "http"}"
}

module "cfssl" {
  source  = "ovh/publiccloud-cfssl/ovh//modules/cfssl-userdata"
  version = ">= 0.1.3"

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
  domain               = "${var.domain}"
  datacenter           = "${var.datacenter}"
  cidr                 = "${var.host_cidr}"
  cfssl                = "${var.cfssl}"
  cfssl_endpoint       = "${var.cfssl_endpoint == "" ? module.cfssl.endpoint : var.cfssl_endpoint}"
  etcd_initial_cluster = "${var.etcd_initial_cluster}"
  ipv4_addrs           = ["${var.ipv4_addrs}"]
}

data "template_file" "kubelet_service" {
  template = <<TPL
[Service]
Environment=CLUSTER_DNS=${cidrhost(var.service_cidr, 10)}
Environment=CLUSTER_DOMAIN=${var.datacenter}.${var.domain}
TPL
}

data "template_file" "k8s_init_service" {
  template = <<TPL
[Service]
Environment=NETWORKING_DNS_DOMAIN=${var.datacenter}.${var.domain}
Environment=NETWORKING_SERVICE_SUBNET=${var.service_cidr}
Environment=NETWORKING_POD_SUBNET=${var.pod_cidr}
Environment=API_SERVER_CERT_SANS=${join(",", var.ipv4_addrs)}
Environment=MASTER_MODE=${var.master_mode}
Environment=WORKER_MODE=${var.worker_mode}
Environment=ETCD_ENDPOINTS=${module.etcd.etcd_endpoints}
Environment=API_ENDPOINT=${var.api_endpoint}
Environment=KUBEPROXY_CONFIG_MODE=iptables
Environment=AUTHORIZATION_MODES=Node,RBAC
TPL
}

data "template_file" "etcd_get_certs_service" {
template = <<TPL
[Service]
Environment=CFSSL_ENDPOINT=${var.cfssl_endpoint == "" ? module.cfssl.endpoint : var.cfssl_endpoint}
TPL
}
