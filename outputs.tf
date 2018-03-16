<<<<<<< HEAD
locals {
  k8s_admin_config = "/etc/kubernetes/admin.conf"

  etcd_test_command = <<CMD
/opt/etcd/bin/etcdctl \
    --ca-file /opt/etcd/certs/ca.pem \
    --cert-file /opt/etcd/certs/cert.pem \
    --key-file /opt/etcd/certs/cert-key.pem \
    --endpoints ${module.userdata.etcd_endpoints} \
    member list \
CMD

  k8s_test_command = <<CMD
sudo /opt/k8s/bin/kubectl \
    --kubeconfig ${local.k8s_admin_config} \
    get nodes \
CMD
=======
output "public_security_group_id" {
  value = "${join("", openstack_networking_secgroup_v2.pub.*.id)}"
>>>>>>> Rework tests and associated outputs
}

output "private_ipv4_addrs" {
  value = ["${data.template_file.ipv4_addrs.*.rendered}"]
}

output "public_ipv4_addrs" {
  value = ["${data.template_file.public_ipv4_addrs.*.rendered}"]
}

output "cfssl_endpoint" {
  value = "${module.userdata.cfssl_endpoint}"
}

output "etcd_initial_cluster" {
  description = "The etcd initial cluster that can be used to join the cluster"

  value = "${module.userdata.etcd_initial_cluster}"
}

output "etcd_endpoints" {
  description = "The etcd client endpoints that can be used to interact with the etcd cluster"
  value       = "${module.userdata.etcd_endpoints}"
}

output "api_endpoint" {
  # TODO: replace this by a DNS entry to round robin on masters IP
  description = "This represents the public k8s api endpoint"
  value       = "${var.api_endpoint != "" ? var.api_endpoint : (var.master_mode ? format("%s:6443", element(concat(data.template_file.public_ipv4_addrs.*.rendered, list("")), 0)) : "")}"
}
