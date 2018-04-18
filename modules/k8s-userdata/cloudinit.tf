locals {
  ip_route_add_tpl   = "- ip route add %s dev %s scope link metric 0"
  eth_route_tpl      = "%s dev %s scope link metric 0"
  networkd_route_tpl = "[Route]\nDestination=%s\nGatewayOnLink=yes\nRouteMetric=3\nScope=link\nProtocol=kernel"
}

data "template_file" "cfssl_ca_files" {
  template = <<TPL
- path: /opt/cfssl/cacert/ca.pem
  permissions: '0644'
  owner: cfssl:cfssl
  content: |
     ${indent(5, var.cacert)}
- path: /opt/cfssl/cacert/ca-key.pem
  permissions: '0600'
  owner: cfssl:cfssl
  content: |
     ${indent(5, var.cacert_key)}
TPL
}

data "template_file" "systemd_network_files" {
  template = <<TPL
- path: /etc/systemd/network/10-eth0.network
  permissions: '0644'
  content: |
    [Match]
    Name=eth0
    [Network]
    DHCP=ipv4
    ${indent(4, format(local.networkd_route_tpl, var.host_cidr))}
    [DHCP]
    RouteMetric=2048
- path: /etc/systemd/network/20-eth1.network
  permissions: '0644'
  content: |
    [Match]
    Name=eth1
    [Network]
    DHCP=ipv4
    [DHCP]
    RouteMetric=2048
TPL
}

data "template_file" "cfssl_conf" {
  template = <<TPL
- path: /etc/sysconfig/cfssl.conf
  mode: 0644
  content: |
    ${indent(4, module.cfssl.conf)}
TPL
}

data "template_file" "etcd_conf" {
  count = "${var.count}"

  template = <<TPL
- path: /etc/sysconfig/etcd.conf
  mode: 0644
  content: |
    ${indent(4, module.etcd.conf[count.index])}
TPL
}

data "template_file" "kubernetes_conf" {
  template = <<TPL
- path: /etc/sysconfig/kubernetes.conf
  mode: 0644
  content: |
    ${indent(4, data.template_file.k8s_vars.rendered)}
TPL
}

data "template_file" "cfssl_files" {
  template = <<TPL
${var.cacert != "" && var.cacert_key != "" ? data.template_file.cfssl_ca_files.rendered : ""}
${data.template_file.cfssl_conf.rendered}
TPL
}

# Render a multi-part cloudinit config making use of the part
# above, and other source files
data "template_file" "config" {
  count = "${var.count}"

  template = <<CLOUDCONFIG
#cloud-config
ssh_authorized_keys:
  ${length(var.ssh_authorized_keys) > 0 ? indent(2, join("\n", formatlist("- %s", var.ssh_authorized_keys))) : ""}
## This route has to be added in order to reach other subnets of the network
write_files:
  ${var.master_mode && var.cfssl && var.cfssl_endpoint == "" && count.index == 0 ? indent(2, element(data.template_file.cfssl_files.*.rendered, count.index)) : ""}
  ${var.master_mode && var.etcd ? indent(2, element(data.template_file.etcd_conf.*.rendered, count.index)) : ""}
  ${indent(2, data.template_file.kubernetes_conf.rendered)}
  ${indent(2, data.template_file.systemd_network_files.rendered)}
  - path: /etc/sysconfig/network-scripts/route-eth0
    content: |
      ${indent(6, format(local.eth_route_tpl, var.host_cidr, "eth0"))}
CLOUDCONFIG
}
