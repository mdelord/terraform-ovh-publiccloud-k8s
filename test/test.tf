locals {
  test_k8s_admin_config = "/etc/kubernetes/admin.conf"
  test_etcd_command = "/opt/etcd/bin/etcdctl --ca-file /opt/etcd/certs/ca.pem --cert-file /opt/etcd/certs/cert.pem --key-file /opt/etcd/certs/cert-key.pem --endpoints https://localhost:2379"
  test_k8s_command = "sudo /opt/k8s/bin/kubectl --kubeconfig ${local.test_k8s_admin_config}"
  test_etcd_status = "[ \\$(${local.test_etcd_command} member list | wc -l) == ${var.count} ] && ${local.test_etcd_command} member list | grep -q isLeader=true"
  test_k8s_status = "[ \\$(${local.test_k8s_command} get nodes | grep master | grep -iw ready | wc -l) == ${var.count} ]"
}

### add remote state backend in case tests is partially applied & breaks.
### allows further manual destroy or investigation
terraform {
  backend "swift" {
    container = "%%TESTNAME%%"
  }
}

### this is the tests run by the CI
output "tf_test" {
  description = "This output is used by module tests to check if cluster is up & running"
  value = "${local.test_ssh_prefix} sh -c \"'${local.test_etcd_status} && ${local.test_k8s_status}'\""
}
