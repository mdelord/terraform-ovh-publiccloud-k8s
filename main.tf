# Terraform version
terraform {
  required_version = ">= 0.10.4"
}

data "openstack_images_image_v2" "k8s" {
  count       = "${var.image_id == "" ? 1 : 0}"
  name        = "${var.image_name}"
  most_recent = true
}

data "openstack_networking_subnet_v2" "subnets" {
  count        = "${var.associate_private_ipv4 ? var.count : 0}"
  subnet_id    = "${length(var.subnet_ids) > 0 ? format("%s", element(var.subnet_ids, count.index)) : ""}"
  cidr         = "${length(var.subnets) > 0 && length(var.subnet_ids) < 1 ? format("%s", element(var.subnets, count.index)): ""}"
  ip_version   = 4
  dhcp_enabled = true
}

data "openstack_networking_network_v2" "ext_net" {
  name      = "Ext-Net"
  tenant_id = ""
}

resource "openstack_networking_secgroup_v2" "pub" {
  count       = "${var.associate_public_ipv4 ? 1 : 0}"
  name        = "${var.name}_pub_sg"
  description = "${var.name} security group for public ingress traffic on etcd hosts"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_etcd" {
  count             = "${var.associate_public_ipv4 ? var.count : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${format("%s/32", element(data.template_file.public_ipv4_addrs.*.rendered, count.index))}"
  port_range_min    = "2379"
  port_range_max    = "2380"
  security_group_id = "${openstack_networking_secgroup_v2.pub.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_cfssl" {
  count             = "${var.associate_public_ipv4 && var.cfssl && var.cfssl_endpoint == "" ? var.count : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${format("%s/32", element(data.template_file.public_ipv4_addrs.*.rendered, count.index))}"
  port_range_min    = "${var.cfssl_port}"
  port_range_max    = "${var.cfssl_port}"
  security_group_id = "${openstack_networking_secgroup_v2.pub.id}"
}

# auth all ports ; TODO filter only kube ports
resource "openstack_networking_secgroup_rule_v2" "in_traffic_k8s_tcp" {
  count             = "${var.associate_public_ipv4 ? var.count : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${format("%s/32", element(data.template_file.public_ipv4_addrs.*.rendered, count.index))}"
  security_group_id = "${openstack_networking_secgroup_v2.pub.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_k8s_udp" {
  count             = "${var.associate_public_ipv4 ? var.count : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_ip_prefix  = "${format("%s/32", element(data.template_file.public_ipv4_addrs.*.rendered, count.index))}"
  security_group_id = "${openstack_networking_secgroup_v2.pub.id}"
}

resource "openstack_networking_secgroup_rule_v2" "egress-ipv4" {
  count             = "${var.associate_public_ipv4 ? 1 : 0}"
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = "${openstack_networking_secgroup_v2.pub.id}"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_port_v2" "public_port_k8s" {
  count = "${var.associate_public_ipv4 ? var.count : 0}"
  name  = "${var.name}_public_${count.index}"

  network_id     = "${data.openstack_networking_network_v2.ext_net.id}"
  admin_state_up = "true"

  security_group_ids = [
    "${compact(concat(openstack_networking_secgroup_v2.pub.*.id, var.public_security_group_ids))}",
  ]
}

data "template_file" "public_ipv4_addrs" {
  count = "${var.associate_public_ipv4 ? var.count : 0}"

  # join all ips as string > remove every ipv6 > split & compact
  template = "${element(compact(split(",", replace(join(",", flatten(openstack_networking_port_v2.public_port_k8s.*.all_fixed_ips)), "/[[:alnum:]]+:[^,]+/", ""))), count.index)}"
}

# this is a hack to output ipv4 addrs only when instances are active
data "template_file" "ipv4_addrs" {
  count = "${var.associate_private_ipv4 ? var.count : 0}"

  # only ipv4 in address list as subnet is setup as ipv4 only
  template = "${element(flatten(openstack_networking_port_v2.port_k8s.*.all_fixed_ips), count.index)}"

  vars {
    k8s_id = "${element(data.template_file.instances_ids.*.rendered, count.index)}"
  }
}

resource "openstack_networking_port_v2" "port_k8s" {
  count = "${var.associate_private_ipv4 ? var.count : 0}"

  name           = "${var.name}_${count.index}"
  network_id     = "${element(data.openstack_networking_subnet_v2.subnets.*.network_id, count.index)}"
  admin_state_up = "true"

  fixed_ip {
    subnet_id = "${data.openstack_networking_subnet_v2.subnets.*.id[count.index]}"
  }
}

# create anti affinity groups of 3 nodes
resource "openstack_compute_servergroup_v2" "k8s" {
  count    = "${var.count > 0 ? 1 + var.count / 3 : 0}"
  name     = "${var.name}-${count.index}"
  policies = ["anti-affinity"]
}

module "userdata" {
  source               = "./modules/k8s-userdata"
  count                = "${var.count}"
  master_mode          = "${var.master_mode}"
  name                 = "${var.name}"
  ignition_mode        = "${var.ignition_mode}"
  domain               = "${var.domain}"
  datacenter           = "${var.datacenter}"
  region               = "${var.region}"
  host_cidr            = "${var.host_cidr}"
  service_cidr         = "${var.service_cidr}"
  pod_cidr             = "${var.pod_cidr}"
  cacert               = "${var.cacert}"
  cacert_key           = "${var.cacert_key}"
  cfssl                = "${var.cfssl}"
  cfssl_endpoint       = "${var.cfssl_endpoint}"
  etcd                 = "${var.etcd}"
  etcd_initial_cluster = "${var.etcd_initial_cluster}"

  # if private ipv4 addrs are set, prefer them over public addrs;
  # they will notably be used to set etcd_initial_cluster attr.
  ipv4_addrs = ["${coalescelist(flatten(openstack_networking_port_v2.port_k8s.*.all_fixed_ips), data.template_file.public_ipv4_addrs.*.rendered)}"]

  ssh_authorized_keys = ["${var.ssh_authorized_keys}"]
  cfssl_key_algo      = "${var.cfssl_key_algo}"
  cfssl_key_size      = "${var.cfssl_key_size}"
  cfssl_bind          = "${var.cfssl_bind}"
  cfssl_port          = "${var.cfssl_port}"

  master_as_worker = "${var.master_as_worker}"
}

resource "openstack_compute_instance_v2" "multinet_k8s" {
  count    = "${var.associate_public_ipv4 && var.associate_private_ipv4 ? var.count : 0}"
  name     = "${var.name}_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.k8s.*.id, list(var.image_id)), 0)}"

  flavor_name = "${var.flavor_name}"
  user_data   = "${element(module.userdata.rendered, count.index)}"

  network {
    port           = "${element(openstack_networking_port_v2.port_k8s.*.id, count.index)}"
  }

  # Important: orders of network declaration matters because public internet interface must be eth1
  network {
    access_network = true
    port = "${element(openstack_networking_port_v2.public_port_k8s.*.id, count.index)}"
  }

  scheduler_hints {
    group = "${element(openstack_compute_servergroup_v2.k8s.*.id, count.index / 3 )}"
  }

  metadata = "${merge(map("k8s_master_mode", var.master_mode), var.metadata)}"
}

resource "openstack_compute_instance_v2" "singlenet_k8s" {
  count    = "${! (var.associate_public_ipv4 && var.associate_private_ipv4) ? var.count : 0}"
  name     = "${var.name}_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.k8s.*.id, list(var.image_id)), 0)}"

  flavor_name = "${var.flavor_name}"
  user_data   = "${element(module.userdata.rendered, count.index)}"

  network {
    access_network = true
    port           = "${element(coalescelist(openstack_networking_port_v2.public_port_k8s.*.id,openstack_networking_port_v2.port_k8s.*.id), count.index)}"
  }

  scheduler_hints {
    group = "${element(openstack_compute_servergroup_v2.k8s.*.id, count.index / 3 )}"
  }

  metadata = "${merge(map("k8s_master_mode", var.master_mode), var.metadata)}"
}


module "post_install_cfssl" {
  source  = "ovh/publiccloud-cfssl/ovh//modules/install-cfssl"
  version = ">= 0.1.3"

  count                   = "${var.post_install_modules && var.cfssl && var.cfssl_endpoint == "" && var.count >= 1 ? 1 : 0}"
  triggers                = ["${element(concat(openstack_compute_instance_v2.singlenet_k8s.*.id, openstack_compute_instance_v2.multinet_k8s.*.id), 0)}"]
  ipv4_addrs              = ["${element(concat(openstack_compute_instance_v2.singlenet_k8s.*.access_ip_v4, openstack_compute_instance_v2.multinet_k8s.*.access_ip_v4), 0)}"]
  ssh_user                = "${var.ssh_user}"
  ssh_bastion_host        = "${var.ssh_bastion_host}"
  ssh_bastion_user        = "${var.ssh_bastion_user}"
}

module "post_install_etcd" {
  source  = "ovh/publiccloud-etcd/ovh//modules/install-etcd"
  version = ">= 0.1.1"

  count                   = "${var.post_install_modules && var.etcd ? var.count : 0}"
  triggers                = ["${concat(openstack_compute_instance_v2.singlenet_k8s.*.id, openstack_compute_instance_v2.multinet_k8s.*.id)}"]
  ipv4_addrs              = ["${concat(openstack_compute_instance_v2.singlenet_k8s.*.access_ip_v4, openstack_compute_instance_v2.multinet_k8s.*.access_ip_v4)}"]
  ssh_user                = "${var.ssh_user}"
  ssh_bastion_host        = "${var.ssh_bastion_host}"
  ssh_bastion_user        = "${var.ssh_bastion_user}"
}

module "post_install_k8s" {
  source                  = "./modules/install-k8s"
  count                   = "${var.post_install_modules ? var.count : 0}"
  triggers                = ["${concat(openstack_compute_instance_v2.singlenet_k8s.*.id, openstack_compute_instance_v2.multinet_k8s.*.id)}"]
  ipv4_addrs              = ["${concat(openstack_compute_instance_v2.singlenet_k8s.*.access_ip_v4, openstack_compute_instance_v2.multinet_k8s.*.access_ip_v4)}"]
  ssh_user                = "${var.ssh_user}"
  ssh_bastion_host        = "${var.ssh_bastion_host}"
  ssh_bastion_user        = "${var.ssh_bastion_user}"
}

# This is somekind of a hack to ensure that when instances ids are output and made
# available to other resources outside the module, the node has been fully provisionned
data "template_file" "instances_ids" {
  count    = "${var.count}"
  template = "$${id}"

  vars {
    id = "${element(coalescelist(openstack_compute_instance_v2.singlenet_k8s.*.id, openstack_compute_instance_v2.multinet_k8s.*.id), count.index)}"

    install_k8s_id   = "${element(coalescelist(module.post_install_k8s.install_ids, list("")), count.index)}"
    install_cfssl_id = "${module.post_install_cfssl.install_id}"
    install_etcd_id  = "${element(coalescelist(module.post_install_etcd.install_ids, list("")), count.index)}"
  }
}

data "template_file" "public_ipv4_dns" {
  count    = "${var.associate_public_ipv4 ? var.count : 0}"
  template = "ip$${ip4}.ip-$${ip1}-$${ip2}-$${ip3}.$${domain}"

  vars {
    id     = "${element(data.template_file.instances_ids.*.rendered, count.index)}"
    ip1    = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 0)}"
    ip2    = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 1)}"
    ip3    = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 2)}"
    ip4    = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 3)}"
    domain = "${lookup(var.ip_dns_domains, var.region, var.default_ip_dns_domains)}"
  }
}
