locals {
  network_route_tpl = "[Route]\nDestination=%s\nGatewayOnLink=yes\nRouteMetric=3\nScope=link\nProtocol=kernel"
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
    "${var.master_mode && var.etcd ? element(data.ignition_file.etcd-conf.*.id, count.index) :""}",

    # Added for k8s
    "${element(data.ignition_file.hostname.*.id, count.index)}",
    "${element(data.ignition_file.kubeconfig.*.id, count.index)}",
    "${data.ignition_file.cni-rbac.*.id}",
    "${data.ignition_file.cni-manifest.*.id}"
  ]
}
