# Terraform version
terraform {
  required_version = ">= 0.10.4"
}

data "openstack_images_image_v2" "k8s" {
  name = "${var.image_name}"
  most_recent = true
}

data "openstack_networking_network_v2" "ext_net" {
  name = "Ext-Net"
  tenant_id = ""
}

data "template_file" "public_ipv4_addrs" {
  count = "${var.count}"
  # join all ips as string > remove every ipv6 > split & compact
  template = "${element(compact(split(",", replace(join(",", flatten(openstack_networking_port_v2.public_port_k8s.*.all_fixed_ips)), "/[[:alnum:]]+:[^,]+/", ""))), count.index)}"
}

resource "openstack_networking_port_v2" "public_port_k8s" {
  count = "${var.count}"
  name = "${var.name}_public_${count.index}"
  network_id = "${data.openstack_networking_network_v2.ext_net.id}"
  admin_state_up = true
  security_group_ids = ["${var.security_group_ids}"]
}

# create anti affinity groups of 3 nodes
resource "openstack_compute_servergroup_v2" "k8s" {
  count = "${var.count > 0 ? 1 + var.count / 3 : 0}"
  name = "${var.name}-${count.index}"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "k8s" {
  count = "${var.count}"
  name = "${var.name}_${count.index}"
  image_id = "${element(data.openstack_images_image_v2.k8s.*.id, 0)}"
  flavor_name = "${var.flavor_name}"
  user_data = "${element(module.userdata.rendered, count.index)}"
  network {
    access_network = true
    port = "${element(openstack_networking_port_v2.public_port_k8s.*.id, count.index)}"
  }
  scheduler_hints {
    group = "${element(openstack_compute_servergroup_v2.k8s.*.id, count.index / 3 )}"
  }
}

module "userdata" {
  source = "./modules/k8s-userdata"
  count = "${var.count}"
  master_mode = "${var.master_mode}"
  name = "${var.name}"
  domain = "${var.domain}"
  datacenter = "${var.datacenter}"
  region = "${var.region}"
  host_cidr = "${var.host_cidr}"
  service_cidr = "${var.service_cidr}"
  pod_cidr = "${var.pod_cidr}"
  cacert = "${var.cacert}"
  cacert_key = "${var.cacert_key}"
  cfssl = "${var.cfssl}"
  cfssl_endpoint = "${var.cfssl_endpoint}"
  etcd = "${var.etcd}"
  etcd_initial_cluster = "${var.etcd_initial_cluster}"
  etcd_endpoints = "${var.etcd_endpoints}"
  ipv4_addrs = "${data.template_file.public_ipv4_addrs.*.rendered}"
  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  cfssl_key_algo = "${var.cfssl_key_algo}"
  cfssl_key_size = "${var.cfssl_key_size}"
  cfssl_bind = "${var.cfssl_bind}"
  cfssl_port = "${var.cfssl_port}"
  api_endpoint = "${var.api_endpoint}"
  worker_mode = "${var.worker_mode}"
}

module "post_install_cfssl" {
  source  = "ovh/publiccloud-cfssl/ovh//modules/install-cfssl"
  version = ">= 0.1.3"
  count = "${var.post_install_modules && var.cfssl && var.count >= 1 ? 1 : 0}"
  triggers = ["${element(openstack_compute_instance_v2.k8s.*.id, 0)}"]
  ipv4_addrs = ["${element(openstack_compute_instance_v2.k8s.*.access_ip_v4, 0)}"]
  ssh_user = "${var.ssh_user}"
}

module "post_install_etcd" {
  source  = "ovh/publiccloud-etcd/ovh//modules/install-etcd"
  version = "0.1.2"
  count = "${var.post_install_modules && var.etcd ? var.count : 0}"
  triggers = ["${openstack_compute_instance_v2.k8s.*.id}"]
  ipv4_addrs = ["${openstack_compute_instance_v2.k8s.*.access_ip_v4}"]
  ssh_user = "${var.ssh_user}"
}

module "post_install_k8s" {
  source = "./modules/install-k8s"
  count = "${var.post_install_modules ? var.count : 0}"
  triggers = ["${openstack_compute_instance_v2.k8s.*.id}"]
  ipv4_addrs = ["${openstack_compute_instance_v2.k8s.*.access_ip_v4}"]
  ssh_user = "${var.ssh_user}"
}

# This is somekind of a hack to ensure that when instances ids are output and made
# available to other resources outside the module, the node has been fully provisionned
data "template_file" "instances_ids" {
  count = "${var.count}"
  template = "$${id}"
  vars {
    id = "${element(openstack_compute_instance_v2.k8s.*.id, count.index)}"
    install_k8s_id = "${element(coalescelist(module.post_install_k8s.install_ids, list("")), count.index)}"
    install_cfssl_id = "${module.post_install_cfssl.install_id}"
    install_etcd_id = "${element(coalescelist(module.post_install_etcd.install_ids, list("")), count.index)}"
  }
}

data "template_file" "public_ipv4_dns" {
  count = "${var.count}"
  template = "ip$${ip4}.ip-$${ip1}-$${ip2}-$${ip3}.$${domain}"
  vars {
    id = "${element(data.template_file.instances_ids.*.rendered, count.index)}"
    ip1 = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 0)}"
    ip2 = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 1)}"
    ip3 = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 2)}"
    ip4 = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 3)}"
    domain = "${lookup(var.ip_dns_domains, var.region, var.default_ip_dns_domains)}"
  }
}
