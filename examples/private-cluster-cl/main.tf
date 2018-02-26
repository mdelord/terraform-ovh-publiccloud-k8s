provider "openstack" {
  version   = "~> 1.2.0"
  region    = "${var.os_region_name}"
  tenant_id = "${var.os_tenant_id}"
  auth_url  = "${var.os_auth_url}"
}

module "network" {
  source  = "ovh/publiccloud-network/ovh"
  version = ">= 0.1.0"

  name   = "${var.name}"
  cidr   = "${var.cidr}"
  region = "${var.os_region_name}"

  # one public subnet for nats & bastion instances
  public_subnets = ["${cidrsubnet(var.cidr, 4, 0)}"]

  # one priv for cfssl private instance
  private_subnets    = ["${cidrsubnet(var.cidr, 4, 1)}"]
  enable_nat_gateway = true
  single_nat_gateway = true
  nat_as_bastion     = true
  ssh_public_keys    = ["${file("${var.public_sshkey}")}"]
}

module "k8s" {
  source                  = "../.."
  region                  = "${var.os_region_name}"
  name                    = "${var.name}"
  count                   = "${var.count}"
  master_mode             = true
  master_as_worker        = true
  host_cidr               = "${var.cidr}"
  cfssl                   = true
  etcd                    = true
  post_install_modules    = true
  image_name              = "CoreOS Stable"
  subnet_ids              = ["${module.network.private_subnets[0]}"]
  flavor_name             = "${var.os_flavor_name}"
  ignition_mode           = true
  ssh_user                = "core"
  ssh_authorized_keys     = ["${file("${var.public_sshkey}")}"]
  ssh_private_key         = "${file("${var.private_sshkey}")}"
  ssh_bastion_private_key = "${file("${var.private_sshkey}")}"
  ssh_bastion_host        = "${module.network.bastion_public_ip}"
  ssh_bastion_user        = "core"
  associate_public_ipv4   = false
  associate_private_ipv4  = true
}
