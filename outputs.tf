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
  description = "This represents the public k8s api endpoint only if `master_mode` is set to true"
  value       = "${var.master_mode ? format("%s:6443", element(concat(data.template_file.public_ipv4_addrs.*.rendered, list("")), 0)) : ""}"
}
