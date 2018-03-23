locals {
  network_route_tpl = "[Route]\nDestination=%s\nGatewayOnLink=yes\nRouteMetric=3\nScope=link\nProtocol=kernel"
}

data "ignition_systemd_unit" "hostname_metadata_service" {
  name    = "hostname-metadata.service"
  enabled = true
  content = <<CONTENT
[Unit]
Description=Set hostname from platform metadata

[Service]
Type=oneshot
ExecStart=/usr/bin/coreos-metadata --provider=ec2 --hostname=/etc/hostname
ExecStartPost=/bin/sh -c 'hostnamectl --transient set-hostname $(cat /etc/hostname)'

[Install]
WantedBy=network.target
CONTENT
}

data "ignition_systemd_unit" "coreos-metadata-sshkeys-dropin" {
  name = "coreos-metadata-sshkeys@.service"
  enabled = true
  dropin {
    name = "10-openstack.conf"
    content = <<CONTENT
[Service]
Environment=COREOS_METADATA_OPT_PROVIDER=--provider=ec2
CONTENT
  }
}

data "ignition_file" "cfssl-conf" {
  count      = "${var.count}"
  filesystem = "root"
  mode       = "0644"
  path       = "/etc/sysconfig/cfssl.conf"

  content {
    content = "${module.cfssl.conf}"
  }
}

data "ignition_file" "etcd-conf" {
  count      = "${var.count}"
  filesystem = "root"
  mode       = "0644"
  path       = "/etc/sysconfig/etcd.conf"

  content {
    content = "${module.etcd.conf[count.index]}"
  }
}

data "ignition_file" "cacert" {
  count      = "${var.cacert != "" ? 1 : 0}"
  filesystem = "root"
  path       = "/etc/ssl/certs/cacert.pem"
  mode       = "0644"

  content {
    content = "${var.cacert}"
  }
}

data "ignition_file" "cfssl-cacert" {
  filesystem = "root"
  path       = "/opt/cfssl/cacert/ca.pem"
  mode       = "0644"

  content {
    content = "${var.cacert}"
  }
}

data "ignition_file" "cfssl-cakey" {
  filesystem = "root"
  path       = "/opt/cfssl/cacert/ca-key.pem"
  mode       = "0600"
  uid        = "1011"

  content {
    content = "${var.cacert_key}"
  }
}

data "ignition_networkd_unit" "eth0" {
  name = "10-eth0.network"

  content = <<IGNITION
[Match]
Name=eth0
[Network]
DHCP=ipv4
${format(local.network_route_tpl, var.host_cidr)}
[DHCP]
RouteMetric=2048
IGNITION
}

data "ignition_networkd_unit" "eth1" {
  name = "10-eth1.network"

  content = <<IGNITION
[Match]
Name=eth1
[Network]
DHCP=ipv4
[DHCP]
RouteMetric=2048
IGNITION
}

data "ignition_user" "core" {
  name                = "core"
  ssh_authorized_keys = ["${var.ssh_authorized_keys}"]
}

data "ignition_config" "coreos" {
  count = "${var.ignition_mode ? var.count : 0 }"
  users = ["${data.ignition_user.core.id}"]

  systemd = [
    "${data.ignition_systemd_unit.hostname_metadata_service.id}",
    "${data.ignition_systemd_unit.coreos-metadata-sshkeys-dropin.id}",
    # Added for k8s
    "${data.ignition_systemd_unit.docker_service.id}",
    "${data.ignition_systemd_unit.kubelet_service.id}",
    "${data.ignition_systemd_unit.k8s-init-service.id}",
    "${data.ignition_systemd_unit.etcd-get-certs-dropin.id}",
  ]

  networkd = [
    "${data.ignition_networkd_unit.eth0.id}",
    "${data.ignition_networkd_unit.eth1.id}",
  ]

  files = [
    "${data.ignition_file.cacert.*.id}",
    "${var.master_mode && var.etcd ? element(data.ignition_file.etcd-conf.*.id, count.index) :""}",

    "${var.master_mode && var.cfssl && var.cfssl_endpoint == "" && count.index == 0 ? data.ignition_file.cfssl-cacert.id : ""}",
    "${var.master_mode && var.cfssl && var.cfssl_endpoint == "" && count.index == 0 ? data.ignition_file.cfssl-cakey.id : ""}",
    "${var.master_mode && var.cfssl && var.cfssl_endpoint == "" && count.index == 0 ? element(data.ignition_file.cfssl-conf.*.id, 0) : ""}",
    # Added for k8s
    "${element(data.ignition_file.kubeconfig.*.id, count.index)}",
    "${data.ignition_file.cni-rbac.*.id}",
    "${data.ignition_file.cni-manifest.*.id}"
  ]
}
