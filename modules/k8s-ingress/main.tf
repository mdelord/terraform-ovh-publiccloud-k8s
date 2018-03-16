resource "openstack_networking_secgroup_rule_v2" "in_traffic_etcd_peer" {
  count             = "${var.etcd_peer ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "2380"
  port_range_max    = "2380"
  remote_group_id   = "${var.remote_group_id}"
  security_group_id = "${var.security_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_etcd_client" {
  count             = "${var.etcd_client ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "2379"
  port_range_max    = "2379"
  remote_group_id   = "${var.remote_group_id}"
  security_group_id = "${var.security_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_cfssl" {
  count             = "${var.cfssl ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "${var.cfssl_port}"
  port_range_max    = "${var.cfssl_port}"
  remote_group_id   = "${var.remote_group_id}"
  security_group_id = "${var.security_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  count             = "${var.ping ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = "${var.remote_group_id}"
  security_group_id = "${var.security_group_id}"
}

### kubernetes networking based on https://github.com/coreos/coreos-kubernetes/blob/master/Documentation/kubernetes-networking.md

resource "openstack_networking_secgroup_rule_v2" "flannel_vxlan" {
  count             = "${(var.flannel_vxlan || var.canal) && (var.master_to_master || var.worker_to_master || var.worker_to_worker || var.master_to_worker)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "flannel_udp" {
  count             = "${var.flannel_udp && (var.master_to_master || var.worker_to_master || var.worker_to_worker || var.master_to_worker)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8285
  port_range_max    = 8285
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "worker-exporter" {
  count             = "${(var.master_to_master || var.worker_to_master || var.worker_to_worker || var.master_to_worker)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9100
  port_range_max    = 9100
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "api-server" {
  count             = "${var.worker_to_master || var.master_to_master ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet" {
  count             = "${var.master_to_worker? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet-heapster" {
  count             = "${( var.worker_to_worker || var.master_to_worker)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10254
  port_range_max    = 10254
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet-read" {
  count             = "${(var.worker_to_worker || var.master_to_worker)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10255
  port_range_max    = 10255
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "calico-bgp" {
  count             = "${var.calico_bgp && (var.master_to_master || var.worker_to_master || var.worker_to_worker || var.master_to_worker)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "apps" {
  count             = "${var.worker_to_worker? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "ipip" {
  count             = "${var.canal && (var.master_to_master || var.worker_to_master || var.worker_to_worker || var.master_to_worker)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "4"
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}

resource "openstack_networking_secgroup_rule_v2" "ipip-legacy" {
  count             = "${var.canal && (var.master_to_master || var.worker_to_master || var.worker_to_worker || var.master_to_worker)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "94"
  security_group_id = "${var.security_group_id}"
  remote_group_id   = "${var.remote_group_id}"
}
