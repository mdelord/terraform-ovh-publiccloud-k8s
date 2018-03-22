resource "openstack_networking_secgroup_v2" "master" {
  name        = "${var.name}_master"
  description = "${var.name} master nodes security group"
}

resource "openstack_networking_secgroup_v2" "worker" {
  name        = "${var.name}_worker"
  description = "${var.name} worker nodes security group"
}

resource "openstack_networking_secgroup_rule_v2" "egress-ipv4_worker" {
  count             = "${var.worker_egress_ip_prefix != "" ? 1 : 0}"
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
  remote_ip_prefix  = "${var.worker_egress_ip_prefix}"
}

resource "openstack_networking_secgroup_rule_v2" "egress-ipv4_master" {
  count             = "${var.master_egress_ip_prefix != "" ? 1 : 0}"
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
  remote_ip_prefix  = "${var.master_egress_ip_prefix}"
}

resource "openstack_networking_secgroup_rule_v2" "etcd_peer_master_master" {
  count             = "${var.etcd ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "2380"
  port_range_max    = "2380"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "etcd_client_master_master" {
  count             = "${var.etcd ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "2379"
  port_range_max    = "2379"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "etcd_client_worker_master" {
  count             = "${var.etcd ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "2379"
  port_range_max    = "2379"
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "cfssl_master_master" {
  count             = "${var.cfssl ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "${var.cfssl_port}"
  port_range_max    = "${var.cfssl_port}"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "cfssl_worker_master" {
  count             = "${var.cfssl ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "${var.cfssl_port}"
  port_range_max    = "${var.cfssl_port}"
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp_master_master" {
  count             = "${var.ping ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp_worker_worker" {
  count             = "${var.ping ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp_master_worker" {
  count             = "${var.ping ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp_worker_master" {
  count             = "${var.ping ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

### kubernetes networking based on https://github.com/coreos/coreos-kubernetes/blob/master/Documentation/kubernetes-networking.md

resource "openstack_networking_secgroup_rule_v2" "flannel_vxlan_master_master" {
  count             = "${(var.flannel_vxlan || var.canal)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "flannel_vxlan_worker_worker" {
  count             = "${(var.flannel_vxlan || var.canal)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}

resource "openstack_networking_secgroup_rule_v2" "flannel_vxlan_master_worker" {
  count             = "${(var.flannel_vxlan || var.canal)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}

resource "openstack_networking_secgroup_rule_v2" "flannel_vxlan_worker_master" {
  count             = "${(var.flannel_vxlan || var.canal)? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "flannel_udp_master_master" {
  count             = "${var.flannel_udp? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8285
  port_range_max    = 8285
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}
resource "openstack_networking_secgroup_rule_v2" "flannel_udp_worker_worker" {
  count             = "${var.flannel_udp? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8285
  port_range_max    = 8285
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "flannel_udp_master_worker" {
  count             = "${var.flannel_udp? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8285
  port_range_max    = 8285
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "flannel_udp_worker_master" {
  count             = "${var.flannel_udp? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8285
  port_range_max    = 8285
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "api-server" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}
resource "openstack_networking_secgroup_rule_v2" "api-server-from-worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet_master_master" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet_master_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet-heapster_worker_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10254
  port_range_max    = 10254
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "kubelet-heapster-master_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10254
  port_range_max    = 10254
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet-read_worker_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10255
  port_range_max    = 10255
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "kubelet-read-master_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10255
  port_range_max    = 10255
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet-read-master_master" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10255
  port_range_max    = 10255
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kubelet-read-worker_master" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10255
  port_range_max    = 10255
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "calico-bgp_master_master" {
  count             = "${var.calico_bgp? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}
resource "openstack_networking_secgroup_rule_v2" "calico-bgp_worker_worker" {
  count             = "${var.calico_bgp? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "calico-bgp_master_worker" {
  count             = "${var.calico_bgp? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "calico-bgp_worker_master" {
  count             = "${var.calico_bgp? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "apps_worker_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}

resource "openstack_networking_secgroup_rule_v2" "ipip_master_master" {
  count             = "${var.canal? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "4"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}
resource "openstack_networking_secgroup_rule_v2" "ipip_worker_worker" {
  count             = "${var.canal? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "4"
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "ipip_master_worker" {
  count             = "${var.canal? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "4"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "ipip_worker_master" {
  count             = "${var.canal? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "4"
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "ipip-legacy_master_master" {
  count             = "${var.canal? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "94"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}
resource "openstack_networking_secgroup_rule_v2" "ipip-legacy_worker_worker" {
  count             = "${var.canal? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "94"
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "ipip-legacy_master_worker" {
  count             = "${var.canal? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "94"
  remote_group_id   = "${openstack_networking_secgroup_v2.master.id}"
  security_group_id = "${openstack_networking_secgroup_v2.worker.id}"
}
resource "openstack_networking_secgroup_rule_v2" "ipip-legacy_worker_master" {
  count             = "${var.canal? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "94"
  remote_group_id   = "${openstack_networking_secgroup_v2.worker.id}"
  security_group_id = "${openstack_networking_secgroup_v2.master.id}"
}
