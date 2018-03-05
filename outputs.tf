locals {
  k8s_admin_config = "/etc/kubernetes/admin.conf"

  etcd_test_command = <<CMD
/opt/etcd/bin/etcdctl \
    --ca-file /opt/etcd/certs/ca.pem \
    --cert-file /opt/etcd/certs/cert.pem \
    --key-file /opt/etcd/certs/cert-key.pem \
    --endpoints https://localhost:2379 \
    member list \
CMD

  k8s_test_command = <<CMD
sudo /opt/k8s/bin/kubectl \
    --kubeconfig ${local.k8s_admin_config} \
    get nodes \
CMD
}

output "security_group_id" {
  value = "${join("", openstack_networking_secgroup_v2.pub.*.id)}"
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

output "etcd_status" {
  description = "This output can be used to check if the etcd cluster is up & running"

  value = "[ \\$(${local.etcd_test_command}    | wc -l) == ${var.count} ] && ${local.etcd_test_command}    | grep -q isLeader=true"
}

output "k8s_status" {
  description = "This output can be used to check if the k8s cluster is up & running"

  value = "[ \\$(${local.k8s_test_command}    | grep master | grep -iw ready | wc -l) == ${var.count} ]"
}

output "k8s_get_config" {
  description = "This output can be used to get config file"

  value = "sudo cat ${local.k8s_admin_config}"
}
